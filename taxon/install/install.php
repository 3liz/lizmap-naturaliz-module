<?php
/**
* @package   lizmap
* @subpackage taxon
* @author    your name
* @copyright 2011 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/


class taxonModuleInstaller extends jInstallerModule {

    function install() {

        // Copy taxon configuration
        $taxonConfFile = jApp::configPath('taxon.ini.php');
        if (!file_exists($taxonConfFile)) {
            $this->copyFile('config/taxon.ini.php', $taxonConfFile);
        }

        // Install taxon structure into database if needed
        if ($this->firstDbExec()) {

            try {
                // Add taxon schema and tables
                $this->execSQLScript('sql/install');

                // Add data for lists
                $this->execSQLScript('sql/data');

                // Add taxon to search_path
                $profileConfig = jApp::configPath('profiles.ini.php');
                $ini = new jIniFileModifier($profileConfig);
                $defaultProfile = $ini->getValue('default', 'jdb');
                $search_path = $ini->getValue('search_path', 'jdb:' . $defaultProfile);
                if( empty( $search_path ) )
                    $search_path = 'public';
                if( !preg_match( '#taxon#', $search_path ) )
                    $ini->setValue('search_path', $search_path . ',taxon', 'jdb:' . $defaultProfile);
                $ini->save();

            } catch (Exception $e){
                jLog::log("Cannot install PostgreSQL database structure");
                jLog::log($e->getMessage());
            }

        }

        /*if ($this->firstExec('acl2')) {
            jAcl2DbManager::addSubject('my.subject', 'taxon~acl.my.subject', 'subject.group.id');
            jAcl2DbManager::addRight('admins', 'my.subject'); // for admin group
        }
        */
    }
}
