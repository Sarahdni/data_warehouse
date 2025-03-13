-- 02_clean_staging/validation/validate_clean_household_cohabitation.sql

CREATE OR REPLACE PROCEDURE clean_staging.validate_clean_household_cohabitation(
    p_batch_id INTEGER,
    p_raise_exception BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_error_count INTEGER := 0;
    v_error_message TEXT;
    v_invalid_refnis_count INTEGER;
    v_invalid_sex_count INTEGER;
    v_invalid_age_count INTEGER;
    v_invalid_nationality_count INTEGER;
    v_negative_count_count INTEGER;
    v_missing_translation_count INTEGER;
    v_total_records INTEGER;
BEGIN
    RAISE NOTICE 'Début de la validation pour le batch %...', p_batch_id;

    -- Compter le nombre total d'enregistrements
    SELECT COUNT(*)
    INTO v_total_records
    FROM clean_staging.clean_household_cohabitation
    WHERE id_batch = p_batch_id;

    RAISE NOTICE 'Nombre total d''enregistrements à valider: %', v_total_records;

    -- Validation des codes REFNIS régionaux
    SELECT COUNT(*)
    INTO v_invalid_refnis_count
    FROM clean_staging.clean_household_cohabitation
    WHERE id_batch = p_batch_id
    AND cd_rgn_refnis NOT IN ('2000', '3000', '4000');

    RAISE NOTICE 'Validation des codes REFNIS région : % invalides (codes autorisés : 2000, 3000, 4000)', v_invalid_refnis_count;

    -- Validation du sexe avec dim_sex
    SELECT COUNT(*)
    INTO v_invalid_sex_count
    FROM clean_staging.clean_household_cohabitation c
    WHERE id_batch = p_batch_id
    AND NOT EXISTS (
        SELECT 1 FROM dw.dim_sex s
        WHERE s.cd_sex = c.cd_sex
    );

    RAISE NOTICE 'Validation du sexe : % invalides', v_invalid_sex_count;

    -- Validation de la nationalité avec dim_nationality
    SELECT COUNT(*)
    INTO v_invalid_nationality_count
    FROM clean_staging.clean_household_cohabitation c
    WHERE id_batch = p_batch_id
    AND NOT EXISTS (
        SELECT 1 FROM dw.dim_nationality n
        WHERE n.cd_nationality = c.cd_natlty
    );

    RAISE NOTICE 'Validation de la nationalité : % invalides', v_invalid_nationality_count;

    -- Validation des tranches d'âge avec dim_age_group
    SELECT COUNT(*)
    INTO v_invalid_age_count
    FROM clean_staging.clean_household_cohabitation c
    WHERE id_batch = p_batch_id
    AND NOT EXISTS (
        SELECT 1 FROM dw.dim_age_group d
        WHERE d.cd_age_group = c.cd_age
    );

    RAISE NOTICE 'Validation des tranches d''âge : % invalides', v_invalid_age_count;

    -- Validation des comptages négatifs
    SELECT COUNT(*)
    INTO v_negative_count_count
    FROM clean_staging.clean_household_cohabitation
    WHERE id_batch = p_batch_id
    AND ms_count < 0;

    RAISE NOTICE 'Comptages négatifs trouvés : %', v_negative_count_count;

    -- Validation des traductions manquantes
    SELECT COUNT(*)
    INTO v_missing_translation_count
    FROM clean_staging.clean_household_cohabitation
    WHERE id_batch = p_batch_id
    AND (
        tx_rgn_descr_nl IS NULL OR
        tx_rgn_descr_fr IS NULL OR
        tx_natlty_nl IS NULL OR
        tx_natlty_fr IS NULL OR
        tx_cohab_nl IS NULL OR
        tx_cohab_fr IS NULL
    );

    RAISE NOTICE 'Traductions manquantes : %', v_missing_translation_count;

    -- Construire le message d'erreur
    IF v_invalid_refnis_count > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := format('Codes REFNIS région invalides: %s', v_invalid_refnis_count);
    END IF;

    IF v_invalid_sex_count > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || CHR(10), '') 
            || format('Codes sexe invalides: %s', v_invalid_sex_count);
    END IF;

    IF v_invalid_age_count > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || CHR(10), '') 
            || format('Tranches d''âge invalides: %s', v_invalid_age_count);
    END IF;

    IF v_invalid_nationality_count > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || CHR(10), '') 
            || format('Codes nationalité invalides: %s', v_invalid_nationality_count);
    END IF;

    IF v_negative_count_count > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || CHR(10), '') 
            || format('Comptages négatifs: %s', v_negative_count_count);
    END IF;

    IF v_missing_translation_count > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || CHR(10), '') 
            || format('Traductions manquantes: %s', v_missing_translation_count);
    END IF;

    -- Enregistrer les résultats
    INSERT INTO metadata.validation_log (
        nm_procedure,
        id_batch,
        dt_validation,
        nb_errors,
        tx_error_message
    ) VALUES (
        'validate_clean_household_cohabitation',
        p_batch_id,
        CURRENT_TIMESTAMP,
        v_error_count,
        v_error_message
    );

    -- Mise à jour des flags de validation
    UPDATE clean_staging.clean_household_cohabitation c
    SET 
        fl_valid_refnis = (cd_rgn_refnis IN ('2000', '3000', '4000')),
        fl_valid_sex = EXISTS (
            SELECT 1 FROM dw.dim_sex s WHERE s.cd_sex = c.cd_sex
        ),
        fl_valid_age = EXISTS (
            SELECT 1 FROM dw.dim_age_group a WHERE a.cd_age_group = c.cd_age
        ),
        fl_valid_nationality = EXISTS (
            SELECT 1 FROM dw.dim_nationality n WHERE n.cd_nationality = c.cd_natlty
        ),
        fl_valid_count = (ms_count >= 0)
    WHERE id_batch = p_batch_id;

    -- Afficher le résultat final
    IF v_error_count = 0 THEN
        RAISE NOTICE 'Validation terminée avec succès. Aucune erreur détectée.';
    ELSE
        RAISE NOTICE 'Validation terminée avec % erreurs.', v_error_count;
        RAISE NOTICE 'Détails: %', COALESCE(v_error_message, 'Pas de détails disponibles');

        -- Lever une exception si demandé
        IF p_raise_exception THEN
            RAISE EXCEPTION 'Validation échouée: %', v_error_message;
        END IF;
    END IF;

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'validate_clean_household_cohabitation',
        'ERROR',
        SQLERRM
    );
    RAISE;
END;
$$;

COMMENT ON PROCEDURE clean_staging.validate_clean_household_cohabitation(INTEGER, BOOLEAN) IS 
'Procédure de validation des données de cohabitation en clean staging.
Vérifie :
- La validité des codes REFNIS région
- La validité des tranches d''âge
- La positivité des comptages
- La présence des traductions

Arguments :
- p_batch_id : ID du batch à valider
- p_raise_exception : Si TRUE, lève une exception en cas d''erreur';