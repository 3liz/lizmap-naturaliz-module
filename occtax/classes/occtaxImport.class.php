<?php

/**
 * @package   lizmap
 * @subpackage occtax
 * @author    Michaël Douchin
 * @copyright 2014 3liz
 * @link      http://3liz.com
 * @license    All rights reserved
 */

/**
 * Contains the tools to import observation data from CSV files
 */
class occtaxImport
{
    // CSV file
    protected $csv_file;

    // CSV file for additional attributes
    protected $csv_attributes_file;

    // CSV separator
    protected $csv_separator = ',';

    // All possible fields
    protected $target_fields = array(
        'id_sinp_occtax',
        'statut_observation',

        'cd_nom',
        'cd_ref',
        'version_taxref',
        'nom_cite',

        'observateurs',
        'determinateurs',

        'denombrement_min',
        'denombrement_max',
        'objet_denombrement',
        'type_denombrement',
        'commentaire',

        'date_debut',
        'date_fin',
        'heure_debut',
        'heure_fin',
        'date_determination',

        'altitude_min',
        'altitude_moy',
        'altitude_max',
        'profondeur_min',
        'profondeur_moy',
        'profondeur_max',

        'code_idcnp_dispositif',
        'dee_floutage',
        'diffusion_niveau_precision',
        'ds_publique',
        'id_origine',

        'jdd_id',
        'statut_source',
        'reference_biblio',

        'sensi_date_attribution',
        'sensi_niveau',
        'sensi_referentiel',
        'sensi_version_referentiel',

        'validation_niv_val',
        'validation_date_ctrl',
        'validation_ech_val',
        'validation_typ_val',
        'validation_validateur',

        'longitude',
        'latitude',
        'wkt',
        'precision_geometrie',
        'nature_objet_geo',

        // descriptif du sujet
        // 1er item
        'obs_technique',
        'occ_etat_biologique',
        'occ_naturalite',
        'occ_sexe',
        'occ_stade_de_vie',
        'occ_denombrement_min',
        'occ_denombrement_max',
        'occ_type_denombrement',
        'occ_statut_biogeographique',
        'occ_statut_biologique',
        'occ_comportement',
        'preuve_existante',
        'url_preuve_numerique',
        'preuve_non_numerique',
        'obs_contexte',
        'obs_description',
        'occ_methode_determination',
        // Deuxième item possible
        'obs_technique_2',
        'occ_etat_biologique_2',
        'occ_naturalite_2',
        'occ_sexe_2',
        'occ_stade_de_vie_2',
        'occ_denombrement_min_2',
        'occ_denombrement_max_2',
        'occ_type_denombrement_2',
        'occ_statut_biogeographique_2',
        'occ_statut_biologique_2',
        'occ_comportement_2',
        'preuve_existante_2',
        'url_preuve_numerique_2',
        'preuve_non_numerique_2',
        'obs_contexte_2',
        'obs_description_2',
        'occ_methode_determination_2',
        // Troisième item possible
        'obs_technique_3',
        'occ_etat_biologique_3',
        'occ_naturalite_3',
        'occ_sexe_3',
        'occ_stade_de_vie_3',
        'occ_denombrement_min_3',
        'occ_denombrement_max_3',
        'occ_type_denombrement_3',
        'occ_statut_biogeographique_3',
        'occ_statut_biologique_3',
        'occ_comportement_3',
        'preuve_existante_3',
        'url_preuve_numerique_3',
        'preuve_non_numerique_3',
        'obs_contexte_3',
        'obs_description_3',
        'occ_methode_determination_3',
    );

    // Mandatory fields
    protected $mandatory_fields = array(
        'id_origine',
        'cd_nom',
        'nom_cite',
        'version_taxref',
        'date_debut',
        'date_fin',
        'statut_observation',
        'ds_publique',
        'statut_source',
        'nature_objet_geo',
    );

    // Mandatory fields for additional attributes
    protected $attributes_mandatory_fields = array(
        'nom_champ_du_csv',
        'nom_attribut',
        'definition_attribut',
        'thematique_attribut',
        'type_attribut',
        'unite_attribut',
    );

    // Corresponding fields
    protected $corresponding_fields = array();

    // Additional found fields
    protected $additional_fields = array();

    // CSV parsed data
    protected $data;

    // CSV parsed data for additional attributes
    public $attributeData = array();

