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
        $readmeDestinationPath = jApp::configPath('occtax-export-LISEZ-MOI.csv.txt');
        if (!file_exists($readmeDestinationPath)) {
            $this->copyFile('config/LISEZ-MOI.csv.md', $readmeDestinationPath);
        }
        $readmeDestinationPath = jApp::configPath('occtax-export-LISEZ-MOI.geojson.txt');
        if (!file_exists($readmeDestinationPath)) {
            $this->copyFile('config/LISEZ-MOI.geojson.md', $readmeDestinationPath);
        }

        // Copy naturaliz configuration file
        $naturalizConfigPath = jApp::configPath('naturaliz.ini.php');
        if (!file_exists($naturalizConfigPath)) {
            $this->copyFile('config/naturaliz.ini.php.dist', $naturalizConfigPath);
        }

        // Add naturaliz_file cache profile used for the search items history
        \jFile::createDir(jApp::varPath('uploads/cache'));
        $profile_ini = new \jIniFileModifier(jApp::configPath('profiles.ini.php'));
        $profile_ini->setValue('driver', 'file', 'jcache:naturaliz_file_cache' );
        $profile_ini->setValue('ttl', '0', 'jcache:naturaliz_file_cache' );
        $profile_ini->setValue('enabled', '1', 'jcache:naturaliz_file_cache' );
        $profile_ini->setValue('cache_dir', 'var:uploads/cache/', 'jcache:naturaliz_file_cache' );
        $profile_ini->setValue('file_locking', '1', 'jcache:naturaliz_file_cache' );
        $profile_ini->setValue('directory_level', '0', 'jcache:naturaliz_file_cache' );
        $profile_ini->save();

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
