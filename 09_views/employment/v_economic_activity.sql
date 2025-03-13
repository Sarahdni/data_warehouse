-- 04_views/employment/v_economic_activity.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_economic_activity_views.sql', 'RUNNING');

-- Vue récursive pour la navigation hiérarchique
CREATE OR REPLACE VIEW dw.v_economic_activity_hierarchy AS
WITH RECURSIVE hierarchy AS (
    -- Niveau racine (sections)
    SELECT 
        id_economic_activity,
        cd_economic_activity,
        cd_level,
        tx_economic_activity_fr,
        tx_economic_activity_nl,
        tx_economic_activity_de,
        tx_economic_activity_en,
        ARRAY[cd_economic_activity]::VARCHAR[] as ancestors,
        1 as depth,
        tx_economic_activity_fr as path_fr,
        tx_economic_activity_nl as path_nl,
        tx_economic_activity_de as path_de,
        tx_economic_activity_en as path_en,
        fl_current,
        dt_valid_from,
        dt_valid_to
    FROM dw.dim_economic_activity
    WHERE cd_level = 1

    UNION ALL

    -- Niveaux suivants
    SELECT 
        n.id_economic_activity,
        n.cd_economic_activity,
        n.cd_level,
        n.tx_economic_activity_fr,
        n.tx_economic_activity_nl,
        n.tx_economic_activity_de,
        n.tx_economic_activity_en,
        (h.ancestors || n.cd_economic_activity::VARCHAR)::VARCHAR[] as ancestors,
        h.depth + 1,
        h.path_fr || ' > ' || n.tx_economic_activity_fr,
        h.path_nl || ' > ' || n.tx_economic_activity_nl,
        h.path_de || ' > ' || n.tx_economic_activity_de,
        h.path_en || ' > ' || n.tx_economic_activity_en,
        n.fl_current,
        n.dt_valid_from,
        n.dt_valid_to
    FROM dw.dim_economic_activity n
    JOIN hierarchy h ON n.cd_parent_activity = h.cd_economic_activity
    WHERE n.cd_level > 1
)
SELECT * FROM hierarchy;

-- Vue pour les activités courantes par niveau
CREATE OR REPLACE VIEW dw.v_economic_activity_by_level AS
SELECT 
    cd_level,
    COUNT(*) as nb_activities,
    MIN(cd_economic_activity) as first_code,
    MAX(cd_economic_activity) as last_code
FROM dw.dim_economic_activity
WHERE fl_current = TRUE
GROUP BY cd_level
ORDER BY cd_level;

-- Vue pour les activités courantes uniquement
CREATE OR REPLACE VIEW dw.v_economic_activity_current AS
SELECT
    cd_economic_activity,
    cd_parent_activity,
    cd_level,
    tx_economic_activity_fr,
    tx_economic_activity_nl,
    tx_economic_activity_de,
    tx_economic_activity_en,
    dt_valid_from,
    dt_valid_to
FROM dw.dim_economic_activity
WHERE fl_current = TRUE;

-- 04_views/metadata/v_missing_translations.sql
CREATE OR REPLACE VIEW metadata.v_missing_translations AS
SELECT 
    mt.id_batch,
    mt.cd_nacebel,
    mt.tx_original_fr,
    mt.missing_languages,
    mt.fl_processed,
    mt.dt_created,
    mt.dt_processed,
    sfh.tx_filename AS source_filename,
    sfh.dt_processed AS batch_processed_date
FROM metadata.missing_translations mt
JOIN metadata.source_file_history sfh ON mt.id_batch = sfh.id_file_history
ORDER BY mt.dt_created DESC;

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (nm_schema, nm_table, tx_description, cd_source)
VALUES 
    ('dw', 'v_economic_activity_hierarchy', 'Vue hiérarchique complète des activités économiques', 'SYSTEM'),
    ('dw', 'v_economic_activity_by_level', 'Vue des statistiques par niveau hiérarchique', 'SYSTEM'),
    ('dw', 'v_economic_activity_current', 'Vue des activités économiques courantes', 'SYSTEM'),
    ('metadata', 'v_missing_translations', 'Vue de suivi des traductions manquantes', 'SYSTEM')
ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON VIEW dw.v_economic_activity_hierarchy IS 'Vue récursive permettant de naviguer dans la hiérarchie NACE-BEL avec chemins complets multilingues';
COMMENT ON VIEW dw.v_economic_activity_by_level IS 'Statistiques sur le nombre d''activités par niveau hiérarchique';
COMMENT ON VIEW dw.v_economic_activity_current IS 'Vue des activités économiques actuellement valides';
COMMENT ON VIEW metadata.v_missing_translations IS 'Vue de suivi des traductions manquantes avec informations sur le fichier source';

-- Log du succès
SELECT utils.log_script_execution('create_economic_activity_views.sql', 'SUCCESS');