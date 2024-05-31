
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


-- Données de test de conformité
-- critere_conformite
TRUNCATE TABLE occtax.critere_conformite RESTART IDENTITY;

-- Ajout des contraintes sur les types de champs attendus: format, non null, occtax
INSERT INTO occtax.critere_conformite (code, libelle, condition, type_critere)
VALUES
('obs_id_sinp_occtax_format', 'Le format de <b>id_sinp_occtax</b> est incorrect. Attendu: uuid' , $$occtax.is_given_type(id_sinp_occtax, 'uuid')$$, 'format'),
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
('obs_validite_niv_val_format', 'Le format de <b>validation_niv_val</b> est incorrect. Attendu: entier' , $$occtax.is_given_type(validation_niv_val, 'integer')$$, 'format'),
('obs_validite_ech_val_format', 'Le format de <b>validation_ech_val</b> est incorrect. Attendu: entier' , $$occtax.is_given_type(validation_ech_val, 'integer')$$, 'format'),
('obs_validite_date_ctrl_format', 'Le format de <b>validation_date_ctrl</b> est incorrect. Attendu: date' , $$occtax.is_given_type(validation_date_ctrl, 'date')$$, 'format'),
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
('obs_nom_cite_not_null', 'La valeur de <b>nom_cite</b> est vide', $$nom_cite IS NOT NULL$$, 'not_null'),
('obs_date_debut_not_null', 'La valeur de <b>date_debut</b> est vide', $$date_debut IS NOT NULL$$, 'not_null'),
('obs_date_fin_not_null', 'La valeur de <b>date_fin</b> est vide', $$date_fin IS NOT NULL$$, 'not_null'),
('obs_ds_publique_not_null', 'La valeur de <b>ds_publique</b> est vide', $$ds_publique IS NOT NULL$$, 'not_null'),
('obs_id_origine_not_null', 'La valeur de <b>id_origine</b> est vide', $$id_origine IS NOT NULL$$, 'not_null'),
('obs_statut_source_not_null', 'La valeur de <b>statut_source</b> est vide', $$statut_source IS NOT NULL$$, 'not_null'),
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
('obs_objet_denombrement_valide', 'La valeur de <b>objet_denombrement</b> n''est pas conforme', 'Le champ <b>objet_denombrement</b> doit être différent de NSP si les champs <b>denombrement_min</b> ou <b>denombrement_max</b> sont renseignés', $$
    ( denombrement_min IS NOT NULL AND denombrement_max IS NOT NULL AND objet_denombrement IN ('COL', 'CPL', 'HAM', 'IND', 'NID', 'NSP', 'PON', 'SURF', 'TIGE', 'TOUF')  )
    OR (denombrement_min IS NULL AND denombrement_max IS NULL AND Coalesce(objet_denombrement, 'NSP') = 'NSP')
$$, 'conforme'),
('obs_type_denombrement_valide', 'La valeur de t<b>ype_denombrement</b> n''est pas conforme', 'Le champ <b>type_denombrement</b> doit correspondre à la nomenclature', $$( type_denombrement IN ('Co', 'Es', 'Ca', 'NSP') )$$, 'conforme'),
('obs_diffusion_niveau_precision_valide', 'La valeur de <b>diffusion_niveau_precision</b> n''est pas conforme', 'Le champ <b>diffusion_niveau_precision</b> doit correspondre à la nomenclature', $$( diffusion_niveau_precision IS NULL OR diffusion_niveau_precision IN ( '0', '1', '2', '3', '4', '5', 'm01', 'm02' ) )$$, 'conforme'),
('obs_dates_valide', 'La valeur des champs <b>date_debut, heure_debut, date_fin et heure_fin</b> n''est pas conforme', 'Les champs <b>date_debut, heure_debut, date_fin et heure_fin</b> doivent avoir des valeurs cohérentes et être dans le passé', $$
    date_debut::date <= date_fin::date
    AND date_debut::date + Coalesce(nullif(heure_debut, ''), '0:00')::time <= date_fin::date + Coalesce(nullif(heure_fin, ''), '23:59')::time
    AND COALESCE(date_fin, date_debut)::date <= now()::date
$$, 'conforme'),
('obs_precision_geometrie_valide', 'La valeur de precision_geometrie</b> n''est pas conforme', 'Le champ <b>precision_geometrie</b> doit être positif ou vide', $$( precision_geometrie::integer IS NULL OR precision_geometrie::integer > 0 )$$, 'conforme'),
('obs_altitude_min_max_valide', 'La valeur des champs <b>altitude_min, altitude_moy et altitude_max</b> n''est pas conforme', 'Les champs <b>altitude_min</b> et <b>altitude_max</b> doivent être cohérents', $$( Coalesce( altitude_min::real, 0 ) <= Coalesce( altitude_max::real, 0 ) )$$, 'conforme'),
('obs_profondeur_min_max_valide', 'La valeur des champs <b>profondeur_min, profondeur_moy et profondeur_max</b> n''est pas conforme', 'Les champs <b>profondeur_min</b> et <b>profondeur_max</b> doivent être cohérents', $$( Coalesce( profondeur_min::real, 0 ) <= Coalesce( profondeur_max::real, 0 ) )$$, 'conforme'),
('obs_dee_floutage_valide', 'La valeur de <b>dee_floutage</b> n''est pas conforme', 'Le champ <b>dee_floutage</b> doit contenir OUI, NON ou être vide', $$( dee_floutage IS NULL OR dee_floutage IN ('OUI', 'NON') )$$, 'conforme'),
('obs_dee_floutage_ds_publique_valide', 'La valeur de <b>dee_floutage</b> n''est pas conforme', 'Le champ <b>dee_floutage </b>doit être renseigné si le champ <b>ds_publique</b> vaut Pr', $$( ds_publique != 'Pr' OR ( ds_publique = 'Pr' AND dee_floutage IS NOT NULL ) )$$, 'conforme'),
('obs_sensi_date_attribution_valide', 'La valeur de <b>sensi_date_attribution</b> n''est pas conforme', 'Le champ <b>sensi_date_attribution</b> doit être renseigné si le champ <b>sensi_niveau</b> est différent de 0', $$( ( sensi_date_attribution IS NULL AND Coalesce(sensi_niveau, '0') = '0' ) OR  ( sensi_date_attribution IS NOT NULL  ) )$$, 'conforme'),
('obs_sensi_niveau_valide', 'La valeur de <b>sensi_niveau</b> n''est pas conforme', 'Le champ <b>sensi_niveau</b> peut seulement prendre les valeurs suivantes: 0, 1, 2, 3, 4, 5, m01 ou m02', $$( sensi_niveau IN ( '0', '1', '2', '3', '4', '5', 'm01', 'm02' ) )$$, 'conforme'),
('obs_sensi_referentiel_valide', 'La valeur de <b>sensi_referentiel</b> n''est pas conforme', '', $$( ( sensi_niveau != '0' AND sensi_referentiel IS NOT NULL) OR sensi_niveau = '0' )$$, 'conforme'),
('obs_sensi_version_referentiel_valide', 'La valeur de <b>sensi_version_referentiel</b> n''est pas conforme', 'Le champ <b>sensi_version_referentiel</b> doit être renseigné si le champ <b>sensi_niveau</b> est différent de 0', $$( ( sensi_niveau != '0' AND sensi_version_referentiel IS NOT NULL) OR sensi_niveau = '0' )$$, 'conforme'),

