-- 00_init/create_metadata_tables.sql

-- Création des tables de métadonnées

-- Table des sources
CREATE TABLE IF NOT EXISTS metadata.dim_source (
    -- Identification
    id_source SERIAL PRIMARY KEY,
    cd_source VARCHAR(50) NOT NULL UNIQUE,
    cd_type VARCHAR(10) NOT NULL,  -- 'FILE' ou 'API'
    
    -- Pour les fichiers
    tx_file_pattern VARCHAR(100),
    tx_file_path VARCHAR(500),
    tx_file_format VARCHAR(20),
    tx_delimiter CHAR(1),
    tx_encoding VARCHAR(20),
    
    -- Pour les APIs
    tx_api_url TEXT,
    tx_api_method VARCHAR(10),
    tx_api_auth_type VARCHAR(20),
    tx_api_parameters TEXT,
    
    -- Description
    tx_name_fr VARCHAR(100) NOT NULL,
    tx_name_nl VARCHAR(100),
    tx_name_de VARCHAR(100),
    tx_name_en VARCHAR(100),
    tx_description_fr TEXT NOT NULL,
    
    -- Métadonnées temporelles
    cd_frequency VARCHAR(20) NOT NULL,                  -- YEARLY, QUARTERLY, MONTHLY
    dt_data_start DATE,                                 -- Début de la période couverte par les données
    dt_data_end DATE,                                   -- Fin de la période couverte par les données
    cd_reference_year INTEGER,                          -- Année de référence (ex: NACEBEL 2028)
    dt_last_update DATE NOT NULL DEFAULT CURRENT_DATE,  -- Date de dernière mise à jour du fichier source
    
    -- Métadonnées spatiales
    cd_geographic_level VARCHAR(20) NOT NULL,
    
    -- Source officielle
    tx_provider VARCHAR(100) NOT NULL,
    tx_official_url TEXT,
    
    -- Traçabilité
    fl_active BOOLEAN DEFAULT TRUE,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Contraintes
    CONSTRAINT chk_source_code CHECK (cd_source ~ '^[A-Z][A-Z0-9_]*$'),
    CONSTRAINT chk_source_type CHECK (cd_type IN ('FILE', 'API')),
    CONSTRAINT chk_frequency CHECK (cd_frequency IN ('YEARLY', 'QUARTERLY', 'MONTHLY')),
    CONSTRAINT chk_geographic_level CHECK (
        cd_geographic_level IN ('SECTOR', 'MUNICIPALITY', 'DISTRICT', 'PROVINCE', 'REGION', 'COUNTRY')
    ),
    CONSTRAINT chk_file_fields CHECK (
        (cd_type = 'FILE' AND tx_file_pattern IS NOT NULL AND tx_file_path IS NOT NULL)
        OR 
        (cd_type = 'API' AND tx_api_url IS NOT NULL)
    )
);

-- Création de la table de registre des fonctions
CREATE TABLE IF NOT EXISTS metadata.function_registry (
    nm_schema VARCHAR(50) NOT NULL,
    nm_function VARCHAR(100) NOT NULL,
    tx_description TEXT,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contrainte de clé primaire
    CONSTRAINT pk_function_registry 
        PRIMARY KEY (nm_schema, nm_function)
);

-- Table historique des fichiers traités
CREATE TABLE IF NOT EXISTS metadata.source_file_history (
    id_file_history SERIAL PRIMARY KEY,
    id_source INTEGER REFERENCES metadata.dim_source(id_source),
    tx_filename VARCHAR(255) NOT NULL,
    dt_processed TIMESTAMP NOT NULL,
    nb_rows_processed INTEGER,
    tx_status VARCHAR(20),
    tx_error_message TEXT,
    CONSTRAINT uk_source_file UNIQUE(id_source, tx_filename),
    CONSTRAINT chk_status CHECK (tx_status IN ('SUCCESS', 'ERROR', 'RUNNING'))
);

