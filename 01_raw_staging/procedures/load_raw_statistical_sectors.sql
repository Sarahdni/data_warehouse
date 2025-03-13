-- 01_raw_staging/procedures/load_raw_statistical_sectors.sql

CREATE OR REPLACE PROCEDURE raw_staging.load_raw_statistical_sectors(
    p_filename TEXT,
    p_truncate BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_source_id INTEGER;
    v_file_history_id INTEGER;
    v_rows_loaded INTEGER;
    v_source_code VARCHAR(50);
    v_geojson_content JSONB;
BEGIN
    -- Enregistrer l'heure de début
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Déterminer le code source selon le fichier
    v_source_code := CASE
        WHEN p_filename = 'sh_statbel_statistical_sectors.geojson' 
            THEN 'STATBEL_SECTORS_2011_2017'
        WHEN p_filename ~ '_31370_' 
            THEN 'STATBEL_SECTORS_31370_' || substring(p_filename from 'sectors_\d+_(\d{4})' for '#')
        WHEN p_filename ~ '_3812_'
            THEN 'STATBEL_SECTORS_3812_' || substring(p_filename from 'sectors_\d+_(\d{4})' for '#')
        WHEN p_filename ~ '^sh_statbel_statistical_sectors_20\d{2}'
            THEN 'STATBEL_SECTORS_' || substring(p_filename from '_20(\d{2})' for '#')
        ELSE 'STATBEL_SECTORS_2011_2017'  -- valeur par défaut
    END;
    
    RAISE NOTICE 'Code source déterminé: %', v_source_code;
    
    -- Récupérer l'id de la source
    SELECT id_source 
    INTO v_source_id
    FROM metadata.dim_source 
    WHERE cd_source = v_source_code
    AND fl_active = TRUE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source % non trouvée ou inactive', v_source_code;
    END IF;

    -- Créer une entrée dans l'historique
    INSERT INTO metadata.source_file_history (
        id_source,
        tx_filename,
        dt_processed,
        tx_status
    ) VALUES (
        v_source_id,
        p_filename,
        v_start_time,
        'RUNNING'
    ) RETURNING id_file_history INTO v_file_history_id;

    -- Lire et parser le fichier GeoJSON
    v_geojson_content := pg_read_file(p_filename)::jsonb;

    -- Vider la table si demandé
    IF p_truncate THEN
        TRUNCATE TABLE raw_staging.raw_statistical_sectors;
    END IF;

    -- Chargement des données
    WITH features AS (
        SELECT value AS feature
        FROM jsonb_array_elements(v_geojson_content -> 'features') 
    )
    INSERT INTO raw_staging.raw_statistical_sectors (
        ogc_fid,
        cd_sector,
        cd_sub_munty,
        cd_munty_refnis,
        cd_dstr_refnis,
        cd_prov_refnis,
        cd_rgn_refnis,
        cd_nuts1,
        cd_nuts2,
        cd_nuts3,
        tx_sector_descr_nl,
        tx_sector_descr_fr,
        tx_sub_munty_nl,
        tx_sub_munty_fr,
        tx_munty_descr_nl,
        tx_munty_descr_fr,
        tx_munty_descr_de,
        tx_munty_descr_en,
        tx_adm_dstr_descr_nl,
        tx_adm_dstr_descr_fr,
        tx_adm_dstr_descr_de,
        tx_adm_dstr_descr_en,
        tx_prov_descr_nl,
        tx_prov_descr_fr,
        tx_prov_descr_de,
        tx_prov_descr_en,
        tx_rgn_descr_nl,
        tx_rgn_descr_fr,
        tx_rgn_descr_de,
        tx_rgn_descr_en,
        geom,
        raw_content,
        id_batch
    )
    SELECT
        (feature -> 'properties' ->> 'PKUID')::integer as ogc_fid,
        feature -> 'properties' ->> 'CD_SECTOR',
        feature -> 'properties' ->> 'CD_SUB_MUNTY',
        feature -> 'properties' ->> 'CD_MUNTY_REFNIS',
        feature -> 'properties' ->> 'CD_DSTR_REFNIS',
        feature -> 'properties' ->> 'CD_PROV_REFNIS',
        feature -> 'properties' ->> 'CD_RGN_REFNIS',
        feature -> 'properties' ->> 'CD_NUTS1',
        feature -> 'properties' ->> 'CD_NUTS2',
        feature -> 'properties' ->> 'CD_NUTS3',
        feature -> 'properties' ->> 'TX_SECTOR_DESCR_NL',
        feature -> 'properties' ->> 'TX_SECTOR_DESCR_FR',
        feature -> 'properties' ->> 'TX_SUB_MUNTY_NL',
        feature -> 'properties' ->> 'TX_SUB_MUNTY_FR',
        feature -> 'properties' ->> 'TX_MUNTY_DESCR_NL',
        feature -> 'properties' ->> 'TX_MUNTY_DESCR_FR',
        feature -> 'properties' ->> 'TX_MUNTY_DESCR_DE',
        feature -> 'properties' ->> 'TX_MUNTY_DESCR_EN',
        feature -> 'properties' ->> 'TX_ADM_DSTR_DESCR_NL',
        feature -> 'properties' ->> 'TX_ADM_DSTR_DESCR_FR',
        feature -> 'properties' ->> 'TX_ADM_DSTR_DESCR_DE',
        feature -> 'properties' ->> 'TX_ADM_DSTR_DESCR_EN',
        feature -> 'properties' ->> 'TX_PROV_DESCR_NL',
        feature -> 'properties' ->> 'TX_PROV_DESCR_FR',
        feature -> 'properties' ->> 'TX_PROV_DESCR_DE',
        feature -> 'properties' ->> 'TX_PROV_DESCR_EN',
        feature -> 'properties' ->> 'TX_RGN_DESCR_NL',
        feature -> 'properties' ->> 'TX_RGN_DESCR_FR',
        feature -> 'properties' ->> 'TX_RGN_DESCR_DE',
        feature -> 'properties' ->> 'TX_RGN_DESCR_EN',
        ST_SetSRID(ST_GeomFromGeoJSON((feature -> 'geometry')::text), 31370), -- SRID belge
        feature,  -- Stockage du contenu brut
        v_file_history_id
    FROM features;    

    -- Récupérer le nombre de lignes insérées
    GET DIAGNOSTICS v_rows_loaded = ROW_COUNT;

    -- Mettre à jour l'historique
    UPDATE metadata.source_file_history 
    SET dt_processed = CURRENT_TIMESTAMP,
        nb_rows_processed = v_rows_loaded,
        tx_status = 'SUCCESS'
    WHERE id_file_history = v_file_history_id;

    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_raw_statistical_sectors.sql',
        'SUCCESS',
        format('Chargement terminé. %s secteurs chargés.', v_rows_loaded)
    );

