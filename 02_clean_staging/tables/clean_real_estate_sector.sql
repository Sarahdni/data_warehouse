-- 02_clean_staging/tables/clean_real_estate_sector.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_clean_real_estate_sector.sql', 'RUNNING');

-- Création de la table
CREATE TABLE IF NOT EXISTS clean_staging.clean_real_estate_sector (
    -- Clés et identifiants
    id_transaction SERIAL PRIMARY KEY,
    cd_year INTEGER NOT NULL,
    cd_sector VARCHAR(20) NOT NULL,
    cd_refnis VARCHAR(5) NOT NULL,      -- Extrait du secteur ou du secteur UNKNOWN
    cd_type VARCHAR(4) NOT NULL,
    
    -- Mesures de volume
    nb_transactions INTEGER NOT NULL,
    
    -- Indicateurs de prix (NULL si confidentiel)
    ms_price_p10 DECIMAL(15,2),
    ms_price_p25 DECIMAL(15,2),
    ms_price_p50 DECIMAL(15,2),
    ms_price_p75 DECIMAL(15,2),
    ms_price_p90 DECIMAL(15,2),
    
    -- Flags de validation
    fl_confidential BOOLEAN NOT NULL,     -- TRUE si nb_transactions < 16
    fl_valid_sector BOOLEAN NOT NULL,     -- TRUE si secteur existe dans dim_statistical_sectors
    fl_unknown_sector BOOLEAN NOT NULL,   -- TRUE si format XXXXX_UNKNOWN
    
    -- Métadonnées
    id_batch INTEGER NOT NULL,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT chk_year_range 
        CHECK (cd_year BETWEEN 1900 AND 2100),
        
    CONSTRAINT chk_sector_format 
        CHECK (
            cd_sector ~ '^[0-9]{5}.*$'  -- Accepte tout ce qui commence par 5 chiffres
        ),
        
    CONSTRAINT chk_type_format 
        CHECK (cd_type ~ '^B[0-9A]{3}$'),
        
    CONSTRAINT chk_transactions_positive 
        CHECK (nb_transactions > 0),
        
    CONSTRAINT chk_refnis_format
        CHECK (cd_refnis ~ '^[0-9]{5}$'),
        
    CONSTRAINT chk_prices_confidentiality
        CHECK (
            (fl_confidential = TRUE AND 
             ms_price_p10 IS NULL AND 
             ms_price_p25 IS NULL AND 
             ms_price_p50 IS NULL AND 
             ms_price_p75 IS NULL AND 
             ms_price_p90 IS NULL)
            OR
            (fl_confidential = FALSE)
        ),
        
    CONSTRAINT chk_prices_progression
        CHECK (
            (ms_price_p10 IS NULL AND 
             ms_price_p25 IS NULL AND 
             ms_price_p50 IS NULL AND 
             ms_price_p75 IS NULL AND 
             ms_price_p90 IS NULL)
            OR
            (ms_price_p10 <= ms_price_p25 AND 
             ms_price_p25 <= ms_price_p50 AND 
             ms_price_p50 <= ms_price_p75 AND 
             ms_price_p75 <= ms_price_p90)
        )
);

-- Index pour optimiser les recherches et jointures
CREATE INDEX IF NOT EXISTS idx_clean_res_year_sector 
    ON clean_staging.clean_real_estate_sector(cd_year, cd_sector);
    
CREATE INDEX IF NOT EXISTS idx_clean_res_refnis 
    ON clean_staging.clean_real_estate_sector(cd_refnis);
    
CREATE INDEX IF NOT EXISTS idx_clean_res_type 
    ON clean_staging.clean_real_estate_sector(cd_type);
    
CREATE INDEX IF NOT EXISTS idx_clean_res_batch 
    ON clean_staging.clean_real_estate_sector(id_batch);

-- Trigger pour mise à jour automatique
CREATE OR REPLACE FUNCTION clean_staging.update_clean_res_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_clean_res_timestamp
    BEFORE UPDATE ON clean_staging.clean_real_estate_sector
    FOR EACH ROW
    EXECUTE FUNCTION clean_staging.update_clean_res_timestamp();

-- Commentaires
COMMENT ON TABLE clean_staging.clean_real_estate_sector IS 
'Table de staging nettoyée pour les transactions immobilières.
Règles appliquées :
1. Confidentialité : Prix masqués si moins de 16 transactions
2. Validation des secteurs : Vérification de l''existence dans dim_statistical_sectors
3. Gestion des UNKNOWN : Format NNNNN_UNKNOWN où NNNNN est le code REFNIS
4. Validation des prix : Vérification de la progression logique (P10 <= P25 <= P50 <= P75 <= P90)';

-- Commentaires sur les colonnes
COMMENT ON COLUMN clean_staging.clean_real_estate_sector.fl_confidential IS 
'TRUE si le nombre de transactions est inférieur à 16 (seuil de confidentialité)';

COMMENT ON COLUMN clean_staging.clean_real_estate_sector.fl_valid_sector IS 
'TRUE si le secteur existe dans dim_statistical_sectors pour l''année donnée';

COMMENT ON COLUMN clean_staging.clean_real_estate_sector.fl_unknown_sector IS 
'TRUE si le secteur suit le format NNNNN_UNKNOWN';

-- Log du succès
SELECT utils.log_script_execution('create_clean_real_estate_sector.sql', 'SUCCESS');