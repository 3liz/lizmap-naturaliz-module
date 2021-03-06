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

        // Copy CSS and JS assets
        $this->copyDirectoryContent('www', jApp::wwwPath());

        // Install taxon structure into database if needed
        if ($this->firstDbExec()) {

            try {
                // Add taxon schema and tables
                $sqlPath = $this->path . 'install/sql/install.pgsql.sql';
                $localConfig = jApp::configPath('naturaliz.ini.php');
                $ini = new jIniFileModifier($localConfig);
                $sqlTpl = jFile::read( $sqlPath );
                $tpl = new jTpl();
                $colonne_locale = $ini->getValue('colonne_locale', 'naturaliz');
                $tpl->assign('colonne_locale', $colonne_locale);
                $liste_rangs = $ini->getValue('liste_rangs', 'naturaliz');
                if(empty($liste_rangs)){
                    $liste_rangs = "FM, GN, AGES, ES, SSES, NAT, VAR, SVAR, FO, SSFO, RACE, CAR, AB";
                }
                $liste_rangs = "'" . implode(
                      "', '",
                      array_map( 'trim', explode(',', $liste_rangs) )
                ) . "'";
                $tpl->assign('liste_rangs', $liste_rangs);
                $sql = $tpl->fetchFromString($sqlTpl, 'text');
                $db = $this->dbConnection();
                $db->exec($sql);

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