    // CSV header columns
    protected $header;

    // CSV header columns for attributes
    protected $attributeHeader;

    // Login
    protected $login;

    // Identifiant du jeu de données
    protected $jdd_uid;

    // Temporary table to store the content of the CSV file
    protected $temporary_table;

    // SRID of the source CSV geometries
    protected $source_srid;

    // Geometry source type
    protected $geometry_format;

    /**
     * Constructor of the import class.
     *
     * @param string  $csv_file File path of the CSV
     * @param integer $source_srid SRID of the given geometries (integer, ex: 4326)
     * @param string  $geometry_format Format of the given geometries: lonlat or wkt
     * @param string  $csv_attributes_file File path of the optional attributes CSV
     */
    public function __construct($csv_file, $source_srid='4326', $geometry_format='lonlat', $csv_attributes_file=Null)
    {
        // Set the csv_file property
        $this->csv_file = $csv_file;
        $this->csv_attributes_file = $csv_attributes_file;

        // Get the user login
        $login = null;
        $user = jAuth::getUserSession();
        if ($user) {
            $login = $user->login;
        }
        $this->login = $login;

        // Set the temporary table name
        $time = time();
        $this->temporary_table = 'temp_'.$time;

        $this->source_srid = $source_srid;
        $this->geometry_format = $geometry_format;
    }

    /**
     * Runs the needed check on the observation CSV structure
     *
     * @param string $csv_content Content of the observation CSV file
     */
    public function checkStructure()
    {
        $status = true;
        $message = '';

        // Get the csv header (first line)
        $header = $this->parseCsv($this->csv_file, 0, 1);

        // Check header
        if (!is_array($header) || count($header) != 1) {
            return array(
                false,
                jLocale::get("occtax~import.csv.wrong.header")
            );
        }
        $header = $header[0];
        $this->header = $header;

        // Check mandatory fields are present
        $missing_mandatory_fields = array();
        foreach ($this->mandatory_fields as $field) {
            if (!in_array($field, $header)) {
                $missing_mandatory_fields[] = $field;
            }
        }

        // find additional fields and corresponding fields
        $additional_fields = array();
        $corresponding_fields = array();
        foreach ($header as $field) {
            if (!in_array($field, $this->target_fields)) {
                $additional_fields[] = $field;
            } else {
                $corresponding_fields[] = $field;
            }
        }

        // Check geometry fields
        $hasNeededGeometryColumns = false;
        if ($this->geometry_format == 'lonlat' && in_array('longitude', $header) && in_array('latitude', $header)) {
            $hasNeededGeometryColumns = true;
            if (!in_array('longitude', $corresponding_fields)) {
                $corresponding_fields[] = 'longitude';
            }
            if (!in_array('latitude', $corresponding_fields)) {
                $corresponding_fields[] = 'latitude';
            }
        } elseif ($this->geometry_format == 'wkt' && in_array('wkt', $header)) {
            $hasNeededGeometryColumns = true;
            if (!in_array('wkt', $corresponding_fields)) {
                $corresponding_fields[] = 'wkt';
            }
        }
        if (!$hasNeededGeometryColumns) {
            if ($this->geometry_format == 'lonlat') {
                $neededGeometryFields = array('longitude', 'latitude');
            } elseif ($this->geometry_format == 'wkt') {
                $neededGeometryFields = array('wkt');
            }
            $message = \jLocale::get(
                'occtax~import.csv.mandatory.geometry.fields.missing',
                array(implode(', ', $neededGeometryFields))
            );
            $status = false;

            return array($status, $message);
        }

        $this->additional_fields = $additional_fields;
        $this->corresponding_fields = $corresponding_fields;

        if (count($missing_mandatory_fields) > 0) {
            $message = jLocale::get("occtax~import.csv.mandatory.fields.missing");
            $message .= ': '.implode(', ', $missing_mandatory_fields);
            $status = false;
            return array($status, $message);
        }

        // Check that the first line (header) contains the same number of columns
        // that the second (data) to avoid errors
        $first_line = $this->parseCsv($this->csv_file, 1, 1);
        if (empty($first_line) || count($first_line[0]) != count($header)) {
            $message = jLocale::get("occtax~import.csv.columns.number.mismatch");
            $status = false;
            return array($status, $message);
        }

        // Validate first line geometry format
        if ($this->geometry_format == 'wkt') {
            $wktColIndex = array_search('wkt', $header);
            $wkt = $first_line[0][$wktColIndex];
            if (!($this->isValidWkt($wkt))) {
                $message = \jLocale::get(
                    'occtax~import.csv.first.line.wkt.wrong.value',
                    array($wkt)
                );
                $status = false;

                return array($status, $message);
            }
        }


        return array($status, $message);
    }

