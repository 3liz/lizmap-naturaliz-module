-- observation
-- Ajout du champ cd_nom_cite
ALTER TABLE occtax.observation ADD COLUMN cd_nom_cite BIGINT ;
COMMENT ON COLUMN occtax.observation.cd_nom_cite IS 'Code du taxon « cd_nom » de TaxRef référençant au niveau national le taxon tel qu''il a été initialement cité par l''observateur dans le champ nom_cite. Le rang taxinomique de la donnée doit être celui de la donnée d''origine. Par défaut, cd_nom = cd_nom_cite. cd_nom peut être modifié dans le cas de la procédure de validation après accord du producteur selon les règles définies dans le protocole régional de validation.' ;

-- On met à jour par défaut le champ cd_nom_cite pour les observations déjà rentrées
UPDATE occtax.observation SET cd_nom_cite = cd_nom ;

-- Ajout du champ nom_retenu
ALTER TABLE occtax.validation_observation ADD COLUMN nom_retenu TEXT ;
COMMENT ON COLUMN occtax.validation_observation.nom_retenu IS 'Nom scientifique du taxon attribué par le validateur, dans le cas où ce taxon est différent du taxon cité initialement par l''observateur (sinon le champ reste NULL). Cela peut arriver en cas d''identification erronnée par l''observateur, ou bien lorsque le validateur valide l''observation au niveau d''un parent taxonomique. Le champ n''a toutefois pas vocation à stocker un nom qui serait synonyme de celui cité par l''observateur, Taxref permettant déjà de traiter les cas de synonymie.' ;



-- jdd
ALTER TABLE occtax.jdd ADD COLUMN jdd_libelle text;
COMMENT ON COLUMN occtax.jdd.jdd_libelle IS 'Libellé court et intelligible du jeu de données';
UPDATE occtax.jdd SET jdd_libelle = concat(jdd_id, ' - ', jdd_code) WHERE jdd_libelle IS NULL;
ALTER TABLE occtax.jdd ADD COLUMN date_minimum_de_diffusion date;
COMMENT ON COLUMN occtax.jdd.date_minimum_de_diffusion IS 'Pour les données de recherche, les producteurs peuvent attendre que la publication scientifique soit publiée avant de diffuser les données. Cette date est utilisée dans le requête de création de la vue matérialisée occtax.vm_observation pour ne pas prendre en compte les données dont la date minimum n''est pas atteinte';

DROP MATERIALIZED VIEW IF EXISTS occtax.vm_observation CASCADE;
CREATE MATERIALIZED VIEW occtax.vm_observation AS
WITH s AS (
    SELECT
    o.cle_obs,
    jsonb_agg(DISTINCT lm01.code_maille) AS code_maille_01,
    min(lm01.code_maille) AS code_maille_01_unique,
    jsonb_agg(DISTINCT lm02.code_maille) AS code_maille_02,
    min(lm02.code_maille) AS code_maille_02_unique,
    jsonb_agg(DISTINCT lm10.code_maille) AS code_maille_10,
    min(lm10.code_maille) AS code_maille_10_unique,
    jsonb_agg(DISTINCT lc.code_commune) AS code_commune,
    min(lc.code_commune) AS code_commune_unique,
    jsonb_agg(DISTINCT ld.code_departement) AS code_departement,
    jsonb_agg(DISTINCT lme.code_me) AS code_me,
    jsonb_agg(DISTINCT len.code_en) AS code_en,
    jsonb_agg(DISTINCT len.type_en) AS type_en,

    string_agg( DISTINCT concat(
        pobs.identite,
        CASE
            WHEN pobs.organisme IS NULL OR pobs.organisme = '' THEN ''
            ELSE ' (' || pobs.organisme|| ')'
        END
    ), ', ' ) AS identite_observateur,
    string_agg( DISTINCT concat(
        pobs.identite_non_floutee,
        CASE
            WHEN pobs.organisme_non_floute IS NULL OR pobs.organisme_non_floute = '' THEN ''
            ELSE ' (' || pobs.organisme_non_floute|| ')'
        END,
        ' - ' || pobs.mail_non_floute
    ), ', ' ) AS identite_observateur_non_floute,
    string_agg( DISTINCT concat(
        pval.identite,
        CASE
            WHEN pval.organisme IS NULL OR pval.organisme = '' THEN ''
            ELSE ' (' || pval.organisme|| ')'
        END
    ), ', ' ) AS validateur,
    string_agg( DISTINCT concat(
        pdet.identite,
        CASE
            WHEN pdet.organisme IS NULL OR pdet.organisme = '' THEN ''
            ELSE ' (' || pdet.organisme|| ')'
        END
    ), ', ' ) AS determinateur,
    string_agg( DISTINCT concat(
        pdet.identite_non_floutee,
        CASE
            WHEN pdet.organisme_non_floute IS NULL OR pdet.organisme_non_floute = '' THEN ''
            ELSE ' (' || pdet.organisme_non_floute|| ')'
        END,
        ' - ' || pdet.mail_non_floute
    ), ', ' ) AS determinateur_non_floute

    FROM occtax."observation"  AS o
    LEFT JOIN occtax."v_observateur"  AS pobs  ON pobs.cle_obs = o.cle_obs
    LEFT JOIN occtax."v_validateur"  AS pval  ON pval.identifiant_permanent = o.identifiant_permanent
    LEFT JOIN occtax."v_determinateur"  AS pdet  ON pdet.cle_obs = o.cle_obs
    LEFT JOIN occtax."localisation_maille_01"  AS lm01  ON lm01.cle_obs = o.cle_obs
    LEFT JOIN occtax."localisation_maille_02"  AS lm02  ON lm02.cle_obs = o.cle_obs
    LEFT JOIN occtax."localisation_maille_10"  AS lm10  ON lm10.cle_obs = o.cle_obs
    LEFT JOIN occtax."localisation_commune"  AS lc  ON lc.cle_obs = o.cle_obs
    LEFT JOIN occtax."localisation_departement"  AS ld  ON ld.cle_obs = o.cle_obs
    LEFT JOIN occtax."localisation_masse_eau"  AS lme  ON lme.cle_obs = o.cle_obs
    LEFT JOIN occtax."v_localisation_espace_naturel"  AS len  ON len.cle_obs = o.cle_obs

    WHERE True
    GROUP BY o.cle_obs
)
SELECT
o.cle_obs,
o.identifiant_permanent,
o.statut_observation,
o.cd_nom,
o.cd_ref,
o.version_taxref,
o.nom_cite,
t.nom_valide, t.reu AS loc, trim(t.nom_vern) AS nom_vern, t.group1_inpn, t.group2_inpn, t.ordre, t.famille, t.protection, tv.url,
(regexp_split_to_array( Coalesce( tgc1.cat_nom, tgc2.cat_nom, 'Autres' ), ' '))[1] AS categorie,
trim(tv.lb_nom, ' ,\t') AS lb_nom_valide, trim(tv.nom_vern, ' ,\t') AS nom_vern_valide,
t.menace, t.rang, t.habitat, t.statut, t.endemicite, t.invasibilite,
o.denombrement_min,
o.denombrement_max,
o.objet_denombrement,
o.type_denombrement,
o.commentaire,
o.date_debut,
o.heure_debut,
o.date_fin,
o.heure_fin,
o.date_determination,
o.altitude_min,
o.altitude_moy,
o.altitude_max,
o.profondeur_min,
o.profondeur_moy,
o.profondeur_max,
o.code_idcnp_dispositif,
o.dee_date_derniere_modification,
o.dee_date_transformation,
o.dee_floutage,
o.diffusion_niveau_precision,
o.ds_publique,
o.identifiant_origine,
o.jdd_code,
o.jdd_id,
o.jdd_metadonnee_dee_id,
o.jdd_source_id,
o.organisme_gestionnaire_donnees,
o.organisme_standard,
o.org_transformation,
o.statut_source,
o.reference_biblio,
o.sensible,
o.sensi_date_attribution,
o.sensi_niveau,
o.sensi_referentiel,
o.sensi_version_referentiel,
o.descriptif_sujet AS descriptif_sujet,
o.validite_niveau,
o.validite_date_validation,
o.precision_geometrie,
o.nature_objet_geo,
o.geom,
CASE
    WHEN o.geom IS NOT NULL THEN
        CASE
            WHEN GeometryType(geom) IN ('POLYGON', 'MULTIPOLYGON') THEN 'Polygone'
            WHEN GeometryType(geom) IN ('LINESTRING', 'MULTILINESTRING') THEN 'Ligne'
            WHEN GeometryType(geom) IN ('POINT', 'MULTIPOINT') THEN 'Point'
            ELSE 'Géométrie'
        END
    WHEN s.code_maille_10 IS NOT NULL THEN 'M10'
    WHEN s.code_commune IS NOT NULL THEN 'COM'
    WHEN s.code_me IS NOT NULL THEN 'ME'
    WHEN s.code_en IS NOT NULL THEN 'EN'
    WHEN s.code_departement IS NOT NULL THEN 'DEP'
    ELSE 'NO'
