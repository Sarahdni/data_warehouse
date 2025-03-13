-- 01_raw_staging/procedures/load_raw_building_stock.sql

CREATE OR REPLACE PROCEDURE raw_staging.load_raw_building_stock(
    p_id_source INTEGER,
    p_delete_existing BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_file_path TEXT;
    v_file_pattern TEXT;
    v_delimiter CHAR(1);
    v_file_history_id INTEGER;
    v_rows_loaded INTEGER;
    v_copy_sql TEXT;
BEGIN
    -- Enregistrer l'heure de début
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Récupérer les informations du fichier
    SELECT tx_file_path, tx_file_pattern, COALESCE(tx_delimiter, ',')
    INTO v_file_path, v_file_pattern, v_delimiter
    FROM metadata.dim_source 
    WHERE id_source = p_id_source
    AND fl_active = TRUE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source ID % non trouvée ou inactive', p_id_source;
    END IF;

    -- Construire le chemin complet
    v_file_path := v_file_path || '/' || v_file_pattern;

    -- Créer une entrée dans l'historique
    INSERT INTO metadata.source_file_history (
        id_source,
        tx_filename,
        dt_processed,
        tx_status
    ) VALUES (
        p_id_source,
        v_file_pattern,
        v_start_time,
        'RUNNING'
    ) RETURNING id_file_history INTO v_file_history_id;

    -- Supprimer les données existantes si demandé
    IF p_delete_existing THEN
        DELETE FROM raw_staging.raw_building_stock 
        USING metadata.source_file_history h
        WHERE raw_building_stock.id_batch = h.id_file_history
        AND h.id_source = p_id_source;
    END IF;

    -- Construire et exécuter la commande COPY
    v_copy_sql := format('COPY raw_staging.raw_building_stock (
        CD_YEAR,
        CD_REFNIS,
        TX_REFNIS_NL,
        TX_REFNIS_FR,
        CD_REFNIS_LVL,
        CD_STAT_TYPE,
        TX_STAT_TYPE_NL,
        TX_STAT_TYPE_FR,
        CD_BUILDING_TYPE,
        TX_BUILDING_TYPE_NL,
        TX_BUILDING_TYPE_FR,
        MS_VALUE
    ) FROM %L WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER %L
    )', v_file_path, v_delimiter);

    EXECUTE v_copy_sql;

    -- Récupérer le nombre de lignes chargées
    GET DIAGNOSTICS v_rows_loaded = ROW_COUNT;

    -- Mettre à jour l'ID du batch
    UPDATE raw_staging.raw_building_stock
    SET id_batch = v_file_history_id
    WHERE id_batch IS NULL;

    -- Mettre à jour l'historique
    UPDATE metadata.source_file_history 
    SET dt_processed = CURRENT_TIMESTAMP,
        nb_rows_processed = v_rows_loaded,
        tx_status = 'SUCCESS'
    WHERE id_file_history = v_file_history_id;

    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_raw_building_stock.sql',
        'SUCCESS',
        format('Chargement terminé. %s lignes chargées.', v_rows_loaded)
    );

EXCEPTION WHEN OTHERS THEN
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
        'load_raw_building_stock.sql',
        'ERROR',
        SQLERRM
    );

    -- Relancer l'erreur
    RAISE;
END;
$$;

COMMENT ON PROCEDURE raw_staging.load_raw_building_stock(INTEGER, BOOLEAN) IS 
'Procédure de chargement des données du parc immobilier dans la table de staging.
Arguments:
- p_id_source: ID de la source dans metadata.dim_source
- p_delete_existing: si TRUE, supprime les données existantes pour cette source avant le chargement (défaut: FALSE)

Exemple:
CALL raw_staging.load_raw_building_stock(183);  -- Pour charger les données de 1995 sans supprimer
CALL raw_staging.load_raw_building_stock(184, TRUE);  -- Pour charger les données de 1998 avec suppression';