--
-- AJOUT D'ATTRIBUTS
--

-- sig.departement
-- RAS le champ nom_departement existe déjà

-- occtax.observation
-- descriptif_sujet : ajout occ_comportement
-- on le place devant occ_statut_biologique pour permettre
-- bascule entre les deux
-- valeur 1 = non renseigné pour occ_comportement
UPDATE occtax.observation
SET descriptif_sujet =
(replace(
    descriptif_sujet::text,
    '"occ_statut_biologique"',
    '"occ_comportement": "1", "occ_statut_biologique"'
))::jsonb
WHERE descriptif_sujet IS NOT NULL
AND descriptif_sujet::text NOT LIKE '%occ_comportement%'
;

-- occtax.observation : ajout nom_lieu
ALTER TABLE occtax.observation
ADD COLUMN IF NOT EXISTS nom_lieu text
;
COMMENT ON COLUMN occtax.observation.nom_lieu
IS 'Nom du lieu ou de la station où a été effectuée l''observation. ATTENTION : cet attribut ne pourra pas être flouté !';

-- MODIFICATION D'ATTRIBUTS
--
-- renommer preuve_numerique en url_preuve_numerique
UPDATE occtax.observation
SET descriptif_sujet =
(replace(descriptif_sujet::text, '"preuve_numerique"', '"url_preuve_numerique"'))::jsonb
WHERE descriptif_sujet IS NOT NULL
;

-- renommer obs_methode en obs_technique
UPDATE occtax.observation
SET descriptif_sujet =
(replace(descriptif_sujet::text, '"obs_methode"', '"obs_technique"'))::jsonb
WHERE descriptif_sujet IS NOT NULL
;

-- occ_statut_biologique : certaines valeurs vont vers occ_comportement
-- 6 : Halte migratoire
UPDATE occtax.observation
SET descriptif_sujet =
(replace(
    descriptif_sujet::text,
    '"occ_comportement": "1", "occ_statut_biologique": "6"',
    '"occ_comportement": "6", "occ_statut_biologique": "1"'
))::jsonb
WHERE descriptif_sujet IS NOT NULL
AND descriptif_sujet::text LIKE '%"occ_statut_biologique": "6"%'
;
-- 7 : Swarming
UPDATE occtax.observation
SET descriptif_sujet =
(replace(
    descriptif_sujet::text,
    '"occ_comportement": "1", "occ_statut_biologique": "7"',
    '"occ_comportement": "7", "occ_statut_biologique": "1"'
))::jsonb
WHERE descriptif_sujet IS NOT NULL
AND descriptif_sujet::text LIKE '%"occ_statut_biologique": "7"%'
;
-- 8 : Chasse / alimentation
UPDATE occtax.observation
SET descriptif_sujet =
(replace(
    descriptif_sujet::text,
    '"occ_comportement": "1", "occ_statut_biologique": "8"',
    '"occ_comportement": "8", "occ_statut_biologique": "1"'
))::jsonb
WHERE descriptif_sujet IS NOT NULL
AND descriptif_sujet::text LIKE '%"occ_statut_biologique": "8"%'
;
-- 10 : Passage en vol
UPDATE occtax.observation
SET descriptif_sujet =
(replace(
    descriptif_sujet::text,
    '"occ_comportement": "1", "occ_statut_biologique": "10"',
    '"occ_comportement": "10", "occ_statut_biologique": "1"'
))::jsonb
WHERE descriptif_sujet IS NOT NULL
AND descriptif_sujet::text LIKE '%"occ_statut_biologique": "10"%'
;
-- 11 : Erratique
UPDATE occtax.observation
SET descriptif_sujet =
(replace(
    descriptif_sujet::text,
    '"occ_comportement": "1", "occ_statut_biologique": "11"',
    '"occ_comportement": "11", "occ_statut_biologique": "1"'
))::jsonb
WHERE descriptif_sujet IS NOT NULL
AND descriptif_sujet::text LIKE '%"occ_statut_biologique": "11"%'
;
-- 12 : Sédentaire
UPDATE occtax.observation
SET descriptif_sujet =
(replace(
    descriptif_sujet::text,
    '"occ_comportement": "1", "occ_statut_biologique": "12"',
    '"occ_comportement": "12", "occ_statut_biologique": "1"'
))::jsonb
WHERE descriptif_sujet IS NOT NULL
AND descriptif_sujet::text LIKE '%"occ_statut_biologique": "12"%'
;

-- occtax.observation
-- denombrement_min et denombrement_max deviennent facultatifs
-- RAS déjà fait dans des versions précédentes

-- habitat
-- version_ref prend un numéro de version et plus une valeur textuelle
-- pas encore implémenté -> ne pas faire pour l'instant

-- maille 10
-- le code maille doit être le CD_SIG des fichiers SHP de l'INPN
-- RAS déjà le cas

-- jdd_metadonnee_dee_id devient id_sinp_jdd
ALTER TABLE occtax.observation RENAME COLUMN jdd_metadonnee_dee_id TO id_sinp_jdd;

-- identifiant_origine devient id_origine
ALTER TABLE occtax.observation RENAME COLUMN identifiant_origine TO id_origine;

-- dee_floutage : commentaire changé
COMMENT ON COLUMN occtax.observation.dee_floutage
IS 'Indique si un floutage a été effectué avant (par le producteur) ou lors de la transformation en DEE. Cela ne concerne que des données d''origine privée.';

-- identifiant_permanent devient id_sinp_occtax
ALTER TABLE occtax.observation RENAME COLUMN identifiant_permanent TO id_sinp_occtax;

-- date_debut et date_fin perdent l'heure
-- RAS déjà des dates

-- table jdd et les autres
ALTER TABLE occtax.jdd RENAME COLUMN jdd_metadonnee_dee_id TO id_sinp_jdd;
ALTER TABLE occtax.lien_observation_identifiant_permanent RENAME COLUMN identifiant_origine TO id_origine;
ALTER TABLE occtax.lien_observation_identifiant_permanent RENAME COLUMN identifiant_permanent TO id_sinp_occtax;
DROP INDEX IF EXISTS occtax."lien_observation_identifiant_per_jdd_id_identifiant_origine_idx";
CREATE INDEX ON occtax.lien_observation_identifiant_permanent (jdd_id, id_origine);

ALTER TABLE occtax.lien_observation_identifiant_permanent
    DROP CONSTRAINT IF EXISTS lien_observation_identifiant__jdd_id_identifiant_origine_id_key
;
ALTER TABLE occtax.lien_observation_identifiant_permanent
ADD CONSTRAINT lien_observation_id_sinp_occtax_jdd_id_id_origine_id_key UNIQUE (jdd_id, id_origine, id_sinp_occtax)
;

--
-- SUPPRESSION D'ATTRIBUTS
--

-- jdd_source_id
ALTER TABLE occtax.observation DROP COLUMN IF EXISTS jdd_source_id CASCADE;

-- sensible
ALTER TABLE occtax.observation DROP COLUMN IF EXISTS sensible CASCADE;

-- validateur
-- RAS déjà fait

-- organisme_standard
ALTER TABLE occtax.observation DROP COLUMN IF EXISTS organisme_standard CASCADE;

-- cd_ref et version taxref !

-- NOMENCLATURE
--
INSERT INTO occtax.nomenclature
(champ, code, valeur, description)
VALUES
('dee_floutage', 'NSP', 'Ne sait pas', $$On ignore si un floutage a eu lieu$$),

('obs_technique', '26', 'Contact olfactif', $$Contact olfactif : l'occurrence a été sentie sur le lieu d'observation$$),
('obs_technique', '27', 'Empreinte et fèces', $$Empreinte et fèces$$),

