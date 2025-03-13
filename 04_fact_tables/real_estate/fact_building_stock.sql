-- 04_fact_tables/real_estate/fact_building_stock.sql


-- Log du début d'exécution
SELECT utils.log_script_execution('create_fact_building_stock.sql', 'RUNNING');

-- Création de la table des faits 
CREATE TABLE IF NOT EXISTS dw.fact_building_stock (
    -- Clés dimensionnelles
    id_date INTEGER NOT NULL,
    id_geography INTEGER NOT NULL,
    cd_building_type VARCHAR(2) NOT NULL,
    cd_statistic_type VARCHAR(10) NOT NULL,
    
    -- Mesures
    ms_building_count INTEGER NOT NULL,
    
    -- Traçabilité
    id_batch INTEGER,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT pk_fact_building_stock 
        PRIMARY KEY (id_date, id_geography, cd_building_type, cd_statistic_type),
    
    CONSTRAINT fk_fact_bs_date 
        FOREIGN KEY (id_date) 
        REFERENCES dw.dim_date(id_date),
        
    CONSTRAINT fk_fact_bs_geography 
        FOREIGN KEY (id_geography) 
        REFERENCES dw.dim_geography(id_geography),
        
    CONSTRAINT fk_fact_bs_building_type 
        FOREIGN KEY (cd_building_type) 
        REFERENCES dw.dim_building_type(cd_building_type),
        
    CONSTRAINT fk_fact_bs_statistic_type 
        FOREIGN KEY (cd_statistic_type) 
        REFERENCES dw.dim_building_statistics(cd_statistic_type),
        
    CONSTRAINT chk_positive_count 
        CHECK (ms_building_count >= 0),
        
    -- Nouvelle contrainte basée sur l'analyse des données
    CONSTRAINT chk_valid_stat_combinations
        CHECK (
            -- Exclure T4.x pour R4 et R6
            (cd_building_type NOT IN ('R4', 'R6') OR cd_statistic_type NOT LIKE 'T4%')
            AND
            -- Exclure T5, T6.x, T7.x pour R6
            (cd_building_type != 'R6' OR (
                cd_statistic_type NOT LIKE 'T4%' AND
                cd_statistic_type != 'T5' AND
                cd_statistic_type NOT LIKE 'T6%' AND
                cd_statistic_type NOT LIKE 'T7%'
            ))
        )
);

-- Index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_fact_bs_date 
    ON dw.fact_building_stock(id_date);

CREATE INDEX IF NOT EXISTS idx_fact_bs_geography 
    ON dw.fact_building_stock(id_geography);

CREATE INDEX IF NOT EXISTS idx_fact_bs_type 
    ON dw.fact_building_stock(cd_building_type);

CREATE INDEX IF NOT EXISTS idx_fact_bs_statistic 
    ON dw.fact_building_stock(cd_statistic_type);

CREATE INDEX IF NOT EXISTS idx_fact_bs_batch 
    ON dw.fact_building_stock(id_batch);

-- Enregistrement dans le registre des tables
INSERT INTO metadata.table_registry (
    nm_schema,
    nm_table,
    tx_description,
    cd_source
) VALUES (
    'dw',
    'fact_building_stock',
    'Table des faits pour les statistiques du parc immobilier belge',
    'BUILDING_STOCK'
) ON CONFLICT (nm_schema, nm_table) DO NOTHING;

-- Commentaires détaillés
COMMENT ON TABLE dw.fact_building_stock IS 
'Table des faits contenant les statistiques sur le parc immobilier belge.
Règles métier :
- Les statistiques T4.x ne sont pas collectées pour les bâtiments R4 et R6
- Pour les bâtiments R6, les statistiques T5, T6.x et T7.x ne sont pas collectées
Ces règles sont appliquées via la contrainte chk_valid_stat_combinations';

COMMENT ON COLUMN dw.fact_building_stock.id_date IS 'Lien vers la dimension temporelle';
COMMENT ON COLUMN dw.fact_building_stock.id_geography IS 'Lien vers la dimension géographique';
COMMENT ON COLUMN dw.fact_building_stock.cd_building_type IS 'Type de bâtiment (R1-R6)';
COMMENT ON COLUMN dw.fact_building_stock.cd_statistic_type IS 'Type de statistique';
COMMENT ON COLUMN dw.fact_building_stock.ms_building_count IS 'Nombre de bâtiments pour la catégorie';
COMMENT ON COLUMN dw.fact_building_stock.id_batch IS 'ID du batch de chargement';

-- Log du succès
SELECT utils.log_script_execution('create_fact_building_stock_structure.sql', 'SUCCESS');