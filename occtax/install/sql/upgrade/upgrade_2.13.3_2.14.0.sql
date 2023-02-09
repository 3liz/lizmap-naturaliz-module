-- Suppression d'une règle inutile sur les dénombrements non null
DELETE FROM occtax.critere_conformite
WHERE code IN ('obs_denombrement_min_not_null', 'obs_denombrement_max_not_null')
AND type_critere = 'not_null'
;
-- Suppression des règles sur le niveau de validite et la date de contrôle
-- cela sera ajouté dans un 2ème temps
DELETE FROM occtax.critere_conformite
WHERE code IN ('obs_validite_niveau_format', 'obs_validite_niveau_valide');


-- Fonction pour calculer la diffusion des données
DROP FUNCTION IF EXISTS occtax.calcul_diffusion(text, text, text) CASCADE;
CREATE OR REPLACE FUNCTION occtax.calcul_diffusion(sensi_niveau text, ds_publique text, diffusion_niveau_precision text)
  RETURNS jsonb AS
$BODY$
DECLARE
    _diffusion jsonb;
BEGIN

    _diffusion =
    CASE
        --non sensible : précision maximale, sauf si diffusion_niveau_precision est NOT NULL et != 5
        WHEN sensi_niveau = '0' THEN
            CASE
                WHEN ds_publique IN ('Ac', 'Pu', 'Re') THEN '["g", "d", "m10", "m02", "m01", "e", "c", "z"]'::jsonb
                ELSE
                    CASE
                        -- tout sauf geom (diffusion standard régionale)
                        WHEN diffusion_niveau_precision = 'm01' THEN '["d", "m10", "m02", "m01", "e", "c", "z"]'::jsonb

                        -- tout sauf geom (diffusion standard régionale)
                        WHEN diffusion_niveau_precision = 'm02' THEN '["d", "m10", "m02", "e", "c", "z"]'::jsonb

                        -- tout sauf geom et maille 2 (diffusion standard nationale):
                        WHEN diffusion_niveau_precision = '0' THEN '["d", "m10", "e", "c", "z"]'::jsonb

                        -- commune et département
                        WHEN diffusion_niveau_precision = '1' THEN '["d", "c"]'::jsonb

                        -- maille 10 et département
                        WHEN diffusion_niveau_precision = '2' THEN '["d", "m10"]'::jsonb

                        -- département
                        WHEN diffusion_niveau_precision = '3'  THEN '["d"]'::jsonb

                        -- non diffusé
                        WHEN diffusion_niveau_precision = '4' THEN NULL::jsonb

                        -- diffusion telle quelle. Si donnée existe, on fourni
                        WHEN diffusion_niveau_precision = '5'  THEN '["g", "d", "m10", "m02", "m01", "e", "c", "z"]'::jsonb

                        ELSE '["d", "m10", "m02", "m01", "e", "c", "z"]'::jsonb
                    END
            END

        -- m02 = département, maille 10, maille 2
        WHEN sensi_niveau = 'm02' THEN '["d", "m10", "m02"]'::jsonb

        -- m01 = département, maille 10, maille 2, maille 1
        WHEN sensi_niveau = 'm01' THEN '["d", "m10", "m02", "m01"]'::jsonb

        -- 1 = tout sauf geom et maille 2 et 1: département, maille 10, espace naturel, commune, znieff
        WHEN sensi_niveau = '1' THEN '["d", "m10", "e", "c", "z"]'::jsonb

        -- 2 = département, maille 10
        WHEN sensi_niveau = '2' THEN '["d", "m10"]'::jsonb

        -- 3 = département
        WHEN sensi_niveau = '3' THEN '["d"]'::jsonb

        -- 4 = non diffusé
        WHEN sensi_niveau = '4' THEN NULL::jsonb

        -- aucune valeur
        ELSE NULL::jsonb
    END
    ;

    RETURN _diffusion;

END
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

