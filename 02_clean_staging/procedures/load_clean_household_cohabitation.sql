-- 02_clean_staging/procedures/load_clean_household_cohabitation.sql

\echo 'Starting load_clean_household_cohabitation.sql...'

-- Log du début d'exécution
DO $$ 
BEGIN 
    PERFORM utils.log_script_execution('load_clean_household_cohabitation.sql', 'RUNNING');
END $$;

-- Suppression de la procédure si elle existe déjà
DROP PROCEDURE IF EXISTS clean_staging.load_clean_household_cohabitation;

CREATE OR REPLACE PROCEDURE clean_staging.load_clean_household_cohabitation(
    p_batch_id INTEGER,
    p_truncate BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_count INTEGER;
    v_error_message TEXT;
    v_source_id INTEGER;
BEGIN
    -- Enregistrer l'heure de début
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Récupérer l'id de la source
    SELECT id_source INTO v_source_id 
    FROM metadata.dim_source 
    WHERE cd_source = 'COHAB_POP';
    
    -- Log du début
    PERFORM utils.log_script_execution('load_clean_household_cohabitation', 'RUNNING');

    -- Suppression des données existantes si demandé
    IF p_truncate THEN
        TRUNCATE TABLE clean_staging.clean_household_cohabitation;
        RAISE NOTICE 'Table clean_household_cohabitation tronquée';
    END IF;

    -- Insertion des données depuis raw_staging
    INSERT INTO clean_staging.clean_household_cohabitation (
        -- Clés et identifiants
        cd_year,
        cd_rgn_refnis,
        tx_rgn_descr_nl,
        tx_rgn_descr_fr,
        
        -- Caractéristiques démographiques
        cd_sex,
        cd_age,
        cd_natlty,
        tx_natlty_nl,
        tx_natlty_fr,
        
        -- Statut de cohabitation
        fl_cohab,
        tx_cohab_nl,
        tx_cohab_fr,
        
        -- Mesures
        ms_count,
        
        -- Traçabilité
        id_batch
    )
    SELECT
        cd_year::INTEGER,
        cd_rgn_refnis,
        utils.fix_encoding(tx_rgn_descr_nl),
        utils.fix_encoding(tx_rgn_descr_fr),
        cd_sex,
        cd_age,
        cd_natlty,
        utils.fix_encoding(tx_natlty_nl),
        utils.fix_encoding(tx_natlty_fr),
        fl_cohab::BOOLEAN,
        utils.fix_encoding(tx_cohab_nl),
        utils.fix_encoding(tx_cohab_fr),
        NULLIF(REGEXP_REPLACE(ms_count, '[^0-9]', '', 'g'), '')::INTEGER,
        p_batch_id
    FROM raw_staging.raw_household_cohabitation
    WHERE id_batch = p_batch_id;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    
    -- Validation initiale des données chargées
    CALL clean_staging.validate_clean_household_cohabitation(
        p_batch_id := p_batch_id,
        p_raise_exception := FALSE
    );

    -- Enregistrement des résultats dans l'historique
    INSERT INTO metadata.source_file_history (
        id_source,
        tx_filename,
        dt_processed,
        nb_rows_processed,
        tx_status
    ) VALUES (
        v_source_id,
        'batch_' || p_batch_id::text,
        CURRENT_TIMESTAMP,
        v_count,
        'SUCCESS'
    );

    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_clean_household_cohabitation',
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
        v_source_id,
        'batch_' || p_batch_id::text,
        CURRENT_TIMESTAMP,
        0,
        'ERROR',
        v_error_message
    );

    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'load_clean_household_cohabitation',
        'ERROR',
        v_error_message
    );
    RAISE;
END;
$$;

-- Ajout des commentaires sur la procédure
COMMENT ON PROCEDURE clean_staging.load_clean_household_cohabitation(INTEGER, BOOLEAN) IS 
'Procédure de chargement des données de cohabitation depuis raw_staging vers clean_staging.

Cette procédure :
1. Charge les données depuis raw_staging
2. Effectue les conversions de types nécessaires
3. Nettoie l''encodage des chaînes de caractères
4. Valide les données chargées
5. Enregistre les résultats dans l''historique

Arguments :
- p_batch_id : ID du batch à charger
- p_truncate : Si TRUE, vide la table avant chargement (défaut: FALSE)

Exemple d''utilisation :
CALL clean_staging.load_clean_household_cohabitation(123, FALSE);';

-- Log du succès de la création
DO $$ 
BEGIN 
    PERFORM utils.log_script_execution('load_clean_household_cohabitation.sql', 'SUCCESS');
END $$;

\echo 'Finished load_clean_household_cohabitation.sql successfully.'