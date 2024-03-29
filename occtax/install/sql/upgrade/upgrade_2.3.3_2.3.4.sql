BEGIN;


-- vm_observation
DROP MATERIALIZED VIEW IF EXISTS occtax.vm_observation CASCADE;
CREATE MATERIALIZED VIEW occtax.vm_observation AS
SELECT
o.cle_obs,
o.identifiant_permanent,
o.statut_observation,
o.cd_nom,
o.cd_ref,
o.version_taxref,
o.nom_cite,
t.nom_valide, t.reu, trim(t.nom_vern) AS nom_vern, t.group1_inpn, t.group2_inpn, t.ordre, t.famille, t.protection, tv.url,
(regexp_split_to_array( Coalesce( tgc1.cat_nom, tgc2.cat_nom, 'Autres' ), ' '))[1] AS categorie,
trim(tv.lb_nom, ' ,\t') AS lb_nom_valide, trim(tv.nom_vern, ' ,\t') AS nom_vern_valide,
t.menace, t.rang, t.habitat,
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
    -- WHEN lm05.code_maille IS NOT NULL THEN 'M05'
    WHEN lm10.code_maille IS NOT NULL THEN 'M10'
    WHEN lc.code_commune IS NOT NULL THEN 'COM'
    WHEN lme.code_me IS NOT NULL THEN 'ME'
    WHEN len.code_en IS NOT NULL THEN 'EN'
    WHEN ld.code_departement IS NOT NULL THEN 'DEP'
    ELSE 'NO'
END AS source_objet,

jsonb_agg(DISTINCT lm01.code_maille) AS code_maille_01,
min(lm01.code_maille) AS code_maille_01_unique,
jsonb_agg(DISTINCT lm02.code_maille) AS code_maille_02,
min(lm02.code_maille) AS code_maille_02_unique,
-- jsonb_agg(DISTINCT lm05.code_maille) AS code_maille_05,
jsonb_agg(DISTINCT lm10.code_maille) AS code_maille_10,
min(lm10.code_maille) AS code_maille_10_unique,
jsonb_agg(DISTINCT lc.code_commune) AS code_commune,
min(lc.code_commune) AS code_commune_unique,
jsonb_agg(DISTINCT ld.code_departement) AS code_departement,
jsonb_agg(DISTINCT lme.code_me) AS code_me,
jsonb_agg(DISTINCT len.code_en) AS code_en,
jsonb_agg(DISTINCT len.type_en) AS type_en,

od.diffusion,
string_agg( DISTINCT concat(
    pobs.identite,
    CASE
        WHEN pobs.organisme IS NULL OR pobs.organisme = '' THEN ''
        ELSE ' (' || pobs.organisme|| ')'
    END
), ', ' ) AS identite_observateur,
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
), ', ' ) AS determinateur

FROM occtax."observation"  AS o
JOIN  occtax."observation_diffusion"  AS od  ON od.cle_obs = o.cle_obs
LEFT JOIN taxon."taxref_consolide_non_filtre" AS t USING (cd_nom)
LEFT JOIN taxon."taxref_consolide_non_filtre" AS tv ON tv.cd_nom = tv.cd_ref AND tv.cd_nom = t.cd_ref
LEFT JOIN taxon."t_group_categorie" AS tgc1  ON tgc1.groupe_nom = t.group1_inpn AND tgc1.groupe_type = 'group1_inpn'
LEFT JOIN taxon."t_group_categorie" AS tgc2  ON tgc2.groupe_nom = t.group2_inpn AND tgc2.groupe_type = 'group2_inpn'
LEFT JOIN occtax."v_observateur"  AS pobs  ON pobs.cle_obs = o.cle_obs
LEFT JOIN occtax."v_validateur"  AS pval  ON pval.cle_obs = o.cle_obs
LEFT JOIN occtax."v_determinateur"  AS pdet  ON pdet.cle_obs = o.cle_obs
LEFT JOIN occtax."localisation_maille_01"  AS lm01  ON lm01.cle_obs = o.cle_obs
LEFT JOIN occtax."localisation_maille_02"  AS lm02  ON lm02.cle_obs = o.cle_obs
LEFT JOIN occtax."localisation_maille_10"  AS lm10  ON lm10.cle_obs = o.cle_obs
LEFT JOIN occtax."localisation_commune"  AS lc  ON lc.cle_obs = o.cle_obs
LEFT JOIN occtax."localisation_departement"  AS ld  ON ld.cle_obs = o.cle_obs
LEFT JOIN occtax."localisation_masse_eau"  AS lme  ON lme.cle_obs = o.cle_obs
LEFT JOIN occtax."v_localisation_espace_naturel"  AS len  ON len.cle_obs = o.cle_obs

WHERE True
GROUP BY o.cle_obs, o.nom_cite, t.nom_valide, t.reu, t.nom_vern, t.group1_inpn, t.group2_inpn, t.ordre, t.famille, t.protection, tv.url,
t.menace, t.rang, t.habitat,
o.cd_nom, o.date_debut, source_objet, o.geom, o.geom, od.diffusion, categorie,
tv.lb_nom, tv.nom_vern
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

-- recreation des dépendances
-- occtax.vm_stat_nb_taxons_observes_par_groupe_taxonomique
DROP VIEW IF EXISTS occtax.vm_stat_nb_taxons_observes_par_groupe_taxonomique;
CREATE VIEW occtax.vm_stat_nb_taxons_observes_par_groupe_taxonomique AS
SELECT row_number() OVER () AS id, categorie,
Count(DISTINCT o.cd_ref) AS nb_taxon_present
FROM occtax.vm_observation o
GROUP BY categorie
ORDER BY categorie
;

-- occtax.vm_stat_nb_observations_par_groupe_taxonomique
DROP VIEW IF EXISTS occtax.vm_stat_nb_observations_par_groupe_taxonomique;
CREATE VIEW occtax.vm_stat_nb_observations_par_groupe_taxonomique AS
SELECT
row_number() OVER () AS id, categorie,
Count(o.cle_obs) AS nbobs
FROM occtax.vm_observation o
GROUP BY categorie
ORDER BY categorie
;


-- occtax.v_observation_validation
DROP VIEW IF EXISTS occtax.v_observation_validation CASCADE;
CREATE VIEW occtax.v_observation_validation AS (
SELECT o.cle_obs,
o.identifiant_permanent,
o.statut_observation,
o.cd_nom,
o.cd_ref,
o.nom_cite,
o.nom_valide,
o.reu,
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
o.identite_observateur,
o.determinateur,
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
END AS validation_producteur
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


COMMIT;
