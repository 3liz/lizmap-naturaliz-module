CREATE OR REPLACE FUNCTION occtax.calcul_niveau_par_condition(
    p_contexte text,
    p_jdd_id TEXT[]
)
RETURNS INTEGER AS
$BODY$
DECLARE json_note TEXT;
DECLARE var_id_critere INTEGER;
DECLARE var_libelle TEXT;
DECLARE var_cd_nom bigint[];
DECLARE var_condition TEXT;
DECLARE var_table_jointure TEXT;
DECLARE var_niveau TEXT;
DECLARE sql_template TEXT;
DECLARE sql_text TEXT;
DECLARE var_count integer;
DECLARE sql_count text;

BEGIN

    -- celui qui a la plus petite note gagne à la fin
    -- (lorsqu''une observation a plusieurs notes données par plusieurs conditions)
    -- cela veut dire ci-dessous que les plus à gauche gagnent (ceux qui ont une note + petite)
    -- on fait attention ici de mettre les valeurs dans l'ordre pour faciliter la lecture de l'objet json_note
    IF p_contexte = 'sensibilite' THEN
        -- sensibilite : Aucune diffusion > département > dép & maille 10 > dep, mailles, en, com, znieff > maille 2 > maille 1 > précision max
        json_note := '{ "4": 1, "3": 2, "2": 3, "1": 4, "m02": 5, "m01": 6, "0": 7 }'; -- sensibilite
    ELSE
        -- validation: invalide > douteux > non évalué > non réalisable > probable > certain
        json_note := '{ "4": 1, "3": 2, "6": 3, "5": 4, "2": 5, "1": 6 }';
    END IF;

    -- Table pour stocker les niveaux calculés
    -- (plusieurs lignes possibles par identifiant_permanent si condition remplie pour plusieurs critères)
    DROP TABLE IF EXISTS occtax.niveau_par_observation;
    CREATE TABLE occtax.niveau_par_observation (
        id_critere integer NOT NULL,
        identifiant_permanent text NOT NULL,
        niveau text NOT NULL,
        contexte text NOT NULL,
        note INTEGER NOT NULL
     );

    DROP TABLE IF EXISTS occtax.niveau_par_observation_compteur;
    CREATE TABLE occtax.niveau_par_observation_compteur (
        id_critere integer NOT NULL,
        libelle text NOT NULL,
        contexte text NOT NULL,
        compteur text NOT NULL,
        condition text NOT NULL
    );

    -- On boucle sur les criteres
    FOR var_id_critere, var_libelle, var_cd_nom, var_condition, var_table_jointure, var_niveau IN
        SELECT id_critere, libelle, cd_nom, "condition", table_jointure, niveau
        FROM occtax.v_critere_validation_et_sensibilite
        WHERE contexte = p_contexte
    LOOP
        sql_template := '
        INSERT INTO occtax.niveau_par_observation
        (id_critere, identifiant_permanent, niveau, contexte, note)
        SELECT
            %s AS id_critere,
            o.identifiant_permanent,
            ''%s'' AS niveau,
            ''%s'' AS contexte,
            (''%s''::json->>''%s'')::integer AS note

        FROM occtax.observation o
        ';
        sql_text := format(sql_template, var_id_critere, var_niveau, p_contexte, json_note, var_niveau);

         -- optionnally add JOIN table
        IF var_table_jointure IS NOT NULL THEN
            sql_template := '
            , %s AS t
            ';
            sql_text := sql_text || format(sql_template, var_table_jointure);
        END IF;

        -- Condition du critère
        sql_template :=  '
        WHERE True
        -- cd_noms
        AND cd_nom = ANY (''%s''::BIGINT[])
        -- condition
        AND (
            %s
        )
        ';
        sql_text := sql_text || format(sql_template, var_cd_nom, var_condition);

        -- Filtre par jdd_id
        IF p_jdd_id IS NOT NULL THEN
            sql_template :=  '
            AND o.jdd_id = ANY ( ''%s''::TEXT[] )
            ';
            sql_text := sql_text || format(sql_template, p_jdd_id);
        END IF;

        -- Log SQL
        RAISE NOTICE '%' , sql_text;

        -- On insère les données dans occtax.niveau_par_observation
        EXECUTE sql_text;

        -- on enregistre les compteurs pour faciliter le débogage
        GET DIAGNOSTICS var_count = ROW_COUNT;
        sql_count := '
        INSERT INTO occtax.niveau_par_observation_compteur
        SELECT
            %s AS id_critere,
            ''%s'' AS contexte,
            ''%s'' AS libelle,
            %s AS compteur,
            %s AS condition
        ;';
        EXECUTE format(sql_count, var_id_critere, var_libelle, p_contexte, var_count, quote_literal(var_condition));

    END LOOP;

    -- Récupération d'une seule ligne par observation
    -- La note permet de dire qui gagne via le DISTINCT ON et le ORDER BY
    DROP TABLE IF EXISTS occtax.niveau_par_observation_final;
    CREATE TABLE occtax.niveau_par_observation_final AS
    SELECT DISTINCT ON (identifiant_permanent) niveau, identifiant_permanent, id_critere, contexte
    FROM occtax.niveau_par_observation
    WHERE contexte = p_contexte
    ORDER BY identifiant_permanent, note;

    RETURN 1;

