-- 02_clean_staging/procedures/load_clean_real_estate_sector.sql

CREATE OR REPLACE PROCEDURE clean_staging.load_clean_real_estate_sector(
    p_batch_id INTEGER,
    p_delete_existing BOOLEAN DEFAULT TRUE,
    p_min_transactions INTEGER DEFAULT 16
)
LANGUAGE plpgsql AS $$
DECLARE
    v_count INTEGER;
    v_error_count INTEGER := 0;
    v_start_time TIMESTAMP;
    v_source_id INTEGER;
BEGIN
    -- Enregistrer le début d'exécution
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Log du début
    PERFORM utils.log_script_execution('load_clean_real_estate_sector', 'RUNNING');

    -- Récupérer l'id de la source (ajuster selon votre structure)
    SELECT id_source INTO v_source_id 
    FROM metadata.dim_source 
    WHERE cd_source = 'REF_REAL_ESTATE_TRANS' 
    LIMIT 1;

    -- Créer l'entrée dans source_file_history
    INSERT INTO metadata.source_file_history (
        id_file_history,
        id_source,
        tx_filename,
        dt_processed,
        tx_status
    ) VALUES (
        p_batch_id,
        v_source_id,
        'real_estate_transactions.csv',
        v_start_time,
        'RUNNING'
    ) ON CONFLICT (id_file_history) DO UPDATE 
    SET dt_processed = v_start_time,
        tx_status = 'RUNNING';

    -- Supprimer les données existantes si demandé
    IF p_delete_existing THEN
        DELETE FROM clean_staging.clean_real_estate_sector 
        WHERE id_batch = p_batch_id;
    END IF;

    -- Insertion avec nettoyage et validation
    INSERT INTO clean_staging.clean_real_estate_sector (
        cd_year,
        cd_sector,
        cd_refnis,
        cd_type,
        nb_transactions,
        ms_price_p10,
        ms_price_p25,
        ms_price_p50,
        ms_price_p75,
        ms_price_p90,
        fl_confidential,
        fl_valid_sector,
        fl_unknown_sector,
        id_batch
    )
    SELECT 
        r.cd_year,
        r.cd_stat_sector,
        CASE 
            WHEN r.cd_stat_sector ~ '_UNKNOWN$' 
            THEN SUBSTRING(r.cd_stat_sector, 1, 5)
            ELSE SUBSTRING(r.cd_stat_sector, 1, 5)
        END as cd_refnis,
        r.cd_type,
        r.ms_transactions,
        -- Prix (NULL si confidentiel)
        CASE WHEN r.ms_transactions >= p_min_transactions THEN r.ms_p10 END,
        CASE WHEN r.ms_transactions >= p_min_transactions THEN r.ms_p25 END,
        CASE WHEN r.ms_transactions >= p_min_transactions THEN r.ms_p50 END,
        CASE WHEN r.ms_transactions >= p_min_transactions THEN r.ms_p75 END,
        CASE WHEN r.ms_transactions >= p_min_transactions THEN r.ms_p90 END,
        -- Flags
        (r.ms_transactions < p_min_transactions) as fl_confidential,
        EXISTS (
            SELECT 1 
            FROM dw.dim_statistical_sectors s
            WHERE s.cd_sector = r.cd_stat_sector
            AND r.cd_year BETWEEN EXTRACT(YEAR FROM s.dt_start) AND EXTRACT(YEAR FROM s.dt_end)
        ) as fl_valid_sector,
        (r.cd_stat_sector ~ '_UNKNOWN$') as fl_unknown_sector,
        p_batch_id
    FROM raw_staging.raw_real_estate_sector r
    WHERE r.id_batch = p_batch_id;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    -- Enregistrement des problèmes de qualité
    INSERT INTO metadata.data_quality_issues (
        id_batch,
        issue_type,
        issue_description,
        nb_records_affected,
        dt_detected
    )
    SELECT 
        p_batch_id,
        'UNKNOWN_SECTOR',
        'Secteurs de type UNKNOWN',
        COUNT(*),
        CURRENT_TIMESTAMP
    FROM clean_staging.clean_real_estate_sector
    WHERE id_batch = p_batch_id
    AND fl_unknown_sector = TRUE
    HAVING COUNT(*) > 0;

    INSERT INTO metadata.data_quality_issues (
        id_batch,
        issue_type,
        issue_description,
        nb_records_affected,
        dt_detected
    )
    SELECT 
        p_batch_id,
        'INVALID_SECTOR',
        'Secteurs non trouvés dans dim_statistical_sectors',
        COUNT(*),
        CURRENT_TIMESTAMP
    FROM clean_staging.clean_real_estate_sector
    WHERE id_batch = p_batch_id
    AND fl_valid_sector = FALSE
    AND fl_unknown_sector = FALSE
    HAVING COUNT(*) > 0;

    -- Log du succès avec statistiques
    RAISE NOTICE 'Nettoyage terminé avec succès:';
    RAISE NOTICE '- Nombre de lignes chargées: %', v_count;

    PERFORM utils.log_script_execution(
        'load_clean_real_estate_sector', 
        'SUCCESS',
        format('Nettoyage terminé. %s lignes chargées. Durée: %s minutes', 
               v_count,
               EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_start_time))/60)
    );

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'load_clean_real_estate_sector', 
        'ERROR',
        format('Erreur: %s. Durée: %s minutes', 
               SQLERRM,
               EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_start_time))/60)
    );
    RAISE;
END;
$$;

COMMENT ON PROCEDURE clean_staging.load_clean_real_estate_sector IS 
'Procédure de nettoyage et validation des données de transactions immobilières.

Règles appliquées :
1. Seuil de confidentialité : Prix masqués si transactions < 16
2. Validation des secteurs contre dim_statistical_sectors
3. Gestion des secteurs UNKNOWN (NNNNN_UNKNOWN)
4. Extraction du code REFNIS
5. Enregistrement des problèmes de qualité

Arguments :
- p_batch_id : ID du batch à charger
- p_delete_existing : Si TRUE, supprime les données existantes
- p_min_transactions : Seuil de confidentialité (défaut: 16)';