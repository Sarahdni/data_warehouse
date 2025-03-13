# Documentation de DIM_COHABITATION_STATUS

## 1. Description Générale
La table `dim_cohabitation_status` est une dimension de référence qui gère les statuts de cohabitation légale. Elle fournit une classification binaire (oui/non) avec support multilingue pour les analyses démographiques et sociales.

## 2. Structure

### 2.1 Clés et Identifiants
- `cd_cohabitation` (VARCHAR(5)) - Clé primaire
  - Valeurs : 'OUI', 'NON'
  - Identifie le statut de cohabitation

### 2.2 Attributs de Classification
- `fl_cohab` (INTEGER)
  - Valeurs : 0 (Non) ou 1 (Oui)
  - Indicateur numérique pour les calculs

### 2.3 Attributs Descriptifs Multilingues
- `tx_cohab_fr` : Description en français (100 caractères max)
- `tx_cohab_nl` : Description en néerlandais (100 caractères max)
- `tx_cohab_de` : Description en allemand (100 caractères max)
- `tx_cohab_en` : Description en anglais (100 caractères max)

### 2.4 Attributs Temporels
- `dt_created` : Date de création
- `dt_updated` : Date de dernière mise à jour

## 3. Classifications Détaillées

### 3.1 Statuts de Cohabitation
1. NON : Pas en cohabitation légale
   - fl_cohab = 0
   - Français : Pas en cohabitation légale
   - Néerlandais : Geen wettelijke samenwoning
   - Allemand : Keine gesetzliche Lebensgemeinschaft
   - Anglais : No legal cohabitation

2. OUI : En cohabitation légale
   - fl_cohab = 1
   - Français : En cohabitation légale
   - Néerlandais : Wettelijke samenwoning
   - Allemand : Gesetzliche Lebensgemeinschaft
   - Anglais : Legal cohabitation

## 4. Contraintes et Validation

### 4.1 Contraintes sur les Valeurs
```sql
CONSTRAINT chk_valid_cohab CHECK (fl_cohab IN (0, 1))
```

### 4.2 Index
```sql
CREATE INDEX idx_cohabitation_flag ON dw.dim_cohabitation_status(fl_cohab);
```

## 5. Données de Référence
```sql
INSERT INTO dw.dim_cohabitation_status (
    cd_cohabitation,
    fl_cohab,
    tx_cohab_fr,
    tx_cohab_nl,
    tx_cohab_de,
    tx_cohab_en
) VALUES
    ('NON', 0, 
     'Pas en cohabitation légale',
     'Geen wettelijke samenwoning',
     'Keine gesetzliche Lebensgemeinschaft',
     'No legal cohabitation'),
    ('OUI', 1,
     'En cohabitation légale',
     'Wettelijke samenwoning',
     'Gesetzliche Lebensgemeinschaft',
     'Legal cohabitation');
```

## 6. Requêtes Utiles

### 6.1 Liste Complète
```sql
SELECT cd_cohabitation,
       fl_cohab,
       tx_cohab_fr,
       tx_cohab_nl
FROM dw.dim_cohabitation_status
ORDER BY fl_cohab;
```

### 6.2 Recherche par Statut
```sql
SELECT cd_cohabitation,
       tx_cohab_fr,
       tx_cohab_nl,
       tx_cohab_de,
       tx_cohab_en
FROM dw.dim_cohabitation_status
WHERE fl_cohab = 1;
```

## 7. Bonnes Pratiques

1. Utilisation des Flags
   - Utiliser fl_cohab pour les calculs
   - cd_cohabitation pour l'affichage
   - Maintenir la cohérence des deux

2. Multilinguisme
   - Maintenir toutes les traductions
   - Adapter selon le contexte
   - Vérifier la cohérence linguistique

3. Intégration
   - Lien avec d'autres dimensions
   - Validation des références
   - Cohérence des analyses

4. Performance
   - Utiliser l'index sur fl_cohab
   - Optimiser les requêtes fréquentes
   - Monitorer l'utilisation

## 8. Utilisations Courantes

1. Analyses Sociales
   - Distribution des cohabitations
   - Évolution temporelle
   - Comparaisons régionales

2. Rapports Démographiques
   - Statistiques de cohabitation
   - Tendances sociales
   - Analyses par région

3. Croisements
   - Avec l'état civil
   - Avec l'âge
   - Avec la localisation

## 9. Relations avec d'Autres Dimensions

1. DIM_CIVIL_STATUS
   - Analyse combinée des statuts
   - Validation des combinaisons valides
   - Statistiques croisées

2. DIM_GEOGRAPHY
   - Répartition géographique
   - Variations régionales
   - Tendances locales

3. DIM_AGE
   - Profils par âge
   - Tendances générationnelles
   - Analyses démographiques