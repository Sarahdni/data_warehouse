-- 02_clean_staging/tables/clean_household_vehicles.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_clean_household_vehicles.sql', 'RUNNING');

-- Création de la table
CREATE TABLE IF NOT EXISTS clean_staging.clean_household_vehicles (
    -- Clés et identifiants
    cd_year INTEGER NOT NULL,
    cd_sector VARCHAR(9) NOT NULL,        -- Code secteur statistique
    cd_refnis VARCHAR(5) NOT NULL,        -- Code REFNIS commune
    
    -- Mesures
    ms_households INTEGER NOT NULL,       -- Nombre de ménages (total_huish)
    ms_vehicles INTEGER NOT NULL,         -- Nombre de véhicules (total_wagens)
    
    -- Flags de validation
    fl_valid_sector BOOLEAN DEFAULT FALSE,     -- Format secteur valide
    fl_valid_refnis BOOLEAN DEFAULT FALSE,     -- Format REFNIS valide
    fl_valid_counts BOOLEAN DEFAULT FALSE,     -- Comptages positifs et cohérents
    
    -- Traçabilité
    id_batch INTEGER NOT NULL,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT pk_clean_household_vehicles 
        PRIMARY KEY (cd_sector, cd_year),
    CONSTRAINT chk_counts_positive 
        CHECK (ms_households >= 0 AND ms_vehicles >= 0),
    CONSTRAINT chk_year_valid 
        CHECK (cd_year >= 2020 AND cd_year <= 2025)
);

-- Index pour optimiser les recherches et jointures
CREATE INDEX IF NOT EXISTS idx_clean_hh_sector 
    ON clean_staging.clean_household_vehicles(cd_sector);
    
CREATE INDEX IF NOT EXISTS idx_clean_hh_refnis 
    ON clean_staging.clean_household_vehicles(cd_refnis);
    
CREATE INDEX IF NOT EXISTS idx_clean_hh_batch 
    ON clean_staging.clean_household_vehicles(id_batch);

-- Trigger pour mise à jour automatique de dt_updated
CREATE OR REPLACE FUNCTION clean_staging.update_household_vehicles_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création du trigger
CREATE TRIGGER tr_update_household_vehicles_timestamp
    BEFORE UPDATE ON clean_staging.clean_household_vehicles
    FOR EACH ROW
    EXECUTE FUNCTION clean_staging.update_household_vehicles_timestamp();

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'clean_staging',
    'clean_household_vehicles',
    'Table de staging nettoyée pour les données de véhicules par ménage',
    'CAR_HOUSEHOLDS'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE clean_staging.clean_household_vehicles IS 
'Table de staging nettoyée contenant le nombre de véhicules par ménage au niveau des secteurs statistiques';

COMMENT ON COLUMN clean_staging.clean_household_vehicles.cd_sector IS 
'Code du secteur statistique';
COMMENT ON COLUMN clean_staging.clean_household_vehicles.cd_refnis IS 
'Code REFNIS de la commune';
COMMENT ON COLUMN clean_staging.clean_household_vehicles.ms_households IS 
'Nombre de ménages dans le secteur';
COMMENT ON COLUMN clean_staging.clean_household_vehicles.ms_vehicles IS 
'Nombre de véhicules dans le secteur';
COMMENT ON COLUMN clean_staging.clean_household_vehicles.fl_valid_sector IS 
'Indique si le format du code secteur est valide';
COMMENT ON COLUMN clean_staging.clean_household_vehicles.fl_valid_refnis IS 
'Indique si le format du code REFNIS est valide';
COMMENT ON COLUMN clean_staging.clean_household_vehicles.fl_valid_counts IS 
'Indique si les comptages sont valides (positifs et cohérents)';

-- Log du succès
SELECT utils.log_script_execution('create_clean_household_vehicles.sql', 'SUCCESS');