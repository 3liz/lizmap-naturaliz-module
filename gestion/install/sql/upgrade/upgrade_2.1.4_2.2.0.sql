BEGIN;

-- gestion des adhérents
CREATE TABLE IF NOT EXISTS gestion.adherent
(
  id_adherent serial NOT NULL PRIMARY KEY, -- Identifiant autogénéré de l'adhérent
  id_organisme integer, -- Identifiant de la structure de l'adhérent
  id_acteur integer, -- Identifiant du contact de référence pour cet adhérent
  date_demande date, -- Date du courrier de demande d'adhésion
  date_adhesion date, -- Date du courrier de notification de l'adhésion au SINP
  statut text, -- Statut d'adhésion (pré-adhérent ou adhérent)
  date_envoi_donnees_historiques date, -- Date fixée pour la fourniture initiale des données et métadonnées au SINP
  date_envoi_annuel date, -- Date fixée pour la fourniture annuelle des nouvelles données et métadonnées au SINP
  anonymisation_personnes boolean, -- Indique si le nom des personnes doit être anonymisé pour la diffusion des données
  diffusion_grand_public text, -- Indique les modalités de diffusion au grand public souhaitées par le producteur (doit permettre de renseigner le champ observation.diffusion_niveau_precision)
  remarque text, -- Remarque sur l'avancement de l'adhésion
  CONSTRAINT adherent_id_contact_fk FOREIGN KEY (id_acteur)
      REFERENCES gestion.acteur (id_acteur) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT adherent_id_organisme_fk FOREIGN KEY (id_organisme)
      REFERENCES occtax.organisme (id_organisme) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT statut_valide CHECK (statut = ANY (ARRAY['Pré-adhérent'::text, 'Adhérent'::text, 'Adhésion résiliée'::TEXT, 'Adhérent exclu'::TEXT]))
);


COMMENT ON TABLE gestion.adherent IS 'Table listant les structures ou personnes physiques ayant fait une demande d''adhésion à la charte du SINP 974, et le statut de leur adhésion.';

COMMENT ON COLUMN gestion.adherent.id_adherent IS 'Identifiant autogénéré de l''adhérent';
COMMENT ON COLUMN gestion.adherent.id_organisme IS 'Identifiant de la structure de l''adhérent';
COMMENT ON COLUMN gestion.adherent.id_acteur IS 'Identifiant du contact de référence pour cet adhérent';
COMMENT ON COLUMN gestion.adherent.date_demande IS 'Date du courrier de demande d''adhésion';
COMMENT ON COLUMN gestion.adherent.date_adhesion IS 'Date du courrier de notification de l''adhésion au SINP';
COMMENT ON COLUMN gestion.adherent.statut IS 'Statut d''adhésion (pré-adhérent ou adhérent)';
COMMENT ON COLUMN gestion.adherent.date_envoi_donnees_historiques IS 'Date fixée pour la fourniture initiale des données et métadonnées au SINP';
COMMENT ON COLUMN gestion.adherent.date_envoi_annuel IS 'Date fixée pour la fourniture annuelle des nouvelles données et métadonnées au SINP';
COMMENT ON COLUMN gestion.adherent.anonymisation_personnes IS 'Indique si le nom des personnes doit être anonymisé pour la diffusion des données';
COMMENT ON COLUMN gestion.adherent.diffusion_grand_public IS 'Indique les modalités de diffusion au grand public souhaitées par le producteur (doit permettre de renseigner le champ observation.diffusion_niveau_precision)';
COMMENT ON COLUMN gestion.adherent.remarque IS 'Remarque sur l''avancement de l''adhésion';


-- Complément de la table gestion.acteur avec de nouveaux champs
ALTER TABLE gestion.acteur ADD COLUMN IF NOT EXISTS service TEXT ;
ALTER TABLE gestion.acteur ADD COLUMN IF NOT EXISTS date_maj timestamp without time zone DEFAULT (now())::timestamp without time zone ;

COMMENT ON COLUMN gestion.acteur.service IS 'Service ou direction de rattachement au sein de l''organisme';
COMMENT ON COLUMN gestion.acteur.date_maj IS 'Date à laquelle l''enregistrement a été modifié pour la dernière fois (automatiquement renseigné)' ;

DROP TRIGGER IF EXISTS tr_date_maj ON gestion.acteur;
CREATE TRIGGER tr_date_maj
  BEFORE UPDATE
  ON gestion.acteur
  FOR EACH ROW
  EXECUTE PROCEDURE occtax.maj_date();


-- Modification sur demande
ALTER TABLE gestion.demande DROP CONSTRAINT IF EXISTS demande_valide;
ALTER TABLE gestion.demande DROP CONSTRAINT IF EXISTS demande_type_demande_valide;

TRUNCATE gestion.g_nomenclature RESTART IDENTITY;

INSERT INTO gestion.g_nomenclature VALUES ('type_demande', 'EI', 'Étude d''impact', NULL, 1);
INSERT INTO gestion.g_nomenclature VALUES ('type_demande', 'MR', 'Mission régalienne', NULL, 2);
INSERT INTO gestion.g_nomenclature VALUES ('type_demande', 'GM', 'Gestion des milieux naturels', NULL, 3);
INSERT INTO gestion.g_nomenclature VALUES ('type_demande', 'SC', 'Sensibilisation et communication', NULL, 4);
INSERT INTO gestion.g_nomenclature VALUES ('type_demande', 'PS', 'Publication scientifique', NULL, 5);
INSERT INTO gestion.g_nomenclature VALUES ('type_demande', 'AP', 'Accès producteur', NULL, 6);
INSERT INTO gestion.g_nomenclature VALUES ('type_demande', 'AT', 'Accès tête de réseau', NULL, 7);
INSERT INTO gestion.g_nomenclature VALUES ('type_demande', 'CO', 'Conservation', NULL, 8);
INSERT INTO gestion.g_nomenclature VALUES ('type_demande', 'AU', 'Autre', NULL, 9);

ALTER TABLE gestion.demande ADD CONSTRAINT demande_type_demande_valide
CHECK ( type_demande IN ('EI','MR','GM','SC','PS','AP','AT','CO','AU') );

ALTER TABLE gestion.demande ADD COLUMN IF NOT EXISTS motif_anonyme BOOLEAN NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN gestion.demande.motif_anonyme IS 'Indique si le motif de la demande doit être anonymisé temporairement. Pour les études d''impact, la charte régionale du SINP peut permettre au demandeur de solliciter une anonymisation du motif de sa demande dans la diffusion grand public. L''anonymisation est levée au plus tard au moment de l''ouverture de la procédure de participation du public.';

ALTER TABLE gestion.demande DROP CONSTRAINT IF EXISTS demande_statut_valide;
ALTER TABLE gestion.demande ADD COLUMN IF NOT EXISTS statut text DEFAULT 'A traiter';
UPDATE gestion.demande SET statut = 'A traiter';
ALTER TABLE gestion.demande ADD CONSTRAINT demande_statut_valide
CHECK ( statut IN ('A traiter', 'Acceptée', 'Refusée') );
COMMENT ON COLUMN gestion.demande.statut IS 'Etat d''avancement de la demande d''accès aux données : A traiter, Acceptée ou Refusée';

ALTER TABLE gestion.demande ADD COLUMN IF NOT EXISTS detail_decision text;
COMMENT ON COLUMN gestion.demande.detail_decision IS 'Détail de la décision pour cette demande';

COMMIT;
