-- 03_dim_tables/employment/dim_entreprise_size_employees.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_dim_entreprise_size_employees.sql', 'RUNNING');

-- Création de la fonction trigger
CREATE OR REPLACE FUNCTION dw.update_entreprise_size_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création de la table
CREATE TABLE IF NOT EXISTS dw.dim_entreprise_size_employees (
    -- Clés et identifiants
    cd_size_class VARCHAR(5) PRIMARY KEY,
    
    -- Bornes du nombre d'employés
    cd_min_employees INTEGER NOT NULL,
    cd_max_employees INTEGER,            -- NULL pour "X employés ou plus"
    
    -- Libellés multilingues
    tx_size_class_fr VARCHAR(100) NOT NULL,
    tx_size_class_nl VARCHAR(100) NOT NULL,
    tx_size_class_de VARCHAR(100) NOT NULL,
    tx_size_class_en VARCHAR(100) NOT NULL,
    
    -- Gestion des versions (SCD Type 2)
    dt_valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
    dt_valid_to DATE,
    fl_current BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Traçabilité
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT chk_dates CHECK (dt_valid_from <= COALESCE(dt_valid_to, '9999-12-31'::date)),
    CONSTRAINT chk_employee_range CHECK (
        cd_min_employees >= 0
        AND (
            cd_max_employees IS NULL 
            OR cd_max_employees >= cd_min_employees
        )
    )
    
);

-- Création des index
CREATE INDEX IF NOT EXISTS idx_entreprise_size_current 
ON dw.dim_entreprise_size_employees(fl_current) 
WHERE fl_current = TRUE;

CREATE INDEX IF NOT EXISTS idx_entreprise_size_dates 
ON dw.dim_entreprise_size_employees(dt_valid_from, dt_valid_to);

CREATE INDEX IF NOT EXISTS idx_entreprise_size_range 
ON dw.dim_entreprise_size_employees(cd_min_employees, cd_max_employees);

-- Création du trigger
DROP TRIGGER IF EXISTS tr_update_entreprise_size_timestamp ON dw.dim_entreprise_size_employees;
CREATE TRIGGER tr_update_entreprise_size_timestamp
    BEFORE UPDATE ON dw.dim_entreprise_size_employees
    FOR EACH ROW
    EXECUTE FUNCTION dw.update_entreprise_size_timestamp();

-- Insertion des données
INSERT INTO dw.dim_entreprise_size_employees (
    cd_size_class,
    cd_min_employees,
    cd_max_employees,
    tx_size_class_fr,
    tx_size_class_nl,
    tx_size_class_de,
    tx_size_class_en
) VALUES
    ('0', 0, 0, 'Aucun employé', 'Geen werknemer', 'Keine Mitarbeiter', 'No employee'),
    ('1', 1, 4, '1-4 employés', '1-4 werknemers', '1-4 Mitarbeiter', '1-4 employees'),
    ('2', 5, 9, '5-9 employés', '5-9 werknemers', '5-9 Mitarbeiter', '5-9 employees'),
    ('3', 10, 19, '10-19 employés', '10-19 werknemers', '10-19 Mitarbeiter', '10-19 employees'),
    ('4', 20, 49, '20-49 employés', '20-49 werknemers', '20-49 Mitarbeiter', '20-49 employees'),
    ('5', 50, 99, '50-99 employés', '50-99 werknemers', '50-99 Mitarbeiter', '50-99 employees'),
    ('6', 100, 199, '100-199 employés', '100-199 werknemers', '100-199 Mitarbeiter', '100-199 employees'),
    ('7', 200, 249, '200-249 employés', '200-249 werknemers', '200-249 Mitarbeiter', '200-249 employees'),
    ('8', 250, 499, '250-499 employés', '250-499 werknemers', '250-499 Mitarbeiter', '250-499 employees'),
    ('9', 500, 999, '500-999 employés', '500-999 werknemers', '500-999 Mitarbeiter', '500-999 employees'),
    ('10', 1000, 1999, '1000-1999 employés', '1000-1999 werknemers', '1000-1999 Mitarbeiter', '1000-1999 employees'),
    ('11', 2000, 2999, '2000-2999 employés', '2000-2999 werknemers', '2000-2999 Mitarbeiter', '2000-2999 employees'),
    ('12', 3000, 3999, '3000-3999 employés', '3000-3999 werknemers', '3000-3999 Mitarbeiter', '3000-3999 employees'),
    ('13', 4000, 4999, '4000-4999 employés', '4000-4999 werknemers', '4000-4999 Mitarbeiter', '4000-4999 employees'),
    ('14', 5000, 9999, '5000-9999 employés', '5000-9999 werknemers', '5000-9999 Mitarbeiter', '5000-9999 employees'),
    ('15', 10000, NULL, '+ 10.000 employés', '+ 10000 werknemers', '+ 10.000 Mitarbeiter', '+ 10.000 employees');
ON CONFLICT (cd_size_class) DO UPDATE SET
    cd_min_employees = EXCLUDED.cd_min_employees,
    cd_max_employees = EXCLUDED.cd_max_employees,
    tx_size_class_fr = EXCLUDED.tx_size_class_fr,
    tx_size_class_nl = EXCLUDED.tx_size_class_nl,
    tx_size_class_de = EXCLUDED.tx_size_class_de,
    tx_size_class_en = EXCLUDED.tx_size_class_en,
    dt_updated = CURRENT_TIMESTAMP;

-- Enregistrement dans le registre
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'dim_entreprise_size_employees',
    'Dimension des classes de taille des entreprises selon le nombre d''employés',
    'SYSTEM'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires
COMMENT ON TABLE dw.dim_entreprise_size_employees IS 'Dimension des classes de taille des entreprises selon le nombre d''employés';
COMMENT ON COLUMN dw.dim_entreprise_size_employees.cd_size_class IS 'Code unique de la classe de taille';
COMMENT ON COLUMN dw.dim_entreprise_size_employees.cd_min_employees IS 'Nombre minimum d''employés dans cette classe';
COMMENT ON COLUMN dw.dim_entreprise_size_employees.cd_max_employees IS 'Nombre maximum d''employés dans cette classe (NULL pour "X employés ou plus")';
COMMENT ON COLUMN dw.dim_entreprise_size_employees.tx_size_class_fr IS 'Description de la classe de taille en français';
COMMENT ON COLUMN dw.dim_entreprise_size_employees.tx_size_class_nl IS 'Description de la classe de taille en néerlandais';
COMMENT ON COLUMN dw.dim_entreprise_size_employees.tx_size_class_de IS 'Description de la classe de taille en allemand';
COMMENT ON COLUMN dw.dim_entreprise_size_employees.tx_size_class_en IS 'Description de la classe de taille en anglais';
COMMENT ON COLUMN dw.dim_entreprise_size_employees.dt_valid_from IS 'Date de début de validité';
COMMENT ON COLUMN dw.dim_entreprise_size_employees.dt_valid_to IS 'Date de fin de validité';
COMMENT ON COLUMN dw.dim_entreprise_size_employees.fl_current IS 'Indicateur de version courante';

-- Log du succès
SELECT utils.log_script_execution('create_dim_entreprise_size_employees.sql', 'SUCCESS');



