-- 04_fact_tables/population/fact_population_structure.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_fact_population_structure.sql', 'RUNNING');

-- Création de la table de fait
CREATE TABLE IF NOT EXISTS dw.fact_population_structure (
    -- Clé primaire surrogate
    id_population_sk BIGSERIAL PRIMARY KEY,
    
    -- Clés étrangères vers les dimensions
    id_date INTEGER NOT NULL,            -- Lien vers dim_date
    id_geography INTEGER NOT NULL,       -- Lien vers dim_geography
    id_age INTEGER NOT NULL,             -- Lien vers dim_age
    cd_sex CHAR(1) NOT NULL,             -- Lien vers dim_sex
    cd_nationality VARCHAR(10) NOT NULL, -- Lien vers dim_nationality
    cd_civil_status VARCHAR(5) NOT NULL, -- Lien vers dim_civil_status
    
    -- Mesures
    ms_population INTEGER NOT NULL,     -- Nombre de personnes
    
    
    -- Traçabilité
    id_batch INTEGER NOT NULL,           -- ID du batch de chargement
    fl_current BOOLEAN NOT NULL DEFAULT TRUE,  -- Indique si c'est la version courante
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Contraintes
    CONSTRAINT chk_population_positive CHECK (ms_population >= 0),
    
    -- Clés étrangères
    CONSTRAINT fk_population_date FOREIGN KEY (id_date) 
        REFERENCES dw.dim_date(id_date),
    CONSTRAINT fk_population_geography FOREIGN KEY (id_geography) 
        REFERENCES dw.dim_geography(id_geography),
    CONSTRAINT fk_population_age FOREIGN KEY (id_age) 
        REFERENCES dw.dim_age(cd_age),
    CONSTRAINT fk_population_sex FOREIGN KEY (cd_sex) 
        REFERENCES dw.dim_sex(cd_sex),
    CONSTRAINT fk_population_nationality FOREIGN KEY (cd_nationality) 
        REFERENCES dw.dim_nationality(cd_nationality),
    CONSTRAINT fk_population_civil_status FOREIGN KEY (cd_civil_status) 
        REFERENCES dw.dim_civil_status(cd_civil_status)
);

-- Index pour optimiser les jointures et recherches
CREATE INDEX IF NOT EXISTS idx_fac_pop_date ON dw.fact_population_structure(id_date);
CREATE INDEX IF NOT EXISTS idx_fac_pop_geography ON dw.fact_population_structure(id_geography);
CREATE INDEX IF NOT EXISTS idx_fac_pop_age ON dw.fact_population_structure(id_age);
CREATE INDEX IF NOT EXISTS idx_fac_pop_sex ON dw.fact_population_structure(cd_sex);
CREATE INDEX IF NOT EXISTS idx_fac_pop_nationality ON dw.fact_population_structure(cd_nationality);
CREATE INDEX IF NOT EXISTS idx_fac_pop_civil ON dw.fact_population_structure(cd_civil_status);
CREATE INDEX IF NOT EXISTS idx_fac_pop_batch ON dw.fact_population_structure(id_batch);
CREATE INDEX IF NOT EXISTS idx_fac_pop_current ON dw.fact_population_structure(fl_current);


-- Fonction trigger pour mise à jour automatique de dt_updated
CREATE OR REPLACE FUNCTION dw.update_fact_population_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour la mise à jour automatique
CREATE TRIGGER tr_update_fact_population_timestamp
    BEFORE UPDATE ON dw.fact_population_structure
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_fact_population_timestamp();

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'fac_population_structure',
    'Table de fait de la structure de la population',
    'POP_STRUCT'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE dw.fact_population_structure IS 'Table de fait contenant les statistiques démographiques par secteur, sexe, âge, nationalité et état civil';
COMMENT ON COLUMN dw.fact_population_structure.ms_population IS 'Nombre de personnes dans le groupe démographique';
COMMENT ON COLUMN dw.fact_population_structure.fl_current IS 'Indique si c''est la version courante des données';

-- Log du succès
SELECT utils.log_script_execution('create_fact_population_structure.sql', 'SUCCESS');


