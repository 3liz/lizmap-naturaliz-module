-- Remplacement du test d'intersection sur les mailles 10
UPDATE occtax.critere_conformite
SET condition = $$
ST_Intersects(
    (SELECT ST_union(geom) FROM sig.maille_10),
    ST_Transform(
        ST_SetSRID(ST_MakePoint(o.longitude::real, o.latitude::real), __SOURCE_SRID__),
        (SELECT srid FROM geometry_columns WHERE f_table_schema = 'occtax' AND f_table_name = 'observation')
    )
)$$
WHERE code = 'obs_geometrie_localisation_dans_maille'
;

DROP FUNCTION IF EXISTS occtax.intersects_maille_10(real, real, integer);


-- Gestion des doublons: ajout des altitudes
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
            AND Coalesce(t.altitude_min::numeric(6,2), 0.0) = Coalesce(o.altitude_min, 0.0)
            AND Coalesce(t.altitude_moy::numeric(6,2), 0.0) = Coalesce(o.altitude_moy, 0.0)
            AND Coalesce(t.altitude_max::numeric(6,2), 0.0) = Coalesce(o.altitude_max, 0.0)
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
date_fin, heure_fin, geom, altitude_min, altitude_moy, altitude_max.'
;
