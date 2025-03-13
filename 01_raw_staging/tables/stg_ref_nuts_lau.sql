-- 01_staging/tables/stg_ref_nuts_lau.sql

-- Log du début de l'exécution
SELECT utils.log_script_execution('create_stg_ref_nuts_lau.sql', 'RUNNING');

DO $$ 
BEGIN 
    -- Création de la table de staging
    CREATE TABLE IF NOT EXISTS staging.stg_ref_nuts_lau (
        -- Structure exacte du CSV
        CD_LAU VARCHAR(10),                   -- Code LAU
        CD_MUNTY_REFNIS VARCHAR(10),          -- Code REFNIS de la municipalité
        TX_DESCR_DE TEXT,                     -- Description en allemand
        TX_DESCR_EN TEXT,                     -- Description en anglais
        TX_DESCR_FR TEXT,                     -- Description en français
        TX_DESCR_NL TEXT,                     -- Description en néerlandais
        DT_VLDT_STRT DATE,                    -- Date de début de validité
        DT_VLDT_STOP DATE,                    -- Date de fin de validité
        CD_LVL_SUP VARCHAR(10),               -- Code du niveau supérieur
        CD_LVL INTEGER,                       -- Niveau hiérarchique
        -- Métadonnées de chargement
        DT_IMPORT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CD_SOURCE VARCHAR(50) NOT NULL DEFAULT 'NUTS_LAU',
        ID_BATCH INTEGER                      -- Pour le suivi des lots de chargement
    );

    -- Index pour optimiser les chargements et validations
    CREATE INDEX IF NOT EXISTS idx_stg_nuts_lau_cd_lau 
        ON staging.stg_ref_nuts_lau(CD_LAU);
        
    CREATE INDEX IF NOT EXISTS idx_stg_nuts_lau_level 
        ON staging.stg_ref_nuts_lau(CD_LVL);
        
    CREATE INDEX IF NOT EXISTS idx_stg_nuts_lau_batch 
        ON staging.stg_ref_nuts_lau(ID_BATCH);

    -- Contraintes de validation basiques
    ALTER TABLE staging.stg_ref_nuts_lau 
        ADD CONSTRAINT chk_stg_nuts_lau_level 
        CHECK (CD_LVL BETWEEN 1 AND 6);

    -- Enregistrement dans le registre des tables de staging
    INSERT INTO metadata.table_registry (
        nm_schema,
        nm_table,
        tx_description,
        cd_source
    ) VALUES (
        'staging',
        'stg_ref_nuts_lau',
        'Table de staging pour les codes NUTS/LAU belges',
        'NUTS_LAU'
    ) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

    -- Log du succès
    PERFORM utils.log_script_execution('create_stg_ref_nuts_lau.sql', 'SUCCESS');

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution('create_stg_ref_nuts_lau.sql', 'ERROR', SQLERRM);
    RAISE;
END $$;

-- Commentaires
COMMENT ON TABLE staging.stg_ref_nuts_lau IS 'Table de staging pour les codes NUTS/LAU';
COMMENT ON COLUMN staging.stg_ref_nuts_lau.CD_LAU IS 'Code LAU unique';
COMMENT ON COLUMN staging.stg_ref_nuts_lau.CD_MUNTY_REFNIS IS 'Code REFNIS de la municipalité';
COMMENT ON COLUMN staging.stg_ref_nuts_lau.CD_LVL_SUP IS 'Code du niveau supérieur dans la hiérarchie';
COMMENT ON COLUMN staging.stg_ref_nuts_lau.CD_LVL IS 'Niveau hiérarchique';
COMMENT ON COLUMN staging.stg_ref_nuts_lau.DT_IMPORT IS 'Date et heure d''import dans le staging';
COMMENT ON COLUMN staging.stg_ref_nuts_lau.CD_SOURCE IS 'Code de la source de données';
COMMENT ON COLUMN staging.stg_ref_nuts_lau.ID_BATCH IS 'Identifiant du lot de chargement';