END
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

-- calcul validation
CREATE OR REPLACE FUNCTION occtax.calcul_niveau_validation(
    p_jdd_id text[],
    p_validateur integer,
    p_simulation boolean)
  RETURNS integer AS
$BODY$
DECLARE sql_template TEXT;
DECLARE sql_text TEXT;
DECLARE useless INTEGER;
DECLARE procedure_ref_record RECORD;
BEGIN

    -- On vérifie qu'on a des données pour le référentiel de validation
    SELECT INTO procedure_ref_record
        "procedure", proc_vers, proc_ref
    FROM occtax.validation_procedure
    LIMIT 1;
    IF procedure_ref_record.proc_vers IS NULL THEN
        RAISE EXCEPTION '[naturaliz] La table validation_procedure est vide';
        RETURN 0;
    END IF;

    -- Remplissage de la table avec les valeurs issues des conditions
    SELECT occtax.calcul_niveau_par_condition(
        'validation',
        p_jdd_id
    ) INTO useless;

    -- UPDATE des observations qui rentrent dans les critères
    if p_simulation IS NOT TRUE THEN
        sql_template := '
        INSERT INTO occtax.validation_observation AS vo
        (
            identifiant_permanent,
            date_ctrl,
            niv_val,
            typ_val,
            ech_val,
            peri_val,
            comm_val,
            validateur,
            "procedure",
            proc_vers,
            proc_ref
        )
        SELECT
            t.identifiant_permanent,
            now(),
            t.niveau,
            ''A'',  -- automatique
            ''2'', -- ech_val
            ''1'', -- perimetre minimal
            ''Validation automatique du '' || now()::DATE || '' : '' || cv.libelle,
            $1, -- validateur

            -- On utilise les valeurs de la table procedure
            p."procedure",
            p.proc_vers,
            p.proc_ref

        FROM occtax.niveau_par_observation_final AS t
        JOIN occtax.critere_validation AS cv ON t.id_critere = cv.id_critere,
        (
            SELECT "procedure", proc_vers, proc_ref
            FROM occtax.validation_procedure, regexp_split_to_array(trim(proc_vers),  ''\.'')  AS a
            ORDER BY concat(lpad(a[1], 3, ''0''), lpad(a[2], 3, ''0''), lpad(a[3], 3, ''0'')) DESC
            LIMIT 1
        ) AS p
        WHERE True
        AND t.contexte = ''validation''
        AND t.identifiant_permanent = identifiant_permanent
        ON CONFLICT ON CONSTRAINT validation_observation_identifiant_permanent_ech_val_unique
        DO UPDATE
        SET (
            date_ctrl,
            niv_val,
            typ_val,
            ech_val,
            peri_val,
            comm_val,
            validateur,
            "procedure",
            proc_vers,
            proc_ref
        ) =
        (
            now(),
            EXCLUDED.niv_val,
            ''A'',  --automatique
            ''2'', -- ech_val
            ''1'', -- perimetre minimal
            ''Validation automatique du '' || now()::DATE,
            $1, -- validateur

            -- On utilise les valeurs de la table procedure
            $2,
            $3,
            $4
        )
         WHERE TRUE
        AND vo.typ_val NOT IN (''M'', ''C'')
        ';
        EXECUTE format(sql_template)
        USING p_validateur, procedure_ref_record."procedure", procedure_ref_record.proc_vers, procedure_ref_record.proc_ref;
    END IF;

    -- On supprime les lignes dans validation_observation pour ech_val = '2' et identifiant_permanent NOT IN
    -- qui ne correspondent pas au critère et qui ne sont pas manuelles
    -- on a bien ajouté le WHERE AND vo.typ_val NOT IN (''M'', ''C'')
    -- pour ne surtout pas supprimer les validations manuelles ou combinées via notre outil auto
    if p_simulation IS NOT TRUE THEN
        sql_template := '
        DELETE FROM occtax.validation_observation vo
        WHERE TRUE
        AND ech_val = ''2''
        AND vo.typ_val NOT IN (''M'', ''C'')
        AND identifiant_permanent NOT IN (
            SELECT identifiant_permanent
            FROM occtax.niveau_par_observation_final AS t
            WHERE contexte = ''validation''
        )
        ';
        sql_text := format(sql_template);
        -- on doit ajouter le filtre jdd_id si non NULL
        IF p_jdd_id IS NOT NULL THEN
            sql_template :=  '
            AND identifiant_permanent IN (
                SELECT identifiant_permanent
                FROM occtax.observation
                WHERE jdd_id = ANY ( ''%s''::TEXT[] )
            )
            ';
            sql_text := sql_text || format(sql_template, p_jdd_id);
        END IF;

        EXECUTE sql_text;
    END IF;

    RETURN 1;

