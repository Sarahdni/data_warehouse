-- 04_fact_tables/population/procedures/load_fact_population_structure.sql

CREATE OR REPLACE PROCEDURE dw.load_fact_population_structure(
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
    PERFORM utils.log_script_execution('load_fact_population_structure', 'RUNNING');

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
        UPDATE dw.fact_population_structure
        SET fl_current = FALSE,
            dt_updated = CURRENT_TIMESTAMP
        WHERE id_date = v_date_id;
        
        RAISE NOTICE 'Anciennes données marquées comme non courantes pour l''année %', p_year;
    END IF;

    -- Insertion des nouvelles données
    INSERT INTO dw.fact_population_structure (
        id_date,
        id_geography,
        id_age,
        cd_sex,
        cd_nationality,
        cd_civil_status,
        ms_population,
        id_batch,
        fl_current,
        dt_created,
        dt_updated
    )
    SELECT 
        v_date_id,                -- id_date
        c.id_geography,           -- id_geography
        c.cd_age,                -- id_age (cd_age est la clé dans dim_age)
        c.cd_sex,                -- cd_sex
        c.cd_nationality,        -- cd_nationality
        c.cd_civil_status,       -- cd_civil_status
        c.ms_population,         -- ms_population
        p_batch_id,              -- id_batch
        TRUE,                    -- fl_current
        CURRENT_TIMESTAMP,       -- dt_created
        CURRENT_TIMESTAMP        -- dt_updated
    FROM clean_staging.clean_population_structure c
    WHERE c.id_batch = p_batch_id
    -- Ne charger que les données valides
    AND c.fl_valid_geography = TRUE
    AND c.fl_valid_sex = TRUE
    AND c.fl_valid_age = TRUE
    AND c.fl_valid_nationality = TRUE
    AND c.fl_valid_civil_status = TRUE
    -- Exclure les populations nulles ou négatives
    AND c.ms_population > 0;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_fact_population_structure', 
        'SUCCESS',
        format('Chargement terminé. %s lignes chargées pour l''année %s', 
               v_count, p_year)
    );

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'load_fact_population_structure', 
        'ERROR',
        SQLERRM
    );
    RAISE;
END;
$$;

COMMENT ON PROCEDURE dw.load_fact_population_structure(INTEGER, INTEGER, BOOLEAN) IS 
'Procédure de chargement de la table de fait population_structure depuis clean_staging.
Arguments:
- p_batch_id : ID du batch à charger
- p_year : Année des données
- p_delete_existing : Si TRUE, marque les données existantes comme non courantes (défaut: FALSE)

La procédure:
1. Récupère l''ID de date correspondant à l''année
2. Gère les versions existantes si demandé
3. Charge uniquement les données valides (tous les flags à TRUE)
4. Exclut les populations nulles ou négatives';