END AS source_objet,

s.code_maille_01,
s.code_maille_01_unique,
s.code_maille_02,
s.code_maille_02_unique,
s.code_maille_10,
s.code_maille_10_unique,
s.code_commune,
s.code_commune_unique,
s.code_departement,
s.code_me,
s.code_en,
s.type_en,
od.diffusion,
s.identite_observateur,
s.identite_observateur_non_floute,
s.validateur,
s.determinateur,
s.determinateur_non_floute
FROM occtax.observation o
INNER JOIN s ON s.cle_obs = o.cle_obs
INNER JOIN  occtax."observation_diffusion"  AS od  ON od.cle_obs = o.cle_obs
LEFT JOIN taxon."taxref_consolide_non_filtre" AS t ON t.cd_nom = o.cd_nom
LEFT JOIN taxon."taxref_consolide_non_filtre" AS tv ON tv.cd_nom = tv.cd_ref AND tv.cd_nom = t.cd_ref
LEFT JOIN taxon."t_group_categorie" AS tgc1  ON tgc1.groupe_nom = t.group1_inpn AND tgc1.groupe_type = 'group1_inpn'
LEFT JOIN taxon."t_group_categorie" AS tgc2  ON tgc2.groupe_nom = t.group2_inpn AND tgc2.groupe_type = 'group2_inpn'
LEFT JOIN occtax."jdd" ON jdd.jdd_id = o.jdd_id
WHERE TRUE
AND (jdd.date_minimum_de_diffusion IS NULL OR jdd.date_minimum_de_diffusion <= now() )
;


CREATE INDEX vm_observation_cle_obs_idx ON occtax.vm_observation (cle_obs);
CREATE INDEX vm_observation_identifiant_permanent_idx ON occtax.vm_observation (identifiant_permanent);
CREATE INDEX vm_observation_geom_idx ON occtax.vm_observation USING GIST (geom);
CREATE INDEX vm_observation_cd_ref_idx ON occtax.vm_observation (cd_ref);
CREATE INDEX vm_observation_cd_nom_idx ON occtax.vm_observation (cd_nom);
CREATE INDEX vm_observation_group1_inpn_idx ON occtax.vm_observation (group1_inpn);
CREATE INDEX vm_observation_group2_inpn_idx ON occtax.vm_observation (group2_inpn);
CREATE INDEX vm_observation_categorie_idx ON occtax.vm_observation (categorie);
CREATE INDEX vm_observation_jdd_id_idx ON occtax.vm_observation (jdd_id);
CREATE INDEX vm_observation_validite_niveau_idx ON occtax.vm_observation (validite_niveau);
CREATE INDEX vm_observation_date_debut_date_fin_idx ON occtax.vm_observation USING btree (date_debut, date_fin DESC);
CREATE INDEX vm_observation_descriptif_sujet_idx ON occtax.vm_observation USING GIN (descriptif_sujet);
CREATE INDEX vm_observation_code_commune_idx ON occtax.vm_observation USING GIN (code_commune);
CREATE INDEX vm_observation_code_maille_01_idx ON occtax.vm_observation USING GIN (code_maille_01);
CREATE INDEX vm_observation_code_maille_02_idx ON occtax.vm_observation USING GIN (code_maille_02);
CREATE INDEX vm_observation_code_maille_01_unique_idx ON occtax.vm_observation (code_maille_01_unique);
CREATE INDEX vm_observation_code_maille_02_unique_idx ON occtax.vm_observation (code_maille_02_unique);
CREATE INDEX vm_observation_code_maille_10_unique_idx ON occtax.vm_observation (code_maille_10_unique);
CREATE INDEX vm_observation_diffusion_idx ON occtax.vm_observation USING GIN (diffusion);

