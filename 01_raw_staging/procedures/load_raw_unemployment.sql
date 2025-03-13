-- 01_raw_staging/procedures/load_raw_unemployment.sql

CREATE OR REPLACE PROCEDURE raw_staging.load_raw_unemployment(
    p_batch_id INTEGER,
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
    WHERE cd_source = 'LFS_UNEMPL'
    AND fl_active = true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source LFS_UNEMPL non trouvée ou inactive';
    END IF;

    -- Trouver le fichier le plus récent
    SELECT file_path INTO v_file_path
    FROM (
        SELECT pg_ls_dir(v_source_record.tx_file_path) AS file_name,
               v_source_record.tx_file_path || '/' || pg_ls_dir(v_source_record.tx_file_path) AS file_path
    ) AS files
    WHERE file_name LIKE 'TF_HVD_LFS_UNEMPLOYMENT_%'
    AND file_name LIKE '%.csv'
    ORDER BY file_name DESC
    LIMIT 1;

    -- Suppression des données existantes si demandé
    IF p_delete_existing THEN
        DELETE FROM raw_staging.raw_unemployment 
        WHERE id_batch = p_batch_id;
    END IF;

    -- Chargement direct des données sans modification
    EXECUTE format('COPY raw_staging.raw_unemployment  (
        ID_CUBE,
        CD_YEAR,
        CD_QUARTER,
        CD_SEX,
        CD_EMPMT_AGE,
        CD_NUTS_LVL2,
        TX_NUTS_LVL2_DESCR_DE,
        TX_NUTS_LVL2_DESCR_EN,
        TX_NUTS_LVL2_DESCR_FR,
        TX_NUTS_LVL2_DESCR_NL,
        CD_ISCED_2011,
        TX_ISCED_2011_DESCR_DE,
        TX_ISCED_2011_DESCR_EN,
        TX_ISCED_2011_DESCR_FR,
        TX_ISCED_2011_DESCR_NL,
        CD_PROPERTY,TX_PROPERTY_DESCR_DE,
        TX_PROPERTY_DESCR_EN,
        TX_PROPERTY_DESCR_FR,
        TX_PROPERTY_DESCR_NL,
        MS_VALUE
    ) FROM %L WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER %L,
        ENCODING %L
    )', v_file_path, v_source_record.tx_delimiter, v_source_record.tx_encoding);

    -- Mise à jour du batch_id pour les lignes nouvellement insérées
    UPDATE raw_staging.raw_unemployment
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
        'load_raw_unemployment', 
        'ERROR',
        SQLERRM
    );
    RAISE;
END;
$$;

COMMENT ON PROCEDURE raw_staging.load_raw_unemployment IS 
'Procédure de chargement brut des données de chomage.
Charge les données exactement comme elles apparaissent dans le fichier source, sans modification.';