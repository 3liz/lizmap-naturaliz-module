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
    sql_template := $SQL$
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
    $SQL$;
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
            sql_template := $SQL$
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
            $SQL$;

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
    sql_template := $SQL$
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
    $SQL$;
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
    sql_template := $SQL$
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
    $SQL$;
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
        sql_template := $SQL$
        WITH ins AS (
            INSERT INTO occtax.observation_personne (cle_obs, id_personne, role_personne)
            WITH source AS (
                SELECT DISTINCT
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
        $SQL$;
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
    sql_template := $SQL$
        SELECT occtax.occtax_update_spatial_relationships(ARRAY['%1$s']) AS update_spatial;
    $SQL$;
    sql_text := format(sql_template,
        _jdd_id
    );
    -- RAISE NOTICE '-- update_spatial';
    -- RAISE NOTICE '%', sql_text;
    EXECUTE sql_text INTO _nb_lignes;
    _result_information := _result_information || jsonb_build_object('update_spatial', _nb_lignes);

    -- Informations de validation
    sql_template := $SQL$
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
    $SQL$;
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
    sql_template := $SQL$
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
    $SQL$;
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
    sql_template := $SQL$
        SELECT occtax.import_observations_post_data_regionale('%1$s') AS json_regional
    $SQL$;
    sql_text := format(sql_template,
        _jdd_id
    );
    -- RAISE NOTICE '-- nettoyage';
    -- RAISE NOTICE '%', sql_text;
    EXECUTE sql_text INTO _result_regional;
    _result_information := _result_information || _result_regional;



    -- Nettoyage
    sql_template := $SQL$
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
    $SQL$;
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
