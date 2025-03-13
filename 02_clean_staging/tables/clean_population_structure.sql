-- 02_clean_staging/tables/clean_population_structure.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_clean_population_structure.sql', 'RUNNING');

CREATE TABLE IF NOT EXISTS clean_staging.clean_population_structure (
    -- Clés vers les dimensions
    id_geography INTEGER,             -- Lien vers dim_geography
    cd_sex CHAR(1),                  -- Lien vers dim_sex
    cd_age INTEGER,                  -- Lien vers dim_age
    cd_nationality VARCHAR(10),       -- Lien vers dim_nationality
    cd_civil_status VARCHAR(5),       -- Lien vers dim_civil_status
    cd_year INTEGER,                 -- Pour lien futur avec dim_date
    
    -- Mesure
    ms_population INTEGER NOT NULL,
    
    -- Traçabilité
    id_batch INTEGER,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Flags de validation
    fl_valid_geography BOOLEAN DEFAULT FALSE,
    fl_valid_sex BOOLEAN DEFAULT FALSE,
    fl_valid_age BOOLEAN DEFAULT FALSE,
    fl_valid_nationality BOOLEAN DEFAULT FALSE,
    fl_valid_civil_status BOOLEAN DEFAULT FALSE,
    
    -- Contraintes
    CONSTRAINT chk_population_positive CHECK (ms_population >= 0),
    
    
    -- Clés étrangères
    FOREIGN KEY (cd_sex) REFERENCES dw.dim_sex(cd_sex),
    FOREIGN KEY (cd_nationality) REFERENCES dw.dim_nationality(cd_nationality),
    FOREIGN KEY (cd_civil_status) REFERENCES dw.dim_civil_status(cd_civil_status),
    FOREIGN KEY (cd_age) REFERENCES dw.dim_age(cd_age),
    FOREIGN KEY (id_geography) REFERENCES dw.dim_geography(id_geography)
);

-- Index pour les jointures fréquentes
CREATE INDEX IF NOT EXISTS idx_clean_pop_geography 
    ON clean_staging.clean_population_structure(id_geography);
    
CREATE INDEX IF NOT EXISTS idx_clean_pop_batch 
    ON clean_staging.clean_population_structure(id_batch);

-- Index composites pour les analyses démographiques courantes
CREATE INDEX IF NOT EXISTS idx_clean_pop_demo 
    ON clean_staging.clean_population_structure(cd_sex, cd_age, cd_nationality);

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'clean_staging',
    'clean_population_structure',
    'Table de staging nettoyée pour les données de structure de population',
    'POP_STRUCT'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Log du succès
SELECT utils.log_script_execution('create_clean_population_structure.sql', 'SUCCESS');