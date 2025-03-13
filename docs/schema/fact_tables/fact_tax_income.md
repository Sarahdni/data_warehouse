# Documentation de la Table de Faits des Revenus Fiscaux

## 1. Vue d'ensemble

Le modèle de données des revenus fiscaux a été conçu pour :
- Stocker les données fiscales au niveau communal
- Suivre différents types de revenus (immobilier, mobilier, professionnel, etc.)
- Gérer les comptages et montants associés
- Supporter l'historisation annuelle des données
- Gérer les changements administratifs (fusions de communes)

## 2. Structure du Projet

### 2.1 Organisation des Fichiers
```
project/
├── 02_clean_staging/
│   ├── tables/
│   │   └── clean_tax_income.sql       # Table de staging nettoyée
│   ├── procedures/
│   │   └── load_clean_tax_income.sql  # Procédure de chargement
│   └── validation/
│       └── validate_clean_tax_income.sql  # Règles de validation
├── 04_fact_tables/taxes/
│   ├── structure/
│   │   └── fact_tax_income.sql       # Structure de la table
│   └── procedures/
│       └── load_fact_tax_income.sql  # Procédure de chargement
├── metadata/
    └── refnis_changes_2019.sql       # Table des changements administratifs
```

### 2.2 Choix de Structure
- Table de faits unique regroupant tous les types de revenus
- Gestion des versions historiques avec SCD Type 2
- Support des modifications territoriales post-2019
- Traçabilité complète (batches, dates de création/modification)
- Validation stricte des données avant chargement

## 3. Structure Détaillée

### 3.1 Table fact_tax_income
```sql
CREATE TABLE dw.fact_tax_income (
    -- Clé surrogate
    id_tax_income_sk BIGSERIAL PRIMARY KEY,
    
    -- Clés dimensionnelles
    id_date INTEGER NOT NULL,
    id_geography INTEGER NOT NULL,
    
    -- Mesures de déclarations
    ms_nbr_non_zero_inc INTEGER NOT NULL,
    ms_nbr_zero_inc INTEGER NOT NULL,
    
    -- Revenus totaux
    ms_tot_net_taxable_inc DECIMAL(15,2),
    ms_tot_net_inc DECIMAL(15,2),
    ms_nbr_tot_net_inc INTEGER,
    
    -- Revenus par type
    ms_real_estate_net_inc DECIMAL(15,2),
    ms_nbr_real_estate_net_inc INTEGER,
    ms_tot_net_mov_ass_inc DECIMAL(15,2),
    ms_nbr_net_mov_ass_inc INTEGER,
    ms_tot_net_various_inc DECIMAL(15,2),
    ms_nbr_net_various_inc INTEGER,
    ms_tot_net_prof_inc DECIMAL(15,2),
    ms_nbr_net_prof_inc INTEGER,
    
    -- Revenus imposables
    ms_sep_taxable_inc DECIMAL(15,2),
    ms_nbr_sep_taxable_inc INTEGER,
    ms_joint_taxable_inc DECIMAL(15,2),
    ms_nbr_joint_taxable_inc INTEGER,
    
    -- Dépenses et taxes
    ms_tot_deduct_spend DECIMAL(15,2),
    ms_nbr_deduct_spend INTEGER,
    ms_tot_state_taxes DECIMAL(15,2),
    ms_nbr_state_taxes INTEGER,
    ms_tot_municip_taxes DECIMAL(15,2),
    ms_nbr_municip_taxes INTEGER,
    ms_tot_suburbs_taxes DECIMAL(15,2),
    ms_nbr_suburbs_taxes INTEGER,
    ms_tot_taxes DECIMAL(15,2),
    ms_nbr_tot_taxes INTEGER,
    ms_tot_residents INTEGER,
    
    -- Traçabilité
    id_batch INTEGER NOT NULL,
    fl_current BOOLEAN NOT NULL DEFAULT TRUE,
    dt_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dt_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

## 4. Problèmes Connus et Limitations

### 4.1 Cas Particuliers et Adaptations

#### 4.1.1 Commune 73028 et Valeurs Nulles
- La commune avec le code REFNIS 73028 est la seule à présenter une valeur NULL pour le nombre de déclarations sans revenu (ms_nbr_zero_inc)
- Adaptation effectuée : modification de la validation pour accepter les valeurs NULL spécifiquement pour ce champ
- Impact : ajout de la condition `(fl_valid_counts IS NULL OR fl_valid_counts = TRUE)` dans la procédure de chargement

#### 4.1.2 Changements Administratifs 2019
- Création de la table metadata.refnis_changes_2019 pour documenter :
  * Les fusions de communes (ex: création de Pelt)
  * Les renumérotations administratives
  * Les correspondances entre anciens et nouveaux codes

Décision technique importante :
- Utilisation des codes REFNIS post-2019 pour toutes les données historiques
- Justification :
  * Éviter une répartition artificielle des mesures historiques qui pourrait introduire des biais
  * Préserver l'intégrité des données fiscales originales
  * Maintenir la cohérence des analyses longitudinales
  * Permettre une traçabilité claire des changements administratifs sans altérer les mesures

Cette approche garantit que :
- Les données fiscales restent fidèles aux données sources
- Les analyses temporelles sont cohérentes
- Les utilisateurs sont informés des changements administratifs via la table de documentation
- Aucune manipulation arbitraire des données n'est introduite

Documentation complète des changements maintenue pour la traçabilité.

### 4.2 Incohérence des Comptages
Un problème de cohérence a été identifié dans les comptages :
- La somme des comptages par type de revenu est supérieure au total
- L'écart augmente progressivement de 2005 à 2022
- Cette incohérence est présente dans les données sources
- Recommandation : utiliser ms_nbr_tot_net_inc comme référence

### 4.2 Gestion des Fusions de Communes
Pour les communes fusionnées en 2019 :
- Les données historiques utilisent le nouveau code REFNIS
- Pas de répartition des mesures historiques
- Documentation des changements dans metadata.refnis_changes_2019

## 5. Processus ETL

### 5.1 Chargement en Staging
```sql
CALL clean_staging.load_clean_tax_income(
    p_batch_id := 123,
    p_truncate := FALSE
);
```

### 5.2 Validations
Contrôles effectués :
1. Format des codes REFNIS
2. Cohérence des montants (non-négativité)
3. Présence des champs obligatoires
4. Validité des dates
5. Cohérence géographique

### 5.3 Chargement dans la Table de Faits
```sql
CALL dw.load_fact_tax_income(
    p_batch_id := 123,
    p_start_year := 2005,
    p_end_year := 2022,
    p_delete_existing := FALSE
);
```

## 6. Index et Performance

### 6.1 Index Principaux
```sql
CREATE INDEX idx_fact_tax_income_date ON dw.fact_tax_income(id_date);
CREATE INDEX idx_fact_tax_income_geo ON dw.fact_tax_income(id_geography);
CREATE INDEX idx_fact_tax_income_current ON dw.fact_tax_income(fl_current) WHERE fl_current = TRUE;
CREATE INDEX idx_fact_tax_income_batch ON dw.fact_tax_income(id_batch);
```

## 7. Requêtes Types

### 7.1 Évolution des Revenus par Commune
```sql
SELECT 
    d.cd_year,
    g.tx_name_fr,
    f.ms_tot_net_taxable_inc,
    f.ms_tot_net_inc,
    f.ms_nbr_tot_net_inc
