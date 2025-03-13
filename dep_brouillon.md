PHASE 9: TABLES DE FAITS - EMPLOI ET TAXES
========================================
1. 03_fact_tables/employment/
   - fact_unemployment.sql

2. 03_fact_tables/taxes/
   - fact_personal_income_tax.sql

PHASE 10: VUES MÉTIER
========================================
1. 04_views/real_estate/
   - v_building_statistics.sql
   - v_construction_permits.sql
   - v_real_estate_prices.sql

2. 04_views/population/
   - v_population_structure.sql
   - v_household_composition.sql

3. 04_views/employment/
   - v_unemployment_rates.sql
   - v_employment_sectors.sql

4. 04_views/taxes/
   - v_income_statistics.sql
   - v_tax_distribution.sql

PHASE 11: MAINTENANCE ET SÉCURITÉ
========================================
1. 06_maintenance/
   - purge_staging.sql
   - rebuild_indexes.sql
   - update_statistics.sql

2. 07_security/
   - roles.sql
   - grants.sql

PHASE 12: TESTS
========================================
1. 08_tests/
   - test_staging.sql
   - test_dimensions.sql
   - test_facts.sql

DOCUMENTATION CONTINUE
========================================
docs/
  - Mettre à jour au fur et à mesure
  - Documenter chaque phase
  - Inclure les diagrammes
  - Documenter les choix techniques











DATA_WAREHOUSE/
│
├── 00_init/
│   ├── create_extensions.sql
│   ├── create_roles.sql
│   └── create_schemas.sql
│
├── 01_staging/
│
│   ├── procedures/
│   │   ├── load_building_permits.sql
│   │   ├── load_building_stock.sql
│   │   ├── load_cohab_pop.sql
│   │   └── load_immo_sector.sql
│   ├── tables/
│   │   ├── stg_building_permits.sql
│   │   ├── stg_building_stock.sql
│   │   ├── stg_cohab_pop.sql
│   │   └── stg_immo_sector.sql
│   └── validation/
│       ├── validate_building_permits.sql
│       ├── validate_building_stock.sql
│       ├── validate_cohab_pop.sql
│       └── validate_immo_sector.sql
├── 02_dim_tables/
│
│   ├── employment/
│   │   ├── dim_economic_activity.sql
│   │   ├── dim_education_level.sql
│   │   ├── dim_entreprise_size_employees.sql
│   │   └── dim_unemployment_type.sql
│   ├── geography/
│   │   └── dim_geography.sql
│   ├── population/
│   │   ├── dim_age_group.sql
│   │   ├── dim_age.sql
│   │   ├── dim_civil_status.sql
│   │   ├── dim_cohabitation_status.sql
│   │   ├── dim_nationality.sql
│   │   └── dim_sex.sql
│   └── real_estate/
│       ├── dim_building_permit.sql
│       ├── dim_building_statistics.sql
│       ├── dim_building_type.sql
│       └── dim_residential_building.sql
│
├── 03_fact_tables/
│   ├── population/
│   │   ├── fact_household_cohabitation.sql
│   │   ├── fact_household_vehicles.sql
│   │   └── fact_population_structure.sql
│   ├── real_estate/
│   │   ├── fact_building_permits.sql
│   │   ├── fact_building_stock.sql
│   │   └── fact_real_estate_transactions.sql
│   ├── taxes/
│   │   └── fact_taxes.sql
│   └── un_employment/
│       ├── fact_nace_employment.sql
│       └── fact_unemployment.sql
│
├── 04_views/
│   ├── population/
│   │   ├── v_household_composition.sql
│   │   ├── v_household_vehicles.sql
│   │   └── v_population_structure.sql
│   ├── real_estate/
│   │   ├── v_building_statistics.sql
│   │   ├── v_construction_permits.sql
│   │   └── v_real_estate_prices.sql
│   ├── taxes/
│   │   ├── v_income_statistics.sql
│   │   └── v_tax_distribution.sql
│   └── un_employment/
│       ├── v_employment_sectors.sql
│       ├── v_entrpreprise_size_evaluation.sql
│       └── v_unemployment_rates.sql
│
├── 05_functions/
│
├── 06_maintenance/
│
├── 07_security/
│
└── 08_tests/