BEGIN;

--
-- Extension validation
--

DROP FUNCTION IF EXISTS occtax.occtax_update_sensibilite_observations( text,  TEXT,  TEXT,  text[],  TEXT[],  BIGINT[]);

-- table validation_observation
DROP TABLE IF EXISTS occtax.validation_observation CASCADE;
CREATE TABLE occtax.validation_observation (
    id_validation serial,
    id_sinp_occtax text,
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
    nom_retenu text,
    CONSTRAINT validation_observation_niv_val_ok CHECK (niv_val IN ( '1', '2', '3', '4', '5', '6' ) ),
    CONSTRAINT validation_observation_typ_val_ok CHECK (typ_val IN ( 'A', 'C', 'M') ),
    CONSTRAINT validation_observation_peri_val_ok CHECK (peri_val IN ( '1', '2' ) ),
    CONSTRAINT validation_observation_ech_val_ok CHECK (ech_val IN ( '1', '2', '3') )
);
ALTER TABLE occtax.validation_observation ADD PRIMARY KEY (id_validation);
-- Contrainte d''unicité sur le couple id_sinp_occtax, ech_val : une seule validation nationale, régionale ou producteur (donc au max 3)
ALTER TABLE occtax.validation_observation ADD CONSTRAINT validation_observation_id_sinp_occtax_ech_val_unique UNIQUE (id_sinp_occtax, ech_val);