-- VUES POUR LES STATISTIQUES
-- nb_observations_par_groupe_taxonomique
DROP VIEW IF EXISTS occtax.vm_stat_nb_observations_par_groupe_taxonomique;
CREATE VIEW occtax.vm_stat_nb_observations_par_groupe_taxonomique AS
SELECT
row_number() OVER () AS id, categorie,
Count(o.cle_obs) AS nbobs
FROM occtax.vm_observation o
GROUP BY categorie
ORDER BY categorie
;

-- nb_taxons_presents
DROP VIEW IF EXISTS occtax.vm_stat_nb_taxons_observes_par_groupe_taxonomique;
CREATE VIEW occtax.vm_stat_nb_taxons_observes_par_groupe_taxonomique AS
SELECT row_number() OVER () AS id, categorie,
Count(DISTINCT o.cd_ref) AS nb_taxon_present
FROM occtax.vm_observation o
GROUP BY categorie
ORDER BY categorie
;

-- STATS
--
CREATE SCHEMA IF NOT EXISTS stats;

-- repartition_temporelle
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.repartition_temporelle AS
WITH stat as (
  SELECT
    EXTRACT(YEAR FROM date_debut)::INTEGER AS annee,
    count(DISTINCT cle_obs) AS nb_donnees
  FROM occtax.vm_observation
  GROUP BY EXTRACT(YEAR FROM date_debut)
  ORDER BY EXTRACT(YEAR FROM date_debut)
)
SELECT
  serie.annee,
  COALESCE(stat.nb_donnees,0) AS nb_donnees
FROM
  (SELECT generate_series(
            (SELECT min(stat.annee) FROM stat),
            (SELECT max(stat.annee) FROM stat)
            ) AS annee
  ) AS serie
LEFT JOIN stat ON stat.annee=serie.annee
ORDER BY serie.annee
;

COMMENT ON MATERIALIZED VIEW stats.repartition_temporelle IS 'Répartition des données par année d''observation';

-- repartition_habitats
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.repartition_habitats AS
SELECT n.code, COALESCE(n.valeur, 'Non renseigné par Taxref') AS habitat,
  count(cle_obs) AS nb_donnees
FROM occtax.vm_observation o
LEFT JOIN taxon.t_nomenclature n ON n.code=o.habitat::TEXT AND n.champ='habitat'
GROUP BY n.code, o.habitat, COALESCE(n.valeur, 'Non renseigné par Taxref')
ORDER BY count(o.cd_ref) DESC
;

COMMENT ON MATERIALIZED VIEW stats.repartition_habitats IS 'Répartition des observations par grand milieu de vie du taxon';

-- connaissance_par_groupe_taxonomique
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.connaissance_par_groupe_taxonomique AS
SELECT CONCAT(
                COALESCE(o.group2_inpn, 'Non renseigné par Taxref'),
                ' (n=',
                stat_taxref.nb_taxons_taxref,
                ')'
            ) AS group2_inpn,
((count(DISTINCT o.cd_ref::NUMERIC)/stat_taxref.nb_taxons_taxref::NUMERIC)*100)::NUMERIC(4,1) AS nb_taxons_observes,
(((stat_taxref.nb_taxons_taxref - count(DISTINCT o.cd_ref))::NUMERIC/stat_taxref.nb_taxons_taxref::NUMERIC)*100)::NUMERIC(4,1) AS manque_taxref,
stat_taxref.nb_taxons_taxref AS total_taxref
FROM occtax.vm_observation o
LEFT JOIN ( SELECT group2_inpn, count(DISTINCT cd_ref) AS nb_taxons_taxref
      FROM taxon.taxref
      -- on ne prend que les espèces et sous-espèces des taxons présents ou ayant été présents à La Réunion
      WHERE {$colonne_locale} IS NOT NULL AND {$colonne_locale} NOT IN ('Q','A') AND rang IN ('ES', 'SSES')
      GROUP BY group2_inpn
      ) stat_taxref ON stat_taxref.group2_inpn=o.group2_inpn
WHERE o.rang IN ('ES', 'SSES')
GROUP BY COALESCE(o.group2_inpn, 'Non renseigné par Taxref'), stat_taxref.nb_taxons_taxref
ORDER BY (count(DISTINCT o.cd_ref)::NUMERIC/stat_taxref.nb_taxons_taxref::NUMERIC)::NUMERIC(3,2) DESC
;

COMMENT ON MATERIALIZED VIEW stats.connaissance_par_groupe_taxonomique IS 'Estimation du degré de connaissance de chaque groupe taxonomique. Pour chaque groupe est calculé le pourcentage d''espèces connues (ie faisant l''objet d''au moins une observation dans Taxref) et le pourcentage d''espèces inconnues (ie indiquées comme présentes dans Taxref mais ne faisant pas encore l''objet d''observation dans Borbonica';

-- nombre_taxons
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.nombre_taxons AS
SELECT COALESCE(o.group2_inpn, 'Non renseigné par Taxref') AS group2_inpn,
  count(DISTINCT cd_ref) AS nb_taxons
