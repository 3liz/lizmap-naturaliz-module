-- Fonction de test de conformité des observations d'une table au standard
-- Fonction de test de conformité des observations d'une table au standard
DROP FUNCTION IF EXISTS occtax.test_conformite_observation(regclass, text);
DROP FUNCTION IF EXISTS occtax.test_conformite_observation(regclass, text, integer);
CREATE OR REPLACE FUNCTION occtax.test_conformite_observation(
    _table_temporaire regclass,
    _type_critere text,
    _source_srid integer DEFAULT 4326
)
RETURNS TABLE (
    id_critere text,
    code text,
    libelle text,
    description text,
    condition text,
    nb_lines integer,
    ids text[]
) AS
$BODY$
DECLARE var_id_critere INTEGER;
DECLARE var_code TEXT;
DECLARE var_libelle TEXT;
DECLARE var_description TEXT;
DECLARE var_condition TEXT;
DECLARE var_table_jointure TEXT;
DECLARE sql_template TEXT;
DECLARE sql_text TEXT;
DECLARE rec record;

BEGIN

    -- Create temporary table to store the results
    CREATE TEMPORARY TABLE temp_results (
        id_critere text,
        code text,
        libelle text,
        description text,
        condition text,
        nb_lines integer,
        ids text[]
    ) ON COMMIT DROP
    ;

    -- On boucle sur les criteres
    FOR var_id_critere, var_code, var_libelle, var_description, var_condition, var_table_jointure IN
        SELECT c.id AS id_critere, c.code, c.libelle, c.description, c.condition, c.table_jointure
        FROM occtax.critere_conformite AS c
        WHERE type_critere = _type_critere
        ORDER BY c.id

    LOOP
        BEGIN
            sql_template := '
            INSERT INTO temp_results
            SELECT
                %s AS id_critere, %s AS code,
                %s AS libelle, %s AS description, %s AS condition,
                count(o.temporary_id) AS nb_lines,
                array_agg(o.id_origine::text) AS ids
            FROM %s AS o
            ';
            sql_text := format(
                sql_template,
                var_id_critere, quote_literal(var_code),
                quote_literal(var_libelle), quote_nullable(var_description),
                quote_literal(var_condition),
                _table_temporaire
            );

            -- optionally add the JOIN clause
            IF var_table_jointure IS NOT NULL THEN
                sql_template := '
                , %s AS t
                ';
                sql_text := sql_text || format(
                    sql_template,
                    var_table_jointure
                );
            END IF;

            -- Condition du critère
            sql_template :=  '
            WHERE True
            -- condition
            AND NOT (
                %s
            )
            ';
            sql_text := sql_text || format(
                sql_template,
                replace(var_condition, '__SOURCE_SRID__', _source_srid::text)
            );

            -- On récupère les données
            EXECUTE sql_text;
        EXCEPTION WHEN others THEN
            RAISE NOTICE '%', concat(var_code, ': ' , var_libelle, '. Description: ', var_description);
            RAISE NOTICE '%', SQLERRM;
            -- Log SQL
            RAISE NOTICE '%' , sql_text;
        END;

    END LOOP;

    RETURN QUERY SELECT * FROM temp_results;

END
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100
;


COMMENT ON FUNCTION occtax.test_conformite_observation(regclass, text, integer)
IS 'Tester la conformité des observations contenues dans la table fournie en paramètre
selon les critères stockés dans la table occtax.critere_conformite'
;



-- Test d'intersection entre un point et les mailles 10
DROP FUNCTION IF EXISTS occtax.intersects_maille_10(real, real, integer);
CREATE FUNCTION occtax.intersects_maille_10(longitude real, latitude real, _source_srid integer DEFAULT 4326) RETURNS BOOLEAN AS $$
DECLARE
    _srid integer;
    _nb_maille integer;
    _inside boolean;
