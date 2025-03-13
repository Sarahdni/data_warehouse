-- 02_clean_staging/procedures/load_clean_tax_income.sql

\echo 'Starting load_clean_tax_income.sql...'

-- Log du début d'exécution
DO $$ 
BEGIN 
    PERFORM utils.log_script_execution('load_clean_tax_income.sql', 'RUNNING');
END $$;

CREATE OR REPLACE PROCEDURE clean_staging.load_clean_tax_income(
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
    -- Enregistrer l'heure de début
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Récupérer l'id de la source
    SELECT id_source INTO v_source_id 
    FROM metadata.dim_source 
    WHERE cd_source = 'INCOME_TAX';
    
    -- Log du début
    PERFORM utils.log_script_execution('load_clean_tax_income', 'RUNNING');

    -- Suppression des données existantes si demandé
    IF p_truncate THEN
        TRUNCATE TABLE clean_staging.clean_tax_income;
        RAISE NOTICE 'Table clean_tax_income tronquée';
    END IF;

    -- Insertion des données depuis raw_staging
    INSERT INTO clean_staging.clean_tax_income (
        cd_year,
        cd_munty_refnis,
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
        cd_dstr_refnis,
        cd_prov_refnis,
        cd_rgn_refnis,
        id_batch
    )
    SELECT
        cd_year::INTEGER,
        cd_munty_refnis,
        NULLIF(REGEXP_REPLACE(ms_nbr_non_zero_inc, '[^0-9]', '', 'g'), '')::INTEGER,
        NULLIF(REGEXP_REPLACE(ms_nbr_zero_inc, '[^0-9]', '', 'g'), '')::INTEGER,
        NULLIF(REGEXP_REPLACE(ms_tot_net_taxable_inc, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_tot_net_inc, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_nbr_tot_net_inc, '[^0-9]', '', 'g'), '')::INTEGER,
        NULLIF(REGEXP_REPLACE(ms_real_estate_net_inc, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_nbr_real_estate_net_inc, '[^0-9]', '', 'g'), '')::INTEGER,
        NULLIF(REGEXP_REPLACE(ms_tot_net_mov_ass_inc, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_nbr_net_mov_ass_inc, '[^0-9]', '', 'g'), '')::INTEGER,
        NULLIF(REGEXP_REPLACE(ms_tot_net_various_inc, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_nbr_net_various_inc, '[^0-9]', '', 'g'), '')::INTEGER,
        NULLIF(REGEXP_REPLACE(ms_tot_net_prof_inc, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_nbr_net_prof_inc, '[^0-9]', '', 'g'), '')::INTEGER,
        NULLIF(REGEXP_REPLACE(ms_sep_taxable_inc, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_nbr_sep_taxable_inc, '[^0-9]', '', 'g'), '')::INTEGER,
        NULLIF(REGEXP_REPLACE(ms_joint_taxable_inc, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_nbr_joint_taxable_inc, '[^0-9]', '', 'g'), '')::INTEGER,
        NULLIF(REGEXP_REPLACE(ms_tot_deduct_spend, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_nbr_deduct_spend, '[^0-9]', '', 'g'), '')::INTEGER,
        NULLIF(REGEXP_REPLACE(ms_tot_state_taxes, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_nbr_state_taxes, '[^0-9]', '', 'g'), '')::INTEGER,
        NULLIF(REGEXP_REPLACE(ms_tot_municip_taxes, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_nbr_municip_taxes, '[^0-9]', '', 'g'), '')::INTEGER,
        NULLIF(REGEXP_REPLACE(ms_tot_suburbs_taxes, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_nbr_suburbs_taxes, '[^0-9]', '', 'g'), '')::INTEGER,
        NULLIF(REGEXP_REPLACE(ms_tot_taxes, '[^0-9\.]', '', 'g'), '')::DECIMAL(15,2),
        NULLIF(REGEXP_REPLACE(ms_nbr_tot_taxes, '[^0-9]', '', 'g'), '')::INTEGER,
        NULLIF(REGEXP_REPLACE(ms_tot_residents, '[^0-9]', '', 'g'), '')::INTEGER,
        cd_dstr_refnis,
        LEFT(cd_prov_refnis, 5),
        cd_rgn_refnis,
        p_batch_id
    FROM raw_staging.raw_tax_income
    WHERE id_batch = p_batch_id;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    
    -- Validation des données chargées
    CALL clean_staging.validate_clean_tax_income(
        p_batch_id := p_batch_id,
        p_raise_exception := FALSE
    );

    -- Enregistrement dans l'historique
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
        'load_clean_tax_income',
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
        'load_clean_tax_income',
        'ERROR',
        v_error_message
    );
    RAISE;
END;
$$;

-- Ajout des commentaires sur la procédure
COMMENT ON PROCEDURE clean_staging.load_clean_tax_income(INTEGER, BOOLEAN) IS 
'Procédure de chargement des données fiscales depuis raw_staging vers clean_staging.

Cette procédure :
1. Charge les données depuis raw_staging
2. Effectue les conversions de types nécessaires et le nettoyage des valeurs numériques
3. Valide les données chargées
4. Enregistre les résultats dans l''historique

Arguments :
- p_batch_id : ID du batch à charger
- p_truncate : Si TRUE, vide la table avant chargement (défaut: FALSE)

Exemple d''utilisation :
CALL clean_staging.load_clean_tax_income(123, FALSE);';

-- Log du succès de la création
DO $$ 
BEGIN 
    PERFORM utils.log_script_execution('load_clean_tax_income.sql', 'SUCCESS');
END $$;

\echo 'Finished load_clean_tax_income.sql successfully.'