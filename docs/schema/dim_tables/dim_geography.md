# Documentation de la Dimension Géographique

## 1. Vue d'ensemble

La dimension géographique a été implémentée avec une approche SCD Type 2 pour gérer l'historique des changements territoriaux. Elle couvre :
- La hiérarchie NUTS/LAU belge complète
- Les codes REFNIS communaux
- Le support multilingue (FR, NL, DE, EN)
- L'historisation des changements territoriaux

## 2. Structure du Projet

### 2.1 Organisation des Fichiers
```
project/
├── 01_staging/
│   ├── tables/
│   │   └── stg_ref_nuts_lau.sql           # Table de staging
│   ├── procedures/
│   │   └── load_ref_nuts_lau.sql          # Procédure de chargement
│   └── validation/
│       └── validate_ref_nuts_lau.sql      # Règles de validation
├── 02_dim_tables/geography/
│   └── dim_geography.sql                  # Table dimensionnelle
└── 05_functions/
    └── geography_utils.sql                # Fonctions utilitaires
```

### 2.2 Choix de Structure
- Staging séparé pour validation des données
- SCD Type 2 pour l'historisation
- Hiérarchie intégrée via auto-référence
- Support multilingue natif

## 3. Structure Détaillée

### 3.1 Clés et Identifiants
- `id_geography` (SERIAL) - Clé primaire
- `cd_lau` (VARCHAR(10)) - Code LAU/NUTS unique
- `cd_refnis` (VARCHAR(10)) - Code REFNIS (pour les communes)
- `cd_sector` (VARCHAR(10)) - Code du secteur statistique

### 3.2 Attributs Descriptifs Multilingues
- `tx_name_fr` : Nom en français
- `tx_name_nl` : Nom en néerlandais
- `tx_name_de` : Nom en allemand (optionnel)
- `tx_name_en` : Nom en anglais (optionnel)

### 3.3 Attributs de Hiérarchie
- `cd_level` (INTEGER) - Niveau hiérarchique
- `cd_parent` (VARCHAR(10)) - Code du niveau supérieur

### 3.4 Attributs Temporels (SCD Type 2)
- `dt_start` : Date de début de validité
- `dt_end` : Date de fin de validité
- `fl_current` : Indicateur de version courante
- `id_batch` : ID du batch de chargement
- `dt_created` : Date de création
- `dt_updated` : Date de dernière mise à jour

## 4. Niveaux Hiérarchiques

### 4.1 Niveau 1 : Régions
- Région flamande (BE2)
- Région wallonne (BE3)
- Région de Bruxelles-Capitale (BE1)

### 4.2 Niveau 2 : Provinces
- 10 provinces + Zone de Bruxelles-Capitale
- Codes NUTS 2

### 4.3 Niveau 3 : Arrondissements
- Divisions administratives
- Organisation territoriale intermédiaire
- Codes NUTS 3

### 4.4 Niveau 4 : Communes
- Unités administratives de base
- Identification par code REFNIS
- Codes LAU

### 4.5 Niveau 5 : Secteurs statistiques
- Plus petite unité territoriale
- Découpage statistique détaillé

## 5. Processus ETL

### 5.1 Chargement en Staging
```sql
CALL staging.load_ref_nuts_lau(
    'NUTS_LAU_2023.csv',
    TRUE  -- Truncate staging
);
```

### 5.2 Validation des Données
Contrôles effectués :
1. Champs obligatoires
```sql
SELECT * FROM staging.stg_ref_nuts_lau
WHERE CD_LAU IS NULL 
   OR CD_LVL IS NULL
   OR DT_VLDT_STRT IS NULL;
```

2. Format des codes
```sql
SELECT * FROM staging.stg_ref_nuts_lau
WHERE CD_LAU !~ '^(BE[0-9A-Z]{1,8}|[0-9]{5})$';
```

3. Cohérence des dates
```sql
SELECT * FROM staging.stg_ref_nuts_lau
WHERE DT_VLDT_STRT > DT_VLDT_STOP;
```

4. Intégrité hiérarchique
```sql
SELECT s1.* FROM staging.stg_ref_nuts_lau s1
LEFT JOIN staging.stg_ref_nuts_lau s2 
  ON s1.CD_LVL_SUP = s2.CD_LAU
WHERE s2.CD_LAU IS NULL;
```

### 5.3 Chargement en Dimension
Procédure complète avec gestion SCD Type 2 :
1. Fermeture des versions obsolètes
2. Insertion des nouvelles versions
3. Mise à jour des flags courants

## 6. Index et Performance

