-- 01_raw_staging/procedures/load_raw_real_estate_sector.sql

CREATE OR REPLACE PROCEDURE raw_staging.load_raw_real_estate_sector(
    p_batch_id INTEGER,
    p_delete_existing BOOLEAN DEFAULT TRUE
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
    
    -- Log du début
    PERFORM utils.log_script_execution('load_raw_real_estate_sector', 'RUNNING');

    -- Récupération des informations de la source
    SELECT 
        id_source,
        tx_file_path,
        tx_file_pattern,
        tx_delimiter,
        tx_encoding
    INTO v_source_record
    FROM metadata.dim_source
    WHERE cd_source = 'IMMO_SECTOR'
    AND fl_active = true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source IMMO_SECTOR non trouvée ou inactive dans metadata.dim_source';
    END IF;

    -- Trouver le fichier le plus récent dans le répertoire
    SELECT file_path INTO v_file_path
    FROM (
        SELECT pg_ls_dir(v_source_record.tx_file_path) AS file_name,
               v_source_record.tx_file_path || '/' || pg_ls_dir(v_source_record.tx_file_path) AS file_path
    ) AS files
    WHERE file_name LIKE 'TF_IMMO_SECTOR_%'
    AND file_name LIKE '%.csv'
    ORDER BY file_name DESC
    LIMIT 1;

    IF v_file_path IS NULL THEN
        RAISE EXCEPTION 'Aucun fichier correspondant au pattern % trouvé dans %', 
                       v_source_record.tx_file_pattern, 
                       v_source_record.tx_file_path;
    END IF;

    RAISE NOTICE 'Traitement du fichier: %', v_file_path;

    -- Suppression des données existantes si demandé
    IF p_delete_existing THEN
        DELETE FROM raw_staging.raw_real_estate_sector 
        WHERE id_batch = p_batch_id;
    END IF;

    -- Création d'une table temporaire pour le chargement
    CREATE TEMP TABLE tmp_import (
        cd_stat_sector VARCHAR(20),
        cd_year INTEGER,
        cd_type VARCHAR(4),
        cd_type_nl VARCHAR(100),
        cd_type_fr VARCHAR(100),
        ms_transactions INTEGER,
        ms_p25 DECIMAL(15,2),
        "ms_p50 (median_price)" DECIMAL(15,2),  -- Nom exact de la colonne dans le CSV
        ms_p75 DECIMAL(15,2),
        ms_p10 DECIMAL(15,2),
        ms_p90 DECIMAL(15,2)
    );

    -- Chargement des données du CSV dans la table temporaire
    EXECUTE format('COPY tmp_import FROM %L WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER %L,
        ENCODING %L,
        FORCE_NULL (ms_p25, "ms_p50 (median_price)", ms_p75, ms_p10, ms_p90)
    )', v_file_path, v_source_record.tx_delimiter, v_source_record.tx_encoding);

    -- Insertion dans la table raw avec gestion des erreurs
    INSERT INTO raw_staging.raw_real_estate_sector (
        cd_stat_sector,
        cd_year,
        cd_type,
        cd_type_nl,
        cd_type_fr,
        ms_transactions,
        ms_p25,
        ms_p50,
        ms_p75,
        ms_p10,
        ms_p90,
        id_batch
    )
    SELECT 
        cd_stat_sector,
        cd_year,
        cd_type,
        cd_type_nl,
        cd_type_fr,
        NULLIF(ms_transactions, 0),
        NULLIF(ms_p25, 0),
        NULLIF("ms_p50 (median_price)", 0),
        NULLIF(ms_p75, 0),
        NULLIF(ms_p10, 0),
        NULLIF(ms_p90, 0),
        p_batch_id
    FROM tmp_import
    WHERE cd_stat_sector IS NOT NULL;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    -- Enregistrement du fichier traité
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

    -- Nettoyage
    DROP TABLE tmp_import;

    -- Log du succès avec plus de détails
    RAISE NOTICE 'Chargement terminé avec succès:';
    RAISE NOTICE '- Nombre de lignes chargées: %', v_count;
    RAISE NOTICE '- Fichier source: %', v_file_path;

    PERFORM utils.log_script_execution(
        'load_raw_real_estate_sector', 
        'SUCCESS',
        format('Chargement terminé. %s lignes chargées. Durée: %s minutes', 
               v_count,
               EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_start_time))/60)
    );

EXCEPTION WHEN OTHERS THEN
    -- Nettoyage en cas d'erreur
    DROP TABLE IF EXISTS tmp_import;
    
    -- Enregistrement de l'erreur dans l'historique des fichiers
    IF v_source_record.id_source IS NOT NULL THEN
        INSERT INTO metadata.source_file_history (
            id_source,
            tx_filename,
            dt_processed,
            nb_rows_processed,
            tx_status,
            tx_error_message
        )
        VALUES (
            v_source_record.id_source,
            COALESCE(v_file_path, 'UNKNOWN'),
            CURRENT_TIMESTAMP,
            0,
            'ERROR',
            SQLERRM
        );
    END IF;
    
    -- Log de l'erreur avec plus de détails
    RAISE NOTICE 'Erreur lors du chargement:';
    RAISE NOTICE '- Message: %', SQLERRM;
    RAISE NOTICE '- Fichier: %', v_file_path;
    
    PERFORM utils.log_script_execution(
        'load_raw_real_estate_sector', 
        'ERROR',
        format('Erreur: %s. Durée: %s minutes', 
               SQLERRM,
               EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_start_time))/60)
    );
    RAISE;
END;
$$;

COMMENT ON PROCEDURE raw_staging.load_raw_real_estate_sector(INTEGER, BOOLEAN) IS 
'Procédure de chargement initial des données de transactions immobilières.
Utilise les paramètres définis dans metadata.dim_source pour la source IMMO_SECTOR.
Cherche automatiquement le fichier le plus récent correspondant au pattern dans le répertoire.

Arguments :
- p_batch_id : ID du batch de chargement
- p_delete_existing : Si TRUE, supprime les données existantes du même batch

Format attendu du CSV :
- CD_STAT_SECTOR : Code du secteur statistique
- CD_YEAR : Année
- CD_TYPE : Type de bien (B001, B002, etc.)
- CD_TYPE_NL : Description en néerlandais
- CD_TYPE_FR : Description en français
- MS_TRANSACTIONS : Nombre de transactions
- MS_P25 : Prix 25e percentile
- MS_P50 (MEDIAN_PRICE) : Prix médian
- MS_P75 : Prix 75e percentile
- MS_P10 : Prix 10e percentile
- MS_P90 : Prix 90e percentile';