-- 02_dim_tables/real_estate/dim_building_statistics.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_dim_building_statistics.sql', 'RUNNING');

-- Création de la fonction trigger
CREATE OR REPLACE FUNCTION dw.update_building_statistics_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création de la table
CREATE TABLE IF NOT EXISTS dw.DIM_BUILDING_STATISTICS (
    -- Clés et identifiants
    cd_statistic_type VARCHAR(10) PRIMARY KEY,    
    cd_statistic_category VARCHAR(50) NOT NULL,    
    
    -- Libellés multilingues
    tx_statistic_type_fr VARCHAR(200) NOT NULL,
    tx_statistic_type_nl VARCHAR(200) NOT NULL,
    tx_statistic_type_de VARCHAR(200) NOT NULL,
    tx_statistic_type_en VARCHAR(200) NOT NULL,
    
    -- Attributs spécifiques
    nb_min_value DECIMAL,                        
    nb_max_value DECIMAL,                        
    tx_unit VARCHAR(10),                         
    
    -- Gestion des versions (SCD Type 2)
    dt_valid_from DATE NOT NULL,
    dt_valid_to DATE,
    
    -- Traçabilité
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT chk_stat_type_categories CHECK (
        cd_statistic_category IN (
            'TOTAL',              
            'SURFACE',            
            'GARAGE',             
            'BATHROOM',           
            'CONSTRUCTION_PERIOD',
            'EQUIPMENT',          
            'DWELLING'            
        )
    ),
    CONSTRAINT chk_dates CHECK (
        dt_valid_from <= dt_valid_to OR dt_valid_to IS NULL
    )
);

-- Création des index
CREATE INDEX IF NOT EXISTS idx_building_stats_category 
ON dw.DIM_BUILDING_STATISTICS(cd_statistic_category);

CREATE INDEX IF NOT EXISTS idx_building_stats_dates 
ON dw.DIM_BUILDING_STATISTICS(dt_valid_from, dt_valid_to);

-- Création du trigger
DROP TRIGGER IF EXISTS tr_update_building_statistics_timestamp ON dw.DIM_BUILDING_STATISTICS;
CREATE TRIGGER tr_update_building_statistics_timestamp
    BEFORE UPDATE ON dw.DIM_BUILDING_STATISTICS
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_building_statistics_timestamp();

