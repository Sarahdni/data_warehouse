-- Script généré automatiquement le 2025-02-20 21:44:20
-- Mise à jour des sources de données
BEGIN;

-- Vérification de l'existence de la table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                WHERE table_schema = 'metadata' 
                AND table_name = 'dim_source') THEN
        RAISE EXCEPTION 'La table metadata.dim_source n''existe pas!';
    END IF;
END $$;

-- Suppression des anciens enregistrements pour BUILDING_STOCK
DELETE FROM metadata.dim_source
WHERE cd_source = 'BUILDING_STOCK';
DELETE FROM metadata.dim_source
WHERE cd_source LIKE 'BUILDING_STOCK_%';

-- Suppression des anciens enregistrements pour CAR_HOUSEHOLDS
DELETE FROM metadata.dim_source
WHERE cd_source = 'CAR_HOUSEHOLDS';
DELETE FROM metadata.dim_source
WHERE cd_source LIKE 'CAR_HOUSEHOLDS_%';

-- Suppression des anciens enregistrements pour IMMO_BY_MUNICIPALITY
DELETE FROM metadata.dim_source
WHERE cd_source = 'IMMO_BY_MUNICIPALITY';
DELETE FROM metadata.dim_source
WHERE cd_source LIKE 'IMMO_BY_MUNICIPALITY_%';

-- Function to handle the inserts
DO $$
DECLARE
    current_date date := CURRENT_DATE;
