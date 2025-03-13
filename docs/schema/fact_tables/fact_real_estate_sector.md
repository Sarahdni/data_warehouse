Documentation de la Table de Faits des Transactions Immobilières (fact_real_estate_sector)
1. Vue d'ensemble
Le modèle de données des transactions immobilières a été conçu pour :

Stocker les statistiques de prix par secteur statistique
Gérer les changements de codes REFNIS des communes
Maintenir la confidentialité des données sensibles
Permettre l'agrégation géographique à différents niveaux
Assurer la traçabilité des données

2. Structure du Projet
2.1 Organisation des Fichiers
Copyproject/
├── 01_raw_staging/
│   ├── tables/
│   │   └── raw_real_estate_sector.sql       # Table brute
│   └── procedures/
│       └── load_raw_real_estate_sector.sql  # Chargement initial
├── 02_clean_staging/
│   ├── tables/
│   │   └── clean_real_estate_sector.sql     # Table nettoyée
│   └── procedures/
│       └── load_clean_real_estate_sector.sql # Nettoyage
└── 04_fact_tables/real_estate/
    ├── fact_real_estate_sector.sql          # Structure finale
    └── procedures/
        └── load_fact_real_estate_sector.sql # Chargement final
3. Défis et Solutions Techniques
3.1 Gestion des Secteurs Inconnus
Défi : Certaines transactions n'ont pas de secteur statistique spécifié.
Solution :

Attribution d'un id_sector_sk = -1 pour ces cas
Conservation du code REFNIS de la commune (format: XXXXX_UNKNOWN)
Agrégation au niveau communal pour préserver les statistiques

3.2 Fusion et Changements de Communes (2019)
Défi : Modification majeure des codes REFNIS en 2019.
Solution :

Création de metadata.refnis_changes_2019 pour documenter les changements
Gestion de deux types de modifications :

Fusions (ex: Puurs + Sint-Amands → Puurs-Sint-Amands)
Renumérotations (ex: Mouscron: 54007 → 57096)


Double jointure avec dim_geography pour gérer les périodes pré/post 2019

3.3 Confidentialité des Données
Défi : Masquage des prix pour < 16 transactions.
Solution :

Flag fl_confidential = TRUE pour ces cas
Masquage automatique de tous les percentiles (P10, P25, P50, P75, P90)
Contrainte CHECK dans la table pour garantir la cohérence

3.4 Agrégation des Secteurs
Défi : Maintien des statistiques même sans détail sectoriel.
Solution :

Flag fl_aggregated_sectors pour identifier les agrégations
Champ nb_aggregated_sectors pour tracer le nombre de secteurs agrégés
Conservation des transactions sans perdre la granularité géographique

4. Structure Détaillée
4.1 Dimensions Utilisées

dim_date

Période annuelle uniquement (cd_period_type = 'Y')
Jointure sur cd_year


dim_statistical_sectors

Gestion de l'historique via dt_start/dt_end
Jointure sur cd_sector et année


dim_geography

Hiérarchie géographique complète
Gestion des périodes de validité
Support multi-niveau (commune, district, province, région)


dim_residential_building

Types de biens (B001, B002, etc.)
Descriptions multilingues



4.2 Mesures et Flags
sqlCopy-- Mesures principales
nb_transactions INTEGER NOT NULL
ms_price_p10 DECIMAL(15,2)
ms_price_p25 DECIMAL(15,2)
ms_price_p50 DECIMAL(15,2)
ms_price_p75 DECIMAL(15,2)
ms_price_p90 DECIMAL(15,2)

-- Flags et indicateurs
fl_confidential BOOLEAN       -- TRUE si < 16 transactions
fl_aggregated_sectors BOOLEAN -- TRUE si données agrégées
nb_aggregated_sectors INTEGER -- Nombre de secteurs agrégés
5. Règles de Gestion
5.1 Règles de Confidentialité

Si nb_transactions < 16 :

fl_confidential = TRUE
Tous les prix = NULL
Traçage dans metadata.data_quality_issues



5.2 Règles d'Agrégation

Si cd_sector = XXXXX_UNKNOWN :

id_sector_sk = -1
fl_aggregated_sectors = TRUE
nb_aggregated_sectors = nombre de secteurs source



5.3 Règles de Temporalité

Données annuelles uniquement
Gestion des périodes de validité pour :

Secteurs statistiques
Géographie administrative
Codes REFNIS



6. Validation et Qualité
6.1 Contrôles de Validité
sqlCopyCONSTRAINT chk_prices_valid CHECK (
    (fl_confidential = TRUE AND prices ARE NULL)
    OR
    (fl_confidential = FALSE AND prices ARE ORDERED)
)
6.2 Traçabilité

Logging des agrégations dans metadata.data_quality_issues
Traçage des changements de REFNIS
Historique des chargements

7. Procédures de Chargement
La procédure load_fact_real_estate_sector gère :

Normalisation des codes REFNIS via metadata.refnis_changes_2019
Agrégation des données au niveau approprié
Application des règles de confidentialité
Gestion des mises à jour (UPSERT)

8. Points d'Attention

Impact des fusions de communes sur les séries temporelles
Gestion des secteurs inconnus dans les analyses
Interprétation des données agrégées
Respect de la confidentialité dans les rapports

9. Recommandations pour l'Analyse

Toujours vérifier fl_confidential avant d'utiliser les prix
Tenir compte des changements de codes REFNIS en 2019
Utiliser nb_aggregated_sectors pour pondérer les analyses
Documenter le niveau d'agrégation dans les rapports