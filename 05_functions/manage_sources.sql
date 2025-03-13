-- 05_functions/manage_sources.sql

/*
Description: Procédure pour gérer les sources de données dans metadata.dim_source
Cette procédure permet d'ajouter, mettre à jour ou désactiver des sources de données.

Exemple d'utilisation pour un fichier csv:

CALL metadata.manage_source(
    'ADD',                              -- Action (ADD, UPDATE ou DISABLE)
    'NOM_SOURCE',                       -- Code unique de la source
    'FILE',                             -- Type de source
    -- Paramètres fichier
    'fichier_*.csv',                    -- Pattern du nom de fichier
    '/chemin/vers/dossier/',            -- Chemin du dossier
    'CSV',                              -- Format
    ';',                                -- Délimiteur
    'UTF-8',                            -- Encodage
    -- Description
    'Nom de la source',                 -- Nom en français
    'Description de la source',         -- Description en français
    'MONTHLY',                          -- Fréquence (YEARLY, QUARTERLY, MONTHLY)
    '2024-01-01',                       -- Date début des données
    '2024-12-31',                       -- Date fin des données
    2024,                               -- Année de référence
    'MUNICIPAL',                        -- Niveau géographique
    'Nom du fournisseur'                -- Fournisseur
);

*/

CREATE OR REPLACE PROCEDURE metadata.manage_source(
    p_action VARCHAR(10),              
    p_cd_source VARCHAR(50),           
    p_cd_type VARCHAR(10),             
    -- Paramètres optionnels pour les fichiers
    p_file_pattern VARCHAR(100) DEFAULT NULL,
    p_file_path VARCHAR(500) DEFAULT NULL,
    p_file_format VARCHAR(20) DEFAULT NULL,
    p_delimiter CHAR(1) DEFAULT NULL,
    p_encoding VARCHAR(20) DEFAULT NULL,
    -- Paramètres optionnels pour les APIs
    p_api_url TEXT DEFAULT NULL,
    p_api_method VARCHAR(10) DEFAULT NULL,
    p_api_auth_type VARCHAR(20) DEFAULT NULL,
    p_api_parameters TEXT DEFAULT NULL,
    -- Paramètres descriptifs
    p_name_fr VARCHAR(100) DEFAULT NULL,
    p_description_fr TEXT DEFAULT NULL,
    p_frequency VARCHAR(20) DEFAULT NULL,
    -- Nouveaux paramètres temporels
    p_data_start DATE DEFAULT NULL,
    p_data_end DATE DEFAULT NULL,
    p_reference_year INTEGER DEFAULT NULL,
    -- Autres paramètres
    p_geographic_level VARCHAR(20) DEFAULT NULL,
    p_provider VARCHAR(100) DEFAULT NULL
)
LANGUAGE plpgsql AS $$
BEGIN
    CASE p_action
        WHEN 'ADD' THEN
            -- Vérification des paramètres obligatoires
            IF p_cd_type = 'FILE' AND (p_file_pattern IS NULL OR p_file_path IS NULL) THEN
                RAISE EXCEPTION 'Pour une source de type fichier, pattern et chemin sont obligatoires';
            END IF;
            
            IF p_cd_type = 'API' AND p_api_url IS NULL THEN
                RAISE EXCEPTION 'Pour une source de type API, l''URL est obligatoire';
            END IF;
            
            INSERT INTO metadata.dim_source (
                cd_source,
                cd_type,
                -- Fichiers
                tx_file_pattern,
                tx_file_path,
                tx_file_format,
                tx_delimiter,
                tx_encoding,
                -- API
                tx_api_url,
                tx_api_method,
                tx_api_auth_type,
                tx_api_parameters,
                -- Description
                tx_name_fr,
                tx_description_fr,
                -- Métadonnées temporelles
                cd_frequency,
                dt_data_start,
                dt_data_end,
                cd_reference_year,
                -- Autres métadonnées
                cd_geographic_level,
                tx_provider,
                fl_active
            ) VALUES (
                p_cd_source,
                p_cd_type,
                p_file_pattern,
                p_file_path,
                p_file_format,
                p_delimiter,
                p_encoding,
                p_api_url,
                p_api_method,
                p_api_auth_type,
                p_api_parameters,
                p_name_fr,
                p_description_fr,
                p_frequency,
                p_data_start,
                p_data_end,
                p_reference_year,
                p_geographic_level,
                p_provider,
                TRUE
            );
            
            RAISE NOTICE 'Source % ajoutée avec succès', p_cd_source;
            
        WHEN 'UPDATE' THEN
            IF NOT EXISTS (SELECT 1 FROM metadata.dim_source WHERE cd_source = p_cd_source) THEN
                RAISE EXCEPTION 'La source % n''existe pas', p_cd_source;
            END IF;
            
            UPDATE metadata.dim_source
            SET
                -- Fichiers
                tx_file_pattern = COALESCE(p_file_pattern, tx_file_pattern),
                tx_file_path = COALESCE(p_file_path, tx_file_path),
                tx_file_format = COALESCE(p_file_format, tx_file_format),
                tx_delimiter = COALESCE(p_delimiter, tx_delimiter),
                tx_encoding = COALESCE(p_encoding, tx_encoding),
                -- API
                tx_api_url = COALESCE(p_api_url, tx_api_url),
                tx_api_method = COALESCE(p_api_method, tx_api_method),
                tx_api_auth_type = COALESCE(p_api_auth_type, tx_api_auth_type),
                tx_api_parameters = COALESCE(p_api_parameters, tx_api_parameters),
                -- Description
                tx_name_fr = COALESCE(p_name_fr, tx_name_fr),
                tx_description_fr = COALESCE(p_description_fr, tx_description_fr),
                -- Métadonnées temporelles
                cd_frequency = COALESCE(p_frequency, cd_frequency),
                dt_data_start = COALESCE(p_data_start, dt_data_start),
                dt_data_end = COALESCE(p_data_end, dt_data_end),
                cd_reference_year = COALESCE(p_reference_year, cd_reference_year),
                -- Autres métadonnées
                cd_geographic_level = COALESCE(p_geographic_level, cd_geographic_level),
                tx_provider = COALESCE(p_provider, tx_provider)

            WHERE cd_source = p_cd_source;
            
            RAISE NOTICE 'Source % mise à jour avec succès', p_cd_source;
            
        WHEN 'DISABLE' THEN
            IF NOT EXISTS (SELECT 1 FROM metadata.dim_source WHERE cd_source = p_cd_source) THEN
                RAISE EXCEPTION 'La source % n''existe pas', p_cd_source;
            END IF;
            
            UPDATE metadata.dim_source
            SET fl_active = FALSE
            WHERE cd_source = p_cd_source;
            
            RAISE NOTICE 'Source % désactivée avec succès', p_cd_source;
            
        ELSE
            RAISE EXCEPTION 'Action non valide. Utilisez ADD, UPDATE, ou DISABLE';
    END CASE;
END;
$$;

COMMENT ON PROCEDURE metadata.manage_source IS 'Procédure de gestion des sources de données (fichiers et APIs)';