
-- stats.avancement_imports
DROP MATERIALIZED VIEW IF EXISTS stats.avancement_imports;
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.avancement_imports AS
  WITH r AS (
         SELECT LEFT(serie.date::TEXT, 7) AS mois,
            count(DISTINCT o.jdd_id) AS nb_jdd,
            count(DISTINCT o.cle_obs) AS nb_obs
           FROM (SELECT generate_series(
               (SELECT date_trunc('month'::text, min(vm_observation.dee_date_transformation)) AS min FROM vm_observation),
               date_trunc('month'::text, now()),
               '1 mon'::interval
        ) AS date) serie
           LEFT JOIN vm_observation o ON date_trunc('month'::text, serie.date) = date_trunc('month'::text, o.dee_date_transformation)
          GROUP BY LEFT(serie.date::TEXT, 7)
          ORDER BY LEFT(serie.date::TEXT, 7)
        )
 SELECT r.mois,
    sum(r.nb_jdd) OVER (ORDER BY r.mois) AS nb_jdd,
    sum(r.nb_obs) OVER (ORDER BY r.mois) AS nb_obs
   FROM r
;

COMMENT ON MATERIALIZED VIEW stats.avancement_imports
    IS 'Nombre cumulé de données et de jeux de données importés dans Borbonica au fil du temps, traduisant la dynamique d''import dans Borbonica';


-- stats.chiffres_cles
DROP MATERIALIZED VIEW IF EXISTS stats.chiffres_cles;
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.chiffres_cles AS
  SELECT 1 AS ordre,
    'Nombre total de données'::text AS libelle,
    count(vm_observation.cle_obs) AS valeur
   FROM vm_observation
UNION
 SELECT 2 AS ordre,
    'Nombre total de jeux de données'::text AS libelle,
    count(DISTINCT vm_observation.jdd_code) AS valeur
   FROM vm_observation
UNION
 SELECT 3 AS ordre,
    'Nombre de producteurs ayant transmis des jeux de données'::text AS libelle,
    count(DISTINCT r.id_organisme) AS valeur
   FROM ( SELECT jdd.jdd_id,
            (jsonb_array_elements(jdd.ayants_droit) ->> 'id_organisme'::text)::integer AS id_organisme,
            jsonb_array_elements(jdd.ayants_droit) ->> 'role'::text AS role
           FROM jdd) r
UNION
 SELECT 4 AS ordre,
    'Nombre d''observateurs cités'::text AS libelle,
    count(DISTINCT p.nom || p.prenom) AS valeur
   FROM observation_personne op
     LEFT JOIN personne p USING (id_personne)
UNION
 SELECT 5 AS ordre,
    'Nombre de taxons faisant l''objet d''observations'::text AS libelle,
    count(DISTINCT vm_observation.cd_ref) AS valeur
   FROM vm_observation
UNION
 SELECT 6 AS ordre,
    'Nombre d''adhérents à la charte régionale SINP'::text AS libelle,
    count(adherent.id_adherent) AS valeur
   FROM adherent
  WHERE adherent.statut = 'Adhérent'::text
UNION
 SELECT 7 AS ordre,
    'Nombre de demandes d''accès aux données ouvertes'::text AS libelle,
    count(demande.id) AS valeur
   FROM demande
  WHERE demande.statut ~~* 'acceptée'::text
  ORDER BY 1;

COMMENT ON MATERIALIZED VIEW stats.chiffres_cles IS 'Divers chiffres clés traduisant l''activité du SINP';