BEGIN
    -- Avoid to test empty data
    IF longitude IS NULL AND latitude IS NULL THEN
        return true;
    END IF;

    -- Get observation table SRID
    SELECT srid
    INTO _srid
    FROM geometry_columns
    WHERE f_table_schema = 'occtax' AND f_table_name = 'observation'
    ;

    -- Intersects
    SELECT count(m.*)
    INTO _nb_maille
    FROM sig.maille_10 AS m
    WHERE True
    AND ST_Intersects(
        m.geom,
        ST_Transform(
            ST_SetSRID(ST_MakePoint(longitude, latitude), _source_srid),
            _srid
        )
    ) ;
    -- If there is an intersection, return True
    IF _nb_maille > 0 THEN
        RETURN True;
    ELSE
        RETURN False;
    END IF;

EXCEPTION WHEN others THEN
    return false;
END;
$$ LANGUAGE plpgsql
;

COMMENT ON FUNCTION occtax.intersects_maille_10(real, real, integer)
IS 'Tester si les géométries point issues de longitude et latitude sont contenus dans les mailles 10x10km.'
;

DROP FUNCTION IF EXISTS occtax.verification_doublons_avant_import(regclass, text, boolean, integer);
DROP FUNCTION IF EXISTS occtax.verification_doublons_avant_import(regclass, text, boolean, integer, text);
CREATE OR REPLACE FUNCTION occtax.verification_doublons_avant_import(
    _table_temporaire regclass,
    _jdd_uid text,
    _check_inside_this_jdd boolean,
    _source_srid integer DEFAULT 4326,
    _geometry_format text DEFAULT 'lonlat'
) RETURNS TABLE (
    duplicate_count integer,
    duplicate_ids text
) AS
$BODY$
DECLARE
    _srid integer;
    sql_template TEXT;
    sql_text TEXT;
BEGIN

    -- Get observation table SRID
    SELECT srid
    INTO _srid
    FROM geometry_columns
    WHERE f_table_schema = 'occtax' AND f_table_name = 'observation'
    ;

    -- Get ids of observation already in occtax.observation
    sql_template := '
    WITH source AS (
        SELECT DISTINCT t.id_origine
        FROM "%1$s" AS t
        INNER JOIN occtax.observation AS o
        ON (
            TRUE
    '
    ;
    sql_text = format(sql_template,
        _table_temporaire
    );

    -- Add equality checks to search for duplicates
    sql_template = '
            AND Coalesce(t.cd_nom::bigint, 0) = Coalesce(o.cd_nom, 0)
            AND Coalesce(t.date_debut::date, ''1980-01-01'') = Coalesce(o.date_debut, ''1980-01-01'')
            AND Coalesce(t.heure_debut::time with time zone, ''00:00'') = Coalesce(o.heure_debut, ''00:00'')
            AND Coalesce(t.date_fin::date, ''1980-01-01'') = Coalesce(o.date_fin, ''1980-01-01'')
            AND Coalesce(t.heure_fin::time with time zone, ''00:00'') = Coalesce(o.heure_fin, ''00:00'')
    '
    ;

    IF _geometry_format = 'lonlat' THEN
        -- longitude & latitude
        sql_template = sql_template || '
            AND Coalesce(ST_Transform(
                    ST_SetSRID(
                        ST_MakePoint(t.longitude::real, t.latitude::real),
                        %2$s
                    ),
                    %1$s
                ), ST_MakePoint(0, 0)) = Coalesce(o.geom, ST_MakePoint(0, 0))
            )
        '
        ;

    ELSE
        -- wkt
        sql_template = sql_template || '
            AND Coalesce(ST_Transform(
                    ST_SetSRID(
                        ST_GeomFromEWKT(''SRID=%2$s;'' || t.wkt),
                        %2$s
                    ),
                    %1$s
                ), ST_MakePoint(0, 0)) = Coalesce(o.geom, ST_MakePoint(0, 0))
            )
        '
        ;
    END IF
    ;
    sql_template = sql_template || '
        WHERE o.cle_obs IS NOT NULL
    '
    ;
    sql_text = sql_text || format(sql_template,
        _srid,
        _source_srid
    );

    -- If the jdd_uid is '__ALL__' check against the observations with another JDD UID
    -- Else check against the observation with the given JDD UID
    IF _check_inside_this_jdd IS TRUE THEN
        sql_template := '
            AND o.id_sinp_jdd = ''%1$s''
        ';
    ELSE
        sql_template := '
            AND o.id_sinp_jdd != ''%1$s''
        ';
    END IF;
    sql_text = sql_text || format(sql_template,
        _jdd_uid
    );

    -- Count results
    sql_text =  sql_text || '
    )
    SELECT
        count(id_origine)::integer AS duplicate_count,
        string_agg(id_origine::text, '', '' ORDER BY id_origine) AS duplicate_ids
    FROM source
    '
    ;

    RAISE NOTICE '%', sql_text;

    BEGIN
        -- On récupère les données
        RETURN QUERY EXECUTE sql_text;
    EXCEPTION WHEN others THEN
        RAISE NOTICE '%', SQLERRM;
        RAISE NOTICE '%' , sql_text;
        RETURN QUERY SELECT 0 AS duplicate_count, '' AS duplicate_ids;
    END;

