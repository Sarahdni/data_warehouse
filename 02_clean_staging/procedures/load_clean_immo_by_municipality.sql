-- 02_clean_staging/procedures/load_clean_immo_by_municipality.sql

\echo 'Starting load_clean_immo_by_municipality.sql...'

-- Log du début d'exécution
DO $$ 
BEGIN 
    PERFORM utils.log_script_execution('load_clean_immo_by_municipality.sql', 'RUNNING');
END $$;

CREATE OR REPLACE PROCEDURE clean_staging.load_clean_immo_by_municipality(
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
    WHERE cd_source = 'IMMO_MUN';
    
    -- Log du début
    PERFORM utils.log_script_execution('load_clean_immo_by_municipality', 'RUNNING');

    -- Suppression des données existantes si demandé
    IF p_truncate THEN
        TRUNCATE TABLE clean_staging.clean_immo_by_municipality;
        RAISE NOTICE 'Table clean_immo_by_municipality tronquée';
    END IF;

    -- Insertion des données depuis raw_staging
    INSERT INTO clean_staging.clean_immo_by_municipality (
        -- Clés et identifiants
        cd_year,
        cd_period,
        cd_refnis,
        
        -- Descriptions multilingues
        tx_property_type_nl,
        tx_property_type_fr,
        tx_municipality_nl,
        tx_municipality_fr,
        
        -- Mesures nettoyées
        ms_total_transactions,
        ms_total_price,
        ms_total_surface,
        ms_mean_price,
        ms_price_p10,
        ms_price_p25,
        ms_price_p50,
        ms_price_p75,
        ms_price_p90,
        
        -- Traçabilité
        id_batch
    )
    SELECT
        -- Conversion et nettoyage des clés
        NULLIF(REGEXP_REPLACE(cd_year, '[^0-9]', '', 'g'), '')::INTEGER,
        cd_period,
        CASE 
            WHEN LENGTH(TRIM(cd_refnis)) = 5 THEN TRIM(cd_refnis)
            WHEN LENGTH(TRIM(cd_refnis)) < 5 THEN LPAD(TRIM(cd_refnis), 5, '0')
            ELSE SUBSTRING(TRIM(cd_refnis), 1, 5)
        END as cd_refnis,
        
        -- Nettoyage des libellés
        utils.fix_encoding(TRIM(cd_type_nl)),
        utils.fix_encoding(TRIM(cd_type_fr)),
        utils.fix_encoding(TRIM(cd_refnis_nl)),
        utils.fix_encoding(TRIM(cd_refnis_fr)),
        
        -- Conversion et nettoyage des mesures
        NULLIF(REGEXP_REPLACE(ms_total_transactions, '[^0-9]', '', 'g'), '')::INTEGER,
        NULLIF(REGEXP_REPLACE(ms_total_price, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_total_surface, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_mean_price, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_p10, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_p25, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_p50, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_p75, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_p90, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        
        p_batch_id
    FROM raw_staging.raw_immo_by_municipality
    WHERE id_batch = p_batch_id
    AND EXISTS (
        SELECT 1 
        FROM dw.dim_geography g
        WHERE g.cd_refnis = CASE 
            WHEN LENGTH(TRIM(r.cd_refnis)) = 5 THEN TRIM(r.cd_refnis)
            WHEN LENGTH(TRIM(r.cd_refnis)) < 5 THEN LPAD(TRIM(r.cd_refnis), 5, '0')
            ELSE SUBSTRING(TRIM(r.cd_refnis), 1, 5)
        END
        AND g.fl_current = TRUE
        AND g.cd_level = 4  -- Niveau communal
    );
    AND cd_class_surface = 'totaal / total';  -- Ne prendre que les totaux

    GET DIAGNOSTICS v_count = ROW_COUNT;
    
    -- Validation des données chargées
    CALL clean_staging.validate_clean_immo_by_municipality(
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
        'load_clean_immo_by_municipality',
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
        'load_clean_immo_by_municipality',
        'ERROR',
        v_error_message
    );
    RAISE;
END;
$$;

-- Ajout des commentaires sur la procédure
COMMENT ON PROCEDURE clean_staging.load_clean_immo_by_municipality(INTEGER, BOOLEAN) IS 
'Procédure de chargement des données immobilières depuis raw_staging vers clean_staging.

Cette procédure :
1. Charge les données depuis raw_staging
2. Nettoie et standardise les formats
3. Convertit les types de données
4. Valide les données chargées
5. Enregistre les résultats dans l''historique

Arguments :
- p_batch_id : ID du batch à charger
- p_truncate : Si TRUE, vide la table avant chargement (défaut: FALSE)

Exemple d''utilisation :
CALL clean_staging.load_clean_immo_by_municipality(123, FALSE);';

-- Log du succès de la création
DO $$ 
BEGIN 
    PERFORM utils.log_script_execution('load_clean_immo_by_municipality.sql', 'SUCCESS');
END $$;

\echo 'Finished load_clean_immo_by_municipality.sql successfully.'