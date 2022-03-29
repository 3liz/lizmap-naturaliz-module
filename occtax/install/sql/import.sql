
-- Stockage des critères de conformité au standard
DROP TABLE IF EXISTS occtax.critere_conformite;
CREATE TABLE occtax.critere_conformite (
    id serial not null PRIMARY KEY,
    code text NOT NULL,
    type_critere text NOT NULL,
    libelle text NOT NULL,
    description text,
    condition text NOT NULL,
    table_jointure text,
    ordre smallint,
    CONSTRAINT critere_conformite_unique_code UNIQUE (code)
);

COMMENT ON TABLE occtax.critere_conformite
IS 'Liste les critères de conformité des données à importer dans la table occtax.observation'
;

-- Fonction de validation d'une identité unique
DROP FUNCTION IF EXISTS occtax.is_valid_identite(identite text);
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
        '^([A-Z\u00C0-\u00FF\- ]+) +([A-Za-z\u00C0-\u00FF\- ]+ +)?\((.+)\)$'
    );

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


-- Fonction de validation d'une identité multiple (identités séparées par virgule)
DROP FUNCTION IF EXISTS occtax.is_valid_identite_multiple(identites text);
CREATE OR REPLACE FUNCTION occtax.is_valid_identite_multiple(identites text)
RETURNS boolean AS $$
DECLARE
    var_is_valid boolean;
    var_items text[];
BEGIN
    -- On sépare par virgule
    FOR var_is_valid, var_items IN
        WITH a AS (
            SELECT regexp_split_to_array(identites, ',') AS personnes
        ),
        -- on sépare en enregistrements
        b AS (
            SELECT * FROM a, unnest(personnes) AS personne
        ),
        c AS (
            SELECT * FROM b, occtax.is_valid_identite(personne)
        )
        SELECT is_valid, items FROM c

    LOOP
        IF NOT var_is_valid THEN
            RETURN False;
        END IF;
    END LOOP;

    RETURN True;
END;
$$ LANGUAGE plpgsql
;

COMMENT ON FUNCTION occtax.is_valid_identite_multiple(text)
IS 'Tester si un champ contenant des personnes séparées par virgule est conforme selon le standard SINP. Ex: DUPONT Jean (Inconnu), INCONNU (Organisme)'
;


-- Fonction de validation de types de données
CREATE OR REPLACE FUNCTION occtax.is_given_type(s text, t text) RETURNS BOOLEAN AS $$
BEGIN
    -- Avoid to test empty strings
    s = Nullif(s, '');
    IF s IS NULL THEN
        return true;
    END IF;

    -- Test to cast the string to the given type
    IF t = 'date' THEN
        PERFORM s::date;
        RETURN true;
    ELSIF t = 'time' THEN
        PERFORM s::time;
        RETURN true;
    ELSIF t = 'integer' THEN
        PERFORM s::integer;
        RETURN true;
    ELSIF t = 'real' THEN
        PERFORM s::real;
        RETURN true;
    ELSIF t = 'text' THEN
        PERFORM s::text;
        RETURN true;
    ELSIF t = 'uuid' THEN
        PERFORM s::uuid;
        RETURN true;
    ELSE
        RETURN true;
    END IF;
EXCEPTION WHEN others THEN
    return false;
END;
$$ LANGUAGE plpgsql
;

COMMENT ON FUNCTION occtax.is_given_type(text, text)
IS 'Tester si le contenu d''un champ est du type attendu'
;

CREATE OR REPLACE FUNCTION occtax.intersects_maille_10(longitude real, latitude real) RETURNS BOOLEAN AS $$
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
            ST_SetSRID(ST_MakePoint(longitude, latitude), _srid),
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

COMMENT ON FUNCTION occtax.intersects_maille_10(real, real)
IS 'Tester si les géométries point issues de longitude et latitude sont contenus dans les mailles 10x10km.'
;


