-- 02_clean_staging/validation/validate_clean_population_structure.sql

CREATE OR REPLACE PROCEDURE clean_staging.validate_clean_population_structure(
    p_batch_id INTEGER,
    p_raise_exception BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_error_count INTEGER := 0;
    v_error_message TEXT;
    v_invalid_geography INTEGER;
    v_invalid_sex INTEGER;
    v_invalid_age INTEGER;
    v_invalid_nationality INTEGER;
    v_invalid_civil_status INTEGER;
    v_negative_population INTEGER;
BEGIN
    -- Vérification des données géographiques invalides
    SELECT COUNT(*) INTO v_invalid_geography
    FROM clean_staging.clean_population_structure
    WHERE id_batch = p_batch_id AND NOT fl_valid_geography;

    -- Vérification des sexes invalides
    SELECT COUNT(*) INTO v_invalid_sex
    FROM clean_staging.clean_population_structure
    WHERE id_batch = p_batch_id AND NOT fl_valid_sex;

    -- Vérification des âges invalides
    SELECT COUNT(*) INTO v_invalid_age
    FROM clean_staging.clean_population_structure
    WHERE id_batch = p_batch_id AND NOT fl_valid_age;

    -- Vérification des nationalités invalides
    SELECT COUNT(*) INTO v_invalid_nationality
    FROM clean_staging.clean_population_structure
    WHERE id_batch = p_batch_id AND NOT fl_valid_nationality;

    -- Vérification des états civils invalides
    SELECT COUNT(*) INTO v_invalid_civil_status
    FROM clean_staging.clean_population_structure
    WHERE id_batch = p_batch_id AND NOT fl_valid_civil_status;

    -- Vérification des populations négatives
    SELECT COUNT(*) INTO v_negative_population
    FROM clean_staging.clean_population_structure
    WHERE id_batch = p_batch_id AND ms_population < 0;

    -- Construction du message d'erreur
    IF v_invalid_geography > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || E'\n', '') || 
                          format('%s enregistrements avec géographie invalide', v_invalid_geography);
    END IF;

    IF v_invalid_sex > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || E'\n', '') || 
                          format('%s enregistrements avec sexe invalide', v_invalid_sex);
    END IF;

    IF v_invalid_age > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || E'\n', '') || 
                          format('%s enregistrements avec âge invalide', v_invalid_age);
    END IF;

    IF v_invalid_nationality > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || E'\n', '') || 
                          format('%s enregistrements avec nationalité invalide', v_invalid_nationality);
    END IF;

    IF v_invalid_civil_status > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || E'\n', '') || 
                          format('%s enregistrements avec état civil invalide', v_invalid_civil_status);
    END IF;

    IF v_negative_population > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || E'\n', '') || 
                          format('%s enregistrements avec population négative', v_negative_population);
    END IF;

    -- Enregistrement des résultats de validation
    INSERT INTO metadata.validation_log (
        nm_procedure,
        id_batch,
        dt_validation,
        nb_errors,
        tx_error_message
    ) VALUES (
        'validate_clean_population_structure',
        p_batch_id,
        CURRENT_TIMESTAMP,
        v_error_count,
        v_error_message
    );

    -- Lever une exception si demandé et s'il y a des erreurs
    IF p_raise_exception AND v_error_count > 0 THEN
        RAISE EXCEPTION 'Validation échouée avec % erreurs: %', v_error_count, v_error_message;
    END IF;

    -- Log du succès
    PERFORM utils.log_script_execution(
        'validate_clean_population_structure',
        CASE 
            WHEN v_error_count = 0 THEN 'SUCCESS'
            ELSE 'WARNING'
        END,
        CASE 
            WHEN v_error_count = 0 THEN 'Validation réussie'
            ELSE format('Validation terminée avec %s avertissements', v_error_count)
        END
    );

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'validate_clean_population_structure',
        'ERROR',
        SQLERRM
    );
    RAISE;
END;
$$;

COMMENT ON PROCEDURE clean_staging.validate_clean_population_structure IS 
'Procédure de validation des données de population dans clean_staging.
Vérifie :
- Validité des liens géographiques
- Validité des codes (sexe, âge, nationalité, état civil)
- Validité des populations (non négatives)';