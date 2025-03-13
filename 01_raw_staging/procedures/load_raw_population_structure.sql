-- 01_raw_staging/procedures/load_raw_population_structure.sql

DROP PROCEDURE IF EXISTS raw_staging.load_raw_population_structure(INTEGER, BOOLEAN);
DROP PROCEDURE IF EXISTS raw_staging.load_raw_population_structure(INTEGER, INTEGER, BOOLEAN);
CREATE OR REPLACE PROCEDURE raw_staging.load_raw_population_structure(
    p_batch_id INTEGER,
    p_source_id INTEGER, 
    p_delete_existing BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_count INTEGER;
    v_start_time TIMESTAMP;
    v_source_record RECORD;
    v_file_path TEXT;
BEGIN
    -- Enregistrer le début d'exécution
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Récupération des informations de la source
    SELECT 
        id_source,
        tx_file_path,
        tx_file_pattern,
        tx_delimiter,
        tx_encoding
    INTO v_source_record
    FROM metadata.dim_source
    WHERE id_source = p_source_id
    AND fl_active = true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source POP_STRUCT non trouvée ou inactive';
    END IF;

    -- Trouver le fichier le plus récent
    SELECT file_path INTO v_file_path
    FROM (
        SELECT pg_ls_dir(v_source_record.tx_file_path) AS file_name,
               v_source_record.tx_file_path || '/' || pg_ls_dir(v_source_record.tx_file_path) AS file_path
    ) AS files
    WHERE file_name LIKE 'TF_SOC_POP_STRUCT_%'
    AND file_name LIKE '%.csv'
    ORDER BY file_name DESC
    LIMIT 1;

    -- Suppression des données existantes si demandé
    IF p_delete_existing THEN
        DELETE FROM raw_staging.raw_population_structure 
        WHERE id_batch = p_batch_id;
    END IF;

    -- Chargement direct des données sans modification
    EXECUTE format('COPY raw_staging.raw_population_structure (
        CD_REFNIS,
        TX_DESCR_NL,
        TX_DESCR_FR,
        CD_DSTR_REFNIS,
        TX_ADM_DSTR_DESCR_NL,
        TX_ADM_DSTR_DESCR_FR,
        CD_PROV_REFNIS,
        TX_PROV_DESCR_NL,
        TX_PROV_DESCR_FR,
        CD_RGN_REFNIS,
        TX_RGN_DESCR_NL,
        TX_RGN_DESCR_FR,
        CD_SEX,
        CD_NATLTY,
        TX_NATLTY_NL,
        TX_NATLTY_FR,
        CD_CIV_STS,
        TX_CIV_STS_NL,
        TX_CIV_STS_FR,
        CD_AGE,
        MS_POPULATION
    ) FROM %L WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER %L,
        ENCODING %L
    )', v_file_path, v_source_record.tx_delimiter, v_source_record.tx_encoding);

    -- Mise à jour du batch_id pour les lignes nouvellement insérées
    UPDATE raw_staging.raw_population_structure
    SET id_batch = p_batch_id
    WHERE id_batch IS NULL;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    -- Enregistrement dans l'historique
    INSERT INTO metadata.source_file_history (
        id_source,
        tx_filename,
        dt_processed,
        nb_rows_processed,
        tx_status
    )
    VALUES (
        v_source_record.id_source,
        v_file_path,
        CURRENT_TIMESTAMP,
        v_count,
        'SUCCESS'
    );

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'load_raw_population_structure', 
        'ERROR',
        SQLERRM
    );
    RAISE;
END;
$$;

COMMENT ON PROCEDURE raw_staging.load_raw_population_structure IS 
'Procédure de chargement brut des données de structure de population.
Charge les données exactement comme elles apparaissent dans le fichier source, sans modification.';