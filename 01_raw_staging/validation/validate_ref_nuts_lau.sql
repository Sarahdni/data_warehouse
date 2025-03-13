-- 01_staging/validation/validate_ref_nuts_lau.sql

CREATE OR REPLACE PROCEDURE staging.validate_ref_nuts_lau(
    p_batch_id INTEGER,                    -- ID du batch à valider
    p_raise_exception BOOLEAN DEFAULT TRUE  -- Si TRUE, lève une exception en cas d'erreur
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
    PERFORM utils.log_script_execution('validate_ref_nuts_lau.sql', 'RUNNING');

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
    FROM staging.stg_ref_nuts_lau
    WHERE id_batch = p_batch_id
    AND (CD_LAU IS NULL 
        OR CD_MUNTY_REFNIS IS NULL
        OR CD_LVL IS NULL
        OR DT_VLDT_STRT IS NULL);

    -- 2. Validation du format des codes
    INSERT INTO tmp_validation_errors
    SELECT 
        'INVALID_CODE_FORMAT',
        'Format de code LAU invalide',
        COUNT(*)
    FROM staging.stg_ref_nuts_lau
    WHERE id_batch = p_batch_id
    AND CD_LAU !~ '^(BE[0-9A-Z]{1,8}|[0-9]{5})$';  -- Accepte soit BE+caractères, soit 5 chiffres 

    -- 3. Validation des dates
    INSERT INTO tmp_validation_errors
    SELECT 
        'INVALID_DATES',
        'Date de début postérieure à la date de fin',
        COUNT(*)
    FROM staging.stg_ref_nuts_lau
    WHERE id_batch = p_batch_id
    AND DT_VLDT_STRT > DT_VLDT_STOP;

    -- 4. Validation de la hiérarchie
    INSERT INTO tmp_validation_errors
    SELECT 
        'INVALID_HIERARCHY',
        'Niveau hiérarchique invalide pour le code supérieur',
        COUNT(*)
    FROM staging.stg_ref_nuts_lau s1
    LEFT JOIN staging.stg_ref_nuts_lau s2 ON s1.CD_LVL_SUP = s2.CD_LAU
    WHERE s1.id_batch = p_batch_id
    AND s1.CD_LVL_SUP IS NOT NULL
    AND s1.CD_LVL_SUP != '-'
    AND (s2.CD_LAU IS NULL OR s1.CD_LVL <= s2.CD_LVL);

    -- 5. Validation de l'unicité des codes
    INSERT INTO tmp_validation_errors
    SELECT 
        'DUPLICATE_CODES',
        'Codes LAU avec périodes qui se chevauchent',
        COUNT(*)
    FROM (
        SELECT s1.CD_LAU
        FROM staging.stg_ref_nuts_lau s1
        JOIN staging.stg_ref_nuts_lau s2 ON s1.CD_LAU = s2.CD_LAU
        AND s1.id_batch = s2.id_batch
        AND s1.DT_VLDT_STRT <= s2.DT_VLDT_STOP
        AND s1.DT_VLDT_STOP >= s2.DT_VLDT_STRT
        AND s1.CTID < s2.CTID  -- Pour éviter le self-join
        WHERE s1.id_batch = p_batch_id
    ) dupes;

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
        'validate_ref_nuts_lau',
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
        'validate_ref_nuts_lau.sql',
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
        'validate_ref_nuts_lau.sql',
        'ERROR',
        SQLERRM
    );
    
    -- Relancer l'erreur
    RAISE;
END;
$$;

-- Commentaires
COMMENT ON PROCEDURE staging.validate_ref_nuts_lau(INTEGER, BOOLEAN) IS 
'Procédure de validation des données NUTS/LAU dans la table de staging.
Vérifie :
- Présence des champs obligatoires
- Format des codes
- Cohérence des dates
- Validité de la hiérarchie
- Unicité des codes

Arguments :
- p_batch_id : ID du batch à valider
- p_raise_exception : si TRUE, lève une exception en cas d''erreur (défaut: TRUE)

Les résultats de validation sont enregistrés dans metadata.validation_log.

Exemple :
CALL staging.validate_ref_nuts_lau(123, TRUE);';

-- Table de log des validations si elle n''existe pas déjà
CREATE TABLE IF NOT EXISTS metadata.validation_log (
    id_validation SERIAL PRIMARY KEY,
    nm_procedure VARCHAR(100) NOT NULL,
    id_batch INTEGER NOT NULL,
    dt_validation TIMESTAMP NOT NULL,
    nb_errors INTEGER NOT NULL,
    tx_error_message TEXT
);