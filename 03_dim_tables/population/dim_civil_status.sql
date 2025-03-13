-- 02_dim_tables/population/dim_civil_status.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_dim_civil_status.sql', 'RUNNING');

-- Création de la fonction trigger
CREATE OR REPLACE FUNCTION dw.update_civil_status_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création de la table dimensionnelle
CREATE TABLE IF NOT EXISTS dw.dim_civil_status (
    -- Clés et identifiants
    cd_civil_status VARCHAR(5) PRIMARY KEY,
    
    -- Libellés multilingues
    tx_civil_status_fr VARCHAR(100) NOT NULL,
    tx_civil_status_nl VARCHAR(100) NOT NULL,
    tx_civil_status_de VARCHAR(100) NOT NULL,
    tx_civil_status_en VARCHAR(100) NOT NULL,
    
    -- Traçabilité
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT chk_valid_civil_status CHECK (cd_civil_status IN ('CEL', 'MAR', 'DIV', 'VEU', 'SEP'))
);

DROP TRIGGER IF EXISTS tr_update_civil_status_timestamp ON dw.dim_civil_status;
CREATE TRIGGER tr_update_civil_status_timestamp
    BEFORE UPDATE ON dw.dim_civil_status
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_civil_status_timestamp();

-- Insertion des données de base
INSERT INTO dw.dim_civil_status (
    cd_civil_status,
    tx_civil_status_fr,
    tx_civil_status_nl,
    tx_civil_status_de,
    tx_civil_status_en
) VALUES
    ('CEL', 'Célibataire', 'Ongehuwd', 'Ledig', 'Single'),
    ('MAR', 'Marié(e)', 'Gehuwd', 'Verheiratet', 'Married'),
    ('DIV', 'Divorcé(e)', 'Gescheiden', 'Geschieden', 'Divorced'),
    ('VEU', 'Veuf/Veuve', 'Weduwe/Weduwnaar', 'Verwitwet', 'Widowed'),
    ('SEP', 'Séparé(e)', 'Gescheiden van tafel en bed', 'Getrennt', 'Separated')
ON CONFLICT (cd_civil_status) DO UPDATE SET
    tx_civil_status_fr = EXCLUDED.tx_civil_status_fr,
    tx_civil_status_nl = EXCLUDED.tx_civil_status_nl,
    tx_civil_status_de = EXCLUDED.tx_civil_status_de,
    tx_civil_status_en = EXCLUDED.tx_civil_status_en,
    dt_updated = CURRENT_TIMESTAMP;

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'dim_civil_status',
    'Table dimensionnelle des états civils',
    'SYSTEM'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE dw.dim_civil_status IS 'Dimension état civil pour les statistiques démographiques';
COMMENT ON COLUMN dw.dim_civil_status.cd_civil_status IS 'Code de l''état civil (CEL=Célibataire, MAR=Marié, DIV=Divorcé, VEU=Veuf/Veuve, SEP=Séparé)';
COMMENT ON COLUMN dw.dim_civil_status.tx_civil_status_fr IS 'Libellé en français';
COMMENT ON COLUMN dw.dim_civil_status.tx_civil_status_nl IS 'Libellé en néerlandais';
COMMENT ON COLUMN dw.dim_civil_status.tx_civil_status_de IS 'Libellé en allemand';
COMMENT ON COLUMN dw.dim_civil_status.tx_civil_status_en IS 'Libellé en anglais';

-- Log du succès
SELECT utils.log_script_execution('create_dim_civil_status.sql', 'SUCCESS');

