-- 01_raw_staging/tables/raw_population_structure.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_raw_population_structure.sql', 'RUNNING');

-- Suppression de la table si elle existe
DROP TABLE IF EXISTS raw_staging.raw_population_structure;

-- Création de la table
CREATE TABLE IF NOT EXISTS raw_staging.raw_population_structure (
    -- Structure exacte du fichier CSV
    CD_REFNIS VARCHAR(5),
    TX_DESCR_NL VARCHAR(100),
    TX_DESCR_FR VARCHAR(100),
    CD_DSTR_REFNIS VARCHAR(5),
    TX_ADM_DSTR_DESCR_NL VARCHAR(100),
    TX_ADM_DSTR_DESCR_FR VARCHAR(100),
    CD_PROV_REFNIS VARCHAR(7),
    TX_PROV_DESCR_NL VARCHAR(100),
    TX_PROV_DESCR_FR VARCHAR(100),
    CD_RGN_REFNIS VARCHAR(5),
    TX_RGN_DESCR_NL VARCHAR(100),
    TX_RGN_DESCR_FR VARCHAR(100),
    CD_SEX CHAR(1),
    CD_NATLTY VARCHAR(3),
    TX_NATLTY_NL VARCHAR(50),
    TX_NATLTY_FR VARCHAR(50),
    CD_CIV_STS VARCHAR(2),
    TX_CIV_STS_NL VARCHAR(50),
    TX_CIV_STS_FR VARCHAR(50),
    CD_AGE INTEGER,
    MS_POPULATION INTEGER,
    
    -- Métadonnées de chargement
    id_batch INTEGER,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index pour optimiser les validations et le nettoyage
CREATE INDEX IF NOT EXISTS idx_raw_pop_batch 
    ON raw_staging.raw_population_structure(id_batch);
    
CREATE INDEX IF NOT EXISTS idx_raw_pop_refnis 
    ON raw_staging.raw_population_structure(CD_REFNIS);

-- Trigger pour la mise à jour automatique de dt_updated
CREATE OR REPLACE FUNCTION raw_staging.update_raw_pop_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_raw_pop_timestamp
    BEFORE UPDATE ON raw_staging.raw_population_structure
    FOR EACH ROW
    EXECUTE FUNCTION raw_staging.update_raw_pop_timestamp();

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'raw_staging',
    'raw_population_structure',
    'Table de staging brut pour les données de structure de population',
    'POP_STRUCT'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE raw_staging.raw_population_structure IS 
'Table de staging brut pour les données de structure de population - reflète exactement le format du fichier source';

-- Log du succès
SELECT utils.log_script_execution('create_raw_population_structure.sql', 'SUCCESS');