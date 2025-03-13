-- 04_fact_tables/population/fact_household_cohabitation.sql

-- Log du début d'exécution
DO $$ 
BEGIN 
    PERFORM utils.log_script_execution('create_fact_household_cohabitation.sql', 'RUNNING');
END $$;

-- Création de la table
DROP TABLE IF EXISTS dw.fact_household_cohabitation CASCADE;
CREATE TABLE dw.fact_household_cohabitation (
    -- Clé primaire
    id_fact_household_cohabitation SERIAL PRIMARY KEY,

    -- Clés étrangères vers les dimensions
    id_date INTEGER NOT NULL REFERENCES dw.dim_date(id_date),
    id_geography INTEGER NOT NULL REFERENCES dw.dim_geography(id_geography),
    cd_sex CHAR(1) NOT NULL REFERENCES dw.dim_sex(cd_sex),
    cd_age_group VARCHAR(10) NOT NULL REFERENCES dw.dim_age_group(cd_age_group),
    cd_nationality VARCHAR(10) NOT NULL REFERENCES dw.dim_nationality(cd_nationality),
    cd_cohabitation VARCHAR(5) NOT NULL REFERENCES dw.dim_cohabitation_status(cd_cohabitation),

    -- Mesures
    ms_count INTEGER NOT NULL,

    -- Traçabilité
    id_batch INTEGER NOT NULL,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Contraintes
    CONSTRAINT chk_household_count CHECK (ms_count >= 0)
);

-- Index pour optimiser les jointures
CREATE INDEX idx_fact_household_date 
    ON dw.fact_household_cohabitation(id_date);
CREATE INDEX idx_fact_household_geography 
    ON dw.fact_household_cohabitation(id_geography);
CREATE INDEX idx_fact_household_batch 
    ON dw.fact_household_cohabitation(id_batch);

-- Commentaires
COMMENT ON TABLE dw.fact_household_cohabitation IS 
'Table de faits des statistiques de cohabitation des ménages';

COMMENT ON COLUMN dw.fact_household_cohabitation.id_date IS 'Référence vers la dimension date';
COMMENT ON COLUMN dw.fact_household_cohabitation.id_geography IS 'Référence vers la dimension géographique';
COMMENT ON COLUMN dw.fact_household_cohabitation.cd_sex IS 'Référence vers la dimension sexe';
COMMENT ON COLUMN dw.fact_household_cohabitation.cd_age_group IS 'Référence vers la dimension groupe d''âge';
COMMENT ON COLUMN dw.fact_household_cohabitation.cd_nationality IS 'Référence vers la dimension nationalité';
COMMENT ON COLUMN dw.fact_household_cohabitation.cd_cohabitation IS 'Référence vers la dimension statut de cohabitation';
COMMENT ON COLUMN dw.fact_household_cohabitation.ms_count IS 'Nombre de personnes';
COMMENT ON COLUMN dw.fact_household_cohabitation.id_batch IS 'Identifiant du lot de chargement';

-- Log du succès
DO $$
BEGIN
    PERFORM utils.log_script_execution('create_fact_household_cohabitation.sql', 'SUCCESS');
END $$;