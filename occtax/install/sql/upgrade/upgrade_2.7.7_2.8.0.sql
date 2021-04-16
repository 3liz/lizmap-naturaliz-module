-- occtax
CREATE OR REPLACE VIEW occtax.v_validateur AS
SELECT CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE p.identite END AS identite,
CASE WHEN p.anonymiser IS TRUE THEN '' ELSE p.mail END AS mail,
CASE WHEN p.anonymiser IS TRUE OR lower(p.identite) = lower(nom_organisme) THEN NULL ELSE Coalesce(nom_organisme, 'INCONNU') END AS organisme,
p.id_personne, vv.identifiant_permanent, p.prenom, p.nom, p.anonymiser,
p.identite AS identite_non_floutee,
p.mail AS mail_non_floute,
Coalesce(nom_organisme, 'INCONNU') AS organisme_non_floute
FROM occtax.validation_observation vv
LEFT JOIN occtax.personne p ON vv.validateur = p.id_personne
LEFT JOIN occtax.organisme o ON p.id_organisme = o.id_organisme
WHERE ech_val = '2' -- uniquement validation de niveau régional
;

CREATE OR REPLACE VIEW occtax.v_determinateur AS
SELECT CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE p.identite END AS identite,
CASE WHEN p.anonymiser IS TRUE THEN '' ELSE p.mail END AS mail,
CASE WHEN p.anonymiser IS TRUE OR lower(p.identite) = lower(nom_organisme) THEN NULL ELSE Coalesce(nom_organisme, 'INCONNU') END AS organisme,
op.id_personne, op.cle_obs, p.prenom, p.nom, p.anonymiser,
p.identite AS identite_non_floutee,
p.mail AS mail_non_floute,
Coalesce(nom_organisme, 'INCONNU') AS organisme_non_floute
FROM occtax.observation_personne op
INNER JOIN occtax.personne p ON p.id_personne = op.id_personne AND op.role_personne = 'Det'
INNER JOIN occtax.organisme o ON o.id_organisme = p.id_organisme
;


CREATE OR REPLACE VIEW occtax.v_observateur AS
SELECT
CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE p.identite END AS identite,
CASE WHEN p.anonymiser IS TRUE THEN '' ELSE p.mail END AS mail,
CASE WHEN p.anonymiser IS TRUE OR lower(p.identite) = lower(nom_organisme) THEN NULL ELSE Coalesce(nom_organisme, 'INCONNU') END AS organisme,
op.id_personne, op.cle_obs, p.prenom, p.nom, p.anonymiser,
p.identite AS identite_non_floutee,
p.mail AS mail_non_floute,
Coalesce(nom_organisme, 'INCONNU') AS organisme_non_floute

FROM occtax.observation_personne op
INNER JOIN occtax.personne p ON p.id_personne = op.id_personne AND op.role_personne = 'Obs'
INNER JOIN occtax.organisme o ON o.id_organisme = p.id_organisme
;


-- taxon et stats
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


DROP MATERIALIZED VIEW IF EXISTS stats.chiffres_cles;
CREATE MATERIALIZED VIEW stats.chiffres_cles AS
  SELECT 1 AS ordre,
    'Nombre total de données' AS libelle,
    count(vm_observation.cle_obs) AS valeur
   FROM occtax.vm_observation
UNION
 SELECT 2 AS ordre,
    'Nombre total de jeux de données' AS libelle,
    count(DISTINCT vm_observation.jdd_code) AS valeur
   FROM occtax.vm_observation
UNION
 SELECT 3 AS ordre,
    'Nombre de producteurs ayant transmis des jeux de données' AS libelle,
    count(DISTINCT r.id_organisme) AS valeur
   FROM ( SELECT jdd.jdd_id,
            (jsonb_array_elements(jdd.ayants_droit) ->> 'id_organisme'::text)::integer AS id_organisme,
            jsonb_array_elements(jdd.ayants_droit) ->> 'role'::text AS role
           FROM occtax.jdd) r
UNION
 SELECT 4 AS ordre,
    'Nombre d''observateurs cités' AS libelle,
    count(DISTINCT p.nom || p.prenom) AS valeur
   FROM occtax.observation_personne op
     LEFT JOIN occtax.personne p USING (id_personne)
UNION
 SELECT 5 AS ordre,
    'Nombre de taxons faisant l''objet d''observations' AS libelle,
    count(DISTINCT vm_observation.cd_ref) AS valeur
   FROM occtax.vm_observation
UNION
 SELECT 6 AS ordre,
    'Nombre d''adhérents à la charte régionale SINP' AS libelle,
    count(ga.id_adherent) AS valeur
   FROM gestion.adherent ga
  WHERE ga.statut = 'Adhérent'
UNION
 SELECT 7 AS ordre,
    'Nombre de demandes d''accès aux données ouvertes' AS libelle,
    count(gd.id) AS valeur
   FROM gestion.demande gd
  WHERE gd.statut ~~* 'acceptée'
ORDER BY ordre
;
COMMENT ON MATERIALIZED VIEW stats.chiffres_cles IS 'Divers chiffres clés traduisant l''activité du SINP';


DROP MATERIALIZED VIEW IF EXISTS stats.liste_jdd;
CREATE MATERIALIZED VIEW stats.liste_jdd AS
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
    LEFT JOIN taxon.taxref_valide t USING (cd_ref)
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