-- PAS DE CONTRAINTE de clés étrangère sur la table observation, car on veut pouvoir supprimer des observations,
-- mais conserver les données dans occtax.validation_observation (l'identifiant permanent sera valide)
-- ALTER TABLE occtax.validation_observation ADD CONSTRAINT validation_observation_id_sinp_occtax_fk FOREIGN KEY (id_sinp_occtax)
-- REFERENCES occtax.observation (id_sinp_occtax)
-- ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE occtax.validation_observation ADD CONSTRAINT validation_observation_validateur_fkey
FOREIGN KEY (validateur)
REFERENCES occtax.personne (id_personne)
ON UPDATE RESTRICT ON DELETE RESTRICT;

COMMENT ON TABLE occtax.validation_observation IS 'Décrit les opérations de validation scientifique et le niveau de validation attribué à la donnée d''occurrence. Les contrôles de validation scientifique ont été effectués au niveau régional ou national. Il n''est possible de transmettre que 2 résultats de contrôle de validation au maximum via ce concept : l''un national, l''autre régional.';
COMMENT ON COLUMN occtax.validation_observation.date_ctrl IS 'Date de réalisation du contrôle de validation. Format AAAA-MM-JJ.';
COMMENT ON COLUMN occtax.validation_observation.niv_val IS 'Niveau de validité attribué à la donnée à la suite de son contrôle. Le niveau de validité et le libellé associé peuvent se trouver dans les nomenclatures NivValAutoValue et NivValManCom suivant qu''on a procédé à une validation automatique ou à une validation manuelle ou combinée.';
COMMENT ON COLUMN occtax.validation_observation.typ_val IS 'Type de validation effectué. Les valeurs permises sont décrites dans la nomenclature TypeValValue, et peuvent avoir été mises à jour : voir le site des standards de données, http://standards-sinp.mnhn.fr';
COMMENT ON COLUMN occtax.validation_observation.ech_val IS 'Echelle de validation de la donnée : producteur, régionale ou nationale. Indique quelle plateforme a réalisé les opérations de validation scientifique. Les valeurs possibles sont définies par la nomenclature EchelleValidationValue, susceptible d''évoluer au fil du temps.';
COMMENT ON COLUMN occtax.validation_observation.peri_val IS 'Périmètre de validation de la donnée. Il est défini par les valeurs de la nomenclature PerimetreValidationValue.';
COMMENT ON COLUMN occtax.validation_observation.validateur IS 'Validateur (personne et organisme ayant procédé à la validation, éventuellement mail). Voir PersonneType dans le standard occurrences de taxons pour savoir comment le remplir.';
COMMENT ON COLUMN occtax.validation_observation.producteur IS 'Personne recontactée par l''expert chez le producteur lorsque l''expert a eu besoin d''informations complémentaires de la part du producteur. Ensemble d''attributs de "PersonneType" (voir standard occurrences de taxons), identité, organisme, éventuellement mail, à remplir dès lors qu''un contact avec le producteyr a eu lieu.';
COMMENT ON COLUMN occtax.validation_observation.date_contact IS 'Date de contact avec le producteur par l''expert lors de la validation. Doit être rempli si une personne a été recontactée.';
COMMENT ON COLUMN occtax.validation_observation.procedure IS 'Procédure utilisée pour la validation de la donnée. Description succincte des opérations réalisées. Si l''on dispose déjà d''une référence qu''on a indiquée dans procRef, pour des raisons de volume de données, il n''est pas nécessire de remplir cet attribut.';
COMMENT ON COLUMN occtax.validation_observation.proc_vers IS 'Version de la procédure utilisée.';
COMMENT ON COLUMN occtax.validation_observation.proc_ref IS 'Référence permettant de retrouver la procédure : URL, référence biblio, texte libre. Exemple : https://inpn.mnhn.fr/docs-web/docs/download/146208';
COMMENT ON COLUMN occtax.validation_observation.comm_val IS 'Commentaire sur la validation.';
COMMENT ON COLUMN occtax.validation_observation.nom_retenu IS 'Nom scientifique du taxon attribué par le validateur, dans le cas où ce taxon est différent du taxon cité initialement par l''observateur (sinon le champ reste NULL). Cela peut arriver en cas d''identification erronnée par l''observateur, ou bien lorsque le validateur valide l''observation au niveau d''un parent taxonomique. Le champ n''a toutefois pas vocation à stocker un nom qui serait synonyme de celui cité par l''observateur, Taxref permettant déjà de traiter les cas de synonymie.' ;


CREATE OR REPLACE VIEW occtax.v_validateurs AS
WITH personne_avec_organisme AS (
    SELECT
        CASE
            WHEN p.anonymiser IS TRUE THEN 'ANONYME'::text
            ELSE p.identite
        END AS identite,
        CASE
            WHEN p.anonymiser IS TRUE THEN ''::text
            ELSE p.mail
        END AS mail,
        CASE
            WHEN p.anonymiser IS TRUE OR lower(p.identite) = lower(o.nom_organisme) THEN NULL::text
            ELSE COALESCE(o.nom_organisme, 'INCONNU'::text)
        END AS organisme,
        p.id_personne,
        p.prenom,
        p.nom,
        p.anonymiser,
        p.identite AS identite_non_floutee,
        p.mail AS mail_non_floute,
        COALESCE(o.nom_organisme, 'INCONNU'::text) AS organisme_non_floute
    FROM occtax.personne p
    LEFT JOIN occtax.organisme o ON p.id_organisme = o.id_organisme
)

SELECT
    vv.*,
    p.identite,
    p.mail,
    p.organisme,
    p.id_personne,
    p.prenom,
    p.nom,
    p.anonymiser,
    p.identite_non_floutee,
    p.mail_non_floute,
    p.organisme_non_floute
FROM occtax.validation_observation AS vv
INNER JOIN personne_avec_organisme AS p
    ON vv.validateur = p.id_personne
;
COMMENT ON VIEW occtax.v_validateurs
IS 'Renvoie les validateurs pour les observations avec les informations sur la personne et sur la validation effectuée
il peut y avoir plusieurs lignes par observation pour prendre en compte les différentes échelles de validation (ech_val)';


CREATE OR REPLACE VIEW occtax.v_determinateur AS
SELECT CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE p.identite END AS identite,
CASE WHEN p.anonymiser IS TRUE THEN '' ELSE p.mail END AS mail,
CASE WHEN p.anonymiser IS TRUE OR lower(p.identite) = lower(nom_organisme) THEN NULL ELSE Coalesce(nom_organisme, 'INCONNU') END AS organisme,
op.id_personne, op.cle_obs, p.prenom, p.nom, p.anonymiser,
p.identite AS identite_non_floutee,
p.mail AS mail_non_floute,
Coalesce(nom_organisme, 'INCONNU') AS organisme_non_floute
FROM occtax.observation_personne op
INNER JOIN occtax.personne p ON p.id_personne = op.id_personne AND op.role_personne = 'Det'
INNER JOIN occtax.organisme o ON o.id_organisme = p.id_organisme
;



-- Tables et fonctions de gestion de validation et sensibilite automatique
--

-- table critere_validation
DROP TABLE IF EXISTS occtax.critere_validation CASCADE;
CREATE TABLE occtax.critere_validation (
    id_critere serial,
    cd_nom bigint[] NOT NULL,
    libelle text NOT NULL,
    description text,
    condition text NOT NULL,
    table_jointure text,
    niveau text NOT NULL,
    CONSTRAINT critere_validation_niveau_valide CHECK ( niveau IN ( '1', '2', '3', '4', '5', '6' ) )

);
ALTER TABLE occtax.critere_validation ADD PRIMARY KEY (id_critere);

COMMENT ON TABLE occtax.critere_validation IS 'Liste les critères qui permettent de calculer un niveau de validation sur chacune des observations, via l''utilisation de conditions SQL, pour un taxon ou un ensemble de taxons.';

COMMENT ON COLUMN occtax.critere_validation.id_critere IS 'Identifiant unique';
COMMENT ON COLUMN occtax.critere_validation.cd_nom IS 'Tableau de cd_nom pour lesquels attribuer le niveau en fonction de la condition';
COMMENT ON COLUMN occtax.critere_validation.libelle IS 'Libellé court de la condition';
COMMENT ON COLUMN occtax.critere_validation.description IS 'Description de la motivation de cette condition et des choix effectués';
COMMENT ON COLUMN occtax.critere_validation.condition IS 'Condition au format SQL s''appliquant sur les champs de la table observation. Une sous-requête peut être effectuée vers d''autres tables. Ex: "altitude_max" > 500 AND altitude_max < 1500';
COMMENT ON COLUMN occtax.critere_validation.table_jointure IS 'Nom de la table utilisée pour une condition de jointure. On peut par exemple l''utiliser pour une intersection spatiale. Par exemple les tampons à 100m autour des rivières. Pour des soucis de performance, il faut faire une jointure et non une condition simple. Cette table doit être stockée dans le schéma sig';
COMMENT ON COLUMN occtax.critere_validation.niveau IS 'Niveau de validation à appliquer pour la condition. Doit correspondre à la nomenclature.';


-- table critere_sensibilite
DROP TABLE IF EXISTS occtax.critere_sensibilite CASCADE;
CREATE TABLE occtax.critere_sensibilite (
    id_critere serial,
    cd_nom bigint[] NOT NULL,
    libelle text NOT NULL,
    description text,
    condition text NOT NULL,
    table_jointure text,
    niveau text NOT NULL,
    CONSTRAINT critere_sensibilite_niveau_valide CHECK ( niveau IN ( 'm01', 'm02', '0', '1', '2', '3', '4' ) )

);
ALTER TABLE occtax.critere_sensibilite ADD PRIMARY KEY (id_critere);

COMMENT ON TABLE occtax.critere_sensibilite IS 'Liste les critères qui permettent de calculer un niveau de sensibilité sur chacune des observations, via l''utilisation de conditions SQL, pour un taxon ou un ensemble de taxons.';

COMMENT ON COLUMN occtax.critere_sensibilite.id_critere IS 'Identifiant unique';
COMMENT ON COLUMN occtax.critere_sensibilite.cd_nom IS 'Tableau de cd_nom pour lesquels attribuer le niveau en fonction de la condition';
COMMENT ON COLUMN occtax.critere_sensibilite.libelle IS 'Libellé court de la condition';
COMMENT ON COLUMN occtax.critere_sensibilite.description IS 'Description de la motivation de cette condition et des choix effectués';
COMMENT ON COLUMN occtax.critere_sensibilite.condition IS 'Condition au format SQL s''appliquant sur les champs de la table observation. Une sous-requête peut être effectuée vers d''autres tables. Ex: "altitude_max" > 500 AND altitude_max < 1500';
COMMENT ON COLUMN occtax.critere_sensibilite.table_jointure IS 'Nom de la table utilisée pour une condition de jointure. On peut par exemple l''utiliser pour une intersection spatiale. Par exemple les tampons à 100m autour des rivières. Pour des soucis de performance, il faut faire une jointure et non une condition simple. Cette table doit être stockée dans le schéma sig';
COMMENT ON COLUMN occtax.critere_sensibilite.niveau IS 'Niveau de sensibilité à appliquer pour la condition. Doit correspondre à la nomenclature. Liste des niveaux : ''m01'', ''m02'', ''0'', ''1'', ''2'', ''3'', ''4'' ';


CREATE OR REPLACE VIEW occtax.v_critere_validation_et_sensibilite AS
    SELECT *, 'sensibilite' AS contexte FROM occtax.critere_sensibilite
    UNION ALL
    SELECT *, 'validation' AS contexte FROM occtax.critere_validation
;



-- validation_procedure
CREATE TABLE occtax.validation_procedure (
    id serial NOT NULL PRIMARY KEY,
    proc_ref text,
    "procedure" text,
    proc_vers text
);
COMMENT ON TABLE occtax.validation_procedure IS 'Procédures de validation.';

COMMENT ON COLUMN occtax.validation_procedure.id IS 'Id unique de la procédure (entier auto)';
COMMENT ON COLUMN occtax.validation_procedure.proc_ref IS 'Référence permettant de retrouver la procédure : URL, référence biblio, texte libre';
COMMENT ON COLUMN occtax.validation_procedure.procedure IS 'Procédure utilisée pour la validation de la donnée. Description succincte des opérations réalisées.';
COMMENT ON COLUMN occtax.validation_procedure.proc_vers IS 'Version de la procédure utilisée.';
ALTER TABLE occtax.validation_procedure ADD CONSTRAINT validation_procedure_unique UNIQUE (proc_ref, "procedure", proc_vers);

ALTER TABLE occtax.validation_procedure ADD CONSTRAINT proc_vers_valide CHECK ( proc_vers ~ '^\d{1,2}\.\d{1,2}\.\d{1,2}$' );

-- sensibilite_referentiel
DROP TABLE IF EXISTS occtax.sensibilite_referentiel;
CREATE TABLE occtax.sensibilite_referentiel (
    id serial NOT NULL PRIMARY KEY,
    sensi_referentiel text,
    sensi_version_referentiel text,
    description text
);
COMMENT ON TABLE occtax.sensibilite_referentiel IS 'Référentiel de sensibilité.';

COMMENT ON COLUMN occtax.sensibilite_referentiel.id IS 'Id unique du référentiel de sensibilité (entier auto)';
COMMENT ON COLUMN occtax.sensibilite_referentiel.sensi_referentiel IS 'Référence permettant de retrouver la procédure : URL, référence biblio, texte libre';
COMMENT ON COLUMN occtax.sensibilite_referentiel.sensi_version_referentiel IS 'Version du référentiel de sensibilité. Doit être du type *.*.* Par ex: 1.0.0';
COMMENT ON COLUMN occtax.sensibilite_referentiel.description IS 'Description du référentiel.';
ALTER TABLE occtax.sensibilite_referentiel ADD CONSTRAINT sensibilite_referentiel_unique UNIQUE (sensi_referentiel, sensi_version_referentiel);

ALTER TABLE occtax.sensibilite_referentiel ADD CONSTRAINT sensi_version_referentiel_valide CHECK ( sensi_version_referentiel ~ '^\d{1,2}\.\d{1,2}\.\d{1,2}$' );


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
        json_note := '{"4": 1, "3": 2, "2": 3, "1": 4, "m02": 5, "m01": 6, "0": 7 }'; -- sensibilite
    ELSE
        -- validation: invalide > douteux > non évalué > non réalisable > probable > certain
        json_note := '{"4": 1, "3": 2, "6": 3, "5": 4, "2": 5, "1": 6 }';
    END IF;

    -- Table pour stocker les niveaux calculés
    -- (plusieurs lignes possibles par id_sinp_occtax si condition remplie pour plusieurs critères)
    DROP TABLE IF EXISTS occtax.niveau_par_observation;
    CREATE TABLE occtax.niveau_par_observation (
        id_critere integer NOT NULL,
        id_sinp_occtax text NOT NULL,
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
        (id_critere, id_sinp_occtax, niveau, contexte, note)
        SELECT
            %s AS id_critere,
            o.id_sinp_occtax,
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
        AND o.cd_nom = ANY (''%s''::BIGINT[])
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
    SELECT DISTINCT ON (id_sinp_occtax) niveau, id_sinp_occtax, id_critere, contexte
    FROM occtax.niveau_par_observation
    WHERE contexte = p_contexte
    ORDER BY id_sinp_occtax, note;

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
    FROM occtax.validation_procedure, regexp_split_to_array(trim(proc_vers),  '\.')  AS a
    ORDER BY concat(lpad(a[1], 3, '0'), lpad(a[2], 3, '0'), lpad(a[3], 3, '0')) DESC
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
            id_sinp_occtax,
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
            t.id_sinp_occtax,
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
        AND t.id_sinp_occtax = id_sinp_occtax
        -- on écarte les données d absence qui ne peuvent être validées automatiquement
        AND t.id_sinp_occtax NOT IN (
            SELECT id_sinp_occtax
            FROM occtax.observation
            WHERE statut_observation = ''No''
        )
        ON CONFLICT ON CONSTRAINT validation_observation_id_sinp_occtax_ech_val_unique
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
            EXCLUDED.comm_val,
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

    -- On supprime les lignes dans validation_observation pour ech_val = '2' et id_sinp_occtax NOT IN
    -- qui ne correspondent pas au critère et qui ne sont pas manuelles
    -- on a bien ajouté le WHERE AND vo.typ_val NOT IN (''M'', ''C'')
    -- pour ne surtout pas supprimer les validations manuelles ou combinées via notre outil auto
    if p_simulation IS NOT TRUE THEN
        sql_template := '
        DELETE FROM occtax.validation_observation vo
        WHERE TRUE
        AND ech_val = ''2''
        AND vo.typ_val NOT IN (''M'', ''C'')
        AND id_sinp_occtax NOT IN (
            SELECT id_sinp_occtax
            FROM occtax.niveau_par_observation_final AS t
            WHERE contexte = ''validation''
        )
        ';
        sql_text := format(sql_template);
        -- on doit ajouter le filtre jdd_id si non NULL
        IF p_jdd_id IS NOT NULL THEN
            sql_template :=  '
            AND id_sinp_occtax IN (
                SELECT id_sinp_occtax
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
        AND t.id_sinp_occtax = o.id_sinp_occtax
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
        AND o.id_sinp_occtax NOT IN(
            SELECT id_sinp_occtax
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



-- nomenclature
-- validation
DELETE FROM occtax.nomenclature WHERE champ = 'niv_val_auto';
INSERT INTO occtax.nomenclature VALUES ('niv_val_auto', '1', 'Certain - très probable', 'La donnée présente un haut niveau de vraisemblance (très majoritairement cohérente) selon le protocole automatique appliquée. Le résultat de la procédure correspond à la définition optimale de satisfaction de l’ensemble des critères du protocole automatique, par exemple, lorsque la localité correspond à la distribution déjà connue et que les autres paramètres écologiques (date de visibilité, altitude, etc.) sont dans la gamme habituelle de valeur.', 1);
INSERT INTO occtax.nomenclature VALUES ('niv_val_auto', '2', 'Probable', 'La donnée est cohérente et plausible selon le protocole automatique appliqué mais ne satisfait pas complétement (intégralement) l’ensemble des critères automatiques appliqués. La donnée présente une forte probabilité d’être juste. Elle ne présente aucune discordance majeure sur les critères jugés les plus importants mais elle satisfait seulement à un niveau intermédiaire, ou un ou plusieurs des critères automatiques appliqués.', 2);
INSERT INTO occtax.nomenclature VALUES ('niv_val_auto', '3', 'Douteux', 'La donnée concorde peu selon le protocole automatique appliqué. La donnée est peu cohérente ou incongrue. Elle ne satisfait pas ou peu un ou plusieurs des critères automatiques appliqués. Elle ne présente cependant pas de discordance majeure sur les critères jugés les plus importants qui permettraient d’attribuer le plus faible niveau de validité (invalide).', 3);
INSERT INTO occtax.nomenclature VALUES ('niv_val_auto', '4', 'Invalide', 'La donnée ne concorde pas selon la procédure automatique appliquée. Elle présente au moins une discordance majeure sur un des critères jugés les plus importants ou la majorité des critères déterminants sont discordants. Elle est considérée comme trop improbable (aberrante notamment au regard de l’aire de répartition connue, des paramètres biotiques et abiotiques de la niche écologique du taxon). Elle est considérée comme invalide.', 4);
INSERT INTO occtax.nomenclature VALUES ('niv_val_auto', '5', 'Non réalisable', 'La donnée a été soumise à l’ensemble du processus de validation mais l’opérateur (humain ou machine) n’a pas pu statuer sur le niveau de fiabilité, notamment à cause des points suivants : état des connaissances du taxon insuffisantes, ou informations insuffisantes sur l’observation.', 5);
INSERT INTO occtax.nomenclature VALUES ('niv_val_auto', '6', 'Non évalué', 'Non évalué : c''est un ajout au standard, qui permet de savoir quand la donnée n''a pas encore été évaluée', 6);
DELETE FROM occtax.nomenclature WHERE champ = 'niv_val_mancom';
INSERT INTO occtax.nomenclature VALUES ('niv_val_mancom', '1', 'Certain - très probable', 'Certain - très probable : La donnée est exacte. Il n’y a pas de doute notable et significatif quant à l’exactitude de l’observation ou de la détermination du taxon. La validation a été réalisée notamment à partir d’une preuve de l’observation qui confirme la détermination du producteur ou après vérification auprès de l’observateur et/ou du déterminateur.', 1);
INSERT INTO occtax.nomenclature VALUES ('niv_val_mancom', '2', 'Probable', 'Probable : La donnée présente un bon niveau de fiabilité. Elle est vraisemblable et crédible. Il n’y a, a priori, aucune raison de douter de l’exactitude de la donnée mais il n’y a pas d’éléments complémentaires suffisants disponibles ou évalués (notamment la présence d’une preuve ou la possibilité de revenir à la donnée source) permettant d’attribuer un plus haut niveau de certitude.', 2);
INSERT INTO occtax.nomenclature VALUES ('niv_val_mancom', '3', 'Douteux', 'Douteux : La donnée est peu vraisemblable ou surprenante mais on ne dispose pas d’éléments suffisants pour attester d’une erreur manifeste. La donnée est considérée comme douteuse.', 3);
INSERT INTO occtax.nomenclature VALUES ('niv_val_mancom', '4', 'Invalide', 'Invalide : La donnée a été infirmée (erreur manifeste/avérée) ou présente un trop bas niveau de fiabilité. Elle est considérée comme trop improbable (aberrante notamment au regard de l’aire de répartition connue, des paramètres biotiques et abiotiques de la niche écologique du taxon, la preuve révèle une erreur de détermination). Elle est considérée comme invalide.', 4);
INSERT INTO occtax.nomenclature VALUES ('niv_val_mancom', '5', 'Non réalisable', 'Non réalisable : La donnée a été soumise à l’ensemble du processus de validation mais l’opérateur (humain ou machine) n’a pas pu statuer sur le niveau de fiabilité, notamment à cause des points suivants : état des connaissances du taxon insuffisantes, ou informations insuffisantes sur l’observation.', 5);
INSERT INTO occtax.nomenclature VALUES ('niv_val_mancom', '6', 'Non évalué', 'Non évalué : c''est un ajout au standard, qui permet de savoir quand la donnée n''a pas encore été évaluée', 6);
DELETE FROM occtax.nomenclature WHERE champ = 'criticite';
INSERT INTO occtax.nomenclature VALUES ('criticite', '1', 'Mineure', 'Mineure : La modification n''est pas de nature à modifier le niveau de validité de la donnée.', 1);
INSERT INTO occtax.nomenclature VALUES ('criticite', '2', 'Majeure', 'Majeure : La modification est de nature à modifier le niveau de validité de la donnée.', 2);
DELETE FROM occtax.nomenclature WHERE champ = 'typ_val';
INSERT INTO occtax.nomenclature VALUES ('typ_val', 'A', 'Automatique', 'Automatique : Résulte d''une validation automatique', 1);
INSERT INTO occtax.nomenclature VALUES ('typ_val', 'C', 'Combinée', 'Combinée : Résulte de la combinaison d''une validation automatique et d''une validation manuelle', 2);
INSERT INTO occtax.nomenclature VALUES ('typ_val', 'M', 'Manuelle', 'Manuelle : Résulte d''une validation manuelle (intervention d''un expert)', 3);
DELETE FROM occtax.nomenclature WHERE champ = 'peri_val';
INSERT INTO occtax.nomenclature VALUES ('peri_val', '1', 'Périmètre minimal', 'Périmètre minimal : Validation effectuée sur la base des attributs minimaux, à savoir le lieu, la date, et le taxon.', 1);
INSERT INTO occtax.nomenclature VALUES ('peri_val', '2', 'Périmètre maximal', 'Périmètre élargi : validation scientifique sur la base des attributs minimaux, lieu, date, taxon, incluant également des  vérifications sur d''autres attributs, précisés dans la procédure de validation associé.', 2);
DELETE FROM occtax.nomenclature WHERE champ = 'ech_val';
INSERT INTO occtax.nomenclature VALUES ('ech_val', '1', 'Validation producteur', 'Validation scientifique des données par le producteur', 1);
INSERT INTO occtax.nomenclature VALUES ('ech_val', '2', 'Validation régionale', 'Validation scientifique effectuée par la plateforme régionale', 2);
INSERT INTO occtax.nomenclature VALUES ('ech_val', '3', 'Validation nationale', 'Validation scientifique effectuée par la plateforme nationale', 3);


CREATE TABLE occtax.validation_personne (
    id_personne integer NOT NULL,
    role_postgresql text NOT NULL,
    role_postgresql_groupe text
);
ALTER TABLE occtax.validation_personne ADD PRIMARY KEY (id_personne, role_postgresql);
COMMENT ON TABLE occtax.validation_personne IS 'Stockage du lien entre personnes (id_personne) et roles postgresql';
COMMENT ON COLUMN occtax.validation_personne.id_personne IS 'Identifiant de la personne (lien avec occtax.personne)';
COMMENT ON COLUMN occtax.validation_personne.role_postgresql IS 'Role PostgreSQL de connexion, en lien avec cette personne. Par exemple john_doe_acme';
COMMENT ON COLUMN occtax.validation_personne.role_postgresql_groupe IS 'Role PostgreSQL jouant le rôle de groupe pour le role_postgresql. C''est ce role role_postgresql_groupe qui a les droits sur La vue de validation, et non le role_postgresql ';

-- on ne permet pas la suppression des personnes de la table personne qui sont encore référencées par validation_personne
ALTER TABLE occtax.validation_personne ADD CONSTRAINT validation_personne_id_personne_fkey
FOREIGN KEY (id_personne)
REFERENCES occtax.personne (id_personne)
ON UPDATE CASCADE ON DELETE RESTRICT;



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
                    id_sinp_occtax,
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
                    NEW.id_sinp_occtax,
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
                AND vo.id_sinp_occtax = NEW.id_sinp_occtax
                ;
            END IF;

        RETURN NEW;

        END IF;
    END;
$$ LANGUAGE plpgsql;




-- panier de validation
CREATE TABLE occtax.validation_panier (
    id serial NOT NULL PRIMARY KEY,
    usr_login character varying NOT NULL,
    id_sinp_occtax text NOT NULL
);

ALTER TABLE occtax.validation_panier ADD CONSTRAINT validation_panier_usr_login_id_sinp_occtax_key UNIQUE (usr_login, id_sinp_occtax);

COMMENT ON TABLE occtax.validation_panier IS 'Panier d''observations retenues pour appliquer des actions en masse. Par exemple pour la validation scientifique manuelle.';
COMMENT ON COLUMN occtax.validation_panier.id IS 'Identifiant auto-incrémenté unique, clé primaire.';
COMMENT ON COLUMN occtax.validation_panier.usr_login IS 'Login de l''utilisateur qui fait la validation en ligne.';
COMMENT ON COLUMN occtax.validation_panier.id_sinp_occtax IS 'Identifiant permanent de l''observation mise dans le panier.';

-- Vue pour récupérer seulement la validation au niveau régional pour les observations
CREATE OR REPLACE VIEW occtax.v_validation_regionale AS
SELECT
id_sinp_occtax,
niv_val AS niv_val_regionale, date_ctrl AS date_ctrl_regionale
FROM occtax.validation_observation
WHERE ech_val = '2'
;
COMMENT ON VIEW occtax.v_validation_regionale
IS 'Vue qui récupère les lignes de la validation régionale depuis occtax.validation_observation (pour l''échelle 2 donc).
Elle est utilisée dans l''application pour les requêtes réalisées en tant que validateur (sinon on utilise les champs de vm_observation).';



COMMIT;