    /**
     * Runs the needed check on the CSV structure
     */
    public function checkAdditionalAttributesStructure()
    {
        $status = true;
        $message = '';

        // Get the csv header (first line)
        $attributeHeader = $this->parseCsv($this->csv_attributes_file, 0, 1);

        // Check header
        if (!is_array($attributeHeader) || count($attributeHeader) != 1) {
            return array(
                false,
                jLocale::get("occtax~import.csv.wrong.header")
            );
        }
        $attributeHeader = $attributeHeader[0];
        $this->attributeHeader = $attributeHeader;

        // Check mandatory fields are present
        $missing_mandatory_fields = array();
        foreach ($this->attributes_mandatory_fields as $field) {
            if (!in_array($field, $attributeHeader)) {
                $missing_mandatory_fields[] = $field;
            }
        }

        if (count($missing_mandatory_fields) > 0) {
            $message = jLocale::get("occtax~import.csv.mandatory.fields.missing.attributes");
            $message .= ': '.implode(', ', $missing_mandatory_fields);
            $status = false;
            return array($status, $message);
        }

        // Check that the first line (header) contains the same number of columns
        // that the second (first line of data) to avoid errors
        $first_line = $this->parseCsv($this->csv_attributes_file, 1, 1);
        if (empty($first_line) || count($first_line[0]) != count($attributeHeader)) {
            $message = jLocale::get("occtax~import.csv.columns.number.mismatch.attributes");
            $status = false;
            return array($status, $message);
        }

        // Validate all the lines (limit to 30 to avoid big imports)
        $i = 0;
        // TODO

        return array($status, $message);
    }

    /**
     * Set the additional attributes data property
     *
     */
    public function setAdditionalAttributesData()
    {
        // Avoid the first line which contains the CSV header
        // We use this method as the additional attributes CSV is light
        $attributeData = $this->parseCsv($this->csv_attributes_file, 1);

        $formattedData = array();
        foreach($attributeData as $line) {
            $i = 0;
            $lineData = array();
            foreach($line as $columnValue) {
                $lineData[$this->attributeHeader[$i]] = trim($columnValue);
                ++$i;
            }
            $formattedData[] = $lineData;
        }
        $this->attributeData = $formattedData;
    }

    /**
     * Parse the CSV raw content and return its data
     *
     * This method must not be used to import heavy data,
     * as it will have high memory footprint
     *
     * @param string $csv_file CSV file full path
     * @param int    $offset   Number of lines to avoid from the beginning
     * @param int    $limit    Number of lines to parse from the beginning. Optional.
     *
     * @return array Array on array containing the data
     */
    protected function parseCsv($csv_file, $offset = 0, $limit = -1)
    {
        $csv_data = array();
        $row = 1;
        $kept = 0;
        if (($handle = fopen($csv_file, 'r')) !== FALSE) {
            while (($data = fgetcsv($handle, 1000, $this->csv_separator)) !== FALSE) {
                // Manage offset
                if ($row > $offset) {
                    // Add data to the table
                    $csv_data[] = $data;
                    $kept++;

                    // Stop after n lines if asked
                    if ($limit > 0 && $kept >= $limit) {
                        break;
                    }
                }
                $row++;
            }
            fclose($handle);
        }

        return $csv_data;
    }

    /**
     * Query the database with SQL text and parameters
     *
     * @param string $sql SQL text to run
     * @param array $params Array of the parameters values
     *
     * @return The resulted data
     */
    private function query($sql, $params)
    {
        $cnx = jDb::getConnection('naturaliz_virtual_profile');
        $cnx->beginTransaction();
        $data = array();
        try {
            $resultset = $cnx->prepare($sql);
            $execute = $resultset->execute($params);
            if ($resultset && $resultset->id() === false) {
                $errorCode = $cnx->errorCode();

                throw new Exception($errorCode);
            }
            $data = $resultset->fetchAll();
            $cnx->commit();

        } catch (Exception $e) {
            $cnx->rollback();
            $data = null;
            \jLog::log($e->getMessage());
        }

        return $data;
    }


