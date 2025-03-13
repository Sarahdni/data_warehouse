-- 02_clean_staging/procedures/load_clean_population_structure.sql

-- Suppression de la procédure existante
DROP PROCEDURE IF EXISTS clean_staging.load_clean_population_structure(INTEGER, INTEGER, BOOLEAN);

CREATE OR REPLACE PROCEDURE clean_staging.load_clean_population_structure(
    p_batch_id INTEGER,
    p_year INTEGER,
    p_truncate BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_count INTEGER;
    v_start_time TIMESTAMP;
    v_year_start DATE;
    v_year_end DATE;
BEGIN
    -- Calculer les dates de début et fin de l'année
    v_year_start := make_date(p_year, 1, 1);
    v_year_end := make_date(p_year, 12, 31);
    
    -- Log du début
    PERFORM utils.log_script_execution('load_clean_population_structure', 'RUNNING');

    -- Suppression des données si demandé
    IF p_truncate THEN
        TRUNCATE TABLE clean_staging.clean_population_structure;
        RAISE NOTICE 'Table clean_population_structure vidée';
    END IF;

    -- Insertion depuis raw_staging avec gestion améliorée des périodes de validité
    INSERT INTO clean_staging.clean_population_structure (
        id_geography,
        cd_sex,
        cd_age,
        cd_nationality,
        cd_civil_status,
        cd_year,
        ms_population,
        id_batch,
        fl_valid_geography,
        fl_valid_sex,
        fl_valid_age,
        fl_valid_nationality,
        fl_valid_civil_status
    )
    WITH valid_geography AS (
        -- Sélectionner la version géographique la plus appropriée
        SELECT r.CD_REFNIS,
               COALESCE(
                   -- D'abord essayer la période exacte avec comparaison par mois
                   MAX(CASE 
                       WHEN v_year_start >= g.dt_start 
                       AND (
                           -- Vérifie si l'année et le mois de fin correspondent
                           (EXTRACT(YEAR FROM g.dt_end) = EXTRACT(YEAR FROM v_year_end) 
                           AND EXTRACT(MONTH FROM g.dt_end) = EXTRACT(MONTH FROM v_year_end))
                           OR g.dt_end > v_year_end 
                           OR g.dt_end IS NULL
                       )
                       THEN g.id_geography 
                   END),
                   -- Sinon prendre la période la plus proche précédente
                   MAX(CASE WHEN g.dt_start <= v_year_end 
                       THEN g.id_geography END),
                   -- En dernier recours, prendre la première période future
                   MIN(g.id_geography)
               ) as id_geography
        FROM raw_staging.raw_population_structure r
        LEFT JOIN dw.dim_geography g ON g.cd_refnis = r.CD_REFNIS
        WHERE r.id_batch = p_batch_id
        GROUP BY r.CD_REFNIS
    )
    SELECT 
        vg.id_geography,
        r.CD_SEX,
        r.CD_AGE,
        CASE 
            WHEN r.CD_NATLTY = 'BEL' THEN 'BE'
            WHEN r.CD_NATLTY = 'ETR' THEN 'NOT_BE'
            ELSE 'NOT_BE'
        END as cd_nationality,
        CASE r.CD_CIV_STS 
            WHEN '1' THEN 'CEL'
            WHEN '2' THEN 'MAR'
            WHEN '3' THEN 'VEU'
            WHEN '4' THEN 'DIV'
            WHEN '5' THEN 'SEP'
        END as cd_civil_status,
        p_year,
        r.MS_POPULATION,
        p_batch_id,
        -- Flags de validation améliorés
        (vg.id_geography IS NOT NULL) as fl_valid_geography,
        (r.CD_SEX IN ('M', 'F')) as fl_valid_sex,
        (r.CD_AGE BETWEEN 0 AND 120) as fl_valid_age,
        (r.CD_NATLTY IN ('BEL', 'ETR')) as fl_valid_nationality,
        (r.CD_CIV_STS IN ('1','2','3','4','5')) as fl_valid_civil_status
    FROM raw_staging.raw_population_structure r
    LEFT JOIN valid_geography vg ON vg.CD_REFNIS = r.CD_REFNIS
    WHERE r.id_batch = p_batch_id
    AND r.MS_POPULATION > 0;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_clean_population_structure', 
        'SUCCESS',
        format('Chargement terminé. %s lignes chargées.', v_count)
    );

    -- Validation des données chargées
    CALL clean_staging.validate_clean_population_structure(p_batch_id);

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'load_clean_population_structure', 
        'ERROR',
        SQLERRM
    );
    RAISE;
END;
$$;

COMMENT ON PROCEDURE clean_staging.load_clean_population_structure IS 
'Procédure de chargement des données de population depuis raw_staging vers clean_staging.
Version améliorée avec gestion des dates de fin de mois.

Améliorations:
- Comparaison par année et mois plutôt que par jour exact
- Gestion des cas où la date de fin tombe dans le même mois
- Logique de fallback en 3 étapes pour trouver la meilleure correspondance
- Support des cas limites comme 2024-12-01 vs 2024-12-31';