# Documentation de DIM_UNEMPLOYMENT_TYPE

## 1. Description Générale
La table `dim_unemployment_type` est une dimension de référence qui catégorise les différents types de taux de chômage. Elle distingue notamment entre le chômage standard et le chômage de longue durée, permettant une analyse différenciée des statistiques de l'emploi.

## 2. Structure

### 2.1 Clés et Identifiants
- `cd_unemp_type` (VARCHAR(20)) - Clé primaire
  - Format: Chaîne de caractères en majuscules
  - Valeurs: 'NORMAL', 'LONG_TERM'
  - Identifie de manière unique chaque type de chômage

### 2.2 Attributs Descriptifs
- Libellés multilingues :
  - `tx_unemp_type_fr` : Description en français
  - `tx_unemp_type_nl` : Description en néerlandais
  - `tx_unemp_type_de` : Description en allemand
  - `tx_unemp_type_en` : Description en anglais

### 2.3 Attributs Temporels
- `dt_valid_from` : Date de début de validité
- `dt_valid_to` : Date de fin de validité
- `fl_current` : Indicateur de version courante
- `dt_created` : Date de création
- `dt_updated` : Date de dernière mise à jour

## 3. Classifications

### 3.1 Types de Chômage
1. Chômage Standard (NORMAL)
   - Taux de chômage classique
   - Mesure la proportion de la population active sans emploi
   - Inclut toutes les durées de chômage

2. Chômage de Longue Durée (LONG_TERM)
   - Mesure le chômage prolongé
   - Concerne les personnes sans emploi depuis une période prolongée
   - Indicateur de difficultés structurelles du marché du travail

## 4. Gestion des Versions

La table implémente une gestion de versions de type SCD (Slowly Changing Dimension) Type 2 avec :
- Dates de validité (dt_valid_from, dt_valid_to)
- Indicateur de version courante (fl_current)
- Traçabilité des modifications (dt_created, dt_updated)

## 5. Requêtes Utiles

### 5.1 Consultation des Types Actifs
```sql
SELECT cd_unemp_type,
       tx_unemp_type_fr,
       tx_unemp_type_nl
FROM dw.dim_unemployment_type
WHERE fl_current = TRUE
ORDER BY cd_unemp_type;
```

### 5.2 Recherche Multilingue
```sql
SELECT cd_unemp_type,
       tx_unemp_type_fr,
       tx_unemp_type_nl,
       tx_unemp_type_de,
       tx_unemp_type_en
FROM dw.dim_unemployment_type
WHERE tx_unemp_type_fr ILIKE '%longue durée%'
   OR tx_unemp_type_nl ILIKE '%langdurig%';
```

### 5.3 Historique des Modifications
```sql
SELECT cd_unemp_type,
       dt_valid_from,
       dt_valid_to,
       fl_current,
       tx_unemp_type_fr
FROM dw.dim_unemployment_type
WHERE cd_unemp_type = 'NORMAL'
ORDER BY dt_valid_from DESC;
```

## 6. Notes d'Implémentation

### 6.1 Contraintes
- Format des codes standardisé
- Cohérence des dates de validité assurée par contrainte
- Non-nullité des descriptions multilingues

### 6.2 Indexation
- Index sur fl_current pour les requêtes courantes
- Index sur les dates pour les recherches historiques

### 6.3 Triggers
- Mise à jour automatique de dt_updated
- Gestion automatique des timestamps

## 7. Bonnes Pratiques

1. Toujours utiliser les codes standardisés comme clés de liaison
2. Vérifier la version courante avec fl_current pour les requêtes standard
3. Utiliser les dates de validité pour les analyses historiques
4. Privilégier les libellés correspondant à la langue de l'utilisateur