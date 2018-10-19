BEGIN;

SET search_path TO occtax,public,pg_catalog;

-- Utilisation de ANONYME au lieu d'INCONNU
CREATE OR REPLACE VIEW v_observateur AS
SELECT
CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE p.identite END AS identite,
CASE WHEN p.anonymiser IS TRUE THEN '' ELSE p.mail END AS mail,
CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE Coalesce(p.organisme, 'INCONNU') END AS organisme,
op.id_personne, op.cle_obs, p.prenom, p.nom, p.anonymiser
FROM observation_personne op
INNER JOIN personne p ON p.id_personne = op.id_personne AND op.role_personne = 'Obs'
;

CREATE OR REPLACE VIEW v_validateur AS
SELECT CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE p.identite END AS identite,
CASE WHEN p.anonymiser IS TRUE THEN '' ELSE p.mail END AS mail,
CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE Coalesce(p.organisme, 'INCONNU') END AS organisme,
op.id_personne, op.cle_obs, p.prenom, p.nom, p.anonymiser
FROM observation_personne op
INNER JOIN personne p ON p.id_personne = op.id_personne AND op.role_personne = 'Val'
;

CREATE OR REPLACE VIEW v_determinateur AS
SELECT CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE p.identite END AS identite,
CASE WHEN p.anonymiser IS TRUE THEN '' ELSE p.mail END AS mail,
CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE Coalesce(p.organisme, 'INCONNU') END AS organisme,
op.id_personne, op.cle_obs, p.prenom, p.nom, p.anonymiser
FROM observation_personne op
INNER JOIN personne p ON p.id_personne = op.id_personne AND op.role_personne = 'Det'
;


-- VALIDATION : vue et triggers pour validation par les validateurs agréés
DROP VIEW IF EXISTS occtax.v_observation_validation CASCADE;
CREATE OR REPLACE VIEW occtax.v_observation_validation AS

SELECT
-- Observation
o.cle_obs, o.identifiant_permanent, statut_observation,

--Taxon
o.cd_nom, o.cd_ref, nom_cite,

t.nom_valide, t.reu, t.nom_vern, t.group2_inpn, t.ordre, t.famille,

--Individus observés
o.denombrement_min, o.denombrement_max, o.objet_denombrement, o.type_denombrement,

-- Descriptif sujet
REPLACE(replace((jsonb_pretty(array_to_json(array_agg(json_build_object(
    'obs_methode',
    dict->>(concat('obs_methode', '_', obs_methode)) ,
    'occ_etat_biologique',
    dict->>(concat('occ_etat_biologique', '_', occ_etat_biologique)),
    'occ_naturalite',
    dict->>(concat('occ_naturalite', '_', occ_naturalite)),
    'occ_sexe',
    dict->>(concat('occ_sexe', '_', occ_sexe)),
    'occ_stade_de_vie',
    dict->>(concat('occ_stade_de_vie', '_', occ_stade_de_vie)),
    'occ_statut_biogeographique',
    dict->>(concat('occ_statut_biogeographique', '_', occ_statut_biogeographique)),
    'occ_statut_biologique',
    dict->>(concat('occ_statut_biologique', '_', occ_statut_biologique)),
    'preuve_existante',
    dict->>(concat('preuve_existante', '_', preuve_existante)),
    'preuve_numerique',
    preuve_numerique,
    'preuve_numerique',
    preuve_non_numerique,
    'obs_contexte',
    obs_contexte,
    'obs_description',
    obs_description,
    'occ_methode_determination',
    dict->>(concat('occ_methode_determination', '_', occ_methode_determination))
)))::jsonb)::text), '"', ''), ':', ' : ') AS descriptif_sujet,

o.date_determination,

-- Quand ?
o.date_debut, o.date_fin, o.heure_debut, o.heure_fin,

--Où ?
o.geom, o.altitude_moy,  o.precision_geometrie, o.nature_objet_geo,

