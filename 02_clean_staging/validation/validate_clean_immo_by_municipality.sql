-- 02_clean_staging/validation/validate_clean_immo_by_municipality.sql

CREATE OR REPLACE PROCEDURE clean_staging.validate_clean_immo_by_municipality(
    p_batch_id INTEGER,
    p_raise_exception BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_error_count INTEGER := 0;
    v_error_message TEXT;
    v_invalid_refnis_count INTEGER;
    v_invalid_transactions_count INTEGER;
    v_invalid_prices_count INTEGER;
    v_invalid_surface_count INTEGER;
    v_missing_translation_count INTEGER;
    v_total_records INTEGER;
    v_confidential_records INTEGER;
BEGIN
    RAISE NOTICE 'Début de la validation pour le batch %...', p_batch_id;

    -- Compter le nombre total d'enregistrements
    SELECT COUNT(*)
    INTO v_total_records
    FROM clean_staging.clean_immo_by_municipality
    WHERE id_batch = p_batch_id;

    RAISE NOTICE 'Nombre total d''enregistrements à valider: %', v_total_records;

    -- 1. Validation des codes REFNIS
    SELECT COUNT(*)
    INTO v_invalid_refnis_count
    FROM clean_staging.clean_immo_by_municipality c
    WHERE id_batch = p_batch_id
    AND NOT EXISTS (
        SELECT 1 FROM dw.dim_geography g
        WHERE g.cd_refnis = c.cd_refnis
    );

    RAISE NOTICE 'Validation des codes REFNIS : % invalides', v_invalid_refnis_count;

    -- 2. Validation des transactions
    SELECT COUNT(*)
    INTO v_invalid_transactions_count
    FROM clean_staging.clean_immo_by_municipality
    WHERE id_batch = p_batch_id
    AND (
        ms_total_transactions IS NULL 
        OR ms_total_transactions < 0
        OR ms_total_transactions != ROUND(ms_total_transactions)
    );

    RAISE NOTICE 'Validation des transactions : % invalides', v_invalid_transactions_count;

    -- 3. Compter les enregistrements sous le seuil de confidentialité
    SELECT COUNT(*)
    INTO v_confidential_records
    FROM clean_staging.clean_immo_by_municipality
    WHERE id_batch = p_batch_id
    AND ms_total_transactions < 10;

    RAISE NOTICE 'Enregistrements sous le seuil de confidentialité : %', v_confidential_records;

    -- 4. Validation des prix (uniquement pour les enregistrements au-dessus du seuil)
    SELECT COUNT(*)
    INTO v_invalid_prices_count
    FROM clean_staging.clean_immo_by_municipality
    WHERE id_batch = p_batch_id
    AND ms_total_transactions >= 10  -- Au-dessus du seuil de confidentialité
    AND (
        ms_mean_price < 0 OR
        ms_price_p10 > ms_price_p25 OR
        ms_price_p25 > ms_price_p50 OR
        ms_price_p50 > ms_price_p75 OR
        ms_price_p75 > ms_price_p90
    );

    RAISE NOTICE 'Validation des prix (hors confidentialité) : % invalides', v_invalid_prices_count;

    -- 5. Validation des surfaces (uniquement pour les enregistrements au-dessus du seuil)
    SELECT COUNT(*)
    INTO v_invalid_surface_count
    FROM clean_staging.clean_immo_by_municipality
    WHERE id_batch = p_batch_id
    AND ms_total_transactions >= 10  -- Au-dessus du seuil de confidentialité
    AND (
        ms_total_surface < 0 OR
        (ms_total_surface = 0 AND ms_total_transactions > 0)
    );

    RAISE NOTICE 'Validation des surfaces (hors confidentialité) : % invalides', v_invalid_surface_count;

    -- 6. Validation des traductions
    SELECT COUNT(*)
    INTO v_missing_translation_count
    FROM clean_staging.clean_immo_by_municipality
    WHERE id_batch = p_batch_id
    AND (
        tx_property_type_nl IS NULL OR
        tx_property_type_fr IS NULL OR
        tx_municipality_nl IS NULL OR
        tx_municipality_fr IS NULL
    );

    RAISE NOTICE 'Traductions manquantes : %', v_missing_translation_count;

    -- Construction du message d'erreur
    IF v_invalid_refnis_count > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := format('Codes REFNIS invalides: %s', v_invalid_refnis_count);
    END IF;

    IF v_invalid_transactions_count > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || CHR(10), '') 
            || format('Transactions invalides: %s', v_invalid_transactions_count);
    END IF;

    IF v_invalid_prices_count > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || CHR(10), '') 
            || format('Prix invalides (hors confidentialité): %s', v_invalid_prices_count);
    END IF;

    IF v_invalid_surface_count > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || CHR(10), '') 
            || format('Surfaces invalides (hors confidentialité): %s', v_invalid_surface_count);
    END IF;

    IF v_missing_translation_count > 0 THEN
        v_error_count := v_error_count + 1;
        v_error_message := COALESCE(v_error_message || CHR(10), '') 
            || format('Traductions manquantes: %s', v_missing_translation_count);
    END IF;

    -- Mise à jour des flags de validation
    UPDATE clean_staging.clean_immo_by_municipality c
    SET 
        fl_valid_refnis = EXISTS (
            SELECT 1 FROM dw.dim_geography g 
            WHERE g.cd_refnis = c.cd_refnis 
            AND g.fl_current = TRUE
        ),
        fl_valid_transactions = (
            ms_total_transactions IS NOT NULL 
            AND ms_total_transactions >= 0
            AND ms_total_transactions = ROUND(ms_total_transactions)
        ),
        fl_valid_prices = (
            ms_total_transactions < 10  -- Données confidentielles
            OR (
                ms_total_transactions >= 10
                AND ms_mean_price >= 0
                AND ms_price_p10 <= ms_price_p25
                AND ms_price_p25 <= ms_price_p50
                AND ms_price_p50 <= ms_price_p75
                AND ms_price_p75 <= ms_price_p90
            )
        ),
        fl_valid_surface = (
            ms_total_transactions < 10  -- Données confidentielles
            OR (
                ms_total_transactions >= 10
                AND ms_total_surface >= 0
                AND (ms_total_surface > 0 OR ms_total_transactions = 0)
            )
        )
    WHERE id_batch = p_batch_id;

    -- Enregistrement des résultats
    INSERT INTO metadata.validation_log (
        nm_procedure,
        id_batch,
        dt_validation,
        nb_errors,
        nb_confidential,
        tx_error_message
    ) VALUES (
        'validate_clean_immo_by_municipality',
        p_batch_id,
        CURRENT_TIMESTAMP,
        v_error_count,
        v_confidential_records,
        v_error_message
    );

    -- Résultat final
    IF v_error_count = 0 THEN
        RAISE NOTICE 'Validation terminée avec succès. % enregistrements confidentiels.', v_confidential_records;
    ELSE
        RAISE NOTICE 'Validation terminée avec % erreurs et % enregistrements confidentiels.', 
                    v_error_count, v_confidential_records;
        RAISE NOTICE 'Détails: %', COALESCE(v_error_message, 'Pas de détails disponibles');

        IF p_raise_exception THEN
            RAISE EXCEPTION 'Validation échouée: %', v_error_message;
        END IF;
    END IF;

