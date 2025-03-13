-- 01_staging/tables/stg_ref_nacebel.sql
-- Log du début de l'exécution
SELECT utils.log_script_execution('create_stg_ref_nacebel.sql', 'RUNNING');

DO $$ 
BEGIN 
    -- Création de la table de staging
    CREATE TABLE IF NOT EXISTS staging.stg_ref_nacebel (
        -- Structure exacte du CSV
        LVL_NACEBEL INTEGER NOT NULL,           -- Niveau hiérarchique
        CD_NACEBEL VARCHAR(10) NOT NULL,        -- Code NACE
        CD_SUP_NACEBEL VARCHAR(10),             -- Code du niveau supérieur
        TX_NACEBEL_DE TEXT,                     -- Description en allemand
        TX_NACEBEL_EN TEXT,                     -- Description en anglais
        TX_NACEBEL_FR TEXT,                     -- Description en français
        TX_NACEBEL_NL TEXT,                     -- Description en néerlandais
        DT_VLDT_START DATE,                     -- Date de début de validité
        DT_VLDT_END DATE,                       -- Date de fin de validité

        -- Métadonnées de chargement
        DT_IMPORT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CD_SOURCE VARCHAR(50) NOT NULL DEFAULT 'NACEBEL_2008',
        ID_BATCH INTEGER                        -- Pour le suivi des lots de chargement
    );

    -- Index pour optimiser les chargements et validations
    CREATE INDEX IF NOT EXISTS idx_stg_nacebel_code 
        ON staging.stg_ref_nacebel(CD_NACEBEL);
        
    CREATE INDEX IF NOT EXISTS idx_stg_nacebel_level 
        ON staging.stg_ref_nacebel(LVL_NACEBEL);
        
    CREATE INDEX IF NOT EXISTS idx_stg_nacebel_parent 
        ON staging.stg_ref_nacebel(CD_SUP_NACEBEL);
        
    CREATE INDEX IF NOT EXISTS idx_stg_nacebel_batch 
        ON staging.stg_ref_nacebel(ID_BATCH);

    -- Contraintes de validation basiques
    ALTER TABLE staging.stg_ref_nacebel 
        ADD CONSTRAINT chk_stg_nacebel_level 
        CHECK (LVL_NACEBEL BETWEEN 1 AND 5);

    ALTER TABLE staging.stg_ref_nacebel 
        ADD CONSTRAINT chk_stg_nacebel_dates 
        CHECK (DT_VLDT_START <= DT_VLDT_END);

    -- Enregistrement dans le registre des tables de staging
    INSERT INTO metadata.table_registry (
        nm_schema,
        nm_table,
        tx_description,
        cd_source
    ) VALUES (
        'staging',
        'stg_ref_nacebel',
        'Table de staging pour les codes d''activité économique NACEBEL 2008',
        'NACEBEL_2008'
    ) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

    -- Log du succès
    PERFORM utils.log_script_execution('create_stg_ref_nacebel.sql', 'SUCCESS');

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution('create_stg_ref_nacebel.sql', 'ERROR', SQLERRM);
    RAISE;
END $$;

-- Commentaires
COMMENT ON TABLE staging.stg_ref_nacebel IS 'Table de staging pour la nomenclature NACEBEL 2008';
COMMENT ON COLUMN staging.stg_ref_nacebel.LVL_NACEBEL IS 'Niveau hiérarchique (1=Section, 2=Division, 3=Groupe, 4=Classe, 5=Sous-classe)';
COMMENT ON COLUMN staging.stg_ref_nacebel.CD_NACEBEL IS 'Code NACE unique';
COMMENT ON COLUMN staging.stg_ref_nacebel.CD_SUP_NACEBEL IS 'Code du niveau supérieur dans la hiérarchie';
COMMENT ON COLUMN staging.stg_ref_nacebel.DT_VLDT_START IS 'Date de début de validité';
COMMENT ON COLUMN staging.stg_ref_nacebel.DT_VLDT_END IS 'Date de fin de validité';
COMMENT ON COLUMN staging.stg_ref_nacebel.DT_IMPORT IS 'Date et heure d''import dans le staging';
COMMENT ON COLUMN staging.stg_ref_nacebel.CD_SOURCE IS 'Code de la source de données';
COMMENT ON COLUMN staging.stg_ref_nacebel.ID_BATCH IS 'Identifiant du lot de chargement';