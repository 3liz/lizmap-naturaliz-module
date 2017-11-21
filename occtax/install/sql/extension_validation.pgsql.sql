BEGIN;



--
-- Extension validation
--
SET search_path TO occtax,public;

DROP FUNCTION IF EXISTS occtax.occtax_update_sensibilite_observations( text,  TEXT,  TEXT,  text[],  TEXT[],  BIGINT[]);

-- table validation_observation
CREATE TABLE validation_observation (
    id_validation serial,
    cle_obs bigint,
    date_ctrl date NOT NULL,
    niv_val text NOT NULL,
    typ_val text NOT NULL,
    ech_val text NOT NULL,
    peri_val text NOT NULL,
    validateur integer NOT NULL,
    proc_vers text NOT NULL,
    producteur integer,
    date_contact date,
    procedure text,
    proc_ref text,
    commm_val text
);
ALTER TABLE validation_observation ADD PRIMARY KEY (id_validation);
-- Contrainte d'unicité sur le couple cle_obs, ech_val : une seule validation nationale, régionale ou producteur (donc au max 3)
ALTER TABLE validation_observation ADD CONSTRAINT validation_observation_cle_obs_ech_val_unique UNIQUE (cle_obs, ech_val);

ALTER TABLE validation_observation ADD CONSTRAINT validation_observation_cle_obs_fk FOREIGN KEY (cle_obs)
REFERENCES observation (cle_obs)
ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE validation_observation ADD CONSTRAINT validation_observation_validateur_fkey
FOREIGN KEY (validateur)
REFERENCES personne (id_personne)
ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE validation_observation ADD CONSTRAINT validation_observation_producteur_fkey
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

COMMENT ON COLUMN validation_observation.commm_val IS 'Commentaire sur la validation.';


-- Tables et fonctions de gestion de validation et sensibilite automatique
--

-- table critere_validation
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
CREATE TABLE critere_sensibilite (
    id_critere serial,
    cd_nom bigint[] NOT NULL,
    libelle text NOT NULL,
    description text,
    condition text NOT NULL,
    table_jointure text,
    niveau text NOT NULL,
    CONSTRAINT critere_sensibilite_niveau_valide CHECK ( niveau IN ( '0', '1', '2', '3', '4' ) )

);
ALTER TABLE critere_sensibilite ADD PRIMARY KEY (id_critere);

COMMENT ON TABLE critere_sensibilite IS 'Liste les critères qui permettent de calculer un niveau de sensibilité sur chacune des observations, via l''utilisation de conditions SQL, pour un taxon ou un ensemble de taxons.';

COMMENT ON COLUMN critere_sensibilite.id_critere IS 'Identifiant unique';
COMMENT ON COLUMN critere_sensibilite.cd_nom IS 'Tableau de cd_nom pour lesquels attribuer le niveau en fonction de la condition';
COMMENT ON COLUMN critere_sensibilite.libelle IS 'Libellé court de la condition';
COMMENT ON COLUMN critere_sensibilite.description IS 'Description de la motivation de cette condition et des choix effectués';
COMMENT ON COLUMN critere_sensibilite.condition IS 'Condition au format SQL s''appliquant sur les champs de la table observation. Une sous-requête peut être effectuée vers d''autres tables. Ex: "altitude_max" > 500 AND altitude_max < 1500';
COMMENT ON COLUMN critere_sensibilite.table_jointure IS 'Nom de la table utilisée pour une condition de jointure. On peut par exemple l''utiliser pour une intersection spatiale. Par exemple les tampons à 100m autour des rivières. Pour des soucis de performance, il faut faire une jointure et non une condition simple. Cette table doit être stockée dans le schéma sig';
COMMENT ON COLUMN critere_sensibilite.niveau IS 'Niveau de sensibilité à appliquer pour la condition. Doit correspondre à la nomenclature.';


CREATE OR REPLACE VIEW occtax.v_critere_validation_et_sensibilite AS
    SELECT *, 'sensibilite' AS contexte FROM occtax.critere_sensibilite
    UNION ALL
    SELECT *, 'validation' AS contexte FROM occtax.critere_validation
