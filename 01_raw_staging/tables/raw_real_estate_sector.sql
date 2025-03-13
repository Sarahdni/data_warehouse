-- 01_raw_staging/tables/raw_real_estate_sector.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_raw_real_estate_sector.sql', 'RUNNING');

-- Création de la table
CREATE TABLE IF NOT EXISTS raw_staging.raw_real_estate_sector (
    -- Données brutes du CSV
    cd_stat_sector VARCHAR(20),       -- Format du code secteur statistique (ex: 11001A00-)
    cd_year INTEGER,                  -- Année de la transaction
    cd_type VARCHAR(4),              -- Type de bien (ex: B001)
    cd_type_nl VARCHAR(100),        -- Description en néerlandais
    cd_type_fr VARCHAR(100),        -- Description en français
    ms_transactions INTEGER,         -- Nombre de transactions
    ms_p25 DECIMAL(15,2),           -- Prix 25e percentile
    ms_p50 DECIMAL(15,2),           -- Prix médian
    ms_p75 DECIMAL(15,2),           -- Prix 75e percentile
    ms_p10 DECIMAL(15,2),           -- Prix 10e percentile
    ms_p90 DECIMAL(15,2),           -- Prix 90e percentile
    
    -- Métadonnées de chargement
    id_batch INTEGER,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes basiques de structure
    CONSTRAINT chk_year_range 
        CHECK (cd_year BETWEEN 1900 AND 2100),
        
        
    CONSTRAINT chk_type_format 
        CHECK (cd_type ~ '^B[0-9A]{3}$')
);

-- Index pour optimiser le nettoyage
CREATE INDEX IF NOT EXISTS idx_raw_r_e_s_batch 
    ON raw_staging.raw_real_estate_sector(id_batch);

CREATE INDEX IF NOT EXISTS idx_raw_r_e_s_sector 
    ON raw_staging.raw_real_estate_sector(cd_stat_sector);

CREATE INDEX IF NOT EXISTS idx_raw_r_e_s_year 
    ON raw_staging.raw_real_estate_sector(cd_year);

-- Trigger pour la mise à jour automatique de dt_updated
CREATE OR REPLACE FUNCTION raw_staging.update_raw_r_e_s_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_raw_r_e_s_timestamp
    BEFORE UPDATE ON raw_staging.raw_real_estate_sector
    FOR EACH ROW
    EXECUTE FUNCTION raw_staging.update_raw_r_e_s_timestamp();

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'raw_staging',
    'raw_real_estate_sector',
    'Table de staging brute pour les données de transactions immobilières',
    'REAL_ESTATE_TRANSACTIONS'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE raw_staging.raw_real_estate_sector IS 
'Table de staging brute pour les données de transactions immobilières. Reflète exactement la structure du fichier source.';

COMMENT ON COLUMN raw_staging.raw_real_estate_sector.cd_stat_sector IS 'Code du secteur statistique';
COMMENT ON COLUMN raw_staging.raw_real_estate_sector.cd_year IS 'Année de la transaction';
COMMENT ON COLUMN raw_staging.raw_real_estate_sector.cd_type IS 'Code du type de bien';
COMMENT ON COLUMN raw_staging.raw_real_estate_sector.cd_type_nl IS 'Description du type de bien en néerlandais';
COMMENT ON COLUMN raw_staging.raw_real_estate_sector.cd_type_fr IS 'Description du type de bien en français';
COMMENT ON COLUMN raw_staging.raw_real_estate_sector.ms_transactions IS 'Nombre de transactions';
COMMENT ON COLUMN raw_staging.raw_real_estate_sector.ms_p25 IS 'Prix au 25e percentile';
COMMENT ON COLUMN raw_staging.raw_real_estate_sector.ms_p50 IS 'Prix médian (50e percentile)';
COMMENT ON COLUMN raw_staging.raw_real_estate_sector.ms_p75 IS 'Prix au 75e percentile';
COMMENT ON COLUMN raw_staging.raw_real_estate_sector.ms_p10 IS 'Prix au 10e percentile';
COMMENT ON COLUMN raw_staging.raw_real_estate_sector.ms_p90 IS 'Prix au 90e percentile';
COMMENT ON COLUMN raw_staging.raw_real_estate_sector.id_batch IS 'Identifiant du batch de chargement';

-- Log du succès
SELECT utils.log_script_execution('create_raw_real_estate_sector.sql', 'SUCCESS');