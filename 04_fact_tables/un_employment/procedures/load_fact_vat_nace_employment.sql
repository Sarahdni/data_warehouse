-- 04_fact_tables/un_employment/procedures/load_fact_vat_nace_employment.sql

CREATE OR REPLACE PROCEDURE dw.load_fact_vat_nace_employment(
    p_batch_id INTEGER,
    p_year INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_date_id INTEGER;
    v_count INTEGER;
    v_ref_date DATE;
    v_start_time TIMESTAMP;
    v_source_id INTEGER;
BEGIN
    -- Initialisation
    v_start_time := CURRENT_TIMESTAMP;
    v_ref_date := make_date(p_year, 1, 1);
    
    -- Récupérer l'ID de la source
    SELECT id_source INTO v_source_id 
    FROM metadata.dim_source 
    WHERE cd_source = 'VAT_NACE_EMPL';

    -- Récupérer l'ID de la date
    SELECT id_date INTO v_date_id
    FROM dw.dim_date
    WHERE cd_year = p_year
    AND cd_period_type = 'Y'
    AND cd_quarter IS NULL
    AND cd_month IS NULL;

    IF v_date_id IS NULL THEN
        RAISE EXCEPTION 'Année % non trouvée dans dim_date', p_year;
    END IF;

    -- Vérification des références manquantes et documentation
    WITH missing_refs AS (
        SELECT 
            COUNT(*) FILTER (WHERE NOT EXISTS (
                SELECT 1 FROM dw.dim_geography g 
                WHERE g.cd_refnis = c.cd_refnis
                AND g.dt_start <= v_ref_date 
                AND (g.dt_end IS NULL OR g.dt_end >= v_ref_date)
            )) as missing_geo,
            COUNT(*) FILTER (WHERE NOT EXISTS (
                SELECT 1 FROM dw.dim_economic_activity e
                WHERE e.cd_economic_activity = c.cd_economic_activity
                AND e.dt_valid_from <= v_ref_date
                AND (e.dt_valid_to IS NULL OR e.dt_valid_to >= v_ref_date)
            )) as missing_nace
        FROM clean_staging.clean_vat_nace_employment c
        WHERE c.id_batch = p_batch_id
        AND c.cd_refnis != '-----'
        AND c.cd_refnis ~ '^[0-9]{5}$'
    )
    INSERT INTO metadata.data_quality_issues (
        id_batch, issue_type, issue_description, nb_records_affected, dt_detected
    )
    SELECT 
        p_batch_id,
        'MISSING_REFERENCES',
        format('Références manquantes pour année %s: %s géographies, %s NACE', 
               p_year, missing_geo, missing_nace),
        missing_geo + missing_nace,
        CURRENT_TIMESTAMP
    FROM missing_refs
    WHERE missing_geo + missing_nace > 0;

    -- Supprimer les données existantes pour cette année
    DELETE FROM dw.fact_vat_nace_employment 
    WHERE cd_year = p_year;
    
    -- Insérer les nouvelles données avec gestion des codes NACE inconnus
    INSERT INTO dw.fact_vat_nace_employment (
        id_date,
        id_geography,
        cd_economic_activity,
        cd_size_class,
        ms_num_entreprises,
        ms_num_starts,
        ms_num_stops,
        fl_foreign,
        cd_nace_level,
        cd_year,
        id_batch
    )
    SELECT 
        v_date_id,
        g.id_geography,
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM dw.dim_economic_activity e 
                WHERE e.cd_economic_activity = c.cd_economic_activity
                AND e.dt_valid_from <= v_ref_date
                AND (e.dt_valid_to IS NULL OR e.dt_valid_to >= v_ref_date)
            ) THEN c.cd_economic_activity
            ELSE '9999'  -- Code pour "inconnu" si pas de correspondance
        END as cd_economic_activity,
        c.cd_size_class,
        c.ms_num_entreprises,
        c.ms_num_starts,
        c.ms_num_stops,
        FALSE,
        c.cd_nace_level,
        p_year,
        p_batch_id
    FROM clean_staging.clean_vat_nace_employment c
    JOIN dw.dim_geography g ON g.cd_refnis = c.cd_refnis 
        AND g.dt_start <= v_ref_date 
        AND (g.dt_end IS NULL OR g.dt_end >= v_ref_date)
    JOIN dw.dim_entreprise_size_employees s ON s.cd_size_class = c.cd_size_class
        AND s.dt_valid_from <= v_ref_date
        AND (s.dt_valid_to IS NULL OR s.dt_valid_to >= v_ref_date)
    WHERE c.id_batch = p_batch_id
    -- Exclusion des entreprises étrangères
    AND c.cd_refnis != '-----'
    -- Exclusion des codes REFNIS non standards
    AND c.cd_refnis ~ '^[0-9]{5}$'
    -- Contraintes d'intégrité
    AND c.cd_size_class IN (
        '0', '1', '2', '3', '4', '5', '6', '7', 
        '8', '9', '10', '11', '12', '13', '14', '15'
    )
    AND c.cd_nace_level BETWEEN 1 AND 5
    AND c.ms_num_entreprises >= 0
    AND c.ms_num_starts >= 0
    AND c.ms_num_stops >= 0;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    -- Traçabilité via transformation_tracking
    INSERT INTO metadata.transformation_tracking (
        id_source,
        nm_table_source,
        nm_schema_source,
        nm_table_target,
        nm_schema_target,
        nb_rows_source,
        nb_rows_target,
        tx_transformation_type,
        dt_start,
        dt_end,
        cd_status,
        id_batch
    ) VALUES (
        v_source_id,
        'clean_vat_nace_employment',
        'clean_staging',
        'fact_vat_nace_employment',
        'dw',
        (SELECT COUNT(*) FROM clean_staging.clean_vat_nace_employment WHERE id_batch = p_batch_id),
        v_count,
        'CLEAN_TO_DW',
        v_start_time,
        CURRENT_TIMESTAMP,
        'SUCCESS',
        p_batch_id
    );

    RAISE NOTICE 'Chargement terminé: % lignes insérées pour l''année %', v_count, p_year;

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur dans transformation_tracking
    INSERT INTO metadata.transformation_tracking (
        id_source,
        nm_table_source,
        nm_schema_source,
        nm_table_target,
        nm_schema_target,
        tx_transformation_type,
        dt_start,
        dt_end,
        cd_status,
        tx_error_message,
        id_batch
    ) VALUES (
        v_source_id,
        'clean_vat_nace_employment',
        'clean_staging',
        'fact_vat_nace_employment',
        'dw',
        'CLEAN_TO_DW',
        v_start_time,
        CURRENT_TIMESTAMP,
        'ERROR',
        SQLERRM,
        p_batch_id
    );
    
    RAISE;
END;
$$;

COMMENT ON PROCEDURE dw.load_fact_vat_nace_employment(INTEGER, INTEGER) IS
'Procédure de chargement de la table des faits d''emploi NACE depuis clean_staging.

Arguments:
- p_batch_id : ID du batch à charger
- p_year : Année des données

Caractéristiques:
- Gestion des codes NACE non référencés (remplacement par ''9999'')
- Exclusion des entreprises étrangères (code REFNIS = "-----")
- Exclusion des codes REFNIS non standards (différents de 5 chiffres)
- Détection et documentation des références manquantes (géographie, NACE)
- Jointures temporelles avec les dimensions pour la validité des données
- Vérification des contraintes d''intégrité
- Suppression des données existantes pour l''année spécifiée
- Traçabilité via transformation_tracking et data_quality_issues';