;


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
    -- (lorsqu'une observation a plusieurs notes données par plusieurs conditions)
    IF p_contexte = 'sensibilite' THEN
        json_note := '{"0": 6, "m02": 5, "1": 4, "2": 3, "3": 2, "4": 1}'; -- sensibilite
    ELSE
        json_note := '{"1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 0}'; -- validation
    END IF;

    -- Table pour stocker les niveaux calculés
    -- (plusieurs lignes possibles par cle_obs si condition remplie pour plusieurs critères)
    DROP TABLE IF EXISTS occtax.niveau_par_observation;
    CREATE TABLE occtax.niveau_par_observation (
        id_critere integer NOT NULL,
        cle_obs bigint NOT NULL,
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
        (id_critere, cle_obs, niveau, contexte, note)
        SELECT
            %s,
            o.cle_obs,
            ''%s'' AS niveau,
            ''%s'' AS contexte,
            (''%s''::json->>''%s'')::integer

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
            AND o.jdd_id jdd_id = ANY ( ''%s''::TEXT[] )
            ';
            sql_text := sql_text || format(sql_template, p_jdd_id);
        END IF;

        -- Log SQL
        RAISE NOTICE '%' , sql_text;

        -- On insère les données dans occtax.niveau_observation
        EXECUTE sql_text;

    END LOOP;

    -- Récupération d'une seule ligne par observation
    -- La note permet de dire qui gagne via le DISTINCT ON et le ORDER BY
    DROP TABLE IF EXISTS occtax.niveau_par_observation_final;
    CREATE TABLE occtax.niveau_par_observation_final AS
    SELECT DISTINCT ON (cle_obs) niveau, cle_obs, id_critere, contexte
    FROM occtax.niveau_par_observation
    WHERE contexte = p_contexte
    ORDER BY cle_obs, note;

    RETURN 1;

END
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

-- calcul validation
CREATE OR REPLACE FUNCTION occtax.calcul_niveau_validation(
    p_jdd_id TEXT[],
    p_ech_val TEXT,
    p_validateur integer,
    p_proc_vers TEXT,
    p_simulation boolean
)
RETURNS INTEGER AS
$BODY$
DECLARE sql_template TEXT;
DECLARE sql_text TEXT;
DECLARE useless INTEGER;
BEGIN

    -- Remplissage de la table avec les valeurs issues des conditions
    SELECT occtax.calcul_niveau_par_condition(
        'validation',
        p_jdd_id
    ) INTO useless;

    -- Suppression des anciennes valeurs ???

    -- UPDATE des observations
    if p_simulation IS NOT TRUE THEN
        sql_template := '
        INSERT INTO occtax.validation_observation AS vo
        (
            cle_obs,
            date_ctrl,
            niv_val,
            typ_val,
            ech_val,
            peri_val,
            validateur,
            proc_vers
        )
        SELECT
            t.cle_obs,
            now(),
            t.niveau,
            ''A'',  -- automatique
            $1, -- ech_val
            ''2'', -- perimetre maximal
            $2, -- validateur
            $3 -- proc_vers
        FROM occtax.niveau_par_observation_final AS t
        WHERE True
        AND t.contexte = ''validation''
        AND t.cle_obs = cle_obs
        ON CONFLICT ON CONSTRAINT validation_observation_cle_obs_ech_val_unique
        DO UPDATE
        SET (
            date_ctrl,
            niv_val,
            typ_val,
            ech_val,
            peri_val,
            validateur,
            proc_vers
        ) =
        (
            now(),
            EXCLUDED.niv_val,
            ''A'',  --automatique
            $1, -- ech_val
            ''2'', -- perimetre maximal
            $2, -- validateur
            $3 -- proc_vers
        )
        WHERE TRUE
        AND vo.typ_val NOT IN (''M'', ''C'')
        ';
        EXECUTE format(sql_template)
        USING p_ech_val, p_validateur, p_proc_vers;
    END IF;

    RETURN 1;

END
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


-- calcul sensibilite
CREATE OR REPLACE FUNCTION occtax.calcul_niveau_sensibilite(
    p_jdd_id TEXT[],
    p_simulation boolean,
    p_sensi_referentiel TEXT,
    p_sensi_version_referentiel TEXT
)
RETURNS INTEGER AS
$BODY$
DECLARE sql_template TEXT;
DECLARE sql_text TEXT;
DECLARE useless INTEGER;
BEGIN

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
            sensi_date_attribution, sensi_niveau, sensi_referentiel, sensi_version_referentiel
        )
        = (
            now(), niveau, ''%s'', ''%s''
        )
        FROM occtax.niveau_par_observation_final AS t
        WHERE True
        AND contexte = ''sensibilite''
        AND t.cle_obs = o.cle_obs
        ';
        sql_text := format(sql_template, p_sensi_referentiel, p_sensi_version_referentiel);

        RAISE NOTICE '%' , sql_text;
        EXECUTE sql_text;
    END IF;

    RETURN 1;

END
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;



-- nomenclature
-- validation
INSERT INTO nomenclature VALUES ('niv_val_auto', '1', 'Certain - très probable', 'La donnée présente un haut niveau de vraisemblance (très majoritairement cohérente) selon le protocole automatique appliquée. Le résultat de la procédure correspond à la définition optimale de satisfaction de l’ensemble des critères du protocole automatique, par exemple, lorsque la localité correspond à la distribution déjà connue et que les autres paramètres écologiques (date de visibilité, altitude, etc.) sont dans la gamme habituelle de valeur.');
INSERT INTO nomenclature VALUES ('niv_val_auto', '2', 'Probable', 'La donnée est cohérente et plausible selon le protocole automatique appliqué mais ne satisfait pas complétement (intégralement) l’ensemble des critères automatiques appliqués. La donnée présente une forte probabilité d’être juste. Elle ne présente aucune discordance majeure sur les critères jugés les plus importants mais elle satisfait seulement à un niveau intermédiaire, ou un ou plusieurs des critères automatiques appliqués.');
INSERT INTO nomenclature VALUES ('niv_val_auto', '3', 'Douteux', 'La donnée concorde peu selon le protocole automatique appliqué. La donnée est peu cohérente ou incongrue. Elle ne satisfait pas ou peu un ou plusieurs des critères automatiques appliqués. Elle ne présente cependant pas de discordance majeure sur les critères jugés les plus importants qui permettraient d’attribuer le plus faible niveau de validité (invalide).');
INSERT INTO nomenclature VALUES ('niv_val_auto', '4', 'Invalide', 'La donnée ne concorde pas selon la procédure automatique appliquée. Elle présente au moins une discordance majeure sur un des critères jugés les plus importants ou la majorité des critères déterminants sont discordants. Elle est considérée comme trop improbable (aberrante notamment au regard de l’aire de répartition connue, des paramètres biotiques et abiotiques de la niche écologique du taxon). Elle est considérée comme invalide.');
INSERT INTO nomenclature VALUES ('niv_val_auto', '5', 'Non réalisable', 'La donnée a été soumise à l’ensemble du processus de validation mais l’opérateur (humain ou machine) n’a pas pu statuer sur le niveau de fiabilité, notamment à cause des points suivants : état des connaissances du taxon insuffisantes, ou informations insuffisantes sur l’observation.');

INSERT INTO nomenclature VALUES ('niv_val_mancom', '1', 'Certain - très probable', 'Certain - très probable : La donnée est exacte. Il n’y a pas de doute notable et significatif quant à l’exactitude de l’observation ou de la détermination du taxon. La validation a été réalisée notamment à partir d’une preuve de l’observation qui confirme la détermination du producteur ou après vérification auprès de l’observateur et/ou du déterminateur.');
INSERT INTO nomenclature VALUES ('niv_val_mancom', '2', 'Probable', 'Probable : La donnée présente un bon niveau de fiabilité. Elle est vraisemblable et crédible. Il n’y a, a priori, aucune raison de douter de l’exactitude de la donnée mais il n’y a pas d’éléments complémentaires suffisants disponibles ou évalués (notamment la présence d’une preuve ou la possibilité de revenir à la donnée source) permettant d’attribuer un plus haut niveau de certitude.');
INSERT INTO nomenclature VALUES ('niv_val_mancom', '3', 'Douteux', 'Douteux : La donnée est peu vraisemblable ou surprenante mais on ne dispose pas d’éléments suffisants pour attester d’une erreur manifeste. La donnée est considérée comme douteuse.');
INSERT INTO nomenclature VALUES ('niv_val_mancom', '4', 'Invalide', 'Invalide : La donnée a été infirmée (erreur manifeste/avérée) ou présente un trop bas niveau de fiabilité. Elle est considérée comme trop improbable (aberrante notamment au regard de l’aire de répartition connue, des paramètres biotiques et abiotiques de la niche écologique du taxon, la preuve révèle une erreur de détermination). Elle est considérée comme invalide.');
INSERT INTO nomenclature VALUES ('niv_val_mancom', '5', 'Non réalisable', 'Non réalisable : La donnée a été soumise à l’ensemble du processus de validation mais l’opérateur (humain ou machine) n’a pas pu statuer sur le niveau de fiabilité, notamment à cause des points suivants : état des connaissances du taxon insuffisantes, ou informations insuffisantes sur l’observation.');

INSERT INTO nomenclature VALUES ('criticite', '1', 'Mineure', 'Mineure : La modification n''est pas de nature à modifier le niveau de validité de la donnée.');
INSERT INTO nomenclature VALUES ('criticite', '2', 'Majeure', 'Majeure : La modification est de nature à modifier le niveau de validité de la donnée.');

INSERT INTO nomenclature VALUES ('typ_val', 'A', 'Automatique', 'Automatique : Résulte d''une validation automatique');
INSERT INTO nomenclature VALUES ('typ_val', 'C', 'Combinée', 'Combinée : Résulte de la combinaison d''une validation automatique et d''une validation manuelle');
INSERT INTO nomenclature VALUES ('typ_val', 'M', 'Manuelle', 'Manuelle : Résulte d''une validation manuelle (intervention d''un expert)');

INSERT INTO nomenclature VALUES ('peri_val', '1', 'Périmètre minimal', 'Périmètre minimal : Validation effectuée sur la base des attributs minimaux, à savoir le lieu, la date, et le taxon.');
INSERT INTO nomenclature VALUES ('peri_val', '2', 'Périmètre maximal', 'Périmètre élargi : validation scientifique sur la base des attributs minimaux, lieu, date, taxon, incluant également des  vérifications sur d''autres attributs, précisés dans la procédure de validation associé.');

INSERT INTO nomenclature VALUES ('ech_val', '1', 'Validation producteur', 'Validation scientifique des données par le producteur');
INSERT INTO nomenclature VALUES ('ech_val', '2', 'Validation régionale', 'Validation scientifique effectuée par la plateforme régionale');
INSERT INTO nomenclature VALUES ('ech_val', '3', 'Validation nationale', 'Validation scientifique effectuée par la plateforme nationale');


COMMIT;
