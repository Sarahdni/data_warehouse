-- 01_raw_staging/procedures/detect_file_format.sql

CREATE OR REPLACE PROCEDURE raw_staging.detect_file_format(
    p_file_path TEXT,
    OUT p_format_type VARCHAR,
    OUT p_header_line VARCHAR,
    OUT p_column_count INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_delimiter CHAR(1) := ',';
    v_file_content TEXT;
    v_first_line TEXT;
    v_head_array TEXT[];
    v_minimal_columns TEXT[] := ARRAY['CD_REFNIS', 'CD_NIS_STAT_UNT_CLS', 'CD_NACE', 'MS_NUM_VAT', 'MS_NUM_VAT_START', 'MS_NUM_VAT_STOP'];
    v_complete_columns TEXT[] := ARRAY['CD_NIS_STAT_UNT_CLS', 'TX_NIS_STAT_UNT_CLS_FR_LVL1', 'CD_NACE', 'TX_NACE_FR_LVL1', 
                                       'CD_ADM_DSTR_REFNIS', 'MS_NUM_VAT', 'MS_NUM_VAT_START', 'MS_NUM_VAT_STOP'];
    v_minimal_matches INTEGER := 0;
    v_complete_matches INTEGER := 0;
BEGIN
    -- Log du début d'exécution
    PERFORM utils.log_script_execution('detect_file_format', 'RUNNING');
    
    -- Initialisation de la valeur par défaut pour p_format_type
    p_format_type := 'UNKNOWN';
    
    -- Lire les premières lignes du fichier directement avec pg_read_file
    EXECUTE 'SELECT * FROM pg_read_file($1, 0, 4000)' INTO v_file_content USING p_file_path;
    
    -- En cas d'erreur de lecture
    IF v_file_content IS NULL OR v_file_content = '' THEN
        RAISE EXCEPTION 'Impossible de lire le fichier: %', p_file_path;
    END IF;
    
    -- Extraire la première ligne (en-tête)
    v_first_line := split_part(v_file_content, E'\n', 1);
    
    -- Nettoyage et normalisation de l'en-tête
    v_first_line := TRIM(v_first_line);
    
    -- Convertir l'en-tête en tableau
    v_head_array := string_to_array(v_first_line, v_delimiter);
    p_column_count := array_length(v_head_array, 1);
    
    -- Normalisation des noms de colonnes (suppression des guillemets, espaces, etc.)
    FOR i IN 1..p_column_count LOOP
        v_head_array[i] := TRIM(REPLACE(REPLACE(v_head_array[i], '"', ''), ' ', ''));
    END LOOP;
    
    -- Détection du format
    FOR i IN 1..array_length(v_minimal_columns, 1) LOOP
        IF v_minimal_columns[i] = ANY(v_head_array) THEN
            v_minimal_matches := v_minimal_matches + 1;
        END IF;
    END LOOP;
    
    FOR i IN 1..array_length(v_complete_columns, 1) LOOP
        IF v_complete_columns[i] = ANY(v_head_array) THEN
            v_complete_matches := v_complete_matches + 1;
        END IF;
    END LOOP;
    
    -- Détermination du type
    IF v_minimal_matches >= 4 AND p_column_count <= 10 THEN
        p_format_type := 'MINIMAL';
    ELSIF v_complete_matches >= 6 AND p_column_count >= 25 THEN
        p_format_type := 'COMPLET';
    ELSE
        p_format_type := 'INCONNU';
    END IF;
    
    -- Sauvegarde de l'en-tête pour utilisation dans la procédure de chargement
    p_header_line := v_first_line;
    
    -- Log des résultats de détection
    PERFORM utils.log_script_execution('detect_file_format', 'SUCCESS', 
        format('Format détecté: %s. Nombre de colonnes: %s', p_format_type, p_column_count));

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur
    PERFORM utils.log_script_execution('detect_file_format', 'ERROR', SQLERRM);
    RAISE;
END;
$$;

COMMENT ON PROCEDURE raw_staging.detect_file_format(TEXT, OUT VARCHAR, OUT VARCHAR, OUT INTEGER) IS 
'Procédure de détection du format d''un fichier CSV de données NACE/VAT.
Cette procédure identifie automatiquement si le fichier est au format MINIMAL ou COMPLET.

Arguments:
- p_file_path: Chemin d''accès au fichier à analyser
- p_format_type (OUT): Contient le format détecté (MINIMAL, COMPLET ou INCONNU)
- p_header_line (OUT): Première ligne contenant l''en-tête
- p_column_count (OUT): Nombre de colonnes détectées

Format MINIMAL: Fichier historique avec colonnes de base (cd_refnis, cd_nis_stat_unt_cls, etc.)
Format COMPLET: Fichier récent avec colonnes étendues incluant les libellés multilingues';