-- Insertion des données (reprises de l'existant)
INSERT INTO dw.DIM_BUILDING_STATISTICS (
    cd_statistic_type, 
    cd_statistic_category,
    tx_statistic_type_fr,
    tx_statistic_type_nl,
    tx_statistic_type_de,
    tx_statistic_type_en,
    nb_min_value,
    nb_max_value,
    tx_unit,
    dt_valid_from
) VALUES
    -- Total
    ('T1', 'TOTAL',
     'Nombre de bâtiments',
     'Aantal gebouwen',
     'Anzahl der Gebäude',
     'Number of buildings',
     NULL, NULL, NULL,
     '2000-01-01'),

    -- Surface au sol
    ('T3.1', 'SURFACE',
     'Nombre de bâtiments ayant une superficie bâtie au sol inférieure à 45 m²',
     'Aantal gebouwen met bebouwde grondoppervlakte kleiner dan 45 m²',
     'Anzahl der Gebäude mit bebauter Grundfläche unter 45 m²',
     'Number of buildings with built-up ground area less than 45 m²',
     0, 45, 'm²',
     '2000-01-01'),

    ('T3.2', 'SURFACE',
     'Nombre de bâtiments ayant une superficie bâtie au sol de 45 à 64 m²',
     'Aantal gebouwen met bebouwde grondoppervlakte van 45 m² tot 64 m²',
     'Anzahl der Gebäude mit bebauter Grundfläche von 45 bis 64 m²',
     'Number of buildings with built-up ground area from 45 to 64 m²',
     45, 64, 'm²',
     '2000-01-01'),

    ('T3.3', 'SURFACE',
     'Nombre de bâtiments ayant une superficie bâtie au sol de 65 à 104 m²',
     'Aantal gebouwen met bebouwde grondoppervlakte van 65 m² tot 104 m²',
     'Anzahl der Gebäude mit bebauter Grundfläche von 65 bis 104 m²',
     'Number of buildings with built-up ground area from 65 to 104 m²',
     65, 104, 'm²',
     '2000-01-01'),

    ('T3.4', 'SURFACE',
     'Nombre de bâtiments ayant une superficie bâtie au sol supérieure à 104 m²',
     'Aantal gebouwen met bebouwde grondoppervlakte groter dan 104 m²',
     'Anzahl der Gebäude mit bebauter Grundfläche über 104 m²',
     'Number of buildings with built-up ground area greater than 104 m²',
     104, NULL, 'm²',
     '2000-01-01'),

    -- Garage
    ('T3.5', 'GARAGE',
     'Nombre de bâtiments comportant au moins un garage, parking ou emplacement couvert',
     'Aantal gebouwen met garage, parking of overdekte staanplaats',
     'Anzahl der Gebäude mit Garage, Parkplatz oder überdachtem Stellplatz',
     'Number of buildings with garage, parking or covered space',
     NULL, NULL, NULL,
     '2000-01-01'),

    -- Salle de bain
    ('T3.6', 'BATHROOM',
     'Nombre de bâtiments comportant au moins une salle de bains',
     'Aantal gebouwen met badkamer',
     'Anzahl der Gebäude mit Badezimmer',
     'Number of buildings with bathroom',
     NULL, NULL, NULL,
     '2000-01-01'),

    -- Périodes de construction
    ('T3.7', 'CONSTRUCTION_PERIOD',
     'Nombre de bâtiments érigés après 1981',
     'Aantal gebouwen opgericht na 1981',
     'Anzahl der nach 1981 errichteten Gebäude',       
     'Number of buildings built after 1981', 
     1981, NULL, 'année',          
     '2000-01-01'),

    ('T3.7.1', 'CONSTRUCTION_PERIOD',
     'Nombre de bâtiments érigés avant 1900',
     'Aantal gebouwen opgericht voor 1900',
     'Anzahl der vor 1900 errichteten Gebäude',
     'Number of buildings built before 1900',
     0, 1900, 'année',
     '2000-01-01'),

    ('T3.7.2', 'CONSTRUCTION_PERIOD',
     'Nombre de bâtiments érigés de 1900 à 1918',
     'Aantal gebouwen opgericht van 1900 tot 1918',
     'Anzahl der von 1900 bis 1918 errichteten Gebäude',
     'Number of buildings built from 1900 to 1918',
     1900, 1918, 'année',
     '2000-01-01'),

    ('T3.7.3', 'CONSTRUCTION_PERIOD',
     'Nombre de bâtiments érigés de 1919 à 1945',
     'Aantal gebouwen opgericht van 1919 tot 1945',
     'Anzahl der von 1919 bis 1945 errichteten Gebäude',
     'Number of buildings built from 1919 to 1945',
     1919, 1945, 'année',
     '2000-01-01'),

    ('T3.7.4', 'CONSTRUCTION_PERIOD',
     'Nombre de bâtiments érigés de 1946 à 1961',
     'Aantal gebouwen opgericht van 1946 tot 1961',
     'Anzahl der von 1946 bis 1961 errichteten Gebäude',
     'Number of buildings built from 1946 to 1961',
     1946, 1961, 'année',
     '2000-01-01'),

     ('T3.9', 'CONSTRUCTION_PERIOD',
     'Nombre de bâtiments pour lesquels l''année d''achèvement de la construction n''est pas disponible',
     'Aantal gebouwen waarvoor het jaar van beëindiging van de contructie niet beschikbaar is',
     'Anzahl der Gebäude, bei denen das Baujahr nicht verfügbar ist',   
     'Number of buildings for which the year of construction completion is not available',
     NULL, NULL, NULL,  
     '2000-01-01'),

    ('T4.1', 'CONSTRUCTION_PERIOD',
     'Nombre de bâtiments érigés de 1962 à 1970',
     'Aantal gebouwen opgericht van 1962 tot 1970',
     'Anzahl der von 1962 bis 1970 errichteten Gebäude',
     'Number of buildings built from 1962 to 1970',
     1962, 1970, 'année',
     '2000-01-01'),

    ('T4.2', 'CONSTRUCTION_PERIOD',
     'Nombre de bâtiments érigés de 1971 à 1981',
     'Aantal gebouwen opgericht van 1971 tot 1981',
     'Anzahl der von 1971 bis 1981 errichteten Gebäude',
     'Number of buildings built from 1971 to 1981',
     1971, 1981, 'année',
     '2000-01-01'),

    ('T4.3', 'CONSTRUCTION_PERIOD',
     'Nombre de bâtiments érigés de 1982 à 1991',
     'Aantal gebouwen opgericht van 1982 tot 1991',
     'Anzahl der von 1982 bis 1991 errichteten Gebäude',
     'Number of buildings built from 1982 to 1991',
     1982, 1991, 'année',
     '2000-01-01'),

    ('T4.4', 'CONSTRUCTION_PERIOD',
     'Nombre de bâtiments érigés de 1992 à 2001',
     'Aantal gebouwen opgericht van 1992 tot 2001',
     'Anzahl der von 1992 bis 2001 errichteten Gebäude',
     'Number of buildings built from 1992 to 2001',
     1992, 2001, 'année',
     '2000-01-01'),

    ('T5', 'CONSTRUCTION_PERIOD',
     'Nombre de bâtiments érigés de 2002 à 2011',
     'Aantal gebouwen opgericht van 2002 tot 2011',
     'Anzahl der von 2002 bis 2011 errichteten Gebäude',
     'Number of buildings built from 2002 to 2011',
     2002, 2011, 'année',
     '2000-01-01'),

    ('T6.1', 'CONSTRUCTION_PERIOD',
     'Nombre de bâtiments érigés après 1981',
     'Aantal gebouwen opgericht na 1981',
     'Anzahl der nach 1981 errichteten Gebäude',
     'Number of buildings built after 1981',
     1981, NULL, 'année',
     '2000-01-01'),

    ('T6.2', 'CONSTRUCTION_PERIOD',
     'Nombre de bâtiments érigés après 2011',
     'Aantal gebouwen opgericht na 2011',
     'Anzahl der nach 2011 errichteten Gebäude',
     'Number of buildings built after 2011',
     2011, NULL, 'année',
     '2000-01-01'),

    ('T7.1', 'CONSTRUCTION_PERIOD',
     'Nombre de bâtiments pour lesquels l''année d''achèvement de la construction n''est pas disponible',
     'Aantal gebouwen waarvoor het jaar van beëindiging van de contructie niet beschikbaar is',
     'Anzahl der Gebäude, für die das Baujahr nicht verfügbar ist',
     'Number of buildings for which the year of construction completion is not available',
     NULL, NULL, NULL,
     '2000-01-01'),

    -- Équipements
    ('T7.2', 'EQUIPMENT',
     'Nombre de bâtiments équipés de chauffage central ou de conditionnement d''air',
     'Aantal gebouwen uitgerust met centrale verwarming of airconditioning',
     'Anzahl der Gebäude mit Zentralheizung oder Klimaanlage',
     'Number of buildings equipped with central heating or air conditioning',
     NULL, NULL, NULL,
     '2000-01-01'),

    -- Logements
    ('T8', 'DWELLING',
     'Nombre de logements',
     'Aantal woongelegenheden',
     'Anzahl der Wohneinheiten',
     'Number of dwelling units',
     NULL, NULL, NULL,
     '2000-01-01')


ON CONFLICT (cd_statistic_type) DO UPDATE SET
    cd_statistic_category = EXCLUDED.cd_statistic_category,
    tx_statistic_type_fr = EXCLUDED.tx_statistic_type_fr,
    tx_statistic_type_nl = EXCLUDED.tx_statistic_type_nl,
    tx_statistic_type_de = EXCLUDED.tx_statistic_type_de,
    tx_statistic_type_en = EXCLUDED.tx_statistic_type_en,
    nb_min_value = EXCLUDED.nb_min_value,
    nb_max_value = EXCLUDED.nb_max_value,
    tx_unit = EXCLUDED.tx_unit,
    dt_updated = CURRENT_TIMESTAMP;

-- Enregistrement dans le registre
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'DIM_BUILDING_STATISTICS',
    'Dimension des statistiques de bâtiments',
    'SYSTEM'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE dw.DIM_BUILDING_STATISTICS IS 'Dimension regroupant tous les types de statistiques liées aux bâtiments';
COMMENT ON COLUMN dw.DIM_BUILDING_STATISTICS.cd_statistic_type IS 'Code unique identifiant le type de statistique';
COMMENT ON COLUMN dw.DIM_BUILDING_STATISTICS.cd_statistic_category IS 'Catégorie principale de la statistique';
COMMENT ON COLUMN dw.DIM_BUILDING_STATISTICS.nb_min_value IS 'Valeur minimale pour les statistiques numériques';
COMMENT ON COLUMN dw.DIM_BUILDING_STATISTICS.nb_max_value IS 'Valeur maximale pour les statistiques numériques';
COMMENT ON COLUMN dw.DIM_BUILDING_STATISTICS.tx_unit IS 'Unité de mesure';
COMMENT ON COLUMN dw.DIM_BUILDING_STATISTICS.dt_valid_from IS 'Date de début de validité';
COMMENT ON COLUMN dw.DIM_BUILDING_STATISTICS.dt_valid_to IS 'Date de fin de validité';

-- Log du succès
SELECT utils.log_script_execution('create_dim_building_statistics.sql', 'SUCCESS');     