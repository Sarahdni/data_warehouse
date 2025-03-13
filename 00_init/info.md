
## Connexion:
psql postgres

# Création de la base de donnée:
CREATE DATABASE belgian_data;

## Réinitialisation de la base donnée from zero
psql template1 -f reset_database.sql




# L'ordre d'exécution de 00_init :

psql -U sarahdinari -d belgian_data -f 00_init/00_01_create_schemas.sql
psql -U sarahdinari -d belgian_data -f 00_init/00_02_create_metadata_tables.sql
psql -U sarahdinari -d belgian_data -f 00_init/00_03_create_extensions.sql
psql -U sarahdinari -d belgian_data -f 00_init/00_04_create_roles.sql
