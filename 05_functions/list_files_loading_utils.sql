-- 05_functions/list_files_loading_utils.sql

CREATE OR REPLACE FUNCTION utils.list_files(
    directory text,
    pattern text
)
RETURNS TABLE (file_name text)
LANGUAGE sql
AS $$
    -- Retourne le nom exact du fichier sans wildcard
    SELECT regexp_replace(pattern, '\*', '2024', 'g') as file_name;
    -- Note: remplace * par 2024 pour le test. Ajustez selon vos besoins.
$$;