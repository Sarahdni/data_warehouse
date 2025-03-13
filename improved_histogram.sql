-- improved_histogram.sql

CREATE OR REPLACE FUNCTION improved_histogram(
    p_property_type text,
    p_num_bins integer DEFAULT 10
)
RETURNS TABLE (
    price_range text,
    property_count bigint,
    visualization text
) AS $$
DECLARE
    v_max_count bigint;
BEGIN
    RETURN QUERY
    WITH price_bounds AS (
        SELECT 
            MIN(ms_mean_price) as min_price,
            MAX(ms_mean_price) as max_price,
            COUNT(*) as total_count
        FROM clean_staging.clean_immo_by_municipality
        WHERE tx_property_type_fr = p_property_type
        AND id_batch = 1
        AND ms_mean_price IS NOT NULL
    ),
    bins AS (
        SELECT
            width_bucket(
                ms_mean_price, 
                min_price, 
                max_price, 
                p_num_bins
            ) as bucket,
            COUNT(*) as count
        FROM clean_staging.clean_immo_by_municipality, price_bounds
        WHERE tx_property_type_fr = p_property_type
        AND id_batch = 1
        AND ms_mean_price IS NOT NULL
        GROUP BY bucket
        ORDER BY bucket
    ),
    max_count AS (
        SELECT MAX(count) as max_count FROM bins
    )
    SELECT 
        CASE 
            WHEN bucket IS NULL THEN 'Valeurs manquantes'
            ELSE format('[%s - %s]',
                to_char(min_price + (bucket-1) * (max_price-min_price)/p_num_bins, 'FM999,999,999.99'),
                to_char(min_price + bucket * (max_price-min_price)/p_num_bins, 'FM999,999,999.99')
            )
        END,
        count,
        repeat('■', GREATEST(1, (count * 50 / max_count)::integer))
    FROM bins
    CROSS JOIN price_bounds
    CROSS JOIN max_count
    ORDER BY bucket;

    -- Ajouter le nombre de valeurs manquantes
    RETURN QUERY
    SELECT 
        'Valeurs manquantes'::text,
        COUNT(*)::bigint,
        repeat('■', GREATEST(1, (COUNT(*) * 50 / (
            SELECT MAX(count) FROM (
                SELECT COUNT(*) as count
                FROM clean_staging.clean_immo_by_municipality
                WHERE tx_property_type_fr = p_property_type
                AND id_batch = 1
                GROUP BY CASE WHEN ms_mean_price IS NULL THEN 1 ELSE 0 END
            ) x
        ))::integer))
    FROM clean_staging.clean_immo_by_municipality
    WHERE tx_property_type_fr = p_property_type
    AND id_batch = 1
    AND ms_mean_price IS NULL
    HAVING COUNT(*) > 0;
END;
$$ LANGUAGE plpgsql;