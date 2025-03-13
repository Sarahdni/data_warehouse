-- 03_dim_tables/time/procedures/generate_dim_date.sql

CREATE OR REPLACE FUNCTION dw.generate_dim_date(
    p_start_year INTEGER,
    p_end_year INTEGER
)
RETURNS void AS $$
DECLARE
    month_names_fr TEXT[] := ARRAY['Janvier','Février','Mars','Avril','Mai','Juin',
                                 'Juillet','Août','Septembre','Octobre','Novembre','Décembre'];
    month_names_nl TEXT[] := ARRAY['Januari','Februari','Maart','April','Mei','Juni',
                                 'Juli','Augustus','September','Oktober','November','December'];
    month_names_de TEXT[] := ARRAY['Januar','Februar','März','April','Mai','Juni',
                                 'Juli','August','September','Oktober','November','Dezember'];
    month_names_en TEXT[] := ARRAY['January','February','March','April','May','June',
                                 'July','August','September','October','November','December'];
    month_short_fr TEXT[] := ARRAY['Jan','Fév','Mar','Avr','Mai','Jun',
                                 'Jul','Aoû','Sep','Oct','Nov','Déc'];
    month_short_nl TEXT[] := ARRAY['Jan','Feb','Maa','Apr','Mei','Jun',
                                 'Jul','Aug','Sep','Okt','Nov','Dec'];
    month_short_de TEXT[] := ARRAY['Jan','Feb','Mär','Apr','Mai','Jun',
                                 'Jul','Aug','Sep','Okt','Nov','Dez'];
    month_short_en TEXT[] := ARRAY['Jan','Feb','Mar','Apr','May','Jun',
                                 'Jul','Aug','Sep','Oct','Nov','Dec'];
BEGIN
    -- Validation des paramètres
    IF p_start_year > p_end_year THEN
        RAISE EXCEPTION 'Start year must be less than or equal to end year';
    END IF;

    -- Log du début de la génération
    PERFORM utils.log_script_execution(
        'generate_dim_date',
        'RUNNING',
        format('Generating dates from %s to %s', p_start_year, p_end_year)
    );

    -- Insertion des années
    INSERT INTO dw.dim_date (
        cd_year, cd_period_type,
        tx_period_fr, tx_period_nl, tx_period_de, tx_period_en,
        tx_period_short_fr, tx_period_short_nl, tx_period_short_de, tx_period_short_en
    )
    SELECT
        y, 'Y',
        y::TEXT, y::TEXT, y::TEXT, y::TEXT,
        y::TEXT, y::TEXT, y::TEXT, y::TEXT
    FROM generate_series(p_start_year, p_end_year) y
    ON CONFLICT (cd_year, cd_quarter, cd_month, cd_period_type) DO NOTHING;

    -- Insertion des semestres
    INSERT INTO dw.dim_date (
        cd_year, cd_period_type,
        tx_period_fr, tx_period_nl, tx_period_de, tx_period_en,
        tx_period_short_fr, tx_period_short_nl, tx_period_short_de, tx_period_short_en
    )
    SELECT
        y, 'S',
        'S' || num || ' ' || y::TEXT,  -- S1 2026
        'S' || num || ' ' || y::TEXT,  -- S1 2026
        'S' || num || ' ' || y::TEXT,  -- S1 2026
        'S' || num || ' ' || y::TEXT,  -- S1 2026
        'S' || num,                    -- S1
        'S' || num,                    -- S1
        'S' || num,                    -- S1
        'S' || num                     -- S1
    FROM generate_series(p_start_year, p_end_year) y
    CROSS JOIN (VALUES (1), (2)) AS s(num)
    ON CONFLICT (cd_year, cd_quarter, cd_month, cd_period_type) DO NOTHING;

    -- Insertion des trimestres
    INSERT INTO dw.dim_date (
        cd_year, cd_quarter, cd_period_type,
        tx_period_fr, tx_period_nl, tx_period_de, tx_period_en,
        tx_period_short_fr, tx_period_short_nl, tx_period_short_de, tx_period_short_en
    )
    SELECT
        y, q, 'Q',
        'T' || q || ' ' || y, 'K' || q || ' ' || y, 
        'Q' || q || ' ' || y, 'Q' || q || ' ' || y,
        'T' || q, 'K' || q, 'Q' || q, 'Q' || q
    FROM generate_series(p_start_year, p_end_year) y
    CROSS JOIN generate_series(1, 4) q
    ON CONFLICT (cd_year, cd_quarter, cd_month, cd_period_type) DO NOTHING;

    -- Insertion des mois
    INSERT INTO dw.dim_date (
        cd_year, cd_month, cd_period_type,
        tx_period_fr, tx_period_nl, tx_period_de, tx_period_en,
        tx_period_short_fr, tx_period_short_nl, tx_period_short_de, tx_period_short_en
    )
    SELECT
        y, m, 'M',
        month_names_fr[m] || ' ' || y, month_names_nl[m] || ' ' || y,
        month_names_de[m] || ' ' || y, month_names_en[m] || ' ' || y,
        month_short_fr[m], month_short_nl[m], month_short_de[m], month_short_en[m]
    FROM generate_series(p_start_year, p_end_year) y
    CROSS JOIN generate_series(1, 12) m
    ON CONFLICT (cd_year, cd_quarter, cd_month, cd_period_type) DO NOTHING;

    -- Log du succès
    PERFORM utils.log_script_execution(
        'generate_dim_date',
        'SUCCESS',
        format('Generated dates from %s to %s', p_start_year, p_end_year)
    );

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution(
        'generate_dim_date',
        'ERROR',
        SQLERRM
    );
    RAISE;
END;
$$ LANGUAGE plpgsql;

-- Commentaire sur la fonction
COMMENT ON FUNCTION dw.generate_dim_date(INTEGER, INTEGER) IS 
'Fonction de génération des données pour la dimension temporelle.
Génère les années, trimestres et mois pour la période spécifiée.

Arguments:
- p_start_year: Année de début
- p_end_year: Année de fin

Exemple:
SELECT dw.generate_dim_date(1970, 2030);';

-- Les vues sont maintenant définies dans 04_views/time/v_time_periods.sql