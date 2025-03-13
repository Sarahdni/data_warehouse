# Documentation du modèle de données pour le chargement des faits immobiliers

## Vue d'ensemble

Ce modèle de données est conçu pour permettre le chargement des données immobilières par commune, depuis des fichiers sources jusqu'à l'entrepôt de données (data warehouse). Il assure la traçabilité de bout en bout, l'intégrité des données et la gestion des erreurs à chaque étape du processus.

## Description des tables

1. `metadata.dim_source` : Table de dimension qui référence toutes les sources de données. Chaque source a un `id_source` unique et un `cd_source` (code source).

2. `metadata.source_file_history` : Table qui enregistre l'historique de traitement de chaque fichier source. Chaque fichier a un `id_file_history` unique. La table a une clé étrangère `id_source` vers `metadata.dim_source`.

3. `raw_staging.raw_immo_by_municipality` : Table de staging qui stocke les données immobilières brutes, telles que chargées depuis les fichiers CSV sources. Chaque ligne a un `id_batch` qui indique le lot de chargement.

4. `clean_staging.clean_immo_by_municipality` : Table de staging qui contient les données immobilières nettoyées et préparées pour l'intégration dans le data warehouse. L'`id_batch` est conservé depuis le staging brut.

5. `dw.fact_real_estate_municipality` : Table de faits finale dans le data warehouse. Contient les données immobilières par commune, liées aux dimensions et avec l'`id_batch` du fichier source.

6. `metadata.transformation_tracking` : Table qui enregistre les méta-données de chaque transformation de données (source, cible, lignes traitées, règles appliquées, etc.). La clé étrangère `id_batch` référence l'`id_file_history` du fichier source dans `metadata.source_file_history`.

7. `dw.dim_date`, `dw.dim_geography`, `dw.dim_building_type` : Tables de dimension liées à la table de faits. Contiennent respectivement les informations sur les dates, les géographies et les types de bâtiments.

## Processus de chargement

Le chargement des données suit les étapes suivantes :

1. Enregistrement des fichiers sources dans `metadata.dim_source` et `metadata.source_file_history`, avec génération d'un `id_file_history` unique par fichier.

2. Chargement des données brutes dans `raw_staging.raw_immo_by_municipality` via la procédure `raw_staging.load_raw_immo_by_municipality`, appelée avec l'`id_source`. Les méta-données de chargement sont enregistrées dans `metadata.source_file_history`.

3. Nettoyage et préparation des données dans `clean_staging.clean_immo_by_municipality`, en conservant l'`id_batch` d'origine.

4. Intégration des données dans `dw.fact_real_estate_municipality` via la procédure `dw.load_fact_real_estate_municipality`, appelée avec l'`id_file_history`. Les méta-données de transformation sont enregistrées dans `metadata.transformation_tracking`.

## Points d'attention

- Chaque fichier source est identifié de façon unique par son `id_file_history`, qui sert à tracer son chargement de bout en bout.
- L'`id_batch` permet de regrouper les lignes par lot de chargement dans les tables de staging brut et nettoyé. 
- Lors de l'appel aux procédures de chargement, il faut utiliser l'`id_file_history` et non l'`id_batch` pour respecter les clés étrangères et conserver l'intégrité référentielle.
- L'`id_file_history` est utilisé comme clé étrangère `id_batch` dans `metadata.transformation_tracking` pour enregistrer les méta-données de chaque transformation.

N'hésitez pas si vous avez des questions sur ce modèle de données !


Vous avez raison de vous poser la question. L'utilisation de l'id_file_history ne va pas directement charger les données de la table clean_staging vers la table de fait. Ce sont deux étapes distinctes du processus.
Voici ce qui se passe en détail :

Lorsque vous chargez les données brutes depuis le fichier source vers la table raw_staging, un nouvel id_batch unique est généré et attribué à toutes les lignes chargées. L'id_file_history correspondant au fichier est enregistré dans la table source_file_history.
Ensuite, lors du nettoyage et de l'intégration des données dans la table clean_staging, l'id_batch est conservé. Cela permet de tracer la provenance des données nettoyées jusqu'au fichier source.
Enfin, lorsque vous appelez la procédure dw.load_fact_real_estate_municipality pour charger les données dans la table de fait, vous lui passez l'id_file_history comme paramètre. La procédure utilise alors cet id_file_history pour récupérer l'id_batch correspondant dans la table source_file_history.
Avec cet id_batch, la procédure peut sélectionner les données de la table clean_staging qui correspondent à ce lot de chargement, les transformer selon les règles métier et les insérer dans la table de fait.

Donc l'id_file_history sert de clé pour retrouver le bon lot de données à charger depuis la table clean_staging vers la table de fait, mais il ne charge pas directement les données.
Il est important de noter que la procédure dw.load_fact_real_estate_municipality doit être codée pour sélectionner les données dans clean_staging en utilisant l'id_batch récupéré via l'id_file_history. Si ce n'est pas le cas, il faudra modifier la procédure.