-- 04_fact_tables/real_estate/fact_real_estate_sector.sql

-- Log du début d'exécution 
SELECT utils.log_script_execution('create_fact_real_estate_sector.sql', 'RUNNING');

-- Création de la table des faits
CREATE TABLE IF NOT EXISTS dw.fact_real_estate_sector (
    -- Clé technique (optionnelle mais recommandée pour traçabilité)
    id_fact SERIAL,
    
    -- Clés étrangères vers les dimensions
    id_date INTEGER NOT NULL,               -- Année de la transaction      
    id_sector_sk INTEGER NOT NULL,          -- Secteur statistique avec historisation
    id_geography INTEGER NOT NULL,          -- Commune/District/Province/Région
    cd_residential_type VARCHAR(4) NOT NULL,   -- Type de bien résidentiel (B001, B002, etc.)

    -- Mesures
    nb_transactions INTEGER NOT NULL,
    nb_aggregated_sectors INTEGER,
    ms_price_p10 DECIMAL(15,2),    -- NULL si confidentiel
    ms_price_p25 DECIMAL(15,2),    -- NULL si confidentiel
    ms_price_p50 DECIMAL(15,2),    -- NULL si confidentiel
    ms_price_p75 DECIMAL(15,2),    -- NULL si confidentiel
    ms_price_p90 DECIMAL(15,2),    -- NULL si confidentiel


    -- Flags
    fl_confidential BOOLEAN NOT NULL DEFAULT FALSE,   -- TRUE si < 16 transactions
    fl_aggregated_sectors BOOLEAN NOT NULL DEFAULT FALSE,

    
    -- Traçabilité
    id_batch INTEGER NOT NULL,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT pk_fact_r_e_s_sector 
        PRIMARY KEY (id_fact),
        
    CONSTRAINT uk_fact_r_e_s_sector
        UNIQUE (id_date, id_sector_sk, id_geography, cd_residential_type),
    
    CONSTRAINT fk_fact_r_e_s_date 
        FOREIGN KEY (id_date) 
        REFERENCES dw.dim_date(id_date),
        
    CONSTRAINT fk_fact_r_e_s_sector          
        FOREIGN KEY (id_sector_sk) 
        REFERENCES dw.dim_statistical_sectors(id_sector_sk),
        
    CONSTRAINT fk_fact_r_e_s_geography
        FOREIGN KEY (id_geography)
        REFERENCES dw.dim_geography(id_geography),
        
    CONSTRAINT fk_fact_r_e_s_residential_type
        FOREIGN KEY (cd_residential_type)
        REFERENCES dw.dim_residential_building(cd_residential_type),
        
    CONSTRAINT fk_fact_r_e_s_batch
        FOREIGN KEY (id_batch)
        REFERENCES metadata.source_file_history(id_file_history),
        
    CONSTRAINT chk_transactions_positive 
        CHECK (nb_transactions >= 0),
        
    CONSTRAINT chk_prices_valid 
        CHECK (
            (fl_confidential = TRUE AND 
             ms_price_p10 IS NULL AND 
             ms_price_p25 IS NULL AND 
             ms_price_p50 IS NULL AND 
             ms_price_p75 IS NULL AND 
             ms_price_p90 IS NULL)
            OR
            (fl_confidential = FALSE AND
             ms_price_p10 >= 0 AND
             ms_price_p25 >= 0 AND
             ms_price_p50 >= 0 AND
             ms_price_p75 >= 0 AND
             ms_price_p90 >= 0 AND
             ms_price_p10 <= ms_price_p25 AND
             ms_price_p25 <= ms_price_p50 AND
             ms_price_p50 <= ms_price_p75 AND
             ms_price_p75 <= ms_price_p90)
        )
);

-- Index pour optimiser les jointures fréquentes
CREATE INDEX IF NOT EXISTS idx_fact_r_e_s_date 
    ON dw.fact_real_estate_sector(id_date);

CREATE INDEX IF NOT EXISTS idx_fact_r_e_s_sector        
    ON dw.fact_real_estate_sector(id_sector_sk);

CREATE INDEX IF NOT EXISTS idx_fact_r_e_s_geography
    ON dw.fact_real_estate_sector(id_geography);

CREATE INDEX IF NOT EXISTS idx_fact_r_e_s_type 
    ON dw.fact_real_estate_sector(cd_residential_type);

CREATE INDEX IF NOT EXISTS idx_fact_r_e_s_batch 
    ON dw.fact_real_estate_sector(id_batch);

-- Trigger pour mise à jour automatique
CREATE OR REPLACE FUNCTION dw.update_fact_r_e_s_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_fact_r_e_s_timestamp
    BEFORE UPDATE ON dw.fact_real_estate_sector
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_fact_r_e_s_timestamp();

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'fact_real_estate_sector',
    'Table des faits des transactions immobilières résidentielles par secteur statistique',
    'REAL_ESTATE_TRANSACTIONS'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires détaillés
COMMENT ON TABLE dw.fact_real_estate_sector IS 
'Table des faits contenant les statistiques de prix des transactions immobilières résidentielles par année et secteur statistique';

COMMENT ON COLUMN dw.fact_real_estate_sector.id_fact IS 'Identifiant technique unique de la transaction';
COMMENT ON COLUMN dw.fact_real_estate_sector.id_date IS 'Référence vers la dimension temporelle (année)';
COMMENT ON COLUMN dw.fact_real_estate_sector.id_sector_sk IS 'Référence vers la dimension des secteurs statistiques avec historisation';
COMMENT ON COLUMN dw.fact_real_estate_sector.id_geography IS 'Référence vers la dimension géographique';
COMMENT ON COLUMN dw.fact_real_estate_sector.cd_residential_type IS 'Type de bien résidentiel';
COMMENT ON COLUMN dw.fact_real_estate_sector.nb_transactions IS 'Nombre de transactions sur la période';
COMMENT ON COLUMN dw.fact_real_estate_sector.ms_price_p10 IS 'Prix au 10e percentile (euros)';
COMMENT ON COLUMN dw.fact_real_estate_sector.ms_price_p25 IS 'Prix au 1er quartile (euros)';
COMMENT ON COLUMN dw.fact_real_estate_sector.ms_price_p50 IS 'Prix médian (euros)';
COMMENT ON COLUMN dw.fact_real_estate_sector.ms_price_p75 IS 'Prix au 3e quartile (euros)';
COMMENT ON COLUMN dw.fact_real_estate_sector.ms_price_p90 IS 'Prix au 90e percentile (euros)';
COMMENT ON COLUMN dw.fact_real_estate_sector.fl_confidential IS 'Indique si les prix sont confidentiels (nb_transactions < 16)';
COMMENT ON COLUMN dw.fact_real_estate_sector.id_batch IS 'Identifiant du batch de chargement';
COMMENT ON COLUMN dw.fact_real_estate_sector.fl_aggregated_sectors IS 'Indique si la ligne représente une agrégation de plusieurs secteurs non spécifiés (TRUE) ou une donnée sectorielle unique (FALSE)';
COMMENT ON COLUMN dw.fact_real_estate_sector.nb_aggregated_sectors IS 'Nombre de secteurs agrégés dans cette ligne (NULL si fl_aggregated_sectors = FALSE)';

-- Log du succès
SELECT utils.log_script_execution('create_fact_real_estate_sector.sql', 'SUCCESS');