# Documentation de Migration du Data Warehouse

## 1. Contexte et Objectifs

### 1.1 Situation Actuelle
Le data warehouse utilise actuellement un schéma unique 'staging' pour les données intermédiaires. Cette architecture est fonctionnelle mais ne permet pas une séparation claire entre les données brutes et les données nettoyées.

### 1.2 Nouvelle Architecture
Une nouvelle structure à trois niveaux est mise en place :
- `raw_staging` : données brutes sans transformation
- `clean_staging` : données nettoyées et validées
- `dw` : modèle dimensionnel final (inchangé)

### 1.3 Objectifs
- Améliorer la traçabilité des transformations
- Séparer clairement les responsabilités
- Faciliter le débogage et l'audit
- Permettre une meilleure gouvernance des données

## 2. Plan de Transition

### 2.1 Phase Actuelle : Coexistence
- Le schéma `staging` est maintenu en l'état
- Les nouveaux schémas `raw_staging` et `clean_staging` sont créés
- Les trois schémas coexistent temporairement

### 2.2 Règles de Développement
- Tout nouveau développement doit utiliser `raw_staging` et `clean_staging`
- Aucune nouvelle table ne doit être créée dans `staging`
- Les processus existants dans `staging` continuent de fonctionner normalement

### 2.3 Organisation des Dossiers
```
project_root/
├── 01_raw_staging/     # Nouveau dossier pour les données brutes
├── 02_clean_staging/   # Nouveau dossier pour les données nettoyées
├── 01_staging/         # Ancien dossier (déprécié)
└── [autres dossiers]   # Structure existante
```

## 3. Nouveaux Composants

### 3.1 Table de Traçabilité
Une nouvelle table `metadata.transformation_tracking` suit les transformations entre les étapes :
- Transformations raw → clean
- Transformations clean → dw
- Historique des opérations
- Suivi des anomalies

### 3.2 Schémas
- `raw_staging` : Réception des données brutes
- `clean_staging` : Données nettoyées et validées
- `staging` : Schéma legacy (déprécié)

## 4. Processus ETL

### 4.1 Nouveau Processus
1. Chargement dans `raw_staging`
   - Données brutes sans modification
   - Validation minimale (format, structure)
   - Logging des erreurs de chargement

2. Transformation vers `clean_staging`
   - Nettoyage et standardisation
   - Application des règles métier
   - Validation approfondie
   - Traçabilité des modifications

3. Chargement dans `dw`
   - Alimentation du modèle dimensionnel
   - Création des clés de substitution
   - Mise à jour des dimensions/faits

### 4.2 Ancien Processus
- Les processus existants dans `staging` continuent de fonctionner
- Pas de modification immédiate nécessaire
- Migration progressive selon les besoins

## 5. Plan de Migration Future

### 5.1 Critères de Migration
La migration d'une table de `staging` vers la nouvelle structure doit être évaluée selon :
- La fréquence de mise à jour des données
- La complexité des transformations
- Les dépendances avec d'autres processus
- Les périodes creuses d'activité

### 5.2 Étapes de Migration
1. Analyser la table et ses dépendances
2. Créer les tables correspondantes dans `raw_staging` et `clean_staging`
3. Adapter les processus ETL
4. Tester en parallèle
5. Basculer vers le nouveau processus
6. Archiver l'ancienne table

## 6. Gouvernance

### 6.1 Conventions de Nommage
- Tables raw_staging : `raw_[nom_table]`
- Tables clean_staging : `clean_[nom_table]`
- Conserver les noms existants dans `staging`

### 6.2 Documentation
- Maintenir un registre des tables migrées
- Documenter les nouvelles transformations
- Mettre à jour les métadonnées

### 6.3 Contrôle Qualité
- Validation des données à chaque étape
- Suivi des anomalies
- Tests de non-régression

## 7. Points d'Attention

### 7.1 Risques Identifiés
- Confusion possible entre les schémas pendant la transition
- Risque de duplication des données
- Complexité temporaire accrue

### 7.2 Mitigation
- Documentation claire et à jour
- Formation des équipes
- Tests approfondis
- Surveillance des performances

## 8. Support et Maintenance

### 8.1 Équipe Responsable
- Équipe DW pour la conception
- Équipe ETL pour l'implémentation
- Équipe QA pour les tests

### 8.2 Procédures de Support
- Processus d'escalade en cas de problème
- Monitoring spécifique pendant la transition
- Procédures de rollback si nécessaire