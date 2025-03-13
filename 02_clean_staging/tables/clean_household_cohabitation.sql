-- 02_clean_staging/tables/clean_household_cohabitation.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_clean_household_cohabitation.sql', 'RUNNING');

-- Création de la table
CREATE TABLE IF NOT EXISTS clean_staging.clean_household_cohabitation (
    -- Clés et identifiants
    cd_year INTEGER NOT NULL,
    cd_rgn_refnis VARCHAR(4) NOT NULL,      -- Code REFNIS de la région
    tx_rgn_descr_nl VARCHAR(100),           -- Description région en néerlandais
    tx_rgn_descr_fr VARCHAR(100),           -- Description région en français
    
    -- Caractéristiques démographiques
    cd_sex CHAR(1) NOT NULL,                -- Sexe (F/M)
    cd_age VARCHAR(10) NOT NULL,            -- Tranche d'âge
    cd_natlty VARCHAR(10) NOT NULL,         -- Code nationalité
    tx_natlty_nl VARCHAR(100),              -- Description nationalité en néerlandais
    tx_natlty_fr VARCHAR(100),              -- Description nationalité en français
    
    -- Statut de cohabitation
    fl_cohab BOOLEAN NOT NULL,              -- Flag cohabitation (0/1)
    tx_cohab_nl VARCHAR(100),               -- Description cohabitation en néerlandais
    tx_cohab_fr VARCHAR(100),               -- Description cohabitation en français
    
    -- Mesures
    ms_count INTEGER NOT NULL,              -- Nombre de personnes
    
    -- Flags de validation
    fl_valid_refnis BOOLEAN DEFAULT FALSE,  -- Format REFNIS valide
    fl_valid_sex BOOLEAN DEFAULT FALSE,     -- Validation avec dim_sex
    fl_valid_age BOOLEAN DEFAULT FALSE,     -- Validation avec dim_age_group
    fl_valid_nationality BOOLEAN DEFAULT FALSE, -- Validation avec dim_nationality
    fl_valid_count BOOLEAN DEFAULT FALSE,   -- Comptage positif
    
    -- Traçabilité
    id_batch INTEGER NOT NULL,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT pk_clean_household_cohabitation 
        PRIMARY KEY (cd_year, cd_rgn_refnis, cd_sex, cd_age, cd_natlty, fl_cohab),
    CONSTRAINT chk_valid_region 
        CHECK (cd_rgn_refnis IN ('2000', '3000', '4000')),
    CONSTRAINT chk_sex 
        CHECK (cd_sex IN ('F', 'M')),
    CONSTRAINT chk_age_format 
        CHECK (cd_age IN ('0-17', '18-64', '65+')),
    CONSTRAINT chk_count_positive 
        CHECK (ms_count >= 0),
    CONSTRAINT chk_year_valid 
        CHECK (cd_year >= 2000 AND cd_year <= 2025)
);

-- Index pour optimiser les recherches et jointures
CREATE INDEX IF NOT EXISTS idx_clean_cohab_refnis 
    ON clean_staging.clean_household_cohabitation(cd_rgn_refnis);
    
CREATE INDEX IF NOT EXISTS idx_clean_cohab_batch 
    ON clean_staging.clean_household_cohabitation(id_batch);

-- Trigger pour mise à jour automatique de dt_updated
CREATE OR REPLACE FUNCTION clean_staging.update_household_cohabitation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_household_cohabitation_timestamp
    BEFORE UPDATE ON clean_staging.clean_household_cohabitation
    FOR EACH ROW
    EXECUTE FUNCTION clean_staging.update_household_cohabitation_timestamp();

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'clean_staging',
    'clean_household_cohabitation',
    'Table de staging nettoyée pour les données de cohabitation légale par région',
    'COHAB_DATA'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE clean_staging.clean_household_cohabitation IS 
'Table de staging nettoyée contenant les données de cohabitation légale par région, sexe, âge et nationalité';

COMMENT ON COLUMN clean_staging.clean_household_cohabitation.cd_rgn_refnis IS 
'Code REFNIS de la région';
COMMENT ON COLUMN clean_staging.clean_household_cohabitation.cd_sex IS 
'Sexe (F: Féminin, M: Masculin)';
COMMENT ON COLUMN clean_staging.clean_household_cohabitation.cd_age IS 
'Tranche d''âge (0-17, 18-64, 65+)';
COMMENT ON COLUMN clean_staging.clean_household_cohabitation.cd_natlty IS 
'Code de nationalité (BE: Belge, NOT_BE: Non-Belge)';
COMMENT ON COLUMN clean_staging.clean_household_cohabitation.fl_cohab IS 
'Indicateur de cohabitation légale (true: cohabitant, false: non-cohabitant)';
COMMENT ON COLUMN clean_staging.clean_household_cohabitation.ms_count IS 
'Nombre de personnes dans la catégorie';

-- Log du succès
SELECT utils.log_script_execution('create_clean_household_cohabitation.sql', 'SUCCESS');