FROM occtax.vm_observation o
GROUP BY COALESCE(o.group2_inpn, 'Non renseigné par Taxref')
ORDER BY count(o.cd_ref) DESC
;

COMMENT ON MATERIALIZED VIEW stats.nombre_taxons IS 'Nombre de taxons observés par groupe taxonomique';

-- repartition_groupe_taxonomique
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.repartition_groupe_taxonomique AS
SELECT COALESCE(o.group2_inpn, 'Non renseigné par Taxref') AS group2_inpn,
  count(o.cle_obs) AS nb_donnees
FROM occtax.vm_observation o
GROUP BY COALESCE(o.group2_inpn, 'Non renseigné par Taxref')
ORDER BY count(o.cd_ref) DESC
;

COMMENT ON MATERIALIZED VIEW stats.repartition_groupe_taxonomique IS 'Nombre d''observations par groupe taxonomique';

-- observations_par_maille_02
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.observations_par_maille_02 AS
SELECT
id_maille, code_maille AS mid, nom_maille AS maille,
count(o.cle_obs) AS nbobs,
count(DISTINCT o.cd_ref) AS nbtax,
m.geom
FROM sig.maille_02 m
INNER JOIN occtax.vm_observation o ON m.code_maille = code_maille_02_unique
GROUP BY id_maille
;

COMMENT ON MATERIALIZED VIEW stats.observations_par_maille_02 IS 'Nombre d''observations et de taxons par mailles de 2km de côté';


-- avancement_imports
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.avancement_imports AS
WITH r AS (
    SELECT LEFT((date_trunc('month', serie.date))::TEXT, 7) AS mois,
    count(DISTINCT jdd_id) AS nb_jdd,
    count(DISTINCT cle_obs) AS nb_obs
    FROM
      (SELECT generate_series(
        (SELECT min(dee_date_transformation) FROM occtax.vm_observation),
        now(),
        '1 month') date) serie
    LEFT JOIN occtax.vm_observation o ON date_trunc('month', serie.date)=date_trunc('month', o.dee_date_transformation)
    GROUP BY date_trunc('month', serie.date)
    ORDER BY date_trunc('month', serie.date)
          )

SELECT mois, sum(nb_jdd) OVER (ORDER BY mois) AS nb_jdd, sum(nb_obs) OVER (ORDER BY mois) AS nb_obs
FROM r ;

COMMENT ON MATERIALIZED VIEW stats.avancement_imports IS 'Nombre cumulé de données et de jeux de données importés dans Borbonica au fil du temps, traduisant la dynamique d''import dans Borbonica';

-- nombre_obs_par_menace
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.nombre_obs_par_menace AS
SELECT COALESCE(n.ordre,0) AS ordre,
  COALESCE(n.code, 'NE') AS code_menace,
  COALESCE(n.valeur, 'Non évaluée') AS menace,
  CASE COALESCE(n.code, 'NE')
    WHEN 'EX' THEN 'C0/M0/J0/N100'
    WHEN 'EW' THEN 'C80/M100/J20/N40'
    WHEN 'RE' THEN 'C70/M100/J10/N25'
    WHEN 'CR' THEN 'C5/M100/J100/N5'
    WHEN 'EN' THEN 'C0/M28/J100/N0'
    WHEN 'VU' THEN 'C0/M0/J98/N0'
    WHEN 'NT' THEN 'C3/M3/J27/N0'
    WHEN 'LC' THEN 'C60/M0/J85/N0'
    WHEN 'DD' THEN 'C0/M0/J0/N23'
    WHEN 'NA' THEN 'C25/M21/J0/N0'
    WHEN 'NE' THEN 'C65/M54/J0/N0'
  END AS couleur_cmjn,
  CASE COALESCE(n.code, 'NE')
    WHEN 'EX' THEN 'R0/V0/B0'
    WHEN 'EW' THEN 'R61/V25/B81'
    WHEN 'RE' THEN 'R90/V26/B99'
    WHEN 'CR' THEN 'R211/V0/B27'
    WHEN 'EN' THEN 'R251/V191/B0'
    WHEN 'VU' THEN 'R255/V237/B0'
    WHEN 'NT' THEN 'R251/V242/B202'
    WHEN 'LC' THEN 'R120/V183/B74'
    WHEN 'DD' THEN 'R211/V212/B213'
    WHEN 'NA' THEN 'R191/V202/B255'
    WHEN 'NE' THEN 'R89/V117/B255'
  END AS couleur_rvb,
  CASE COALESCE(n.code, 'NE')
    WHEN 'EX' THEN 'rgb(0,0,0)'
    WHEN 'EW' THEN 'rgb(61,25,81)'
    WHEN 'RE' THEN 'rgb(90,26,99)'
    WHEN 'CR' THEN 'rgb(211,0,27)'
    WHEN 'EN' THEN 'rgb(251,191,0)'
    WHEN 'VU' THEN 'rgb(255,237,0)'
    WHEN 'NT' THEN 'rgb(251,242,202)'
    WHEN 'LC' THEN 'rgb(120,183,74)'
    WHEN 'DD' THEN 'rgb(211,212,213)'
    WHEN 'NA' THEN 'rgb(191,202,255)'
    WHEN 'NE' THEN 'rgb(89,117,255)'
  END AS couleur_html,
  count(DISTINCT o.cle_obs) AS nb_obs
FROM occtax.vm_observation o
LEFT JOIN taxon.t_nomenclature n ON n.code::TEXT=o.menace::TEXT AND n.champ='menace'
GROUP BY n.code, n.ordre, COALESCE(n.valeur, 'Non évaluée')
ORDER BY COALESCE(n.ordre,0) DESC
;

COMMENT ON MATERIALIZED VIEW stats.nombre_obs_par_menace IS 'nombre d''observations par niveau de menace UICN de taxon';

