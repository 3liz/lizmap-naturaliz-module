<?php
/**
* @package   lizmap
* @subpackage gestion
* @author    3liz
* @copyright 2016 3liz
* @link      http://3liz.com
* @license    Mozilla Public Licence
*/


class gestionModuleInstaller extends jInstallerModule {

    function install() {

        // Install gestion structure into database if needed
        if ($this->firstDbExec()) {

            // Add gestion schema and tables
            $sqlPath = $this->path . 'install/sql/install.pgsql.sql';
            $sqlTpl = jFile::read( $sqlPath );
            $tpl = new jTpl();

            // Get SRID
            $localConfig = jApp::configPath('naturaliz.ini.php');
            $ini = new jIniFileModifier($localConfig);
            $srid = $ini->getValue('srid', 'naturaliz');
            $tpl->assign('SRID', $srid);
            $sql = $tpl->fetchFromString($sqlTpl, 'text');

            try{
                  $db = $this->dbConnection();
                  $db->exec($sql);

                  // Add data for lists
                  $this->execSQLScript('sql/data');

                  // Add gestion to search_path
                  $profileConfig = jApp::configPath('profiles.ini.php');
                  $ini = new jIniFileModifier($profileConfig);
                  $defaultProfile = $ini->getValue('default', 'jdb');
                  $search_path = $ini->getValue('search_path', 'jdb:' . $defaultProfile);
                  if( empty( $search_path ) )
                      $search_path = 'public';
                  if( !preg_match( '#gestion#', $search_path ) )
                      $ini->setValue('search_path', $search_path . ',gestion', 'jdb:' . $defaultProfile);
                  $ini->save();
            } catch (Exception $e){
                jLog::log("Cannot install PostgreSQL database structure");
                jLog::log($e->getMessage());
            }


        }
    }
}
