-- 02_clean_staging/procedures/load_clean_statistical_sectors.sql

CREATE OR REPLACE PROCEDURE clean_staging.load_clean_statistical_sectors(
    p_batch_id INTEGER,
    p_year INTEGER,
    p_truncate BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_rows_loaded INTEGER;
    v_source_file TEXT;
BEGIN
    -- Enregistrer l'heure de début
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Log du démarrage
    PERFORM utils.log_script_execution(
        'load_clean_statistical_sectors.sql',
        'RUNNING',
        format('Démarrage du chargement pour le batch %s, année %s', p_batch_id, p_year)
    );

    -- Récupérer le nom du fichier source pour traçabilité
    SELECT tx_filename INTO v_source_file
    FROM metadata.source_file_history
    WHERE id_file_history = p_batch_id;

    -- Vider la table si demandé
    IF p_truncate THEN
        TRUNCATE TABLE clean_staging.clean_statistical_sectors;
        RAISE NOTICE 'Table clean_statistical_sectors vidée';
    END IF;

    -- Suppression des données existantes pour l'année spécifiée
    DELETE FROM clean_staging.clean_statistical_sectors
    WHERE year_validity = p_year;
    
    -- Chargement des données
    INSERT INTO clean_staging.clean_statistical_sectors (
        cd_sector,
        year_validity,
        cd_refnis,
        cd_sub_munty,
        cd_dstr_refnis,
        cd_prov_refnis,
        cd_rgn_refnis,
        cd_nuts_lv1,
        cd_nuts_lv2,
        cd_nuts_lv3,
        tx_sector_descr_fr,
        tx_sector_descr_nl,
        tx_sector_descr_de,
        tx_sector_descr_en,
        tx_sub_munty_fr,
        tx_sub_munty_nl,
        tx_sub_munty_de,
        tx_sub_munty_en,
        geom_31370,      -- Le centroid sera automatiquement calculé par le trigger trg_update_centroid
        ms_area_ha,
        ms_perimeter_m,
        id_batch,
        dt_created,
        dt_updated
    )
    SELECT 
        cd_sector,
        p_year,
        cd_munty_refnis,
        cd_sub_munty,
        cd_dstr_refnis,
        cd_prov_refnis,
        cd_rgn_refnis,
        cd_nuts_lv1,
        cd_nuts_lv2,
        cd_nuts_lv3,
        tx_sector_descr_fr,
        tx_sector_descr_nl,
        tx_sector_descr_de,
        tx_sector_descr_en,
        tx_sub_munty_fr,
        tx_sub_munty_nl,
        tx_sub_munty_de,
        tx_sub_munty_en,
        geom_31370,
        ms_area_ha,
        ms_perimeter_m,
        p_batch_id,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    FROM raw_staging.raw_statistical_sectors
    WHERE id_batch = p_batch_id;

    -- Récupérer le nombre de lignes insérées
    GET DIAGNOSTICS v_rows_loaded = ROW_COUNT;

    -- Identifier et enregistrer les traductions manquantes
    WITH sector_missing_langs AS (
        -- Pour les descriptions de secteurs
        SELECT 
            cd_sector as code_entity,
            'SECTOR' as entity_type,
            'tx_sector_descr' as field_name,
            tx_sector_descr_fr as tx_original_fr,
            ARRAY_AGG(lang) as missing_languages
        FROM clean_staging.clean_statistical_sectors
        CROSS JOIN LATERAL (
            SELECT UNNEST(ARRAY['DE', 'EN']) as lang
            WHERE tx_sector_descr_de IS NULL OR tx_sector_descr_en IS NULL
        ) langs
        WHERE year_validity = p_year
        AND id_batch = p_batch_id
        AND tx_sector_descr_fr IS NOT NULL
        AND (
            (lang = 'DE' AND tx_sector_descr_de IS NULL) OR
            (lang = 'EN' AND tx_sector_descr_en IS NULL)
        )
        GROUP BY cd_sector, tx_sector_descr_fr
    ),
    submunty_missing_langs AS (
        -- Pour les descriptions de sous-communes
        SELECT 
            cd_sector as code_entity,
            'SUBMUNTY' as entity_type,
            'tx_sub_munty' as field_name,
            tx_sub_munty_fr as tx_original_fr,
            ARRAY_AGG(lang) as missing_languages
        FROM clean_staging.clean_statistical_sectors
        CROSS JOIN LATERAL (
            SELECT UNNEST(ARRAY['DE', 'EN']) as lang
            WHERE tx_sub_munty_de IS NULL OR tx_sub_munty_en IS NULL
        ) langs
        WHERE year_validity = p_year
        AND id_batch = p_batch_id
        AND tx_sub_munty_fr IS NOT NULL 
        AND (
            (lang = 'DE' AND tx_sub_munty_de IS NULL) OR
            (lang = 'EN' AND tx_sub_munty_en IS NULL)
        )
        GROUP BY cd_sector, tx_sub_munty_fr
    ),
    all_missing_translations AS (
        SELECT * FROM sector_missing_langs
        UNION ALL
        SELECT * FROM submunty_missing_langs
    )
    INSERT INTO metadata.missing_translations (
        code_entity,
        entity_type,
        field_name,
        tx_original_fr,
        missing_languages,
        id_batch,
        dt_created,
        fl_processed
    )
    SELECT 
        mt.code_entity,
        mt.entity_type,
        mt.field_name,
        mt.tx_original_fr,
        mt.missing_languages,
        p_batch_id,
        CURRENT_TIMESTAMP,
        FALSE
    FROM all_missing_translations mt
    WHERE NOT EXISTS (
        -- Vérifier si une traduction manquante existe déjà
        SELECT 1 
        FROM metadata.missing_translations existing
        WHERE existing.code_entity = mt.code_entity
        AND existing.entity_type = mt.entity_type
        AND existing.field_name = mt.field_name
        AND NOT existing.fl_processed
    );

    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_clean_statistical_sectors.sql',
        'SUCCESS',
        format('Chargement terminé. %s secteurs chargés pour l''année %s', v_rows_loaded, p_year)
    );

    -- Validation des données chargées
    CALL clean_staging.validate_clean_statistical_sectors(p_batch_id, TRUE);

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'load_clean_statistical_sectors.sql',
        'ERROR',
        format('Erreur lors du chargement: %s', SQLERRM)
    );
    RAISE;
END;
$$;

COMMENT ON PROCEDURE clean_staging.load_clean_statistical_sectors IS 
'Procédure de chargement des secteurs statistiques dans la table clean_staging.
Arguments:
- p_batch_id: identifiant du batch à charger (depuis raw_staging)
- p_year: année de validité des données
- p_truncate: si TRUE, vide la table avant le chargement (défaut: FALSE)

La procédure:
1. Charge les données depuis raw_staging en préservant l''intégrité des codes
2. Calcule automatiquement les centroïdes via le trigger trg_update_centroid
3. Identifie les traductions manquantes (DE, EN) pour tous les champs textuels (tx_sector_descr, tx_sub_munty)
   et les ajoute dans metadata.missing_translations s''ils n''existent pas déjà
4. Effectue les validations post-chargement

Exemple:
CALL clean_staging.load_clean_statistical_sectors(70, 2024, FALSE);';

