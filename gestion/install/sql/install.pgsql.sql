CREATE SCHEMA IF NOT EXISTS gestion;

SET search_path TO gestion,occtax,public,pg_catalog;

-- Nomenclature
CREATE TABLE g_nomenclature (
    champ text,
    code text,
    valeur text,
    description text,
    g_order integer
);

ALTER TABLE g_nomenclature ADD PRIMARY KEY (champ, code);

COMMENT ON TABLE g_nomenclature IS 'Stockage de la t_nomenclature pour les champs des tables qui ont des listes de valeurs prédéfinies.';
COMMENT ON COLUMN g_nomenclature.champ IS 'Description de la valeur';
COMMENT ON COLUMN g_nomenclature.code IS 'Code associé à une valeur';
COMMENT ON COLUMN g_nomenclature.valeur IS 'Libellé court. Joue le rôle de valeur';
COMMENT ON COLUMN g_nomenclature.description IS 'Libellé court. Joue le rôle de valeur';
COMMENT ON COLUMN g_nomenclature.g_order IS 'Ordre (optionnel)';

CREATE INDEX ON g_nomenclature (champ, code);


-- Table demande
CREATE TABLE demande (
    id serial PRIMARY KEY,
    usr_login character varying(50),
    id_acteur integer NOT NULL,
    id_organisme integer NOT NULL,
    motif text NOT NULL,
    motif_anonyme BOOLEAN NOT NULL DEFAULT FALSE,
    type_demande text NOT NULL,
    date_demande date NOT NULL,
    commentaire text,
    statut text DEFAULT 'A traiter',
    detail_decision text,
    date_validite_min date NOT NULL,
    date_validite_max date NOT NULL,
    cd_ref bigint[],
    group1_inpn text[],
    group2_inpn text[],
    date_creation date DEFAULT now(),
    libelle_geom text,
    validite_niveau text[] NOT NULL DEFAULT ARRAY['1', '2', '3', '4', '5']::text[],
    critere_additionnel text

);
SELECT AddGeometryColumn('demande', 'geom', {$SRID}, 'MULTIPOLYGON', 2);

ALTER TABLE demande ADD CONSTRAINT demande_user_login_fk
FOREIGN KEY (usr_login) REFERENCES jlx_user (usr_login)
ON DELETE RESTRICT;

ALTER TABLE demande ADD CONSTRAINT demande_id_organisme_fk
FOREIGN KEY (id_organisme) REFERENCES occtax."organisme" (id_organisme)
ON DELETE RESTRICT;

ALTER TABLE gestion.demande ADD CONSTRAINT demande_type_demande_valide
CHECK ( type_demande IN ('EI','MR','GM','SC','PS','AP','AT','CO','AU') );

ALTER TABLE gestion.demande ADD CONSTRAINT demande_statut_valide
CHECK ( statut IN ('A traiter', 'Acceptée', 'Refusée') );

COMMENT ON TABLE demande IS 'Liste des demandes d''acccès à l''application. Cette table permet de restreindre les accès aux données, par date, taxon, etc.';
COMMENT ON COLUMN demande.id IS 'Identifiant auto de la demande (clé primaire)';
COMMENT ON COLUMN demande.usr_login IS 'Login de l''utilisateur qui fait la demande, pour lequel activer une restriction. On peut avoir plusieurs lignes qui référencent le usr_login. Ce champ peut être vide quand on a pas encore validé la demande (et si on ne la valide jamais). Clé étrangère vers publi.jlx_user';
COMMENT ON COLUMN demande.id_organisme IS 'Identifiant de l''organisme ayant émis la demande. Clé étrangère vers table organisme';
COMMENT ON COLUMN demande.id_acteur IS 'Identifiant de l''acteur ayant émis la demande. Clé étrangère vers table acteur';
COMMENT ON COLUMN demande.motif IS 'Motif de la demande d''accès aux données fourni par le demandeur';
COMMENT ON COLUMN demande.motif_anonyme IS 'Indique si le motif de la demande doit être anonymisé temporairement. Pour les études d''impact, la charte régionale du SINP peut permettre au demandeur de solliciter une anonymisation du motif de sa demande dans la diffusion grand public. L''anonymisation est levée au plus tard au moment de l''ouverture de la procédure de participation du public.';
COMMENT ON COLUMN demande.type_demande IS 'Type de demande selon la typologie de la charte du SINP (exemple : mission régalienne, publication scientifique, etc.)';
COMMENT ON COLUMN demande.date_demande IS 'Date d''émission de la demande (découplée de la date de création, qui est elle renseignée automatiquement';

