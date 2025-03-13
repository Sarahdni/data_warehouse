-- Script de création des rôles et permissions
-- À exécuter en tant que superutilisateur

-- Logging de début d'exécution
SELECT utils.log_script_execution('create_roles.sql', 'RUNNING');

-- Script corrigé pour la création des rôles
DO $$
BEGIN
    -- Table de registre des rôles
    CREATE TABLE IF NOT EXISTS metadata.role_registry (
        id_role SERIAL PRIMARY KEY,
        nm_role VARCHAR(50) NOT NULL UNIQUE,
        dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        tx_description TEXT,
        fl_active BOOLEAN NOT NULL DEFAULT TRUE
    );

    -- Création des rôles applicatifs
    -- Rôle ETL
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dw_etl') THEN
        CREATE ROLE dw_etl LOGIN PASSWORD 'hellodata';
        COMMENT ON ROLE dw_etl IS 'Rôle pour les processus ETL';
    END IF;

    -- Insert into role_registry AFTER role creation
    IF NOT EXISTS (SELECT 1 FROM metadata.role_registry WHERE nm_role = 'dw_etl') THEN
        INSERT INTO metadata.role_registry (nm_role, tx_description)
        VALUES ('dw_etl', 'Rôle pour les processus ETL');
    END IF;

    -- Rôle lecture seule
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dw_reader') THEN
        CREATE ROLE dw_reader LOGIN PASSWORD 'hellodata';
        COMMENT ON ROLE dw_reader IS 'Rôle lecture seule pour les analystes';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM metadata.role_registry WHERE nm_role = 'dw_reader') THEN
        INSERT INTO metadata.role_registry (nm_role, tx_description)
        VALUES ('dw_reader', 'Rôle lecture seule pour les analystes');
    END IF;

    -- Rôle développeur
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dw_developer') THEN
        CREATE ROLE dw_developer LOGIN PASSWORD 'hellodata';
        COMMENT ON ROLE dw_developer IS 'Rôle pour les développeurs';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM metadata.role_registry WHERE nm_role = 'dw_developer') THEN
        INSERT INTO metadata.role_registry (nm_role, tx_description)
        VALUES ('dw_developer', 'Rôle pour les développeurs');
    END IF;

    -- Rôle admin
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dw_admin') THEN
        CREATE ROLE dw_admin LOGIN PASSWORD 'hellodata';
        COMMENT ON ROLE dw_admin IS 'Rôle pour les administrateurs';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM metadata.role_registry WHERE nm_role = 'dw_admin') THEN
        INSERT INTO metadata.role_registry (nm_role, tx_description)
        VALUES ('dw_admin', 'Rôle pour les administrateurs');
    END IF;
    
    -- Table de suivi des permissions
    CREATE TABLE IF NOT EXISTS metadata.permission_registry (
        id_permission SERIAL PRIMARY KEY,
        nm_role VARCHAR(50) NOT NULL,
        nm_schema VARCHAR(50) NOT NULL,
        tx_permission_type VARCHAR(50) NOT NULL,
        dt_granted TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        tx_granted_by VARCHAR(100) NOT NULL DEFAULT CURRENT_USER,
        CONSTRAINT fk_role FOREIGN KEY (nm_role) 
            REFERENCES metadata.role_registry(nm_role),
        CONSTRAINT fk_schema FOREIGN KEY (nm_schema) 
            REFERENCES metadata.schema_registry(nm_schema)
    );

    -- Enregistrement des permissions accordées
    INSERT INTO metadata.permission_registry 
        (nm_role, nm_schema, tx_permission_type)
    VALUES 
        ('dw_etl', 'staging', 'ALL'),
        ('dw_etl', 'dw', 'INSERT,UPDATE'),
        ('dw_reader', 'dw', 'SELECT'),
        ('dw_developer', 'staging', 'ALL'),
        ('dw_developer', 'dw', 'ALL'),
        ('dw_developer', 'utils', 'ALL'),
        ('dw_admin', 'staging', 'ALL'),
        ('dw_admin', 'dw', 'ALL'),
        ('dw_admin', 'metadata', 'ALL'),
        ('dw_admin', 'utils', 'ALL')
    ON CONFLICT DO NOTHING;

    -- Logging du succès
    PERFORM utils.log_script_execution('create_roles.sql', 'SUCCESS');

EXCEPTION WHEN OTHERS THEN
    -- Logging de l'erreur
    PERFORM utils.log_script_execution('create_roles.sql', 'ERROR', SQLERRM);
    RAISE;
END $$;

-- Rappel de sécurité
DO $$
BEGIN
    RAISE NOTICE 'SECURITY REMINDER: Remember to change default passwords for all roles!';
END $$;