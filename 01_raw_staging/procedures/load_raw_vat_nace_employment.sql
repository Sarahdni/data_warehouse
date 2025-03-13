-- 01_raw_staging/procedures/load_raw_vat_nace_employment.sql

CREATE OR REPLACE PROCEDURE raw_staging.load_raw_vat_nace_employment(
    p_source_id INTEGER,
    p_delete_existing BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_batch_id INTEGER;
    v_count INTEGER;
    v_start_time TIMESTAMP;
    v_source_record RECORD;
    v_format_type VARCHAR;
    v_header_line VARCHAR;
    v_column_count INTEGER;
    v_copy_sql TEXT;
    v_file_path TEXT;
    v_file_name TEXT;
BEGIN
    -- Enregistrer le début d'exécution
    v_start_time := CURRENT_TIMESTAMP;
    PERFORM utils.log_script_execution('load_raw_vat_nace_employment', 'RUNNING');
    
    -- Récupération des informations de la source par ID
    SELECT 
        id_source,
        tx_file_path,
        tx_file_pattern,
        tx_delimiter,
        tx_encoding,
        cd_source
    INTO v_source_record
    FROM metadata.dim_source
    WHERE id_source = p_source_id
    AND fl_active = true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source avec ID % non trouvée ou inactive', p_source_id;
    END IF;
    
    -- Construction directe du chemin du fichier
    v_file_path := v_source_record.tx_file_path || v_source_record.tx_file_pattern;
    v_file_name := v_source_record.tx_file_pattern;
    
    -- Vérifier si le fichier existe
    IF NOT EXISTS (SELECT 1 FROM pg_stat_file(v_file_path)) THEN
        RAISE EXCEPTION 'Fichier non trouvé: %', v_file_path;
    END IF;
    
    -- Détecter le format du fichier
    CALL raw_staging.detect_file_format(
        v_file_path,
        v_format_type,
        v_header_line,
        v_column_count
    );
    
    IF v_format_type = 'INCONNU' THEN
        RAISE EXCEPTION 'Format de fichier non reconnu: %', v_file_path;
    END IF;
    
    -- Suppression des données existantes si demandé
    IF p_delete_existing AND v_batch_id IS NOT NULL THEN
        DELETE FROM raw_staging.raw_vat_nace_employment
        WHERE id_batch = v_batch_id;
    END IF;
    
    -- Préparation d'une table temporaire pour le chargement
    CREATE TEMP TABLE temp_vat_nace AS 
    SELECT * FROM raw_staging.raw_vat_nace_employment 
    WHERE 1=0;
    
    -- Chargement dans la table temporaire
    IF v_format_type = 'MINIMAL' THEN
        -- Pour le format minimal, nous utilisons COPY avec un fichier temporaire de format spécifié
        EXECUTE format('
            COPY temp_vat_nace(
                cd_refnis,
                cd_nis_stat_unt_cls,
                cd_nace,
                ms_num_vat,
                ms_num_vat_start,
                ms_num_vat_stop
            ) FROM %L WITH (
                FORMAT csv,
                HEADER true,
                DELIMITER %L,
                ENCODING %L,
                NULL ''''
            )', v_file_path, v_source_record.tx_delimiter, v_source_record.tx_encoding);
    ELSE
        -- Format complet
        EXECUTE format('
            COPY temp_vat_nace(
                cd_nis_stat_unt_cls,
                tx_nis_stat_unt_cls_fr_lvl1,
                tx_nis_stat_unt_cls_nl_lvl1,
                tx_nis_stat_unt_cls_en_lvl1,
                cd_nace,
                tx_nace_fr_lvl1,
                tx_nace_nl_lvl1,
                tx_nace_en_lvl1,
                tx_nace_fr_lvl2,
                tx_nace_nl_lvl2,
                tx_nace_en_lvl2,
                tx_nace_fr_lvl3,
                tx_nace_nl_lvl3,
                tx_nace_en_lvl3,
                tx_nace_fr_lvl4,
                tx_nace_nl_lvl4,
                tx_nace_en_lvl4,
                tx_nace_fr_lvl5,
                tx_nace_nl_lvl5,
                tx_nace_en_lvl5,
                cd_adm_dstr_refnis,
                tx_adm_dstr_descr_fr,
                tx_adm_dstr_descr_nl,
                tx_adm_dstr_descr_en,
                cd_rgn_refnis,
                cd_prov_refnis,
                tx_prov_descr_fr,
                tx_prov_descr_nl,
                tx_prov_descr_en,
                tx_rgn_descr_fr,
                tx_rgn_descr_nl,
                tx_rgn_descr_en,
                ms_num_vat,
                ms_num_vat_start,
                ms_num_vat_stop
            ) FROM %L WITH (
                FORMAT csv,
                HEADER true,
                DELIMITER %L,
                ENCODING %L,
                NULL ''''
            )', v_file_path, v_source_record.tx_delimiter, v_source_record.tx_encoding);
    END IF;
    
    -- Enregistrement dans l'historique
    INSERT INTO metadata.source_file_history (
        id_source,
        tx_filename,
        dt_processed,
        tx_status
    )
    VALUES (
        v_source_record.id_source,
        v_file_name,
        CURRENT_TIMESTAMP,
        'SUCCESS'
    )
    RETURNING id_file_history INTO v_batch_id;
    
    -- Transfert des données de la table temporaire vers la table finale
    INSERT INTO raw_staging.raw_vat_nace_employment (
        id_batch,
        cd_nis_stat_unt_cls,
        tx_nis_stat_unt_cls_fr_lvl1,
        tx_nis_stat_unt_cls_nl_lvl1,
        tx_nis_stat_unt_cls_en_lvl1,
        cd_nace,
        tx_nace_fr_lvl1,
        tx_nace_nl_lvl1,
        tx_nace_en_lvl1,
        tx_nace_fr_lvl2,
        tx_nace_nl_lvl2,
        tx_nace_en_lvl2,
        tx_nace_fr_lvl3,
        tx_nace_nl_lvl3,
        tx_nace_en_lvl3,
        tx_nace_fr_lvl4,
        tx_nace_nl_lvl4,
        tx_nace_en_lvl4,
        tx_nace_fr_lvl5,
        tx_nace_nl_lvl5,
        tx_nace_en_lvl5,
        cd_adm_dstr_refnis,
        tx_adm_dstr_descr_fr,
        tx_adm_dstr_descr_nl,
        tx_adm_dstr_descr_en,
        cd_rgn_refnis,
        cd_prov_refnis,
        tx_prov_descr_fr,
        tx_prov_descr_nl,
        tx_prov_descr_en,
        tx_rgn_descr_fr,
        tx_rgn_descr_nl,
        tx_rgn_descr_en,
        ms_num_vat,
        ms_num_vat_start,
        ms_num_vat_stop,
        tx_file_format
    )
    SELECT 
        v_batch_id,
        cd_nis_stat_unt_cls,
        tx_nis_stat_unt_cls_fr_lvl1,
        tx_nis_stat_unt_cls_nl_lvl1,
        tx_nis_stat_unt_cls_en_lvl1,
        cd_nace,
        tx_nace_fr_lvl1,
        tx_nace_nl_lvl1,
        tx_nace_en_lvl1,
        tx_nace_fr_lvl2,
        tx_nace_nl_lvl2,
        tx_nace_en_lvl2,
        tx_nace_fr_lvl3,
        tx_nace_nl_lvl3,
        tx_nace_en_lvl3,
        tx_nace_fr_lvl4,
        tx_nace_nl_lvl4,
        tx_nace_en_lvl4,
        tx_nace_fr_lvl5,
        tx_nace_nl_lvl5,
        tx_nace_en_lvl5,
        COALESCE(cd_adm_dstr_refnis, cd_refnis),  -- Mapping pour le format minimal
        tx_adm_dstr_descr_fr,
        tx_adm_dstr_descr_nl,
        tx_adm_dstr_descr_en,
        cd_rgn_refnis,
        cd_prov_refnis,
        tx_prov_descr_fr,
        tx_prov_descr_nl,
        tx_prov_descr_en,
        tx_rgn_descr_fr,
        tx_rgn_descr_nl,
        tx_rgn_descr_en,
        ms_num_vat,
        ms_num_vat_start,
        ms_num_vat_stop,
        v_format_type
    FROM temp_vat_nace;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    
    -- Mise à jour du nombre de lignes dans l'historique
    UPDATE metadata.source_file_history
    SET nb_rows_processed = v_count
    WHERE id_file_history = v_batch_id;
    
    -- Nettoyage
    DROP TABLE temp_vat_nace;
    
    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_raw_vat_nace_employment', 
        'SUCCESS',
        format('Source %s (%s) : %s lignes chargées dans le format %s', 
               v_source_record.id_source, 
               v_source_record.cd_source,
               v_count, 
               v_format_type)
    );

EXCEPTION WHEN OTHERS THEN
    -- Nettoyage en cas d'erreur
    DROP TABLE IF EXISTS temp_vat_nace;
    
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'load_raw_vat_nace_employment', 
        'ERROR',
        SQLERRM
    );
    
    -- Enregistrement de l'échec dans l'historique
    IF v_source_record.id_source IS NOT NULL AND v_file_name IS NOT NULL THEN
        INSERT INTO metadata.source_file_history (
            id_source,
            tx_filename,
            dt_processed,
            tx_status,
            tx_error_message
        )
        VALUES (
            v_source_record.id_source,
            v_file_name,
            CURRENT_TIMESTAMP,
            'ERROR',
            SQLERRM
        );
    END IF;
    
    RAISE;
END;
$$;

COMMENT ON PROCEDURE raw_staging.load_raw_vat_nace_employment(INTEGER, BOOLEAN) IS 
'Procédure de chargement brut des données de l''emploi par secteur nace.
Cette procédure détecte automatiquement le format du fichier (MINIMAL ou COMPLET) et
adapte le chargement en conséquence.

Arguments:
- p_source_id: Identifiant de la source dans metadata.dim_source (ex: 226 pour VAT_NACE_EMPL_2008)
- p_delete_existing: Si TRUE, supprime les données existantes pour ce batch

Cette procédure fonctionne avec les deux formats de fichiers:
- Format MINIMAL (2008-2021): 6 colonnes (cd_refnis, cd_nis_stat_unt_cls, etc.)
- Format COMPLET (2023): 35 colonnes avec libellés multilingues';