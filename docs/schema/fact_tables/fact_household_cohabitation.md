# Documentation de FACT_HOUSEHOLD_COHABITATION

## 1. Description Générale
La table `fact_household_cohabitation` est une table de fait qui stocke les statistiques de cohabitation des ménages. Elle permet d'analyser les patterns de cohabitation selon différents critères démographiques tels que l'âge, le sexe, et la nationalité.

## 2. Structure

### 2.1 Clés et Identifiants
- `id_fact_household_cohabitation` (SERIAL) - Clé primaire
- `id_date` (INTEGER) - Clé étrangère vers dim_date
- `id_geography` (INTEGER) - Clé étrangère vers dim_geography
- `cd_sex` (CHAR(1)) - Code sexe (référence dim_sex)
- `cd_age_group` (VARCHAR(10)) - Code groupe d'âge (référence dim_age_group)
- `cd_nationality` (VARCHAR(10)) - Code nationalité (référence dim_nationality)
- `cd_cohabitation` (VARCHAR(5)) - Statut de cohabitation (référence dim_cohabitation_status)

### 2.2 Mesures
- `ms_count` (INTEGER) - Nombre de personnes dans la catégorie

### 2.3 Traçabilité
- `id_batch` (INTEGER) - Identifiant du lot de chargement
- `dt_created` (TIMESTAMP) - Date de création
- `dt_updated` (TIMESTAMP) - Date de dernière mise à jour

## 3. Contraintes et Index

### 3.1 Contraintes
- `chk_household_count` : ms_count >= 0
- Clés étrangères vers :
  - dim_date
  - dim_geography
  - dim_sex
  - dim_age_group
  - dim_nationality
  - dim_cohabitation_status

### 3.2 Index
- `idx_fact_household_date` sur id_date
- `idx_fact_household_geography` sur id_geography
- `idx_fact_household_batch` sur id_batch

## 4. Processus de Chargement

### 4.1 Chargement
```sql
CALL dw.load_fact_household_cohabitation(batch_id, truncate_flag);
```

Les paramètres sont :
- batch_id : Identifiant du lot à charger
- truncate_flag : Si TRUE, vide la table avant chargement

### 4.2 Transformation des Données
Principales transformations effectuées :
```sql
CASE WHEN c.fl_cohab = '1' THEN 'OUI'
     WHEN c.fl_cohab = '0' THEN 'NON'
     ELSE NULL
END as cd_cohabitation
```

## 5. Défis Techniques et Solutions

### 5.1 Gestion des Codes REFNIS
**Problème** : Les codes REFNIS peuvent avoir des formats différents.
**Solution** : 
```sql
LPAD(cd_rgn_refnis, 5, '0')
```

### 5.2 Jointure avec dim_date
**Problème** : Nécessité de lier uniquement avec les années complètes.
**Solution** : 
```sql
JOIN dw.dim_date d ON d.cd_year = c.cd_year::INTEGER
    AND d.cd_period_type = 'Y'
```

### 5.3 Validation des Données
**Problème** : S'assurer de la cohérence des comptages.
**Solution** : 
- Contrainte CHECK sur ms_count
- Validation des clés de référence

## 6. Bonnes Pratiques

### 6.1 Chargement des Données
1. Vérifier l'intégrité des données sources
2. Valider les codes de référence
3. Utiliser le paramètre truncate avec précaution

### 6.2 Maintenance
1. Surveiller la croissance de la table
2. Maintenir les index régulièrement
3. Vérifier régulièrement les performances des requêtes

### 6.3 Qualité des Données
1. Vérifier les valeurs nulles
2. Valider les totaux par catégorie
3. Contrôler la cohérence temporelle

## 7. Requêtes Utiles

### 7.1 Analyse par Année et Sexe
```sql
SELECT 
    d.cd_year,
    f.cd_sex,
    SUM(f.ms_count) as total_persons,
    COUNT(DISTINCT f.cd_cohabitation) as nb_cohabitation_types
FROM dw.fact_household_cohabitation f
JOIN dw.dim_date d ON d.id_date = f.id_date
GROUP BY d.cd_year, f.cd_sex
ORDER BY d.cd_year, f.cd_sex;
```

### 7.2 Distribution par Âge et Cohabitation
```sql
SELECT 
    f.cd_age_group,
    f.cd_cohabitation,
    SUM(f.ms_count) as total_count,
    ROUND(100.0 * SUM(f.ms_count) / SUM(SUM(f.ms_count)) 
        OVER (PARTITION BY f.cd_age_group), 2) as percentage
FROM dw.fact_household_cohabitation f
WHERE f.id_date = (SELECT MAX(id_date) FROM dw.fact_household_cohabitation)
GROUP BY f.cd_age_group, f.cd_cohabitation
ORDER BY f.cd_age_group, f.cd_cohabitation;
```

## 8. Résolution de Problèmes

### 8.1 Données Manquantes
- Vérifier la présence des codes dans les dimensions
- Contrôler l'exhaustivité des données sources
- Valider les périodes de référence

### 8.2 Incohérences
- Vérifier les totaux par catégorie
- Contrôler les distributions statistiques
- Valider les règles métier (ex: âge vs cohabitation)

### 8.3 Performances
- Analyser le plan d'exécution des requêtes
- Vérifier l'utilisation des index
- Optimiser les requêtes fréquentes