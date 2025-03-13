# Documentation des Tables de Population Structure

## 1. Vue d'ensemble

Le modèle de données de la structure de population implémente un processus ETL robuste pour gérer :
- Les données démographiques par commune
- La gestion des nationalités (Belge/Étrangère)
- Le traitement des états civils
- La validation des données géographiques avec gestion des changements historiques
- Le support de chargements incrementaux

## 2. Structure du Projet

### 2.1 Organisation des Fichiers
```
project/
├── 02_clean_staging/
│   ├── tables/
│   │   └── clean_population_structure.sql      # Table de staging nettoyée
│   ├── procedures/
│   │   └── load_clean_population_structure.sql # Procédure de chargement
│   └── validation/
│       └── validate_clean_population_structure.sql # Règles de validation
```

### 2.2 Choix de Structure
- Gestion par lots (batches) pour la traçabilité
- Flags de validation pour chaque dimension
- Support des changements historiques des codes géographiques
- Transformation des codes en versions normalisées

## 3. Problèmes Rencontrés et Solutions

### 3.1 Gestion des Codes Géographiques

#### Problème Initial
- Certaines communes (29 au total) présentaient des codes REFNIS différents entre les données sources et dim_geography
- Certaines communes avaient des entrées multiples dans dim_geography avec des périodes de validité différentes
- La validation échouait pour environ 23,522 enregistrements

#### Solution Implémentée
```sql
LEFT JOIN dw.dim_geography g ON 
    g.cd_refnis = r.CD_REFNIS AND
    g.fl_current = TRUE
```
- Utilisation d'une jointure sur les codes REFNIS actuels
- Simplification de la validation géographique
- Acceptation des codes valides indépendamment de leur période de validité

### 3.2 Gestion des Nationalités

#### Problème Initial
- Les données sources utilisaient 'BEL' et 'ETR' comme codes
- Le système attendait 'BE' et 'NOT_BE'
- 169,221 enregistrements étaient marqués comme invalides

#### Solution Implémentée
```sql
CASE 
    WHEN r.CD_NATLTY = 'BEL' THEN 'BE'
    WHEN r.CD_NATLTY = 'ETR' THEN 'NOT_BE'
    ELSE 'NOT_BE'
END as cd_nationality
```
- Mapping explicite des codes de nationalité
- Gestion des cas par défaut
- Validation adaptée aux codes sources

### 3.3 Structure de la Table de Staging

```sql
CREATE TABLE clean_staging.clean_population_structure (
    -- Clés vers les dimensions
    id_geography INTEGER,
    cd_sex CHAR(1),
    cd_age INTEGER,
    cd_nationality VARCHAR(10),
    cd_civil_status VARCHAR(5),
    cd_year INTEGER,
    
    -- Mesure
    ms_population INTEGER NOT NULL,
    
    -- Flags de validation
    fl_valid_geography BOOLEAN DEFAULT FALSE,
    fl_valid_sex BOOLEAN DEFAULT FALSE,
    fl_valid_age BOOLEAN DEFAULT FALSE,
    fl_valid_nationality BOOLEAN DEFAULT FALSE,
    fl_valid_civil_status BOOLEAN DEFAULT FALSE
);
```

## 4. Processus ETL

### 4.1 Validation des Données
Contrôles effectués :
1. Validité des codes géographiques (avec gestion historique)
2. Format des codes de sexe (M/F)
3. Plage d'âge valide (0-120)
4. Codes de nationalité valides (BEL/ETR)
5. États civils valides (1-5)

### 4.2 Transformation des Données
```sql
-- Exemple de transformation des états civils
CASE r.CD_CIV_STS 
    WHEN '1' THEN 'CEL'  -- Célibataire
    WHEN '2' THEN 'MAR'  -- Marié
    WHEN '3' THEN 'VEU'  -- Veuf/Veuve
    WHEN '4' THEN 'DIV'  -- Divorcé
    WHEN '5' THEN 'SEP'  -- Séparé
END as cd_civil_status
```

## 5. Bonnes Pratiques

### 5.1 Gestion des Données
1. Toujours utiliser les procédures de chargement
2. Valider les données avant insertion
3. Gérer les cas particuliers dans le code
4. Documenter les transformations

### 5.2 Optimisation
1. Utilisation d'index appropriés
2. Gestion des lots (batches)
3. Validation en une seule passe
4. Traçabilité des erreurs

## 6. Évolutions Possibles

### 6.1 Améliorations Potentielles
1. Ajout de dimensions supplémentaires
2. Support multi-langues plus étendu
3. Historisation des changements
4. Gestion plus fine des erreurs

