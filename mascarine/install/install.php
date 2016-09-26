<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/


class mascarineModuleInstaller extends jInstallerModule {

    function install() {

        // Copy export readme file
        $readmeDestinationPath = jApp::configPath('mascarine-export-LISEZ-MOI.txt');
        if (!file_exists($readmeDestinationPath)) {
            $this->copyFile('config/LISEZ-MOI.md', $readmeDestinationPath);
        }

        // Copy mascarine www
        $this->copyDirectoryContent('www', jApp::wwwPath());

        // Copy mascarine configuration
        $mascarineConfFile = jApp::configPath('mascarine.ini.php');
        if (!file_exists($mascarineConfFile)) {
            $this->copyFile('config/mascarine.ini.php', $mascarineConfFile);
        }

        $localConfig = jApp::configPath('localconfig.ini.php');
        if (!file_exists($localConfig)) {
            $localConfigDist = jApp::configPath('localconfig.ini.php.dist');
            if (file_exists($localConfigDist)) {
                copy($localConfigDist, $localConfig);
            }
            else {
                file_put_contents($localConfigDist, ';<'.'?php die(\'\');?'.'>');
            }
        }
        $ini = new jIniFileModifier($localConfig);
        //$ini->setValue('mascarine', 'mascarine.ini.php', 'coordplugins');
        $ini->save();

        // Install mascarine structure into database if needed
        if ($this->firstDbExec()) {

            // Add mascarine schema and tables
            $sqlPath = $this->path . 'install/sql/install.pgsql.sql';
            $sqlTpl = jFile::read( $sqlPath );
            $tpl = new jTpl();

            // Get SRID
            $localConfig = jApp::configPath('localconfig.ini.php');
            $ini = new jIniFileModifier($localConfig);
            $srid = $ini->getValue('srid', 'naturaliz');
            $tpl->assign('SRID', $srid);
            $sql = $tpl->fetchFromString($sqlTpl, 'text');
            $db = $this->dbConnection();
            $db->exec($sql);

            // Add data for lists
            $this->execSQLScript('sql/data');

            // Add mascarine to search_path
            $profileConfig = jApp::configPath('profiles.ini.php');
            $ini = new jIniFileModifier($profileConfig);
            $defaultProfile = $ini->getValue('default', 'jdb');
            $search_path = $ini->getValue('search_path', 'jdb:' . $defaultProfile);
            if( empty( $search_path ) )
                $search_path = 'public';
            if( !preg_match( '#mascarine#', $search_path ) )
                $ini->setValue('search_path', $search_path . ',mascarine', 'jdb:' . $defaultProfile);
            $ini->save();
        }

        if ($this->firstExec('acl2') ) {
            $this->useDbProfile('auth');

            // Create subjects
            jAcl2DbManager::addSubjectGroup( 'mascarine.subject.group', 'mascarine~jacl2.mascarine.subject.group.name');
            jAcl2DbManager::addSubject( 'mascarine.admin.config.gerer', 'mascarine~jacl2.mascarine.admin.config.gerer', 'mascarine.subject.group');
            jAcl2DbManager::addSubject( 'observation.creer', 'mascarine~jacl2.observation.creer', 'mascarine.subject.group');
            jAcl2DbManager::addSubject( 'observation.modifier.toute', 'mascarine~jacl2.observation.modifier.toute', 'mascarine.subject.group');
            jAcl2DbManager::addSubject( 'observation.modifier.organisme', 'mascarine~jacl2.observation.modifier.organisme', 'mascarine.subject.group');
            jAcl2DbManager::addSubject( 'observation.valider', 'mascarine~jacl2.observation.valider', 'mascarine.subject.group');
            jAcl2DbManager::addSubject( 'observation.modifier.remarques.controles', 'mascarine~jacl2.observation.modifier.remarques.controle', 'mascarine.subject.group');

            // Set rights on groups
            jAcl2DbManager::addRight( 'naturaliz_profil_1', 'mascarine.admin.config.gerer' );
            jAcl2DbManager::addRight( 'naturaliz_profil_1', 'observation.creer' );
            jAcl2DbManager::addRight( 'naturaliz_profil_1', 'observation.modifier.toute' );
            jAcl2DbManager::addRight( 'naturaliz_profil_1', 'observation.modifier.organisme' );
            jAcl2DbManager::addRight( 'naturaliz_profil_1', 'observation.valider' );
            jAcl2DbManager::addRight( 'naturaliz_profil_1', 'observation.modifier.remarques.controles' );

            jAcl2DbManager::addRight( 'naturaliz_profil_2', 'observation.creer' );
            jAcl2DbManager::addRight( 'naturaliz_profil_2', 'observation.modifier.organisme' );

            jAcl2DbManager::addRight( 'naturaliz_profil_3', 'observation.creer' );

            jAcl2DbManager::addRight( 'naturaliz_profil_4', 'observation.creer' );
        }
    }
}
