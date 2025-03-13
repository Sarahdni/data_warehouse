-- 05_functions/utils.apply_refnis_ratio.sql


CREATE OR REPLACE FUNCTION utils.apply_refnis_ratio(
    p_year INTEGER,
    p_refnis VARCHAR(5),
    p_value NUMERIC,
    p_column_name TEXT
)
RETURNS NUMERIC AS $$
DECLARE
    v_result NUMERIC;
BEGIN
    -- Pour les années >= 2019 ou les communes non fusionnées, pas de transformation
    IF p_year >= 2019 OR p_refnis NOT IN ('12041', '45068', '72042', '72043', '44085') THEN
        RETURN p_value;
    END IF;

    -- Pour les communes fusionnées avant 2019, appliquer les ratios
    SELECT COALESCE(SUM(CAST(p_value AS NUMERIC) * r.rt_split_ratio), 0)
    INTO v_result
    FROM metadata.refnis_changes_2019 rc
    JOIN metadata.refnis_split_ratios r 
        ON r.cd_refnis_pre2019 = rc.cd_refnis_pre2019 
        AND r.cd_refnis_post2019 = p_refnis
    WHERE rc.cd_refnis_post2019 = p_refnis;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;