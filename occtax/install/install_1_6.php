<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/
require_once(__DIR__.'/installTrait.php');

class occtaxModuleInstaller extends jInstallerModule
{

    use installTrait;

    function install() {

        // Copy export readme files
        $readmeDestinationPath = jApp::varConfigPath('occtax-export-LISEZ-MOI.csv.txt');
        if (!file_exists($readmeDestinationPath)) {
            $this->copyFile('config/LISEZ-MOI.csv.md', $readmeDestinationPath);
        }
        $readmeDestinationPath = jApp::varConfigPath('occtax-export-LISEZ-MOI.geojson.txt');
        if (!file_exists($readmeDestinationPath)) {
            $this->copyFile('config/LISEZ-MOI.geojson.md', $readmeDestinationPath);
        }

        // Copy naturaliz configuration file
        $naturalizConfigPath = jApp::varConfigPath('naturaliz.ini.php');
        if (!file_exists($naturalizConfigPath)) {
            $this->copyFile('config/naturaliz.ini.php.dist', $naturalizConfigPath);
        }

        // Install occtax schema into database if needed
        if ($this->firstDbExec()) {

            //try {
                $db = $this->dbConnection();
                $this->setupOcctaxDatabase($db, $this->path.'install/sql/');
                // Add data for lists
                $this->execSQLScript('sql/data');

            //} catch (Exception $e){
                //jLog::log("Cannot install PostgreSQL database structure");
                //jLog::log($e->getMessage());
            //}

        }

        if ($this->firstExec('acl2') ) {
            $this->setupOcctaxRights();
        }

    }
}
