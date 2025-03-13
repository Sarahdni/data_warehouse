# Documentation de DIM_SEX

## 1. Description Générale
La table `dim_sex` est une dimension de référence qui gère la classification du sexe/genre dans les statistiques démographiques. Elle fournit une classification binaire standard avec support multilingue.

## 2. Structure

### 2.1 Clés et Identifiants
- `cd_sex` (CHAR(1)) - Clé primaire
  - Valeurs : 'M', 'F'
  - Code standard international

### 2.2 Attributs Descriptifs Multilingues
- `tx_sex_fr` : Libellé en français (20 caractères max)
- `tx_sex_nl` : Libellé en néerlandais (20 caractères max)
- `tx_sex_de` : Libellé en allemand (20 caractères max)
- `tx_sex_en` : Libellé en anglais (20 caractères max)

### 2.3 Attributs Temporels
- `dt_created` : Date de création
- `dt_updated` : Date de dernière mise à jour

## 3. Classifications Standards

### 3.1 Codes et Libellés
1. M : Masculin
   - Français : Masculin
   - Néerlandais : Mannelijk
   - Allemand : Männlich
   - Anglais : Male

2. F : Féminin
   - Français : Féminin
   - Néerlandais : Vrouwelijk
   - Allemand : Weiblich
   - Anglais : Female

## 4. Contraintes et Validation

### 4.1 Contrainte sur les Codes
```sql
CONSTRAINT chk_valid_sex CHECK (cd_sex IN ('M', 'F'))
```

### 4.2 Contraintes de Non-Nullité
- Tous les libellés multilingues sont obligatoires
- Les dates de traçabilité sont automatiquement gérées

## 5. Données de Référence
```sql
INSERT INTO dw.dim_sex (
    cd_sex,
    tx_sex_fr,
    tx_sex_nl,
    tx_sex_de,
    tx_sex_en
) VALUES
    ('M', 'Masculin', 'Mannelijk', 'Männlich', 'Male'),
    ('F', 'Féminin', 'Vrouwelijk', 'Weiblich', 'Female')
ON CONFLICT (cd_sex) DO UPDATE SET
    tx_sex_fr = EXCLUDED.tx_sex_fr,
    tx_sex_nl = EXCLUDED.tx_sex_nl,
    tx_sex_de = EXCLUDED.tx_sex_de,
    tx_sex_en = EXCLUDED.tx_sex_en,
    dt_updated = CURRENT_TIMESTAMP;
```

## 6. Requêtes Utiles

### 6.1 Liste Complète Multilingue
```sql
SELECT cd_sex,
       tx_sex_fr,
       tx_sex_nl,
       tx_sex_de,
       tx_sex_en
FROM dw.dim_sex
ORDER BY cd_sex;
```

### 6.2 Traduction Spécifique
```sql
SELECT cd_sex,
       tx_sex_fr,
       tx_sex_nl
FROM dw.dim_sex
WHERE cd_sex = 'M';
```

## 7. Bonnes Pratiques

1. Utilisation des Codes
   - Utiliser les codes standards internationaux
   - Maintenir la cohérence des références
   - Respecter la casse des codes

2. Multilinguisme
   - Maintenir toutes les traductions à jour
   - Utiliser les libellés appropriés selon le contexte
   - Vérifier la cohérence linguistique

3. Intégration
   - Utiliser comme référence pour les faits
   - Valider les clés étrangères
   - Assurer l'intégrité référentielle

4. Performance
   - Table de petite taille, pas d'index spécifique nécessaire
   - Utilisation fréquente en jointure
   - Cache efficace

## 8. Utilisations Courantes

1. Analyses Démographiques
   - Répartition par sexe
   - Ratios hommes/femmes
   - Pyramides des âges

2. Statistiques
   - Indicateurs par genre
   - Analyses comparatives
   - Études sociodémographiques

3. Rapports Standards
   - Tableaux de bord
   - Rapports officiels
   - Publications statistiques

## 9. Relations Courantes

1. Avec DIM_AGE
   - Analyses démographiques
   - Pyramides des âges
   - Études générationnelles

2. Avec DIM_GEOGRAPHY
   - Répartition géographique
   - Analyses régionales
   - Comparaisons territoriales

3. Avec les Tables de Faits
   - Statistiques de population
   - Indicateurs sociaux
   - Mesures démographiques