-- 04_fact_tables/taxes/fact_tax_income.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_fact_tax_income.sql', 'RUNNING');

-- Création de la table de fait
CREATE TABLE IF NOT EXISTS dw.fact_tax_income (
    -- Clé primaire surrogate
    id_tax_income_sk BIGSERIAL PRIMARY KEY,
    
    -- Clés étrangères vers les dimensions
    id_date INTEGER NOT NULL,          -- Lien vers dim_date
    id_geography INTEGER NOT NULL,     -- Lien vers dim_geography
    
    -- Mesures de déclarations
    ms_nbr_non_zero_inc INTEGER NOT NULL,     -- Nombre de déclarations non nulles
    ms_nbr_zero_inc INTEGER,                  -- Nombre de déclarations nulles
    
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
    
    -- Traçabilité
    id_batch INTEGER NOT NULL,                 -- ID du batch de chargement
    fl_current BOOLEAN NOT NULL DEFAULT TRUE,  -- Indicateur de version courante
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Contraintes
    CONSTRAINT chk_declarations_positive CHECK (
        ms_nbr_non_zero_inc >= 0 AND
        ms_nbr_zero_inc >= 0
    ),
    CONSTRAINT chk_amounts_positive CHECK (
        ms_tot_net_taxable_inc >= 0 AND
        ms_tot_net_inc >= 0 AND
        ms_tot_taxes >= 0
    ),
    
    -- Clés étrangères
    CONSTRAINT fk_tax_date FOREIGN KEY (id_date) 
        REFERENCES dw.dim_date(id_date),
    CONSTRAINT fk_tax_geography FOREIGN KEY (id_geography) 
        REFERENCES dw.dim_geography(id_geography)
);

-- Index pour optimiser les jointures et recherches
CREATE INDEX IF NOT EXISTS idx_fact_tax_date 
    ON dw.fact_tax_income(id_date);
CREATE INDEX IF NOT EXISTS idx_fact_tax_geography 
    ON dw.fact_tax_income(id_geography);
CREATE INDEX IF NOT EXISTS idx_fact_tax_batch 
    ON dw.fact_tax_income(id_batch);
CREATE INDEX IF NOT EXISTS idx_fact_tax_current 
    ON dw.fact_tax_income(fl_current);

-- Fonction trigger pour mise à jour automatique de dt_updated
CREATE OR REPLACE FUNCTION dw.update_fact_tax_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour la mise à jour automatique
CREATE TRIGGER tr_update_fact_tax_timestamp
    BEFORE UPDATE ON dw.fact_tax_income
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_fact_tax_timestamp();

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'fact_tax_income',
    'Table de fait des revenus fiscaux par commune',
    'INCOME_TAX'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE dw.fact_tax_income IS 'Table de fait contenant les données de revenus fiscaux et d''imposition par commune';

-- Commentaires des clés
COMMENT ON COLUMN dw.fact_tax_income.id_tax_income_sk IS 'Clé technique auto-incrémentée de la table';
COMMENT ON COLUMN dw.fact_tax_income.id_date IS 'Clé étrangère vers la dimension date';
COMMENT ON COLUMN dw.fact_tax_income.id_geography IS 'Clé étrangère vers la dimension géographique';

-- Commentaires des mesures de déclarations
COMMENT ON COLUMN dw.fact_tax_income.ms_nbr_non_zero_inc IS 'Nombre de déclarations avec revenus non nuls';
COMMENT ON COLUMN dw.fact_tax_income.ms_nbr_zero_inc IS 'Nombre de déclarations avec revenus nuls';

-- Commentaires des revenus totaux
COMMENT ON COLUMN dw.fact_tax_income.ms_tot_net_taxable_inc IS 'Revenu net imposable total de la commune';
COMMENT ON COLUMN dw.fact_tax_income.ms_tot_net_inc IS 'Revenu net total avant imposition';
COMMENT ON COLUMN dw.fact_tax_income.ms_nbr_tot_net_inc IS 'Nombre total de revenus nets déclarés';

