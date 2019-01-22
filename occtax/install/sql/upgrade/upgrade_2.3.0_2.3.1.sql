BEGIN;

-- taxon
ALTER EXTENSION unaccent SET SCHEMA public;
ALTER EXTENSION pg_trgm SET SCHEMA public;
ALTER TEXT SEARCH CONFIGURATION french_text_search SET SCHEMA public;

-- occtax
SET search_path TO occtax,public;

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
            ''Validation automatique du '' || now()::DATE || '' : '' || cv.libelle,
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

ALTER TABLE occtax.critere_validation DROP CONSTRAINT IF EXISTS critere_validation_niveau_valide ;
ALTER TABLE occtax.critere_validation ADD CONSTRAINT critere_validation_niveau_valide CHECK ( niveau IN ( '1', '2', '3', '4', '5', '6' ) ) ;

ALTER TABLE occtax.jdd_import
ALTER COLUMN nb_donnees_source TYPE INTEGER,
ALTER COLUMN nb_donnees_import TYPE INTEGER
;


-- vm_observation
DROP MATERIALIZED VIEW IF EXISTS occtax.vm_observation CASCADE;
CREATE MATERIALIZED VIEW occtax.vm_observation AS
SELECT
o.cle_obs,
o.identifiant_permanent,
o.statut_observation,
o.cd_nom,
o.cd_ref,
o.version_taxref,
o.nom_cite,
t.nom_valide, t.reu, trim(t.nom_vern) AS nom_vern, t.group1_inpn, t.group2_inpn, t.ordre, t.famille, t.protection, t.url,
(regexp_split_to_array( Coalesce( tgc1.cat_nom, tgc2.cat_nom, 'Autres' ), ' '))[1] AS categorie,
trim(tv.lb_nom) AS lb_nom_valide, trim(tv.nom_vern) AS nom_vern_valide,
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
o.identifiant_origine,
o.jdd_code,
o.jdd_id,
o.jdd_metadonnee_dee_id,
o.jdd_source_id,
o.organisme_gestionnaire_donnees,
o.organisme_standard,
o.org_transformation,
o.statut_source,
o.reference_biblio,
o.sensible,
o.sensi_date_attribution,
o.sensi_niveau,
o.sensi_referentiel,
o.sensi_version_referentiel,
o.descriptif_sujet AS descriptif_sujet,
o.validite_niveau,
o.validite_date_validation,
o.precision_geometrie,
o.nature_objet_geo,
o.geom,
CASE
    WHEN o.geom IS NOT NULL THEN
        CASE
            WHEN GeometryType(geom) IN ('POLYGON', 'MULTIPOLYGON') THEN 'Polygone'
            WHEN GeometryType(geom) IN ('LINESTRING', 'MULTILINESTRING') THEN 'Ligne'
            WHEN GeometryType(geom) IN ('POINT', 'MULTIPOINT') THEN 'Point'
            ELSE 'Géométrie'
        END
    -- WHEN lm05.code_maille IS NOT NULL THEN 'M05'
    WHEN lm10.code_maille IS NOT NULL THEN 'M10'
    WHEN lc.code_commune IS NOT NULL THEN 'COM'
    WHEN lme.code_me IS NOT NULL THEN 'ME'
    WHEN len.code_en IS NOT NULL THEN 'EN'
    WHEN ld.code_departement IS NOT NULL THEN 'DEP'
    ELSE 'NO'
END AS source_objet,

jsonb_agg(DISTINCT lm01.code_maille) AS code_maille_01,
min(lm01.code_maille) AS code_maille_01_unique,
jsonb_agg(DISTINCT lm02.code_maille) AS code_maille_02,
min(lm02.code_maille) AS code_maille_02_unique,
-- jsonb_agg(DISTINCT lm05.code_maille) AS code_maille_05,
jsonb_agg(DISTINCT lm10.code_maille) AS code_maille_10,
min(lm10.code_maille) AS code_maille_10_unique,
jsonb_agg(DISTINCT lc.code_commune) AS code_commune,
min(lc.code_commune) AS code_commune_unique,
jsonb_agg(DISTINCT ld.code_departement) AS code_departement,
jsonb_agg(DISTINCT lme.code_me) AS code_me,
jsonb_agg(DISTINCT len.code_en) AS code_en,
jsonb_agg(DISTINCT len.type_en) AS type_en,

