
-- Ajuster les dates de validité dans dim_geography pour ces communes pour couvrir la période 2005-2018
UPDATE dw.dim_geography 
SET dt_start = '2005-01-01'
WHERE cd_refnis IN (
    '12041', '44083', '44084', '44085', '45068', '51067', '51068', '51069',
    '55085', '55086', '57096', '57097', '58001', '58002', '58003', '58004',
    '72042', '72043'
);




-- Voir les noms de ces communes
SELECT DISTINCT cd_munty_refnis, 
       tx_munty_descr_fr 
FROM raw_staging.raw_tax_income 
WHERE cd_munty_refnis IN (
    '12041', '44083', '44084', '44085', '45068', '51067', '51068', '51069',
    '55085', '55086', '57096', '57097', '58001', '58002', '58003', '58004',
    '72042', '72043'
)
AND cd_year::integer BETWEEN 2005 AND 2018
ORDER BY cd_munty_refnis;



SELECT 
    g.cd_refnis, 
    g.tx_name_fr 
FROM dw.dim_geography g 
WHERE g.cd_refnis IN (
    SELECT DISTINCT cd_munty_refnis
    FROM raw_staging.raw_tax_income 
    WHERE cd_munty_refnis IN (
        '12041', '44083', '44084', '44085', '45068', '51067', '51068', '51069',
        '55085', '55086', '57096', '57097', '58001', '58002', '58003', '58004',
        '72042', '72043'
    ) 
    AND cd_year::integer < 2019
) 
AND (g.dt_end = '2018-12-31' OR g.dt_start = '2019-01-01')
ORDER BY g.cd_refnis;



SELECT DISTINCT
    r.cd_munty_refnis,
    r.tx_munty_descr_fr,
    gbefore.cd_refnis AS cd_refnis_before_2019,
    gafter.cd_refnis AS cd_refnis_after_2019
FROM raw_staging.raw_tax_income r
LEFT JOIN dw.dim_geography gbefore 
    ON r.cd_munty_refnis = gbefore.cd_refnis 
    AND gbefore.dt_end = '2018-12-31'
LEFT JOIN dw.dim_geography gafter 
    ON r.cd_munty_refnis = gafter.cd_refnis 
    AND gafter.dt_start = '2019-01-01'
WHERE r.cd_munty_refnis IN (
    '12041', '44083', '44084', '44085', '45068', '51067', '51068', '51069',
    '55085', '55086', '57096', '57097', '58001', '58002', '58003', '58004',
    '72042', '72043'
)
AND r.cd_year::integer BETWEEN 2005 AND 2018
ORDER BY r.cd_munty_refnis;





----- trouve rles similitudes entre les deux table pour les codes-----
SELECT
    r.cd_munty_refnis,
    r.tx_munty_descr_fr,
    g.cd_refnis AS cd_refnis_before_2019
FROM (
    SELECT DISTINCT
        cd_munty_refnis,
        tx_munty_descr_fr
    FROM raw_staging.raw_tax_income
    WHERE cd_munty_refnis IN (
        '12041', '44083', '44084', '44085', '45068', '51067', '51068', '51069',
        '55085', '55086', '57096', '57097', '58001', '58002', '58003', '58004',
        '72042', '72043'
    )
    AND cd_year::integer BETWEEN 2005 AND 2018
) r
LEFT JOIN dw.dim_geography g
    ON r.tx_munty_descr_fr = g.tx_name_fr
    AND g.dt_end = '2018-12-31'
ORDER BY r.cd_munty_refnis;



SELECT 
    cd_refnis, 
    tx_name_fr, 
    tx_name_nl,
    dt_start,
    dt_end
FROM dw.dim_geography
WHERE cd_refnis IN ('12034', '12029', '45017', '45057', '71047', '71037', '72020', '72025')
ORDER BY cd_refnis;






