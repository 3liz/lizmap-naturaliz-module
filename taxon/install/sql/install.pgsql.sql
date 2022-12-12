DROP SCHEMA IF EXISTS taxon CASCADE;
CREATE SCHEMA taxon;

-- Création de la table taxon.taxref
DROP TABLE IF EXISTS taxon.taxref CASCADE;
CREATE TABLE taxon.taxref (
  regne text,
  phylum text,
  classe text,
  ordre text,
  famille text,
  sous_famille text,
  tribu text,
  group1_inpn text,
  group2_inpn text,
  cd_nom integer,
  cd_taxsup integer,
  cd_sup integer,
  cd_ref integer,
  rang text,
  lb_nom text,
  lb_auteur text,
  nom_complet text,
  nom_complet_html text,
  nom_valide text,
  nom_vern text,
  nom_vern_eng text,
  habitat character varying(1),
  fr character varying(1),
  gf character varying(1),
  mar character varying(1),
  gua character varying(1),
  sm character varying(1),
  sb character varying(1),
  spm character varying(1),
  may character varying(1),
  epa character varying(1),
  reu character varying(1),
  sa character varying(1),
  ta character varying(1),
  taaf character varying(1),
  pf character varying(1),
  nc character varying(1),
  wf character varying(1),
  cli character varying(1),
  url text
);
ALTER TABLE taxon.taxref ADD PRIMARY KEY (cd_nom);

-- Indexes
CREATE INDEX ON taxon.taxref (regne);
CREATE INDEX ON taxon.taxref (group1_inpn);
CREATE INDEX ON taxon.taxref (group2_inpn);
CREATE INDEX ON taxon.taxref (cd_ref);
CREATE INDEX ON taxon.taxref (cd_nom);
CREATE INDEX ON taxon.taxref (cd_sup); -- pour les requêtes récursives

