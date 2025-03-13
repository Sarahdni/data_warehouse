-- 01_raw_staging/tables/raw_household_cohabitation.sql

CREATE TABLE IF NOT EXISTS raw_staging.raw_household_cohabitation (
    -- Clé technique
    id_raw SERIAL PRIMARY KEY,
    
    -- Données brutes du CSV
    cd_year VARCHAR(4),
    cd_rgn_refnis VARCHAR(4),
    tx_rgn_descr_nl VARCHAR(100),
    tx_rgn_descr_fr VARCHAR(100),
    cd_sex CHAR(1),
    cd_age VARCHAR(10),
    cd_natlty VARCHAR(10),
    tx_natlty_nl VARCHAR(100),
    tx_natlty_fr VARCHAR(100),
    fl_cohab VARCHAR(1),
    tx_cohab_nl VARCHAR(100),
    tx_cohab_fr VARCHAR(100),
    ms_count VARCHAR(20),
    
    -- Traçabilité
    id_batch INTEGER,
    dt_import TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX IF NOT EXISTS idx_raw_cohab_batch 
    ON raw_staging.raw_household_cohabitation(id_batch);

COMMENT ON TABLE raw_staging.raw_household_cohabitation IS 
'Table de staging brute pour les données de cohabitation des ménages';