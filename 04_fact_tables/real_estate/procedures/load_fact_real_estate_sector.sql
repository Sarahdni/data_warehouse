-- 04_fact_tables/real_estate/procedures/load_fact_real_estate_sector.sql
CREATE OR REPLACE PROCEDURE dw.load_fact_real_estate_sector(
    p_batch_id integer, 
    p_delete_existing boolean DEFAULT false
)
LANGUAGE plpgsql AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_count INTEGER;
    v_error_count INTEGER := 0;
BEGIN
    -- Enregistrer le début d'exécution
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Log du début
    PERFORM utils.log_script_execution('load_fact_real_estate_sector', 'RUNNING');

    -- Supprimer les données existantes du batch si demandé
    IF p_delete_existing THEN
        DELETE FROM dw.fact_real_estate_sector
        WHERE id_batch = p_batch_id;
    END IF;

    -- Insertion avec agrégation des données
    INSERT INTO dw.fact_real_estate_sector(
        id_date,
        id_sector_sk,
        id_geography,
        cd_residential_type,
        nb_transactions,
        ms_price_p10,
        ms_price_p25,
        ms_price_p50,
        ms_price_p75,
        ms_price_p90,
        fl_confidential,
        fl_aggregated_sectors,
        nb_aggregated_sectors,
        id_batch
    )
    
    WITH normalized_refnis AS (
        SELECT 
            c.*,
            CASE
                -- Si c'est un nouveau code utilisé avant 2019, on doit le convertir en ancien code
                WHEN c.cd_year::INTEGER < 2019 AND EXISTS (
                    SELECT 1 FROM metadata.refnis_changes_2019 rc 
                    WHERE rc.cd_refnis_post2019 = SUBSTRING(c.cd_refnis FROM 1 FOR 5)
                ) THEN (
                    SELECT rc.cd_refnis_pre2019 
                    FROM metadata.refnis_changes_2019 rc 
                    WHERE rc.cd_refnis_post2019 = SUBSTRING(c.cd_refnis FROM 1 FOR 5)
                    LIMIT 1
                )
                -- Si c'est un ancien code utilisé en/après 2019, on le convertit en nouveau code
                WHEN c.cd_year::INTEGER >= 2019 THEN 
                    COALESCE(
                        (SELECT rc.cd_refnis_post2019 
                        FROM metadata.refnis_changes_2019 rc 
                        WHERE rc.cd_refnis_pre2019 = SUBSTRING(c.cd_refnis FROM 1 FOR 5)
                        ),
                        SUBSTRING(c.cd_refnis FROM 1 FOR 5)
                    )
                -- Sinon on garde le code tel quel
                ELSE SUBSTRING(c.cd_refnis FROM 1 FOR 5)
            END as normalized_refnis
        FROM clean_staging.clean_real_estate_sector c
        WHERE c.id_batch = p_batch_id
    ),
    aggregated_data AS (
        SELECT 
            d.id_date,
            COALESCE(s.id_sector_sk, -1) as id_sector_sk,
            g.id_geography,
            c.cd_type as cd_residential_type,
            SUM(c.nb_transactions) as total_transactions,
            COUNT(*) as nb_source_records,
            NULLIF(MIN(c.ms_price_p10), 0) as ms_price_p10,
            NULLIF(MIN(c.ms_price_p25), 0) as ms_price_p25,
            NULLIF(MIN(c.ms_price_p50), 0) as ms_price_p50,
            NULLIF(MIN(c.ms_price_p75), 0) as ms_price_p75,
            NULLIF(MIN(c.ms_price_p90), 0) as ms_price_p90,
            CASE 
                WHEN SUM(c.nb_transactions) < 16 THEN TRUE 
                ELSE FALSE 
            END as fl_confidential
        FROM normalized_refnis c
        JOIN dw.dim_date d ON d.cd_year = c.cd_year::INTEGER AND d.cd_period_type = 'Y'
        LEFT JOIN dw.dim_statistical_sectors s ON s.cd_sector = c.cd_sector
            AND DATE_PART('year', s.dt_start) = c.cd_year::INTEGER
        -- Une seule jointure avec dim_geography mais sur le code normalisé
        JOIN dw.dim_geography g ON
            g.cd_refnis = c.normalized_refnis
            AND g.cd_level = '4'
            AND make_date(c.cd_year::INTEGER, 1, 1) BETWEEN g.dt_start AND g.dt_end
        GROUP BY 
            d.id_date,
            COALESCE(s.id_sector_sk, -1),
            g.id_geography,
            c.cd_type
    )
    SELECT 
        id_date,
        id_sector_sk,
        id_geography,
        cd_residential_type,
        total_transactions as nb_transactions,
        ms_price_p10,
        ms_price_p25,
        ms_price_p50,
        ms_price_p75,
        ms_price_p90,
        fl_confidential,
        CASE WHEN id_sector_sk = -1 AND nb_source_records > 1 THEN TRUE ELSE FALSE END as fl_aggregated_sectors,
        CASE WHEN id_sector_sk = -1 AND nb_source_records > 1 THEN nb_source_records ELSE NULL END as nb_aggregated_sectors,
        p_batch_id
    FROM aggregated_data
    ON CONFLICT (id_date, id_geography, id_sector_sk, cd_residential_type)
    DO UPDATE SET
        nb_transactions = EXCLUDED.nb_transactions,
        ms_price_p10 = EXCLUDED.ms_price_p10,
        ms_price_p25 = EXCLUDED.ms_price_p25,
        ms_price_p50 = EXCLUDED.ms_price_p50,
        ms_price_p75 = EXCLUDED.ms_price_p75,
        ms_price_p90 = EXCLUDED.ms_price_p90,
        fl_confidential = EXCLUDED.fl_confidential,
        fl_aggregated_sectors = EXCLUDED.fl_aggregated_sectors,
        nb_aggregated_sectors = EXCLUDED.nb_aggregated_sectors,
        id_batch = EXCLUDED.id_batch,
        dt_updated = CURRENT_TIMESTAMP;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    -- Log des statistiques d'agrégation
    INSERT INTO metadata.data_quality_issues (
        id_batch,
        issue_type,
        issue_description,
        nb_records_affected,
        dt_detected
    )
    SELECT 
        p_batch_id,
        'AGGREGATED_SECTORS',
        format('Données agrégées au niveau commune pour l''année %s: %s enregistrements agrégés en %s lignes', 
               c.cd_year, 
               COUNT(*),
               COUNT(DISTINCT CONCAT(d.id_date, g.id_geography, c.cd_type))),
        COUNT(*),
        CURRENT_TIMESTAMP
    FROM clean_staging.clean_real_estate_sector c
    JOIN dw.dim_date d ON d.cd_year = c.cd_year::INTEGER AND d.cd_period_type = 'Y'
    LEFT JOIN dw.dim_geography g ON g.cd_refnis = SUBSTRING(c.cd_sector FROM 1 FOR 5) 
        AND g.cd_level = '4'
        AND make_date(c.cd_year::INTEGER, 1, 1) BETWEEN g.dt_start AND g.dt_end
    WHERE c.id_batch = p_batch_id
    AND c.cd_sector IS NULL
    GROUP BY c.cd_year
    HAVING COUNT(*) > 0;

    -- Mise à jour du statut dans source_file_history
    UPDATE metadata.source_file_history 
    SET nb_rows_processed = v_count,
        dt_processed = CURRENT_TIMESTAMP,
        tx_status = 'SUCCESS'
    WHERE id_file_history = p_batch_id;

    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_fact_real_estate_sector', 
        'SUCCESS',
        format('Chargement terminé. %s lignes chargées. Durée: %s minutes', 
               v_count,
               EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_start_time))/60)
    );

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'load_fact_real_estate_sector', 
        'ERROR',
        format('Erreur: %s. Durée: %s minutes', 
               SQLERRM,
               EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_start_time))/60)
    );
    RAISE;
END;
$$;

COMMENT ON PROCEDURE dw.load_fact_real_estate_sector(INTEGER, BOOLEAN) IS 
'Procédure de chargement de la table des faits des transactions immobilières.
Arguments:
- p_batch_id : ID du batch à charger
- p_delete_existing : Si TRUE, supprime les données existantes du batch

La procédure:
1. Agrège les données au niveau le plus fin disponible
2. Trace les agrégations via fl_aggregated_sectors et nb_aggregated_sectors
3. Gère les prix et la confidentialité pour les données agrégées
4. Trace les problèmes de qualité des données
5. Met à jour les métadonnées de chargement';