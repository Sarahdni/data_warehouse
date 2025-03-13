-- 01_staging/procedures/load_ref_nacebel.sql

-- Drop de l'ancienne procédure
DROP PROCEDURE IF EXISTS staging.load_ref_nacebel(TEXT, BOOLEAN);

CREATE OR REPLACE PROCEDURE staging.load_ref_nacebel(
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
    v_temp_table_name TEXT;
BEGIN
    -- Enregistrer l'heure de début
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Récupérer les informations de la source et le chemin complet
    SELECT id_source, tx_file_path 
    INTO v_source_id, v_file_path
    FROM metadata.dim_source 
    WHERE cd_source = 'NACEBEL_2008'
    AND fl_active = TRUE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source NACEBEL_2008 non trouvée ou inactive';
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
        TRUNCATE TABLE staging.stg_ref_nacebel;
    END IF;

    -- Créer une table temporaire pour le chargement initial
    v_temp_table_name := 'temp_nacebel_' || v_file_history_id;
    
    EXECUTE format('CREATE TEMP TABLE %I (
        LVL_NACEBEL INTEGER,
        CD_NACEBEL VARCHAR(10),
        CD_SUP_NACEBEL VARCHAR(10),
        TX_NACEBEL_DE TEXT,
        TX_NACEBEL_EN TEXT,
        TX_NACEBEL_FR TEXT,
        TX_NACEBEL_NL TEXT,
        DT_VLDT_START TEXT,
        DT_VLDT_END TEXT
    )', v_temp_table_name);

    -- Charger les données brutes dans la table temporaire
    EXECUTE format('COPY %I FROM %L WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER '',''
    )', v_temp_table_name, v_file_path);

    -- Insérer les données dans la table de staging avec conversion de dates
    EXECUTE format('
        INSERT INTO staging.stg_ref_nacebel (
            LVL_NACEBEL,
            CD_NACEBEL,
            CD_SUP_NACEBEL,
            TX_NACEBEL_DE,
            TX_NACEBEL_EN,
            TX_NACEBEL_FR,
            TX_NACEBEL_NL,
            DT_VLDT_START,
            DT_VLDT_END
        )
        SELECT 
            LVL_NACEBEL,
            CD_NACEBEL,
            NULLIF(CD_SUP_NACEBEL, ''-''),
            TX_NACEBEL_DE,
            TX_NACEBEL_EN,
            TX_NACEBEL_FR,
            TX_NACEBEL_NL,
            TO_DATE(DT_VLDT_START, ''DD/MM/YYYY''),
            TO_DATE(DT_VLDT_END, ''DD/MM/YYYY'')
        FROM %I', v_temp_table_name);

    -- Récupérer le nombre de lignes chargées
    GET DIAGNOSTICS v_rows_loaded = ROW_COUNT;

    -- Mettre à jour l'ID du lot pour les lignes chargées
    UPDATE staging.stg_ref_nacebel
    SET id_batch = v_file_history_id
    WHERE id_batch IS NULL;

    -- Supprimer la table temporaire
    EXECUTE format('DROP TABLE %I', v_temp_table_name);

    -- Mettre à jour l'historique des fichiers
    UPDATE metadata.source_file_history 
    SET dt_processed = CURRENT_TIMESTAMP,
        nb_rows_processed = v_rows_loaded,
        tx_status = 'SUCCESS'
    WHERE id_file_history = v_file_history_id;

    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_ref_nacebel.sql',
        'SUCCESS',
        format('Chargement terminé. %s lignes chargées.', v_rows_loaded)
    );

EXCEPTION WHEN OTHERS THEN
    -- Nettoyer la table temporaire en cas d'erreur
    IF v_temp_table_name IS NOT NULL THEN
        EXECUTE format('DROP TABLE IF EXISTS %I', v_temp_table_name);
    END IF;

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
        'load_ref_nacebel.sql',
        'ERROR',
        SQLERRM
    );

    -- Relancer l'erreur
    RAISE;
END;
$$;

COMMENT ON PROCEDURE staging.load_ref_nacebel(TEXT, BOOLEAN) IS 
'Procédure de chargement des codes NACEBEL dans la table de staging.
Arguments:
- p_filename: nom du fichier CSV (doit être dans le répertoire configuré dans dim_source)
- p_truncate: si TRUE, vide la table avant le chargement (défaut: TRUE)

Exemple:
CALL staging.load_ref_nacebel(''ref_nacebel_2008.csv'', TRUE);';