-- Table de suivi des traductions manquantes
CREATE TABLE IF NOT EXISTS metadata.missing_translations (
    id_missing_translation SERIAL PRIMARY KEY,
    id_batch INTEGER NOT NULL,
    cd_nacebel VARCHAR(10) NOT NULL,
    tx_original_fr TEXT NOT NULL,
    missing_languages TEXT[] NOT NULL,
    fl_processed BOOLEAN DEFAULT FALSE,
    dt_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_processed TIMESTAMP,
    
);

-- Index
CREATE INDEX IF NOT EXISTS idx_file_history_status 
ON metadata.source_file_history(tx_status);

-- Fonction pour mise à jour automatique de dt_updated
CREATE OR REPLACE FUNCTION metadata.update_modified_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mise à jour automatique
CREATE TRIGGER tr_update_source_timestamp
    BEFORE UPDATE ON metadata.dim_source
    FOR EACH ROW
    EXECUTE FUNCTION metadata.update_modified_timestamp();

-- Insertion des sources de données initiales
INSERT INTO metadata.dim_source (
    cd_source,
    cd_type,
    tx_file_pattern,
    tx_file_path,
    tx_file_format,
    tx_delimiter,
    tx_encoding,
    tx_name_fr,
    tx_description_fr,
    cd_frequency,
    dt_data_start,
    dt_data_end,
    cd_reference_year,
    cd_geographic_level,
    tx_provider

) VALUES 
    ('NUTS_LAU', 
    'FILE',
    'TU_COM_NUTS_LAU-*.csv',
    '/Users/sarahdinari/Desktop/data_lake/reference_tables/',
    'CSV',
    ',',
    'UTF-8',
    'Codes NUTS/LAU',
    'Codes administratifs NUTS et LAU belges',
    'YEARLY',
    '2025-01-01',      -- dt_data_start (début validité de la version 2025)
    NULL,              -- dt_data_end (NULL car c'est une référence en cours)
    2025,              -- cd_reference_year (version 2025 des codes)
    'COUNTRY',
    'Statbel'
),
('REF_NACEBEL',
    'FILE',
    'ref_nacebel_*.csv',
    '/Users/sarahdinari/Desktop/data_lake/reference_tables/',
    'CSV',
    ',',
    'UTF-8',
    'Codes Nacebel',
    'Nomenclature d''activités économiques belge',
    'YEARLY',
    '2008-01-01',      -- dt_data_start (début validité NACEBEL 2028)
    NULL,              -- dt_data_end (NULL car c'est une référence en cours)
    2008,              -- cd_reference_year (NACEBEL version 2028)
    'COUNTRY',
    'Statbel'
);

-- Table de suivi de la qualité des données
CREATE TABLE IF NOT EXISTS metadata.data_quality_issues (
    id_quality_issue SERIAL PRIMARY KEY,
    id_batch INTEGER NOT NULL,
    issue_type VARCHAR(50) NOT NULL,
    issue_description TEXT NOT NULL,
    nb_records_affected INTEGER,
    tx_examples TEXT,
    dt_detected TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_resolved TIMESTAMP,
    tx_resolution_notes TEXT,
    
    CONSTRAINT fk_batch
        FOREIGN KEY (id_batch)
        REFERENCES metadata.source_file_history(id_file_history)
);

-- Index pour optimiser les requêtes par batch
CREATE INDEX IF NOT EXISTS idx_data_quality_batch 
    ON metadata.data_quality_issues(id_batch);

-- Commentaires pour dim_source
COMMENT ON TABLE metadata.dim_source IS 'Table de référence des sources de données du data warehouse';
COMMENT ON COLUMN metadata.dim_source.id_source IS 'Identifiant technique unique de la source';
COMMENT ON COLUMN metadata.dim_source.cd_source IS 'Code unique de la source (format: MAJUSCULES_AVEC_UNDERSCORE)';
COMMENT ON COLUMN metadata.dim_source.cd_type IS 'Type de source : FILE pour les fichiers, API pour les sources API';

-- Commentaires pour les champs relatifs aux fichiers
COMMENT ON COLUMN metadata.dim_source.tx_file_pattern IS 'Pattern des noms de fichiers attendus (ex: DEMO_*.csv)';
COMMENT ON COLUMN metadata.dim_source.tx_file_path IS 'Chemin d''accès au répertoire des fichiers';
COMMENT ON COLUMN metadata.dim_source.tx_file_format IS 'Format du fichier (CSV, XLSX, etc.)';
COMMENT ON COLUMN metadata.dim_source.tx_delimiter IS 'Délimiteur pour les fichiers CSV';
COMMENT ON COLUMN metadata.dim_source.tx_encoding IS 'Encodage des fichiers (UTF-8, LATIN1, etc.)';

-- Commentaires pour les champs relatifs aux APIs
COMMENT ON COLUMN metadata.dim_source.tx_api_url IS 'URL de base de l''API';
COMMENT ON COLUMN metadata.dim_source.tx_api_method IS 'Méthode HTTP (GET, POST, etc.)';
COMMENT ON COLUMN metadata.dim_source.tx_api_auth_type IS 'Type d''authentification (NONE, API_KEY, OAUTH)';
COMMENT ON COLUMN metadata.dim_source.tx_api_parameters IS 'Paramètres requis de l''API au format JSON';

-- Commentaires pour les champs descriptifs
COMMENT ON COLUMN metadata.dim_source.tx_name_fr IS 'Nom de la source en français';
COMMENT ON COLUMN metadata.dim_source.tx_name_nl IS 'Nom de la source en néerlandais';
COMMENT ON COLUMN metadata.dim_source.tx_name_de IS 'Nom de la source en allemand';
COMMENT ON COLUMN metadata.dim_source.tx_name_en IS 'Nom de la source en anglais';
COMMENT ON COLUMN metadata.dim_source.tx_description_fr IS 'Description détaillée de la source en français';

-- Commentaires pour les métadonnées temporelles
COMMENT ON COLUMN metadata.dim_source.cd_frequency IS 'Fréquence de mise à jour (YEARLY, QUARTERLY, MONTHLY)';
COMMENT ON COLUMN metadata.dim_source.dt_data_start IS 'Date de début de la période couverte par les données de la source';
COMMENT ON COLUMN metadata.dim_source.dt_data_end IS 'Date de fin de la période couverte par les données de la source';
COMMENT ON COLUMN metadata.dim_source.cd_reference_year IS 'Année de référence de la nomenclature ou classification utilisée ';
COMMENT ON COLUMN metadata.dim_source.dt_last_update IS 'Date de dernière mise à jour des données';

-- Commentaires pour les métadonnées spatiales
COMMENT ON COLUMN metadata.dim_source.cd_geographic_level IS 'Niveau géographique des données (SECTOR, MUNICIPALITY, etc.)';

-- Commentaires pour la source officielle
COMMENT ON COLUMN metadata.dim_source.tx_provider IS 'Organisation fournissant les données (ex: Statbel)';
COMMENT ON COLUMN metadata.dim_source.tx_official_url IS 'URL de la documentation officielle';

-- Commentaires pour la traçabilité
COMMENT ON COLUMN metadata.dim_source.fl_active IS 'Indique si la source est active (TRUE) ou désactivée (FALSE)';
COMMENT ON COLUMN metadata.dim_source.dt_created IS 'Date de création de l''enregistrement';
COMMENT ON COLUMN metadata.dim_source.dt_updated IS 'Date de dernière modification de l''enregistrement';

-- Commentaires pour source_file_history
COMMENT ON TABLE metadata.source_file_history IS 'Historique des chargements de fichiers par source';
COMMENT ON COLUMN metadata.source_file_history.id_file_history IS 'Identifiant unique de l''historique';
COMMENT ON COLUMN metadata.source_file_history.id_source IS 'Référence vers la source de données';
COMMENT ON COLUMN metadata.source_file_history.tx_filename IS 'Nom du fichier traité';
COMMENT ON COLUMN metadata.source_file_history.dt_processed IS 'Date et heure du traitement';
COMMENT ON COLUMN metadata.source_file_history.nb_rows_processed IS 'Nombre de lignes traitées';
COMMENT ON COLUMN metadata.source_file_history.tx_status IS 'Statut du traitement (SUCCESS, ERROR, RUNNING)';
COMMENT ON COLUMN metadata.source_file_history.tx_error_message IS 'Message d''erreur en cas d''échec';

-- Commentaires pour missing_translations
COMMENT ON TABLE metadata.missing_translations IS 'Table de suivi des traductions manquantes';
COMMENT ON COLUMN metadata.missing_translations.id_missing_translation IS 'Identifiant unique de la traduction manquante';
COMMENT ON COLUMN metadata.missing_translations.id_batch IS 'Identifiant du lot de chargement';
COMMENT ON COLUMN metadata.missing_translations.cd_nacebel IS 'Code NACE-BEL concerné';
COMMENT ON COLUMN metadata.missing_translations.tx_original_fr IS 'Texte original en français';
COMMENT ON COLUMN metadata.missing_translations.missing_languages IS 'Liste des langues manquantes';
COMMENT ON COLUMN metadata.missing_translations.fl_processed IS 'Indique si la traduction manquante a été traitée';
COMMENT ON COLUMN metadata.missing_translations.dt_created IS 'Date de création de l''enregistrement';
COMMENT ON COLUMN metadata.missing_translations.dt_processed IS 'Date de traitement de la traduction manquante';


-- Commentaires metadata.function_registry
COMMENT ON TABLE metadata.function_registry IS 
'Registre des fonctions utilitaires du data warehouse';

COMMENT ON COLUMN metadata.function_registry.nm_schema IS 'Nom du schéma contenant la fonction';
COMMENT ON COLUMN metadata.function_registry.nm_function IS 'Nom de la fonction';
COMMENT ON COLUMN metadata.function_registry.tx_description IS 'Description de la fonction';
COMMENT ON COLUMN metadata.function_registry.dt_created IS 'Date de création de l''enregistrement';
COMMENT ON COLUMN metadata.function_registry.dt_updated IS 'Date de dernière mise à jour';


-- Commentaires pour data_quality_issues
COMMENT ON TABLE metadata.data_quality_issues IS 
    'Table de suivi des problèmes de qualité des données';
COMMENT ON COLUMN metadata.data_quality_issues.id_quality_issue IS 
    'Identifiant unique du problème de qualité';
COMMENT ON COLUMN metadata.data_quality_issues.id_batch IS 
    'Référence vers le batch de chargement concerné';
COMMENT ON COLUMN metadata.data_quality_issues.issue_type IS 
    'Type de problème (ex: MISSING_DESCRIPTIONS, INVALID_FORMAT)';
COMMENT ON COLUMN metadata.data_quality_issues.issue_description IS 
    'Description détaillée du problème';
COMMENT ON COLUMN metadata.data_quality_issues.nb_records_affected IS 
    'Nombre d''enregistrements affectés par le problème';
COMMENT ON COLUMN metadata.data_quality_issues.dt_detected IS 
    'Date et heure de détection du problème';
COMMENT ON COLUMN metadata.data_quality_issues.dt_resolved IS 
    'Date et heure de résolution du problème';
COMMENT ON COLUMN metadata.data_quality_issues.tx_resolution_notes IS 
    'Notes sur la résolution du problème';
COMMENT ON COLUMN metadata.data_quality_issues.tx_examples IS 
'Exemples de valeurs problématiques (limité à 10 exemples)';    





/* IL FAUT ABSOLUMENT DOCUMENTER CETTE TABLE SUR CE FICHIER !!!!!!!
-- Ajout du champ id_batch à la table transformation_tracking
ALTER TABLE metadata.transformation_tracking
ADD COLUMN id_batch INTEGER;

-- Ajout d'une contrainte foreign key vers source_file_history 
ALTER TABLE metadata.transformation_tracking
ADD CONSTRAINT fk_transformation_batch 
   FOREIGN KEY (id_batch) 
   REFERENCES metadata.source_file_history(id_file_history);

-- Ajout d'un index pour optimiser les recherches par batch
CREATE INDEX idx_transformation_batch 
   ON metadata.transformation_tracking(id_batch);

-- Commentaire sur la nouvelle colonne
COMMENT ON COLUMN metadata.transformation_tracking.id_batch 
   IS 'Identifiant du batch de chargement, référence vers source_file_history';
*/





