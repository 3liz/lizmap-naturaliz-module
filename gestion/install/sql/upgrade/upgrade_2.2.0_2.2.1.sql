BEGIN;

ALTER TABLE gestion.demande ADD COLUMN critere_additionnel text;
COMMENT ON COLUMN gestion.demande.critere_additionnel IS 'Critère additionnel de filtrage pour la demande, au format SQL.';


COMMIT;
