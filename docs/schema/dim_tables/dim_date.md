# Documentation de DIM_DATE

## 1. Description Générale
La table `dim_date` est une dimension temporelle qui gère la hiérarchie des périodes (années, trimestres, mois) avec support multilingue. Elle est conçue pour supporter les analyses temporelles à différents niveaux de granularité.

## 2. Structure

### 2.1 Clés et Identifiants
- `id_date` (SERIAL) - Clé primaire
- `cd_year` (INTEGER) - Année
- `cd_quarter` (SMALLINT) - Trimestre (1-4)
- `cd_month` (SMALLINT) - Mois (1-12)
- `cd_period_type` (CHAR(1)) - Type de période ('Y', 'Q', 'M')

### 2.2 Attributs Descriptifs Multilingues
- Libellés longs :
  - `tx_period_fr` : Libellé en français
  - `tx_period_nl` : Libellé en néerlandais
  - `tx_period_de` : Libellé en allemand
  - `tx_period_en` : Libellé en anglais
- Libellés courts :
  - `tx_period_short_fr` : Libellé court en français
  - `tx_period_short_nl` : Libellé court en néerlandais
  - `tx_period_short_de` : Libellé court en allemand
  - `tx_period_short_en` : Libellé court en anglais

### 2.3 Attributs Temporels
- `dt_created` : Date de création
- `dt_updated` : Date de dernière mise à jour

## 3. Types de Périodes

### 3.1 Années (Y)
- Code période : 'Y'
- Format : YYYY
- Exemple : 2024

### 3.2 Trimestres (Q)
- Code période : 'Q'
- Format : "Qn YYYY"
- Exemple : "Q1 2024"

### 3.3 Mois (M)
- Code période : 'M'
- Format : "Mois YYYY"
- Exemple : "Janvier 2024"

## 4. Utilitaires (date_utils)

### 4.1 Fonction generate_dim_date
```sql
SELECT dw.generate_dim_date(2000, 2025);
```
Génère automatiquement :
- Les années
- Les trimestres
- Les mois
- Les libellés multilingues

### 4.2 Gestion des Mois
- Noms des mois en 4 langues
- Versions courtes et longues
- Formats standardisés

## 5. Vues Associées

### 5.1 v_dim_date_current
- Vue des périodes courantes
- Indicateur de période active
- Filtres automatiques

### 5.2 v_current_periods
- Périodes courantes uniquement
- Support multilingue
- Tous niveaux de granularité

### 5.3 Vues Spécialisées
- v_years : Liste des années
- v_quarters : Liste des trimestres
- v_months : Liste des mois

## 6. Contraintes et Index

### 6.1 Contraintes
- `uk_dim_date` : Unicité (cd_year, cd_quarter, cd_month, cd_period_type)
- `chk_period_type` : Valeurs valides ('Y', 'Q', 'M')
- `chk_quarter` : Valeurs entre 1 et 4
- `chk_month` : Valeurs entre 1 et 12
- `chk_period_consistency` : Cohérence selon le type de période

### 6.2 Index
- `idx_date_year` sur cd_year
- `idx_date_quarter` sur (cd_year, cd_quarter)
- `idx_date_month` sur (cd_year, cd_month)

## 7. Requêtes Utiles

### 7.1 Consultation par Période
```sql
SELECT cd_year, 
       cd_quarter,
       tx_period_fr,
       tx_period_short_fr
FROM dw.dim_date
WHERE cd_period_type = 'Q'
ORDER BY cd_year, cd_quarter;
```

### 7.2 Périodes Courantes
```sql
SELECT *
FROM dw.v_current_periods
WHERE cd_period_type = 'M';
```

### 7.3 Recherche Multi-Langues
```sql
SELECT cd_year,
       cd_month,
       tx_period_fr,
       tx_period_nl,
       tx_period_de,
       tx_period_en
FROM dw.dim_date
WHERE cd_period_type = 'M'
AND cd_year = 2024;
```

## 8. Bonnes Pratiques

1. Génération des Données
   - Utiliser generate_dim_date pour la création
   - Maintenir une plage temporelle suffisante
   - Mettre à jour régulièrement

2. Utilisation des Vues
   - Privilégier les vues pour les requêtes standard
   - Utiliser v_current_periods pour les données actuelles
   - Adapter la granularité selon les besoins

3. Multilinguisme
   - Maintenir tous les libellés à jour
   - Utiliser les formats appropriés
   - Respecter les standards linguistiques

4. Performance
   - Utiliser les index appropriés
   - Filtrer sur le type de période
   - Optimiser les requêtes temporelles