-- nombre_taxons_par_menace
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.nombre_taxons_par_menace AS
SELECT
  COALESCE(n.ordre,0) AS ordre,
  COALESCE(n.code, 'NE') AS code_menace,
  COALESCE(n.valeur, 'Non évaluée') AS menace,
  CASE COALESCE(n.code, 'NE')
    WHEN 'EX' THEN 'C0/M0/J0/N100'
    WHEN 'EW' THEN 'C80/M100/J20/N40'
    WHEN 'RE' THEN 'C70/M100/J10/N25'
    WHEN 'CR' THEN 'C5/M100/J100/N5'
    WHEN 'EN' THEN 'C0/M28/J100/N0'
    WHEN 'VU' THEN 'C0/M0/J98/N0'
    WHEN 'NT' THEN 'C3/M3/J27/N0'
    WHEN 'LC' THEN 'C60/M0/J85/N0'
    WHEN 'DD' THEN 'C0/M0/J0/N23'
    WHEN 'NA' THEN 'C25/M21/J0/N0'
    WHEN 'NE' THEN 'C65/M54/J0/N0'
  END AS couleur_cmjn,
  CASE COALESCE(n.code, 'NE')
    WHEN 'EX' THEN 'R0/V0/B0'
    WHEN 'EW' THEN 'R61/V25/B81'
    WHEN 'RE' THEN 'R90/V26/B99'
    WHEN 'CR' THEN 'R211/V0/B27'
    WHEN 'EN' THEN 'R251/V191/B0'
    WHEN 'VU' THEN 'R255/V237/B0'
    WHEN 'NT' THEN 'R251/V242/B202'
    WHEN 'LC' THEN 'R120/V183/B74'
    WHEN 'DD' THEN 'R211/V212/B213'
    WHEN 'NA' THEN 'R191/V202/B255'
    WHEN 'NE' THEN 'R89/V117/B255'
  END AS couleur_rvb,
  CASE COALESCE(n.code, 'NE')
    WHEN 'EX' THEN 'rgb(0,0,0)'
    WHEN 'EW' THEN 'rgb(61,25,81)'
    WHEN 'RE' THEN 'rgb(90,26,99)'
    WHEN 'CR' THEN 'rgb(211,0,27)'
    WHEN 'EN' THEN 'rgb(251,191,0)'
    WHEN 'VU' THEN 'rgb(255,237,0)'
    WHEN 'NT' THEN 'rgb(251,242,202)'
    WHEN 'LC' THEN 'rgb(120,183,74)'
    WHEN 'DD' THEN 'rgb(211,212,213)'
    WHEN 'NA' THEN 'rgb(191,202,255)'
    WHEN 'NE' THEN 'rgb(89,117,255)'
  END AS couleur_html,
  count(DISTINCT o.cd_ref) AS nb_taxons
FROM occtax.vm_observation o
LEFT JOIN taxon.t_nomenclature n ON n.code::TEXT=o.menace::TEXT AND n.champ='menace'
GROUP BY n.code, n.ordre, COALESCE(n.valeur, 'Non évaluée')
ORDER BY COALESCE(n.ordre,0) DESC
;

COMMENT ON MATERIALIZED VIEW stats.nombre_taxons_par_menace IS 'Nombre de taxons par niveau de menace UICN de taxon';

-- chiffres_cles
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.chiffres_cles AS
SELECT 1 AS ordre,
    'Nombre total de données' AS libelle,
    count(cle_obs) AS valeur
FROM occtax.vm_observation

UNION
SELECT 2 AS ordre,
    'Nombre total de jeux de données' AS libelle,
    count(DISTINCT jdd_code) AS valeur
FROM occtax.vm_observation

UNION
SELECT 3 AS ordre,
    'Nombre de producteurs ayant transmis des jeux de données' AS libelle,
    count(DISTINCT r.id_organisme) AS valeur
FROM (
    SELECT  jdd_id,
            (jsonb_array_elements(ayants_droit)->>'id_organisme')::INTEGER AS id_organisme,
            jsonb_array_elements(ayants_droit)->>'role' AS role
    FROM occtax.jdd
    ) r

UNION
SELECT 4 AS ordre,
    'Nombre d''observateurs cités' AS libelle,
    count(DISTINCT op.id_personne) AS valeur
FROM occtax.observation_personne op

UNION
SELECT 5 AS ordre,
    'Nombre de taxons faisant l''objet d''observations' AS libelle,
    count(DISTINCT cd_ref) AS valeur
FROM occtax.vm_observation


UNION
SELECT 6 AS ordre,
    'Nombre d''adhérents à la charte régionale SINP' AS libelle,
    count(id_adherent) AS valeur
FROM gestion.adherent
WHERE statut='Adhérent'

UNION
SELECT 7 AS ordre,
    'Nombre de demandes d''accès aux données ouvertes' AS libelle,
    count(id) AS valeur
FROM gestion.demande
WHERE statut ilike 'acceptée'

ORDER BY ordre
;

COMMENT ON MATERIALIZED VIEW stats.chiffres_cles IS 'Divers chiffres clés traduisant l''activité du SINP';

-- rangs_taxonomiques
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.rangs_taxonomiques AS
SELECT CASE o.rang
      WHEN 'SSES' THEN 'Sous-espèce'
      WHEN 'ES' THEN 'Espèce'
      WHEN 'GN' THEN 'Genre'
      WHEN 'FM' THEN 'Famille'
      WHEN 'OR' THEN 'Ordre'
      WHEN 'VAR' THEN 'Variété'
      WHEN NULL THEN 'Non renseigné par Taxref'
      ELSE 'Autre'
    END AS rang,
  count(cle_obs) AS nb_donnees
FROM occtax.vm_observation o
GROUP BY CASE o.rang
      WHEN 'SSES' THEN 'Sous-espèce'
      WHEN 'ES' THEN 'Espèce'
      WHEN 'GN' THEN 'Genre'
      WHEN 'FM' THEN 'Famille'
      WHEN 'OR' THEN 'Ordre'
      WHEN 'VAR' THEN 'Variété'
      WHEN NULL THEN 'Non renseigné par Taxref'
      ELSE 'Autre'
    END
