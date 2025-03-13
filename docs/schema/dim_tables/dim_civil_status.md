# Documentation de DIM_CIVIL_STATUS

## 1. Description Générale
La table `dim_civil_status` est une dimension de référence qui gère les différents états civils des personnes. Elle fournit une classification standardisée des statuts matrimoniaux avec support multilingue.

## 2. Structure

### 2.1 Clés et Identifiants
- `cd_civil_status` (VARCHAR(5)) - Clé primaire
  - Valeurs : 'CEL', 'MAR', 'DIV', 'VEU', 'SEP'
  - Codes standards pour les états civils

### 2.2 Attributs Descriptifs Multilingues
- `tx_civil_status_fr` : Description en français (100 caractères max)
- `tx_civil_status_nl` : Description en néerlandais (100 caractères max)
- `tx_civil_status_de` : Description en allemand (100 caractères max)
- `tx_civil_status_en` : Description en anglais (100 caractères max)

### 2.3 Attributs Temporels
- `dt_created` : Date de création
- `dt_updated` : Date de dernière mise à jour

## 3. Classifications Détaillées

### 3.1 États Civils Standards
1. CEL : Célibataire
   - Français : Célibataire
   - Néerlandais : Ongehuwd
   - Allemand : Ledig
   - Anglais : Single

2. MAR : Marié(e)
   - Français : Marié(e)
   - Néerlandais : Gehuwd
   - Allemand : Verheiratet
   - Anglais : Married

3. DIV : Divorcé(e)
   - Français : Divorcé(e)
   - Néerlandais : Gescheiden
   - Allemand : Geschieden
   - Anglais : Divorced

4. VEU : Veuf/Veuve
   - Français : Veuf/Veuve
   - Néerlandais : Weduwe/Weduwnaar
   - Allemand : Verwitwet
   - Anglais : Widowed

5. SEP : Séparé(e)
   - Français : Séparé(e)
   - Néerlandais : Gescheiden van tafel en bed
   - Allemand : Getrennt
   - Anglais : Separated

## 4. Contraintes et Validation

### 4.1 Contraintes sur les Codes
```sql
CONSTRAINT chk_valid_civil_status CHECK (cd_civil_status IN ('CEL', 'MAR', 'DIV', 'VEU', 'SEP'))
```

### 4.2 Non-Nullité
- Tous les libellés multilingues sont obligatoires
- Les dates de création et mise à jour sont automatiquement gérées

## 5. Données de Référence
```sql
INSERT INTO dw.dim_civil_status (
    cd_civil_status,
    tx_civil_status_fr,
    tx_civil_status_nl,
    tx_civil_status_de,
    tx_civil_status_en
) VALUES
    ('CEL', 'Célibataire', 'Ongehuwd', 'Ledig', 'Single'),
    ('MAR', 'Marié(e)', 'Gehuwd', 'Verheiratet', 'Married'),
    ('DIV', 'Divorcé(e)', 'Gescheiden', 'Geschieden', 'Divorced'),
    ('VEU', 'Veuf/Veuve', 'Weduwe/Weduwnaar', 'Verwitwet', 'Widowed'),
    ('SEP', 'Séparé(e)', 'Gescheiden van tafel en bed', 'Getrennt', 'Separated');
```

## 6. Requêtes Utiles

### 6.1 Liste Complète Multilingue
```sql
SELECT cd_civil_status,
       tx_civil_status_fr,
       tx_civil_status_nl,
       tx_civil_status_de,
       tx_civil_status_en
FROM dw.dim_civil_status
ORDER BY cd_civil_status;
```

### 6.2 Recherche par Langue
```sql
SELECT cd_civil_status,
       tx_civil_status_fr,
       tx_civil_status_nl
FROM dw.dim_civil_status
WHERE tx_civil_status_fr ILIKE '%marié%'
   OR tx_civil_status_nl ILIKE '%gehuwd%';
```

## 7. Bonnes Pratiques

1. Gestion des Codes
   - Utiliser les codes standards
   - Respecter la casse (majuscules)
   - Maintenir la cohérence des références

2. Multilinguisme
   - Maintenir toutes les traductions à jour
   - Vérifier la cohérence linguistique
   - Adapter les formulations selon le contexte

3. Intégration
   - Utiliser comme référence pour les faits
   - Valider les clés étrangères
   - Maintenir l'intégrité des données

4. Maintenance
   - Documenter les modifications
   - Vérifier les impacts des changements
   - Maintenir la cohérence historique

## 8. Utilisations Courantes

1. Analyses Démographiques
   - Distribution des états civils
   - Évolution temporelle
   - Comparaisons régionales

2. Rapports Statistiques
   - Statistiques de population
   - Tendances matrimoniales
   - Analyses sociologiques

3. Intégrations
   - Systèmes de gestion administrative
   - Bases de données démographiques
   - Applications statistiques