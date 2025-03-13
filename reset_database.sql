-- Se connecter à la base template1
-- psql template1 -f reset_database.sql
\c template1;

-- Terminer toutes les connexions à la base belgian_data
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE datname = 'belgian_data' 
  AND pid <> pg_backend_pid();

-- Supprimer la base de données
DROP DATABASE IF EXISTS belgian_data;

-- Recréer la base de données
CREATE DATABASE belgian_data
    WITH 
    OWNER = sarahdinari
    ENCODING = 'UTF8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

-- Commentaire sur la base de données
COMMENT ON DATABASE belgian_data
    IS 'Entrepôt de données pour les statistiques belges';