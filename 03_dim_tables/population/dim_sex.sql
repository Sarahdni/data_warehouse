-- 03_dim_tables/population/dim_sex.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_dim_sex.sql', 'RUNNING');

-- Création de la fonction trigger
CREATE OR REPLACE FUNCTION dw.update_sex_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création de la table dimensionnelle
CREATE TABLE IF NOT EXISTS dw.dim_sex (
    -- Clés et identifiants
    cd_sex CHAR(1) PRIMARY KEY,
    
    -- Libellés multilingues
    tx_sex_fr VARCHAR(20) NOT NULL,
    tx_sex_nl VARCHAR(20) NOT NULL,
    tx_sex_de VARCHAR(20) NOT NULL,
    tx_sex_en VARCHAR(20) NOT NULL,
    
    -- Traçabilité
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT chk_valid_sex CHECK (cd_sex IN ('M', 'F','A'))
);

DROP TRIGGER IF EXISTS tr_update_sex_timestamp ON dw.dim_sex;
CREATE TRIGGER tr_update_sex_timestamp
    BEFORE UPDATE ON dw.dim_sex
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_sex_timestamp();

-- Insertion des données de base
INSERT INTO dw.dim_sex (
    cd_sex,
    tx_sex_fr,
    tx_sex_nl,
    tx_sex_de,
    tx_sex_en
) VALUES
    ('M', 'Masculin', 'Mannelijk', 'Männlich', 'Male'),
    ('F', 'Féminin', 'Vrouwelijk', 'Weiblich', 'Female'),
    ('A', 'Tous les sexes', 'Alle geslachten', 'Alle Geschlechter', 'All sexes')
ON CONFLICT (cd_sex) DO UPDATE SET
    tx_sex_fr = EXCLUDED.tx_sex_fr,
    tx_sex_nl = EXCLUDED.tx_sex_nl,
    tx_sex_de = EXCLUDED.tx_sex_de,
    tx_sex_en = EXCLUDED.tx_sex_en,
    dt_updated = CURRENT_TIMESTAMP;

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'dim_sex',
    'Table dimensionnelle du sexe/genre',
    'SYSTEM'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE dw.dim_sex IS 'Dimension sexe/genre pour les statistiques démographiques';
COMMENT ON COLUMN dw.dim_sex.cd_sex IS 'Code du sexe (M=Masculin, F=Féminin)';
COMMENT ON COLUMN dw.dim_sex.tx_sex_fr IS 'Libellé en français';
COMMENT ON COLUMN dw.dim_sex.tx_sex_nl IS 'Libellé en néerlandais';
COMMENT ON COLUMN dw.dim_sex.tx_sex_de IS 'Libellé en allemand';
COMMENT ON COLUMN dw.dim_sex.tx_sex_en IS 'Libellé en anglais';

-- Log du succès
SELECT utils.log_script_execution('create_dim_sex.sql', 'SUCCESS');