-- Fonction de test de conformité des observations d'une table au standard
DROP FUNCTION IF EXISTS occtax.test_conformite_observation(regclass, text);
CREATE OR REPLACE FUNCTION occtax.test_conformite_observation(_table_temporaire regclass, _type_critere text)
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
                array_agg(o.identifiant_origine::text) AS ids
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
            sql_text := sql_text || format(sql_template, var_condition);

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


COMMENT ON FUNCTION occtax.test_conformite_observation(regclass, text)
IS 'Tester la conformité des observations contenues dans la table fournie en paramètre selon les critères stockés dans la table occtax.critere_conformite'
;


-- Données de test de conformité
-- critere_conformite
TRUNCATE TABLE occtax.critere_conformite RESTART IDENTITY;

-- Ajout des contraintes sur les types de champs attendus: format, non null, occtax
INSERT INTO occtax.critere_conformite (code, libelle, condition, type_critere)
VALUES
('obs_identifiant_permanent_format', 'Le format de <b>identifiant_permanent</b> est incorrect. Attendu: uuid' , $$occtax.is_given_type(identifiant_permanent, 'uuid')$$, 'format'),
('obs_cd_nom_format', 'Le format de <b>cd_nom</b> est incorrect. Attendu: entier' , $$occtax.is_given_type(cd_nom, 'integer')$$, 'format'),
('obs_cd_ref_format', 'Le format de <b>cd_ref</b> est incorrect. Attendu: entier' , $$occtax.is_given_type(cd_ref, 'integer')$$, 'format'),
('obs_denombrement_min_format', 'Le format de <b>denombrement_min</b> est incorrect. Attendu: entier' , $$occtax.is_given_type(denombrement_min, 'integer')$$, 'format'),
('obs_denombrement_max_format', 'Le format de <b>denombrement_max</b> est incorrect. Attendu: entier' , $$occtax.is_given_type(denombrement_max, 'integer')$$, 'format'),
('obs_date_debut_format', 'Le format de <b>date_debut</b> est incorrect. Attendu: date JJ/MM/AAAA' , $$occtax.is_given_type(date_debut, 'date')$$, 'format'),
('obs_date_fin_format', 'Le format de <b>date_fin</b> est incorrect. Attendu: date  JJ/MM/AAAA' , $$occtax.is_given_type(date_fin, 'date')$$, 'format'),
('obs_heure_debut_format', 'Le format de <b>heure_debut</b> est incorrect. Attendu: heure HH:MM' , $$occtax.is_given_type(heure_debut, 'time')$$, 'format'),
('obs_heure_fin_format', 'Le format de <b>heure_fin</b> est incorrect. Attendu: heure HH:MM' , $$occtax.is_given_type(heure_fin, 'time')$$, 'format'),
('obs_date_determination_format', 'Le format de <b>date_determination</b> est incorrect. Attendu: date JJ/MM/AAAA' , $$occtax.is_given_type(date_determination, 'date')$$, 'format'),
('obs_altitude_min_format', 'Le format de <b>altitude_min</b> est incorrect. Attendu: numérique' , $$occtax.is_given_type(altitude_min, 'real')$$, 'format'),
('obs_altitude_max_format', 'Le format de <b>altitude_max</b> est incorrect. Attendu: numérique' , $$occtax.is_given_type(altitude_max, 'real')$$, 'format'),
('obs_altitude_moy_format', 'Le format de <b>altitude_moy</b> est incorrect. Attendu: numérique' , $$occtax.is_given_type(altitude_moy, 'real')$$, 'format'),
('obs_profondeur_min_format', 'Le format de <b>profondeur_min</b> est incorrect. Attendu: numérique' , $$occtax.is_given_type(profondeur_min, 'real')$$, 'format'),
('obs_profondeur_max_format', 'Le format de <b>profondeur_max</b> est incorrect. Attendu: numérique' , $$occtax.is_given_type(profondeur_max, 'real')$$, 'format'),
('obs_profondeur_moy_format', 'Le format de <b>profondeur_moy</b> est incorrect. Attendu: numérique' , $$occtax.is_given_type(profondeur_moy, 'real')$$, 'format'),
('obs_sensi_date_attribution_format', 'Le format de <b>sensi_date_attribution</b> est incorrect. Attendu: date JJ/MM/AAAA' , $$occtax.is_given_type(sensi_date_attribution, 'date')$$, 'format'),
('obs_validite_niveau_format', 'Le format de <b>validite_niveau</b> est incorrect. Attendu: entier' , $$occtax.is_given_type(validite_niveau, 'integer')$$, 'format'),
('obs_validite_date_validation_format', 'Le format de <b>validite_date_validation</b> est incorrect. Attendu: date' , $$occtax.is_given_type(validite_date_validation, 'date')$$, 'format'),
('obs_longitude_format', 'Le format de <b>longitude</b> est incorrect. Attendu: numérique' , $$occtax.is_given_type(longitude, 'real')$$, 'format'),
('obs_latitude_format', 'Le format de <b>latitude</b> est incorrect. Attendu: numérique' , $$occtax.is_given_type(latitude, 'real')$$, 'format'),
('obs_precision_geometrie_format', 'Le format de <b>precision_geometrie</b> est incorrect. Attendu: entier' , $$occtax.is_given_type(precision_geometrie, 'integer')$$, 'format')

