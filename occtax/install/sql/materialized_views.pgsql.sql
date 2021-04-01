
-- Table et fonction pour gérer les vues matérialisées
CREATE TABLE IF NOT EXISTS occtax.materialized_object_list(
    ob_id serial NOT NULL PRIMARY KEY,
    ob_schema text NOT NULL,
    ob_name text NOT NULL,
    ob_order smallint NOT NULL
);

COMMENT ON TABLE occtax.materialized_object_list IS 'Liste des vues matérialisées à rafraîchir via script cron.';
COMMENT ON COLUMN occtax.materialized_object_list.ob_id IS 'Identifiant unique automatique';
COMMENT ON COLUMN occtax.materialized_object_list.ob_schema IS 'Schéma de la vue matérialiée';
COMMENT ON COLUMN occtax.materialized_object_list.ob_name IS 'Nom de la vue matérialisée';
COMMENT ON COLUMN occtax.materialized_object_list.ob_order IS 'Ordre : l''ordre est important: il faut notamment rafraîchir d''abord les vues matérialisées dont dépendent les autres.';

ALTER TABLE occtax.materialized_object_list DROP CONSTRAINT IF EXISTS materialized_object_list_unique;
ALTER TABLE occtax.materialized_object_list ADD CONSTRAINT materialized_object_list_unique UNIQUE (ob_schema, ob_name);

-- FUNCTION: occtax.manage_materialized_objects(text, boolean, text)

-- DROP FUNCTION occtax.manage_materialized_objects(text, boolean, text);

CREATE OR REPLACE FUNCTION occtax.manage_materialized_objects(
    p_action text,
    p_cascade boolean,
    p_object_schema text)
    RETURNS integer
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS $BODY$
DECLARE
    sql_template TEXT;
    sql_text TEXT;
    _ob_schema text;
    _ob_name text;
    _ob_full_type text;
    _ob_col text;
BEGIN

    sql_template:= '';
    sql_text:= '';

    -- Loop through views to create
    FOR
        _ob_schema, _ob_name
    IN
        SELECT
        ob_schema, ob_name
        FROM occtax.materialized_object_list
        WHERE ob_schema = p_object_schema OR p_object_schema IS NULL
        ORDER BY ob_order
    LOOP
        _ob_full_type := 'MATERIALIZED VIEW';

        -- DROP OBJETS
        IF
            -- if asked to do so
            p_action = 'drop'
        THEN
            sql_template := '
                 DROP %s IF EXISTS %I.%I %s;
            ';
            sql_text := concat(
                sql_text,
                format(
                    sql_template,
                    _ob_full_type,
                    _ob_schema,
                    _ob_name,
                    CASE WHEN p_cascade THEN 'CASCADE' ELSE '' END
                )
            );
        END IF;

        -- REFRESH OBJECTS
        IF p_action = 'refresh'
        THEN
            sql_template := '
                REFRESH MATERIALIZED VIEW %I.%I;
            ';
            sql_text := concat(
                sql_text,
                format(
                    sql_template,
                    _ob_schema,
                    _ob_name
                )
            );
        END IF;

    END LOOP;

    -- Execute SQL
    BEGIN
        --RAISE NOTICE '%' , sql_text;
        EXECUTE sql_text;
        RETURN 1;
    EXCEPTION WHEN OTHERS THEN
        --RAISE NOTICE '%' , sql_text;
        RAISE NOTICE '% %', SQLERRM, SQLSTATE;
        RETURN 0;
    END;

END;
$BODY$;

-- OCCTAX
--
-- VUE MATERIALISEE DE CONSOLIDATION DES DONNEES
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

    FROM      occtax."observation"  AS o
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
t.nom_valide, t.{$colonne_locale} AS loc, trim(t.nom_vern) AS nom_vern, t.group1_inpn, t.group2_inpn, t.ordre, t.famille, t.protection, tv.url,
Coalesce( tgc1.libelle_court, tgc2.libelle_court, 'Autres' ) AS categorie,
trim(tv.lb_nom, ' ,\t') AS lb_nom_valide, trim(tv.nom_vern, ' ,\t') AS nom_vern_valide,
t.menace_nationale, t.menace_regionale, t.menace_monde,
t.rang, t.habitat, t.statut, t.endemicite, t.invasibilite,
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


