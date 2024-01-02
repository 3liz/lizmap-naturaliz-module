<?php
/**
 * @package   lizmap
 * @subpackage taxon
 * @copyright 2011-2022 3liz
 * @link      http://3liz.com
 * @license    All rights reserved
 */



class taxonModuleInstaller extends \Jelix\Installer\Module\Installer
{
    public function install(\Jelix\Installer\Module\API\InstallHelpers $helpers)
    {

        $db = $helpers->database();
        // Add taxon schema and tables
        $sqlPath = $this->getPath().'install/sql/install.pgsql.sql';
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
        $db->dbConnection()->exec($sql);

        // Add data for lists
        $db->execSQLScript('sql/data');


        /*
        jAcl2DbManager::addSubject('my.subject', 'taxon~acl.my.subject', 'subject.group.id');
        jAcl2DbManager::addRight('admins', 'my.subject'); // for admin group
        */
    }
}
