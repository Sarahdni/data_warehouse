-- Drop de l'ancienne procédure
DROP PROCEDURE IF EXISTS staging.load_ref_nuts_lau(TEXT, BOOLEAN);

CREATE OR REPLACE PROCEDURE staging.load_ref_nuts_lau(
    p_filename TEXT,                    -- Nom du fichier seulement
    p_truncate BOOLEAN DEFAULT TRUE     -- Option pour vider la table avant chargement
)
LANGUAGE plpgsql AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_source_id INTEGER;
    v_file_path TEXT;
    v_batch_id INTEGER;
    v_rows_loaded INTEGER;
    v_file_history_id INTEGER;
    v_copy_sql TEXT;
BEGIN
    -- Enregistrer l'heure de début
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Récupérer les informations de la source et le chemin complet
    SELECT id_source, tx_file_path 
    INTO v_source_id, v_file_path
    FROM metadata.dim_source 
    WHERE cd_source = 'NUTS_LAU'
    AND fl_active = TRUE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source NUTS_LAU non trouvée ou inactive';
    END IF;

    -- Construire le chemin complet
    v_file_path := v_file_path || p_filename;

    -- Créer une entrée dans l'historique des fichiers
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

    -- Vider la table si demandé
    IF p_truncate THEN
        TRUNCATE TABLE staging.stg_ref_nuts_lau;
    END IF;

    -- Construire et exécuter la commande COPY dynamiquement
    v_copy_sql := format('COPY staging.stg_ref_nuts_lau (
        CD_LAU,
        CD_MUNTY_REFNIS,
        TX_DESCR_DE,
        TX_DESCR_EN,
        TX_DESCR_FR,
        TX_DESCR_NL,
        DT_VLDT_STRT,
        DT_VLDT_STOP,
        CD_LVL_SUP,
        CD_LVL
    ) FROM %L 
    WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER '',''
    )', v_file_path);

    EXECUTE v_copy_sql;

    -- Récupérer le nombre de lignes chargées
    GET DIAGNOSTICS v_rows_loaded = ROW_COUNT;

    -- Mettre à jour l'ID du lot pour les lignes chargées
    UPDATE staging.stg_ref_nuts_lau
    SET id_batch = v_file_history_id
    WHERE id_batch IS NULL;

    -- Mettre à jour l'historique des fichiers
    UPDATE metadata.source_file_history 
    SET dt_processed = CURRENT_TIMESTAMP,
        nb_rows_processed = v_rows_loaded,
        tx_status = 'SUCCESS'
    WHERE id_file_history = v_file_history_id;

    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_ref_nuts_lau.sql',
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
        'load_ref_nuts_lau.sql',
        'ERROR',
        SQLERRM
    );

    -- Relancer l'erreur
    RAISE;
END;
$$;

COMMENT ON PROCEDURE staging.load_ref_nuts_lau(TEXT, BOOLEAN) IS 
'Procédure de chargement des codes NUTS/LAU dans la table de staging.
Arguments:
- p_filename: nom du fichier CSV (doit être dans le répertoire configuré dans dim_source)
- p_truncate: si TRUE, vide la table avant le chargement (défaut: TRUE)

Exemple:
CALL staging.load_ref_nuts_lau(''TU_COM_NUTS_LAU-2023.csv'', TRUE);';