-- 01_staging/validation/validate_building_stock.sql

CREATE OR REPLACE PROCEDURE staging.validate_building_stock(
    p_batch_id INTEGER,                    
    p_raise_exception BOOLEAN DEFAULT TRUE  
)
LANGUAGE plpgsql AS $$
DECLARE
    v_error_count INTEGER := 0;
    v_error_message TEXT;
    v_start_time TIMESTAMP;
BEGIN
    -- Enregistrer l'heure de début
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Log du début de la validation
    PERFORM utils.log_script_execution('validate_building_stock.sql', 'RUNNING');

    -- Table temporaire pour stocker les erreurs
    CREATE TEMP TABLE tmp_validation_errors (
        error_type VARCHAR(50),
        error_message TEXT,
        affected_rows INTEGER
    );

    -- 1. Validation des champs obligatoires
    INSERT INTO tmp_validation_errors
    SELECT 
        'MISSING_REQUIRED_FIELDS',
        'Champs obligatoires manquants',
        COUNT(*)
    FROM staging.stg_building_stock
    WHERE id_batch = p_batch_id
    AND (CD_YEAR IS NULL 
        OR CD_REFNIS IS NULL 
        OR CD_STAT_TYPE IS NULL
        OR CD_BUILDING_TYPE IS NULL
        OR MS_VALUE IS NULL);

    -- 2. Validation du format REFNIS (modifié)
    INSERT INTO tmp_validation_errors
    SELECT 
        'INVALID_REFNIS_FORMAT',
        'Format de code REFNIS invalide',
        COUNT(*)
    FROM staging.stg_building_stock
    WHERE id_batch = p_batch_id
    AND CD_REFNIS IS NOT NULL
    AND NOT utils.validate_refnis(CD_REFNIS);

    -- 3. Validation des années
    INSERT INTO tmp_validation_errors
    SELECT 
        'INVALID_YEAR',
        'Année invalide (doit être >= 2000)',
        COUNT(*)
    FROM staging.stg_building_stock
    WHERE id_batch = p_batch_id
    AND CD_YEAR < 2000;

    -- 4. Validation des types de bâtiment
    INSERT INTO tmp_validation_errors
    SELECT 
        'INVALID_BUILDING_TYPE',
        'Type de bâtiment invalide',
        COUNT(*)
    FROM staging.stg_building_stock
    WHERE id_batch = p_batch_id
    AND CD_BUILDING_TYPE NOT IN ('R1', 'R2', 'R3', 'R4', 'R5', 'R6');

    -- 5. Validation des valeurs numériques
    INSERT INTO tmp_validation_errors
    SELECT 
        'NEGATIVE_VALUES',
        'Valeurs numériques négatives détectées',
        COUNT(*)
    FROM staging.stg_building_stock
    WHERE id_batch = p_batch_id
    AND MS_VALUE < 0;

    -- Compter le nombre total d'erreurs
    SELECT COUNT(*), string_agg(error_type || ': ' || affected_rows || ' rows', E'\n')
    INTO v_error_count, v_error_message
    FROM tmp_validation_errors
    WHERE affected_rows > 0;

    -- Enregistrer les résultats de la validation
    INSERT INTO metadata.validation_log (
        nm_procedure,
        id_batch,
        dt_validation,
        nb_errors,
        tx_error_message
    ) VALUES (
        'validate_building_stock',
        p_batch_id,
        v_start_time,
        v_error_count,
        v_error_message
    );

    -- Nettoyer la table temporaire
    DROP TABLE tmp_validation_errors;

    -- Gérer les erreurs selon le paramètre p_raise_exception
    IF v_error_count > 0 AND p_raise_exception THEN
        RAISE EXCEPTION 'Validation failed with % errors: %', v_error_count, v_error_message;
    END IF;

    -- Log du succès
    PERFORM utils.log_script_execution(
        'validate_building_stock.sql',
        'SUCCESS',
        CASE 
            WHEN v_error_count = 0 THEN 'Validation successful'
            ELSE format('Validation completed with %s errors', v_error_count)
        END
    );

EXCEPTION WHEN OTHERS THEN
    -- Nettoyer la table temporaire en cas d'erreur
    DROP TABLE IF EXISTS tmp_validation_errors;
    
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'validate_building_stock.sql',
        'ERROR',
        SQLERRM
    );
    
    -- Relancer l'erreur
    RAISE;
END;
$$;

COMMENT ON PROCEDURE staging.validate_building_stock(INTEGER, BOOLEAN) IS 
'Procédure de validation des données du parc immobilier dans la table de staging.
Vérifie :
- Présence des champs obligatoires
- Format des codes REFNIS
- Validité des années (>= 2000)
- Validité des types de bâtiment (R1-R6)
- Non-négativité des mesures

Arguments :
- p_batch_id : ID du batch à valider
- p_raise_exception : si TRUE, lève une exception en cas d''erreur (défaut: TRUE)

Les résultats de validation sont enregistrés dans metadata.validation_log.

Exemple :
CALL staging.validate_building_stock(123, TRUE);';