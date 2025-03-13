# Documentation de DIM_NATIONALITY

## 1. Description Générale
La table `dim_nationality` est une dimension de référence qui gère la classification des nationalités dans le contexte belge. Elle fournit une classification binaire (Belge/Non-Belge) avec support multilingue.

## 2. Structure

### 2.1 Clés et Identifiants
- `cd_nationality` (VARCHAR(10)) - Clé primaire
  - Valeurs : 'BE', 'NOT_BE'
  - Classification simple Belge/Non-Belge

### 2.2 Attributs Descriptifs Multilingues
- `tx_nationality_fr` : Libellé en français (50 caractères max)
- `tx_nationality_nl` : Libellé en néerlandais (50 caractères max)
- `tx_nationality_de` : Libellé en allemand (50 caractères max)
- `tx_nationality_en` : Libellé en anglais (50 caractères max)

### 2.3 Attributs Temporels
- `dt_created` : Date de création
- `dt_updated` : Date de dernière mise à jour

## 3. Classifications Standards

### 3.1 Types de Nationalité
1. BE : Belge
   - Français : Belge
   - Néerlandais : Belgisch
   - Allemand : Belgisch
   - Anglais : Belgian

2. NOT_BE : Non-Belge
   - Français : Non-Belge
   - Néerlandais : Niet-Belgisch
   - Allemand : Nicht-Belgisch
   - Anglais : Non-Belgian

## 4. Contraintes et Validation

### 4.1 Contrainte sur les Codes
```sql
CONSTRAINT chk_valid_nationality CHECK (cd_nationality IN ('BE', 'NOT_BE'))
```

### 4.2 Contraintes de Non-Nullité
- Tous les libellés multilingues sont obligatoires
- Les dates de traçabilité sont automatiquement gérées

## 5. Données de Référence
```sql
INSERT INTO dw.dim_nationality (
    cd_nationality,
    tx_nationality_fr,
    tx_nationality_nl,
    tx_nationality_de,
    tx_nationality_en
) VALUES
    ('BE', 'Belge', 'Belgisch', 'Belgisch', 'Belgian'),
    ('NOT_BE', 'Non-Belge', 'Niet-Belgisch', 'Nicht-Belgisch', 'Non-Belgian')
ON CONFLICT (cd_nationality) DO UPDATE SET
    tx_nationality_fr = EXCLUDED.tx_nationality_fr,
    tx_nationality_nl = EXCLUDED.tx_nationality_nl,
    tx_nationality_de = EXCLUDED.tx_nationality_de,
    tx_nationality_en = EXCLUDED.tx_nationality_en,
    dt_updated = CURRENT_TIMESTAMP;
```

## 6. Requêtes Utiles

### 6.1 Liste Complète Multilingue
```sql
SELECT cd_nationality,
       tx_nationality_fr,
       tx_nationality_nl,
       tx_nationality_de,
       tx_nationality_en
FROM dw.dim_nationality
ORDER BY cd_nationality;
```

### 6.2 Recherche par Nationalité
```sql
SELECT cd_nationality,
       tx_nationality_fr,
       tx_nationality_nl
FROM dw.dim_nationality
WHERE cd_nationality = 'BE';
```

## 7. Bonnes Pratiques

1. Utilisation des Codes
   - Utiliser les codes standards
   - Maintenir la cohérence des références
   - Respecter la casse (BE, NOT_BE)

2. Multilinguisme
   - Maintenir toutes les traductions à jour
   - Adapter les libellés selon le contexte
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
   - Distribution des nationalités
   - Évolution temporelle
   - Analyses migratoires

2. Statistiques Officielles
   - Rapports démographiques
   - Études de population
   - Indicateurs d'intégration

3. Études Sociales
   - Analyses socio-économiques
   - Études d'intégration
   - Politiques publiques

## 9. Relations Courantes

1. Avec DIM_GEOGRAPHY
   - Répartition géographique
   - Concentration par région
   - Tendances migratoires

2. Avec DIM_AGE
   - Profils démographiques
   - Structure par âge
   - Analyses générationnelles

3. Avec les Tables de Faits
   - Statistiques de population
   - Indicateurs d'intégration
   - Études migratoires

## 10. Notes Importantes

1. Simplicité Volontaire
   - Classification binaire intentionnelle
   - Focus sur la nationalité belge
   - Facilite les analyses macro

2. Contexte d'Utilisation
   - Statistiques officielles belges
   - Études démographiques nationales
   - Rapports standardisés

3. Extensions Possibles
   - Possibilité d'ajouter des sous-catégories
   - Classification plus détaillée si nécessaire
   - Évolution selon les besoins