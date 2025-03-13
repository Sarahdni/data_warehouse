# Documentation des Tables de Faits des Permis de Construction

## 1. Vue d'ensemble

Le modèle de données des permis de construction a été implémenté avec une approche de séparation des mesures. Il couvre :
- Les comptages de bâtiments et logements
- Les mesures de surface (bâtiments résidentiels)
- Les mesures de volume (bâtiments non résidentiels)
- La distinction entre nouvelles constructions et rénovations
- Le support des données mensuelles et annuelles

## 2. Structure du Projet

### 2.1 Organisation des Fichiers
```
project/
├── 01_staging/
│   ├── tables/
│   │   └── stg_building_permits.sql       # Table de staging
│   ├── procedures/
│   │   └── load_building_permits.sql      # Procédure de chargement
│   └── validation/
│       └── validate_building_permits.sql  # Règles de validation
├── 03_fact_tables/real_estate/
│   ├── structure/
│   │   └── fact_building_permits_structure.sql  # Structure des tables
│   └── procedures/
│       ├── load_fact_building_permits_counts.sql
│       ├── load_fact_building_permits_surface.sql
│       ├── load_fact_building_permits_volume.sql
│       └── load_fact_building_permits.sql       # Procédure principale
```

### 2.2 Choix de Structure
- Séparation des mesures en trois tables distinctes
- Gestion par lots (batches) pour la traçabilité
- Support des cumuls annuels et données mensuelles
- Contraintes d'intégrité strictes

## 3. Structure Détaillée

### 3.1 Table fact_building_permits_counts
```sql
CREATE TABLE dw.fact_building_permits_counts (
    -- Clés dimensionnelles
    id_date INTEGER NOT NULL,
    id_geography INTEGER NOT NULL,
    
    -- Mesures de comptage
    nb_buildings INTEGER NOT NULL DEFAULT 0,
    nb_dwellings INTEGER NOT NULL DEFAULT 0,
    nb_apartments INTEGER NOT NULL DEFAULT 0,
    nb_houses INTEGER NOT NULL DEFAULT 0,
    
    -- Flags de classification
    fl_residential BOOLEAN NOT NULL,
    fl_new_construction BOOLEAN NOT NULL,
    
    -- Traçabilité
    id_batch INTEGER,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT pk_fact_bp_counts 
        PRIMARY KEY (id_date, id_geography, fl_residential, fl_new_construction)
);
```

### 3.2 Table fact_building_permits_surface
```sql
CREATE TABLE dw.fact_building_permits_surface (
    -- Clés dimensionnelles
    id_date INTEGER NOT NULL,
    id_geography INTEGER NOT NULL,
    
    -- Mesures de surface
    nb_surface_m2 DECIMAL(15,2) NOT NULL,
    
    -- Flags (toujours TRUE pour cette table)
    fl_residential BOOLEAN NOT NULL,
    fl_new_construction BOOLEAN NOT NULL,
    
    -- Traçabilité
    id_batch INTEGER,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT pk_fact_bp_surface PRIMARY KEY (id_date, id_geography)
);
```

### 3.3 Table fact_building_permits_volume
```sql
CREATE TABLE dw.fact_building_permits_volume (
    -- Clés dimensionnelles
    id_date INTEGER NOT NULL,
    id_geography INTEGER NOT NULL,
    
    -- Mesures de volume
    nb_volume_m3 DECIMAL(15,2) NOT NULL,
    
    -- Flags (prédéfinis pour cette table)
    fl_residential BOOLEAN NOT NULL,
    fl_new_construction BOOLEAN NOT NULL,
    
    -- Traçabilité
    id_batch INTEGER,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes
    CONSTRAINT pk_fact_bp_volume PRIMARY KEY (id_date, id_geography)
);
```

## 4. Processus ETL

### 4.1 Chargement en Staging
```sql
CALL staging.load_building_permits(
    'TF_BUILDING_PERMITS_1996_2024.csv',
    TRUE  -- Truncate staging
);
```

### 4.2 Validation des Données
Contrôles effectués :
1. Format des codes REFNIS
2. Validité des périodes (0-12)
3. Validité des années (>= 1996)
4. Non-négativité des mesures
5. Cohérence des totaux
6. Détection des doublons

### 4.3 Chargement dans les Tables de Faits
Procédure orchestrée en trois phases :
1. Chargement des comptages
2. Chargement des surfaces
3. Chargement des volumes

## 5. Index et Performance

### 5.1 Index pour fact_building_permits_counts
```sql
CREATE INDEX idx_fact_bp_counts_date ON dw.fact_building_permits_counts(id_date);
CREATE INDEX idx_fact_bp_counts_geo ON dw.fact_building_permits_counts(id_geography);
CREATE INDEX idx_fact_bp_counts_type ON dw.fact_building_permits_counts(fl_residential, fl_new_construction);
CREATE INDEX idx_fact_bp_counts_batch ON dw.fact_building_permits_counts(id_batch);
```

