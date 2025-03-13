-- 01_raw_staging/tables/raw_immo_by_municipality.sql

CREATE TABLE IF NOT EXISTS raw_staging.raw_immo_by_municipality (
    -- Clé technique
    id_raw SERIAL PRIMARY KEY,
    
    -- Données brutes du CSV
    cd_year VARCHAR(4),
    cd_type_nl VARCHAR(100),
    cd_type_fr VARCHAR(100),
    cd_refnis VARCHAR(5),
    cd_refnis_nl VARCHAR(100),
    cd_refnis_fr VARCHAR(100),
    cd_period VARCHAR(2),
    cd_class_surface VARCHAR(50),
    ms_total_transactions VARCHAR(20),
    ms_total_price VARCHAR(20),
    ms_total_surface VARCHAR(20),
    ms_mean_price VARCHAR(20),
    ms_p10 VARCHAR(20),
    ms_p25 VARCHAR(20),
    ms_p50 VARCHAR(20),
    ms_p75 VARCHAR(20),
    ms_p90 VARCHAR(20),
    
    -- Traçabilité
    id_batch INTEGER,
    dt_import TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX IF NOT EXISTS idx_raw_immo_batch 
    ON raw_staging.raw_immo_by_municipality(id_batch);

CREATE INDEX IF NOT EXISTS idx_raw_immo_year 
    ON raw_staging.raw_immo_by_municipality(cd_year);

CREATE INDEX IF NOT EXISTS idx_raw_immo_refnis 
    ON raw_staging.raw_immo_by_municipality(cd_refnis);

COMMENT ON TABLE raw_staging.raw_immo_by_municipality IS 
'Table de staging brute pour les données immobilières par commune';

-- Commentaires sur les colonnes
COMMENT ON COLUMN raw_staging.raw_immo_by_municipality.cd_year IS 'Année de référence';
COMMENT ON COLUMN raw_staging.raw_immo_by_municipality.cd_type_nl IS 'Type de bien en néerlandais';
COMMENT ON COLUMN raw_staging.raw_immo_by_municipality.cd_type_fr IS 'Type de bien en français';
COMMENT ON COLUMN raw_staging.raw_immo_by_municipality.cd_refnis IS 'Code REFNIS de la commune';
COMMENT ON COLUMN raw_staging.raw_immo_by_municipality.cd_period IS 'Période (Q1-Q4: trimestres, S1-S2: semestres)';
COMMENT ON COLUMN raw_staging.raw_immo_by_municipality.cd_class_surface IS 'Classe de surface';
COMMENT ON COLUMN raw_staging.raw_immo_by_municipality.ms_total_transactions IS 'Nombre total de transactions';
COMMENT ON COLUMN raw_staging.raw_immo_by_municipality.ms_total_price IS 'Prix total des transactions';
COMMENT ON COLUMN raw_staging.raw_immo_by_municipality.ms_total_surface IS 'Surface totale';
COMMENT ON COLUMN raw_staging.raw_immo_by_municipality.ms_mean_price IS 'Prix moyen';
COMMENT ON COLUMN raw_staging.raw_immo_by_municipality.ms_p10 IS '10ème percentile du prix';
COMMENT ON COLUMN raw_staging.raw_immo_by_municipality.ms_p25 IS '25ème percentile du prix';
COMMENT ON COLUMN raw_staging.raw_immo_by_municipality.ms_p50 IS '50ème percentile du prix (médiane)';
COMMENT ON COLUMN raw_staging.raw_immo_by_municipality.ms_p75 IS '75ème percentile du prix';
COMMENT ON COLUMN raw_staging.raw_immo_by_municipality.ms_p90 IS '90ème percentile du prix';