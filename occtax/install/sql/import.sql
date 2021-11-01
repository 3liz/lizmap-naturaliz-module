DROP TABLE IF EXISTS occtax.critere_conformite;
CREATE TABLE occtax.critere_conformite (
    id serial not null PRIMARY KEY,
    code text NOT NULL,
    libelle text NOT NULL,
    description text,
    condition text NOT NULL,
    table_jointure text,
    ordre smallint,
    CONSTRAINT critere_conformite_unique_code UNIQUE (code)
);

COMMENT ON TABLE occtax.critere_conformite
IS 'Liste les critères de conformité des données à importer dans la table occtax.observation'
;


DROP FUNCTION IF EXISTS occtax.test_conformite_observation();
CREATE OR REPLACE FUNCTION occtax.test_conformite_observation(table_temporaire regclass)
RETURNS TABLE (
    id_critere text,
    code text,
    libelle text,
    description text,
    condition text,
    nb_lines integer,
    ids integer[]
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
        ids integer[]
    ) ON COMMIT DROP
    ;

    -- On boucle sur les criteres
    FOR var_id_critere, var_code, var_libelle, var_description, var_condition, var_table_jointure IN
        SELECT c.id_critere, c.code, c.libelle, c.description, c.condition, c.table_jointure
        FROM occtax.critere_conformite AS c
        ORDER BY c.id_critere

    LOOP
        sql_template := '
        INSERT INTO temp_results
        SELECT
            %s AS id_critere, %s AS code,
            %s AS libelle, %s AS description, %s AS condition,
            count(o.id) AS nb_lines, array_agg(o.id) AS ids
        FROM %s AS o
        ';
        sql_text := format(
            sql_template,
            var_id_critere, quote_literal(var_code),
            quote_literal(var_libelle), quote_nullable(var_description),
            quote_literal(var_condition),
            table_temporaire
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

        -- Log SQL
        RAISE NOTICE '%' , sql_text;

        -- On récupère les données
        EXECUTE sql_text;

    END LOOP;

    RETURN QUERY SELECT * FROM temp_results;

END
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100
;


COMMENT ON FUNCTION occtax.test_conformite_observation(regclass)
IS 'Tester la conformité des observations contenues dans la table fournie en paramètre selon les critères stockés dans la table occtax.critere_conformite'
;


-- Table pour le modèle d'import
DROP TABLE IF EXISTS occtax.observation_temporaire;
CREATE TABLE occtax.observation_temporaire (
    identifiant_permanent text,
    statut_observation text,

    cd_nom text,
    version_taxref text,
    nom_cite text,

    denombrement_min text,
    denombrement_max text,
    objet_denombrement text,
    type_denombrement text,
    commentaire text,

    date_debut text,
    date_fin text,
    heure_debut text,
    heure_fin text,
    date_determination text,

    altitude_min text,
    altitude_moy text,
    altitude_max text,
    profondeur_min text,
    profondeur_moy text,
    profondeur_max text,

    code_idcnp_dispositif text,
    dee_floutage text,
    diffusion_niveau_precision text,
    ds_publique text,
    identifiant_origine text,

    statut_source text,
    reference_biblio text,
    sensible text,
    sensi_date_attribution text,
    sensi_niveau text,
    sensi_referentiel text,
    sensi_version_referentiel text,

    longitude text,
    latitude text,
    precision_geometrie text,
    nature_objet_geo text
);

COMMENT ON TABLE occtax.observation_temporaire
IS 'Table utilisée pour créer les tables temporaires pour les imports via fichier CSV. Elle respecte la structure de la table occtax.observation, sauf certains champs manquants ou avec un type adapté au CSV.
Tous les champs sont en text pour faciliter l''import: le test de format est réalisé après import.'
;

-- Ajout des contraintes sur les champs issus de la table occtax.observation

-- NOT NULL
INSERT INTO occtax.critere_conformite (code, libelle, condition)
VALUES
('obs_statut_observation_not_null', 'statut_observation est vide', $$statut_observation IS NOT NULL$$),
('obs_cd_nom_not_null', 'cd_nom est vide', $$cd_nom IS NOT NULL$$),
('obs_version_taxref_not_null', 'version_taxref est vide', $$version_taxref IS NOT NULL$$),
('obs_nom_cite_not_null', 'nom_cite est vide', $$nom_cite IS NOT NULL$$),
('obs_date_debut_not_null', 'date_debut est vide', $$date_debut IS NOT NULL$$),
('obs_date_fin_not_null', 'date_fin est vide', $$date_fin IS NOT NULL$$),
('obs_ds_publique_not_null', 'ds_publique est vide', $$ds_publique IS NOT NULL$$),
('obs_identifiant_origine_not_null', 'identifiant_origine est vide', $$identifiant_origine IS NOT NULL$$),
('obs_statut_source_not_null', 'statut_source est vide', $$statut_source IS NOT NULL$$),
('obs_sensible_not_null', 'sensible est vide', $$sensible IS NOT NULL$$),
('obs_sensi_niveau_not_null', 'sensi_niveau est vide', $$sensi_niveau IS NOT NULL$$),
('obs_longitude_not_null', 'longitude est vide', $$longitude IS NOT NULL$$),
('obs_latitude_not_null', 'latitude est vide', $$latitude IS NOT NULL$$),
('obs_nature_objet_geo_not_null', 'nature_objet_geo est vide', $$nature_objet_geo IS NOT NULL$$)
ON CONFLICT ON CONSTRAINT critere_conformite_unique_code DO NOTHING
;

-- CHECK
INSERT INTO occtax.critere_conformite (code, libelle, description, condition)
VALUES
('obs_statut_source_valide', 'Statut source invalide', 'Le champ statut_source doit correspondre à la nomenclature', $$( statut_source IN ( 'Te', 'Co', 'Li', 'NSP' ) )$$),
('obs_reference_biblio_valide', 'Référence bibliographique manquante', 'Le champ reference_biblio doit être renseignée si le champ statut_source vaut Li', $$( (statut_source = 'Li' AND reference_biblio IS NOT NULL) OR statut_source != 'Li' )$$),
('obs_ds_publique_valide', 'DS Publique invalide', 'Le champ ds_publique doit correspondre à la nomenclature', $$( ds_publique IN ( 'Pu', 'Re', 'Ac', 'Pr', 'NSP' ) )$$),
('obs_statut_observation_valide', 'Statut de l''observation invalide', 'Le champ statut_observation', $$( statut_observation IN ( 'Pr', 'No', 'NSP' ) )$$),
('obs_objet_denombrement_valide', 'Objet du dénombrement invalide', 'Le champ objet_denombrement doit être différent de NSP si les champs denombrement_min ou denombrement_max sont renseignés', $$(
    ( denombrement_min IS NOT NULL AND denombrement_max IS NOT NULL AND objet_denombrement IN ('COL', 'CPL', 'HAM', 'IND', 'NID', 'NSP', 'PON', 'SURF', 'TIGE', 'TOUF')  )
    OR (denombrement_min IS NULL AND denombrement_max IS NULL AND Coalesce(objet_denombrement, 'NSP') = 'NSP')
)$$),
('obs_type_denombrement_valide', 'Type de dénombrement', 'Le champ type_denombrement doit correspondre à la nomenclature', $$( type_denombrement IN ('Co', 'Es', 'Ca', 'NSP') )$$),
('obs_diffusion_niveau_precision_valide', 'Diffusion niveau précision', 'Le champ diffusion_niveau_precision doit correspondre à la nomenclature', $$( diffusion_niveau_precision IS NULL OR diffusion_niveau_precision IN ( '0', '1', '2', '3', '4', '5', 'm01', 'm02' ) )$$),
('obs_dates_valide', 'Dates de début et de fin invalides', 'Les champs date_debut, heure_debut, date_fin et heure_fin doivent avoir des valeurs cohérentes', $$(date_debut <= date_fin AND date_debut + heure_debut <= date_fin + heure_fin)$$),
('obs_precision_geometrie_valide', 'Précision de la géométrie invalide', 'Le champ precision_geometrie doit être positif ou vide', $$( precision_geometrie IS NULL OR precision_geometrie > 0 )$$),
('obs_altitude_min_max_valide', 'Altitudes invalides', 'Les champs altitude_min et altitude_max doivent être cohérents', $$( Coalesce( altitude_min, 0 ) <= Coalesce( altitude_max, 0 ) )$$),
('obs_profondeur_min_max_valide', 'Profondeurs invalides', 'Les champs profondeur_min et profondeur_max doivent être cohérents', $$( Coalesce( profondeur_min, 0 ) <= Coalesce( profondeur_max, 0 ) )$$),
('obs_dee_floutage_valide', 'Dee floutage invalide', 'Le champ dee_floutage doit contenir OUI, NON ou être vide', $$( dee_floutage IS NULL OR dee_floutage IN ('OUI', 'NON') )$$),
('obs_dee_date_derniere_modification_valide', 'DEE date de dernière modification invalide', 'Le champ dee_date_derniere_modification doit être supérieur au champ dee_date_transformation', $$( dee_date_derniere_modification >= dee_date_transformation )$$),
('obs_dee_floutage_ds_publique_valide', 'DEE floutage invalide', 'Le champ dee_floutage doit être renseigné si le champ ds_publique vaut Pr', $$( ds_publique != 'Pr' OR ( ds_publique = 'Pr' AND dee_floutage IS NOT NULL ) )$$),
('obs_sensi_date_attribution_valide', 'Sensi date attribution invalide', 'Le champ sensi_date_attribution doit être renseigné si le champ sensi_niveau est différent de 0', $$( ( sensi_date_attribution IS NULL AND Coalesce(sensi_niveau, '0') = '0' ) OR  ( sensi_date_attribution IS NOT NULL  ) )$$),
('obs_sensi_niveau_valide', 'Sensi niveau valide erroné', 'Le champ sensi_niveau peut seulement prendre les valeurs suivantes: 0, 1, 2, 3, 4, 5, m01 ou m02', $$( sensi_niveau IN ( '0', '1', '2', '3', '4', '5', 'm01', 'm02' ) )$$),
('obs_sensi_referentiel_valide', '', '', $$( ( sensi_niveau != '0' AND sensi_referentiel IS NOT NULL) OR sensi_niveau = '0' )$$),
('obs_sensi_version_referentiel_valide', 'Sensi version referentiel invalide', 'Le champ sensi_version_referentiel doit être renseigné si le champ sensi_niveau est différent de 0', $$( ( sensi_niveau != '0' AND sensi_version_referentiel IS NOT NULL) OR sensi_niveau = '0' )$$),
('obs_version_taxref_valide', 'Version du TAXREF invalide', 'La version du TAXREF doit être renseigné si le cd_nom est positif', $$(cd_nom IS NULL OR ( cd_nom IS NOT NULL AND cd_nom > 0 AND version_taxref IS NOT NULL) OR ( cd_nom IS NOT NULL AND cd_nom < 0 ))$$)
ON CONFLICT ON CONSTRAINT critere_conformite_unique_code DO NOTHING
;
