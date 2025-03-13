# Pour créer cette table de dimmension :

psql -U sarahdinari -d belgian_data -f 02_dim_tables/geography/dim_geography.sql

# Lancer la procedure de chargement :
psql -U sarahdinari -d belgian_data -f 02_dim_tables/geography/procedures/load_dim_geography.sql