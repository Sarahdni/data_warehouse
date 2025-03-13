-- 04_fact_tables/taxes/procedures/load_fact_tax_income.sql

CREATE OR REPLACE PROCEDURE dw.load_fact_tax_income(
    p_batch_id INTEGER,
    p_start_year INTEGER,
    p_end_year INTEGER,
    p_delete_existing BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_count INTEGER := 0;
    v_total_count INTEGER := 0;
    v_processing_year INTEGER;
    v_date_id INTEGER;
BEGIN    
    -- Log du début
    PERFORM utils.log_script_execution('load_fact_tax_income', 'RUNNING');

    -- Validations des années
    IF p_start_year > p_end_year THEN
        RAISE EXCEPTION 'L''année de début doit être inférieure ou égale à l''année de fin';
    END IF;

    -- Suppression des données existantes si demandé
    IF p_delete_existing THEN
        UPDATE dw.fact_tax_income
        SET fl_current = FALSE,
            dt_updated = CURRENT_TIMESTAMP
        WHERE id_date IN (
            SELECT id_date 
            FROM dw.dim_date 
            WHERE cd_year BETWEEN p_start_year AND p_end_year
            AND cd_period_type = 'Y'
            AND cd_quarter IS NULL
            AND cd_month IS NULL
        );
        
        RAISE NOTICE 'Anciennes données marquées comme non courantes pour la période % - %', 
            p_start_year, p_end_year;
    END IF;

    -- Insertion pour chaque année dans la plage
    FOR v_processing_year IN p_start_year..p_end_year LOOP
        -- Récupérer l'ID de la date pour l'année courante
        SELECT id_date INTO v_date_id
        FROM dw.dim_date
        WHERE cd_year = v_processing_year
        AND cd_period_type = 'Y'
        AND cd_quarter IS NULL
        AND cd_month IS NULL;

        IF v_date_id IS NULL THEN
            RAISE WARNING 'Année % non trouvée dans dim_date, ignorée', v_processing_year;
            CONTINUE;
        END IF;

        -- Insertion des données pour l'année courante
        INSERT INTO dw.fact_tax_income (
            id_date,
            id_geography,
            ms_nbr_non_zero_inc,
            ms_nbr_zero_inc,
            ms_tot_net_taxable_inc,
            ms_tot_net_inc,
            ms_nbr_tot_net_inc,
            ms_real_estate_net_inc,
            ms_nbr_real_estate_net_inc,
            ms_tot_net_mov_ass_inc,
            ms_nbr_net_mov_ass_inc,
            ms_tot_net_various_inc,
            ms_nbr_net_various_inc,
            ms_tot_net_prof_inc,
            ms_nbr_net_prof_inc,
            ms_sep_taxable_inc,
            ms_nbr_sep_taxable_inc,
            ms_joint_taxable_inc,
            ms_nbr_joint_taxable_inc,
            ms_tot_deduct_spend,
            ms_nbr_deduct_spend,
            ms_tot_state_taxes,
            ms_nbr_state_taxes,
            ms_tot_municip_taxes,
            ms_nbr_municip_taxes,
            ms_tot_suburbs_taxes,
            ms_nbr_suburbs_taxes,
            ms_tot_taxes,
            ms_nbr_tot_taxes,
            ms_tot_residents,
            id_batch,
            fl_current
        )
        SELECT DISTINCT ON (c.cd_munty_refnis)
            v_date_id,
            g.id_geography,
            c.ms_nbr_non_zero_inc,
            c.ms_nbr_zero_inc,
            c.ms_tot_net_taxable_inc,
            c.ms_tot_net_inc,
            c.ms_nbr_tot_net_inc,
            c.ms_real_estate_net_inc,
            c.ms_nbr_real_estate_net_inc,
            c.ms_tot_net_mov_ass_inc,
            c.ms_nbr_net_mov_ass_inc,
            c.ms_tot_net_various_inc,
            c.ms_nbr_net_various_inc,
            c.ms_tot_net_prof_inc,
            c.ms_nbr_net_prof_inc,
            c.ms_sep_taxable_inc,
            c.ms_nbr_sep_taxable_inc,
            c.ms_joint_taxable_inc,
            c.ms_nbr_joint_taxable_inc,
            c.ms_tot_deduct_spend,
            c.ms_nbr_deduct_spend,
            c.ms_tot_state_taxes,
            c.ms_nbr_state_taxes,
            c.ms_tot_municip_taxes,
            c.ms_nbr_municip_taxes,
            c.ms_tot_suburbs_taxes,
            c.ms_nbr_suburbs_taxes,
            c.ms_tot_taxes,
            c.ms_nbr_tot_taxes,
            c.ms_tot_residents,
            p_batch_id,
            TRUE
        FROM clean_staging.clean_tax_income c
        JOIN dw.dim_geography g ON 
            CASE 
                WHEN EXISTS (
                    SELECT 1 FROM metadata.refnis_changes_2019 
                    WHERE cd_refnis_post2019 = c.cd_munty_refnis
                ) THEN 
                    -- Pour les communes fusionnées, utiliser le nouveau REFNIS sans contrainte de date
                    g.cd_refnis = c.cd_munty_refnis 
                ELSE
                    -- Pour les autres communes, respecter les dates de validité
                    g.cd_refnis = c.cd_munty_refnis 
                    AND g.dt_start <= MAKE_DATE(v_processing_year, 1, 1)
                    AND (g.dt_end >= MAKE_DATE(v_processing_year, 12, 31) OR g.dt_end IS NULL)
            END
        WHERE c.id_batch = p_batch_id
        AND c.cd_year = v_processing_year
        AND c.fl_valid_munty_refnis = TRUE
        AND (c.fl_valid_counts IS NULL OR c.fl_valid_counts = TRUE)
        AND c.fl_valid_amounts = TRUE
        AND c.fl_valid_hierarchy = TRUE;

        GET DIAGNOSTICS v_count = ROW_COUNT;
        v_total_count := v_total_count + v_count;

        RAISE NOTICE 'Année % : % lignes chargées', v_processing_year, v_count;
    END LOOP;

    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_fact_tax_income',
        'SUCCESS',
        format('Chargement terminé. %s lignes chargées au total pour la période %s-%s',
            v_total_count, p_start_year, p_end_year)
    );

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'load_fact_tax_income',
        'ERROR',
        SQLERRM
    );
    RAISE;
END;
$$;


COMMENT ON PROCEDURE dw.load_fact_tax_income(INTEGER, INTEGER, INTEGER, BOOLEAN) IS 
'Procédure de chargement de la table de fait tax_income depuis clean_staging.
IMPORTANT: Les données doivent être préalablement validées avec la procédure clean_staging.validate_clean_tax_income.

Arguments:
- p_batch_id : ID du batch à charger
- p_start_year : Année de début de la période à charger
- p_end_year : Année de fin de la période à charger
- p_delete_existing : Si TRUE, marque les données existantes comme non courantes (défaut: FALSE)

La procédure:
1. Valide la cohérence des années de début et de fin
2. Gère les versions existantes si demandé (SCD Type 2)
3. Charge les données année par année depuis clean_staging
4. Ne charge que les données valides (tous les flags à TRUE)
5. Maintient l''historique avec fl_current
6. Assure la jointure avec la géographie valide pour chaque année, en prenant en compte les fusions de communes
7. Fournit des statistiques de chargement par année';
