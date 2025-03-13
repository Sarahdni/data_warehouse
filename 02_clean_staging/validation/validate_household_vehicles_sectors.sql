-- 02_clean_staging/validation/validate_household_vehicles_sectors.sql


CREATE OR REPLACE PROCEDURE clean_staging.validate_household_vehicles_sectors(
    p_batch_id INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_invalid_sectors INTEGER;
    v_invalid_refnis INTEGER;
    v_invalid_counts INTEGER;
    v_null_values INTEGER;
BEGIN
    -- Mise à jour des flags de validation pour les codes secteur
    UPDATE clean_staging.clean_household_vehicles
    SET fl_valid_sector = CASE 
        WHEN cd_sector IS NULL THEN FALSE
        WHEN cd_sector ~ '^[0-9]{5}[A-Z][0-9]{2,3}(-)?$' OR  -- Format: 5 chiffres + 1 lettre + 2-3 chiffres + tiret optionnel
             cd_sector ~ '^[0-9]{5}[A-Z][0-9][A-Z]{2}$' OR    -- Format: 5 chiffres + 1 lettre + 1 chiffre + 2 lettres
             cd_sector ~ '^[0-9]{7}[A-Z]{2}$' OR              -- Format: 7 chiffres + 2 lettres
             cd_sector LIKE '%ZZZZ'                            -- Gestion des secteurs inconnus
        THEN TRUE
        ELSE FALSE
    END
    WHERE id_batch = p_batch_id;

    -- Mise à jour des flags de validation pour les codes REFNIS
    UPDATE clean_staging.clean_household_vehicles
    SET fl_valid_refnis = CASE 
        WHEN cd_refnis IS NULL THEN FALSE
        WHEN cd_refnis ~ '^[0-9]{5}$' THEN TRUE
        ELSE FALSE
    END
    WHERE id_batch = p_batch_id;

    -- Mise à jour des flags de validation pour les comptages
    UPDATE clean_staging.clean_household_vehicles
    SET fl_valid_counts = CASE 
        WHEN ms_households >= 0 
         AND ms_vehicles >= 0 
         AND ms_households IS NOT NULL 
         AND ms_vehicles IS NOT NULL 
        THEN TRUE
        ELSE FALSE
    END
    WHERE id_batch = p_batch_id;

    -- Compter les différents types d'invalidité
    SELECT 
        COUNT(*) FILTER (WHERE NOT fl_valid_sector) as invalid_sectors,
        COUNT(*) FILTER (WHERE NOT fl_valid_refnis) as invalid_refnis,
        COUNT(*) FILTER (WHERE NOT fl_valid_counts) as invalid_counts,
        COUNT(*) FILTER (WHERE 
            cd_sector IS NULL OR 
            cd_refnis IS NULL OR 
            ms_households IS NULL OR 
            ms_vehicles IS NULL
        ) as null_values
    INTO 
        v_invalid_sectors,
        v_invalid_refnis,
        v_invalid_counts,
        v_null_values
    FROM clean_staging.clean_household_vehicles
    WHERE id_batch = p_batch_id;

    -- Log des résultats détaillés
    RAISE NOTICE 'Résultats de la validation pour le batch %:', p_batch_id;
    RAISE NOTICE 'Codes secteur invalides: %', v_invalid_sectors;
    RAISE NOTICE 'Codes REFNIS invalides: %', v_invalid_refnis;
    RAISE NOTICE 'Comptages invalides: %', v_invalid_counts;
    RAISE NOTICE 'Valeurs NULL trouvées: %', v_null_values;

    -- Log dans la table de suivi
    PERFORM utils.log_script_execution(
        'validate_household_vehicles_sectors',
        'SUCCESS',
        format('Validation terminée. Détails: %s secteurs invalides, %s REFNIS invalides, %s comptages invalides, %s valeurs NULL',
            v_invalid_sectors, v_invalid_refnis, v_invalid_counts, v_null_values)
    );

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'validate_household_vehicles_sectors',
        'ERROR',
        SQLERRM
    );
    RAISE;
END;
$$;

COMMENT ON PROCEDURE clean_staging.validate_household_vehicles_sectors(INTEGER) IS 
'Procédure de validation des codes secteurs, REFNIS et comptages pour la table clean_household_vehicles.
- Valide le format des codes secteur selon les patterns autorisés
- Valide le format des codes REFNIS (5 chiffres)
- Vérifie que les comptages sont positifs et non nuls
- Détecte et compte les valeurs NULL
Arguments:
- p_batch_id: ID du batch à valider';