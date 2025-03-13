-- 04_fact_tables/real_estate/procedures/load_fact_real_estate_municipality.sql
CREATE OR REPLACE PROCEDURE dw.load_fact_real_estate_municipality(
    p_batch_id INTEGER,
    p_truncate BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_count INTEGER;
    v_error_message TEXT;
    v_source_id INTEGER;
BEGIN
    -- Enregistrer le début d'exécution
    v_start_time := CURRENT_TIMESTAMP;

    -- Récupérer l'id de la source
    SELECT id_source INTO v_source_id 
    FROM metadata.dim_source 
    WHERE cd_source = 'IMMO_MUN';
    
    -- Log du début
    PERFORM utils.log_script_execution('load_fact_real_estate_municipality', 'RUNNING');

    -- Vider la table si demandé
    IF p_truncate THEN
        TRUNCATE TABLE dw.fact_real_estate_municipality;
        RAISE NOTICE 'Table fact_real_estate_municipality tronquée';
    END IF;



    -- Insertion des données depuis clean_staging
    WITH source_data AS (
        SELECT DISTINCT 
            d.id_date,
            g.id_geography,
            CASE 
                WHEN c.tx_property_type_fr = 'appartements, flats, studios' THEN 'R7'
                WHEN c.tx_property_type_fr = 'terrains à bâtir' THEN 'R8'
                WHEN c.tx_property_type_fr = 'maisons d''habitation' THEN 'R9'
                WHEN c.tx_property_type_fr = 'villas, bungalows, maisons de campagne' THEN 'R10'
            END as cd_building_type,
            c.ms_total_transactions,
            CASE 
                WHEN c.ms_total_transactions < 10 THEN NULL 
                ELSE c.ms_total_price 
            END as ms_total_price,
            CASE 
                WHEN c.ms_total_transactions < 10 THEN NULL 
                ELSE c.ms_total_surface 
            END as ms_total_surface,
            CASE 
                WHEN c.ms_total_transactions < 10 THEN NULL 
                ELSE c.ms_mean_price 
            END as ms_mean_price,
            CASE 
                WHEN c.ms_total_transactions < 10 THEN NULL 
                ELSE c.ms_price_p10 
            END as ms_price_p10,
            CASE 
                WHEN c.ms_total_transactions < 10 THEN NULL 
                ELSE c.ms_price_p25 
            END as ms_price_p25,
            CASE 
                WHEN c.ms_total_transactions < 10 THEN NULL 
                ELSE c.ms_price_p50 
            END as ms_price_p50,
            CASE 
                WHEN c.ms_total_transactions < 10 THEN NULL 
                ELSE c.ms_price_p75 
            END as ms_price_p75,
            CASE 
                WHEN c.ms_total_transactions < 10 THEN NULL 
                ELSE c.ms_price_p90 
            END as ms_price_p90,
            c.ms_total_transactions < 10 as fl_confidential,
            p_batch_id as id_batch
        FROM clean_staging.clean_immo_by_municipality c
        JOIN dw.dim_date d 
            ON d.cd_year = c.cd_year 
            AND d.cd_period_type = 
                CASE 
                    WHEN c.cd_period LIKE 'Q%' THEN 'Q'
                    WHEN c.cd_period LIKE 'S%' THEN 'S'
                    ELSE 'Y'
                END
            AND CASE 
                WHEN c.cd_period LIKE 'Q%' THEN 
                    NULLIF(SUBSTRING(c.cd_period, 2, 1), '')::INTEGER = d.cd_quarter
                WHEN c.cd_period LIKE 'S%' THEN 
                    NULLIF(SUBSTRING(c.cd_period, 2, 1), '')::INTEGER = d.cd_semester
                ELSE 
                    d.cd_quarter IS NULL AND d.cd_semester IS NULL
            END
        JOIN dw.dim_geography g ON g.cd_refnis = c.cd_refnis
            AND c.cd_year BETWEEN EXTRACT(YEAR FROM g.dt_start) AND EXTRACT(YEAR FROM g.dt_end)
        WHERE c.id_batch = p_batch_id
    )
    INSERT INTO dw.fact_real_estate_municipality (
        id_date,
        id_geography,
        cd_building_type,
        ms_total_transactions,
        ms_total_price,
        ms_total_surface,
        ms_mean_price,
        ms_price_p10,
        ms_price_p25,
        ms_price_p50,
        ms_price_p75,
        ms_price_p90,
        fl_confidential,
        id_batch
    )
    SELECT *
    FROM source_data
    ON CONFLICT (id_date, id_geography, cd_building_type) 
    DO UPDATE SET
        ms_total_transactions = EXCLUDED.ms_total_transactions,
        ms_total_price = EXCLUDED.ms_total_price,
        ms_total_surface = EXCLUDED.ms_total_surface,
        ms_mean_price = EXCLUDED.ms_mean_price,
        ms_price_p10 = EXCLUDED.ms_price_p10,
        ms_price_p25 = EXCLUDED.ms_price_p25,
        ms_price_p50 = EXCLUDED.ms_price_p50,
        ms_price_p75 = EXCLUDED.ms_price_p75,
        ms_price_p90 = EXCLUDED.ms_price_p90,
        fl_confidential = EXCLUDED.fl_confidential,
        id_batch = EXCLUDED.id_batch,
        dt_updated = CURRENT_TIMESTAMP;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    -- Enregistrement des résultats dans l'historique
    INSERT INTO metadata.source_file_history (
        id_source,
        tx_filename,
        dt_processed,
        nb_rows_processed,
        tx_status
    ) VALUES (
        v_source_id,
        'batch_' || p_batch_id::text,
        CURRENT_TIMESTAMP,
        v_count,
        'SUCCESS'
    );

    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_fact_real_estate_municipality',
        'SUCCESS',
        format('Chargement terminé. %s lignes chargées.', v_count)
    );

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
    
    -- Enregistrement de l'erreur
    INSERT INTO metadata.source_file_history (
        id_source,
        tx_filename,
        dt_processed,
        nb_rows_processed,
        tx_status,
        tx_error_message
    ) VALUES (
        v_source_id,
        'batch_' || p_batch_id::text,
        CURRENT_TIMESTAMP,
        0,
        'ERROR',
        v_error_message
    );

    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'load_fact_real_estate_municipality',
        'ERROR',
        v_error_message
    );
    RAISE;
END;
$$;

COMMENT ON PROCEDURE dw.load_fact_real_estate_municipality(INTEGER, BOOLEAN) IS 
'Procédure de chargement de la table de faits immobiliers par commune.

Arguments:
- p_batch_id : ID du batch à charger
- p_truncate : si TRUE, vide la table avant chargement (défaut: FALSE)

La procédure :
1. Charge les données depuis clean_staging
2. Fait la jointure avec dim_date sur l''année et la période
3. Fait la jointure avec dim_geography sur le code REFNIS
4. Détermine le type de bien (cd_building_type)
5. Gère la confidentialité (<10 transactions)
6. Enregistre les résultats dans l''historique

Exemple:
CALL dw.load_fact_real_estate_municipality(123, FALSE);';

    