ON CONFLICT ON CONSTRAINT critere_conformite_unique_code DO NOTHING
;

-- Ajout des contraintes sur les champs issus de la table occtax.observation

-- NOT NULL
INSERT INTO occtax.critere_conformite (code, libelle, condition, type_critere)
VALUES
('obs_observateurs_not_null', 'La valeur de <b>observateurs</b> est vide', $$observateurs IS NOT NULL$$, 'not_null'),
('obs_statut_observation_not_null', 'La valeur de <b>statut_observation</b> est vide', $$statut_observation IS NOT NULL$$, 'not_null'),
('obs_denombrement_min_not_null', 'La valeur de <b>denombrement_min</b> est vide', $$denombrement_min IS NOT NULL$$, 'not_null'),
('obs_denombrement_max_not_null', 'La valeur de <b>denombrement_max</b> est vide', $$denombrement_max IS NOT NULL$$, 'not_null'),
('obs_nom_cite_not_null', 'La valeur de <b>nom_cite</b> est vide', $$nom_cite IS NOT NULL$$, 'not_null'),
('obs_date_debut_not_null', 'La valeur de <b>date_debut</b> est vide', $$date_debut IS NOT NULL$$, 'not_null'),
('obs_date_fin_not_null', 'La valeur de <b>date_fin</b> est vide', $$date_fin IS NOT NULL$$, 'not_null'),
('obs_ds_publique_not_null', 'La valeur de <b>ds_publique</b> est vide', $$ds_publique IS NOT NULL$$, 'not_null'),
('obs_identifiant_origine_not_null', 'La valeur de <b>identifiant_origine</b> est vide', $$identifiant_origine IS NOT NULL$$, 'not_null'),
('obs_statut_source_not_null', 'La valeur de <b>statut_source</b> est vide', $$statut_source IS NOT NULL$$, 'not_null'),
('obs_sensible_not_null', 'La valeur de <b>sensible</b> est vide', $$sensible IS NOT NULL$$, 'not_null'),
('obs_sensi_niveau_not_null', 'La valeur de <b>sensi_niveau</b> est vide', $$sensi_niveau IS NOT NULL$$, 'not_null'),
('obs_longitude_not_null', 'La valeur de <b>longitude</b> est vide', $$longitude IS NOT NULL$$, 'not_null'),
('obs_latitude_not_null', 'La valeur de <b>latitude</b> est vide', $$latitude IS NOT NULL$$, 'not_null'),
('obs_nature_objet_geo_not_null', 'La valeur de <b>nature_objet_geo</b> est vide', $$nature_objet_geo IS NOT NULL$$, 'not_null')

ON CONFLICT ON CONSTRAINT critere_conformite_unique_code DO NOTHING
;

