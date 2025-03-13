-- 02_dim_tables/real_estate/dim_residential_building.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_dim_residential_building.sql', 'RUNNING');

-- Création de la fonction trigger
CREATE OR REPLACE FUNCTION dw.update_residential_building_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création de la table
CREATE TABLE IF NOT EXISTS dw.dim_residential_building (
    -- Clés et identifiants
    cd_residential_type VARCHAR(4) PRIMARY KEY,
    nb_display_order INTEGER NOT NULL,  -- Ordre d'affichage standardisé
    
    -- Libellés multilingues
    tx_residential_type_fr VARCHAR(100) NOT NULL,
    tx_residential_type_nl VARCHAR(100) NOT NULL,
    tx_residential_type_de VARCHAR(100) NOT NULL,
    tx_residential_type_en VARCHAR(100) NOT NULL,
    
    -- Gestion des versions (SCD Type 2)
    dt_valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
    dt_valid_to DATE,
    fl_current BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Traçabilité
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT chk_residential_type_format CHECK (cd_residential_type ~ '^B[0-9A]{3}$'),
    CONSTRAINT chk_dates CHECK (dt_valid_from <= COALESCE(dt_valid_to, '9999-12-31'::date)),
    CONSTRAINT chk_display_order CHECK (nb_display_order BETWEEN 1 AND 10)
);

-- Création des index
CREATE INDEX IF NOT EXISTS idx_residential_building_current 
ON dw.dim_residential_building(fl_current) 
WHERE fl_current = TRUE;

CREATE INDEX IF NOT EXISTS idx_residential_building_dates 
ON dw.dim_residential_building(dt_valid_from, dt_valid_to);

CREATE INDEX IF NOT EXISTS idx_residential_building_order
ON dw.dim_residential_building(nb_display_order);

-- Création du trigger
DROP TRIGGER IF EXISTS tr_update_residential_building_timestamp ON dw.dim_residential_building;
CREATE TRIGGER tr_update_residential_building_timestamp
    BEFORE UPDATE ON dw.dim_residential_building
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_residential_building_timestamp();

-- Insertion des données
INSERT INTO dw.dim_residential_building (
    cd_residential_type,
    nb_display_order,
    tx_residential_type_fr,
    tx_residential_type_nl,
    tx_residential_type_de,
    tx_residential_type_en
) VALUES
    ('B00A', 1, 
     'Toutes maisons',
     'Alle huizen',
     'Alle Häuser',
     'All houses'),
     
    ('B001', 2, 
     'Maisons 2 ou 3 façades',
     'Huizen met 2 of 3 gevels',
     'Häuser mit 2 oder 3 Fassaden',
     'Houses with 2 or 3 facades'),
     
    ('B002', 3, 
     'Maisons 4 façades ou plus',
     'Huizen met 4 of meer gevels',
     'Häuser mit 4 oder mehr Fassaden',
     'Houses with 4 or more facades'),
     
    ('B015', 4, 
     'Appartements',
     'Appartementen',
     'Wohnungen',
     'Apartments')
ON CONFLICT (cd_residential_type) DO UPDATE SET
    tx_residential_type_fr = EXCLUDED.tx_residential_type_fr,
    tx_residential_type_nl = EXCLUDED.tx_residential_type_nl,
    tx_residential_type_de = EXCLUDED.tx_residential_type_de,
    tx_residential_type_en = EXCLUDED.tx_residential_type_en,
    nb_display_order = EXCLUDED.nb_display_order,
    dt_updated = CURRENT_TIMESTAMP;

-- Création de la vue ordonnée
CREATE OR REPLACE VIEW dw.v_residential_building AS
SELECT 
    cd_residential_type,
    tx_residential_type_fr,
    tx_residential_type_nl,
    tx_residential_type_de,
    tx_residential_type_en,
    nb_display_order
FROM dw.dim_residential_building
WHERE fl_current = TRUE
ORDER BY nb_display_order;

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES 
    ('dw', 'dim_residential_building',
     'Dimension des types de biens résidentiels',
     'SYSTEM')
ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE dw.dim_residential_building IS 'Dimension des types de biens résidentiels pour les statistiques de prix immobiliers';

COMMENT ON COLUMN dw.dim_residential_building.cd_residential_type IS 'Code unique du type de bien (B001=maisons 2-3 façades, B002=maisons 4+ façades, B00A=toutes maisons, B015=appartements)';
COMMENT ON COLUMN dw.dim_residential_building.nb_display_order IS 'Ordre d''affichage standardisé (1=total, 2=maisons 2-3 façades, 3=maisons 4+ façades, 4=appartements)';
COMMENT ON COLUMN dw.dim_residential_building.tx_residential_type_fr IS 'Description du type de bien en français';
COMMENT ON COLUMN dw.dim_residential_building.tx_residential_type_nl IS 'Description du type de bien en néerlandais';
COMMENT ON COLUMN dw.dim_residential_building.tx_residential_type_de IS 'Description du type de bien en allemand';
COMMENT ON COLUMN dw.dim_residential_building.tx_residential_type_en IS 'Description du type de bien en anglais';
COMMENT ON COLUMN dw.dim_residential_building.dt_valid_from IS 'Date de début de validité';
COMMENT ON COLUMN dw.dim_residential_building.dt_valid_to IS 'Date de fin de validité';
COMMENT ON COLUMN dw.dim_residential_building.fl_current IS 'Indicateur de version courante';

-- Log du succès
SELECT utils.log_script_execution('create_dim_residential_building.sql', 'SUCCESS');