-- Liste des vues et vues matérialisées qui dépendent de vm_observation
-- occtax.vm_stat_nb_observations_par_groupe_taxonomique
-- occtax.vm_stat_nb_taxons_observes_par_groupe_taxonomique AS
-- stats.repartition_temporelle AS
-- stats.repartition_habitats AS
-- stats.connaissance_par_groupe_taxonomique AS
-- stats.nombre_taxons AS
-- stats.repartition_groupe_taxonomique AS
-- stats.observations_par_maille_02 AS
-- stats.avancement_imports AS
-- stats.nombre_obs_par_menace AS
-- stats.nombre_taxons_par_menace AS
-- stats.chiffres_cles AS
-- stats.rangs_taxonomiques AS
-- stats.nombre_taxons_par_statut_biogeographique AS
-- stats.nombre_obs_par_statut_biogeographique AS
-- occtax.v_observation_validation

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

-- nb_observations_par_commune
DROP VIEW IF EXISTS occtax.vm_stat_nb_observations_par_commune;
CREATE VIEW occtax.vm_stat_nb_observations_par_commune AS
SELECT
row_number() OVER () AS id, c.nom_commune,
Count(o.cle_obs) AS nbobs
FROM occtax.observation  AS o
INNER JOIN occtax.localisation_commune lc ON lc.cle_obs = o.cle_obs
INNER JOIN sig.commune c ON c.code_commune = lc.code_commune
WHERE True
GROUP BY nom_commune
ORDER BY nom_commune
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

-- nb_observations_par_an
DROP VIEW IF EXISTS occtax.vm_stat_nb_observations_par_an;
CREATE VIEW occtax.vm_stat_nb_observations_par_an AS
SELECT row_number() OVER () AS id,
to_char( date_trunc('year', date_debut) , 'YYYY') AS periode,
Count(cle_obs) AS nbobs
FROM occtax.observation AS o
WHERE True
GROUP BY periode
ORDER BY periode
;

-- STATS
--
CREATE SCHEMA IF NOT EXISTS stats;

-- repartition_altitudinale_observations
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.repartition_altitudinale_observations AS
SELECT serie.altitude,
  count(DISTINCT a.cle_obs) AS nb_obs
FROM (SELECT generate_series(0, 3100, 100) altitude) serie
LEFT JOIN occtax.attribut_additionnel a ON trunc(a.valeur::NUMERIC(10,2),-2)=serie.altitude
WHERE a.nom='altitude_mnt'
GROUP BY serie.altitude
ORDER BY serie.altitude
;

COMMENT ON MATERIALIZED VIEW stats.repartition_altitudinale_observations IS 'Répartition des observations par tranche altitudinale de 100m';

-- repartition_altitudinale_taxons
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.repartition_altitudinale_taxons AS
SELECT serie.altitude,
  count(DISTINCT o.cd_ref) AS nb_taxons
FROM (SELECT generate_series(0, 3100, 100) altitude) serie
LEFT JOIN occtax.attribut_additionnel a ON trunc(a.valeur::NUMERIC(10,2),-2)=serie.altitude
LEFT JOIN occtax.observation o ON o.cle_obs=a.cle_obs
WHERE a.nom='altitude_mnt'
GROUP BY serie.altitude
ORDER BY serie.altitude
;

COMMENT ON MATERIALIZED VIEW stats.repartition_altitudinale_taxons IS 'Répartition des taxons observés par tranche altitudinale de 100m';

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
GROUP BY id_maille, code_maille, nom_maille, m.geom
;
COMMENT ON MATERIALIZED VIEW stats.observations_par_maille_02 IS 'Nombre d''observations et de taxons par mailles de 2km de côté';

-- observations_par_commune
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.observations_par_commune AS
SELECT
row_number() over () AS id,
c.nom_commune,
Count(o.cle_obs) AS nbobs
FROM occtax.observation  AS o
INNER JOIN occtax.localisation_commune lc ON lc.cle_obs = o.cle_obs
INNER JOIN sig.commune c ON c.code_commune = lc.code_commune
WHERE True
GROUP BY nom_commune
ORDER BY nom_commune
;

COMMENT ON MATERIALIZED VIEW stats.observations_par_commune IS 'Nombre d''observations par commune';