    /**
     * Create the temporary table in the database
     *
     * @return null|array Not null content if success.
     */
    public function createTemporaryTables()
    {
        $params = array();

        // Drop tables
        $sql = 'DROP TABLE IF EXISTS ';
        $sql .= '"'.$this->temporary_table.'_source", ';
        $sql .= '"'.$this->temporary_table.'_target"';
        $params = array();
        $data = $this->query($sql, $params);

        // Create temporary table to store the CSV source data and the formatted imported data
        $tables = array(
            'source' => $this->header,
            'target' => $this->target_fields,
        );
        foreach ($tables as $name => $columns) {
            $sql = 'CREATE TABLE "'.$this->temporary_table.'_'.$name.'" (';
            $sql .= ' temporary_id serial';
            $comma = ',';
            foreach ($columns as $column) {
                $sql .= $comma.'"'.$column.'" text';
            }
            if (preg_match('/"odata" text/', $sql)) {
                // Replace odata type text into json
                $sql = str_replace('"odata" text', '"odata" json', $sql);
            } else {
                // Add odata field it if not present
                $sql.= ', "odata" json';
            }
            $sql .= ');';
            $data = $this->query($sql, $params);
            if (!is_array($data) && !$data) {
                return false;
            }
        }

        return true;
    }

    /**
     * Copy the observations data from the CSV into the temporary source table
     *
     * @param array $profile Jelix profile name
     * @param PgSql\Connection $pgConnection PostgreSQL connection
     *
     * @return array Array with status, message and query result
     */
    private function copyDataFromCSV($profile, $pgConnection) {
        // We need to add the search path configured in the profile
        // because here we recreate a new connection with pg_connect
        // and we do not use the virtual profile with jDb
        // otherwise the COPY will not find the temporary table if the public schema
        // is not the first one in the search_path
        $setSearchPath = "";
        if (array_key_exists('search_path', $profile) && !empty($profile['search_path'])) {
            $setSearchPath = "SET search_path TO ".$profile['search_path'].";";
        }
        $table = '"'.$this->temporary_table.'_source"';
        $columns = $this->header;
        $file = $this->csv_file;
        $sql = $setSearchPath.' COPY '.$table.' (';
        $comma = '';
        foreach ($columns as $column) {
            $sql .= $comma.'"'.$column.'"';
            $comma = ', ';
        }
        $sql.= ') ';
        $sql.= " FROM STDIN WITH CSV HEADER DELIMITER ',' ";
        $query = pg_query($pgConnection, $sql);

        // If we can read the file
        if ($query && ($handle = fopen($file, 'r')) !== FALSE) {
            while (($data = fgets($handle)) !== FALSE) {
                pg_put_line($pgConnection, $data);
            }
            fclose($handle);
            $query = pg_end_copy($pgConnection);
            $status = true;
            $message = 'Les données ont été lues depuis le CSV et importées dans la table temporaire';
        } else {
            $status = false;
            $message = 'Les données ne peuvent pas être lues depuis le CSV pour import dans la table temporaire';
            $query = null;
        }

        return array($status, $message, $query);
    }

    /**
     * Insert the data from the CSV file
     * into the target table.
     *
     * We should not read the CSV data but only copy all the data to PostgreSQL
     *
     * @return boolean True if success
     */
    private function importCsvDataToTemporaryTable()
    {
        $status = true;
        $message = 'ok';
        $query = null;

        try {
            $profile = jProfiles::get('jdb', 'naturaliz_virtual_profile');
            $dsn = sprintf(
                "host=%s port=%s dbname=%s user=%s password=%s",
                $profile['host'],
                $profile['port'],
                $profile['database'],
                $profile['user'],
                $profile['password']
            );
            /** @var PgSql\Connection */
            $pgConnection = pg_pconnect($dsn);

            // Import observation data
            list($status, $message, $query) = $this->copyDataFromCSV($profile, $pgConnection);

        }  catch (Exception $e) {
            $message = $e->getMessage();
            $status = false;
            \jLog::log($message, 'error');

        } finally {
            if ($pgConnection) {
                if (!$query) {
                    \jLog::log(pg_last_error($pgConnection), 'error');
                    $message = 'Erreur : le fichier '.$this->csv_file.' contient des données supplémentaires après la dernière colonne attendue';
                    $status = false;
                }

                pg_close($pgConnection);
            }
        }

        return array($status, $message);
    }

