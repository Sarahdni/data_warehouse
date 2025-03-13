-- 04_fact_tables/un_employment/fact_unemployment.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_fact_unemployment.sql', 'RUNNING');

-- Création de la table des faits
CREATE TABLE IF NOT EXISTS dw.fact_unemployment (
    -- Clé technique
    id_fact_unemployment SERIAL PRIMARY KEY,
    
    -- Clés dimensionnelles
    id_date INTEGER NOT NULL,               -- Référence vers dim_date
    id_geography INTEGER NOT NULL,          -- Référence vers dim_geography
    cd_sex CHAR(1) NOT NULL,               -- Référence vers dim_sex
    cd_age_group VARCHAR(10) NOT NULL,      -- Référence vers dim_age_group
    cd_education_level VARCHAR(10) NOT NULL, -- Référence vers dim_education_level
    cd_unemp_type VARCHAR(20) NOT NULL,     -- Référence vers dim_unemployment_type
    
    -- Mesures
    ms_unemployment_rate DECIMAL(10,4),     -- Taux de chômage
    
    -- Flags d'agrégation
    fl_total_sex BOOLEAN DEFAULT FALSE,
    fl_total_age BOOLEAN DEFAULT FALSE,
    fl_total_education BOOLEAN DEFAULT FALSE,
    fl_total_geography BOOLEAN DEFAULT FALSE,
    
    -- Traçabilité
    fl_valid BOOLEAN NOT NULL DEFAULT TRUE,
    id_batch INTEGER NOT NULL,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT fk_fact_unemployment_date 
        FOREIGN KEY (id_date) 
        REFERENCES dw.dim_date(id_date),
        
    CONSTRAINT fk_fact_unemployment_geography 
        FOREIGN KEY (id_geography) 
        REFERENCES dw.dim_geography(id_geography),
        
    CONSTRAINT fk_fact_unemployment_sex
        FOREIGN KEY (cd_sex)
        REFERENCES dw.dim_sex(cd_sex),
        
    CONSTRAINT fk_fact_unemployment_age
        FOREIGN KEY (cd_age_group)
        REFERENCES dw.dim_age_group(cd_age_group),
        
    CONSTRAINT fk_fact_unemployment_education
        FOREIGN KEY (cd_education_level)
        REFERENCES dw.dim_education_level(cd_education_level),
        
    CONSTRAINT fk_fact_unemployment_type
        FOREIGN KEY (cd_unemp_type)
        REFERENCES dw.dim_unemployment_type(cd_unemp_type),
        
    CONSTRAINT uk_fact_unemployment 
        UNIQUE (id_date, id_geography, cd_sex, cd_age_group, cd_education_level, cd_unemp_type),
        
    CONSTRAINT chk_unemployment_rate 
        CHECK (ms_unemployment_rate >= 0 AND ms_unemployment_rate <= 1)
);

-- Index pour optimiser les jointures
CREATE INDEX IF NOT EXISTS idx_fact_unemployment_date 
    ON dw.fact_unemployment(id_date);

CREATE INDEX IF NOT EXISTS idx_fact_unemployment_geography 
    ON dw.fact_unemployment(id_geography);

CREATE INDEX IF NOT EXISTS idx_fact_unemployment_sex 
    ON dw.fact_unemployment(cd_sex);

CREATE INDEX IF NOT EXISTS idx_fact_unemployment_age 
    ON dw.fact_unemployment(cd_age_group);

CREATE INDEX IF NOT EXISTS idx_fact_unemployment_education 
    ON dw.fact_unemployment(cd_education_level);

CREATE INDEX IF NOT EXISTS idx_fact_unemployment_type 
    ON dw.fact_unemployment(cd_unemp_type);

CREATE INDEX IF NOT EXISTS idx_fact_unemployment_batch 
    ON dw.fact_unemployment(id_batch);

-- Index composites pour les requêtes courantes
CREATE INDEX IF NOT EXISTS idx_fact_unemployment_geo_date 
    ON dw.fact_unemployment(id_geography, id_date);

CREATE INDEX IF NOT EXISTS idx_fact_unemployment_demo_complete 
    ON dw.fact_unemployment(cd_sex, cd_age_group, cd_education_level, cd_unemp_type);

-- Trigger pour mise à jour automatique
CREATE OR REPLACE FUNCTION dw.update_fact_unemployment_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_fact_unemployment_timestamp
    BEFORE UPDATE ON dw.fact_unemployment
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_fact_unemployment_timestamp();

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'fact_unemployment',
    'Table des faits du chômage avec dimensions complètes',
    'LFS_UNEMPL'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires détaillés
COMMENT ON TABLE dw.fact_unemployment IS 
'Table des faits contenant les taux de chômage par période, géographie et caractéristiques démographiques.';

COMMENT ON COLUMN dw.fact_unemployment.id_fact_unemployment IS 
'Identifiant technique unique de la mesure de chômage';

COMMENT ON COLUMN dw.fact_unemployment.id_date IS 
'Référence vers la dimension temporelle (année/trimestre)';

COMMENT ON COLUMN dw.fact_unemployment.id_geography IS 
'Référence vers la dimension géographique (commune/région)';

COMMENT ON COLUMN dw.fact_unemployment.cd_sex IS 
'Référence vers la dimension sexe (M/F/A)';

COMMENT ON COLUMN dw.fact_unemployment.cd_age_group IS 
'Référence vers la dimension groupe d''âge (15-24, 25-54, 55-74, A)';

COMMENT ON COLUMN dw.fact_unemployment.cd_education_level IS 
'Référence vers la dimension niveau d''éducation (0, GRP_1-2, etc.)';

COMMENT ON COLUMN dw.fact_unemployment.cd_unemp_type IS 
'Référence vers la dimension type de chômage (NORMAL/LONG_TERM)';

COMMENT ON COLUMN dw.fact_unemployment.ms_unemployment_rate IS 
'Taux de chômage (entre 0 et 1)';

COMMENT ON COLUMN dw.fact_unemployment.fl_total_sex IS 
'Indique si la ligne représente un total pour tous les sexes';

COMMENT ON COLUMN dw.fact_unemployment.fl_total_age IS 
'Indique si la ligne représente un total pour tous les groupes d''âge';

COMMENT ON COLUMN dw.fact_unemployment.fl_total_education IS 
'Indique si la ligne représente un total pour tous les niveaux d''éducation';

COMMENT ON COLUMN dw.fact_unemployment.fl_total_geography IS 
'Indique si la ligne représente un total géographique';

COMMENT ON COLUMN dw.fact_unemployment.fl_valid IS 
'Indicateur de validité de la ligne';

COMMENT ON COLUMN dw.fact_unemployment.id_batch IS 
'Identifiant du lot de chargement';

COMMENT ON COLUMN dw.fact_unemployment.dt_created IS 
'Date et heure de création de l''enregistrement';

COMMENT ON COLUMN dw.fact_unemployment.dt_updated IS 
'Date et heure de dernière mise à jour de l''enregistrement';

-- Log du succès
SELECT utils.log_script_execution('create_fact_unemployment.sql', 'SUCCESS');
