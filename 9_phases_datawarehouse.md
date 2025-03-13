# Structure du Data Warehouse

## 00_init/ (Initialisation)
**Rôle principal**: dw_admin
**Schémas créés**: raw_staging, clean_staging, dw, metadata, utils
**Fichiers clés**:
- create_schemas.sql
- create_extensions.sql
- create_roles.sql

**But**: 
- Créer la structure de base de l'entrepôt
- Installer les extensions nécessaires
- Définir les rôles et permissions initiales

## 01_raw_staging/ (Zone de Transit brute)
**Rôle principal**: dw_etl
**Schéma utilisé**: staging
**Sous-dossiers**:
- tables/: Structure des tables de staging brut
- procedures/: Procédures de chargement inital
- validation/: Règles de validation basiques

**But**:
- Recevoir les données brutes sans modification
- Conserver une copie exacte des données sources
- Effectuer les validations minimales (format, structure)


## 02_clean_staging/ (Zone de Transit nettoyée)
**Rôle principal**: dw_etl
**Schéma utilisé**: clean staging
**Sous-dossiers**:
- tables/: Structure des tables de staging nettoyée
- procedures/: Procédures de nettoyage et transformation
- validation/: Règles de validation basiques

**But**:
- Nettoyer et standardiser les données
- Appliquer les règles métier de base
- Préparer les données pour le modèle dimensionnel
- Tracer les modifications appliquées

## 03_dim_tables/ (Tables Dimensionnelles)
**Rôle principal**: dw_developer
**Schéma utilisé**: dw
**Sous-dossiers**:
- geography/: Dimensions géographiques
- time/: Dimensions temporelles
- employment/: Dimensions liées à l'emploi
- population/: Dimensions démographiques
- real_estate/: Dimensions immobilières

**But**:
- Créer les tables de référence
- Gérer les hiérarchies
- Maintenir l'historique des changements

## 04_fact_tables/ (Tables de Faits)
**Rôle principal**: dw_developer
**Schéma utilisé**: dw
**Sous-dossiers**:
- population/: Faits sur la population
- real_estate/: Faits immobiliers
- taxes/: Faits sur les taxes
- un_employment/: Faits sur l'emploi

**But**:
- Stocker les métriques principales
- Lier les dimensions entre elles
- Permettre les analyses

## 05_views/ (Vues Métier)
**Rôle principal**: dw_developer
**Schéma utilisé**: dw
**Sous-dossiers**:
- population/: Vues démographiques
- real_estate/: Vues immobilières
- taxes/: Vues fiscales
- un_employment/: Vues sur l'emploi

**But**:
- Simplifier l'accès aux données
- Créer des agrégats prédéfinis
- Sécuriser l'accès aux données

## 06_functions/ (Fonctions Utilitaires)
**Rôle principal**: dw_developer
**Schéma utilisé**: utils
**Types de fonctions**:
- geography_utils.sql
- date_utils.sql
- validation_utils.sql
- string_utils.sql

**But**:
- Factoriser le code commun
- Fournir des utilitaires réutilisables
- Standardiser les traitements

## 07_maintenance/ (Maintenance)
**Rôle principal**: dw_admin
**Schéma utilisé**: metadata
**Opérations**:
- purge_staging.sql
- rebuild_indexes.sql
- update_statistics.sql

**But**:
- Nettoyer les données temporaires
- Optimiser les performances
- Maintenir les statistiques

## 08_security/ (Sécurité)
**Rôle principal**: dw_admin
**Fichiers clés**:
- roles.sql
- grants.sql

**But**:
- Gérer les droits d'accès
- Auditer les accès
- Sécuriser les données sensibles

## 09_tests/ (Tests)
**Rôle principal**: dw_developer
**Tests inclus**:
- test_staging.sql
- test_dimensions.sql
- test_facts.sql

**But**:
- Valider les chargements
- Vérifier l'intégrité des données
- Tester les performances

## Rôles principaux
1. **dw_etl**:
   - Accès en écriture aux schémas raw_staging et clean_staging
   - Accès en insertion au schéma dw

2. **dw_reader**:
   - Accès en lecture au schéma dw
   - Accès aux vues métier

3. **dw_developer**:
   - Accès complet aux schémas staging et dw
   - Accès aux utilitaires

4. **dw_admin**:
   - Accès complet à tous les schémas
   - Gestion des droits