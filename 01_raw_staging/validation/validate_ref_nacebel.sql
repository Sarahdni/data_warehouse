-- 01_staging/validation/validate_ref_nacebel.sql

CREATE OR REPLACE PROCEDURE staging.validate_ref_nacebel(
    p_batch_id INTEGER,                    -- ID du batch à valider
    p_raise_exception BOOLEAN DEFAULT TRUE  -- Si TRUE, lève une exception en cas d'erreur
)
LANGUAGE plpgsql AS $$
DECLARE
    v_error_count INTEGER := 0;
    v_translation_count INTEGER := 0;
    v_error_message TEXT;
    v_start_time TIMESTAMP;
BEGIN
    -- Enregistrer l'heure de début
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Log du début de la validation
    PERFORM utils.log_script_execution('validate_ref_nacebel.sql', 'RUNNING');

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
    FROM staging.stg_ref_nacebel
    WHERE id_batch = p_batch_id
    AND (CD_NACEBEL IS NULL 
        OR LVL_NACEBEL IS NULL
        OR DT_VLDT_START IS NULL);

    -- 2. Validation du format des codes NACE selon le niveau
    INSERT INTO tmp_validation_errors
    SELECT 
        'INVALID_CODE_FORMAT',
        'Format de code NACE invalide pour le niveau correspondant',
        COUNT(*)
    FROM staging.stg_ref_nacebel
    WHERE id_batch = p_batch_id
    AND (
        (LVL_NACEBEL = 1 AND CD_NACEBEL !~ '^[A-Z]$') OR
        (LVL_NACEBEL = 2 AND CD_NACEBEL !~ '^[0-9]{2}$') OR
        (LVL_NACEBEL = 3 AND CD_NACEBEL !~ '^[0-9]{3}$') OR
        (LVL_NACEBEL = 4 AND CD_NACEBEL !~ '^[0-9]{4}$') OR
        (LVL_NACEBEL = 5 AND CD_NACEBEL !~ '^[0-9]{5}$')
    );

    -- 3. Validation des dates
    INSERT INTO tmp_validation_errors
    SELECT 
        'INVALID_DATES',
        'Date de début postérieure à la date de fin',
        COUNT(*)
    FROM staging.stg_ref_nacebel
    WHERE id_batch = p_batch_id
    AND DT_VLDT_START > DT_VLDT_END;

    -- 4. Validation de la hiérarchie NACE
    INSERT INTO tmp_validation_errors
    SELECT 
        'INVALID_HIERARCHY',
        'Code parent introuvable ou niveau hiérarchique invalide',
        COUNT(*)
    FROM staging.stg_ref_nacebel s1
    LEFT JOIN staging.stg_ref_nacebel s2 ON s1.CD_SUP_NACEBEL = s2.CD_NACEBEL
    WHERE s1.id_batch = p_batch_id
    AND s1.CD_SUP_NACEBEL IS NOT NULL
    AND s1.CD_SUP_NACEBEL != '-'
    AND (s2.CD_NACEBEL IS NULL OR s1.LVL_NACEBEL <= s2.LVL_NACEBEL);

    -- 5. Validation de l'unicité des codes
    INSERT INTO tmp_validation_errors
    SELECT 
        'DUPLICATE_CODES',
        'Codes NACE avec périodes qui se chevauchent',
        COUNT(*)
    FROM (
        SELECT s1.CD_NACEBEL
        FROM staging.stg_ref_nacebel s1
        JOIN staging.stg_ref_nacebel s2 ON s1.CD_NACEBEL = s2.CD_NACEBEL
        AND s1.id_batch = s2.id_batch
        AND s1.DT_VLDT_START <= s2.DT_VLDT_END
        AND s1.DT_VLDT_END >= s2.DT_VLDT_START
        AND s1.CTID < s2.CTID  -- Pour éviter le self-join
        WHERE s1.id_batch = p_batch_id
    ) dupes;

    -- 6. Vérification des traductions manquantes
    INSERT INTO metadata.missing_translations (
        id_batch,
        cd_nacebel,
        tx_original_fr,
        missing_languages
    )
    SELECT 
        id_batch,
        CD_NACEBEL,
        TX_NACEBEL_FR,
        ARRAY_REMOVE(ARRAY[
            CASE WHEN TX_NACEBEL_EN IS NULL THEN 'EN' END,
            CASE WHEN TX_NACEBEL_DE IS NULL THEN 'DE' END
        ], NULL)
    FROM staging.stg_ref_nacebel s
    WHERE id_batch = p_batch_id
    AND (TX_NACEBEL_EN IS NULL OR TX_NACEBEL_DE IS NULL)
    ON CONFLICT (id_batch, cd_nacebel) DO NOTHING;

    GET DIAGNOSTICS v_translation_count = ROW_COUNT;

    -- Ajouter les problèmes de traduction aux erreurs de validation
    IF v_translation_count > 0 THEN
        INSERT INTO tmp_validation_errors (
            error_type,
            error_message,
            affected_rows
        ) VALUES (
            'MISSING_TRANSLATIONS',
            'Traductions manquantes (EN ou DE)',
            v_translation_count
        );
    END IF;

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
        'validate_ref_nacebel',
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
        'validate_ref_nacebel.sql',
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
        'validate_ref_nacebel.sql',
        'ERROR',
        SQLERRM
    );
    
    -- Relancer l'erreur
    RAISE;
END;
$$;

-- Commentaires
COMMENT ON PROCEDURE staging.validate_ref_nacebel(INTEGER, BOOLEAN) IS 
'Procédure de validation des données NACEBEL dans la table de staging.
Vérifie :
- Présence des champs obligatoires
- Format des codes NACE selon le niveau
- Cohérence des dates
- Validité de la hiérarchie
- Traductions manquantes (EN ou DE)

Arguments :
- p_batch_id : ID du batch à valider
- p_raise_exception : si TRUE, lève une exception en cas d''erreur (défaut: TRUE)

Les résultats de validation sont enregistrés dans metadata.validation_log.
Les traductions manquantes sont enregistrées dans metadata.missing_translations.

Exemple :
CALL staging.validate_ref_nacebel(123, TRUE);';