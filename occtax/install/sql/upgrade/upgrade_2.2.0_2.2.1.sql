BEGIN;

SET search_path TO occtax,public;

-- View to help query observateurs, determinateurs, validateurs
CREATE OR REPLACE VIEW v_observateur AS
SELECT
CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE p.identite END AS identite,
CASE WHEN p.anonymiser IS TRUE THEN '' ELSE p.mail END AS mail,
CASE WHEN p.anonymiser IS TRUE THEN 'Inconnu' ELSE Coalesce(p.organisme, 'Inconnu') END AS organisme,
op.id_personne, op.cle_obs, p.prenom, p.nom, p.anonymiser
FROM observation_personne op
INNER JOIN personne p ON p.id_personne = op.id_personne AND op.role_personne = 'Obs'
;

CREATE OR REPLACE VIEW v_validateur AS
SELECT CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE p.identite END AS identite,
CASE WHEN p.anonymiser IS TRUE THEN '' ELSE p.mail END AS mail,
CASE WHEN p.anonymiser IS TRUE THEN 'Inconnu' ELSE Coalesce(p.organisme, 'Inconnu') END AS organisme,
op.id_personne, op.cle_obs, p.prenom, p.nom, p.anonymiser
FROM observation_personne op
INNER JOIN personne p ON p.id_personne = op.id_personne AND op.role_personne = 'Val'
;

CREATE OR REPLACE VIEW v_determinateur AS
SELECT CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE p.identite END AS identite,
CASE WHEN p.anonymiser IS TRUE THEN '' ELSE p.mail END AS mail,
CASE WHEN p.anonymiser IS TRUE THEN 'Inconnu' ELSE Coalesce(p.organisme, 'Inconnu') END AS organisme,
op.id_personne, op.cle_obs, p.prenom, p.nom, p.anonymiser
FROM observation_personne op
INNER JOIN personne p ON p.id_personne = op.id_personne AND op.role_personne = 'Det'
;

COMMIT;
