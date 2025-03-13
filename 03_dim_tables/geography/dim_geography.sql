-- 02_dim_tables/geography/dim_geography.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_dim_geography.sql', 'RUNNING');

-- Création de la table dimensionnelle
CREATE TABLE IF NOT EXISTS dw.dim_geography (
    -- Clés et identifiants
    id_geography SERIAL PRIMARY KEY,
    cd_lau VARCHAR(10) NOT NULL,          -- Code LAU/NUTS
    cd_refnis VARCHAR(10),                -- Code REFNIS (pour les communes)
    cd_sector VARCHAR(10),                -- Code du secteur statistique
    
    -- Libellés multilingues
    tx_name_fr TEXT NOT NULL,
    tx_name_nl TEXT NOT NULL,
    tx_name_de TEXT,
    tx_name_en TEXT,
    
    -- Hiérarchie
    cd_level INTEGER NOT NULL,            -- Niveau hiérarchique (1=région, 2=province, etc.)
    cd_parent VARCHAR(10),                -- Code du niveau supérieur
    
    -- Gestion des versions (SCD Type 2)
    dt_start DATE NOT NULL,               -- Date de début de validité
    dt_end DATE,                          -- Date de fin de validité
    fl_current BOOLEAN NOT NULL DEFAULT TRUE,  -- Indicateur de version courante
    
    -- Traçabilité
    id_batch INTEGER,                     -- ID du batch de chargement
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT chk_geography_level CHECK (cd_level >= 0 AND cd_level <= 6),
    CONSTRAINT chk_geography_dates CHECK (dt_start <= dt_end OR dt_end IS NULL)
);

-- Index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_geography_lau ON dw.dim_geography(cd_lau);
CREATE INDEX IF NOT EXISTS idx_geography_refnis ON dw.dim_geography(cd_refnis);
CREATE INDEX IF NOT EXISTS idx_geography_sector ON dw.dim_geography(cd_sector);
CREATE INDEX IF NOT EXISTS idx_geography_current ON dw.dim_geography(fl_current);
CREATE INDEX IF NOT EXISTS idx_geography_hierarchy ON dw.dim_geography(cd_parent, cd_level);
CREATE INDEX IF NOT EXISTS idx_geography_dates ON dw.dim_geography(dt_start, dt_end);

-- Index unique conditionnel sur la version courante
CREATE UNIQUE INDEX IF NOT EXISTS uk_geography_current 
ON dw.dim_geography(cd_lau) 
WHERE fl_current = TRUE;

-- Trigger pour mise à jour automatique de dt_updated
CREATE OR REPLACE FUNCTION dw.update_geography_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_update_geography_timestamp ON dw.dim_geography;
CREATE TRIGGER tr_update_geography_timestamp
    BEFORE UPDATE ON dw.dim_geography
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_geography_timestamp();

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry(
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'dim_geography',
    'Table dimensionnelle de la géographie belge (NUTS/LAU/Secteurs)',
    'NUTS_LAU'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE dw.dim_geography IS 'Dimension géographique - Hiérarchie territoriale belge';
COMMENT ON COLUMN dw.dim_geography.cd_lau IS 'Code unique LAU/NUTS';
COMMENT ON COLUMN dw.dim_geography.cd_refnis IS 'Code REFNIS (uniquement pour les communes)';
COMMENT ON COLUMN dw.dim_geography.cd_sector IS 'Code du secteur statistique';
COMMENT ON COLUMN dw.dim_geography.cd_level IS 'Niveau hiérarchique (1=région, 2=province, etc.)';
COMMENT ON COLUMN dw.dim_geography.cd_parent IS 'Code du niveau hiérarchique supérieur';
COMMENT ON COLUMN dw.dim_geography.dt_start IS 'Date de début de validité de la version';
COMMENT ON COLUMN dw.dim_geography.dt_end IS 'Date de fin de validité de la version';
COMMENT ON COLUMN dw.dim_geography.fl_current IS 'Indique si c''est la version courante';

-- Log du succès
SELECT utils.log_script_execution('create_dim_geography.sql', 'SUCCESS');