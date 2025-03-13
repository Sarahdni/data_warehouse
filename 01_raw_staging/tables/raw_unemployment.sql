-- 01_raw_staging/tables/raw_unemployment.sql

CREATE TABLE IF NOT EXISTS raw_staging.raw_unemployment (
    -- Clé technique
    id_raw SERIAL PRIMARY KEY,
    
    -- Données brutes du CSV
    
    id_cube VARCHAR(4),
    cd_year VARCHAR(4),
    cd_quarter VARCHAR(6),
    cd_sex VARCHAR(6),
    cd_empmt_age VARCHAR(6),
    cd_nuts_lvl2 VARCHAR(6),
    tx_nuts_lvl2_descr_de VARCHAR(100),
    tx_nuts_lvl2_descr_en VARCHAR(100),
    tx_nuts_lvl2_descr_fr VARCHAR(100),
    tx_nuts_lvl2_descr_nl VARCHAR(100),
    cd_isced_2011 VARCHAR(50),
    tx_isced_2011_descr_de VARCHAR(255),
    tx_isced_2011_descr_en VARCHAR(255),
    tx_isced_2011_descr_fr VARCHAR(255),
    tx_isced_2011_descr_nl VARCHAR(255),
    cd_property VARCHAR(50),
    tx_property_descr_de VARCHAR(100),
    tx_property_descr_en VARCHAR(100),
    tx_property_descr_fr VARCHAR(100),
    tx_property_descr_nl VARCHAR(100),
    ms_value VARCHAR(20),

-- Métadonnées de chargement
    id_batch INTEGER,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- Index
CREATE INDEX IF NOT EXISTS idx_raw_unemployment_batch 
    ON raw_staging.raw_unemployment(id_batch);

COMMENT ON TABLE raw_staging.raw_unemployment IS 
'Table de staging brute pour les données de chômage';