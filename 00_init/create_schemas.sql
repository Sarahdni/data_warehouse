-- 00_init/create_schemas.sql


-- 1. Création des schémas
CREATE SCHEMA IF NOT EXISTS raw_staging;
CREATE SCHEMA IF NOT EXISTS clean_staging;
CREATE SCHEMA IF NOT EXISTS dw;
CREATE SCHEMA IF NOT EXISTS metadata;
CREATE SCHEMA IF NOT EXISTS utils;

-- Commentaires sur les schémas
COMMENT ON SCHEMA raw_staging IS 'Schéma contenant les tables de staging brutes, sans transformation';
COMMENT ON SCHEMA clean_staging IS 'Schéma contenant les tables de staging nettoyées et validées';
COMMENT ON SCHEMA dw IS 'Schéma contenant les tables dimensionnelles et de faits';
COMMENT ON SCHEMA metadata IS 'Schéma contenant les tables de métadonnées et de configuration';
COMMENT ON SCHEMA utils IS 'Schéma contenant les fonctions et procédures utilitaires';

-- 2. Table de registre des tables
CREATE TABLE IF NOT EXISTS metadata.table_registry (
    id_table SERIAL PRIMARY KEY,
    nm_schema VARCHAR(50) NOT NULL,
    nm_table VARCHAR(100) NOT NULL,
    tx_description TEXT,
    cd_source VARCHAR(50),
    fl_view BOOLEAN DEFAULT FALSE,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_last_modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_table_name UNIQUE(nm_schema, nm_table)
);

-- 3. Table de contrôle des versions
CREATE TABLE IF NOT EXISTS metadata.version_control (
    id_version SERIAL PRIMARY KEY,
    cd_version VARCHAR(20) NOT NULL,
    dt_installation TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_validation TIMESTAMP,
    tx_comments TEXT,
    tx_installed_by VARCHAR(100) NOT NULL DEFAULT CURRENT_USER
);

-- 4. Table de suivi des schémas
CREATE TABLE IF NOT EXISTS metadata.schema_registry (
    id_schema SERIAL PRIMARY KEY,
    nm_schema VARCHAR(50) NOT NULL UNIQUE,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tx_description TEXT,
    fl_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_schema_name CHECK (nm_schema ~ '^[a-z][a-z0-9_]*$')
);

-- 5. Table de suivi des exécutions de scripts
CREATE TABLE IF NOT EXISTS metadata.script_execution_log (
    id_execution SERIAL PRIMARY KEY,
    nm_script VARCHAR(200) NOT NULL,
    dt_start TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_end TIMESTAMP,
    cd_status VARCHAR(20) NOT NULL DEFAULT 'RUNNING',
    tx_error_message TEXT,
    tx_executed_by VARCHAR(100) NOT NULL DEFAULT CURRENT_USER,
    CONSTRAINT chk_status CHECK (cd_status IN ('RUNNING', 'SUCCESS', 'ERROR'))
);

-- 6. Table de suivi des transformations
CREATE TABLE IF NOT EXISTS metadata.transformation_tracking (
    id_transformation SERIAL PRIMARY KEY,
    id_source INTEGER REFERENCES metadata.dim_source(id_source),
    nm_table_source VARCHAR(100) NOT NULL,
    nm_schema_source VARCHAR(50) NOT NULL,
    nm_table_target VARCHAR(100) NOT NULL,
    nm_schema_target VARCHAR(50) NOT NULL,
    nb_rows_source INTEGER,
    nb_rows_target INTEGER,
    tx_transformation_type VARCHAR(50) NOT NULL,
    tx_transformation_rules TEXT,
    dt_start TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_end TIMESTAMP,
    cd_status VARCHAR(20) DEFAULT 'RUNNING',
    tx_error_message TEXT,
    
    CONSTRAINT chk_transformation_type CHECK (
        tx_transformation_type IN (
            'RAW_TO_CLEAN',    -- De raw_staging vers clean_staging
            'CLEAN_TO_DW',     -- De clean_staging vers dw
            'REFRESH_DIM',     -- Rafraîchissement d'une dimension
            'REFRESH_FACT'     -- Rafraîchissement d'une table de faits
        )
    ),
    CONSTRAINT chk_transformation_status CHECK (
        cd_status IN ('RUNNING', 'SUCCESS', 'ERROR', 'WARNING')
    )
);