EXCEPTION WHEN OTHERS THEN
    PERFORM utils.log_script_execution(
        'validate_clean_immo_by_municipality',
        'ERROR',
        SQLERRM
    );
    RAISE;
END;
$$;

-- Ajout des commentaires sur la procédure
COMMENT ON PROCEDURE clean_staging.validate_clean_immo_by_municipality(INTEGER, BOOLEAN) IS 
'Procédure de validation des données immobilières en clean staging.

Vérifie :
- La validité des codes REFNIS
- La cohérence des transactions
- La validité des prix et leur hiérarchie (p10 < p25 < p50 < p75 < p90) pour les données non confidentielles
- La cohérence des surfaces pour les données non confidentielles
- La présence des traductions
- Le comptage des enregistrements sous le seuil de confidentialité (< 10 transactions)

Gestion de la confidentialité :
- Les enregistrements avec moins de 10 transactions sont marqués comme confidentiels
- Les prix et surfaces NULL pour ces enregistrements sont considérés comme valides
- Le nombre d''enregistrements confidentiels est tracé dans metadata.validation_log

Arguments :
- p_batch_id : ID du batch à valider
- p_raise_exception : Si TRUE, lève une exception en cas d''erreur

Flags de validation mis à jour :
- fl_valid_refnis : Existence du code REFNIS
- fl_valid_transactions : Validité du nombre de transactions
- fl_valid_prices : Validité des prix (tenant compte de la confidentialité)
- fl_valid_surface : Validité des surfaces (tenant compte de la confidentialité)';