('obs_validation_niv_val_valide', 'La valeur de <b>validation_niv_val</b> n''est pas conforme', 'Le champ <b>validation_niv_val</b> peut seulement prendre les valeurs suivantes: 1, 2, 3, 4, 5, 6', $$( validation_niv_val IN ( '1', '2', '3', '4', '5', '6' ) )$$, 'conforme'),
('obs_validation_ech_val_valide', 'La valeur de <b>validation_ech_val</b> n''est pas conforme', 'Le champ <b>validation_ech_val</b> peut seulement prendre les valeurs suivantes: 1, 2, 3', $$( validation_ech_val IN ( '1', '2', '3' ) )$$, 'conforme'),
('obs_validation_typ_val_valide', 'La valeur de <b>validation_typ_val</b> n''est pas conforme', 'Le champ <b>validation_typ_val</b> peut seulement prendre les valeurs suivantes: A, M, C', $$( validation_typ_val IN ( 'A', 'M', 'C' ) )$$, 'conforme'),

('obs_validation_validateur_valide_format', 'La valeur de <b>validation_validateur</b> n''est pas conforme',
'Le champ <b>validation_validateur</b> doit être du type: "NOM Prénom (Organisme 1)" ou "INCONNU (Indépendant)". Il doit contenir une personne valide si "validite_niv_val" est renseigné.',
$$(
    (validation_niv_val IS NOT NULL AND occtax.is_valid_identite_multiple(Coalesce(validation_validateur, 'invalide')))
    OR validation_niv_val IS NULL )
$$, 'conforme'
),

('obs_version_taxref_valide', 'La valeur de <b>version_taxref</b> n''est pas conforme', 'La version du TAXREF <b>version_taxref</b> doit être renseignée si le <b>cd_nom</b> est positif', $$
    cd_nom IS NULL
    OR ( cd_nom IS NOT NULL AND cd_nom::bigint > 0 AND version_taxref IS NOT NULL)
    OR ( cd_nom IS NOT NULL AND cd_nom::bigint < 0 )
$$, 'conforme'),
('obs_observateurs_valide', 'La valeur de <b>observateurs</b> n''est pas conforme', 'Le champ <b>observateurs</b> doit être du type: NOM Prénom (Organisme 1), AUTRE-NOM Prénoms-Composé (Organisme 2), INCONNU (Indépendant)', $$(occtax.is_valid_identite_multiple(observateurs))$$, 'conforme'),
('obs_determinateurs_valide', 'La valeur de <b>determinateurs</b> n''est pas conforme', 'Le champ <b>determinateurs</b> doit être rempli si le cd_nom est rempli', $$(cd_nom IS NULL OR ( cd_nom IS NOT NULL AND determinateurs IS NOT NULL))$$, 'conforme'),
('obs_determinateurs_valide_format', 'La valeur de <b>determinateurs</b> n''est pas conforme', 'Le champ <b>determinateurs</b> doit être du type: NOM Prénom (Organisme 1), AUTRE-NOM Prénoms-Composé (Organisme 2), INCONNU (Indépendant)', $$(occtax.is_valid_identite_multiple(determinateurs))$$, 'conforme'),
('obs_nature_objet_geo_valide', 'La valeur de <b>nature_objet_geo</b> n''est pas conforme', 'Le champ <b>nature_objet_geo</b> peut prendre les valeurs: In, St, NSP', $$
    (nature_objet_geo = ANY (ARRAY['St'::text, 'In'::text, 'NSP'::text]) )
$$, 'conforme'),

('obs_statut_observation_et_denombrement_valide', 'Les valeurs de valeur de <b>denombrement_min</b> et <b>denombrement_max</b> ne sont pas compatibles avec celle de <b>statut_observation</b>', 'Les dénombrements doivent valoir 0 ou NULL si le statut est "No" (non observé) ou "NSP", et être entières si le statut est "Pr" (présent)', $$
    (statut_observation = 'No' AND COALESCE(denombrement_min::integer, 0) = 0 AND COALESCE(denombrement_max::integer, 0) = 0)
    OR (
            statut_observation = 'Pr'
            AND (denombrement_min <> 0 OR denombrement_min IS NULL)
            AND (denombrement_max <> 0 OR denombrement_max IS NULL)
    )
    OR statut_observation = 'NSP'
$$, 'conforme'),
-- obs_denombrement_min_max_valide
('obs_denombrement_min_max_valide', 'Les valeurs de <b>denombrement_min</b> et <b>denombrement_max</b> ne sont pas conformes.', 'La valeur de <b>denombrement_min</b> doit être inférieure à celle de <b>denombrement_max</b>', $$
    COALESCE(denombrement_min::integer, 0) <= COALESCE(denombrement_max::integer, 0)
    OR denombrement_max IS NULL
$$, 'conforme'),

-- géométrie dans les mailles 10x10km
('obs_geometrie_localisation_dans_maille', 'Les <b>géométries</b> ne sont pas conformes', 'Les <b>géométries</b> doivent être à l''intérieur des mailles 10x10km.' , $$
ST_Intersects(
    (SELECT ST_union(geom) FROM sig.maille_10),
    ST_Transform(
        ST_SetSRID(ST_MakePoint(o.longitude::real, o.latitude::real), __SOURCE_SRID__),
        (SELECT srid FROM geometry_columns WHERE f_table_schema = 'occtax' AND f_table_name = 'observation')
    )
)$$, 'conforme')

