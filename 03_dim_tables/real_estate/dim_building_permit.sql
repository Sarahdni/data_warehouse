-- 02_dim_tables/real_estate/dim_building_permit.sql


-- Log du début d'exécution
SELECT utils.log_script_execution('create_dim_building_permit.sql', 'RUNNING');

-- Création de la fonction trigger
CREATE OR REPLACE FUNCTION dw.update_building_permit_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création de la table dimensionnelle

CREATE TABLE IF NOT EXISTS dw.dim_building_permit (
    -- Clés et identifiants
    id_permit_type SERIAL PRIMARY KEY,
    cd_permit_class VARCHAR(20) NOT NULL,         -- RES ou NONRES
    cd_permit_action VARCHAR(20) NOT NULL,        -- NEW ou RENOVATION
    cd_measure_type VARCHAR(20) NOT NULL,         -- BUILDING, DWELLING, etc.
    tx_measure_unit VARCHAR(10) NOT NULL,         -- COUNT, M2, M3
    
    -- Libellés multilingues
    tx_descr_fr VARCHAR(255) NOT NULL,
    tx_descr_nl VARCHAR(255) NOT NULL,
    tx_descr_de VARCHAR(255) NOT NULL,
    tx_descr_en VARCHAR(255) NOT NULL,
    
    -- Gestion SCD Type 2
    dt_start DATE NOT NULL DEFAULT CURRENT_DATE,
    dt_end DATE,
    fl_current BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Traçabilité
    id_batch INTEGER,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT chk_permit_class 
        CHECK (cd_permit_class IN ('RES', 'NONRES')),
    
    CONSTRAINT chk_permit_action 
        CHECK (cd_permit_action IN ('NEW', 'RENOVATION')),
    
    CONSTRAINT chk_measure_type 
        CHECK (cd_measure_type IN (
            'BUILDING', 'DWELLING', 'APARTMENT', 
            'SINGLE_HOUSE', 'TOTAL_SURFACE', 'VOLUME'
        )),
    
    CONSTRAINT chk_measure_unit 
        CHECK (tx_measure_unit IN ('COUNT', 'M2', 'M3')),
    
    CONSTRAINT chk_measure_coherence 
        CHECK (
            (cd_measure_type IN ('BUILDING', 'DWELLING', 'APARTMENT', 'SINGLE_HOUSE') 
             AND tx_measure_unit = 'COUNT')
            OR
            (cd_measure_type = 'TOTAL_SURFACE' AND tx_measure_unit = 'M2')
            OR
            (cd_measure_type = 'VOLUME' AND tx_measure_unit = 'M3')
        ),
    
    CONSTRAINT chk_dates 
        CHECK (dt_start <= COALESCE(dt_end, '9999-12-31'::date))
);

-- Index pour optimiser les recherches
CREATE INDEX IF NOT EXISTS idx_building_permit_current 
    ON dw.dim_building_permit(fl_current);
    
CREATE INDEX IF NOT EXISTS idx_building_permit_dates 
    ON dw.dim_building_permit(dt_start, dt_end);
    
CREATE INDEX IF NOT EXISTS idx_building_permit_type 
    ON dw.dim_building_permit(cd_permit_class, cd_permit_action, cd_measure_type);

-- Index unique sur la version courante
CREATE UNIQUE INDEX IF NOT EXISTS uk_building_permit_current 
    ON dw.dim_building_permit(cd_permit_class, cd_permit_action, cd_measure_type) 
    WHERE fl_current = TRUE;

-- Création du trigger
DROP TRIGGER IF EXISTS tr_update_building_permit_timestamp ON dw.dim_building_permit;
CREATE TRIGGER tr_update_building_permit_timestamp
    BEFORE UPDATE ON dw.dim_building_permit
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_building_permit_timestamp();

