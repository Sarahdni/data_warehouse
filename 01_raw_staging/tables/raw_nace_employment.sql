-- 01_raw_staging/tables/raw_nace_employment.sql

CREATE TABLE IF NOT EXISTS raw_staging.raw_nace_employment (
    -- Clé technique
    id_raw SERIAL PRIMARY KEY,
    
    -- Données brutes du CSV
    
    cd_nis_stat_unt_cls VARCHAR(3),
    tx_nis_stat_unt_cls_fr_lvl1 VARCHAR(25),
    tx_nis_stat_unt_cls_nl_lvl1 VARCHAR(25),
    tx_nis_stat_unt_cls_en_lvl1 VARCHAR(25),
    cd_nace VARCHAR(10),
    tx_nace_fr_lvl1 VARCHAR(250),
    tx_nace_nl_lvl1 VARCHAR(250),
    tx_nace_en_lvl1 VARCHAR(250),
    tx_nace_fr_lvl2 VARCHAR(250),
    tx_nace_nl_lvl2 VARCHAR(250),
    tx_nace_en_lvl2 VARCHAR(250),
    tx_nace_fr_lvl3 VARCHAR(250),
    tx_nace_nl_lvl3 VARCHAR(250),
    tx_nace_en_lvl3 VARCHAR(250),
    tx_nace_fr_lvl4 VARCHAR(250),
    tx_nace_nl_lvl4 VARCHAR(250),
    tx_nace_en_lvl4 VARCHAR(250),
    tx_nace_fr_lvl5 VARCHAR(250),
    tx_nace_nl_lvl5 VARCHAR(250),
    tx_nace_en_lvl5 VARCHAR(250),
    cd_adm_dstr_refnis VARCHAR(100),
    tx_adm_dstr_descr_fr VARCHAR(100),
    tx_adm_dstr_descr_nl VARCHAR(100),
    tx_adm_dstr_descr_en VARCHAR(100),
    cd_rgn_refnis VARCHAR(100),
    cd_prov_refnis VARCHAR(100),
    tx_prov_descr_fr VARCHAR(100),
    tx_prov_descr_nl VARCHAR(100),
    tx_prov_descr_en VARCHAR(100),
    tx_rgn_descr_fr VARCHAR(100),
    tx_rgn_descr_nl VARCHAR(100),
    tx_rgn_descr_en VARCHAR(100),
    ms_num_vat VARCHAR(20),
    ms_num_vat_start VARCHAR(10),
    ms_num_vat_stop VARCHAR(10),

    -- Métadonnées de chargement
    id_batch INTEGER,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);



-- Index
CREATE INDEX IF NOT EXISTS idx_raw_nace_employment_batch 
    ON raw_staging.raw_nace_employment(id_batch);

COMMENT ON TABLE raw_staging.raw_nace_employment IS 
'Table de staging brute pour les données de l''emploi par secteur nace';