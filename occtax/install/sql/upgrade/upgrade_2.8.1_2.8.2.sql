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