--Personnes
string_agg(
    vobs.identite || concat(
        ' - ' || vobs.mail,
        CASE
            WHEN vobs.organisme = 'ANONYME' THEN ''
            ELSE ' (' || vobs.organisme|| ')'
        END
    ),
    ', '
) AS observateurs,
string_agg(
    vdet.identite || concat(
        ' - ' || vdet.mail,

        CASE
            WHEN vdet.organisme = 'ANONYME' THEN ''
            ELSE ' (' || vdet.organisme|| ')'
        END
    ),
    ', '
) AS determinateurs,

o.organisme_gestionnaire_donnees,

--Généralités
o.commentaire, o.code_idcnp_dispositif,  o.dee_date_transformation, o.dee_date_derniere_modification,

jdd.jdd_code, jdd.jdd_id, jdd.jdd_description, jdd.jdd_metadonnee_dee_id,
o.statut_source, o.reference_biblio,

-- Diffusion
o.ds_publique, o.diffusion_niveau_precision, o.sensi_niveau,

--Validation
o.validite_niveau, o.validite_date_validation,
-- table validation_observation
v.id_validation,
v.date_ctrl,
v.niv_val,
v.typ_val,
v.ech_val,
v.peri_val,
string_agg( vval.identite || concat(' - ' || vval.mail, ' (' || vval.organisme || ')' ), ', ') AS validateur,
v.proc_vers,



CASE
    WHEN vp.niv_val IS NOT NULL THEN concat(n.valeur, ' (Validation le ', COALESCE(vp.date_ctrl::text, 'Date non connue'), ' par ', vvalp.identite, ' - ', vvalp.organisme, ')')
    ELSE NULL::text
    END AS validation_producteur,
-- vlt : ajout de validation_producteur
v.producteur,
v.date_contact,
v."procedure",
v.proc_ref,
v.comm_val


FROM occtax.observation o
LEFT JOIN taxon.taxref_consolide_non_filtre AS t USING (cd_nom)
LEFT JOIN occtax.v_observateur AS vobs USING (cle_obs)

LEFT JOIN occtax.v_determinateur AS vdet USING (cle_obs)
LEFT JOIN occtax.jdd USING (jdd_id)
-- plateforme régionale
LEFT JOIN occtax.validation_observation v ON "ech_val" = '2' AND v.identifiant_permanent = o.identifiant_permanent
-- vlt : ajout des 4 lignes suivantes :
LEFT JOIN validation_observation vp ON vp.ech_val = '1'::text AND vp.identifiant_permanent = o.identifiant_permanent
LEFT JOIN occtax.personne vval ON vval.id_personne=v.validateur
LEFT JOIN occtax.personne vvalp ON vvalp.id_personne=vp.validateur
LEFT JOIN nomenclature n ON n.champ = 'niv_val_auto'::text AND n.code = vp.niv_val
left join lateral
jsonb_to_recordset(o.descriptif_sujet) AS (
    obs_methode text,
    occ_etat_biologique text,
    occ_naturalite text,
    occ_sexe text,
    occ_stade_de_vie text,
    occ_statut_biogeographique text,
    occ_statut_biologique text,
    preuve_existante text,
    preuve_numerique text,
    preuve_non_numerique text,
    obs_contexte text,
    obs_description text,
    occ_methode_determination text
) ON TRUE,
occtax.v_nomenclature_plat
GROUP BY
o.cle_obs, o.identifiant_permanent, o.statut_observation,
o.cd_nom, nom_cite,
t.nom_valide, t.reu, t.nom_vern, t.ordre, t.famille, t.group1_inpn, t.group2_inpn,
-- ajout de t.ordre, t.famille, supression de t.group1_inpn,
o.denombrement_min, o.denombrement_max, o.objet_denombrement, o.type_denombrement,

