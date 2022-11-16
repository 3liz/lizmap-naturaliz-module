-- Ajout d'un organisme avec id = -1 pour faciliter les imports (en évitant soucis de contraintes de clé étrangère)
INSERT INTO occtax.organisme (id_organisme, nom_organisme, commentaire)
VALUES (-1, 'Non défini', 'Organisme non défini. Utiliser pour éviter les soucis de contrainte de clé étrangère avec la table personne. Il faut utiliser l''organisme inconnu ou indépendant à la place')
ON CONFLICT DO NOTHING
;


-- Fonction de validation d'une identité unique
CREATE OR REPLACE FUNCTION occtax.is_valid_identite(identite text)
RETURNS TABLE (
  is_valid boolean,
  items text[]
) AS $$
DECLARE
    items text[];
BEGIN
    items = regexp_match(
        trim(identite),
        '^([A-Z\u00C0-\u00FF\- ]+) +([A-Za-z\u00C0-\u00FF\-\. ]+ +)?\((.+)\)$'
    );
    -- NB:
    -- Le premier bloc prend le nom
    -- le 2ème le prénom
    -- le point dans le deuxième bloc (pour le prénom) permet d'avoir une initiale
    -- suivie d'un point : DUPONT M. serait donc valide
    -- L'organisme est le troisième bloc attrapé

    -- Si on ne trouve rien via la regex, on renvoie FALSE
    IF items IS NULL THEN
        RETURN QUERY
        SELECT FALSE, NULL::text[] AS items
        -- LIMIT 1
        ;
        RETURN;
    END IF;

    -- On vérifie que le tableau de résultat a bien 3 items
    IF NOT (array_length(items, 1) = 3) THEN
        RETURN QUERY
        SELECT FALSE, NULL::text[] AS items
        -- LIMIT 1
        ;
        RETURN;
    END IF;

    -- Si le prénom est vide, il faut que le nom soit INCONNU
    IF (trim(items[2]) = '' OR trim(items[2]) IS NULL) AND trim(items[1]) != 'INCONNU' THEN
        RETURN QUERY
        SELECT FALSE, NULL::text[] AS items
        --LIMIT 1
        ;
        RETURN;
    END IF;

    -- Renvoie les données nettoyées
    RETURN QUERY
    SELECT TRUE, ARRAY[trim(items[1]), trim(items[2]), trim(items[3])]::text[] AS items
    ;

    RETURN;
END;
$$ LANGUAGE plpgsql
;

COMMENT ON FUNCTION occtax.is_valid_identite(text)
IS 'Tester si l''identite est conforme: NOM-SOUS-NOM Prénom Autre prénom (Organisme) ou  INCONNU (Organisme)'
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
        datasource:= format('
		WITH jdd_source AS (
            SELECT *
            FROM occtax.jdd
            WHERE jdd_id = %1$s
        ),
        delete_obs AS (
            DELETE
            FROM occtax.observation
            WHERE jdd_metadonnee_dee_id IN (
                SELECT jdd_metadonnee_dee_id
                FROM jdd_source
            )
		)
        SELECT
        1 AS id,
        ''Les observations du JDD "'' || j.jdd_code ||''" ont bien été supprimées'' AS message,
        NULL AS geom,
		FROM delete_obs AS d, jdd_source AS j
        ',
        feature_id
        );
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
