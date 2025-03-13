-- 03_dim_tables/geography/procedures/load_dim_statistical_sectors.sql

CREATE OR REPLACE PROCEDURE dw.load_dim_statistical_sectors(
    p_batch_id INTEGER,
    p_year INTEGER,
    p_is_historical_batch BOOLEAN DEFAULT FALSE

)
LANGUAGE plpgsql AS $$
DECLARE
    v_start_date DATE;
    v_end_date DATE;
    v_source_code VARCHAR(50);
    v_rows_processed INTEGER;
BEGIN
    -- Récupérer le code source
    SELECT cd_source INTO v_source_code
    FROM metadata.dim_source s
    JOIN metadata.source_file_history h ON h.id_source = s.id_source
    WHERE h.id_file_history = p_batch_id;

    -- Déterminer les dates de validité
    IF v_source_code = 'STATBEL_SECTORS_2011_2017' THEN
        -- Pour le batch historique
        v_start_date := '2011-01-01'::DATE;
        v_end_date := '2017-12-31'::DATE;
        
        -- Vérifier que l'année est dans la plage
        IF p_year < 2011 OR p_year > 2017 THEN
            RAISE EXCEPTION 'L''année % n''est pas dans la plage 2011-2017', p_year;
        END IF;
    ELSE
        -- Pour les données annuelles
        v_start_date := make_date(p_year, 1, 1);
        v_end_date := make_date(p_year, 12, 31);
    END IF;
    
    -- Insérer les données
    INSERT INTO dw.dim_statistical_sectors (
        cd_sector,
        dt_start,
        dt_end,
        cd_refnis,
        cd_sub_munty,
        cd_dstr_refnis,
        cd_prov_refnis,
        cd_rgn_refnis,
        cd_nuts1,
        cd_nuts2,
        cd_nuts3,
        tx_sector_fr,
        tx_sector_nl,
        tx_sector_de,
        tx_sector_en,
        tx_sub_munty_fr,
        tx_sub_munty_nl,
        tx_sub_munty_de,
        tx_sub_munty_en,
        geom_31370,
        centroid_31370,
        ms_area_ha,
        ms_perimeter_m,
        id_batch
    )
    SELECT 
        cd_sector,
        v_start_date,
        v_end_date,
        cd_refnis,
        cd_sub_munty,
        cd_dstr_refnis,
        cd_prov_refnis,
        cd_rgn_refnis,
        cd_nuts_lv1,
        cd_nuts_lv2,
        cd_nuts_lv3,
        tx_sector_descr_fr,
        tx_sector_descr_nl,
        tx_sector_descr_de,
        tx_sector_descr_en,
        tx_sub_munty_fr,
        tx_sub_munty_nl,
        tx_sub_munty_de,
        tx_sub_munty_en,
        geom_31370,
        centroid,
        ms_area_ha,
        ms_perimeter_m,
        p_batch_id
    FROM clean_staging.clean_statistical_sectors
    WHERE id_batch = p_batch_id;

    GET DIAGNOSTICS v_rows_processed = ROW_COUNT;
    
    RAISE NOTICE 'Chargement terminé. % secteurs chargés pour la période du % au %', 
        v_rows_processed, v_start_date, v_end_date;

END;
$$;

COMMENT ON PROCEDURE dw.load_dim_statistical_sectors(INTEGER, INTEGER, BOOLEAN) IS 
'Procédure de chargement de la dimension des secteurs statistiques.

Paramètres :
- p_batch_id : ID du batch à charger depuis la table de staging 
- p_year : Année des données à charger
- p_is_historical_batch : Indique si c''est un batch historique 2011-2017 (défaut : FALSE)

Étapes : 
1. Récupère le code source du batch
2. Détermine les dates de début et de fin de validité :
   - Fixes pour le batch historique 2011-2017
   - Calculées à partir de l''année pour les données annuelles
3. Insère les données de la table de staging dans la dimension
4. Affiche le nombre de secteurs chargés et la période de validité

Exemple d''utilisation :
CALL dw.load_dim_statistical_sectors(64, 2017, TRUE);
CALL dw.load_dim_statistical_sectors(68, 2018);';
 
    