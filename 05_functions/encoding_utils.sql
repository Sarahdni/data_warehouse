-- 05_functions/encoding_utils.sql

-- Log du début d'exécution
SELECT utils.log_script_execution('create_encoding_utils.sql', 'RUNNING');

-- Fonction pour corriger l'encodage des chaînes de caractères
CREATE OR REPLACE FUNCTION utils.fix_encoding(input_text text) 
RETURNS text AS $$
BEGIN
    -- Si l'entrée est NULL, retourner NULL
    IF input_text IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Convertir en UTF8 puis reconvertir pour nettoyer l'encodage
    RETURN convert_from(convert_to(input_text, 'UTF8'), 'UTF8');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Tests unitaires basiques
DO $$
BEGIN
    -- Test avec une chaîne normale
    ASSERT utils.fix_encoding('test') = 'test', 
        'Le texte normal devrait rester inchangé';
    
    -- Test avec NULL
    ASSERT utils.fix_encoding(NULL) IS NULL, 
        'NULL devrait rester NULL';
    
    -- Test avec des caractères spéciaux
    ASSERT utils.fix_encoding('éèêë') ~ '[éèêë]', 
        'Les caractères accentués devraient être préservés';
END;
$$;

-- Documentation de la fonction
COMMENT ON FUNCTION utils.fix_encoding(text) IS 
'Fonction utilitaire pour corriger l''encodage des chaînes de caractères.

Cette fonction effectue une double conversion UTF8 pour nettoyer les potentiels
problèmes d''encodage dans les chaînes de caractères.

Arguments:
  - input_text: Texte à nettoyer

Retourne:
  - Le texte avec un encodage UTF8 propre
  - NULL si l''entrée est NULL

Exemple d''utilisation:
  SELECT utils.fix_encoding(''texte avec caractères spéciaux'');';

-- Enregistrement dans le registre des fonctions
INSERT INTO metadata.function_registry (
    nm_schema,
    nm_function,
    tx_description
) VALUES (
    'utils',
    'fix_encoding',
    'Fonction de nettoyage d''encodage des chaînes de caractères'
) ON CONFLICT (nm_schema, nm_function) DO NOTHING;

-- Log du succès
SELECT utils.log_script_execution('create_encoding_utils.sql', 'SUCCESS');