END
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100
;

COMMENT ON FUNCTION occtax.verification_doublons_avant_import(regclass, text, boolean, integer, text)
IS 'Vérifie que les données en attente d''import (dans la table fournie en paramètre)
ne contiennent pas des données déjà existantes dans la table occtax.observation.
Les comparaisons sont faites sur les champs: cd_nom, date_debut, heure_debut,
date_fin, heure_fin, geom.'
;


-- Fonction d'import des données d'observation depuis la table temporaire vers occtax.observation
DROP FUNCTION IF EXISTS occtax.import_observations_depuis_table_temporaire(regclass, text, text, text);
DROP FUNCTION IF EXISTS occtax.import_observations_depuis_table_temporaire(regclass, text, text, text, text, text);
DROP FUNCTION IF EXISTS occtax.import_observations_depuis_table_temporaire(regclass, text, text, text, text);
DROP FUNCTION IF EXISTS occtax.import_observations_depuis_table_temporaire(regclass, text, text, text, text, integer);
DROP FUNCTION IF EXISTS occtax.import_observations_depuis_table_temporaire(regclass, text, text, text, text, integer, text);
CREATE OR REPLACE FUNCTION occtax.import_observations_depuis_table_temporaire(
    _table_temporaire regclass,
    _import_login text,
    _jdd_uid text,
    _organisme_gestionnaire_donnees text,
    _org_transformation text,
    _source_srid integer DEFAULT 4326,
    _geometry_format text DEFAULT 'lonlat'
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
    ';

    IF _geometry_format = 'lonlat' THEN
        -- longitude & latitude
        sql_template = sql_template || '
        ST_Transform(
            ST_SetSRID(
                ST_MakePoint(s.longitude::real, s.latitude::real),
                %8$s
            ),
            %7$s
        ) AS geom,
        '
        ;
    ELSE
        -- wkt
        sql_template = sql_template || '
        ST_Transform(
            ST_SetSRID(
                ST_GeomFromEWKT(''SRID=%8$s;'' || s.wkt),
                %8$s
            ),
            %7$s
        ) AS geom,
        '
        ;
    END IF
    ;

    sql_template = sql_template || '
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
        _srid,
        _source_srid
    );

    -- RAISE NOTICE '%', sql_text;
    -- Import
    RETURN QUERY EXECUTE sql_text;

END
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100
;


COMMENT ON FUNCTION occtax.import_observations_depuis_table_temporaire(regclass, text, text, text, text, integer, text)
IS 'Importe les observations contenues dans la table fournie en paramètre pour le JDD fourni et les organismes (gestionnaire, transformation et standardisation)'
;