o.date_determination,  o.date_debut, o.date_fin, o.heure_debut, o.heure_fin,
o.geom, o.altitude_moy,  o.precision_geometrie, o.nature_objet_geo,
o.commentaire, o.code_idcnp_dispositif,  o.dee_date_transformation, o.dee_date_derniere_modification,
jdd.jdd_code, jdd.jdd_id, jdd.jdd_description, jdd.jdd_metadonnee_dee_id,
o.statut_source, o.reference_biblio,
o.ds_publique, o.diffusion_niveau_precision, o.sensi_niveau,
o.validite_niveau, o.validite_date_validation,
v.id_validation,
v.date_ctrl,
v.niv_val,
v.typ_val,
v.ech_val,
v.peri_val,
v.validateur,
v.proc_vers,
v.producteur,
v.date_contact,
v."procedure",
v.proc_ref,
v.comm_val,
-- vlt : ajout de :
vp.niv_val, n.valeur, vp.date_ctrl, vvalp.identite, vvalp.organisme
;

-- Taxon
CREATE INDEX ON taxref_consolide (famille);
CREATE INDEX ON taxon.taxref_consolide_all (cd_ref);
CREATE INDEX ON taxon.taxref_consolide_non_filtre (famille);


-- Vues pour l'impression, suppression du ORDER BY random() trop couteux
DROP VIEW IF EXISTS sig.tpl_observation_maille;
CREATE OR REPLACE VIEW sig.tpl_observation_maille AS
SELECT id_maille AS mid, nom_maille AS maille, 10 AS nbobs, 3 AS nbtax, 410 AS rayon, 'red'::text AS color, ''::text AS geojson, ST_Centroid( geom )::geometry(POINT, {$SRID}) AS geom FROM sig.maille_02;

DROP VIEW IF EXISTS sig.tpl_observation_brute_point;
CREATE OR REPLACE VIEW sig.tpl_observation_brute_point AS
SELECT 1::integer AS cle_obs, ''::text AS nom_cite, '1'::bigint AS cd_nom, '2015-01-01'::text AS date_debut, ''::text AS identite_observateur, 'GEO'::text AS source_objet, ''::text AS geojson,
(SELECT geom FROM occtax.observation LIMIT 1 )::geometry(Point, {$SRID}) AS geom;

DROP VIEW IF EXISTS sig.tpl_observation_brute_linestring;
CREATE OR REPLACE VIEW sig.tpl_observation_brute_linestring AS
SELECT 1::integer AS cle_obs, ''::text AS nom_cite, '1'::bigint AS cd_nom, '2015-01-01'::text AS date_debut, ''::text AS identite_observateur, 'GEO'::text AS source_objet, ''::text AS geojson,
(SELECT ST_ExteriorRing(ST_Buffer(geom, 1000)) AS geom FROM occtax.observation LIMIT 1)::geometry(Linestring, {$SRID}) AS geom;

DROP VIEW IF EXISTS sig.tpl_observation_brute_polygon;
CREATE OR REPLACE VIEW sig.tpl_observation_brute_polygon AS
SELECT 1::integer AS cle_obs, ''::text AS nom_cite, '1'::bigint AS cd_nom, '2015-01-01'::text AS date_debut, ''::text AS identite_observateur, 'GEO'::text AS source_objet, ''::text AS geojson,
(SELECT ST_Buffer(geom, 1000) AS geom FROM occtax.observation LIMIT 1)::geometry(Polygon, {$SRID}) AS geom;

DROP VIEW IF EXISTS sig.tpl_observation_brute_centroid;
CREATE OR REPLACE VIEW sig.tpl_observation_brute_centroid AS
SELECT 1::integer AS cle_obs, ''::text AS nom_cite, '1'::bigint AS cd_nom, '2015-01-01'::text AS date_debut, ''::text AS identite_observateur, 'GEO'::text AS source_objet, ''::text AS geojson, (SELECT geom FROM occtax.observation LIMIT 1)::geometry(Point, {$SRID}) AS geom;

COMMIT;
