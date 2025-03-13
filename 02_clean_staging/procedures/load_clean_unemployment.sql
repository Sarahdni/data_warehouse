-- 02_clean_staging/procedures/load_clean_unemployment.sql

CREATE OR REPLACE PROCEDURE clean_staging.load_clean_unemployment(
   p_batch_id INTEGER,
   p_delete_existing BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql AS $$
DECLARE
   v_count INTEGER;
   v_start_time TIMESTAMP;
   v_error_msg TEXT;
BEGIN
   -- Log début d'exécution
   v_start_time := CURRENT_TIMESTAMP;
   
   -- Suppression des données existantes si demandé
   IF p_delete_existing THEN
       DELETE FROM clean_staging.clean_unemployment 
       WHERE id_batch = p_batch_id;
   END IF;

   -- Chargement principal avec identification des totaux
   INSERT INTO clean_staging.clean_unemployment (
       id_date,
       id_geography,
       cd_sex,
       cd_age_group,
       cd_education_level,
       ms_unemployment_rate,
       fl_total_sex,
       fl_total_age,
       fl_total_education,
       fl_total_geography,
       cd_measure_type,
       fl_valid,
       id_batch
   )
   SELECT
       -- Référence temporelle
       d.id_date,
       
       -- Référence géographique
        CASE 
           WHEN r.cd_nuts_lvl2 = 'TOTAL' THEN 
               (SELECT id_geography FROM dw.dim_geography WHERE cd_lau = 'BE' AND fl_current = true)
           ELSE g.id_geography 
        END,
       
       -- Démographie
        CASE 
           WHEN r.cd_sex = 'TOTAL' THEN 'A'
           WHEN r.cd_sex = 'MALE' THEN 'M'
           WHEN r.cd_sex = 'FEMALE' THEN 'F'
        END,
       
        CASE 
            WHEN r.cd_empmt_age = 'TOTAL' THEN 'A'
            ELSE r.cd_empmt_age
        END,
       
       -- Pour cd_education_group (utilisation des clés primaires)
        CASE 
            WHEN r.cd_isced_2011 = 'TOTAL' THEN 'TOTAL'
            WHEN r.cd_isced_2011 = '0' THEN '0'
            WHEN r.cd_isced_2011 = '2024-02-01 00:00:00' THEN 'GRP_1-2'
            WHEN r.cd_isced_2011 = '2024-04-03 00:00:00' THEN 'GRP_3-4'
            WHEN r.cd_isced_2011 = '2024-08-05 00:00:00' THEN 'GRP_5-8'
            ELSE NULL
        END,
       
       
        -- Taux de chômage 
        CASE
           WHEN r.ms_value IS NULL OR TRIM(r.ms_value) = '' THEN NULL
           WHEN CAST(r.ms_value AS DECIMAL(10,4)) = 0 THEN NULL
           ELSE CAST(r.ms_value AS DECIMAL(10,4))
        END,
       
       -- Flags des totaux
       r.cd_sex = 'TOTAL',
       r.cd_empmt_age = 'TOTAL',
       r.cd_isced_2011 = 'TOTAL',
       r.cd_nuts_lvl2 = 'TOTAL',
       
       -- Type de mesure
        CASE r.cd_property
            WHEN 'MS_UNEMPMT_RATE' THEN 'NORMAL'
            WHEN 'MS_LT_UNEMPMT_RATE' THEN 'LONG_TERM'   
        END,

        -- Validité
        TRUE,  -- Par défaut, toutes les lignes sont valides
     
       p_batch_id
       
    FROM raw_staging.raw_unemployment r
    JOIN dw.dim_date d ON 
       d.cd_year = CAST(r.cd_year AS INTEGER) 
       AND CASE r.cd_quarter
           WHEN 'TOTAL' THEN d.cd_period_type = 'Y' AND d.cd_quarter IS NULL
           ELSE d.cd_period_type = 'Q' AND d.cd_quarter = CAST(SUBSTRING(r.cd_quarter, 2, 1) AS INTEGER)
       END
    LEFT JOIN dw.dim_geography g ON 
        r.cd_nuts_lvl2 = g.cd_lau
        AND g.fl_current = true
    WHERE r.id_batch = p_batch_id;   
  

   GET DIAGNOSTICS v_count = ROW_COUNT;

   -- Validation des données chargées
   BEGIN
       CALL clean_staging.validate_clean_unemployment(p_batch_id, FALSE);
   EXCEPTION
       WHEN OTHERS THEN
           v_error_msg := SQLERRM;
           -- On continue malgré les erreurs de validation
   END;

   -- Log du résultat
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
       tx_error_message
   ) VALUES (
       (SELECT id_source FROM metadata.dim_source WHERE cd_source = 'LFS_UNEMPL'),
       'raw_unemployment',
       'raw_staging',
       'clean_unemployment',
       'clean_staging',
       (SELECT COUNT(*) FROM raw_staging.raw_unemployment WHERE id_batch = p_batch_id),
       v_count,
       'RAW_TO_CLEAN',
       v_start_time,
       CURRENT_TIMESTAMP,
       CASE 
           WHEN v_error_msg IS NULL THEN 'SUCCESS'
           ELSE 'WARNING'
       END,
       'Transformation complète avec gestion des totaux et groupes d''éducation',
       v_error_msg
   );

   RAISE NOTICE 'Chargement terminé: % lignes chargées', v_count;
   IF v_error_msg IS NOT NULL THEN
       RAISE NOTICE 'Avertissements de validation: %', v_error_msg;
   END IF;

EXCEPTION WHEN OTHERS THEN
   -- Log de l'erreur
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
       tx_error_message
   ) VALUES (
       (SELECT id_source FROM metadata.dim_source WHERE cd_source = 'LFS_UNEMPL'),
       'raw_unemployment',
       'raw_staging',
       'clean_unemployment',
       'clean_staging',
       'RAW_TO_CLEAN',
       v_start_time,
       CURRENT_TIMESTAMP,
       'ERROR',
       SQLERRM
   );
   
   RAISE;
END;
$$;

COMMENT ON PROCEDURE clean_staging.load_clean_unemployment IS 
'Procédure de chargement des données de chômage de raw_staging vers clean_staging:
- Gère les totaux pour le sexe, l''âge et l''éducation
- Traite les groupes d''éducation (1-2, 3-4, 5-8)
- Préserve les descriptions multilingues
- Valide les données chargées';