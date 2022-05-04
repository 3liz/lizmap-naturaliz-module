
-- Renommage de la fonction de suppression des données importées
ALTER FUNCTION occtax.import_delete_imported_observations(text, text)
RENAME TO occtax.import_supprimer_observations_importees;

COMMENT ON FUNCTION occtax.import_supprimer_observations_importees(text, text)
IS 'Suppression des données importées, utile si un souci a été rencontré lors de la procédure. Elle attend en paramètre la table temporaire et le JDD UUID.'
;

-- Correction de la vue qui montre la liste des JDD et imports
DROP VIEW IF EXISTS occtax.v_import_web_liste;
CREATE OR REPLACE VIEW occtax.v_import_web_liste AS
SELECT
    (odata->>'import_time')::timestamp(0) AS date_import,
    jdd_metadonnee_dee_id AS jdd,
    count(cle_obs) AS nombre_observations,
    odata->>'import_temp_table' AS code_import,
    odata->>'import_login' AS login_import,
    ST_Buffer(ST_ConvexHull(ST_Collect(ST_Centroid(geom))), 1)::geometry(POLYGON, {$SRID}) AS geom
FROM occtax.observation
WHERE odata ? 'import_login' AND odata ? 'import_time'
GROUP BY odata, jdd_metadonnee_dee_id
ORDER BY date_import, code_import, login_import;
;

COMMENT ON VIEW occtax.v_import_web_liste
IS 'Vue utile pour lister les imports effectués par les utilisateurs depuis l''interface Web, à partir de fichiers CSV'
;


-- Fonction pour valider les observations importées, c'est-à-dire enlever leur statut temporaire
-- et les rendre visibles dans l'application
DROP FUNCTION IF EXISTS occtax.import_valider_observations_importees(text, text);
CREATE OR REPLACE FUNCTION occtax.import_valider_observations_importees(
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
    WHERE jdd_metadonnee_dee_id = _jdd_uid
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

COMMENT ON FUNCTION occtax.import_valider_observations_importees(text, text)
IS 'Validation des observations importées pour la table temporaire et le JDD UUID fournis. Elle seront alors disponibles dans l''application';
;
