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
    protected $jdd_id;

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
            $sql.= ', odata json';
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
        $sql.= ', odata';

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
}