    /**
     * Save the CSV file content into the temporary table
     *
     * @param string $sql SQL text to run
     * @param array $params Array of the parameters values
     *
     * @return null|array Not null content if success.
     */
    public function saveToSourceTemporaryTable()
    {
        if (!empty($this->csv_attributes_file)) {
            $this->setAdditionalAttributesData();
        }

        // Import the data
        list($status, $message) = $this->importCsvDataToTemporaryTable();

        return array($status, $message);
    }

    /**
     * Insert the data from the temporary table containing the CSV content
     * into the temporary formatted target table.
     *
     * @return boolean True if success
     */
    private function importCsvDataToTargetTable()
    {
        $status = true;

        // Insert the CSV data into the source temporary table
        $sql = 'INSERT INTO "'.$this->temporary_table.'_target"';
        $sql .= ' (';
        $comma = '';
        $fields = '';
        $parsedFields = '';

        // Corresponding fields
        foreach ($this->corresponding_fields as $column) {
            $fields .= $comma.'"'.$column.'"';
            $parsedFields .= $comma.'Nullif(Nullif(trim("'.$column.'"), \'\'), \'NULL\')';
            $comma = ', ';
        }
        $sql .= $fields;

        // JSON containing other data
        if (!preg_match('/, odata/', $sql)) {
            $sql.= ', odata';
        }

        $sql .= ')';
        $sql .= ' SELECT ';
        $sql .= $parsedFields;
        if (!empty($this->additional_fields)) {
            $comma = '';
            $sql_add = ', json_build_object(';
            foreach ($this->additional_fields as $column) {
                $sql_add .= $comma."'".$column."', ".'"'.$column.'"';
                $comma = ', ';
            }
            $sql_add .= ")";
            $sql .= $sql_add;
        } else {
            $sql .= ', NULL::json';
        }

        $sql .= ' FROM "'.$this->temporary_table.'_source"';
        $sql .= ';';

        $params = array();
        $data = $this->query($sql, $params);

        $status = (is_array($data));
        return $status;
    }

    /**
     * Write imported CSV data into the formatted temporary table
     *
     * @return null|array Not null content if success.
     */
    public function saveToTargetTemporaryTable()
    {
        // Insert to the target formatted table
        $status = $this->importCsvDataToTargetTable();

        return $status;
    }

    /**
     * Validate the CSV imported data against the rules
     * listed in the table occtax.critere_conformite
     *
     * @param string $type_conformite Type de la conformité à tester: not_null, format, valide
     *
     * @return array The list.
     */
    public function validateCsvData($type_conformite)
    {
        $sql = "SELECT *, array_to_string(ids, ', ') AS ids_text";
        $sql .= ' FROM occtax.test_conformite_observation($1, $2, $3)';
        $sql .= ' WHERE nb_lines > 0';
        $sql .= ' ';
        $params = array(
            $this->temporary_table.'_target',
            $type_conformite,
            $this->source_srid,
        );
        $data = $this->query($sql, $params);

        return $data;
    }

    /**
     * Check that the target temporary table does not have
     * observations already present in occtax.observation
     *
     * @param string $jdd_uid JDD UUID. If null given, check duplicates against all observations
     * @param boolean $check_inside_this_jdd If True, check among observations of the same jdd.
     *                                       If False, check among the other observations
     *
     * @return null|array Null if a SQL request has failed, and array with duplicate check data otherwise.
     */
    public function checkCsvDataDuplicatedObservations($jdd_uid, $check_inside_this_jdd=true)
    {
        $sql = "SELECT duplicate_count, duplicate_ids";
        $sql .= ' FROM occtax.verification_doublons_avant_import($1, $2, ';
        if ($check_inside_this_jdd) {
            $sql .= 'TRUE';
        } else {
            $sql .= 'FALSE';
        }
        $sql .= ', $3';
        $sql .= ', $4';
        $sql .= ')';
        $sql .= ' WHERE True';
        $sql .= ' ';
        if ($jdd_uid === null) {
            $jdd_uid = '__ALL__';
        }
        $params = array(
            $this->temporary_table.'_target',
            $jdd_uid,
            $this->source_srid,
            $this->geometry_format,
        );
        $check_duplicate = $this->query($sql, $params);

        return $check_duplicate;
    }

