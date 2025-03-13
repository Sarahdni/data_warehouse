-- 02_clean_staging/validation/validate_clean_statistical_sectors.sql

CREATE OR REPLACE PROCEDURE clean_staging.validate_clean_statistical_sectors(
    p_batch_id INTEGER,
    p_raise_exception BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_null_counts record;
    v_invalid_format_counts record;
    v_invalid_sector_examples text[];
    v_invalid_refnis_examples text[];
    v_missing_descriptions record;
    v_invalid_geom_counts record;
    v_duplicate_sectors integer;
    v_has_critical_errors BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE 'Début de la validation pour le batch %', p_batch_id;
    
    -- 1. Vérification des valeurs NULL pour les champs obligatoires
    SELECT 
        COUNT(*) FILTER (WHERE cd_sector IS NULL) as null_sector,
        COUNT(*) FILTER (WHERE cd_refnis IS NULL) as null_refnis,
        COUNT(*) FILTER (WHERE year_validity IS NULL) as null_year,
        COUNT(*) FILTER (WHERE geom_31370 IS NULL) as null_geom
    INTO v_null_counts
    FROM clean_staging.clean_statistical_sectors
    WHERE id_batch = p_batch_id;

    -- 2. Validation des formats avec assignation directe aux variables
    WITH format_validation AS (
        SELECT 
            COUNT(*) FILTER (WHERE cd_sector !~ '^[0-9]{5}[A-Z][0-9]{2,3}(-)?$'
                        AND cd_sector !~ '^[0-9]{5}[A-Z][0-9][A-Z]{2}$' 
                        AND cd_sector !~ '^[0-9]{7}[A-Z]{2}$') as invalid_sectors,
            COUNT(*) FILTER (WHERE cd_refnis !~ '^[0-9]{5}$') as invalid_refnis
        FROM clean_staging.clean_statistical_sectors
        WHERE id_batch = p_batch_id
    )
    SELECT * INTO v_invalid_format_counts FROM format_validation;

    -- Récupération séparée des exemples
    SELECT 
        array_agg(DISTINCT cd_sector) FILTER (
            WHERE cd_sector !~ '^[0-9]{5}[A-Z][0-9]{2,3}(-)?$'
            AND cd_sector !~ '^[0-9]{5}[A-Z][0-9][A-Z]{2}$'
            AND cd_sector !~ '^[0-9]{7}[A-Z]{2}$'
        ),
        array_agg(DISTINCT cd_refnis) FILTER (
            WHERE cd_refnis !~ '^[0-9]{5}$'
        )
    INTO 
        v_invalid_sector_examples,
        v_invalid_refnis_examples
    FROM clean_staging.clean_statistical_sectors
    WHERE id_batch = p_batch_id;


    -- 3. Vérification des doublons
    SELECT COUNT(*)
    INTO v_duplicate_sectors
    FROM (
        SELECT cd_sector, year_validity
        FROM clean_staging.clean_statistical_sectors
        WHERE id_batch = p_batch_id
        GROUP BY cd_sector, year_validity
        HAVING COUNT(*) > 1
    ) dupes;

    -- 4. Validation des descriptions bilingues obligatoires (FR/NL)
    SELECT 
        COUNT(*) FILTER (WHERE tx_sector_descr_fr IS NULL) as missing_sector_fr,
        COUNT(*) FILTER (WHERE tx_sector_descr_nl IS NULL) as missing_sector_nl,
        COUNT(*) FILTER (WHERE cd_sub_munty IS NOT NULL AND tx_sub_munty_fr IS NULL) as missing_submunty_fr,
        COUNT(*) FILTER (WHERE cd_sub_munty IS NOT NULL AND tx_sub_munty_nl IS NULL) as missing_submunty_nl
    INTO v_missing_descriptions
    FROM clean_staging.clean_statistical_sectors
    WHERE id_batch = p_batch_id;

    -- 5. Validation géométrique
    SELECT 
        COUNT(*) FILTER (WHERE ms_area_ha <= 0) as invalid_area,
        COUNT(*) FILTER (WHERE ms_perimeter_m <= 0) as invalid_perimeter,
        COUNT(*) FILTER (WHERE centroid IS NULL) as missing_centroid,
        COUNT(*) FILTER (WHERE NOT ST_IsValid(geom_31370)) as invalid_geom
    INTO v_invalid_geom_counts
    FROM clean_staging.clean_statistical_sectors
    WHERE id_batch = p_batch_id;


    -- Séparer les erreurs critiques des avertissements
    v_has_critical_errors := (
        v_null_counts.null_sector > 0 OR
        v_null_counts.null_refnis > 0 OR
        v_null_counts.null_year > 0 OR
        v_null_counts.null_geom > 0 OR
        v_invalid_format_counts.invalid_sectors > 0 OR
        v_invalid_format_counts.invalid_refnis > 0 OR
        v_duplicate_sectors > 0 OR
        v_invalid_geom_counts.invalid_area > 0 OR
        v_invalid_geom_counts.invalid_perimeter > 0 OR
        v_invalid_geom_counts.missing_centroid > 0 OR
        v_invalid_geom_counts.invalid_geom > 0
    );

    -- Affichage des résultats
    RAISE NOTICE '1. Valeurs NULL:';
    RAISE NOTICE '   - Secteurs: %', v_null_counts.null_sector;
    RAISE NOTICE '   - REFNIS: %', v_null_counts.null_refnis;
    RAISE NOTICE '   - Année: %', v_null_counts.null_year;
    RAISE NOTICE '   - Géométrie: %', v_null_counts.null_geom;

    RAISE NOTICE '2. Formats invalides:';
    RAISE NOTICE '   - Codes secteur: % (exemples: %)', 
        COALESCE(v_invalid_format_counts.invalid_sectors, 0),
        array_to_string(v_invalid_sector_examples[1:5], ', ');
    RAISE NOTICE '   - Codes REFNIS: % (exemples: %)', 
        COALESCE(v_invalid_format_counts.invalid_refnis, 0),
        array_to_string(v_invalid_refnis_examples[1:5], ', ');

    RAISE NOTICE '3. Doublons:';
    RAISE NOTICE '   - Secteurs dupliqués: %', v_duplicate_sectors;

    RAISE NOTICE '4. Descriptions bilingues manquantes:';
    RAISE NOTICE '   - Secteur FR: %', v_missing_descriptions.missing_sector_fr;
    RAISE NOTICE '   - Secteur NL: %', v_missing_descriptions.missing_sector_nl;
    RAISE NOTICE '   - Sous-commune FR: %', v_missing_descriptions.missing_submunty_fr;
    RAISE NOTICE '   - Sous-commune NL: %', v_missing_descriptions.missing_submunty_nl;

    RAISE NOTICE '5. Anomalies géométriques:';
    RAISE NOTICE '   - Surfaces invalides: %', v_invalid_geom_counts.invalid_area;
    RAISE NOTICE '   - Périmètres invalides: %', v_invalid_geom_counts.invalid_perimeter;
    RAISE NOTICE '   - Centroïdes manquants: %', v_invalid_geom_counts.missing_centroid;
    RAISE NOTICE '   - Géométries invalides: %', v_invalid_geom_counts.invalid_geom;

    -- Lever une exception si demandé et si des erreurs sont trouvées
    IF p_raise_exception AND (
        v_null_counts.null_sector > 0 OR
        v_null_counts.null_refnis > 0 OR
        v_null_counts.null_year > 0 OR
        v_null_counts.null_geom > 0 OR
        v_invalid_format_counts.invalid_sectors > 0 OR
        v_invalid_format_counts.invalid_refnis > 0 OR
        v_duplicate_sectors > 0 OR
        v_invalid_geom_counts.invalid_area > 0 OR
        v_invalid_geom_counts.invalid_perimeter > 0 OR
        v_invalid_geom_counts.missing_centroid > 0 OR
        v_invalid_geom_counts.invalid_geom > 0
    ) THEN
        RAISE EXCEPTION 'Validation échouée. Voir les détails dans les logs.';
    END IF;

    -- Tracer les descriptions manquantes
    IF v_missing_descriptions.missing_sector_fr > 0 
    OR v_missing_descriptions.missing_sector_nl > 0 THEN
        INSERT INTO metadata.data_quality_issues (
            id_batch,
            issue_type,
            issue_description,
            nb_records_affected
        )
        VALUES (
            p_batch_id,
            'MISSING_DESCRIPTIONS',
            format('Descriptions manquantes - FR: %s, NL: %s', 
                v_missing_descriptions.missing_sector_fr, 
                v_missing_descriptions.missing_sector_nl),
            GREATEST(v_missing_descriptions.missing_sector_fr, 
                    v_missing_descriptions.missing_sector_nl)
        );
        
        RAISE NOTICE 'AVERTISSEMENT: Descriptions bilingues manquantes enregistrées dans metadata.data_quality_issues';
    END IF;

    RAISE NOTICE 'Validation terminée avec succès.';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Erreur durant la validation: %', SQLERRM;
    IF p_raise_exception THEN
        RAISE;
    END IF;
END;
$$;

COMMENT ON PROCEDURE clean_staging.validate_clean_statistical_sectors IS 
'Procédure de validation des données nettoyées des secteurs statistiques.
Arguments:
- p_batch_id : identifiant du batch à valider
- p_raise_exception : si TRUE, lève une exception en cas d''erreur (défaut: TRUE)

Vérifie:
1. Présence des données obligatoires
2. Format des codes (secteur, REFNIS)
3. Absence de doublons
4. Présence des descriptions bilingues obligatoires (FR/NL)
5. Validité des données géométriques (surface, périmètre, centroïde)

Exemple:
CALL clean_staging.validate_clean_statistical_sectors(68);
ou
CALL clean_staging.validate_clean_statistical_sectors(68, TRUE);';