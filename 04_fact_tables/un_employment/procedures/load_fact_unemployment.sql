-- 04_fact_tables/un_employment/procedures/load_fact_unemployment.sql

CREATE OR REPLACE PROCEDURE dw.load_fact_unemployment(
    p_batch_id INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_count INTEGER;
    v_error_count INTEGER := 0;
    v_start_time TIMESTAMP;
    v_source_id INTEGER;
BEGIN
    -- Enregistrer le début d'exécution
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Log du début
    PERFORM utils.log_script_execution('load_fact_unemployment', 'RUNNING');

    -- Récupérer l'ID de la source
    SELECT id_source INTO v_source_id 
    FROM metadata.dim_source 
    WHERE cd_source = 'LFS_UNEMPL';

    -- Vérifier l'existence des données sources
    IF NOT EXISTS (
        SELECT 1 FROM clean_staging.clean_unemployment 
        WHERE id_batch = p_batch_id
    ) THEN
        RAISE EXCEPTION 'Aucune donnée trouvée dans clean_staging pour le batch %', p_batch_id;
    END IF;

    -- Supprimer les données existantes pour ce batch
    DELETE FROM dw.fact_unemployment 
    WHERE id_batch = p_batch_id;
    
    -- Insérer les nouvelles données avec vérification des contraintes
    INSERT INTO dw.fact_unemployment (
        id_date,
        id_geography,
        cd_sex,
        cd_age_group,
        cd_education_level,
        cd_unemp_type,
        ms_unemployment_rate,
        fl_total_sex,
        fl_total_age,
        fl_total_education,
        fl_total_geography,
        fl_valid,
        id_batch
    )
    SELECT 
        d.id_date,  -- Join avec dim_date au lieu d'utiliser un paramètre fixe
        c.id_geography,
        c.cd_sex,
        c.cd_age_group,
        c.cd_education_level,
        c.cd_measure_type AS cd_unemp_type,
        c.ms_unemployment_rate,
        c.fl_total_sex,
        c.fl_total_age,
        c.fl_total_education,
        c.fl_total_geography,
        c.fl_valid,
        p_batch_id
    FROM clean_staging.clean_unemployment c
    JOIN dw.dim_date d ON 
        d.id_date = c.id_date
    WHERE c.id_batch = p_batch_id
    AND c.ms_unemployment_rate IS NOT NULL
    AND c.ms_unemployment_rate BETWEEN 0 AND 1;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    -- Log des statistiques
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
        tx_transformation_rules,
        id_batch
    ) VALUES (
        v_source_id,
        'clean_unemployment',
        'clean_staging',
        'fact_unemployment',
        'dw',
        (SELECT COUNT(*) FROM clean_staging.clean_unemployment WHERE id_batch = p_batch_id),
        v_count,
        'CLEAN_TO_DW',
        v_start_time,
        CURRENT_TIMESTAMP,
        'SUCCESS',
        format('Chargement données de chômage pour le batch %s', p_batch_id),
        p_batch_id
    );

    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_fact_unemployment', 
        'SUCCESS',
        format('Chargement terminé. %s lignes chargées pour le batch %s. Durée: %s minutes', 
               v_count,
               p_batch_id,
               EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_start_time))/60)
    );

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
        'clean_unemployment',
        'clean_staging',
        'fact_unemployment',
        'dw',
        'CLEAN_TO_DW',
        v_start_time,
        CURRENT_TIMESTAMP,
        'ERROR',
        SQLERRM,
        p_batch_id
    );

    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'load_fact_unemployment', 
        'ERROR',
        format('Erreur: %s. Durée: %s minutes', 
               SQLERRM,
               EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_start_time))/60)
    );
    RAISE;
END;
$$;

COMMENT ON PROCEDURE dw.load_fact_unemployment(INTEGER) IS 
'Procédure de chargement de la table des faits de chômage depuis clean_staging.

Arguments:
- p_batch_id : ID du batch à charger

Caractéristiques:
- Charge toutes les années présentes dans le batch
- Gestion de toutes les dimensions (géographie, sexe, âge, éducation, type de chômage)
- Validation des taux de chômage (0-1)
- Gestion des flags de totaux
- Traçabilité complète via transformation_tracking
- Logging détaillé des opérations';