BEGIN;

-- GESTION
--
-- nomenclature
INSERT INTO g_nomenclature VALUES ('civilite', 'M', 'Monsieur', NULL, 1) ON CONFLICT (champ, code) DO NOTHING;
INSERT INTO g_nomenclature VALUES ('civilite', 'Mme', 'Madame', NULL, 2) ON CONFLICT (champ, code) DO NOTHING;
INSERT INTO g_nomenclature VALUES ('civilite', 'Mlle', 'Mademoiselle', NULL, 3) ON CONFLICT (champ, code) DO NOTHING;

INSERT INTO g_nomenclature VALUES ('statut_adhesion', 'Pré-adhérent', 'Pré-adhérent', NULL, 1) ON CONFLICT (champ, code) DO NOTHING;
INSERT INTO g_nomenclature VALUES ('statut_adhesion', 'Adhérent', 'Adhérent', NULL, 2) ON CONFLICT (champ, code) DO NOTHING;
INSERT INTO g_nomenclature VALUES ('statut_adhesion', 'Adhésion résiliée', 'Adhésion résiliée', NULL, 3) ON CONFLICT (champ, code) DO NOTHING;
INSERT INTO g_nomenclature VALUES ('statut_adhesion', 'Adhérent exclu', 'Adhérent exclu', NULL, 4) ON CONFLICT (champ, code) DO NOTHING;

INSERT INTO g_nomenclature VALUES ('statut_demande', 'A traiter', 'A traiter', NULL, 1) ON CONFLICT (champ, code) DO NOTHING;
INSERT INTO g_nomenclature VALUES ('statut_demande', 'Acceptée', 'Acceptée', NULL, 2) ON CONFLICT (champ, code) DO NOTHING;
INSERT INTO g_nomenclature VALUES ('statut_demande', 'Refusée', 'Refusée', NULL, 3) ON CONFLICT (champ, code) DO NOTHING;

INSERT INTO g_nomenclature VALUES ('type_echange_inpn', 'Import', 'Import', NULL, 1) ON CONFLICT (champ, code) DO NOTHING;
INSERT INTO g_nomenclature VALUES ('type_echange_inpn', 'Export', 'Export', NULL, 2) ON CONFLICT (champ, code) DO NOTHING;


CREATE TABLE IF NOT EXISTS gestion.echange_inpn
(
    id_echange serial NOT NULL PRIMARY KEY,
    date date,
    type text,
    description text,
    interlocuteur text,
    nb_donnees integer,
    commentaire text
)
;

COMMENT ON TABLE gestion.echange_inpn IS 'Table destinée à stocker les informations relatives aux échanges de données avec la plate-forme nationale SINP';

COMMENT ON COLUMN gestion.echange_inpn.id_echange IS 'Identifiant unique auto-incrémenté';
COMMENT ON COLUMN gestion.echange_inpn.date IS 'Date à laquelle l''échange a lieu (date du courriel de transmission)';
COMMENT ON COLUMN gestion.echange_inpn.type IS 'Type d''échange (export depuis Borbonica ou import dans Borbonica)';
COMMENT ON COLUMN gestion.echange_inpn.description IS 'Description littérale de l''échange';
COMMENT ON COLUMN gestion.echange_inpn.interlocuteur IS 'Coordonnées de l''interlorcuteur qui a envoyé les données (import) ou à qui elles sont destinées (export)';
COMMENT ON COLUMN gestion.echange_inpn.nb_donnees IS 'Nombre de données (observations) concernées par l''échange';
COMMENT ON COLUMN gestion.echange_inpn.commentaire IS 'Commentaire libre sur l''échange';

ALTER TABLE gestion.echange_inpn DROP CONSTRAINT IF EXISTS echange_inpn_type;
ALTER TABLE gestion.echange_inpn ADD CONSTRAINT echange_inpn_type
CHECK ( type IN ('Import', 'Export') );


-- OCCTAX
--

SET search_path TO occtax,taxon,sig,gestion,public;
--
-- VUE POUR OPTIMISATION
DROP MATERIALIZED VIEW IF EXISTS occtax.vm_observation CASCADE;

-- Vues pour les personnes
CREATE OR REPLACE VIEW v_observateur AS
SELECT
CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE p.identite END AS identite,
CASE WHEN p.anonymiser IS TRUE THEN '' ELSE p.mail END AS mail,
CASE WHEN p.anonymiser IS TRUE OR lower(p.identite) = lower(nom_organisme) THEN NULL ELSE Coalesce(nom_organisme, 'INCONNU') END AS organisme,
op.id_personne, op.cle_obs, p.prenom, p.nom, p.anonymiser,
p.identite AS identite_non_floutee,
p.mail AS mail_non_floute,
Coalesce(nom_organisme, 'INCONNU') AS organisme_non_floute

FROM observation_personne op
INNER JOIN personne p ON p.id_personne = op.id_personne AND op.role_personne = 'Obs'
INNER JOIN organisme o ON o.id_organisme = p.id_organisme
;

