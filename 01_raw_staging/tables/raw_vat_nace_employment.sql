-- 01_raw_staging/tables/raw_vat_nace_employment.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_raw_vat_nace_employment.sql', 'RUNNING');

-- Création de la table raw_vat_nace_employment (remplaçant raw_nace_employment)
CREATE TABLE IF NOT EXISTS raw_staging.raw_vat_nace_employment (
    -- Clé technique
    id_raw SERIAL PRIMARY KEY,
    
    -- Données brutes du CSV (format complet et minimal)
    -- Colonnes minimales (présentes dans tous les formats)
    cd_refnis VARCHAR(100),                    -- Uniquement dans format minimal
    cd_nis_stat_unt_cls VARCHAR(3),
    cd_nace VARCHAR(10),
    ms_num_vat VARCHAR(20),
    ms_num_vat_start VARCHAR(10),
    ms_num_vat_stop VARCHAR(10),
    
    -- Colonnes additionnelles (présentes uniquement dans le format complet)
    tx_nis_stat_unt_cls_fr_lvl1 VARCHAR(25),
    tx_nis_stat_unt_cls_nl_lvl1 VARCHAR(25),
    tx_nis_stat_unt_cls_en_lvl1 VARCHAR(25),
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

    -- Métadonnées de chargement
    id_batch INTEGER,                         -- Référence du batch de chargement
    tx_file_format VARCHAR(20),               -- Type de format détecté (MINIMAL ou COMPLET)
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX IF NOT EXISTS idx_raw_vat_nace_employment_batch 
    ON raw_staging.raw_vat_nace_employment(id_batch);

CREATE INDEX IF NOT EXISTS idx_raw_vat_nace_employment_nace 
    ON raw_staging.raw_vat_nace_employment(cd_nace);

CREATE INDEX IF NOT EXISTS idx_raw_vat_nace_employment_refnis 
    ON raw_staging.raw_vat_nace_employment(cd_refnis);

CREATE INDEX IF NOT EXISTS idx_raw_vat_nace_employment_adm_dstr 
    ON raw_staging.raw_vat_nace_employment(cd_adm_dstr_refnis);

-- Commentaires
COMMENT ON TABLE raw_staging.raw_vat_nace_employment IS 
'Table de staging brute pour les données de l''emploi par secteur nace.
Supporte deux formats de fichiers différents:
- Format MINIMAL: colonnes basiques (cd_refnis, cd_nis_stat_unt_cls, cd_nace, ms_num_vat*)
- Format COMPLET: ensemble complet de colonnes avec libellés multilingues';

-- Log du succès
SELECT utils.log_script_execution('create_raw_vat_nace_employment.sql', 'SUCCESS');

-- Création d'une vue pour assurer la compatibilité avec l'ancien nom de table
CREATE OR REPLACE VIEW raw_staging.raw_nace_employment AS
SELECT * FROM raw_staging.raw_vat_nace_employment;

-- Commentaire sur la vue
COMMENT ON VIEW raw_staging.raw_nace_employment IS 
'Vue de compatibilité avec l''ancien nom de table. 
Pointe vers raw_staging.raw_vat_nace_employment.';