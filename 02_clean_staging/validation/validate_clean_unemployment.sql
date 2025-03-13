-- 02_clean_staging/validation/validate_clean_unemployment.sql

CREATE OR REPLACE PROCEDURE clean_staging.validate_clean_unemployment(
   p_batch_id INTEGER,
   p_raise_exception BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
   v_error_count INTEGER := 0;
   v_total_records INTEGER;
   v_start_time TIMESTAMP;
   v_data_quality_issue RECORD;
BEGIN
   v_start_time := CURRENT_TIMESTAMP;
   
   -- Compte total des enregistrements pour ce batch
   SELECT COUNT(*) INTO v_total_records 
   FROM clean_staging.clean_unemployment 
   WHERE id_batch = p_batch_id;

   -- 1. Validation des données manquantes obligatoires
   INSERT INTO metadata.data_quality_issues (
       id_batch,
       issue_type,
       issue_description,
       nb_records_affected,
       dt_detected
   )
   SELECT 
       p_batch_id,
       'MISSING_REQUIRED',
       'Données obligatoires manquantes',
       COUNT(*),
       CURRENT_TIMESTAMP
   FROM clean_staging.clean_unemployment
   WHERE id_batch = p_batch_id
   AND (
       id_date IS NULL OR
       id_geography IS NULL OR
       cd_measure_type IS NULL OR
       (NOT fl_total_sex AND cd_sex IS NULL) OR
       (NOT fl_total_age AND cd_age_group IS NULL) OR
       (NOT fl_total_education AND cd_education_level IS NULL)
   );

   -- 2. Validation de la cohérence des flags de totaux
   INSERT INTO metadata.data_quality_issues (
       id_batch,
       issue_type,
       issue_description,
       nb_records_affected,
       dt_detected
   )
   SELECT 
       p_batch_id,
       'INCONSISTENT_TOTALS',
       'Incohérence entre les flags de totaux et les valeurs',
       COUNT(*),
       CURRENT_TIMESTAMP
   FROM clean_staging.clean_unemployment
   WHERE id_batch = p_batch_id
   AND (
       (fl_total_sex AND cd_sex != 'A') OR
       (fl_total_age AND cd_age_group != 'A') OR
       (fl_total_education AND cd_education_level != 'TOTAL') OR
       (NOT fl_total_sex AND cd_sex = 'A') OR
       (NOT fl_total_age AND cd_age_group = 'A') OR
       (NOT fl_total_education AND cd_education_level = 'TOTAL')
   );

   -- 3. Validation des valeurs des taux de chômage
   INSERT INTO metadata.data_quality_issues (
       id_batch,
       issue_type,
       issue_description,
       nb_records_affected,
       dt_detected
   )
   SELECT 
       p_batch_id,
       'INVALID_RATES',
       'Taux de chômage invalides (négatifs ou supérieurs à 1)',
       COUNT(*),
       CURRENT_TIMESTAMP
   FROM clean_staging.clean_unemployment
   WHERE id_batch = p_batch_id
   AND (
       ms_unemployment_rate < 0 OR 
       ms_unemployment_rate > 1
   );

   -- 4. Validation de la cohérence des groupes d'éducation
   INSERT INTO metadata.data_quality_issues (
       id_batch,
       issue_type,
       issue_description,
       nb_records_affected,
       dt_detected
   )
   SELECT 
       p_batch_id,
       'INVALID_EDUCATION_LEVEL',
       'Niveau d''éducation invalide',
       COUNT(*),
       CURRENT_TIMESTAMP
   FROM clean_staging.clean_unemployment
   WHERE id_batch = p_batch_id
   AND cd_education_level NOT IN (
       '0', 'GRP_1-2', 'GRP_3-4', 'GRP_5-8', 'TOTAL'
   )
   AND cd_education_level IS NOT NULL;

   -- 5. Validation des valeurs aberrantes pour les taux de chômage
   INSERT INTO metadata.data_quality_issues (
       id_batch,
       issue_type,
       issue_description,
       nb_records_affected,
       dt_detected
   )
   SELECT 
       p_batch_id,
       'OUTLIER_RATES',
       'Taux de chômage suspects (variation importante)',
       COUNT(*),
       CURRENT_TIMESTAMP
   FROM (
       SELECT 
           c1.*,
           AVG(ms_unemployment_rate) OVER (
               PARTITION BY id_geography, cd_sex, cd_age_group
               ORDER BY id_date 
               ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING
           ) as avg_rate
       FROM clean_staging.clean_unemployment c1
       WHERE id_batch = p_batch_id
   ) subq
   WHERE ABS(ms_unemployment_rate - avg_rate) > 0.1
   AND NOT (fl_total_sex OR fl_total_age OR fl_total_education OR fl_total_geography);

   -- 6. Validation de la cohérence temporelle des mesures
   INSERT INTO metadata.data_quality_issues (
       id_batch,
       issue_type,
       issue_description,
       nb_records_affected,
       dt_detected
   )
   SELECT 
       p_batch_id,
       'TEMPORAL_INCONSISTENCY',
       'Variations temporelles suspectes',
       COUNT(*),
       CURRENT_TIMESTAMP
   FROM clean_staging.clean_unemployment c1
   JOIN dw.dim_date d ON c1.id_date = d.id_date
   WHERE c1.id_batch = p_batch_id
   AND EXISTS (
       SELECT 1 
       FROM clean_staging.clean_unemployment c2
       JOIN dw.dim_date d2 ON c2.id_date = d2.id_date
       WHERE c2.id_geography = c1.id_geography
       AND c2.cd_sex = c1.cd_sex
       AND c2.cd_age_group = c1.cd_age_group
       AND c2.cd_education_level = c1.cd_education_level
       AND d2.cd_year = d.cd_year - 1
       AND ABS(c1.ms_unemployment_rate - c2.ms_unemployment_rate) > 0.2
   );

   -- Récupération du nombre total d'erreurs
   SELECT COUNT(*) INTO v_error_count
   FROM metadata.data_quality_issues
   WHERE id_batch = p_batch_id
   AND dt_detected > v_start_time;

   -- Log des résultats dans transformation_tracking
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
       (SELECT id_source FROM metadata.dim_source WHERE cd_source = 'LFS_UNEMPL'),
       'raw_unemployment',
       'raw_staging',
       'clean_unemployment',
       'clean_staging',
       v_total_records,
       v_total_records,
       'RAW_TO_CLEAN',
       v_start_time,
       CURRENT_TIMESTAMP,
       CASE WHEN v_error_count = 0 THEN 'SUCCESS' ELSE 'WARNING' END,
       format('Validation complète avec %s problèmes détectés sur %s enregistrements', 
              v_error_count, v_total_records),
       p_batch_id
   );

   -- Affichage des résultats
   FOR v_data_quality_issue IN 
       SELECT issue_type, issue_description, nb_records_affected 
       FROM metadata.data_quality_issues 
       WHERE id_batch = p_batch_id 
       AND dt_detected > v_start_time
       ORDER BY nb_records_affected DESC
   LOOP
       RAISE NOTICE '% - % (% enregistrements)', 
           v_data_quality_issue.issue_type, 
           v_data_quality_issue.issue_description, 
           v_data_quality_issue.nb_records_affected;
   END LOOP;

   IF p_raise_exception AND v_error_count > 0 THEN
       RAISE EXCEPTION 'Validation échouée avec % erreurs sur % enregistrements', 
           v_error_count, v_total_records;
   END IF;

EXCEPTION WHEN OTHERS THEN
    -- En cas d'erreur, on log et on relève si demandé
    RAISE NOTICE 'Erreur lors de la validation: %', SQLERRM;
    IF p_raise_exception THEN
        RAISE;
    END IF;
END;
$$;

COMMENT ON PROCEDURE clean_staging.validate_clean_unemployment IS 
'Procédure de validation complète des données de chômage nettoyées avec:
1. Vérification des données obligatoires
2. Validation de la cohérence des flags de totaux
3. Validation des taux de chômage
4. Vérification des niveaux d''éducation
5. Détection des valeurs aberrantes
6. Validation de la cohérence temporelle
Les résultats sont enregistrés dans metadata.data_quality_issues.';