-- 01_raw_staging/validation/validate_raw_statistical_sectors.sql

CREATE TYPE raw_staging.invalid_format_stats AS (
    invalid_sectors integer,
    invalid_munty integer,
    invalid_submunty integer
);

CREATE OR REPLACE PROCEDURE raw_staging.validate_raw_statistical_sectors(
    p_batch_id INTEGER,
    p_raise_exception BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_null_counts record;
    v_invalid_format_counts raw_staging.invalid_format_stats; 
    v_invalid_sector_examples text[];
    v_invalid_munty_examples text[];
    v_invalid_submunty_examples text[];
    v_missing_descriptions record;
    v_invalid_geom_counts record;
BEGIN
    RAISE NOTICE 'Début de la validation pour le batch %', p_batch_id;
    
    -- 1. Vérification des valeurs NULL
    SELECT 
        COUNT(*) FILTER (WHERE cd_sector IS NULL) as null_sector,
        COUNT(*) FILTER (WHERE cd_munty_refnis IS NULL) as null_munty,
        COUNT(*) FILTER (WHERE cd_sub_munty IS NULL) as null_submunty,
        COUNT(*) FILTER (WHERE geom_31370 IS NULL) as null_geom
    INTO v_null_counts
    FROM raw_staging.raw_statistical_sectors
    WHERE id_batch = p_batch_id;

   -- 2. Validation des formats et récupération des exemples en une seule requête
    WITH invalid_formats AS (
        SELECT 
            COUNT(*) FILTER (WHERE cd_sector !~ '^[0-9]{5}[A-Z][0-9]{2,3}(-)?$'
                            AND cd_sector !~ '^[0-9]{5}[A-Z][0-9][A-Z]{2}$' AND cd_sector !~ '^[0-9]{7}[A-Z]{2}$') as invalid_sectors,
            COUNT(*) FILTER (WHERE cd_munty_refnis !~ '^[0-9]{5}$') as invalid_munty,
            COUNT(*) FILTER (WHERE cd_sub_munty !~ '^[0-9]{5}[A-Z]$' AND cd_sub_munty !~ '^[0-9]{6}$') as invalid_submunty,  
            array_agg(DISTINCT cd_sector) FILTER (WHERE cd_sector !~ '^[0-9]{5}[A-Z][0-9]{2,3}(-)?$'
                                                AND cd_sector !~ '^[0-9]{5}[A-Z][0-9][A-Z]{2}$' AND cd_sector !~ '^[0-9]{7}[A-Z]{2}$') as invalid_sector_examples,
            array_agg(DISTINCT cd_munty_refnis) FILTER (WHERE cd_munty_refnis !~ '^[0-9]{5}$') as invalid_munty_examples,
            array_agg(DISTINCT cd_sub_munty) FILTER (WHERE cd_sub_munty !~ '^[0-9]{5}[A-Z]$' AND cd_sub_munty !~ '^[0-9]{6}$') as invalid_submunty_examples
        FROM raw_staging.raw_statistical_sectors
        WHERE id_batch = p_batch_id
    )
    SELECT 
        invalid_sectors, invalid_munty, invalid_submunty,
        invalid_sector_examples[1:5], invalid_munty_examples[1:5], invalid_submunty_examples[1:5]
    INTO 
        v_invalid_format_counts.invalid_sectors, 
        v_invalid_format_counts.invalid_munty, 
        v_invalid_format_counts.invalid_submunty,
        v_invalid_sector_examples,
        v_invalid_munty_examples,
        v_invalid_submunty_examples
    FROM invalid_formats;


    -- 3. Validation des descriptions
    SELECT 
        COUNT(*) FILTER (WHERE tx_sector_descr_fr IS NULL) as missing_sector_fr,
        COUNT(*) FILTER (WHERE tx_sector_descr_nl IS NULL) as missing_sector_nl,
        COUNT(*) FILTER (WHERE tx_sub_munty_fr IS NULL) as missing_submunty_fr,
        COUNT(*) FILTER (WHERE tx_sub_munty_nl IS NULL) as missing_submunty_nl,
        COUNT(*) FILTER (WHERE tx_munty_descr_fr IS NULL) as missing_munty_fr,
        COUNT(*) FILTER (WHERE tx_munty_descr_nl IS NULL) as missing_munty_nl
    INTO v_missing_descriptions
    FROM raw_staging.raw_statistical_sectors
    WHERE id_batch = p_batch_id;

    -- 4. Validation géométrique
    SELECT 
        COUNT(*) FILTER (WHERE ms_area_ha <= 0) as invalid_area,
        COUNT(*) FILTER (WHERE ms_perimeter_m <= 0) as invalid_perimeter
    INTO v_invalid_geom_counts
    FROM raw_staging.raw_statistical_sectors
    WHERE id_batch = p_batch_id;

    -- Affichage des résultats
    RAISE NOTICE 'Résultats de la validation:';
    RAISE NOTICE '1. Valeurs NULL:';
    RAISE NOTICE '   - Secteurs: %', v_null_counts.null_sector;
    RAISE NOTICE '   - Communes: %', v_null_counts.null_munty;
    RAISE NOTICE '   - Sous-communes: %', v_null_counts.null_submunty;
    RAISE NOTICE '   - Géométries: %', v_null_counts.null_geom;

    RAISE NOTICE '2. Formats invalides:';
    RAISE NOTICE '   - Codes secteur: % (exemples: %)', 
        COALESCE(v_invalid_format_counts.invalid_sectors, 0),
        array_to_string(v_invalid_sector_examples, ', ');
    RAISE NOTICE '   - Codes commune: % (exemples: %)', 
        COALESCE(v_invalid_format_counts.invalid_munty, 0),
        array_to_string(v_invalid_munty_examples, ', ');
    RAISE NOTICE '   - Codes sous-commune: % (exemples: %)', 
        COALESCE(v_invalid_format_counts.invalid_submunty, 0),
        array_to_string(v_invalid_submunty_examples, ', ');

    RAISE NOTICE '3. Descriptions manquantes par langue:';
    RAISE NOTICE '   Secteur FR: %', v_missing_descriptions.missing_sector_fr;
    RAISE NOTICE '   Secteur NL: %', v_missing_descriptions.missing_sector_nl;
    RAISE NOTICE '   Sous-commune FR: %', v_missing_descriptions.missing_submunty_fr;
    RAISE NOTICE '   Sous-commune NL: %', v_missing_descriptions.missing_submunty_nl;
    RAISE NOTICE '   Commune FR: %', v_missing_descriptions.missing_munty_fr;
    RAISE NOTICE '   Commune NL: %', v_missing_descriptions.missing_munty_nl;

    RAISE NOTICE '4. Anomalies géométriques:';
    RAISE NOTICE '   - Surfaces invalides: %', v_invalid_geom_counts.invalid_area;
    RAISE NOTICE '   - Périmètres invalides: %', v_invalid_geom_counts.invalid_perimeter;

    -- Lever une exception si demandé et si des erreurs sont trouvées
    IF p_raise_exception AND (
        v_null_counts.null_sector > 0 OR
        v_invalid_format_counts.invalid_sectors > 0 OR
        v_invalid_format_counts.invalid_munty > 0 OR
        v_invalid_format_counts.invalid_submunty > 0 OR
        v_missing_descriptions > 0 OR
        v_invalid_geom_counts.invalid_area > 0 OR
        v_invalid_geom_counts.invalid_perimeter > 0
    ) THEN
        RAISE EXCEPTION 'Validation échouée. Voir les détails dans les logs.';
    END IF;

    RAISE NOTICE 'Validation terminée avec succès.';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Erreur durant la validation: %', SQLERRM;
    IF p_raise_exception THEN
        RAISE;
    END IF;
END;
$$;

COMMENT ON PROCEDURE raw_staging.validate_raw_statistical_sectors IS 
'Procédure de validation complète des données brutes des secteurs statistiques.
Arguments:
- p_batch_id : identifiant du batch à valider (obligatoire)
- p_raise_exception : si TRUE, lève une exception en cas d''erreur (défaut: TRUE)

Vérifie:
1. Présence des données obligatoires
2. Format des codes (secteur, commune, sous-commune)
3. Présence des descriptions bilingues
4. Validité des données géométriques

Exemple d''utilisation:
CALL raw_staging.validate_raw_statistical_sectors(70);
ou
CALL raw_staging.validate_raw_statistical_sectors(70, TRUE);';