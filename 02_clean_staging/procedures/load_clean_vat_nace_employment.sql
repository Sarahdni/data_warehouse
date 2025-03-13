-- 02_clean_staging/procedures/load_clean_vat_nace_employment.sql

CREATE OR REPLACE PROCEDURE clean_staging.load_clean_vat_nace_employment(
    p_batch_id INTEGER,
    p_year INTEGER,
    p_delete_existing BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_count INTEGER;
    v_start_time TIMESTAMP;
    v_error_msg TEXT;
    v_foreign_id INTEGER;
BEGIN
    -- Enregistrer le début d'exécution
    v_start_time := CURRENT_TIMESTAMP;
    PERFORM utils.log_script_execution('load_clean_vat_nace_employment', 'RUNNING');

    -- Suppression des données existantes si demandé
    IF p_delete_existing THEN
        DELETE FROM clean_staging.clean_vat_nace_employment 
        WHERE id_batch = p_batch_id;
    END IF;

    -- Chargement avec agrégation et normalisation des données
    INSERT INTO clean_staging.clean_vat_nace_employment (
        cd_economic_activity,
        cd_size_class,
        ms_num_entreprises,
        ms_num_starts,
        ms_num_stops,
        cd_refnis,
        fl_foreign,
        cd_nace_level,
        cd_year,
        id_batch
    )
    SELECT 
        -- Normalisation du code NACE (traiter les codes avec X)
        CASE 
            WHEN r.cd_nace LIKE '%X' THEN 
                SUBSTRING(r.cd_nace, 1, LENGTH(r.cd_nace)-1)
            ELSE r.cd_nace
        END AS cd_economic_activity,
        
        -- Normalisation du code de taille (convertir en format 0-15)
        CASE
            -- Traiter les codes à 2 chiffres (format 00-15)
            WHEN LENGTH(r.cd_nis_stat_unt_cls) = 2 THEN 
                CASE 
                    WHEN r.cd_nis_stat_unt_cls = '00' THEN '0'
                    WHEN r.cd_nis_stat_unt_cls = '01' THEN '1'
                    WHEN r.cd_nis_stat_unt_cls = '02' THEN '2'
                    WHEN r.cd_nis_stat_unt_cls = '03' THEN '3'
                    WHEN r.cd_nis_stat_unt_cls = '04' THEN '4'
                    WHEN r.cd_nis_stat_unt_cls = '05' THEN '5'
                    WHEN r.cd_nis_stat_unt_cls = '06' THEN '6'
                    WHEN r.cd_nis_stat_unt_cls = '07' THEN '7'
                    WHEN r.cd_nis_stat_unt_cls = '08' THEN '8'
                    WHEN r.cd_nis_stat_unt_cls = '09' THEN '9'
                    ELSE r.cd_nis_stat_unt_cls
                END
            -- Les codes à 1 chiffre restent inchangés
            ELSE r.cd_nis_stat_unt_cls
        END AS cd_size_class,
        
        -- Conversion des nombres d'entreprises (ms_num_vat) en entiers
        CAST(NULLIF(REPLACE(r.ms_num_vat, '.0', ''), '') AS INTEGER) AS ms_num_entreprises,
        
        -- Conversion des démarrages (ms_num_vat_start) en entiers
        CAST(NULLIF(REPLACE(r.ms_num_vat_start, '.0', ''), '') AS INTEGER) AS ms_num_starts,
        
        -- Conversion des arrêts (ms_num_vat_stop) en entiers
        CAST(NULLIF(REPLACE(r.ms_num_vat_stop, '.0', ''), '') AS INTEGER) AS ms_num_stops,
        
        -- Code géographique
        COALESCE(r.cd_adm_dstr_refnis, r.cd_refnis) AS cd_refnis,
        
        -- Détection des entreprises étrangères
        CASE 
            WHEN COALESCE(r.cd_adm_dstr_refnis, r.cd_refnis) = '-----' THEN TRUE
            ELSE FALSE
        END AS fl_foreign,
        
        -- Détermination du niveau NACE à partir de la longueur du code
        CASE 
            WHEN r.cd_nace LIKE '%X' THEN 
                -- Pour les codes spéciaux, prendre la longueur sans le X
                CASE LENGTH(SUBSTRING(r.cd_nace, 1, LENGTH(r.cd_nace)-1))
                    WHEN 1 THEN 1  -- Section
                    WHEN 2 THEN 2  -- Division
                    WHEN 3 THEN 3  -- Groupe
                    WHEN 4 THEN 4  -- Classe
                    WHEN 5 THEN 5  -- Sous-classe
                    ELSE 5         -- Par défaut sous-classe
                END
            ELSE 
                -- Pour les codes normaux
                CASE LENGTH(r.cd_nace)
                    WHEN 1 THEN 1  -- Section
                    WHEN 2 THEN 2  -- Division
                    WHEN 3 THEN 3  -- Groupe
                    WHEN 4 THEN 4  -- Classe
                    WHEN 5 THEN 5  -- Sous-classe
                    ELSE 5         -- Par défaut sous-classe
                END
        END AS cd_nace_level,
        
        -- Année des données (passée en paramètre)
        p_year AS cd_year,
        
        -- ID du batch
        p_batch_id AS id_batch
    FROM 
        raw_staging.raw_vat_nace_employment r
    WHERE 
        r.id_batch = p_batch_id
        -- Exclure les codes REFNIS invalides ou non attribués
        AND COALESCE(r.cd_adm_dstr_refnis, r.cd_refnis) != 'XXXXX';

    GET DIAGNOSTICS v_count = ROW_COUNT;
    
    -- Log du succès
    PERFORM utils.log_script_execution(
        'load_clean_vat_nace_employment',
        'SUCCESS',
        format('Chargement terminé. %s lignes traitées pour l''année %s', v_count, p_year)
    );
    
    -- Insertion dans transformation_tracking
    INSERT INTO metadata.transformation_tracking (
        id_source,
        nm_table_source,
        nm_schema_source,
        nm_table_target,
        nm_schema_target,
        nb_rows_source,
        nb_rows_target,
        tx_transformation_type,
        dt_start,
        dt_end,
        cd_status,
        tx_transformation_rules,
        id_batch
    ) VALUES (
        (SELECT id_source FROM metadata.dim_source WHERE cd_source = 'VAT_NACE_EMPL'),
        'raw_vat_nace_employment',
        'raw_staging',
        'clean_vat_nace_employment',
        'clean_staging',
        (SELECT COUNT(*) FROM raw_staging.raw_vat_nace_employment WHERE id_batch = p_batch_id),
        v_count,
        'RAW_TO_CLEAN',
        v_start_time,
        CURRENT_TIMESTAMP,
        'SUCCESS',
        'Agrégation et normalisation des données NACE/TVA avec gestion des formats spéciaux',
        p_batch_id
    );

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    v_error_msg := SQLERRM;
    
    PERFORM utils.log_script_execution(
        'load_clean_vat_nace_employment',
        'ERROR',
        v_error_msg
    );
    
    -- Enregistrement dans transformation_tracking
    INSERT INTO metadata.transformation_tracking (
        id_source,
        nm_table_source,
        nm_schema_source,
        nm_table_target,
        nm_schema_target,
        tx_transformation_type,
        dt_start,
        dt_end,
        cd_status,
        tx_error_message,
        id_batch
    ) VALUES (
        (SELECT id_source FROM metadata.dim_source WHERE cd_source = 'VAT_NACE_EMPL'),
        'raw_vat_nace_employment',
        'raw_staging',
        'clean_vat_nace_employment',
        'clean_staging',
        'RAW_TO_CLEAN',
        v_start_time,
        CURRENT_TIMESTAMP,
        'ERROR',
        v_error_msg,
        p_batch_id
    );
    
    RAISE;
END;
$$;

COMMENT ON PROCEDURE clean_staging.load_clean_vat_nace_employment IS 
'Procédure de chargement des données d''emploi par secteur NACE depuis la table raw_vat_nace_employment.

Arguments:
- p_batch_id : ID du batch à traiter
- p_year : Année des données (à extraire du contexte ou du nom de fichier)
- p_delete_existing : Si TRUE, supprime les données existantes pour ce batch

Transformations effectuées:
- Normalisation des codes NACE (traitement spécial pour les codes se terminant par X)
- Conversion des codes de taille d''entreprise (NIS) en format standard 0-15
- Conversion des nombres d''entreprises et mouvements en valeurs entières
- Détection des entreprises étrangères (code REFNIS = -----)
- Détermination du niveau dans la hiérarchie NACE (1-5)
- Exclusion des codes REFNIS non valides (XXXXX)

Cette procédure gère à la fois les données au format minimal et complet.';