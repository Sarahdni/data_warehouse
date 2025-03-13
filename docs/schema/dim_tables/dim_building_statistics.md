# Documentation de DIM_BUILDING_STATISTICS

## 1. Description Générale
La table `dim_building_statistics` est une dimension de référence qui catégorise les différents types de statistiques liées aux bâtiments en Belgique. Elle couvre des aspects variés tels que la surface, les garages, les salles de bain, les périodes de construction et les équipements.

## 2. Structure

### 2.1 Clés et Identifiants
- `cd_statistic_type` (VARCHAR(10)) - Clé primaire
  - Format: T[0-9]+(\.[0-9]+)? (ex: T1, T3.1, T4.2)
  - Identifie uniquement chaque type de statistique

### 2.2 Attributs de Classification
- `cd_statistic_category` (VARCHAR(50))
  - Catégories validées : TOTAL, SURFACE, GARAGE, BATHROOM, CONSTRUCTION_PERIOD, EQUIPMENT, DWELLING
  - Définit le groupement principal des statistiques

### 2.3 Attributs de Mesure
- `nb_min_value` (DECIMAL)
  - Valeur minimale pour les statistiques numériques
  - NULL pour les statistiques non numériques
- `nb_max_value` (DECIMAL)
  - Valeur maximale pour les statistiques numériques
  - NULL pour les valeurs ouvertes ou non numériques
- `tx_unit` (VARCHAR(10))
  - Unité de mesure (m², année, etc.)

### 2.4 Attributs Descriptifs Multilingues
- `tx_statistic_type_fr` : Description en français
- `tx_statistic_type_nl` : Description en néerlandais
- `tx_statistic_type_de` : Description en allemand
- `tx_statistic_type_en` : Description en anglais

### 2.5 Attributs Temporels
- `dt_valid_from` : Date de début de validité
- `dt_valid_to` : Date de fin de validité
- `dt_created` : Date de création
- `dt_updated` : Date de dernière mise à jour

## 3. Catégories de Statistiques

### 3.1 TOTAL (T1)
- Statistiques globales sur le nombre de bâtiments
- Pas de plages de valeurs

### 3.2 SURFACE (T3.1-T3.4)
- Classification par superficie au sol
- Plages définies :
  - < 45 m²
  - 45-64 m²
  - 65-104 m²
  - > 104 m²

### 3.3 GARAGE (T3.5)
- Statistiques sur les bâtiments avec garage/parking
- Comptage binaire (présence/absence)

### 3.4 BATHROOM (T3.6)
- Statistiques sur les bâtiments avec salle de bain
- Comptage binaire (présence/absence)

### 3.5 CONSTRUCTION_PERIOD (T3.7.1-T6.2)
- Classification par période de construction
- Périodes historiques définies :
  - Avant 1900
  - 1900-1918
  - 1919-1945
  - 1946-1961
  - 1962-1970
  - 1971-1981
  - 1982-1991
  - 1992-2001
  - 2002-2011
  - Après 2011

### 3.6 EQUIPMENT (T7.2)
- Statistiques sur les équipements
- Focus sur le chauffage central/climatisation

### 3.7 DWELLING (T8)
- Statistiques sur les unités de logement
- Comptage des logements

## 4. Gestion des Versions
La table implémente une gestion de versions de type SCD (Slowly Changing Dimension) Type 2 avec :
- Dates de validité (dt_valid_from, dt_valid_to)
- Traçabilité des modifications (dt_created, dt_updated)

## 5. Requêtes Utiles

### 5.1 Consultation par Catégorie
```sql
SELECT cd_statistic_type,
       tx_statistic_type_fr,
       nb_min_value,
       nb_max_value,
       tx_unit
FROM dw.DIM_BUILDING_STATISTICS
WHERE cd_statistic_category = 'SURFACE'
ORDER BY cd_statistic_type;
```

### 5.2 Recherche Multi-Langues
```sql
SELECT cd_statistic_type,
       tx_statistic_type_fr,
       tx_statistic_type_nl,
       tx_statistic_type_de,
       tx_statistic_type_en
FROM dw.DIM_BUILDING_STATISTICS
WHERE tx_statistic_type_fr ILIKE '%garage%'
   OR tx_statistic_type_nl ILIKE '%garage%'
   OR tx_statistic_type_de ILIKE '%garage%'
   OR tx_statistic_type_en ILIKE '%garage%';
```

### 5.3 Statistiques Actives
```sql
SELECT cd_statistic_type,
       cd_statistic_category,
       tx_statistic_type_fr,
       dt_valid_from,
       dt_valid_to
FROM dw.DIM_BUILDING_STATISTICS
WHERE dt_valid_to IS NULL
ORDER BY cd_statistic_category, cd_statistic_type;
```

## 6. Contraintes et Indexation

### 6.1 Contraintes Principales
- Check sur les catégories valides
- Check sur la cohérence des dates de validité
- Format standardisé des codes statistiques

### 6.2 Index
- Index sur cd_statistic_category
- Index sur les dates de validité

## 7. Bonnes Pratiques

1. Validation des Données
   - Vérifier la cohérence des plages de valeurs
   - Respecter le format des codes statistiques
   - Maintenir la cohérence des traductions

2. Utilisation des Catégories
   - Regrouper les analyses par catégorie
   - Respecter la hiérarchie des codes

3. Gestion Temporelle
   - Toujours vérifier la validité temporelle
   - Maintenir l'historique des modifications

4. Multilinguisme
   - Maintenir toutes les traductions à jour
   - Utiliser les libellés appropriés selon le contexte