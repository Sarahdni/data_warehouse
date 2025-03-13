-- 03_fact_tables/real_estate/procedures/load_fact_building_permits_counts.sql

CREATE OR REPLACE PROCEDURE dw.load_fact_building_permits_counts(
    p_batch_id INTEGER,
    p_delete_existing BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_count INTEGER;
BEGIN
    -- Supprimer les données existantes pour ce batch si demandé
    IF p_delete_existing THEN
        DELETE FROM dw.fact_building_permits_counts WHERE id_batch = p_batch_id;
    END IF;

    -- Charger les données résidentielles - nouvelles constructions
    INSERT INTO dw.fact_building_permits_counts (
        id_date, id_geography,
        nb_buildings, nb_dwellings, nb_apartments, nb_houses,
        fl_residential, fl_new_construction,
        id_batch
    )
    SELECT 
        d.id_date,
        g.id_geography,
        COALESCE(s.MS_BUILDING_RES_NEW, 0),
        COALESCE(s.MS_DWELLING_RES_NEW, 0),
        COALESCE(s.MS_APARTMENT_RES_NEW, 0),
        COALESCE(s.MS_SINGLE_HOUSE_RES_NEW, 0),
        TRUE,  -- fl_residential
        TRUE,  -- fl_new_construction
        s.id_batch
    FROM staging.stg_building_permits s
    JOIN dw.dim_date d ON d.cd_year = s.CD_YEAR
        AND (
            (s.CD_PERIOD = 0 AND d.cd_period_type = 'Y') OR  -- Pour le cumul annuel
            (s.CD_PERIOD > 0 AND d.cd_period_type = 'M' AND d.cd_month = s.CD_PERIOD) -- Pour les mois
        )
    JOIN dw.dim_geography g ON g.cd_refnis = s.REFNIS
    WHERE s.id_batch = p_batch_id
    AND (s.MS_BUILDING_RES_NEW > 0 
         OR s.MS_DWELLING_RES_NEW > 0 
         OR s.MS_APARTMENT_RES_NEW > 0 
         OR s.MS_SINGLE_HOUSE_RES_NEW > 0)
    ON CONFLICT (id_date, id_geography, fl_residential, fl_new_construction) 
    DO UPDATE SET
        nb_buildings = fact_building_permits_counts.nb_buildings + EXCLUDED.nb_buildings,
        nb_dwellings = fact_building_permits_counts.nb_dwellings + EXCLUDED.nb_dwellings,
        nb_apartments = fact_building_permits_counts.nb_apartments + EXCLUDED.nb_apartments,
        nb_houses = fact_building_permits_counts.nb_houses + EXCLUDED.nb_houses,
        id_batch = EXCLUDED.id_batch;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '% lignes insérées pour les nouvelles constructions résidentielles', v_count;

    -- Charger les données résidentielles - rénovations
    INSERT INTO dw.fact_building_permits_counts (
        id_date, id_geography,
        nb_buildings, nb_dwellings, nb_apartments, nb_houses,
        fl_residential, fl_new_construction,
        id_batch
    )
    SELECT 
        d.id_date,
        g.id_geography,
        COALESCE(s.MS_BUILDING_RES_RENOVATION, 0),
        0, 0, 0,  -- Pas de détail sur les logements pour les rénovations
        TRUE,  -- fl_residential
        FALSE, -- fl_new_construction
        s.id_batch
    FROM staging.stg_building_permits s
    JOIN dw.dim_date d ON d.cd_year = s.CD_YEAR
        AND (
            (s.CD_PERIOD = 0 AND d.cd_period_type = 'Y') OR  -- Pour le cumul annuel
            (s.CD_PERIOD > 0 AND d.cd_period_type = 'M' AND d.cd_month = s.CD_PERIOD) -- Pour les mois
        )
    JOIN dw.dim_geography g ON g.cd_refnis = s.REFNIS
    WHERE s.id_batch = p_batch_id
    AND s.MS_BUILDING_RES_RENOVATION > 0
    ON CONFLICT (id_date, id_geography, fl_residential, fl_new_construction) 
    DO UPDATE SET
        nb_buildings = fact_building_permits_counts.nb_buildings + EXCLUDED.nb_buildings,
        id_batch = EXCLUDED.id_batch;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '% lignes insérées pour les rénovations résidentielles', v_count;

    -- Charger les données non résidentielles - nouvelles constructions
    INSERT INTO dw.fact_building_permits_counts (
        id_date, id_geography,
        nb_buildings, nb_dwellings, nb_apartments, nb_houses,
        fl_residential, fl_new_construction,
        id_batch
    )
    SELECT 
        d.id_date,
        g.id_geography,
        COALESCE(s.MS_BUILDING_NONRES_NEW, 0),
        0, 0, 0,  -- Pas de logements pour non résidentiel
        FALSE, -- fl_residential
        TRUE,  -- fl_new_construction
        s.id_batch
    FROM staging.stg_building_permits s
    JOIN dw.dim_date d ON d.cd_year = s.CD_YEAR
        AND (
            (s.CD_PERIOD = 0 AND d.cd_period_type = 'Y') OR  -- Pour le cumul annuel
            (s.CD_PERIOD > 0 AND d.cd_period_type = 'M' AND d.cd_month = s.CD_PERIOD) -- Pour les mois
        )
    JOIN dw.dim_geography g ON g.cd_refnis = s.REFNIS
    WHERE s.id_batch = p_batch_id
    AND s.MS_BUILDING_NONRES_NEW > 0
    ON CONFLICT (id_date, id_geography, fl_residential, fl_new_construction) 
    DO UPDATE SET
        nb_buildings = fact_building_permits_counts.nb_buildings + EXCLUDED.nb_buildings,
        id_batch = EXCLUDED.id_batch;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '% lignes insérées pour les nouvelles constructions non résidentielles', v_count;

    -- Charger les données non résidentielles - rénovations
    INSERT INTO dw.fact_building_permits_counts (
        id_date, id_geography,
        nb_buildings, nb_dwellings, nb_apartments, nb_houses,
        fl_residential, fl_new_construction,
        id_batch
    )
    SELECT 
        d.id_date,
        g.id_geography,
        COALESCE(s.MS_BUILDING_NONRES_RENOVATION, 0),
        0, 0, 0,  -- Pas de logements pour non résidentiel
        FALSE, -- fl_residential
        FALSE, -- fl_new_construction
        s.id_batch
    FROM staging.stg_building_permits s
    JOIN dw.dim_date d ON d.cd_year = s.CD_YEAR
        AND (
            (s.CD_PERIOD = 0 AND d.cd_period_type = 'Y') OR  -- Pour le cumul annuel
            (s.CD_PERIOD > 0 AND d.cd_period_type = 'M' AND d.cd_month = s.CD_PERIOD) -- Pour les mois
        )
    JOIN dw.dim_geography g ON g.cd_refnis = s.REFNIS
    WHERE s.id_batch = p_batch_id
    AND s.MS_BUILDING_NONRES_RENOVATION > 0
    ON CONFLICT (id_date, id_geography, fl_residential, fl_new_construction) 
    DO UPDATE SET
        nb_buildings = fact_building_permits_counts.nb_buildings + EXCLUDED.nb_buildings,
        id_batch = EXCLUDED.id_batch;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '% lignes insérées pour les rénovations non résidentielles', v_count;

END;
$$;

COMMENT ON PROCEDURE dw.load_fact_building_permits_counts(INTEGER, BOOLEAN) IS 
'Procédure de chargement des mesures de comptage pour les permis de construire.

Traite quatre types de données :
1. Nouvelles constructions résidentielles (buildings, dwellings, apartments, houses)
2. Rénovations résidentielles (buildings uniquement)
3. Nouvelles constructions non résidentielles (buildings uniquement)
4. Rénovations non résidentielles (buildings uniquement)

Arguments :
- p_batch_id : Identifiant du lot à charger
- p_delete_existing : Si TRUE, supprime les données existantes avant chargement

Caractéristiques :
- Gère les données annuelles (cd_period = 0) et mensuelles (cd_period 1-12)
- Utilise DISTINCT pour éviter les doublons
- Remplace les valeurs NULL par 0 pour toutes les mesures
- Maintient les totaux séparés pour résidentiel/non-résidentiel

Contraintes :
- La table dim_date doit contenir les périodes correspondantes (Y/M)
- La table dim_geography doit contenir les codes REFNIS correspondants';










-- 03_fact_tables/real_estate/procedures/load_fact_building_permits_surface.sql

CREATE OR REPLACE PROCEDURE dw.load_fact_building_permits_surface(
    p_batch_id INTEGER,
    p_delete_existing BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_count INTEGER;
BEGIN
    -- Nettoyage des données existantes si demandé
    IF p_delete_existing THEN
        DELETE FROM dw.fact_building_permits_surface 
        WHERE id_batch = p_batch_id;
    END IF;

    -- Charger les données pour surface résidentielle (nouvelles constructions uniquement)
    INSERT INTO dw.fact_building_permits_surface (
        id_date, 
        id_geography,
        nb_surface_m2,
        fl_residential, 
        fl_new_construction,
        id_batch
    )
    SELECT DISTINCT
        d.id_date,
        g.id_geography,
        COALESCE(s.MS_TOTAL_SURFACE_RES_NEW, 0),
        TRUE,  -- fl_residential
        TRUE,  -- fl_new_construction
        s.id_batch
    FROM staging.stg_building_permits s
    JOIN dw.dim_date d ON d.cd_year = s.CD_YEAR
        AND (
            (s.CD_PERIOD = 0 AND d.cd_period_type = 'Y') OR  
            (s.CD_PERIOD > 0 AND d.cd_period_type = 'M' AND d.cd_month = s.CD_PERIOD)
        )
    JOIN dw.dim_geography g ON g.cd_refnis = s.REFNIS
    WHERE s.id_batch = p_batch_id
      AND s.MS_TOTAL_SURFACE_RES_NEW > 0
    ON CONFLICT (id_date, id_geography) 
    DO UPDATE SET
        nb_surface_m2 = fact_building_permits_surface.nb_surface_m2 + EXCLUDED.nb_surface_m2,
        id_batch = EXCLUDED.id_batch;    

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '% lignes insérées pour les mesures de surface résidentielle', v_count;
END;
$$;

COMMENT ON PROCEDURE dw.load_fact_building_permits_surface IS 
'Procédure de chargement des mesures de surface pour les bâtiments résidentiels.

Arguments :
- p_batch_id : Identifiant du lot à charger
- p_delete_existing : Si TRUE, supprime les données existantes avant chargement

Caractéristiques :
- Gère les données annuelles (cd_period = 0) et mensuelles (cd_period 1-12)
- Ne traite que les nouvelles constructions (fl_new_construction = TRUE)
- Ne charge que les données avec une surface positive
- Gère la mise à jour cumulative des surfaces

Contraintes :
- La table dim_date doit contenir les périodes correspondantes (Y/M)
- La table dim_geography doit contenir les codes REFNIS correspondants';
















-- 03_fact_tables/real_estate/procedures/load_fact_building_permits_volume.sql

CREATE OR REPLACE PROCEDURE dw.load_fact_building_permits_volume(
    p_batch_id INTEGER,
    p_delete_existing BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_count INTEGER;
BEGIN
    -- Nettoyage des données existantes si demandé
    IF p_delete_existing THEN
        DELETE FROM dw.fact_building_permits_volume 
        WHERE id_batch = p_batch_id;
    END IF;

    -- Charger les données pour volume non-résidentiel (nouvelles constructions uniquement)
    INSERT INTO dw.fact_building_permits_volume (
        id_date, 
        id_geography,
        nb_volume_m3,
        fl_residential, 
        fl_new_construction,
        id_batch
    )
    SELECT DISTINCT
        d.id_date,
        g.id_geography,
        COALESCE(s.MS_VOLUME_NONRES_NEW, 0),
        FALSE,  -- fl_residential
        TRUE,   -- fl_new_construction
        s.id_batch
    FROM staging.stg_building_permits s
    JOIN dw.dim_date d ON d.cd_year = s.CD_YEAR
        AND (
            (s.CD_PERIOD = 0 AND d.cd_period_type = 'Y') OR  
            (s.CD_PERIOD > 0 AND d.cd_period_type = 'M' AND d.cd_month = s.CD_PERIOD)
        )
    JOIN dw.dim_geography g ON g.cd_refnis = s.REFNIS
    WHERE s.id_batch = p_batch_id
      AND s.MS_VOLUME_NONRES_NEW > 0
    ON CONFLICT (id_date, id_geography) 
    DO UPDATE SET
        nb_volume_m3 = fact_building_permits_volume.nb_volume_m3 + EXCLUDED.nb_volume_m3,
        id_batch = EXCLUDED.id_batch;    

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '% lignes insérées pour les mesures de volume non résidentiel', v_count;
END;
$$;

COMMENT ON PROCEDURE dw.load_fact_building_permits_volume IS 
'Procédure de chargement des mesures de volume pour les bâtiments non résidentiels.

Arguments :
- p_batch_id : Identifiant du lot à charger
- p_delete_existing : Si TRUE, supprime les données existantes avant chargement

Caractéristiques :
- Gère les données annuelles (cd_period = 0) et mensuelles (cd_period 1-12)
- Ne traite que les nouvelles constructions (fl_new_construction = TRUE)
- Ne charge que les données avec un volume positif
- Gère la mise à jour cumulative des volumes

Contraintes :
- La table dim_date doit contenir les périodes correspondantes (Y/M)
- La table dim_geography doit contenir les codes REFNIS correspondants';















-- Procédure principale
CREATE OR REPLACE PROCEDURE dw.load_fact_building_permits(
    p_batch_id INTEGER,
    p_delete_existing BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_start_time TIMESTAMP;
BEGIN
    -- Enregistrer le début de l'exécution
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Log du début
    PERFORM utils.log_script_execution('load_fact_building_permits', 'RUNNING');

    -- Exécution dans une transaction
    BEGIN
        -- Charger les comptages
        RAISE NOTICE 'Début du chargement des comptages...';
        CALL dw.load_fact_building_permits_counts(p_batch_id, p_delete_existing);

        -- Charger les surfaces
        RAISE NOTICE 'Début du chargement des surfaces...';
        CALL dw.load_fact_building_permits_surface(p_batch_id, p_delete_existing);

        -- Charger les volumes
        RAISE NOTICE 'Début du chargement des volumes...';
        CALL dw.load_fact_building_permits_volume(p_batch_id, p_delete_existing);

        -- Log du succès
        PERFORM utils.log_script_execution(
            'load_fact_building_permits', 
            'SUCCESS',
            format('Chargement terminé en %s minutes', 
                   EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_start_time))/60)
        );

    EXCEPTION WHEN OTHERS THEN
        -- Log de l'erreur
        PERFORM utils.log_script_execution(
            'load_fact_building_permits', 
            'ERROR', 
            format('Erreur: %s. Durée: %s minutes', 
                   SQLERRM, 
                   EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_start_time))/60)
        );
        RAISE;
    END;
END;
$$;


COMMENT ON PROCEDURE dw.load_fact_building_permits IS 
'Procédure principale orchestrant le chargement de toutes les mesures de permis de construire.

Arguments :
- p_batch_id : Identifiant du lot à charger
- p_delete_existing : Si TRUE, supprime les données existantes avant chargement

Fonctionnement :
1. Chargement des comptages (buildings, logements, etc.)
2. Chargement des surfaces (m²)
3. Chargement des volumes (m³)

Caractéristiques :
- Exécution dans une transaction unique (tout ou rien)
- Logging détaillé avec temps d''exécution
- Gestion des erreurs avec rollback automatique
- Utilise utils.log_script_execution pour le suivi

Prérequis :
- Les tables de dimensions doivent être chargées
- Les données doivent être présentes en staging';