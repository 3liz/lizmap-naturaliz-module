BEGIN;

--
-- Extension validation
--
SET search_path TO occtax,public;

DROP FUNCTION IF EXISTS occtax.occtax_update_sensibilite_observations( text,  TEXT,  TEXT,  text[],  TEXT[],  BIGINT[]);

-- table validation_observation
DROP TABLE IF EXISTS validation_observation CASCADE;
CREATE TABLE validation_observation (
    id_validation serial,
    identifiant_permanent text,
    date_ctrl date NOT NULL,
    niv_val text NOT NULL,
    typ_val text NOT NULL,
    ech_val text NOT NULL,
    peri_val text NOT NULL,
    validateur integer NOT NULL,
    proc_vers text NOT NULL,
    producteur text,
    date_contact date,
    procedure text,
    proc_ref text,
    comm_val text,
    CONSTRAINT validation_observation_niv_val_ok CHECK (niv_val IN ( '1', '2', '3', '4', '5' ) ),
    CONSTRAINT validation_observation_typ_val_ok CHECK (typ_val IN ( 'A', 'C', 'M') ),
    CONSTRAINT validation_observation_peri_val_ok CHECK (peri_val IN ( '1', '2' ) ),
    CONSTRAINT validation_observation_ech_val_ok CHECK (ech_val IN ( '1', '2', '3') )
);
ALTER TABLE validation_observation ADD PRIMARY KEY (id_validation);
-- Contrainte d''unicité sur le couple identifiant_permanent, ech_val : une seule validation nationale, régionale ou producteur (donc au max 3)
ALTER TABLE validation_observation ADD CONSTRAINT validation_observation_identifiant_permanent_ech_val_unique UNIQUE (identifiant_permanent, ech_val);