-- Insertion des données de référence
INSERT INTO dw.dim_building_permit (
    cd_permit_class,
    cd_permit_action,
    cd_measure_type,
    tx_measure_unit,
    tx_descr_fr,
    tx_descr_nl,
    tx_descr_de,
    tx_descr_en
) VALUES
    ('RES', 'NEW', 'BUILDING', 'COUNT',
     'Nombre de nouveaux bâtiments résidentiels',
     'Aantal nieuwe residentiële gebouwen',
     'Anzahl neuer Wohngebäude',
     'Number of new residential buildings'),
     
    ('RES', 'NEW', 'DWELLING', 'COUNT',
     'Nombre de nouveaux logements',
     'Aantal nieuwe woningen',
     'Anzahl neuer Wohnungen',
     'Number of new dwellings'),
     
    ('RES', 'NEW', 'APARTMENT', 'COUNT',
     'Nombre de nouveaux appartements',
     'Aantal nieuwe appartementen',
     'Anzahl neuer Apartments',
     'Number of new apartments'),
     
    ('RES', 'NEW', 'SINGLE_HOUSE', 'COUNT',
     'Nombre de nouvelles maisons unifamiliales',
     'Aantal nieuwe eengezinswoningen',
     'Anzahl neuer Einfamilienhäuser',
     'Number of new single-family houses'),
     
    ('RES', 'NEW', 'TOTAL_SURFACE', 'M2',
     'Surface totale des nouveaux bâtiments résidentiels',
     'Totale oppervlakte van nieuwe residentiële gebouwen',
     'Gesamtfläche der neuen Wohngebäude',
     'Total surface area of new residential buildings'),
     
    ('RES', 'RENOVATION', 'BUILDING', 'COUNT',
     'Nombre de bâtiments résidentiels rénovés',
     'Aantal gerenoveerde residentiële gebouwen',
     'Anzahl renovierter Wohngebäude',
     'Number of renovated residential buildings'),
     
    ('NONRES', 'NEW', 'BUILDING', 'COUNT',
     'Nombre de nouveaux bâtiments non résidentiels',
     'Aantal nieuwe niet-residentiële gebouwen',
     'Anzahl neuer Nichtwohngebäude',
     'Number of new non-residential buildings'),
     
    ('NONRES', 'NEW', 'VOLUME', 'M3',
     'Volume total des nouveaux bâtiments non résidentiels',
     'Totaal volume van nieuwe niet-residentiële gebouwen',
     'Gesamtvolumen der neuen Nichtwohngebäude',
     'Total volume of new non-residential buildings'),
     
    ('NONRES', 'RENOVATION', 'BUILDING', 'COUNT',
     'Nombre de bâtiments non résidentiels rénovés',
     'Aantal gerenoveerde niet-residentiële gebouwen',
     'Anzahl renovierter Nichtwohngebäude',
     'Number of renovated non-residential buildings')
ON CONFLICT (cd_permit_class, cd_permit_action, cd_measure_type) 
WHERE fl_current = TRUE 
DO NOTHING;

-- Commentaires
COMMENT ON TABLE dw.dim_building_permit IS 
    'Dimension des types de permis de construire avec gestion des versions (SCD Type 2)';

COMMENT ON COLUMN dw.dim_building_permit.id_permit_type IS 
    'Identifiant technique unique du type de permis';
COMMENT ON COLUMN dw.dim_building_permit.cd_permit_class IS 
    'Classe de permis (RES=résidentiel, NONRES=non résidentiel)';
COMMENT ON COLUMN dw.dim_building_permit.cd_permit_action IS 
    'Type d''action (NEW=nouvelle construction, RENOVATION=rénovation)';
COMMENT ON COLUMN dw.dim_building_permit.cd_measure_type IS 
    'Type de mesure (BUILDING, DWELLING, APARTMENT, etc.)';
COMMENT ON COLUMN dw.dim_building_permit.tx_measure_unit IS 
    'Unité de mesure (COUNT=nombre, M2=mètres carrés, M3=mètres cubes)';
COMMENT ON COLUMN dw.dim_building_permit.dt_start IS 
    'Date de début de validité de la version';
COMMENT ON COLUMN dw.dim_building_permit.dt_end IS 
    'Date de fin de validité de la version';
COMMENT ON COLUMN dw.dim_building_permit.fl_current IS 
    'Indicateur de version courante';

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'dim_building_permit',
    'Dimension des types de permis de construire',
    'SYSTEM'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Log du succès
SELECT utils.log_script_execution('create_dim_building_permit.sql', 'SUCCESS');