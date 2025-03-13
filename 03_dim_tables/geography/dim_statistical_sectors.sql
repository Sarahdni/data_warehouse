-- 03_dim_tables/geography/dim_statistical_sectors.sql

-- Création de la table de dimension des secteurs statistiques
CREATE TABLE IF NOT EXISTS dw.dim_statistical_sectors (
    -- Clé surrogate et naturelle
    id_sector_sk SERIAL,                                -- Surrogate key
    cd_sector VARCHAR(9) NOT NULL,                      -- Code unique du secteur statistique
    
    -- Validité temporelle 
    dt_start DATE NOT NULL,                            -- Date de début de validité
    dt_end DATE NOT NULL,                              -- Date de fin de validité
    
    -- Codes administratifs et hiérarchie
    cd_refnis VARCHAR(5) NOT NULL,                      -- Code REFNIS commune
    cd_sub_munty VARCHAR(7),                            -- Code sous-commune
    cd_dstr_refnis VARCHAR(5),                          -- Code district
    cd_prov_refnis VARCHAR(5),                          -- Code province
    cd_rgn_refnis VARCHAR(5),                           -- Code région
    
    -- Codes NUTS pour analyses européennes
    cd_nuts1 VARCHAR(5),                                -- NUTS niveau 1 (régions)
    cd_nuts2 VARCHAR(5),                                -- NUTS niveau 2 (provinces)
    cd_nuts3 VARCHAR(5),                                -- NUTS niveau 3 (arrondissements)
    
    -- Libellés multilingues
    tx_sector_fr TEXT,                         -- Libellé du secteur en français
    tx_sector_nl TEXT,                         -- Libellé du secteur en néerlandais
    tx_sector_de TEXT,                                  -- Libellé du secteur en allemand
    tx_sector_en TEXT,                                  -- Libellé du secteur en anglais
    tx_sub_munty_fr TEXT,                              -- Libellé sous-commune en français
    tx_sub_munty_nl TEXT,                              -- Libellé sous-commune en néerlandais
    tx_sub_munty_de TEXT,                              -- Libellé sous-commune en allemand
    tx_sub_munty_en TEXT,                              -- Libellé sous-commune en anglais
    
    -- Informations géographiques
    geom_31370 geometry(MultiPolygon, 31370),                -- Géométrie en projection belge Lambert 72
    centroid_31370 geometry(Point, 31370),                    -- Point central calculé
    ms_area_ha NUMERIC(10,2),                          -- Surface en hectares
    ms_perimeter_m NUMERIC(10,2),                      -- Périmètre en mètres
    
    -- Métadonnées
    id_batch INTEGER NOT NULL,                          -- Identifiant du batch de chargement
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT pk_dim_statistical_sectors PRIMARY KEY (id_sector_sk),
    CONSTRAINT uk_sector_period UNIQUE (cd_sector, dt_start, dt_end),
    CONSTRAINT chk_dates CHECK (dt_start <= dt_end),
    CONSTRAINT chk_date_range CHECK (
        dt_start >= '1900-01-01' AND 
        dt_end <= '2100-12-31'
    )
);

-- Index pour optimiser les jointures et recherches fréquentes
CREATE INDEX IF NOT EXISTS idx_dim_statistical_sectors_cd 
    ON dw.dim_statistical_sectors(cd_sector);

CREATE INDEX IF NOT EXISTS idx_dim_statistical_sectors_dates 
    ON dw.dim_statistical_sectors(dt_start, dt_end);

CREATE INDEX IF NOT EXISTS idx_dim_statistical_sectors_refnis 
    ON dw.dim_statistical_sectors(cd_refnis);


-- Index spatial
CREATE INDEX IF NOT EXISTS idx_dim_statistical_sectors_geom 
    ON dw.dim_statistical_sectors USING GIST (geom_31370);

CREATE INDEX IF NOT EXISTS idx_dim_statistical_sectors_centroid 
    ON dw.dim_statistical_sectors USING GIST (centroid_31370);    





-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'dim_statistical_sectors',
    'Table de dimension des secteurs statistiques avec historisation',
    'STATBEL_SECTORS'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE dw.dim_statistical_sectors IS 'Dimension des secteurs statistiques belges avec période de validité';
COMMENT ON COLUMN dw.dim_statistical_sectors.id_sector_sk IS 'Clé surrogate de la dimension secteur statistique';
COMMENT ON COLUMN dw.dim_statistical_sectors.cd_sector IS 'Code unique du secteur statistique (format: 5 chiffres + lettre + 2-3 chiffres)';
COMMENT ON COLUMN dw.dim_statistical_sectors.dt_start IS 'Date de début de validité de la version';
COMMENT ON COLUMN dw.dim_statistical_sectors.dt_end IS 'Date de fin de validité (NULL si version courante)';
COMMENT ON COLUMN dw.dim_statistical_sectors.fl_current IS 'Indique si c''est la version courante du secteur';
COMMENT ON COLUMN dw.dim_statistical_sectors.cd_refnis IS 'Code REFNIS de la commune de rattachement';
COMMENT ON COLUMN dw.dim_statistical_sectors.geom IS 'Géométrie du secteur en projection Lambert 72 (EPSG:31370)';
