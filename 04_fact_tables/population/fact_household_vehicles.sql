-- 04_fact_tables/population/fact_household_vehicles.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_fact_household_vehicles.sql', 'RUNNING');

-- Création de la table de fait
CREATE TABLE IF NOT EXISTS dw.fact_household_vehicles (
    -- Clé primaire surrogate
    id_household_vehicles_sk BIGSERIAL PRIMARY KEY,
    
    -- Clés étrangères vers les dimensions
    id_date INTEGER NOT NULL,          -- Lien vers dim_date
    id_geography INTEGER NOT NULL,     -- Lien vers dim_geography
    id_sector_sk INTEGER NOT NULL,     -- Lien vers dim_statistical_sectors 
    -- Mesures
    ms_households INTEGER NOT NULL,    -- Nombre de ménages
    ms_vehicles INTEGER NOT NULL,      -- Nombre de véhicules
    
    -- Ratios calculés
    rt_vehicles_per_household DECIMAL(5,2), -- Ratio véhicules par ménage
    
    -- Traçabilité
    id_batch INTEGER NOT NULL,         -- ID du batch de chargement
    fl_current BOOLEAN NOT NULL DEFAULT TRUE,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Contraintes
    CONSTRAINT chk_households_positive CHECK (ms_households >= 0),
    CONSTRAINT chk_vehicles_positive CHECK (ms_vehicles >= 0),
    CONSTRAINT chk_ratio_valid CHECK (rt_vehicles_per_household >= 0),
    
    -- Clés étrangères
    CONSTRAINT fk_vehicles_date FOREIGN KEY (id_date) 
        REFERENCES dw.dim_date(id_date),
    CONSTRAINT fk_vehicles_geography FOREIGN KEY (id_geography) 
        REFERENCES dw.dim_geography(id_geography),
    CONSTRAINT fk_vehicles_secteur FOREIGN KEY (id_sector_sk) 
        REFERENCES dw.dim_statistical_sectors(id_sector_sk)    
);

-- Index pour optimiser les jointures et recherches
CREATE INDEX IF NOT EXISTS idx_fact_vehicles_date 
    ON dw.fact_household_vehicles(id_date);
CREATE INDEX IF NOT EXISTS idx_fact_vehicles_geography 
    ON dw.fact_household_vehicles(id_geography);
CREATE INDEX IF NOT EXISTS idx_fact_vehicles_batch 
    ON dw.fact_household_vehicles(id_batch);
CREATE INDEX IF NOT EXISTS idx_fact_vehicles_current 
    ON dw.fact_household_vehicles(fl_current);

-- Fonction trigger pour mise à jour automatique de dt_updated
CREATE OR REPLACE FUNCTION dw.update_fact_vehicles_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour la mise à jour automatique
CREATE TRIGGER tr_update_fact_vehicles_timestamp
    BEFORE UPDATE ON dw.fact_household_vehicles
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_fact_vehicles_timestamp();

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'fact_household_vehicles',
    'Table de fait du nombre de véhicules par ménage et par secteur',
    'CAR_HOUSEHOLDS'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE dw.fact_household_vehicles IS 'Table de fait contenant le nombre de véhicules par ménage au niveau des secteurs statistiques';
COMMENT ON COLUMN dw.fact_household_vehicles.ms_households IS 'Nombre de ménages dans le secteur';
COMMENT ON COLUMN dw.fact_household_vehicles.ms_vehicles IS 'Nombre de véhicules dans le secteur';
COMMENT ON COLUMN dw.fact_household_vehicles.rt_vehicles_per_household IS 'Ratio du nombre de véhicules par ménage';
COMMENT ON COLUMN dw.fact_household_vehicles.fl_current IS 'Indique si c''est la version courante des données';

-- Log du succès
SELECT utils.log_script_execution('create_fact_household_vehicles.sql', 'SUCCESS');