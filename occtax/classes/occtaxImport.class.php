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

    // CSV header
    protected $header = array(
        'id'
    );

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
     * Runs quick check on the CSV structure
     *
     * @param string $csv_content Content of the observation CSV file
     */
    public function checkStructure()
    {
        $status = true;
        $message = '';

        // Check the CSV header
        $header = $this->parseCsv(0, 1);
        if (!$header === $this->header) {
            return array(
                false,
                jLocale::get("occtax~import.csv.wrong.header")
            );
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
        if (($handle = fopen($this->csv_file, "r")) !== FALSE) {
            while (($data = fgetcsv($handle, 1000, ",")) !== FALSE) {
                // Manage offset
                if ($row > $offset) {
                    // Add data to the table
                    $csv_data[] = $data;

                    // Stop after n lines if asked
                    if ($limit > 0 && $kept >= $limit) {
                        break;
                    }
                    $kept++;
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
        $cnx = jDb::getConnection();
        $cnx->beginTransaction();
        try {
            $resultset = $cnx->prepare($sql);
            $resultset->execute($params);
            $data = $resultset->fetchAll();
            $cnx->commit();
        } catch (Exception $e) {
            $cnx->rollback();
            $data = null;
        }

        return $data;
    }


    /**
     * Create the temporary table in the database
     *
     * @return null|array Not null content if success.
     */
    protected function createTemporaryTable()
    {
        $sql = '
        DROP TABLE IF EXISTS $1;
        CREATE TABLE $1 ( LIKE occtax.observation_temporaire INCLUDING ALL);
        ';
        $params = array($this->temporary_table);
        $data = $this->query($sql, $params);

        return $data;
    }

    /**
     * Run multiple INSERT for the given table
     *
     * @param string $table Name of the table (include schema eg: occtax.a_table)
     * @param array $multiple_params Array of array of the parameters values
     *
     * @return boolean True if success
     */
    private function multipleInsert($table, $multiple_params)
    {
        $status = true;
        $cnx = jDb::getConnection();
        $cnx->beginTransaction();
        try {
            foreach ($multiple_params as $params) {
                $sql = ' INSERT INTO $1 VALUES (';
                $v = '';
                for ($i = 0; $i = count($this->header); $i++) {
                    $sql .= $v . '$' . $i;
                    $v = ', ';
                }
                $sql .= ');';
                $resultset = $cnx->prepare($sql);
                $resultset->execute($params);
            }
            $cnx->commit();
        } catch (Exception $e) {
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
    protected function saveToTemporaryTable()
    {
        // Check the data
        if (count($this->data) == 0) {
            return false;
        }

        // Create the temporary table
        if (!$this->createTemporaryTable()) {
            return false;
        }

        // Import the data
        $this->multipleInsert($this->temporary_table, $this->data);

        return true;
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
        $sql = 'DROP TABLE IF EXISTS $1';
        $params = array($this->temporary_table);
        $data = $this->query($sql, $params);
    }
}
