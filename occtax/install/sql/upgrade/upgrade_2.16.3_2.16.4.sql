-- Suppression des contraintes d'unicité de la table personne
-- et ajout d'une contrainte d'unicité seulement sur l'identité et l'organisme
ALTER TABLE occtax.personne DROP CONSTRAINT IF EXISTS personne_identite_id_organisme_key;
ALTER TABLE occtax.personne DROP CONSTRAINT IF EXISTS personne_identite_organisme_mail_key;
ALTER TABLE occtax.personne ADD CONSTRAINT personne_identite_id_organisme_key UNIQUE (identite, id_organisme);

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
        ON CONFLICT ON CONSTRAINT personne_identite_id_organisme_key DO NOTHING
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
