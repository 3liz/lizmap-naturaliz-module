DROP SCHEMA IF EXISTS taxon CASCADE;
CREATE SCHEMA taxon;
SET search_path = taxon, public, pg_catalog;

-- Création de la table taxref
DROP TABLE IF EXISTS taxref CASCADE;
CREATE TABLE taxref (
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
ALTER TABLE taxref ADD PRIMARY KEY (cd_nom);

-- Indexes
CREATE INDEX ON taxref (regne);
CREATE INDEX ON taxref (group1_inpn);
CREATE INDEX ON taxref (group2_inpn);
CREATE INDEX ON taxref (cd_ref);
CREATE INDEX ON taxref (cd_nom);

COMMENT ON TABLE taxref IS 'Données taxonomiques TAXREF';
COMMENT ON COLUMN taxref.regne IS 'Règne auquel le taxon appartient';
COMMENT ON COLUMN taxref.phylum IS 'Embranchement auquel le taxon appartient';
COMMENT ON COLUMN taxref.classe IS 'Classe à laquelle le taxon appartient';
COMMENT ON COLUMN taxref.ordre IS 'Ordre auquel le taxon appartient';
COMMENT ON COLUMN taxref.famille IS 'Famille à laquelle le taxon appartient';
COMMENT ON COLUMN taxref.sous_famille IS 'Sous- famille à laquelle le taxon appartient';
COMMENT ON COLUMN taxref.tribu IS 'Tribu à laquelle le taxon appartient';
COMMENT ON COLUMN taxref.group1_inpn IS 'Libellé Groupe 1 INPN pour ce taxon';
COMMENT ON COLUMN taxref.group2_inpn IS 'Libellé Groupe 1 INPN';
COMMENT ON COLUMN taxref.cd_nom IS 'Identifiant unique du nom scientifique';
COMMENT ON COLUMN taxref.cd_taxsup IS 'Identifiant (CD_NOM) du taxon supérieur calculé dans la classification simplifiée ';
COMMENT ON COLUMN taxref.cd_sup IS 'Identifiant (CD_NOM) du taxon directement supérieur';
COMMENT ON COLUMN taxref.cd_ref IS 'Identifiant (CD_NOM) du taxon de référence (nom retenu)';
COMMENT ON COLUMN taxref.rang IS 'Rang taxonomique (lien vers TAXREF_RANG)';
COMMENT ON COLUMN taxref.lb_nom IS 'Nom scientifique du taxon (sans l’autorité)';
COMMENT ON COLUMN taxref.lb_auteur IS 'Autorité du taxon (Auteur, année, gestion des parenthèses)';
COMMENT ON COLUMN taxref.nom_complet IS 'Combinaison des champs pour donner le nom complet (~LB_NOM+" "+LB_AUTEUR)';
COMMENT ON COLUMN taxref.nom_complet_html IS 'Nom complet formatté en HTML';
COMMENT ON COLUMN taxref.nom_valide IS 'Le NOM_COMPLET du CD_REF';
COMMENT ON COLUMN taxref.nom_vern IS 'Noms vernaculaires français';
COMMENT ON COLUMN taxref.nom_vern_eng IS 'Noms vernaculaires anglais';
COMMENT ON COLUMN taxref.habitat IS 'Code de l’habitat (clé vers TAXREF_HABITATS)';
COMMENT ON COLUMN taxref.fr IS 'Statut biogéographique en France métropolitaine (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref.gf IS 'Statut biogéographique en Guyane française (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref.mar IS 'Statut biogéographique à la Martinique (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref.gua IS 'Statut biogéographique à la Guadeloupe (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref.sm IS 'Statut biogéographique à Saint-Martin (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref.sb IS 'Statut biogéographique à Saint-Barthélemy (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref.spm IS 'Statut biogéographique à Saint-Pierre et Miquelon (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref.may IS 'Statut biogéographique à Mayotte (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref.epa IS 'Statut biogéographique aux Îles Éparses (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref.reu IS 'Statut biogéographique à la Réunion (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref.sa IS 'Statut biogéographique aux îles subantarctiques ( (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref.ta IS 'Statut biogéographique en Terre Adélie (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref.taaf IS 'Statut biogéographique aux TAAF (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref.pf IS 'Statut biogéographique en Polynésie française (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref.nc IS 'Statut biogéographique en Nouvelle-Calédonie (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref.wf IS 'Statut biogéographique à Wallis et Futuna (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref.cli IS 'Statut biogéographique à Clipperton (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref.url IS 'Permalien INPN = ‘http://inpn.mnhn.fr/espece/cd_nom/’ + CD_NOM';



-- Table pour stocker des informations sur les bdd de taxon locales
CREATE TABLE taxref_local_source (
  id serial PRIMARY KEY,
  code text UNIQUE NOT NULL,
  titre text NOT NULL,
  description text,
  info_url text NOT NULL,
  taxon_url text NOT NULL
);
COMMENT ON TABLE taxref_local_source IS 'Stockage des informations sur les sources de données des taxons';
COMMENT ON COLUMN taxref_local_source.id IS 'Identifiant automatique';
COMMENT ON COLUMN taxref_local_source.code IS 'Code court de la base de données. Par exemple: CBNM. Doit être unique';
COMMENT ON COLUMN taxref_local_source.titre IS 'Titre de la base de données. Par exemple: Index de la flore vasculaire de La Réunion';
COMMENT ON COLUMN taxref_local_source.description IS 'Description de la base de données. Optionnelle';
COMMENT ON COLUMN taxref_local_source.info_url IS 'URL vers une page décrivant la base de données source. Ex: http://mascarine.cbnm.org/';
COMMENT ON COLUMN taxref_local_source.taxon_url IS 'URL vers la fiche d''un taxon dans la base de données source.';



-- Table de stockage des taxons locaux non présents dans le TAXREF officiel
DROP TABLE IF EXISTS taxref_local CASCADE;
CREATE TABLE taxref_local
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
  cd_nom_valide bigint -- Cd_nom du taxon valide une fois que le taxon est apparu dans taxref
  CONSTRAINT taxref_local_cd_nom_valid CHECK ( cd_nom < 0 )
)
WITH (
  OIDS=FALSE
);

ALTER TABLE taxref_local ADD PRIMARY KEY(cd_nom);
DROP SEQUENCE IF EXISTS taxref_local_cd_nom_seq;
CREATE SEQUENCE taxref_local_cd_nom_seq INCREMENT -1 START -1;
ALTER TABLE taxref_local ALTER COLUMN cd_nom SET DEFAULT nextval('taxref_local_cd_nom_seq');
ALTER TABLE taxref_local ALTER COLUMN cd_ref SET DEFAULT currval('taxref_local_cd_nom_seq');

ALTER TABLE taxon.taxref_local ADD CONSTRAINT taxref_local_lb_nom UNIQUE (lb_nom);

COMMENT ON TABLE taxref_local  IS 'Données taxonomiques qui ne sont pas dans TAXREF. L''identifiant donné est négatif temporaire, jusqu''à la création du taxon dans le TAXREF officiel. La structure de la table est complètement identique à celle de TAXREF pour permettre une UNION entre les 2 tables';
COMMENT ON COLUMN taxref_local.regne IS 'Règne auquel le taxon appartient';
COMMENT ON COLUMN taxref_local.phylum IS 'Embranchement auquel le taxon appartient';
COMMENT ON COLUMN taxref_local.classe IS 'Classe à laquelle le taxon appartient';
COMMENT ON COLUMN taxref_local.ordre IS 'Ordre auquel le taxon appartient';
COMMENT ON COLUMN taxref_local.famille IS 'Famille à laquelle le taxon appartient';
COMMENT ON COLUMN taxref_local.sous_famille IS 'Sous-famille à laquelle le taxon appartient';
COMMENT ON COLUMN taxref_local.tribu IS 'Tribu à laquelle le taxon appartient';
COMMENT ON COLUMN taxref_local.group1_inpn IS 'Libellé Groupe 1 INPN pour ce taxon';
COMMENT ON COLUMN taxref_local.group2_inpn IS 'Libellé Groupe 1 INPN';
COMMENT ON COLUMN taxref_local.cd_nom IS 'Identifiant unique du nom scientifique';
COMMENT ON COLUMN taxref_local.cd_taxsup IS 'Identifiant (CD_NOM) du taxon supérieur calculé dans la classification simplifiée ';
COMMENT ON COLUMN taxref_local.cd_sup IS 'Identifiant (CD_NOM) du taxon directement supérieur';
COMMENT ON COLUMN taxref_local.cd_ref IS 'Identifiant (CD_NOM) du taxon de référence (nom retenu)';
COMMENT ON COLUMN taxref_local.rang IS 'Rang taxonomique (lien vers TAXREF_RANG)';
COMMENT ON COLUMN taxref_local.lb_nom IS 'Nom scientifique du taxon (sans l’autorité)';
COMMENT ON COLUMN taxref_local.lb_auteur IS 'Autorité du taxon (Auteur, année, gestion des parenthèses)';
COMMENT ON COLUMN taxref_local.nom_complet IS 'Combinaison des champs pour donner le nom complet (~LB_NOM+" "+LB_AUTEUR)';
COMMENT ON COLUMN taxref_local.nom_complet_html IS 'Nom complet formatté en HTML';
COMMENT ON COLUMN taxref_local.nom_valide IS 'Le NOM_COMPLET du CD_REF';
COMMENT ON COLUMN taxref_local.nom_vern IS 'Noms vernaculaires français';
COMMENT ON COLUMN taxref_local.nom_vern_eng IS 'Noms vernaculaires anglais';
COMMENT ON COLUMN taxref_local.habitat IS 'Code de l’habitat (clé vers TAXREF_HABITATS)';
COMMENT ON COLUMN taxref_local.fr IS 'Statut biogéographique en France métropolitaine (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref_local.gf IS 'Statut biogéographique en Guyane française (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref_local.mar IS 'Statut biogéographique à la Martinique (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref_local.gua IS 'Statut biogéographique à la Guadeloupe (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref_local.sm IS 'Statut biogéographique à Saint-Martin (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref_local.sb IS 'Statut biogéographique à Saint-Barthélemy (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref_local.spm IS 'Statut biogéographique à Saint-Pierre et Miquelon (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref_local.may IS 'Statut biogéographique à Mayotte (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref_local.epa IS 'Statut biogéographique aux Îles Éparses (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref_local.reu IS 'Statut biogéographique à la Réunion (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref_local.sa IS 'Statut biogéographique îles subantarctiques (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref_local.ta IS 'Statut biogéographique en Terre Adélie (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref_local.taaf IS 'Statut biogéographique aux TAAF (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref_local.pf IS 'Statut biogéographique en Polynésie française (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref_local.nc IS 'Statut biogéographique en Nouvelle-Calédonie (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref_local.wf IS 'Statut biogéographique à Wallis et Futuna (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref_local.cli IS 'Statut biogéographique à Clipperton (clé vers TAXREF_STATUTS)';
COMMENT ON COLUMN taxref_local.url IS 'Permalien INPN = ‘http://inpn.mnhn.fr/espece/cd_nom/’ + CD_NOM';
COMMENT ON COLUMN taxref_local.cd_nom_valide IS 'cd_nom du taxon valide, à renseigner après import d''un nouveau TAXREF, pour pouvoir modifier ensuite les observations qui faisaient référence au cd_nom négatif provisoire de la ligne. Penser à supprimer la ligne une fois les modifications faites sur les observations';

CREATE INDEX taxref_local_cd_nom_idx ON taxref_local USING btree (cd_nom);
CREATE INDEX taxref_local_cd_ref_idx ON taxref_local USING btree  (cd_ref);
CREATE INDEX taxref_local_group1_inpn_idx ON taxref_local USING btree (group1_inpn);
CREATE INDEX taxref_local_group2_inpn_idx ON taxref_local USING btree (group2_inpn);
CREATE INDEX taxref_local_regne_idx ON taxref_local USING btree (regne);

CREATE INDEX ON taxref (habitat);
CREATE INDEX ON taxref_local (habitat);


-- Colonnes pour stocker les informations spécifiques pour taxref_local
ALTER TABLE taxref_local ADD COLUMN local_bdd_code text NOT NULL;
ALTER TABLE taxref_local ADD COLUMN local_identifiant_origine text NOT NULL;
ALTER TABLE taxref_local ADD COLUMN local_identifiant_origine_ref text;
COMMENT ON COLUMN taxref_local.local_bdd_code IS 'Base de données source. Ce champ est une clé étrangère liée à la table taxref_local_source, vers le champ code';
COMMENT ON COLUMN taxref_local.local_identifiant_origine IS 'Identifiant du taxon (équivalent cd_nom) dans la base de données d''origine.';
COMMENT ON COLUMN taxref_local.local_identifiant_origine_ref IS 'Identifiant du taxon de référence (équivalent cd_ref) dans la base de données d''origine.';

ALTER TABLE taxref_local
ADD CONSTRAINT taxref_local_bdd_code FOREIGN KEY (local_bdd_code)
REFERENCES taxref_local_source (code) MATCH SIMPLE
ON UPDATE CASCADE ON DELETE RESTRICT
;



-- Ajout d'une vue pour les taxons valides seulement
-- seulement sur les rangs qui correpondent à des espaces
DROP MATERIALIZED VIEW IF EXISTS taxref_valide CASCADE;
CREATE MATERIALIZED VIEW taxref_valide AS
WITH taxref_mnhn_et_local AS (
  SELECT regne, phylum, classe, ordre, famille, sous_famille, tribu, group1_inpn, group2_inpn,
  cd_nom, cd_taxsup, cd_ref, rang, lb_nom, lb_auteur, nom_complet,
  nom_complet_html, nom_valide, nom_vern, nom_vern_eng, habitat,
  fr, gf, mar, gua, sm, sb, spm, may, epa, reu, sa, ta, taaf, pf, nc, wf, cli, url
  FROM taxref
  UNION ALL
  SELECT regne, phylum, classe, ordre, famille, sous_famille, tribu, group1_inpn, group2_inpn,
  cd_nom, cd_taxsup, cd_ref, rang, lb_nom, lb_auteur, nom_complet,
  nom_complet_html, nom_valide, nom_vern, nom_vern_eng, habitat,
  fr, gf, mar, gua, sm, sb, spm, may, epa, reu, sa, ta, taaf, pf, nc, wf, cli, url
  FROM taxref_local
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
AND rang IN ('FM', 'GN', 'AGES', 'ES', 'SSES', 'NAT', 'VAR', 'SVAR', 'FO', 'SSFO', 'RACE', 'CAR', 'AB');

COMMENT ON MATERIALIZED VIEW taxref_valide IS '
Vue matérialisée pour récupérer uniquement les taxons valides (cd_nom = cd_ref) dans la table taxref et dans la table taxref_local.

Elle fait une union entre les 2 tables source et ne conserve que les taxons des rangs: FM, GN, AGES, ES, SSES, NAT, VAR, SVAR, FO, SSFO, RACE, CAR, AB.

Elle doit être rafraîchie dès qu''on réalise un import dans une ou l''autre des tables sources: `REFRESH MATERIALIZED VIEW taxref_valide;`
';


-- ALTER TABLE taxref_valide ADD PRIMARY KEY (cd_nom);
CREATE INDEX ON taxref_valide (group1_inpn);
CREATE INDEX ON taxref_valide (group2_inpn);
CREATE INDEX ON taxref_valide (cd_ref);
CREATE INDEX ON taxref_valide (cd_nom);
CREATE INDEX ON taxref_valide (habitat);


-- Ajout des capacités de recherche plein texte
SET search_path TO public,pg_catalog;
DROP TEXT SEARCH CONFIGURATION IF EXISTS french_text_search;
CREATE TEXT SEARCH CONFIGURATION french_text_search (COPY = french);
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
ALTER TEXT SEARCH CONFIGURATION french_text_search ALTER MAPPING FOR hword, hword_part, word, asciihword, asciiword, hword_asciipart WITH unaccent, french_stem;
SET default_text_search_config TO french_text_search;

SET search_path TO taxon,public,pg_catalog;

-- Création de la table de stockage des vecteurs pour la recherche plein texte sur taxref
DROP MATERIALIZED VIEW IF EXISTS taxref_fts;
CREATE MATERIALIZED VIEW taxref_fts AS
WITH taxref_mnhn_et_local AS (
  SELECT cd_nom, cd_ref, nom_valide, nom_vern, nom_complet, group2_inpn, rang, {$colonne_locale} AS loc
  FROM taxref
  UNION ALL
  SELECT cd_nom, cd_ref, nom_valide, nom_vern, nom_complet, group2_inpn, rang, {$colonne_locale} AS loc
  FROM taxref_local
  WHERE cd_nom_valide IS NULL
)
-- Noms valides
SELECT cd_nom::bigint, cd_ref::bigint, nom_valide AS val, nom_valide, 6::smallint AS poids,
group2_inpn, to_tsvector( unaccent(coalesce(nom_valide,'')) )::tsvector AS vec, loc
FROM taxref_mnhn_et_local
WHERE cd_nom = cd_ref
AND rang IN ('FM', 'GN', 'AGES', 'ES', 'SSES', 'NAT', 'VAR', 'SVAR', 'FO', 'SSFO', 'RACE', 'CAR', 'AB')


-- Noms vernaculaires
UNION ALL
SELECT cd_nom::bigint, cd_ref::bigint, nom_vern AS val, nom_valide, 4::smallint AS poids,
group2_inpn, to_tsvector( unaccent(coalesce(nom_vern,'')) )::tsvector AS vec, loc
FROM taxref_mnhn_et_local
WHERE cd_nom = cd_ref AND nom_vern IS NOT NULL AND nom_vern != ''
AND rang IN ('FM', 'GN', 'AGES', 'ES', 'SSES', 'NAT', 'VAR', 'SVAR', 'FO', 'SSFO', 'RACE', 'CAR', 'AB')


-- Noms synonymes
UNION ALL
SELECT cd_nom::bigint, cd_ref::bigint, nom_complet AS val, nom_valide, 2::smallint,
group2_inpn, to_tsvector( unaccent(coalesce(nom_complet,'')) )::tsvector AS vec, loc
FROM taxref_mnhn_et_local
WHERE cd_nom != cd_ref
AND rang IN ('FM', 'GN', 'AGES', 'ES', 'SSES', 'NAT', 'VAR', 'SVAR', 'FO', 'SSFO', 'RACE', 'CAR', 'AB')
;


COMMENT ON MATERIALIZED VIEW taxref_fts IS '
Vue matérialisée pour le stockage des informations de recherche plein texte visible dans naturaliz.

Cette vue se base sur une UNION des taxons, valides ou non, des tables taxref et taxref_local. On n''a gardé que les taxons des rangs: FM, GN, AGES, ES, SSES, NAT, VAR, SVAR, FO, SSFO, RACE, CAR, AB

Un champ poids permet de prioriser la recherche dans cet ordre, avec les poids respectifs 6, 4 et 2:
* noms (nom_valide) des taxons valides (cd_nom = cd_ref)
* noms vernaculaires (nom_vern) des taxons valides (cd_nom = cd_ref)
* noms (nom_complet) des taxons synonymes (cd_nom != cd_ref)

Cette vue doit être rafraîchie dès qu''on modifie les données dans les tables taxref et/ou taxref_local: `REFRESH MATERIALIZED VIEW taxref_fts`
';
COMMENT ON COLUMN taxref_fts.cd_nom IS 'Identifiant du taxon (cd_nom) en lien avec la table taxref';
COMMENT ON COLUMN taxref_fts.cd_ref IS 'Identifiant du taxon valide (cd_ref)';
COMMENT ON COLUMN taxref_fts.val IS 'Valeur à afficher (nom du taxon, group1_inpn, etc.)';
COMMENT ON COLUMN taxref_fts.nom_valide IS 'Nom valide correspondant';
COMMENT ON COLUMN taxref_fts.poids IS 'Importance de l objet dans la recherche, fonction du type';
COMMENT ON COLUMN taxref_fts.group2_inpn IS 'Groupe INPN - utilisé pour afficher des icônes';
COMMENT ON COLUMN taxref_fts.vec IS 'Vecteur de la recherche plein texte';

-- Ajout de l'index
CREATE INDEX ON taxref_fts USING gin(vec);
CREATE INDEX ON taxref_fts (group2_inpn);


-- Ajout de la table t_complement
DROP TABLE IF EXISTS t_complement CASCADE;
CREATE TABLE t_complement
(
  cd_nom_fk integer,
  statut character varying(15),
  rarete character varying(10),
  endemicite character varying(5),
  invasibilite character varying(5),
  menace character varying(5),
  menace_monde character varying(6),
  protection character varying(5),
  det_znieff character varying(15),
  CONSTRAINT t_complement_pkey PRIMARY KEY (cd_nom_fk)
)
WITH (
  OIDS=FALSE
);

COMMENT ON TABLE t_complement IS 'Stockage des données complémentaires sur les taxons, non présents dans TAXREF : données locales (endémicité, invasibilité, etc.), déterminants ZNIEFF';

COMMENT ON COLUMN t_complement.cd_nom_fk IS 'Identifiant du taxon, lien avec taxref.cd_nom';
COMMENT ON COLUMN t_complement.statut IS 'Statut local';
COMMENT ON COLUMN t_complement.rarete IS 'Rareté locale du taxon';
COMMENT ON COLUMN t_complement.endemicite IS 'Endémicité locale du taxon';
COMMENT ON COLUMN t_complement.invasibilite IS 'Invasibilité locale du taxon';
COMMENT ON COLUMN t_complement.menace IS 'Menace locale sur le taxon';
COMMENT ON COLUMN t_complement.menace_monde IS 'Menace mondiale sur le taxon';
COMMENT ON COLUMN t_complement.protection IS 'Statut de protection local';
COMMENT ON COLUMN t_complement.det_znieff IS 'Déterminant ZNIEFF';

CREATE INDEX ON t_complement (cd_nom_fk);
CREATE INDEX ON t_complement (det_znieff);
CREATE INDEX ON t_complement (endemicite);
CREATE INDEX ON t_complement (invasibilite);
CREATE INDEX ON t_complement (menace);
CREATE INDEX ON t_complement (protection);
CREATE INDEX ON t_complement (rarete);
CREATE INDEX ON t_complement (statut);


-- Nomenclature
DROP TABLE IF EXISTS t_nomenclature CASCADE;
CREATE TABLE t_nomenclature
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

COMMENT ON TABLE t_nomenclature IS 'Stockage de la t_nomenclature pour les champs des tables qui ont des listes de valeurs prédéfinies.';
COMMENT ON COLUMN t_nomenclature.champ IS 'Description de la valeur';
COMMENT ON COLUMN t_nomenclature.code IS 'Code associé à une valeur';
COMMENT ON COLUMN t_nomenclature.valeur IS 'Libellé court. Joue le rôle de valeur';
COMMENT ON COLUMN t_nomenclature.description IS 'Libellé court. Joue le rôle de valeur';
COMMENT ON COLUMN t_nomenclature.ordre IS 'Ordre d''apparition souhaité, utilisé par exemple dans les listes déroulantes du formulaire de recherche.';

CREATE INDEX ON t_nomenclature (champ, code);


-- Table t_group_categorie : groupes personnalisés pour le filtre des taxons
DROP TABLE IF EXISTS t_group_categorie CASCADE;
CREATE TABLE t_group_categorie (
    cat_nom text,
    groupe_nom text,
    groupe_type text,
    regne text,
    CONSTRAINT t_group_categorie_regne_valide CHECK ( regne IN ( 'Plantae', 'Animalia', 'Fungi', 'Chromista', 'Bacteria', 'Protozoa' ) )
);
ALTER TABLE t_group_categorie ADD PRIMARY KEY (cat_nom, groupe_nom);

COMMENT ON TABLE t_group_categorie IS 'Liste des catégories de groupes de taxons affichées dans la liste déroulante du filtre de recherche.';
COMMENT ON COLUMN t_group_categorie.cat_nom IS 'Libellé à afficher pour le groupe';
COMMENT ON COLUMN t_group_categorie.groupe_nom IS 'Nom du groupe INPN correspondant';
COMMENT ON COLUMN t_group_categorie.groupe_type IS 'Type de groupe INPN : group1_inpn ou group2_inpn';
COMMENT ON COLUMN t_group_categorie.regne IS 'Le règne du groupe INPN';



-- Table de stockage des taxons sensibles
CREATE TABLE taxon_sensible
(
  cd_nom integer NOT NULL,
  nom_valide text,
  CONSTRAINT taxon_sensible_pkey PRIMARY KEY (cd_nom)
);

COMMENT ON TABLE taxon_sensible IS 'Liste des taxon sensibles. Les observations concernées par ces taxon ne seront visibles que pour les personnes avec des droits hauts.';

COMMENT ON COLUMN taxon_sensible.cd_nom IS 'Identifiant du taxon.';
COMMENT ON COLUMN taxon_sensible.nom_valide IS 'Nom valide du taxon, ajouté pour faciliter la lecture (optionnel)';



-- Vue de consolidation des données TAXREF officielles valides, locales et complémentaires
DROP MATERIALIZED VIEW IF EXISTS taxon.taxref_consolide CASCADE;
CREATE MATERIALIZED VIEW taxon.taxref_consolide AS
SELECT
t.*, c.*
FROM (
        SELECT regne, phylum, classe, ordre, famille, sous_famille, tribu, group1_inpn, group2_inpn, cd_nom, cd_taxsup, cd_ref, rang, lb_nom, lb_auteur, nom_complet, nom_complet_html, nom_valide, nom_vern, nom_vern_eng, habitat, fr, gf, mar, gua, sm, sb, spm, may, epa, reu, sa, ta, taaf, pf, nc, wf, cli, url
        FROM taxref_valide
) AS t
LEFT JOIN t_complement AS c ON c.cd_nom_fk = t.cd_nom
;

COMMENT ON MATERIALIZED VIEW taxon.taxref_consolide IS '
Vue matérialisée pour gérer l''association des données du TAXREF (taxref) et des taxons locaux (taxref_local) avec les données complémentaires sur les statuts, la protection, les menaces (t_complement).

Seuls les taxons valides sont présents dans cette table (car elle dépend de la vue matérialisée taxref_valide )

Elle est principalement utilisée pour récupérer les cd_ref des sous-ensembles de taxons à filtrer lorsqu''on chercher des observations.

C''est une vue matérialisée, c''est-à-dire une vue qui se comporte comme une table, et qu''on doit mettre à jour suite à un import de taxons (dans taxref ou taxref_local), ou suite à la mise à jour de taxref_valide, via `REFRESH MATERIALIZED VIEW taxref_consolide;`
';
CREATE INDEX ON taxref_consolide (group1_inpn);
CREATE INDEX ON taxref_consolide (group2_inpn);
CREATE INDEX ON taxref_consolide (cd_ref);
CREATE INDEX ON taxref_consolide (cd_nom);
CREATE INDEX ON taxref_consolide (famille);


-- statuts de protection
CREATE TABLE protections (
    cd_nom text,
    cd_protection text,
    nom_cite text,
    syn_cite text,
    nom_francais_cite text,
    precisions text,
    cd_nom_cite text
)
;
COMMENT ON TABLE protections IS 'Statuts de protection des espèces. Source: fichier du TAXREF listant les protections, par exemple : PROTECTION_ESPECES_10.csv. L''import ne conserve que les données pour les codes d''arrêtés spécifiés dans la configuration de l''application';
CREATE INDEX ON protections (cd_nom);

-- MENACES = TAXON DES LISTES ROUGES
CREATE TABLE menaces (
    cd_nom integer NOT NULL, -- Identifiant unique du nom scientifique
    cd_ref integer, -- Identifiant (CD_NOM) du taxon de référence (nom retenu)
    nom_scientifique text,
    auteur text,
    nom_commun text,
    rang text,
    famille text,
    endemisme text,
    population text,
    commentaire text,
    categorie_france text,
    criteres_france text,
    tendance text,
    liste_rouge_source text,
    annee_publi text,
    categorie_lr_europe text,
    categorie_lr_monde text
)
;
COMMENT ON TABLE menaces IS 'Données sur les menaces, issues des listes rouges';
CREATE INDEX ON menaces (cd_nom);


-- Vue taxref_consolide_all pour pouvoir faire des statistiques
-- sur tous les taxons, valides ou non.
-- Sinon le tableau renvoit "Autre" car les taxons non valides ne sont pas bien pris en compte
DROP MATERIALIZED VIEW IF EXISTS taxon.taxref_consolide_all;
CREATE MATERIALIZED VIEW taxon.taxref_consolide_all AS
WITH
taxref_mnhn_et_local AS (
  SELECT group1_inpn, group2_inpn, cd_nom
  FROM taxref
  WHERE rang IN ('FM', 'GN', 'AGES', 'ES', 'SSES', 'NAT', 'VAR', 'SVAR', 'FO', 'SSFO', 'RACE', 'CAR', 'AB')
  UNION ALL
  SELECT group1_inpn, group2_inpn, cd_nom
  FROM taxref_local
  WHERE rang IN ('FM', 'GN', 'AGES', 'ES', 'SSES', 'NAT', 'VAR', 'SVAR', 'FO', 'SSFO', 'RACE', 'CAR', 'AB')
  AND cd_nom_valide IS NULL
)
SELECT tml.*, c.*
FROM taxref_mnhn_et_local AS tml
LEFT JOIN t_complement AS c ON c.cd_nom_fk = tml.cd_nom
;
CREATE INDEX ON taxon.taxref_consolide_all (cd_nom);
CREATE INDEX ON taxon.taxref_consolide_all (protection);


-- Vue qui rassemble tous les taxons de TAXREF et de taxref local:
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
  FROM taxref
  WHERE True
  UNION ALL
  SELECT
  regne, phylum, classe, ordre, famille, sous_famille, tribu, group1_inpn, group2_inpn,
cd_nom, cd_taxsup, cd_ref, rang, lb_nom, lb_auteur, nom_complet,
nom_complet_html, nom_valide, nom_vern, nom_vern_eng, habitat,
fr, gf, mar, gua, sm, sb, spm, may, epa, reu, sa, ta, taaf, pf, nc, wf, cli, url
  FROM taxref_local
  WHERE True
  AND cd_nom_valide IS NULL
)
SELECT tml.*, c.*
FROM taxref_mnhn_et_local AS tml
LEFT JOIN t_complement AS c ON c.cd_nom_fk = tml.cd_nom
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
CREATE INDEX ON taxon.taxref_consolide_non_filtre (menace);
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



