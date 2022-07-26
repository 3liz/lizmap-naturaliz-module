DROP MATERIALIZED VIEW stats.chiffres_cles;
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
