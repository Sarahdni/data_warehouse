 -- 04_views/real_estate/v_residential_building.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_v_residential_building.sql', 'RUNNING');

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
    cd_source,
    fl_view
) VALUES (
    'dw',
    'v_residential_building',
    'Vue ordonnée des types de biens résidentiels actifs',
    'SYSTEM',
    TRUE
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON VIEW dw.v_residential_building IS 'Vue ordonnée des types de biens résidentiels actuellement valides';
COMMENT ON COLUMN dw.v_residential_building.cd_residential_type IS 'Code unique du type de bien';
COMMENT ON COLUMN dw.v_residential_building.tx_residential_type_fr IS 'Description en français';
COMMENT ON COLUMN dw.v_residential_building.tx_residential_type_nl IS 'Description en néerlandais';
COMMENT ON COLUMN dw.v_residential_building.tx_residential_type_de IS 'Description en allemand';
COMMENT ON COLUMN dw.v_residential_building.tx_residential_type_en IS 'Description en anglais';
COMMENT ON COLUMN dw.v_residential_building.nb_display_order IS 'Ordre d''affichage standardisé';

-- Log du succès
SELECT utils.log_script_execution('create_v_residential_building.sql', 'SUCCESS');