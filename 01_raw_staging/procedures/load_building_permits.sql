-- 01_staging/procedures/load_building_permits.sql

CREATE OR REPLACE PROCEDURE staging.load_building_permits(
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
    WHERE cd_source = 'BUILDING_PERMITS'
    AND fl_active = TRUE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source BUILDING_PERMITS non trouvée ou inactive';
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
        TRUNCATE TABLE staging.stg_building_permits;
    END IF;

    -- Créer une table temporaire pour le chargement initial
    CREATE TEMP TABLE tmp_building_permits (
        REFNIS VARCHAR(20),
        REFNIS_NL VARCHAR(100),
        REFNIS_FR VARCHAR(100),
        CD_YEAR INTEGER,
        CD_PERIOD INTEGER,
        MS_BUILDING_RES_NEW NUMERIC,
        MS_DWELLING_RES_NEW NUMERIC,
        MS_APARTMENT_RES_NEW NUMERIC,
        MS_SINGLE_HOUSE_RES_NEW NUMERIC,
        MS_TOTAL_SURFACE_RES_NEW NUMERIC,
        MS_BUILDING_RES_RENOVATION NUMERIC,
        MS_BUILDING_NONRES_NEW NUMERIC,
        MS_VOLUME_NONRES_NEW NUMERIC,
        MS_BUILDING_NONRES_RENOVATION NUMERIC,
        CD_REFNIS_NATION VARCHAR(20),
        CD_REFNIS_REGION VARCHAR(20),
        CD_REFNIS_PROVINCE VARCHAR(20),
        CD_REFNIS_DISTRICT VARCHAR(20),
        CD_REFNIS_MUNICIPALITY VARCHAR(20),
        CD_REFNIS_LEVEL INTEGER
    );

    -- Construire et exécuter la commande COPY
    v_copy_cmd := format('COPY tmp_building_permits FROM %L WITH (FORMAT csv, HEADER true, DELIMITER '','')', v_file_path);
    EXECUTE v_copy_cmd;

    -- Insérer dans la table de staging avec formatage du REFNIS
    INSERT INTO staging.stg_building_permits (
        REFNIS,
        REFNIS_NL,
        REFNIS_FR,
        CD_YEAR,
        CD_PERIOD,
        MS_BUILDING_RES_NEW,
        MS_DWELLING_RES_NEW,
        MS_APARTMENT_RES_NEW,
        MS_SINGLE_HOUSE_RES_NEW,
        MS_TOTAL_SURFACE_RES_NEW,
        MS_BUILDING_RES_RENOVATION,
        MS_BUILDING_NONRES_NEW,
        MS_VOLUME_NONRES_NEW,
        MS_BUILDING_NONRES_RENOVATION,
        CD_REFNIS_NATION,
        CD_REFNIS_REGION,
        CD_REFNIS_PROVINCE,
        CD_REFNIS_DISTRICT,
        CD_REFNIS_MUNICIPALITY,
        CD_REFNIS_LEVEL
    )
    SELECT 
        LPAD(REFNIS, 5, '0'),
        REFNIS_NL,
        REFNIS_FR,
        CD_YEAR,
        CD_PERIOD,
        MS_BUILDING_RES_NEW,
        MS_DWELLING_RES_NEW,
        MS_APARTMENT_RES_NEW,
        MS_SINGLE_HOUSE_RES_NEW,
        MS_TOTAL_SURFACE_RES_NEW,
        MS_BUILDING_RES_RENOVATION,
        MS_BUILDING_NONRES_NEW,
        MS_VOLUME_NONRES_NEW,
        MS_BUILDING_NONRES_RENOVATION,
        CD_REFNIS_NATION,
        CD_REFNIS_REGION,
        CD_REFNIS_PROVINCE,
        CD_REFNIS_DISTRICT,
        CD_REFNIS_MUNICIPALITY,
        CD_REFNIS_LEVEL
    FROM tmp_building_permits;

    -- Récupérer le nombre de lignes chargées
    GET DIAGNOSTICS v_rows_loaded = ROW_COUNT;

    -- Mettre à jour l'ID du batch
    UPDATE staging.stg_building_permits
    SET id_batch = v_file_history_id
    WHERE id_batch IS NULL;

    -- Nettoyer la table temporaire
    DROP TABLE tmp_building_permits;

    -- Mettre à jour l'historique
    UPDATE metadata.source_file_history 
    SET dt_processed = CURRENT_TIMESTAMP,
        nb_rows_processed = v_rows_loaded,
        tx_status = 'SUCCESS'
    WHERE id_file_history = v_file_history_id;

    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_building_permits.sql',
        'SUCCESS',
        format('Chargement terminé. %s lignes chargées.', v_rows_loaded)
    );

EXCEPTION WHEN OTHERS THEN
    -- Nettoyer la table temporaire en cas d'erreur
    DROP TABLE IF EXISTS tmp_building_permits;
    
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
        'load_building_permits.sql',
        'ERROR',
        SQLERRM
    );

    -- Relancer l'erreur
    RAISE;
END;
$$;

COMMENT ON PROCEDURE staging.load_building_permits(TEXT, BOOLEAN) IS 
'Procédure de chargement des données de permis de construire dans la table de staging.
Arguments:
- p_filename: nom du fichier CSV (doit être dans le répertoire configuré dans dim_source)
- p_truncate: si TRUE, vide la table avant le chargement (défaut: TRUE)

Exemple:
CALL staging.load_building_permits(''TF_BUILDING_PERMITS_1996_2024.csv'', TRUE);';