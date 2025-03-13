# Documentation de DIM_EDUCATION_LEVEL

## 1. Description Générale
La table `dim_education_level` est une dimension de référence qui catégorise les différents niveaux d'éducation selon la classification internationale type de l'éducation (ISCED 2011). Cette classification est utilisée pour standardiser la représentation des niveaux d'éducation dans les statistiques démographiques et d'emploi.

## 2. Structure

### 2.1 Clés et Identifiants
- `cd_education_level` (VARCHAR(10)) - Clé primaire
  - Format: Numérique de 0 à 8
  - Correspond aux niveaux ISCED 2011
  - Identifie de manière unique chaque niveau d'éducation

### 2.2 Attributs Descriptifs
- Libellés multilingues :
  - `tx_education_level_fr` : Description en français
  - `tx_education_level_nl` : Description en néerlandais
  - `tx_education_level_de` : Description en allemand
  - `tx_education_level_en` : Description en anglais

### 2.3 Attributs Temporels
- `dt_valid_from` : Date de début de validité
- `dt_valid_to` : Date de fin de validité
- `fl_current` : Indicateur de version courante
- `dt_created` : Date de création
- `dt_updated` : Date de dernière mise à jour

## 3. Classifications ISCED 2011

### 3.1 Niveaux d'Éducation
1. **Niveau 0 : Inférieur au primaire**
   - Éducation de la petite enfance
   - Enseignement pré-primaire
   - Base pour l'apprentissage futur

2. **Niveau 1 : Primaire**
   - Éducation élémentaire
   - Acquisition des compétences fondamentales
   - Premier cycle de l'éducation de base

3. **Niveau 2 : Secondaire inférieur**
   - Premier cycle de l'enseignement secondaire
   - Renforcement des acquis du primaire
   - Préparation à la formation professionnelle

4. **Niveau 3 : Secondaire supérieur**
   - Deuxième cycle de l'enseignement secondaire
   - Formation générale ou technique
   - Accès aux études supérieures

5. **Niveau 4 : Post-secondaire non-supérieur**
   - Enseignement post-secondaire non-tertiaire
   - Formation professionnelle avancée
   - Transition vers le marché du travail

6. **Niveau 5 : Supérieur court**
   - Enseignement supérieur de cycle court
   - Formation professionnelle supérieure
   - Orientation pratique et technique

7. **Niveau 6 : Bachelier**
   - Licence ou niveau équivalent
   - Formation académique ou professionnelle
   - Premier niveau de l'enseignement supérieur

8. **Niveau 7 : Master**
   - Master ou niveau équivalent
   - Spécialisation avancée
   - Formation théorique approfondie

9. **Niveau 8 : Doctorat**
   - Doctorat ou niveau équivalent
   - Recherche avancée
   - Plus haut niveau de qualification

## 4. Gestion des Versions

La table implémente une gestion de versions de type SCD (Slowly Changing Dimension) Type 2 avec :
- Dates de validité (dt_valid_from, dt_valid_to)
- Indicateur de version courante (fl_current)
- Traçabilité des modifications (dt_created, dt_updated)

## 5. Requêtes Utiles

### 5.1 Consultation des Niveaux Actifs
```sql
SELECT cd_education_level,
       tx_education_level_fr,
       tx_education_level_nl
FROM dw.dim_education_level
WHERE fl_current = TRUE
ORDER BY cd_education_level::integer;
```

### 5.2 Recherche Multilingue
```sql
SELECT cd_education_level,
       tx_education_level_fr,
       tx_education_level_nl,
       tx_education_level_de,
       tx_education_level_en
FROM dw.dim_education_level
WHERE tx_education_level_fr ILIKE '%supérieur%'
   OR tx_education_level_nl ILIKE '%hoger%';
```

### 5.3 Historique des Modifications
```sql
SELECT cd_education_level,
       dt_valid_from,
       dt_valid_to,
       fl_current,
       tx_education_level_fr
FROM dw.dim_education_level
WHERE cd_education_level = '6'
ORDER BY dt_valid_from DESC;
```

## 6. Notes d'Implémentation

### 6.1 Contraintes
- Format des codes numériques (0-8)
- Cohérence des dates de validité
- Non-nullité des descriptions multilingues

### 6.2 Indexation
- Index sur fl_current pour les requêtes courantes
- Index sur les dates pour les recherches historiques

### 6.3 Triggers
- Mise à jour automatique de dt_updated
- Gestion automatique des timestamps

## 7. Bonnes Pratiques

1. Toujours utiliser les codes numériques comme clés de liaison
2. Vérifier la version courante avec fl_current pour les requêtes standard
3. Utiliser les dates de validité pour les analyses historiques
4. Privilégier les libellés correspondant à la langue de l'utilisateur