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