ORDER BY count(o.cd_ref) DESC
;

COMMENT ON MATERIALIZED VIEW stats.rangs_taxonomiques IS 'Nombre d''observations par rang du taxon';

-- nombre_taxons_par_statut_biogeographique
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.nombre_taxons_par_statut_biogeographique AS
SELECT concat_ws( ' - ', o.loc, COALESCE(n.valeur, 'Non renseigné par Taxref')) AS loc,
  count(DISTINCT o.cd_ref) AS nb_taxons
FROM occtax.vm_observation o
LEFT JOIN taxon.t_nomenclature n ON n.code::TEXT=o.loc::TEXT AND n.champ='statut_taxref'
GROUP BY concat_ws( ' - ', o.loc, COALESCE(n.valeur, 'Non renseigné par Taxref'))
ORDER BY count(o.cd_ref) DESC
;

COMMENT ON MATERIALIZED VIEW stats.nombre_taxons_par_statut_biogeographique IS 'nombre de taxons par statut biogéographique (selon Taxref)';

-- nombre_obs_par_statut_biogeographique
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.nombre_obs_par_statut_biogeographique AS
SELECT concat_ws( ' - ', o.loc, COALESCE(n.valeur, 'Non renseigné par Taxref')) AS loc,
  count(DISTINCT cle_obs) AS nb_obs
FROM occtax.vm_observation o
LEFT JOIN taxon.t_nomenclature n ON n.code::TEXT=o.loc::TEXT AND n.champ='statut_taxref'
GROUP BY concat_ws( ' - ', o.loc, COALESCE(n.valeur, 'Non renseigné par Taxref'))
ORDER BY count(o.cle_obs) DESC
;

COMMENT ON MATERIALIZED VIEW stats.nombre_obs_par_statut_biogeographique IS 'nombre d''observations par statut biogéographique (selon Taxref)';

-- Liste des taxons observés
DROP MATERIALIZED VIEW IF EXISTS stats.liste_taxons_observes;
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.liste_taxons_observes AS
SELECT o.cd_ref, t.lb_nom, t.nom_vern, t.group2_inpn, t.{$colonne_locale} AS loc, t.rang,
m.valeur AS menace_uicn,
count(o.cle_obs) AS nb_observations,
max(EXTRACT(YEAR FROM COALESCE(o.date_fin, o.date_debut))) AS annee_derniere_obs,
string_agg(DISTINCT jdd.jdd_description, ' | ' ORDER BY jdd.jdd_description) AS liste_jdd,
t.url AS fiche_taxon
FROM occtax.observation o
LEFT JOIN (
    SELECT cd_ref, lb_nom, nom_vern, group2_inpn, {$colonne_locale}, rang, url, menace
    FROM taxon.taxref_consolide_non_filtre
    WHERE cd_nom=cd_ref
        )t USING(cd_ref)
LEFT JOIN (SELECT * FROM taxon.t_nomenclature WHERE champ='menace')m ON m.code=t.menace
LEFT JOIN occtax.jdd USING(jdd_code)
GROUP BY o.cd_ref, t.lb_nom, t.nom_vern, t.group2_inpn, t.{$colonne_locale}, t.rang, m.valeur, t.url
ORDER BY count(o.cle_obs) DESC ;

COMMENT ON MATERIALIZED VIEW stats.liste_taxons_observes IS 'Liste des taxons faisant l''objet d''au moins une observation dans Borbonica et statuts associés' ;


DROP VIEW IF EXISTS occtax.v_observation_validation CASCADE;
CREATE VIEW occtax.v_observation_validation AS (
SELECT o.cle_obs,
o.identifiant_permanent,
o.statut_observation,
o.cd_nom,
o.cd_ref,
o.nom_cite,
o.nom_valide,
o.loc,
o.nom_vern,
o.group2_inpn,
o.ordre,
o.famille,
o.lb_nom_valide,
o.nom_vern_valide,
o.denombrement_min,
o.denombrement_max,
o.objet_denombrement,
o.type_denombrement,
o.descriptif_sujet,
-- Preuve existante: on cherche dans descriptif_sujet. Si au moins une preuve n'est pas oui, on met Non
CASE
    WHEN descriptif_sujet IS NULL OR descriptif_sujet::text ~* '"preuve_existante": ((")?(0|2|3)(")?|null)'
        THEN 'Non'
    ELSE 'Oui'
END AS preuve_existante,
o.date_determination,
o.date_debut,
o.date_fin,
o.heure_debut,
o.heure_fin,
o.geom,
o.altitude_moy,
o.precision_geometrie,
o.nature_objet_geo,
o.identite_observateur_non_floute,
o.determinateur_non_floute,
o.organisme_gestionnaire_donnees,
o.commentaire,
o.code_idcnp_dispositif,
o.dee_date_transformation,
o.dee_date_derniere_modification,
o.jdd_code,
o.jdd_id,
o.jdd_metadonnee_dee_id,
o.statut_source,
o.reference_biblio,
o.ds_publique,
o.diffusion_niveau_precision,
o.sensi_niveau,
v.id_validation,
v.date_ctrl,
v.niv_val,
v.typ_val,
v.ech_val,
v.peri_val,
v.val_validateur AS validateur,
v.proc_vers,
v.producteur,
v.date_contact,
v.procedure,
v.proc_ref,
v.comm_val,
-- on doit stocker les informations relatives à la validation producteur :
CASE
    WHEN vprod.id_validation IS NOT NULL
        THEN concat('Niveau de validité attribué le ', vprod.date_ctrl::TEXT, ' par ', vprod.val_validateur ,  ' : ', vprod.valeur, '.', vprod.comm_val)
    ELSE NULL
END AS validation_producteur,
v.nom_retenu
FROM vm_observation o
LEFT JOIN (
    SELECT vv.*,
    identite || concat(' - ' || mail, ' (' || o.nom_organisme || ')' ) AS val_validateur
    FROM validation_observation vv
    LEFT JOIN personne p ON vv.validateur = p.id_personne
    LEFT JOIN organisme o ON p.id_organisme = o.id_organisme
    WHERE ech_val = '2' -- uniquement validation de niveau régional
) v USING (identifiant_permanent)
-- jointure pour avoir les informations relatives à la validation producteur
LEFT JOIN (
    SELECT vv.*,
    n.valeur,
    identite || concat(' - ' || mail, ' (' || o.nom_organisme || ')' ) AS val_validateur
    FROM validation_observation vv
    LEFT JOIN personne p ON vv.validateur = p.id_personne
    LEFT JOIN organisme o ON p.id_organisme = o.id_organisme
    LEFT JOIN occtax.nomenclature n ON n.champ='niv_val_mancom' AND n.code=vv.niv_val
    WHERE vv.ech_val = '1' -- uniquement validation producteur
) vprod USING (identifiant_permanent)
)
;

