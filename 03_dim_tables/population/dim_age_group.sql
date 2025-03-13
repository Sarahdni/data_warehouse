-- 03_dim_tables/population/dim_age_group.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_dim_age_group.sql', 'RUNNING');

-- Création de la fonction trigger
CREATE OR REPLACE FUNCTION dw.update_age_group_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.dt_updated = CURRENT_TIMESTAMP;
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création de la table
CREATE TABLE IF NOT EXISTS dw.dim_age_group (
   cd_age_group VARCHAR(10) PRIMARY KEY,
   cd_age_min INTEGER,
   cd_age_max INTEGER,
   fl_total BOOLEAN NOT NULL DEFAULT FALSE,
   tx_age_group_fr VARCHAR(100) NOT NULL,
   tx_age_group_nl VARCHAR(100) NOT NULL,
   tx_age_group_de VARCHAR(100) NOT NULL,
   tx_age_group_en VARCHAR(100) NOT NULL,
   dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   CONSTRAINT chk_age_group_range CHECK (
      (cd_age_group = 'A' AND cd_age_min IS NULL AND cd_age_max IS NULL AND fl_total = TRUE) OR
      (cd_age_group != 'A' AND cd_age_min IS NOT NULL AND cd_age_max IS NOT NULL AND fl_total = FALSE AND cd_age_min <= cd_age_max)
   ),
   CONSTRAINT chk_age_group_valid_ranges CHECK (
       fl_total = TRUE OR
       (cd_age_min >= 0 AND cd_age_max <= 120)
   )
);

-- Création des index
CREATE INDEX IF NOT EXISTS idx_age_group_total 
ON dw.dim_age_group(fl_total) WHERE fl_total = TRUE;

CREATE INDEX IF NOT EXISTS idx_age_group_ranges 
ON dw.dim_age_group(cd_age_min, cd_age_max) 
WHERE fl_total = FALSE;

-- Création du trigger
DROP TRIGGER IF EXISTS tr_update_age_group_timestamp ON dw.dim_age_group;
CREATE TRIGGER tr_update_age_group_timestamp
   BEFORE UPDATE ON dw.dim_age_group
   FOR EACH ROW
   EXECUTE FUNCTION dw.update_age_group_timestamp();

-- Insertion des données
INSERT INTO dw.dim_age_group (
   cd_age_group,
   cd_age_min,
   cd_age_max,
   fl_total,
   tx_age_group_fr,
   tx_age_group_nl,
   tx_age_group_de,
   tx_age_group_en
) VALUES
   ('15-24', 15, 24, FALSE,
    'Jeunes (15-24 ans)', 'Jongeren (15-24 jaar)',
    'Jugendliche (15-24 Jahre)', 'Youth (15-24 years)'),
   
   ('25-54', 25, 54, FALSE,
    'Âge principal de travail (25-54 ans)', 'Hoofdarbeidsleeftijd (25-54 jaar)',
    'Haupterwerbsalter (25-54 Jahre)', 'Prime working age (25-54 years)'),
   
   ('55-74', 55, 74, FALSE,
    'Seniors actifs (55-74 ans)', 'Actieve senioren (55-74 jaar)',
    'Aktive Senioren (55-74 Jahre)', 'Active seniors (55-74 years)'),
   
   ('0-17', 0, 17, FALSE,
    'Mineurs (0-17 ans)', 'Minderjarigen (0-17 jaar)',
    'Minderjährige (0-17 Jahre)', 'Minors (0-17 years)'),
   
   ('18-64', 18, 64, FALSE,
    'Adultes (18-64 ans)', 'Volwassenen (18-64 jaar)',
    'Erwachsene (18-64 Jahre)', 'Adults (18-64 years)'),
   
   ('65+', 65, 120, FALSE,
    'Seniors (65 ans et plus)', 'Senioren (65+ jaar)',
    'Senioren (65+ Jahre)', 'Seniors (65+ years)'),
   
   ('A', NULL, NULL, TRUE,
    'Tous âges', 'Alle leeftijden',
    'Alle Altersgruppen', 'All ages');

-- Commentaires
COMMENT ON TABLE dw.dim_age_group IS 'Dimension des groupes d''âge pour différents contextes d''analyse';
COMMENT ON COLUMN dw.dim_age_group.cd_age_group IS 'Code unique du groupe d''âge';
COMMENT ON COLUMN dw.dim_age_group.cd_age_min IS 'Âge minimum du groupe (NULL pour TOTAL)';
COMMENT ON COLUMN dw.dim_age_group.cd_age_max IS 'Âge maximum du groupe (NULL pour TOTAL)';
COMMENT ON COLUMN dw.dim_age_group.fl_total IS 'Flag identifiant le groupe comme étant un TOTAL';

-- Enregistrement dans le registre
INSERT INTO metadata.table_registry (
   nm_schema,
   nm_table,
   tx_description,
   cd_source
) VALUES (
   'dw',
   'dim_age_group',
   'Table dimensionnelle des groupes d''âge',
   'SYSTEM'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Log du succès
SELECT utils.log_script_execution('create_dim_age_group.sql', 'SUCCESS');