COMMENT ON FUNCTION occtax.calcul_diffusion(text, text, text)
IS 'Calcul de la diffusion en fonction des valeurs de "sensi_niveau", "ds_publique", "diffusion_niveau_precision".
Cette fonction renvoie un jsonb qui permet à l''application de connaître comment afficher la donnée.
Par exemple: ["d", "m10", "m02"] veut dire qu''on ne doit diffuser que pour le niveau département et mailles 1 et 2km'
;


-- Suppression de la vue inutile car remplacement par une simple fonction
DROP MATERIALIZED VIEW IF EXISTS occtax.observation_diffusion CASCADE;

-- Suppression du trigger qui permet d'ajouter les champs
DROP TRIGGER IF EXISTS trg_validation_renseigner_champs_observation ON occtax.validation_observation;
DROP FUNCTION IF EXISTS occtax.update_observation_set_validation_fields();

-- Suppression de cette vue remplacée par occtax.v_validation_regionale
DROP VIEW IF EXISTS occtax.v_observation_champs_validation;

-- Vue pour récupérer seulement la validation au niveau régional pour les observations
CREATE OR REPLACE VIEW occtax.v_validation_regionale AS
SELECT
identifiant_permanent,
niv_val AS niv_val_regionale, date_ctrl AS date_ctrl_regionale
FROM occtax.validation_observation
WHERE ech_val = '2'
;
COMMENT ON VIEW occtax.v_validation_regionale
IS 'Vue qui récupère les lignes de la validation régionale depuis occtax.validation_observation (pour l''échelle 2 donc).
Elle est utilisée dans l''application pour les requêtes réalisées en tant que validateur (sinon on utilise les champs de vm_observation).';



-- vm_observation
DROP VIEW IF EXISTS occtax.v_vm_observation CASCADE;
CREATE OR REPLACE VIEW occtax.v_vm_observation AS
WITH
agg_m01 AS (
    SELECT
        cle_obs, jsonb_agg(code_maille) AS code_maille, min(code_maille) AS code_maille_unique
    FROM occtax.localisation_maille_01
    GROUP BY cle_obs
),
agg_m02 AS (
    SELECT
        cle_obs, jsonb_agg(code_maille) AS code_maille, min(code_maille) AS code_maille_unique
    FROM occtax.localisation_maille_02
    GROUP BY cle_obs
),
agg_m10 AS (
    SELECT
        cle_obs, jsonb_agg(code_maille) AS code_maille, min(code_maille) AS code_maille_unique
    FROM occtax.localisation_maille_10
    GROUP BY cle_obs
),
agg_com AS (
    SELECT
        cle_obs, jsonb_agg(code_commune) AS code_commune, min(code_commune) AS code_commune_unique
    FROM occtax.localisation_commune
    GROUP BY cle_obs
),
agg_dep AS (
    SELECT
        cle_obs, jsonb_agg(code_departement) AS code_departement
    FROM occtax.localisation_departement
    GROUP BY cle_obs
),
agg_me AS (
    SELECT
        cle_obs, jsonb_agg(code_me) AS code_me
    FROM occtax.localisation_masse_eau
    GROUP BY cle_obs
),
agg_en AS (
    SELECT
        cle_obs,
        jsonb_agg(code_en ORDER BY code_en) AS code_en,
        jsonb_agg(type_en ORDER BY code_en) AS type_en
    FROM occtax.v_localisation_espace_naturel
    GROUP BY cle_obs
),

agg_observateur AS (
    SELECT
        cle_obs,
        string_agg( concat(
            identite,
            CASE
                WHEN organisme IS NULL OR organisme = '' THEN ''
                ELSE ' (' || organisme|| ')'
            END
        ), ', ' ORDER BY identite) AS identite_observateur,
        string_agg( concat(
            identite_non_floutee,
            CASE
                WHEN organisme_non_floute IS NULL OR organisme_non_floute = '' THEN ''
                ELSE ' (' || organisme_non_floute|| ')'
            END,
            ' - ' || mail_non_floute
        ), ', ' ORDER BY identite) AS identite_observateur_non_floute
    FROM occtax."v_observateur"
    GROUP BY cle_obs
),

