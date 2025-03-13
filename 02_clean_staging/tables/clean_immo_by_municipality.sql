-- 02_clean_staging/tables/clean_immo_by_municipality.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_clean_immo_by_municipality.sql', 'RUNNING');

CREATE TABLE IF NOT EXISTS clean_staging.clean_immo_by_municipality (
    -- Clés et identifiants
    id_clean SERIAL PRIMARY KEY,
    cd_year INTEGER NOT NULL,
    cd_period VARCHAR(2) NOT NULL,
    cd_refnis VARCHAR(5) NOT NULL,
    
    -- Descriptions multilingues
    tx_property_type_nl VARCHAR(100) NOT NULL,
    tx_property_type_fr VARCHAR(100) NOT NULL,
    tx_municipality_nl VARCHAR(100) NOT NULL,
    tx_municipality_fr VARCHAR(100) NOT NULL,
    
    -- Mesures nettoyées et validées
    ms_total_transactions INTEGER,
    ms_total_price DECIMAL(15,2),
    ms_total_surface DECIMAL(15,2),
    ms_mean_price DECIMAL(15,2),
    ms_price_p10 DECIMAL(15,2),
    ms_price_p25 DECIMAL(15,2),
    ms_price_p50 DECIMAL(15,2),
    ms_price_p75 DECIMAL(15,2),
    ms_price_p90 DECIMAL(15,2),
    
    -- Flags de validation

    fl_confidential BOOLEAN DEFAULT FALSE,
    fl_valid_refnis BOOLEAN DEFAULT FALSE,
    fl_valid_transactions BOOLEAN DEFAULT FALSE,
    fl_valid_prices BOOLEAN DEFAULT FALSE,
    fl_valid_surface BOOLEAN DEFAULT FALSE,
    
    -- Traçabilité
    id_batch INTEGER NOT NULL,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT chk_year CHECK (cd_year BETWEEN 1950 AND 2050),
    CONSTRAINT chk_period CHECK (cd_period IN ('Q1', 'Q2', 'Q3', 'Q4', 'S1', 'S2', 'Y')),
    CONSTRAINT chk_transactions CHECK (ms_total_transactions >= 0),
    CONSTRAINT chk_prices CHECK (
         fl_confidential = TRUE OR  -- Si confidentiel, pas de vérification des prix
    (
        ms_total_price >= 0 AND
        ms_mean_price >= 0 AND
        ms_price_p10 >= 0 AND
        ms_price_p25 >= 0 AND
        ms_price_p50 >= 0 AND
        ms_price_p75 >= 0 AND
        ms_price_p90 >= 0
    )
    CONSTRAINT chk_surface CHECK (ms_total_surface >= 0)
);

-- Index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_clean_immo_batch 
    ON clean_staging.clean_immo_by_municipality(id_batch);

CREATE INDEX IF NOT EXISTS idx_clean_immo_year_period 
    ON clean_staging.clean_immo_by_municipality(cd_year, cd_period);

CREATE INDEX IF NOT EXISTS idx_clean_immo_refnis 
    ON clean_staging.clean_immo_by_municipality(cd_refnis);
CREATE INDEX IF NOT EXISTS idx_clean_immo_confidential 
    ON clean_staging.clean_immo_by_municipality(fl_confidential);

-- Trigger pour mise à jour automatique de dt_updated
CREATE OR REPLACE FUNCTION clean_staging.update_immo_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_immo_timestamp
    BEFORE UPDATE ON clean_staging.clean_immo_by_municipality
    FOR EACH ROW
    EXECUTE FUNCTION clean_staging.update_immo_timestamp();

-- Commentaires
COMMENT ON TABLE clean_staging.clean_immo_by_municipality IS 
'Table de staging nettoyée pour les données immobilières par commune';

COMMENT ON COLUMN clean_staging.clean_immo_by_municipality.cd_year IS 'Année de référence';
COMMENT ON COLUMN clean_staging.clean_immo_by_municipality.cd_period IS 'Période (Q1-Q4: trimestres, S1-S2: semestres, Y: année)';
COMMENT ON COLUMN clean_staging.clean_immo_by_municipality.cd_refnis IS 'Code REFNIS de la commune';
COMMENT ON COLUMN clean_staging.clean_immo_by_municipality.fl_valid_refnis IS 'Validation du code REFNIS';
COMMENT ON COLUMN clean_staging.clean_immo_by_municipality.fl_valid_transactions IS 'Validation des nombres de transactions';
COMMENT ON COLUMN clean_staging.clean_immo_by_municipality.fl_valid_prices IS 'Validation des prix';
COMMENT ON COLUMN clean_staging.clean_immo_by_municipality.fl_valid_surface IS 'Validation des surfaces';
COMMENT ON COLUMN clean_staging.clean_immo_by_municipality.fl_confidential IS 'Indique si les données sont confidentielles (TRUE si moins de 10 transactions)';

-- Log du succès
SELECT utils.log_script_execution('create_clean_immo_by_municipality.sql', 'SUCCESS');