-- Comparaison entre clean_staging et fact pour l'année 2022
WITH clean_data AS (
    SELECT 
        c.cd_munty_refnis,
        c.cd_year,
        c.fl_valid_munty_refnis,
        c.fl_valid_counts,
        c.fl_valid_amounts,
        c.fl_valid_hierarchy
    FROM clean_staging.clean_tax_income c
    WHERE c.cd_year = 2022
),
fact_data AS (
    SELECT 
        g.cd_refnis,
        d.cd_year
    FROM dw.fact_tax_income f
    JOIN dw.dim_geography g ON f.id_geography = g.id_geography
    JOIN dw.dim_date d ON f.id_date = d.id_date
    WHERE d.cd_year = 2022
    AND f.fl_current = TRUE
)
SELECT 
    c.cd_munty_refnis,
    c.fl_valid_munty_refnis as "REFNIS valide",
    c.fl_valid_counts as "Comptages valides",
    c.fl_valid_amounts as "Montants valides",
    c.fl_valid_hierarchy as "Hiérarchie valide",
    CASE 
        WHEN f.cd_refnis IS NULL THEN 'Manquant dans FACT'
        ELSE 'Présent dans FACT'
    END as "Statut"
FROM clean_data c
LEFT JOIN fact_data f ON c.cd_munty_refnis = f.cd_refnis
WHERE f.cd_refnis IS NULL  -- Pour ne voir que les lignes manquantes
ORDER BY c.cd_munty_refnis;


INSERT INTO dw.dim_building_type (
    cd_building_type,
    tx_building_type_fr,
    tx_building_type_nl,
    tx_building_type_de,
    tx_building_type_en,
    dt_valid_from,
    fl_current
) VALUES 
('R7',
    'appartements, flats, studios',
    'appartementen, flats, studio''s',
    'Wohnungen, Flats, Studios',
    'apartments, flats, studios',
    '2025-01-28',
    true
),
('R8',
    'terrains à bâtir',
    'bouwgronden',
    'Bauland',
    'building plots',
    '2025-01-28',
    true
),
('R9',
    'maisons d''habitation',
    'gewone woonhuizen',
    'Wohnhäuser',
    'residential houses',
    '2025-01-28',
    true
),
('R10',
    'villas, bungalows, maisons de campagne',
    'villa''s bungalows, landhuizen',
    'Villen, Bungalows, Landhäuser',
    'villas, bungalows, country houses',
    '2025-01-28',
    true
);





WITH clean_data AS (
    SELECT 
        c.cd_year,
        c.cd_period,
        c.cd_refnis,
        c.tx_property_type_fr,
        c.ms_total_transactions,
        c.fl_confidential
    FROM clean_staging.clean_immo_by_municipality c
),
fact_data AS (
    SELECT 
        f.id_fact,
        d.cd_year,
        CASE 
            WHEN d.cd_period_type = 'Q' THEN 'Q' || d.cd_quarter
            WHEN d.cd_period_type = 'S' THEN 'S' || d.cd_semester
            ELSE 'Y'
        END as period,
        g.cd_refnis,
        CASE f.cd_building_type
            WHEN 'R7' THEN 'appartements, flats, studios'
            WHEN 'R8' THEN 'terrains à bâtir'
            WHEN 'R9' THEN 'maisons d''habitation'
            WHEN 'R10' THEN 'villas, bungalows, maisons de campagne'
        END as property_type_fr,
        f.ms_total_transactions,
        f.fl_confidential
    FROM dw.fact_real_estate_municipality f
    JOIN dw.dim_date d ON f.id_date = d.id_date
    JOIN dw.dim_geography g ON f.id_geography = g.id_geography
)
SELECT 
    c.cd_year,
    c.cd_period,
    c.cd_refnis,
    c.tx_property_type_fr as clean_property_type,
    c.ms_total_transactions as clean_transactions,
    c.fl_confidential as clean_confidential,
    f.cd_year as fact_year,
    f.period as fact_period,
    f.property_type_fr as fact_property_type,
    f.ms_total_transactions as fact_transactions,
    f.fl_confidential as fact_confidential
FROM clean_data c
LEFT JOIN fact_data f ON 
    c.cd_year = f.cd_year 
    AND c.cd_period = f.period
    AND c.cd_refnis = f.cd_refnis
    AND c.tx_property_type_fr = f.property_type_fr
