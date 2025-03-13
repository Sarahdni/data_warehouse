-- 02_dim_tables/population/dim_cohabitation_status.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_dim_cohabitation.sql', 'RUNNING');

-- Création de la fonction trigger
CREATE OR REPLACE FUNCTION dw.update_cohabitation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création de la table dimensionnelle
CREATE TABLE IF NOT EXISTS dw.dim_cohabitation_status (
    -- Clés et identifiants
    cd_cohabitation VARCHAR(5) PRIMARY KEY,
    fl_cohab INTEGER NOT NULL,
    
    -- Libellés multilingues
    tx_cohab_fr VARCHAR(100) NOT NULL,
    tx_cohab_nl VARCHAR(100) NOT NULL,
    tx_cohab_de VARCHAR(100) NOT NULL,
    tx_cohab_en VARCHAR(100) NOT NULL,
    
    -- Traçabilité
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT chk_valid_cohab CHECK (fl_cohab IN (0, 1))
);

DROP TRIGGER IF EXISTS tr_update_cohabitation_timestamp ON dw.dim_cohabitation_status;
CREATE TRIGGER tr_update_cohabitation_timestamp
    BEFORE UPDATE ON dw.dim_cohabitation_status
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_cohabitation_timestamp();

-- Insertion des données de base
INSERT INTO dw.dim_cohabitation_status (
    cd_cohabitation,
    fl_cohab,
    tx_cohab_fr,
    tx_cohab_nl,
    tx_cohab_de,
    tx_cohab_en
) VALUES
    ('NON', 0, 'Pas en cohabitation légale', 'Geen wettelijke samenwoning', 
     'Keine gesetzliche Lebensgemeinschaft', 'No legal cohabitation'),
    ('OUI', 1, 'En cohabitation légale', 'Wettelijke samenwoning', 
     'Gesetzliche Lebensgemeinschaft', 'Legal cohabitation')
ON CONFLICT (cd_cohabitation) DO UPDATE SET
    fl_cohab = EXCLUDED.fl_cohab,
    tx_cohab_fr = EXCLUDED.tx_cohab_fr,
    tx_cohab_nl = EXCLUDED.tx_cohab_nl,
    tx_cohab_de = EXCLUDED.tx_cohab_de,
    tx_cohab_en = EXCLUDED.tx_cohab_en,
    dt_updated = CURRENT_TIMESTAMP;

-- Index pour la recherche par fl_cohab
CREATE INDEX IF NOT EXISTS idx_cohabitation_flag 
ON dw.dim_cohabitation_status(fl_cohab);

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'dim_cohabitation_status',
    'Table dimensionnelle des statuts de cohabitation légale',
    'SYSTEM'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE dw.dim_cohabitation_status IS 'Dimension statut de cohabitation légale';
COMMENT ON COLUMN dw.dim_cohabitation_status.cd_cohabitation IS 'Code du statut de cohabitation';
COMMENT ON COLUMN dw.dim_cohabitation_status.fl_cohab IS 'Indicateur de cohabitation (0=Non, 1=Oui)';
COMMENT ON COLUMN dw.dim_cohabitation_status.tx_cohab_fr IS 'Libellé en français';
COMMENT ON COLUMN dw.dim_cohabitation_status.tx_cohab_nl IS 'Libellé en néerlandais';
COMMENT ON COLUMN dw.dim_cohabitation_status.tx_cohab_de IS 'Libellé en allemand';
COMMENT ON COLUMN dw.dim_cohabitation_status.tx_cohab_en IS 'Libellé en anglais';

-- Log du succès
SELECT utils.log_script_execution('create_dim_cohabitation.sql', 'SUCCESS');