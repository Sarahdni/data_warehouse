# D'abord, créons les tables de staging :

psql -U sarahdinari -d belgian_data -f 01_staging/tables/stg_ref_nuts_lau.sql

# Ensuite, la procédure de chargement :

psql -U sarahdinari -d belgian_data -f 01_staging/procedures/load_ref_nuts_lau.sql

# Enfin, la validation :
psql -U sarahdinari -d belgian_data -f 01_staging/validation/validate_ref_nuts_lau.sql

# Vérifions que tout est bien en place :

La table de staging a été créée
La procédure de chargement est installée
La procédure de validation et sa table de log sont créées

-- Liste des objets créés
\d staging.stg_ref_nuts_lau
\df staging.load_ref_nuts_lau
\df staging.validate_ref_nuts_lau
