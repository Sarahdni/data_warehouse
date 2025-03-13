-- 01_raw_staging/tables/raw_building_stock.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_raw_building_stock.sql', 'RUNNING');

DO $$ 
BEGIN 
    -- Création de la table de staging
    CREATE TABLE IF NOT EXISTS raw_staging.raw_building_stock (
        -- Structure exacte du CSV
        CD_YEAR INTEGER,
        CD_REFNIS VARCHAR(20),
        TX_REFNIS_NL VARCHAR(100),
        TX_REFNIS_FR VARCHAR(100),
        CD_REFNIS_LVL INTEGER,
        CD_STAT_TYPE VARCHAR(10),
        TX_STAT_TYPE_NL VARCHAR(100),
        TX_STAT_TYPE_FR VARCHAR(100),
        CD_BUILDING_TYPE VARCHAR(2),
        TX_BUILDING_TYPE_NL VARCHAR(100),
        TX_BUILDING_TYPE_FR VARCHAR(100),
        MS_VALUE NUMERIC,

        -- Métadonnées de chargement
        DT_IMPORT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CD_SOURCE VARCHAR(50) NOT NULL DEFAULT 'BUILDING_STOCK',
        ID_BATCH INTEGER                        -- Pour le suivi des lots de chargement
    );

    -- Index pour optimiser les chargements et validations
    CREATE INDEX IF NOT EXISTS idx_raw_building_stock_refnis 
        ON raw_staging.raw_building_stock(CD_REFNIS);
        
    CREATE INDEX IF NOT EXISTS idx_raw_building_stock_year 
        ON raw_staging.raw_building_stock(CD_YEAR);
        
    CREATE INDEX IF NOT EXISTS idx_raw_building_stock_batch 
        ON raw_staging.raw_building_stock(ID_BATCH);

    -- Enregistrement dans le registre des tables
    INSERT INTO metadata.table_registry (
        nm_schema,
        nm_table,
        tx_description,
        cd_source
    ) VALUES (
        'raw_staging',
        'raw_building_stock',
        'Table de raw_staging pour les statistiques du parc immobilier',
        'BUILDING_STOCK'
    ) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

    -- Log du succès
    PERFORM utils.log_script_execution('create_raw_building_stock.sql', 'SUCCESS');

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution('create_raw_building_stock.sql', 'ERROR', SQLERRM);
    RAISE;
END $$;

-- Commentaires
COMMENT ON TABLE raw_staging.raw_building_stock IS 'Table de staging pour les données du parc immobilier';
COMMENT ON COLUMN raw_staging.raw_building_stock.ID_BATCH IS 'Identifiant du lot de chargement';