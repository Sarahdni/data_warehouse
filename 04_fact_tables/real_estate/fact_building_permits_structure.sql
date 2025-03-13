-- 03_fact_tables/real_estate/fact_building_permits_structure.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_fact_building_permits_structure.sql', 'RUNNING');

-- Table pour les mesures de type COUNT (nombre de bâtiments, logements, etc.)
CREATE TABLE IF NOT EXISTS dw.fact_building_permits_counts (
    -- Clés dimensionnelles
    id_date INTEGER NOT NULL,
    id_geography INTEGER NOT NULL,
    
    -- Mesures de comptage
    nb_buildings INTEGER NOT NULL DEFAULT 0,        -- Nombre de bâtiments
    nb_dwellings INTEGER NOT NULL DEFAULT 0,        -- Nombre de logements
    nb_apartments INTEGER NOT NULL DEFAULT 0,       -- Nombre d'appartements
    nb_houses INTEGER NOT NULL DEFAULT 0,           -- Nombre de maisons individuelles
    
    -- Flags pour le type (résidentiel/non-résidentiel et nouveau/rénovation)
    fl_residential BOOLEAN NOT NULL,
    fl_new_construction BOOLEAN NOT NULL,
    
    -- Traçabilité
    id_batch INTEGER,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT pk_fact_bp_counts 
        PRIMARY KEY (id_date, id_geography, fl_residential, fl_new_construction),
        
    CONSTRAINT fk_fact_bp_counts_date 
        FOREIGN KEY (id_date) 
        REFERENCES dw.dim_date(id_date),
        
    CONSTRAINT fk_fact_bp_counts_geography 
        FOREIGN KEY (id_geography) 
        REFERENCES dw.dim_geography(id_geography),
        
    CONSTRAINT chk_fact_bp_counts_positive 
        CHECK (nb_buildings >= 0 AND nb_dwellings >= 0 
               AND nb_apartments >= 0 AND nb_houses >= 0)
);

-- Table pour les mesures de surface (en m²)
CREATE TABLE IF NOT EXISTS dw.fact_building_permits_surface (
    -- Clés dimensionnelles
    id_date INTEGER NOT NULL,
    id_geography INTEGER NOT NULL,
    
    -- Mesures de surface
    nb_surface_m2 DECIMAL(15,2) NOT NULL,        -- Surface en m²
    
    -- Flags
    fl_residential BOOLEAN NOT NULL,             -- Toujours TRUE pour cette table
    fl_new_construction BOOLEAN NOT NULL,        -- Toujours TRUE pour cette table
    
    -- Traçabilité
    id_batch INTEGER,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT pk_fact_bp_surface
        PRIMARY KEY (id_date, id_geography),
        
    CONSTRAINT fk_fact_bp_surface_date 
        FOREIGN KEY (id_date) 
        REFERENCES dw.dim_date(id_date),
        
    CONSTRAINT fk_fact_bp_surface_geography 
        FOREIGN KEY (id_geography) 
        REFERENCES dw.dim_geography(id_geography),
        
    CONSTRAINT chk_fact_bp_surface_positive 
        CHECK (nb_surface_m2 >= 0),
        
    CONSTRAINT chk_fact_bp_surface_residential 
        CHECK (fl_residential = TRUE),
        
    CONSTRAINT chk_fact_bp_surface_new 
        CHECK (fl_new_construction = TRUE)
);

-- Table pour les mesures de volume (en m³)
CREATE TABLE IF NOT EXISTS dw.fact_building_permits_volume (
    -- Clés dimensionnelles
    id_date INTEGER NOT NULL,
    id_geography INTEGER NOT NULL,
    
    -- Mesures de volume
    nb_volume_m3 DECIMAL(15,2) NOT NULL,        -- Volume en m³
    
    -- Flags
    fl_residential BOOLEAN NOT NULL,             -- Toujours FALSE pour cette table
    fl_new_construction BOOLEAN NOT NULL,        -- Toujours TRUE pour cette table
    
    -- Traçabilité
    id_batch INTEGER,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT pk_fact_bp_volume
        PRIMARY KEY (id_date, id_geography),
        
    CONSTRAINT fk_fact_bp_volume_date 
        FOREIGN KEY (id_date) 
        REFERENCES dw.dim_date(id_date),
        
    CONSTRAINT fk_fact_bp_volume_geography 
        FOREIGN KEY (id_geography) 
        REFERENCES dw.dim_geography(id_geography),
        
    CONSTRAINT chk_fact_bp_volume_positive 
        CHECK (nb_volume_m3 >= 0),
        
    CONSTRAINT chk_fact_bp_volume_nonresidential 
        CHECK (fl_residential = FALSE),
        
    CONSTRAINT chk_fact_bp_volume_new 
        CHECK (fl_new_construction = TRUE)
);

-- Index pour optimiser les requêtes courantes
CREATE INDEX IF NOT EXISTS idx_fact_bp_counts_date ON dw.fact_building_permits_counts(id_date);
CREATE INDEX IF NOT EXISTS idx_fact_bp_counts_geo ON dw.fact_building_permits_counts(id_geography);
CREATE INDEX IF NOT EXISTS idx_fact_bp_counts_type ON dw.fact_building_permits_counts(fl_residential, fl_new_construction);
CREATE INDEX IF NOT EXISTS idx_fact_bp_counts_batch ON dw.fact_building_permits_counts(id_batch);

CREATE INDEX IF NOT EXISTS idx_fact_bp_surface_date ON dw.fact_building_permits_surface(id_date);
CREATE INDEX IF NOT EXISTS idx_fact_bp_surface_geo ON dw.fact_building_permits_surface(id_geography);
CREATE INDEX IF NOT EXISTS idx_fact_bp_surface_batch ON dw.fact_building_permits_surface(id_batch);

CREATE INDEX IF NOT EXISTS idx_fact_bp_volume_date ON dw.fact_building_permits_volume(id_date);
CREATE INDEX IF NOT EXISTS idx_fact_bp_volume_geo ON dw.fact_building_permits_volume(id_geography);
CREATE INDEX IF NOT EXISTS idx_fact_bp_volume_batch ON dw.fact_building_permits_volume(id_batch);

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (nm_schema, nm_table, tx_description, cd_source)
VALUES 
    ('dw', 'fact_building_permits_counts', 
     'Table de faits des permis de construire - mesures de comptage', 'BUILDING_PERMITS'),
    ('dw', 'fact_building_permits_surface', 
     'Table de faits des permis de construire - mesures de surface', 'BUILDING_PERMITS'),
    ('dw', 'fact_building_permits_volume', 
     'Table de faits des permis de construire - mesures de volume', 'BUILDING_PERMITS')
ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Log du succès
SELECT utils.log_script_execution('create_fact_building_permits_structure.sql', 'SUCCESS');