COMMENT ON COLUMN demande.commentaire IS 'Remarques générales sur la demande.';
COMMENT ON COLUMN demande.date_validite_min IS 'Date minimale de validité de la demande. Les accès sont bloqués si le demandeur consulte l''application avant cette date, pour cette demande.';
COMMENT ON COLUMN demande.date_validite_max IS 'Date maximale de validité de la demande. Les accès sont bloqués si le demandeur consulte l''application après cette date, pour cette demande.';
COMMENT ON COLUMN demande.cd_ref IS 'Tableau des identifiants cd_ref des taxons pour lesquels restreindre l''accès aux données';
COMMENT ON COLUMN demande.group1_inpn IS 'Noms des groupes INPN de type 1. Clé étrangère vers table taxon.t_group_categorie.groupe_nom';
COMMENT ON COLUMN demande.group2_inpn IS 'Noms des groupes INPN de type 2. Clé étrangère vers table taxon.t_group_categorie.groupe_nom';
COMMENT ON COLUMN demande.date_creation IS 'Date de création de la ligne dans la table (automatique si aucune valeur passée)';
COMMENT ON COLUMN demande.libelle_geom IS 'Description littérale de la zone géographique sur laquelle porte la demande';
COMMENT ON COLUMN demande.validite_niveau IS 'Liste de niveaux de validité accessible à la personne, sous la forme d''un tableau.';
COMMENT ON COLUMN demande.geom IS 'Géométrie dans laquelle restreindre les observations consultables. On fait une intersection entre les observation et cette géométrie.';
COMMENT ON COLUMN gestion.demande.statut IS 'Etat d''avancement de la demande d''accès aux données : A traiter, Acceptée ou Refusée';
COMMENT ON COLUMN gestion.demande.detail_decision IS 'Détail de la décision pour cette demande';
COMMENT ON COLUMN gestion.demande.critere_additionnel IS 'Critère additionnel de filtrage pour la demande, au format SQL.';

-- table acteur
CREATE TABLE acteur(
    id_acteur serial PRIMARY KEY,
    nom text NOT NULL,
    prenom text NOT NULL,
    civilite text NOT NULL,
    courriel text,
    tel_1 text,
    tel_2 text,
    fonction text,
    id_organisme integer NOT NULL,
    remarque text,
    bulletin_information boolean default TRUE,
    reunion_sinp boolean default FALSE,
    service TEXT,
    date_maj timestamp without time zone DEFAULT (now())::timestamp without time zone
);
ALTER TABLE acteur ADD CONSTRAINT acteur_id_organisme_fkey
FOREIGN KEY (id_organisme)
REFERENCES occtax.organisme(id_organisme) MATCH SIMPLE
ON UPDATE RESTRICT
ON DELETE RESTRICT
;

ALTER TABLE demande ADD CONSTRAINT demande_id_acteur_fk
FOREIGN KEY (id_acteur) REFERENCES "acteur" (id_acteur)
ON DELETE RESTRICT;

ALTER TABLE acteur ADD UNIQUE (nom, prenom, id_organisme);