BEGIN
    -- Insert generic record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK', 'FILE', 'building_stock_*.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments', NULL, NULL, NULL, 'Données sur le parc immobilier', 'YEARLY', '1995-01-01', '2024-12-31', 2024, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 1995 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_1995', 'FILE', 'building_stock_1995.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 1995', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 1995', 'YEARLY', '1995-01-01', '1995-12-31', 1995, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 1998 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_1998', 'FILE', 'building_stock_1998.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 1998', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 1998', 'YEARLY', '1998-01-01', '1998-12-31', 1998, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2001 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2001', 'FILE', 'building_stock_2001.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2001', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2001', 'YEARLY', '2001-01-01', '2001-12-31', 2001, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2002 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2002', 'FILE', 'building_stock_2002.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2002', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2002', 'YEARLY', '2002-01-01', '2002-12-31', 2002, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2003 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2003', 'FILE', 'building_stock_2003.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2003', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2003', 'YEARLY', '2003-01-01', '2003-12-31', 2003, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2004 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2004', 'FILE', 'building_stock_2004.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2004', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2004', 'YEARLY', '2004-01-01', '2004-12-31', 2004, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2005 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2005', 'FILE', 'building_stock_2005.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2005', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2005', 'YEARLY', '2005-01-01', '2005-12-31', 2005, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2006 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2006', 'FILE', 'building_stock_2006.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2006', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2006', 'YEARLY', '2006-01-01', '2006-12-31', 2006, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2007 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2007', 'FILE', 'building_stock_2007.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2007', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2007', 'YEARLY', '2007-01-01', '2007-12-31', 2007, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2008 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2008', 'FILE', 'building_stock_2008.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2008', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2008', 'YEARLY', '2008-01-01', '2008-12-31', 2008, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2009 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2009', 'FILE', 'building_stock_2009.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2009', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2009', 'YEARLY', '2009-01-01', '2009-12-31', 2009, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2010 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2010', 'FILE', 'building_stock_2010.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2010', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2010', 'YEARLY', '2010-01-01', '2010-12-31', 2010, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2011 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2011', 'FILE', 'building_stock_2011.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2011', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2011', 'YEARLY', '2011-01-01', '2011-12-31', 2011, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2012 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2012', 'FILE', 'building_stock_2012.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2012', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2012', 'YEARLY', '2012-01-01', '2012-12-31', 2012, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2013 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2013', 'FILE', 'building_stock_2013.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2013', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2013', 'YEARLY', '2013-01-01', '2013-12-31', 2013, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2014 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2014', 'FILE', 'building_stock_2014.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2014', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2014', 'YEARLY', '2014-01-01', '2014-12-31', 2014, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2015 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2015', 'FILE', 'building_stock_2015.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2015', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2015', 'YEARLY', '2015-01-01', '2015-12-31', 2015, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2016 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2016', 'FILE', 'building_stock_2016.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2016', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2016', 'YEARLY', '2016-01-01', '2016-12-31', 2016, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2017 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2017', 'FILE', 'building_stock_2017.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2017', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2017', 'YEARLY', '2017-01-01', '2017-12-31', 2017, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2018 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2018', 'FILE', 'building_stock_2018.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2018', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2018', 'YEARLY', '2018-01-01', '2018-12-31', 2018, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2019 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2019', 'FILE', 'building_stock_2019.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2019', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2019', 'YEARLY', '2019-01-01', '2019-12-31', 2019, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2020 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2020', 'FILE', 'building_stock_2020.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2020', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2020', 'YEARLY', '2020-01-01', '2020-12-31', 2020, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2021 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2021', 'FILE', 'building_stock_2021.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2021', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2021', 'YEARLY', '2021-01-01', '2021-12-31', 2021, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2022 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2022', 'FILE', 'building_stock_2022.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2022', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2022', 'YEARLY', '2022-01-01', '2022-12-31', 2022, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2023 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2023', 'FILE', 'building_stock_2023.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2023', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2023', 'YEARLY', '2023-01-01', '2023-12-31', 2023, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2024 record for BUILDING_STOCK
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'BUILDING_STOCK_2024', 'FILE', 'building_stock_2024.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/building_stock_statistiques_cadastrales', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Stock des bâtiments 2024', NULL, NULL, NULL, 'Données sur le parc immobilier pour l'année 2024', 'YEARLY', '2024-01-01', '2024-12-31', 2024, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert generic record for CAR_HOUSEHOLDS
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'CAR_HOUSEHOLDS', 'FILE', 'car_households_*.csv', '/Users/sarahdinari/Desktop/data_lake/mobility/car_households', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Voitures par type de ménage', NULL, NULL, NULL, 'Nombre de voitures selon le type de ménage par commune', 'YEARLY', '2017-01-01', '2023-12-31', 2023, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', 'https://statbel.fgov.be/fr/themes/mobilite/circulation/possession-de-vehicules', true
    );

    -- Insert 2017 record for CAR_HOUSEHOLDS
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'CAR_HOUSEHOLDS_2017', 'FILE', 'car_households_2017.csv', '/Users/sarahdinari/Desktop/data_lake/mobility/car_households', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Voitures par type de ménage 2017', NULL, NULL, NULL, 'Nombre de voitures selon le type de ménage par commune pour l'année 2017', 'YEARLY', '2017-01-01', '2017-12-31', 2017, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2018 record for CAR_HOUSEHOLDS
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'CAR_HOUSEHOLDS_2018', 'FILE', 'car_households_2018.csv', '/Users/sarahdinari/Desktop/data_lake/mobility/car_households', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Voitures par type de ménage 2018', NULL, NULL, NULL, 'Nombre de voitures selon le type de ménage par commune pour l'année 2018', 'YEARLY', '2018-01-01', '2018-12-31', 2018, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2019 record for CAR_HOUSEHOLDS
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'CAR_HOUSEHOLDS_2019', 'FILE', 'car_households_2019.csv', '/Users/sarahdinari/Desktop/data_lake/mobility/car_households', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Voitures par type de ménage 2019', NULL, NULL, NULL, 'Nombre de voitures selon le type de ménage par commune pour l'année 2019', 'YEARLY', '2019-01-01', '2019-12-31', 2019, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2020 record for CAR_HOUSEHOLDS
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'CAR_HOUSEHOLDS_2020', 'FILE', 'car_households_2020.csv', '/Users/sarahdinari/Desktop/data_lake/mobility/car_households', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Voitures par type de ménage 2020', NULL, NULL, NULL, 'Nombre de voitures selon le type de ménage par commune pour l'année 2020', 'YEARLY', '2020-01-01', '2020-12-31', 2020, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2021 record for CAR_HOUSEHOLDS
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'CAR_HOUSEHOLDS_2021', 'FILE', 'car_households_2021.csv', '/Users/sarahdinari/Desktop/data_lake/mobility/car_households', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Voitures par type de ménage 2021', NULL, NULL, NULL, 'Nombre de voitures selon le type de ménage par commune pour l'année 2021', 'YEARLY', '2021-01-01', '2021-12-31', 2021, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2022 record for CAR_HOUSEHOLDS
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'CAR_HOUSEHOLDS_2022', 'FILE', 'car_households_2022.csv', '/Users/sarahdinari/Desktop/data_lake/mobility/car_households', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Voitures par type de ménage 2022', NULL, NULL, NULL, 'Nombre de voitures selon le type de ménage par commune pour l'année 2022', 'YEARLY', '2022-01-01', '2022-12-31', 2022, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert 2023 record for CAR_HOUSEHOLDS
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'CAR_HOUSEHOLDS_2023', 'FILE', 'car_households_2023.csv', '/Users/sarahdinari/Desktop/data_lake/mobility/car_households', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Voitures par type de ménage 2023', NULL, NULL, NULL, 'Nombre de voitures selon le type de ménage par commune pour l'année 2023', 'YEARLY', '2023-01-01', '2023-12-31', 2023, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert generic record for IMMO_BY_MUNICIPALITY
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'IMMO_BY_MUNICIPALITY', 'FILE', 'immo_by_municipality_*_*.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/immo_by_municipality', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Analyses immobilières par commune', NULL, NULL, NULL, 'Analyses détaillées du marché immobilier par commune de 1980 à 2019', 'YEARLY', '1980-01-01', '2019-12-31', 2019, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', 'https://statbel.fgov.be/fr/themes/construction-logement/prix-de-limmobilier', true
    );

    -- Insert period 1980-1989 record for IMMO_BY_MUNICIPALITY
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'IMMO_BY_MUNICIPALITY_1980_2019', 'FILE', 'immo_by_municipality_1980_2019.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/immo_by_municipality', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Analyses immobilières par commune 1980-2019', NULL, NULL, NULL, 'Analyses détaillées du marché immobilier par commune pour la période 1980-2019', 'YEARLY', '1980-01-01', '1980-12-31', 1980, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert period 1990-1999 record for IMMO_BY_MUNICIPALITY
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'IMMO_BY_MUNICIPALITY_1980_2019', 'FILE', 'immo_by_municipality_1980_2019.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/immo_by_municipality', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Analyses immobilières par commune 1980-2019', NULL, NULL, NULL, 'Analyses détaillées du marché immobilier par commune pour la période 1980-2019', 'YEARLY', '1990-01-01', '1990-12-31', 1990, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert period 2000-2009 record for IMMO_BY_MUNICIPALITY
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'IMMO_BY_MUNICIPALITY_1980_2019', 'FILE', 'immo_by_municipality_1980_2019.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/immo_by_municipality', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Analyses immobilières par commune 1980-2019', NULL, NULL, NULL, 'Analyses détaillées du marché immobilier par commune pour la période 1980-2019', 'YEARLY', '2000-01-01', '2000-12-31', 2000, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

    -- Insert period 2010-2019 record for IMMO_BY_MUNICIPALITY
    INSERT INTO metadata.dim_source (
        cd_source, cd_type, tx_file_pattern, tx_file_path, tx_file_format, tx_delimiter, tx_encoding, tx_api_url, tx_api_method, tx_api_auth_type, tx_api_parameters, tx_name_fr, tx_name_nl, tx_name_de, tx_name_en, tx_description_fr, cd_frequency, dt_data_start, dt_data_end, cd_reference_year, dt_last_update, cd_geographic_level, tx_provider, tx_official_url, fl_active
    ) VALUES (
        'IMMO_BY_MUNICIPALITY_1980_2019', 'FILE', 'immo_by_municipality_1980_2019.csv', '/Users/sarahdinari/Desktop/data_lake/real_estate/immo_by_municipality', 'CSV', ,, 'UTF-8', NULL, NULL, NULL, NULL, 'Analyses immobilières par commune 1980-2019', NULL, NULL, NULL, 'Analyses détaillées du marché immobilier par commune pour la période 1980-2019', 'YEARLY', '2010-01-01', '2010-12-31', 2010, 'CURRENT_DATE', 'MUNICIPALITY', 'STATBEL', NULL, true
    );

END $$;

COMMIT;
