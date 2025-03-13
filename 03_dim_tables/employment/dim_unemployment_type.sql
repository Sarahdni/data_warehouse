-- 03_dim_tables/employment/dim_unemployment_type.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_dim_unemployment_type.sql', 'RUNNING');

-- Création de la fonction trigger
CREATE OR REPLACE FUNCTION dw.update_unemployment_type_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création de la table
CREATE TABLE IF NOT EXISTS dw.dim_unemployment_type (
    -- Clés et identifiants
    cd_unemp_type VARCHAR(20) PRIMARY KEY,
    
    -- Libellés multilingues
    tx_unemp_type_fr VARCHAR(100) NOT NULL,
    tx_unemp_type_nl VARCHAR(100) NOT NULL,
    tx_unemp_type_de VARCHAR(100) NOT NULL,
    tx_unemp_type_en VARCHAR(100) NOT NULL,
    
    -- Gestion des versions (SCD Type 2)
    dt_valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
    dt_valid_to DATE,
    fl_current BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Traçabilité
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT chk_dates CHECK (dt_valid_from <= COALESCE(dt_valid_to, '9999-12-31'::date))
);

-- Création des index
CREATE INDEX IF NOT EXISTS idx_unemployment_type_current 
ON dw.dim_unemployment_type(fl_current) 
WHERE fl_current = TRUE;

CREATE INDEX IF NOT EXISTS idx_unemployment_type_dates 
ON dw.dim_unemployment_type(dt_valid_from, dt_valid_to);

-- Création du trigger
DROP TRIGGER IF EXISTS tr_update_unemployment_type_timestamp ON dw.dim_unemployment_type;
CREATE TRIGGER tr_update_unemployment_type_timestamp
    BEFORE UPDATE ON dw.dim_unemployment_type
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_unemployment_type_timestamp();

-- Insertion des données
INSERT INTO dw.dim_unemployment_type (
    cd_unemp_type,
    tx_unemp_type_fr,
    tx_unemp_type_nl,
    tx_unemp_type_de,
    tx_unemp_type_en
) VALUES
    ('NORMAL', 
     'Chômage standard', 
     'Standaard werkloosheids', 
     'Standard-Arbeitslosen', 
     'Standard unemployment'),
    
    ('LONG_TERM',
     'Chômage de longue durée', 
     'Langdurige werkloosheids', 
     'Langzeitarbeitslosen', 
     'Long-term unemployment')
ON CONFLICT (cd_unemp_type) DO UPDATE SET
    tx_unemp_type_fr = EXCLUDED.tx_unemp_type_fr,
    tx_unemp_type_nl = EXCLUDED.tx_unemp_type_nl,
    tx_unemp_type_de = EXCLUDED.tx_unemp_type_de,
    tx_unemp_type_en = EXCLUDED.tx_unemp_type_en,
    dt_updated = CURRENT_TIMESTAMP;

-- Enregistrement dans le registre
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'dim_unemployment_type',
    'Types de chômage',
    'SYSTEM'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE dw.dim_unemployment_type IS 'Dimension définissant les différents types de chômage (normal et longue durée)';
COMMENT ON COLUMN dw.dim_unemployment_type.cd_unemp_type IS 'Code unique du type de chômage';
COMMENT ON COLUMN dw.dim_unemployment_type.tx_unemp_type_fr IS 'Description du type de chômage en français';
COMMENT ON COLUMN dw.dim_unemployment_type.tx_unemp_type_nl IS 'Description du type de chômage en néerlandais';
COMMENT ON COLUMN dw.dim_unemployment_type.tx_unemp_type_de IS 'Description du type de chômage en allemand';
COMMENT ON COLUMN dw.dim_unemployment_type.tx_unemp_type_en IS 'Description du type de chômage en anglais';
COMMENT ON COLUMN dw.dim_unemployment_type.dt_valid_from IS 'Date de début de validité';
COMMENT ON COLUMN dw.dim_unemployment_type.dt_valid_to IS 'Date de fin de validité';
COMMENT ON COLUMN dw.dim_unemployment_type.fl_current IS 'Indicateur de version courante';

-- Log du succès
SELECT utils.log_script_execution('create_dim_unemployment_type.sql', 'SUCCESS');