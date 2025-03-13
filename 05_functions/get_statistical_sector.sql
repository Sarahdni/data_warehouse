-- 05_functions/et_statistical_sector.sql

-- Fonction utilitaire pour rechercher un secteur statistique pour une année donnée
CREATE OR REPLACE FUNCTION dw.get_statistical_sector(
  p_sector_code VARCHAR,  -- Code du secteur à rechercher
  p_year INTEGER          -- Année pour laquelle on veut les données du secteur
)
RETURNS SETOF dw.dim_statistical_sectors AS $$
SELECT * 
FROM dw.dim_statistical_sectors
WHERE cd_sector = p_sector_code                           -- Filtre sur le code du secteur
  AND date_trunc('year', dt_start) = to_date(p_year::text, 'YYYY');  -- Filtre sur l'année de début de validité
$$ LANGUAGE sql;