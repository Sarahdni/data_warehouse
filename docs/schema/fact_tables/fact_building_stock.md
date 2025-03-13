# Documentation de la Table de Faits du Parc Immobilier (Building Stock)

## 1. Vue d'ensemble

Le modèle de données du parc immobilier a été conçu pour stocker et analyser les statistiques sur les bâtiments en Belgique. Il permet de :
- Suivre l'évolution du parc immobilier par type de bâtiment
- Analyser différentes caractéristiques (âge, superficie, équipements)
- Gérer les données par zone géographique
- Maintenir l'historique des changements

## 2. Structure du Projet

### 2.1 Organisation des Fichiers
```
project/
├── 01_staging/
│   ├── tables/
│   │   └── stg_building_stock.sql        # Table de staging
│   ├── procedures/
│   │   └── load_building_stock.sql       # Procédure de chargement
│   └── validation/
│       └── validate_building_stock.sql   # Règles de validation
└── 03_fact_tables/real_estate/
    ├── fact_building_stock.sql           # Structure de la table de faits
    └── procedures/
        └── load_fact_building_stock.sql  # Procédure de chargement
```

## 3. Particularités et Règles Métier

### 3.1 Types de Bâtiments
- R1 : Maisons de type fermé
- R2 : Maisons de type demi-fermé
- R3 : Maisons de type ouvert, fermes, châteaux
- R4 : Buildings et immeubles à appartements
- R5 : Maisons de commerce
- R6 : Tous les autres bâtiments

### 3.2 Statistiques Non Collectées

#### Année 1995
Trois catégories de statistiques non collectées ont été identifiées :
1. Statistiques générales non collectées (69.77% des cas) :
   - T3.7.1 à T3.7.4 et T3.9 pour tous les types de bâtiments

2. Statistiques spécifiques aux buildings et immeubles à appartements (9.30% des cas) :
   - T4.1 à T4.4 uniquement pour R4

3. Statistiques non collectées pour les autres bâtiments (20.93% des cas) :
   - T4.1 à T4.4
   - T5
   - T6.1 et T6.2
   - T7.1 et T7.2
   pour le type R6

### 3.3 Changements de Nomenclature

#### Évolution 2023-2024
En 2023-2024, un changement de nomenclature a été observé dans les noms des colonnes :

| Ancien nom (1995-2022) | Nouveau nom (2023-2024) |
|------------------------|------------------------|
| TX_BUILDING_TYPE_FR    | CD_BUILDING_TYPE_FR   |
| TX_BUILDING_TYPE_NL    | CD_BUILDING_TYPE_NL   |
| TX_REFNIS_FR          | CD_REFNIS_FR         |
| TX_REFNIS_NL          | CD_REFNIS_NL         |
| TX_STAT_TYPE_FR       | CD_STAT_TYPE_FR      |
| TX_STAT_TYPE_NL       | CD_STAT_TYPE_NL      |

**Action corrective :** Pour maintenir la cohérence historique des données, standardisation vers la nomenclature historique (préfixe "TX_").

## 4. Structure Détaillée

### 4.1 Table fact_building_stock
```sql
CREATE TABLE dw.fact_building_stock (
    -- Clés dimensionnelles
    id_date INTEGER NOT NULL,
    id_geography INTEGER NOT NULL,
    cd_building_type VARCHAR(2) NOT NULL,
    cd_statistic_type VARCHAR(10) NOT NULL,
    
    -- Mesure principale
    ms_building_count INTEGER NOT NULL,
    
    -- Traçabilité
    id_batch INTEGER,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Clé primaire composite
    CONSTRAINT pk_fact_building_stock 
        PRIMARY KEY (id_date, id_geography, cd_building_type, cd_statistic_type)
);
```

