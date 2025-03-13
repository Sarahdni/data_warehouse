-- 02_clean_staging/tables/clean_unemployment.sql

CREATE TABLE IF NOT EXISTS clean_staging.clean_unemployment (
    -- Clé technique
    id_clean SERIAL PRIMARY KEY,
    
    -- Référence temporelle
    id_date INTEGER NOT NULL REFERENCES dw.dim_date(id_date),
    
    -- Référence géographique
    id_geography INTEGER NOT NULL REFERENCES dw.dim_geography(id_geography),
    
    -- Références démographiques
    cd_sex CHAR(1),  -- NULL pour les totaux
    cd_age_group VARCHAR(10),  -- NULL pour les totaux
    cd_education_level VARCHAR(10),  -- table dim_education_level
    
    
    -- Mesures
    ms_unemployment_rate DECIMAL(10,4),
    
    -- Flags d'agrégation
    fl_total_sex BOOLEAN DEFAULT FALSE,
    fl_total_age BOOLEAN DEFAULT FALSE,
    fl_total_education BOOLEAN DEFAULT FALSE,
    fl_total_geography BOOLEAN DEFAULT FALSE,
    
  
    
    -- Métadonnées de la mesure
    cd_measure_type VARCHAR(50) NOT NULL,

    
    -- Validité et traçabilité
    fl_valid BOOLEAN NOT NULL DEFAULT TRUE,
    id_batch INTEGER NOT NULL,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT chk_sex CHECK (cd_sex IN ('M', 'F','A')),
    CONSTRAINT chk_age_group CHECK (
        cd_age_group IN ('15-24', '25-54', '55-74', 'A') 
        OR cd_age_group IS NULL
    ),
    CONSTRAINT chk_unemployment_rate CHECK (
        ms_unemployment_rate >= 0 AND ms_unemployment_rate <= 1
    ),
    CONSTRAINT chk_measure_type CHECK (
        cd_measure_type IN ('NORMAL', 'LONG_TERM')
    ),
    CONSTRAINT chk_totals CHECK (
        (fl_total_sex = TRUE AND cd_sex = 'A') OR
        (fl_total_sex = FALSE AND cd_sex IN ('M', 'F'))
    )
);

-- Index
CREATE INDEX IF NOT EXISTS idx_clean_unemployment_date 
    ON clean_staging.clean_unemployment(id_date);

CREATE INDEX IF NOT EXISTS idx_clean_unemployment_geo 
    ON clean_staging.clean_unemployment(id_geography);

CREATE INDEX IF NOT EXISTS idx_clean_unemployment_demo 
    ON clean_staging.clean_unemployment(cd_sex, cd_age_group, cd_education_level);

CREATE INDEX IF NOT EXISTS idx_clean_unemployment_batch 
    ON clean_staging.clean_unemployment(id_batch);


-- Commentaires détaillés
COMMENT ON TABLE clean_staging.clean_unemployment IS 
'Table de staging nettoyée pour les données de chômage, incluant les données détaillées et les agrégats';

