SET search_path TO gestion,occtax,sig,public;

-- organisme
INSERT INTO occtax.organisme
( nom_organisme )
VALUES ( '3liz' )
ON CONFLICT DO NOTHING;

-- acteur
INSERT INTO acteur
(
nom, prenom, civilite, id_organisme,
tel_1, tel_2, courriel, fonction, remarque
)
VALUES (
    'DOUCHIN', 'Michaël', 'M', (SELECT id_organisme FROM organisme WHERE nom_organisme = '3liz'),
    NULL, NULL, 'mdouchin@3liz.com', NULL, 'Acteur ajouté pour test'
)
ON CONFLICT DO NOTHING;

-- demande
DELETE FROM demande WHERE date_demande = now()::date AND usr_login = 'mdouchin';
INSERT INTO demande
(id_acteur, id_organisme, motif, type_demande,
date_demande, date_validite_min, date_validite_max,
group1_inpn, group2_inpn,
libelle_geom, geom, validite_niveau
)
VALUES (
    (SELECT id_acteur FROM acteur WHERE nom = 'DOUCHIN' AND prenom = 'Michaël'),
    (SELECT id_organisme FROM organisme WHERE nom_organisme = '3liz'),
    'test de demande',
    'PT',
    now()::date,
    now()::date,
    now() + '1 month'::interval,
    NULL,
    Array['Angiospermes'],
    'commune de saint leu',
    (SELECT geom FROM commune WHERE nom_commune = 'Saint-Leu'),
    ARRAY['1', '2', '3', '4', '5']
);

-- créer l'utilisateur mdouchin via l'interface d'administration de Lizmap
-- le placer dans un profil avec droits de voir les données brutes

-- Enfin modifier la demande pour mettre mdouchin comme usr_login
UPDATE demande
SET usr_login = 'mdouchin'
WHERE id_acteur = (SELECT id_acteur FROM acteur WHERE nom = 'DOUCHIN' AND prenom = 'Michaël')
AND motif = 'test de demande'
;

-- Modification du filtrer de sensibilité
UPDATE demande
SET validite_niveau = ARRAY['1', '2', '3', '4', '5', '6']
WHERE id_acteur = (SELECT id_acteur FROM acteur WHERE nom = 'DOUCHIN' AND prenom = 'Michaël')
AND motif = 'test de demande'
;

-- Modifier la géométrie
UPDATE demande
SET geom = (SELECT ST_Union(geom) FROM sig.commune WHERE nom_commune IN ('Saint-Leu'))
WHERE id_acteur = (SELECT id_acteur FROM acteur WHERE nom = 'DOUCHIN' AND prenom = 'Michaël')
AND motif = 'test de demande'
;

-- Modifier le group inpn 2
UPDATE demande
SET group2_inpn = array['Angiospermes', 'Oiseaux']
WHERE id_acteur = (SELECT id_acteur FROM acteur WHERE nom = 'DOUCHIN' AND prenom = 'Michaël')
AND motif = 'test de demande'
;
SELECT * FROM demande
