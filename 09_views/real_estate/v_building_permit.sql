 -- 04_views/real_estate/v_building_permit.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_v_building_permit.sql', 'RUNNING');

-- Vue des permis de construire actuellement valides
CREATE OR REPLACE VIEW dw.v_building_permit AS
SELECT 
    id_permit_type,
    cd_permit_class,
    cd_permit_action,
    cd_measure_type,
    tx_measure_unit,
    tx_descr_fr,
    tx_descr_nl,
    tx_descr_de,
    tx_descr_en
FROM dw.dim_building_permit
WHERE fl_current = TRUE
ORDER BY 
    cd_permit_class,
    cd_permit_action,
    cd_measure_type;

COMMENT ON VIEW dw.v_building_permit IS 
'Vue des types de permis de construire actuellement valides';

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'v_building_permit',
    'Vue des types de permis de construire actifs',
    'SYSTEM'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Log du succès
SELECT utils.log_script_execution('create_v_building_permit.sql', 'SUCCESS');