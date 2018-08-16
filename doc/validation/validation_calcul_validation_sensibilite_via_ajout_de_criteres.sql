BEGIN;

Set search_path TO occtax,sig,public;

-- VALIDATION
-- 1er test
INSERT INTO critere_validation
(cd_nom, libelle, "condition", table_jointure, niveau)
VALUES(
    ARRAY[705993,706098],
    'Observations de moins de 1 an',
    'o.date_debut > NOW() - INTERVAL ''1 year''',
    NULL,
    3
);

-- 2ème test
INSERT INTO critere_validation
(cd_nom, libelle, "condition", table_jointure, niveau)
VALUES(
    ARRAY[459500,441946,432596,810738],
    'Observations avec une altitude supérieure à 200 m ',
    'o.altitude_max > 200',
    NULL,
    2
);

-- 3eme test spatial
-- a/ On crée une table de test avec des tampons de 2km autour des espaces naturels
DROP TABLE IF EXISTS sig.test_a_supprimer;
CREATE TABLE sig.test_a_supprimer AS
SELECT code_en, type_en, ST_Buffer(geom, 2000) AS geom
FROM sig.espace_naturel
WHERE type_en = 'SCL';
CREATE INDEX ON sig.test_a_supprimer USING GIST (geom);

-- b/ on ajoute le critère avec cette table dans la table de jointure
INSERT INTO critere_validation
(cd_nom, libelle, description, "condition", table_jointure, niveau)
VALUES(
    ARRAY[459500,441946,432596,810738],
    'Observations à moins de 2km des zones du Conservatoire du littoral',
    'Observations à moins de 2km des zones du Conservatoire du littoral',
    'ST_Intersects(o.geom, t.geom)',
    'sig.test_a_supprimer',
    5
);


-- Ajouter les métadonnées de la prcédure de validation
INSERT INTO occtax.validation_procedure (proc_ref, "procedure", proc_vers)
VALUES ('1.0.0', 'Procédure de validation de test', '1.0.0')
ON CONFLICT DO NOTHING;

-- Lancer la fonction de calcul de validation
SELECT occtax.calcul_niveau_validation(
    NULL, -- jdd_id
    (SELECT id_personne FROM occtax.personne WHERE nom = 'NOTTER' LIMIT 1), -- validateur
    FALSE -- pas de simulation : on applique en direct
);
-- SELECT * FROM validation_observation;



-- SENSIBILITE

-- Ajout d'un critère
INSERT INTO occtax.critere_sensibilite (cd_nom, libelle, "condition", table_jointure, niveau)
VALUES (ARRAY[441613], '1', 'o.commentaire ILIKE ''%nid%'' OR o.commentaire ILIKE ''%terrier %'' OR o.commentaire ILIKE ''%colonie %'' OR o.descriptif_sujet @>  ''[{"occ_statut_biologique": "4"}]'' OR o.descriptif_sujet @>  ''[{"occ_stade_de_vie": "9"}]'' OR o.descriptif_sujet @>  ''[{"occ_stade_de_vie": "25"}]''   ', NULL, '2');


-- Ajout d'un critère plus complexe avec une condition sur le contenu de descriptif_sujet
INSERT INTO occtax.critere_sensibilite (cd_nom, libelle, "condition", table_jointure, niveau)
VALUES (
    ARRAY[441613],
    'test',
    '  commentaire ~*  ''nid|nich|terrier|colonie|reproduct'' -- ~* veut dire "expression régulière insensible à la casse"
    OR descriptif_sujet::text ~* ''"occ_statut_biologique": "3"'' -- si une seule valeur recherchée
    OR descriptif_sujet::text ~* ''"occ_stade_de_vie": "(9|25)"''  -- Les parenthèses son importante !
    OR (donnee_complementaire->>''atlas_code'')::integer BETWEEN 2 AND 19
    OR (donnee_complementaire->>''atlas_code'')::integer IN (30, 40, 50)
    ',
    NULL, '2'
);

-- Ajout du référentuel dans sensibilite_referentiel
INSERT INTO occtax.sensibilite_referentiel (sensi_referentiel, sensi_version_referentiel, description)
VALUES ('Référentiel de sensibilité TEST', '1.0.0', 'Un référentiel de sensibilité de test')
ON CONFLICT DO NOTHING;

-- Calcul
SELECT occtax.calcul_niveau_sensibilite(
    NULL, -- jdd_id . Si NULL, toutes les observations sont concernées
    FALSE  -- pas de simulation : on applique en direct
);


SELECT count(cle_obs) AS nb, sensi_referentiel, sensi_niveau
FROM observation
WHERE TRUE
-- AND sensi_referentiel = 'Référentiel de sensibilité TEST'
GROUP BY sensi_niveau, sensi_referentiel;

COMMIT;
