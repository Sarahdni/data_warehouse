-- 02_clean_staging/tables/clean_tax_income.sql

CREATE TABLE IF NOT EXISTS clean_staging.clean_tax_income (
    -- Clés et identifiants
    cd_year INTEGER NOT NULL,
    cd_munty_refnis VARCHAR(5) NOT NULL,      -- Code REFNIS commune
    
    -- Mesures de déclarations
    ms_nbr_non_zero_inc INTEGER NOT NULL,     -- Nombre de déclarations non nulles
    ms_nbr_zero_inc INTEGER ,         -- Nombre de déclarations nulles
    
    -- Revenus totaux
    ms_tot_net_taxable_inc DECIMAL(15,2),     -- Revenu net imposable total
    ms_tot_net_inc DECIMAL(15,2),             -- Revenu net total
    ms_nbr_tot_net_inc INTEGER,               -- Nombre total de revenus nets
    
    -- Revenus par type
    ms_real_estate_net_inc DECIMAL(15,2),     -- Revenu immobilier net
    ms_nbr_real_estate_net_inc INTEGER,       -- Nombre de revenus immobiliers
    ms_tot_net_mov_ass_inc DECIMAL(15,2),     -- Revenu mobilier net total
    ms_nbr_net_mov_ass_inc INTEGER,           -- Nombre de revenus mobiliers
    ms_tot_net_various_inc DECIMAL(15,2),     -- Revenus divers nets
    ms_nbr_net_various_inc INTEGER,           -- Nombre de revenus divers
    ms_tot_net_prof_inc DECIMAL(15,2),        -- Revenus professionnels nets
    ms_nbr_net_prof_inc INTEGER,              -- Nombre de revenus professionnels
    
    -- Revenus imposables
    ms_sep_taxable_inc DECIMAL(15,2),         -- Revenus imposables séparément
    ms_nbr_sep_taxable_inc INTEGER,           -- Nombre de revenus imposables séparément
    ms_joint_taxable_inc DECIMAL(15,2),       -- Revenus imposables conjointement
    ms_nbr_joint_taxable_inc INTEGER,         -- Nombre de revenus imposables conjointement
    
    -- Déductions et taxes
    ms_tot_deduct_spend DECIMAL(15,2),        -- Dépenses déductibles totales
    ms_nbr_deduct_spend INTEGER,              -- Nombre de dépenses déductibles
    ms_tot_state_taxes DECIMAL(15,2),         -- Impôts d'état totaux
    ms_nbr_state_taxes INTEGER,               -- Nombre d'impôts d'état
    ms_tot_municip_taxes DECIMAL(15,2),       -- Impôts communaux totaux
    ms_nbr_municip_taxes INTEGER,             -- Nombre d'impôts communaux
    ms_tot_suburbs_taxes DECIMAL(15,2),       -- Impôts d'agglomération totaux
    ms_nbr_suburbs_taxes INTEGER,             -- Nombre d'impôts d'agglomération
    ms_tot_taxes DECIMAL(15,2),               -- Total des impôts
    ms_nbr_tot_taxes INTEGER,                 -- Nombre total d'impôts
    ms_tot_residents INTEGER,                 -- Nombre total de résidents
    
    -- Hiérarchie géographique
    cd_dstr_refnis VARCHAR(5),               -- Code REFNIS district
    cd_prov_refnis VARCHAR(5),               -- Code REFNIS province
    cd_rgn_refnis VARCHAR(5),                -- Code REFNIS région
    
    -- Flags de validation
    fl_valid_munty_refnis BOOLEAN DEFAULT FALSE,   -- Format REFNIS commune valide
    fl_valid_counts BOOLEAN DEFAULT FALSE,         -- Cohérence des comptages
    fl_valid_amounts BOOLEAN DEFAULT FALSE,        -- Cohérence des montants
    fl_valid_hierarchy BOOLEAN DEFAULT FALSE,      -- Cohérence hiérarchie géographique
    
    -- Traçabilité
    id_batch INTEGER NOT NULL,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT pk_clean_tax_income PRIMARY KEY (cd_year, cd_munty_refnis),
    CONSTRAINT chk_year_valid CHECK (cd_year >= 2000 AND cd_year <= 2025),
    CONSTRAINT chk_counts_positive CHECK (
        ms_nbr_non_zero_inc >= 0 AND
        ms_nbr_zero_inc >= 0 AND
        ms_nbr_tot_net_inc >= 0
    )
);

-- Index
CREATE INDEX IF NOT EXISTS idx_clean_tax_munty 
    ON clean_staging.clean_tax_income(cd_munty_refnis);
CREATE INDEX IF NOT EXISTS idx_clean_tax_batch 
    ON clean_staging.clean_tax_income(id_batch);

-- Trigger pour mise à jour automatique de dt_updated
CREATE OR REPLACE FUNCTION clean_staging.update_tax_income_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_tax_income_timestamp
    BEFORE UPDATE ON clean_staging.clean_tax_income
    FOR EACH ROW
    EXECUTE FUNCTION clean_staging.update_tax_income_timestamp();

-- Commentaires
COMMENT ON TABLE clean_staging.clean_tax_income IS 
'Table de staging nettoyée pour les données de revenus fiscaux par commune';