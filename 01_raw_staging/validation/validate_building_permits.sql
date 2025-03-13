-- 01_staging/validation/validate_building_permits.sql

CREATE OR REPLACE PROCEDURE staging.validate_building_permits(
    p_batch_id INTEGER,                    
    p_raise_exception BOOLEAN DEFAULT TRUE  
)
LANGUAGE plpgsql AS $$
DECLARE
    v_error_count INTEGER := 0;
    v_error_message TEXT;
    v_start_time TIMESTAMP;
    v_duplicate_count INTEGER;
BEGIN
    -- Enregistrer l'heure de début
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Log du début de la validation
    PERFORM utils.log_script_execution('validate_building_permits.sql', 'RUNNING');

    -- Table temporaire pour stocker les erreurs
    CREATE TEMP TABLE tmp_validation_errors (
        error_type VARCHAR(50),
        error_message TEXT,
        affected_rows INTEGER
    );

    -- Déduplication des données
    CREATE TEMP TABLE tmp_deduplicated AS
    SELECT DISTINCT ON (REFNIS, CD_YEAR, CD_PERIOD)
        *
    FROM staging.stg_building_permits
    WHERE id_batch = p_batch_id
    ORDER BY REFNIS, CD_YEAR, CD_PERIOD;

    -- Compter les doublons supprimés
    GET DIAGNOSTICS v_duplicate_count = ROW_COUNT;

    -- Si des doublons ont été trouvés, les enregistrer comme erreur
    IF v_duplicate_count > 0 THEN
        INSERT INTO tmp_validation_errors
        SELECT 
            'DUPLICATE_ENTRIES',
            'Entrées en double pour la même période et zone géographique',
            (SELECT COUNT(*) FROM staging.stg_building_permits WHERE id_batch = p_batch_id) - v_duplicate_count;
    END IF;

    -- 1. Validation du format REFNIS
    INSERT INTO tmp_validation_errors
    SELECT 
        'INVALID_REFNIS_FORMAT',
        'Codes REFNIS invalides (doit être composé de 5 chiffres)',
        invalid_count::integer
    FROM utils.validate_refnis_batch('staging', 'stg_building_permits', 'REFNIS', p_batch_id)
    WHERE invalid_count > 0;

    -- 2. Validation des champs obligatoires
    INSERT INTO tmp_validation_errors
    SELECT 
        'MISSING_REQUIRED_FIELDS',
        'Champs obligatoires manquants',
        COUNT(*)
    FROM staging.stg_building_permits
    WHERE id_batch = p_batch_id
    AND (CD_YEAR IS NULL OR CD_PERIOD IS NULL);

    -- 3. Validation des périodes
    INSERT INTO tmp_validation_errors
    SELECT 
        'INVALID_PERIOD',
        'Période invalide (doit être entre 0 et 12)',
        COUNT(*)
    FROM staging.stg_building_permits
    WHERE id_batch = p_batch_id
    AND (CD_PERIOD < 0 OR CD_PERIOD > 12);

    -- 4. Validation de l'année
    INSERT INTO tmp_validation_errors
    SELECT 
        'INVALID_YEAR',
        'Année invalide (doit être >= 1996)',
        COUNT(*)
    FROM staging.stg_building_permits
    WHERE id_batch = p_batch_id
    AND CD_YEAR < 1996;

    -- 5. Validation des niveaux géographiques
    INSERT INTO tmp_validation_errors
    SELECT 
        'INVALID_GEOGRAPHIC_LEVEL',
        'Niveau géographique invalide (doit être entre 0 et 5)',
        COUNT(*)
    FROM staging.stg_building_permits
    WHERE id_batch = p_batch_id
    AND (CD_REFNIS_LEVEL < 0 OR CD_REFNIS_LEVEL > 5);

    -- 6. Validation des valeurs numériques négatives
    INSERT INTO tmp_validation_errors
    SELECT 
        'NEGATIVE_VALUES',
        'Valeurs numériques négatives détectées',
        COUNT(*)
    FROM staging.stg_building_permits
    WHERE id_batch = p_batch_id
    AND (
        MS_BUILDING_RES_NEW < 0 OR
        MS_DWELLING_RES_NEW < 0 OR
        MS_APARTMENT_RES_NEW < 0 OR
        MS_SINGLE_HOUSE_RES_NEW < 0 OR
        MS_TOTAL_SURFACE_RES_NEW < 0 OR
        MS_BUILDING_RES_RENOVATION < 0 OR
        MS_BUILDING_NONRES_NEW < 0 OR
        MS_VOLUME_NONRES_NEW < 0 OR
        MS_BUILDING_NONRES_RENOVATION < 0
    );

    -- 7. Validation de la cohérence des valeurs
    INSERT INTO tmp_validation_errors
    SELECT 
        'INCONSISTENT_VALUES',
        'Incohérence dans les valeurs de logements',
        COUNT(*)
    FROM staging.stg_building_permits
    WHERE id_batch = p_batch_id
    AND MS_DWELLING_RES_NEW < (MS_APARTMENT_RES_NEW + MS_SINGLE_HOUSE_RES_NEW);

    -- Comptage des erreurs
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
        'validate_building_permits',
        p_batch_id,
        v_start_time,
        v_error_count,
        v_error_message
    );

    -- Nettoyer les tables temporaires
    DROP TABLE IF EXISTS tmp_validation_errors;
    DROP TABLE IF EXISTS tmp_deduplicated;

    -- Gérer les erreurs selon le paramètre p_raise_exception
    IF v_error_count > 0 AND p_raise_exception THEN
        RAISE EXCEPTION 'Validation failed with % errors: %', v_error_count, v_error_message;
    END IF;

    -- Log du succès
    PERFORM utils.log_script_execution(
        'validate_building_permits.sql',
        'SUCCESS',
        CASE 
            WHEN v_error_count = 0 THEN 'Validation successful'
            ELSE format('Validation completed with %s errors', v_error_count)
        END
    );

EXCEPTION WHEN OTHERS THEN
    -- Nettoyer les tables temporaires en cas d'erreur
    DROP TABLE IF EXISTS tmp_validation_errors;
    DROP TABLE IF EXISTS tmp_deduplicated;
    
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'validate_building_permits.sql',
        'ERROR',
        SQLERRM
    );
    
    -- Relancer l'erreur
    RAISE;
END;
$$;

COMMENT ON PROCEDURE staging.validate_building_permits(INTEGER, BOOLEAN) IS 
'Procédure de validation des données de permis de construire dans la table de staging.
Vérifie :
- Format des codes REFNIS (5 chiffres)
- Présence des champs obligatoires
- Validité des périodes (0-12)
- Validité des années (>= 1996)
- Validité des niveaux géographiques (0-5)
- Non-négativité des mesures
- Cohérence des valeurs de logements
- Détection des doublons

Arguments :
- p_batch_id : ID du batch à valider
- p_raise_exception : si TRUE, lève une exception en cas d''erreur (défaut: TRUE)

Les résultats de validation sont enregistrés dans metadata.validation_log.

Exemple :
CALL staging.validate_building_permits(123, TRUE);';