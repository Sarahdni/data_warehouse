-- 02_dim_tables/population/dim_age.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_dim_age.sql', 'RUNNING');

-- Création de la fonction trigger
CREATE OR REPLACE FUNCTION dw.update_age_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création de la table
CREATE TABLE IF NOT EXISTS dw.dim_age (
    cd_age INTEGER PRIMARY KEY,
    cd_age_group VARCHAR(10),
    cd_social_group VARCHAR(20),
    cd_generation VARCHAR(20),
    fl_minor BOOLEAN GENERATED ALWAYS AS (cd_age < 18) STORED,
    fl_senior BOOLEAN GENERATED ALWAYS AS (cd_age >= 67) STORED,
    fl_working_age BOOLEAN GENERATED ALWAYS AS (cd_age BETWEEN 15 AND 67) STORED,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cd_age_group) REFERENCES dw.dim_age_group(cd_age_group),
    CONSTRAINT chk_valid_age CHECK (cd_age >= 0 AND cd_age <= 120)
);

-- Création des index
CREATE INDEX IF NOT EXISTS idx_age_working ON dw.dim_age(fl_working_age) WHERE fl_working_age = TRUE;
CREATE INDEX IF NOT EXISTS idx_age_groups ON dw.dim_age(cd_age_group);
CREATE INDEX IF NOT EXISTS idx_social_groups ON dw.dim_age(cd_social_group);
CREATE INDEX IF NOT EXISTS idx_generation ON dw.dim_age(cd_generation);

-- Création du trigger
DROP TRIGGER IF EXISTS tr_update_age_timestamp ON dw.dim_age;
CREATE TRIGGER tr_update_age_timestamp
    BEFORE UPDATE ON dw.dim_age
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_age_timestamp();

-- Insertion des données
INSERT INTO dw.dim_age (cd_age, cd_age_group, cd_social_group, cd_generation)
SELECT 
    age,
    CASE
        WHEN age < 15 THEN NULL
        WHEN age BETWEEN 15 AND 24 THEN '15-24'
        WHEN age BETWEEN 25 AND 54 THEN '25-54'
        WHEN age BETWEEN 55 AND 74 THEN '55-74'
        ELSE NULL
    END,
    CASE
        WHEN age BETWEEN 0 AND 17 THEN '0-17'
        WHEN age BETWEEN 18 AND 64 THEN '18-64'
        WHEN age >= 65 THEN '65+'
    END,
    CASE
        WHEN age <= 12 THEN 'GEN_ALPHA'
        WHEN age BETWEEN 13 AND 28 THEN 'GEN_Z'
        WHEN age BETWEEN 29 AND 44 THEN 'MILLENNIAL'
        WHEN age BETWEEN 45 AND 60 THEN 'GEN_X'
        WHEN age BETWEEN 61 AND 79 THEN 'BABY_BOOMER'
        ELSE 'SILENT_GEN'
    END
FROM generate_series(0, 120) age;

-- Commentaires
COMMENT ON TABLE dw.dim_age IS 'Dimension des âges avec support pour différents contextes';
COMMENT ON COLUMN dw.dim_age.cd_age IS 'Âge exact en années';
COMMENT ON COLUMN dw.dim_age.cd_age_group IS 'Référence vers les groupes d''âge standards';
COMMENT ON COLUMN dw.dim_age.cd_social_group IS 'Classification sociale';
COMMENT ON COLUMN dw.dim_age.cd_generation IS 'Classification générationnelle';
COMMENT ON COLUMN dw.dim_age.fl_minor IS 'Indique si l''âge est mineur (<18)';
COMMENT ON COLUMN dw.dim_age.fl_senior IS 'Indique si l''âge est senior (>=67)';
COMMENT ON COLUMN dw.dim_age.fl_working_age IS 'Indique si l''âge est en âge de travailler (15-67)';

-- Enregistrement dans le registre
INSERT INTO metadata.table_registry (nm_schema, nm_table, tx_description, cd_source)
VALUES ('dw', 'dim_age', 'Dimension des âges avec classifications multiples', 'SYSTEM')
ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Log du succès
SELECT utils.log_script_execution('create_dim_age.sql', 'SUCCESS');