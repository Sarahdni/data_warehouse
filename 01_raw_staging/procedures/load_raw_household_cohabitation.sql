-- 01_raw_staging/procedures/load_raw_household_cohabitation.sql

-- Log du début d'exécution
DO $$ 
BEGIN 
    PERFORM utils.log_script_execution('load_raw_household_cohabitation.sql', 'RUNNING');
END $$;

-- Création de la procédure
DROP PROCEDURE IF EXISTS raw_staging.load_raw_household_cohabitation;

CREATE OR REPLACE PROCEDURE raw_staging.load_raw_household_cohabitation(
    p_filename TEXT,
    p_truncate BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_source_id INTEGER;
    v_file_path TEXT;
    v_file_history_id INTEGER;
    v_rows_loaded INTEGER;
    v_copy_cmd TEXT;
BEGIN
    -- Enregistrer l'heure de début
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Récupérer les informations de la source
    SELECT id_source, tx_file_path 
    INTO v_source_id, v_file_path
    FROM metadata.dim_source 
    WHERE cd_source = 'COHAB_POP'
    AND fl_active = TRUE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source COHAB_POP non trouvée ou inactive';
    END IF;

    -- Construire le chemin complet
    v_file_path := v_file_path || p_filename;

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

    -- Vider la table si demandé
    IF p_truncate THEN
        TRUNCATE TABLE raw_staging.raw_household_cohabitation;
    END IF;

    -- Créer une table temporaire pour le chargement initial
    CREATE TEMP TABLE tmp_household_cohabitation (
        cd_year VARCHAR(4),
        cd_rgn_refnis VARCHAR(4),
        tx_rgn_descr_nl VARCHAR(100),
        tx_rgn_descr_fr VARCHAR(100),
        cd_sex CHAR(1),
        cd_age VARCHAR(10),
        cd_natlty VARCHAR(10),
        tx_natlty_nl VARCHAR(100),
        tx_natlty_fr VARCHAR(100),
        fl_cohab VARCHAR(1),
        tx_cohab_nl VARCHAR(100),
        tx_cohab_fr VARCHAR(100),
        ms_count VARCHAR(20)
    );

    -- Construire et exécuter la commande COPY
    v_copy_cmd := format('COPY tmp_household_cohabitation FROM %L WITH (FORMAT csv, HEADER true, DELIMITER '','')', v_file_path);
    EXECUTE v_copy_cmd;

    -- Insérer dans la table de staging
    INSERT INTO raw_staging.raw_household_cohabitation (
        cd_year,
        cd_rgn_refnis,
        tx_rgn_descr_nl,
        tx_rgn_descr_fr,
        cd_sex,
        cd_age,
        cd_natlty,
        tx_natlty_nl,
        tx_natlty_fr,
        fl_cohab,
        tx_cohab_nl,
        tx_cohab_fr,
        ms_count,
        id_batch
    )
    SELECT 
        cd_year,
        cd_rgn_refnis,
        tx_rgn_descr_nl,
        tx_rgn_descr_fr,
        cd_sex,
        cd_age,
        cd_natlty,
        tx_natlty_nl,
        tx_natlty_fr,
        fl_cohab,
        tx_cohab_nl,
        tx_cohab_fr,
        ms_count,
        v_file_history_id
    FROM tmp_household_cohabitation;

    -- Récupérer le nombre de lignes chargées
    GET DIAGNOSTICS v_rows_loaded = ROW_COUNT;

    -- Nettoyer la table temporaire
    DROP TABLE tmp_household_cohabitation;

    -- Mettre à jour l'historique
    UPDATE metadata.source_file_history 
    SET dt_processed = CURRENT_TIMESTAMP,
        nb_rows_processed = v_rows_loaded,
        tx_status = 'SUCCESS'
    WHERE id_file_history = v_file_history_id;

    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_raw_household_cohabitation',
        'SUCCESS',
        format('Chargement terminé. %s lignes chargées.', v_rows_loaded)
    );

EXCEPTION WHEN OTHERS THEN
    -- Nettoyer la table temporaire en cas d'erreur
    DROP TABLE IF EXISTS tmp_household_cohabitation;
    
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
        'load_raw_household_cohabitation',
        'ERROR',
        SQLERRM
    );
    
    RAISE;
END;
$$;

-- Log du succès de la création
DO $$ 
BEGIN 
    PERFORM utils.log_script_execution('load_raw_household_cohabitation.sql', 'SUCCESS');
END $$;


COMMENT ON PROCEDURE raw_staging.load_raw_household_cohabitation(TEXT, BOOLEAN) IS 
'Procédure de chargement des données brutes de cohabitation depuis un fichier CSV.

Arguments:
- p_filename: nom du fichier CSV (doit être dans le répertoire configuré dans dim_source pour COHAB_POP)
- p_truncate: si TRUE, vide la table avant le chargement (défaut: TRUE)

Exemple:
CALL raw_staging.load_raw_household_cohabitation(''TF_COHAB_POP_2001_2024.csv'', TRUE);';