od.diffusion,
string_agg( DISTINCT concat(
    pobs.identite,
    CASE
        WHEN pobs.organisme IS NULL OR pobs.organisme = '' THEN ''
        ELSE ' (' || pobs.organisme|| ')'
    END
), ', ' ) AS identite_observateur,
string_agg( DISTINCT concat(
    pval.identite,
    CASE
        WHEN pval.organisme IS NULL OR pval.organisme = '' THEN ''
        ELSE ' (' || pval.organisme|| ')'
    END
), ', ' ) AS validateur,
string_agg( DISTINCT concat(
    pdet.identite,
    CASE
        WHEN pdet.organisme IS NULL OR pdet.organisme = '' THEN ''
        ELSE ' (' || pdet.organisme|| ')'
    END
), ', ' ) AS determinateur

FROM occtax."observation"  AS o
JOIN  occtax."observation_diffusion"  AS od  ON od.cle_obs = o.cle_obs
LEFT JOIN taxon."taxref_consolide_non_filtre" AS t USING (cd_nom)
LEFT JOIN taxon."taxref_valide" AS tv ON tv.cd_nom = t.cd_ref
LEFT JOIN taxon."t_group_categorie" AS tgc1  ON tgc1.groupe_nom = t.group1_inpn AND tgc1.groupe_type = 'group1_inpn'
LEFT JOIN taxon."t_group_categorie" AS tgc2  ON tgc2.groupe_nom = t.group2_inpn AND tgc2.groupe_type = 'group2_inpn'
LEFT JOIN occtax."v_observateur"  AS pobs  ON pobs.cle_obs = o.cle_obs
LEFT JOIN occtax."v_validateur"  AS pval  ON pval.cle_obs = o.cle_obs
LEFT JOIN occtax."v_determinateur"  AS pdet  ON pdet.cle_obs = o.cle_obs
LEFT JOIN occtax."localisation_maille_01"  AS lm01  ON lm01.cle_obs = o.cle_obs
LEFT JOIN occtax."localisation_maille_02"  AS lm02  ON lm02.cle_obs = o.cle_obs
LEFT JOIN occtax."localisation_maille_10"  AS lm10  ON lm10.cle_obs = o.cle_obs
LEFT JOIN occtax."localisation_commune"  AS lc  ON lc.cle_obs = o.cle_obs
LEFT JOIN occtax."localisation_departement"  AS ld  ON ld.cle_obs = o.cle_obs
LEFT JOIN occtax."localisation_masse_eau"  AS lme  ON lme.cle_obs = o.cle_obs
LEFT JOIN occtax."v_localisation_espace_naturel"  AS len  ON len.cle_obs = o.cle_obs

WHERE True
GROUP BY o.cle_obs, o.nom_cite, t.nom_valide, t.reu, t.nom_vern, t.group1_inpn, t.group2_inpn, t.ordre, t.famille, t.protection, t.url,
o.cd_nom, o.date_debut, source_objet, o.geom, o.geom, od.diffusion, categorie,
tv.lb_nom, tv.nom_vern
;

CREATE INDEX vm_observation_cle_obs_idx ON occtax.vm_observation (cle_obs);
CREATE INDEX vm_observation_identifiant_permanent_idx ON occtax.vm_observation (identifiant_permanent);
CREATE INDEX vm_observation_geom_idx ON occtax.vm_observation USING GIST (geom);
CREATE INDEX vm_observation_cd_ref_idx ON occtax.vm_observation (cd_ref);
CREATE INDEX vm_observation_cd_nom_idx ON occtax.vm_observation (cd_nom);
CREATE INDEX vm_observation_group1_inpn_idx ON occtax.vm_observation (group1_inpn);
CREATE INDEX vm_observation_group2_inpn_idx ON occtax.vm_observation (group2_inpn);
CREATE INDEX vm_observation_categorie_idx ON occtax.vm_observation (categorie);
CREATE INDEX vm_observation_jdd_id_idx ON occtax.vm_observation (jdd_id);
CREATE INDEX vm_observation_validite_niveau_idx ON occtax.vm_observation (validite_niveau);
CREATE INDEX vm_observation_date_debut_date_fin_idx ON occtax.vm_observation USING btree (date_debut, date_fin DESC);
CREATE INDEX vm_observation_descriptif_sujet_idx ON occtax.vm_observation USING GIN (descriptif_sujet);
CREATE INDEX vm_observation_code_commune_idx ON occtax.vm_observation USING GIN (code_commune);
CREATE INDEX vm_observation_code_maille_01_idx ON occtax.vm_observation USING GIN (code_maille_01);
CREATE INDEX vm_observation_code_maille_02_idx ON occtax.vm_observation USING GIN (code_maille_02);
CREATE INDEX vm_observation_code_maille_01_unique_idx ON occtax.vm_observation (code_maille_01_unique);
CREATE INDEX vm_observation_code_maille_02_unique_idx ON occtax.vm_observation (code_maille_02_unique);
CREATE INDEX vm_observation_code_maille_10_unique_idx ON occtax.vm_observation (code_maille_10_unique);
CREATE INDEX vm_observation_diffusion_idx ON occtax.vm_observation USING GIN (diffusion);