ON CONFLICT ON CONSTRAINT critere_conformite_unique_code DO NOTHING
;


-- Ajout des critères de conformité pour les champs de descriptif du sujet

-- CHECK
INSERT INTO occtax.critere_conformite (code, libelle, condition, type_critere)
VALUES
-- format
('descriptif_obs_technique_format', 'Le format de <b>obs_technique</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(obs_technique, 'integer')$$, 'format'),
('descriptif_occ_etat_biologique_format', 'Le format de <b>occ_etat_biologique</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_etat_biologique, 'integer')$$, 'format'),
('descriptif_occ_naturalite_format', 'Le format de <b>occ_naturalite</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_naturalite, 'integer')$$, 'format'),
('descriptif_occ_sexe_format', 'Le format de <b>occ_sexe</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_sexe, 'integer')$$, 'format'),
('descriptif_occ_stade_de_vie_format', 'Le format de <b>occ_stade_de_vie</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_stade_de_vie, 'integer')$$, 'format'),
('descriptif_occ_denombrement_min_format', 'Le format de <b>occ_denombrement_min</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_denombrement_min, 'integer')$$, 'format'),
('descriptif_occ_denombrement_max_format', 'Le format de <b>occ_denombrement_max</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_denombrement_max, 'integer')$$, 'format'),
('descriptif_occ_type_denombrement_format', 'Le format de <b>occ_type_denombrement</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_type_denombrement, 'text')$$, 'format'),
('descriptif_occ_statut_biogeographique_format', 'Le format de <b>occ_statut_biogeographique</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_statut_biogeographique, 'integer')$$, 'format'),
('descriptif_occ_statut_biologique_format', 'Le format de <b>occ_statut_biologique</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_statut_biologique, 'integer')$$, 'format'),
('descriptif_occ_comportement_format', 'Le format de <b>occ_comportement</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_comportement, 'integer')$$, 'format'),
('descriptif_preuve_existante_format', 'Le format de <b>preuve_existante</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(preuve_existante, 'integer')$$, 'format'),

('descriptif_obs_technique_format_2', 'Le format de <b>obs_technique_2</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(obs_technique_2, 'integer')$$, 'format'),
('descriptif_occ_etat_biologique_format_2', 'Le format de <b>occ_etat_biologique_2</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_etat_biologique_2, 'integer')$$, 'format'),
('descriptif_occ_naturalite_format_2', 'Le format de <b>occ_naturalite_2</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_naturalite_2, 'integer')$$, 'format'),
('descriptif_occ_sexe_format_2', 'Le format de <b>occ_sexe_2</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_sexe_2, 'integer')$$, 'format'),
('descriptif_occ_stade_de_vie_format_2', 'Le format de <b>occ_stade_de_vie_2</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_stade_de_vie_2, 'integer')$$, 'format'),
('descriptif_occ_denombrement_min_format_2', 'Le format de <b>occ_denombrement_min_2</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_denombrement_min_2, 'integer')$$, 'format'),
('descriptif_occ_denombrement_max_format_2', 'Le format de <b>occ_denombrement_max_2</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_denombrement_max_2, 'integer')$$, 'format'),
('descriptif_occ_type_denombrement_format_2', 'Le format de <b>occ_type_denombrement_2</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_type_denombrement_2, 'text')$$, 'format'),
('descriptif_occ_statut_biogeographique_format_2', 'Le format de <b>occ_statut_biogeographique_2</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_statut_biogeographique_2, 'integer')$$, 'format'),
('descriptif_occ_statut_biologique_format_2', 'Le format de <b>occ_statut_biologique_2</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_statut_biologique_2, 'integer')$$, 'format'),
('descriptif_occ_comportement_format_2', 'Le format de <b>occ_comportement_2</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_comportement_2, 'integer')$$, 'format'),
('descriptif_preuve_existante_format_2', 'Le format de <b>preuve_existante_2</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(preuve_existante_2, 'integer')$$, 'format'),

('descriptif_obs_technique_format_3', 'Le format de <b>obs_technique_3</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(obs_technique_3, 'integer')$$, 'format'),
('descriptif_occ_etat_biologique_format_3', 'Le format de <b>occ_etat_biologique_3</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_etat_biologique_3, 'integer')$$, 'format'),
('descriptif_occ_naturalite_format_3', 'Le format de <b>occ_naturalite_3</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_naturalite_3, 'integer')$$, 'format'),
('descriptif_occ_sexe_format_3', 'Le format de <b>occ_sexe_3</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_sexe_3, 'integer')$$, 'format'),
('descriptif_occ_stade_de_vie_format_3', 'Le format de <b>occ_stade_de_vie_3</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_stade_de_vie_3, 'integer')$$, 'format'),
('descriptif_occ_denombrement_min_format_3', 'Le format de <b>occ_denombrement_min_3</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_denombrement_min_3, 'integer')$$, 'format'),
('descriptif_occ_denombrement_max_format_3', 'Le format de <b>occ_denombrement_max_3</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_denombrement_max_3, 'integer')$$, 'format'),
('descriptif_occ_type_denombrement_format_3', 'Le format de <b>occ_type_denombrement_3</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_type_denombrement_3, 'text')$$, 'format'),
('descriptif_occ_statut_biogeographique_format_3', 'Le format de <b>occ_statut_biogeographique_3</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_statut_biogeographique_3, 'integer')$$, 'format'),
('descriptif_occ_statut_biologique_format_3', 'Le format de <b>occ_statut_biologique_3</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_statut_biologique_3, 'integer')$$, 'format'),
('descriptif_occ_comportement_format_3', 'Le format de <b>occ_comportement_3</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(occ_comportement_3, 'integer')$$, 'format'),
('descriptif_preuve_existante_format_3', 'Le format de <b>preuve_existante_3</b> est incorrect. Attendu: Entier' , $$occtax.is_given_type(preuve_existante_3, 'integer')$$, 'format')



ON CONFLICT ON CONSTRAINT critere_conformite_unique_code DO NOTHING
;

-- conforme
INSERT INTO occtax.critere_conformite (code, libelle, description, condition, type_critere)
VALUES

('descriptif_obs_technique_valide', 'La valeur de <b>obs_technique</b> n''est pas conforme', 'Le champ <b>obs_technique</b> doit correspondre à la nomenclature', $$( obs_technique IN ('0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26','27')  )$$, 'conforme'),
('descriptif_occ_etat_biologique_valide', 'La valeur de <b>occ_etat_biologique</b> n''est pas conforme', 'Le champ <b>occ_etat_biologique</b> doit correspondre à la nomenclature', $$( occ_etat_biologique IN ( '0','1','2','3' ) )$$, 'conforme'),
('descriptif_occ_naturalite_valide', 'La valeur de <b>occ_naturalite</b> n''est pas conforme', 'Le champ <b>occ_naturalite</b> doit correspondre à la nomenclature', $$( occ_naturalite IN ( '0','1','2','3','4','5' ) )$$, 'conforme'),
('descriptif_occ_sexe_valide', 'La valeur de <b>occ_sexe</b> n''est pas conforme', 'Le champ <b>occ_sexe</b> doit correspondre à la nomenclature', $$( occ_sexe IN ('0','1','2','3','4','5' ) )$$, 'conforme'),
('descriptif_occ_stade_de_vie_valide', 'La valeur de <b>occ_stade_de_vie</b> n''est pas conforme', 'Le champ <b>occ_stade_de_vie</b> doit correspondre à la nomenclature', $$( occ_stade_de_vie IN ('0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26','27' ) )$$, 'conforme'),
('descriptif_occ_type_denombrement_valide', 'La valeur de <b>occ_type_denombrement</b> n''est pas conforme', 'Le champ <b>occ_type_denombrement</b> doit correspondre à la nomenclature', $$( occ_type_denombrement IN ( 'Ca', 'Co', 'Es', 'NSP' ) )$$, 'conforme'),
('descriptif_occ_statut_biogeographique_valide', 'La valeur de <b>occ_statut_biogeographique</b> n''est pas conforme', 'Le champ <b>occ_statut_biogeographique</b> doit correspondre à la nomenclature', $$( occ_statut_biogeographique IN ( '0','1','2','3','4','5', '6' ) )$$, 'conforme'),
('descriptif_occ_statut_biologique_valide', 'La valeur de <b>occ_statut_biologique</b> n''est pas conforme', 'Le champ <b>occ_statut_biologique</b> doit correspondre à la nomenclature', $$( occ_statut_biologique IN ( '0','1','2','3','4','5', '9', '13' ) )$$, 'conforme'),
('descriptif_occ_comportement_valide', 'La valeur de <b>occ_comportement</b> n''est pas conforme', 'Le champ <b>occ_comportement</b> doit correspondre à la nomenclature', $$( occ_comportement IN ( '0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23' ) )$$, 'conforme'),
('descriptif_preuve_existante_valide', 'La valeur de <b>preuve_existante</b> n''est pas conforme', 'Le champ <b>preuve_existante</b> doit correspondre à la nomenclature', $$( preuve_existante IN ( '0','1','2','3' ) )$$, 'conforme'),

('descriptif_obs_technique_valide_2', 'La valeur de <b>obs_technique_2</b> n''est pas conforme', 'Le champ <b>obs_technique_2</b> doit correspondre à la nomenclature', $$( obs_technique_2 IN ('0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26','27')  )$$, 'conforme'),
('descriptif_occ_etat_biologique_valide_2', 'La valeur de <b>occ_etat_biologique_2</b> n''est pas conforme', 'Le champ <b>occ_etat_biologique_2</b> doit correspondre à la nomenclature', $$( occ_etat_biologique_2 IN ( '0','1','2','3' ) )$$, 'conforme'),
('descriptif_occ_naturalite_valide_2', 'La valeur de <b>occ_naturalite_2</b> n''est pas conforme', 'Le champ <b>occ_naturalite_2</b> doit correspondre à la nomenclature', $$( occ_naturalite_2 IN ( '0','1','2','3','4','5' ) )$$, 'conforme'),
('descriptif_occ_sexe_valide_2', 'La valeur de <b>occ_sexe_2</b> n''est pas conforme', 'Le champ <b>occ_sexe_2</b> doit correspondre à la nomenclature', $$( occ_sexe_2 IN ('0','1','2','3','4','5' ) )$$, 'conforme'),
('descriptif_occ_stade_de_vie_valide_2', 'La valeur de <b>occ_stade_de_vie_2</b> n''est pas conforme', 'Le champ <b>occ_stade_de_vie_2</b> doit correspondre à la nomenclature', $$( occ_stade_de_vie_2 IN ('0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26','27' ) )$$, 'conforme'),
('descriptif_occ_type_denombrement_valide_2', 'La valeur de <b>occ_type_denombrement_2</b> n''est pas conforme', 'Le champ <b>occ_type_denombrement_2</b> doit correspondre à la nomenclature', $$( occ_type_denombrement_2 IN ( 'Ca', 'Co', 'Es', 'NSP' ) )$$, 'conforme'),
('descriptif_occ_statut_biogeographique_valide_2', 'La valeur de <b>occ_statut_biogeographique_2</b> n''est pas conforme', 'Le champ <b>occ_statut_biogeographique_2</b> doit correspondre à la nomenclature', $$( occ_statut_biogeographique_2 IN ( '0','1','2','3','4','5', '6' ) )$$, 'conforme'),
('descriptif_occ_statut_biologique_valide_2', 'La valeur de <b>occ_statut_biologique_2</b> n''est pas conforme', 'Le champ <b>occ_statut_biologique_2</b> doit correspondre à la nomenclature', $$( occ_statut_biologique_2 IN ( '0','1','2','3','4','5', '9', '13' ) )$$, 'conforme'),
('descriptif_occ_comportement_valide_2', 'La valeur de <b>occ_comportement_2</b> n''est pas conforme', 'Le champ <b>occ_comportement_2</b> doit correspondre à la nomenclature', $$( occ_comportement_2 IN ( '0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23' ) )$$, 'conforme'),
('descriptif_preuve_existante_valide_2', 'La valeur de <b>preuve_existante_2</b> n''est pas conforme', 'Le champ <b>preuve_existante_2</b> doit correspondre à la nomenclature', $$( preuve_existante_2 IN ( '0','1','2','3' ) )$$, 'conforme'),

('descriptif_obs_technique_valide_3', 'La valeur de <b>obs_technique_3</b> n''est pas conforme', 'Le champ <b>obs_technique_3</b> doit correspondre à la nomenclature', $$( obs_technique_3 IN ('0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26','27')  )$$, 'conforme'),
('descriptif_occ_etat_biologique_valide_3', 'La valeur de <b>occ_etat_biologique_3</b> n''est pas conforme', 'Le champ <b>occ_etat_biologique_3</b> doit correspondre à la nomenclature', $$( occ_etat_biologique_3 IN ( '0','1','2','3' ) )$$, 'conforme'),
('descriptif_occ_naturalite_valide_3', 'La valeur de <b>occ_naturalite_3</b> n''est pas conforme', 'Le champ <b>occ_naturalite_3</b> doit correspondre à la nomenclature', $$( occ_naturalite_3 IN ( '0','1','2','3','4','5' ) )$$, 'conforme'),
('descriptif_occ_sexe_valide_3', 'La valeur de <b>occ_sexe_3</b> n''est pas conforme', 'Le champ <b>occ_sexe_3</b> doit correspondre à la nomenclature', $$( occ_sexe_3 IN ('0','1','2','3','4','5' ) )$$, 'conforme'),
('descriptif_occ_stade_de_vie_valide_3', 'La valeur de <b>occ_stade_de_vie_3</b> n''est pas conforme', 'Le champ <b>occ_stade_de_vie_3</b> doit correspondre à la nomenclature', $$( occ_stade_de_vie_3 IN ('0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26','27' ) )$$, 'conforme'),
('descriptif_occ_type_denombrement_valide_3', 'La valeur de <b>occ_type_denombrement_3</b> n''est pas conforme', 'Le champ <b>occ_type_denombrement_3</b> doit correspondre à la nomenclature', $$( occ_type_denombrement_3 IN ( 'Ca', 'Co', 'Es', 'NSP' ) )$$, 'conforme'),
('descriptif_occ_statut_biogeographique_valide_3', 'La valeur de <b>occ_statut_biogeographique_3</b> n''est pas conforme', 'Le champ <b>occ_statut_biogeographique_3</b> doit correspondre à la nomenclature', $$( occ_statut_biogeographique_3 IN ( '0','1','2','3','4','5', '6' ) )$$, 'conforme'),
('descriptif_occ_statut_biologique_valide_3', 'La valeur de <b>occ_statut_biologique_3</b> n''est pas conforme', 'Le champ <b>occ_statut_biologique_3</b> doit correspondre à la nomenclature', $$( occ_statut_biologique_3 IN ( '0','1','2','3','4','5', '9', '13' ) )$$, 'conforme'),
('descriptif_occ_comportement_valide_3', 'La valeur de <b>occ_comportement_3</b> n''est pas conforme', 'Le champ <b>occ_comportement_3</b> doit correspondre à la nomenclature', $$( occ_comportement_3 IN ( '0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23' ) )$$, 'conforme'),
('descriptif_preuve_existante_valide_3', 'La valeur de <b>preuve_existante_3</b> n''est pas conforme', 'Le champ <b>preuve_existante_3</b> doit correspondre à la nomenclature', $$( preuve_existante_3 IN ( '0','1','2','3' ) )$$, 'conforme')

ON CONFLICT ON CONSTRAINT critere_conformite_unique_code DO NOTHING
;


-- Vérification des doublons
DROP FUNCTION IF EXISTS occtax.verification_doublons_avant_import(regclass, text);
DROP FUNCTION IF EXISTS occtax.verification_doublons_avant_import(regclass, text, boolean);
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
    sql_template := $SQL$
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
        SELECT * FROM occtax.jdd WHERE id_sinp_jdd = '%1$s'
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
        nextval('occtax.observation_cle_obs_seq'::regclass) AS cle_obs,
        -- C'est la plateforme régionale qui définit les id permanents
        -- sauf s'ils sont déjà définis en amont (Ex: export MNHN)
        CASE
            WHEN nullif(trim(s.id_sinp_occtax), '') IS NOT NULL THEN trim(s.id_sinp_occtax)
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

        -- descriptif du sujet
        -- On est obligé de passer par des array car array_to_string enlève les items NULL
        -- On fait en sorte que chaque item puisse être NULL si aucun champ n'a de valeur
        -- On finalise par transformer la String finale en json
        -- Ex simple:
        -- SELECT ('[' || array_to_string(array [NULL, json_build_object('a', 2, 'b', 34), NULL, json_build_object('a', 6, 'b', 12) ], ',') || ']')::json
        -- renvoie
        -- [{"a" : 2, "b" : 34},{"a" : 6, "b" : 12}]
        ('[' || array_to_string(ARRAY[
            -- 1er groupe de champs
            CASE
                WHEN nullif(concat(
                    nullif(s.obs_technique, ''), nullif(s.occ_etat_biologique, ''),
                    nullif(s.occ_naturalite, ''), nullif(s.occ_sexe, ''),
                    nullif(s.occ_stade_de_vie, ''), nullif(s.occ_denombrement_min, ''),
                    nullif(s.occ_denombrement_max, ''), nullif(s.occ_type_denombrement, ''),
                    nullif(s.occ_statut_biogeographique, ''), nullif(s.occ_statut_biologique, ''),
                    nullif(s.occ_comportement, ''), nullif(s.preuve_existante, ''),
                    nullif(s.url_preuve_numerique, ''), nullif(s.preuve_non_numerique, ''),
                    nullif(s.obs_contexte, ''), nullif(s.obs_description, ''),
                    nullif(s.occ_methode_determination, '')
                ), '') IS NOT NULL THEN
                    json_build_object(
                        'obs_technique', trim(s.obs_technique),
                        'occ_etat_biologique', trim(s.occ_etat_biologique),
                        'occ_naturalite', trim(s.occ_naturalite),
                        'occ_sexe', trim(s.occ_sexe),
                        'occ_stade_de_vie', trim(s.occ_stade_de_vie),
                        'occ_denombrement_min', trim(s.occ_denombrement_min),
                        'occ_denombrement_max', trim(s.occ_denombrement_max),
                        'occ_type_denombrement', trim(s.occ_type_denombrement),
                        'occ_statut_biogeographique', trim(s.occ_statut_biogeographique),
                        'occ_statut_biologique', trim(s.occ_statut_biologique),
                        'occ_comportement', trim(s.occ_comportement),
                        'preuve_existante', trim(s.preuve_existante),
                        'url_preuve_numerique', trim(s.url_preuve_numerique),
                        'preuve_non_numerique', trim(s.preuve_non_numerique),
                        'obs_contexte', trim(s.obs_contexte),
                        'obs_description', trim(s.obs_description),
                        'occ_methode_determination', trim(s.occ_methode_determination)
                    )
                ELSE NULL::json
            END,

            -- 2ème groupe de champs
            CASE
                WHEN nullif(concat(
                    nullif(s.obs_technique_2, ''), nullif(s.occ_etat_biologique_2, ''),
                    nullif(s.occ_naturalite_2, ''), nullif(s.occ_sexe_2, ''),
                    nullif(s.occ_stade_de_vie_2, ''), nullif(s.occ_denombrement_min_2, ''),
                    nullif(s.occ_denombrement_max_2, ''), nullif(s.occ_type_denombrement_2, ''),
                    nullif(s.occ_statut_biogeographique_2, ''), nullif(s.occ_statut_biologique_2, ''),
                    nullif(s.occ_comportement_2, ''), nullif(s.preuve_existante_2, ''),
                    nullif(s.url_preuve_numerique_2, ''), nullif(s.preuve_non_numerique_2, ''),
                    nullif(s.obs_contexte_2, ''), nullif(s.obs_description_2, ''),
                    nullif(s.occ_methode_determination_2, '')
                ), '') IS NOT NULL THEN
                    json_build_object(
                        'obs_technique', trim(s.obs_technique_2),
                        'occ_etat_biologique', trim(s.occ_etat_biologique_2),
                        'occ_naturalite', trim(s.occ_naturalite_2),
                        'occ_sexe', trim(s.occ_sexe_2),
                        'occ_stade_de_vie', trim(s.occ_stade_de_vie_2),
                        'occ_denombrement_min', trim(s.occ_denombrement_min_2),
                        'occ_denombrement_max', trim(s.occ_denombrement_max_2),
                        'occ_type_denombrement', trim(s.occ_type_denombrement_2),
                        'occ_statut_biogeographique', trim(s.occ_statut_biogeographique_2),
                        'occ_statut_biologique', trim(s.occ_statut_biologique_2),
                        'occ_comportement', trim(s.occ_comportement_2),
                        'preuve_existante', trim(s.preuve_existante_2),
                        'url_preuve_numerique', trim(s.url_preuve_numerique_2),
                        'preuve_non_numerique', trim(s.preuve_non_numerique_2),
                        'obs_contexte', trim(s.obs_contexte_2),
                        'obs_description', trim(s.obs_description_2),
                        'occ_methode_determination', trim(s.occ_methode_determination_2)
                    )
                ELSE NULL::json
            END,

            -- 3ème groupe de champs
            CASE
                WHEN nullif(concat(
                    nullif(s.obs_technique_3, ''), nullif(s.occ_etat_biologique_3, ''),
                    nullif(s.occ_naturalite_3, ''), nullif(s.occ_sexe_3, ''),
                    nullif(s.occ_stade_de_vie_3, ''), nullif(s.occ_denombrement_min_3, ''),
                    nullif(s.occ_denombrement_max_3, ''), nullif(s.occ_type_denombrement_3, ''),
                    nullif(s.occ_statut_biogeographique_3, ''), nullif(s.occ_statut_biologique_3, ''),
                    nullif(s.occ_comportement_3, ''), nullif(s.preuve_existante_3, ''),
                    nullif(s.url_preuve_numerique_3, ''), nullif(s.preuve_non_numerique_3, ''),
                    nullif(s.obs_contexte_3, ''), nullif(s.obs_description_3, ''),
                    nullif(s.occ_methode_determination_3, '')
                ), '') IS NOT NULL THEN
                    json_build_object(
                        'obs_technique', trim(s.obs_technique_3),
                        'occ_etat_biologique', trim(s.occ_etat_biologique_3),
                        'occ_naturalite', trim(s.occ_naturalite_3),
                        'occ_sexe', trim(s.occ_sexe_3),
                        'occ_stade_de_vie', trim(s.occ_stade_de_vie_3),
                        'occ_denombrement_min', trim(s.occ_denombrement_min_3),
                        'occ_denombrement_max', trim(s.occ_denombrement_max_3),
                        'occ_type_denombrement', trim(s.occ_type_denombrement_3),
                        'occ_statut_biogeographique', trim(s.occ_statut_biogeographique_3),
                        'occ_statut_biologique', trim(s.occ_statut_biologique_3),
                        'occ_comportement', trim(s.occ_comportement_3),
                        'preuve_existante', trim(s.preuve_existante_3),
                        'url_preuve_numerique', trim(s.url_preuve_numerique_3),
                        'preuve_non_numerique', trim(s.preuve_non_numerique_3),
                        'obs_contexte', trim(s.obs_contexte_3),
                        'obs_description', trim(s.obs_description_3),
                        'occ_methode_determination', trim(s.occ_methode_determination_3)
                    )
                ELSE NULL::json
            END
        ], ',') || ']')::json AS descriptif_sujet,

        NULL AS donnee_complementaire,

        s.precision_geometrie::integer,
        s.nature_objet_geo,
    $SQL$;

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


-- Ajout d'un organisme avec id = -1 pour faciliter les imports (en évitant soucis de contraintes de clé étrangère)
INSERT INTO occtax.organisme (id_organisme, nom_organisme, commentaire)
VALUES (-1, 'Non défini', 'Organisme non défini. Utiliser pour éviter les soucis de contrainte de clé étrangère avec la table personne. Il faut utiliser l''organisme inconnu ou indépendant à la place')
ON CONFLICT DO NOTHING
;
-- Ajout d'un acteur INCONNU
INSERT INTO gestion.acteur (id_acteur, nom, prenom, civilite, id_organisme, remarque)
VALUES (-1, 'INCONNU', 'Inconnu', 'M', -1, 'Acteur non défini')
ON CONFLICT DO NOTHING;


-- Fonction pour personnaliser ce qui est fait en fin de fonction suivante occtax.import_observations_post_data
DROP FUNCTION IF EXISTS occtax.import_observations_post_data_regionale(text);
CREATE OR REPLACE FUNCTION occtax.import_observations_post_data_regionale(
    _jdd_id text
)
RETURNS jsonb AS
$BODY$
DECLARE
    sql_template TEXT;
    sql_text TEXT;
    _nb_lignes integer;
    _result jsonb;
BEGIN

    -- Le JSON qui sera renvoyé. On l'initialise à {}
    _result := jsonb_build_object();

    -- Calcul de sensibilité
    --
    -- COMMENTE CAR IL FAUT AU PREALABLE VERIFIER occtax.critere_sensibilite
    -- CAR LES OBS QUI NE TOMBENT PAS SOUS CES CRITERE VOIENT LE NIVEAU 0 DONNE
    -- sql_template := '
    -- WITH calcul AS (
    --     SELECT occtax.calcul_niveau_sensibilite(ARRAY[''%1$s''], False) AS resultat;
    -- ) SELECT resultat AS nb FROM calcul
    -- ;
    -- ';
    -- sql_text := format(sql_template,
    --     _jdd_id
    -- );
    -- EXECUTE sql_text INTO _nb_lignes;
    -- _result := _result || jsonb_build_object('calcul_sensibilite', _nb_lignes);


    -- Calcul de validite
    --
    -- COMMENTE CAR IL FAUT PRECISER DANS LA REQUETE COMMENT RECUPERER LE VALIDATEUR
    -- (2ème paramètre de calcul_niveau_validation)
    -- sql_template := '
    -- WITH calcul AS (
    --     SELECT occtax.calcul_niveau_validation(
    --         ARRAY[''%1$s''],
    --         (SELECT id_personne FROM personne WHERE identite=''Administrateur Borbonica''),
    --         FALSE
    --     ) AS resultat
    -- ) SELECT resultat AS nb FROM calcul
    -- ;
    -- ';
    -- sql_text := format(sql_template,
    --     _jdd_id
    -- );
    -- EXECUTE sql_text INTO _nb_lignes;
    -- _result := _result || jsonb_build_object('calcul_validite', _nb_lignes);


    RETURN _result;

END
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100
;


COMMENT ON FUNCTION occtax.import_observations_post_data_regionale(text)
IS 'Lancement de traitements SQL réalisés après l''import des données CSV.
Cette fonction est lancée par occtax.import_observations_post_data.
Elle attend en paramètre le jdd_id (pas le id_sinp_jdd)'
;


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
    sql_template := $$
    WITH ins AS (
        INSERT INTO occtax.lien_observation_identifiant_permanent
        (jdd_id, id_origine, id_sinp_occtax, dee_date_derniere_modification, dee_date_transformation)
        SELECT o.jdd_id, o.id_origine, o.id_sinp_occtax, o.dee_date_derniere_modification, o.dee_date_transformation
        FROM occtax.observation o
        WHERE True
            AND o.jdd_id IN ('%1$s')
            AND o.odata->>'import_temp_table' = '%2$s'
            AND o.odata->>'import_login' = '%3$s'
        ON CONFLICT ON CONSTRAINT lien_observation_id_sinp_occtax_jdd_id_id_origine_id_key
        DO NOTHING
        RETURNING id_origine
    ) SELECT count(*) AS nb FROM ins
    ;
    $$;
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
            sql_template := $$
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
                    Coalesce(trim(t.odata->>%4$s), 'NSP') AS valeur,
                    Coalesce(%7$s, 'NSP') AS unite,
                    Coalesce(%8$s, 'NSP') AS thematique,
                    Coalesce(%9$s, 'NSP') AS type

                FROM occtax.observation AS o
                JOIN "%2$s" AS t
                    ON t.id_origine = o.id_origine
                WHERE True
                    AND o.jdd_id IN ('%1$s')
                    AND o.odata->>'import_temp_table' = '%2$s'
                    AND o.odata->>'import_login' = '%3$s'
                    -- il faut avoir une valeur
                    AND nullif(trim(t.odata->>%4$s), '') IS NOT NULL
                ON CONFLICT ON CONSTRAINT attribut_additionnel_pkey
                DO NOTHING
                RETURNING cle_obs
            ) SELECT count(*) AS nb FROM ins
            ;
            $$;

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
    sql_template := $$
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
            SELECT DISTINCT trim(regexp_split_to_table(personnes, ',')) AS personne
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
    $$;
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
    sql_template := $$
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
            SELECT DISTINCT trim(regexp_split_to_table(personnes, ',')) AS personne
            FROM personnes
        ),
        valide AS (
            SELECT
                personne, v.*
            FROM personne, occtax.is_valid_identite(personne) AS v
        )
        INSERT INTO occtax.personne (identite, nom, prenom, mail, id_organisme)
        SELECT DISTINCT
            concat(items[1], ' ' || items[2]) AS identite,
            items[1] AS nom,
            items[2] AS prenom,
            '%2$s' AS mail,
            o.id_organisme
        FROM valide AS v
        LEFT JOIN occtax.organisme AS o
            ON o.nom_organisme = items[3]
        WHERE is_valid
        ON CONFLICT ON CONSTRAINT personne_identite_id_organisme_key DO NOTHING
		RETURNING identite
    ) SELECT count(*) AS nb FROM ins
    ;
    $$;
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
        sql_template := $$
        WITH ins AS (
            INSERT INTO occtax.observation_personne (cle_obs, id_personne, role_personne)
            WITH source AS (
                SELECT
                cle_obs,
                o.odata->>'%1$s' AS odata_%1$s,
                trim(%1$s) AS %2$s, rn
                FROM
                occtax.observation AS o,
                regexp_split_to_table(o.odata->>'%1$s', ',')  WITH ORDINALITY x(%1$s, rn)
                WHERE True
                AND o.odata->>'%1$s' IS NOT NULL
                AND o.id_sinp_jdd = '%3$s'
                ORDER BY o.cle_obs, rn
            )
            SELECT
                s.cle_obs, p.id_personne, '%4$s' AS role_personne
            FROM source AS s
            JOIN occtax.personne AS p
                ON s.%2$s = concat(p.identite, ' (', (SELECT nom_organisme FROM occtax.organisme og WHERE og.id_organisme = p.id_organisme), ')')
            ORDER BY cle_obs, rn
            ON CONFLICT DO NOTHING
		    RETURNING cle_obs, id_personne, role_personne
        ) SELECT count(*) AS nb FROM ins
        ;
        $$;
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
    sql_template := $$
        SELECT occtax.occtax_update_spatial_relationships(ARRAY['%1$s']) AS update_spatial;
    $$;
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
    sql_template := $$
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
    $$;
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
    sql_template := $$
        SELECT occtax.import_observations_post_data_regionale('%1$s') AS json_regional
    $$;
    sql_text := format(sql_template,
        _jdd_id
    );
    -- RAISE NOTICE '-- nettoyage';
    -- RAISE NOTICE '%', sql_text;
    EXECUTE sql_text INTO _result_regional;
    _result_information := _result_information || _result_regional;



    -- Nettoyage
    sql_template := $$
    WITH ins AS (
        UPDATE occtax.observation
        SET odata = odata - 'observateurs' - 'determinateurs'
        WHERE True
        AND jdd_id = '%1$s'
        AND odata->>'import_temp_table' = '%2$s'
        AND odata->>'import_login' = '%3$s'
        RETURNING cle_obs
    ) SELECT count(*) AS nb FROM ins
    ;
    $$;
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

-- Vue pour lister les données importées
DROP VIEW IF EXISTS occtax.v_import_web_liste;
CREATE OR REPLACE VIEW occtax.v_import_web_liste AS
SELECT
    row_number() OVER() AS id,
    (odata->>'import_time')::timestamp(0) AS date_import,
    id_sinp_jdd AS jdd,
    count(cle_obs) AS nombre_observations,
    odata->>'import_temp_table' AS code_import,
    odata->>'import_login' AS login_import,
    ST_Buffer(ST_ConvexHull(ST_Collect(ST_Centroid(geom))), 1)::geometry(POLYGON, {$SRID}) AS geom
FROM occtax.observation
WHERE odata ? 'import_login' AND odata ? 'import_time'
GROUP BY odata, id_sinp_jdd
ORDER BY date_import, code_import, login_import;
;

COMMENT ON VIEW occtax.v_import_web_liste
IS 'Vue utile pour lister les imports effectués par les utilisateurs depuis l''interface Web, à partir de fichiers CSV'
;

-- Vue pour voir toutes les observations importées en attente d'intégration
DROP VIEW IF EXISTS occtax.v_import_web_observations;
CREATE OR REPLACE VIEW occtax.v_import_web_observations AS
SELECT
o.cle_obs, o.id_origine, o.id_sinp_occtax,
cd_nom, nom_cite, cd_ref,
denombrement_min, denombrement_max, objet_denombrement, type_denombrement,
commentaire,
date_debut, date_fin, heure_debut, heure_fin, date_determination,
dee_floutage, diffusion_niveau_precision, ds_publique,
id_sinp_jdd,
statut_source, reference_biblio,
sensi_date_attribution, sensi_niveau, sensi_referentiel, sensi_version_referentiel,
precision_geometrie, nature_objet_geo,
(ST_Centroid(geom))::geometry(point, {$SRID}) AS geom,
(odata->>'import_time')::timestamp(0) AS date_import,
odata->>'import_temp_table' AS code_import,
odata->>'import_login' AS login_import

FROM occtax.observation AS o
WHERE odata ? 'import_login' AND odata ? 'import_time'
ORDER BY id_sinp_jdd, date_import, code_import, login_import;
;

COMMENT ON VIEW occtax.v_import_web_observations
IS 'Vue utile pour lister les observations importées par les utilisateurs depuis l''interface Web, à partir de fichier CSV. Seuls les centroides des géométries sont affichés.'
;

-- Fonction pour activer les observations importées, c'est-à-dire enlever leur statut temporaire
-- et les rendre visibles dans l'application pour l'ensemble des utilisateurs
DROP FUNCTION IF EXISTS occtax.import_activer_observations_importees(text, text);
CREATE OR REPLACE FUNCTION occtax.import_activer_observations_importees(
    _table_temporaire text,
    _jdd_uid text
)
RETURNS INTEGER AS
$BODY$
DECLARE
    _jdd_id TEXT;
    _nb_lignes integer;
BEGIN
    -- Get jdd_id from uid
    SELECT jdd_id
    INTO _jdd_id
    FROM occtax.jdd
    WHERE id_sinp_jdd = _jdd_uid
    ;

    IF _jdd_id IS NULL THEN
        RETURN 0;
    END IF;

    -- Validation
    UPDATE occtax.observation
    SET odata = odata - 'import_time' - 'import_login' - 'import_temp_table'
    WHERE True
    AND jdd_id = _jdd_id
    AND odata->>'import_temp_table' = _table_temporaire::text
    ;

    -- Nombre de lignes
    GET DIAGNOSTICS _nb_lignes = ROW_COUNT;

    RETURN _nb_lignes;

END
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100
;

COMMENT ON FUNCTION occtax.import_activer_observations_importees(text, text)
IS 'Activation des observations importées depuis un CSV dans l''interface Web
pour la table temporaire et le JDD UUID fournis.
Ces observations seront alors disponibles dans l''application';
;


-- Fonctions pour le module action de Lizmap
-- utiliser dans le projet de gestion pour activer les observations importées
-- ou les supprimer
DROP FUNCTION IF EXISTS public.query_to_geojson(text);
CREATE OR REPLACE FUNCTION public.query_to_geojson(datasource text)
RETURNS json AS
$$
DECLARE
    sqltext text;
    ajson json;
BEGIN
    sqltext:= format('
        SELECT jsonb_build_object(
            ''type'',  ''FeatureCollection'',
            ''features'', jsonb_agg(features.feature)
        )::json
        FROM (
          SELECT jsonb_build_object(
            ''type'',       ''Feature'',
            ''id'',         id,
            ''geometry'',   ST_AsGeoJSON(ST_Transform(geom, 4326))::jsonb,
            ''properties'', to_jsonb(inputs) - ''geom''
          ) AS feature
          FROM (
              SELECT * FROM (%s) foo
          ) AS inputs
        ) AS features
    ', datasource);
    RAISE NOTICE 'SQL = %s', sqltext;
    EXECUTE sqltext INTO ajson;
    RETURN ajson;
END;
$$
LANGUAGE 'plpgsql'
IMMUTABLE STRICT;

COMMENT ON FUNCTION public.query_to_geojson(text) IS 'Generate a valid GEOJSON from a given SQL text query.';


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
            WHERE id_sinp_jdd IN (
                SELECT id_sinp_jdd
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
