-- 04_fact_tables/population/procedures/load_fact_household_cohabitation.sql

CREATE OR REPLACE PROCEDURE dw.load_fact_household_cohabitation(
    p_batch_id INTEGER,
    p_truncate BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_count INTEGER;
    v_error_message TEXT;
BEGIN
    -- Enregistrer l'heure de début
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Log du début
    PERFORM utils.log_script_execution('load_fact_household_cohabitation', 'RUNNING');

    -- Vider la table si demandé
    IF p_truncate THEN
        TRUNCATE TABLE dw.fact_household_cohabitation;
        RAISE NOTICE 'Table fact_household_cohabitation tronquée';
    END IF;

    -- Insertion des données depuis clean_staging
    INSERT INTO dw.fact_household_cohabitation (
        id_date,
        id_geography,
        cd_sex,
        cd_age_group,
        cd_nationality,
        cd_cohabitation,
        ms_count,
        id_batch
    )
    SELECT 
        d.id_date,
        g.id_geography,
        c.cd_sex,
        c.cd_age AS cd_age_group,  -- correspondance directe car même format
        c.cd_natlty,
        CASE WHEN c.fl_cohab = '1' THEN 'OUI'
             WHEN c.fl_cohab = '0' THEN 'NON'
             ELSE NULL
        END as cd_cohabitation,
        c.ms_count, 
        p_batch_id
    FROM clean_staging.clean_household_cohabitation c
    JOIN dw.dim_date d ON d.cd_year = c.cd_year::INTEGER
        AND d.cd_period_type = 'Y'  -- pour année complète
    JOIN dw.dim_geography g ON g.cd_refnis = LPAD(c.cd_rgn_refnis, 5, '0')
    WHERE c.id_batch = p_batch_id;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_fact_household_cohabitation',
        'SUCCESS',
        format('Chargement terminé. %s lignes chargées.', v_count)
    );

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
    
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'load_fact_household_cohabitation',
        'ERROR',
        v_error_message
    );
    RAISE;
END;
$$;

COMMENT ON PROCEDURE dw.load_fact_household_cohabitation(INTEGER, BOOLEAN) IS 
'Procédure de chargement de la table de faits des cohabitations.

Arguments:
- p_batch_id : ID du batch à charger
- p_truncate : si TRUE, vide la table avant chargement (défaut: FALSE)

Exemple:
CALL dw.load_fact_household_cohabitation(123, FALSE);';