-- PAS DE CONTRAINTE de clés étrangère sur la table observation, car on veut pouvoir supprimer des observations,
-- mais conserver les données dans validation_observation (l'identifiant permanent sera valide)
-- ALTER TABLE validation_observation ADD CONSTRAINT validation_observation_identifiant_permanent_fk FOREIGN KEY (identifiant_permanent)
-- REFERENCES observation (identifiant_permanent)
-- ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE validation_observation ADD CONSTRAINT validation_observation_validateur_fkey
FOREIGN KEY (validateur)
REFERENCES personne (id_personne)
ON UPDATE RESTRICT ON DELETE RESTRICT;

COMMENT ON TABLE validation_observation IS 'Décrit les opérations de validation scientifique et le niveau de validation attribué à la donnée d''occurrence. Les contrôles de validation scientifique ont été effectués au niveau régional ou national. Il n''est possible de transmettre que 2 résultats de contrôle de validation au maximum via ce concept : l''un national, l''autre régional.';

COMMENT ON COLUMN validation_observation.date_ctrl IS 'Date de réalisation du contrôle de validation. Format AAAA-MM-JJ.';

COMMENT ON COLUMN validation_observation.niv_val IS 'Niveau de validité attribué à la donnée à la suite de son contrôle. Le niveau de validité et le libellé associé peuvent se trouver dans les nomenclatures NivValAutoValue et NivValManCom suivant qu''on a procédé à une validation automatique ou à une validation manuelle ou combinée.';

COMMENT ON COLUMN validation_observation.typ_val IS 'Type de validation effectué. Les valeurs permises sont décrites dans la nomenclature TypeValValue, et peuvent avoir été mises à jour : voir le site des standards de données, http://standards-sinp.mnhn.fr';

COMMENT ON COLUMN validation_observation.ech_val IS 'Echelle de validation de la donnée : producteur, régionale ou nationale. Indique quelle plateforme a réalisé les opérations de validation scientifique. Les valeurs possibles sont définies par la nomenclature EchelleValidationValue, susceptible d''évoluer au fil du temps.';

COMMENT ON COLUMN validation_observation.peri_val IS 'Périmètre de validation de la donnée. Il est défini par les valeurs de la nomenclature PerimetreValidationValue.';

COMMENT ON COLUMN validation_observation.validateur IS 'Validateur (personne et organisme ayant procédé à la validation, éventuellement mail). Voir PersonneType dans le standard occurrences de taxons pour savoir comment le remplir.';

COMMENT ON COLUMN validation_observation.producteur IS 'Personne recontactée par l''expert chez le producteur lorsque l''expert a eu besoin d''informations complémentaires de la part du producteur. Ensemble d''attributs de "PersonneType" (voir standard occurrences de taxons), identité, organisme, éventuellement mail, à remplir dès lors qu''un contact avec le producteyr a eu lieu.';

COMMENT ON COLUMN validation_observation.date_contact IS 'Date de contact avec le producteur par l''expert lors de la validation. Doit être rempli si une personne a été recontactée.';

COMMENT ON COLUMN validation_observation.procedure IS 'Procédure utilisée pour la validation de la donnée. Description succincte des opérations réalisées. Si l''on dispose déjà d''une référence qu''on a indiquée dans procRef, pour des raisons de volume de données, il n''est pas nécessire de remplir cet attribut.';

COMMENT ON COLUMN validation_observation.proc_vers IS 'Version de la procédure utilisée.';

COMMENT ON COLUMN validation_observation.proc_ref IS 'Référence permettant de retrouver la procédure : URL, référence biblio, texte libre. Exemple : https://inpn.mnhn.fr/docs-web/docs/download/146208';

COMMENT ON COLUMN validation_observation.comm_val IS 'Commentaire sur la validation.';


-- Tables et fonctions de gestion de validation et sensibilite automatique
--

-- table critere_validation
DROP TABLE IF EXISTS critere_validation CASCADE;
CREATE TABLE critere_validation (
    id_critere serial,
    cd_nom bigint[] NOT NULL,
    libelle text NOT NULL,
    description text,
    condition text NOT NULL,
    table_jointure text,
    niveau text NOT NULL,
    CONSTRAINT critere_validation_niveau_valide CHECK ( niveau IN ( '1', '2', '3', '4', '5' ) )

);
ALTER TABLE critere_validation ADD PRIMARY KEY (id_critere);

COMMENT ON TABLE critere_validation IS 'Liste les critères qui permettent de calculer un niveau de validation sur chacune des observations, via l''utilisation de conditions SQL, pour un taxon ou un ensemble de taxons.';

COMMENT ON COLUMN critere_validation.id_critere IS 'Identifiant unique';
COMMENT ON COLUMN critere_validation.cd_nom IS 'Tableau de cd_nom pour lesquels attribuer le niveau en fonction de la condition';
COMMENT ON COLUMN critere_validation.libelle IS 'Libellé court de la condition';
COMMENT ON COLUMN critere_validation.description IS 'Description de la motivation de cette condition et des choix effectués';
COMMENT ON COLUMN critere_validation.condition IS 'Condition au format SQL s''appliquant sur les champs de la table observation. Une sous-requête peut être effectuée vers d''autres tables. Ex: "altitude_max" > 500 AND altitude_max < 1500';
COMMENT ON COLUMN critere_validation.table_jointure IS 'Nom de la table utilisée pour une condition de jointure. On peut par exemple l''utiliser pour une intersection spatiale. Par exemple les tampons à 100m autour des rivières. Pour des soucis de performance, il faut faire une jointure et non une condition simple. Cette table doit être stockée dans le schéma sig';
COMMENT ON COLUMN critere_validation.niveau IS 'Niveau de validation à appliquer pour la condition. Doit correspondre à la nomenclature.';


-- table critere_sensibilite
DROP TABLE IF EXISTS critere_sensibilite CASCADE;
CREATE TABLE critere_sensibilite (
    id_critere serial,
    cd_nom bigint[] NOT NULL,
    libelle text NOT NULL,
    description text,
    condition text NOT NULL,
    table_jointure text,
    niveau text NOT NULL,
    CONSTRAINT critere_sensibilite_niveau_valide CHECK ( niveau IN ( 'm02', '0', '1', '2', '3', '4' ) )

);
ALTER TABLE critere_sensibilite ADD PRIMARY KEY (id_critere);

COMMENT ON TABLE critere_sensibilite IS 'Liste les critères qui permettent de calculer un niveau de sensibilité sur chacune des observations, via l''utilisation de conditions SQL, pour un taxon ou un ensemble de taxons.';

COMMENT ON COLUMN critere_sensibilite.id_critere IS 'Identifiant unique';
COMMENT ON COLUMN critere_sensibilite.cd_nom IS 'Tableau de cd_nom pour lesquels attribuer le niveau en fonction de la condition';
COMMENT ON COLUMN critere_sensibilite.libelle IS 'Libellé court de la condition';
COMMENT ON COLUMN critere_sensibilite.description IS 'Description de la motivation de cette condition et des choix effectués';
COMMENT ON COLUMN critere_sensibilite.condition IS 'Condition au format SQL s''appliquant sur les champs de la table observation. Une sous-requête peut être effectuée vers d''autres tables. Ex: "altitude_max" > 500 AND altitude_max < 1500';
COMMENT ON COLUMN critere_sensibilite.table_jointure IS 'Nom de la table utilisée pour une condition de jointure. On peut par exemple l''utiliser pour une intersection spatiale. Par exemple les tampons à 100m autour des rivières. Pour des soucis de performance, il faut faire une jointure et non une condition simple. Cette table doit être stockée dans le schéma sig';
COMMENT ON COLUMN critere_sensibilite.niveau IS 'Niveau de sensibilité à appliquer pour la condition. Doit correspondre à la nomenclature. Liste des niveaux : ''m02'', ''0'', ''1'', ''2'', ''3'', ''4'' ';


CREATE OR REPLACE VIEW occtax.v_critere_validation_et_sensibilite AS
    SELECT *, 'sensibilite' AS contexte FROM occtax.critere_sensibilite
    UNION ALL
    SELECT *, 'validation' AS contexte FROM occtax.critere_validation
;



-- validation_procedure
CREATE TABLE validation_procedure (
    id serial NOT NULL PRIMARY KEY,
    proc_ref text,
    "procedure" text,
    proc_vers text
);
COMMENT ON TABLE validation_procedure IS 'Procédures de validation.';

COMMENT ON COLUMN validation_procedure.id IS 'Id unique de la procédure (entier auto)';
COMMENT ON COLUMN validation_procedure.proc_ref IS 'Référence permettant de retrouver la procédure : URL, référence biblio, texte libre';
COMMENT ON COLUMN validation_procedure.procedure IS 'Procédure utilisée pour la validation de la donnée. Description succincte des opérations réalisées.';
COMMENT ON COLUMN validation_procedure.proc_vers IS 'Version de la procédure utilisée.';
ALTER TABLE validation_procedure ADD CONSTRAINT validation_procedure_unique UNIQUE (proc_ref, "procedure", proc_vers);

ALTER TABLE occtax.validation_procedure ADD CONSTRAINT proc_vers_valide CHECK ( proc_vers ~ '^\d{1,2}\.\d{1,2}\.\d{1,2}$' );

-- sensibilite_referentiel
DROP TABLE IF EXISTS sensibilite_referentiel;
CREATE TABLE sensibilite_referentiel (
    id serial NOT NULL PRIMARY KEY,
    sensi_referentiel text,
    sensi_version_referentiel text,
    description text
);
COMMENT ON TABLE sensibilite_referentiel IS 'Référentiel de sensibilité.';

COMMENT ON COLUMN sensibilite_referentiel.id IS 'Id unique du référentiel de sensibilité (entier auto)';
COMMENT ON COLUMN sensibilite_referentiel.sensi_referentiel IS 'Référence permettant de retrouver la procédure : URL, référence biblio, texte libre';
COMMENT ON COLUMN sensibilite_referentiel.sensi_version_referentiel IS 'Version du référentiel de sensibilité. Doit être du type *.*.* Par ex: 1.0.0';
COMMENT ON COLUMN sensibilite_referentiel.description IS 'Description du référentiel.';
ALTER TABLE sensibilite_referentiel ADD CONSTRAINT sensibilite_referentiel_unique UNIQUE (sensi_referentiel, sensi_version_referentiel);

ALTER TABLE occtax.sensibilite_referentiel ADD CONSTRAINT sensi_version_referentiel_valide CHECK ( sensi_version_referentiel ~ '^\d{1,2}\.\d{1,2}\.\d{1,2}$' );


CREATE OR REPLACE FUNCTION occtax.calcul_niveau_par_condition(
    p_contexte text,
    p_jdd_id TEXT[]
)
RETURNS INTEGER AS
$BODY$
DECLARE json_note TEXT;
DECLARE var_id_critere INTEGER;
DECLARE var_cd_nom bigint[];
DECLARE var_condition TEXT;
DECLARE var_table_jointure TEXT;
DECLARE var_niveau TEXT;
DECLARE sql_template TEXT;
DECLARE sql_text TEXT;

BEGIN

    -- celui qui a la plus petite note gagne à la fin
    -- (lorsqu''une observation a plusieurs notes données par plusieurs conditions)
    IF p_contexte = 'sensibilite' THEN
        json_note := '{"0": 6, "m02": 5, "1": 4, "2": 3, "3": 2, "4": 1}'; -- sensibilite
    ELSE
        json_note := '{"1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 0}'; -- validation
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


    -- On boucle sur les criteres
    FOR var_id_critere, var_cd_nom, var_condition, var_table_jointure, var_niveau IN
        SELECT id_critere, cd_nom, "condition", table_jointure, niveau
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
        EXECUTE format(sql_template)
        ;
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

        RAISE NOTICE '%' , sql_text;
        EXECUTE sql_text;
    END IF;


    END IF;

    RETURN 1;

END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



-- nomenclature
-- validation
DELETE FROM nomenclature WHERE champ = 'niv_val_auto';
INSERT INTO nomenclature VALUES ('niv_val_auto', '1', 'Certain - très probable', 'La donnée présente un haut niveau de vraisemblance (très majoritairement cohérente) selon le protocole automatique appliquée. Le résultat de la procédure correspond à la définition optimale de satisfaction de l’ensemble des critères du protocole automatique, par exemple, lorsque la localité correspond à la distribution déjà connue et que les autres paramètres écologiques (date de visibilité, altitude, etc.) sont dans la gamme habituelle de valeur.');
INSERT INTO nomenclature VALUES ('niv_val_auto', '2', 'Probable', 'La donnée est cohérente et plausible selon le protocole automatique appliqué mais ne satisfait pas complétement (intégralement) l’ensemble des critères automatiques appliqués. La donnée présente une forte probabilité d’être juste. Elle ne présente aucune discordance majeure sur les critères jugés les plus importants mais elle satisfait seulement à un niveau intermédiaire, ou un ou plusieurs des critères automatiques appliqués.');
INSERT INTO nomenclature VALUES ('niv_val_auto', '3', 'Douteux', 'La donnée concorde peu selon le protocole automatique appliqué. La donnée est peu cohérente ou incongrue. Elle ne satisfait pas ou peu un ou plusieurs des critères automatiques appliqués. Elle ne présente cependant pas de discordance majeure sur les critères jugés les plus importants qui permettraient d’attribuer le plus faible niveau de validité (invalide).');
INSERT INTO nomenclature VALUES ('niv_val_auto', '4', 'Invalide', 'La donnée ne concorde pas selon la procédure automatique appliquée. Elle présente au moins une discordance majeure sur un des critères jugés les plus importants ou la majorité des critères déterminants sont discordants. Elle est considérée comme trop improbable (aberrante notamment au regard de l’aire de répartition connue, des paramètres biotiques et abiotiques de la niche écologique du taxon). Elle est considérée comme invalide.');
INSERT INTO nomenclature VALUES ('niv_val_auto', '5', 'Non réalisable', 'La donnée a été soumise à l’ensemble du processus de validation mais l’opérateur (humain ou machine) n’a pas pu statuer sur le niveau de fiabilité, notamment à cause des points suivants : état des connaissances du taxon insuffisantes, ou informations insuffisantes sur l’observation.');

DELETE FROM nomenclature WHERE champ = 'niv_val_mancom';
INSERT INTO nomenclature VALUES ('niv_val_mancom', '1', 'Certain - très probable', 'Certain - très probable : La donnée est exacte. Il n’y a pas de doute notable et significatif quant à l’exactitude de l’observation ou de la détermination du taxon. La validation a été réalisée notamment à partir d’une preuve de l’observation qui confirme la détermination du producteur ou après vérification auprès de l’observateur et/ou du déterminateur.');
INSERT INTO nomenclature VALUES ('niv_val_mancom', '2', 'Probable', 'Probable : La donnée présente un bon niveau de fiabilité. Elle est vraisemblable et crédible. Il n’y a, a priori, aucune raison de douter de l’exactitude de la donnée mais il n’y a pas d’éléments complémentaires suffisants disponibles ou évalués (notamment la présence d’une preuve ou la possibilité de revenir à la donnée source) permettant d’attribuer un plus haut niveau de certitude.');
INSERT INTO nomenclature VALUES ('niv_val_mancom', '3', 'Douteux', 'Douteux : La donnée est peu vraisemblable ou surprenante mais on ne dispose pas d’éléments suffisants pour attester d’une erreur manifeste. La donnée est considérée comme douteuse.');
INSERT INTO nomenclature VALUES ('niv_val_mancom', '4', 'Invalide', 'Invalide : La donnée a été infirmée (erreur manifeste/avérée) ou présente un trop bas niveau de fiabilité. Elle est considérée comme trop improbable (aberrante notamment au regard de l’aire de répartition connue, des paramètres biotiques et abiotiques de la niche écologique du taxon, la preuve révèle une erreur de détermination). Elle est considérée comme invalide.');
INSERT INTO nomenclature VALUES ('niv_val_mancom', '5', 'Non réalisable', 'Non réalisable : La donnée a été soumise à l’ensemble du processus de validation mais l’opérateur (humain ou machine) n’a pas pu statuer sur le niveau de fiabilité, notamment à cause des points suivants : état des connaissances du taxon insuffisantes, ou informations insuffisantes sur l’observation.');

DELETE FROM nomenclature WHERE champ = 'criticite';
INSERT INTO nomenclature VALUES ('criticite', '1', 'Mineure', 'Mineure : La modification n''est pas de nature à modifier le niveau de validité de la donnée.');
INSERT INTO nomenclature VALUES ('criticite', '2', 'Majeure', 'Majeure : La modification est de nature à modifier le niveau de validité de la donnée.');

DELETE FROM nomenclature WHERE champ = 'typ_val';
INSERT INTO nomenclature VALUES ('typ_val', 'A', 'Automatique', 'Automatique : Résulte d''une validation automatique');
INSERT INTO nomenclature VALUES ('typ_val', 'C', 'Combinée', 'Combinée : Résulte de la combinaison d''une validation automatique et d''une validation manuelle');
INSERT INTO nomenclature VALUES ('typ_val', 'M', 'Manuelle', 'Manuelle : Résulte d''une validation manuelle (intervention d''un expert)');

DELETE FROM nomenclature WHERE champ = 'peri_val';
INSERT INTO nomenclature VALUES ('peri_val', '1', 'Périmètre minimal', 'Périmètre minimal : Validation effectuée sur la base des attributs minimaux, à savoir le lieu, la date, et le taxon.');
INSERT INTO nomenclature VALUES ('peri_val', '2', 'Périmètre maximal', 'Périmètre élargi : validation scientifique sur la base des attributs minimaux, lieu, date, taxon, incluant également des  vérifications sur d''autres attributs, précisés dans la procédure de validation associé.');

DELETE FROM nomenclature WHERE champ = 'ech_val';
INSERT INTO nomenclature VALUES ('ech_val', '1', 'Validation producteur', 'Validation scientifique des données par le producteur');
INSERT INTO nomenclature VALUES ('ech_val', '2', 'Validation régionale', 'Validation scientifique effectuée par la plateforme régionale');
INSERT INTO nomenclature VALUES ('ech_val', '3', 'Validation nationale', 'Validation scientifique effectuée par la plateforme nationale');


-- VALIDATION : vue et triggers pour validation par les validateurs agréés
DROP VIEW IF EXISTS occtax.v_observation_validation CASCADE;
CREATE OR REPLACE VIEW occtax.v_observation_validation AS

SELECT
-- Observation
o.cle_obs, statut_observation,

--Taxon
o.cd_nom, o.cd_ref, nom_cite,

t.nom_valide, t.reu, t.nom_vern, t.group1_inpn, t.group2_inpn,

--Individus observés
denombrement_min, denombrement_max, objet_denombrement, type_denombrement,

-- Descriptif sujet
REPLACE(replace((jsonb_pretty(array_to_json(array_agg(json_build_object(
    'obs_methode',
    dict->>(concat('obs_methode', '_', obs_methode)) ,
    'occ_etat_biologique',
    dict->>(concat('occ_etat_biologique', '_', occ_etat_biologique)),
    'occ_naturalite',
    dict->>(concat('occ_naturalite', '_', occ_naturalite)),
    'occ_sexe',
    dict->>(concat('occ_sexe', '_', occ_sexe)),
    'occ_stade_de_vie',
    dict->>(concat('occ_stade_de_vie', '_', occ_stade_de_vie)),
    'occ_statut_biogeographique',
    dict->>(concat('occ_statut_biogeographique', '_', occ_statut_biogeographique)),
    'occ_statut_biologique',
    dict->>(concat('occ_statut_biologique', '_', occ_statut_biologique)),
    'preuve_existante',
    dict->>(concat('preuve_existante', '_', preuve_existante)),
    'preuve_numerique',
    preuve_numerique,
    'preuve_numerique',
    preuve_non_numerique,
    'obs_contexte',
    obs_contexte,
    'obs_description',
    obs_description,
    'occ_methode_determination',
    dict->>(concat('occ_methode_determination', '_', occ_methode_determination))
)))::jsonb)::text), '"', ''), ':', ' : ') AS descriptif_sujet,

date_determination,

-- Quand ?
date_debut, date_fin, heure_debut, heure_fin,

--Où ?
geom, altitude_moy,  precision_geometrie, nature_objet_geo,

--Personnes
string_agg(
    vobs.identite || concat(' - ' || vobs.mail, ' (' || vobs.organisme || ')' ),
    ', '
) AS observateurs,
string_agg(
    vdet.identite || concat(' - ' || vdet.mail, ' (' || vdet.organisme || ')' ),
    ', '
) AS determinateurs,

organisme_gestionnaire_donnees,

--Généralités
commentaire, code_idcnp_dispositif,  dee_date_transformation, dee_date_derniere_modification,

jdd.jdd_code, jdd.jdd_id, jdd.jdd_description, jdd.jdd_metadonnee_dee_id,
statut_source, reference_biblio,

-- Diffusion
ds_publique, diffusion_niveau_precision, sensi_niveau,

--Validation
validite_niveau, validite_date_validation,
-- table validation_observation
id_validation,
date_ctrl,
niv_val,
typ_val,
ech_val,
peri_val,
string_agg( vval.identite || concat(' - ' || vval.mail, ' (' || vval.organisme || ')' ), ', ') AS validateur,
proc_vers,
producteur,
date_contact,
"procedure",
proc_ref,
comm_val


FROM occtax.observation o
LEFT JOIN taxon.taxref AS t USING (cd_nom)
LEFT JOIN occtax.v_observateur AS vobs USING (cle_obs)
LEFT JOIN occtax.personne AS vval USING (id_personne)
LEFT JOIN occtax.v_determinateur AS vdet USING (cle_obs)
LEFT JOIN occtax.jdd USING (jdd_id)
-- plateforme régionale
LEFT JOIN occtax.validation_observation v ON "ech_val" = '2' AND v.identifiant_permanent = o.identifiant_permanent
left join lateral
jsonb_to_recordset(o.descriptif_sujet) AS (
    obs_methode text,
    occ_etat_biologique text,
    occ_naturalite text,
    occ_sexe text,
    occ_stade_de_vie text,
    occ_statut_biogeographique text,
    occ_statut_biologique text,
    preuve_existante text,
    preuve_numerique text,
    preuve_non_numerique text,
    obs_contexte text,
    obs_description text,
    occ_methode_determination text
) ON TRUE,
occtax.v_nomenclature_plat
GROUP BY
o.cle_obs, statut_observation,
o.cd_nom, nom_cite,
t.nom_valide, t.reu, t.nom_vern, t.group1_inpn, t.group2_inpn,
denombrement_min, denombrement_max, objet_denombrement, type_denombrement,

date_determination,  date_debut, date_fin, heure_debut, heure_fin,
geom, altitude_moy,  precision_geometrie, nature_objet_geo,
commentaire, code_idcnp_dispositif,  dee_date_transformation, dee_date_derniere_modification,
jdd.jdd_code, jdd.jdd_id, jdd.jdd_description, jdd.jdd_metadonnee_dee_id,
statut_source, reference_biblio,
ds_publique, diffusion_niveau_precision, sensi_niveau,
validite_niveau, validite_date_validation,
id_validation,
date_ctrl,
niv_val,
typ_val,
ech_val,
peri_val,
validateur,
proc_vers,
producteur,
date_contact,
"procedure",
proc_ref,
comm_val
;


-- validation_personne
SET search_path TO occtax,public;

CREATE TABLE validation_personne (
    id_personne integer NOT NULL,
    role_postgresql text NOT NULL,
    role_postgresql_groupe text
);
ALTER TABLE validation_personne ADD PRIMARY KEY (id_personne, role_postgresql);
COMMENT ON TABLE validation_personne IS 'Stockage du lien entre personnes (id_personne) et roles postgresql';
COMMENT ON COLUMN validation_personne.id_personne IS 'Identifiant de la personne (lien avec occtax.personne)';
COMMENT ON COLUMN validation_personne.role_postgresql IS 'Role PostgreSQL de connexion, en lien avec cette personne. Par exemple john_doe_acme';
COMMENT ON COLUMN validation_personne.role_postgresql_groupe IS 'Role PostgreSQL jouant le rôle de groupe pour le role_postgresql. C''est ce role role_postgresql_groupe qui a les droits sur La vue de validation, et non le role_postgresql ';

ALTER TABLE validation_personne ADD CONSTRAINT validation_personne_id_personne_fkey
FOREIGN KEY (id_personne)
REFERENCES personne (id_personne)
ON DELETE CASCADE;



-- Fonction trigger qui lance la modification sur la table validation_observation
-- lorsque l'utilisateur modifie une vue filtrée sur la vue matérialisée
CREATE OR REPLACE FUNCTION occtax.update_observation_validation() RETURNS TRIGGER AS $$
    BEGIN
        -- On empêche le DELETE et INSERT (même si déjà géré par les droits d'accès)
        IF (TG_OP = 'DELETE') THEN
            RAISE EXCEPTION 'Il est interdit de supprimer des éléments';
            RETURN NULL;
        ELSIF (TG_OP = 'INSERT') THEN
            RAISE EXCEPTION 'Il est interdit d''insérer des éléments';
            RETURN NULL;
        ELSIF (TG_OP = 'UPDATE') THEN

            -- On test si il y a déjà une validation ou pas
            IF OLD.id_validation IS NULL THEN

                -- INSERT
                WITH p AS (
                    SELECT "procedure", proc_vers, proc_ref
                    FROM occtax.validation_procedure, regexp_split_to_array(trim(proc_vers),  '\.')  AS a
                    ORDER BY concat(lpad(a[1], 3, '0'), lpad(a[2], 3, '0'), lpad(a[3], 3, '0')) DESC
                    LIMIT 1
                )
                INSERT INTO occtax.validation_observation
                (
                    identifiant_permanent,
                    date_ctrl,
                    niv_val,
                    typ_val,
                    ech_val,
                    peri_val,
                    validateur,
                    producteur,
                    date_contact,
                    "procedure",
                    proc_vers,
                    proc_ref,
                    comm_val
                )
                SELECT
                    NEW.identifiant_permanent,
                    now()::date,
                    NEW.niv_val,
                    'M', -- insert donc la validation est manuelle
                    '2', -- ech_val
                    '1', -- peri_val : toujours minimal,

                    -- on va cherche le id_personne du validateur
                    (
                        SELECT id_personne
                        FROM occtax.validation_personne
                        WHERE role_postgresql = CURRENT_USER
                    ),

                    NEW.producteur,
                    NEW.date_contact,

                    -- On utilise les valeurs de la table procedure
                    p."procedure",
                    p.proc_vers,
                    p.proc_ref,

                    NEW.comm_val
                FROM p
                ;

            ELSE

                -- UPDATE
                UPDATE occtax.validation_observation vo
                SET (
                    date_ctrl,
                    niv_val,
                    typ_val,
                    ech_val,
                    peri_val,
                    validateur,
                    producteur,
                    date_contact,
                    "procedure",
                    proc_vers,
                    proc_ref,
                    comm_val
                ) = (
                    now()::date,
                    NEW.niv_val,
                    -- typ_val
                    CASE
                        WHEN OLD.typ_val IN ('A', 'C') THEN 'C'
                        ELSE 'M'
                    END,
                    '2', -- ech_val
                    '1', -- peri_val : toujours minimal,

                    -- on va cherche le id_personne du validateur
                    (
                        SELECT id_personne
                        FROM occtax.validation_personne
                        WHERE role_postgresql = CURRENT_USER
                    ),

                    NEW.producteur,
                    NEW.date_contact,

                    -- On utilise les valeurs de la table procedure
                    p."procedure",
                    p.proc_vers,
                    p.proc_ref,

                    NEW.comm_val
                )
                FROM (
                    SELECT "procedure", proc_vers, proc_ref
                    FROM occtax.validation_procedure, regexp_split_to_array(trim(proc_vers),  '\.')  AS a
                    ORDER BY concat(lpad(a[1], 3, '0'), lpad(a[2], 3, '0'), lpad(a[3], 3, '0')) DESC
                    LIMIT 1
                ) AS p
                WHERE TRUE
                AND vo.id_validation = NEW.id_validation
                AND vo.identifiant_permanent = NEW.identifiant_permanent
                ;
            END IF;

        RETURN NEW;

        END IF;
    END;
$$ LANGUAGE plpgsql;



-- Fonction trigger qui lance la modification des champs validite_niveau et validite_date_validation
-- lorsque l'utilisateur modifie la table occtax.validation_observation
CREATE OR REPLACE FUNCTION occtax.update_observation_set_validation_fields() RETURNS TRIGGER AS $$
    BEGIN

        IF TG_OP = 'DELETE' THEN
            UPDATE occtax.observation o
            SET
                validite_niveau = '6', -- Non évalué
                validite_date_validation = NULL
            WHERE o.identifiant_permanent = NEW.identifiant_permanent
            ;
            RETURN OLD;
        ELSE
            UPDATE occtax.observation o
            SET
                validite_niveau = CASE WHEN NEW.niv_val IS NOT NULL THEN NEW.niv_val ELSE '6' END,
                validite_date_validation = NEW.date_ctrl
            WHERE o.identifiant_permanent = NEW.identifiant_permanent
            ;
            RETURN NEW;
        END IF;
    END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS trg_validation_renseigner_champs_observation ON occtax.validation_observation;
CREATE TRIGGER trg_validation_renseigner_champs_observation
AFTER INSERT OR UPDATE OR DELETE ON occtax.validation_observation
FOR EACH ROW EXECUTE PROCEDURE occtax.update_observation_set_validation_fields();


COMMIT;
