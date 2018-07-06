BEGIN;

DELETE FROM occtax.nomenclature WHERE champ IN ('niveau_validation_automatique', 'niveau_validation_manuelle_combine');

COMMIT;