-- Commentaires des revenus par type
COMMENT ON COLUMN dw.fact_tax_income.ms_real_estate_net_inc IS 'Revenus immobiliers nets';
COMMENT ON COLUMN dw.fact_tax_income.ms_nbr_real_estate_net_inc IS 'Nombre de déclarations avec revenus immobiliers';
COMMENT ON COLUMN dw.fact_tax_income.ms_tot_net_mov_ass_inc IS 'Revenus mobiliers nets totaux';
COMMENT ON COLUMN dw.fact_tax_income.ms_nbr_net_mov_ass_inc IS 'Nombre de déclarations avec revenus mobiliers';
COMMENT ON COLUMN dw.fact_tax_income.ms_tot_net_various_inc IS 'Revenus divers nets totaux';
COMMENT ON COLUMN dw.fact_tax_income.ms_nbr_net_various_inc IS 'Nombre de déclarations avec revenus divers';
COMMENT ON COLUMN dw.fact_tax_income.ms_tot_net_prof_inc IS 'Revenus professionnels nets totaux';
COMMENT ON COLUMN dw.fact_tax_income.ms_nbr_net_prof_inc IS 'Nombre de déclarations avec revenus professionnels';

-- Commentaires des revenus imposables
COMMENT ON COLUMN dw.fact_tax_income.ms_sep_taxable_inc IS 'Revenus imposables séparément';
COMMENT ON COLUMN dw.fact_tax_income.ms_nbr_sep_taxable_inc IS 'Nombre de déclarations avec revenus imposables séparément';
COMMENT ON COLUMN dw.fact_tax_income.ms_joint_taxable_inc IS 'Revenus imposables conjointement';
COMMENT ON COLUMN dw.fact_tax_income.ms_nbr_joint_taxable_inc IS 'Nombre de déclarations avec revenus imposables conjointement';

-- Commentaires des déductions et taxes
COMMENT ON COLUMN dw.fact_tax_income.ms_tot_deduct_spend IS 'Total des dépenses déductibles';
COMMENT ON COLUMN dw.fact_tax_income.ms_nbr_deduct_spend IS 'Nombre de déclarations avec dépenses déductibles';
COMMENT ON COLUMN dw.fact_tax_income.ms_tot_state_taxes IS 'Total des impôts d''État perçus';
COMMENT ON COLUMN dw.fact_tax_income.ms_nbr_state_taxes IS 'Nombre de contribuables avec impôts d''État';
COMMENT ON COLUMN dw.fact_tax_income.ms_tot_municip_taxes IS 'Total des impôts communaux perçus';
COMMENT ON COLUMN dw.fact_tax_income.ms_nbr_municip_taxes IS 'Nombre de contribuables avec impôts communaux';
COMMENT ON COLUMN dw.fact_tax_income.ms_tot_suburbs_taxes IS 'Total des impôts d''agglomération perçus';
COMMENT ON COLUMN dw.fact_tax_income.ms_nbr_suburbs_taxes IS 'Nombre de contribuables avec impôts d''agglomération';
COMMENT ON COLUMN dw.fact_tax_income.ms_tot_taxes IS 'Total de tous les impôts perçus';
COMMENT ON COLUMN dw.fact_tax_income.ms_nbr_tot_taxes IS 'Nombre total de contribuables';
COMMENT ON COLUMN dw.fact_tax_income.ms_tot_residents IS 'Nombre total de résidents dans la commune';

-- Commentaires des champs de traçabilité
COMMENT ON COLUMN dw.fact_tax_income.id_batch IS 'Identifiant du lot de chargement';
COMMENT ON COLUMN dw.fact_tax_income.fl_current IS 'Indique si c''est la version courante des données (true) ou une version historique (false)';
COMMENT ON COLUMN dw.fact_tax_income.dt_created IS 'Date et heure de création de l''enregistrement';
COMMENT ON COLUMN dw.fact_tax_income.dt_updated IS 'Date et heure de dernière mise à jour de l''enregistrement';

-- Log du succès
SELECT utils.log_script_execution('create_fact_tax_income.sql', 'SUCCESS');