-- 02_clean_staging/validation/validate_clean_tax_income.sql

CREATE OR REPLACE PROCEDURE clean_staging.validate_clean_tax_income(
    p_batch_id INTEGER,
    p_raise_exception BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_error_count INTEGER := 0;
    v_error_message TEXT;
    v_invalid_refnis_count INTEGER;
    v_invalid_counts_count INTEGER;
    v_invalid_amounts_count INTEGER;
    v_invalid_hierarchy_count INTEGER;
    v_total_records INTEGER;
BEGIN
    RAISE NOTICE 'Début de la validation pour le batch %...', p_batch_id;

    -- Compter le nombre total d'enregistrements
    SELECT COUNT(*)
    INTO v_total_records
    FROM clean_staging.clean_tax_income
    WHERE id_batch = p_batch_id;

    RAISE NOTICE 'Nombre total d''enregistrements à valider: %', v_total_records;

    -- Validation des codes REFNIS
    SELECT COUNT(*)
    INTO v_invalid_refnis_count
    FROM clean_staging.clean_tax_income c
    WHERE id_batch = p_batch_id
    AND NOT utils.validate_refnis(cd_munty_refnis);

    RAISE NOTICE 'Validation des codes REFNIS : % invalides', v_invalid_refnis_count;

    -- Validation des comptages modifiée : uniquement la positivité
    SELECT COUNT(*)
    INTO v_invalid_counts_count
    FROM clean_staging.clean_tax_income
    WHERE id_batch = p_batch_id
    AND (
        ms_nbr_non_zero_inc < 0 OR
        ms_nbr_zero_inc < 0
    );

    RAISE NOTICE 'Validation des comptages : % invalides', v_invalid_counts_count;

    -- Validation des montants
    SELECT COUNT(*)
    INTO v_invalid_amounts_count
    FROM clean_staging.clean_tax_income
    WHERE id_batch = p_batch_id
    AND (
        ms_tot_net_taxable_inc < 0 OR
        ms_tot_net_inc < 0 OR
        ms_tot_taxes != COALESCE(ms_tot_state_taxes, 0) +
                       COALESCE(ms_tot_municip_taxes, 0) +
                       COALESCE(ms_tot_suburbs_taxes, 0)
    );

    RAISE NOTICE 'Validation des montants : % invalides', v_invalid_amounts_count;

    -- Validation de la hiérarchie géographique
    SELECT COUNT(*)
    INTO v_invalid_hierarchy_count
    FROM clean_staging.clean_tax_income c
    WHERE id_batch = p_batch_id
    AND NOT EXISTS (
        SELECT 1 
        FROM dw.dim_geography g
        WHERE g.cd_refnis = c.cd_munty_refnis
    );

    RAISE NOTICE 'Validation de la hiérarchie géographique : % invalides', v_invalid_hierarchy_count;

    -- Construire le message d'erreur
    IF v_invalid_refnis_count > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := format('Codes REFNIS invalides: %s', v_invalid_refnis_count);
    END IF;

    IF v_invalid_counts_count > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || CHR(10), '') 
            || format('Comptages invalides: %s', v_invalid_counts_count);
    END IF;

    IF v_invalid_amounts_count > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || CHR(10), '') 
            || format('Montants invalides: %s', v_invalid_amounts_count);
    END IF;

    IF v_invalid_hierarchy_count > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || CHR(10), '') 
            || format('Hiérarchie géographique invalide: %s', v_invalid_hierarchy_count);
    END IF;

    -- Mise à jour des flags de validation
    UPDATE clean_staging.clean_tax_income c
    SET 
        fl_valid_munty_refnis = utils.validate_refnis(cd_munty_refnis),
        fl_valid_counts = (
            ms_nbr_non_zero_inc >= 0 AND
            ms_nbr_zero_inc >= 0
        ),
        fl_valid_amounts = (
            ms_tot_net_taxable_inc >= 0 AND
            ms_tot_net_inc >= 0 AND
            ms_tot_taxes = COALESCE(ms_tot_state_taxes, 0) +
                          COALESCE(ms_tot_municip_taxes, 0) +
                          COALESCE(ms_tot_suburbs_taxes, 0)
        ),
        fl_valid_hierarchy = EXISTS (
            SELECT 1 
            FROM dw.dim_geography g
            WHERE g.cd_refnis = c.cd_munty_refnis
        )
    WHERE id_batch = p_batch_id;

    -- Enregistrer les résultats
    INSERT INTO metadata.validation_log (
        nm_procedure,
        id_batch,
        dt_validation,
        nb_errors,
        tx_error_message
    ) VALUES (
        'validate_clean_tax_income',
        p_batch_id,
        CURRENT_TIMESTAMP,
        v_error_count,
        v_error_message
    );

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
        'validate_clean_tax_income',
        'ERROR',
        SQLERRM
    );
    RAISE;
END;
$$;