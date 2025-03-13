-- 01_raw_staging/procedures/load_statistical_sectors.sql

CREATE OR REPLACE PROCEDURE raw_staging.load_raw_statistical_sectors(
    p_source_id INTEGER,
    p_year_reference INTEGER,
    p_truncate BOOLEAN DEFAULT FALSE,
    p_srid INTEGER DEFAULT 31370
)
LANGUAGE plpgsql AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_rows_loaded INTEGER;
    v_geojson_content JSONB;
    v_file_history_id INTEGER;
    v_file_path TEXT;
    v_file_pattern TEXT;
    v_full_path TEXT;
BEGIN
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Log du début
    PERFORM utils.log_script_execution('load_raw_statistical_sectors.sql', 'RUNNING');
    
    -- Récupération des informations de la source
    SELECT tx_file_path, tx_file_pattern
    INTO v_file_path, v_file_pattern
    FROM metadata.dim_source
    WHERE id_source = p_source_id
    AND fl_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source id % non trouvée ou inactive', p_source_id;
    END IF;

    -- Construction du chemin complet
    v_full_path := v_file_path || v_file_pattern;
    
    -- Création de l'entrée dans l'historique
    INSERT INTO metadata.source_file_history (
        id_source,
        tx_filename,
        dt_processed,
        tx_status
    ) VALUES (
        p_source_id,
        v_file_pattern,
        v_start_time,
        'RUNNING'
    ) RETURNING id_file_history INTO v_file_history_id;
    
    -- Lecture du fichier GeoJSON
    v_geojson_content := pg_read_file(v_full_path)::jsonb;

    -- Truncate si demandé
    IF p_truncate THEN
        TRUNCATE TABLE raw_staging.raw_statistical_sectors;
    END IF;

    -- Chargement des données
    INSERT INTO raw_staging.raw_statistical_sectors (
        cd_country,
        cd_sector,
        cd_sub_munty,
        cd_munty_refnis,
        cd_dstr_refnis,
        cd_prov_refnis,
        cd_rgn_refnis,
        cd_nuts_lv1,
        cd_nuts_lv2,
        cd_nuts_lv3,
        tx_sector_descr_fr,
        tx_sector_descr_nl,
        tx_sector_descr_de,
        tx_sub_munty_fr,
        tx_sub_munty_nl,
        tx_munty_descr_fr,
        tx_munty_descr_nl,
        tx_munty_descr_de,
        tx_munty_dstr,
        tx_adm_dstr_descr_fr,
        tx_adm_dstr_descr_nl,
        tx_adm_dstr_descr_de,
        tx_prov_descr_fr,
        tx_prov_descr_nl,
        tx_prov_descr_de,
        tx_rgn_descr_fr,
        tx_rgn_descr_nl,
        tx_rgn_descr_de,
        geom_31370,
        ms_area_ha,
        ms_perimeter_m,
        year_reference,
        dt_import,
        id_batch,
        tx_source_file
    )
    SELECT 
        f.value -> 'properties' ->> 'cd_country',
        f.value -> 'properties' ->> 'cd_sector',
        f.value -> 'properties' ->> 'cd_sub_munty',
        f.value -> 'properties' ->> 'cd_munty_refnis',
        f.value -> 'properties' ->> 'cd_dstr_refnis',
        f.value -> 'properties' ->> 'cd_prov_refnis',
        f.value -> 'properties' ->> 'cd_rgn_refnis',
        f.value -> 'properties' ->> 'cd_nuts_lv1',
        f.value -> 'properties' ->> 'cd_nuts_lv2',
        f.value -> 'properties' ->> 'cd_nuts_lv3',
        f.value -> 'properties' ->> 'tx_sector_descr_fr',
        f.value -> 'properties' ->> 'tx_sector_descr_nl',
        f.value -> 'properties' ->> 'tx_sector_descr_de',
        f.value -> 'properties' ->> 'tx_sub_munty_fr',
        f.value -> 'properties' ->> 'tx_sub_munty_nl',
        f.value -> 'properties' ->> 'tx_munty_descr_fr',
        f.value -> 'properties' ->> 'tx_munty_descr_nl',
        f.value -> 'properties' ->> 'tx_munty_descr_de',
        f.value -> 'properties' ->> 'tx_munty_dstr',
        f.value -> 'properties' ->> 'tx_adm_dstr_descr_fr',
        f.value -> 'properties' ->> 'tx_adm_dstr_descr_nl',
        f.value -> 'properties' ->> 'tx_adm_dstr_descr_de',
        f.value -> 'properties' ->> 'tx_prov_descr_fr',
        f.value -> 'properties' ->> 'tx_prov_descr_nl',
        f.value -> 'properties' ->> 'tx_prov_descr_de',
        f.value -> 'properties' ->> 'tx_rgn_descr_fr',
        f.value -> 'properties' ->> 'tx_rgn_descr_nl',
        f.value -> 'properties' ->> 'tx_rgn_descr_de',
        ST_Force2D(ST_SetSRID(ST_GeomFromGeoJSON((f.value -> 'geometry')::text), p_srid)), 
        (f.value -> 'properties' ->> 'ms_area_ha')::NUMERIC(15,10),
        (f.value -> 'properties' ->> 'ms_perimeter_m')::NUMERIC(15,3),
        p_year_reference,
        CURRENT_TIMESTAMP,
        v_file_history_id,
        v_file_pattern
    FROM jsonb_array_elements(v_geojson_content -> 'features') f;


    GET DIAGNOSTICS v_rows_loaded = ROW_COUNT;

    -- Mise à jour du statut dans l'historique
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
        -- Mise à jour de l'historique en cas d'erreur
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

COMMENT ON PROCEDURE raw_staging.load_raw_statistical_sectors(INTEGER, INTEGER, BOOLEAN, INTEGER) IS 
'Procédure de chargement des secteurs statistiques.

Arguments:
- p_source_id: ID de la source dans metadata.dim_source
- p_year_reference: année de référence pour le jeu de données
- p_truncate: si TRUE, vide la table avant le chargement (défaut: FALSE)
- p_srid: système de référence spatiale à utiliser (défaut: 31370)

La procédure:
1. Récupère le chemin et le pattern du fichier depuis metadata.dim_source
2. Charge le fichier GeoJSON correspondant
3. Insère les données dans raw_staging.raw_statistical_sectors
4. Gère la traçabilité via metadata.source_file_history';