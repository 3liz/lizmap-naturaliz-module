BEGIN;

-- Fonction trigger mettant à jour le champ date_maj automatiquement
DROP FUNCTION IF EXISTS occtax.maj_date();
CREATE OR REPLACE FUNCTION occtax.maj_date()
RETURNS trigger AS
$BODY$
  BEGIN
    NEW.date_maj=current_TIMESTAMP(0);
    RETURN NEW ;
  END ;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


-- Complément de la table occtax.organisme
ALTER TABLE occtax.organisme ADD COLUMN IF NOT EXISTS sigle TEXT ; -- Sigle de la structure
ALTER TABLE occtax.organisme ADD COLUMN IF NOT EXISTS responsable text ; -- Nom de la personne responsable de la structure, pour les envois postaux officiels
ALTER TABLE occtax.organisme ADD COLUMN IF NOT EXISTS adresse1 TEXT ; -- Adresse de niveau 1
ALTER TABLE occtax.organisme ADD COLUMN IF NOT EXISTS adresse2 TEXT ; -- Adresse de niveau 2
ALTER TABLE occtax.organisme ADD COLUMN IF NOT EXISTS cs TEXT ; -- Courrier spécial
ALTER TABLE occtax.organisme ADD COLUMN IF NOT EXISTS cp integer ; -- Code postal
ALTER TABLE occtax.organisme ADD COLUMN IF NOT EXISTS commune TEXT ; -- Commune
ALTER TABLE occtax.organisme ADD COLUMN IF NOT EXISTS cedex TEXT ; -- CEDEX
ALTER TABLE occtax.organisme ADD COLUMN IF NOT EXISTS csr boolean ; -- Indique si la structure est membre du Comité de suivi régional du SINP
ALTER TABLE occtax.organisme ADD COLUMN IF NOT EXISTS commentaire character varying ; -- Commentaire sur la structure
ALTER TABLE occtax.organisme ADD COLUMN IF NOT EXISTS date_maj timestamp without time zone DEFAULT (now())::timestamp without time zone ; -- Date à laquelle l'enregistrement a été modifé pour la dernière fois (rempli automatiquement)

COMMENT ON COLUMN occtax.organisme.sigle IS 'Sigle de la structure' ;
COMMENT ON COLUMN occtax.organisme.responsable IS 'Nom de la personne responsable de la structure, pour les envois postaux officiels' ;
COMMENT ON COLUMN occtax.organisme.adresse1 IS 'Adresse de niveau 1' ;
COMMENT ON COLUMN occtax.organisme.adresse2 IS 'Adresse de niveau 2' ;
COMMENT ON COLUMN occtax.organisme.cs IS 'Courrier spécial' ;
COMMENT ON COLUMN occtax.organisme.cp IS 'Code postal' ;
COMMENT ON COLUMN occtax.organisme.commune IS 'Commune' ;
COMMENT ON COLUMN occtax.organisme.cedex IS 'CEDEX' ;
COMMENT ON COLUMN occtax.organisme.csr IS 'Indique si la structure est membre du Comité de suivi régional du SINP' ;
COMMENT ON COLUMN occtax.organisme.commentaire IS 'Commentaire sur la structure' ;
COMMENT ON COLUMN occtax.organisme.date_maj IS 'Date à laquelle l''enregistrement a été modifé pour la dernière fois (rempli automatiquement)' ;

-- Fonction trigger mettant à jour le champ automatiquement
CREATE TRIGGER IF NOT EXISTS tr_date_maj
  BEFORE UPDATE
  ON occtax.organisme
  FOR EACH ROW
  EXECUTE PROCEDURE occtax.maj_date();


-- Complément de la table occtax.jdd
ALTER TABLE occtax.jdd ADD COLUMN IF NOT EXISTS ayants_droit jsonb ; -- Liste et rôle des structures ayant des droits sur le jeu de données, et rôle concerné (ex : financeur, maître d'oeuvre...). Stocker les structures via leur id_organisme
COMMENT ON COLUMN occtax.jdd.ayants_droit IS 'Liste et rôle des structures ayant des droits sur le jeu de données, et rôle concerné (ex : financeur, maître d''oeuvre...). Stocker les structures via leur id_organisme';


-- Ajout d'un champ ordre dans la table de nomenclature
ALTER TABLE occtax.nomenclature ADD COLUMN IF NOT EXISTS IF NOT EXISTS ordre smallint DEFAULT 0;
COMMENT ON COLUMN occtax.nomenclature.ordre IS 'Ordre d''apparition souhaité, utilisé par exemple dans les listes déroulantes du formulaire de recherche.';

UPDATE occtax.nomenclature SET ordre = 1 WHERE champ ='validite_niveau' AND code = '1';
UPDATE occtax.nomenclature SET ordre = 2 WHERE champ ='validite_niveau' AND code = '2';
UPDATE occtax.nomenclature SET ordre = 3 WHERE champ ='validite_niveau' AND code = '3';
UPDATE occtax.nomenclature SET ordre = 4 WHERE champ ='validite_niveau' AND code = '4';
UPDATE occtax.nomenclature SET ordre = 5 WHERE champ ='validite_niveau' AND code = '5';
UPDATE occtax.nomenclature SET ordre = 6 WHERE champ ='validite_niveau' AND code = '6';

COMMIT;
