# Documentation de DIM_BUILDING_PERMIT

## 1. Description Générale
La table `dim_building_permit` est une dimension de référence qui catégorise les différents types de permis de construire. Elle gère les permis pour les bâtiments résidentiels et non-résidentiels, incluant les nouvelles constructions et les rénovations.

## 2. Structure

### 2.1 Clés et Identifiants
- `id_permit_type` (SERIAL) - Clé primaire
- `cd_permit_class` (VARCHAR(20)) - Classification principale (RES/NONRES)
- `cd_permit_action` (VARCHAR(20)) - Type d'action (NEW/RENOVATION)
- `cd_measure_type` (VARCHAR(20)) - Type de mesure
- `tx_measure_unit` (VARCHAR(10)) - Unité de mesure

### 2.2 Attributs Descriptifs Multilingues
- `tx_descr_fr` : Description en français
- `tx_descr_nl` : Description en néerlandais
- `tx_descr_de` : Description en allemand
- `tx_descr_en` : Description en anglais

### 2.3 Attributs Temporels (SCD Type 2)
- `dt_start` : Date de début de validité
- `dt_end` : Date de fin de validité
- `fl_current` : Indicateur de version courante
- `id_batch` : ID du batch de chargement
- `dt_created` : Date de création
- `dt_updated` : Date de dernière mise à jour

## 3. Classifications

### 3.1 Classes de Permis (cd_permit_class)
1. RES : Résidentiel
   - Logements particuliers
   - Immeubles d'habitation
   - Projets résidentiels

2. NONRES : Non-résidentiel
   - Bâtiments commerciaux
   - Bâtiments industriels
   - Infrastructures publiques

### 3.2 Types d'Action (cd_permit_action)
1. NEW : Nouvelle construction
   - Construction depuis zéro
   - Nouveaux bâtiments

2. RENOVATION : Rénovation
   - Modifications d'existant
   - Réhabilitations
   - Transformations

### 3.3 Types de Mesure (cd_measure_type)
1. BUILDING : Nombre de bâtiments
2. DWELLING : Nombre de logements
3. APARTMENT : Nombre d'appartements
4. SINGLE_HOUSE : Nombre de maisons unifamiliales
5. TOTAL_SURFACE : Surface totale
6. VOLUME : Volume total

### 3.4 Unités de Mesure (tx_measure_unit)
- COUNT : Nombre d'unités
- M2 : Mètres carrés
- M3 : Mètres cubes

## 4. Contraintes et Validations

### 4.1 Contraintes sur les Classifications
- `chk_permit_class` : Valide RES ou NONRES
- `chk_permit_action` : Valide NEW ou RENOVATION
- `chk_measure_type` : Liste prédéfinie de types
- `chk_measure_unit` : Liste prédéfinie d'unités

### 4.2 Contraintes de Cohérence
```sql
CONSTRAINT chk_measure_coherence CHECK (
    (cd_measure_type IN ('BUILDING', 'DWELLING', 'APARTMENT', 'SINGLE_HOUSE') 
     AND tx_measure_unit = 'COUNT')
    OR
    (cd_measure_type = 'TOTAL_SURFACE' AND tx_measure_unit = 'M2')
    OR
    (cd_measure_type = 'VOLUME' AND tx_measure_unit = 'M3')
)
```

## 5. Index

### 5.1 Index Principaux
- `idx_building_permit_current` sur fl_current
- `idx_building_permit_dates` sur (dt_start, dt_end)
- `idx_building_permit_type` sur (cd_permit_class, cd_permit_action, cd_measure_type)

### 5.2 Index Unique
- `uk_building_permit_current` sur (cd_permit_class, cd_permit_action, cd_measure_type) WHERE fl_current = TRUE

## 6. Exemples de Données

### 6.1 Permis Résidentiels
```sql
SELECT cd_permit_class, cd_permit_action, cd_measure_type, tx_descr_fr
FROM dw.dim_building_permit
WHERE cd_permit_class = 'RES'
AND fl_current = TRUE;
```

### 6.2 Statistiques de Surface
```sql
SELECT cd_permit_class, cd_measure_type, tx_measure_unit, tx_descr_fr
FROM dw.dim_building_permit
WHERE cd_measure_type = 'TOTAL_SURFACE'
AND fl_current = TRUE;
```

## 7. Vues Associées

### 7.1 v_building_permit
- Vue des permis actuellement valides
- Tri automatique par classification
- Support multilingue

## 8. Bonnes Pratiques

1. Utilisation des Classifications
   - Respecter la cohérence mesure/unité
   - Utiliser les codes standards
   - Valider les combinaisons

2. Gestion des Versions
   - Maintenir l'historique des changements
   - Utiliser fl_current pour les données actives
   - Documenter les modifications majeures

3. Multilinguisme
   - Maintenir toutes les traductions à jour
   - Utiliser les descriptions appropriées
   - Vérifier la cohérence linguistique

4. Performance
   - Utiliser les index appropriés
   - Filtrer sur fl_current
   - Optimiser les requêtes fréquentes

## 9. Requêtes Utiles

### 9.1 Statistiques par Type
```sql
SELECT cd_permit_class,
       COUNT(*) as total_measures
FROM dw.dim_building_permit
WHERE fl_current = TRUE
GROUP BY cd_permit_class;
```

### 9.2 Recherche Multilingue
```sql
SELECT cd_permit_class,
       cd_permit_action,
       tx_descr_fr,
       tx_descr_nl
FROM dw.dim_building_permit
WHERE fl_current = TRUE
AND (tx_descr_fr ILIKE '%appartement%'
     OR tx_descr_nl ILIKE '%appartement%');
```

### 9.3 Historique des Modifications
```sql
SELECT cd_permit_class,
       cd_permit_action,
       dt_start,
       dt_end,
       fl_current
FROM dw.dim_building_permit
WHERE cd_permit_class = 'RES'
ORDER BY dt_start DESC;
```