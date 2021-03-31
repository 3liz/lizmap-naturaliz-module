

CREATE SCHEMA divers;


--
-- Name: SCHEMA divers; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA divers IS 'Schéma permettant de stocker diverses tables utilisées par l''équipe projet :
- qui ne sont pas prévues dans la structure initiale de naturaliz
- et qui ne sont pas des données source';


--
-- Name: analyse_jdd(text, integer); Type: FUNCTION; Schema: divers; Owner: -
--

CREATE FUNCTION divers.analyse_jdd(jdd_nom text, nb_valeurs_max integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$

DECLARE liste_champs RECORD ;

BEGIN

    RAISE NOTICE 'Je suis en train de travailler, ça peut prendre quelques minutes ! L''occasion de pratiquer la respiration ventrale ou de se préparer un roiboos...' ;

    -- 1/ Suppression des lignes correspondantes si la fonction a déjà été lancée pour ce jeu de données
    DELETE
    FROM divers.jdd_analyse ;

    -- 2/ remplissage des valeurs uniques depuis la table testée

    FOR liste_champs IN (
        SELECT column_name AS champ
        FROM information_schema.columns
        WHERE table_schema = 'fdw'
        AND table_name = $1
        ORDER BY ordinal_position
        )

        LOOP

        EXECUTE

        'WITH p AS (
            SELECT ' || liste_champs.champ || ', count(*) AS occurence
            FROM fdw.' || $1 || '
            GROUP BY ' || liste_champs.champ || '
            ORDER BY ' || liste_champs.champ || '
            )

        INSERT INTO divers.jdd_analyse(jdd_nom, ordre, champ, type, nb_char, nb_valeurs, valeurs, date)

        SELECT  ''' || $1 || ''' AS jdd_nom,

            c.ordinal_position AS n,

            c.column_name AS champ,

            c.data_type AS type,

            c.character_maximum_length AS nb_char, -- attention, parfois ce champ est vide dans information.schema : pourquoi ?

            (SELECT count( DISTINCT COALESCE(' || liste_champs.champ || '::TEXT, '''')) FROM fdw.' || $1 || ') AS nb_valeurs,

            (SELECT CASE    WHEN (SELECT count( DISTINCT ' || liste_champs.champ || '::TEXT) FROM fdw.' || $1 || ')>' || $2 || '
                        THEN ''["Nombre de valeurs supérieur à ' || $2 || ', modifier les arguments de la fonction pour en afficher d''''avantage"]''
                    ELSE array_to_json(
                            array_agg(
                                json_build_object(
                                    ''valeur'', COALESCE("' || liste_champs.champ || '"::TEXT, ''NULL''),
                                    ''occurence'', "occurence"
                                    )
                                )
                            )
                    END
                    FROM p
                        )AS valeurs,

            ''now''::TEXT::TIMESTAMP WITH TIME ZONE AS date

        FROM information_schema.columns c
        WHERE c.table_schema = ''fdw''
        AND c.table_name = ''' || $1 || '''
        AND c.column_name = ''' || liste_champs.champ || ''''
        ;

        END LOOP;
        RETURN    ;

        RAISE NOTICE 'Voilà j''ai fini ! N''oublie pas de lancer la requête SELECT * FROM divers.v_jdd_analyse pour voir le résultat de mon analyse' ;

    END ;

$_$;



--
-- Name: fonction_controle_coherence_conformite(text[]); Type: FUNCTION; Schema: divers; Owner: -
--

CREATE FUNCTION divers.fonction_controle_coherence_conformite(jdd_id text[]) RETURNS void
    LANGUAGE plpgsql
    AS $_$

DECLARE liste_champs RECORD ;

BEGIN

-- a/ Vidage de la table
DELETE FROM divers.controle_coherence_conformite ;

-- b/ remplissage des valeurs uniques depuis la table testée

WITH o AS (
        SELECT  o.jdd_id,o.jdd_code, o.cle_obs, o.identifiant_origine, o.nom_cite, o.cd_nom, o.ds_publique, o.diffusion_niveau_precision, tc.cd_nom AS cd_nom_taxref, tc.cd_ref, t.nom_valide, t.reu, t.habitat, CONCAT(t.habitat, ' - ', h.valeur) AS habitat_decode,
        o.geom, lc.code_commune, ltm.geom AS sur_terre, min(r.larg_pb_th) AS en_riviere, zee.geom AS dans_zee,
                COALESCE(altitude_min, altitude_moy,altitude_max) AS altitude, profondeur_min
        FROM occtax.observation o
        LEFT JOIN taxon.taxref_consolide_non_filtre tc ON o.cd_nom = tc.cd_nom
        LEFT JOIN taxon.taxref_valide t ON o.cd_ref=t.cd_ref
        LEFT JOIN (SELECT * FROM taxon.t_nomenclature WHERE champ= 'habitat') h ON h.code = t.habitat
        LEFT JOIN sig.limite_terre_mer ltm ON st_intersects(ltm.geom, o.geom)
        LEFT JOIN sig.riviere r ON st_distance(r.geom, o.geom)::INTEGER <= r.larg_pb_th::INTEGER
        LEFT JOIN sig.zone_economique_exclusive zee ON st_intersects(zee.geom, o.geom)
        LEFT JOIN occtax.localisation_commune lc ON lc.cle_obs = o.cle_obs
        WHERE o.jdd_id = ANY ($1)
        GROUP BY o.jdd_id,o.jdd_code, o.cle_obs, o.identifiant_origine, o.nom_cite, o.cd_nom, o.ds_publique, o.diffusion_niveau_precision, tc.cd_nom, tc.cd_ref, t.nom_valide,t.reu, t.habitat, o.geom, lc.code_commune, ltm.geom, zee.geom,
                COALESCE(altitude_min, altitude_moy,altitude_max), profondeur_min, t.habitat, h.valeur
            )

    , test_5 AS (
    -- TEST 5 "Diffusion au grand public" : on vérifie que les modalités de diffusion au grand public sont bien précisées et sont compatibles avec le statut public de la donnée
    SELECT o.cle_obs
    FROM o
    WHERE   (ds_publique = ANY (ARRAY['NSP'::text, 'Pr'::text]) AND diffusion_niveau_precision IS  NULL)
            OR (ds_publique = ANY (ARRAY['Pu'::text, 'Re'::text, 'Ac'::text])  AND diffusion_niveau_precision <> '5')

    ORDER BY o.cle_obs

    ), test_11 AS (
    -- TEST 11 "Altitude des observations marines" : on vérifie que les observations concernant un organisme marin n'ont pas une altitude supérieure à 0m
    SELECT o.cle_obs
    FROM o
    WHERE altitude>0 AND habitat='1'
    ORDER BY o.cle_obs

    ), test_12 AS (
    -- TEST 12 "Profondeur des observations terrestres" : on vérifie que les observations concernant un organisme terrestre n'ont pas une profondeur supérieure à 0m
    SELECT o.cle_obs
    FROM o
    WHERE profondeur_min>0 AND habitat='3'
    ORDER BY o.cle_obs

    ), test_13 AS (
    -- TEST 13 "localisation des espèces marines" : on vérifie que les observations concernant un organisme marin n'ont pas lieu en milieu terrestre
    SELECT o.cle_obs
    FROM o
    WHERE habitat='1' AND o.sur_terre IS NOT NULL
    ORDER BY o.cle_obs

    ), test_14 AS (
    -- TEST 14 "localisation des espèces terrestres" : on vérifie que les observations concernant un organisme terrestre n'ont pas lieu en mer
    SELECT o.cle_obs
    FROM o
    WHERE habitat IN ('2', '3', '7', '8') AND o.sur_terre IS NULL AND o.code_commune IS NULL
    ORDER BY o.cle_obs

    -- test 15 : "localisation des espèces d'eau douce" : on vérifie que les observations de taxons d'eau douce n'ont pas lieu en dehors d'un cours d'eau
    ), test_15 AS (
    SELECT o.cle_obs
    FROM o
    WHERE habitat IN ('2') AND o.en_riviere IS NULL
    ORDER BY o.cle_obs

    ), test_16 AS (
    -- TEST 16 "identifiants du jeu de données non cohérents" : on vérifie que les jdd_id et jdd_code sont les mêmes entre les tables occtax et jdd
    SELECT o.cle_obs
    FROM o
    WHERE o.jdd_id NOT IN (SELECT DISTINCT jdd.jdd_id FROM occtax.jdd) OR o.jdd_code NOT IN (SELECT DISTINCT jdd.jdd_code FROM occtax.jdd)
    ORDER BY o.cle_obs

    ),test_27 AS (
    -- TEST 27 "champ obligatoire : identite" : On vérifie qu'on a bien au moins un observateur/observation
    SELECT o.cle_obs
    FROM o
    LEFT JOIN occtax.observation_personne op USING(cle_obs)
    WHERE op.id_personne IS NULL
    ORDER BY o.cle_obs

    ), test_41 AS (
    -- TEST 41 "champ obligatoire : rattachement géographique" : on vérifie que chaque observation est associée à exactement une géométrie de référence
    -- Il peut s'agir d'une géométrie précise, ou bien d'un espace de référence (maille, commune...). D'autres géométries de rattachement peuvent être associées.
    SELECT o.cle_obs,
        st_summary(o.geom),
        count(DISTINCT o.geom) AS nb_geom,
        count(DISTINCT lc.code_commune) AS nb_commune,
        count(DISTINCT lm02.code_maille) AS nb_maille_02,
        count(DISTINCT lm10.code_maille) AS nb_maille_10,
        count(DISTINCT lme.code_me) AS nb_masse_eau,
        count(DISTINCT len.code_en) AS nb_espace_nat,
        count(DISTINCT ld.code_departement) AS nb_departement
    FROM o
    LEFT JOIN occtax.localisation_commune lc ON lc.cle_obs=o.cle_obs
    LEFT JOIN occtax.localisation_maille_02 lm02 ON lm02.cle_obs=o.cle_obs
    LEFT JOIN occtax.localisation_maille_02 lm10 ON lm10.cle_obs=o.cle_obs
    LEFT JOIN occtax.localisation_masse_eau lme ON lme.cle_obs=o.cle_obs
    LEFT JOIN occtax.localisation_espace_naturel len ON len.cle_obs=o.cle_obs
    LEFT JOIN occtax.localisation_departement ld ON ld.cle_obs=o.cle_obs
    WHERE
        (o.geom IS NULL AND CONCAT(COALESCE(lc.type_info_geo,''),
                                   COALESCE(lm02.type_info_geo,''),
                                   COALESCE(lm10.type_info_geo,''),
                                   COALESCE(lme.type_info_geo,''),
                                   COALESCE(len.type_info_geo,''),
                                   COALESCE(ld.type_info_geo,''))  NOT ILIKE '%1%') -- Aucune géométrie de référence

        OR  (o.geom IS NULL AND CONCAT(COALESCE(lc.type_info_geo,''),
                                   COALESCE(lm02.type_info_geo,''),
                                   COALESCE(lm10.type_info_geo,''),
                                   COALESCE(lme.type_info_geo,''),
                                   COALESCE(len.type_info_geo,''),
                                   COALESCE(ld.type_info_geo,''))  ILIKE '%1%1%') -- Plusieurs géométries de référence sans geom précise

        OR (o.geom IS NOT NULL AND CONCAT(COALESCE(lc.type_info_geo,''),
                                   COALESCE(lm02.type_info_geo,''),
                                   COALESCE(lm10.type_info_geo,''),
                                   COALESCE(lme.type_info_geo,''),
                                   COALESCE(len.type_info_geo,''),
                                   COALESCE(ld.type_info_geo,'')) ILIKE '%1%') -- Plusieurs géométries de référence dont géom précise
    GROUP BY o.cle_obs, o.geom, o.jdd_code, o.jdd_id, o.identifiant_origine
    ORDER BY cle_obs

    ), test_46 AS (
    -- TEST 46 "localisation des espèces dans la ZEE" : on vérifie que les observations ne sont pas situées en dehors de la ZEE
    SELECT  o.cle_obs
    FROM o
    WHERE o.dans_zee IS NULL AND o.geom IS NOT NULL
    ORDER BY o.cle_obs

    ), test_47 AS (
    -- TEST 47 "champs obligatoires : cd_nom et cd_ref" : on vérifie que les observations sont bien associées à un cd_nom et un cd_ref issus de Taxref ou Taxref_local
    SELECT  o.cle_obs
    FROM o
    WHERE o.cd_nom_taxref IS NULL or o.cd_ref IS NULL
    ORDER BY o.cle_obs

    ), liste AS (
-- On fusionne les différentes tables pour avoir une table globale des anomalies
    SELECT  cle_obs,
            'test_5' AS libelle_test,
            'Les modalités de diffusion au grand public ne sont pas précisées ou bien sont incompatibles avec le statut public de la donnée' AS description_anomalie
    FROM test_5
    UNION
    SELECT  cle_obs,
            'test_11' AS libelle_test,
            'L''observation concerne un organisme marin et est à une altitude supérieure à 0m' AS description_anomalie
    FROM test_11
    UNION
    SELECT  cle_obs,
            'test_12' AS libelle_test,
            'L''observation concerne un organime terrestre et est à une profondeur supérieure à 0m'  AS description_anomalie
    FROM test_12
    UNION
    SELECT cle_obs ,
            'test_13' AS libelle_test,
            'L''observation concerne un organisme marin mais a lieu en milieu terrestre'  AS description_anomalie
    FROM test_13
    UNION
    SELECT cle_obs,
            'test_14' AS libelle_test,
            'L''observation concerne un organisme terrestre mais a lieu en mer'  AS description_anomalie
    FROM test_14
    UNION
    SELECT  cle_obs,
            'test_15' AS libelle_test,
            'L''observation concerne un organisme d''eau douce mais a lieu en dehors d''un cours d''eau'  AS description_anomalie
    FROM test_15
    UNION
    SELECT  cle_obs,
            'test_16' AS libelle_test,
            'Les identifiants du jeu de données jdd_id et jdd_code ne sont pas cohérents entre la table observation et la table jdd'  AS description_anomalie
    FROM test_16
    UNION
    SELECT  cle_obs,
            'test_27' AS libelle_test,
            'L''observation est orpheline : elle n''est associée à aucun observateur' AS description_anomalie
    FROM test_27
    UNION
    SELECT cle_obs,
            'test_41' AS libelle_test,
            'L''observation n''est pas associée à un unique objet géographique de référence' AS description_anomalie
    FROM test_41
    UNION
    SELECT  cle_obs,
            'test_46' AS libelle_test,
            'L''observation est située en dehors de la ZEE' AS description_anomalie
    FROM test_46
    UNION
    SELECT  cle_obs,
            'test_47' AS libelle_test,
            'L''observation n’est pas associée à un cd_nom ou un cd_ref issu de Taxref ou Taxref_local' AS description_anomalie
    FROM test_47
    )

INSERT INTO divers.controle_coherence_conformite
(jdd_id, jdd_code, cle_obs, identifiant_origine, wkt, libelle_test, description_anomalie, date_analyse, nom_cite, nom_valide, reu, habitat )
SELECT o.jdd_id, o.jdd_code, l.cle_obs, o.identifiant_origine, st_AsEWKT(o.geom), l.libelle_test, l.description_anomalie, now()::TIMESTAMP WITH TIME ZONE, o.nom_cite, o.nom_valide, o.reu, o.habitat_decode
FROM liste l
LEFT JOIN o USING(cle_obs)
ORDER BY l.libelle_test, o.cle_obs
;

END ;

$_$;


--
-- Name: fonction_controle_doublons(text[], integer, boolean); Type: FUNCTION; Schema: divers; Owner: -
--

CREATE FUNCTION divers.fonction_controle_doublons(jdd_id text[], rayon_en_m integer, p_controle_interne boolean) RETURNS void
    LANGUAGE plpgsql
    AS $_$


DECLARE sql_requete_principale TEXT ;
DECLARE sql_clause_where TEXT ;
DECLARE sql_group_by TEXT ;
DECLARE sql_insert TEXT ;
DECLARE jdd_id_compares TEXT[] ;

BEGIN

    RAISE NOTICE 'Je suis en train de travailler, ça peut prendre quelques minutes ! L''occasion de pratiquer la respiration ventrale...' ;

-- 2.1 On vide la table divers.controle_doublons
-------------------------------------------------------
    DELETE FROM divers.controle_doublons ;

-- 2.2 On établit la liste des jdd_id auxquels comparer le(s) jdd testé(s)
-------------------------------------------------------

    IF p_controle_interne IS TRUE
        THEN SELECT INTO jdd_id_compares array_agg(jdd.jdd_id) FROM occtax.jdd WHERE jdd.jdd_id = ANY ($1) ;
        ELSE SELECT INTO jdd_id_compares array_agg(jdd.jdd_id) FROM occtax.jdd WHERE NOT(jdd.jdd_id = ANY ($1)) ;
    END IF ;


-- 2.3 On lance la fonction
--------------------------

    sql_requete_principale := '

    -- Table complète des obs, enrichie par jointures
    WITH v_obs AS (
            SELECT  o.cle_obs,
                o.jdd_code,
                o.organisme_gestionnaire_donnees,
                o.jdd_id,
                o.identifiant_origine,
                o.identifiant_permanent,
                COALESCE(o.geom, m02.geom, m10.geom) AS geom, -- on prend la géométrie de l''objet et à défaut celle de la maille la plus précise
                o.date_debut,
                o.cd_ref,
                o.denombrement_min,
                string_agg(DISTINCT
                    CONCAT_WS ('' '',
                            ds.occ_denombrement_min, lower(ds.occ_objet_denombrement) || ''(s)'',
                            CASE WHEN ds.occ_etat_biologique IN (''Trouvé mort'') THEN lower(ds.occ_etat_biologique) ELSE NULL END,
                            CASE WHEN ds.occ_sexe NOT IN (''Inconnu'', ''Non renseigné'', ''NSP'', ''Indéterminé'') THEN ''de sexe '' || lower(ds.occ_sexe) ELSE NULL END,
                            CASE WHEN ds.occ_stade_de_vie NOT IN (''Inconnu'', ''Non renseigné'', ''NSP'', ''Indéterminé'') THEN ''au stade '' || lower(ds.occ_stade_de_vie) ELSE NULL END,
                            CASE WHEN ds.occ_statut_biologique NOT IN (''Inconnu'', ''Non renseigné'', ''NSP'', ''Indéterminé'') THEN ''de statut '' || lower(ds.occ_statut_biologique) ELSE NULL END
                           )
                    , '' ; ''
                    ) AS detail_individus,
                string_agg(DISTINCT p.identite, '' - '' ORDER BY p.identite) AS observateurs,
                o.validite_niveau,
                o.validite_date_validation,
                o.dee_date_derniere_modification::DATE,
                max(i.date_import) AS dernier_import
        FROM occtax.observation o
        LEFT JOIN occtax.observation_personne op USING(cle_obs)
        LEFT JOIN occtax.personne p USING(id_personne)
        -- ajout de jointures pour récupérer les mailles
        LEFT JOIN occtax.localisation_maille_02 lm02 ON lm02.cle_obs = o.cle_obs
        LEFT JOIN sig.maille_02 m02 ON lm02.code_maille = m02.code_maille
        LEFT JOIN occtax.localisation_maille_10 lm10 ON lm10.cle_obs=o.cle_obs
        LEFT JOIN sig.maille_10 m10 ON lm10.code_maille = m10.code_maille
        LEFT JOIN occtax.jdd_import i ON o.jdd_id=i.jdd_id
        LEFT JOIN occtax.v_descriptif_sujet_decodee ds ON ds.cle_obs = o.cle_obs
        WHERE (op.role_personne=''Obs'' OR op.role_personne IS NULL)
        GROUP BY o.cle_obs, o.jdd_code, o.jdd_id, o.identifiant_origine, COALESCE(o.geom, m02.geom, m10.geom), o.date_debut, o.cd_ref, o.organisme_gestionnaire_donnees, o.denombrement_min
            )

    -- Table(s) qu''on souhaite tester
    ,obs_source AS (
        SELECT * FROM v_obs WHERE v_obs.jdd_id = ANY ($1)
        )

    -- Tables auxquelles on souhaite la comparer
    ,obs_cible AS (
        SELECT * FROM v_obs WHERE v_obs.jdd_id = ANY ($2)
        )

    ,liste_doublons_brute AS (
        SELECT
            CASE WHEN s.jdd_code = c.jdd_code
                THEN s.jdd_code
                ELSE CONCAT(s.jdd_code, '' | '', c.jdd_code)
            END AS jdd_code,

            CASE WHEN s.jdd_id = c.jdd_id
                THEN s.jdd_id
                ELSE CONCAT(s.jdd_id, '' | '', c.jdd_id)
            END AS jdd_id,

            CASE
                WHEN TRIM(lower(s.organisme_gestionnaire_donnees)) = TRIM(LOWER(c.organisme_gestionnaire_donnees))
                THEN CONCAT(''Même organisme'', '' ('', s.organisme_gestionnaire_donnees, '')'')
                ELSE CONCAT(s.organisme_gestionnaire_donnees, '' | '', c.organisme_gestionnaire_donnees)
            END AS organisme_gestionnaire_donnees,

            s.cle_obs AS cle_obs_source,
            c.cle_obs AS cle_obs_cible,
            s.identifiant_origine AS identifiant_origine_source,
            c.identifiant_origine AS identifiant_origine_cible,
            s.identifiant_permanent AS identifiant_permanent_source,
            c.identifiant_permanent AS identifiant_permanent_cible,
            st_distance(s.geom, c.geom)::NUMERIC(10,1) AS distance_geom_m,
            t.group2_inpn,
            t.nom_valide,
            t.nom_vern,
            c.date_debut,

            CASE WHEN s.observateurs = c.observateurs
                THEN CONCAT(''Mêmes observateurs'', '' ('', s.observateurs, '')'')
                ELSE CONCAT(s.observateurs, '' | '', c.observateurs)
            END AS observateurs,

            CASE WHEN s.denombrement_min = c.denombrement_min
                THEN CONCAT(''Même effectif'', '' ('', s.denombrement_min, '')'')
                ELSE CONCAT(s.denombrement_min, '' | '', c.denombrement_min)
            END AS denombrement_total,

            CASE WHEN s.detail_individus = c.detail_individus
                THEN CONCAT(''Mêmes individus'', '' ('', s.detail_individus, '')'')
                ELSE CONCAT(s.detail_individus, '' | '', c.detail_individus)
            END AS detail_individus,

            CASE WHEN s.validite_niveau = c.validite_niveau
                THEN CONCAT(''Même niveau'', '' ('', s.validite_niveau, '')'')
                ELSE CONCAT(s.validite_niveau, '' | '', c.validite_niveau)
            END AS validite_niveau,

            CASE WHEN s.validite_date_validation = c.validite_date_validation
                THEN s.validite_date_validation::TEXT
                ELSE CONCAT(s.validite_date_validation, '' | '', c.validite_date_validation)
            END AS validite_date_validation,

            CASE WHEN s.dernier_import = c.dernier_import
                THEN s.dernier_import::TEXT
                ELSE CONCAT(s.dernier_import, '' | '', c.dernier_import)
            END AS dernier_import,

            CASE WHEN s.dee_date_derniere_modification = c.dee_date_derniere_modification
                THEN s.dee_date_derniere_modification::TEXT
                ELSE CONCAT(s.dee_date_derniere_modification, '' | '', c.dee_date_derniere_modification)
            END AS dee_date_derniere_modification

        FROM obs_source s
        INNER JOIN obs_cible c
            ON s.cd_ref = c.cd_ref
            AND s.date_debut = c.date_debut
            AND st_DWithin(s.geom, c.geom, $3) -- les géométries doivent être distantes de moins de la valeur indiquée en paramètre
        LEFT JOIN taxon.taxref_valide t ON s.cd_ref = t.cd_ref
        WHERE s.cle_obs <> c.cle_obs -- pour les cas où on teste intra-jeu
    ';

    IF p_controle_interne IS TRUE
        THEN sql_clause_where =
                'AND s.cle_obs < c.cle_obs
                '; -- permet de ne pas lister deux fois une même paire d'observations
        ELSE sql_clause_where =
                'AND TRUE
                ' ;
    END IF ;

    sql_group_by = '
    GROUP BY    s.jdd_code, c.jdd_code, s.jdd_id, c.jdd_id, s.cle_obs, c.cle_obs, c.identifiant_origine, s.identifiant_origine, s.identifiant_permanent, c.identifiant_permanent, c.organisme_gestionnaire_donnees, s.organisme_gestionnaire_donnees,
    c.date_debut, t.nom_valide, t.group2_inpn, t.nom_vern, c.observateurs, s.observateurs, c.dernier_import, s.dernier_import, c.dee_date_derniere_modification, s.dee_date_derniere_modification, c.validite_niveau, s.validite_niveau, c.validite_date_validation, s.validite_date_validation, s.denombrement_min, c.denombrement_min, s.geom, c.geom, s.detail_individus, c.detail_individus
    ORDER BY s.identifiant_origine, c.identifiant_origine, st_distance(s.geom, c.geom)::NUMERIC(10,1) --  Finalement, on trie par id pour pouvoir mieux gérer les triplons, étant donné que de toutes façons on définit une distance max en paramètre dans la fonction.
    ' ;

    -- il est ensuite nécessaire de distinguer les cas : pour les doublons internes strictement identiques on regroupe les obs, pour les doublons externes ou les doublons internes non strictement identiques on garde des paires d'observation
    IF p_controle_interne IS TRUE
        THEN sql_insert =
            '
                )
            --Insertion
            INSERT INTO divers.controle_doublons(jdd_code, jdd_id, organisme_gestionnaire_donnees, cle_obs, identifiant_origine, identifiant_permanent, nb_obs, distance_geom_m, group2_inpn, nom_valide, nom_vern, date_debut, observateurs, denombrement_total, detail_individus, validite_niveau, validite_date_validation, dernier_import, dee_date_derniere_modification)

            -- On prend déjà les obs a priori complétement identiques
            SELECT jdd_code, jdd_id, organisme_gestionnaire_donnees,
            CONCAT(
                string_agg(DISTINCT cle_obs_source::TEXT, '', '' ORDER BY cle_obs_source::TEXT),
                '', '',
                string_agg(DISTINCT cle_obs_cible::TEXT, '','' ORDER BY cle_obs_cible::TEXT)
                )AS cle_obs,

            CONCAT(
                string_agg(DISTINCT identifiant_origine_source, '', '' ORDER BY identifiant_origine_source),
                '', '',
                string_agg(DISTINCT identifiant_origine_cible, '','' ORDER BY identifiant_origine_cible)
                )AS identifiant_origine,

            CONCAT(
                string_agg(DISTINCT identifiant_permanent_source, '', '' ORDER BY identifiant_permanent_source),
                '', '',
                string_agg(DISTINCT identifiant_permanent_cible, '','' ORDER BY identifiant_permanent_cible)
                )AS identifiant_permanent,
            COUNT(DISTINCT cle_obs_cible) + COUNT(DISTINCT cle_obs_source) AS nb_obs,
            distance_geom_m, group2_inpn, nom_valide, nom_vern, date_debut, observateurs, denombrement_total, detail_individus, validite_niveau, validite_date_validation, dernier_import, dee_date_derniere_modification

            FROM liste_doublons_brute
            WHERE observateurs ILIKE ''Même%%'' AND denombrement_total ILIKE ''Même%%'' AND detail_individus ILIKE ''Même%%''

            GROUP BY jdd_code, jdd_id, organisme_gestionnaire_donnees, distance_geom_m, group2_inpn, nom_valide, nom_vern, date_debut, observateurs, denombrement_total, detail_individus, validite_niveau, validite_date_validation, dernier_import, dee_date_derniere_modification

            -- Puis on complète par les obs qui présentent certaines différences sur les observateurs, le denombrement ou le détail des individus, qu''on ne regroupe pas
            UNION
            SELECT jdd_code, jdd_id, organisme_gestionnaire_donnees,
            CONCAT(cle_obs_source, '' | '', cle_obs_cible) AS cle_obs,
            CONCAT(identifiant_origine_source, '' | '', identifiant_origine_cible) AS identifiant_origine,
            CONCAT(identifiant_permanent_source, '' | '', identifiant_permanent_cible) AS identifiant_permanent,
            2 AS nb_obs,
            distance_geom_m, group2_inpn, nom_valide, nom_vern, date_debut, observateurs, denombrement_total, detail_individus, validite_niveau, validite_date_validation, dernier_import, dee_date_derniere_modification

            FROM liste_doublons_brute
            WHERE NOT(observateurs ILIKE ''Même%%'' AND denombrement_total ILIKE ''Même%%'' AND detail_individus ILIKE ''Même%%'')

            ORDER BY identifiant_origine
            ';
        ELSE sql_insert =
            '
            )
            --Insertion
            INSERT INTO divers.controle_doublons(jdd_code, jdd_id, organisme_gestionnaire_donnees, cle_obs, identifiant_origine, identifiant_permanent, nb_obs, distance_geom_m, group2_inpn, nom_valide, nom_vern, date_debut, observateurs, denombrement_total, detail_individus, validite_niveau, validite_date_validation, dernier_import, dee_date_derniere_modification)

            SELECT jdd_code, jdd_id, organisme_gestionnaire_donnees,
            CONCAT(cle_obs_source, '' | '', cle_obs_cible) AS cle_obs,
            CONCAT(identifiant_origine_source, '' | '', identifiant_origine_cible) AS identifiant_origine,
            CONCAT(identifiant_permanent_source, '' | '', identifiant_permanent_cible) AS identifiant_permanent,
            2 AS nb_obs,
            distance_geom_m, group2_inpn, nom_valide, nom_vern, date_debut, observateurs, denombrement_total, detail_individus, validite_niveau, validite_date_validation, dernier_import, dee_date_derniere_modification

            FROM liste_doublons_brute

            ORDER BY identifiant_origine_source, identifiant_origine_cible
            ';
    END IF;

    EXECUTE format(sql_requete_principale) || format(sql_clause_where) || format(sql_group_by) || format(sql_insert)
    USING jdd_id, jdd_id_compares, rayon_en_m ;


    RAISE NOTICE 'Voilà j''ai fini ! N''oublie pas de lancer la requête SELECT * FROM divers.controle_doublons pour voir le résultat de mon analyse' ;

END ;

$_$;


--
-- Name: FUNCTION fonction_controle_doublons(jdd_id text[], rayon_en_m integer, p_controle_interne boolean); Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON FUNCTION divers.fonction_controle_doublons(jdd_id text[], rayon_en_m integer, p_controle_interne boolean) IS 'Fonction permettant de lister dans la table divers.controle_doublons les doublons potentiels associés à un ou plusieurs jeux de données. Le premier argument de la fonction est un tableau contenant le(s) jdd_id de()s jeu(x) de données qu''on souhaite tester. LE deuxième argument correspond à la distance maximale en mètres entre observations pour pouvoir être considféré comme un doublon potentiel. Le troisième argument indique si on souhaite un contrôle interne au sein de(s) jdd testé(s), ou bien externe (le ou les jdd testés par rapport à l''ensemble des autres jdd). Par défaut, les obs éloignées de plus de 10 km ne sont pas prises en compte.';


--
-- Name: nettoyage_valeurs_null_et_espaces(text); Type: FUNCTION; Schema: divers; Owner: -
--

CREATE FUNCTION divers.nettoyage_valeurs_null_et_espaces(jdd_nom text) RETURNS void
    LANGUAGE plpgsql
    AS $_$


DECLARE liste_champs RECORD ;

BEGIN

FOR liste_champs IN (
    SELECT column_name AS champ
    FROM information_schema.columns
    WHERE table_schema = 'fdw'
    AND table_name = $1
    AND column_name <> 'geom' -- l'utilisation de champ nommé 'geom' pose des problèmes d'application de la fonction
    ORDER BY ordinal_position
    )

    LOOP

    EXECUTE

    -- Suppression des espaces
    'UPDATE fdw.' || $1||
    ' SET ' || liste_champs.champ || ' = TRIM(' || liste_champs.champ || ') ;'

    -- Remplacement des '' par des NULL
    'UPDATE fdw.' || $1||
    ' SET ' || liste_champs.champ || ' = NULL
    WHERE ' || liste_champs.champ || '::TEXT = '''' ;'

    ;

    END LOOP;
    RETURN    ;

END ;

$_$;


--
-- Name: FUNCTION nettoyage_valeurs_null_et_espaces(jdd_nom text); Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON FUNCTION divers.nettoyage_valeurs_null_et_espaces(jdd_nom text) IS 'Fonction permettant de remplacer toutes les valeurs '''' par une valeur NULL et également (depuis la version 3) d''appliquer à tous les champs une fonction Trim permettant de supprimer les espaces indésirables en bout de chaîne.';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: cd_nom_disparus; Type: TABLE; Schema: divers; Owner: -
--

CREATE TABLE divers.cd_nom_disparus (
    cd_nom text,
    plus_recente_diffusion text,
    cd_nom_remplacement text,
    cd_raison_suppression text,
    raison_suppression text
);




--
-- Name: controle_coherence_conformite; Type: TABLE; Schema: divers; Owner: -
--

CREATE TABLE divers.controle_coherence_conformite (
    jdd_id text NOT NULL,
    jdd_code text,
    cle_obs integer NOT NULL,
    identifiant_origine text,
    wkt text,
    libelle_test text NOT NULL,
    description_anomalie text,
    date_analyse timestamp with time zone,
    nom_cite text,
    nom_valide text,
    reu text,
    habitat text
);


--
-- Name: TABLE controle_coherence_conformite; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON TABLE divers.controle_coherence_conformite IS 'Table listant les anomalies issues de l''analyse de contrôle et de conformité des tables testées';


--
-- Name: COLUMN controle_coherence_conformite.jdd_id; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.controle_coherence_conformite.jdd_id IS 'jdd_id du jeu de données de l''observation';


--
-- Name: COLUMN controle_coherence_conformite.jdd_code; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.controle_coherence_conformite.jdd_code IS 'jdd_code du jeu de données de l''observation';


--
-- Name: COLUMN controle_coherence_conformite.cle_obs; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.controle_coherence_conformite.cle_obs IS 'cle_obs de l''observation';


--
-- Name: COLUMN controle_coherence_conformite.identifiant_origine; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.controle_coherence_conformite.identifiant_origine IS 'identifiant_origine de l''observation';


--
-- Name: COLUMN controle_coherence_conformite.libelle_test; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.controle_coherence_conformite.libelle_test IS 'Libellé du test';


--
-- Name: COLUMN controle_coherence_conformite.description_anomalie; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.controle_coherence_conformite.description_anomalie IS 'Description détaillée de l''anomalie détectée par le test';


--
-- Name: COLUMN controle_coherence_conformite.date_analyse; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.controle_coherence_conformite.date_analyse IS 'Date à laquelle l''analyse a été réalisée';


--
-- Name: COLUMN controle_coherence_conformite.nom_cite; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.controle_coherence_conformite.nom_cite IS 'Nom de taxon cité';


--
-- Name: COLUMN controle_coherence_conformite.nom_valide; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.controle_coherence_conformite.nom_valide IS 'Nom valide du taxon issu de Taxref';


--
-- Name: COLUMN controle_coherence_conformite.reu; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.controle_coherence_conformite.reu IS 'Statut biogéographique issu de Taxref';


--
-- Name: COLUMN controle_coherence_conformite.habitat; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.controle_coherence_conformite.habitat IS 'Habitat du taxon d''après Taxref';


--
-- Name: controle_doublons; Type: TABLE; Schema: divers; Owner: -
--

CREATE TABLE divers.controle_doublons (
    jdd_code text,
    jdd_id text,
    organisme_gestionnaire_donnees text,
    cle_obs text,
    identifiant_origine text,
    identifiant_permanent text,
    nb_obs integer,
    distance_geom_m numeric,
    group2_inpn text,
    nom_valide text,
    nom_vern text,
    date_debut date,
    observateurs text,
    denombrement_total text,
    detail_individus text,
    validite_niveau text,
    validite_date_validation text,
    dernier_import text,
    dee_date_derniere_modification text
);


--
-- Name: TABLE controle_doublons; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON TABLE divers.controle_doublons IS 'Table stockant le résultat de la fonction de recherche de doublons divers.fonction_controle_doublons(text[], integer, boolean)';


--
-- Name: geometries_uniques; Type: TABLE; Schema: divers; Owner: -
--

CREATE TABLE divers.geometries_uniques (
    id_geom bigint,
    wkt text,
    liste_cle_obs bigint[],
    geom public.geometry(Geometry,2975)
);


--
-- Name: jdd_analyse; Type: TABLE; Schema: divers; Owner: -
--

CREATE TABLE divers.jdd_analyse (
    id integer NOT NULL,
    jdd_nom text,
    ordre integer,
    champ text,
    type text,
    nb_char integer,
    nb_valeurs integer,
    valeurs jsonb,
    date timestamp with time zone
);


--
-- Name: TABLE jdd_analyse; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON TABLE divers.jdd_analyse IS 'Analyse des différents jeux de données testés';


--
-- Name: COLUMN jdd_analyse.id; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.jdd_analyse.id IS 'Identifiant auto-généré';


--
-- Name: COLUMN jdd_analyse.jdd_nom; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.jdd_analyse.jdd_nom IS 'Nom du jeu de données (c''est-à-dire de la table)';


--
-- Name: COLUMN jdd_analyse.ordre; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.jdd_analyse.ordre IS 'Ordre du champ dans le jeu de données';


--
-- Name: COLUMN jdd_analyse.champ; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.jdd_analyse.champ IS 'Nom du champ dans le jdd';


--
-- Name: COLUMN jdd_analyse.type; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.jdd_analyse.type IS 'Type du champ';


--
-- Name: COLUMN jdd_analyse.nb_char; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.jdd_analyse.nb_char IS 'Nombre maximal de caractères';


--
-- Name: COLUMN jdd_analyse.nb_valeurs; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.jdd_analyse.nb_valeurs IS 'Nombre de valeurs uniques du champ';


--
-- Name: COLUMN jdd_analyse.valeurs; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.jdd_analyse.valeurs IS 'Valeurs uniques du champ et occurences';


--
-- Name: COLUMN jdd_analyse.date; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.jdd_analyse.date IS 'Date à laquelle l''analyse a été réalisée';


--
-- Name: jdd_analyse_id_seq; Type: SEQUENCE; Schema: divers; Owner: -
--

CREATE SEQUENCE divers.jdd_analyse_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jdd_analyse_id_seq; Type: SEQUENCE OWNED BY; Schema: divers; Owner: -
--

ALTER SEQUENCE divers.jdd_analyse_id_seq OWNED BY divers.jdd_analyse.id;



--
-- Name: observation_doublon; Type: TABLE; Schema: divers; Owner: -
--

CREATE TABLE divers.observation_doublon (
    cle_obs bigint NOT NULL,
    identifiant_permanent text NOT NULL,
    statut_observation text NOT NULL,
    cd_nom bigint,
    cd_ref bigint,
    version_taxref text,
    nom_cite text NOT NULL,
    denombrement_min integer,
    denombrement_max integer,
    objet_denombrement text,
    type_denombrement text,
    commentaire text,
    date_debut date NOT NULL,
    date_fin date NOT NULL,
    heure_debut time with time zone,
    heure_fin time with time zone,
    date_determination date,
    altitude_min numeric(6,2),
    altitude_moy numeric(6,2),
    altitude_max numeric(6,2),
    profondeur_min numeric(6,2),
    profondeur_moy numeric(6,2),
    profondeur_max numeric(6,2),
    code_idcnp_dispositif text,
    dee_date_derniere_modification timestamp with time zone NOT NULL,
    dee_date_transformation timestamp with time zone NOT NULL,
    dee_floutage text,
    diffusion_niveau_precision text,
    ds_publique text NOT NULL,
    identifiant_origine text,
    jdd_code text,
    jdd_id text,
    jdd_metadonnee_dee_id text NOT NULL,
    jdd_source_id text,
    organisme_gestionnaire_donnees text NOT NULL,
    org_transformation text NOT NULL,
    statut_source text NOT NULL,
    reference_biblio text,
    sensible text DEFAULT 0 NOT NULL,
    sensi_date_attribution timestamp with time zone,
    sensi_niveau text DEFAULT 0 NOT NULL,
    sensi_referentiel text,
    sensi_version_referentiel text,
    validite_niveau text,
    validite_date_validation date,
    precision_geometrie integer,
    nature_objet_geo text,
    descriptif_sujet jsonb,
    donnee_complementaire jsonb,
    geom public.geometry(Geometry,2975),
    odata jsonb,
    organisme_standard text,
    identifiant_permanent_donnee_conservee text NOT NULL,
    date_deplacement timestamp with time zone DEFAULT now() NOT NULL,
    cd_nom_cite bigint
);


--
-- Name: TABLE observation_doublon; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON TABLE divers.observation_doublon IS 'Table stockant les doublons écartés de la table occtax.observation. Les doublons concernés sont les données déjà importées dans Borbonica en base de production, qui seraient écartées à l''occasion de l''import d''un jeu de données plus complet et remplacées par ces nouvelles données. Les doublons repérés avant l''import en base de production ne doivent pas être importés et n''ont pas vocation à figurer dans cette table. La table permet de garder la traçabilité de ces données, notamment dans la perspective d''échanges avec la plateforme nationale SINP';


--
-- Name: COLUMN observation_doublon.identifiant_permanent_donnee_conservee; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.observation_doublon.identifiant_permanent_donnee_conservee IS 'Identifiant permanent de la donnée associée qui est conservée dans la table occtax.observation';


--
-- Name: COLUMN observation_doublon.date_deplacement; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.observation_doublon.date_deplacement IS 'Date à laquelle le doublon a été retiré de la table occtax.observation pour être placé dans la table divers.observation_doublon (automatiquement renseignée)';


--
-- Name: COLUMN observation_doublon.cd_nom_cite; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.observation_doublon.cd_nom_cite IS 'Code du taxon « cd_nom » de TaxRef référençant au niveau national le taxon tel qu''il a été initialement cité par l''observateur dans le champ nom_cite. Le rang taxinomique de la donnée doit être celui de la donnée d''origine. Par défaut, cd_nom = cd_nom_cite. cd_nom peut être modifié dans le cas de la procédure de validation après accord du producteur selon les règles définies dans le protocole régional de validation.';


--
-- Name: observation_hors_zee; Type: TABLE; Schema: divers; Owner: -
--

CREATE TABLE divers.observation_hors_zee (
    cle_obs bigint,
    identifiant_permanent text,
    statut_observation text,
    cd_nom bigint,
    cd_ref bigint,
    version_taxref text,
    nom_cite text,
    denombrement_min integer,
    denombrement_max integer,
    objet_denombrement text,
    type_denombrement text,
    commentaire text,
    date_debut date,
    date_fin date,
    heure_debut time with time zone,
    heure_fin time with time zone,
    date_determination date,
    altitude_min numeric(6,2),
    altitude_moy numeric(6,2),
    altitude_max numeric(6,2),
    profondeur_min numeric(6,2),
    profondeur_moy numeric(6,2),
    profondeur_max numeric(6,2),
    code_idcnp_dispositif text,
    dee_date_derniere_modification timestamp with time zone,
    dee_date_transformation timestamp with time zone,
    dee_floutage text,
    diffusion_niveau_precision text,
    ds_publique text,
    identifiant_origine text,
    jdd_code text,
    jdd_id text,
    jdd_metadonnee_dee_id text,
    jdd_source_id text,
    organisme_gestionnaire_donnees text,
    org_transformation text,
    statut_source text,
    reference_biblio text,
    sensible text,
    sensi_date_attribution timestamp with time zone,
    sensi_niveau text,
    sensi_referentiel text,
    sensi_version_referentiel text,
    validite_niveau text,
    validite_date_validation date,
    precision_geometrie integer,
    nature_objet_geo text,
    descriptif_sujet jsonb,
    donnee_complementaire jsonb,
    geom public.geometry(Geometry,2975),
    odata jsonb,
    organisme_standard text,
    cd_nom_cite bigint
);


--
-- Name: TABLE observation_hors_zee; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON TABLE divers.observation_hors_zee IS 'Table permettant de conserver pour mémoire les données hors ZEE transmises par les producteurs 974. A terme, cela peut être intéressant dans le cadre d''échange avec Mayotte ou d''autres zone de l''Océan Indien.';


--
-- Name: suivi_imports; Type: TABLE; Schema: divers; Owner: -
--

CREATE TABLE divers.suivi_imports (
    id integer NOT NULL,
    nom_jdd text NOT NULL,
    description_detaillee text,
    date_reception date NOT NULL,
    date_import_dev date,
    date_import_prod date,
    nb_donnees integer,
    importateur_initiales text,
    commentaire text,
    jdd_id text[],
    id_organisme integer[]
);


--
-- Name: TABLE suivi_imports; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON TABLE divers.suivi_imports IS 'Table permettant de suivre l''avancement de l''import des jdd dès leur réception (ie avant leur import dans Borbonica)';


--
-- Name: COLUMN suivi_imports.nom_jdd; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.suivi_imports.nom_jdd IS 'nom du jdd sous forme de code (idéalement le futur jdd_code mais cela peut évoluer au fil du temps)';


--
-- Name: COLUMN suivi_imports.date_reception; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.suivi_imports.date_reception IS 'date de réception du jeu de données';


--
-- Name: COLUMN suivi_imports.date_import_dev; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.suivi_imports.date_import_dev IS 'date d''import en base de développement';


--
-- Name: COLUMN suivi_imports.date_import_prod; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.suivi_imports.date_import_prod IS 'date d''import en base de production';


--
-- Name: COLUMN suivi_imports.nb_donnees; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.suivi_imports.nb_donnees IS 'Nombre total de données dans le fichier source fourni par le producteur';


--
-- Name: COLUMN suivi_imports.importateur_initiales; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.suivi_imports.importateur_initiales IS 'Initiales de la personne en charge de l''import';


--
-- Name: COLUMN suivi_imports.commentaire; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.suivi_imports.commentaire IS 'Commentaire libre';


--
-- Name: COLUMN suivi_imports.jdd_id; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.suivi_imports.jdd_id IS 'Liste des jdd_id associés au fichier';


--
-- Name: COLUMN suivi_imports.id_organisme; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON COLUMN divers.suivi_imports.id_organisme IS 'Liste des id_organisme associés au jeu de données';


--
-- Name: suivi_imports_id_seq1; Type: SEQUENCE; Schema: divers; Owner: -
--

CREATE SEQUENCE divers.suivi_imports_id_seq1
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: suivi_imports_id_seq1; Type: SEQUENCE OWNED BY; Schema: divers; Owner: -
--

ALTER SEQUENCE divers.suivi_imports_id_seq1 OWNED BY divers.suivi_imports.id;



--
-- Name: v_doublons_par_jdd_code; Type: VIEW; Schema: divers; Owner: -
--

CREATE VIEW divers.v_doublons_par_jdd_code AS
 SELECT d.jdd_code AS jdd_code_doublons,
    string_agg(DISTINCT o.jdd_code, ' | '::text ORDER BY o.jdd_code) AS jdd_code_donnees_conservees,
    count(DISTINCT d.cle_obs) AS nb_doublons
   FROM (divers.observation_doublon d
     LEFT JOIN occtax.observation o ON ((o.identifiant_permanent = d.identifiant_permanent_donnee_conservee)))
  GROUP BY d.jdd_code
  ORDER BY d.jdd_code;


--
-- Name: VIEW v_doublons_par_jdd_code; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON VIEW divers.v_doublons_par_jdd_code IS 'Vue permettant d''avoir une vision synthétique des doublons écartés par jeu de données';


--
-- Name: v_jdd_analyse; Type: VIEW; Schema: divers; Owner: -
--

CREATE VIEW divers.v_jdd_analyse AS
 WITH r AS (
         SELECT jdd_analyse.jdd_nom,
            jdd_analyse.ordre,
            jdd_analyse.champ,
            jdd_analyse.nb_valeurs,
                CASE
                    WHEN ((jdd_analyse.valeurs)::text ~~* '%Nombre de valeurs%'::text) THEN btrim((jdd_analyse.valeurs)::text, '[]"'::text)
                    ELSE NULL::text
                END AS valeurs_trop_nombreuses,
            (jsonb_array_elements(jdd_analyse.valeurs) ->> 'valeur'::text) AS valeurs,
            (jsonb_array_elements(jdd_analyse.valeurs) ->> 'occurence'::text) AS occurence
           FROM divers.jdd_analyse
          ORDER BY jdd_analyse.jdd_nom, jdd_analyse.ordre
        )
 SELECT r.jdd_nom,
    r.ordre,
    r.champ,
    r.nb_valeurs,
        CASE
            WHEN (r.valeurs_trop_nombreuses IS NOT NULL) THEN r.valeurs_trop_nombreuses
            ELSE string_agg((((r.valeurs || ' ('::text) || r.occurence) || ' obs.)'::text), ' | '::text)
        END AS valeurs_occurence
   FROM r
  GROUP BY r.jdd_nom, r.ordre, r.champ, r.nb_valeurs, r.valeurs_trop_nombreuses
  ORDER BY r.jdd_nom, r.ordre;


--
-- Name: VIEW v_jdd_analyse; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON VIEW divers.v_jdd_analyse IS 'Vue permettant de visualiser de manière lisible et agrégée les listes de valeur par champ pour les tables dont l''analyse a été réalisée';


--
-- Name: v_liste_cadre; Type: VIEW; Schema: divers; Owner: -
--

CREATE VIEW divers.v_liste_cadre AS
 SELECT c.cadre_id,
    c.libelle,
    c.description,
    c.ayants_droit,
    c.date_lancement,
    c.date_cloture,
    string_agg(DISTINCT jdd.jdd_code, ' | '::text) AS liste_jdd,
    count(DISTINCT o.cle_obs) AS nb_obs,
    ('https://inpn.mnhn.fr/espece/cadre/'::text || c.cadre_id) AS url_cadre
   FROM ((occtax.cadre c
     LEFT JOIN occtax.jdd ON ((jdd.jdd_cadre = c.cadre_id)))
     LEFT JOIN occtax.observation o ON ((o.jdd_id = jdd.jdd_id)))
  GROUP BY c.cadre_id, c.libelle, c.description, c.ayants_droit, c.date_lancement, c.date_cloture
  ORDER BY c.libelle;


--
-- Name: VIEW v_liste_cadre; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON VIEW divers.v_liste_cadre IS 'Vue listant les différents cadre d''acquisition de données et les jeux de données associées.';


--
-- Name: v_liste_jdd_non_importes; Type: VIEW; Schema: divers; Owner: -
--

CREATE VIEW divers.v_liste_jdd_non_importes AS
 SELECT suivi_imports.importateur_initiales,
        CASE
            WHEN (suivi_imports.date_import_dev IS NULL) THEN 'Non importé'::text
            WHEN ((suivi_imports.date_import_dev IS NOT NULL) AND (suivi_imports.date_import_prod IS NULL)) THEN 'Importé en dév'::text
            ELSE NULL::text
        END AS statut,
    count(DISTINCT suivi_imports.nom_jdd) AS nb_jdd,
    sum(suivi_imports.nb_donnees) AS nb_donnees,
    string_agg(concat('- ', suivi_imports.nom_jdd, ' (reçu le ', suivi_imports.date_reception, ', ', suivi_imports.nb_donnees, ' données)'), chr(10)) AS liste_jdd
   FROM divers.suivi_imports
  WHERE ((suivi_imports.date_import_dev IS NULL) OR (suivi_imports.date_import_prod IS NULL))
  GROUP BY suivi_imports.importateur_initiales,
        CASE
            WHEN (suivi_imports.date_import_dev IS NULL) THEN 'Non importé'::text
            WHEN ((suivi_imports.date_import_dev IS NOT NULL) AND (suivi_imports.date_import_prod IS NULL)) THEN 'Importé en dév'::text
            ELSE NULL::text
        END
  ORDER BY suivi_imports.importateur_initiales,
        CASE
            WHEN (suivi_imports.date_import_dev IS NULL) THEN 'Non importé'::text
            WHEN ((suivi_imports.date_import_dev IS NOT NULL) AND (suivi_imports.date_import_prod IS NULL)) THEN 'Importé en dév'::text
            ELSE NULL::text
        END;


--
-- Name: VIEW v_liste_jdd_non_importes; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON VIEW divers.v_liste_jdd_non_importes IS 'Vue permettant de suivre les jeux de donénes dont l''import n''est pas terminé';



--
-- Name: v_suivi_imports; Type: VIEW; Schema: divers; Owner: -
--

CREATE VIEW divers.v_suivi_imports AS
 SELECT '2. En prod.'::text AS statut,
    string_agg(DISTINCT jdd.jdd_id, ', '::text) AS liste_jdd_id,
    string_agg(DISTINCT jdd.jdd_code, ', '::text) AS liste_jdd,
    count(DISTINCT jdd.jdd_code) AS nb_jdd,
        CASE
            WHEN (min(i.date_reception) <> max(i.date_reception)) THEN concat('Données reçues entre le ', min(i.date_reception), ' et le ', max(i.date_reception))
            ELSE (min(i.date_reception))::text
        END AS date_reception,
    (date_trunc('second'::text, premier_import.dee_date_transformation))::timestamp without time zone AS date_premier_import,
    min(i.nb_donnees_source) AS nb_donnees_source,
    concat(a.prenom, ' ', a.nom) AS importateur
   FROM (((occtax.jdd
     LEFT JOIN ( SELECT observation.jdd_id,
            observation.dee_date_transformation
           FROM occtax.observation
          GROUP BY observation.jdd_id, observation.dee_date_transformation) premier_import ON ((premier_import.jdd_id = jdd.jdd_id)))
     LEFT JOIN occtax.jdd_import i ON ((i.jdd_id = jdd.jdd_id)))
     LEFT JOIN gestion.acteur a ON ((a.id_acteur = i.acteur_importateur)))
  GROUP BY premier_import.dee_date_transformation, a.prenom, a.nom
UNION
 SELECT
        CASE
            WHEN (suivi_imports.date_import_dev IS NULL) THEN '0. Non importé'::text
            ELSE '1. En dev.'::text
        END AS statut,
    array_to_string(suivi_imports.jdd_id, ','::text) AS liste_jdd_id,
    suivi_imports.nom_jdd AS liste_jdd,
    COALESCE(cardinality(suivi_imports.jdd_id), 1) AS nb_jdd,
    (suivi_imports.date_reception)::text AS date_reception,
    suivi_imports.date_import_dev AS date_premier_import,
    suivi_imports.nb_donnees AS nb_donnees_source,
        CASE
            WHEN (lower(btrim(suivi_imports.importateur_initiales)) = 'vlt'::text) THEN 'Valentin LE TELLIER'::text
            WHEN (lower(btrim(suivi_imports.importateur_initiales)) = 'jcn'::text) THEN 'Jean-Cyrille NOTTER'::text
            ELSE 'Inconnu'::text
        END AS importateur
   FROM divers.suivi_imports
  WHERE (suivi_imports.date_import_prod IS NULL)
  ORDER BY 1, 6, 5;


--
-- Name: VIEW v_suivi_imports; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON VIEW divers.v_suivi_imports IS 'Vue permettant de suivre l''avancement des opérations d''import, une opération pouvant concerner l''import simultané de plusieurs jeux de données.';

--
-- Name: v_taille_tables; Type: VIEW; Schema: divers; Owner: -
--

CREATE VIEW divers.v_taille_tables AS
 SELECT n.nspname AS schema,
    c.relname AS relation,
    pg_size_pretty(pg_relation_size((c.oid)::regclass)) AS taille
   FROM (pg_class c
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE (n.nspname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name]))
  ORDER BY (pg_relation_size((c.oid)::regclass)) DESC;


