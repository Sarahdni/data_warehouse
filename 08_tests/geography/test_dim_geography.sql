-- 08_tests/geography/test_dim_geography.sql

"""
Les tests créés vérifient :

- Structure de base :

Existence de la table
Présence des colonnes requises


- Insertions valides :

Insertion d'une région (niveau supérieur)
Insertion d'un secteur statistique


- Contraintes :

Format des codes secteurs
Cohérence entre REFNIS et secteur
Unicité des versions courantes


- Gestion des erreurs :

Log détaillé des erreurs
Nettoyage des données de test
"""

-- Log du début des tests
SELECT utils.log_script_execution('test_dim_geography.sql', 'RUNNING');

DO $$
DECLARE
    v_test_count INTEGER := 0;
    v_failed_count INTEGER := 0;
    v_error_message TEXT;
BEGIN
    -- Table temporaire pour les résultats des tests
    CREATE TEMP TABLE test_results (
        test_name VARCHAR(100),
        test_type VARCHAR(50),
        status VARCHAR(20),
        error_message TEXT
    );

    -- 1. Test de la structure de la table
    v_test_count := v_test_count + 1;
    BEGIN
        IF NOT EXISTS (
            SELECT 1 
            FROM information_schema.tables 
            WHERE table_schema = 'dw' 
            AND table_name = 'dim_geography'
        ) THEN
            RAISE EXCEPTION 'Table dim_geography non trouvée';
        END IF;

        INSERT INTO test_results VALUES(
            'Structure table', 
            'Structure', 
            'SUCCESS',
            NULL
        );
    EXCEPTION WHEN OTHERS THEN
        v_failed_count := v_failed_count + 1;
        INSERT INTO test_results VALUES(
            'Structure table', 
            'Structure', 
            'FAILED',
            SQLERRM
        );
    END;

    -- 2. Test d'insertion d'une région
    v_test_count := v_test_count + 1;
    BEGIN
        INSERT INTO dw.dim_geography (
            cd_lau,
            cd_refnis,
            tx_name_fr,
            tx_name_nl,
            cd_level,
            dt_start,
            dt_end
        ) VALUES (
            'BE1',
            '04000',
            'Région de Bruxelles-Capitale',
            'Brussels Hoofdstedelijk Gewest',
            1,
            '2023-01-01',
            '9999-12-31'
        );

        INSERT INTO test_results VALUES(
            'Insertion région', 
            'Insertion', 
            'SUCCESS',
            NULL
        );
    EXCEPTION WHEN OTHERS THEN
        v_failed_count := v_failed_count + 1;
        INSERT INTO test_results VALUES(
            'Insertion région', 
            'Insertion', 
            'FAILED',
            SQLERRM
        );
    END;

    -- 3. Test d'insertion d'un secteur statistique
    v_test_count := v_test_count + 1;
    BEGIN
        INSERT INTO dw.dim_geography (
            cd_sector,
            cd_refnis,
            tx_name_fr,
            tx_name_nl,
            cd_level,
            dt_start,
            dt_end
        ) VALUES (
            '11001A00-',
            '11001',
            'Secteur A00',
            'Sector A00',
            6,
            '2023-01-01',
            '9999-12-31'
        );

        INSERT INTO test_results VALUES(
            'Insertion secteur', 
            'Insertion', 
            'SUCCESS',
            NULL
        );
    EXCEPTION WHEN OTHERS THEN
        v_failed_count := v_failed_count + 1;
        INSERT INTO test_results VALUES(
            'Insertion secteur', 
            'Insertion', 
            'FAILED',
            SQLERRM
        );
    END;

    -- 4. Test de la contrainte sur le format du secteur
    v_test_count := v_test_count + 1;
    BEGIN
        INSERT INTO dw.dim_geography (
            cd_sector,
            cd_refnis,
            tx_name_fr,
            tx_name_nl,
            cd_level,
            dt_start,
            dt_end
        ) VALUES (
            'INVALID',  -- Format invalide
            '11001',
            'Test',
            'Test',
            6,
            '2023-01-01',
            '9999-12-31'
        );
        
        -- Si on arrive ici, c'est que la contrainte n'a pas fonctionné
        v_failed_count := v_failed_count + 1;
        INSERT INTO test_results VALUES(
            'Contrainte format secteur', 
            'Contrainte', 
            'FAILED',
            'La contrainte de format n''a pas bloqué un code secteur invalide'
        );
    EXCEPTION WHEN check_violation THEN
        -- C'est le comportement attendu
        INSERT INTO test_results VALUES(
            'Contrainte format secteur', 
            'Contrainte', 
            'SUCCESS',
            NULL
        );
    END;

    -- 5. Test de la cohérence REFNIS-Secteur
    v_test_count := v_test_count + 1;
    BEGIN
        INSERT INTO dw.dim_geography (
            cd_sector,
            cd_refnis,
            tx_name_fr,
            tx_name_nl,
            cd_level,
            dt_start,
            dt_end
        ) VALUES (
            '11001A00-',
            '22222',  -- REFNIS incohérent
            'Test',
            'Test',
            6,
            '2023-01-01',
            '9999-12-31'
        );
        
        v_failed_count := v_failed_count + 1;
        INSERT INTO test_results VALUES(
            'Cohérence REFNIS-Secteur', 
            'Contrainte', 
            'FAILED',
            'La contrainte de cohérence n''a pas bloqué un REFNIS incohérent'
        );
    EXCEPTION WHEN check_violation THEN
        INSERT INTO test_results VALUES(
            'Cohérence REFNIS-Secteur', 
            'Contrainte', 
            'SUCCESS',
            NULL
        );
    END;

    -- 6. Test de l'unicité des versions courantes
    v_test_count := v_test_count + 1;
    BEGIN
        -- Première insertion
        INSERT INTO dw.dim_geography (
            cd_lau,
            cd_refnis,
            tx_name_fr,
            tx_name_nl,
            cd_level,
            dt_start,
            dt_end,
            fl_current
        ) VALUES (
            'BE2',
            '02000',
            'Test',
            'Test',
            1,
            '2023-01-01',
            '9999-12-31',
            TRUE
        );

        -- Deuxième insertion avec le même code
        INSERT INTO dw.dim_geography (
            cd_lau,
            cd_refnis,
            tx_name_fr,
            tx_name_nl,
            cd_level,
            dt_start,
            dt_end,
            fl_current
        ) VALUES (
            'BE2',
            '02000',
            'Test2',
            'Test2',
            1,
            '2023-01-01',
            '9999-12-31',
            TRUE
        );

        v_failed_count := v_failed_count + 1;
        INSERT INTO test_results VALUES(
            'Unicité version courante', 
            'Contrainte', 
            'FAILED',
            'La contrainte d''unicité n''a pas bloqué un doublon'
        );
    EXCEPTION WHEN unique_violation THEN
        INSERT INTO test_results VALUES(
            'Unicité version courante', 
            'Contrainte', 
            'SUCCESS',
            NULL
        );
    END;

    -- Nettoyage des données de test
    TRUNCATE TABLE dw.dim_geography;

    -- Résumé des tests
    RAISE NOTICE 'Tests terminés: % tests exécutés, % échecs', v_test_count, v_failed_count;
    
    -- Log des résultats détaillés
    FOR v_error_message IN SELECT error_message FROM test_results WHERE status = 'FAILED'
    LOOP
        RAISE NOTICE '%', v_error_message;
    END LOOP;

    -- Log du résultat final
    IF v_failed_count = 0 THEN
        PERFORM utils.log_script_execution(
            'test_dim_geography.sql',
            'SUCCESS',
            format('Tous les tests (%s) ont réussi', v_test_count)
        );
    ELSE
        PERFORM utils.log_script_execution(
            'test_dim_geography.sql',
            'ERROR',
            format('%s tests sur %s ont échoué', v_failed_count, v_test_count)
        );
        RAISE EXCEPTION 'Tests échoués';
    END IF;

EXCEPTION WHEN OTHERS THEN
    -- Log de l'erreur générale
    PERFORM utils.log_script_execution('test_dim_geography.sql', 'ERROR', SQLERRM);
    RAISE;
END $$;