### 4.2 Contraintes et Validations
```sql
-- Contraintes métier
CONSTRAINT chk_positive_count 
    CHECK (ms_building_count >= 0);
    
CONSTRAINT chk_valid_stat_combinations
    CHECK (
        -- Règles pour 1995
        (EXTRACT(YEAR FROM dt_created) != 1995 OR (
            cd_statistic_type NOT IN ('T3.7.1', 'T3.7.2', 'T3.7.3', 'T3.7.4', 'T3.9') AND
            (cd_building_type != 'R4' OR cd_statistic_type NOT LIKE 'T4%') AND
            (cd_building_type != 'R6' OR (
                cd_statistic_type NOT LIKE 'T4%' AND
                cd_statistic_type != 'T5' AND
                cd_statistic_type NOT LIKE 'T6%' AND
                cd_statistic_type NOT LIKE 'T7%'
            ))
        ))
    );
```

## 5. Procédures de Chargement

### 5.1 Gestion des Données Non Collectées
La procédure `load_fact_building_stock` inclut :
- Identification des statistiques non collectées par année
- Catégorisation détaillée des raisons
- Logging complet des statistiques manquantes
- Mode debug pour analyse détaillée

### 5.2 Harmonisation des Colonnes
Pour les fichiers 2023-2024 :
- Renommage automatique des colonnes CD_ en TX_
- Maintien de la cohérence historique
- Traçabilité des modifications

## 6. Contrôles Qualité

### 6.1 Vérifications Automatiques
```sql
-- Détection des anomalies dans les combinaisons
SELECT *
FROM dw.fact_building_stock f
WHERE (
    -- Vérification des règles 1995
    EXTRACT(YEAR FROM dt_created) = 1995 AND (
        cd_statistic_type IN ('T3.7.1', 'T3.7.2', 'T3.7.3', 'T3.7.4', 'T3.9') OR
        (cd_building_type = 'R4' AND cd_statistic_type LIKE 'T4%') OR
        (cd_building_type = 'R6' AND (
            cd_statistic_type LIKE 'T4%' OR
            cd_statistic_type = 'T5' OR
            cd_statistic_type LIKE 'T6%' OR
            cd_statistic_type LIKE 'T7%'
        ))
    )
);
```

## 7. Recommandations

1. Maintenir la documentation des statistiques non collectées par année
2. Continuer à utiliser la nomenclature TX_ pour la cohérence historique
3. Implémenter des contrôles de validation spécifiques pour 1995
4. Mettre en place un suivi des changements de nomenclature
5. Documenter toute nouvelle exception ou règle métier découverte

## 8. Points d'Attention

1. Les données de 1995 présentent des particularités importantes
2. La nomenclature des colonnes a changé en 2023-2024
3. Certaines combinaisons de statistiques sont invalides selon le type de bâtiment
4. Les règles de validation doivent tenir compte de l'année des données




PART 2!!!

# Documentation de la Table de Faits du Parc Immobilier (Building Stock)

## 1. Évolution de la Structure des Données

### 1.1 Changement Structurel en 2016
La collecte des données a connu un changement majeur en 2016 qui se maintient jusqu'à présent :

#### Période 1995-2015
Total par année : 88,044 lignes
Non collectées : 27,434 (31.2%)
- Statistiques T3.7.1 à T3.7.4 et T3.9 pour tous les types : 19,140 (69.77%)
- Statistiques R6 (autres bâtiments) : 5,742 (20.93%)
- Statistiques R4 (buildings) : 2,552 (9.30%)
Lignes valides : 60,610 (68.8%)

#### Période 2016-présent
Total par année : 88,044 lignes
Non collectées : 8,294 (9.4%)
- Statistiques R6 (autres bâtiments) : 5,742 (69.23%)
- Statistiques R4 (buildings) : 2,552 (30.77%)
Lignes valides : 79,750 (90.6%)

### 1.2 Changement de Nomenclature en 2023
En 2023, seuls les noms des colonnes ont changé, sans impact sur la structure des données :