-- CHECK
INSERT INTO occtax.critere_conformite (code, libelle, description, condition, type_critere)
VALUES
('obs_statut_source_valide', 'La valeur de <b>statut_source</b> n''est pas conforme', 'Le champ <b>statut_source</b> doit correspondre à la nomenclature', $$( statut_source IN ( 'Te', 'Co', 'Li', 'NSP' ) )$$, 'conforme'),
('obs_reference_biblio_valide', 'La valeur de <b>reference_biblio</b> n''est pas conforme', 'Le champ <b>reference_biblio</b> doit être renseignée si le champ <b>statut_source</b> vaut Li', $$( (statut_source = 'Li' AND reference_biblio IS NOT NULL) OR statut_source != 'Li' )$$, 'conforme'),
('obs_ds_publique_valide', 'La valeur de <b>ds_publique</b> n''est pas conforme', 'Le champ <b>ds_publique</b> doit correspondre à la nomenclature', $$( ds_publique IN ( 'Pu', 'Re', 'Ac', 'Pr', 'NSP' ) )$$, 'conforme'),
('obs_statut_observation_valide', 'La valeur de <b>statut_observation</b> n''est pas conforme', 'Le champ <b>statut_observation</b> doit correspondre à la nomenclature', $$( statut_observation IN ( 'Pr', 'No', 'NSP' ) )$$, 'conforme'),
('obs_objet_denombrement_valide', 'La valeur de <b>objet_denombrement</b> n''est pas conforme', 'Le champ <b>objet_denombrement</b> doit être différent de NSP si les champs <b>denombrement_min</b> ou <b>denombrement_max</b> sont renseignés', $$(
    ( denombrement_min IS NOT NULL AND denombrement_max IS NOT NULL AND objet_denombrement IN ('COL', 'CPL', 'HAM', 'IND', 'NID', 'NSP', 'PON', 'SURF', 'TIGE', 'TOUF')  )
    OR (denombrement_min IS NULL AND denombrement_max IS NULL AND Coalesce(objet_denombrement, 'NSP') = 'NSP')
)$$, 'conforme'),
('obs_type_denombrement_valide', 'La valeur de t<b>ype_denombrement</b> n''est pas conforme', 'Le champ <b>type_denombrement</b> doit correspondre à la nomenclature', $$( type_denombrement IN ('Co', 'Es', 'Ca', 'NSP') )$$, 'conforme'),
('obs_diffusion_niveau_precision_valide', 'La valeur de <b>diffusion_niveau_precision</b> n''est pas conforme', 'Le champ <b>diffusion_niveau_precision</b> doit correspondre à la nomenclature', $$( diffusion_niveau_precision IS NULL OR diffusion_niveau_precision IN ( '0', '1', '2', '3', '4', '5', 'm01', 'm02' ) )$$, 'conforme'),
('obs_dates_valide', 'La valeur des champs <b>date_debut, heure_debut, date_fin et heure_fin</b> n''est pas conforme', 'Les champs <b>date_debut, heure_debut, date_fin et heure_fin</b> doivent avoir des valeurs cohérentes', $$(date_debut::date <= date_fin::date AND date_debut::date + Coalesce(nullif(heure_debut, ''), '0:00')::time <= date_fin::date + Coalesce(nullif(heure_fin, ''), '0:00')::time )$$, 'conforme'),
('obs_precision_geometrie_valide', 'La valeur de precision_geometrie</b> n''est pas conforme', 'Le champ <b>precision_geometrie</b> doit être positif ou vide', $$( precision_geometrie::integer IS NULL OR precision_geometrie::integer > 0 )$$, 'conforme'),
('obs_altitude_min_max_valide', 'La valeur des champs <b>altitude_min, altitude_moy et altitude_max</b> n''est pas conforme', 'Les champs <b>altitude_min</b> et <b>altitude_max</b> doivent être cohérents', $$( Coalesce( altitude_min::real, 0 ) <= Coalesce( altitude_max::real, 0 ) )$$, 'conforme'),
('obs_profondeur_min_max_valide', 'La valeur des champs <b>profondeur_min, profondeur_moy et profondeur_max</b> n''est pas conforme', 'Les champs <b>profondeur_min</b> et <b>profondeur_max</b> doivent être cohérents', $$( Coalesce( profondeur_min::real, 0 ) <= Coalesce( profondeur_max::real, 0 ) )$$, 'conforme'),
('obs_dee_floutage_valide', 'La valeur de <b>dee_floutage</b> n''est pas conforme', 'Le champ <b>dee_floutage</b> doit contenir OUI, NON ou être vide', $$( dee_floutage IS NULL OR dee_floutage IN ('OUI', 'NON') )$$, 'conforme'),
('obs_dee_floutage_ds_publique_valide', 'La valeur de <b>dee_floutage</b> n''est pas conforme', 'Le champ <b>dee_floutage </b>doit être renseigné si le champ <b>ds_publique</b> vaut Pr', $$( ds_publique != 'Pr' OR ( ds_publique = 'Pr' AND dee_floutage IS NOT NULL ) )$$, 'conforme'),
('obs_sensi_date_attribution_valide', 'La valeur de <b>sensi_date_attribution</b> n''est pas conforme', 'Le champ <b>sensi_date_attribution</b> doit être renseigné si le champ <b>sensi_niveau</b> est différent de 0', $$( ( sensi_date_attribution IS NULL AND Coalesce(sensi_niveau, '0') = '0' ) OR  ( sensi_date_attribution IS NOT NULL  ) )$$, 'conforme'),
('obs_sensi_niveau_valide', 'La valeur de <b>sensi_niveau</b> n''est pas conforme', 'Le champ <b>sensi_niveau</b> peut seulement prendre les valeurs suivantes: 0, 1, 2, 3, 4, 5, m01 ou m02', $$( sensi_niveau IN ( '0', '1', '2', '3', '4', '5', 'm01', 'm02' ) )$$, 'conforme'),
('obs_sensi_referentiel_valide', 'La valeur de <b>sensi_referentiel</b> n''est pas conforme', '', $$( ( sensi_niveau != '0' AND sensi_referentiel IS NOT NULL) OR sensi_niveau = '0' )$$, 'conforme'),
('obs_sensi_version_referentiel_valide', 'La valeur de <b>sensi_version_referentiel</b> n''est pas conforme', 'Le champ <b>sensi_version_referentiel</b> doit être renseigné si le champ <b>sensi_niveau</b> est différent de 0', $$( ( sensi_niveau != '0' AND sensi_version_referentiel IS NOT NULL) OR sensi_niveau = '0' )$$, 'conforme'),
('obs_version_taxref_valide', 'La valeur de <b>version_taxref</b> n''est pas conforme', 'La version du TAXREF <b>version_taxref</b> doit être renseignée si le <b>cd_nom</b> est positif', $$(cd_nom IS NULL OR ( cd_nom IS NOT NULL AND cd_nom::integer > 0 AND version_taxref IS NOT NULL) OR ( cd_nom IS NOT NULL AND cd_nom::integer < 0 ))$$, 'conforme'),
('obs_observateurs_valide', 'La valeur de <b>observateurs</b> n''est pas conforme', 'Le champ <b>observateurs</b> doit être du type: NOM Prénom (Organisme 1), AUTRE-NOM Prénoms-Composé (Organisme 2), INCONNU (Indépendant)', $$(occtax.is_valid_identite_multiple(observateurs))$$, 'conforme'),
('obs_determinateurs_valide', 'La valeur de <b>determinateurs</b> n''est pas conforme', 'Le champ <b>determinateurs</b> doit être rempli si le cd_nom est rempli', $$(cd_nom IS NULL OR ( cd_nom IS NOT NULL AND determinateurs IS NOT NULL))$$, 'conforme'),
('obs_determinateurs_valide_format', 'La valeur de <b>determinateurs</b> n''est pas conforme', 'Le champ <b>determinateurs</b> doit être du type: NOM Prénom (Organisme 1), AUTRE-NOM Prénoms-Composé (Organisme 2), INCONNU (Indépendant)', $$(occtax.is_valid_identite_multiple(determinateurs))$$, 'conforme'),
('obs_nature_objet_geo_valide', 'La valeur de <b>nature_objet_geo</b> n''est pas conforme', 'Le champ <b>nature_objet_geo</b> peut prendre les valeurs: In, St, NSP', $$(geom IS NOT NULL AND (nature_objet_geo = ANY (ARRAY['St'::text, 'In'::text, 'NSP'::text])) OR geom IS NULL)$$, 'conforme'),