### 6.1 Index Principaux
```sql
CREATE INDEX idx_geography_lau ON dw.dim_geography(cd_lau);
CREATE INDEX idx_geography_refnis ON dw.dim_geography(cd_refnis);
CREATE INDEX idx_geography_sector ON dw.dim_geography(cd_sector);
CREATE INDEX idx_geography_current ON dw.dim_geography(fl_current);
CREATE INDEX idx_geography_hierarchy ON dw.dim_geography(cd_parent, cd_level);
CREATE INDEX idx_geography_dates ON dw.dim_geography(dt_start, dt_end);

-- Index unique pour les versions courantes
CREATE UNIQUE INDEX uk_geography_current 
ON dw.dim_geography(cd_lau) 
WHERE fl_current = TRUE;
```

### 6.2 Optimisations
- Index partiels pour les versions courantes
- Index composites pour la hiérarchie
- Contraintes avec index implicites

## 7. Requêtes Utiles

### 7.1 Navigation Hiérarchique
```sql
WITH RECURSIVE hierarchy AS (
    -- Niveau racine (régions)
    SELECT 
        cd_lau,
        cd_level,
        tx_name_fr,
        ARRAY[cd_lau] as path_codes,
        ARRAY[tx_name_fr] as path_names
    FROM dw.dim_geography
    WHERE cd_level = 1 
    AND fl_current = TRUE

    UNION ALL

    -- Niveaux suivants
    SELECT 
        g.cd_lau,
        g.cd_level,
        g.tx_name_fr,
        h.path_codes || g.cd_lau,
        h.path_names || g.tx_name_fr
    FROM dw.dim_geography g
    JOIN hierarchy h ON g.cd_parent = h.cd_lau
    WHERE g.fl_current = TRUE
)
SELECT 
    cd_lau,
    cd_level,
    tx_name_fr,
    array_to_string(path_names, ' > ') as full_path
FROM hierarchy
ORDER BY path_codes;
```

### 7.2 Recherche par Niveau
```sql
-- Liste des provinces actuelles
SELECT 
    d.cd_lau,
    d.tx_name_fr,
    d.tx_name_nl,
    r.tx_name_fr as region_name
FROM dw.dim_geography d
JOIN dw.dim_geography r ON d.cd_parent = r.cd_lau
WHERE d.cd_level = 2 
AND d.fl_current = TRUE
AND r.fl_current = TRUE
ORDER BY d.cd_lau;
```

### 7.3 Suivi des Changements
```sql
-- Historique des modifications d'une entité
SELECT 
    cd_lau,
    tx_name_fr,
    dt_start,
    dt_end,
    fl_current
FROM dw.dim_geography
WHERE cd_lau = 'BE10'
ORDER BY dt_start DESC;
```

## 8. Maintenance

### 8.1 Mises à jour Périodiques
1. Backup des données actuelles
2. Chargement des nouvelles données
3. Validation complète
4. Application des changements
5. Vérification post-mise à jour

### 8.2 Contrôles Qualité
```sql
-- Vérification des doublons actifs
SELECT cd_lau, COUNT(*)
FROM dw.dim_geography
WHERE fl_current = TRUE
GROUP BY cd_lau
HAVING COUNT(*) > 1;

-- Vérification des orphelins
SELECT d.*
FROM dw.dim_geography d
LEFT JOIN dw.dim_geography p 
    ON d.cd_parent = p.cd_lau
    AND p.fl_current = TRUE
WHERE d.fl_current = TRUE
AND d.cd_parent IS NOT NULL
AND p.cd_lau IS NULL;

-- Vérification des niveaux
SELECT d.cd_lau, d.cd_level, p.cd_level as parent_level
FROM dw.dim_geography d
JOIN dw.dim_geography p 
    ON d.cd_parent = p.cd_lau
WHERE d.fl_current = TRUE
AND p.fl_current = TRUE
AND d.cd_level <= p.cd_level;
```

### 8.3 Archivage
- Conservation de l'historique complet
- Archivage des anciennes versions après 10 ans
- Sauvegarde des métadonnées de chargement

## 9. Bonnes Pratiques

### 9.1 Gestion des Données
1. Utiliser systématiquement les procédures de chargement
2. Valider les données avant insertion
3. Maintenir la cohérence de la hiérarchie
4. Documenter les changements majeurs

### 9.2 Requêtes
1. Privilégier les vues pour les requêtes standard
2. Toujours filtrer sur fl_current par défaut
3. Utiliser les index appropriés
4. Optimiser les requêtes hiérarchiques

### 9.3 Multilinguisme
1. Maintenir toutes les traductions à jour
2. Valider la cohérence des libellés
3. Utiliser la langue appropriée selon le contexte
4. Gérer les cas particuliers (Bruxelles-Capitale)

### 9.4 Historisation
1. Respecter le modèle SCD Type 2
2. Documenter les changements importants
3. Maintenir la traçabilité des modifications
4. Gérer correctement les dates de validité