-- generate_ascii_histogram.sql

CREATE OR REPLACE FUNCTION simple_histogram(
    p_property_type text,
    p_num_bins integer DEFAULT 10
)
RETURNS TABLE (
    price_range text,
    property_count bigint
) AS $$
BEGIN
    RETURN QUERY
    WITH price_bounds AS (
        SELECT 
            MIN(ms_mean_price) as min_price,
            MAX(ms_mean_price) as max_price
        FROM clean_staging.clean_immo_by_municipality
        WHERE tx_property_type_fr = p_property_type
        AND id_batch = 1
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
        GROUP BY bucket
        ORDER BY bucket
    )
    SELECT 
        format('[%s - %s]',
            to_char(min_price + (bucket-1) * (max_price-min_price)/p_num_bins, 'FM999,999,999.00'),
            to_char(min_price + bucket * (max_price-min_price)/p_num_bins, 'FM999,999,999.00')
        ),
        count
    FROM bins, price_bounds
    ORDER BY bucket;
END;
$$ LANGUAGE plpgsql;