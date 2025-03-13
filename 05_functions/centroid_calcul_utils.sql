-- 05_functions/centroid_calcul_utils.sql

SELECT utils.log_script_execution('centroid_calcul_utils.sql', 'RUNNING');

-- Création de la fonction pour le calcul du centroïde
CREATE OR REPLACE FUNCTION clean_staging.update_centroid()
RETURNS TRIGGER AS $$
BEGIN
    -- Modification ici : geom -> geom_31370
    NEW.centroid := ST_Centroid(NEW.geom_31370);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION clean_staging.update_centroid() IS 
    'Fonction trigger pour calculer automatiquement le centroïde d''une géométrie dans les tables avec une colonne geom_31370';

-- Création du trigger pour la table clean_statistical_sectors
DROP TRIGGER IF EXISTS trg_update_centroid ON clean_staging.clean_statistical_sectors;

CREATE TRIGGER trg_update_centroid
    BEFORE INSERT OR UPDATE OF geom_31370
    ON clean_staging.clean_statistical_sectors
    FOR EACH ROW
    EXECUTE FUNCTION clean_staging.update_centroid();

SELECT utils.log_script_execution('centroid_calcul_utils.sql', 'SUCCESS');