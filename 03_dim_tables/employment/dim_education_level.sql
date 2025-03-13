-- 03_dim_tables/employment/dim_education_level.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_dim_education_level.sql', 'RUNNING');

-- Création de la fonction trigger
CREATE OR REPLACE FUNCTION dw.update_education_level_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création de la table
CREATE TABLE IF NOT EXISTS dw.dim_education_level (
    -- Clés et identifiants
    cd_education_level VARCHAR(10) PRIMARY KEY,
    cd_education_group VARCHAR(20),  -- Nouveau: pour gérer les groupes (1-2, 3-4, 5-8)
    fl_is_group BOOLEAN NOT NULL DEFAULT FALSE, -- Nouveau: indique si c'est un groupe
    
    -- Libellés multilingues
    tx_education_level_fr VARCHAR(200) NOT NULL,
    tx_education_level_nl VARCHAR(200) NOT NULL,
    tx_education_level_de VARCHAR(200) NOT NULL,
    tx_education_level_en VARCHAR(200) NOT NULL,
    
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
CREATE INDEX IF NOT EXISTS idx_education_level_current 
ON dw.dim_education_level(fl_current) 
WHERE fl_current = TRUE;

CREATE INDEX IF NOT EXISTS idx_education_level_dates 
ON dw.dim_education_level(dt_valid_from, dt_valid_to);

CREATE INDEX IF NOT EXISTS idx_education_level_group
ON dw.dim_education_level(cd_education_group);

-- Création du trigger
DROP TRIGGER IF EXISTS tr_update_education_level_timestamp ON dw.dim_education_level;
CREATE TRIGGER tr_update_education_level_timestamp
    BEFORE UPDATE ON dw.dim_education_level
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_education_level_timestamp();

-- Insertion des données ISCED 2011 - Niveaux individuels
INSERT INTO dw.dim_education_level (
    cd_education_level,
    cd_education_group,
    fl_is_group,
    tx_education_level_fr,
    tx_education_level_nl,
    tx_education_level_de,
    tx_education_level_en
) VALUES
    ('0', '0', FALSE,
     'Inférieur à l''enseignement primaire (niveau 0)',
     'Lager dan basisonderwijs (niveau 0)',
     'Unter Grundbildung (Niveau 0)',
     'Below primary education (level 0)'),
     
    ('1', '1-2', FALSE,
     'Primaire',
     'Basisonderwijs',
     'Grundbildung',
     'Primary'),
     
    ('2', '1-2', FALSE,
     'Secondaire inférieur',
     'Lager secundair',
     'Sekundarstufe I',
     'Lower secondary'),
     
    ('3', '3-4', FALSE,
     'Secondaire supérieur',
     'Hoger secundair',
     'Sekundarstufe II',
     'Upper secondary'),
     
    ('4', '3-4', FALSE,
     'Post-secondaire non-supérieur',
     'Post-secundair niet-hoger',
     'Postsekundär, nicht tertiär',
     'Post-secondary non-tertiary'),
     
    ('5', '5-8', FALSE,
     'Supérieur court',
     'Kort hoger',
     'Kurzer tertiärer',
     'Short-cycle tertiary'),
     
    ('6', '5-8', FALSE,
     'Bachelier',
     'Bachelor',
     'Bachelor',
     'Bachelor'),
     
    ('7', '5-8', FALSE,
     'Master',
     'Master',
     'Master',
     'Master'),
     
    ('8', '5-8', FALSE,
     'Doctorat',
     'Doctoraat',
     'Doktorat',
     'Doctoral'),

    -- Insertion des groupes
    ('GRP_1-2', '1-2', TRUE,
     'Enseignement primaire et premier cycle du secondaire (niveaux 1 et 2)',
     'Basisonderwijs en lager secundair onderwijs (niveaus 1 en 2)',
     'Grundbildung und Sekundarstufe I (Stufen 1 und 2)',
     'Primary and lower secondary education (levels 1 and 2)'),
     
    ('GRP_3-4', '3-4', TRUE,
     'Deuxième cycle de l''enseignement secondaire et enseignement postsecondaire non supérieur (niveaux 3 et 4)',
     'Hoger secundair en postsecundair niet-tertiair onderwijs (niveaus 3 en 4)',
     'Sekundarstufe II und postsekundäre, nicht-tertiäre Bildung (Stufen 3 und 4)',
     'Upper secondary and post-secondary non-tertiary education (levels 3 and 4)'),
     
    ('GRP_5-8', '5-8', TRUE,
     'Enseignement supérieur (niveaux 5 à 8)',
     'Tertiair onderwijs (niveaus 5-8)',
     'Tertiäre Bildung (Stufen 5-8)',
     'Higher education (levels 5-8)'),
     
    ('TOTAL', NULL, TRUE,
     'Total',
     'Totaal',
     'Gesamt',
     'Total')
ON CONFLICT (cd_education_level) DO UPDATE SET
    cd_education_group = EXCLUDED.cd_education_group,
    fl_is_group = EXCLUDED.fl_is_group,
    tx_education_level_fr = EXCLUDED.tx_education_level_fr,
    tx_education_level_nl = EXCLUDED.tx_education_level_nl,
    tx_education_level_de = EXCLUDED.tx_education_level_de,
    tx_education_level_en = EXCLUDED.tx_education_level_en,
    dt_updated = CURRENT_TIMESTAMP;

-- Enregistrement dans le registre
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'dim_education_level',
    'Dimension des niveaux d''éducation selon ISCED 2011',
    'SYSTEM'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE dw.dim_education_level IS 'Dimension des niveaux d''éducation selon ISCED 2011';
COMMENT ON COLUMN dw.dim_education_level.cd_education_level IS 'Code du niveau d''éducation ISCED 2011';
COMMENT ON COLUMN dw.dim_education_level.cd_education_group IS 'Code du groupe d''éducation (1-2, 3-4, 5-8)';
COMMENT ON COLUMN dw.dim_education_level.fl_is_group IS 'Indique si l''enregistrement représente un groupe';
COMMENT ON COLUMN dw.dim_education_level.tx_education_level_fr IS 'Description en français';
COMMENT ON COLUMN dw.dim_education_level.tx_education_level_nl IS 'Description en néerlandais';
COMMENT ON COLUMN dw.dim_education_level.tx_education_level_de IS 'Description en allemand';
COMMENT ON COLUMN dw.dim_education_level.tx_education_level_en IS 'Description en anglais';
COMMENT ON COLUMN dw.dim_education_level.dt_valid_from IS 'Date de début de validité';
COMMENT ON COLUMN dw.dim_education_level.dt_valid_to IS 'Date de fin de validité';
COMMENT ON COLUMN dw.dim_education_level.fl_current IS 'Indicateur de version courante';

-- Log du succès
SELECT utils.log_script_execution('create_dim_education_level.sql', 'SUCCESS');