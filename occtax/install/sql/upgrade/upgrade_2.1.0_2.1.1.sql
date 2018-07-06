BEGIN;

DELETE FROM occtax.nomenclature WHERE champ IN ('niveau_validation_automatique', 'niveau_validation_manuelle_combine');

ALTER TABLE occtax.lien_observation_identifiant_permanent DROP CONSTRAINT IF EXISTS lien_observation_identifiant__jdd_id_identifiant_origine_id_key;
ALTER TABLE occtax.lien_observation_identifiant_permanent
ADD CONSTRAINT lien_observation_identifiant__jdd_id_identifiant_origine_id_key UNIQUE (jdd_id, identifiant_origine, identifiant_permanent);


COMMIT;