COMMENT ON TABLE taxon.taxref IS 'Données taxonomiques taxon.taxref';
COMMENT ON COLUMN taxon.taxref.regne IS 'Règne auquel le taxon appartient';
COMMENT ON COLUMN taxon.taxref.phylum IS 'Embranchement auquel le taxon appartient';
COMMENT ON COLUMN taxon.taxref.classe IS 'Classe à laquelle le taxon appartient';
COMMENT ON COLUMN taxon.taxref.ordre IS 'Ordre auquel le taxon appartient';
COMMENT ON COLUMN taxon.taxref.famille IS 'Famille à laquelle le taxon appartient';
COMMENT ON COLUMN taxon.taxref.sous_famille IS 'Sous- famille à laquelle le taxon appartient';
COMMENT ON COLUMN taxon.taxref.tribu IS 'Tribu à laquelle le taxon appartient';
COMMENT ON COLUMN taxon.taxref.group1_inpn IS 'Libellé Groupe 1 INPN pour ce taxon';
COMMENT ON COLUMN taxon.taxref.group2_inpn IS 'Libellé Groupe 1 INPN';
COMMENT ON COLUMN taxon.taxref.cd_nom IS 'Identifiant unique du nom scientifique';
COMMENT ON COLUMN taxon.taxref.cd_taxsup IS 'Identifiant (CD_NOM) du taxon supérieur calculé dans la classification simplifiée ';
COMMENT ON COLUMN taxon.taxref.cd_sup IS 'Identifiant (CD_NOM) du taxon directement supérieur';
COMMENT ON COLUMN taxon.taxref.cd_ref IS 'Identifiant (CD_NOM) du taxon de référence (nom retenu)';
COMMENT ON COLUMN taxon.taxref.rang IS 'Rang taxonomique (lien vers TAXREF_RANG)';
COMMENT ON COLUMN taxon.taxref.lb_nom IS 'Nom scientifique du taxon (sans l’autorité)';
COMMENT ON COLUMN taxon.taxref.lb_auteur IS 'Autorité du taxon (Auteur, année, gestion des parenthèses)';
COMMENT ON COLUMN taxon.taxref.nom_complet IS 'Combinaison des champs pour donner le nom complet (~LB_NOM+" "+LB_AUTEUR)';
COMMENT ON COLUMN taxon.taxref.nom_complet_html IS 'Nom complet formatté en HTML';
COMMENT ON COLUMN taxon.taxref.nom_valide IS 'Le NOM_COMPLET du CD_REF';
COMMENT ON COLUMN taxon.taxref.nom_vern IS 'Noms vernaculaires français';
COMMENT ON COLUMN taxon.taxref.nom_vern_eng IS 'Noms vernaculaires anglais';
COMMENT ON COLUMN taxon.taxref.habitat IS 'Code de l’habitat (clé vers TAXREF_HABITATS)';
COMMENT ON COLUMN taxon.taxref.fr IS 'Statut biogéographique en France métropolitaine (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref.gf IS 'Statut biogéographique en Guyane française (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref.mar IS 'Statut biogéographique à la Martinique (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref.gua IS 'Statut biogéographique à la Guadeloupe (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref.sm IS 'Statut biogéographique à Saint-Martin (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref.sb IS 'Statut biogéographique à Saint-Barthélemy (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref.spm IS 'Statut biogéographique à Saint-Pierre et Miquelon (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref.may IS 'Statut biogéographique à Mayotte (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref.epa IS 'Statut biogéographique aux Îles Éparses (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref.reu IS 'Statut biogéographique à la Réunion (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref.sa IS 'Statut biogéographique aux îles subantarctiques ( (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref.ta IS 'Statut biogéographique en Terre Adélie (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref.taaf IS 'Statut biogéographique aux TAAF (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref.pf IS 'Statut biogéographique en Polynésie française (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref.nc IS 'Statut biogéographique en Nouvelle-Calédonie (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref.wf IS 'Statut biogéographique à Wallis et Futuna (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref.cli IS 'Statut biogéographique à Clipperton (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref.url IS 'Permalien INPN = ‘http://inpn.mnhn.fr/espece/cd_nom/’ + CD_NOM';



-- Table pour stocker des informations sur les bdd de taxon locales
CREATE TABLE taxon.taxref_local_source (
  id serial PRIMARY KEY,
  code text UNIQUE NOT NULL,
  titre text NOT NULL,
  description text,
  info_url text NOT NULL,
  taxon_url text NOT NULL
);
COMMENT ON TABLE taxon.taxref_local_source IS 'Stockage des informations sur les sources de données des taxons';
COMMENT ON COLUMN taxon.taxref_local_source.id IS 'Identifiant automatique';
COMMENT ON COLUMN taxon.taxref_local_source.code IS 'Code court de la base de données. Par exemple: CBNM. Doit être unique';
COMMENT ON COLUMN taxon.taxref_local_source.titre IS 'Titre de la base de données. Par exemple: Index de la flore vasculaire de La Réunion';
COMMENT ON COLUMN taxon.taxref_local_source.description IS 'Description de la base de données. Optionnelle';
COMMENT ON COLUMN taxon.taxref_local_source.info_url IS 'URL vers une page décrivant la base de données source. Ex: http://mascarine.cbnm.org/';
COMMENT ON COLUMN taxon.taxref_local_source.taxon_url IS 'URL vers la fiche d''un taxon dans la base de données source.';



-- Table de stockage des taxons locaux non présents dans le TAXREF officiel
DROP TABLE IF EXISTS taxon.taxref_local CASCADE;
CREATE TABLE taxon.taxref_local
(
  regne text, -- Règne auquel le taxon appartient
  phylum text, -- Embranchement auquel le taxon appartient
  classe text, -- Classe à laquelle le taxon appartient
  ordre text, -- Ordre auquel le taxon appartient
  famille text, -- Famille à laquelle le taxon appartient
  sous_famille text,
  tribu text,
  group1_inpn text, -- Libellé Groupe 1 INPN pour ce taxon
  group2_inpn text, -- Libellé Groupe 1 INPN
  cd_nom integer NOT NULL, -- Identifiant unique du nom scientifique
  cd_taxsup integer, -- Identifiant (CD_NOM) du taxon supérieur
  cd_sup integer,
  cd_ref integer NOT NULL, -- Identifiant (CD_NOM) du taxon de référence (nom retenu)
  rang text, -- Rang taxonomique (lien vers TAXREF_RANG)
  lb_nom text, -- Nom scientifique du taxon (sans l’autorité)
  lb_auteur text, -- Autorité du taxon (Auteur, année, gestion des parenthèses)
  nom_complet text, -- Combinaison des champs pour donner le nom complet (~LB_NOM+" "+LB_AUTEUR)
  nom_complet_html text,
  nom_valide text, -- Le NOM_COMPLET du CD_REF
  nom_vern text, -- Noms vernaculaires français
  nom_vern_eng text, -- Noms vernaculaires anglais
  habitat character varying(1), -- Code de l’habitat (clé vers TAXREF_HABITATS)
  fr character varying(1), -- Statut biogéographique en France métropolitaine (clé vers TAXREF_STATUTS)
  gf character varying(1), -- Statut biogéographique en Guyane française (clé vers TAXREF_STATUTS)
  mar character varying(1), -- Statut biogéographique à la Martinique (clé vers TAXREF_STATUTS)
  gua character varying(1), -- Statut biogéographique à la Guadeloupe (clé vers TAXREF_STATUTS)
  sm character varying(1), -- Statut biogéographique à Saint-Martin (clé vers TAXREF_STATUTS)
  sb character varying(1), -- Statut biogéographique à Saint-Barthélemy (clé vers TAXREF_STATUTS)
  spm character varying(1), -- Statut biogéographique à Saint-Pierre et Miquelon (clé vers TAXREF_STATUTS)
  may character varying(1), -- Statut biogéographique à Mayotte (clé vers TAXREF_STATUTS)
  epa character varying(1), -- Statut biogéographique aux Îles Éparses (clé vers TAXREF_STATUTS)
  reu character varying(1), -- Statut biogéographique à la Réunion (clé vers TAXREF_STATUTS)
  sa character varying(1), -- Statut biogéographique aux îles subantarctiques (clé vers TAXREF_STATUTS)
  ta character varying(1), -- Statut biogéographique en Terre Adélie (clé vers TAXREF_STATUTS)
  taaf character varying(1), -- Statut biogéographique aux TAAF (clé vers TAXREF_STATUTS)
  pf character varying(1), -- Statut biogéographique en Polynésie française (clé vers TAXREF_STATUTS)
  nc character varying(1), -- Statut biogéographique en Nouvelle-Calédonie (clé vers TAXREF_STATUTS)
  wf character varying(1), -- Statut biogéographique à Wallis et Futuna (clé vers TAXREF_STATUTS)
  cli character varying(1), -- Statut biogéographique à Clipperton (clé vers TAXREF_STATUTS)
  url text, -- Permalien INPN = ‘http://inpn.mnhn.fr/espece/cd_nom/’ + CD_NOM
  cd_nom_valide bigint -- Cd_nom du taxon valide une fois que le taxon est apparu dans taxon.taxref
  CONSTRAINT taxref_local_cd_nom_valid CHECK ( cd_nom < 0 )
)
WITH (
  OIDS=FALSE
);

ALTER TABLE taxon.taxref_local ADD PRIMARY KEY(cd_nom);
DROP SEQUENCE IF EXISTS taxon.taxref_local_cd_nom_seq;
CREATE SEQUENCE taxon.taxref_local_cd_nom_seq INCREMENT -1 START -1;
ALTER TABLE taxon.taxref_local ALTER COLUMN cd_nom SET DEFAULT nextval('taxon.taxref_local_cd_nom_seq');
ALTER TABLE taxon.taxref_local ALTER COLUMN cd_ref SET DEFAULT currval('taxon.taxref_local_cd_nom_seq');

ALTER TABLE taxon.taxref_local ADD CONSTRAINT taxref_local_lb_nom UNIQUE (lb_nom);

COMMENT ON TABLE taxon.taxref_local  IS 'Données taxonomiques qui ne sont pas dans TAXREF. L''identifiant donné est négatif temporaire, jusqu''à la création du taxon dans le TAXREF officiel. La structure de la table est complètement identique à celle de TAXREF pour permettre une UNION entre les 2 tables';
COMMENT ON COLUMN taxon.taxref_local.regne IS 'Règne auquel le taxon appartient';
COMMENT ON COLUMN taxon.taxref_local.phylum IS 'Embranchement auquel le taxon appartient';
COMMENT ON COLUMN taxon.taxref_local.classe IS 'Classe à laquelle le taxon appartient';
COMMENT ON COLUMN taxon.taxref_local.ordre IS 'Ordre auquel le taxon appartient';
COMMENT ON COLUMN taxon.taxref_local.famille IS 'Famille à laquelle le taxon appartient';
COMMENT ON COLUMN taxon.taxref_local.sous_famille IS 'Sous-famille à laquelle le taxon appartient';
COMMENT ON COLUMN taxon.taxref_local.tribu IS 'Tribu à laquelle le taxon appartient';
COMMENT ON COLUMN taxon.taxref_local.group1_inpn IS 'Libellé Groupe 1 INPN pour ce taxon';
COMMENT ON COLUMN taxon.taxref_local.group2_inpn IS 'Libellé Groupe 1 INPN';
COMMENT ON COLUMN taxon.taxref_local.cd_nom IS 'Identifiant unique du nom scientifique';
COMMENT ON COLUMN taxon.taxref_local.cd_taxsup IS 'Identifiant (CD_NOM) du taxon supérieur calculé dans la classification simplifiée ';
COMMENT ON COLUMN taxon.taxref_local.cd_sup IS 'Identifiant (CD_NOM) du taxon directement supérieur';
COMMENT ON COLUMN taxon.taxref_local.cd_ref IS 'Identifiant (CD_NOM) du taxon de référence (nom retenu)';
COMMENT ON COLUMN taxon.taxref_local.rang IS 'Rang taxonomique (lien vers TAXREF_RANG)';
COMMENT ON COLUMN taxon.taxref_local.lb_nom IS 'Nom scientifique du taxon (sans l’autorité)';
COMMENT ON COLUMN taxon.taxref_local.lb_auteur IS 'Autorité du taxon (Auteur, année, gestion des parenthèses)';
COMMENT ON COLUMN taxon.taxref_local.nom_complet IS 'Combinaison des champs pour donner le nom complet (~LB_NOM+" "+LB_AUTEUR)';
COMMENT ON COLUMN taxon.taxref_local.nom_complet_html IS 'Nom complet formatté en HTML';
COMMENT ON COLUMN taxon.taxref_local.nom_valide IS 'Le NOM_COMPLET du CD_REF';
COMMENT ON COLUMN taxon.taxref_local.nom_vern IS 'Noms vernaculaires français';
COMMENT ON COLUMN taxon.taxref_local.nom_vern_eng IS 'Noms vernaculaires anglais';
COMMENT ON COLUMN taxon.taxref_local.habitat IS 'Code de l’habitat (clé vers TAXREF_HABITATS)';
COMMENT ON COLUMN taxon.taxref_local.fr IS 'Statut biogéographique en France métropolitaine (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref_local.gf IS 'Statut biogéographique en Guyane française (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref_local.mar IS 'Statut biogéographique à la Martinique (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref_local.gua IS 'Statut biogéographique à la Guadeloupe (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref_local.sm IS 'Statut biogéographique à Saint-Martin (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref_local.sb IS 'Statut biogéographique à Saint-Barthélemy (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref_local.spm IS 'Statut biogéographique à Saint-Pierre et Miquelon (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref_local.may IS 'Statut biogéographique à Mayotte (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref_local.epa IS 'Statut biogéographique aux Îles Éparses (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref_local.reu IS 'Statut biogéographique à la Réunion (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref_local.sa IS 'Statut biogéographique îles subantarctiques (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref_local.ta IS 'Statut biogéographique en Terre Adélie (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref_local.taaf IS 'Statut biogéographique aux TAAF (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref_local.pf IS 'Statut biogéographique en Polynésie française (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref_local.nc IS 'Statut biogéographique en Nouvelle-Calédonie (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref_local.wf IS 'Statut biogéographique à Wallis et Futuna (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref_local.cli IS 'Statut biogéographique à Clipperton (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxon.taxref_local.url IS 'Permalien INPN = ‘http://inpn.mnhn.fr/espece/cd_nom/’ + CD_NOM';
COMMENT ON COLUMN taxon.taxref_local.cd_nom_valide IS 'cd_nom du taxon valide, à renseigner après import d''un nouveau TAXREF, pour pouvoir modifier ensuite les observations qui faisaient référence au cd_nom négatif provisoire de la ligne. Penser à supprimer la ligne une fois les modifications faites sur les observations';

CREATE INDEX taxref_local_cd_nom_idx ON taxon.taxref_local USING btree (cd_nom);
CREATE INDEX taxref_local_cd_ref_idx ON taxon.taxref_local USING btree  (cd_ref);
CREATE INDEX taxref_local_group1_inpn_idx ON taxon.taxref_local USING btree (group1_inpn);
CREATE INDEX taxref_local_group2_inpn_idx ON taxon.taxref_local USING btree (group2_inpn);
CREATE INDEX taxref_local_regne_idx ON taxon.taxref_local USING btree (regne);
CREATE INDEX taxref_local_cd_sup_idx ON taxon.taxref_local (cd_sup);

CREATE INDEX ON taxon.taxref (habitat);
CREATE INDEX ON taxon.taxref_local (habitat);


-- Colonnes pour stocker les informations spécifiques pour taxon.taxref_local
ALTER TABLE taxon.taxref_local ADD COLUMN local_bdd_code text NOT NULL;
ALTER TABLE taxon.taxref_local ADD COLUMN local_identifiant_origine text NOT NULL;
ALTER TABLE taxon.taxref_local ADD COLUMN local_identifiant_origine_ref text;
COMMENT ON COLUMN taxon.taxref_local.local_bdd_code IS 'Base de données source. Ce champ est une clé étrangère liée à la table taxon.taxref_local_source, vers le champ code';
COMMENT ON COLUMN taxon.taxref_local.local_identifiant_origine IS 'Identifiant du taxon (équivalent cd_nom) dans la base de données d''origine.';
COMMENT ON COLUMN taxon.taxref_local.local_identifiant_origine_ref IS 'Identifiant du taxon de référence (équivalent cd_ref) dans la base de données d''origine.';

ALTER TABLE taxon.taxref_local
ADD CONSTRAINT taxref_local_bdd_code FOREIGN KEY (local_bdd_code)
REFERENCES taxon.taxref_local_source (code) MATCH SIMPLE
ON UPDATE CASCADE ON DELETE RESTRICT
;



-- Ajout d'une vue pour les taxons valides seulement
-- seulement sur les rangs qui correpondent à des espaces
DROP MATERIALIZED VIEW IF EXISTS taxon.taxref_valide CASCADE;
CREATE MATERIALIZED VIEW taxon.taxref_valide AS
WITH taxref_mnhn_et_local AS (
  SELECT regne, phylum, classe, ordre, famille, sous_famille, tribu, group1_inpn, group2_inpn,
  cd_nom, cd_taxsup, cd_ref, rang, lb_nom, lb_auteur, nom_complet,
  nom_complet_html, nom_valide, nom_vern, nom_vern_eng, habitat,
  fr, gf, mar, gua, sm, sb, spm, may, epa, reu, sa, ta, taaf, pf, nc, wf, cli, url
  FROM taxon.taxref
  UNION ALL
  SELECT regne, phylum, classe, ordre, famille, sous_famille, tribu, group1_inpn, group2_inpn,
  cd_nom, cd_taxsup, cd_ref, rang, lb_nom, lb_auteur, nom_complet,
  nom_complet_html, nom_valide, nom_vern, nom_vern_eng, habitat,
  fr, gf, mar, gua, sm, sb, spm, may, epa, reu, sa, ta, taaf, pf, nc, wf, cli, url
  FROM taxon.taxref_local
  WHERE cd_nom_valide IS NULL
)
SELECT
regne, phylum, classe, ordre, famille, sous_famille, tribu, group1_inpn, group2_inpn,
cd_nom, cd_taxsup, cd_ref, rang, lb_nom, lb_auteur, nom_complet,
nom_complet_html, nom_valide, nom_vern, nom_vern_eng, habitat,
fr, gf, mar, gua, sm, sb, spm, may, epa, reu, sa, ta, taaf, pf, nc, wf, cli, url
FROM taxref_mnhn_et_local
WHERE True
AND cd_nom = cd_ref
AND rang IN ({$liste_rangs});

COMMENT ON MATERIALIZED VIEW taxon.taxref_valide IS '
Vue matérialisée pour récupérer uniquement les taxons valides (cd_nom = cd_ref) dans la table taxon.taxref et dans la table taxon.taxref_local.

Elle fait une union entre les 2 tables source et ne conserve que les taxons des rangs: FM, GN, AGES, ES, SSES, NAT, VAR, SVAR, FO, SSFO, RACE, CAR, AB.

Elle doit être rafraîchie dès qu''on réalise un import dans une ou l''autre des tables sources: `REFRESH MATERIALIZED VIEW taxon.taxref_valide;`
';


-- ALTER TABLE taxon.taxref_valide ADD PRIMARY KEY (cd_nom);
CREATE INDEX ON taxon.taxref_valide (group1_inpn);
CREATE INDEX ON taxon.taxref_valide (group2_inpn);
CREATE INDEX ON taxon.taxref_valide (cd_ref);
CREATE INDEX ON taxon.taxref_valide (cd_nom);
CREATE INDEX ON taxon.taxref_valide (habitat);


-- Ajout des capacités de recherche plein texte
DROP TEXT SEARCH CONFIGURATION IF EXISTS french_text_search;
CREATE TEXT SEARCH CONFIGURATION french_text_search (COPY = french);
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
ALTER TEXT SEARCH CONFIGURATION french_text_search ALTER MAPPING FOR hword, hword_part, word, asciihword, asciiword, hword_asciipart WITH unaccent, french_stem;
SET default_text_search_config TO french_text_search;

-- Création de la table de stockage des vecteurs pour la recherche plein texte sur taxon.taxref
DROP MATERIALIZED VIEW IF EXISTS taxon.taxref_fts;
CREATE MATERIALIZED VIEW taxon.taxref_fts AS
WITH taxref_mnhn_et_local AS (
  SELECT cd_nom, cd_ref, nom_valide, nom_vern, nom_complet, group2_inpn, rang, {$colonne_locale} AS loc
  FROM taxon.taxref
  UNION ALL
  SELECT cd_nom, cd_ref, nom_valide, nom_vern, nom_complet, group2_inpn, rang, {$colonne_locale} AS loc
  FROM taxon.taxref_local
  WHERE cd_nom_valide IS NULL
)
-- Noms valides
SELECT cd_nom::bigint, cd_ref::bigint, nom_valide AS val, nom_valide, 6::smallint AS poids,
group2_inpn, to_tsvector( unaccent(coalesce(nom_valide,'')) )::tsvector AS vec, loc
FROM taxref_mnhn_et_local
WHERE cd_nom = cd_ref
AND rang IN ({$liste_rangs})


-- Noms vernaculaires
UNION ALL
SELECT cd_nom::bigint, cd_ref::bigint, nom_vern AS val, nom_valide, 4::smallint AS poids,
group2_inpn, to_tsvector( unaccent(coalesce(nom_vern,'')) )::tsvector AS vec, loc
FROM taxref_mnhn_et_local
WHERE cd_nom = cd_ref AND nom_vern IS NOT NULL AND nom_vern != ''
AND rang IN ({$liste_rangs})


-- Noms synonymes
UNION ALL
SELECT cd_nom::bigint, cd_ref::bigint, nom_complet AS val, nom_valide, 2::smallint,
group2_inpn, to_tsvector( unaccent(coalesce(nom_complet,'')) )::tsvector AS vec, loc
FROM taxref_mnhn_et_local
WHERE cd_nom != cd_ref
AND rang IN ({$liste_rangs})
;


COMMENT ON MATERIALIZED VIEW taxon.taxref_fts IS '
Vue matérialisée pour le stockage des informations de recherche plein texte visible dans naturaliz.

Cette vue se base sur une UNION des taxons, valides ou non, des tables taxon.taxref et taxon.taxref_local. On n''a gardé que les taxons des rangs: FM, GN, AGES, ES, SSES, NAT, VAR, SVAR, FO, SSFO, RACE, CAR, AB

Un champ poids permet de prioriser la recherche dans cet ordre, avec les poids respectifs 6, 4 et 2:
* noms (nom_valide) des taxons valides (cd_nom = cd_ref)
* noms vernaculaires (nom_vern) des taxons valides (cd_nom = cd_ref)
* noms (nom_complet) des taxons synonymes (cd_nom != cd_ref)

Cette vue doit être rafraîchie dès qu''on modifie les données dans les tables taxon.taxref et/ou taxon.taxref_local: `REFRESH MATERIALIZED VIEW taxon.taxref_fts`
';
COMMENT ON COLUMN taxon.taxref_fts.cd_nom IS 'Identifiant du taxon (cd_nom) en lien avec la table taxon.taxref';
COMMENT ON COLUMN taxon.taxref_fts.cd_ref IS 'Identifiant du taxon valide (cd_ref)';
COMMENT ON COLUMN taxon.taxref_fts.val IS 'Valeur à afficher (nom du taxon, group1_inpn, etc.)';
COMMENT ON COLUMN taxon.taxref_fts.nom_valide IS 'Nom valide correspondant';
COMMENT ON COLUMN taxon.taxref_fts.poids IS 'Importance de l objet dans la recherche, fonction du type';
COMMENT ON COLUMN taxon.taxref_fts.group2_inpn IS 'Groupe INPN - utilisé pour afficher des icônes';
COMMENT ON COLUMN taxon.taxref_fts.vec IS 'Vecteur de la recherche plein texte';

-- Ajout de l'index
CREATE INDEX ON taxon.taxref_fts USING gin(vec);
CREATE INDEX ON taxon.taxref_fts (group2_inpn);


-- Ajout de la table taxon.t_complement
DROP TABLE IF EXISTS taxon.t_complement CASCADE;
CREATE TABLE taxon.t_complement
(
  cd_nom_fk integer,
  statut character varying(15),
  rarete character varying(10),
  endemicite character varying(5),
  invasibilite character varying(5),
  menace_nationale character varying(5),
  menace_regionale character varying(5),
  menace_monde character varying(6),
  protection character varying(5),
  det_znieff character varying(15),
  CONSTRAINT t_complement_pkey PRIMARY KEY (cd_nom_fk)
)
WITH (
  OIDS=FALSE
);

COMMENT ON TABLE taxon.t_complement IS 'Stockage des données complémentaires sur les taxons, non présentes dans TAXREF : données locales (endémicité, invasibilité, etc.), déterminants ZNIEFF, menaces... La table contient tous les taxons, y compris les synonymes.';


COMMENT ON COLUMN taxon.t_complement.cd_nom_fk IS 'Identifiant du taxon, lien avec taxon.taxref.cd_nom';
COMMENT ON COLUMN taxon.t_complement.statut IS 'Statut local';
COMMENT ON COLUMN taxon.t_complement.rarete IS 'Rareté locale du taxon';
COMMENT ON COLUMN taxon.t_complement.endemicite IS 'Endémicité locale du taxon';
COMMENT ON COLUMN taxon.t_complement.invasibilite IS 'Invasibilité locale du taxon';
COMMENT ON COLUMN taxon.t_complement.menace_nationale IS 'Menace nationale sur le taxon';
COMMENT ON COLUMN taxon.t_complement.menace_regionale IS 'Menace régionale sur le taxon';
COMMENT ON COLUMN taxon.t_complement.menace_monde IS 'Menace mondiale sur le taxon';
COMMENT ON COLUMN taxon.t_complement.protection IS 'Statut de protection local';
COMMENT ON COLUMN taxon.t_complement.det_znieff IS 'Déterminant ZNIEFF';

CREATE INDEX ON taxon.t_complement (cd_nom_fk);
CREATE INDEX ON taxon.t_complement (det_znieff);
CREATE INDEX ON taxon.t_complement (endemicite);
CREATE INDEX ON taxon.t_complement (invasibilite);
CREATE INDEX ON taxon.t_complement (menace_nationale);
CREATE INDEX ON taxon.t_complement (menace_regionale);
CREATE INDEX ON taxon.t_complement (protection);
CREATE INDEX ON taxon.t_complement (rarete);
CREATE INDEX ON taxon.t_complement (statut);


-- Nomenclature
DROP TABLE IF EXISTS taxon.t_nomenclature CASCADE;
CREATE TABLE taxon.t_nomenclature
(
  champ text NOT NULL, -- Description de la valeur
  code text NOT NULL, -- Code associé à une valeur
  valeur text, -- Libellé court. Joue le rôle de valeur
  description text,
  ordre smallint DEFAULT 0,
  CONSTRAINT t_nomenclature_pkey PRIMARY KEY (champ, code)
)
WITH (
  OIDS=FALSE
);

COMMENT ON TABLE taxon.t_nomenclature IS 'Stockage de la taxon.t_nomenclature pour les champs des tables qui ont des listes de valeurs prédéfinies.';
COMMENT ON COLUMN taxon.t_nomenclature.champ IS 'Description de la valeur';
COMMENT ON COLUMN taxon.t_nomenclature.code IS 'Code associé à une valeur';
COMMENT ON COLUMN taxon.t_nomenclature.valeur IS 'Libellé court. Joue le rôle de valeur';
COMMENT ON COLUMN taxon.t_nomenclature.description IS 'Libellé court. Joue le rôle de valeur';
COMMENT ON COLUMN taxon.t_nomenclature.ordre IS 'Ordre d''apparition souhaité, utilisé par exemple dans les listes déroulantes du formulaire de recherche.';

CREATE INDEX ON taxon.t_nomenclature (champ, code);


-- Table taxon.t_group_categorie : groupes personnalisés pour le filtre des taxons
DROP TABLE IF EXISTS taxon.t_group_categorie CASCADE;
CREATE TABLE taxon.t_group_categorie (
    cat_nom text,
    groupe_nom text,
    groupe_type text,
    regne text,
    libelle_court text,
    CONSTRAINT t_group_categorie_regne_valide CHECK ( regne IN ( 'Plantae', 'Animalia', 'Fungi', 'Chromista', 'Bacteria', 'Protozoa' ) )
);
ALTER TABLE taxon.t_group_categorie ADD PRIMARY KEY (cat_nom, groupe_nom);

COMMENT ON TABLE taxon.t_group_categorie IS 'Liste des catégories de groupes de taxons affichées dans la liste déroulante du filtre de recherche.';
COMMENT ON COLUMN taxon.t_group_categorie.cat_nom IS 'Libellé à afficher pour le groupe';
COMMENT ON COLUMN taxon.t_group_categorie.groupe_nom IS 'Nom du groupe INPN correspondant';
COMMENT ON COLUMN taxon.t_group_categorie.groupe_type IS 'Type de groupe INPN : group1_inpn ou group2_inpn';
COMMENT ON COLUMN taxon.t_group_categorie.regne IS 'Le règne du groupe INPN';
COMMENT ON COLUMN taxon.t_group_categorie.libelle_court IS 'Libellé court à afficher dans les tableaux de résultat';


-- Table de stockage des taxons sensibles
CREATE TABLE taxon.taxon_sensible
(
  cd_nom integer NOT NULL,
  nom_valide text,
  CONSTRAINT taxon_sensible_pkey PRIMARY KEY (cd_nom)
);

COMMENT ON TABLE taxon.taxon_sensible IS 'Liste des taxon sensibles. Les observations concernées par ces taxon ne seront visibles que pour les personnes avec des droits hauts.';

COMMENT ON COLUMN taxon.taxon_sensible.cd_nom IS 'Identifiant du taxon.';
COMMENT ON COLUMN taxon.taxon_sensible.nom_valide IS 'Nom valide du taxon, ajouté pour faciliter la lecture (optionnel)';



-- Vue de consolidation des données TAXREF officielles valides, locales et complémentaires
DROP MATERIALIZED VIEW IF EXISTS taxon.taxref_consolide CASCADE;
CREATE MATERIALIZED VIEW taxon.taxref_consolide AS
SELECT
t.*, c.*
FROM (
        SELECT regne, phylum, classe, ordre, famille, sous_famille, tribu, group1_inpn, group2_inpn, cd_nom, cd_taxsup, cd_ref, rang, lb_nom, lb_auteur, nom_complet, nom_complet_html, nom_valide, nom_vern, nom_vern_eng, habitat, fr, gf, mar, gua, sm, sb, spm, may, epa, reu, sa, ta, taaf, pf, nc, wf, cli, url
        FROM taxon.taxref_valide
) AS t
LEFT JOIN taxon.t_complement AS c ON c.cd_nom_fk = t.cd_nom
;

COMMENT ON MATERIALIZED VIEW taxon.taxref_consolide IS '
Vue matérialisée pour gérer l''association des données du TAXREF (taxref) et des taxons locaux (taxref_local) avec les données complémentaires sur les statuts, la protection, les menaces (t_complement).

Seuls les taxons valides sont présents dans cette table (car elle dépend de la vue matérialisée taxon.taxref_valide )

Elle est principalement utilisée pour récupérer les cd_ref des sous-ensembles de taxons à filtrer lorsqu''on chercher des observations.

C''est une vue matérialisée, c''est-à-dire une vue qui se comporte comme une table, et qu''on doit mettre à jour suite à un import de taxons (dans taxon.taxref ou taxon.taxref_local), ou suite à la mise à jour de taxon.taxref_valide, via `REFRESH MATERIALIZED VIEW taxon.taxref_consolide;`
';
CREATE INDEX ON taxon.taxref_consolide (group1_inpn);
CREATE INDEX ON taxon.taxref_consolide (group2_inpn);
CREATE INDEX ON taxon.taxref_consolide (cd_ref);
CREATE INDEX ON taxon.taxref_consolide (cd_nom);
CREATE INDEX ON taxon.taxref_consolide (famille);


-- Vue qui rassemble tous les taxons de TAXREF et de taxon.taxref local:
-- valides et non valides
-- tous les rangs
-- utilisée pour le filtrage de la fin
-- du fichier de lizmap/lizmap-modules/occtax/classes/occtaxSearchObservation.class.php
DROP MATERIALIZED VIEW IF EXISTS taxon.taxref_consolide_non_filtre;
CREATE MATERIALIZED VIEW taxon.taxref_consolide_non_filtre AS
WITH
taxref_mnhn_et_local AS (
  SELECT
  regne, phylum, classe, ordre, famille, sous_famille, tribu, group1_inpn, group2_inpn,
cd_nom, cd_taxsup, cd_ref, rang, lb_nom, lb_auteur, nom_complet,
nom_complet_html, nom_valide, nom_vern, nom_vern_eng, habitat,
fr, gf, mar, gua, sm, sb, spm, may, epa, reu, sa, ta, taaf, pf, nc, wf, cli, url
  FROM taxon.taxref
  WHERE True
  UNION ALL
  SELECT
  regne, phylum, classe, ordre, famille, sous_famille, tribu, group1_inpn, group2_inpn,
cd_nom, cd_taxsup, cd_ref, rang, lb_nom, lb_auteur, nom_complet,
nom_complet_html, nom_valide, nom_vern, nom_vern_eng, habitat,
fr, gf, mar, gua, sm, sb, spm, may, epa, reu, sa, ta, taaf, pf, nc, wf, cli, url
  FROM taxon.taxref_local
  WHERE True
  AND cd_nom_valide IS NULL
)
SELECT tml.*, c.*
FROM taxref_mnhn_et_local AS tml
LEFT JOIN taxon.t_complement AS c ON c.cd_nom_fk = tml.cd_nom
;

CREATE INDEX ON taxon.taxref_consolide_non_filtre (cd_ref);
CREATE INDEX ON taxon.taxref_consolide_non_filtre (cd_nom);
CREATE INDEX ON taxon.taxref_consolide_non_filtre (regne);
CREATE INDEX ON taxon.taxref_consolide_non_filtre (group1_inpn);
CREATE INDEX ON taxon.taxref_consolide_non_filtre (group2_inpn);
CREATE INDEX ON taxon.taxref_consolide_non_filtre (protection);
CREATE INDEX ON taxon.taxref_consolide_non_filtre (det_znieff);
CREATE INDEX ON taxon.taxref_consolide_non_filtre (endemicite);
CREATE INDEX ON taxon.taxref_consolide_non_filtre (invasibilite);
CREATE INDEX ON taxon.taxref_consolide_non_filtre (menace_nationale);
CREATE INDEX ON taxon.taxref_consolide_non_filtre (menace_regionale);
CREATE INDEX ON taxon.taxref_consolide_non_filtre (protection);
CREATE INDEX ON taxon.taxref_consolide_non_filtre (rarete);
CREATE INDEX ON taxon.taxref_consolide_non_filtre (statut);
CREATE INDEX ON taxon.taxref_consolide_non_filtre (famille);


-- Noms vernaculaires : nouveau depuis TAXREF V11
DROP TABLE IF EXISTS taxon.taxvern CASCADE;
CREATE TABLE taxon.taxvern (
  cd_vern integer PRIMARY KEY,
  cd_nom integer,
  lb_vern text,
  nom_vern_source text,
  langue text,
  iso639_3 text,
  pays text
);
COMMENT ON TABLE taxon.taxvern IS 'Nom vernaculaires. Nouveau depuis TAXREF V11';
CREATE INDEX ON taxon.taxvern (cd_nom);
CREATE INDEX ON taxon.taxvern ("iso639_3");


-- Stockage des médias
DROP TABLE IF EXISTS taxon.medias;
CREATE TABLE IF NOT EXISTS taxon.medias (
    id serial PRIMARY KEY NOT NULL,
    cd_nom bigint NOT NULL,
    cd_ref bigint NOT NULL,
    principal boolean DEFAULT False,
    source text NOT NULL DEFAULT 'inpn',
    id_origine integer,
    url_origine text,
    media_path text,
    titre text,
    auteur text,
    description text,
    licence text
)
;

ALTER TABLE taxon.medias ADD CONSTRAINT taxon_media_unique UNIQUE (cd_ref, source, id_origine, media_path);

COMMENT ON TABLE taxon.medias
IS 'Stockage des informations sur les médias liés aux taxons. Plusieurs sources possibles: inpn ou local.
Le chemin enregistré dans media_path est le chemin relatif vers le fichier par rapport au répertoire Lizmap.';

COMMENT ON COLUMN taxon.medias.id IS 'Identifiant automatique';
COMMENT ON COLUMN taxon.medias.cd_nom IS 'CD_NOM du taxon';
COMMENT ON COLUMN taxon.medias.cd_ref IS 'CD_REF du taxon';
COMMENT ON COLUMN taxon.medias.principal IS 'Si la photographie est la photographie principale, mettre True (pas encore supporté)';
COMMENT ON COLUMN taxon.medias.source IS 'Source de la photographie: mettre local si la photographie est ajoutée manuellement, ou inpn si elle provient de l''API de l''INPN';
COMMENT ON COLUMN taxon.medias.id_origine IS 'Identifiant d''origine du media dans l''API de l''INPN';
COMMENT ON COLUMN taxon.medias.url_origine IS 'URL d''origine du média téléchargé depuis l''API de l''INPN';
COMMENT ON COLUMN taxon.medias.media_path IS 'Chemin relatif du fichier image par rapport au projet QGIS de l''aplication Naturaliz';
COMMENT ON COLUMN taxon.medias.titre IS 'Titre de la photographie';
COMMENT ON COLUMN taxon.medias.auteur IS 'Auteur (copyright) de la photographie';
COMMENT ON COLUMN taxon.medias.description IS 'Description';
COMMENT ON COLUMN taxon.medias.licence IS 'Licence. Par exemple: CC-BY-SA';
