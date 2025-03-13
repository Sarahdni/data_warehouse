-- 04_fact_tables/un_employment/fact_vat_nace_employment.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_fact_vat_nace_employment.sql', 'RUNNING');

-- Création de la table des faits
CREATE TABLE IF NOT EXISTS dw.fact_vat_nace_employment (
    -- Clé technique
    id_fact_nace SERIAL PRIMARY KEY,
    
    -- Clés dimensionnelles
    id_date INTEGER NOT NULL,                   -- Référence temporelle (dim_date)
    id_geography INTEGER NOT NULL,              -- Référence géographique (dim_geography)
    cd_economic_activity VARCHAR(10) NOT NULL,  -- Code NACE (dim_economic_activity)
    cd_size_class VARCHAR(5) NOT NULL,          -- Classe de taille (dim_entreprise_size_employees)
    
    -- Mesures
    ms_num_entreprises INTEGER NOT NULL,        -- Nombre total d'entreprises
    ms_num_starts INTEGER NOT NULL DEFAULT 0,   -- Nombre de créations d'entreprises
    ms_num_stops INTEGER NOT NULL DEFAULT 0,    -- Nombre de cessations d'entreprises
    ms_net_creation INTEGER 
        GENERATED ALWAYS AS (ms_num_starts - ms_num_stops) STORED, -- Création nette
    
    -- Flags et niveaux
    fl_foreign BOOLEAN NOT NULL DEFAULT FALSE,  -- Entreprise étrangère
    cd_nace_level INTEGER NOT NULL,             -- Niveau NACE (1-5)
    
    -- Traçabilité
    id_batch INTEGER NOT NULL,                  -- Identifiant du lot de chargement
    cd_year INTEGER NOT NULL,                   -- Année de référence des données
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT fk_fact_nace_date 
        FOREIGN KEY (id_date) 
        REFERENCES dw.dim_date(id_date),
        
    CONSTRAINT fk_fact_nace_geography 
        FOREIGN KEY (id_geography) 
        REFERENCES dw.dim_geography(id_geography),
        
    CONSTRAINT fk_fact_nace_economic_activity
        FOREIGN KEY (cd_economic_activity)
        REFERENCES dw.dim_economic_activity(cd_economic_activity),
        
    CONSTRAINT fk_fact_nace_size
        FOREIGN KEY (cd_size_class)
        REFERENCES dw.dim_entreprise_size_employees(cd_size_class),
        
    CONSTRAINT uk_fact_nace_employment 
        UNIQUE (id_date, cd_economic_activity, cd_size_class, id_geography, fl_foreign),
        
    CONSTRAINT chk_nace_level 
        CHECK (cd_nace_level BETWEEN 1 AND 5),
        
    CONSTRAINT chk_size_class 
        CHECK (cd_size_class IN (
            '0',   -- Aucun employé
            '1',   -- 1-4 employés
            '2',   -- 5-9 employés
            '3',   -- 10-19 employés
            '4',   -- 20-49 employés
            '5',   -- 50-99 employés
            '6',   -- 100-199 employés
            '7',   -- 200-249 employés
            '8',   -- 250-499 employés
            '9',   -- 500-999 employés
            '10',  -- 1000-1999 employés
            '11',  -- 2000-2999 employés
            '12',  -- 3000-3999 employés
            '13',  -- 4000-4999 employés
            '14',  -- 5000-9999 employés
            '15'   -- 10000+ employés
        )),
        
    CONSTRAINT chk_numbers_positive 
        CHECK (
            ms_num_entreprises >= 0 AND 
            ms_num_starts >= 0 AND 
            ms_num_stops >= 0
        )
);

-- Index pour optimiser les jointures et recherches fréquentes
CREATE INDEX IF NOT EXISTS idx_fact_vat_nace_date 
    ON dw.fact_vat_nace_employment(id_date);

CREATE INDEX IF NOT EXISTS idx_fact_vat_nace_geography 
    ON dw.fact_vat_nace_employment(id_geography);

CREATE INDEX IF NOT EXISTS idx_fact_vat_nace_activity 
    ON dw.fact_vat_nace_employment(cd_economic_activity);

