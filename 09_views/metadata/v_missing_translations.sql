-- 04_views/metadata/v_missing_translations.sql
CREATE OR REPLACE VIEW metadata.v_missing_translations AS
SELECT 
    mt.id_batch,
    mt.cd_nacebel,
    mt.tx_original_fr,
    mt.missing_languages,
    mt.fl_processed,
    mt.dt_created,
    mt.dt_processed,
    sfh.tx_filename AS source_filename,
    sfh.dt_processed AS batch_processed_date
FROM metadata.missing_translations mt
JOIN metadata.source_file_history sfh ON mt.id_batch = sfh.id_file_history
ORDER BY mt.dt_created DESC;

COMMENT ON VIEW metadata.v_missing_translations IS 'Vue de suivi des traductions manquantes';