COMMENT ON TABLE acteur IS 'Liste les acteurs liés à l''application. Cette table sert à stocker les personnes ressource: responsables des imports de données, référents des jeux de données, etc.';
COMMENT ON COLUMN acteur.id_acteur IS 'Identifiant de l''acteur (entier auto-incrémenté)';
COMMENT ON COLUMN acteur.nom IS 'Nom de l''acteur';
COMMENT ON COLUMN acteur.prenom IS 'Prénom de l''acteur';
COMMENT ON COLUMN acteur.civilite IS 'Civilité de l''acteur';
COMMENT ON COLUMN acteur.courriel IS 'Courriel de l''acteur';
COMMENT ON COLUMN acteur.tel_1 IS 'Numéro de téléphone principal de l''acteur';
COMMENT ON COLUMN acteur.tel_2 IS 'Numéro de téléphone secondaire de l''acteur';
COMMENT ON COLUMN acteur.fonction IS 'Fonction de l''acteur (champ libre)';
COMMENT ON COLUMN acteur.id_organisme IS 'Identifiant de l''organisme de l''acteur (clé étrangère vers table organisme)';
COMMENT ON COLUMN acteur.remarque IS 'Remarque sur l''acteur (texte libre)';
COMMENT ON COLUMN acteur.bulletin_information IS 'Indique si l''acteur souhaite recevoir le bulletin d''information par courriel.';
COMMENT ON COLUMN acteur.reunion_sinp IS 'Indique si l''acteur participe aux réunion du SINP local.';
COMMENT ON COLUMN acteur.service IS 'Service ou direction de rattachement au sein de l''organisme';
COMMENT ON COLUMN acteur.date_maj IS 'Date à laquelle l''enregistrement a été modifié pour la dernière fois (automatiquement renseigné)' ;

CREATE TRIGGER tr_date_maj
  BEFORE UPDATE
  ON gestion.acteur
  FOR EACH ROW
  EXECUTE PROCEDURE occtax.maj_date();

-- Ajout de champs dans la table occtax.jdd_import
ALTER TABLE occtax.jdd_import
ADD COLUMN IF NOT EXISTS acteur_referent integer not null;
COMMENT ON COLUMN jdd_import.acteur_referent IS 'Acteur référent (celui qui est responsable des données, par exemple dans son pôle thématique). En lien avec la table gestion.acteur';

ALTER TABLE occtax.jdd_import
ADD COLUMN IF NOT EXISTS acteur_importateur integer not null;
COMMENT ON COLUMN jdd_import.acteur_importateur IS 'Acteur qui a réalisé l''import des données dans la base. En lien avec la table acteur.';

ALTER TABLE occtax.jdd_import ADD CONSTRAINT jdd_import_acteur_referent_fkey
FOREIGN KEY (acteur_referent)
REFERENCES gestion.acteur(id_acteur) MATCH SIMPLE
ON UPDATE CASCADE
ON DELETE RESTRICT
;

ALTER TABLE occtax.jdd_import ADD CONSTRAINT jdd_import_acteur_importateur_fkey
FOREIGN KEY (acteur_importateur)
REFERENCES gestion.acteur(id_acteur) MATCH SIMPLE
ON UPDATE CASCADE
ON DELETE RESTRICT
;


-- gestion des adhérents
CREATE TABLE gestion.adherent
(
  id_adherent serial NOT NULL PRIMARY KEY, -- Identifiant autogénéré de l'adhérent
  id_organisme integer, -- Identifiant de la structure de l'adhérent
  id_acteur integer, -- Identifiant du contact de référence pour cet adhérent
  date_demande date, -- Date du courrier de demande d'adhésion
  date_adhesion date, -- Date du courrier de notification de l'adhésion au SINP
  statut text, -- Statut d'adhésion (pré-adhérent ou adhérent)
  date_envoi_donnees_historiques date, -- Date fixée pour la fourniture initiale des données et métadonnées au SINP
  date_envoi_annuel text, -- Date fixée pour la fourniture annuelle des nouvelles données et métadonnées au SINP
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
)
WITH (
  OIDS=FALSE
);


