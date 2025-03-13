-- 05_functions/validation_utils.sql

-- Fonction pour valider le format REFNIS
CREATE OR REPLACE FUNCTION utils.validate_refnis(p_refnis text)
RETURNS BOOLEAN AS $$
BEGIN
    -- Vérifie si le REFNIS:
    -- - n'est pas NULL
    -- - a exactement 5 caractères
    -- - ne contient que des chiffres
    RETURN p_refnis IS NOT NULL 
        AND length(p_refnis) = 5 
        AND p_refnis ~ '^[0-9]{5}$';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Fonction pour valider les REFNIS en masse dans une table
CREATE OR REPLACE FUNCTION utils.validate_refnis_batch(
    p_schema text,
    p_table text,
    p_column text,
    p_batch_id integer
) RETURNS TABLE (
    invalid_count bigint,
    invalid_values text[]
) AS $$
DECLARE
    v_sql text;
BEGIN
    v_sql := format(
        'SELECT COUNT(*) as invalid_count,
                array_agg(DISTINCT %I) as invalid_values
         FROM %I.%I
         WHERE id_batch = $1
         AND %I IS NOT NULL
         AND NOT utils.validate_refnis(%I)',
        p_column, p_schema, p_table, p_column, p_column
    );
    
    RETURN QUERY EXECUTE v_sql USING p_batch_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION utils.validate_refnis_batch(text, text, text, integer) IS 
'Valide en masse les codes REFNIS dans une colonne d''une table.
Arguments:
- p_schema: schéma de la table
- p_table: nom de la table
- p_column: nom de la colonne contenant les REFNIS
- p_batch_id: ID du batch à valider

Retourne:
- invalid_count: nombre de REFNIS invalides
- invalid_values: tableau des valeurs invalides distinctes';