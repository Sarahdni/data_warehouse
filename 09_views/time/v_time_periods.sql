-- 04_views/time/v_time_periods.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_time_views.sql', 'RUNNING');

DO $$ 
BEGIN 
    -- Vue des périodes courantes
    CREATE OR REPLACE VIEW dw.v_current_periods AS
    SELECT 
        id_date,
        cd_year,
        cd_quarter,
        cd_month,
        cd_period_type,
        tx_period_fr,
        tx_period_nl,
        tx_period_de,
        tx_period_en
    FROM dw.v_dim_date_current 
    WHERE fl_current_period = TRUE;

    COMMENT ON VIEW dw.v_current_periods IS 'Périodes courantes (année, trimestre, mois en cours)';

    -- Vue des années
    CREATE OR REPLACE VIEW dw.v_years AS
    SELECT 
        id_date,
        cd_year,
        tx_period_fr AS tx_year_fr,
        tx_period_nl AS tx_year_nl,
        tx_period_de AS tx_year_de,
        tx_period_en AS tx_year_en
    FROM dw.dim_date 
    WHERE cd_period_type = 'Y' 
    ORDER BY cd_year;

    COMMENT ON VIEW dw.v_years IS 'Liste des années disponibles';

    -- Vue des trimestres
    CREATE OR REPLACE VIEW dw.v_quarters AS
    SELECT 
        id_date,
        cd_year,
        cd_quarter,
        tx_period_fr,
        tx_period_nl,
        tx_period_de,
        tx_period_en,
        tx_period_short_fr,
        tx_period_short_nl,
        tx_period_short_de,
        tx_period_short_en
    FROM dw.dim_date 
    WHERE cd_period_type = 'Q' 
    ORDER BY cd_year, cd_quarter;

    COMMENT ON VIEW dw.v_quarters IS 'Liste des trimestres avec leurs libellés';

    -- Vue des mois
    CREATE OR REPLACE VIEW dw.v_months AS
    SELECT 
        id_date,
        cd_year,
        cd_month,
        tx_period_fr,
        tx_period_nl,
        tx_period_de,
        tx_period_en,
        tx_period_short_fr,
        tx_period_short_nl,
        tx_period_short_de,
        tx_period_short_en
    FROM dw.dim_date 
    WHERE cd_period_type = 'M' 
    ORDER BY cd_year, cd_month;

    COMMENT ON VIEW dw.v_months IS 'Liste des mois avec leurs libellés';

    -- Enregistrement des vues dans le registre
    INSERT INTO metadata.table_registry (nm_schema, nm_table, tx_description, cd_source)
    VALUES 
        ('dw', 'v_current_periods', 'Périodes temporelles courantes', 'SYSTEM'),
        ('dw', 'v_years', 'Liste des années', 'SYSTEM'),
        ('dw', 'v_quarters', 'Liste des trimestres', 'SYSTEM'),
        ('dw', 'v_months', 'Liste des mois', 'SYSTEM')
    ON CONFLICT (nm_schema, nm_table) DO NOTHING;

    -- Log du succès
    PERFORM utils.log_script_execution('create_time_views.sql', 'SUCCESS');

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution('create_time_views.sql', 'ERROR', SQLERRM);
    RAISE;
END $$;