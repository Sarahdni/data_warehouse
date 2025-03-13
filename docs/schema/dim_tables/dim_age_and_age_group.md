# Documentation des Dimensions d'Âge (dim_age & dim_age_group)

## 1. Vue d'ensemble

### 1.1 Description Générale
Les dimensions d'âge sont implémentées à travers deux tables complémentaires :
- `dim_age_group` : Définit les groupes d'âge standards pour différents contextes d'analyse
- `dim_age` : Gère les âges individuels et leurs classifications

### 1.2 Relations entre les Tables
- `dim_age` référence `dim_age_group` via la clé étrangère `cd_age_group`
- Un âge peut appartenir à plusieurs types de groupes (standards, sociaux, générationnels)
- Les groupes standards sont définis dans `dim_age_group` pour garantir la cohérence

### 1.3 Organisation des Fichiers
```
/02_dim_tables/population/
├── dim_age.sql               # Définition de la table dim_age
└── dim_age_group.sql         # Définition de la table dim_age_group
 
```

## 2. Structure des Tables

### 2.1 dim_age_group
```sql
CREATE TABLE dw.dim_age_group (
    cd_age_group VARCHAR(10) PRIMARY KEY,
    cd_age_min INTEGER,
    cd_age_max INTEGER,
    fl_total BOOLEAN NOT NULL DEFAULT FALSE,
    tx_age_group_fr VARCHAR(100) NOT NULL,
    tx_age_group_nl VARCHAR(100) NOT NULL,
    tx_age_group_de VARCHAR(100) NOT NULL,
    tx_age_group_en VARCHAR(100) NOT NULL,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Contraintes
    CONSTRAINT chk_age_group_range CHECK (...),
    CONSTRAINT chk_age_group_valid_ranges CHECK (...)
);
```

### 2.2 dim_age
```sql
CREATE TABLE dw.dim_age (
    cd_age INTEGER PRIMARY KEY,
    cd_age_group VARCHAR(10),
    cd_social_group VARCHAR(20),
    cd_generation VARCHAR(20),
    fl_minor BOOLEAN GENERATED ALWAYS AS (cd_age < 18) STORED,
    fl_senior BOOLEAN GENERATED ALWAYS AS (cd_age >= 67) STORED,
    fl_working_age BOOLEAN GENERATED ALWAYS AS (cd_age BETWEEN 15 AND 67) STORED,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cd_age_group) REFERENCES dw.dim_age_group(cd_age_group),
    CONSTRAINT chk_valid_age CHECK (cd_age >= 0 AND cd_age <= 120)
);
```

## 3. Classifications et Règles Métier

### 3.1 Groupes d'Âge Standards (dim_age_group)
1. Statistiques d'emploi
   - 15-24 : Jeunes travailleurs
   - 25-54 : Âge principal de travail
   - 55-74 : Seniors actifs

2. Statistiques sociales
   - 0-17 : Mineurs
   - 18-64 : Adultes
   - 65+ : Seniors

3. Groupe total
   - TOTAL : Tous âges confondus

### 3.2 Classifications dans dim_age

#### 3.2.1 Groupes Sociaux (cd_social_group)
- 0-17 : Mineurs
- 18-64 : Population en âge de travailler
- 65+ : Retraités

#### 3.2.2 Classifications Générationnelles (cd_generation)
Basé sur l'année de référence 2025 :
- GEN_ALPHA : ≤12 ans
- GEN_Z : 13-28 ans
- MILLENNIAL : 29-44 ans
- GEN_X : 45-60 ans
- BABY_BOOMER : 61-79 ans
- SILENT_GEN : 80+ ans

#### 3.2.3 Indicateurs Automatiques
- fl_minor : Âge < 18
- fl_senior : Âge ≥ 67
- fl_working_age : Âge entre 15 et 67

## 4. Implémentation Technique

### 4.1 Index
dim_age_group :
```sql
CREATE INDEX idx_age_group_total ON dw.dim_age_group(fl_total);
CREATE INDEX idx_age_group_ranges ON dw.dim_age_group(cd_age_min, cd_age_max);
```

dim_age :
```sql
CREATE INDEX idx_age_working ON dw.dim_age(fl_working_age);
CREATE INDEX idx_age_groups ON dw.dim_age(cd_age_group);
CREATE INDEX idx_social_groups ON dw.dim_age(cd_social_group);
CREATE INDEX idx_generation ON dw.dim_age(cd_generation);
```

### 4.2 Triggers
Mise à jour automatique des timestamps :
```sql
CREATE OR REPLACE FUNCTION dw.update_age_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dt_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### 4.3 Contraintes
- Validité des âges : 0-120 ans
- Cohérence des plages d'âge
- Unicité des groupes standards
- Intégrité référentielle

## 5. Guides d'Utilisation

### 5.1 Requêtes Courantes

#### 5.1.1 Population Active
```sql
SELECT a.cd_age,
       g.tx_age_group_fr,
       a.fl_working_age
FROM dw.dim_age a
LEFT JOIN dw.dim_age_group g ON a.cd_age_group = g.cd_age_group
WHERE a.fl_working_age = TRUE
ORDER BY a.cd_age;
```

#### 5.1.2 Analyse Générationnelle
```sql
SELECT cd_generation,
       COUNT(*) as nb_ages,
       MIN(cd_age) as age_min,
       MAX(cd_age) as age_max
FROM dw.dim_age
GROUP BY cd_generation
ORDER BY MIN(cd_age);
```

#### 5.1.3 Distribution par Groupe
```sql
SELECT g.cd_age_group,
       g.tx_age_group_fr,
       COUNT(a.cd_age) as nb_ages
FROM dw.dim_age_group g
LEFT JOIN dw.dim_age a ON g.cd_age_group = a.cd_age_group
WHERE g.fl_total = FALSE
GROUP BY g.cd_age_group, g.tx_age_group_fr
ORDER BY g.cd_age_min;
```

### 5.2 Bonnes Pratiques

1. Utilisation des Classifications
   - Choisir la classification appropriée au contexte
   - Utiliser les indicateurs générés pour les filtres simples
   - Considérer les chevauchements potentiels

2. Performance
   - Utiliser les index appropriés
   - Optimiser les jointures
   - Profiter des colonnes générées

3. Multilinguisme
   - Utiliser la langue appropriée selon le contexte
   - Maintenir toutes les traductions

## 6. Maintenance

### 6.1 Gestion des Données
```sql
-- Mise à jour d'un groupe d'âge
UPDATE dw.dim_age_group
SET tx_age_group_fr = 'Nouveau libellé'
WHERE cd_age_group = 'CODE';

-- Ajout d'un nouveau groupe
INSERT INTO dw.dim_age_group (...) VALUES (...);
```

### 6.2 Vérifications Courantes
```sql
-- Vérification des classifications
SELECT cd_age, cd_age_group, cd_social_group, cd_generation
FROM dw.dim_age
WHERE cd_age NOT BETWEEN 0 AND 120;

-- Vérification des groupes
SELECT cd_age_group, cd_age_min, cd_age_max 
FROM dw.dim_age_group 
WHERE NOT (cd_age_min <= cd_age_max OR fl_total = TRUE);
```

### 6.3 Points d'Attention
1. Maintenir la cohérence des classifications
2. Vérifier les impacts des modifications
3. Documenter les changements importants
4. Valider les règles métier

## 7. Évolution et Maintenance

### 7.1 Modifications Planifiées
- Ajustement annuel des générations
- Mise à jour des libellés
- Optimisation des index

### 7.2 Points de Vigilance
- Cohérence des classifications
- Performance des requêtes
- Intégrité des données