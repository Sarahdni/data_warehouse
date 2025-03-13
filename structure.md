DATA_WAREHOUSE/
│
├── 00_init/
│   ├── create_extensions.sql
│   ├── create_metadata_tables.sql
│   ├── create_roles.sql
│   └── create_schemas.sql
│
├── 01_raw_staging/
│
│   ├── procedures/
│   │   ├── 
│   │   ├── 
│   │   ├── 
│   │   └── 
│   ├── tables/
│   │   ├── 
│   │   ├── 
│   │   ├── 
│   │   └── 
│   └── validation/
│       ├── 
│       ├── 
│       ├── 
│       └── 
├── 02_clean_staging/
│
│   ├── procedures/
│   │   ├── load_ref_nacebel.sql
│   │   ├── load_ref_nuts_lau.sql
│   │   ├── 
│   │   └── 
│   ├── tables/
│   │   ├── stg_ref_nacebel.sql
│   │   ├── stg_ref_nuts_lau.sql
│   │   ├── 
│   │   └── 
│   └── validation/
│       ├── validate_ref_nacebel.sql
│       ├── validate_ref_nuts_lau.sql
│       ├── 
│       
├── 03_dim_tables/
│
│   ├── employment/
│   │   ├── dim_economic_activity.sql
│   │   ├── dim_education_level.sql
│   │   ├── dim_entreprise_size_employees.sql
│   │   ├── dim_unemployment_type.sql
│   │   └── procedures/
│   │           └── load_dim_economic_activity.sql
│   ├── geography/
│   │   └── dim_geography.sql
│   │   └── procedures/
│   │           └── load_dim_geography.sql
│   ├── population/
│   │   ├── dim_age_group.sql
│   │   ├── dim_age.sql
│   │   ├── dim_civil_status.sql
│   │   ├── dim_cohabitation_status.sql
│   │   ├── dim_nationality.sql
│   │   └── dim_sex.sql
│   └── real_estate/
│   │   ├── dim_building_permit.sql
│   │   ├── dim_building_statistics.sql
│   │   ├── dim_building_type.sql
│   │   └── dim_residential_building.sql
│   ├── time/
│       └── dim_date.sql
│       └── procedures/
│              └── generate_dim_date.sql
│
├── 04_fact_tables/
│   ├── population/
│   │   ├── 
│   │   ├── 
│   │   └── 
│   ├── real_estate/
│   │   ├── 
│   │   ├── 
│   │   └── 
│   ├── taxes/
│   │   └── 
│   └── un_employment/
│       ├── 
│       └── 
│
├── 05_views/
│
├── 06_functions/
│
├── 07_maintenance/
│
├── 08_security/
│
└── 09_tests/





