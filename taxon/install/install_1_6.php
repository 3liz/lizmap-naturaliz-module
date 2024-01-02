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
        $taxonConfFile = jApp::varConfigPath('taxon.ini.php');
        if (!file_exists($taxonConfFile)) {
            $this->copyFile('config/taxon.ini.php', $taxonConfFile);
        }

        // Copy CSS and JS assets
        $this->copyDirectoryContent('www', jApp::wwwPath());

        // Install taxon structure into database if needed
        if ($this->firstDbExec()) {

            // Add taxon schema and tables
            $sqlPath = $this->path.'install/sql/install.pgsql.sql';
            $localConfig = jApp::varConfigPath('naturaliz.ini.php');
            $ini = new \Jelix\IniFile\IniModifier($localConfig);
            $sqlTpl = jFile::read( $sqlPath );
            $tpl = new jTpl();
            $colonne_locale = $ini->getValue('colonne_locale', 'naturaliz');
            $tpl->assign('colonne_locale', $colonne_locale);
            $liste_rangs = $ini->getValue('liste_rangs', 'naturaliz');
            if(empty($liste_rangs)){
                $liste_rangs = "FM, GN, AGES, ES, SSES, NAT, VAR, SVAR, FO, SSFO, RACE, CAR, AB";
            }
            $liste_rangs = "'".implode(
                  "', '",
                  array_map( 'trim', explode(',', $liste_rangs) )
            )."'";
            $tpl->assign('liste_rangs', $liste_rangs);
            $sql = $tpl->fetchFromString($sqlTpl, 'text');
            $db = $this->dbConnection();
            $db->exec($sql);

            // Add data for lists
            $this->execSQLScript('sql/data');

        }

        /*if ($this->firstExec('acl2')) {
            jAcl2DbManager::addSubject('my.subject', 'taxon~acl.my.subject', 'subject.group.id');
            jAcl2DbManager::addRight('admins', 'my.subject'); // for admin group
        }
        */
    }
}