-- Correction de certaines valeurs incorrectes
DELETE FROM occtax.critere_conformite WHERE code IN (
    'obs_identifiant_origine_not_null',
    'obs_identifiant_permanent_format',
    'obs_validite_niveau_valide',
    'obs_validite_niveau_format'
);

UPDATE occtax.critere_conformite
SET condition = $$occtax.intersects_maille_10(longitude::real, latitude::real, __SOURCE_SRID__)$$
WHERE code = 'obs_geometrie_localisation_dans_maille'
;

UPDATE occtax.critere_conformite SET condition = $$
    date_debut::date <= date_fin::date
    AND date_debut::date + Coalesce(nullif(heure_debut, ''), '0:00')::time <= date_fin::date + Coalesce(nullif(heure_fin, ''), '23:59')::time
    AND COALESCE(date_fin, date_debut)::date <= now()::date
$$
WHERE code = 'obs_dates_valide'
;

UPDATE occtax.critere_conformite SET condition = $$
    cd_nom IS NULL
    OR ( cd_nom IS NOT NULL AND cd_nom::bigint > 0 AND version_taxref IS NOT NULL)
    OR ( cd_nom IS NOT NULL AND cd_nom::bigint < 0 )
$$
WHERE code = 'obs_version_taxref_valide'
;

UPDATE occtax.critere_conformite SET condition = $$
    (statut_observation = 'No' AND COALESCE(denombrement_min::integer, 0) = 0 AND COALESCE(denombrement_max::integer, 0) = 0)
    OR (
            statut_observation = 'Pr'
            AND (denombrement_min::integer <> 0 OR denombrement_min IS NULL)
            AND (denombrement_max::integer <> 0 OR denombrement_max IS NULL)
    )
    OR statut_observation = 'NSP'
$$

WHERE code = 'obs_statut_observation_et_denombrement_valide'
;

INSERT INTO occtax.critere_conformite
(code, libelle, "description", condition, type_critere)
VALUES
('obs_validation_validateur_valide_format', 'La valeur de <b>validation_validateur</b> n''est pas conforme',
'Le champ <b>validation_validateur</b> doit être du type: "NOM Prénom (Organisme 1)" ou "INCONNU (Indépendant)". Il doit contenir une personne valide si "validite_niv_val" est renseigné.',
$$(
    (validation_niv_val IS NOT NULL AND occtax.is_valid_identite_multiple(Coalesce(validation_validateur, 'invalide')))
    OR validation_niv_val IS NULL )
$$, 'conforme'
)
ON CONFLICT DO NOTHING
;


UPDATE occtax.critere_conformite SET condition = $$
    COALESCE(denombrement_min::integer, 0) <= COALESCE(denombrement_max::integer, 0)
    OR denombrement_max IS NULL
$$
WHERE code = 'obs_denombrement_min_max_valide'
;



-- Attributs additionnels
ALTER TABLE occtax.attribut_additionnel
DROP CONSTRAINT IF EXISTS attribut_additionnel_type_valide;
ALTER TABLE occtax.attribut_additionnel
ADD CONSTRAINT attribut_additionnel_type_valide
CHECK (type IS NULL OR (type = ANY (ARRAY['QTA'::text, 'QUAL'::text, 'NSP'::text])))
;
ALTER TABLE occtax.attribut_additionnel ALTER COLUMN type SET DEFAULT 'NSP';
ALTER TABLE occtax.attribut_additionnel ALTER COLUMN thematique SET DEFAULT 'Inconnu';


