-- 01_staging/tables/stg_building_permits.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_stg_building_permits.sql', 'RUNNING');

DO $$ 
BEGIN 
    -- Création de la table de staging
    CREATE TABLE IF NOT EXISTS staging.stg_building_permits (
        -- Structure exacte du CSV
        REFNIS VARCHAR(20),
        REFNIS_NL VARCHAR(100),
        REFNIS_FR VARCHAR(100),
        CD_YEAR INTEGER,
        CD_PERIOD INTEGER,
        MS_BUILDING_RES_NEW NUMERIC,
        MS_DWELLING_RES_NEW NUMERIC,
        MS_APARTMENT_RES_NEW NUMERIC,
        MS_SINGLE_HOUSE_RES_NEW NUMERIC,
        MS_TOTAL_SURFACE_RES_NEW NUMERIC,
        MS_BUILDING_RES_RENOVATION NUMERIC,
        MS_BUILDING_NONRES_NEW NUMERIC,
        MS_VOLUME_NONRES_NEW NUMERIC,
        MS_BUILDING_NONRES_RENOVATION NUMERIC,
        CD_REFNIS_NATION VARCHAR(20),
        CD_REFNIS_REGION VARCHAR(20),
        CD_REFNIS_PROVINCE VARCHAR(20),
        CD_REFNIS_DISTRICT VARCHAR(20),
        CD_REFNIS_MUNICIPALITY VARCHAR(20),
        CD_REFNIS_LEVEL INTEGER,

        -- Métadonnées de chargement
        DT_IMPORT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CD_SOURCE VARCHAR(50) NOT NULL DEFAULT 'BUILDING_PERMITS',
        ID_BATCH INTEGER                        -- Pour le suivi des lots de chargement
    );

    -- Index pour optimiser les chargements et validations
    CREATE INDEX IF NOT EXISTS idx_stg_building_permits_refnis 
        ON staging.stg_building_permits(REFNIS);
        
    CREATE INDEX IF NOT EXISTS idx_stg_building_permits_period 
        ON staging.stg_building_permits(CD_YEAR, CD_PERIOD);
        
    CREATE INDEX IF NOT EXISTS idx_stg_building_permits_batch 
        ON staging.stg_building_permits(ID_BATCH);

    -- Enregistrement dans le registre des tables
    INSERT INTO metadata.table_registry (
        nm_schema,
        nm_table,
        tx_description,
        cd_source
    ) VALUES (
        'staging',
        'stg_building_permits',
        'Table de staging pour les permis de construire',
        'BUILDING_PERMITS'
    ) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

    -- Log du succès
    PERFORM utils.log_script_execution('create_stg_building_permits.sql', 'SUCCESS');

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution('create_stg_building_permits.sql', 'ERROR', SQLERRM);
    RAISE;
END $$;

-- Commentaires
COMMENT ON TABLE staging.stg_building_permits IS 'Table de staging pour les données de permis de construire';
COMMENT ON COLUMN staging.stg_building_permits.ID_BATCH IS 'Identifiant du lot de chargement';