-- Index pour les recherches fréquentes sur la table de transformation
CREATE INDEX IF NOT EXISTS idx_transformation_date 
ON metadata.transformation_tracking(dt_start);

CREATE INDEX IF NOT EXISTS idx_transformation_status 
ON metadata.transformation_tracking(cd_status);

-- 7. Fonction pour la mise à jour automatique de dt_last_modified
CREATE OR REPLACE FUNCTION metadata.update_modified_column()
RETURNS TRIGGER AS 
$BODY$
BEGIN
    NEW.dt_last_modified = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;

-- 8. Trigger pour table_registry
DROP TRIGGER IF EXISTS tr_update_tableregistry_timestamp ON metadata.table_registry;

CREATE TRIGGER tr_update_tableregistry_timestamp
    BEFORE UPDATE ON metadata.table_registry
    FOR EACH ROW
    EXECUTE FUNCTION metadata.update_modified_column();

-- 9. Fonction utilitaire pour logger l'exécution des scripts
CREATE OR REPLACE FUNCTION utils.log_script_execution(
    p_script_name VARCHAR(200),
    p_status VARCHAR(20),
    p_error_message TEXT DEFAULT NULL
)
RETURNS void AS 
$BODY$
BEGIN
    IF p_status = 'RUNNING' THEN
        INSERT INTO metadata.script_execution_log (nm_script, cd_status)
        VALUES (p_script_name, p_status);
    ELSE
        UPDATE metadata.script_execution_log
        SET dt_end = CURRENT_TIMESTAMP,
            cd_status = p_status,
            tx_error_message = p_error_message
        WHERE nm_script = p_script_name
          AND dt_end IS NULL;
    END IF;
END;
$BODY$
LANGUAGE plpgsql;

-- 10. Insertion des schémas dans le registre
INSERT INTO metadata.schema_registry (nm_schema, tx_description)
VALUES 
    ('raw_staging', 'Schéma pour les tables de staging brutes'),
    ('clean_staging', 'Schéma pour les tables de staging nettoyées'),
    ('dw', 'Schéma pour l''entrepôt de données'),
    ('metadata', 'Schéma pour les métadonnées'),
    ('utils', 'Schéma pour les utilitaires')
ON CONFLICT (nm_schema) DO UPDATE 
SET tx_description = EXCLUDED.tx_description;

-- 11. Commentaires sur les tables
COMMENT ON TABLE metadata.table_registry IS 'Registre de toutes les tables et vues du data warehouse';
COMMENT ON TABLE metadata.version_control IS 'Table de contrôle des versions du data warehouse';
COMMENT ON TABLE metadata.schema_registry IS 'Registre des schémas du data warehouse';
COMMENT ON TABLE metadata.script_execution_log IS 'Journal d''exécution des scripts';

-- 12. Commentaires sur les colonnes principales
COMMENT ON COLUMN metadata.table_registry.nm_schema IS 'Nom du schéma';
COMMENT ON COLUMN metadata.table_registry.nm_table IS 'Nom de la table ou vue';
COMMENT ON COLUMN metadata.table_registry.cd_source IS 'Code de la source de données';
COMMENT ON COLUMN metadata.table_registry.fl_view IS 'Indique si l''objet est une vue';

COMMENT ON COLUMN metadata.transformation_tracking.tx_transformation_type IS 'Type de transformation effectuée';
COMMENT ON COLUMN metadata.transformation_tracking.tx_transformation_rules IS 'Description des règles de transformation appliquées';
COMMENT ON COLUMN metadata.transformation_tracking.nb_rows_source IS 'Nombre de lignes dans la table source';
COMMENT ON COLUMN metadata.transformation_tracking.nb_rows_target IS 'Nombre de lignes dans la table cible après transformation';