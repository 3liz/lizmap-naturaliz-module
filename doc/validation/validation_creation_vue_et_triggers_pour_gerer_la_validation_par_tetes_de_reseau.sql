BEGIN;

-- EXEMPLE avec organisme de validation ACME et utilisateur John DOE

SET search_path TO occtax,public;

-- DROP ROLE validation_test;
CREATE ROLE validation_acme LOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
ALTER ROLE validation_acme WITH PASSWORD 'acme';
GRANT USAGE ON SCHEMA occtax TO validation_acme;

-- créer un nouvel utilisateur et le mettre dans le groupe
CREATE ROLE validation_test LOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
ALTER ROLE validation_test WITH PASSWORD 'V@L1D_**TeSt%';
-- on met cet utilisateur dans le groupe validation_acme
GRANT validation_acme TO validation_test;

-- ajout dans validation_personne
INSERT INTO occtax.personne (identite, nom, prenom, mail, organisme)
VALUES ('DOE John (ACME)', 'DOE', 'John', 'john.doe@acme.acme', 'ACME')
ON CONFLICT DO NOTHING
;
INSERT INTO validation_personne
(id_personne, role_postgresql, role_postgresql_groupe)
VALUES (
    (SELECT id_personne FROM personne WHERE nom = 'DOE' AND prenom = 'John' AND mail = 'john.doe@acme.acme' ),
    'validation_test',
    'validation_acme'
);


-- On ajoute une procédure de validation si elle n'existe pas déjà !
INSERT INTO occtax.validation_procedure (proc_ref, "procedure", proc_vers)
VALUES ('1.0.0', 'Procédure de validation de test', '1.0.0')
ON CONFLICT DO NOTHING;

-- On crée une vue qui filtre les données comme on le souhaite
-- dans cet exemple, on a filtré sur le group2_inpn. On pourrait très bien filtrer sur d'autres critères
DROP VIEW IF EXISTS occtax.v_observation_validation_test;
CREATE VIEW occtax.v_observation_validation_test AS
SELECT *
FROM occtax.v_observation_validation o
WHERE TRUE
AND group2_inpn = 'Oiseaux';

-- On crée une vue pour mettre à plat descriptif sujet
-- à partir de la vue précédente
DROP VIEW IF EXISTS occtax.v_descriptif_sujet_test;
CREATE VIEW occtax.v_descriptif_sujet_test AS
SELECT cle_obs, ds.*
FROM occtax.v_observation_validation_test o
join
jsonb_to_recordset(o.descriptif_sujet) AS ds (
    obs_methode text, occ_etat_biologique text, occ_naturalite text, occ_sexe text,
    occ_stade_de_vie text, occ_statut_biogeographique text, occ_statut_biologique text,
    preuve_existante text, preuve_numerique text, preuve_non_numerique text,
    obs_contexte text, obs_description text, occ_methode_determination text
) ON TRUE
;


-- On donne les droits de sélection et de modification sur cette vue
GRANT SELECT, UPDATE ON occtax.v_observation_validation_test TO validation_acme;
-- on enlève les droits sur occtax.observation
REVOKE SELECT, INSERT, UPDATE ON occtax.observation FROM validation_acme;

-- ON donne les droits la vue de mise à plat de descriptif_sujet
GRANT SELECT ON occtax.v_descriptif_sujet_test TO validation_acme;

-- donner le droit de SELECT, INSERT et d'UPDATE sur la table validation_observation
-- c'est obligatoire mais sans souci pour la sécurité car seulement table avec contenu du standard validation
GRANT SELECT, INSERT, UPDATE ON occtax.validation_observation TO validation_acme;

-- On donne le droite sur les champs de la table occtax.observation
-- Nécessaire à cause du trigger occtax.update_observation_set_validation_fields()
-- ON donne ce qui est strictement nécessaire, pas plus
GRANT
    SELECT (cle_obs, identifiant_permanent, validite_niveau, validite_date_validation),
    UPDATE (validite_niveau, validite_date_validation)
ON occtax.observation TO validation_acme
;

-- Droit en lecture sur les tables nomenclature, validation_procedure, validation_personne
GRANT SELECT ON occtax.nomenclature, occtax.validation_procedure, occtax.validation_personne TO validation_acme;

-- Utilisation de la séquence pour les validation
GRANT USAGE ON validation_observation_id_validation_seq TO validation_acme;

-- Visualisation des données de sig
GRANT USAGE ON SCHEMA sig TO validation_acme;
GRANT SELECT ON ALL TABLES IN SCHEMA sig TO validation_acme;

-- On peut enlever les droits sur des données de sig sensibles
REVOKE ALL PRIVILEGES ON sig.validation_couche_sensible_pour_autre_validateur, sig.validation_couche_sensible_pour_autre_validateur_bis
FROM validation_acme;

-- On ajoute le TRIGGER pour déclencher la fonction qui modifiera la table occtax.validation_observation
CREATE TRIGGER trg_validation_observation_test
INSTEAD OF INSERT OR UPDATE OR DELETE ON occtax.v_observation_validation_test
FOR EACH ROW EXECUTE PROCEDURE occtax.update_observation_validation();


COMMIT;

