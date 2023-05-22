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


-- Assouplissement de la vérification des identités
CREATE OR REPLACE FUNCTION occtax.is_valid_identite(identite text)
RETURNS TABLE (
  is_valid boolean,
  items text[]
) AS $$
DECLARE
    items text[];
    organisme text;
BEGIN
    items = regexp_match(
        trim(identite),
        '^([A-Z\u00C0-\u00FF\- ]+) +([A-Za-z\u00C0-\u00FF\-\. ]+ *)?(\(.*\))?$'
    );
    -- NB:
    -- Le premier bloc prend le nom
    -- le 2ème le prénom
    -- le point dans le deuxième bloc (pour le prénom) permet d'avoir une initiale
    -- suivie d'un point : DUPONT M. serait donc valide
    -- L'organisme est le troisième bloc attrapé
    -- S'il n'est pas trouvé on remplace par (Inconnu)

    -- Si on ne trouve rien via la regex, on renvoie FALSE
    IF items IS NULL THEN
        RETURN QUERY
        SELECT FALSE, NULL::text[] AS items
        ;
        RETURN;
    END IF;

    -- Le nom doit être renseigné
    IF nullif(trim(items[1]), '') IS NULL THEN
        RETURN QUERY
        SELECT FALSE, NULL::text[] AS items
        ;
        RETURN;
    END IF;

    -- Si le prénom est vide, il faut que le nom soit INCONNU
    IF nullif(trim(items[2]), '') IS NULL AND trim(items[1]) != 'INCONNU' THEN
        RETURN QUERY
        SELECT FALSE, NULL::text[] AS items
        ;
        RETURN;
    END IF;

    -- Travail sur l'organisme
    organisme := Coalesce(trim(nullif(trim(items[3], ' ()'), '')), 'Inconnu');
    IF organisme IS NULL THEN
        organisme = 'Inconnu';
    END IF;

    -- Renvoie les données nettoyées
    -- Si l'organisme est vide, on renvoit 'Inconnu'
    RETURN QUERY
    SELECT TRUE, ARRAY[
        trim(items[1]),
        trim(items[2]),
        organisme
    ]::text[] AS items
    ;

    RETURN;
END;
$$ LANGUAGE plpgsql
;

COMMENT ON FUNCTION occtax.is_valid_identite(text)
IS 'Tester si l''identite est conforme: NOM-SOUS-NOM Prénom Autre prénom (Organisme) ou  INCONNU (Organisme).
Si l''organisme n''est pas trouvé, on le définit en (Inconnu) comme le prévoit le standard.'
;


CREATE OR REPLACE FUNCTION occtax.import_observations_depuis_table_temporaire(
    _table_temporaire regclass,
    _import_login text,
    _jdd_uid text,
    _organisme_gestionnaire_donnees text,
    _org_transformation text
)
RETURNS TABLE (
    cle_obs bigint,
    id_sinp_occtax text
) AS
$BODY$
DECLARE
    sql_template TEXT;
    sql_text TEXT;
    _jdd_id TEXT;
    _srid integer;
