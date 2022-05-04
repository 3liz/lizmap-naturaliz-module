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

    // CSV separator
    protected $csv_separator = ',';

    // All possible fields
    protected $target_fields = array(
        'identifiant_permanent',
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
        'identifiant_origine',

        'jdd_id',
        'statut_source',
        'reference_biblio',

        'sensible',
        'sensi_date_attribution',
        'sensi_niveau',
        'sensi_referentiel',
        'sensi_version_referentiel',

        'validite_niveau',
        'validite_date_validation',

        'longitude',
        'latitude',
        'precision_geometrie',
        'nature_objet_geo',

        'descriptif_sujet',
    );

    // Mandatory fields
    protected $mandatory_fields = array(
        'identifiant_origine',
        'cd_nom',
        'nom_cite',
        'version_taxref',
        'date_debut',
        'date_fin',
        'statut_observation',
        'ds_publique',
        'statut_source',
        'sensible',
        'longitude',
        'latitude',
        'nature_objet_geo',
    );

    // Corresponding fields
    protected $corresponding_fields = array();

    // Additional found fields
    protected $additional_fields = array();

    // CSV parsed data
    protected $data;

    // Login
    protected $login;

    // Identifiant du jeu de données
    protected $jdd_uid;

    // Temporary table to store the content of the CSV file
    protected $temporary_table;

    /**
     * Constructor of the import class.
     *
     * @param string $csv_file File path of the CSV
     */
    public function __construct($csv_file)
    {
        // Set the csv_file property
        $this->csv_file = $csv_file;

        // Get the user login
        $login = null;
        $user = jAuth::getUserSession();
        if ($user) {
            $login = $user->login;
        }
        $this->login = $login;

        // Set the temporary table name
        $time = time();
        $this->temporary_table = 'temp_' . $time;
    }

    /**
     * Runs the needed check on the CSV structure
     *
     * @param string $csv_content Content of the observation CSV file
     */
    public function checkStructure()
    {
        $status = true;
        $message = '';

        // Get the csv header (first line)
        $header = $this->parseCsv(0, 1);

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

        $this->additional_fields = $additional_fields;
        $this->corresponding_fields = $corresponding_fields;

        if (count($missing_mandatory_fields) > 0) {
            $message = jLocale::get("occtax~import.csv.mandatory.fields.missing");
            $message .= ': ' . implode(', ', $missing_mandatory_fields);
            $status = false;
            return array($status, $message);
        }

        // Check that the first line (header) contains the same number of columns
        // that the second (data) to avoid errors
        $first_line = $this->parseCsv(1, 1);
        if (empty($first_line) || count($first_line[0]) != count($header)) {
            $message = jLocale::get("occtax~import.csv.columns.number.mismatch");
            $status = false;
            return array($status, $message);
        }

        return array($status, $message);
    }

    /**
     * Set the data property
     *
     */
    public function setData()
    {
        // Avoid the first line which contains the CSV header
        $this->data = $this->parseCsv(1);
    }

    /**
     * Parse the CSV raw content and fill the data property
     *
     * @param int $offset Number of lines to avoid from the beginning
     * @param int $limit Number of lines to parse from the beginning. Optionnal.
     *
     * @return array Array on array containing the data
     */
    protected function parseCsv($offset = 0, $limit = -1)
    {
        $csv_data = array();
        $row = 1;
        $kept = 0;
        if (($handle = fopen($this->csv_file, 'r')) !== FALSE) {
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
            $resultset->execute($params);
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
        $sql = 'DROP TABLE IF EXISTS "' . $this->temporary_table . '_source", "' . $this->temporary_table . '_target"';
        $params = array();
        $data = $this->query($sql, $params);

        // Create temporary table to store the CSV source data and the formatted imported data
        $tables = array(
            'source' => $this->header,
            'target' => $this->target_fields,
        );
        foreach ($tables as $name => $columns) {
            $sql = 'CREATE TABLE "' . $this->temporary_table . '_' . $name . '" (';
            $sql .= ' temporary_id serial';
            $comma = ',';
            foreach ($columns as $column) {
                $sql .= $comma . '"' . $column . '" text';
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
     * Insert the data from the CSV file
     * into the target table.
     *
     * @param string $table Name of the table (include schema eg: occtax.a_table)
     * @param array $multiple_params Array of array of the parameters values
     *
     * @return boolean True if success
     */
    private function importCsvDataToTemporaryTable($table, $multiple_params)
    {
        $status = true;

        // Insert the CSV data into the source temporary table
        $cnx = jDb::getConnection('naturaliz_virtual_profile');
        $cnx->beginTransaction();
        try {
            // Loop through each CSV data line
            foreach ($multiple_params as $params) {
                $sql = ' INSERT INTO "' . $table . '_source"';
                $sql .= '(';
                $comma = '';
                foreach ($this->header as $column) {
                    $sql .= $comma . '"' . $column . '"';
                    $comma = ', ';
                }
                $sql .= ')';
                $sql .= ' VALUES (';
                $comma = '';
                $i = 1;
                foreach ($this->header as $column) {
                    $sql .= $comma . 'Nullif(trim($' . $i . "), '')";
                    $comma = ', ';
                    $i++;
                }
                $sql .= ');';
                $resultset = $cnx->prepare($sql);
                $resultset->execute($params);
            }
            $cnx->commit();
        } catch (Exception $e) {
            jLog::log($e->getMessage());
            $cnx->rollback();
            $status = false;
        }

        return $status;
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
        // Read data from the CSV file
        // and set the data property with the read content
        $set_data = $this->setData();

        // Check the data
        if (count($this->data) == 0) {
            return false;
        }

        // Import the data
        $status = $this->importCsvDataToTemporaryTable($this->temporary_table, $this->data);

        return $status;
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
        $sql = 'INSERT INTO "' . $this->temporary_table . '_target"';
        $sql .= ' (';
        $comma = '';
        $fields = '';

        // Corresponding fields
        foreach ($this->corresponding_fields as $column) {
            $fields .= $comma . '"' . $column . '"';
            $comma = ', ';
        }
        $sql .= $fields;

        // JSON containing other data
        if (!preg_match('/, odata/', $sql)) {
            $sql.= ', odata';
        }

        $sql .= ')';
        $sql .= ' SELECT ';
        $sql .= $fields;
        if (!empty($this->additional_fields)) {
            $comma = '';
            $sql_add = ', json_build_object(';
            foreach ($this->additional_fields as $column) {
                $sql_add .= $comma . "'" . $column ."', " . '"' . $column . '"';
                $comma = ', ';
            }
            $sql_add .= ")";
            $sql .= $sql_add;
        } else {
            $sql .= ', NULL::json';
        }

        $sql .= ' FROM "' . $this->temporary_table . '_source"';
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
        $cnx = jDb::getConnection('naturaliz_virtual_profile');
        $sql = "SELECT *, array_to_string(ids, ', ') AS ids_text";
        $sql .= ' FROM occtax.test_conformite_observation($1, $2)';
        $sql .= ' WHERE nb_lines > 0';
        $sql .= ' ';
        $params = array(
            $this->temporary_table . '_target',
            $type_conformite,
        );
        $data = $this->query($sql, $params);

        return $data;
    }

    /**
     * Import the CSV imported data in the database
     * observation table
     *
     * @param string $login The authenticated user login.
     * @param string $jdd_uid JDD UUID.
     * @param string $organisme_responsable Organisme
     *
     * @return boolean $status The status of the import.
     */
    public function importCsvIntoObservation($login, $jdd_uid, $organisme_responsable)
    {
        // Import dans la table observation
        $sql = ' SELECT count(*) AS nb';
        $sql .= ' FROM occtax.import_observations_depuis_table_temporaire($1, $2, $3, $4)';
        $params = array(
            $this->temporary_table . '_target',
            $login,
            $jdd_uid,
            $organisme_responsable,
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
     * @param string $login The authenticated user login.
     * @param string $jdd_uid JDD UUID.
     *
     * @return boolean $status The status of the import.
     */
    public function addImportedObservationPostData($login, $jdd_uid)
    {
        // Import dans les tables liées à observation
        $sql = ' SELECT import_report';
        $sql .= ' FROM occtax.import_observations_post_data($1, $2, $3)';
        $params = array(
            $this->temporary_table . '_target',
            $login,
            $jdd_uid,
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
            $this->temporary_table . '_target',
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

        // Drop the temporary table
        $sql = 'DROP TABLE IF EXISTS "' . $this->temporary_table . '_source"';
        $sql .= ', "' . $this->temporary_table . '_target"';
        // \jLog::log($this->temporary_table . '_target"');
        $params = array();
        $data = $this->query($sql, $params);
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
     * Get the data of a given JDD id
     * by querying the INPN public API
     *
     * $jddData = array(
     *     'jdd_id' => 40895,
     *     'jdd_code' => 'Suivi des gîtes à chiroptères de Martinique (PNRM, SFEPM 2015-2022)',
     *     'jdd_libelle' => 'Suivi gîtes chiroptères Martinique',
     *     'jdd_description' => 'Suivi terrain sur 53 gîtes localisés sur toute la Martinique, détermination des espèces présentes et comptage des effectifs',
     *     'jdd_metadonnee_dee_id' => '93733D7D-A447-70EE-E053-5014A8C03C91',
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
            $sql .= ' WHERE jdd_metadonnee_dee_id = $1';
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
