-- Ajout des contraintes sur la table

-- obs_dates_valides
ALTER TABLE occtax.observation DROP CONSTRAINT IF EXISTS obs_dates_valides;
ALTER TABLE occtax.observation ADD CONSTRAINT obs_dates_valides CHECK (
    date_debut::date <= date_fin::date
    AND date_debut::date + Coalesce(heure_debut, '0:00')::time <= date_fin::date + Coalesce(heure_fin, '23:59')::time
    AND (COALESCE(date_fin, date_debut) <= date_determination OR date_determination IS NULL)
    AND COALESCE(date_fin, date_debut) <= now()::date
    AND (COALESCE(date_fin, date_debut) <= validite_date_validation OR validite_date_validation IS NULL)
    AND COALESCE(date_fin, date_debut) <= dee_date_transformation
    AND dee_date_transformation <= dee_date_derniere_modification
);

-- obs_version_taxref_valide
ALTER TABLE occtax.observation DROP CONSTRAINT IF EXISTS obs_version_taxref_valide;
ALTER TABLE occtax.observation ADD CONSTRAINT obs_version_taxref_valide CHECK (
    cd_nom IS NULL
    OR ( cd_nom IS NOT NULL AND cd_nom > 0 AND version_taxref IS NOT NULL)
    OR ( cd_nom IS NOT NULL AND cd_nom < 0 )
);

-- obs_statut_observation_et_denombrement_valide
ALTER TABLE occtax.observation DROP CONSTRAINT IF EXISTS obs_statut_observation_et_denombrement_valide;
ALTER TABLE occtax.observation ADD CONSTRAINT obs_statut_observation_et_denombrement_valide CHECK (
    (statut_observation = 'No' AND COALESCE(denombrement_min, 0) = 0 AND COALESCE(denombrement_max, 0) = 0)
    OR (
            statut_observation = 'Pr'
            AND (denombrement_min <> 0 OR denombrement_min IS NULL)
            AND (denombrement_max <> 0 OR denombrement_max IS NULL)
    )
    OR statut_observation = 'NSP'
);

-- obs_denombrement_min_max_valide
ALTER TABLE occtax.observation DROP CONSTRAINT IF EXISTS obs_denombrement_min_max_valide;
ALTER TABLE occtax.observation ADD CONSTRAINT obs_denombrement_min_max_valide CHECK (
    COALESCE(denombrement_min, 0) <= COALESCE(denombrement_max, 0)
    OR denombrement_max IS NULL
);

-- obs_objet_denombrement_valide
ALTER TABLE occtax.observation DROP CONSTRAINT IF EXISTS obs_objet_denombrement_valide;
ALTER TABLE occtax.observation ADD CONSTRAINT obs_objet_denombrement_valide CHECK (
    ( denombrement_min IS NOT NULL AND denombrement_max IS NOT NULL AND objet_denombrement IN ('COL', 'CPL', 'HAM', 'IND', 'NID', 'NSP', 'PON', 'SURF', 'TIGE', 'TOUF')  )
    OR (denombrement_min IS NULL AND denombrement_max IS NULL AND Coalesce(objet_denombrement, 'NSP') = 'NSP')
);

-- clés étrangères jdd_id et jdd_code
ALTER TABLE occtax.observation DROP CONSTRAINT IF EXISTS observation_jdd_id_fk;
ALTER TABLE occtax.observation
    ADD CONSTRAINT observation_jdd_id_fk
    FOREIGN KEY (jdd_id) REFERENCES occtax.jdd (jdd_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE occtax.jdd ADD UNIQUE (jdd_code);
ALTER TABLE occtax.observation DROP CONSTRAINT IF EXISTS observation_jdd_code_fk;
ALTER TABLE occtax.observation
    ADD CONSTRAINT observation_jdd_code_fk
    FOREIGN KEY (jdd_code) REFERENCES occtax.jdd (jdd_code)
    ON DELETE RESTRICT ON UPDATE CASCADE
;


-- occtax.critere_conformite
--
-- obs_nature_objet_geo_valide
UPDATE occtax.critere_conformite
SET "condition" = $$(nature_objet_geo = ANY (ARRAY['St'::text, 'In'::text, 'NSP'::text]) )$$
WHERE code = 'obs_nature_objet_geo_valide' AND type_critere = 'conforme'
;

-- obs_dates_valide
UPDATE occtax.critere_conformite
SET "condition" = $$
    date_debut::date <= date_fin::date
    AND date_debut::date + Coalesce(nullif(heure_debut, ''), '0:00')::time <= date_fin::date + Coalesce(nullif(heure_fin, ''), '23:59')::time
    AND COALESCE(date_fin, date_debut) <= now()::date
$$
WHERE code = 'obs_dates_valide'
;

-- obs_version_taxref_valide
UPDATE occtax.critere_conformite
SET "condition" = $$
    cd_nom IS NULL
    OR ( cd_nom IS NOT NULL AND cd_nom > 0 AND version_taxref IS NOT NULL)
    OR ( cd_nom IS NOT NULL AND cd_nom < 0 )
$$
WHERE code = 'obs_version_taxref_valide'
;

INSERT INTO occtax.critere_conformite (code, libelle, description, condition, type_critere)
VALUES

-- obs_statut_observation_et_denombrement_valide
('obs_statut_observation_et_denombrement_valide', 'Les valeurs de valeur de <b>denombrement_min</b> et <b>denombrement_max</b> ne sont pas compatibles avec celle de <b>statut_observation</b>', 'Les dénombrements doivent valoir 0 ou NULL si le statut est "No" (non observé) ou "NSP", et être entières si le statut est "Pr" (présent)', $$
    (statut_observation = 'No' AND COALESCE(denombrement_min, 0) = 0 AND COALESCE(denombrement_max, 0) = 0)
    OR (
            statut_observation = 'Pr'
            AND (denombrement_min <> 0 OR denombrement_min IS NULL)
            AND (denombrement_max <> 0 OR denombrement_max IS NULL)
    )
    OR statut_observation = 'NSP'
$$, 'conforme'),
-- obs_denombrement_min_max_valide
('obs_denombrement_min_max_valide', 'Les valeurs de <b>denombrement_min</b> et <b>denombrement_max</b> ne sont pas conformes.', 'La valeur de <b>denombrement_min</b> doit être inférieure à celle de <b>denombrement_max</b>', $$
    COALESCE(denombrement_min, 0) <= COALESCE(denombrement_max, 0)
    OR denombrement_max IS NULL
$$, 'conforme')
;

-- obs_objet_denombrement_valide
UPDATE occtax.critere_conformite
SET "condition" = $$
    ( denombrement_min IS NOT NULL AND denombrement_max IS NOT NULL AND objet_denombrement IN ('COL', 'CPL', 'HAM', 'IND', 'NID', 'NSP', 'PON', 'SURF', 'TIGE', 'TOUF')  )
    OR (denombrement_min IS NULL AND denombrement_max IS NULL AND Coalesce(objet_denombrement, 'NSP') = 'NSP')
$$
WHERE code = 'obs_objet_denombrement_valide'
;


-- vues matérialisées
DELETE FROM occtax.materialized_object_list WHERE ob_name = 'observation_diffusion';
