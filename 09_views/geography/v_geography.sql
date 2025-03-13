-- 04_views/geography/v_geography.sql

-- Log du début de l'exécution
SELECT utils.log_script_execution('create_geography_views.sql', 'RUNNING');

DO $$
BEGIN
    -- Vue principale avec la hiérarchie complète
    CREATE OR REPLACE VIEW dw.v_geography_hierarchy AS
    WITH RECURSIVE hierarchy AS (
        -- Sélection du niveau racine (niveau 1 - régions)
        SELECT 
            id_geography,
            cd_lau,
            cd_refnis,
            tx_name_fr,
            tx_name_nl,
            tx_name_de,
            tx_name_en,
            cd_level,
            cd_parent,
            ARRAY[cd_lau] as path_lau,
            ARRAY[COALESCE(tx_name_fr, '')] as path_fr,
            ARRAY[COALESCE(tx_name_nl, '')] as path_nl,
            1 as level_depth
        FROM dw.dim_geography
        WHERE cd_level = 1 
        AND fl_current = TRUE

        UNION ALL

        -- Niveaux suivants
        SELECT 
            g.id_geography,
            g.cd_lau,
            g.cd_refnis,
            g.tx_name_fr,
            g.tx_name_nl,
            g.tx_name_de,
            g.tx_name_en,
            g.cd_level,
            g.cd_parent,
            h.path_lau || g.cd_lau,
            h.path_fr || COALESCE(g.tx_name_fr, ''),
            h.path_nl || COALESCE(g.tx_name_nl, ''),
            h.level_depth + 1
        FROM dw.dim_geography g
        INNER JOIN hierarchy h ON g.cd_parent = h.cd_lau
        WHERE g.fl_current = TRUE
    )
    SELECT 
        id_geography,
        cd_lau,
        cd_refnis,
        tx_name_fr,
        tx_name_nl,
        tx_name_de,
        tx_name_en,
        cd_level,
        cd_parent,
        path_lau,
        path_fr,
        path_nl,
        level_depth,
        array_to_string(path_fr, ' > ') as full_path_fr,
        array_to_string(path_nl, ' > ') as full_path_nl
    FROM hierarchy;

    -- Vue simplifiée pour les analyses courantes
    CREATE OR REPLACE VIEW dw.v_geography AS
    SELECT 
        g.id_geography,
        g.cd_lau,
        g.cd_refnis,
        g.tx_name_fr,
        g.tx_name_nl,
        g.tx_name_de,
        g.tx_name_en,
        g.cd_level,
        p.cd_lau as cd_parent_lau,
        p.tx_name_fr as tx_parent_name_fr,
        p.tx_name_nl as tx_parent_name_nl,
        CASE g.cd_level
            WHEN 1 THEN 'Région'
            WHEN 2 THEN 'Province'
            WHEN 3 THEN 'Arrondissement'
            WHEN 4 THEN 'Commune'
            WHEN 5 THEN 'Secteur'
            ELSE 'Autre'
        END as tx_level_type_fr,
        CASE g.cd_level
            WHEN 1 THEN 'Gewest'
            WHEN 2 THEN 'Provincie'
            WHEN 3 THEN 'Arrondissement'
            WHEN 4 THEN 'Gemeente'
            WHEN 5 THEN 'Sector'
            ELSE 'Andere'
        END as tx_level_type_nl
    FROM dw.dim_geography g
    LEFT JOIN dw.dim_geography p ON g.cd_parent = p.cd_lau
    WHERE g.fl_current = TRUE
    AND (p.fl_current = TRUE OR p.fl_current IS NULL);

    -- Vue des changements historiques
    CREATE OR REPLACE VIEW dw.v_geography_history AS
    SELECT 
        g.id_geography,
        g.cd_lau,
        g.cd_refnis,
        g.tx_name_fr,
        g.tx_name_nl,
        g.cd_level,
        g.dt_start,
        g.dt_end,
        g.fl_current,
        COUNT(*) OVER (PARTITION BY g.cd_lau) as nb_versions,
        FIRST_VALUE(g.dt_start) OVER (
            PARTITION BY g.cd_lau 
            ORDER BY g.dt_start
        ) as dt_first_version,
        LAST_VALUE(g.dt_end) OVER (
            PARTITION BY g.cd_lau 
            ORDER BY g.dt_start
            RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
        ) as dt_last_version
    FROM dw.dim_geography g;

    -- Enregistrement dans le registre des vues
    INSERT INTO metadata.table_registry (
        nm_schema,
        nm_table,
        tx_description,
        cd_source,
        fl_view
    ) VALUES 
        ('dw', 'v_geography_hierarchy', 
         'Vue hiérarchique complète de la géographie', 'NUTS_LAU', TRUE),
        ('dw', 'v_geography', 
         'Vue simplifiée de la géographie courante', 'NUTS_LAU', TRUE),
        ('dw', 'v_geography_history',
         'Vue historique des changements géographiques', 'NUTS_LAU', TRUE)
    ON CONFLICT (nm_schema, nm_table) DO NOTHING;

    -- Log du succès
    PERFORM utils.log_script_execution('create_geography_views.sql', 'SUCCESS');

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution('create_geography_views.sql', 'ERROR', SQLERRM);
    RAISE;
END $$;

-- Commentaires détaillés
COMMENT ON VIEW dw.v_geography_hierarchy IS 'Vue récursive présentant la hiérarchie géographique complète avec chemins';
COMMENT ON VIEW dw.v_geography IS 'Vue simplifiée de la géographie courante avec informations sur le parent';
COMMENT ON VIEW dw.v_geography_history IS 'Vue présentant l''historique des changements géographiques';