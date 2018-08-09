BEGIN;
SET search_path TO taxon,public;

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
CREATE INDEX ON taxref_consolide (regne);
CREATE INDEX ON taxref_consolide (group1_inpn);
CREATE INDEX ON taxref_consolide (group2_inpn);
CREATE INDEX ON taxref_consolide (cd_ref);
CREATE INDEX ON taxref_consolide (cd_nom);



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


-- Moteur de recherche défini par défaut
SET default_text_search_config TO french_text_search;

-- Création de la table de stockage des vecteurs pour la recherche plein texte sur taxref
DROP MATERIALIZED VIEW IF EXISTS taxref_fts;
CREATE MATERIALIZED VIEW taxref_fts AS
WITH taxref_mnhn_et_local AS (
  SELECT cd_nom, cd_ref, nom_valide, nom_vern, nom_complet, group2_inpn, rang
  FROM taxref
  UNION ALL
  SELECT cd_nom, cd_ref, nom_valide, nom_vern, nom_complet, group2_inpn, rang
  FROM taxref_local
  WHERE cd_nom_valide IS NULL
)
-- Noms valides
SELECT cd_nom::bigint, cd_ref::bigint, nom_valide AS val, nom_valide, 6::smallint AS poids,
group2_inpn, to_tsvector( unaccent(coalesce(nom_valide,'')) )::tsvector AS vec
FROM taxref_mnhn_et_local
WHERE cd_nom = cd_ref
AND rang IN ('FM', 'GN', 'AGES', 'ES', 'SSES', 'NAT', 'VAR', 'SVAR', 'FO', 'SSFO', 'RACE', 'CAR', 'AB')


-- Noms vernaculaires
UNION ALL
SELECT cd_nom::bigint, cd_ref::bigint, nom_vern AS val, nom_valide, 4::smallint AS poids,
group2_inpn, to_tsvector( unaccent(coalesce(nom_vern,'')) )::tsvector AS vec
FROM taxref_mnhn_et_local
WHERE cd_nom = cd_ref AND nom_vern IS NOT NULL AND nom_vern != ''
AND rang IN ('FM', 'GN', 'AGES', 'ES', 'SSES', 'NAT', 'VAR', 'SVAR', 'FO', 'SSFO', 'RACE', 'CAR', 'AB')


-- Noms synonymes
UNION ALL
SELECT cd_nom::bigint, cd_ref::bigint, nom_complet AS val, nom_valide, 2::smallint,
group2_inpn, to_tsvector( unaccent(coalesce(nom_complet,'')) )::tsvector AS vec
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



COMMIT;
