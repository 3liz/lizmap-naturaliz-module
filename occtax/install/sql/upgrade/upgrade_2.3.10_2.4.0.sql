
DROP MATERIALIZED VIEW IF EXISTS taxon.taxref_consolide_all;

-- taxref_valide
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
Vue matérialisée pour récupérer uniquement les taxons valides (cd_nom = cd_ref) dans la table taxref et dans la table taxref_local.

Elle fait une union entre les 2 tables source et ne conserve que les taxons des rangs: FM, GN, AGES, ES, SSES, NAT, VAR, SVAR, FO, SSFO, RACE, CAR, AB.

Elle doit être rafraîchie dès qu''on réalise un import dans une ou l''autre des tables sources: `REFRESH MATERIALIZED VIEW taxref_valide;`
';

-- ALTER TABLE taxref_valide ADD PRIMARY KEY (cd_nom);
CREATE INDEX ON taxon.taxref_valide (group1_inpn);
CREATE INDEX ON taxon.taxref_valide (group2_inpn);
CREATE INDEX ON taxon.taxref_valide (cd_ref);
CREATE INDEX ON taxon.taxref_valide (cd_nom);
CREATE INDEX ON taxon.taxref_valide (habitat);

-- recreate depending views

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

Seuls les taxons valides sont présents dans cette table (car elle dépend de la vue matérialisée taxref_valide )

Elle est principalement utilisée pour récupérer les cd_ref des sous-ensembles de taxons à filtrer lorsqu''on chercher des observations.

C''est une vue matérialisée, c''est-à-dire une vue qui se comporte comme une table, et qu''on doit mettre à jour suite à un import de taxons (dans taxref ou taxref_local), ou suite à la mise à jour de taxref_valide, via `REFRESH MATERIALIZED VIEW taxref_consolide;`
';
CREATE INDEX ON taxon.taxref_consolide (group1_inpn);
CREATE INDEX ON taxon.taxref_consolide (group2_inpn);
CREATE INDEX ON taxon.taxref_consolide (cd_ref);
CREATE INDEX ON taxon.taxref_consolide (cd_nom);
CREATE INDEX ON taxon.taxref_consolide (famille);


-- Stats
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.liste_jdd AS
WITH groupes AS (
    SELECT jdd_id, COALESCE(group2_inpn, 'Autres') AS group2_inpn, count(cle_obs) AS nb_obs, count(DISTINCT cd_ref) AS nb_taxons
    FROM occtax.observation
    LEFT JOIN taxon.taxref_valide USING (cd_ref)
    GROUP BY jdd_id, group2_inpn
    ORDER BY jdd_id, group2_inpn
    ),

    milieux AS(
    SELECT jdd_id, COALESCE(n.valeur, 'Habitat non connu') AS habitat, count(cle_obs) AS nb_obs
    FROM occtax.observation
    LEFT JOIN taxref_valide t USING (cd_ref)
    LEFT JOIN taxon.t_nomenclature n ON n.code=t.habitat::TEXT
    WHERE n.champ='habitat'
    GROUP BY jdd_id, n.valeur
    ORDER BY jdd_id, n.valeur
    ),

    r AS(
    SELECT  jdd_id,
            jsonb_array_elements(ayants_droit)->>'id_organisme' AS id_organisme,
            jsonb_array_elements(ayants_droit)->>'role' AS role
    FROM occtax.jdd
    )

SELECT jdd.jdd_code,
    jdd.jdd_description,
    string_agg(DISTINCT
                   COALESCE (o.sigle, o.nom_organisme) || ' (' || r.role || ')', ' - '
                   ORDER BY COALESCE (o.sigle, o.nom_organisme) || ' (' || r.role || ')'
                  ) AS producteurs,
    i.date_reception,
    imin.date_import AS date_premier_import,
    imax.date_import AS date_dernier_import,
    i.nb_donnees_source, i.nb_donnees_import,
    string_agg(DISTINCT groupes.group2_inpn || ' (' || groupes.nb_obs || ' obs, ' || groupes.nb_taxons || ' taxons)', ' | ' ) AS groupes_taxonomiques,
    string_agg(DISTINCT milieux.habitat || ' (' || milieux.nb_obs || ' obs)', ' | ' ) AS habitats_taxons,
    i.date_obs_min,
    i.date_obs_max,
    CONCAT('https://inpn.mnhn.fr/mtd/cadre/export/xml/GetRecordById?id=', jdd.jdd_cadre) AS fiche_md_cadre_acquisition,
    CONCAT('https://inpn.mnhn.fr/mtd/cadre/jdd/export/xml/GetRecordById?id=', jdd.jdd_metadonnee_dee_id) AS fiche_md_jdd