-- Importe les données complémentaires (observateurs, liens spatiaux, etc.)
DROP FUNCTION IF EXISTS occtax.import_observations_post_data(regclass, text, text);
DROP FUNCTION IF EXISTS occtax.import_observations_post_data(regclass, text, text, text);
DROP FUNCTION IF EXISTS occtax.import_observations_post_data(regclass, text, text, text, text, date, text);
DROP FUNCTION IF EXISTS occtax.import_observations_post_data(regclass, text, text, text, text, date, text, text);
DROP FUNCTION IF EXISTS occtax.import_observations_post_data(regclass, text, text, text, text, date, text, text, integer);
DROP FUNCTION IF EXISTS occtax.import_observations_post_data(regclass, text, text, text, text, date, text, text, integer, text);
DROP FUNCTION IF EXISTS occtax.import_observations_post_data(regclass, text, text, text, text, date, text, text, text);
CREATE OR REPLACE FUNCTION occtax.import_observations_post_data(
    _table_temporaire regclass,
    _import_login text, _jdd_uid text, _default_email text,
    _libelle_import text, _date_reception date, _remarque_import text,
    _import_user_email text,
    _attributs_additionnels text DEFAULT '[]'
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
    _result_regional jsonb;
    _result_information jsonb;
    _aa_champ text; _aa_nom text; _aa_definition text;
    _aa_unite text; _aa_thematique text; _aa_type text;
BEGIN
    -- Get jdd_id from uid
    SELECT jdd_id
    INTO _jdd_id
    FROM occtax.jdd WHERE id_sinp_jdd = _jdd_uid
    ;

    -- Initialisation de la variable JSON de retour à {}
    _result_information := jsonb_build_object();

    -- table occtax.lien_observation_identifiant_permanent
    -- Conservation des liens entre les identifiants origine et les identifiants permanents
    sql_template := '
    WITH ins AS (
        INSERT INTO occtax.lien_observation_identifiant_permanent
        (jdd_id, id_origine, id_sinp_occtax, dee_date_derniere_modification, dee_date_transformation)
        SELECT o.jdd_id, o.id_origine, o.id_sinp_occtax, o.dee_date_derniere_modification, o.dee_date_transformation
        FROM occtax.observation o
        WHERE True
            AND o.jdd_id IN (''%1$s'')
            AND o.odata->>''import_temp_table'' = ''%2$s''
            AND o.odata->>''import_login'' = ''%3$s''
        ON CONFLICT ON CONSTRAINT lien_observation_id_sinp_occtax_jdd_id_id_origine_id_key
        DO NOTHING
        RETURNING id_origine
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
    _result_information := _result_information || jsonb_build_object('liens', _nb_lignes);

    -- table occtax.attribut_additionnel
    -- Si l'utilisateur a ajouté un fichier CSV décrivant les attributs

    -- On récupère d'abord les informations des attributs
    IF _attributs_additionnels IS NOT NULL THEN
        -- RAISE NOTICE '%', _attributs_additionnels;
        FOR _aa_champ, _aa_nom, _aa_definition, _aa_unite, _aa_thematique, _aa_type IN
            SELECT
                nom_champ_du_csv, nom_attribut, definition_attribut,
                unite_attribut, thematique_attribut, type_attribut
            FROM json_to_recordset(_attributs_additionnels::json)
                AS a(
                    nom_champ_du_csv text, nom_attribut text, definition_attribut text,
                    thematique_attribut text, type_attribut text, unite_attribut text
                )
        LOOP
            -- RAISE NOTICE '% - %', _aa_champ, _aa_nom;
            sql_template := '
            WITH ins AS (
                INSERT INTO occtax.attribut_additionnel (
                    cle_obs,
                    nom, definition, valeur,
                    unite, thematique, type
                )
                SELECT
                    o.cle_obs,
                    Coalesce(%5$s, %4$s) AS nom,
                    Coalesce(%6$s, %5$s, %4$s) AS definition,
                    Coalesce(trim(t.odata->>%4$s), ''NSP'') AS valeur,
                    Coalesce(%7$s, ''NSP'') AS unite,
                    Coalesce(%8$s, ''NSP'') AS thematique,
                    Coalesce(%9$s, ''NSP'') AS type

                FROM occtax.observation AS o
                JOIN "%2$s" AS t
                    ON t.id_origine = o.id_origine
                WHERE True
                    AND o.jdd_id IN (''%1$s'')
                    AND o.odata->>''import_temp_table'' = ''%2$s''
                    AND o.odata->>''import_login'' = ''%3$s''
                    -- il faut avoir une valeur
                    AND nullif(trim(t.odata->>%4$s), '''') IS NOT NULL
                ON CONFLICT ON CONSTRAINT attribut_additionnel_pkey
                DO NOTHING
                RETURNING cle_obs
            ) SELECT count(*) AS nb FROM ins
            ;
            ';
            sql_text := format(sql_template,
                _jdd_id,
                _table_temporaire,
                _import_login,
                quote_literal(_aa_champ),
                quote_literal(_aa_nom),
                quote_literal(_aa_definition),
                quote_literal(_aa_unite),
                quote_literal(_aa_thematique),
                quote_literal(_aa_type)
            );
            -- RAISE NOTICE '-- table occtax.attribut_additionnel';
            -- RAISE NOTICE '%', sql_text;
            EXECUTE sql_text INTO _nb_lignes;
        END LOOP;

        -- RAISE NOTICE 'occtax.attribut_additionnel: %', _nb_lignes;
        _result_information := _result_information || jsonb_build_object('attributs_additionnels', _nb_lignes);
    END IF;


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
            UNION
            SELECT DISTINCT validation_validateur AS personnes
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
            UNION
            SELECT DISTINCT validation_validateur AS personnes
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
                AND o.id_sinp_jdd = ''%3$s''
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
            -- on enlève le s final pour créer le nom du champ à nommer
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
                id_sinp_occtax,
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
                o.id_sinp_occtax,
                Coalesce(s.validation_date_ctrl::date, now()::date) AS date_ctrl,
                Coalesce(NuLLif(s.validation_niv_val::text, ''), '6') AS niv_val,
                Coalesce(Nullif(s.validation_typ_val::text, ''), 'M') AS typ_val,
                Coalesce(Nullif(s.validation_ech_val::text, ''), '2') AS ech_val,
                '1' AS peri_val,
                op.id_personne AS validateur,
                (SELECT "procedure" FROM occtax.validation_procedure ORDER BY id DESC LIMIT 1) AS "procedure",
                (SELECT proc_vers FROM occtax.validation_procedure ORDER BY id DESC LIMIT 1) AS proc_vers,
                (SELECT proc_ref FROM occtax.validation_procedure ORDER BY id DESC LIMIT 1) AS proc_ref,
                'Données validées pendant l''import CSV du ' || now()::date::text
            FROM occtax.observation AS o
            INNER JOIN "%1$s" AS s
                ON o.id_origine = s.id_origine::text
            INNER JOIN occtax.personne AS op
                ON s.validation_validateur = concat(op.identite, ' (', (SELECT nom_organisme FROM occtax.organisme og WHERE og.id_organisme = op.id_organisme), ')')
            WHERE True
                AND o.odata->>'import_temp_table' = '%1$s'
                AND o.jdd_id IN ('%2$s')
                AND o.odata->>'import_login' = '%3$s'
            ON CONFLICT ON CONSTRAINT validation_observation_id_sinp_occtax_ech_val_unique
            DO NOTHING
		    RETURNING id_sinp_occtax
        ) SELECT count(*) AS nb FROM ins
    $$;
    sql_text := format(sql_template,
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


    -- Adaptations régionales
    -- Lancement de la fonction occtax.import_observations_post_data_regionale
    sql_template := '
        SELECT occtax.import_observations_post_data_regionale(''%1$s'') AS json_regional
    ';
    sql_text := format(sql_template,
        _jdd_id
    );
    -- RAISE NOTICE '-- nettoyage';
    -- RAISE NOTICE '%', sql_text;
    EXECUTE sql_text INTO _result_regional;
    _result_information := _result_information || _result_regional;



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


COMMENT ON FUNCTION occtax.import_observations_post_data(regclass, text, text, text, text, date, text, text, text)
IS 'Importe les données complémentaires (observateurs, liens spatiaux, validation, etc.)
sur les observations contenues dans la table fournie en paramètre'
;


-- Supprime les données importées (nettoyage)
DROP FUNCTION IF EXISTS occtax.import_supprimer_observations_importees(text, text);
CREATE OR REPLACE FUNCTION occtax.import_supprimer_observations_importees(
    _table_temporaire text,
    _jdd_uid text
)
RETURNS BOOLEAN AS
$BODY$
DECLARE
    _jdd_id TEXT;
BEGIN
    -- Get jdd_id from uid
    SELECT jdd_id
    INTO _jdd_id
    FROM occtax.jdd WHERE id_sinp_jdd = _jdd_uid
    ;

    -- Nettoyage
    DELETE FROM occtax.localisation_commune WHERE cle_obs IN (
        SELECT cle_obs FROM occtax.observation
        WHERE jdd_id = _jdd_id AND odata->>'import_temp_table' = _table_temporaire::text
    );
    DELETE FROM occtax.localisation_departement WHERE cle_obs IN (
        SELECT cle_obs FROM occtax.observation
        WHERE jdd_id = _jdd_id AND odata->>'import_temp_table' = _table_temporaire::text
    );
    DELETE FROM occtax.localisation_espace_naturel WHERE cle_obs IN (
        SELECT cle_obs FROM occtax.observation
        WHERE jdd_id = _jdd_id AND odata->>'import_temp_table' = _table_temporaire::text
    );
    DELETE FROM occtax.localisation_habitat WHERE cle_obs IN (
        SELECT cle_obs FROM occtax.observation
        WHERE jdd_id = _jdd_id AND odata->>'import_temp_table' = _table_temporaire::text
    );
    DELETE FROM occtax.localisation_maille_01 WHERE cle_obs IN (
        SELECT cle_obs FROM occtax.observation
        WHERE jdd_id = _jdd_id AND odata->>'import_temp_table' = _table_temporaire::text
    );
    DELETE FROM occtax.localisation_maille_02 WHERE cle_obs IN (
        SELECT cle_obs FROM occtax.observation
        WHERE jdd_id = _jdd_id AND odata->>'import_temp_table' = _table_temporaire::text
    );
    DELETE FROM occtax.localisation_maille_05 WHERE cle_obs IN (
        SELECT cle_obs FROM occtax.observation
        WHERE jdd_id = _jdd_id AND odata->>'import_temp_table' = _table_temporaire::text
    );
    DELETE FROM occtax.localisation_maille_10 WHERE cle_obs IN (
        SELECT cle_obs FROM occtax.observation
        WHERE jdd_id = _jdd_id AND odata->>'import_temp_table' = _table_temporaire::text
    );
    DELETE FROM occtax.localisation_masse_eau WHERE cle_obs IN (
        SELECT cle_obs FROM occtax.observation
        WHERE jdd_id = _jdd_id AND odata->>'import_temp_table' = _table_temporaire::text
    );
    DELETE FROM occtax.observation_personne WHERE cle_obs IN (
        SELECT cle_obs FROM occtax.observation
        WHERE jdd_id = _jdd_id AND odata->>'import_temp_table' = _table_temporaire::text
    );
    DELETE FROM occtax.observation
    WHERE jdd_id IN (_jdd_id) AND odata->>'import_temp_table' = _table_temporaire::text;

    RETURN True;

END
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100
;

COMMENT ON FUNCTION occtax.import_supprimer_observations_importees(text, text)
IS 'Suppression des données importées, utile si un souci a été rencontré lors de la procédure. Elle attend en paramètre la table temporaire et le JDD UUID.'
;
