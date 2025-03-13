# Documentation des Biens Résidentiels

## Emplacement des Fichiers
- Table: `02_dim_tables/real_estate/dim_residential_building.sql`
- Vue: `04_views/real_estate/v_residential_building.sql`

## 1. Table DIM_RESIDENTIAL_BUILDING

### 1.1 Description Générale
La table `dim_residential_building` est une dimension de référence qui catégorise les différents types de biens résidentiels utilisés dans les statistiques de prix immobiliers. Elle utilise une nomenclature standardisée (B001, B002, B00A, B015) pour classifier les biens selon leur type et leur nombre de façades.

### 1.2 Structure

#### 1.2.1 Clés et Identifiants
- `cd_residential_type` (VARCHAR(4)) - Clé primaire
  - Format: B[0-9A]{3}
  - Exemple: B001, B002, B00A, B015
- `nb_display_order` (INTEGER) - Ordre d'affichage standardisé
  - Valeurs: 1-10
  - Utilisé pour l'affichage cohérent des rapports

#### 1.2.2 Attributs Descriptifs
- Libellés multilingues :
  - `tx_residential_type_fr` : Description en français
  - `tx_residential_type_nl` : Description en néerlandais
  - `tx_residential_type_de` : Description en allemand
  - `tx_residential_type_en` : Description en anglais

#### 1.2.3 Attributs Temporels
- `dt_valid_from` : Date de début de validité
- `dt_valid_to` : Date de fin de validité
- `fl_current` : Indicateur de version courante
- `dt_created` : Date de création
- `dt_updated` : Date de dernière mise à jour

### 1.3 Classifications

#### 1.3.1 Types de Biens Résidentiels
1. B00A : Toutes maisons (Total)
   - Agrégat de toutes les catégories de maisons
   - Ordre d'affichage : 1

2. B001 : Maisons 2 ou 3 façades
   - Maisons mitoyennes ou semi-mitoyennes
   - Ordre d'affichage : 2

3. B002 : Maisons 4 façades ou plus
   - Maisons isolées
   - Ordre d'affichage : 3

4. B015 : Appartements
   - Unités en copropriété
   - Ordre d'affichage : 4

### 1.4 Gestion des Versions

La table implémente une gestion de versions de type SCD (Slowly Changing Dimension) Type 2 avec :
- Dates de validité (dt_valid_from, dt_valid_to)
- Indicateur de version courante (fl_current)
- Traçabilité des modifications (dt_created, dt_updated)

## 2. Vue V_RESIDENTIAL_BUILDING

### 2.1 Description
La vue `v_residential_building` fournit un accès simplifié aux données courantes des types de biens résidentiels, avec un tri automatique selon l'ordre d'affichage défini.

### 2.2 Structure
- Hérite des colonnes principales de la table dimension :
  - cd_residential_type
  - tx_residential_type_fr, tx_residential_type_nl, tx_residential_type_de, tx_residential_type_en
  - nb_display_order
- Filtre automatiquement sur les versions courantes (fl_current = TRUE)
- Tri automatique par nb_display_order

### 2.3 Utilisation
La vue est particulièrement utile pour :
- Les rapports standards
- Les interfaces utilisateur
- Les tableaux de bord
- L'affichage ordonné des types de biens

## 3. Requêtes Utiles

### 3.1 Consultation des Types Actifs avec Ordre (via la vue)
```sql
SELECT cd_residential_type,
       tx_residential_type_fr,
       tx_residential_type_nl
FROM dw.v_residential_building;
```

### 3.2 Recherche par Type de Bien (via la table)
```sql
SELECT cd_residential_type,
       tx_residential_type_fr,
       tx_residential_type_nl,
       tx_residential_type_de,
       tx_residential_type_en
FROM dw.dim_residential_building
WHERE cd_residential_type IN ('B001', 'B002')
  AND fl_current = TRUE;
```

### 3.3 Historique des Modifications
```sql
SELECT cd_residential_type,
       dt_valid_from,
       dt_valid_to,
       fl_current,
       tx_residential_type_fr
FROM dw.dim_residential_building
WHERE cd_residential_type = 'B001'
ORDER BY dt_valid_from DESC;
```

## 4. Notes d'Implémentation

### 4.1 Contraintes (Table)
- Format du code type vérifié par expression régulière
- Cohérence des dates de validité assurée par contrainte
- Ordre d'affichage limité entre 1 et 10
- Non-nullité des descriptions multilingues

### 4.2 Indexation
- Index sur fl_current pour les requêtes courantes
- Index sur les dates pour les recherches historiques
- Index sur l'ordre d'affichage pour les tris

### 4.3 Triggers
- Mise à jour automatique de dt_updated
- Gestion automatique des timestamps

## 5. Bonnes Pratiques

1. Utiliser la vue `v_residential_building` pour :
   - Les rapports standards
   - L'affichage ordonné des types
   - Les requêtes ne nécessitant que les données courantes

2. Utiliser la table `dim_residential_building` pour :
   - Les requêtes nécessitant l'historique
   - Les mises à jour de données
   - Les analyses temporelles

3. Maintenance :
   - Respecter l'ordre d'affichage pour une présentation cohérente
   - Maintenir la cohérence des ordres d'affichage lors des insertions
   - Vérifier la cohérence des dates lors des mises à jour

4. Multilinguisme :
   - Utiliser les libellés correspondant à la langue de l'utilisateur
   - Maintenir tous les libellés à jour dans toutes les langues