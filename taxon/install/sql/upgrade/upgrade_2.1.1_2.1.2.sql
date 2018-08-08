BEGIN;


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


COMMIT;
