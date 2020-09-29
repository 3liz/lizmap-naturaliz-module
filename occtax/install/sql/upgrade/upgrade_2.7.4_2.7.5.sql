ALTER TABLE gestion.acteur ADD COLUMN IF NOT EXISTS en_poste boolean DEFAULT True;
COMMENT ON COLUMN gestion.acteur.en_poste IS 'Indique si la personne est actuellement en poste sur l''organisme qui lui est associé dans l''enregistrement. Ce champ est particulièrement utile pour des personnes ayant occupé différents postes à La Réunion. Il permet de garder en mémoire les lignes le concernant mais de ne pas les prendre en compte pour la communication SINP.';


CREATE TABLE IF NOT EXISTS occtax.cadre (
    cadre_id text NOT NULL PRIMARY KEY,
    cadre_uuid text NOT NULL,
    libelle text NOT NULL,
    description text,
    ayants_droit jsonb,
    date_lancement date,
    date_cloture date
);
COMMENT ON TABLE occtax.cadre IS 'Recense les cadres d''acquisition tels que renseignés dans l''application nationale https://inpn.mnhn.fr/mtd/. Un cadre d''acquisition regroupe de 1 à n jeux de données. On cherchera la cohérence dans le remplissage par rapport à ce qui est renseigné en ligne.';
COMMENT ON COLUMN occtax.cadre.cadre_id IS 'Identifiant unique du cadre d''acquisition attribué par la plate-forme nationale INPN (du type ''2393'').';
COMMENT ON COLUMN occtax.cadre.cadre_uuid IS 'Identifiant unique du cadre d''acquisition attribué par la plate-forme nationale INPN (au format UUID).';
COMMENT ON COLUMN occtax.cadre.libelle IS 'Nom complet du cadre d''acquisition';
COMMENT ON COLUMN occtax.cadre.description IS 'Description du cadre d''acquisition';
COMMENT ON COLUMN occtax.cadre.ayants_droit IS 'Liste et rôle des structures ayant des droits sur le jeu de données, et rôle concerné (ex : financeur, maître d''oeuvre, maître d''ouvrage, fournisseur...). Stocker les structures via leur id_organisme';
COMMENT ON COLUMN occtax.cadre.date_lancement IS 'Date de lancement du cadre d''acquisition';
COMMENT ON COLUMN occtax.cadre.date_cloture IS 'Date de clôture du cadre d''acquisition';

DROP INDEX IF EXISTS cadre_cadre_id_idx;
CREATE INDEX cadre_cadre_id_idx ON occtax.cadre USING btree (cadre_id);

-- schéma utiles pour l'import de données
CREATE SCHEMA IF NOT EXISTS fdw;
CREATE SCHEMA IF NOT EXISTS divers;
