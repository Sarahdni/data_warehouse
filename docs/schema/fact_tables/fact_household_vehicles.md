# Documentation de FACT_HOUSEHOLD_VEHICLES

## 1. Description Générale
La table `fact_household_vehicles` est une table de fait qui stocke les données relatives aux véhicules par ménage au niveau des secteurs statistiques. Elle permet d'analyser la possession de véhicules par ménage à différents niveaux géographiques.

## 2. Structure

### 2.1 Clés et Identifiants
- `id_household_vehicles_sk` (BIGSERIAL) - Clé primaire surrogate
- `id_date` (INTEGER) - Clé étrangère vers dim_date
- `id_geography` (INTEGER) - Clé étrangère vers dim_geography
- `id_sector_sk` (INTEGER) - Clé étrangère vers dim_statistical_sectors

### 2.2 Mesures
- `ms_households` (INTEGER) - Nombre de ménages
- `ms_vehicles` (INTEGER) - Nombre de véhicules
- `rt_vehicles_per_household` (DECIMAL(5,2)) - Ratio calculé véhicules/ménages

### 2.3 Traçabilité
- `id_batch` (INTEGER) - Identifiant du lot de chargement
- `fl_current` (BOOLEAN) - Indicateur de version courante
- `dt_created` (TIMESTAMP) - Date de création
- `dt_updated` (TIMESTAMP) - Date de dernière mise à jour

## 3. Contraintes et Index

### 3.1 Contraintes
- `chk_households_positive` : ms_households >= 0
- `chk_vehicles_positive` : ms_vehicles >= 0
- `chk_ratio_valid` : rt_vehicles_per_household >= 0
- Clés étrangères vers :
  - dim_date
  - dim_geography
  - dim_statistical_sectors

### 3.2 Index
- `idx_fact_vehicles_date` sur id_date
- `idx_fact_vehicles_geography` sur id_geography
- `idx_fact_vehicles_batch` sur id_batch
- `idx_fact_vehicles_current` sur fl_current

## 4. Processus de Chargement

### 4.1 Validation Préalable
```sql
CALL clean_staging.validate_household_vehicles_sectors(batch_id);
```
Valide :
- Format des codes secteur
- Format des codes REFNIS
- Validité des comptages

### 4.2 Chargement
```sql
CALL dw.load_fact_household_vehicles(batch_id, year, delete_existing);
```

## 5. Défis Techniques et Solutions

### 5.1 Gestion des Secteurs Inconnus
**Problème** : Certains secteurs se terminent par 'ZZZZ', indiquant des données agrégées ou inconnues.
**Solution** : 
- Utilisation d'un LEFT JOIN spécifique
- Mapping vers un secteur 'UNKNOWN' dans dim_statistical_sectors
```sql
CASE 
    WHEN cd_sector LIKE '%ZZZZ' THEN 
        (SELECT id_sector_sk FROM dim_statistical_sectors WHERE cd_sector = 'UNKNOWN')
    ELSE s.id_sector_sk
END
```

### 5.2 Gestion de la Temporalité
**Problème** : Les codes REFNIS et secteurs ont des périodes de validité.
**Solution** : 
- Jointures avec conditions temporelles
- Utilisation de MAKE_DATE pour la comparaison des dates
```sql
AND dt_start <= MAKE_DATE(p_year, 1, 1)
AND (dt_end >= MAKE_DATE(p_year, 12, 31) OR dt_end IS NULL)
```

### 5.3 Calcul des Ratios
**Problème** : Gestion des divisions par zéro dans le calcul du ratio véhicules/ménages.
**Solution** : 
```sql
CASE
    WHEN ms_households > 0 THEN
        ROUND(CAST(ms_vehicles AS DECIMAL) / ms_households, 2)
    ELSE NULL
END
```

## 6. Bonnes Pratiques

### 6.1 Validation des Données
1. Toujours exécuter validate_household_vehicles_sectors avant le chargement
2. Vérifier les résultats de validation
3. Corriger les données source si nécessaire

### 6.2 Chargement des Données
1. Vérifier l'existence de l'année dans dim_date
2. Considérer l'utilisation de p_delete_existing pour la gestion des versions
3. Vérifier le nombre de lignes chargées

### 6.3 Maintenance
1. Surveiller la croissance de la table
2. Maintenir les index régulièrement
3. Archiver les anciennes versions si nécessaire

## 7. Requêtes Utiles

### 7.1 Vérification des Chargements
```sql
SELECT d.cd_year, 
       COUNT(*) as nb_records,
       AVG(rt_vehicles_per_household) as avg_ratio
FROM dw.fact_household_vehicles f
JOIN dw.dim_date d ON d.id_date = f.id_date
WHERE f.fl_current = TRUE
GROUP BY d.cd_year
ORDER BY d.cd_year;
```

### 7.2 Analyse par Niveau Géographique
```sql
SELECT g.cd_refnis,
       SUM(f.ms_households) as total_households,
       SUM(f.ms_vehicles) as total_vehicles,
       ROUND(AVG(f.rt_vehicles_per_household), 2) as avg_ratio
FROM dw.fact_household_vehicles f
JOIN dw.dim_geography g ON g.id_geography = f.id_geography
WHERE f.fl_current = TRUE
GROUP BY g.cd_refnis;
```

## 8. Résolution de Problèmes

### 8.1 Données Manquantes
- Vérifier la validité des codes secteur et REFNIS
- Contrôler les périodes de validité
- Vérifier la présence de secteurs ZZZZ

### 8.2 Incohérences
- Valider les ratios véhicules/ménages
- Vérifier les jointures avec dim_geography
- Contrôler les doublons potentiels