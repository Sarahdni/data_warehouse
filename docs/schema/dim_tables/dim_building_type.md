# Documentation de DIM_BUILDING_TYPE

## 1. Description Générale
La table `dim_building_type` est une dimension de référence qui catégorise les différents types de bâtiments selon la classification standardisée belge. Elle utilise une nomenclature de R1 à R6 pour classifier les bâtiments selon leur style de construction et leur usage.

## 2. Structure

### 2.1 Clés et Identifiants
- `cd_building_type` (VARCHAR(2)) - Clé primaire
  - Format: R[1-6]
  - Identifie de manière unique chaque type de bâtiment

### 2.2 Attributs Descriptifs
- Libellés multilingues :
  - `tx_building_type_fr` : Description en français
  - `tx_building_type_nl` : Description en néerlandais
  - `tx_building_type_de` : Description en allemand
  - `tx_building_type_en` : Description en anglais

### 2.3 Attributs Temporels
- `dt_valid_from` : Date de début de validité
- `dt_valid_to` : Date de fin de validité
- `fl_current` : Indicateur de version courante
- `dt_created` : Date de création
- `dt_updated` : Date de dernière mise à jour

## 3. Classifications

### 3.1 Types de Bâtiments (R1-R6)
1. R1 : Maisons de type fermé
   - Bâtiments mitoyens des deux côtés
   - Style urbain traditionnel

2. R2 : Maisons de type demi-fermé
   - Bâtiments mitoyens d'un seul côté
   - Style semi-urbain

3. R3 : Maisons de type ouvert, fermes, châteaux
   - Bâtiments isolés
   - Inclut les propriétés rurales et historiques

4. R4 : Buildings et immeubles à appartements
   - Bâtiments résidentiels collectifs
   - Structures multi-étages

5. R5 : Maisons de commerce
   - Bâtiments à usage commercial
   - Souvent avec commerce au rez-de-chaussée

6. R6 : Tous les autres bâtiments
   - Catégorie résiduelle
   - Bâtiments ne correspondant pas aux autres catégories

## 4. Gestion des Versions

La table implémente une gestion de versions de type SCD (Slowly Changing Dimension) Type 2 avec :
- Dates de validité (dt_valid_from, dt_valid_to)
- Indicateur de version courante (fl_current)
- Traçabilité des modifications (dt_created, dt_updated)

## 5. Requêtes Utiles

### 5.1 Consultation des Types Actifs
```sql
SELECT cd_building_type,
       tx_building_type_fr,
       tx_building_type_nl
FROM dw.dim_building_type
WHERE fl_current = TRUE
ORDER BY cd_building_type;
```

### 5.2 Recherche Multilingue
```sql
SELECT cd_building_type,
       tx_building_type_fr,
       tx_building_type_nl,
       tx_building_type_de,
       tx_building_type_en
FROM dw.dim_building_type
WHERE tx_building_type_fr ILIKE '%commerce%'
   OR tx_building_type_nl ILIKE '%handel%'
   OR tx_building_type_de ILIKE '%Geschäft%'
   OR tx_building_type_en ILIKE '%commercial%';
```

### 5.3 Historique des Modifications
```sql
SELECT cd_building_type,
       dt_valid_from,
       dt_valid_to,
       fl_current,
       tx_building_type_fr
FROM dw.dim_building_type
WHERE cd_building_type = 'R1'
ORDER BY dt_valid_from DESC;
```

## 6. Notes d'Implémentation

### 6.1 Contraintes
- Format du code type vérifié par expression régulière
- Cohérence des dates de validité assurée par contrainte
- Non-nullité des descriptions multilingues

### 6.2 Indexation
- Index sur fl_current pour les requêtes courantes
- Index sur les dates pour les recherches historiques

### 6.3 Triggers
- Mise à jour automatique de dt_updated
- Gestion automatique des timestamps

## 7. Bonnes Pratiques

1. Toujours utiliser les codes (R1-R6) comme clés de liaison
2. Vérifier la version courante avec fl_current pour les requêtes standard
3. Utiliser les dates de validité pour les analyses historiques
4. Privilégier les libellés correspondant à la langue de l'utilisateur