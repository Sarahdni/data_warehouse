-- 01_raw_staging/procedures/load_raw_immo_by_municipality.sql

\echo 'Starting load_raw_immo_by_municipality.sql...'

-- Log du début d'exécution
DO $$ 
BEGIN 
    PERFORM utils.log_script_execution('load_raw_immo_by_municipality.sql', 'RUNNING');
END $$;

-- Suppression de la procédure si elle existe déjà
DROP PROCEDURE IF EXISTS raw_staging.load_raw_immo_by_municipality;

CREATE OR REPLACE PROCEDURE raw_staging.load_raw_immo_by_municipality(
    p_source_id INTEGER,
    p_truncate BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_count INTEGER;
    v_error_message TEXT;
    v_file_path TEXT;
    v_batch_id INTEGER;
BEGIN
    -- Récupérer le chemin complet du fichier depuis dim_source
    SELECT tx_file_path || tx_file_pattern 
    INTO v_file_path
    FROM metadata.dim_source 
    WHERE id_source = p_source_id;

    IF v_file_path IS NULL THEN
        RAISE EXCEPTION 'Source id % non trouvée dans dim_source', p_source_id;
    END IF;

    -- Générer un nouveau batch_id
    SELECT COALESCE(MAX(id_batch), 0) + 1 
    INTO v_batch_id 
    FROM raw_staging.raw_immo_by_municipality;

    -- Vider la table si demandé
    IF p_truncate THEN
        TRUNCATE TABLE raw_staging.raw_immo_by_municipality;
        RAISE NOTICE 'Table raw_immo_by_municipality tronquée';
    END IF;

    -- Insertion des données
    BEGIN
        EXECUTE format('
            COPY raw_staging.raw_immo_by_municipality (
                cd_year,
                cd_type_nl,
                cd_type_fr,
                cd_refnis,
                cd_refnis_nl,
                cd_refnis_fr,
                cd_period,
                cd_class_surface,
                ms_total_transactions,
                ms_total_price,
                ms_total_surface,
                ms_mean_price,
                ms_p10,
                ms_p25,
                ms_p50,
                ms_p75,
                ms_p90
            ) FROM %L WITH (
                FORMAT CSV,
                HEADER true,
                DELIMITER %L,
                ENCODING %L
            )', 
            v_file_path, 
            ',',
            'UTF-8'
        );

        GET DIAGNOSTICS v_count = ROW_COUNT;

        -- Mise à jour de l'id_batch
        UPDATE raw_staging.raw_immo_by_municipality
        SET id_batch = v_batch_id
        WHERE id_batch IS NULL;

        -- Enregistrement dans l'historique
        INSERT INTO metadata.source_file_history (
            id_source,
            tx_filename,
            dt_processed,
            nb_rows_processed,
            tx_status
        ) VALUES (
            p_source_id,
            v_file_path,
            CURRENT_TIMESTAMP,
            v_count,
            'SUCCESS'
        );

        -- Log du succès
        PERFORM utils.log_script_execution(
            'load_raw_immo_by_municipality',
            'SUCCESS',
            format('Chargement terminé. %s lignes chargées.', v_count)
        );

    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
        
        -- Enregistrement de l'erreur
        INSERT INTO metadata.source_file_history (
            id_source,
            tx_filename,
            dt_processed,
            nb_rows_processed,
            tx_status,
            tx_error_message
        ) VALUES (
            p_source_id,
            v_file_path,
            CURRENT_TIMESTAMP,
            0,
            'ERROR',
            v_error_message
        );

        -- Log de l'erreur
        PERFORM utils.log_script_execution(
            'load_raw_immo_by_municipality',
            'ERROR',
            v_error_message
        );
        
        RAISE;
    END;
END;
$$;

-- Ajout des commentaires sur la procédure
COMMENT ON PROCEDURE raw_staging.load_raw_immo_by_municipality(INTEGER, BOOLEAN) IS 
'Procédure de chargement des données immobilières par commune dans la table raw_staging.

Arguments :
- p_source_id : ID de la source dans metadata.dim_source
- p_truncate : Si TRUE, vide la table avant chargement (défaut: FALSE)

Exemple d''utilisation :
CALL raw_staging.load_raw_immo_by_municipality(183, FALSE);';

-- Log du succès de la création
DO $$ 
BEGIN 
    PERFORM utils.log_script_execution('load_raw_immo_by_municipality.sql', 'SUCCESS');
END $$;

\echo 'Finished load_raw_immo_by_municipality.sql successfully.'