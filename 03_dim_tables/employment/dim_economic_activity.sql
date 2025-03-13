-- 02_dim_tables/employment/dim_economic_activity.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_dim_economic_activity.sql', 'RUNNING');

-- Création de la fonction trigger
CREATE OR REPLACE FUNCTION dw.update_economic_activity_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création de la table dimensionnelle
CREATE TABLE IF NOT EXISTS dw.dim_economic_activity (
    -- Clés et identifiants
    id_economic_activity SERIAL PRIMARY KEY,
    cd_economic_activity VARCHAR(10) NOT NULL,
    cd_parent_activity VARCHAR(10),
    cd_level INTEGER NOT NULL,
    
    -- Libellés multilingues
    tx_economic_activity_fr TEXT NOT NULL,
    tx_economic_activity_nl TEXT NOT NULL,
    tx_economic_activity_de TEXT NOT NULL,
    tx_economic_activity_en TEXT NOT NULL,
    
    -- Gestion des versions (SCD Type 2)
    dt_valid_from DATE NOT NULL,
    dt_valid_to DATE,
    fl_current BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Traçabilité
    id_batch INTEGER,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT uk_economic_activity_code UNIQUE (cd_economic_activity),
    CONSTRAINT uk_economic_activity_version UNIQUE (cd_economic_activity, dt_valid_from),
    CONSTRAINT chk_level_range CHECK (cd_level BETWEEN 1 AND 5),
    CONSTRAINT chk_valid_dates CHECK (dt_valid_from <= COALESCE(dt_valid_to, '9999-12-31'::date)),
    CONSTRAINT chk_code_format CHECK (
        (cd_level = 1 AND cd_economic_activity ~ '^[A-Z]$') OR
        (cd_level = 2 AND cd_economic_activity ~ '^[0-9]{2}$') OR
        (cd_level = 3 AND cd_economic_activity ~ '^[0-9]{3}$') OR
        (cd_level = 4 AND cd_economic_activity ~ '^[0-9]{4}$') OR
        (cd_level = 5 AND cd_economic_activity ~ '^[0-9]{5}$')
    )
);

-- Ajout de la contrainte de clé étrangère
ALTER TABLE dw.dim_economic_activity 
    ADD CONSTRAINT fk_economic_activity_parent 
    FOREIGN KEY (cd_parent_activity) 
    REFERENCES dw.dim_economic_activity(cd_economic_activity) 
    DEFERRABLE INITIALLY DEFERRED;

-- Création des index
CREATE INDEX IF NOT EXISTS idx_economic_activity_parent 
    ON dw.dim_economic_activity(cd_parent_activity);
    
CREATE INDEX IF NOT EXISTS idx_economic_activity_level 
    ON dw.dim_economic_activity(cd_level);
    
CREATE INDEX IF NOT EXISTS idx_economic_activity_current 
    ON dw.dim_economic_activity(fl_current) 
    WHERE fl_current = TRUE;
    
CREATE INDEX IF NOT EXISTS idx_economic_activity_dates 
    ON dw.dim_economic_activity(dt_valid_from, dt_valid_to);

-- Création du trigger
DROP TRIGGER IF EXISTS tr_update_economic_activity_timestamp ON dw.dim_economic_activity;
CREATE TRIGGER tr_update_economic_activity_timestamp
    BEFORE UPDATE ON dw.dim_economic_activity
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_economic_activity_timestamp();

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'dim_economic_activity',
    'Table dimensionnelle des activités économiques (NACE-BEL)',
    'NACEBEL_2008'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires détaillés
COMMENT ON TABLE dw.dim_economic_activity IS 'Dimension des activités économiques selon la nomenclature NACE-BEL';

COMMENT ON COLUMN dw.dim_economic_activity.cd_economic_activity IS 'Code de l''activité économique (format selon niveau)';
COMMENT ON COLUMN dw.dim_economic_activity.cd_parent_activity IS 'Code de l''activité parent dans la hiérarchie';
COMMENT ON COLUMN dw.dim_economic_activity.cd_level IS 'Niveau hiérarchique (1=Section, 2=Division, 3=Groupe, 4=Classe, 5=Sous-classe)';
COMMENT ON COLUMN dw.dim_economic_activity.tx_economic_activity_fr IS 'Libellé de l''activité en français';
COMMENT ON COLUMN dw.dim_economic_activity.tx_economic_activity_nl IS 'Libellé de l''activité en néerlandais';
COMMENT ON COLUMN dw.dim_economic_activity.tx_economic_activity_de IS 'Libellé de l''activité en allemand';
COMMENT ON COLUMN dw.dim_economic_activity.tx_economic_activity_en IS 'Libellé de l''activité en anglais';
COMMENT ON COLUMN dw.dim_economic_activity.dt_valid_from IS 'Date de début de validité';
COMMENT ON COLUMN dw.dim_economic_activity.dt_valid_to IS 'Date de fin de validité';
COMMENT ON COLUMN dw.dim_economic_activity.fl_current IS 'Indique si c''est la version courante';
COMMENT ON COLUMN dw.dim_economic_activity.id_batch IS 'Identifiant du lot de chargement';

-- Log du succès
SELECT utils.log_script_execution('create_dim_economic_activity.sql', 'SUCCESS');