# Documentation de DIM_ENTREPRISE_SIZE_EMPLOYEES

## 1. Description Générale
La table `dim_entreprise_size_employees` est une dimension de référence qui catégorise les entreprises selon leur taille, basée sur le nombre d'employés. Elle utilise une classification standardisée de S0 à S8 pour permettre une analyse cohérente des statistiques d'entreprises.

## 2. Structure

### 2.1 Clés et Identifiants
- `cd_size_class` (VARCHAR(5)) - Clé primaire
  - Format: S[0-8]
  - Identifie de manière unique chaque classe de taille
  - Classification progressive des plus petites aux plus grandes entreprises

### 2.2 Attributs Numériques
- `cd_min_employees` : Nombre minimum d'employés dans la classe
- `cd_max_employees` : Nombre maximum d'employés dans la classe
  - NULL pour la classe "500 employés ou plus"

### 2.3 Attributs Descriptifs
- Libellés multilingues :
  - `tx_size_class_fr` : Description en français
  - `tx_size_class_nl` : Description en néerlandais
  - `tx_size_class_de` : Description en allemand
  - `tx_size_class_en` : Description en anglais

### 2.4 Attributs Temporels
- `dt_valid_from` : Date de début de validité
- `dt_valid_to` : Date de fin de validité
- `fl_current` : Indicateur de version courante
- `dt_created` : Date de création
- `dt_updated` : Date de dernière mise à jour

## 3. Classes de Taille

### 3.1 Classification Détaillée
1. **S0 : Sans Employé**
   - Min: 0, Max: 0
   - Entreprises individuelles
   - Travailleurs indépendants

2. **S1 : Très Petites Entreprises (1-4)**
   - Min: 1, Max: 4
   - Micro-entreprises
   - Structure familiale

3. **S2 : Petites Entreprises (5-9)**
   - Min: 5, Max: 9
   - Très petites structures
   - Gestion directe

4. **S3 : Petites Entreprises (10-19)**
   - Min: 10, Max: 19
   - Petites structures
   - Organisation simple

5. **S4 : Entreprises Moyennes (20-49)**
   - Min: 20, Max: 49
   - Structures moyennes
   - Organisation départementale

6. **S5 : Entreprises Moyennes (50-99)**
   - Min: 50, Max: 99
   - Moyennes structures
   - Organisation complexe

7. **S6 : Grandes Entreprises (100-199)**
   - Min: 100, Max: 199
   - Grandes structures
   - Organisation multi-niveau

8. **S7 : Grandes Entreprises (200-499)**
   - Min: 200, Max: 499
   - Très grandes structures
   - Organisation matricielle

9. **S8 : Très Grandes Entreprises (500+)**
   - Min: 500, Max: NULL
   - Structures majeures
   - Organisation complexe internationale

## 4. Gestion des Versions

La table implémente une gestion de versions de type SCD (Slowly Changing Dimension) Type 2 avec :
- Dates de validité (dt_valid_from, dt_valid_to)
- Indicateur de version courante (fl_current)
- Traçabilité des modifications (dt_created, dt_updated)

## 5. Requêtes Utiles

### 5.1 Consultation des Classes Actives
```sql
SELECT cd_size_class,
       cd_min_employees,
       cd_max_employees,
       tx_size_class_fr
FROM dw.dim_entreprise_size_employees
WHERE fl_current = TRUE
ORDER BY cd_min_employees;
```

### 5.2 Recherche par Plage d'Employés
```sql
SELECT cd_size_class,
       tx_size_class_fr,
       cd_min_employees,
       cd_max_employees
FROM dw.dim_entreprise_size_employees
WHERE cd_min_employees <= 100 
AND (cd_max_employees >= 100 OR cd_max_employees IS NULL)
AND fl_current = TRUE;
```

### 5.3 Affichage des Plages avec Formatage
```sql
SELECT cd_size_class,
       CASE 
           WHEN cd_max_employees IS NULL THEN cd_min_employees || '+'
           ELSE cd_min_employees || '-' || cd_max_employees
       END as plage_employes,
       tx_size_class_fr
FROM dw.dim_entreprise_size_employees
WHERE fl_current = TRUE
ORDER BY cd_min_employees;
```

## 6. Notes d'Implémentation

### 6.1 Contraintes
- Format des codes standardisé (S[0-8])
- Cohérence des plages d'employés
- Non-nullité des descriptions multilingues
- Validité des dates de version

### 6.2 Indexation
- Index sur fl_current
- Index sur les plages d'employés
- Index sur les dates de validité

### 6.3 Triggers
- Mise à jour automatique de dt_updated
- Validation des plages d'employés

## 7. Bonnes Pratiques

1. Utilisation des Codes
   - Toujours utiliser les codes S[0-8] comme clés de liaison
   - Ne pas utiliser les plages d'employés directement

2. Gestion des Plages
   - Traiter le cas NULL pour S8 (500+)
   - Vérifier les chevauchements

3. Requêtes
   - Filtrer sur fl_current par défaut
   - Utiliser les dates pour l'historique

4. Multilinguisme
   - Adapter les libellés à la langue de l'utilisateur
   - Maintenir tous les libellés à jour