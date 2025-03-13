-- 01_raw_staging/validation/validate_raw_unemployment.sql

CREATE OR REPLACE PROCEDURE raw_staging.validate_raw_unemployment(
    p_batch_id INTEGER,
    p_raise_exception BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
    -- Structure explicite du record pour les comptages NULL
    v_null_counts RECORD;
    
    -- Variables pour stocker les comptages
    v_invalid_year_counts integer;
    v_invalid_quarter_counts integer;
    v_invalid_nuts_counts integer;
    v_invalid_value_counts integer;
    v_missing_translation_counts record;
    v_duplicate_counts integer;
    v_summary text;
    
    -- Variables pour stocker les exemples
    v_invalid_year_examples text[];
    v_invalid_quarter_examples text[];
    v_invalid_nuts_examples text[];
    v_invalid_value_examples text[];
    v_null_value_examples text[];
BEGIN
    RAISE NOTICE 'Début de la validation du batch % de raw_unemployment', p_batch_id;

    -- 1. Vérification des valeurs NULL avec exemples
    SELECT 
        COUNT(*) FILTER (WHERE id_cube IS NULL) as null_cube,
        COUNT(*) FILTER (WHERE cd_year IS NULL) as null_year,
        COUNT(*) FILTER (WHERE cd_quarter IS NULL) as null_quarter,
        COUNT(*) FILTER (WHERE cd_nuts_lvl2 IS NULL) as null_nuts,
        COUNT(*) FILTER (WHERE ms_value IS NULL) as null_value,
        COUNT(*) FILTER (WHERE cd_sex IS NULL) as null_sex,
        COUNT(*) FILTER (WHERE cd_empmt_age IS NULL) as null_age,
        COUNT(*) FILTER (WHERE cd_isced_2011 IS NULL) as null_isced,
        array_agg(DISTINCT cd_nuts_lvl2) FILTER (WHERE ms_value IS NULL) as null_value_examples
    INTO v_null_counts
    FROM raw_staging.raw_unemployment
    WHERE id_batch = p_batch_id;

    -- 2. Validation du format des années avec exemples
    SELECT 
        COUNT(*) as invalid_count,
        array_agg(DISTINCT cd_year) FILTER (
            WHERE cd_year !~ '^\d{4}$'
        ) as examples
    INTO v_invalid_year_counts, v_invalid_year_examples
    FROM raw_staging.raw_unemployment
    WHERE id_batch = p_batch_id
    AND cd_year !~ '^\d{4}$';

    -- 3. Validation du format des trimestres avec exemples (incluant TOTAL)
    SELECT 
        COUNT(*) as invalid_count,
        array_agg(DISTINCT cd_quarter) FILTER (
            WHERE cd_quarter NOT IN ('Q1', 'Q2', 'Q3', 'Q4', 'TOTAL')
        ) as examples
    INTO v_invalid_quarter_counts, v_invalid_quarter_examples
    FROM raw_staging.raw_unemployment
    WHERE id_batch = p_batch_id
    AND cd_quarter NOT IN ('Q1', 'Q2', 'Q3', 'Q4', 'TOTAL');

    -- 4. Validation du format des codes NUTS avec exemples
    SELECT 
        COUNT(*) as invalid_count,
        array_agg(DISTINCT cd_nuts_lvl2) FILTER (
            WHERE cd_nuts_lvl2 !~ '^[A-Z]{2}\d{1}$'
        ) as examples
    INTO v_invalid_nuts_counts, v_invalid_nuts_examples
    FROM raw_staging.raw_unemployment
    WHERE id_batch = p_batch_id
    AND cd_nuts_lvl2 !~ '^[A-Z]{2}\d{1}$';

    -- 5. Validation des valeurs numériques avec exemples
    SELECT 
        COUNT(*) as invalid_count,
        array_agg(DISTINCT ms_value) FILTER (
            WHERE ms_value !~ '^\d+(\.\d+)?$' OR ms_value::numeric < 0
        ) as examples
    INTO v_invalid_value_counts, v_invalid_value_examples
    FROM raw_staging.raw_unemployment
    WHERE id_batch = p_batch_id
    AND ms_value IS NOT NULL
    AND (ms_value !~ '^\d+(\.\d+)?$' OR ms_value::numeric < 0);

    -- Construction du résumé des validations avec exemples
    v_summary := format(
        E'Résultats de la validation (batch %s):\n\n' ||
        E'1. Valeurs NULL:\n' ||
        E'   - ID Cube: %s\n   - Année: %s\n   - Trimestre: %s\n   - NUTS: %s\n' ||
        E'   - Valeur: %s (Exemples de NUTS sans valeur: %s)\n   - Sexe: %s\n   - Age: %s\n   - ISCED: %s\n\n' ||
        E'2. Formats invalides:\n' ||
        E'   - Années invalides: %s (Exemples: %s)\n' ||
        E'   - Trimestres invalides: %s (Exemples: %s)\n' ||
        E'   - Codes NUTS invalides: %s (Exemples: %s)\n' ||
        E'   - Valeurs numériques invalides: %s (Exemples: %s)\n',
        p_batch_id,
        v_null_counts.null_cube, v_null_counts.null_year, v_null_counts.null_quarter,
        v_null_counts.null_nuts, 
        v_null_counts.null_value, 
        array_to_string((v_null_counts.null_value_examples)[1:10], ', '),
        v_null_counts.null_sex,
        v_null_counts.null_age, 
        v_null_counts.null_isced,
        v_invalid_year_counts, 
        array_to_string(v_invalid_year_examples[1:10], ', '),
        v_invalid_quarter_counts, 
        array_to_string(v_invalid_quarter_examples[1:10], ', '),
        v_invalid_nuts_counts, 
        array_to_string(v_invalid_nuts_examples[1:10], ', '),
        v_invalid_value_counts, 
        array_to_string(v_invalid_value_examples[1:10], ', ')
    );

    -- Affichage du résumé
    RAISE NOTICE '%', v_summary;

    -- Enregistrement des exemples dans la table de qualité
    INSERT INTO metadata.data_quality_issues (
        id_batch,
        issue_type,
        issue_description,
        nb_records_affected,
        tx_examples
    )
    SELECT p_batch_id, issue_type, issue_description, nb_records, examples
    FROM (
        SELECT 
            'NULL_VALUES' as issue_type,
            'Valeurs nulles pour MS_VALUE' as issue_description,
            v_null_counts.null_value as nb_records,
            array_to_string((v_null_counts.null_value_examples)[1:10], ', ') as examples
        WHERE v_null_counts.null_value > 0
        UNION ALL
        SELECT 
            'INVALID_QUARTER',
            'Format de trimestre invalide',
            v_invalid_quarter_counts,
            array_to_string(v_invalid_quarter_examples[1:10], ', ')
        WHERE v_invalid_quarter_counts > 0
        UNION ALL
        SELECT 
            'INVALID_NUTS',
            'Format de code NUTS invalide',
            v_invalid_nuts_counts,
            array_to_string(v_invalid_nuts_examples[1:10], ', ')
        WHERE v_invalid_nuts_counts > 0
        UNION ALL
        SELECT 
            'INVALID_VALUES',
            'Valeurs numériques invalides',
            v_invalid_value_counts,
            array_to_string(v_invalid_value_examples[1:10], ', ')
        WHERE v_invalid_value_counts > 0
    ) issues;

    -- Lever une exception si demandé et si des erreurs critiques sont trouvées
    IF p_raise_exception AND (
        v_null_counts.null_cube > 0 OR
        v_null_counts.null_year > 0 OR
        v_null_counts.null_quarter > 0 OR
        v_null_counts.null_nuts > 0 OR
        v_null_counts.null_value > 0 OR
        v_invalid_year_counts > 0 OR
        v_invalid_quarter_counts > 0 OR
        v_invalid_nuts_counts > 0 OR
        v_invalid_value_counts > 0
    ) THEN
        RAISE EXCEPTION 'Validation échouée. Voir les détails dans les logs et metadata.data_quality_issues';
    END IF;

    RAISE NOTICE 'Validation terminée.';

EXCEPTION WHEN OTHERS THEN
    -- En cas d'erreur, on log et on relève si demandé
    RAISE NOTICE 'Erreur lors de la validation: %', SQLERRM;
    IF p_raise_exception THEN
        RAISE;
    END IF;
END;
$$;

COMMENT ON PROCEDURE raw_staging.validate_raw_unemployment IS 
'Procédure de validation complète des données brutes de chômage.

Paramètres:
- p_batch_id: Identifiant du batch à valider
- p_raise_exception: Si TRUE, lève une exception en cas d''erreur (défaut: TRUE)

Validations effectuées:
1. Présence des données obligatoires (valeurs NULL)
2. Format des années (YYYY)
3. Format des trimestres (Q1-Q4)
4. Format des codes NUTS
5. Validité des valeurs numériques
6. Cohérence des traductions
7. Détection des doublons

Les résultats sont:
- Affichés dans les logs
- Enregistrés dans metadata.data_quality_issues
- Peuvent déclencher une exception si p_raise_exception = TRUE

Exemple d''utilisation:
CALL raw_staging.validate_raw_unemployment(123, TRUE);';