WHERE f.cd_refnis IS NULL  -- Les lignes qui n'ont pas de correspondance dans fact
ORDER BY c.cd_year, c.cd_period, c.cd_refnis;




WITH fact_data AS (
    SELECT 
        f.id_fact,
        d.cd_year,
        d.cd_period_type,
        CASE 
            WHEN d.cd_period_type = 'Q' THEN 'Q' || d.cd_quarter
            WHEN d.cd_period_type = 'S' THEN 'S' || d.cd_semester
            WHEN d.cd_period_type = 'Y' THEN 'Y'
        END as period,
        g.cd_refnis,
        f.cd_building_type,
        f.ms_total_transactions,
        f.fl_confidential
    FROM dw.fact_real_estate_municipality f
    JOIN dw.dim_date d ON f.id_date = d.id_date
    JOIN dw.dim_geography g ON f.id_geography = g.id_geography
    WHERE f.id_batch = 1
)
SELECT 
    f.cd_year,
    f.period,
    f.cd_refnis,
    CASE f.cd_building_type
        WHEN 'R7' THEN 'appartements, flats, studios'
        WHEN 'R8' THEN 'terrains à bâtir'
        WHEN 'R9' THEN 'maisons d''habitation'
        WHEN 'R10' THEN 'villas, bungalows, maisons de campagne'
    END as property_type,
    f.ms_total_transactions,
    f.fl_confidential
FROM fact_data f
LEFT JOIN clean_staging.clean_immo_by_municipality c ON 
    f.cd_year = c.cd_year 
    AND f.period = c.cd_period
    AND f.cd_refnis = c.cd_refnis
    AND (
        (f.cd_building_type = 'R7' AND c.tx_property_type_fr = 'appartements, flats, studios')
        OR (f.cd_building_type = 'R8' AND c.tx_property_type_fr = 'terrains à bâtir')
        OR (f.cd_building_type = 'R9' AND c.tx_property_type_fr = 'maisons d''habitation')
        OR (f.cd_building_type = 'R10' AND c.tx_property_type_fr = 'villas, bungalows, maisons de campagne')
    )
    AND c.id_batch = 1
WHERE c.id_clean IS NULL
ORDER BY f.cd_year, f.period, f.cd_refnis;




SELECT 
    d.cd_year,
    COUNT(DISTINCT f.id_geography) as nombre_communes_agregees,
    SUM(f.nb_aggregated_sectors) as total_secteurs_agreges,
    COUNT(*) as nombre_enregistrements
FROM dw.fact_real_estate_sector f
JOIN dw.dim_date d ON f.id_date = d.id_date
WHERE f.fl_aggregated_sectors = TRUE
GROUP BY d.cd_year
ORDER BY d.cd_year;



WITH price_violations AS (
    SELECT 
        id_batch,
        cd_year,
        cd_sector,
        cd_type,
        CASE
            WHEN ms_price_p10 < 0 OR ms_price_p25 < 0 OR ms_price_p50 < 0 OR ms_price_p75 < 0 OR ms_price_p90 < 0 THEN 'Prix négatifs'
            WHEN ms_price_p10 > ms_price_p25 OR 
                 ms_price_p25 > ms_price_p50 OR 
                 ms_price_p50 > ms_price_p75 OR 
                 ms_price_p75 > ms_price_p90 THEN 'Ordre des percentiles incorrect'
            ELSE 'OK'
        END as violation_type,
        ms_price_p10,
        ms_price_p25,
        ms_price_p50,
        ms_price_p75,
        ms_price_p90,
        nb_transactions
    FROM clean_staging.clean_real_estate_sector
    WHERE nb_transactions >= 16  -- Équivalent à fl_confidential = FALSE
)
SELECT 
    violation_type,
    COUNT(*) as nb_violations,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as pourcentage
FROM price_violations
WHERE violation_type != 'OK'
GROUP BY violation_type
ORDER BY nb_violations DESC;




