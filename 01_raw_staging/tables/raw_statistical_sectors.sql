-- 01_raw_staging/tables/raw_statistical_sectors.sql

SELECT utils.log_script_execution('create_raw_statistical_sectors.sql', 'RUNNING');

DO $$ 
BEGIN 
    CREATE TABLE IF NOT EXISTS raw_staging.raw_statistical_sectors (
        -- Identifiant technique
        id_raw_sector SERIAL PRIMARY KEY,
        
        -- Codes administratifs
        cd_country VARCHAR(9),
        cd_sector VARCHAR(9),
        cd_sub_munty VARCHAR(9),        -- Format: 5 chiffres + 4 caractères (ex: 12021B023)
        cd_munty_refnis VARCHAR(9),  -- Sera paddé dans clean_staging
        cd_dstr_refnis VARCHAR(9),   -- Sera paddé dans clean_staging
        cd_prov_refnis VARCHAR(9),   -- Sera paddé dans clean_staging
        cd_rgn_refnis VARCHAR(9),    -- Sera paddé dans clean_staging
        
        -- Codes NUTS
        cd_nuts_lv1 VARCHAR(9),
        cd_nuts_lv2 VARCHAR(9),
        cd_nuts_lv3 VARCHAR(9),
        
        -- Descriptions multilingues
        tx_sector_descr_fr TEXT,
        tx_sector_descr_nl TEXT,
        tx_sector_descr_de TEXT,
        tx_sector_descr_en TEXT,
        tx_sub_munty_fr TEXT,
        tx_sub_munty_nl TEXT,
        tx_sub_munty_de TEXT,
        tx_sub_munty_en TEXT,
        tx_munty_descr_fr TEXT,
        tx_munty_descr_nl TEXT,
        tx_munty_descr_de TEXT,
        tx_munty_descr_en TEXT,
        tx_munty_dstr TEXT,
        tx_adm_dstr_descr_fr TEXT,
        tx_adm_dstr_descr_nl TEXT,
        tx_adm_dstr_descr_de TEXT,
        tx_adm_dstr_descr_en TEXT,
        tx_prov_descr_fr TEXT,
        tx_prov_descr_nl TEXT,
        tx_prov_descr_de TEXT,
        tx_prov_descr_en TEXT,
        tx_rgn_descr_fr TEXT,
        tx_rgn_descr_nl TEXT,
        tx_rgn_descr_de TEXT,
        tx_rgn_descr_en TEXT,
        
        -- Géométrie 
        geom_31370 geometry(MultiPolygon),
        geom_3812 geometry(MultiPolygon),
        ms_area_ha NUMERIC(15,10), -- surface en hectares
        ms_perimeter_m NUMERIC(15,3), -- périmètre en mètres
      
        
        -- Métadonnées temporelles et traçabilité
        year_reference INTEGER,     -- Année de référence fournie lors du chargement
        dt_import TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        id_batch INTEGER NOT NULL,  -- Pour lier avec metadata.source_file_history
        
        -- Information sur la source
        tx_source_file VARCHAR(255) NOT NULL  -- Nom du fichier source
    );

    -- Index demandé
    CREATE INDEX IF NOT EXISTS idx_raw_sectors_munty_refnis 
        ON raw_staging.raw_statistical_sectors(cd_munty_refnis);

    -- Index pour jointure avec dim_geography
    CREATE INDEX IF NOT EXISTS idx_raw_sectors_cd_sector 
        ON raw_staging.raw_statistical_sectors(cd_sector);


    -- Enregistrement dans le registre des tables
    INSERT INTO metadata.table_registry (
        nm_schema,
        nm_table,
        tx_description,
        cd_source
    ) VALUES (
        'raw_staging',
        'raw_statistical_sectors',
        'Données brutes des secteurs statistiques',
        'STATBEL_SECTORS'
    ) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

    -- Log du succès
    PERFORM utils.log_script_execution('create_raw_statistical_sectors.sql', 'SUCCESS');

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution('create_raw_statistical_sectors.sql', 'ERROR', SQLERRM);
    RAISE;
END $$;

-- Commentaires
COMMENT ON TABLE raw_staging.raw_statistical_sectors IS 'Table de staging des secteurs statistiques belges';
COMMENT ON COLUMN raw_staging.raw_statistical_sectors.year_reference IS 'Année de référence fournie lors du chargement';
COMMENT ON COLUMN raw_staging.raw_statistical_sectors.tx_source_file IS 'Nom du fichier source pour traçabilité';