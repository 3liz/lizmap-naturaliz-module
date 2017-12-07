BEGIN;

-- EXEMPLE avec organisme de validation ACME et utilisateur John DOE

SET search_path TO occtax,public;

-- DROP ROLE validation_acme;
CREATE ROLE validation_acme LOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
ALTER ROLE validation_acme WITH PASSWORD 'acme';
GRANT USAGE ON SCHEMA occtax TO validation_acme;

-- créer un nouvel utilisateur et le mettre dans le groupe
CREATE ROLE john_doe_acme LOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
ALTER ROLE john_doe_acme WITH PASSWORD 'acme';
-- on met cet utilisateur dans le groupe validation_acme
GRANT validation_acme TO john_doe_acme;

-- ajout dans validation_personne
INSERT INTO occtax.personne (identite, nom, prenom, mail, organisme)
VALUES ('DOE John (ACME)', 'DOE', 'John', 'john.doe@acme.acme', 'ACME')
ON CONFLICT DO NOTHING
;
INSERT INTO validation_personne
(id_personne, role_postgresql, role_postgresql_groupe)
VALUES (
    (SELECT id_personne FROM personne WHERE nom = 'DOE' AND prenom = 'John' AND mail = 'john.doe@acme.acme' ),
    'john_doe_acme',
    'validation_acme'
);



-- On ajoute une procédure de validation si elle n'existe pas déjà !
DELETE FROM occtax.validation_procedure;
INSERT INTO occtax.validation_procedure (proc_code, proc_ref, "procedure", proc_vers)
VALUES ('test', '1.0beta', 'Procédure de validation de test', '1.0beta');


-- On crée une vue qui filtre les données comme on le souhaite
-- dans cet exemple, on a filtré sur le group2_inpn. On pourrait très bien filtrer sur d'autres critères
DROP VIEW IF EXISTS occtax.v_observation_validation_acme;
CREATE VIEW occtax.v_observation_validation_acme AS
SELECT *
FROM v_observation_validation o
WHERE TRUE
AND group2_inpn = 'Oiseaux';


-- On donne les droits de sélection et de modification sur cette vue
GRANT SELECT, UPDATE ON occtax.v_observation_validation_acme TO validation_acme;
-- on enlève les droits sur occtax.observation
REVOKE SELECT, INSERT, UPDATE ON occtax.observation FROM validation_acme;
-- donner le droit de SELECT, INSERT et d'UPDATE sur la table validation_observation
GRANT SELECT, INSERT, UPDATE ON occtax.validation_observation TO validation_acme;
-- Droit en lecture sur les tables nomenclature, validation_procedure, validation_personne
GRANT SELECT ON occtax.nomenclature, occtax.validation_procedure, occtax.validation_personne TO validation_acme;
-- Utilisation de la séquence pour les validation
GRANT USAGE ON validation_observation_id_validation_seq TO validation_acme;
-- Visualisation des données de sig
GRANT SELECT ON ALL TABLES IN SCHEMA sig TO validation_acme;

-- On ajoute le TRIGGER pour déclencher la fonction qui modifiera la table occtax.validation_observation
CREATE TRIGGER trg_validation_observation_acme
INSTEAD OF INSERT OR UPDATE OR DELETE ON occtax.v_observation_validation_acme
FOR EACH ROW EXECUTE PROCEDURE occtax.update_observation_validation();


COMMIT;
