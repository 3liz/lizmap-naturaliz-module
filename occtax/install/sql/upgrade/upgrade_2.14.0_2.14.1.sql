-- Vue pour exploiter les personnes
CREATE OR REPLACE VIEW occtax.v_personne AS
SELECT
p.id_personne,
p.prenom, p.nom, p.anonymiser,
CASE
    WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE p.identite
END AS identite,
CASE
    WHEN p.anonymiser IS TRUE THEN '' ELSE p.mail
END AS mail,
CASE
    WHEN p.anonymiser IS TRUE OR lower(p.identite) = lower(nom_organisme) THEN NULL ELSE Coalesce(nom_organisme, 'INCONNU')
END AS organisme,
p.identite AS identite_non_floutee,
p.mail AS mail_non_floute,
Coalesce(nom_organisme, 'INCONNU') AS organisme_non_floute,
concat(p.identite, ' (', Coalesce(nom_organisme, 'INCONNU'), ')') AS identite_complete_non_floutee
FROM occtax.personne p
INNER JOIN occtax.organisme o
    ON o.id_organisme = p.id_organisme
;

COMMENT ON VIEW occtax.v_personne
IS 'Vue qui simplifie l''utilisation des données de la table personne';


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


DROP FUNCTION IF EXISTS occtax.import_observations_depuis_table_temporaire(regclass, text, text, text);
DROP FUNCTION IF EXISTS occtax.import_observations_depuis_table_temporaire(regclass, text, text, text, text, text);
CREATE OR REPLACE FUNCTION occtax.import_observations_depuis_table_temporaire(
    _table_temporaire regclass,
    _import_login text,
    _jdd_uid text,
    _organisme_gestionnaire_donnees text,
    _org_transformation text,
    _organisme_standard text
)
RETURNS TABLE (
    cle_obs bigint,
    identifiant_permanent text
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
    FROM occtax.jdd WHERE jdd_metadonnee_dee_id = _jdd_uid
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
        identifiant_permanent,
        identifiant_origine,

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
        jdd_metadonnee_dee_id,
        jdd_source_id,

        organisme_gestionnaire_donnees,
        org_transformation,
        statut_source,
        reference_biblio,

        sensible,
        sensi_date_attribution,
        sensi_niveau,
        sensi_referentiel,
        sensi_version_referentiel,

        descriptif_sujet,
        donnee_complementaire,

        precision_geometrie,
        nature_objet_geo,
        geom,

        odata,

        organisme_standard
    )
    WITH info_jdd AS (
        SELECT * FROM occtax.jdd WHERE jdd_metadonnee_dee_id = ''%1$s''
    ),
    organisme_responsable AS (
        SELECT
        $$%2$s$$ AS organisme_gestionnaire_donnees,
        $$%3$s$$ AS org_transformation,
        $$%4$s$$ AS organisme_standard
    ),
    source_sans_doublon AS (
        SELECT csv.*
        FROM "%6$s" AS csv, info_jdd AS j
        WHERE True
        AND csv.identifiant_origine NOT IN
		(	SELECT o.identifiant_origine
			FROM occtax.observation AS o
			WHERE True
			AND jdd_id = j.jdd_id
		)
    )
    SELECT
        nextval(''occtax.observation_cle_obs_seq''::regclass) AS cle_obs,
        -- C''est la plateforme régionale qui définit les id permanents
        CASE
            WHEN loip.identifiant_permanent IS NOT NULL THEN loip.identifiant_permanent
            ELSE CAST(uuid_generate_v4() AS text)
        END AS identifiant_permanent,
        s.identifiant_origine,

        s.statut_observation,
        s.cd_nom::bigint,
        s.cd_nom::bigint AS cd_ref,
        s.cd_nom::bigint AS cd_nom_cite,
        s.version_taxref,
        s.nom_cite,

        s.denombrement_min::integer,
        s.denombrement_max::integer,
        s.objet_denombrement,
        s.type_denombrement,

        s.commentaire,

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
        j.jdd_metadonnee_dee_id,
        NULL AS jdd_source_id,

        org.organisme_gestionnaire_donnees AS organisme_gestionnaire_donnees,
        org.org_transformation AS org_transformation,

        s.statut_source,
        s.reference_biblio,

        s.sensible,
        s.sensi_date_attribution::date,
        s.sensi_niveau::text,
        s.sensi_referentiel,
        s.sensi_version_referentiel,

        NULL descriptif_sujet,
        NULL AS donnee_complementaire,

        s.precision_geometrie::integer,
        s.nature_objet_geo,
        ST_Transform(
            ST_SetSRID(
                ST_MakePoint(s.longitude::real, s.latitude::real),
                %8$s
            ),
            %8$s
        ) AS geom,

        json_build_object(
            ''observateurs'', s.observateurs,
            ''determinateurs'', s.determinateurs,
            ''import_login'', ''%5$s'',
            ''import_temp_table'', ''%6$s'',
            ''import_time'', now()::timestamp(0)
        ) AS odata,

        org.organisme_standard AS organisme_standard

    FROM
        info_jdd AS j,
        organisme_responsable AS org,
        source_sans_doublon AS s
        -- jointure pour récupérer les identifiants permanents si déjà créés lors d''un import passé
        LEFT JOIN occtax.lien_observation_identifiant_permanent AS loip
            ON loip.jdd_id = ''%7$s''
            AND loip.identifiant_origine = s.identifiant_origine::TEXT

    ON CONFLICT DO NOTHING
    RETURNING cle_obs, identifiant_permanent
    ';
    sql_text := format(sql_template,
        _jdd_uid,
        _organisme_gestionnaire_donnees,
        _org_transformation,
        _organisme_standard,
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


COMMENT ON FUNCTION occtax.import_observations_depuis_table_temporaire(regclass, text, text, text, text, text)
IS 'Importe les observations contenues dans la table fournie en paramètre pour le JDD fourni et les organismes (gestionnaire, transformation et standardisation)'
;



-- Importe les données complémentaires (observateurs, liens spatiaux, etc.)
DROP FUNCTION IF EXISTS occtax.import_observations_post_data(regclass, text, text);
DROP FUNCTION IF EXISTS occtax.import_observations_post_data(regclass, text, text, text);
DROP FUNCTION IF EXISTS occtax.import_observations_post_data(regclass, text, text, text, text, date, text);
DROP FUNCTION IF EXISTS occtax.import_observations_post_data(regclass, text, text, text, text, date, text, text);
DROP FUNCTION IF EXISTS occtax.import_observations_post_data(regclass, text, text, text, text, date, text, text, integer);
CREATE OR REPLACE FUNCTION occtax.import_observations_post_data(
    _table_temporaire regclass,
    _import_login text, _jdd_uid text, _default_email text,
    _libelle_import text, _date_reception date, _remarque_import text,
    _import_user_email text,
    _validateur integer
)
RETURNS TABLE (
    import_report json
) AS
$BODY$
DECLARE
    sql_template TEXT;
    sql_text TEXT;
    _import_status boolean;
    _import_report json;
    _jdd_id TEXT;
    _nom_type_personne text;
    _nom_role_personne text;
    _set_val integer;
    _nb_lignes integer;
    _result_information jsonb;
BEGIN
    -- Get jdd_id from uid
    SELECT jdd_id
    INTO _jdd_id
    FROM occtax.jdd WHERE jdd_metadonnee_dee_id = _jdd_uid
    ;

    -- table occtax.lien_observation_identifiant_permanent
    -- Conservation des liens entre les identifiants origine et les identifiants permanents
    sql_template := '
    WITH ins AS (
        INSERT INTO occtax.lien_observation_identifiant_permanent
        (jdd_id, identifiant_origine, identifiant_permanent, dee_date_derniere_modification, dee_date_transformation)
        SELECT o.jdd_id, o.identifiant_origine, o.identifiant_permanent, o.dee_date_derniere_modification, o.dee_date_transformation
        FROM occtax.observation o
        WHERE True
            AND o.jdd_id IN (''%1$s'')
            AND o.odata->>''import_temp_table'' = ''%2$s''
            AND o.odata->>''import_login'' = ''%3$s''
        ON CONFLICT ON CONSTRAINT lien_observation_identifiant__jdd_id_identifiant_origine_id_key
        DO NOTHING
        RETURNING identifiant_origine
    ) SELECT count(*) AS nb FROM ins
    ;
    ';
    sql_text := format(sql_template,
        _jdd_id,
        _table_temporaire,
        _import_login
    );
    -- RAISE NOTICE '-- table occtax.lien_observation_identifiant_permanent';
    -- RAISE NOTICE '%', sql_text;
    EXECUTE sql_text INTO _nb_lignes;
    -- RAISE NOTICE 'occtax.organisme: %', _nb_lignes;
    _result_information := jsonb_build_object('liens', _nb_lignes);

    -- Table occtax.organisme
    SELECT setval('occtax.organisme_id_organisme_seq', (SELECT max(id_organisme) FROM occtax.organisme))
    INTO _set_val;
    sql_template := '
    WITH ins AS (
        WITH personnes AS (
            SELECT DISTINCT observateurs AS personnes
            FROM %1$s
            UNION
            SELECT DISTINCT determinateurs AS personnes
            FROM %1$s
        ),
        personne AS (
            SELECT DISTINCT trim(regexp_split_to_table(personnes, '','')) AS personne
            FROM personnes
        ),
        valide AS (
            SELECT
                personne, v.*
            FROM personne, occtax.is_valid_identite(personne) AS v
        )
        INSERT INTO occtax.organisme (nom_organisme)
        SELECT DISTINCT items[3]
        FROM valide AS v
        WHERE is_valid
        ON CONFLICT DO NOTHING
		RETURNING nom_organisme
    ) SELECT count(*) AS nb FROM ins
    ;
    ';
    sql_text := format(sql_template,
        _table_temporaire
    );
    -- RAISE NOTICE '-- table occtax.organisme';
    -- RAISE NOTICE '%', sql_text;
    EXECUTE sql_text INTO _nb_lignes;
    -- RAISE NOTICE 'occtax.organisme: %', _nb_lignes;
    _result_information := _result_information || jsonb_build_object('organismes', _nb_lignes);

    -- Table occtax.personne
    SELECT setval('occtax.personne_id_personne_seq', (SELECT max(id_personne) FROM occtax.personne))
    INTO _set_val;
    sql_template := '
    WITH ins AS (
        WITH personnes AS (
            SELECT DISTINCT observateurs AS personnes
            FROM %1$s
            UNION
            SELECT DISTINCT determinateurs AS personnes
            FROM %1$s
        ),
        personne AS (
            SELECT DISTINCT trim(regexp_split_to_table(personnes, '','')) AS personne
            FROM personnes
        ),
        valide AS (
            SELECT
                personne, v.*
            FROM personne, occtax.is_valid_identite(personne) AS v
        )
        INSERT INTO occtax.personne (identite, nom, prenom, mail, id_organisme)
        SELECT DISTINCT
            concat(items[1], '' '' || items[2]) AS identite,
            items[1] AS nom,
            items[2] AS prenom,
            ''%2$s'' AS mail,
            o.id_organisme
        FROM valide AS v
        LEFT JOIN occtax.organisme AS o
            ON o.nom_organisme = items[3]
        WHERE is_valid
        ON CONFLICT DO NOTHING
		RETURNING identite
    ) SELECT count(*) AS nb FROM ins
    ;
    ';
    sql_text := format(sql_template,
        _table_temporaire,
        _default_email
    );
    -- RAISE NOTICE '-- table occtax.personne';
    -- RAISE NOTICE '%', sql_text;
    EXECUTE sql_text INTO _nb_lignes;
    -- RAISE NOTICE 'occtax.personne: %', _nb_lignes;
    _result_information := _result_information || jsonb_build_object('personnes', _nb_lignes);

    -- Table occtax.observation_personne
    -- observateurs & déterminateurs
    FOR _nom_type_personne, _nom_role_personne IN
        SELECT 'observateurs' AS nom, 'Obs' AS typ
        UNION
        SELECT 'determinateurs' AS nom, 'Det' AS typ
    LOOP
        sql_template := '
        WITH ins AS (
            INSERT INTO occtax.observation_personne (cle_obs, id_personne, role_personne)
            WITH source AS (
                SELECT
                cle_obs,
                o.odata->>''%1$s'' AS odata_%1$s,
                trim(%1$s) AS %2$s, rn
                FROM
                occtax.observation AS o,
                regexp_split_to_table(o.odata->>''%1$s'', '','')  WITH ORDINALITY x(%1$s, rn)
                WHERE True
                AND o.odata->>''%1$s'' IS NOT NULL
                AND o.jdd_metadonnee_dee_id = ''%3$s''
                ORDER BY o.cle_obs, rn
            )
            SELECT
                s.cle_obs, p.id_personne, ''%4$s'' AS role_personne
            FROM source AS s
            JOIN occtax.personne AS p
                ON s.%2$s = concat(p.identite, '' ('', (SELECT nom_organisme FROM occtax.organisme og WHERE og.id_organisme = p.id_organisme), '')'')
            ORDER BY cle_obs, rn
            ON CONFLICT DO NOTHING
		    RETURNING cle_obs, id_personne, role_personne
        ) SELECT count(*) AS nb FROM ins
        ;
        ';
        sql_text := format(sql_template,
            _nom_type_personne,
            -- on enlève le s final
            substr(_nom_type_personne, 1, length(_nom_type_personne) - 1),
            _jdd_uid,
            _nom_role_personne
        );
        -- RAISE NOTICE '-- table occtax.observation_personne, %', _nom_type_personne;
        -- RAISE NOTICE '%', sql_text;
        EXECUTE sql_text INTO _nb_lignes;
        -- RAISE NOTICE '  lignes: %', _nb_lignes;
        _result_information := _result_information || jsonb_build_object(_nom_type_personne, _nb_lignes);

    END LOOP;

    -- Relations spatiales
    sql_template := '
        SELECT occtax.occtax_update_spatial_relationships(ARRAY[''%1$s'']) AS update_spatial;
    ';
    sql_text := format(sql_template,
        _jdd_id
    );
    -- RAISE NOTICE '-- update_spatial';
    -- RAISE NOTICE '%', sql_text;
    EXECUTE sql_text INTO _nb_lignes;
    _result_information := _result_information || jsonb_build_object('update_spatial', _nb_lignes);

    -- Informations de validation
    sql_template := $$
        WITH ins AS (
            INSERT INTO occtax.validation_observation (
                identifiant_permanent,
                date_ctrl,
                niv_val,
                typ_val,
                ech_val,
                peri_val,
                validateur,
                "procedure",
                proc_vers,
                proc_ref,
                comm_val
            )
            SELECT
                o.identifiant_permanent,
                Coalesce(s.validation_date_ctrl::date, now()::date) AS date_ctrl,
                Coalesce(NuLLif(s.validation_niv_val::text, ''), '6') AS niv_val,
                Coalesce(Nullif(s.validation_typ_val::text, ''), 'M') AS typ_val,
                Coalesce(Nullif(s.validation_ech_val::text, ''), '2') AS ech_val,
                '1' AS peri_val,
                %1$s AS validateur,
                (SELECT "procedure" FROM occtax.validation_procedure ORDER BY id DESC LIMIT 1) AS "procedure",
                (SELECT proc_vers FROM occtax.validation_procedure ORDER BY id DESC LIMIT 1) AS proc_vers,
                (SELECT proc_ref FROM occtax.validation_procedure ORDER BY id DESC LIMIT 1) AS proc_ref,
                'Données validées pendant l''import CSV du ' || now()::date::text
            FROM occtax.observation AS o
            INNER JOIN "%2$s" AS s
                ON o.identifiant_origine = s.identifiant_origine::text
            WHERE True
                AND o.odata->>'import_temp_table' = '%2$s'
                AND o.jdd_id IN ('%3$s')
                AND o.odata->>'import_login' = '%4$s'
            ON CONFLICT ON CONSTRAINT validation_observation_identifiant_permanent_ech_val_unique
            DO NOTHING
		    RETURNING identifiant_permanent
        ) SELECT count(*) AS nb FROM ins
    $$;
    sql_text := format(sql_template,
        _validateur,
        _table_temporaire,
        _jdd_id,
        _import_login
    );
    -- RAISE NOTICE '-- nettoyage';
    -- RAISE NOTICE '%', sql_text;
    EXECUTE sql_text INTO _nb_lignes;
    _result_information := _result_information || jsonb_build_object('validation', _nb_lignes);


    -- Log d'import: table occtax.jdd_import
    -- Table import
    sql_template := '
    WITH rapport AS (
        SELECT
            count(*) AS nb_importe,
            min(date_debut::date) AS date_obs_min,
            max(Coalesce(date_fin::date, date_debut::date)) AS date_obs_max
        FROM "%1$s"
    ),
    acteur_connecte AS (
        SELECT id_acteur
        FROM gestion.acteur
        WHERE courriel = trim($$%6$s$$)
        LIMIT 1
    ),
    ins AS (
        INSERT INTO occtax.jdd_import (
            jdd_id,
            libelle, remarque, date_reception,
            date_import, nb_donnees_source, nb_donnees_import,
            date_obs_min, date_obs_max,
            acteur_referent,
            acteur_importateur
        )
        SELECT
            $$%2$s$$,
            $$%3$s$$, $$%4$s$$, $$%5$s$$,
            now()::date, r.nb_importe, r.nb_importe,
            date_obs_min, date_obs_max,
            -1,
            CASE
                WHEN ac.id_acteur IS NOT NULL
                    THEN ac.id_acteur
                ELSE -1
            END AS acteur_importateur
        FROM rapport AS r
		LEFT JOIN acteur_connecte AS ac ON True
        LIMIT 1
        RETURNING id_import
    ) SELECT count(*) AS nb FROM ins
    ;
    ';
    sql_text := format(sql_template,
        _table_temporaire,
        _jdd_id,
        _libelle_import, _remarque_import, _date_reception,
        _import_user_email
    );
    -- RAISE NOTICE '-- nettoyage';
    -- RAISE NOTICE '%', sql_text;
    EXECUTE sql_text INTO _nb_lignes;
    _result_information := _result_information || jsonb_build_object('jdd_import', _nb_lignes);


    -- Nettoyage
    sql_template := '
    WITH ins AS (
        UPDATE occtax.observation
        SET odata = odata - ''observateurs'' - ''determinateurs''
        WHERE True
        AND jdd_id = ''%1$s''
        AND odata->>''import_temp_table'' = ''%2$s''
        AND odata->>''import_login'' = ''%3$s''
        RETURNING cle_obs
    ) SELECT count(*) AS nb FROM ins
    ;
    ';
    sql_text := format(sql_template,
        _jdd_id,
        _table_temporaire::text,
        _import_login
    );
    -- RAISE NOTICE '-- nettoyage';
    -- RAISE NOTICE '%', sql_text;
    EXECUTE sql_text INTO _nb_lignes;
    _result_information := _result_information || jsonb_build_object('clean', _nb_lignes);

    -- Return information
    RETURN QUERY SELECT _result_information::json;

    RETURN;

END
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100
;


COMMENT ON FUNCTION occtax.import_observations_post_data(regclass, text, text, text, text, date, text, text, integer)
IS 'Importe les données complémentaires (observateurs, liens spatiaux, validation, etc.)
sur les observations contenues dans la table fournie en paramètre'
;



DROP FUNCTION IF EXISTS public.lizmap_get_data(json);
CREATE OR REPLACE FUNCTION public.lizmap_get_data(parameters json)
RETURNS json AS
$$
DECLARE
    feature_id integer;
    layer_name text;
    layer_table text;
    layer_schema text;
    action_name text;
    sqltext text;
    datasource text;
    ajson json;
BEGIN

    action_name:= parameters->>'action_name';
    feature_id:= (parameters->>'feature_id')::integer;
    layer_name:= parameters->>'layer_name';
    layer_schema:= parameters->>'layer_schema';
    layer_table:= parameters->>'layer_table';

    IF action_name = 'supprimer_observations_import_csv' THEN
        datasource:= format('
		WITH get_import AS (
            SELECT
            %1$s AS id,
			jdd, date_import, code_import, login_import nombre_observations,
            ''Les '' || "nombre_observations" || '' observations de cet import du '' || "date_import" || '' par '' || "login_import" || '' ont été supprimées'' AS message,
            geom
            FROM "%2$s"."%3$s"
            WHERE id = %1$s
		), action_import AS (
			SELECT occtax.import_supprimer_observations_importees(code_import, jdd) AS nb_action
			FROM get_import
		)
		SELECT g.*, a.*
		FROM get_import AS g, action_import AS a
        ',
        feature_id,
        layer_schema,
        layer_table
        );

	ELSEIF action_name = 'activer_observations_import_csv' THEN
        datasource:= format('
		WITH get_import AS (
            SELECT
            %1$s AS id,
			jdd, date_import, code_import, login_import nombre_observations,
            ''Les '' || "nombre_observations" || '' observations de cet import du '' || "date_import" || '' par '' || "login_import" || '' ont été activées'' AS message,
            geom
            FROM "%2$s"."%3$s"
            WHERE id = %1$s
		), action_import AS (
			SELECT occtax.import_activer_observations_importees(code_import, jdd)
			FROM get_import
		)
		SELECT g.*, a.*
		FROM get_import AS g, action_import AS a
        ',
        feature_id,
        layer_schema,
        layer_table
        );
	ELSEIF action_name = 'delete_jdd_observations' THEN
        -- On ne peut pas utiliser SELECT query_to_geojson(datasource)
        -- car le DELETE doit être au plus haut niveau
        -- TODO: faire une fonction qui supprime les données d'un JDD ?
        -- Ici, feature_id représente le jdd_id
        WITH
        delete_obs AS (
            DELETE
            FROM occtax.observation
            WHERE jdd_metadonnee_dee_id IN (
                SELECT jdd_metadonnee_dee_id
                FROM occtax.jdd
                WHERE jdd_id::text = feature_id::text
            )
            RETURNING cle_obs
        ),
        jdd_source AS (
            SELECT *
            FROM occtax.jdd
            WHERE jdd_id::text = feature_id::text
        ),
        inputs AS (
            SELECT
            1 AS id,
            'Les ' || count(d.cle_obs) || ' observations du JDD "' || max(j.jdd_code) ||'" ont bien été supprimées' AS message,
            NULL AS geom
                FROM delete_obs AS d, jdd_source AS j
            GROUP BY id
        ),
        features AS (
        SELECT jsonb_build_object(
            'type',       'Feature',
            'id',         id,
            'geometry',   ST_AsGeoJSON(ST_Transform(geom, 4326))::jsonb,
            'properties', to_jsonb(inputs) - 'geom'
        ) AS feature
        FROM inputs
        )
        SELECT jsonb_build_object(
            'type',  'FeatureCollection',
            'features', jsonb_agg(features.feature)
        )::json
        INTO ajson
        FROM features
        ;
        RETURN ajson;

	ELSEIF action_name = 'refresh_materialized_views' THEN
        datasource:= '
		WITH refresh_views AS (
            SELECT occtax.manage_materialized_objects(''refresh'', True, NULL) AS ok
        ),
        fin AS (
            SELECT
            1 AS id,
            ''Les vues matérialisées ont bien été rafraîchies'' AS message,
            NULL AS geom,
            r.ok
            FROM refresh_views AS r
		)
		SELECT *
		FROM fin
        ';
    ELSE
    -- Default : return geometry
        datasource:= format('
            SELECT
            %1$s AS id,
            ''Action par défaut: la géométrie de l objet est affichée'' AS message,
            geom
            FROM "%2$s"."%3$s"
            WHERE id = %1$s
        ',
        feature_id,
        layer_schema,
        layer_table
        );

    END IF;
	RAISE NOTICE 'SQL = %', datasource;

    SELECT query_to_geojson(datasource)
    INTO ajson
    ;
    RETURN ajson;
END;
$$
LANGUAGE 'plpgsql'
VOLATILE STRICT;

COMMENT ON FUNCTION public.lizmap_get_data(json)
IS 'Generate a valid GeoJSON from an action described by a name,
PostgreSQL schema and table name of the source data, a QGIS layer name, a feature id and additional options.';
