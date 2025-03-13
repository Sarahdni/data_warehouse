-- 02_dim_tables/time/dim_date.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_dim_date.sql', 'RUNNING');

-- Création de la table dimensionnelle
CREATE TABLE IF NOT EXISTS dw.dim_date (
    -- Clés et identifiants
    id_date SERIAL PRIMARY KEY,
    cd_year INTEGER NOT NULL,
    cd_semester SMALLINT,
    cd_quarter SMALLINT,
    cd_month SMALLINT,
    cd_period_type CHAR(1),
    
    -- Labels multilingues pour la période
    tx_period_fr VARCHAR(50),
    tx_period_nl VARCHAR(50),
    tx_period_de VARCHAR(50),
    tx_period_en VARCHAR(50),
    
    -- Labels courts multilingues
    tx_period_short_fr VARCHAR(20),
    tx_period_short_nl VARCHAR(20),
    tx_period_short_de VARCHAR(20),
    tx_period_short_en VARCHAR(20),
    
    -- Traçabilité
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT uk_dim_date UNIQUE(cd_year,cd_semester, cd_quarter, cd_month, cd_period_type),
    CONSTRAINT chk_period_type CHECK (cd_period_type IN ('Y','S', 'Q', 'M')),
    CONSTRAINT chk_semester CHECK ( (cd_period_type = 'S' AND cd_semester BETWEEN 1 AND 2) 
                                OR  (cd_period_type != 'S' AND cd_semester IS NULL)),
    CONSTRAINT chk_quarter CHECK (cd_quarter BETWEEN 1 AND 4 OR cd_quarter IS NULL),
    CONSTRAINT chk_month CHECK (cd_month BETWEEN 1 AND 12 OR cd_month IS NULL),
    CONSTRAINT chk_period_consistency CHECK (
        (cd_period_type = 'Y' AND cd_quarter IS NULL AND cd_month IS NULL) OR
        (cd_period_type = 'S' AND cd_quarter IS NULL AND cd_month IS NULL) OR
        (cd_period_type = 'Q' AND cd_quarter IS NOT NULL AND cd_month IS NULL) OR
        (cd_period_type = 'M' AND cd_month IS NOT NULL)
    )
);

-- Index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_date_year ON dw.dim_date(cd_year);
CREATE INDEX IF NOT EXISTS idx_date_quarter ON dw.dim_date(cd_year, cd_quarter) 
WHERE cd_period_type = 'Q';
CREATE INDEX IF NOT EXISTS idx_date_month ON dw.dim_date(cd_year, cd_month) 
WHERE cd_period_type = 'M';

-- Vue pour les périodes courantes (remplace la colonne générée)
CREATE OR REPLACE VIEW dw.v_dim_date_current AS
SELECT 
    *,
    CASE cd_period_type
        WHEN 'Y' THEN cd_year = EXTRACT(YEAR FROM CURRENT_DATE)
        WHEN 'Q' THEN cd_year = EXTRACT(YEAR FROM CURRENT_DATE) 
                    AND cd_quarter = EXTRACT(QUARTER FROM CURRENT_DATE)
        WHEN 'M' THEN cd_year = EXTRACT(YEAR FROM CURRENT_DATE) 
                    AND cd_month = EXTRACT(MONTH FROM CURRENT_DATE)
    END AS fl_current_period
FROM dw.dim_date;

-- Fonction pour le trigger
CREATE OR REPLACE FUNCTION dw.update_date_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création du trigger
DROP TRIGGER IF EXISTS tr_update_date_timestamp ON dw.dim_date;
CREATE TRIGGER tr_update_date_timestamp
    BEFORE UPDATE ON dw.dim_date
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_date_timestamp();

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry(
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'dim_date',
    'Table dimensionnelle temporelle (Années/Trimestres/Mois)',
    'SYSTEM'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE dw.dim_date IS 'Dimension temporelle - Hiérarchie Année/Trimestre/Mois';
COMMENT ON COLUMN dw.dim_date.cd_year IS 'Année (YYYY)';
COMMENT ON COLUMN dw.dim_date.cd_semester IS 'Numéro du semestre (1-2) uniquement pour cd_period_type = S';
COMMENT ON COLUMN dw.dim_date.cd_quarter IS 'Trimestre (1-4)';
COMMENT ON COLUMN dw.dim_date.cd_month IS 'Mois (1-12)';
COMMENT ON COLUMN dw.dim_date.cd_period_type IS 'Type de période (Y=Year, Q=Quarter, M=Month)';

-- Log du succès
SELECT utils.log_script_execution('create_dim_date.sql', 'SUCCESS');