WITH missing_geo AS (
    SELECT 
        c.cd_year,
        SUBSTRING(c.cd_refnis FROM 1 FOR 5) as commune_refnis,
        COUNT(*) as nb_records,
        STRING_AGG(DISTINCT c.cd_type, ', ') as types,
        MAX(c.nb_transactions) as max_transactions
    FROM clean_staging.clean_real_estate_sector c
    LEFT JOIN dw.dim_geography g 
        ON g.cd_refnis = SUBSTRING(c.cd_refnis FROM 1 FOR 5)
        AND g.cd_level = 4
        AND make_date(c.cd_year::INTEGER, 1, 1) BETWEEN g.dt_start AND g.dt_end
    WHERE g.id_geography IS NULL
        AND c.cd_year >= '2019'  -- Concentrons-nous sur les années avec des missing geography
    GROUP BY c.cd_year, SUBSTRING(c.cd_refnis FROM 1 FOR 5)
)
SELECT 
    'TOTAL' as cd_year,
    COUNT(DISTINCT commune_refnis) as nb_communes,
    SUM(nb_records) as total_records,
    NULL as types,
    NULL as max_transactions,
    NULL as tx_name_fr,
    NULL as tx_name_nl,
    NULL as cd_lau,
    NULL as fl_current,
    NULL as dt_start,
    NULL as dt_end
FROM missing_geo
UNION ALL
SELECT 
    cd_year::text,
    1,
    nb_records,
    types,
    max_transactions,
    g.tx_name_fr,
    g.tx_name_nl,
    g.cd_lau,
    g.fl_current,
    g.dt_start,
    g.dt_end
FROM missing_geo m
LEFT JOIN dw.dim_geography g 
    ON g.cd_refnis = m.commune_refnis 
    AND g.cd_level = 4
ORDER BY cd_year;
SELECT SUM(nb_records) as total_records_manquants
FROM (
    SELECT 
        cd_year,
        SUBSTRING(cd_refnis FROM 1 FOR 5) as commune_refnis,
        COUNT(*) as nb_records
    FROM clean_staging.clean_real_estate_sector c
    LEFT JOIN dw.dim_geography g 
        ON g.cd_refnis = SUBSTRING(c.cd_refnis FROM 1 FOR 5)
        AND g.cd_level = 4
        AND make_date(c.cd_year::INTEGER, 1, 1) BETWEEN g.dt_start AND g.dt_end
    WHERE g.id_geography IS NULL
        AND c.cd_year >= '2019'
    GROUP BY cd_year, SUBSTRING(cd_refnis FROM 1 FOR 5)
) as subquery;





WITH problematic_data AS (
    SELECT 
        c.cd_refnis,
        SUBSTRING(c.cd_refnis FROM 1 FOR 5) as commune_refnis,
        c.cd_year,
        rc.cd_refnis_pre2019,
        rc.cd_refnis_post2019,
        g_new.id_geography as new_id,
        g_old.id_geography as old_id
    FROM clean_staging.clean_real_estate_sector c
    LEFT JOIN metadata.refnis_changes_2019 rc 
        ON rc.cd_refnis_pre2019 = SUBSTRING(c.cd_refnis FROM 1 FOR 5)
    LEFT JOIN dw.dim_geography g_new ON
        COALESCE(rc.cd_refnis_post2019, SUBSTRING(c.cd_refnis FROM 1 FOR 5)) = g_new.cd_refnis
        AND g_new.cd_level = '4'
        AND make_date(c.cd_year::INTEGER, 1, 1) BETWEEN g_new.dt_start AND g_new.dt_end
    LEFT JOIN dw.dim_geography g_old ON
        SUBSTRING(c.cd_refnis FROM 1 FOR 5) = g_old.cd_refnis
        AND g_old.cd_level = '4'
        AND make_date(c.cd_year::INTEGER, 1, 1) BETWEEN g_old.dt_start AND g_old.dt_end
    WHERE c.id_batch = 35
        AND g_new.id_geography IS NULL 
        AND g_old.id_geography IS NULL
)
SELECT DISTINCT * FROM problematic_data;