| 1995-2022           | 2023-2024           | Impact                    |
|---------------------|---------------------|---------------------------|
| TX_BUILDING_TYPE_FR | CD_BUILDING_TYPE_FR | Nom uniquement           |
| TX_BUILDING_TYPE_NL | CD_BUILDING_TYPE_NL | Nom uniquement           |
| TX_REFNIS_FR       | CD_REFNIS_FR        | Nom uniquement           |
| TX_REFNIS_NL       | CD_REFNIS_NL        | Nom uniquement           |
| TX_STAT_TYPE_FR    | CD_STAT_TYPE_FR     | Nom uniquement           |
| TX_STAT_TYPE_NL    | CD_STAT_TYPE_NL     | Nom uniquement           |

Important : Ce changement n'affecte que la nomenclature des colonnes. La structure des données (statistiques collectées et non collectées) reste identique à celle établie en 2016.

## 2. Types de Bâtiments et Statistiques

### 2.1 Types de Bâtiments
- R1 : Maisons de type fermé
- R2 : Maisons de type demi-fermé
- R3 : Maisons de type ouvert, fermes, châteaux
- R4 : Buildings et immeubles à appartements
- R5 : Maisons de commerce
- R6 : Tous les autres bâtiments

### 2.2 Statistiques Non Collectées (depuis 2016)
Pour R4 (Buildings et immeubles à appartements) :
- T4.1 à T4.4

Pour R6 (Autres bâtiments) :
- T4.1 à T4.4
- T5
- T6.1 et T6.2
- T7.1 et T7.2

## 3. Structure de la Table

### 3.1 Schéma
```sql
CREATE TABLE dw.fact_building_stock (
    id_date INTEGER NOT NULL,
    id_geography INTEGER NOT NULL,
    cd_building_type VARCHAR(2) NOT NULL,
    cd_statistic_type VARCHAR(10) NOT NULL,
    ms_building_count INTEGER NOT NULL,
    id_batch INTEGER,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT pk_fact_building_stock 
        PRIMARY KEY (id_date, id_geography, cd_building_type, cd_statistic_type)
);
```

### 3.2 Contraintes de Validation
```sql
-- Contraintes métier
CONSTRAINT chk_positive_count 
    CHECK (ms_building_count >= 0);

CONSTRAINT chk_valid_stat_combinations
    CHECK (
        -- Pour toutes les années depuis 2016
        (cd_building_type NOT IN ('R4', 'R6') OR cd_statistic_type NOT LIKE 'T4%')
        AND
        (cd_building_type != 'R6' OR (
            cd_statistic_type NOT LIKE 'T4%' AND
            cd_statistic_type != 'T5' AND
            cd_statistic_type NOT LIKE 'T6%' AND
            cd_statistic_type NOT LIKE 'T7%'
        ))
    );
```

## 4. Recommandations pour l'Analyse

1. Traitement des Séries Temporelles
   - Tenir compte de la rupture de série en 2016
   - Ne pas interpréter les variations 2015-2016 comme des changements réels
   - Analyser séparément les périodes 1995-2015 et 2016-présent

2. Gestion des Colonnes
   - Standardiser vers le format TX_ pour maintenir la cohérence historique
   - Documenter la transformation CD_ vers TX_ dans les métadonnées

3. Contrôles Qualité
   - Vérifier les totaux par année : toujours 88,044 lignes
   - Confirmer le nombre de statistiques non collectées :
     * 27,434 avant 2016
     * 8,294 depuis 2016
   - Valider la répartition R4/R6 des statistiques non collectées

4. Documentation
   - Mentionner la rupture de 2016 dans les analyses
   - Clarifier que le changement de 2023 n'affecte que les noms des colonnes
   - Maintenir la traçabilité des transformations de nomenclature

## 5. Points d'Attention

1. L'amélioration de la couverture en 2016 est réelle et maintenue
2. Le changement de nomenclature en 2023 est purement technique
3. Les analyses de tendances doivent tenir compte de la rupture de 2016
4. La standardisation vers TX_ est une décision de cohérence historique