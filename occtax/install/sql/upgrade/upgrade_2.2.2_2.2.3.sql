BEGIN;

-- AJOUT DU CHAMP id_maille serial pour améliorer les performances de requêtes par GROUP BY
ALTER TABLE sig.maille_05 DROP CONSTRAINT IF EXISTS maille_05_pkey;
ALTER TABLE sig.maille_05 ADD COLUMN IF NOT EXISTS id_maille serial;
ALTER TABLE sig.maille_05 ADD PRIMARY KEY (id_maille);
ALTER TABLE sig.maille_05 DROP CONSTRAINT IF EXISTS maille_05_code_maille_key;
ALTER TABLE sig.maille_05 ADD UNIQUE (code_maille);


ALTER TABLE sig.maille_10 DROP CONSTRAINT IF EXISTS maille_10_pkey;
ALTER TABLE sig.maille_10 ADD COLUMN IF NOT EXISTS id_maille serial;
ALTER TABLE sig.maille_10 ADD PRIMARY KEY (id_maille);
ALTER TABLE sig.maille_10 DROP CONSTRAINT IF EXISTS maille_10_code_maille_key;
ALTER TABLE sig.maille_10 ADD UNIQUE (code_maille);


-- VUE MATERIALISEE DE CONSOLIDATION DES DONNEES
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
t.nom_valide, t.reu, t.nom_vern, t.group1_inpn, t.group2_inpn, t.ordre, t.famille, t.protection, t.url,
(regexp_split_to_array( Coalesce( tgc1.cat_nom, tgc2.cat_nom, 'Autres' ), ' '))[1] AS categorie,
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

od.diffusion,
string_agg( DISTINCT concat(
    pobs.identite,
    CASE
        WHEN pobs.organisme = 'ANONYME' THEN ''
        ELSE ' (' || pobs.organisme|| ')'
    END
), ', ' ) AS identite_observateur,
string_agg( DISTINCT concat(
    pval.identite,
    CASE
        WHEN pval.organisme = 'ANONYME' THEN ''
        ELSE ' (' || pval.organisme|| ')'
    END
), ', ' ) AS validateur,
string_agg( DISTINCT concat(
    pdet.identite,
    CASE
        WHEN pdet.organisme = 'ANONYME' THEN ''
        ELSE ' (' || pdet.organisme|| ')'
    END
), ', ' ) AS determinateur

FROM occtax."observation"  AS o
JOIN  occtax."observation_diffusion"  AS od  ON od.cle_obs = o.cle_obs
LEFT JOIN taxon."taxref_consolide_non_filtre" AS t USING (cd_nom)
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
GROUP BY o.cle_obs, o.nom_cite, t.nom_valide, t.reu, t.nom_vern, t.group1_inpn, t.group2_inpn, t.ordre, t.famille, t.protection, t.url,
o.cd_nom, o.date_debut, source_objet, o.geom, o.geom, od.diffusion, categorie
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


COMMIT;