FROM dw.fact_tax_income f
JOIN dw.dim_date d ON f.id_date = d.id_date
JOIN dw.dim_geography g ON f.id_geography = g.id_geography
WHERE f.fl_current = TRUE
ORDER BY d.cd_year, g.tx_name_fr;
```

### 7.2 Analyse des Types de Revenus
```sql
SELECT 
    d.cd_year,
    g.tx_name_fr,
    f.ms_real_estate_net_inc,
    f.ms_tot_net_mov_ass_inc,
    f.ms_tot_net_prof_inc,
    f.ms_tot_net_various_inc
FROM dw.fact_tax_income f
JOIN dw.dim_date d ON f.id_date = d.id_date
JOIN dw.dim_geography g ON f.id_geography = g.id_geography
WHERE f.fl_current = TRUE
ORDER BY d.cd_year, g.tx_name_fr;
```

## 8. Maintenance

### 8.1 Procédures de Maintenance
1. Archivage des anciens batches
2. Mise à jour des statistiques
3. Réindexation périodique
4. Validation des cumuls annuels

### 8.2 Contrôles Qualité
```sql
-- Vérification des totaux
SELECT 
    d.cd_year,
    SUM(f.ms_tot_net_taxable_inc) as total_net_taxable,
    SUM(f.ms_tot_net_inc) as total_net,
    SUM(f.ms_nbr_tot_net_inc) as total_declarations
FROM dw.fact_tax_income f
JOIN dw.dim_date d ON f.id_date = d.id_date
WHERE f.fl_current = TRUE
GROUP BY d.cd_year
ORDER BY d.cd_year;
```

## 9. Évolutions Futures

### 9.1 Améliorations Proposées
1. Ajout d'indicateurs de qualité des données
2. Support des corrections historiques
3. Ajout de mesures dérivées (ratios, moyennes)
4. Amélioration de la gestion des valeurs manquantes

### 9.2 Développements Potentiels
1. Création de vues matérialisées pour les agrégats
2. Ajout de nouvelles dimensions d'analyse
3. Intégration de données socio-économiques
4. Support de données infra-annuelles

## 10. Bonnes Pratiques

### 10.1 Gestion des Données
1. Toujours utiliser les procédures de chargement
2. Valider systématiquement les données
3. Documenter les anomalies détectées
4. Maintenir la traçabilité des chargements

### 10.2 Optimisation
1. Utiliser les index appropriés
2. Filtrer sur fl_current
3. Limiter les périodes analysées
4. Privilégier les agrégations en amont

### 10.3 Documentation
1. Maintenir à jour cette documentation
2. Documenter les changements majeurs
3. Tracer les décisions de conception
4. Documenter les cas particuliers