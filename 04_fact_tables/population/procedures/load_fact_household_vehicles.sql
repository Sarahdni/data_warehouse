-- 04_fact_tables/population/procedures/load_fact_household_vehicles.sql

CREATE OR REPLACE PROCEDURE dw.load_fact_household_vehicles(
    p_batch_id INTEGER,
    p_year INTEGER,
    p_delete_existing BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_count INTEGER;
    v_start_time TIMESTAMP;
    v_date_id INTEGER;
BEGIN
    -- Enregistrer l'heure de début
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Log du début
    PERFORM utils.log_script_execution('load_fact_household_vehicles', 'RUNNING');

    -- Récupérer l'ID de la date pour l'année
    SELECT id_date INTO v_date_id
    FROM dw.dim_date
    WHERE cd_year = p_year
    AND cd_period_type = 'Y'
    AND cd_quarter IS NULL
    AND cd_month IS NULL;

    IF v_date_id IS NULL THEN
        RAISE EXCEPTION 'Année % non trouvée dans dim_date', p_year;
    END IF;

    -- Suppression des données existantes si demandé
    IF p_delete_existing THEN
        UPDATE dw.fact_household_vehicles
        SET fl_current = FALSE,
            dt_updated = CURRENT_TIMESTAMP
        WHERE id_date = v_date_id;
        
        RAISE NOTICE 'Anciennes données marquées comme non courantes pour l''année %', p_year;
    END IF;

    -- Insertion des nouvelles données
    INSERT INTO dw.fact_household_vehicles (
        id_date,
        id_geography,
        id_sector_sk,
        ms_households,
        ms_vehicles,
        rt_vehicles_per_household,
        id_batch,
        fl_current
    )
    SELECT
        v_date_id,                        -- id_date
        g.id_geography,                   -- id_geography
        CASE 
            WHEN c.cd_sector LIKE '%ZZZZ' THEN (
                SELECT id_sector_sk 
                FROM dw.dim_statistical_sectors 
                WHERE cd_sector = 'UNKNOWN'
                AND dt_start <= MAKE_DATE(p_year, 1, 1)
                AND (dt_end >= MAKE_DATE(p_year, 12, 31) OR dt_end IS NULL)
            )
            ELSE s.id_sector_sk
        END,
        c.ms_households,                  -- ms_households
        c.ms_vehicles,                    -- ms_vehicles
        CASE
            WHEN c.ms_households > 0 THEN
                ROUND(CAST(c.ms_vehicles AS DECIMAL) / c.ms_households, 2)
            ELSE NULL
        END,                              -- rt_vehicles_per_household
        p_batch_id,                       -- id_batch
        TRUE                              -- fl_current
    FROM clean_staging.clean_household_vehicles c
    JOIN dw.dim_geography g ON g.cd_refnis = c.cd_refnis 
        AND g.dt_start <= MAKE_DATE(p_year, 1, 1)
        AND (g.dt_end >= MAKE_DATE(p_year, 12, 31) OR g.dt_end IS NULL)
    LEFT JOIN dw.dim_statistical_sectors s ON s.cd_sector = c.cd_sector 
        AND NOT c.cd_sector LIKE '%ZZZZ'
        AND s.dt_start <= MAKE_DATE(p_year, 1, 1)
        AND (s.dt_end >= MAKE_DATE(p_year, 12, 31) OR s.dt_end IS NULL)
    WHERE c.id_batch = p_batch_id
    AND c.cd_year = p_year; 

    GET DIAGNOSTICS v_count = ROW_COUNT;

    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_fact_household_vehicles',
        'SUCCESS',
        format('Chargement terminé. %s lignes chargées pour l''année %s',
            v_count, p_year)
    );

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'load_fact_household_vehicles',
        'ERROR',
        SQLERRM
    );
    RAISE;
END;
$$;

COMMENT ON PROCEDURE dw.load_fact_household_vehicles(INTEGER, INTEGER, BOOLEAN) IS 
'Procédure de chargement de la table de fait household_vehicles depuis clean_staging.
IMPORTANT: Les données doivent être préalablement validées avec la procédure clean_staging.validate_household_vehicles_sectors.
CALL dw.load_fact_household_vehicles(84,2022, FALSE);


Arguments:
- p_batch_id : ID du batch à charger
- p_year : Année des données
- p_delete_existing : Si TRUE, marque les données existantes comme non courantes (défaut: FALSE)

La procédure:
1. Vérifie et récupère l''ID de date correspondant à l''année
3. Gère les versions existantes si demandé (SCD Type 2)
4. Charge les données depuis la table de celan_staging
5. Calcule automatiquement le ratio véhicules par ménage
6. Maintient l''historique avec fl_current
7. Assure la jointure avec les secteurs statistiques valides pour l''année donnée';