-- gestion
ALTER TABLE gestion.echange_inpn ADD COLUMN liste_identifiant_permanent TEXT[] ;
COMMENT ON COLUMN gestion.echange_inpn.liste_identifiant_permanent IS 'Liste des identifiants permanents des observations transmises lors de l''échange de données. Ce champ est destiné à faciliter la traçabilité des données, afin notamment de ne pas exporter deux fois les mêmes données et de pouvoir transmettre à nouveau des observations qui auraient été modifiées (notamment validées) depuis le dernier échange.';


-- fonction occtax_update_spatial_relationships
CREATE OR REPLACE FUNCTION occtax.occtax_update_spatial_relationships(jdd_id text[])
  RETURNS integer AS
$BODY$
DECLARE sql_text TEXT;
DECLARE row_count_value INTEGER;
BEGIN

sql_text := '
-- -- localisation_commune
DELETE FROM occtax.localisation_commune
WHERE cle_obs IN (
    SELECT cle_obs FROM occtax.observation WHERE jdd_id = ANY ( $1 ) AND geom IS NOT NULL
);
INSERT INTO occtax.localisation_commune
SELECT DISTINCT
    o.cle_obs,
    c.code_commune,
    ''2'' AS type_info_geo
FROM occtax.observation o
INNER JOIN sig.commune c ON ST_Intersects( o.geom, c.geom )
WHERE 2>1
AND o.jdd_id = ANY ( $1 )
;

-- Départements
DELETE FROM occtax.localisation_departement
WHERE cle_obs IN (
    SELECT cle_obs FROM occtax.observation WHERE jdd_id = ANY ( $1 ) AND geom IS NOT NULL
);
INSERT INTO occtax.localisation_departement
SELECT DISTINCT
    o.cle_obs,
    d.code_departement,
    ''2'' AS type_info_geo
FROM occtax.observation o
INNER JOIN sig.departement d ON ST_Intersects( o.geom, d.geom )
WHERE 2>1
AND o.jdd_id = ANY ( $1 )
;

-- -- -- localisation_maille_10
DELETE FROM occtax.localisation_maille_10
WHERE cle_obs IN (
    SELECT cle_obs FROM occtax.observation WHERE jdd_id = ANY ( $1 ) AND geom IS NOT NULL
);
INSERT INTO occtax.localisation_maille_10
SELECT DISTINCT
    o.cle_obs,
    m.code_maille,
    ''2'' AS type_info_geo
FROM occtax.observation o
INNER JOIN sig.maille_10 m ON ST_Intersects( o.geom, m.geom )
WHERE 2>1
AND o.jdd_id = ANY ( $1 )
AND o.geom IS NOT NULL
;

-- -- -- localisation_maille_05
DELETE FROM occtax.localisation_maille_05
WHERE cle_obs IN (
    SELECT cle_obs FROM occtax.observation WHERE jdd_id = ANY ( $1 ) AND geom IS NOT NULL
);
INSERT INTO occtax.localisation_maille_05
SELECT DISTINCT
    o.cle_obs,
    m.code_maille,
    ''2'' AS type_info_geo
FROM occtax.observation o
INNER JOIN sig.maille_05 m ON ST_Intersects( o.geom, m.geom )
WHERE 2>1
AND o.jdd_id = ANY ( $1 )
AND o.geom IS NOT NULL
;

-- -- -- localisation_maille_02
DELETE FROM occtax.localisation_maille_02
WHERE cle_obs IN (
    SELECT cle_obs FROM occtax.observation WHERE jdd_id = ANY ( $1 ) AND geom IS NOT NULL
);
INSERT INTO occtax.localisation_maille_02
SELECT DISTINCT
    o.cle_obs,
    m.code_maille,
    ''2'' AS type_info_geo
FROM occtax.observation o
INNER JOIN sig.maille_02 m ON ST_Intersects( o.geom, m.geom )
WHERE 2>1
AND o.jdd_id = ANY ( $1 )
AND o.geom IS NOT NULL
;

-- -- -- localisation_maille_01
DELETE FROM occtax.localisation_maille_01
WHERE cle_obs IN (
    SELECT cle_obs FROM occtax.observation WHERE jdd_id = ANY ( $1 ) AND geom IS NOT NULL
);
INSERT INTO occtax.localisation_maille_01
SELECT DISTINCT
    o.cle_obs,
    m.code_maille,
    ''2'' AS type_info_geo
FROM occtax.observation o
INNER JOIN sig.maille_01 m ON ST_Intersects( o.geom, m.geom )
WHERE 2>1
AND o.jdd_id = ANY ( $1 )
AND o.geom IS NOT NULL
;

-- -- -- localisation_masse_eau
DELETE FROM occtax.localisation_masse_eau
WHERE cle_obs IN (
    SELECT cle_obs FROM occtax.observation WHERE jdd_id = ANY ( $1 ) AND geom IS NOT NULL
);
INSERT INTO occtax.localisation_masse_eau
SELECT DISTINCT
    o.cle_obs,
    m.code_me,
    ''2'' AS type_info_geo
