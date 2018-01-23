BEGIN;

--
-- Extension validation
--
SET search_path TO occtax,public;

DROP FUNCTION IF EXISTS occtax.occtax_update_sensibilite_observations( text,  TEXT,  TEXT,  text[],  TEXT[],  BIGINT[]);

-- validation_procedure
DROP TABLE IF EXISTS validation_procedure;
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

INSERT INTO occtax.validation_procedure (proc_ref, "procedure", proc_vers)
VALUES ('1.0.0', 'Procédure de validation de test', '1.0.0')
ON CONFLICT DO NOTHING;

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


CREATE OR REPLACE FUNCTION occtax.calcul_niveau_validation(
    p_jdd_id TEXT[],
    p_validateur integer,
    p_simulation boolean
)
RETURNS INTEGER AS
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
            cle_obs,
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
            t.cle_obs,
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
        AND t.cle_obs = cle_obs
        ON CONFLICT ON CONSTRAINT validation_observation_cle_obs_ech_val_unique
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
            ''Validation automatique du '' || now()::DATE || '' : '' || cv.libelle,
            $1, -- validateur

            -- On utilise les valeurs de la table procedure
            p."procedure",
            p.proc_vers,
            p.proc_ref
        )
         WHERE TRUE
        AND vo.typ_val NOT IN (''M'', ''C'')
        ';
        EXECUTE format(sql_template)
        USING p_validateur;
    END IF;

    -- On supprime les lignes dans validation_observation pour ech_val = '2' et cle_obs NOT IN
    -- qui ne correspondent pas au critère et qui ne sont pas manuelles
    -- on a bien ajouté le WHERE AND vo.typ_val NOT IN (''M'', ''C'')
    -- pour ne surtout pas supprimer les validations manuelles ou combinées via notre outil auto
    if p_simulation IS NOT TRUE THEN
        sql_template := '
        DELETE FROM occtax.validation_observation vo
        WHERE TRUE
        AND ech_val = ''2''
        AND vo.typ_val NOT IN (''M'', ''C'')
        AND cle_obs NOT IN (
            SELECT cle_obs
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


DROP FUNCTION IF EXISTS occtax.calcul_niveau_sensibilite(text[],boolean,text,text);

-- calcul sensibilite
CREATE OR REPLACE FUNCTION occtax.calcul_niveau_sensibilite(
    p_jdd_id TEXT[],
    p_simulation boolean
)
RETURNS INTEGER AS
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
        AND t.cle_obs = o.cle_obs
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
        FROM occtax.niveau_par_observation_final AS t,
        (
            SELECT sensi_referentiel, sensi_version_referentiel
            FROM occtax.sensibilite_referentiel, regexp_split_to_array(trim(sensi_version_referentiel),  ''\.'')  AS a
            ORDER BY concat(lpad(a[1], 3, ''0''), lpad(a[2], 3, ''0''), lpad(a[3], 3, ''0'')) DESC
            LIMIT 1
        ) AS p
        WHERE True
        AND contexte = ''sensibilite''
        AND o.cle_obs != t.cle_obs
        -- AND o.sensi_referentiel = p.sensi_referentiel
        ';
        sql_text := format(sql_template, p_sensi_referentiel, p_sensi_version_referentiel);

        RAISE NOTICE '%' , sql_text;
        EXECUTE sql_text;
    END IF;


    END IF;

    RETURN 1;

END
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


-- Vue pour avoir une nomenclature à plat
DROP VIEW IF EXISTS v_nomenclature_plat CASCADE;
CREATE VIEW v_nomenclature_plat AS
SELECT
json_object(
    array_agg(concat("champ", '_', "code") ) ,
    array_agg("valeur")
) AS dict
FROM occtax.nomenclature
;



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
LEFT JOIN occtax.validation_observation v ON "ech_val" = '2' AND v.cle_obs = o.cle_obs
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
                    cle_obs,
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
                    NEW.cle_obs,
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
                AND vo.cle_obs = NEW.cle_obs
                ;
            END IF;

        RETURN NEW;

        END IF;
    END;
$$ LANGUAGE plpgsql;



COMMIT;
