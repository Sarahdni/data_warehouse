-- 02_dim_tables/population/dim_nationality.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_dim_nationality.sql', 'RUNNING');

-- Création de la fonction trigger
CREATE OR REPLACE FUNCTION dw.update_nationality_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création de la table dimensionnelle
CREATE TABLE IF NOT EXISTS dw.dim_nationality (
    -- Clés et identifiants
    cd_nationality VARCHAR(10) PRIMARY KEY,
    
    -- Libellés multilingues
    tx_nationality_fr VARCHAR(50) NOT NULL,
    tx_nationality_nl VARCHAR(50) NOT NULL,
    tx_nationality_de VARCHAR(50) NOT NULL,
    tx_nationality_en VARCHAR(50) NOT NULL,
    
    -- Traçabilité
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT chk_valid_nationality CHECK (cd_nationality IN ('BE', 'NOT_BE'))
);

DROP TRIGGER IF EXISTS tr_update_nationality_timestamp ON dw.dim_nationality;
CREATE TRIGGER tr_update_nationality_timestamp
    BEFORE UPDATE ON dw.dim_nationality
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_nationality_timestamp();

-- Insertion des données de base
INSERT INTO dw.dim_nationality (
    cd_nationality,
    tx_nationality_fr,
    tx_nationality_nl,
    tx_nationality_de,
    tx_nationality_en
) VALUES
    ('BE', 'Belge', 'Belgisch', 'Belgisch', 'Belgian'),
    ('NOT_BE', 'Non-Belge', 'Niet-Belgisch', 'Nicht-Belgisch', 'Non-Belgian')
ON CONFLICT (cd_nationality) DO UPDATE SET
    tx_nationality_fr = EXCLUDED.tx_nationality_fr,
    tx_nationality_nl = EXCLUDED.tx_nationality_nl,
    tx_nationality_de = EXCLUDED.tx_nationality_de,
    tx_nationality_en = EXCLUDED.tx_nationality_en,
    dt_updated = CURRENT_TIMESTAMP;

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'dim_nationality',
    'Table dimensionnelle des nationalités',
    'SYSTEM'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE dw.dim_nationality IS 'Dimension nationalité pour les statistiques démographiques';
COMMENT ON COLUMN dw.dim_nationality.cd_nationality IS 'Code de nationalité (BE=Belge, NOT_BE=Non-Belge)';
COMMENT ON COLUMN dw.dim_nationality.tx_nationality_fr IS 'Libellé en français';
COMMENT ON COLUMN dw.dim_nationality.tx_nationality_nl IS 'Libellé en néerlandais';
COMMENT ON COLUMN dw.dim_nationality.tx_nationality_de IS 'Libellé en allemand';
COMMENT ON COLUMN dw.dim_nationality.tx_nationality_en IS 'Libellé en anglais';

-- Log du succès
SELECT utils.log_script_execution('create_dim_nationality.sql', 'SUCCESS');