FROM occtax.observation o
INNER JOIN sig.masse_eau m ON ST_Intersects( o.geom, m.geom )
WHERE 2>1
AND o.jdd_id = ANY ( $1 )
AND o.geom IS NOT NULL
;

-- -- -- localisation_espace_naturel
DELETE FROM occtax.localisation_espace_naturel
WHERE cle_obs IN (
    SELECT cle_obs FROM occtax.observation WHERE jdd_id = ANY ( $1 ) AND geom IS NOT NULL
);
INSERT INTO occtax.localisation_espace_naturel
SELECT DISTINCT
    o.cle_obs,
    en.code_en,
    ''2'' AS type_info_geo
FROM occtax.observation o
INNER JOIN sig.espace_naturel en ON ST_Intersects( o.geom, en.geom )
WHERE 2>1
AND o.jdd_id = ANY ( $1 )
AND o.geom IS NOT NULL
;

';

-- RAISE NOTICE '%s' , sql_text;

EXECUTE format(sql_text)
USING jdd_id;
RETURN 1;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



-- calcul niveau validation
CREATE OR REPLACE FUNCTION occtax.calcul_niveau_validation(
    p_jdd_id text[],
    p_validateur integer,
    p_simulation boolean)
  RETURNS integer AS
$BODY$
DECLARE sql_template TEXT;
DECLARE sql_text TEXT;
DECLARE useless INTEGER;
DECLARE procedure_ref_record RECORD;
BEGIN

    -- On vérifie qu'on a des données pour le référentiel de validation
    SELECT INTO procedure_ref_record
        "procedure", proc_vers, proc_ref
    FROM occtax.validation_procedure
    ORDER BY proc_vers DESC
    LIMIT 1;
    IF procedure_ref_record.proc_vers IS NULL THEN
        RAISE EXCEPTION '[naturaliz] La table validation_procedure est vide';
        RETURN 0;
    END IF;

    -- Remplissage de la table avec les valeurs issues des conditions
    SELECT occtax.calcul_niveau_par_condition(
        'validation',
        p_jdd_id
    ) INTO useless;

    -- UPDATE des observations qui rentrent dans les critères
    if p_simulation IS NOT TRUE THEN
        sql_template := '
        INSERT INTO occtax.validation_observation AS vo
        (
            identifiant_permanent,
            date_ctrl,
            niv_val,
            typ_val,
            ech_val,
            peri_val,
            comm_val,
            validateur,
            "procedure",
            proc_vers,
            proc_ref
        )
        SELECT
            t.identifiant_permanent,
            now(),
            t.niveau,
            ''A'',  -- automatique
            ''2'', -- ech_val
            ''1'', -- perimetre minimal
            ''Validation automatique du '' || now()::DATE || '' : '' || cv.libelle,
            $1, -- validateur

            -- On utilise les valeurs de la table procedure
            p."procedure",
            p.proc_vers,
            p.proc_ref

        FROM occtax.niveau_par_observation_final AS t
        JOIN occtax.critere_validation AS cv ON t.id_critere = cv.id_critere,
        (
            SELECT "procedure", proc_vers, proc_ref
            FROM occtax.validation_procedure, regexp_split_to_array(trim(proc_vers),  ''\.'')  AS a
            ORDER BY concat(lpad(a[1], 3, ''0''), lpad(a[2], 3, ''0''), lpad(a[3], 3, ''0'')) DESC
            LIMIT 1
        ) AS p
        WHERE True
        AND t.contexte = ''validation''
        AND t.identifiant_permanent = identifiant_permanent
        ON CONFLICT ON CONSTRAINT validation_observation_identifiant_permanent_ech_val_unique
        DO UPDATE
        SET (
            date_ctrl,
            niv_val,
            typ_val,
            ech_val,
            peri_val,
            comm_val,
            validateur,
            "procedure",
            proc_vers,
            proc_ref
        ) =
        (
            now(),
            EXCLUDED.niv_val,
            ''A'',  --automatique
            ''2'', -- ech_val
            ''1'', -- perimetre minimal
            EXCLUDED.comm_val,
            $1, -- validateur

            -- On utilise les valeurs de la table procedure
            $2,
            $3,
            $4
        )
         WHERE TRUE
        AND vo.typ_val NOT IN (''M'', ''C'')
        ';
        EXECUTE format(sql_template)
        USING p_validateur, procedure_ref_record."procedure", procedure_ref_record.proc_vers, procedure_ref_record.proc_ref;
    END IF;

    -- On supprime les lignes dans validation_observation pour ech_val = '2' et identifiant_permanent NOT IN
    -- qui ne correspondent pas au critère et qui ne sont pas manuelles
    -- on a bien ajouté le WHERE AND vo.typ_val NOT IN (''M'', ''C'')
    -- pour ne surtout pas supprimer les validations manuelles ou combinées via notre outil auto
    if p_simulation IS NOT TRUE THEN
        sql_template := '
        DELETE FROM occtax.validation_observation vo
        WHERE TRUE
        AND ech_val = ''2''
        AND vo.typ_val NOT IN (''M'', ''C'')
        AND identifiant_permanent NOT IN (
            SELECT identifiant_permanent
            FROM occtax.niveau_par_observation_final AS t
            WHERE contexte = ''validation''
        )
        ';
        sql_text := format(sql_template);
        -- on doit ajouter le filtre jdd_id si non NULL
        IF p_jdd_id IS NOT NULL THEN
            sql_template :=  '
            AND identifiant_permanent IN (
                SELECT identifiant_permanent
                FROM occtax.observation
                WHERE jdd_id = ANY ( ''%s''::TEXT[] )
            )
            ';
            sql_text := sql_text || format(sql_template, p_jdd_id);
        END IF;

        EXECUTE sql_text;
    END IF;

    RETURN 1;

END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