-- déterminateur
agg_determinateur AS (
    SELECT
        cle_obs,
        string_agg( concat(
            identite,
            CASE
                WHEN organisme IS NULL OR organisme = '' THEN ''
                ELSE ' (' || organisme|| ')'
            END
        ), ', ' ORDER BY identite) AS determinateur,
        string_agg( concat(
            identite_non_floutee,
            CASE
                WHEN organisme_non_floute IS NULL OR organisme_non_floute = '' THEN ''
                ELSE ' (' || organisme_non_floute|| ')'
            END,
            ' - ' || mail_non_floute
        ), ', ' ORDER BY identite) AS determinateur_non_floute
    FROM occtax."v_determinateur"
    GROUP BY cle_obs
),


-- validation
validation_producteur AS (
    SELECT
        identifiant_permanent,
        Coalesce(niv_val, '6') AS niv_val,
        date_ctrl AS date_ctrl,
        concat(
            identite,
            CASE
                WHEN organisme IS NULL OR organisme = '' THEN ''
                ELSE ' (' || organisme|| ')'
            END
        ) AS validateur
    FROM occtax.v_validateurs
    WHERE ech_val = '1'
),
validation_regionale AS (
    SELECT
        identifiant_permanent,
        Coalesce(niv_val, '6') AS niv_val,
        date_ctrl AS date_ctrl,
        concat(
            identite,
            CASE
                WHEN organisme IS NULL OR organisme = '' THEN ''
                ELSE ' (' || organisme|| ')'
            END
        ) AS validateur
    FROM occtax.v_validateurs
    WHERE ech_val = '2'
),
validation_nationale AS (
    SELECT
        identifiant_permanent,
        Coalesce(niv_val, '6') AS niv_val,
        date_ctrl AS date_ctrl,
        concat(
            identite,
            CASE
                WHEN organisme IS NULL OR organisme = '' THEN ''
                ELSE ' (' || organisme|| ')'
            END
        ) AS validateur
    FROM occtax.v_validateurs
    WHERE ech_val = '3'
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

-- validations producteur, régionale et nationale
jsonb_build_object(
    'niv_val', val_p.niv_val,
    'date_ctrl', val_p.date_ctrl,
    'validateur', val_p.validateur
) AS validation_producteur,
jsonb_build_object(
    'niv_val', val_r.niv_val,
    'date_ctrl', val_r.date_ctrl,
    'validateur', val_r.validateur
) AS validation_regionale,
jsonb_build_object(
    'niv_val', val_n.niv_val,
    'date_ctrl', val_n.date_ctrl,
    'validateur', val_n.validateur
) AS validation_nationale,
-- ajout de niv_val pour les 3 échelles
-- en cas de filtres WHERE (demande, grand public, etc.)
val_p.niv_val AS niv_val_producteur,
val_r.niv_val AS niv_val_regionale,
val_n.niv_val AS niv_val_nationale,

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
    WHEN lm10.code_maille IS NOT NULL THEN 'M10'
    WHEN lc.code_commune IS NOT NULL THEN 'COM'
    WHEN lme.code_me IS NOT NULL THEN 'ME'
    WHEN len.code_en IS NOT NULL THEN 'EN'
    WHEN ld.code_departement IS NOT NULL THEN 'DEP'
    ELSE 'NO'
END AS source_objet,

-- liens spatiaux
lm01.code_maille AS code_maille_01,
lm01.code_maille_unique AS code_maille_01_unique,
lm02.code_maille AS code_maille_02,
lm02.code_maille_unique AS code_maille_02_unique,
lm10.code_maille AS code_maille_10,
lm10.code_maille_unique AS code_maille_10_unique,
lc.code_commune, lc.code_commune_unique,
ld.code_departement,
lme.code_me,
len.code_en, len.type_en,

-- calcul de la diffusion
occtax.calcul_diffusion(o.sensi_niveau, o.ds_publique, o.diffusion_niveau_precision) AS diffusion,

-- observateurs
pobs.identite_observateur, pobs.identite_observateur_non_floute,
-- validateurs
rtrim(concat(
    'Validation producteur: ' || val_p.validateur || ', ',
    'Validation régionale: ' || val_r.validateur || ', ',
    'Validation nationale: ' || val_n.validateur || ', '
), ', ') AS validateur,
-- déterminateurs
pdet.determinateur, pdet.determinateur_non_floute

FROM      occtax."observation"  AS o
INNER JOIN occtax."jdd" ON jdd.jdd_id = o.jdd_id
LEFT JOIN agg_observateur   AS pobs  ON pobs.cle_obs = o.cle_obs
LEFT JOIN validation_producteur AS val_p ON val_p.identifiant_permanent = o.identifiant_permanent
LEFT JOIN validation_regionale AS val_r ON val_r.identifiant_permanent = o.identifiant_permanent
LEFT JOIN validation_nationale AS val_n ON val_n.identifiant_permanent = o.identifiant_permanent
LEFT JOIN agg_determinateur AS pdet  ON pdet.cle_obs = o.cle_obs
LEFT JOIN agg_m01 AS lm01  ON lm01.cle_obs = o.cle_obs
LEFT JOIN agg_m02 AS lm02  ON lm02.cle_obs = o.cle_obs
LEFT JOIN agg_m10 AS lm10  ON lm10.cle_obs = o.cle_obs
LEFT JOIN agg_com AS lc    ON lc.cle_obs = o.cle_obs
LEFT JOIN agg_dep AS ld    ON ld.cle_obs = o.cle_obs
LEFT JOIN agg_me  AS lme   ON lme.cle_obs = o.cle_obs
LEFT JOIN agg_en  AS len   ON len.cle_obs = o.cle_obs

LEFT JOIN taxon."taxref_consolide_non_filtre" AS t ON t.cd_nom = o.cd_nom
LEFT JOIN taxon."taxref_consolide_non_filtre" AS tv ON tv.cd_nom = tv.cd_ref AND tv.cd_nom = t.cd_ref
LEFT JOIN taxon."t_group_categorie" AS tgc1  ON tgc1.groupe_nom = t.group1_inpn AND tgc1.groupe_type = 'group1_inpn'
LEFT JOIN taxon."t_group_categorie" AS tgc2  ON tgc2.groupe_nom = t.group2_inpn AND tgc2.groupe_type = 'group2_inpn'
WHERE TRUE
AND (jdd.date_minimum_de_diffusion IS NULL OR jdd.date_minimum_de_diffusion <= now() )
;

COMMENT ON VIEW occtax.v_vm_observation
IS 'Vue contenant la requête complexe qui est la source de la vue matérialisée vm_observation.
On peut modifier cette vue puis rafraîchir la vue vm_observation si besoin.
Dans le cas où la liste de champs reste inchangée, cela facilite les choses car cela n''oblige pas
à supprimer et recréer vm_observation et ses vues dépendantes (stats)';


-- VUE MATERIALISEE DE CONSOLIDATION DES DONNEES
DROP MATERIALIZED VIEW IF EXISTS occtax.vm_observation CASCADE;
CREATE MATERIALIZED VIEW occtax.vm_observation AS
SELECT *
FROM occtax.v_vm_observation
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
CREATE INDEX vm_observation_date_debut_date_fin_idx ON occtax.vm_observation USING btree (date_debut, date_fin DESC);
CREATE INDEX vm_observation_descriptif_sujet_idx ON occtax.vm_observation USING GIN (descriptif_sujet);
CREATE INDEX vm_observation_code_commune_idx ON occtax.vm_observation USING GIN (code_commune);
CREATE INDEX vm_observation_code_maille_01_idx ON occtax.vm_observation USING GIN (code_maille_01);
CREATE INDEX vm_observation_code_maille_02_idx ON occtax.vm_observation USING GIN (code_maille_02);
CREATE INDEX vm_observation_code_maille_01_unique_idx ON occtax.vm_observation (code_maille_01_unique);
CREATE INDEX vm_observation_code_maille_02_unique_idx ON occtax.vm_observation (code_maille_02_unique);
CREATE INDEX vm_observation_code_maille_10_unique_idx ON occtax.vm_observation (code_maille_10_unique);
CREATE INDEX vm_observation_diffusion_idx ON occtax.vm_observation USING GIN (diffusion);
CREATE INDEX vm_observation_validation_regionale_idx ON occtax.vm_observation USING GIN (validation_regionale);


-- DÉTAIL : vue occtax.v_vm_observation dépend de vue matérialisée occtax.observation_diffusion
-- vue matérialisée occtax.vm_observation dépend de vue occtax.v_vm_observation
-- vue occtax.vm_stat_nb_observations_par_groupe_taxonomique dépend de vue matérialisée occtax.vm_observation
-- vue occtax.vm_stat_nb_taxons_observes_par_groupe_taxonomique dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.repartition_temporelle dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.repartition_habitats dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.connaissance_par_groupe_taxonomique dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.nombre_taxons dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.repartition_groupe_taxonomique dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.observations_par_maille_02 dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.avancement_imports dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.nombre_obs_par_menace dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.nombre_taxons_par_menace dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.rangs_taxonomiques dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.nombre_taxons_par_statut_biogeographique dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.nombre_obs_par_statut_biogeographique dépend de vue matérialisée occtax.vm_observation
-- vue occtax.v_observation_validation dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.chiffres_cles dépend de vue matérialisée occtax.vm_observation

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
SELECT
    niv_val AS niveau_validite,
    (SELECT valeur FROM occtax.nomenclature WHERE champ='validite_niveau' AND code = niv_val) AS niveau_validite_libelle,
    (SELECT valeur FROM occtax.nomenclature WHERE champ='type_validation' AND code = typ_val) AS type_validite,
    count(DISTINCT v.identifiant_permanent) AS nb_obs
FROM
    occtax.validation_observation AS v
WHERE v.ech_val = '2'
GROUP BY niv_val, typ_val
ORDER BY niv_val
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
            jsonb_array_elements(jdd.ayants_droit) ->> 'id_organisme'::text AS id_organisme,
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


-- modification des règles d'import
DELETE FROM occtax.critere_conformite WHERE code = 'obs_validite_date_validation_format';
INSERT INTO occtax.critere_conformite (code, libelle, description, condition, type_critere)
VALUES
('obs_validite_niv_val_format', 'Le format de <b>validation_niv_val</b> est incorrect. Attendu: entier', NULL, $$occtax.is_given_type(validation_niv_val, 'integer')$$, 'format'),
('obs_validite_ech_val_format', 'Le format de <b>validation_ech_val</b> est incorrect. Attendu: entier', NULL, $$occtax.is_given_type(validation_ech_val, 'integer')$$, 'format'),
('obs_validite_date_ctrl_format', 'Le format de <b>validation_date_ctrl</b> est incorrect. Attendu: date', NULL, $$occtax.is_given_type(validation_date_ctrl, 'date')$$, 'format'),

('obs_validation_niv_val_valide', 'La valeur de <b>validation_niv_val</b> n''est pas conforme', 'Le champ <b>validation_niv_val</b> peut seulement prendre les valeurs suivantes: 1, 2, 3, 4, 5, 6', $$( validation_niv_val IN ( '1', '2', '3', '4', '5', '6' ) )$$, 'conforme'),
('obs_validation_ech_val_valide', 'La valeur de <b>validation_ech_val</b> n''est pas conforme', 'Le champ <b>validation_ech_val</b> peut seulement prendre les valeurs suivantes: 1, 2, 3', $$( validation_ech_val IN ( '1', '2', '3' ) )$$, 'conforme'),
('obs_validation_typ_val_valide', 'La valeur de <b>validation_typ_val</b> n''est pas conforme', 'Le champ <b>validation_typ_val</b> peut seulement prendre les valeurs suivantes: A, M, C', $$( validation_typ_val IN ( 'A', 'M', 'C' ) )$$, 'conforme')
ON CONFLICT ON CONSTRAINT critere_conformite_unique_code DO NOTHING
;
