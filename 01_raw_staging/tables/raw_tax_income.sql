-- 01_raw_staging/tables/raw_tax_income.sql

CREATE TABLE IF NOT EXISTS raw_staging.raw_tax_income (
    -- Clé technique
    id_raw SERIAL PRIMARY KEY,
    
    -- Données brutes du CSV
    cd_year VARCHAR(4),                        -- Année
    cd_munty_refnis VARCHAR(5),                -- Code REFNIS commune
    
    -- Mesures brutes (gardées en VARCHAR pour validation)
    ms_nbr_non_zero_inc VARCHAR(20),           -- Nombre de déclarations non nulles
    ms_nbr_zero_inc VARCHAR(20),               -- Nombre de déclarations nulles
    ms_tot_net_taxable_inc VARCHAR(20),        -- Revenu net imposable total
    ms_tot_net_inc VARCHAR(20),                -- Revenu net total
    ms_nbr_tot_net_inc VARCHAR(20),            -- Nombre total de revenus nets
    ms_real_estate_net_inc VARCHAR(20),        -- Revenu immobilier net
    ms_nbr_real_estate_net_inc VARCHAR(20),    -- Nombre de revenus immobiliers
    ms_tot_net_mov_ass_inc VARCHAR(20),        -- Revenu mobilier net total
    ms_nbr_net_mov_ass_inc VARCHAR(20),        -- Nombre de revenus mobiliers
    ms_tot_net_various_inc VARCHAR(20),        -- Revenus divers nets
    ms_nbr_net_various_inc VARCHAR(20),        -- Nombre de revenus divers
    ms_tot_net_prof_inc VARCHAR(20),           -- Revenus professionnels nets
    ms_nbr_net_prof_inc VARCHAR(20),           -- Nombre de revenus professionnels
    ms_sep_taxable_inc VARCHAR(20),            -- Revenus imposables séparément
    ms_nbr_sep_taxable_inc VARCHAR(20),        -- Nombre de revenus imposables séparément
    ms_joint_taxable_inc VARCHAR(20),          -- Revenus imposables conjointement
    ms_nbr_joint_taxable_inc VARCHAR(20),      -- Nombre de revenus imposables conjointement
    ms_tot_deduct_spend VARCHAR(20),           -- Dépenses déductibles totales
    ms_nbr_deduct_spend VARCHAR(20),           -- Nombre de dépenses déductibles
    ms_tot_state_taxes VARCHAR(20),            -- Impôts d'état totaux
    ms_nbr_state_taxes VARCHAR(20),            -- Nombre d'impôts d'état
    ms_tot_municip_taxes VARCHAR(20),          -- Impôts communaux totaux
    ms_nbr_municip_taxes VARCHAR(20),          -- Nombre d'impôts communaux
    ms_tot_suburbs_taxes VARCHAR(20),          -- Impôts d'agglomération totaux
    ms_nbr_suburbs_taxes VARCHAR(20),          -- Nombre d'impôts d'agglomération
    ms_tot_taxes VARCHAR(20),                  -- Total des impôts
    ms_nbr_tot_taxes VARCHAR(20),              -- Nombre total d'impôts
    ms_tot_residents VARCHAR(20),              -- Nombre total de résidents
    
    -- Descriptions géographiques
    tx_munty_descr_nl VARCHAR(100),            -- Description commune NL
    tx_munty_descr_fr VARCHAR(100),            -- Description commune FR
    tx_munty_descr_en VARCHAR(100),            -- Description commune EN
    tx_munty_descr_de VARCHAR(100),            -- Description commune DE
    cd_dstr_refnis VARCHAR(10),                 -- Code REFNIS district
    tx_dstr_descr_nl VARCHAR(100),             -- Description district NL
    tx_dstr_descr_fr VARCHAR(100),             -- Description district FR
    tx_dstr_descr_en VARCHAR(100),             -- Description district EN
    tx_dstr_descr_de VARCHAR(100),             -- Description district DE
    cd_prov_refnis VARCHAR(10),                 -- Code REFNIS province
    tx_prov_descr_nl VARCHAR(100),             -- Description province NL
    tx_prov_descr_fr VARCHAR(100),             -- Description province FR
    tx_prov_descr_en VARCHAR(100),             -- Description province EN
    tx_prov_descr_de VARCHAR(100),             -- Description province DE
    cd_rgn_refnis VARCHAR(10),                  -- Code REFNIS région
    tx_rgn_descr_nl VARCHAR(100),              -- Description région NL
    tx_rgn_descr_fr VARCHAR(100),              -- Description région FR
    tx_rgn_descr_en VARCHAR(100),              -- Description région EN
    tx_rgn_descr_de VARCHAR(100),              -- Description région DE
    
    -- Traçabilité
    id_batch INTEGER NOT NULL,
    dt_import TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX IF NOT EXISTS idx_raw_tax_income_batch 
    ON raw_staging.raw_tax_income(id_batch);
CREATE INDEX IF NOT EXISTS idx_raw_tax_income_year_refnis 
    ON raw_staging.raw_tax_income(cd_year, cd_munty_refnis);

-- Commentaires
COMMENT ON TABLE raw_staging.raw_tax_income IS 
'Table de staging brute pour les données de revenus fiscaux par commune';