--
-- Name: VIEW v_taille_tables; Type: COMMENT; Schema: divers; Owner: -
--

COMMENT ON VIEW divers.v_taille_tables IS 'Vue indiquant la taille occupée par les relations de la base de données (vues matérialisées et tables) à l''exception des schémas pg_catalog et information_schema ;';



--
-- Name: jdd_analyse id; Type: DEFAULT; Schema: divers; Owner: -
--

ALTER TABLE ONLY divers.jdd_analyse ALTER COLUMN id SET DEFAULT nextval('divers.jdd_analyse_id_seq'::regclass);




--
-- Name: suivi_imports id; Type: DEFAULT; Schema: divers; Owner: -
--

ALTER TABLE ONLY divers.suivi_imports ALTER COLUMN id SET DEFAULT nextval('divers.suivi_imports_id_seq1'::regclass);


--
-- Name: controle_coherence_conformite fdw_controle_coherence_conformite_pk; Type: CONSTRAINT; Schema: divers; Owner: -
--

ALTER TABLE ONLY divers.controle_coherence_conformite
    ADD CONSTRAINT fdw_controle_coherence_conformite_pk PRIMARY KEY (cle_obs, libelle_test);


--
-- Name: jdd_analyse jdd_analyse_pk; Type: CONSTRAINT; Schema: divers; Owner: -
--

ALTER TABLE ONLY divers.jdd_analyse
    ADD CONSTRAINT jdd_analyse_pk PRIMARY KEY (id);



--
-- Name: observation_doublon observation_pkey; Type: CONSTRAINT; Schema: divers; Owner: -
--

ALTER TABLE ONLY divers.observation_doublon
    ADD CONSTRAINT observation_pkey PRIMARY KEY (identifiant_permanent, identifiant_permanent_donnee_conservee);


--
-- Name: suivi_imports suivi_imports_pkey; Type: CONSTRAINT; Schema: divers; Owner: -
--

ALTER TABLE ONLY divers.suivi_imports
    ADD CONSTRAINT suivi_imports_pkey PRIMARY KEY (nom_jdd);

