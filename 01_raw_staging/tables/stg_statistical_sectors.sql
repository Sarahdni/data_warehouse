-- 01_staging/tables/stg_statistical_sectors.sql


-- Log du début d'exécution
SELECT utils.log_script_execution('create_stg_statistical_sectors.sql', 'RUNNING');

DO $$ 
BEGIN 
    -- Création de la table de staging
    CREATE TABLE IF NOT EXISTS staging.stg_statistical_sectors (
        -- Identifiants
        ogc_fid INTEGER,
        cd_sector VARCHAR(10),
        
        -- Descriptions secteur
        tx_sector_descr_nl VARCHAR(100),
        tx_sector_descr_fr VARCHAR(100),
        tx_sector_descr_de VARCHAR(100),
        
        -- Hiérarchie administrative
        cd_sub_munty VARCHAR(10),
        tx_sub_munty_nl VARCHAR(100),
        tx_sub_munty_fr VARCHAR(100),
        
        cd_munty_refnis VARCHAR(10),
        tx_munty_descr_nl VARCHAR(100),
        tx_munty_descr_fr VARCHAR(100),
        tx_munty_descr_de VARCHAR(100),
        tx_munty_dstr VARCHAR(100),
        
        cd_dstr_refnis VARCHAR(10),
        tx_adm_dstr_descr_nl VARCHAR(100),
        tx_adm_dstr_descr_fr VARCHAR(100),
        tx_adm_dstr_descr_de VARCHAR(100),
        
        cd_prov_refnis VARCHAR(10),
        tx_prov_descr_nl VARCHAR(100),
        tx_prov_descr_fr VARCHAR(100),
        tx_prov_descr_de VARCHAR(100),
        
        cd_rgn_refnis VARCHAR(10),
        tx_rgn_descr_nl VARCHAR(100),
        tx_rgn_descr_fr VARCHAR(100),
        tx_rgn_descr_de VARCHAR(100),
        
        -- Codes NUTS
        cd_country CHAR(2),
        cd_nuts_lvl1 VARCHAR(3),
        cd_nuts_lvl2 VARCHAR(4),
        cd_nuts_lvl3 VARCHAR(5),
        
        -- Mesures
        ms_area_ha DECIMAL(15,6),
        ms_perimeter_m DECIMAL(15,2),

        -- Géométrie
        geom geometry(MULTIPOLYGON),     -- Type PostGIS pour stocker la géométrie
        
        -- Métadonnées
        tx_spatial_ref VARCHAR(20),      -- EPSG:31370 ou EPSG:3812
        dt_situation DATE,               -- Date de référence des données
        dt_validity_start DATE,          
        dt_validity_end DATE,                
        
        -- Traçabilité
        id_batch INTEGER,
        dt_import TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

    -- Index pour optimiser les validations et chargements
    CREATE INDEX IF NOT EXISTS idx_stg_sectors_batch 
        ON staging.stg_statistical_sectors(id_batch);
    CREATE INDEX IF NOT EXISTS idx_stg_sectors_refnis 
        ON staging.stg_statistical_sectors(cd_munty_refnis);
    CREATE INDEX IF NOT EXISTS idx_stg_sectors_code 
        ON staging.stg_statistical_sectors(cd_sector);
    CREATE INDEX IF NOT EXISTS idx_stg_sectors_geom 
        ON staging.stg_statistical_sectors USING GIST(geom);

    

    -- Enregistrement dans le registre des tables
    INSERT INTO metadata.table_registry (
        nm_schema,
        nm_table,
        tx_description,
        cd_source
    ) VALUES (
        'staging',
        'stg_statistical_sectors',
        'Table de staging pour les secteurs statistiques',
        'STATBEL_SECTORS'
    ) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

    -- Log du succès
    PERFORM utils.log_script_execution('create_stg_statistical_sectors.sql', 'SUCCESS');

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution('create_stg_statistical_sectors.sql', 'ERROR', SQLERRM);
    RAISE;
END $$;

COMMENT ON TABLE staging.stg_statistical_sectors IS 'Table de staging pour les secteurs statistiques belges';

