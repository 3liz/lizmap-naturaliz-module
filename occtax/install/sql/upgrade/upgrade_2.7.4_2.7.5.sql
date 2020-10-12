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

-- Modification de t_groupe_categorie

-- correction des Fougères
UPDATE taxon.t_group_categorie
SET groupe_nom = 'Ptéridophytes'
WHERE groupe_nom='Fougères' AND groupe_type='group2_inpn';

-- Ce qui est au-dessus a été appliqué de dév et prod le 23/06/2020, ce qui est en dessous a été appliqué seulement en dév le 23/06/2020.
-- Complément de la table t_group_categorie (revient à ajouter les deux catégories Echinodermes et Eponges, les autres étant déjà existantes)
INSERT INTO taxon.t_group_categorie(cat_nom, groupe_nom, groupe_type, regne) VALUES
('Mollusques', 'Mollusques', 'group1_inpn', 'Animalia'),
('Échinodermes (Étoiles de mer, oursins,...)', 'Echinodermes', 'group1_inpn', 'Animalia'),
('Éponges', 'Porifères', 'group1_inpn', 'Animalia'),
('Éponges', 'Spongiaires', 'group1_inpn', 'Animalia'),
('Algues', 'Algues', 'group1_inpn', 'Chromista'),
('Mousses', 'Bryophytes', 'group1_inpn', 'Plantae'),
('Bactéries et algues bleues', 'Cyanobactéries', 'group1_inpn', 'Bacteria'),
('Bactéries et algues bleues', 'Protéobactéries', 'group1_inpn', 'Bacteria')

ON CONFLICT DO NOTHING
;

-- Il faut désormais ajouter deux imagettes pour ces deux nouveaux groupes pour qu'ils s'affichent correctement dans le tableau des résultats

-- On supprime les lignes déjà rentrées de niveau group2_inpn correspondant à des nouvelles lignes rentrées de niveau group1_inpn (plus nécessaires puisque group1_inpn prime pour attribuer une catégorie à un taxon)
DELETE FROM taxon.t_group_categorie
WHERE cat_nom IN ('Algues', 'Mollusques', 'Lichens', 'Mousses') AND groupe_type = 'group2_inpn' ; -- le lichen est une erreur, il était rattaché aux mousses

REFRESH MATERIALIZED VIEW occtax.vm_observation;

-- Ajout de champs
ALTER TABLE taxon.t_group_categorie ADD COLUMN libelle_court text;
COMMENT ON COLUMN taxon.t_group_categorie.libelle_court IS 'Libellé court à afficher dans les tableaux de résultat';

UPDATE taxon.t_group_categorie SET libelle_court = (regexp_split_to_array( cat_nom, ' '))[1] WHERE libelle_court IS NULL;
