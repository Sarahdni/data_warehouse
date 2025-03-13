-- Script d'installation des extensions PostgreSQL nécessaires
-- À exécuter en tant que superutilisateur

-- Logging de début d'exécution
SELECT utils.log_script_execution('create_extensions.sql', 'RUNNING');

DO $$
BEGIN
    -- Extension pour la gestion des UUID
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'uuid-ossp') THEN
        CREATE EXTENSION "uuid-ossp";
    END IF;

    -- Extension pour les fonctions mathématiques avancées
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'tablefunc') THEN
        CREATE EXTENSION tablefunc;
    END IF;

    -- Extension pour les opérations sur les dates/heures
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'btree_gist') THEN
        CREATE EXTENSION btree_gist;
    END IF;

    -- Extension pour les recherches textuelles
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'unaccent') THEN
        CREATE EXTENSION unaccent;
    END IF;

    -- Extension pour les analyses statistiques
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'cube') THEN
        CREATE EXTENSION cube;
    END IF;

    -- Extension pour la gestion des langues
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm') THEN
        CREATE EXTENSION pg_trgm;
    END IF;

    -- Extension pour le partitionnement
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_partman') THEN
        -- Note: pg_partman doit être installé séparément
        -- CREATE EXTENSION pg_partman;
        RAISE NOTICE 'pg_partman extension should be installed separately if needed';
    END IF;

    -- Extension qui fournit les types géométriques et les fonctions spatiales nécessaires.
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis') THEN
        CREATE EXTENSION postgis;
    END IF;

    -- Enregistrement des extensions dans le registre des métadonnées
    CREATE TABLE IF NOT EXISTS metadata.extension_registry (
        id_extension SERIAL PRIMARY KEY,
        nm_extension VARCHAR(50) NOT NULL UNIQUE,
        dt_installed TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        tx_version VARCHAR(20) NOT NULL,
        tx_description TEXT
    );

    -- Insertion des extensions installées
    INSERT INTO metadata.extension_registry (nm_extension, tx_version, tx_description)
    SELECT 
        e.extname,
        e.extversion,
        x.comment
    FROM pg_extension e
    JOIN pg_available_extensions x ON e.extname = x.name
    ON CONFLICT (nm_extension) 
    DO UPDATE SET 
        tx_version = EXCLUDED.tx_version,
        dt_installed = CURRENT_TIMESTAMP;

    -- Logging du succès
    PERFORM utils.log_script_execution('create_extensions.sql', 'SUCCESS');

EXCEPTION WHEN OTHERS THEN
    -- Logging de l'erreur
    PERFORM utils.log_script_execution('create_extensions.sql', 'ERROR', SQLERRM);
    RAISE;
END $$;