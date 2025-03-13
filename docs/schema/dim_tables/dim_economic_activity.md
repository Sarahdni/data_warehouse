# Documentation de la Dimension des Activités Économiques

## 1. Vue d'ensemble

La dimension des activités économiques gère la nomenclature NACE-BEL avec :
- Une hiérarchie à 5 niveaux
- Un support multilingue (FR, NL, DE, EN)
- Une gestion historique (SCD Type 2)
- Un système de traçabilité des traductions manquantes

## 2. Structure du Projet

### 2.1 Organisation des Fichiers
```
project/
├── 01_staging/
│   ├── tables/
│   │   └── stg_ref_nacebel.sql         # Table de staging
│   ├── procedures/
│   │   └── load_ref_nacebel.sql        # Procédure de chargement staging
│   └── validation/
│       └── validate_ref_nacebel.sql    # Validation des données
├── 02_dim_tables/employment/
│   ├── procedures/
│   │   └── load_dim_economic_activity.sql # Procédure de chargement dimension
│   └── dim_economic_activity.sql       # Structure de la table
└── 04_views/employment/
    └── v_economic_activity.sql         # Vues métier
```

## 3. Structure des Tables

### 3.1 Table Dimensionnelle (dim_economic_activity)
```sql
id_economic_activity   SERIAL PK         # Identifiant technique
cd_economic_activity   VARCHAR(10)       # Code NACE-BEL
cd_parent_activity    VARCHAR(10) FK     # Code parent
cd_level             INTEGER            # Niveau hiérarchique (1-5)
tx_economic_activity_[fr/nl/de/en] TEXT # Libellés multilingues
dt_valid_from        DATE              # Début de validité
dt_valid_to          DATE              # Fin de validité
fl_current           BOOLEAN           # Version courante
id_batch             INTEGER           # ID du lot de chargement
```

### 3.2 Hiérarchie NACE-BEL
1. Niveau 1 (Section) : Une lettre (ex: A)
2. Niveau 2 (Division) : 2 chiffres (ex: 01)
3. Niveau 3 (Groupe) : 3 chiffres (ex: 011)
4. Niveau 4 (Classe) : 4 chiffres (ex: 0111)
5. Niveau 5 (Sous-classe) : 5 chiffres (ex: 01110)

## 4. Gestion des Traductions

### 4.1 Table de Suivi (metadata.missing_translations)
```sql
id_missing_translation SERIAL PK    # Identifiant unique
id_batch              INTEGER      # Batch concerné
cd_nacebel            VARCHAR(10)  # Code NACE-BEL
tx_original_fr        TEXT         # Libellé français original
missing_languages     TEXT[]       # Langues manquantes
fl_processed          BOOLEAN      # Statut de traitement
```

### 4.2 Processus de Traduction
1. Détection lors de la validation
2. Enregistrement dans missing_translations
3. Marquage temporaire (TO TRANSLATE/ZU ÜBERSETZEN)
4. Suivi via v_missing_translations

## 5. Processus ETL

### 5.1 Flux de Données
1. Chargement CSV → staging (load_ref_nacebel)
2. Validation des données (validate_ref_nacebel)
3. Traitement des traductions (process_missing_translations)
4. Chargement dimension (load_dim_economic_activity)

### 5.2 Contraintes et Validations
- Format des codes selon le niveau
- Intégrité hiérarchique
- Complétude des traductions
- Cohérence des dates

## 6. Vues Métier

### 6.1 v_economic_activity_hierarchy
- Navigation récursive dans la hiérarchie
- Chemins complets dans toutes les langues
- Gestion des versions courantes/historiques

### 6.2 v_economic_activity_by_level
- Statistiques par niveau hiérarchique
- Comptage des activités
- Plages de codes

## 7. Maintenance

### 7.1 Chargement Initial
```sql
CALL staging.load_ref_nacebel('nacebel_2008.csv', TRUE);
CALL staging.validate_ref_nacebel(batch_id, FALSE);
CALL metadata.process_missing_translations(batch_id);
CALL dw.load_dim_economic_activity(batch_id, CURRENT_DATE);
```

### 7.2 Mises à Jour
- Gestion SCD Type 2
- Conservation de l'historique
- Traçabilité des changements

## 8. Statistiques Actuelles

### 8.1 Volumétrie
- Niveau 1 (Sections) : 21 codes
- Niveau 2 (Divisions) : 88 codes
- Niveau 3 (Groupes) : 272 codes
- Niveau 4 (Classes) : 615 codes
- Niveau 5 (Sous-classes) : 943 codes

### 8.2 Traductions
- Français : 100% complet
- Néerlandais : 100% complet
- Allemand : Variable
- Anglais : Variable

## 9. Exemples d'Utilisation

### 9.1 Requêtes Courantes
```sql
-- Hiérarchie complète d'une activité
SELECT * FROM dw.v_economic_activity_hierarchy
WHERE cd_economic_activity = '01110';

-- Activités par niveau
SELECT * FROM dw.v_economic_activity_by_level;

-- Traductions manquantes
SELECT * FROM metadata.v_missing_translations
WHERE fl_processed = FALSE;
```

### 9.2 Bonnes Pratiques
1. Toujours utiliser les vues pour la navigation hiérarchique
2. Vérifier fl_current pour les données courantes
3. Utiliser les codes du niveau le plus détaillé possible
4. Suivre régulièrement les traductions manquantes