-- avancement_imports
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.avancement_imports AS
  WITH r AS (
         SELECT LEFT(serie.date::TEXT, 7) AS mois,
            count(DISTINCT o.jdd_id) AS nb_jdd,
            count(DISTINCT o.cle_obs) AS nb_obs
           FROM (SELECT generate_series(
               (SELECT date_trunc('month'::text, min(vm_observation.dee_date_transformation)) AS min FROM occtax.vm_observation),
               date_trunc('month'::text, now()),
               '1 mon'::interval
        ) AS date) serie
           LEFT JOIN occtax.vm_observation o ON date_trunc('month'::text, serie.date) = date_trunc('month'::text, o.dee_date_transformation)
          GROUP BY LEFT(serie.date::TEXT, 7)
          ORDER BY LEFT(serie.date::TEXT, 7)
        )
 SELECT r.mois,
    sum(r.nb_jdd) OVER (ORDER BY r.mois) AS nb_jdd,
    sum(r.nb_obs) OVER (ORDER BY r.mois) AS nb_obs
   FROM r
;
COMMENT ON MATERIALIZED VIEW stats.avancement_imports IS 'Nombre cumulé de données et de jeux de données importés dans Borbonica au fil du temps, traduisant la dynamique d''import dans Borbonica';

-- validation
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.validation AS
SELECT nn.code AS niveau_validite,
nn.valeur AS niveau_validite_libelle,
nt.valeur AS type_validite,
count(DISTINCT o.cle_obs) AS nb_obs
FROM (SELECT code, valeur FROM occtax.nomenclature WHERE champ='validite_niveau')nn
LEFT JOIN occtax.observation o ON nn.code=COALESCE(o.validite_niveau, '6')
LEFT JOIN occtax.validation_observation v ON v.identifiant_permanent=o.identifiant_permanent AND v.ech_val='2'
LEFT JOIN (SELECT code, valeur FROM occtax.nomenclature WHERE champ='type_validation')nt ON nt.code=COALESCE(v.typ_val,'A')
GROUP BY nn.code, nn.valeur, nt.valeur
ORDER BY nn.code
;

COMMENT ON MATERIALIZED VIEW stats.validation IS 'Nombre de données par niveau de validation';

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
LEFT JOIN taxon.t_nomenclature n ON n.code::TEXT=o.menace_nationale::TEXT AND n.champ='menace'
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
LEFT JOIN taxon.t_nomenclature n ON n.code::TEXT=o.menace_nationale::TEXT AND n.champ='menace'
GROUP BY n.code, n.ordre, COALESCE(n.valeur, 'Non évaluée')
ORDER BY COALESCE(n.ordre,0) DESC
;
COMMENT ON MATERIALIZED VIEW stats.nombre_taxons_par_menace IS 'Nombre de taxons par niveau de menace UICN de taxon';

-- chiffres_cles
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.chiffres_cles AS
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

-- sensibilite_donnees
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.sensibilite_donnees AS
SELECT n.valeur AS sensi_libelle,
count(cle_obs) AS nb_obs
FROM occtax.observation o
LEFT JOIN (SELECT code, valeur FROM occtax.nomenclature WHERE champ='sensi_niveau') n ON n.code=o.sensi_niveau
GROUP BY sensi_niveau,  n.valeur
ORDER BY sensi_niveau
;

COMMENT ON MATERIALIZED VIEW stats.sensibilite_donnees IS 'Nombre d''observations par niveau de sensibilité des données';

-- types_demandes
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.types_demandes AS
SELECT  n.valeur AS type_demande,
    count(d.id) AS nb_demandes
FROM gestion.demande d
LEFT JOIN gestion.g_nomenclature n ON n.code=d.type_demande AND n.champ='type_demande'
GROUP BY n.valeur
ORDER BY count(d.id) DESC
;

COMMENT ON MATERIALIZED VIEW stats.types_demandes IS 'Nombre de demandes par type';

-- liste_adherents
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.liste_adherents AS
SELECT a.id_adherent, o.nom_organisme, a.statut,  a.date_demande, a.date_adhesion
FROM gestion.adherent a
LEFT JOIN occtax.organisme o USING (id_organisme)
ORDER BY id_adherent
;

COMMENT ON MATERIALIZED VIEW stats.liste_adherents IS 'Liste des adhérents et pré-adhérents à la charte régionale du SINP';

