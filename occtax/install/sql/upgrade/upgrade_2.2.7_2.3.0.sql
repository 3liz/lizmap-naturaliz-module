BEGIN;

SET search_path TO occtax,public;

INSERT INTO organisme (id_organisme, nom_organisme, commentaire)
VALUES (-1, 'Non défini', 'Organisme non défini. Utiliser pour éviter les soucis de contrainte de clé étrangère avec la table personne. Il faut utiliser l''organisme inconnu ou indépendant à la place')
ON CONFLICT DO NOTHING
;

ALTER TABLE personne ADD COLUMN IF NOT EXISTS id_organisme integer NOT NULL DEFAULT -1;
COMMENT ON COLUMN personne.id_organisme IS 'Identifiant de l''organisme, en lien avec la table observation. On utilise -1 par défaut, qui correspond à un organisme non défini, à remplacer par organisme inconnu ou indépendant.';

ALTER TABLE personne DROP CONSTRAINT IF EXISTS personne_id_organisme_fkey;
ALTER TABLE personne ADD CONSTRAINT personne_id_organisme_fkey
FOREIGN KEY (id_organisme)
REFERENCES organisme(id_organisme) MATCH SIMPLE
ON UPDATE CASCADE
ON DELETE RESTRICT;

ALTER TABLE organisme ADD COLUMN IF NOT EXISTS uuid_national text;
COMMENT ON COLUMN organisme.uuid_national IS 'Identifiant de l''organisme au niveau national (uuid)';

-- Vues
CREATE OR REPLACE VIEW v_observateur AS
SELECT
CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE p.identite END AS identite,
CASE WHEN p.anonymiser IS TRUE THEN '' ELSE p.mail END AS mail,
CASE WHEN p.anonymiser IS TRUE OR lower(p.identite) = lower(nom_organisme) THEN NULL ELSE Coalesce(nom_organisme, 'INCONNU') END AS organisme,
op.id_personne, op.cle_obs, p.prenom, p.nom, p.anonymiser
FROM observation_personne op
INNER JOIN personne p ON p.id_personne = op.id_personne AND op.role_personne = 'Obs'
INNER JOIN organisme o ON o.id_organisme = p.id_organisme
;

CREATE OR REPLACE VIEW v_validateur AS
SELECT CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE p.identite END AS identite,
CASE WHEN p.anonymiser IS TRUE THEN '' ELSE p.mail END AS mail,
CASE WHEN p.anonymiser IS TRUE OR lower(p.identite) = lower(nom_organisme) THEN NULL ELSE Coalesce(nom_organisme, 'INCONNU') END AS organisme,
op.id_personne, op.cle_obs, p.prenom, p.nom, p.anonymiser
FROM observation_personne op
INNER JOIN personne p ON p.id_personne = op.id_personne AND op.role_personne = 'Val'
INNER JOIN organisme o ON o.id_organisme = p.id_organisme
;

CREATE OR REPLACE VIEW v_determinateur AS
SELECT CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE p.identite END AS identite,
CASE WHEN p.anonymiser IS TRUE THEN '' ELSE p.mail END AS mail,
CASE WHEN p.anonymiser IS TRUE OR lower(p.identite) = lower(nom_organisme) THEN NULL ELSE Coalesce(nom_organisme, 'INCONNU') END AS organisme,
op.id_personne, op.cle_obs, p.prenom, p.nom, p.anonymiser
FROM observation_personne op
INNER JOIN personne p ON p.id_personne = op.id_personne AND op.role_personne = 'Det'
INNER JOIN organisme o ON o.id_organisme = p.id_organisme
;

DROP INDEX IF EXISTS personne_organisme_lower_idx;
CREATE INDEX IF NOT EXISTS organisme_nom_organisme_lower_idx ON occtax.organisme (lower(nom_organisme));
CREATE INDEX IF NOT EXISTS personne_id_organisme_idx ON personne (id_organisme);

REFRESH MATERIALIZED VIEW occtax.vm_observation;

COMMIT;