DROP VIEW IF EXISTS v_validateur;
CREATE VIEW v_validateur AS
SELECT CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE p.identite END AS identite,
CASE WHEN p.anonymiser IS TRUE THEN '' ELSE p.mail END AS mail,
CASE WHEN p.anonymiser IS TRUE OR lower(p.identite) = lower(nom_organisme) THEN NULL ELSE Coalesce(nom_organisme, 'INCONNU') END AS organisme,
p.id_personne, vv.identifiant_permanent, p.prenom, p.nom, p.anonymiser,
p.identite AS identite_non_floutee,
p.mail AS mail_non_floute,
Coalesce(nom_organisme, 'INCONNU') AS organisme_non_floute
FROM validation_observation vv
LEFT JOIN personne p ON vv.validateur = p.id_personne
LEFT JOIN organisme o ON p.id_organisme = o.id_organisme
WHERE ech_val = '2' -- uniquement validation de niveau régional
;

CREATE OR REPLACE VIEW v_determinateur AS
SELECT CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE p.identite END AS identite,
CASE WHEN p.anonymiser IS TRUE THEN '' ELSE p.mail END AS mail,
CASE WHEN p.anonymiser IS TRUE OR lower(p.identite) = lower(nom_organisme) THEN NULL ELSE Coalesce(nom_organisme, 'INCONNU') END AS organisme,
op.id_personne, op.cle_obs, p.prenom, p.nom, p.anonymiser,
p.identite AS identite_non_floutee,
p.mail AS mail_non_floute,
Coalesce(nom_organisme, 'INCONNU') AS organisme_non_floute
FROM observation_personne op
INNER JOIN personne p ON p.id_personne = op.id_personne AND op.role_personne = 'Det'
INNER JOIN organisme o ON o.id_organisme = p.id_organisme
;


-- VM_OBSERVATION
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

-- VUE POUR VALIDATION DES OBSERVATIONS
DROP VIEW IF EXISTS occtax.v_observation_validation;
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


-- Modifications tierces
-- 1. Ajout d'une colonne code_critere pour faciliter la gestion de la table critere_validation
----------------------------------------------------------------------------------------------
ALTER TABLE occtax.critere_validation ADD COLUMN code_critere TEXT ;
COMMENT ON COLUMN occtax.critere_validation.code_critere IS 'code du critère dans la base source (ex : tortues_marines_1)' ;
ALTER TABLE occtax.critere_validation ADD CONSTRAINT critere_validation_code_critere_unique UNIQUE(code_critere) ;


-- 2. Ajout d'une colonne code_critere pour faciliter la gestion de la table critere_sensibilite
----------------------------------------------------------------------------------------------
ALTER TABLE occtax.critere_sensibilite ADD COLUMN code_critere TEXT ;
COMMENT ON COLUMN occtax.critere_sensibilite.code_critere IS 'code du critère dans la base source (ex : sensibilite_528679)' ;
ALTER TABLE occtax.critere_sensibilite ADD CONSTRAINT critere_sensibilite_code_critere_unique UNIQUE(code_critere) ;

-- 3. Ajout d'une table occtax.cadre
---------------------------------------
CREATE TABLE occtax.cadre
(
    cadre_id TEXT NOT NULL,
    cadre_uuid TEXT NOT NULL,
    libelle TEXT NOT NULL,
    description TEXT,
    ayants_droit jsonb,
    date_lancement DATE,
    date_cloture DATE,
    CONSTRAINT cadre_pkey PRIMARY KEY (cadre_id)
)
;

COMMENT ON TABLE occtax.cadre
    IS 'Recense les cadres d''acquisition tels que renseignés dans l''application nationale https://inpn.mnhn.fr/mtd/. Un cadre d''acquisition regroupe de 1 à n jeux de données. On cherchera la cohérence dans le remplissage par rapport à ce qui est renseigné en ligne.';
COMMENT ON COLUMN occtax.cadre.cadre_id IS 'Identifiant unique du cadre d''acquisition attribué par la plate-forme nationale INPN (du type ''2393'').';
COMMENT ON COLUMN occtax.cadre.cadre_uuid IS 'Identifiant unique du cadre d''acquisition attribué par la plate-forme nationale INPN (au format UUID).';
COMMENT ON COLUMN occtax.cadre.libelle IS 'Nom complet du cadre d''acquisition' ;
COMMENT ON COLUMN occtax.cadre.description IS 'Description du cadre d''acquisition';
COMMENT ON COLUMN occtax.cadre.ayants_droit IS 'Liste et rôle des structures ayant des droits sur le jeu de données, et rôle concerné (ex : financeur, maître d''oeuvre, maître d''ouvrage, fournisseur...). Stocker les structures via leur id_organisme';
COMMENT ON COLUMN occtax.cadre.date_lancement IS 'Date de lancement du cadre d''acquisition' ;
COMMENT ON COLUMN occtax.cadre.date_cloture IS 'Date de clôture du cadre d''acquisition' ;

-- Index: cadre_cadre_id_idx
CREATE INDEX cadre_cadre_id_idx
    ON occtax.cadre USING btree
    (cadre_id)
    TABLESPACE pg_default;


COMMIT;
