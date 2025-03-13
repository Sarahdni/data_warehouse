-- 02_clean_staging/tables/clean_vat_nace_employment.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_clean_vat_nace_employment.sql', 'RUNNING');

-- Création de la table clean_vat_nace_employment
CREATE TABLE IF NOT EXISTS clean_staging.clean_vat_nace_employment (
    -- Clé technique
    id_clean SERIAL PRIMARY KEY,
    
    -- Références de classification
    cd_economic_activity VARCHAR(10) NOT NULL,  -- Code NACE (5 chiffres max)
    cd_size_class VARCHAR(5) NOT NULL,          -- Code de la classe de taille
    
    -- Dénombrements
    ms_num_entreprises INTEGER NOT NULL,        -- Nombre total d'entreprises actives
    ms_num_starts INTEGER NOT NULL DEFAULT 0,   -- Nombre de nouvelles entreprises
    ms_num_stops INTEGER NOT NULL DEFAULT 0,    -- Nombre d'entreprises fermées
    
    -- Références géographiques
    cd_refnis VARCHAR(10) NOT NULL,             -- Code administratif REFNIS
    
    -- Flags de niveau
    fl_foreign BOOLEAN NOT NULL DEFAULT FALSE,  -- Indique si l'entreprise est étrangère
    cd_nace_level INTEGER NOT NULL,             -- Niveau de la nomenclature NACE (1-5)
    
    -- Métadonnées source
    cd_year INTEGER,                            -- Année des données (extrait du nom de fichier)
    
    -- Traçabilité
    id_batch INTEGER NOT NULL,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT chk_nace_level CHECK (cd_nace_level BETWEEN 1 AND 5),
    CONSTRAINT chk_numbers CHECK (
        ms_num_entreprises >= 0 AND 
        ms_num_starts >= 0 AND 
        ms_num_stops >= 0
    ),
    CONSTRAINT uk_nace_employment UNIQUE (
        cd_economic_activity, 
        cd_size_class, 
        cd_refnis, 
        id_batch
    )
);

-- Index pour optimiser les requêtes fréquentes
CREATE INDEX IF NOT EXISTS idx_clean_vat_nace_employment_activity 
    ON clean_staging.clean_vat_nace_employment(cd_economic_activity);

CREATE INDEX IF NOT EXISTS idx_clean_vat_nace_employment_size 
    ON clean_staging.clean_vat_nace_employment(cd_size_class);

CREATE INDEX IF NOT EXISTS idx_clean_vat_nace_employment_refnis 
    ON clean_staging.clean_vat_nace_employment(cd_refnis);

CREATE INDEX IF NOT EXISTS idx_clean_vat_nace_employment_batch 
    ON clean_staging.clean_vat_nace_employment(id_batch);

CREATE INDEX IF NOT EXISTS idx_clean_vat_nace_employment_foreign 
    ON clean_staging.clean_vat_nace_employment(fl_foreign);

CREATE INDEX IF NOT EXISTS idx_clean_vat_nace_employment_year 
    ON clean_staging.clean_vat_nace_employment(cd_year);

-- Commentaires
COMMENT ON TABLE clean_staging.clean_vat_nace_employment IS 
'Table de staging nettoyée pour les données d''emploi par secteur NACE.
Cette table normalise les données provenant de différents formats de fichiers source
(MINIMAL ou COMPLET) et prépare les données pour l''alimentation de la table de faits.';

COMMENT ON COLUMN clean_staging.clean_vat_nace_employment.cd_economic_activity IS 
'Code de l''activité économique selon la nomenclature NACE-BEL';

COMMENT ON COLUMN clean_staging.clean_vat_nace_employment.cd_size_class IS 
'Code de la classe de taille des entreprises (0-15)';

COMMENT ON COLUMN clean_staging.clean_vat_nace_employment.ms_num_entreprises IS 
'Nombre total d''entreprises actives pour cette combinaison NACE/taille/géographie';

COMMENT ON COLUMN clean_staging.clean_vat_nace_employment.ms_num_starts IS 
'Nombre de nouvelles entreprises (nouveaux numéros TVA) pour la période';

COMMENT ON COLUMN clean_staging.clean_vat_nace_employment.ms_num_stops IS 
'Nombre d''entreprises fermées (numéros TVA arrêtés) pour la période';

COMMENT ON COLUMN clean_staging.clean_vat_nace_employment.cd_refnis IS 
'Code administratif REFNIS (district administratif)';

COMMENT ON COLUMN clean_staging.clean_vat_nace_employment.fl_foreign IS 
'Indique si les données concernent des entreprises étrangères';

COMMENT ON COLUMN clean_staging.clean_vat_nace_employment.cd_nace_level IS 
'Niveau de la nomenclature NACE (1=Section, 2=Division, 3=Groupe, 4=Classe, 5=Sous-classe)';

COMMENT ON COLUMN clean_staging.clean_vat_nace_employment.cd_year IS 
'Année de référence des données, extraite du nom de fichier source';

-- Créer une vue de compatibilité avec l'ancien nom
CREATE OR REPLACE VIEW clean_staging.clean_nace_employment AS
SELECT * FROM clean_staging.clean_vat_nace_employment;

COMMENT ON VIEW clean_staging.clean_nace_employment IS 
'Vue de compatibilité avec l''ancien nom de table. 
Pointe vers clean_staging.clean_vat_nace_employment.';

-- Log du succès
SELECT utils.log_script_execution('create_clean_vat_nace_employment.sql', 'SUCCESS');