CREATE INDEX IF NOT EXISTS idx_fact_vat_nace_size 
    ON dw.fact_vat_nace_employment(cd_size_class);

CREATE INDEX IF NOT EXISTS idx_fact_vat_nace_foreign 
    ON dw.fact_vat_nace_employment(fl_foreign);

CREATE INDEX IF NOT EXISTS idx_fact_vat_nace_batch 
    ON dw.fact_vat_nace_employment(id_batch);

CREATE INDEX IF NOT EXISTS idx_fact_vat_nace_year
    ON dw.fact_vat_nace_employment(cd_year);

-- Index composites pour les requêtes courantes
CREATE INDEX IF NOT EXISTS idx_fact_vat_nace_activity_size 
    ON dw.fact_vat_nace_employment(cd_economic_activity, cd_size_class);

CREATE INDEX IF NOT EXISTS idx_fact_vat_nace_geo_date 
    ON dw.fact_vat_nace_employment(id_geography, id_date);

CREATE INDEX IF NOT EXISTS idx_fact_vat_nace_year_activity
    ON dw.fact_vat_nace_employment(cd_year, cd_economic_activity);

-- Trigger pour mise à jour automatique
CREATE OR REPLACE FUNCTION dw.update_fact_vat_nace_timestamp()
RETURNS TRIGGER AS $
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_update_fact_vat_nace_timestamp ON dw.fact_vat_nace_employment;
CREATE TRIGGER tr_update_fact_vat_nace_timestamp
    BEFORE UPDATE ON dw.fact_vat_nace_employment
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_fact_vat_nace_timestamp();

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'fact_vat_nace_employment',
    'Table des faits de l''emploi par secteur NACE, classe de taille et géographie',
    'VAT_NACE_EMPL'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires détaillés
COMMENT ON TABLE dw.fact_vat_nace_employment IS 
'Table des faits contenant les statistiques d''emploi par secteur NACE, classe de taille et géographie.
Les données incluent le nombre d''entreprises actives, les créations et cessations d''activité.
Une distinction est faite entre les entreprises nationales et étrangères.';

COMMENT ON COLUMN dw.fact_vat_nace_employment.id_fact_nace IS 
'Identifiant technique unique de l''enregistrement';

COMMENT ON COLUMN dw.fact_vat_nace_employment.id_date IS 
'Référence vers la dimension temporelle (dim_date)';

COMMENT ON COLUMN dw.fact_vat_nace_employment.id_geography IS 
'Référence vers la dimension géographique (dim_geography)';

COMMENT ON COLUMN dw.fact_vat_nace_employment.cd_economic_activity IS 
'Code de l''activité économique selon la nomenclature NACE (dim_economic_activity)';

COMMENT ON COLUMN dw.fact_vat_nace_employment.cd_size_class IS 
'Classe de taille de l''entreprise (dim_entreprise_size_employees)';

COMMENT ON COLUMN dw.fact_vat_nace_employment.ms_num_entreprises IS 
'Nombre total d''entreprises actives';

COMMENT ON COLUMN dw.fact_vat_nace_employment.ms_num_starts IS 
'Nombre d''entreprises créées dans la période';

COMMENT ON COLUMN dw.fact_vat_nace_employment.ms_num_stops IS 
'Nombre d''entreprises ayant cessé leur activité dans la période';

COMMENT ON COLUMN dw.fact_vat_nace_employment.ms_net_creation IS 
'Création nette d''entreprises (créations - cessations)';

COMMENT ON COLUMN dw.fact_vat_nace_employment.fl_foreign IS 
'Indique si l''entreprise est étrangère';

COMMENT ON COLUMN dw.fact_vat_nace_employment.cd_nace_level IS 
'Niveau dans la hiérarchie NACE (1: Section, 2: Division, 3: Groupe, 4: Classe, 5: Sous-classe)';

COMMENT ON COLUMN dw.fact_vat_nace_employment.id_batch IS 
'Identifiant du batch de chargement';

COMMENT ON COLUMN dw.fact_vat_nace_employment.cd_year IS
'Année de référence des données, permet des requêtes directes sans jointure avec dim_date';

-- Log du succès
SELECT utils.log_script_execution('create_fact_vat_nace_employment.sql', 'SUCCESS');