-- liste_jdd
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

-- liste_demandes
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.liste_demandes AS
SELECT  d.id,
        d.date_demande,
        o.nom_organisme,
        CASE WHEN d.motif_anonyme IS TRUE THEN 'Motif anonymisé temporairement'
                ELSE d.motif
                END AS motif,
        n.valeur AS type_demande,
        d.commentaire AS description_demande,
        date_validite_min,
        date_validite_max,
        d.statut,
        d.detail_decision
-- todo (je n'arrive pas à faire car il me manque le script de filtre des demandes): ajouter aussi :
-- le nombre de données concernées par la demande à la date à laquelle elle est formulée,
-- la ventilation par niveau de sensibilité (string_agg)
-- la ventilation par groupe taxonomique (string_agg)
FROM gestion.demande d
LEFT JOIN gestion.g_nomenclature n ON n.code=d.type_demande AND n.champ='type_demande'
LEFT JOIN occtax.organisme o ON o.id_organisme=d.id_organisme
ORDER BY date_demande
;

COMMENT ON MATERIALIZED VIEW stats.liste_demandes IS 'Liste des demandes d''accès aux données précises du SINP 974';

-- liste_organismes
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.liste_organismes AS
WITH r AS(
        SELECT  jdd_id,
                (jsonb_array_elements(ayants_droit)->>'id_organisme')::INTEGER AS id_organisme,
                jsonb_array_elements(ayants_droit)->>'role' AS role
        FROM occtax.jdd
        )

    ,j AS (
SELECT o.id_organisme,
    o.nom_organisme,
    count(jdd.jdd_id) AS nb_jdd,
    string_agg(CONCAT('- ', jdd.jdd_description, ' (', r.role,')') , chr(10) ORDER BY i.date_reception) AS liste_jdd,
    sum(i.nb_donnees_import) AS nb_donnees_jdd,
    max(i.date_reception) AS date_dernier_envoi_donnees
FROM occtax.jdd
JOIN (SELECT jdd_id, max(id_import) AS id_import, max(date_import) AS date_import FROM occtax.jdd_import GROUP BY jdd_id) imax ON imax.jdd_id=jdd.jdd_id
LEFT JOIN occtax.jdd_import i on imax.jdd_id=i.jdd_id
LEFT JOIN r ON r.jdd_id=jdd.jdd_id
LEFT JOIN occtax.organisme o ON r.id_organisme = o.id_organisme
WHERE imax.id_import=i.id_import
GROUP BY o.nom_organisme, o.id_organisme
    ),

d AS (
SELECT o.id_organisme,
    o.nom_organisme,
    count(d.id) AS nb_demandes,
    string_agg(CONCAT('- ', d.motif, ' (', d.statut, ')') , chr(10) ORDER BY d.date_demande) AS liste_demandes,
    min(d.date_demande) AS date_premiere_demande,
    max(d.date_demande) AS date_derniere_demande,
    max(d.date_validite_max) AS date_fin_dernier_acces
FROM gestion.demande d
LEFT JOIN occtax.organisme o ON o.id_organisme=d.id_organisme
GROUP BY o.nom_organisme, o.id_organisme
)

SELECT o.nom_organisme,
    COALESCE(a.statut, 'Non adhérent') AS statut_adherent_sinp974,
    COALESCE(j.nb_jdd, 0) AS nb_jdd,
    j.liste_jdd,
    COALESCE(j.nb_donnees_jdd,0) AS nb_donnees,
    j.date_dernier_envoi_donnees,
    COALESCE(d.nb_demandes,0) AS nb_demandes,
    d.liste_demandes,
    d.date_premiere_demande,
    d.date_derniere_demande,
    d.date_fin_dernier_acces

FROM occtax.organisme o
LEFT JOIN gestion.adherent a ON a.id_organisme=o.id_organisme
LEFT JOIN j ON j.id_organisme=o.id_organisme
LEFT JOIN d ON d.id_organisme=o.id_organisme
WHERE j.nb_jdd>0 OR d.nb_demandes>0 OR a.statut<>'Non adhérent'
ORDER BY o.nom_organisme
;

COMMENT ON MATERIALIZED VIEW stats.liste_organismes IS 'liste des organismes contributeurs ou utilisateurs du SINP à La Réunion : adhérents, demandeurs d''accès aux données précises et producteurs';

-- Liste des taxons observés
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.liste_taxons_observes AS
SELECT o.cd_ref, t.lb_nom, t.nom_vern, t.group2_inpn, t.{$colonne_locale} AS loc, t.rang,
m.valeur AS menace_uicn,
count(o.cle_obs) AS nb_observations,
max(EXTRACT(YEAR FROM COALESCE(o.date_fin, o.date_debut))) AS annee_derniere_obs,
string_agg(DISTINCT jdd.jdd_description, ' | ' ORDER BY jdd.jdd_description) AS liste_jdd,
t.url AS fiche_taxon
FROM occtax.observation o
LEFT JOIN (
    SELECT cd_ref, lb_nom, nom_vern, group2_inpn, {$colonne_locale}, rang, url, menace_nationale
    FROM taxon.taxref_consolide_non_filtre
    WHERE cd_nom=cd_ref
        )t USING(cd_ref)
LEFT JOIN (SELECT * FROM taxon.t_nomenclature WHERE champ='menace')m ON m.code=t.menace_nationale
LEFT JOIN occtax.jdd USING(jdd_code)
GROUP BY o.cd_ref, t.lb_nom, t.nom_vern, t.group2_inpn, t.{$colonne_locale}, t.rang, m.valeur, t.url
ORDER BY count(o.cle_obs) DESC ;

COMMENT ON MATERIALIZED VIEW stats.liste_taxons_observes IS 'Liste des taxons faisant l''objet d''au moins une observation dans Borbonica et statuts associés' ;


-- VALIDATION : vue et triggers pour validation par les validateurs agréés
DROP VIEW IF EXISTS occtax.v_observation_validation CASCADE;
CREATE VIEW occtax.v_observation_validation AS (
SELECT o.cle_obs,
o.identifiant_permanent,
o.identifiant_origine,
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
FROM occtax.vm_observation o
LEFT JOIN (
    SELECT vv.*,
    identite || concat(' - ' || mail, ' (' || o.nom_organisme || ')' ) AS val_validateur
    FROM occtax.validation_observation vv
    LEFT JOIN occtax.personne p ON vv.validateur = p.id_personne
    LEFT JOIN occtax.organisme o ON p.id_organisme = o.id_organisme
    WHERE ech_val = '2' -- uniquement validation de niveau régional
) v USING (identifiant_permanent)
-- jointure pour avoir les informations relatives à la validation producteur
LEFT JOIN (
    SELECT vv.*,
    n.valeur,
    identite || concat(' - ' || mail, ' (' || o.nom_organisme || ')' ) AS val_validateur
    FROM occtax.validation_observation vv
    LEFT JOIN occtax.personne p ON vv.validateur = p.id_personne
    LEFT JOIN occtax.organisme o ON p.id_organisme = o.id_organisme
    LEFT JOIN occtax.nomenclature n ON n.champ='niv_val_mancom' AND n.code=vv.niv_val
    WHERE vv.ech_val = '1' -- uniquement validation producteur
) vprod USING (identifiant_permanent)
)
;




-- Ajout des lignes dans occtax.materialized_object_list

INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('occtax', 'observation_diffusion', -1) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('occtax', 'vm_observation',  0) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'repartition_altitudinale_observations', 1) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'repartition_altitudinale_taxons', 2) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'repartition_temporelle', 3) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'repartition_habitats', 4) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'connaissance_par_groupe_taxonomique', 5) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'nombre_taxons', 6) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'repartition_groupe_taxonomique', 7) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'observations_par_maille_02', 8) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'observations_par_commune', 9) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'avancement_imports', 10) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'validation', 11) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'nombre_obs_par_menace', 12) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'nombre_taxons_par_menace', 13) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'chiffres_cles', 14) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'rangs_taxonomique', 15) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'nombre_taxons_par_statut_biogeographique', 16) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'nombre_obs_par_statut_biogeographique', 17) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'sensibilite_donnees', 18) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'types_demandes', 19) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'liste_adherents', 20) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'liste_jdd', 21) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'liste_demandes', 22) ON CONFLICT DO NOTHING;
INSERT INTO occtax.materialized_object_list ("ob_schema", "ob_name", "ob_order") VALUES('stats ', 'liste_organismes', 23) ON CONFLICT DO NOTHING;

