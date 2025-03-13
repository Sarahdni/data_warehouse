-- 04_fact_tables/real_estate/fact_real_estate_municipality.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_fact_real_estate_municipality.sql', 'RUNNING');

-- Création de la table des faits
CREATE TABLE IF NOT EXISTS dw.fact_real_estate_municipality (
    -- Clé technique 
    id_fact SERIAL,
    
    -- Clés dimensionnelles
    id_date INTEGER NOT NULL,               -- Année/Période
    id_geography INTEGER NOT NULL,          -- Commune
    cd_building_type VARCHAR(3) NOT NULL,       -- Type de bien (lien vers dim_building_type)
    
    -- Mesures
    ms_total_transactions INTEGER NOT NULL,
    ms_total_price DECIMAL(15,2),          -- NULL si confidentiel
    ms_total_surface DECIMAL(15,2),        -- NULL si confidentiel
    ms_mean_price DECIMAL(15,2),           -- NULL si confidentiel
    ms_price_p10 DECIMAL(15,2),            -- NULL si confidentiel
    ms_price_p25 DECIMAL(15,2),            -- NULL si confidentiel
    ms_price_p50 DECIMAL(15,2),            -- NULL si confidentiel
    ms_price_p75 DECIMAL(15,2),            -- NULL si confidentiel
    ms_price_p90 DECIMAL(15,2),            -- NULL si confidentiel

    -- Flags
    fl_confidential BOOLEAN NOT NULL DEFAULT FALSE,  -- TRUE si < 10 transactions
    
    -- Traçabilité
    id_batch INTEGER NOT NULL,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT pk_fact_real_estate_municipality 
        PRIMARY KEY (id_fact),
        
    CONSTRAINT uk_fact_real_estate_municipality
        UNIQUE (id_date, id_geography, cd_building_type),
    
    CONSTRAINT fk_fact_rem_date 
        FOREIGN KEY (id_date) 
        REFERENCES dw.dim_date(id_date),
        
    CONSTRAINT fk_fact_rem_geography
        FOREIGN KEY (id_geography)
        REFERENCES dw.dim_geography(id_geography),

    CONSTRAINT fk_fact_rem_building_type
        FOREIGN KEY (cd_building_type)
        REFERENCES dw.dim_building_type(cd_building_type)
        
);

-- Index pour optimiser les jointures fréquentes
CREATE INDEX IF NOT EXISTS idx_fact_rem_date 
    ON dw.fact_real_estate_municipality(id_date);

CREATE INDEX IF NOT EXISTS idx_fact_rem_geography
    ON dw.fact_real_estate_municipality(id_geography);

CREATE INDEX IF NOT EXISTS idx_fact_rem_building_type 
    ON dw.fact_real_estate_municipality(cd_building_type);

CREATE INDEX IF NOT EXISTS idx_fact_rem_batch 
    ON dw.fact_real_estate_municipality(id_batch);

-- Trigger pour mise à jour automatique
CREATE OR REPLACE FUNCTION dw.update_fact_rem_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_fact_rem_timestamp
    BEFORE UPDATE ON dw.fact_real_estate_municipality
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_fact_rem_timestamp();

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'fact_real_estate_municipality',
    'Table des faits des transactions immobilières par commune',
    'IMMO_MUN'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires détaillés
COMMENT ON TABLE dw.fact_real_estate_municipality IS 
'Table des faits contenant les statistiques immobilières agrégées au niveau communal';

COMMENT ON COLUMN dw.fact_real_estate_municipality.id_fact IS 'Identifiant technique unique de la transaction';
COMMENT ON COLUMN dw.fact_real_estate_municipality.id_date IS 'Référence vers la dimension temporelle';
COMMENT ON COLUMN dw.fact_real_estate_municipality.id_geography IS 'Référence vers la dimension géographique (commune)';
COMMENT ON COLUMN dw.fact_real_estate_municipality.cd_building_type IS 'Référence vers la dimension des types de biens';
COMMENT ON COLUMN dw.fact_real_estate_municipality.ms_total_transactions IS 'Nombre total de transactions';
COMMENT ON COLUMN dw.fact_real_estate_municipality.ms_total_price IS 'Prix total des transactions (euros)';
COMMENT ON COLUMN dw.fact_real_estate_municipality.ms_total_surface IS 'Surface totale des biens (m²)';
COMMENT ON COLUMN dw.fact_real_estate_municipality.ms_mean_price IS 'Prix moyen (euros)';
COMMENT ON COLUMN dw.fact_real_estate_municipality.ms_price_p10 IS 'Prix au 10e percentile (euros)';
COMMENT ON COLUMN dw.fact_real_estate_municipality.ms_price_p25 IS 'Prix au 1er quartile (euros)';
COMMENT ON COLUMN dw.fact_real_estate_municipality.ms_price_p50 IS 'Prix médian (euros)';
COMMENT ON COLUMN dw.fact_real_estate_municipality.ms_price_p75 IS 'Prix au 3e quartile (euros)';
COMMENT ON COLUMN dw.fact_real_estate_municipality.ms_price_p90 IS 'Prix au 90e percentile (euros)';
COMMENT ON COLUMN dw.fact_real_estate_municipality.fl_confidential IS 'Indique si les prix sont confidentiels (nb_transactions < 16)';
COMMENT ON COLUMN dw.fact_real_estate_municipality.id_batch IS 'Identifiant du batch de chargement';

-- Log du succès
SELECT utils.log_script_execution('create_fact_real_estate_municipality.sql', 'SUCCESS');