-- recreation des dépendances
-- occtax.vm_stat_nb_taxons_observes_par_groupe_taxonomique
DROP VIEW IF EXISTS occtax.vm_stat_nb_taxons_observes_par_groupe_taxonomique;
CREATE VIEW occtax.vm_stat_nb_taxons_observes_par_groupe_taxonomique AS
SELECT row_number() OVER () AS id, categorie,
Count(DISTINCT o.cd_ref) AS nb_taxon_present
FROM occtax.vm_observation o
GROUP BY categorie
ORDER BY categorie
;

-- occtax.vm_stat_nb_observations_par_groupe_taxonomique
DROP VIEW IF EXISTS occtax.vm_stat_nb_observations_par_groupe_taxonomique;
CREATE VIEW occtax.vm_stat_nb_observations_par_groupe_taxonomique AS
SELECT
row_number() OVER () AS id, categorie,
Count(o.cle_obs) AS nbobs
FROM occtax.vm_observation o
GROUP BY categorie
ORDER BY categorie
;


-- occtax.v_observation_validation
DROP VIEW IF EXISTS occtax.v_observation_validation CASCADE;
CREATE VIEW occtax.v_observation_validation AS (
SELECT o.cle_obs,
o.identifiant_permanent,
o.statut_observation,
o.cd_nom,
o.cd_ref,
o.nom_cite,
o.nom_valide,
o.reu,
o.nom_vern,
o.group2_inpn,
o.ordre,
o.famille,
o.lb_nom_valide,
o.nom_vern_valide,
o.denombrement_min,
o.denombrement_max,
o.objet_denombrement,
o.type_denombrement,
o.descriptif_sujet,
-- Preuve existante: on cherche dans descriptif_sujet. Si au moins une preuve n'est pas oui, on met Non
CASE
    WHEN descriptif_sujet IS NULL OR descriptif_sujet::text ~* '"preuve_existante": ((")?(0|2|3)(")?|null)'
        THEN 'Non'
    ELSE 'Oui'
END AS preuve_existante,
o.date_determination,
o.date_debut,
o.date_fin,
o.heure_debut,
o.heure_fin,
o.geom,
o.altitude_moy,
o.precision_geometrie,
o.nature_objet_geo,
o.identite_observateur,
o.determinateur,
o.organisme_gestionnaire_donnees,
o.commentaire,
o.code_idcnp_dispositif,
o.dee_date_transformation,
o.dee_date_derniere_modification,
o.jdd_code,
o.jdd_id,
o.jdd_metadonnee_dee_id,
o.statut_source,
o.reference_biblio,
o.ds_publique,
o.diffusion_niveau_precision,
o.sensi_niveau,
v.id_validation,
v.date_ctrl,
v.niv_val,
v.typ_val,
v.ech_val,
v.peri_val,
v.val_validateur AS validateur,
v.proc_vers,
v.producteur,
v.date_contact,
v.procedure,
v.proc_ref,
v.comm_val,
-- on doit stocker les informations relatives à la validation producteur :
CASE
    WHEN vprod.id_validation IS NOT NULL
        THEN concat('Niveau de validité attribué le ', vprod.date_ctrl::TEXT, ' par ', vprod.val_validateur ,  ' : ', vprod.valeur, '.', vprod.comm_val)
    ELSE NULL
END AS validation_producteur
FROM vm_observation o
LEFT JOIN (
    SELECT vv.*,
    identite || concat(' - ' || mail, ' (' || o.nom_organisme || ')' ) AS val_validateur
    FROM validation_observation vv
    LEFT JOIN personne p ON vv.validateur = p.id_personne
    LEFT JOIN organisme o ON p.id_organisme = o.id_organisme
    WHERE ech_val = '2' -- uniquement validation de niveau régional
) v USING (identifiant_permanent)
-- jointure pour avoir les informations relatives à la validation producteur
LEFT JOIN (
    SELECT vv.*,
    n.valeur,
    identite || concat(' - ' || mail, ' (' || o.nom_organisme || ')' ) AS val_validateur
    FROM validation_observation vv
    LEFT JOIN personne p ON vv.validateur = p.id_personne
    LEFT JOIN organisme o ON p.id_organisme = o.id_organisme
    LEFT JOIN occtax.nomenclature n ON n.champ='niv_val_mancom' AND n.code=vv.niv_val
    WHERE vv.ech_val = '1' -- uniquement validation producteur
) vprod USING (identifiant_permanent)
)
;


COMMIT;