### 6.2 Extensions Envisagées
- Support des indicateurs dérivés
- Calculs démographiques avancés
- Intégration avec d'autres sources de données
- Rapports automatisés





# Documentation des Problèmes Résolus - ETL Structure Population

## 1. Gestion des Périodes de Validité Géographique

### 1.1 Problème Initial : Cas Hasselt
**Situation** :
- Code 71022 : validité de 1900-01-01 à 2018-12-31 (cd_lvl_sup: BE221)
- Code 71022 : validité de 2019-01-01 à 2024-12-31 (cd_lvl_sup: BE224)
- Code 71072 : validité de 2025-01-01 à 9999-12-31 (cd_lvl_sup: BE224)

**Impact** :
- Données de population pour 2024 non valides car :
  - Le code 71022 n'était pas marqué comme fl_current = true
  - Le nouveau code 71072 n'était pas encore valide

**Solution** :
```sql
WITH valid_geography AS (
    SELECT r.CD_REFNIS,
           COALESCE(
               -- Période exacte
               MAX(CASE WHEN v_year_start >= g.dt_start 
                   AND (v_year_end <= g.dt_end OR g.dt_end IS NULL)
                   THEN g.id_geography END),
               -- Période précédente la plus proche
               MAX(CASE WHEN g.dt_start <= v_year_end 
                   THEN g.id_geography END),
               -- Première période future
               MIN(g.id_geography)
           ) as id_geography
    FROM raw_staging.stg_population_structure_raw r
    LEFT JOIN dw.dim_geography g ON g.cd_refnis = r.CD_REFNIS
    GROUP BY r.CD_REFNIS
)
```

### 1.2 Problème : Dates de Fin de Mois (Code 82003)
**Situation** :
- Code 82003 avait une date de fin au 2024-12-01
- Notre validation cherchait une validité jusqu'au 2024-12-31
- 1408 enregistrements étaient marqués comme invalides

**Solution** :
```sql
WHEN v_year_start >= g.dt_start 
AND (
    -- Vérifie si l'année et le mois de fin correspondent
    (EXTRACT(YEAR FROM g.dt_end) = EXTRACT(YEAR FROM v_year_end) 
    AND EXTRACT(MONTH FROM g.dt_end) = EXTRACT(MONTH FROM v_year_end))
    OR g.dt_end > v_year_end 
    OR g.dt_end IS NULL
)
```

## 2. Améliorations Apportées

### 2.1 Logique de Correspondance en 3 Étapes
1. **Correspondance Exacte** :
   - Vérifie la période exacte avec tolérance sur le jour de fin
   - Utilise année/mois plutôt que date exacte

2. **Période Précédente** :
   - Si pas de correspondance exacte, prend la période valide la plus proche

3. **Période Future** :
   - En dernier recours, utilise la première période future disponible

### 2.2 Validation Améliorée
```sql
-- Flags de validation améliorés
(vg.id_geography IS NOT NULL) as fl_valid_geography,
(r.CD_SEX IN ('M', 'F')) as fl_valid_sex,
(r.CD_AGE BETWEEN 0 AND 120) as fl_valid_age,
(r.CD_NATLTY IN ('BEL', 'ETR')) as fl_valid_nationality,
(r.CD_CIV_STS IN ('1','2','3','4','5')) as fl_valid_civil_status
```

## 3. Résultats Obtenus

### 3.1 Avant Correction
- 1408 enregistrements avec géographie invalide
- Problèmes avec les communes en transition
- Rejets dus aux dates de fin de mois

### 3.2 Après Correction
- 476,319 lignes chargées avec succès
- Validation réussie sans erreurs
- Gestion correcte des cas particuliers :
  - Transitions de codes (ex: Hasselt)
  - Dates de fin de mois (ex: Code 82003)
  - Périodes historiques

## 4. Bonnes Pratiques Établies

1. **Gestion des Dates** :
   - Utiliser des comparaisons par année/mois plutôt que par jour
   - Prévoir des cas de chevauchement de périodes

2. **Validation des Données** :
   - Implémenter des flags de validation explicites
   - Logger les erreurs de manière détaillée
   - Permettre une validation flexible (tolérance sur les dates)

3. **Maintenance** :
   - Documenter les cas particuliers
   - Maintenir un historique des problèmes résolus
   - Prévoir les futurs changements de codes

## 5. Points d'Attention Futurs

1. Surveiller les prochains changements de codes géographiques
2. Maintenir à jour les périodes de validité
3. Vérifier régulièrement les cas particuliers
4. Adapter la logique pour les nouveaux cas similaires