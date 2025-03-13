-- 02_clean_staging/tables/clean_statistical_sectors.sql


SELECT utils.log_script_execution('create_clean_statistical_sectors.sql', 'RUNNING');

-- Création de la table
DROP TABLE IF EXISTS clean_staging.clean_statistical_sectors CASCADE;
CREATE TABLE clean_staging.clean_statistical_sectors (
    -- Clé technique
    id_sector SERIAL,
    
    -- Identifiants et année de validité
    cd_sector VARCHAR(9) NOT NULL,    -- Format: 5 chiffres + lettre + 2-3 chiffres
    year_validity INTEGER NOT NULL,    -- Année de validité
    
    -- Codes administratifs 
    cd_refnis VARCHAR(5) NOT NULL,    -- Pour jointure avec dim_geography
    cd_sub_munty VARCHAR(7),          -- Code sous-commune
    cd_dstr_refnis VARCHAR(5),        -- Code district
    cd_prov_refnis VARCHAR(5),        -- Code province
    cd_rgn_refnis VARCHAR(5),         -- Code région
    
    -- Codes NUTS
    cd_nuts_lv1 VARCHAR(5),
    cd_nuts_lv2 VARCHAR(5),
    cd_nuts_lv3 VARCHAR(5),
    
    -- Descriptions multilingues
    tx_sector_descr_fr TEXT,
    tx_sector_descr_nl TEXT,
    tx_sector_descr_de TEXT,
    tx_sector_descr_en TEXT,
    tx_sub_munty_fr TEXT,
    tx_sub_munty_nl TEXT,
    tx_sub_munty_de TEXT,
    tx_sub_munty_en TEXT,
    
    -- Informations géographiques
    geom_31370 geometry(MultiPolygon, 31370),  -- Géométrie principale en projection belge
    centroid geometry(Point, 31370),     -- Point central calculé
    ms_area_ha NUMERIC(10,2),            -- Surface en hectares
    ms_perimeter_m NUMERIC(10,2),        -- Périmètre en mètres
    
    -- Métadonnées
    id_batch INTEGER NOT NULL,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    PRIMARY KEY (cd_sector, year_validity),
    CONSTRAINT check_year CHECK (year_validity >= 1900 AND year_validity <= 2100)
);

-- Index pour optimiser les jointures fréquentes
CREATE INDEX IF NOT EXISTS idx_clean_sectors_refnis 
    ON clean_staging.clean_statistical_sectors(cd_refnis);

CREATE INDEX IF NOT EXISTS idx_clean_sectors_year 
    ON clean_staging.clean_statistical_sectors(year_validity);

-- Index spatial pour les requêtes géographiques
CREATE INDEX IF NOT EXISTS idx_clean_sectors_geom 
    ON clean_staging.clean_statistical_sectors USING GIST (geom);

CREATE INDEX IF NOT EXISTS idx_clean_sectors_centroid 
    ON clean_staging.clean_statistical_sectors USING GIST (centroid);

-- Création du trigger
DROP TRIGGER IF EXISTS trg_update_centroid ON clean_staging.clean_statistical_sectors;
CREATE TRIGGER trg_update_centroid
    BEFORE INSERT OR UPDATE OF geom
    ON clean_staging.clean_statistical_sectors
    FOR EACH ROW
    EXECUTE FUNCTION clean_staging.update_centroid();

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'clean_staging',
    'clean_statistical_sectors',
    'Table de référence des secteurs statistiques avec historique annuel',
    'STATBEL_SECTORS'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Ajout des commentaires
COMMENT ON TABLE clean_staging.clean_statistical_sectors IS 'Table de référence des secteurs statistiques belges avec historique annuel';
COMMENT ON COLUMN clean_staging.clean_statistical_sectors.cd_sector IS 'Code unique du secteur statistique';
COMMENT ON COLUMN clean_staging.clean_statistical_sectors.year_validity IS 'Année de validité du secteur';
COMMENT ON COLUMN clean_staging.clean_statistical_sectors.cd_refnis IS 'Code REFNIS pour jointure avec dim_geography';
COMMENT ON COLUMN clean_staging.clean_statistical_sectors.centroid IS 'Point central calculé automatiquement';

SELECT utils.log_script_execution('create_clean_statistical_sectors.sql', 'SUCCESS');