### 5.2 Index pour fact_building_permits_surface
```sql
CREATE INDEX idx_fact_bp_surface_date ON dw.fact_building_permits_surface(id_date);
CREATE INDEX idx_fact_bp_surface_geo ON dw.fact_building_permits_surface(id_geography);
CREATE INDEX idx_fact_bp_surface_batch ON dw.fact_building_permits_surface(id_batch);
```

### 5.3 Index pour fact_building_permits_volume
```sql
CREATE INDEX idx_fact_bp_volume_date ON dw.fact_building_permits_volume(id_date);
CREATE INDEX idx_fact_bp_volume_geo ON dw.fact_building_permits_volume(id_geography);
CREATE INDEX idx_fact_bp_volume_batch ON dw.fact_building_permits_volume(id_batch);
```

## 6. Requêtes Types

### 6.1 Analyse des Nouvelles Constructions Résidentielles
```sql
SELECT 
    d.cd_year,
    d.cd_month,
    g.tx_name_fr,
    f.nb_buildings,
    f.nb_dwellings,
    f.nb_apartments,
    f.nb_houses,
    s.nb_surface_m2
FROM dw.fact_building_permits_counts f
JOIN dw.dim_date d ON f.id_date = d.id_date
JOIN dw.dim_geography g ON f.id_geography = g.id_geography
JOIN dw.fact_building_permits_surface s 
    ON f.id_date = s.id_date 
    AND f.id_geography = s.id_geography
WHERE f.fl_residential = TRUE
AND f.fl_new_construction = TRUE;
```

### 6.2 Analyse des Rénovations
```sql
SELECT 
    d.cd_year,
    g.tx_name_fr,
    SUM(CASE WHEN f.fl_residential THEN f.nb_buildings ELSE 0 END) as renovations_residentielles,
    SUM(CASE WHEN NOT f.fl_residential THEN f.nb_buildings ELSE 0 END) as renovations_non_residentielles
FROM dw.fact_building_permits_counts f
JOIN dw.dim_date d ON f.id_date = d.id_date
JOIN dw.dim_geography g ON f.id_geography = g.id_geography
WHERE NOT f.fl_new_construction
GROUP BY d.cd_year, g.tx_name_fr;
```

## 7. Maintenance

### 7.1 Procédures de Maintenance
1. Purge des anciens batches
2. Mise à jour des statistiques
3. Réindexation périodique
4. Archivage des données historiques

### 7.2 Contrôles Qualité
```sql
-- Vérification des totaux
SELECT 
    d.cd_year,
    SUM(f.nb_buildings) as total_buildings,
    SUM(f.nb_dwellings) as total_dwellings
FROM dw.fact_building_permits_counts f
JOIN dw.dim_date d ON f.id_date = d.id_date
WHERE f.fl_residential 
AND f.fl_new_construction
GROUP BY d.cd_year
ORDER BY d.cd_year;

-- Détection des anomalies
SELECT *
FROM dw.fact_building_permits_counts
WHERE nb_dwellings < nb_apartments + nb_houses;
```

## 8. Évolutions Possibles

### 8.1 Restructuration en Deux Tables
Une évolution possible serait de restructurer les données en deux tables principales :
```sql
CREATE TABLE dw.fact_building_permits_residential (
    id_date INTEGER,
    id_geography INTEGER,
    nb_buildings INTEGER,
    nb_dwellings INTEGER,
    nb_apartments INTEGER,
    nb_houses INTEGER,
    nb_surface_m2 DECIMAL(15,2),
    fl_new_construction BOOLEAN,
    id_batch INTEGER
);

CREATE TABLE dw.fact_building_permits_nonresidential (
    id_date INTEGER,
    id_geography INTEGER,
    nb_buildings INTEGER,
    nb_volume_m3 DECIMAL(15,2),
    fl_new_construction BOOLEAN,
    id_batch INTEGER
);
```

Avantages :
- Structure plus alignée avec la logique métier
- Réduction des jointures nécessaires
- Simplification des requêtes
- Maintenance plus simple

### 8.2 Ajout de Nouvelles Mesures
Possibilités d'extension :
- Coûts estimés des projets
- Impact environnemental
- Consommation énergétique prévue
- Classification détaillée des types de bâtiments

### 8.3 Amélioration du Processus ETL
Pistes d'amélioration :
- Parallélisation des chargements
- Pré-agrégation des données
- Gestion plus fine des mises à jour
- Support de sources de données additionnelles

## 9. Bonnes Pratiques

### 9.1 Gestion des Données
1. Toujours utiliser les procédures de chargement
2. Valider les données avant insertion
3. Maintenir la cohérence entre les tables
4. Documenter les changements majeurs

### 9.2 Optimisation des Requêtes
1. Utiliser les index appropriés
2. Éviter les jointures inutiles
3. Préférer les agrégations en amont
4. Créer des vues pour les requêtes fréquentes

### 9.3 Gestion des Périodes
1. Gérer correctement les cumuls annuels
2. Valider la cohérence mensuelle/annuelle
3. Maintenir l'historique des corrections
4. Documenter les changements méthodologiques