('occ_comportement', '0', 'Inconnu', $$Inconnu: le statut biologique de l'individu n'est pas connu$$),
('occ_comportement', '1', 'Non renseigné', $$Non renseigné: le statut biologique de l'individu n'a pas été renseigné$$),
('occ_comportement', '2', 'Echouage', $$Echouage: l'individu tente de s'échouer ou vient de s'échouer sur le rivage$$),
('occ_comportement', '3', 'Dortoir', $$Dortoir: individus se regroupant dans une zone définie pour y passer la nuit ou la journée$$),
('occ_comportement', '4', 'Migration', $$Migration: l'individu (ou groupe d'individus) est en migration active$$),
('occ_comportement', '5', 'Toile', $$Construction de toile: l'individu construit sa toile$$),
('occ_comportement', '6', 'Halte migratoire', $$Halte migratoire: indique que l'individu procède à une halte au cours de sa migration, et a été découvert sur sa zone de halte$$),
('occ_comportement', '7', 'Swarming', $$Swarming: Indique que l'individu a un comportement de swarming : il se regroupe avec d'autres individus de taille similaire$$),
('occ_comportement', '8', 'Chasse / alimentation', $$Chasse / alimentation: Indique que l'individu est sur une zone qui lui permet de chasser ou de s'alimenter$$),
('occ_comportement', '9', 'Hivernage', $$Hivernage: l'individu hiverne (modification de son comportement liée à l'hiver pouvant par exemple comporter un
changement de lieu, d'alimentation, de production de sève ou de graisse...)$$),
('occ_comportement', '10', 'Passage en vol', $$Passage en vol : Indique que l'individu est de passage et en vol.$$),
('occ_comportement', '11', 'Erratique', $$Erratique : Individu d'une ou de populations d'un taxon qui ne se trouve, actuellement, que de manière occasionnelle dans les
limites d’une région. Il a été retenu comme seuil, une absence de 80% d'un laps de temps donné (année, saisons...)$$),
('occ_comportement', '12', 'Sédentaire', $$Sédentaire : Individu demeurant à un seul emplacement, ou restant toute l'année dans sa région d'origine, même s'il effectue
des déplacements locaux$$),
('occ_comportement', '13', 'Estivage', $$Estivage : l'individu estive (modification de son comportement liée à l'été pouvant par exemple comporter un changement de
lieu, d'alimentation, de production de sève ou de graisse...)$$),
('occ_comportement', '14', 'Nourrissage jeunes', $$Nourrissage des jeune$$),
('occ_comportement', '15', 'Posé', $$Posé : Individu(s) posé(s)$$),
('occ_comportement', '16', 'Déplacement', $$Déplacement : Individu(s) en déplacement$$),
('occ_comportement', '17', 'Repos', $$Repos$$),
('occ_comportement', '18', 'Chant', $$Chant$$),
('occ_comportement', '19', 'Accouplement', $$Accouplement$$),
('occ_comportement', '20', 'Coeur copulatoire', $$Coeur copulatoire$$),
('occ_comportement', '21', 'Tandem', $$Tandem$$),
('occ_comportement', '22', 'Territorial', $$Territorial$$),
('occ_comportement', '23', 'Pond', $$Pond$$),

('occ_stade_de_vie', '27', 'Fruit', $$Fruit : L'individu est sous forme de fruit$$),

('occ_statut_biologique', '13', 'Végétatif', $$L'individu est au stade végétatif$$),

('type_aa', 'NSP', 'Ne sait pas', 'Le type du paramètre est inconnu'),

('typ_val', 'NSP', 'Ne sait pas', 'Le type de validation effectué n''est pas connu')

ON CONFLICT ON CONSTRAINT nomenclature_pkey DO NOTHING
;


-- renommage de obs_methode en obs_technique
UPDATE occtax.nomenclature SET champ = 'obs_technique' WHERE champ = 'obs_methode';

-- modification
UPDATE occtax.nomenclature
SET description = 'Indique qu''un floutage a eu lieu. Floutage effectué par le producteur avant envoi vers le SINP (une plateforme du SINP).'
WHERE champ = 'dee_floutage' AND code = 'OUI'
;
UPDATE occtax.nomenclature
SET description = 'Indique qu''aucun floutage n''a eu lieu. Donnée non floutée, fournie précise par le producteur.'
WHERE champ = 'dee_floutage' AND code = 'NON'
;
UPDATE occtax.nomenclature
SET description = 'Observation indirecte : Galerie forée dans le bois, les racines ou les tiges, par des larves (Lépidoptères, Coléoptères, Diptères) ou creusée dans la terre (micro-mammifères, mammifères... ).'
WHERE champ = 'obs_technique' AND code = '23'
;



--------------------
-- extension_validation.sql
--------------------
ALTER TABLE occtax.validation_observation RENAME COLUMN identifiant_permanent TO id_sinp_occtax;
ALTER TABLE occtax.validation_observation DROP CONSTRAINT IF EXISTS validation_observation_identifiant_permanent_ech_val_unique;
ALTER TABLE occtax.validation_observation ADD CONSTRAINT validation_observation_id_sinp_occtax_ech_val_unique UNIQUE (id_sinp_occtax, ech_val);

DROP VIEW IF EXISTS occtax.v_validateurs CASCADE;
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

         -- optionally add JOIN table
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


ALTER TABLE occtax.validation_panier RENAME COLUMN identifiant_permanent TO id_sinp_occtax;
ALTER TABLE occtax.validation_panier DROP CONSTRAINT IF EXISTS validation_panier_usr_login_identifiant_permanent_key;
ALTER TABLE occtax.validation_panier ADD CONSTRAINT validation_panier_usr_login_id_sinp_occtax_key UNIQUE (usr_login, id_sinp_occtax);

DROP VIEW IF EXISTS occtax.v_validation_regionale;
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

-----------------------
-- vm_observation
------------------------
DROP VIEW IF EXISTS occtax.v_vm_observation CASCADE;
CREATE OR REPLACE VIEW occtax.v_vm_observation AS
WITH
agg_m01 AS (
    SELECT
        cle_obs, jsonb_agg(code_maille) AS code_maille, min(code_maille) AS code_maille_unique
    FROM occtax.localisation_maille_01
    GROUP BY cle_obs
),
agg_m02 AS (
    SELECT
        cle_obs, jsonb_agg(code_maille) AS code_maille, min(code_maille) AS code_maille_unique
    FROM occtax.localisation_maille_02
    GROUP BY cle_obs
),
agg_m10 AS (
    SELECT
        cle_obs, jsonb_agg(code_maille) AS code_maille, min(code_maille) AS code_maille_unique
    FROM occtax.localisation_maille_10
    GROUP BY cle_obs
),
agg_com AS (
    SELECT
        cle_obs, jsonb_agg(code_commune) AS code_commune, min(code_commune) AS code_commune_unique
    FROM occtax.localisation_commune
    GROUP BY cle_obs
),
agg_dep AS (
    SELECT
        cle_obs, jsonb_agg(code_departement) AS code_departement
    FROM occtax.localisation_departement
    GROUP BY cle_obs
),
agg_me AS (
    SELECT
        cle_obs, jsonb_agg(code_me) AS code_me
    FROM occtax.localisation_masse_eau
    GROUP BY cle_obs
),
agg_en AS (
    SELECT
        cle_obs,
        jsonb_agg(code_en ORDER BY code_en) AS code_en,
        jsonb_agg(type_en ORDER BY code_en) AS type_en
    FROM occtax.v_localisation_espace_naturel
    GROUP BY cle_obs
),

agg_observateur AS (
    SELECT
        cle_obs,
        string_agg( concat(
            identite,
            CASE
                WHEN organisme IS NULL OR organisme = '' THEN ''
                ELSE ' (' || organisme|| ')'
            END
        ), ', ' ORDER BY identite) AS identite_observateur,
        string_agg( concat(
            identite_non_floutee,
            CASE
                WHEN organisme_non_floute IS NULL OR organisme_non_floute = '' THEN ''
                ELSE ' (' || organisme_non_floute|| ')'
            END,
            ' - ' || mail_non_floute
        ), ', ' ORDER BY identite) AS identite_observateur_non_floute
    FROM occtax."v_observateur"
    GROUP BY cle_obs
),

-- déterminateur
agg_determinateur AS (
    SELECT
        cle_obs,
        string_agg( concat(
            identite,
            CASE
                WHEN organisme IS NULL OR organisme = '' THEN ''
                ELSE ' (' || organisme|| ')'
            END
        ), ', ' ORDER BY identite) AS determinateur,
        string_agg( concat(
            identite_non_floutee,
            CASE
                WHEN organisme_non_floute IS NULL OR organisme_non_floute = '' THEN ''
                ELSE ' (' || organisme_non_floute|| ')'
            END,
            ' - ' || mail_non_floute
        ), ', ' ORDER BY identite) AS determinateur_non_floute
    FROM occtax."v_determinateur"
    GROUP BY cle_obs
),


-- validation
validation_producteur AS (
    SELECT
        id_sinp_occtax,
        Coalesce(niv_val, '6') AS niv_val,
        date_ctrl AS date_ctrl,
        concat(
            identite,
            CASE
                WHEN organisme IS NULL OR organisme = '' THEN ''
                ELSE ' (' || organisme|| ')'
            END
        ) AS validateur
    FROM occtax.v_validateurs
    WHERE ech_val = '1'
),
validation_regionale AS (
    SELECT
        id_sinp_occtax,
        Coalesce(niv_val, '6') AS niv_val,
        date_ctrl AS date_ctrl,
        concat(
            identite,
            CASE
                WHEN organisme IS NULL OR organisme = '' THEN ''
                ELSE ' (' || organisme|| ')'
            END
        ) AS validateur
    FROM occtax.v_validateurs
    WHERE ech_val = '2'
),
validation_nationale AS (
    SELECT
        id_sinp_occtax,
        Coalesce(niv_val, '6') AS niv_val,
        date_ctrl AS date_ctrl,
        concat(
            identite,
            CASE
                WHEN organisme IS NULL OR organisme = '' THEN ''
                ELSE ' (' || organisme|| ')'
            END
        ) AS validateur
    FROM occtax.v_validateurs
    WHERE ech_val = '3'
)

SELECT
o.cle_obs,
o.id_sinp_occtax,
o.statut_observation,
o.cd_nom,
o.cd_ref,
o.version_taxref,
o.nom_cite,
t.nom_valide, t.reu AS loc, trim(t.nom_vern) AS nom_vern, t.group1_inpn, t.group2_inpn, t.ordre, t.famille, t.protection, tv.url,
Coalesce( tgc1.libelle_court, tgc2.libelle_court, 'Autres' ) AS categorie,
trim(tv.lb_nom, ' ,\t') AS lb_nom_valide, trim(tv.nom_vern, ' ,\t') AS nom_vern_valide,
t.menace_nationale, t.menace_regionale, t.menace_monde,
t.rang, t.habitat, t.statut, t.endemicite, t.invasibilite,
o.denombrement_min,
o.denombrement_max,
o.objet_denombrement,
o.type_denombrement,
o.commentaire,
o.date_debut,
o.heure_debut,
o.date_fin,
o.heure_fin,
o.date_determination,
o.altitude_min,
o.altitude_moy,
o.altitude_max,
o.profondeur_min,
o.profondeur_moy,
o.profondeur_max,
o.code_idcnp_dispositif,
o.dee_date_derniere_modification,
o.dee_date_transformation,
o.dee_floutage,
o.diffusion_niveau_precision,
o.ds_publique,
o.id_origine,
o.jdd_code,
o.jdd_id,
o.id_sinp_jdd,
o.organisme_gestionnaire_donnees,
o.org_transformation,
o.statut_source,
o.reference_biblio,
o.sensi_date_attribution,
o.sensi_niveau,
o.sensi_referentiel,
o.sensi_version_referentiel,
o.descriptif_sujet AS descriptif_sujet,

-- validations producteur, régionale et nationale
jsonb_build_object(
    'niv_val', val_p.niv_val,
    'date_ctrl', val_p.date_ctrl,
    'validateur', val_p.validateur
) AS validation_producteur,
jsonb_build_object(
    'niv_val', val_r.niv_val,
    'date_ctrl', val_r.date_ctrl,
    'validateur', val_r.validateur
) AS validation_regionale,
jsonb_build_object(
    'niv_val', val_n.niv_val,
    'date_ctrl', val_n.date_ctrl,
    'validateur', val_n.validateur
) AS validation_nationale,
-- ajout de niv_val pour les 3 échelles
-- en cas de filtres WHERE (demande, grand public, etc.)
val_p.niv_val AS niv_val_producteur,
val_r.niv_val AS niv_val_regionale,
val_n.niv_val AS niv_val_nationale,

o.precision_geometrie,
o.nature_objet_geo,
o.nom_lieu,
o.geom,
CASE
    WHEN o.geom IS NOT NULL THEN
        CASE
            WHEN GeometryType(geom) IN ('POLYGON', 'MULTIPOLYGON') THEN 'Polygone'
            WHEN GeometryType(geom) IN ('LINESTRING', 'MULTILINESTRING') THEN 'Ligne'
            WHEN GeometryType(geom) IN ('POINT', 'MULTIPOINT') THEN 'Point'
            ELSE 'Géométrie'
        END
    WHEN lm10.code_maille IS NOT NULL THEN 'M10'
    WHEN lc.code_commune IS NOT NULL THEN 'COM'
    WHEN lme.code_me IS NOT NULL THEN 'ME'
    WHEN len.code_en IS NOT NULL THEN 'EN'
    WHEN ld.code_departement IS NOT NULL THEN 'DEP'
    ELSE 'NO'
END AS source_objet,

-- liens spatiaux
lm01.code_maille AS code_maille_01,
lm01.code_maille_unique AS code_maille_01_unique,
lm02.code_maille AS code_maille_02,
lm02.code_maille_unique AS code_maille_02_unique,
lm10.code_maille AS code_maille_10,
lm10.code_maille_unique AS code_maille_10_unique,
lc.code_commune, lc.code_commune_unique,
ld.code_departement,
lme.code_me,
len.code_en, len.type_en,

-- calcul de la diffusion
occtax.calcul_diffusion(o.sensi_niveau, o.ds_publique, o.diffusion_niveau_precision) AS diffusion,

-- observateurs
pobs.identite_observateur, pobs.identite_observateur_non_floute,
-- validateurs
rtrim(concat(
    'Validation producteur: ' || val_p.validateur || ', ',
    'Validation régionale: ' || val_r.validateur || ', ',
    'Validation nationale: ' || val_n.validateur || ', '
), ', ') AS validateur,
-- déterminateurs
pdet.determinateur, pdet.determinateur_non_floute

FROM      occtax."observation"  AS o
INNER JOIN occtax."jdd" ON jdd.jdd_id = o.jdd_id
LEFT JOIN agg_observateur   AS pobs  ON pobs.cle_obs = o.cle_obs
LEFT JOIN validation_producteur AS val_p ON val_p.id_sinp_occtax = o.id_sinp_occtax
LEFT JOIN validation_regionale AS val_r ON val_r.id_sinp_occtax = o.id_sinp_occtax
LEFT JOIN validation_nationale AS val_n ON val_n.id_sinp_occtax = o.id_sinp_occtax
LEFT JOIN agg_determinateur AS pdet  ON pdet.cle_obs = o.cle_obs
LEFT JOIN agg_m01 AS lm01  ON lm01.cle_obs = o.cle_obs
LEFT JOIN agg_m02 AS lm02  ON lm02.cle_obs = o.cle_obs
LEFT JOIN agg_m10 AS lm10  ON lm10.cle_obs = o.cle_obs
LEFT JOIN agg_com AS lc    ON lc.cle_obs = o.cle_obs
LEFT JOIN agg_dep AS ld    ON ld.cle_obs = o.cle_obs
LEFT JOIN agg_me  AS lme   ON lme.cle_obs = o.cle_obs
LEFT JOIN agg_en  AS len   ON len.cle_obs = o.cle_obs

LEFT JOIN taxon."taxref_consolide_non_filtre" AS t ON t.cd_nom = o.cd_nom
LEFT JOIN taxon."taxref_consolide_non_filtre" AS tv ON tv.cd_nom = tv.cd_ref AND tv.cd_nom = t.cd_ref
LEFT JOIN taxon."t_group_categorie" AS tgc1  ON tgc1.groupe_nom = t.group1_inpn AND tgc1.groupe_type = 'group1_inpn'
LEFT JOIN taxon."t_group_categorie" AS tgc2  ON tgc2.groupe_nom = t.group2_inpn AND tgc2.groupe_type = 'group2_inpn'
WHERE TRUE
AND (jdd.date_minimum_de_diffusion IS NULL OR jdd.date_minimum_de_diffusion <= now() )
;

COMMENT ON VIEW occtax.v_vm_observation
IS 'Vue contenant la requête complexe qui est la source de la vue matérialisée vm_observation.
On peut modifier cette vue puis rafraîchir la vue vm_observation si besoin.
Dans le cas où la liste de champs reste inchangée, cela facilite les choses car cela n''oblige pas
à supprimer et recréer vm_observation et ses vues dépendantes (stats)';


-- VUE MATERIALISEE DE CONSOLIDATION DES DONNEES
DROP MATERIALIZED VIEW IF EXISTS occtax.vm_observation CASCADE;
CREATE MATERIALIZED VIEW occtax.vm_observation AS
SELECT *
FROM occtax.v_vm_observation
;

CREATE INDEX vm_observation_cle_obs_idx ON occtax.vm_observation (cle_obs);
CREATE INDEX vm_observation_id_sinp_occtax_idx ON occtax.vm_observation (id_sinp_occtax);
CREATE INDEX vm_observation_geom_idx ON occtax.vm_observation USING GIST (geom);
CREATE INDEX vm_observation_cd_ref_idx ON occtax.vm_observation (cd_ref);
CREATE INDEX vm_observation_cd_nom_idx ON occtax.vm_observation (cd_nom);
CREATE INDEX vm_observation_group1_inpn_idx ON occtax.vm_observation (group1_inpn);
CREATE INDEX vm_observation_group2_inpn_idx ON occtax.vm_observation (group2_inpn);
CREATE INDEX vm_observation_categorie_idx ON occtax.vm_observation (categorie);
CREATE INDEX vm_observation_jdd_id_idx ON occtax.vm_observation (jdd_id);
CREATE INDEX vm_observation_date_debut_date_fin_idx ON occtax.vm_observation USING btree (date_debut, date_fin DESC);
CREATE INDEX vm_observation_descriptif_sujet_idx ON occtax.vm_observation USING GIN (descriptif_sujet);
CREATE INDEX vm_observation_code_commune_idx ON occtax.vm_observation USING GIN (code_commune);
CREATE INDEX vm_observation_code_maille_01_idx ON occtax.vm_observation USING GIN (code_maille_01);
CREATE INDEX vm_observation_code_maille_02_idx ON occtax.vm_observation USING GIN (code_maille_02);
CREATE INDEX vm_observation_code_maille_01_unique_idx ON occtax.vm_observation (code_maille_01_unique);
CREATE INDEX vm_observation_code_maille_02_unique_idx ON occtax.vm_observation (code_maille_02_unique);
CREATE INDEX vm_observation_code_maille_10_unique_idx ON occtax.vm_observation (code_maille_10_unique);
CREATE INDEX vm_observation_diffusion_idx ON occtax.vm_observation USING GIN (diffusion);
CREATE INDEX vm_observation_validation_regionale_idx ON occtax.vm_observation USING GIN (validation_regionale);


-- DÉTAIL : vue occtax.v_vm_observation dépend de vue matérialisée occtax.observation_diffusion
-- vue matérialisée occtax.vm_observation dépend de vue occtax.v_vm_observation
-- vue occtax.vm_stat_nb_observations_par_groupe_taxonomique dépend de vue matérialisée occtax.vm_observation
-- vue occtax.vm_stat_nb_taxons_observes_par_groupe_taxonomique dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.repartition_temporelle dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.repartition_habitats dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.connaissance_par_groupe_taxonomique dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.nombre_taxons dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.repartition_groupe_taxonomique dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.observations_par_maille_02 dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.avancement_imports dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.nombre_obs_par_menace dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.nombre_taxons_par_menace dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.rangs_taxonomiques dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.nombre_taxons_par_statut_biogeographique dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.nombre_obs_par_statut_biogeographique dépend de vue matérialisée occtax.vm_observation
-- vue occtax.v_observation_validation dépend de vue matérialisée occtax.vm_observation
-- vue matérialisée stats.chiffres_cles dépend de vue matérialisée occtax.vm_observation

-- VUES POUR LES STATISTIQUES

-- nb_observations_par_groupe_taxonomique
DROP VIEW IF EXISTS occtax.vm_stat_nb_observations_par_groupe_taxonomique;
CREATE VIEW occtax.vm_stat_nb_observations_par_groupe_taxonomique AS
SELECT
row_number() OVER () AS id, categorie,
Count(o.cle_obs) AS nbobs
FROM occtax.vm_observation o
GROUP BY categorie
ORDER BY categorie
;

-- nb_observations_par_commune
DROP VIEW IF EXISTS occtax.vm_stat_nb_observations_par_commune;
CREATE VIEW occtax.vm_stat_nb_observations_par_commune AS
SELECT
row_number() OVER () AS id, c.nom_commune,
Count(o.cle_obs) AS nbobs
FROM occtax.observation  AS o
INNER JOIN occtax.localisation_commune lc ON lc.cle_obs = o.cle_obs
INNER JOIN sig.commune c ON c.code_commune = lc.code_commune
WHERE True
GROUP BY nom_commune
ORDER BY nom_commune
;

-- nb_taxons_presents
DROP VIEW IF EXISTS occtax.vm_stat_nb_taxons_observes_par_groupe_taxonomique;
CREATE VIEW occtax.vm_stat_nb_taxons_observes_par_groupe_taxonomique AS
SELECT row_number() OVER () AS id, categorie,
Count(DISTINCT o.cd_ref) AS nb_taxon_present
FROM occtax.vm_observation o
GROUP BY categorie
ORDER BY categorie
;

-- nb_observations_par_an
DROP VIEW IF EXISTS occtax.vm_stat_nb_observations_par_an;
CREATE VIEW occtax.vm_stat_nb_observations_par_an AS
SELECT row_number() OVER () AS id,
to_char( date_trunc('year', date_debut) , 'YYYY') AS periode,
Count(cle_obs) AS nbobs
FROM occtax.observation AS o
WHERE True
GROUP BY periode
ORDER BY periode
;

-- STATS
--
CREATE SCHEMA IF NOT EXISTS stats;

-- repartition_altitudinale_observations
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.repartition_altitudinale_observations AS
SELECT serie.altitude,
  count(DISTINCT a.cle_obs) AS nb_obs
FROM (SELECT generate_series(0, 3100, 100) altitude) serie
LEFT JOIN occtax.attribut_additionnel a ON trunc(a.valeur::NUMERIC(10,2),-2)=serie.altitude
WHERE a.nom='altitude_mnt'
GROUP BY serie.altitude
ORDER BY serie.altitude
;

COMMENT ON MATERIALIZED VIEW stats.repartition_altitudinale_observations IS 'Répartition des observations par tranche altitudinale de 100m';

-- repartition_altitudinale_taxons
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.repartition_altitudinale_taxons AS
SELECT serie.altitude,
  count(DISTINCT o.cd_ref) AS nb_taxons
FROM (SELECT generate_series(0, 3100, 100) altitude) serie
LEFT JOIN occtax.attribut_additionnel a ON trunc(a.valeur::NUMERIC(10,2),-2)=serie.altitude
LEFT JOIN occtax.observation o ON o.cle_obs=a.cle_obs
WHERE a.nom='altitude_mnt'
GROUP BY serie.altitude
ORDER BY serie.altitude
;

COMMENT ON MATERIALIZED VIEW stats.repartition_altitudinale_taxons IS 'Répartition des taxons observés par tranche altitudinale de 100m';

-- repartition_temporelle
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.repartition_temporelle AS
WITH stat as (
  SELECT
    EXTRACT(YEAR FROM date_debut)::INTEGER AS annee,
    count(DISTINCT cle_obs) AS nb_donnees
  FROM occtax.vm_observation
  GROUP BY EXTRACT(YEAR FROM date_debut)
  ORDER BY EXTRACT(YEAR FROM date_debut)
)
SELECT
  serie.annee,
  COALESCE(stat.nb_donnees,0) AS nb_donnees
FROM
  (SELECT generate_series(
            (SELECT min(stat.annee) FROM stat),
            (SELECT max(stat.annee) FROM stat)
            ) AS annee
  ) AS serie
LEFT JOIN stat ON stat.annee=serie.annee
ORDER BY serie.annee
;
COMMENT ON MATERIALIZED VIEW stats.repartition_temporelle IS 'Répartition des données par année d''observation';

-- repartition_habitats
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.repartition_habitats AS
SELECT n.code, COALESCE(n.valeur, 'Non renseigné par Taxref') AS habitat,
  count(cle_obs) AS nb_donnees
FROM occtax.vm_observation o
LEFT JOIN taxon.t_nomenclature n ON n.code=o.habitat::TEXT AND n.champ='habitat'
GROUP BY n.code, o.habitat, COALESCE(n.valeur, 'Non renseigné par Taxref')
ORDER BY count(o.cd_ref) DESC
;
COMMENT ON MATERIALIZED VIEW stats.repartition_habitats IS 'Répartition des observations par grand milieu de vie du taxon';

-- connaissance_par_groupe_taxonomique
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.connaissance_par_groupe_taxonomique AS
SELECT CONCAT(
                COALESCE(o.group2_inpn, 'Non renseigné par Taxref'),
                ' (n=',
                stat_taxref.nb_taxons_taxref,
                ')'
            ) AS group2_inpn,
((count(DISTINCT o.cd_ref::NUMERIC)/stat_taxref.nb_taxons_taxref::NUMERIC)*100)::NUMERIC(4,1) AS nb_taxons_observes,
(((stat_taxref.nb_taxons_taxref - count(DISTINCT o.cd_ref))::NUMERIC/stat_taxref.nb_taxons_taxref::NUMERIC)*100)::NUMERIC(4,1) AS manque_taxref,
stat_taxref.nb_taxons_taxref AS total_taxref
FROM occtax.vm_observation o
LEFT JOIN ( SELECT group2_inpn, count(DISTINCT cd_ref) AS nb_taxons_taxref
      FROM taxon.taxref
      -- on ne prend que les espèces et sous-espèces des taxons présents ou ayant été présents à La Réunion
      WHERE {$colonne_locale} IS NOT NULL AND {$colonne_locale} NOT IN ('Q','A') AND rang IN ('ES', 'SSES')
      GROUP BY group2_inpn
      ) stat_taxref ON stat_taxref.group2_inpn=o.group2_inpn
WHERE o.rang IN ('ES', 'SSES')
GROUP BY COALESCE(o.group2_inpn, 'Non renseigné par Taxref'), stat_taxref.nb_taxons_taxref
ORDER BY (count(DISTINCT o.cd_ref)::NUMERIC/stat_taxref.nb_taxons_taxref::NUMERIC)::NUMERIC(3,2) DESC
;
COMMENT ON MATERIALIZED VIEW stats.connaissance_par_groupe_taxonomique IS 'Estimation du degré de connaissance de chaque groupe taxonomique. Pour chaque groupe est calculé le pourcentage d''espèces connues (ie faisant l''objet d''au moins une observation dans Taxref) et le pourcentage d''espèces inconnues (ie indiquées comme présentes dans Taxref mais ne faisant pas encore l''objet d''observation dans Borbonica';

-- nombre_taxons
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.nombre_taxons AS
SELECT COALESCE(o.group2_inpn, 'Non renseigné par Taxref') AS group2_inpn,
  count(DISTINCT cd_ref) AS nb_taxons
FROM occtax.vm_observation o
GROUP BY COALESCE(o.group2_inpn, 'Non renseigné par Taxref')
ORDER BY count(o.cd_ref) DESC
;
COMMENT ON MATERIALIZED VIEW stats.nombre_taxons IS 'Nombre de taxons observés par groupe taxonomique';

-- repartition_groupe_taxonomique
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.repartition_groupe_taxonomique AS
SELECT COALESCE(o.group2_inpn, 'Non renseigné par Taxref') AS group2_inpn,
  count(o.cle_obs) AS nb_donnees
FROM occtax.vm_observation o
GROUP BY COALESCE(o.group2_inpn, 'Non renseigné par Taxref')
ORDER BY count(o.cd_ref) DESC
;
COMMENT ON MATERIALIZED VIEW stats.repartition_groupe_taxonomique IS 'Nombre d''observations par groupe taxonomique';

-- observations_par_maille_02
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.observations_par_maille_02 AS
SELECT
id_maille, code_maille AS mid, nom_maille AS maille,
count(o.cle_obs) AS nbobs,
count(DISTINCT o.cd_ref) AS nbtax,
m.geom
FROM sig.maille_02 m
INNER JOIN occtax.vm_observation o ON m.code_maille = code_maille_02_unique
GROUP BY id_maille, code_maille, nom_maille, m.geom
;
COMMENT ON MATERIALIZED VIEW stats.observations_par_maille_02 IS 'Nombre d''observations et de taxons par mailles de 2km de côté';

-- observations_par_commune
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.observations_par_commune AS
SELECT
row_number() over () AS id,
c.nom_commune,
Count(o.cle_obs) AS nbobs
FROM occtax.observation  AS o
INNER JOIN occtax.localisation_commune lc ON lc.cle_obs = o.cle_obs
INNER JOIN sig.commune c ON c.code_commune = lc.code_commune
WHERE True
GROUP BY nom_commune
ORDER BY nom_commune
;

COMMENT ON MATERIALIZED VIEW stats.observations_par_commune IS 'Nombre d''observations par commune';

-- avancement_imports
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.avancement_imports AS
  WITH r AS (
         SELECT LEFT(serie.date::TEXT, 7) AS mois,
            count(DISTINCT o.jdd_id) AS nb_jdd,
            count(DISTINCT o.cle_obs) AS nb_obs
           FROM (SELECT generate_series(
               (SELECT date_trunc('month'::text, min(vm_observation.dee_date_transformation)) AS min FROM occtax.vm_observation),
               date_trunc('month'::text, now()),
               '1 mon'::interval
        ) AS date) serie
           LEFT JOIN occtax.vm_observation o ON date_trunc('month'::text, serie.date) = date_trunc('month'::text, o.dee_date_transformation)
          GROUP BY LEFT(serie.date::TEXT, 7)
          ORDER BY LEFT(serie.date::TEXT, 7)
        )
 SELECT r.mois,
    sum(r.nb_jdd) OVER (ORDER BY r.mois) AS nb_jdd,
    sum(r.nb_obs) OVER (ORDER BY r.mois) AS nb_obs
   FROM r
;
COMMENT ON MATERIALIZED VIEW stats.avancement_imports IS 'Nombre cumulé de données et de jeux de données importés dans Borbonica au fil du temps, traduisant la dynamique d''import dans Borbonica';

-- validation
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.validation AS
SELECT
    niv_val AS niveau_validite,
    (SELECT valeur FROM occtax.nomenclature WHERE champ='validite_niveau' AND code = niv_val) AS niveau_validite_libelle,
    (SELECT valeur FROM occtax.nomenclature WHERE champ='type_validation' AND code = typ_val) AS type_validite,
    count(DISTINCT v.id_sinp_occtax) AS nb_obs
FROM
    occtax.validation_observation AS v
WHERE v.ech_val = '2'
GROUP BY niv_val, typ_val
ORDER BY niv_val
;

COMMENT ON MATERIALIZED VIEW stats.validation IS 'Nombre de données par niveau de validation';

-- nombre_obs_par_menace
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.nombre_obs_par_menace AS
SELECT COALESCE(n.ordre,0) AS ordre,
  COALESCE(n.code, 'NE') AS code_menace,
  COALESCE(n.valeur, 'Non évaluée') AS menace,
  CASE COALESCE(n.code, 'NE')
    WHEN 'EX' THEN 'C0/M0/J0/N100'
    WHEN 'EW' THEN 'C80/M100/J20/N40'
    WHEN 'RE' THEN 'C70/M100/J10/N25'
    WHEN 'CR' THEN 'C5/M100/J100/N5'
    WHEN 'EN' THEN 'C0/M28/J100/N0'
    WHEN 'VU' THEN 'C0/M0/J98/N0'
    WHEN 'NT' THEN 'C3/M3/J27/N0'
    WHEN 'LC' THEN 'C60/M0/J85/N0'
    WHEN 'DD' THEN 'C0/M0/J0/N23'
    WHEN 'NA' THEN 'C25/M21/J0/N0'
    WHEN 'NE' THEN 'C65/M54/J0/N0'
  END AS couleur_cmjn,
  CASE COALESCE(n.code, 'NE')
    WHEN 'EX' THEN 'R0/V0/B0'
    WHEN 'EW' THEN 'R61/V25/B81'
    WHEN 'RE' THEN 'R90/V26/B99'
    WHEN 'CR' THEN 'R211/V0/B27'
    WHEN 'EN' THEN 'R251/V191/B0'
    WHEN 'VU' THEN 'R255/V237/B0'
    WHEN 'NT' THEN 'R251/V242/B202'
    WHEN 'LC' THEN 'R120/V183/B74'
    WHEN 'DD' THEN 'R211/V212/B213'
    WHEN 'NA' THEN 'R191/V202/B255'
    WHEN 'NE' THEN 'R89/V117/B255'
  END AS couleur_rvb,
  CASE COALESCE(n.code, 'NE')
    WHEN 'EX' THEN 'rgb(0,0,0)'
    WHEN 'EW' THEN 'rgb(61,25,81)'
    WHEN 'RE' THEN 'rgb(90,26,99)'
    WHEN 'CR' THEN 'rgb(211,0,27)'
    WHEN 'EN' THEN 'rgb(251,191,0)'
    WHEN 'VU' THEN 'rgb(255,237,0)'
    WHEN 'NT' THEN 'rgb(251,242,202)'
    WHEN 'LC' THEN 'rgb(120,183,74)'
    WHEN 'DD' THEN 'rgb(211,212,213)'
    WHEN 'NA' THEN 'rgb(191,202,255)'
    WHEN 'NE' THEN 'rgb(89,117,255)'
  END AS couleur_html,
  count(DISTINCT o.cle_obs) AS nb_obs
FROM occtax.vm_observation o
LEFT JOIN taxon.t_nomenclature n ON n.code::TEXT=o.menace_nationale::TEXT AND n.champ='menace'
GROUP BY n.code, n.ordre, COALESCE(n.valeur, 'Non évaluée')
ORDER BY COALESCE(n.ordre,0) DESC
;
COMMENT ON MATERIALIZED VIEW stats.nombre_obs_par_menace IS 'nombre d''observations par niveau de menace UICN de taxon';

-- nombre_taxons_par_menace
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.nombre_taxons_par_menace AS
SELECT
  COALESCE(n.ordre,0) AS ordre,
  COALESCE(n.code, 'NE') AS code_menace,
  COALESCE(n.valeur, 'Non évaluée') AS menace,
  CASE COALESCE(n.code, 'NE')
    WHEN 'EX' THEN 'C0/M0/J0/N100'
    WHEN 'EW' THEN 'C80/M100/J20/N40'
    WHEN 'RE' THEN 'C70/M100/J10/N25'
    WHEN 'CR' THEN 'C5/M100/J100/N5'
    WHEN 'EN' THEN 'C0/M28/J100/N0'
    WHEN 'VU' THEN 'C0/M0/J98/N0'
    WHEN 'NT' THEN 'C3/M3/J27/N0'
    WHEN 'LC' THEN 'C60/M0/J85/N0'
    WHEN 'DD' THEN 'C0/M0/J0/N23'
    WHEN 'NA' THEN 'C25/M21/J0/N0'
    WHEN 'NE' THEN 'C65/M54/J0/N0'
  END AS couleur_cmjn,
  CASE COALESCE(n.code, 'NE')
    WHEN 'EX' THEN 'R0/V0/B0'
    WHEN 'EW' THEN 'R61/V25/B81'
    WHEN 'RE' THEN 'R90/V26/B99'
    WHEN 'CR' THEN 'R211/V0/B27'
    WHEN 'EN' THEN 'R251/V191/B0'
    WHEN 'VU' THEN 'R255/V237/B0'
    WHEN 'NT' THEN 'R251/V242/B202'
    WHEN 'LC' THEN 'R120/V183/B74'
    WHEN 'DD' THEN 'R211/V212/B213'
    WHEN 'NA' THEN 'R191/V202/B255'
    WHEN 'NE' THEN 'R89/V117/B255'
  END AS couleur_rvb,
  CASE COALESCE(n.code, 'NE')
    WHEN 'EX' THEN 'rgb(0,0,0)'
    WHEN 'EW' THEN 'rgb(61,25,81)'
    WHEN 'RE' THEN 'rgb(90,26,99)'
    WHEN 'CR' THEN 'rgb(211,0,27)'
    WHEN 'EN' THEN 'rgb(251,191,0)'
    WHEN 'VU' THEN 'rgb(255,237,0)'
    WHEN 'NT' THEN 'rgb(251,242,202)'
    WHEN 'LC' THEN 'rgb(120,183,74)'
    WHEN 'DD' THEN 'rgb(211,212,213)'
    WHEN 'NA' THEN 'rgb(191,202,255)'
    WHEN 'NE' THEN 'rgb(89,117,255)'
  END AS couleur_html,
  count(DISTINCT o.cd_ref) AS nb_taxons
FROM occtax.vm_observation o
LEFT JOIN taxon.t_nomenclature n ON n.code::TEXT=o.menace_nationale::TEXT AND n.champ='menace'
GROUP BY n.code, n.ordre, COALESCE(n.valeur, 'Non évaluée')
ORDER BY COALESCE(n.ordre,0) DESC
;
COMMENT ON MATERIALIZED VIEW stats.nombre_taxons_par_menace IS 'Nombre de taxons par niveau de menace UICN de taxon';

-- chiffres_cles
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.chiffres_cles AS
  SELECT 1 AS ordre,
    'Nombre total de données' AS libelle,
    count(vm_observation.cle_obs) AS valeur
   FROM occtax.vm_observation
UNION
 SELECT 2 AS ordre,
    'Nombre total de jeux de données' AS libelle,
    count(DISTINCT vm_observation.jdd_code) AS valeur
   FROM occtax.vm_observation
UNION
 SELECT 3 AS ordre,
    'Nombre de producteurs ayant transmis des jeux de données' AS libelle,
    count(DISTINCT r.id_organisme) AS valeur
   FROM ( SELECT jdd.jdd_id,
            jsonb_array_elements(jdd.ayants_droit) ->> 'id_organisme'::text AS id_organisme,
            jsonb_array_elements(jdd.ayants_droit) ->> 'role'::text AS role
           FROM occtax.jdd) r
UNION
 SELECT 4 AS ordre,
    'Nombre d''observateurs cités' AS libelle,
    count(DISTINCT p.nom || p.prenom) AS valeur
   FROM occtax.observation_personne op
     LEFT JOIN occtax.personne p USING (id_personne)
UNION
 SELECT 5 AS ordre,
    'Nombre de taxons faisant l''objet d''observations' AS libelle,
    count(DISTINCT vm_observation.cd_ref) AS valeur
   FROM occtax.vm_observation
UNION
 SELECT 6 AS ordre,
    'Nombre d''adhérents à la charte régionale SINP' AS libelle,
    count(ga.id_adherent) AS valeur
   FROM gestion.adherent ga
  WHERE ga.statut = 'Adhérent'
UNION
 SELECT 7 AS ordre,
    'Nombre de demandes d''accès aux données ouvertes' AS libelle,
    count(gd.id) AS valeur
   FROM gestion.demande gd
  WHERE gd.statut ~~* 'acceptée'
ORDER BY ordre
;
COMMENT ON MATERIALIZED VIEW stats.chiffres_cles IS 'Divers chiffres clés traduisant l''activité du SINP';

-- rangs_taxonomiques
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.rangs_taxonomiques AS
SELECT CASE o.rang
      WHEN 'SSES' THEN 'Sous-espèce'
      WHEN 'ES' THEN 'Espèce'
      WHEN 'GN' THEN 'Genre'
      WHEN 'FM' THEN 'Famille'
      WHEN 'OR' THEN 'Ordre'
      WHEN 'VAR' THEN 'Variété'
      WHEN NULL THEN 'Non renseigné par Taxref'
      ELSE 'Autre'
    END AS rang,
  count(cle_obs) AS nb_donnees
FROM occtax.vm_observation o
GROUP BY CASE o.rang
      WHEN 'SSES' THEN 'Sous-espèce'
      WHEN 'ES' THEN 'Espèce'
      WHEN 'GN' THEN 'Genre'
      WHEN 'FM' THEN 'Famille'
      WHEN 'OR' THEN 'Ordre'
      WHEN 'VAR' THEN 'Variété'
      WHEN NULL THEN 'Non renseigné par Taxref'
      ELSE 'Autre'
    END
ORDER BY count(o.cd_ref) DESC
;
COMMENT ON MATERIALIZED VIEW stats.rangs_taxonomiques IS 'Nombre d''observations par rang du taxon';

-- nombre_taxons_par_statut_biogeographique
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.nombre_taxons_par_statut_biogeographique AS
SELECT concat_ws( ' - ', o.loc, COALESCE(n.valeur, 'Non renseigné par Taxref')) AS loc,
  count(DISTINCT o.cd_ref) AS nb_taxons
FROM occtax.vm_observation o
LEFT JOIN taxon.t_nomenclature n ON n.code::TEXT=o.loc::TEXT AND n.champ='statut_taxref'
GROUP BY concat_ws( ' - ', o.loc, COALESCE(n.valeur, 'Non renseigné par Taxref'))
ORDER BY count(o.cd_ref) DESC
;
COMMENT ON MATERIALIZED VIEW stats.nombre_taxons_par_statut_biogeographique IS 'nombre de taxons par statut biogéographique (selon Taxref)';

-- nombre_obs_par_statut_biogeographique
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.nombre_obs_par_statut_biogeographique AS
SELECT concat_ws( ' - ', o.loc, COALESCE(n.valeur, 'Non renseigné par Taxref')) AS loc,
  count(DISTINCT cle_obs) AS nb_obs
FROM occtax.vm_observation o
LEFT JOIN taxon.t_nomenclature n ON n.code::TEXT=o.loc::TEXT AND n.champ='statut_taxref'
GROUP BY concat_ws( ' - ', o.loc, COALESCE(n.valeur, 'Non renseigné par Taxref'))
ORDER BY count(o.cle_obs) DESC
;
COMMENT ON MATERIALIZED VIEW stats.nombre_obs_par_statut_biogeographique IS 'nombre d''observations par statut biogéographique (selon Taxref)';

-- sensibilite_donnees
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.sensibilite_donnees AS
SELECT n.valeur AS sensi_libelle,
count(cle_obs) AS nb_obs
FROM occtax.observation o
LEFT JOIN (SELECT code, valeur FROM occtax.nomenclature WHERE champ='sensi_niveau') n ON n.code=o.sensi_niveau
GROUP BY sensi_niveau,  n.valeur
ORDER BY sensi_niveau
;

COMMENT ON MATERIALIZED VIEW stats.sensibilite_donnees IS 'Nombre d''observations par niveau de sensibilité des données';

-- types_demandes
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.types_demandes AS
SELECT  n.valeur AS type_demande,
    count(d.id) AS nb_demandes
FROM gestion.demande d
LEFT JOIN gestion.g_nomenclature n ON n.code=d.type_demande AND n.champ='type_demande'
GROUP BY n.valeur
ORDER BY count(d.id) DESC
;

COMMENT ON MATERIALIZED VIEW stats.types_demandes IS 'Nombre de demandes par type';

-- liste_adherents
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.liste_adherents AS
SELECT a.id_adherent, o.nom_organisme, a.statut,  a.date_demande, a.date_adhesion
FROM gestion.adherent a
LEFT JOIN occtax.organisme o USING (id_organisme)
ORDER BY id_adherent
;

COMMENT ON MATERIALIZED VIEW stats.liste_adherents IS 'Liste des adhérents et pré-adhérents à la charte régionale du SINP';

-- liste_jdd
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.liste_jdd AS
WITH groupes AS (
    SELECT jdd_id, COALESCE(group2_inpn, 'Autres') AS group2_inpn, count(cle_obs) AS nb_obs, count(DISTINCT cd_ref) AS nb_taxons
    FROM occtax.observation
    LEFT JOIN taxon.taxref_valide USING (cd_ref)
    GROUP BY jdd_id, group2_inpn
    ORDER BY jdd_id, group2_inpn
    ),

    milieux AS(
    SELECT jdd_id, COALESCE(n.valeur, 'Habitat non connu') AS habitat, count(cle_obs) AS nb_obs
    FROM occtax.observation
    LEFT JOIN taxon.taxref_valide t USING (cd_ref)
    LEFT JOIN taxon.t_nomenclature n ON n.code=t.habitat::TEXT
    WHERE n.champ='habitat'
    GROUP BY jdd_id, n.valeur
    ORDER BY jdd_id, n.valeur
    ),

    r AS(
    SELECT  jdd_id,
            jsonb_array_elements(ayants_droit)->>'id_organisme' AS id_organisme,
            jsonb_array_elements(ayants_droit)->>'role' AS role
    FROM occtax.jdd
    )

SELECT jdd.jdd_code,
    jdd.jdd_description,
    string_agg(DISTINCT
                   COALESCE (o.sigle, o.nom_organisme) || ' (' || r.role || ')', ' - '
                   ORDER BY COALESCE (o.sigle, o.nom_organisme) || ' (' || r.role || ')'
                  ) AS producteurs,
    i.date_reception,
    imin.date_import AS date_premier_import,
    imax.date_import AS date_dernier_import,
    i.nb_donnees_source, i.nb_donnees_import,
    string_agg(DISTINCT groupes.group2_inpn || ' (' || groupes.nb_obs || ' obs, ' || groupes.nb_taxons || ' taxons)', ' | ' ) AS groupes_taxonomiques,
    string_agg(DISTINCT milieux.habitat || ' (' || milieux.nb_obs || ' obs)', ' | ' ) AS habitats_taxons,
    i.date_obs_min,
    i.date_obs_max,
    CONCAT('https://inpn.mnhn.fr/mtd/cadre/export/xml/GetRecordById?id=', jdd.jdd_cadre) AS fiche_md_cadre_acquisition,
    CONCAT('https://inpn.mnhn.fr/mtd/cadre/jdd/export/xml/GetRecordById?id=', jdd.id_sinp_jdd) AS fiche_md_jdd
FROM occtax.jdd
LEFT JOIN groupes ON jdd.jdd_id=groupes.jdd_id
LEFT JOIN milieux ON jdd.jdd_id=milieux.jdd_id
LEFT JOIN r ON jdd.jdd_id=r.jdd_id
JOIN (SELECT jdd_id, min(id_import) AS id_import, min(date_import) AS date_import  FROM occtax.jdd_import GROUP BY jdd_id) imin ON imin.jdd_id=jdd.jdd_id
JOIN (SELECT jdd_id, max(id_import) AS id_import, max(date_import) AS date_import FROM occtax.jdd_import GROUP BY jdd_id) imax ON imax.jdd_id=jdd.jdd_id
LEFT JOIN occtax.jdd_import i ON imax.jdd_id=i.jdd_id
LEFT JOIN occtax.organisme o ON r.id_organisme::INTEGER=o.id_organisme
WHERE imax.id_import=i.id_import
GROUP BY jdd_cadre, jdd.jdd_code, jdd.jdd_description, jdd.id_sinp_jdd,
    i.date_reception, imin.date_import, imax.date_import, i.nb_donnees_source, i.nb_donnees_import,
    i.date_obs_min, i.date_obs_max
ORDER BY imin.date_import
;

COMMENT ON MATERIALIZED VIEW stats.liste_jdd IS 'Liste des jeux de données indiquant pour chacun les producteurs concernés, les milieux de vie des taxons concernés, les URL pour accéder aux fiches de métadonnées, etc.';

-- liste_demandes
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.liste_demandes AS
SELECT  d.id,
        d.date_demande,
        o.nom_organisme,
        CASE WHEN d.motif_anonyme IS TRUE THEN 'Motif anonymisé temporairement'
                ELSE d.motif
                END AS motif,
        n.valeur AS type_demande,
        d.commentaire AS description_demande,
        date_validite_min,
        date_validite_max,
        d.statut,
        d.detail_decision
-- todo (je n'arrive pas à faire car il me manque le script de filtre des demandes): ajouter aussi :
-- le nombre de données concernées par la demande à la date à laquelle elle est formulée,
-- la ventilation par niveau de sensibilité (string_agg)
-- la ventilation par groupe taxonomique (string_agg)
FROM gestion.demande d
LEFT JOIN gestion.g_nomenclature n ON n.code=d.type_demande AND n.champ='type_demande'
LEFT JOIN occtax.organisme o ON o.id_organisme=d.id_organisme
ORDER BY date_demande
;

COMMENT ON MATERIALIZED VIEW stats.liste_demandes IS 'Liste des demandes d''accès aux données précises du SINP 974';

-- liste_organismes
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.liste_organismes AS
WITH r AS(
        SELECT  jdd_id,
                (jsonb_array_elements(ayants_droit)->>'id_organisme')::INTEGER AS id_organisme,
                jsonb_array_elements(ayants_droit)->>'role' AS role
        FROM occtax.jdd
        )

    ,j AS (
SELECT o.id_organisme,
    o.nom_organisme,
    count(jdd.jdd_id) AS nb_jdd,
    string_agg(CONCAT('- ', jdd.jdd_description, ' (', r.role,')') , chr(10) ORDER BY i.date_reception) AS liste_jdd,
    sum(i.nb_donnees_import) AS nb_donnees_jdd,
    max(i.date_reception) AS date_dernier_envoi_donnees
FROM occtax.jdd
JOIN (SELECT jdd_id, max(id_import) AS id_import, max(date_import) AS date_import FROM occtax.jdd_import GROUP BY jdd_id) imax ON imax.jdd_id=jdd.jdd_id
LEFT JOIN occtax.jdd_import i on imax.jdd_id=i.jdd_id
LEFT JOIN r ON r.jdd_id=jdd.jdd_id
LEFT JOIN occtax.organisme o ON r.id_organisme = o.id_organisme
WHERE imax.id_import=i.id_import
GROUP BY o.nom_organisme, o.id_organisme
    ),

d AS (
SELECT o.id_organisme,
    o.nom_organisme,
    count(d.id) AS nb_demandes,
    string_agg(CONCAT('- ', d.motif, ' (', d.statut, ')') , chr(10) ORDER BY d.date_demande) AS liste_demandes,
    min(d.date_demande) AS date_premiere_demande,
    max(d.date_demande) AS date_derniere_demande,
    max(d.date_validite_max) AS date_fin_dernier_acces
FROM gestion.demande d
LEFT JOIN occtax.organisme o ON o.id_organisme=d.id_organisme
GROUP BY o.nom_organisme, o.id_organisme
)

SELECT o.nom_organisme,
    COALESCE(a.statut, 'Non adhérent') AS statut_adherent_sinp974,
    COALESCE(j.nb_jdd, 0) AS nb_jdd,
    j.liste_jdd,
    COALESCE(j.nb_donnees_jdd,0) AS nb_donnees,
    j.date_dernier_envoi_donnees,
    COALESCE(d.nb_demandes,0) AS nb_demandes,
    d.liste_demandes,
    d.date_premiere_demande,
    d.date_derniere_demande,
    d.date_fin_dernier_acces

FROM occtax.organisme o
LEFT JOIN gestion.adherent a ON a.id_organisme=o.id_organisme
LEFT JOIN j ON j.id_organisme=o.id_organisme
LEFT JOIN d ON d.id_organisme=o.id_organisme
WHERE j.nb_jdd>0 OR d.nb_demandes>0 OR a.statut<>'Non adhérent'
ORDER BY o.nom_organisme
;

COMMENT ON MATERIALIZED VIEW stats.liste_organismes IS 'liste des organismes contributeurs ou utilisateurs du SINP à La Réunion : adhérents, demandeurs d''accès aux données précises et producteurs';

-- Liste des taxons observés
CREATE MATERIALIZED VIEW IF NOT EXISTS stats.liste_taxons_observes AS
SELECT o.cd_ref, t.lb_nom, t.nom_vern, t.group2_inpn, t.{$colonne_locale} AS loc, t.rang,
m.valeur AS menace_uicn,
count(o.cle_obs) AS nb_observations,
max(EXTRACT(YEAR FROM COALESCE(o.date_fin, o.date_debut))) AS annee_derniere_obs,
string_agg(DISTINCT jdd.jdd_description, ' | ' ORDER BY jdd.jdd_description) AS liste_jdd,
t.url AS fiche_taxon
FROM occtax.observation o
LEFT JOIN (
    SELECT cd_ref, lb_nom, nom_vern, group2_inpn, {$colonne_locale}, rang, url, menace_nationale
    FROM taxon.taxref_consolide_non_filtre
    WHERE cd_nom=cd_ref
        )t USING(cd_ref)
LEFT JOIN (SELECT * FROM taxon.t_nomenclature WHERE champ='menace')m ON m.code=t.menace_nationale
LEFT JOIN occtax.jdd USING(jdd_code)
GROUP BY o.cd_ref, t.lb_nom, t.nom_vern, t.group2_inpn, t.{$colonne_locale}, t.rang, m.valeur, t.url
ORDER BY count(o.cle_obs) DESC ;

COMMENT ON MATERIALIZED VIEW stats.liste_taxons_observes IS 'Liste des taxons faisant l''objet d''au moins une observation dans Borbonica et statuts associés' ;

---------------------
-- gestion
----------------------

COMMENT ON COLUMN gestion.echange_inpn.liste_identifiant_permanent
IS 'Liste des identifiants permanents id_sinp_occtax des observations transmises lors de l''échange de données.
Ce champ est destiné à faciliter la traçabilité des données, afin notamment de ne pas exporter deux fois les mêmes données
et de pouvoir transmettre à nouveau des observations qui auraient été modifiées (notamment validées) depuis le dernier échange.';


--------------------
-- import.sql
--------------------
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
IS 'Tester la conformité des observations contenues dans la table fournie en paramètre
selon les critères stockés dans la table occtax.critere_conformite'
;


DELETE FROM occtax.critere_conformite WHERE code IN (
    'obs_identifiant_permanent_occtax_format',
    'obs_identifiant_permanent_not_null',
    'obs_sensible_not_null'
);
INSERT INTO occtax.critere_conformite (code, libelle, condition, type_critere)
VALUES
('obs_id_sinp_occtax_format', 'Le format de <b>id_sinp_occtax</b> est incorrect. Attendu: uuid' , $$occtax.is_given_type(id_sinp_occtax, 'uuid')$$, 'format'),
('obs_id_origine_not_null', 'La valeur de <b>id_origine</b> est vide', $$id_origine IS NOT NULL$$, 'not_null')
ON CONFLICT ON CONSTRAINT critere_conformite_unique_code DO NOTHING
;

CREATE OR REPLACE FUNCTION occtax.verification_doublons_avant_import(
    _table_temporaire regclass,
    _jdd_uid text,
    _check_inside_this_jdd boolean
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
            AND Coalesce(ST_Transform(
                    ST_SetSRID(
                        ST_MakePoint(t.longitude::real, t.latitude::real),
                        %1$s
                    ),
                    %1$s
                ), ST_MakePoint(0, 0)) = Coalesce(o.geom, ST_MakePoint(0, 0))
            )
        WHERE o.cle_obs IS NOT NULL
    '
    ;
    sql_text = sql_text || format(sql_template,
        _srid
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

COMMENT ON FUNCTION occtax.verification_doublons_avant_import(regclass, text, boolean)
IS 'Vérifie que les données en attente d''import (dans la table fournie en paramètre)
ne contiennent pas des données déjà existantes dans la table occtax.observation.
Les comparaisons sont faites sur les champs: cd_nom, date_debut, heure_debut,
date_fin, heure_fin, geom.'
;

DROP FUNCTION IF EXISTS occtax.import_observations_depuis_table_temporaire(regclass, text, text, text, text, text);
CREATE OR REPLACE FUNCTION occtax.import_observations_depuis_table_temporaire(
    _table_temporaire regclass,
    _import_login text,
    _jdd_uid text,
    _organisme_gestionnaire_donnees text,
    _org_transformation text
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
        CASE
            WHEN loip.id_sinp_occtax IS NOT NULL THEN loip.id_sinp_occtax
            ELSE CAST(uuid_generate_v4() AS text)
        END AS id_sinp_occtax,
        s.id_origine,

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

        s.dee_floutage AS dee_floutage,
        s.diffusion_niveau_precision AS diffusion_niveau_precision,
        s.ds_publique,

        j.jdd_code,
        j.jdd_id,
        j.id_sinp_jdd,

        org.organisme_gestionnaire_donnees AS organisme_gestionnaire_donnees,
        org.org_transformation AS org_transformation,

        s.statut_source,
        s.reference_biblio,

        s.sensi_date_attribution::date,
        s.sensi_niveau::text,
        s.sensi_referentiel,
        s.sensi_version_referentiel,

        NULL descriptif_sujet,
        NULL AS donnee_complementaire,

        s.precision_geometrie::integer,
        s.nature_objet_geo,
        ST_Transform(
            ST_SetSRID(
                ST_MakePoint(s.longitude::real, s.latitude::real),
                %7$s
            ),
            %7$s
        ) AS geom,

        json_build_object(
            ''observateurs'', s.observateurs,
            ''determinateurs'', s.determinateurs,
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


COMMENT ON FUNCTION occtax.import_observations_depuis_table_temporaire(regclass, text, text, text, text)
IS 'Importe les observations contenues dans la table fournie en paramètre pour le JDD fourni et les organismes (gestionnaire, transformation et standardisation)'
;



CREATE OR REPLACE FUNCTION occtax.import_observations_post_data(
    _table_temporaire regclass,
    _import_login text, _jdd_uid text, _default_email text,
    _libelle_import text, _date_reception date, _remarque_import text,
    _import_user_email text,
    _validateur integer
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
    FROM occtax.jdd WHERE id_sinp_jdd = _jdd_uid
    ;

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
                %1$s AS validateur,
                (SELECT "procedure" FROM occtax.validation_procedure ORDER BY id DESC LIMIT 1) AS "procedure",
                (SELECT proc_vers FROM occtax.validation_procedure ORDER BY id DESC LIMIT 1) AS proc_vers,
                (SELECT proc_ref FROM occtax.validation_procedure ORDER BY id DESC LIMIT 1) AS proc_ref,
                'Données validées pendant l''import CSV du ' || now()::date::text
            FROM occtax.observation AS o
            INNER JOIN "%2$s" AS s
                ON o.id_origine = s.id_origine::text
            WHERE True
                AND o.odata->>'import_temp_table' = '%2$s'
                AND o.jdd_id IN ('%3$s')
                AND o.odata->>'import_login' = '%4$s'
            ON CONFLICT ON CONSTRAINT validation_observation_id_sinp_occtax_ech_val_unique
            DO NOTHING
		    RETURNING id_sinp_occtax
        ) SELECT count(*) AS nb FROM ins
    $$;
    sql_text := format(sql_template,
        _validateur,
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


COMMENT ON FUNCTION occtax.import_observations_post_data(regclass, text, text, text, text, date, text, text, integer)
IS 'Importe les données complémentaires (observateurs, liens spatiaux, validation, etc.)
sur les observations contenues dans la table fournie en paramètre'
;

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
    DELETE FROM occtax.lien_observation_identifiant_permanent WHERE id_sinp_occtax IN (
        SELECT id_sinp_occtax FROM occtax.observation
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


-- TODO
