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
    usr_login character varying(50) NOT NULL,
    id_organisme integer NOT NULL,
    motif text NOT NULL,
    type_demande text NOT NULL,
    date_demande date NOT NULL,
    commentaire text,
    date_validite_min date NOT NULL,
    date_validite_max date NOT NULL,
    cd_ref bigint[],
    group1_inpn text[],
    group2_inpn text[],
    date_creation date DEFAULT now(),
    libelle_geom text NOT NULL
);
SELECT AddGeometryColumn('demande', 'geom', {$SRID}, 'GEOMETRY', 2);
ALTER TABLE demande ALTER COLUMN geom SET NOT NULL;

ALTER TABLE demande ADD CONSTRAINT demande_user_login_fk
FOREIGN KEY (usr_login) REFERENCES jlx_user (usr_login)
ON DELETE RESTRICT;
ALTER TABLE demande ADD CONSTRAINT demande_id_organisme_fk
FOREIGN KEY (id_organisme) REFERENCES occtax."organisme" (id_organisme)
ON DELETE RESTRICT;

ALTER TABLE demande ADD CONSTRAINT demande_valide
CHECK ( Coalesce(cd_ref::text, group1_inpn::text, group2_inpn::text, '') != '' )
;

COMMENT ON TABLE demande IS 'Liste des demandes d''acccès à l''application. Cette table permet de restreindre les accès aux données, par date, taxon, etc.';
COMMENT ON COLUMN demande.id IS 'Identifiant auto de la demande (clé primaire)';
COMMENT ON COLUMN demande.usr_login IS 'Login de l''utilisateur qui fait la demande, pour lequel activer une restriction. On peut avoir plusieurs lignes pour la demande. Clé étrangère vers publi.jlx_user';
COMMENT ON COLUMN demande.id_organisme IS 'Identifiant de l''organisme ayant émis la demande. Clé étrangère vers table organisme';
COMMENT ON COLUMN demande.motif IS 'Motif de la demande d''accès aux données fourni par le demandeur';
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
COMMENT ON COLUMN demande.geom IS 'Géométrie dans laquelle restreindre les observations consultables. On fait une intersection entre les observation et cette géométrie.';


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
    usr_login text,
    remarque text,
    bulletin_information boolean default FALSE,
    reunion_sinp boolean default FALSE
);
ALTER TABLE acteur ADD CONSTRAINT acteur_id_organisme_fkey
FOREIGN KEY (id_organisme)
REFERENCES gestion.organisme(id_organisme) MATCH SIMPLE
ON UPDATE RESTRICT
ON DELETE RESTRICT
;

ALTER TABLE acteur ADD CONSTRAINT acteur_usr_login_fkey
FOREIGN KEY (usr_login)
REFERENCES public.jlx_user(usr_login) MATCH SIMPLE
ON UPDATE RESTRICT
ON DELETE RESTRICT
;

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
COMMENT ON COLUMN acteur.usr_login IS 'Login de l''acteur. Ce login doit correspondre au contenu de la table public.jlx_user';
COMMENT ON COLUMN acteur.remarque IS 'Remarque sur l''acteur (texte libre)';
COMMENT ON COLUMN acteur.bulletin_information IS 'Indique si l''acteur souhaite recevoir le bulletin d''information par courriel.';
COMMENT ON COLUMN acteur.reunion_sinp IS 'Indique si l''acteur participe aux réunion du SINP local.';



-- INDEXES
CREATE INDEX ON demande (usr_login);
CREATE INDEX ON acteur (usr_login);