EXCEPTION 
    WHEN OTHERS THEN
        -- Mettre à jour l'historique en cas d'erreur
        IF v_file_history_id IS NOT NULL THEN
            UPDATE metadata.source_file_history 
            SET dt_processed = CURRENT_TIMESTAMP,
                tx_status = 'ERROR',
                tx_error_message = SQLERRM
            WHERE id_file_history = v_file_history_id;
        END IF;

        -- Log de l'erreur
        PERFORM utils.log_script_execution(
            'load_raw_statistical_sectors.sql',
            'ERROR',
            SQLERRM
        );

        RAISE;
END;
$$;

COMMENT ON PROCEDURE raw_staging.load_raw_statistical_sectors(TEXT, BOOLEAN) IS 
'Procédure de chargement brut des secteurs statistiques depuis un fichier GeoJSON.
Arguments:
- p_filename: nom du fichier GeoJSON à charger (ex: sh_statbel_statistical_sectors_31370_2024.geojson)
- p_truncate: si TRUE, vide la table avant le chargement (défaut: TRUE)

La procédure détermine automatiquement le code source en fonction du nom du fichier:
- sh_statbel_statistical_sectors.geojson -> STATBEL_SECTORS_2011_2017
- *_31370_* -> STATBEL_SECTORS_31370_YYYY
- *_3812_* -> STATBEL_SECTORS_3812_YYYY
- *_20XX -> STATBEL_SECTORS_XX

Exemple:
CALL raw_staging.load_raw_statistical_sectors(''/Users/sarahdinari/Desktop/data_lake/reference_tables/secteurs_statistiques/sh_statbel_statistical_sectors.geojson'', TRUE);';