FROM occtax.jdd
LEFT JOIN groupes ON jdd.jdd_id=groupes.jdd_id
LEFT JOIN milieux ON jdd.jdd_id=milieux.jdd_id
LEFT JOIN r ON jdd.jdd_id=r.jdd_id
JOIN (SELECT jdd_id, min(id_import) AS id_import, min(date_import) AS date_import  FROM occtax.jdd_import GROUP BY jdd_id) imin ON imin.jdd_id=jdd.jdd_id
JOIN (SELECT jdd_id, max(id_import) AS id_import, max(date_import) AS date_import FROM occtax.jdd_import GROUP BY jdd_id) imax ON imax.jdd_id=jdd.jdd_id
LEFT JOIN occtax.jdd_import i ON imax.jdd_id=i.jdd_id
LEFT JOIN occtax.organisme o ON r.id_organisme::INTEGER=o.id_organisme
WHERE imax.id_import=i.id_import
GROUP BY jdd_cadre, jdd.jdd_code, jdd.jdd_description, jdd.jdd_metadonnee_dee_id,
    i.date_reception, imin.date_import, imax.date_import, i.nb_donnees_source, i.nb_donnees_import,
    i.date_obs_min, i.date_obs_max
ORDER BY imin.date_import
;

COMMENT ON MATERIALIZED VIEW stats.liste_jdd IS 'Liste des jeux de données indiquant pour chacun les producteurs concernés, les milieux de vie des taxons concernés, les URL pour accéder aux fiches de métadonnées, etc.';


-- Recherche plein texte
-- Création de la table de stockage des vecteurs pour la recherche plein texte sur taxref
DROP MATERIALIZED VIEW IF EXISTS taxon.taxref_fts;
CREATE MATERIALIZED VIEW taxon.taxref_fts AS
WITH taxref_mnhn_et_local AS (
  SELECT cd_nom, cd_ref, nom_valide, nom_vern, nom_complet, group2_inpn, rang, {$colonne_locale} AS loc
  FROM taxref
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

Cette vue se base sur une UNION des taxons, valides ou non, des tables taxref et taxref_local. On n''a gardé que les taxons des rangs: FM, GN, AGES, ES, SSES, NAT, VAR, SVAR, FO, SSFO, RACE, CAR, AB

Un champ poids permet de prioriser la recherche dans cet ordre, avec les poids respectifs 6, 4 et 2:
* noms (nom_valide) des taxons valides (cd_nom = cd_ref)
* noms vernaculaires (nom_vern) des taxons valides (cd_nom = cd_ref)
* noms (nom_complet) des taxons synonymes (cd_nom != cd_ref)

Cette vue doit être rafraîchie dès qu''on modifie les données dans les tables taxref et/ou taxref_local: `REFRESH MATERIALIZED VIEW taxref_fts`
';
COMMENT ON COLUMN taxon.taxref_fts.cd_nom IS 'Identifiant du taxon (cd_nom) en lien avec la table taxref';
COMMENT ON COLUMN taxon.taxref_fts.cd_ref IS 'Identifiant du taxon valide (cd_ref)';
COMMENT ON COLUMN taxon.taxref_fts.val IS 'Valeur à afficher (nom du taxon, group1_inpn, etc.)';
COMMENT ON COLUMN taxon.taxref_fts.nom_valide IS 'Nom valide correspondant';
COMMENT ON COLUMN taxon.taxref_fts.poids IS 'Importance de l objet dans la recherche, fonction du type';
COMMENT ON COLUMN taxon.taxref_fts.group2_inpn IS 'Groupe INPN - utilisé pour afficher des icônes';
COMMENT ON COLUMN taxon.taxref_fts.vec IS 'Vecteur de la recherche plein texte';

-- Ajout de l'index
CREATE INDEX ON taxon.taxref_fts USING gin(vec);
CREATE INDEX ON taxon.taxref_fts (group2_inpn);

