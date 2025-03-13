--04_fact_tables/taxes/procedures/metadata.refnis_changes_2019.sql

-- Créer une table pour documenter les changements de codes REFNIS
CREATE TABLE metadata.refnis_changes_2019 (
   cd_refnis_pre2019 VARCHAR(5),
   cd_refnis_post2019 VARCHAR(5),
   tx_name_fr VARCHAR(100),
   dt_change DATE DEFAULT '2019-01-01',
   tx_note TEXT,
   dt_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (cd_refnis_pre2019, cd_refnis_post2019)
);

-- Documentation des changements
INSERT INTO metadata.refnis_changes_2019 (
   cd_refnis_pre2019, 
   cd_refnis_post2019, 
   tx_name_fr, 
   tx_note
) VALUES
('12030', '12041', 'Puurs-Sint-Amands', 'Ancienne commune de Puurs fusionnée en 2019'),
('12034', '12041', 'Puurs-Sint-Amands', 'Ancienne commune de Sint-Amands fusionnée en 2019'),
('45017', '45068', 'Kruisem', 'Ancienne commune de Kruishoutem fusionnée en 2019'),
('45057', '45068', 'Kruisem', 'Ancienne commune de Zingem fusionnée en 2019'),
('71047', '72042', 'Oudsbergen', 'Ancienne commune de Opglabbeek fusionnée en 2019'),
('72040', '72042', 'Oudsbergen', 'Ancienne commune de Meeuwen-Gruitrode fusionnée en 2019'),
('72025', '72043', 'Pelt', 'Ancienne commune de Neerpelt fusionnée en 2019'),
('72029', '72043', 'Pelt', 'Ancienne commune de Overpelt fusionnée en 2019'),
('44072', '44085', 'Lievegem', 'Ancienne commune de Waarschoot fusionnée en 2019'),
('44036', '44085', 'Lievegem', 'Ancienne commune de Lovendegem fusionnée en 2019'),
('44080', '44085', 'Lievegem', 'Ancienne commune de Zomergem fusionnée en 2019'),
('44011', '44083', 'Deinze', 'Renumérotation REFNIS'),
('44001', '44084', 'Aalter', 'Renumérotation REFNIS'),
('55010', '51067', 'Enghien', 'Renumérotation REFNIS'),
('55039', '51068', 'Silly', 'Renumérotation REFNIS'),
('55023', '51069', 'Lessines', 'Renumérotation REFNIS'),
('52063', '55085', 'Seneffe', 'Renumérotation REFNIS'),
('52043', '55086', 'Manage', 'Renumérotation REFNIS'),
('54007', '57096', 'Mouscron', 'Renumérotation REFNIS'),
('54010', '57097', 'Comines-Warneton', 'Renumérotation REFNIS'),
('55022', '58001', 'La Louvière', 'Renumérotation REFNIS'),
('56011', '58002', 'Binche', 'Renumérotation REFNIS'),
('56085', '58003', 'Estinnes', 'Renumérotation REFNIS'),
('56087', '58004', 'Morlanwelz', 'Renumérotation REFNIS');
('44029', '44084', 'Aalter', 'Ancienne commune de Knesselare fusionnée avec Aalter en 2019'),
('44049', '44083', 'Deinze', 'Ancienne commune de Nevele fusionnée avec Deinze en 2019');

-- Ajout des commentaires
COMMENT ON TABLE metadata.refnis_changes_2019 IS 
'Table documentant les changements de codes REFNIS survenus en 2019, incluant les fusions de communes et les renumérotations administratives';

COMMENT ON COLUMN metadata.refnis_changes_2019.cd_refnis_pre2019 IS 'Code REFNIS utilisé avant 2019';
COMMENT ON COLUMN metadata.refnis_changes_2019.cd_refnis_post2019 IS 'Nouveau code REFNIS utilisé à partir de 2019';
COMMENT ON COLUMN metadata.refnis_changes_2019.tx_name_fr IS 'Nom de la commune en français';
COMMENT ON COLUMN metadata.refnis_changes_2019.dt_change IS 'Date du changement (par défaut: 2019-01-01)';
COMMENT ON COLUMN metadata.refnis_changes_2019.tx_note IS 'Description du changement (fusion, renumérotation, etc.)';