    /**
     * Import the CSV imported data in the database
     * observation table
     *
     * @param string  $login The authenticated user login.
     * @param string  $jdd_uid JDD UUID.
     * @param string  $organisme_gestionnaire_donnees Organisme gestionnaire de données
     * @param string  $org_transformation Organisme de transformation
     *
     * @return boolean $status The status of the import.
     */
    public function importCsvIntoObservation($login, $jdd_uid,
        $organisme_gestionnaire_donnees, $org_transformation
    ) {
        // Import dans la table observation
        $sql = ' SELECT count(*) AS nb';
        $sql .= ' FROM occtax.import_observations_depuis_table_temporaire(
            $1,
            $2, $3,
            $4, $5,
            $6, $7
        )';
        $params = array(
            $this->temporary_table.'_target',
            $login, $jdd_uid,
            $organisme_gestionnaire_donnees, $org_transformation,
            $this->source_srid, $this->geometry_format
        );
        $import_observation = $this->query($sql, $params);
        if (!is_array($import_observation)) {
            return null;
        }
        if (count($import_observation) != 1) {
            return null;
        }
        $import_observation = $import_observation[0];

        return $import_observation;
    }

    /**
     * Add the other data from the previously imported
     * csv data: lien, organisme, personne, spatial relationships
     *
     * @param string  $login The authenticated user login.
     * @param string  $jdd_uid JDD UUID.
     * @param string  $default_email Default email for newly created persons.
     * @param string  $libelle_import Libellé de l'import
     * @param string  $date_reception Date de réception des données
     * @param string  $remarque_import Remarques sur l'import
     * @param string  $user_email Email de l'importateur connecté
     *
     * @return boolean $status The status of the import.
     */
    public function addImportedObservationPostData(
        $login, $jdd_uid, $default_email,
        $libelle_import, $date_reception, $remarque_import,
        $user_email
    ) {
        // Import dans les tables liées à observation
        $sql = ' SELECT import_report';
        $sql .= ' FROM occtax.import_observations_post_data(
            $1,
            $2, $3, $4,
            $5, $6, $7,
            $8,
            $9
        )';
        $params = array(
            $this->temporary_table.'_target',
            $login, $jdd_uid,
            $default_email,
            $libelle_import, $date_reception, $remarque_import,
            $user_email,
            json_encode($this->attributeData)
        );
        $import_other = $this->query($sql, $params);
        if (!is_array($import_other)) {
            return null;
        }
        if (count($import_other) != 1) {
            return null;
        }
        $import_other = json_decode($import_other[0]->import_report);

        return $import_other;
    }

    /**
     * Delete the previously imported data
     * from the different tables.
     *
     * It is useful if a previous step has failed.
     *
     * @param string $jdd_uid JDD UUID.
     *
     * @return boolean $status The status of the import.
     */
    public function deleteImportedData($jdd_uid)
    {
        // Suppression
        $sql = ' SELECT *';
        $sql .= ' FROM occtax.import_supprimer_observations_importees($1, $2)';
        $params = array(
            $this->temporary_table.'_target',
            $jdd_uid,
        );
        $result = $this->query($sql, $params);
        if (!is_array($result)) {
            return null;
        }
        if (count($result) != 1) {
            return null;
        }

        return $result;
    }

    /**
     * Clean the import process
     *
     */
    public function clean()
    {
        // Remove CSV file
        unlink($this->csv_file);
        if ($this->csv_attributes_file) {
            unlink($this->csv_attributes_file);
        }

        // Drop the temporary table
        $sql = 'DROP TABLE IF EXISTS "'.$this->temporary_table.'_target"';
        $sql .= ', "'.$this->temporary_table.'_source"';
        $params = array();
        $this->query($sql, $params);
    }

    /**
     * Check if a given string is a valid UUID.
     *
     * @param string $uuid The string to check
     *
     * @return bool
     */
    public function isValidUuid($uuid)
    {
        if (empty($uuid)) {
            return false;
        }
        $uuid_regexp = '/^([0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12})$/i';
        if (!is_string($uuid) || (preg_match($uuid_regexp, $uuid) !== 1)) {
            return false;
        }

        return true;
    }


    /**
     * Validate a string containing a WKT.
     *
     * @param string wkt String to validate. Ex: "POLYGON((1 1,5 1,5 5,1 5,1 1))"
     * @param mixed $wkt
     *
     * @return bool
     */
    private function isValidWkt($wkt)
    {
        $patterns = array('/multi/', '/point/', '/polygon/', '/linestring/');
        $replacements = array('', '', '', '');
        $wktCoordinates = preg_replace($patterns, $replacements, trim(strtolower($wkt)));

        // If the original WKT does not contain any item in the listed patterns
        if ($wktCoordinates == trim(strtolower($wkt))) {
            return False;
        }

        // If the WKT coordinates does not contain any parenthesis at the beginning or end
        if (!preg_match('/^\(.+\)$/', $wktCoordinates) || !strpos($wktCoordinates, ' ')) {
            return False;
        }

        // Limit the authorized characters
        $regex = '#^[0-9 \.,\-\(\)]+$#';
        $match = preg_match($regex, trim($wktCoordinates));

        return $match;
    }


    /**
     * Get the data of a given JDD id
     * by querying the INPN public API
     *
     * $jddData = array(
     *     'jdd_id' => 40895,
     *     'jdd_code' => 'Suivi des gîtes à chiroptères de Martinique (PNRM, SFEPM 2015-2022)',
     *     'jdd_libelle' => 'Suivi gîtes chiroptères Martinique',
     *     'jdd_description' => 'Suivi terrain sur 53 gîtes localisés sur toute la Martinique, détermination des espèces présentes et comptage des effectifs',
     *     'id_sinp_jdd' => '93733D7D-A447-70EE-E053-5014A8C03C91',
     *     'jdd_cadre' => '25856',
     *     'ayants_droit' => '',
     *     'date_minimum_de_diffusion' => '',
     *     'url_fiche' => 'https://inpn.mnhn.fr/mtd/cadre/jdd/edit/40895',
     *     'cadre_id' => '25856',
     *     'cadre_uuid' => 'AADC610C-1566-7740-E053-2614A8C0710E',
     *     'cadre_libelle' => 'Élaboration des aménagements des forêts domaniales et départementales de Mayotte',
     *     'cadre_description' => 'description',
     *     'cadre_date_lancement' => '2014-01-01',
     *     'cadre_date_cloture' => '2018-12-31',
     *     'cadre_url_fiche' => 'https://inpn.mnhn.fr/mtd/cadre/edit/25856',
     * );
     *
     * @param string $jddUid JDD UID. Ex: AAEEEA9C-B888-40CC-E053-2614A8C03D42
     * @param string $source Source where to get the JDD data from. 'api' or 'database'
     *
     * @return array The JDD data
     */
    public function getJdd($jddUid, $source='database')
    {
        $jddData = array();

        // Get JDD from source
        if (!in_array($source, array('api', 'database'))) {
            $source = 'database';
        }
        if ($source == 'api') {
            // Get XML
            $jddUrl = 'https://inpn.mnhn.fr/mtd/cadre/jdd/export/xml/GetRecordById?id='.$jddUid;
            // try {
            //     $lizmapProxy = jClasses::getService('lizmap~lizmapProxy');
            //     list($data, $mime, $http_code) = $lizmapProxy->getRemoteData($jddUrl);
            // } catch(Exception $e) {
            //     list($data, $mime, $http_code) = \Lizmap\Request\Proxy::getRemoteData($jddUrl);
            // }
            // if ($http_code != 200) {
            //     return $jddData;
            // }

            return $jddData;

        } else {
            // Query the database
            $sql = 'SELECT j.*,';
            $sql .= ' c.cadre_id, c.cadre_uuid, c.libelle AS cadre_libelle, c.description AS cadre_description,';
            $sql .= ' c.date_lancement AS cadre_date_lancement, c.date_cloture AS cadre_cloture, c.url_fiche AS cadre_url_fiche';
            $sql .= ' FROM occtax.jdd AS j';
            $sql .= ' LEFT JOIN occtax.cadre AS c';
            $sql .= '     ON j.jdd_cadre = c.cadre_id';
            $sql .= ' WHERE id_sinp_jdd = $1';
            $sql .= ' LIMIT 1';
            $params = array($jddUid);
            $data = $this->query($sql, $params);
            if (is_array($data) && count($data) == 1) {
                $jddData = $data;
            }

            return $jddData;
        }

        return $jddData;
    }
}
