BEGIN;

-- Supprimer les anciennes contraintes d'unicité sur la table personne (gêne les imports)
ALTER TABLE occtax.personne DROP CONSTRAINT IF EXISTS personne_mail_key;
ALTER TABLE occtax.personne DROP CONSTRAINT IF EXISTS personne_identite_mail_key;

COMMIT;
