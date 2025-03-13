-- 04_fact_tables/real_estate/procedures/load_fact_building_stock.sql

CREATE OR REPLACE PROCEDURE dw.load_fact_building_stock(
    p_batch_id INTEGER,
    p_delete_existing BOOLEAN DEFAULT FALSE,
    p_debug BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_count INTEGER := 0;
    v_error_count INTEGER := 0;
    v_non_collected_count INTEGER := 0;
    v_start_time TIMESTAMP;
    v_source_id INTEGER;
    v_year VARCHAR;
    r_stats RECORD;
BEGIN
    -- Enregistrer le début de l'exécution
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Log du début
    PERFORM utils.log_script_execution('load_fact_building_stock', 'RUNNING');

    -- Récupérer l'année du batch
    SELECT DISTINCT CD_YEAR INTO v_year 
    FROM raw_staging.raw_building_stock 
    WHERE id_batch = p_batch_id;

    -- Récupérer l'ID de la source
    SELECT id_source INTO v_source_id 
    FROM metadata.dim_source 
    WHERE cd_source = 'BUILDING_STOCK';

    -- Créer une table temporaire pour les statistiques non collectées
    CREATE TEMP TABLE tmp_non_collected_stats (
        cd_year VARCHAR,
        cd_building_type VARCHAR,
        cd_stat_type VARCHAR,
        reason VARCHAR
    );

    -- Identifier les statistiques non collectées pour cette année
    INSERT INTO tmp_non_collected_stats
    SELECT 
        CD_YEAR,
        CD_BUILDING_TYPE,
        CD_STAT_TYPE,
        CASE 
            WHEN CD_STAT_TYPE IN ('T3.7.1', 'T3.7.2', 'T3.7.3', 'T3.7.4', 'T3.9') 
                THEN 'Statistique non collectée en ' || CD_YEAR
            WHEN CD_BUILDING_TYPE = 'R4' AND CD_STAT_TYPE LIKE 'T4%' 
                THEN 'Statistique non collectée pour les buildings et immeubles à appartements en ' || CD_YEAR
            WHEN CD_BUILDING_TYPE = 'R6' AND CD_STAT_TYPE IN ('T4.1', 'T4.2', 'T4.3', 'T4.4', 'T5', 'T6.1', 'T6.2', 'T7.1', 'T7.2')
                THEN 'Statistique non collectée pour les autres bâtiments en ' || CD_YEAR
            ELSE 'Donnée manquante - Raison indéterminée'
        END as reason
    FROM raw_staging.raw_building_stock s
    WHERE s.id_batch = p_batch_id
    AND MS_VALUE IS NULL;

    GET DIAGNOSTICS v_non_collected_count = ROW_COUNT;

    -- Créer la table des données valides
    CREATE TEMP TABLE tmp_valid_data AS
    SELECT 
        CD_YEAR,
        CASE 
            WHEN length(CD_REFNIS) = 4 THEN '0' || CD_REFNIS
            ELSE CD_REFNIS
        END as CD_REFNIS,
        CD_BUILDING_TYPE,
        CD_STAT_TYPE,
        COALESCE(MS_VALUE, 0) as MS_VALUE,
        id_batch
    FROM raw_staging.raw_building_stock s
    WHERE s.id_batch = p_batch_id
    AND MS_VALUE IS NOT NULL;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    -- Mode debug amélioré
    IF p_debug THEN
        RAISE NOTICE E'\n=== Statistiques de chargement pour l''année % ===', v_year;
        RAISE NOTICE 'Total des lignes traitées: %', v_count + v_non_collected_count;
        RAISE NOTICE 'Statistiques non collectées: %', v_non_collected_count;
        
        -- Distribution des statistiques non collectées
        RAISE NOTICE E'\n=== Détail des statistiques non collectées ===';
        FOR r_stats IN 
            SELECT reason, COUNT(*) as total,
                   ROUND(COUNT(*)::numeric / v_non_collected_count * 100, 2) as percentage
            FROM tmp_non_collected_stats
            GROUP BY reason
            ORDER BY total DESC
        LOOP
            RAISE NOTICE '- %: % lignes (%.2f%%)', 
                r_stats.reason, 
                r_stats.total,
                r_stats.percentage;
        END LOOP;
    END IF;

    -- Supprimer les données existantes si demandé
    IF p_delete_existing THEN
        DELETE FROM dw.fact_building_stock WHERE id_batch = p_batch_id;
    END IF;

    -- Insérer les nouvelles données
    INSERT INTO dw.fact_building_stock (
        id_date,
        id_geography,
        cd_building_type,
        cd_statistic_type,
        ms_building_count,
        id_batch
    )
    SELECT 
        d.id_date,
        g.id_geography,
        t.CD_BUILDING_TYPE,
        t.CD_STAT_TYPE,
        t.MS_VALUE::INTEGER,
        p_batch_id
    FROM tmp_valid_data t
    JOIN dw.dim_date d ON d.cd_year = t.CD_YEAR 
        AND d.cd_period_type = 'Y'
    JOIN dw.dim_geography g ON g.cd_refnis = t.CD_REFNIS
    ON CONFLICT (id_date, id_geography, cd_building_type, cd_statistic_type) 
    DO UPDATE SET
        ms_building_count = EXCLUDED.ms_building_count,
        dt_updated = CURRENT_TIMESTAMP,
        id_batch = EXCLUDED.id_batch;

    -- Log dans transformation_tracking avec informations améliorées
    INSERT INTO metadata.transformation_tracking (
        id_source, 
        nm_table_source, 
        nm_schema_source,
        nm_table_target, 
        nm_schema_target,
        nb_rows_source, 
        nb_rows_target, 
        nb_rows_rejected,
        tx_transformation_type, 
        dt_start, 
        dt_end,
        cd_status, 
        tx_transformation_rules, 
        id_batch
    ) VALUES (
        v_source_id,
        'raw_building_stock', 
        'raw_staging',
        'fact_building_stock', 
        'dw',
        v_count + v_non_collected_count, 
        v_count, 
        v_non_collected_count,
        'CLEAN_TO_DW',
        v_start_time, 
        CURRENT_TIMESTAMP,
        'SUCCESS',
        format('Année: %s, Stats non collectées: %s, Debug=%s', 
               v_year, v_non_collected_count, p_debug),
        p_batch_id
    );

    -- Nettoyage
    DROP TABLE tmp_non_collected_stats;
    DROP TABLE tmp_valid_data;

    -- Log du succès avec message amélioré
    PERFORM utils.log_script_execution(
        'load_fact_building_stock', 
        'SUCCESS',
        format('Chargement année %s terminé. %s lignes chargées, %s statistiques non collectées sur un total de %s lignes. Durée: %s minutes', 
            v_year,
            v_count, 
            v_non_collected_count,
            v_count + v_non_collected_count,
            EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_start_time))/60)
    );

EXCEPTION WHEN OTHERS THEN
    -- Nettoyage en cas d'erreur
    DROP TABLE IF EXISTS tmp_non_collected_stats;
    DROP TABLE IF EXISTS tmp_valid_data;
    
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'load_fact_building_stock', 
        'ERROR',
        format('Erreur sur année %s: %s. Durée: %s minutes', 
            v_year,
            SQLERRM,
            EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_start_time))/60)
    );
    RAISE;
END;
$$;

COMMENT ON PROCEDURE dw.load_fact_building_stock IS 
'Procédure de chargement des données du parc immobilier avec gestion des statistiques non collectées.

Caractéristiques :
- Identification des statistiques non collectées par année
- Logging détaillé avec raisons spécifiques
- Mode debug pour analyser la distribution des données manquantes
- Traçabilité complète dans transformation_tracking

Arguments :
- p_batch_id : ID du batch à charger
- p_delete_existing : Si TRUE, supprime les données existantes du batch
- p_debug : Si TRUE, affiche les statistiques détaillées

Exemple avec debug :
CALL dw.load_fact_building_stock(123, TRUE, TRUE);';