COMMENT ON TABLE gestion.adherent
  IS 'Table listant les structures ou personnes physiques ayant fait une demande d''adhésion à la charte du SINP 974, et le statut de leur adhésion.';

COMMENT ON COLUMN gestion.adherent.id_adherent IS 'Identifiant autogénéré de l''adhérent';
COMMENT ON COLUMN gestion.adherent.id_organisme IS 'Identifiant de la structure de l''adhérent';
COMMENT ON COLUMN gestion.adherent.id_acteur IS 'Identifiant du contact de référence pour cet adhérent';
COMMENT ON COLUMN gestion.adherent.date_demande IS 'Date du courrier de demande d''adhésion';
COMMENT ON COLUMN gestion.adherent.date_adhesion IS 'Date du courrier de notification de l''adhésion au SINP';
COMMENT ON COLUMN gestion.adherent.statut IS 'Statut d''adhésion (pré-adhérent ou adhérent)';
COMMENT ON COLUMN gestion.adherent.date_envoi_donnees_historiques IS 'Date fixée pour la fourniture initiale des données et métadonnées au SINP';
COMMENT ON COLUMN gestion.adherent.date_envoi_annuel IS 'Date fixée pour la fourniture annuelle des nouvelles données et métadonnées au SINP. Au format texte, par ex: 15 décembre';
COMMENT ON COLUMN gestion.adherent.anonymisation_personnes IS 'Indique si le nom des personnes doit être anonymisé pour la diffusion des données';
COMMENT ON COLUMN gestion.adherent.diffusion_grand_public IS 'Indique les modalités de diffusion au grand public souhaitées par le producteur (doit permettre de renseigner le champ observation.diffusion_niveau_precision)';
COMMENT ON COLUMN gestion.adherent.remarque IS 'Remarque sur l''avancement de l''adhésion';


-- echange_inpn
CREATE TABLE gestion.echange_inpn
(
    id_echange serial NOT NULL PRIMARY KEY,
    date date,
    type text,
    description text,
    interlocuteur text,
    nb_donnees integer,
    commentaire text,
    liste_identifiant_permanent TEXT[]
)
;

COMMENT ON TABLE gestion.echange_inpn IS 'Table destinée à stocker les informations relatives aux échanges de données avec la plate-forme nationale SINP';

COMMENT ON COLUMN gestion.echange_inpn.id_echange IS 'Identifiant unique auto-incrémenté';
COMMENT ON COLUMN gestion.echange_inpn.date IS 'Date à laquelle l''échange a lieu (date du courriel de transmission)';
COMMENT ON COLUMN gestion.echange_inpn.type IS 'Type d''échange (export depuis Borbonica ou import dans Borbonica)';
COMMENT ON COLUMN gestion.echange_inpn.description IS 'Description littérale de l''échange';
COMMENT ON COLUMN gestion.echange_inpn.interlocuteur IS 'Coordonnées de l''interlorcuteur qui a envoyé les données (import) ou à qui elles sont destinées (export)';
COMMENT ON COLUMN gestion.echange_inpn.nb_donnees IS 'Nombre de données (observations) concernées par l''échange';
COMMENT ON COLUMN gestion.echange_inpn.commentaire IS 'Commentaire libre sur l''échange';
COMMENT ON COLUMN gestion.echange_inpn.liste_identifiant_permanent IS 'Liste des identifiants permanents des observations transmises lors de l''échange de données. Ce champ est destiné à faciliter la traçabilité des données, afin notamment de ne pas exporter deux fois les mêmes données et de pouvoir transmettre à nouveau des observations qui auraient été modifiées (notamment validées) depuis le dernier échange.';

ALTER TABLE gestion.echange_inpn ADD CONSTRAINT echange_inpn_type
CHECK ( type IN ('Import', 'Export') );


-- INDEXES
CREATE INDEX ON demande (usr_login);
CREATE INDEX ON demande (id_acteur);