-- géométrie dans les mailles 10x10km
('obs_geometrie_localisation_dans_maille', 'Les <b>géométries</b> ne sont pas conformes', 'Les <b>géométries</b> doivent être à l''intérieur des mailles 10x10km.' , $$occtax.intersects_maille_10(longitude, latitude)$$, 'conforme')

ON CONFLICT ON CONSTRAINT critere_conformite_unique_code DO NOTHING
;

DROP FUNCTION IF EXISTS occtax.import_observations_depuis_table_temporaire(regclass, text, text, text);
CREATE OR REPLACE FUNCTION occtax.import_observations_depuis_table_temporaire(
    _table_temporaire regclass,
    _import_login text,
    _jdd_uid text,
    _organisme_responsable text
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

        validite_niveau,
        validite_date_validation,

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
        SELECT ''%2$s'' AS nom_organisme
    ),
    source_sans_doublon AS (
        SELECT csv.*
        FROM "%4$s" AS csv, info_jdd AS j
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

        NULL AS dee_floutage,
        NULL AS diffusion_niveau_precision,
        s.ds_publique,

        j.jdd_code,
        j.jdd_id,
        j.jdd_metadonnee_dee_id,
        NULL AS jdd_source_id,

        org.nom_organisme AS organisme_gestionnaire_donnees,
        org.nom_organisme AS org_transformation,

        s.statut_source,
        s.reference_biblio,

        s.sensible,
        s.sensi_date_attribution::date,
        s.sensi_niveau::text,
        s.sensi_referentiel,
        s.sensi_version_referentiel,

        ''1'' AS validite_niveau,
        now()::date AS validite_date_validation,

        NULL descriptif_sujet,
        NULL AS donnee_complementaire,

        s.precision_geometrie::integer,
        s.nature_objet_geo,
        ST_Transform(
            ST_SetSRID(
                ST_MakePoint(s.longitude::real, s.latitude::real),
                %6$s
            ),
            %6$s
        ) AS geom,

        json_build_object(
            ''observateurs'', s.observateurs,
            ''determinateurs'', s.determinateurs,
            ''import_login'', ''%3$s'',
            ''import_temp_table'', ''%4$s'',
            ''import_time'', now()::timestamp(0)
        ) AS odata,

        org.nom_organisme AS organisme_standard

    FROM
        info_jdd AS j,
        organisme_responsable AS org,
        source_sans_doublon AS s
        -- jointure pour récupérer les identifiants permanents si déjà créés lors d''un import passé
        LEFT JOIN occtax.lien_observation_identifiant_permanent AS loip
            ON loip.jdd_id = ''%5$s''
            AND loip.identifiant_origine = s.identifiant_origine::TEXT

    ON CONFLICT DO NOTHING
    RETURNING cle_obs, identifiant_permanent
    ';
    sql_text := format(sql_template,
        _jdd_uid,
        _organisme_responsable,
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


COMMENT ON FUNCTION occtax.import_observations_depuis_table_temporaire(regclass, text, text, text)
IS 'Importe les observations contenues dans la table fournie en paramètre pour le JDD fourni et l''organisme responsable'
;

-- Importe les données complémentaires (observateurs, liens spatiaux, etc.)
DROP FUNCTION IF EXISTS occtax.import_observations_post_data(regclass, text, text);
CREATE OR REPLACE FUNCTION occtax.import_observations_post_data(
    _table_temporaire regclass,
    _import_login text,
    _jdd_uid text
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
            AND odata->>''import_temp_table'' = ''%2$s''
            AND odata->>''import_login'' = ''%3$s''
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
            ''inconnu@inco.nnu'' AS mail,
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
        _table_temporaire
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
                odata->>''%1$s'' AS odata_%1$s,
                trim(%1$s) AS %2$s, rn
                FROM
                occtax.observation AS o,
                regexp_split_to_table(odata->>''%1$s'', '','')  WITH ORDINALITY x(%1$s, rn)
                WHERE True
                AND odata->>''%1$s'' IS NOT NULL
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


COMMENT ON FUNCTION occtax.import_observations_post_data(regclass, text, text)
IS 'Importe les données complémentaires (observateurs, liens spatiaux, etc.) sur les observations contenues dans la table fournie en paramètre'
;



-- Supprime les données importées (nettoyage)
DROP FUNCTION IF EXISTS occtax.import_delete_imported_observations(text, text);
CREATE OR REPLACE FUNCTION occtax.import_delete_imported_observations(
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
    FROM occtax.jdd WHERE jdd_metadonnee_dee_id = _jdd_uid
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
    DELETE FROM occtax.lien_observation_identifiant_permanent WHERE identifiant_permanent IN (
        SELECT identifiant_permanent FROM occtax.observation
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

COMMENT ON FUNCTION occtax.import_delete_imported_observations(text, text)
IS 'Suppression des données importées, utile si un souci a été rencontré lors de la procédure'
;

-- Vue pour lister les données importées
DROP VIEW IF EXISTS occtax.v_import_web_liste;
CREATE OR REPLACE VIEW occtax.v_import_web_liste AS
SELECT
(odata->>'import_time')::timestamp(0) AS date_import,
jdd_metadonnee_dee_id AS jdd,
count(cle_obs) AS nombre_observations,
odata->>'import_temp_table' AS code_import,
odata->>'import_login' AS login_import,
ST_ConvexHull(ST_Collect(ST_Centroid(geom)))::geometry(POLYGON, {$SRID}) AS geom
FROM occtax.observation
WHERE odata ? 'import_login' AND odata ? 'import_time'
GROUP BY odata, jdd_metadonnee_dee_id
ORDER BY date_import, code_import, login_import;
;

COMMENT ON VIEW occtax.v_import_web_liste
IS 'Vue utile pour lister les imports effectués par les utilisateurs depuis l''interface Web, à partir de fichier CSV'
;

-- Vue pour voir toutes les observations importées en attente d'intégration
DROP VIEW IF EXISTS occtax.v_import_web_observations;
CREATE OR REPLACE VIEW occtax.v_import_web_observations AS
SELECT
o.cle_obs, o.identifiant_origine, o.identifiant_permanent,
cd_nom, nom_cite, cd_ref,
denombrement_min, denombrement_max, objet_denombrement, type_denombrement,
commentaire,
date_debut, date_fin, heure_debut, heure_fin, date_determination,
dee_floutage, diffusion_niveau_precision, ds_publique,
jdd_metadonnee_dee_id,
statut_source, reference_biblio,
sensible, sensi_date_attribution, sensi_niveau, sensi_referentiel, sensi_version_referentiel,
validite_niveau, validite_date_validation,
precision_geometrie, nature_objet_geo,
(ST_Centroid(geom))::geometry(point, {$SRID}) AS geom,
(odata->>'import_time')::timestamp(0) AS date_import,
odata->>'import_temp_table' AS code_import,
odata->>'import_login' AS login_import

FROM occtax.observation AS o
WHERE odata ? 'import_login' AND odata ? 'import_time'
ORDER BY jdd_metadonnee_dee_id, date_import, code_import, login_import;
;

COMMENT ON VIEW occtax.v_import_web_observations
IS 'Vue utile pour lister les observations importées par les utilisateurs depuis l''interface Web, à partir de fichier CSV. Seuls les centroides des géométries sont affichés.'
;