END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- calcul sensibilite
CREATE OR REPLACE FUNCTION occtax.calcul_niveau_sensibilite(
    p_jdd_id text[],
    p_simulation boolean)
  RETURNS integer AS
$BODY$
DECLARE sql_template TEXT;
DECLARE sql_text TEXT;
DECLARE useless INTEGER;
DECLARE sensi_ref_record RECORD;
BEGIN

    -- On vérifie qu'on a des données pour le référentiel de sensibilité
    SELECT INTO sensi_ref_record
        sensi_referentiel, sensi_version_referentiel
    FROM occtax.sensibilite_referentiel
    LIMIT 1;
    IF sensi_ref_record.sensi_referentiel IS NULL THEN
        RAISE EXCEPTION '[naturaliz] La table sensibilite_referentiel est vide';
        RETURN 0;
    END IF;

    -- Remplissage de la table avec les valeurs issues des conditions
    SELECT occtax.calcul_niveau_par_condition(
        'sensibilite',
        p_jdd_id
    ) INTO useless;

    -- UPDATE des observations
    if p_simulation IS NOT TRUE THEN
        sql_template := '
        UPDATE occtax.observation o
        SET (
            sensi_date_attribution, sensi_niveau,
            sensi_referentiel, sensi_version_referentiel
        )
        = (
            now(), niveau,
            p.sensi_referentiel, p.sensi_version_referentiel
        )
        FROM occtax.niveau_par_observation_final AS t,
        (
            SELECT sensi_referentiel, sensi_version_referentiel
            FROM occtax.sensibilite_referentiel, regexp_split_to_array(trim(sensi_version_referentiel),  ''\.'')  AS a
            ORDER BY concat(lpad(a[1], 3, ''0''), lpad(a[2], 3, ''0''), lpad(a[3], 3, ''0'')) DESC
            LIMIT 1
        ) AS p
        WHERE True
        AND contexte = ''sensibilite''
        AND t.identifiant_permanent = o.identifiant_permanent
        ';
        sql_text := format(sql_template);

        RAISE NOTICE '%' , sql_text;
        EXECUTE sql_text;


    -- On update les observations
    -- qui ne sont pas attrapées par les critères
    -- pour remettre la valeur par défaut cad sensi_niveau = 0

    if p_simulation IS NOT TRUE THEN
        sql_template := '
        UPDATE occtax.observation o
        SET (
            sensi_date_attribution, sensi_niveau,
            sensi_referentiel, sensi_version_referentiel
        )
        = (
            now(), ''0'',
            p.sensi_referentiel, p.sensi_version_referentiel
        )
        FROM
        (
            SELECT sensi_referentiel, sensi_version_referentiel
            FROM occtax.sensibilite_referentiel, regexp_split_to_array(trim(sensi_version_referentiel),  ''\.'')  AS a
            ORDER BY concat(lpad(a[1], 3, ''0''), lpad(a[2], 3, ''0''), lpad(a[3], 3, ''0'')) DESC
            LIMIT 1
        ) AS p
        WHERE True
        -- AND o.sensi_referentiel = p.sensi_referentiel
        AND o.identifiant_permanent NOT IN(
            SELECT identifiant_permanent
            FROM occtax.niveau_par_observation_final
            WHERE contexte = ''sensibilite''
        )

        ';
        sql_text := format(sql_template);

        -- on doit ajouter le filtre jdd_id si non NULL
        IF p_jdd_id IS NOT NULL THEN
            sql_template :=  '
            AND o.jdd_id = ANY ( ''%s''::TEXT[] )
            ';
            sql_text := sql_text || format(sql_template, p_jdd_id);
        END IF;

        RAISE NOTICE '%' , sql_text;
        EXECUTE sql_text;
    END IF;


    END IF;

    RETURN 1;

END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
