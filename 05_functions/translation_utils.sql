-- Sauvegarde des données existantes
CREATE TEMP TABLE temp_missing_translations AS 
SELECT * FROM metadata.missing_translations;

-- Modification de la table
ALTER TABLE metadata.missing_translations 
    -- Renommer cd_nacebel en code_entity pour le rendre générique
    RENAME COLUMN cd_nacebel TO code_entity;
    
-- Ajout de colonnes pour rendre la table plus générique
ALTER TABLE metadata.missing_translations 
    ADD COLUMN entity_type VARCHAR(50),  -- Type d'entité (NACEBEL, SECTOR, etc.)
    ADD COLUMN field_name VARCHAR(100);   -- Nom du champ à traduire

-- Migration des données existantes
UPDATE metadata.missing_translations mt
SET 
    entity_type = 'NACEBEL',
    field_name = 'tx_nacebel_descr'
FROM temp_missing_translations tmp
WHERE mt.id_missing_translation = tmp.id_missing_translation;

-- Ajout des contraintes et index
ALTER TABLE metadata.missing_translations
    ALTER COLUMN entity_type SET NOT NULL,
    ADD CONSTRAINT ck_entity_type CHECK (entity_type IN ('NACEBEL', 'SECTOR', 'SUBMUNTY')),
    ADD CONSTRAINT uk_missing_translation UNIQUE (code_entity, entity_type, field_name, id_batch);

CREATE INDEX idx_missing_trans_entity 
    ON metadata.missing_translations(entity_type, code_entity);

-- Mise à jour des commentaires
COMMENT ON TABLE metadata.missing_translations IS 
'Table générique de suivi des traductions manquantes pour différentes entités (NACEBEL, secteurs statistiques, etc.)';

COMMENT ON COLUMN metadata.missing_translations.code_entity IS 
'Code de l''entité concernée (cd_nacebel, cd_sector, etc.)';

COMMENT ON COLUMN metadata.missing_translations.entity_type IS 
'Type d''entité concernée (NACEBEL, SECTOR, SUBMUNTY, etc.)';

COMMENT ON COLUMN metadata.missing_translations.field_name IS 
'Nom du champ nécessitant une traduction (tx_nacebel_descr, tx_sector_descr, etc.)';

COMMENT ON COLUMN metadata.missing_translations.tx_original_fr IS 
'Texte original en français à traduire';

COMMENT ON COLUMN metadata.missing_translations.missing_languages IS 
'Liste des codes langue manquants (ex: {DE,EN})';

