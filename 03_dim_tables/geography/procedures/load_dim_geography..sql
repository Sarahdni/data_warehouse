
CREATE OR REPLACE PROCEDURE dw.load_dim_geography(
    p_batch_id INTEGER,
    p_effective_date DATE DEFAULT CURRENT_DATE,
    p_raise_exception BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_count_insert INTEGER := 0;
BEGIN
    -- On n'insère que les données qui ont passé la validation
    INSERT INTO dw.dim_geography (
        cd_lau,
        cd_refnis,
        tx_name_fr,
        tx_name_nl,
        tx_name_de,
        tx_name_en,
        cd_level,
        cd_parent,
        dt_start,
        dt_end,
        fl_current,
        id_batch
    )
    SELECT DISTINCT ON (s.cd_lau, s.dt_vldt_strt)
        s.cd_lau,
        NULLIF(s.cd_munty_refnis, '-'),
        CASE 
            WHEN s.cd_lau = 'BE10' THEN 'Zone administrative de Bruxelles-Capitale'
            ELSE COALESCE(s.tx_descr_fr, s.tx_descr_en, s.tx_descr_nl, s.tx_descr_de, 'Non défini')
        END,
        CASE 
            WHEN s.cd_lau = 'BE10' THEN 'Administratieve zone van Brussel-Hoofdstad'
            ELSE COALESCE(s.tx_descr_nl, s.tx_descr_en, s.tx_descr_fr, s.tx_descr_de, 'Niet gedefinieerd')
        END,
        s.tx_descr_de,
        s.tx_descr_en,
        s.cd_lvl,
        NULLIF(s.cd_lvl_sup, '-'),
        s.dt_vldt_strt,
        s.dt_vldt_stop,
        s.dt_vldt_stop = '9999-12-31'::date,
        p_batch_id
    FROM staging.stg_ref_nuts_lau s
    WHERE s.id_batch = p_batch_id
    AND NOT EXISTS (
        SELECT 1 
        FROM dw.dim_geography d 
        WHERE d.cd_lau = s.cd_lau 
        AND d.dt_start = s.dt_vldt_strt
    )
    ORDER BY s.cd_lau, s.dt_vldt_strt;

    GET DIAGNOSTICS v_count_insert = ROW_COUNT;
    RAISE NOTICE 'Inserted % rows', v_count_insert;
END;
$$;

COMMENT ON PROCEDURE dw.load_dim_geography(INTEGER, DATE, BOOLEAN) IS 
'Procédure de chargement de la dimension géographique.
Arguments:
- p_batch_id : ID du batch à charger depuis staging
- p_effective_date : Date d''effet des changements (défaut: date du jour)
- p_raise_exception : Si TRUE, lève une exception en cas d''erreur';