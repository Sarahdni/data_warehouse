-- 02_clean_staging/validation/validate_clean_household_vehicles.sql

CREATE OR REPLACE PROCEDURE clean_staging.validate_clean_household_vehicles(
    p_batch_id INTEGER,
    p_raise_exception BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_error_count INTEGER := 0;
    v_error_message TEXT;
    v_invalid_sector_count INTEGER;
    v_invalid_refnis_count INTEGER;
    v_invalid_ratio_count INTEGER;
    v_total_records INTEGER;
BEGIN
    RAISE NOTICE 'Début de la validation pour le batch %...', p_batch_id;

    -- Compter le nombre total d'enregistrements
    SELECT COUNT(*)
    INTO v_total_records
    FROM clean_staging.clean_household_vehicles
    WHERE id_batch = p_batch_id;

    RAISE NOTICE 'Nombre total d''enregistrements à valider: %', v_total_records;

    -- Compter les erreurs de secteur
    SELECT COUNT(*)
    INTO v_invalid_sector_count
    FROM clean_staging.clean_household_vehicles
    WHERE id_batch = p_batch_id
    AND NOT fl_valid_sector;

    RAISE NOTICE 'Validation des codes secteur : % invalides', v_invalid_sector_count;

    -- Compter les erreurs de REFNIS
    SELECT COUNT(*)
    INTO v_invalid_refnis_count
    FROM clean_staging.clean_household_vehicles
    WHERE id_batch = p_batch_id
    AND NOT fl_valid_refnis;

    RAISE NOTICE 'Validation des codes REFNIS : % invalides', v_invalid_refnis_count;

    -- Compter les ratios suspects
    SELECT COUNT(*)
    INTO v_invalid_ratio_count
    FROM clean_staging.clean_household_vehicles
    WHERE id_batch = p_batch_id
    AND ms_households > 0 
    AND (ms_vehicles::DECIMAL / ms_households) > 5;

    RAISE NOTICE 'Ratios véhicules/ménages suspects (>5) : %', v_invalid_ratio_count;

    -- Construire le message d'erreur
    IF v_invalid_sector_count > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := format('Secteurs invalides: %s', v_invalid_sector_count);
    END IF;

    IF v_invalid_refnis_count > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || CHR(10), '') 
            || format('REFNIS invalides: %s', v_invalid_refnis_count);
    END IF;

    IF v_invalid_ratio_count > 0 THEN
        v_error_message := COALESCE(v_error_message || CHR(10), '') 
            || format('Ratios suspects (>5): %s', v_invalid_ratio_count);
    END IF;

    -- Enregistrer les résultats
    INSERT INTO metadata.validation_log (
        nm_procedure,
        id_batch,
        dt_validation,
        nb_errors,
        tx_error_message
    ) VALUES (
        'validate_clean_household_vehicles',
        p_batch_id,
        CURRENT_TIMESTAMP,
        v_error_count,
        v_error_message
    );

    -- Afficher le résultat final
    IF v_error_count = 0 AND v_invalid_ratio_count = 0 THEN
        RAISE NOTICE 'Validation terminée avec succès. Aucune erreur détectée.';
    ELSE
        RAISE NOTICE 'Validation terminée avec % erreurs et % avertissements.', 
                    v_error_count, v_invalid_ratio_count;
        RAISE NOTICE 'Détails: %', COALESCE(v_error_message, 'Pas de détails disponibles');

        -- Lever une exception si demandé
        IF p_raise_exception AND v_error_count > 0 THEN
            RAISE EXCEPTION 'Validation échouée: %', v_error_message;
        END IF;
    END IF;

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'validate_clean_household_vehicles',
        'ERROR',
        SQLERRM
    );
    RAISE NOTICE 'Erreur lors de la validation: %', SQLERRM;
    RAISE;
END;
$$;