BEGIN
    -- Get jdd_id from uid
    SELECT jdd_id INTO _jdd_id
    FROM occtax.jdd WHERE id_sinp_jdd = _jdd_uid
    ;

    -- Get observation table SRID
    SELECT srid
    INTO _srid
    FROM geometry_columns
    WHERE f_table_schema = 'occtax' AND f_table_name = 'observation'
    ;

    -- Set occtax.observation sequence to the max of cle_obs
    PERFORM 'SELECT Setval(''occtax.observation_cle_obs_seq'', (SELECT max(cle_obs) FROM occtax.observation ) )';

    -- Buils INSERT SQL
    sql_template := '
    INSERT INTO occtax.observation
    (
        cle_obs,
        id_sinp_occtax,
        id_origine,

        statut_observation,
        cd_nom,
        cd_ref,
        cd_nom_cite,
        version_taxref,
        nom_cite,

        denombrement_min,
        denombrement_max,
        objet_denombrement,
        type_denombrement,

        commentaire,

        date_debut,
        date_fin,
        heure_debut,
        heure_fin,
        date_determination,

        dee_date_derniere_modification,
        dee_date_transformation,

        altitude_min,
        altitude_moy,
        altitude_max,
        profondeur_min,
        profondeur_moy,
        profondeur_max,

        dee_floutage,
        diffusion_niveau_precision,
        ds_publique,

        jdd_code,
        jdd_id,
        id_sinp_jdd,

        organisme_gestionnaire_donnees,
        org_transformation,
        statut_source,
        reference_biblio,

        sensi_date_attribution,
        sensi_niveau,
        sensi_referentiel,
        sensi_version_referentiel,

        descriptif_sujet,
        donnee_complementaire,

        precision_geometrie,
        nature_objet_geo,
        geom,

        odata
    )
    WITH info_jdd AS (
        SELECT * FROM occtax.jdd WHERE id_sinp_jdd = ''%1$s''
    ),
    organisme_responsable AS (
        SELECT
        $$%2$s$$ AS organisme_gestionnaire_donnees,
        $$%3$s$$ AS org_transformation
    ),
    source_sans_doublon AS (
        SELECT csv.*
        FROM "%5$s" AS csv, info_jdd AS j
        WHERE True
        AND csv.id_origine NOT IN
		(	SELECT o.id_origine
			FROM occtax.observation AS o
			WHERE True
			AND jdd_id = j.jdd_id
		)
    )
    SELECT
        nextval(''occtax.observation_cle_obs_seq''::regclass) AS cle_obs,
        -- C''est la plateforme régionale qui définit les id permanents
        -- sauf s''ils sont déjà définis en amont (Ex: export MNHN)
        CASE
            WHEN nullif(trim(s.id_sinp_occtax), '''') IS NOT NULL THEN trim(s.id_sinp_occtax)
            ELSE
                CASE
                    WHEN loip.id_sinp_occtax IS NOT NULL THEN loip.id_sinp_occtax
                    ELSE CAST(uuid_generate_v4() AS text)
                END
        END AS id_sinp_occtax,
        trim(s.id_origine),

        s.statut_observation,
        s.cd_nom::bigint,
        s.cd_nom::bigint AS cd_ref,
        s.cd_nom::bigint AS cd_nom_cite,
        trim(s.version_taxref),
        trim(s.nom_cite),

        s.denombrement_min::integer,
        s.denombrement_max::integer,
        s.objet_denombrement,
        s.type_denombrement,

        trim(s.commentaire),

        s.date_debut::date,
        s.date_fin::date,
        s.heure_debut::time with time zone,
        s.heure_fin::time with time zone,
        s.date_determination::date,

        now()::date AS dee_date_derniere_modification,
        now()::date AS dee_date_transformation,

        s.altitude_min::real,
        s.altitude_moy::real,
        s.altitude_max::real,
        s.profondeur_min::real,
        s.profondeur_moy::real,
        s.profondeur_max::real,

        s.dee_floutage AS dee_floutage,
        s.diffusion_niveau_precision AS diffusion_niveau_precision,
        s.ds_publique,

        j.jdd_code,
        j.jdd_id,
        j.id_sinp_jdd,

        org.organisme_gestionnaire_donnees AS organisme_gestionnaire_donnees,
        org.org_transformation AS org_transformation,

        s.statut_source,
        trim(s.reference_biblio),

        s.sensi_date_attribution::date,
        s.sensi_niveau::text,
        trim(s.sensi_referentiel),
        trim(s.sensi_version_referentiel),

        NULL descriptif_sujet,
        NULL AS donnee_complementaire,

        s.precision_geometrie::integer,
        s.nature_objet_geo,
        ST_Transform(
            ST_SetSRID(
                ST_MakePoint(s.longitude::real, s.latitude::real),
                %7$s
            ),
            %7$s
        ) AS geom,

        json_build_object(
            ''observateurs'', trim(s.observateurs),
            ''determinateurs'', trim(s.determinateurs),
            ''import_login'', ''%4$s'',
            ''import_temp_table'', ''%5$s'',
            ''import_time'', now()::timestamp(0)
        ) AS odata

    FROM
        info_jdd AS j,
        organisme_responsable AS org,
        source_sans_doublon AS s
        -- jointure pour récupérer les identifiants permanents si déjà créés lors d''un import passé
        LEFT JOIN occtax.lien_observation_identifiant_permanent AS loip
            ON loip.jdd_id = ''%6$s''
            AND loip.id_origine = s.id_origine::TEXT

    ON CONFLICT DO NOTHING
    RETURNING cle_obs, id_sinp_occtax
    ';
    sql_text := format(sql_template,
        _jdd_uid,
        _organisme_gestionnaire_donnees,
        _org_transformation,
        _import_login,
        _table_temporaire,
        _jdd_id,
        _srid
    );

    -- RAISE NOTICE '%', sql_text;
    -- Import
    RETURN QUERY EXECUTE sql_text;

END
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100
;


COMMENT ON FUNCTION occtax.import_observations_depuis_table_temporaire(regclass, text, text, text, text)
IS 'Importe les observations contenues dans la table fournie en paramètre pour le JDD fourni et les organismes (gestionnaire, transformation et standardisation)'
;

-- vues matérialisées
DELETE FROM occtax.materialized_object_list WHERE ob_name = 'observation_diffusion';
