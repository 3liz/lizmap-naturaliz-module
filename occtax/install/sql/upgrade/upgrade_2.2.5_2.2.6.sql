BEGIN;

-- VALIDATION : vue et triggers pour validation par les validateurs agréés
DROP VIEW IF EXISTS occtax.v_observation_validation CASCADE;
CREATE VIEW occtax.v_observation_validation AS (
SELECT
-- Observation
cle_obs, identifiant_permanent, statut_observation,
--Taxon
cd_nom, cd_ref, nom_cite,
nom_valide, reu, nom_vern, group2_inpn, ordre, famille,
--Individus observés
denombrement_min, denombrement_max, objet_denombrement, type_denombrement,

-- Descriptif sujet
descriptif_sujet,

-- Preuve existante: on cherche dans descriptif_sujet. Si au moins une preuve n'est pas oui, on met Non
CASE
    WHEN descriptif_sujet IS NULL OR descriptif_sujet::text ~* '"preuve_existante": ("(0|2|3)"|null)'
        THEN 'Non'
    ELSE 'Oui'
END AS preuve_existante,
date_determination,
-- Quand ?
date_debut, date_fin, heure_debut, heure_fin,
--Où ?
geom, altitude_moy,  precision_geometrie, nature_objet_geo,
--Personnes
identite_observateur,
determinateur,
--Généralités
organisme_gestionnaire_donnees,
commentaire, code_idcnp_dispositif,  dee_date_transformation, dee_date_derniere_modification,
jdd_code, jdd_id, jdd_metadonnee_dee_id,
statut_source, reference_biblio,
-- Diffusion
ds_publique, diffusion_niveau_precision, sensi_niveau,
--Validation
v.id_validation, v.date_ctrl, v.niv_val, v.typ_val, v.ech_val, v.peri_val,
v.val_validateur AS validateur, v.proc_vers, v.producteur, v.date_contact, v."procedure",
v.proc_ref, v.comm_val

FROM vm_observation o
LEFT JOIN (
    SELECT vv.*,
    identite || concat(' - ' || mail, ' (' || organisme || ')' ) AS val_validateur
    FROM validation_observation vv
    LEFT JOIN personne p ON vv.validateur = p.id_personne
) v USING (identifiant_permanent)

)
;


COMMIT;
