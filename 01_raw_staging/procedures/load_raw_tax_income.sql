-- 01_raw_staging/procedures/load_raw_tax_income.sql

-- Création de la séquence si elle n'existe pas
CREATE SEQUENCE IF NOT EXISTS metadata.seq_batch_id
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;

-- Procédure de chargement
CREATE OR REPLACE PROCEDURE raw_staging.load_raw_tax_income(
    p_filename TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_source_id INTEGER;
    v_file_path TEXT;
    v_delimiter CHAR;
    v_encoding TEXT;
    v_count INTEGER;
    v_start_time TIMESTAMP;
    v_temp_table_name TEXT;
    v_sql TEXT;
    v_batch_id INTEGER;
BEGIN
    -- Générer un nouveau batch_id
    SELECT nextval('metadata.seq_batch_id') INTO v_batch_id;
    
    -- Log du début
    PERFORM utils.log_script_execution('load_raw_tax_income', 'RUNNING',
        format('Début du chargement avec batch_id %s', v_batch_id));

    -- Récupérer les informations de la source
    SELECT 
        id_source,
        tx_file_path,
        tx_delimiter,
        tx_encoding
    INTO 
        v_source_id,
        v_file_path,
        v_delimiter,
        v_encoding
    FROM metadata.dim_source 
    WHERE cd_source = 'INCOME_TAX'
    AND fl_active = TRUE;

    IF v_source_id IS NULL THEN
        RAISE EXCEPTION 'Source INCOME_TAX non trouvée ou inactive dans dim_source';
    END IF;

    -- Construire le chemin complet du fichier
    v_file_path := v_file_path || p_filename;
    
    -- Créer un nom unique pour la table temporaire
    v_temp_table_name := 'temp_tax_income_' || v_batch_id;

    -- Créer la table temporaire sans les colonnes de traçabilité
    EXECUTE format('
        CREATE TEMP TABLE %I (
            cd_year VARCHAR(4),
            cd_munty_refnis VARCHAR(5),
            ms_nbr_non_zero_inc VARCHAR(20),
            ms_nbr_zero_inc VARCHAR(20),
            ms_tot_net_taxable_inc VARCHAR(20),
            ms_tot_net_inc VARCHAR(20),
            ms_nbr_tot_net_inc VARCHAR(20),
            ms_real_estate_net_inc VARCHAR(20),
            ms_nbr_real_estate_net_inc VARCHAR(20),
            ms_tot_net_mov_ass_inc VARCHAR(20),
            ms_nbr_net_mov_ass_inc VARCHAR(20),
            ms_tot_net_various_inc VARCHAR(20),
            ms_nbr_net_various_inc VARCHAR(20),
            ms_tot_net_prof_inc VARCHAR(20),
            ms_nbr_net_prof_inc VARCHAR(20),
            ms_sep_taxable_inc VARCHAR(20),
            ms_nbr_sep_taxable_inc VARCHAR(20),
            ms_joint_taxable_inc VARCHAR(20),
            ms_nbr_joint_taxable_inc VARCHAR(20),
            ms_tot_deduct_spend VARCHAR(20),
            ms_nbr_deduct_spend VARCHAR(20),
            ms_tot_state_taxes VARCHAR(20),
            ms_nbr_state_taxes VARCHAR(20),
            ms_tot_municip_taxes VARCHAR(20),
            ms_nbr_municip_taxes VARCHAR(20),
            ms_tot_suburbs_taxes VARCHAR(20),
            ms_nbr_suburbs_taxes VARCHAR(20),
            ms_tot_taxes VARCHAR(20),
            ms_nbr_tot_taxes VARCHAR(20),
            ms_tot_residents VARCHAR(20),
            tx_munty_descr_nl VARCHAR(100),
            tx_munty_descr_fr VARCHAR(100),
            tx_munty_descr_en VARCHAR(100),
            tx_munty_descr_de VARCHAR(100),
            cd_dstr_refnis VARCHAR(10),
            tx_dstr_descr_nl VARCHAR(100),
            tx_dstr_descr_fr VARCHAR(100),
            tx_dstr_descr_en VARCHAR(100),
            tx_dstr_descr_de VARCHAR(100),
            cd_prov_refnis VARCHAR(10),
            tx_prov_descr_nl VARCHAR(100),
            tx_prov_descr_fr VARCHAR(100),
            tx_prov_descr_en VARCHAR(100),
            tx_prov_descr_de VARCHAR(100),
            cd_rgn_refnis VARCHAR(10),
            tx_rgn_descr_nl VARCHAR(100),
            tx_rgn_descr_fr VARCHAR(100),
            tx_rgn_descr_en VARCHAR(100),
            tx_rgn_descr_de VARCHAR(100)
        )', v_temp_table_name);

    -- Charger les données dans la table temporaire
    EXECUTE format('COPY %I FROM %L WITH (
        FORMAT csv,
        DELIMITER %L,
        HEADER true,
        ENCODING %L
    )', v_temp_table_name, v_file_path, v_delimiter, v_encoding);

    -- Récupérer le nombre de lignes chargées
    EXECUTE format('SELECT COUNT(*) FROM %I', v_temp_table_name) INTO v_count;

    IF v_count = 0 THEN
        RAISE EXCEPTION 'Aucune donnée chargée depuis le fichier %', p_filename;
    END IF;

    -- Insérer les données dans la table finale avec le batch_id
    EXECUTE format('
        INSERT INTO raw_staging.raw_tax_income (
            cd_year, cd_munty_refnis, 
            ms_nbr_non_zero_inc, ms_nbr_zero_inc,
            ms_tot_net_taxable_inc, ms_tot_net_inc, ms_nbr_tot_net_inc,
            ms_real_estate_net_inc, ms_nbr_real_estate_net_inc,
            ms_tot_net_mov_ass_inc, ms_nbr_net_mov_ass_inc,
            ms_tot_net_various_inc, ms_nbr_net_various_inc,
            ms_tot_net_prof_inc, ms_nbr_net_prof_inc,
            ms_sep_taxable_inc, ms_nbr_sep_taxable_inc,
            ms_joint_taxable_inc, ms_nbr_joint_taxable_inc,
            ms_tot_deduct_spend, ms_nbr_deduct_spend,
            ms_tot_state_taxes, ms_nbr_state_taxes,
            ms_tot_municip_taxes, ms_nbr_municip_taxes,
            ms_tot_suburbs_taxes, ms_nbr_suburbs_taxes,
            ms_tot_taxes, ms_nbr_tot_taxes, ms_tot_residents,
            tx_munty_descr_nl, tx_munty_descr_fr, tx_munty_descr_en, tx_munty_descr_de,
            cd_dstr_refnis, tx_dstr_descr_nl, tx_dstr_descr_fr, tx_dstr_descr_en, tx_dstr_descr_de,
            cd_prov_refnis, tx_prov_descr_nl, tx_prov_descr_fr, tx_prov_descr_en, tx_prov_descr_de,
            cd_rgn_refnis, tx_rgn_descr_nl, tx_rgn_descr_fr, tx_rgn_descr_en, tx_rgn_descr_de,
            id_batch,
            dt_import
        )
        SELECT 
            cd_year, cd_munty_refnis,
            ms_nbr_non_zero_inc, ms_nbr_zero_inc,
            ms_tot_net_taxable_inc, ms_tot_net_inc, ms_nbr_tot_net_inc,
            ms_real_estate_net_inc, ms_nbr_real_estate_net_inc,
            ms_tot_net_mov_ass_inc, ms_nbr_net_mov_ass_inc,
            ms_tot_net_various_inc, ms_nbr_net_various_inc,
            ms_tot_net_prof_inc, ms_nbr_net_prof_inc,
            ms_sep_taxable_inc, ms_nbr_sep_taxable_inc,
            ms_joint_taxable_inc, ms_nbr_joint_taxable_inc,
            ms_tot_deduct_spend, ms_nbr_deduct_spend,
            ms_tot_state_taxes, ms_nbr_state_taxes,
            ms_tot_municip_taxes, ms_nbr_municip_taxes,
            ms_tot_suburbs_taxes, ms_nbr_suburbs_taxes,
            ms_tot_taxes, ms_nbr_tot_taxes, ms_tot_residents,
            tx_munty_descr_nl, tx_munty_descr_fr, tx_munty_descr_en, tx_munty_descr_de,
            cd_dstr_refnis, tx_dstr_descr_nl, tx_dstr_descr_fr, tx_dstr_descr_en, tx_dstr_descr_de,
            cd_prov_refnis, tx_prov_descr_nl, tx_prov_descr_fr, tx_prov_descr_en, tx_prov_descr_de,
            cd_rgn_refnis, tx_rgn_descr_nl, tx_rgn_descr_fr, tx_rgn_descr_en, tx_rgn_descr_de,
            %s,
            CURRENT_TIMESTAMP
        FROM %I',
        v_batch_id, v_temp_table_name
    );

    -- Enregistrer dans l'historique
    INSERT INTO metadata.source_file_history (
        id_source,
        tx_filename,
        dt_processed,
        nb_rows_processed,
        tx_status
    ) VALUES (
        v_source_id,
        p_filename,
        CURRENT_TIMESTAMP,
        v_count,
        'SUCCESS'
    );

    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_raw_tax_income',
        'SUCCESS',
        format('Chargement terminé. %s lignes chargées (batch_id: %s)', 
               v_count, v_batch_id)
    );

    -- Nettoyer la table temporaire
    EXECUTE format('DROP TABLE IF EXISTS %I', v_temp_table_name);

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'load_raw_tax_income',
        'ERROR',
        SQLERRM
    );

    -- Enregistrer l'erreur dans l'historique
    INSERT INTO metadata.source_file_history (
        id_source,
        tx_filename,
        dt_processed,
        nb_rows_processed,
        tx_status,
        tx_error_message
    ) VALUES (
        v_source_id,
        p_filename,
        CURRENT_TIMESTAMP,
        0,
        'ERROR',
        SQLERRM
    );

    -- Nettoyer en cas d'erreur
    EXECUTE format('DROP TABLE IF EXISTS %I', v_temp_table_name);
    RAISE;
END;
$$;

COMMENT ON PROCEDURE raw_staging.load_raw_tax_income(TEXT) IS 
'Procédure de chargement des données fiscales brutes.
Cette procédure utilise les paramètres de configuration stockés dans metadata.dim_source
et génère automatiquement un batch_id.

Arguments :
- p_filename : Nom du fichier à charger

Exemple d''utilisation :
CALL raw_staging.load_raw_tax_income(''tax_income_2023.csv'');';