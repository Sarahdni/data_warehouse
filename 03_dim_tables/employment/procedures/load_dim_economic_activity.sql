-- 02_dim_tables/employment/procedures/load_dim_economic_activity.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('load_dim_economic_activity.sql', 'RUNNING');

-- Création de la procédure de chargement
CREATE OR REPLACE PROCEDURE dw.load_dim_economic_activity(
    p_batch_id INTEGER,
    p_effective_date DATE DEFAULT CURRENT_DATE,
    p_raise_exception BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_count_insert INTEGER := 0;
    v_count_update INTEGER := 0;
    v_missing_translations INTEGER;
BEGIN
    -- Vérifier les traductions manquantes
    SELECT COUNT(*)
    INTO v_missing_translations
    FROM staging.stg_ref_nacebel
    WHERE id_batch = p_batch_id
    AND (TX_NACEBEL_EN IS NULL OR TX_NACEBEL_DE IS NULL);

    IF v_missing_translations > 0 THEN
        -- Insérer les traductions manquantes dans la table de suivi
        INSERT INTO metadata.missing_translations (
            id_batch,
            cd_nacebel,
            tx_original_fr,
            missing_languages
        )
        SELECT 
            id_batch,
            CD_NACEBEL,
            TX_NACEBEL_FR,
            ARRAY_REMOVE(ARRAY[
                CASE WHEN TX_NACEBEL_EN IS NULL THEN 'EN' END,
                CASE WHEN TX_NACEBEL_DE IS NULL THEN 'DE' END
            ], NULL)
        FROM staging.stg_ref_nacebel
        WHERE id_batch = p_batch_id
        AND (TX_NACEBEL_EN IS NULL OR TX_NACEBEL_DE IS NULL);

        -- Mettre à jour les traductions manquantes avec un marqueur
        UPDATE staging.stg_ref_nacebel
        SET 
            TX_NACEBEL_EN = CASE 
                WHEN TX_NACEBEL_EN IS NULL THEN '(TO TRANSLATE) ' || TX_NACEBEL_FR
                ELSE TX_NACEBEL_EN
            END,
            TX_NACEBEL_DE = CASE 
                WHEN TX_NACEBEL_DE IS NULL THEN '(ZU ÜBERSETZEN) ' || TX_NACEBEL_FR
                ELSE TX_NACEBEL_DE
            END
        WHERE id_batch = p_batch_id
        AND (TX_NACEBEL_EN IS NULL OR TX_NACEBEL_DE IS NULL);
        
        RAISE NOTICE '% traductions manquantes ont été marquées pour traduction ultérieure', v_missing_translations;
    END IF;

    -- Création d'une table temporaire pour faciliter le chargement hiérarchique
    CREATE TEMP TABLE tmp_economic_activity AS
    SELECT 
        s.CD_NACEBEL as cd_economic_activity,
        s.CD_SUP_NACEBEL as cd_parent_activity,
        s.LVL_NACEBEL as cd_level,
        s.TX_NACEBEL_FR as tx_economic_activity_fr,
        s.TX_NACEBEL_NL as tx_economic_activity_nl,
        s.TX_NACEBEL_DE as tx_economic_activity_de,
        s.TX_NACEBEL_EN as tx_economic_activity_en,
        s.DT_VLDT_START as dt_valid_from,
        s.DT_VLDT_END as dt_valid_to,
        p_batch_id as id_batch
    FROM staging.stg_ref_nacebel s
    WHERE s.id_batch = p_batch_id;

    -- Chargement niveau par niveau pour respecter les dépendances hiérarchiques
    FOR i IN 1..5 LOOP
        -- Désactiver les versions obsolètes
        UPDATE dw.dim_economic_activity d
        SET 
            dt_valid_to = p_effective_date - INTERVAL '1 day',
            fl_current = FALSE
        FROM tmp_economic_activity t
        WHERE t.cd_level = i
        AND d.cd_economic_activity = t.cd_economic_activity
        AND d.fl_current = TRUE;

        GET DIAGNOSTICS v_count_update = ROW_COUNT;

        -- Insérer les nouvelles versions
        INSERT INTO dw.dim_economic_activity (
            cd_economic_activity,
            cd_parent_activity,
            cd_level,
            tx_economic_activity_fr,
            tx_economic_activity_nl,
            tx_economic_activity_de,
            tx_economic_activity_en,
            dt_valid_from,
            dt_valid_to,
            fl_current,
            id_batch
        )
        SELECT 
            t.cd_economic_activity,
            NULLIF(t.cd_parent_activity, '-'),
            t.cd_level,
            t.tx_economic_activity_fr,
            t.tx_economic_activity_nl,
            t.tx_economic_activity_de,
            t.tx_economic_activity_en,
            GREATEST(t.dt_valid_from, p_effective_date),
            t.dt_valid_to,
            TRUE,
            t.id_batch
        FROM tmp_economic_activity t
        WHERE t.cd_level = i;

        GET DIAGNOSTICS v_count_insert = ROW_COUNT;
        
        RAISE NOTICE 'Niveau % : % mises à jour, % insertions', i, v_count_update, v_count_insert;
    END LOOP;

    -- Nettoyage
    DROP TABLE tmp_economic_activity;

    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_dim_economic_activity',
        'SUCCESS',
        format('Chargement terminé. Insertions: %s, Mises à jour: %s, Traductions manquantes: %s', 
               v_count_insert, v_count_update, v_missing_translations)
    );

EXCEPTION WHEN OTHERS THEN
    -- Nettoyage en cas d'erreur
    DROP TABLE IF EXISTS tmp_economic_activity;
    
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'load_dim_economic_activity',
        'ERROR',
        SQLERRM
    );
    
    -- Relancer l'erreur si demandé
    IF p_raise_exception THEN
        RAISE;
    END IF;
END;
$$;

-- Commentaires
COMMENT ON PROCEDURE dw.load_dim_economic_activity(INTEGER, DATE, BOOLEAN) IS 
'Procédure de chargement de la dimension des activités économiques.
Arguments:
- p_batch_id : ID du batch à charger depuis staging
- p_effective_date : Date d''effet des changements (défaut: date du jour)
- p_raise_exception : Si TRUE, lève une exception en cas d''erreur

La procédure gère:
- La détection et le marquage des traductions manquantes
- Le chargement niveau par niveau pour respecter la hiérarchie
- La désactivation des versions obsolètes
- L''insertion des nouvelles versions
- La gestion SCD Type 2 avec dates de validité';

-- Log du succès de la création
SELECT utils.log_script_execution('load_dim_economic_activity.sql', 'SUCCESS');