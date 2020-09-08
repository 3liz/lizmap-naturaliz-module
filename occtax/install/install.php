<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/


class occtaxModuleInstaller extends jInstallerModule {

    function addSchemaToSearchPath($schema_name) {

        // Add gestion to search_path
        $profileConfig = jApp::configPath('profiles.ini.php');
        $ini = new jIniFileModifier($profileConfig);
        $defaultProfile = $ini->getValue('default', 'jdb');
        $search_path = $ini->getValue('search_path', 'jdb:' . $defaultProfile);
        if (empty($search_path )) {
            $search_path = 'public';
        }
        if (!preg_match( '#'.$schema_name.'#', $search_path )) {
            $ini->setValue('search_path', $search_path . ',' . $schema_name, 'jdb:' . $defaultProfile);
        }
        $ini->save();
    }

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

        // Install occtax schema into database if needed
        if ($this->firstDbExec()) {

            //try {
                $db = $this->dbConnection();

                // Get SRID
                $localConfig = jApp::configPath('naturaliz.ini.php');
                $ini = new jIniFileModifier($localConfig);
                $srid = $this->getParameter('srid');
                if(empty($srid)){
                    $srid = $ini->getValue('srid', 'naturaliz');
                }

                // Add occtax schema and tables
                $sqlPath = $this->path . 'install/sql/install.pgsql.sql';
                $sqlTpl = jFile::read( $sqlPath );
                $tpl = new jTpl();
                $tpl->assign('SRID', $srid);
                $sql = $tpl->fetchFromString($sqlTpl, 'text');
                $db->exec($sql);

                // Add gestion
                $sqlPath = $this->path . 'install/sql/gestion.pgsql.sql';
                $sqlTpl = jFile::read( $sqlPath );
                $tpl = new jTpl();
                $tpl->assign('SRID', $srid);
                $sql = $tpl->fetchFromString($sqlTpl, 'text');
                $sql.= jFile::read( $this->path . 'install/sql/gestion.data.pgsql.sql' );
                $db->exec($sql);

                // Add extension validation
                // DO NOT USE TEMPLATE : no need (no srid) AND bug with some PostgreSQL regexp inside
                $sqlPath = $this->path . 'install/sql/extension_validation.pgsql.sql';
                $sqlTpl = jFile::read( $sqlPath );
                $tpl = new jTpl();
                $colonne_locale = $ini->getValue('colonne_locale', 'naturaliz');
                $tpl->assign('colonne_locale', $colonne_locale);
                $sql = jFile::read( $sqlPath );
                $db->exec($sql);

                // Add materialized views
                $sqlPath = $this->path . 'install/sql/materialized_views.pgsql.sql';
                $sqlTpl = jFile::read( $sqlPath );
                $tpl = new jTpl();
                $colonne_locale = $ini->getValue('colonne_locale', 'naturaliz');
                $tpl->assign('colonne_locale', $colonne_locale);
                $sql = $tpl->fetchFromString($sqlTpl, 'text');
                $db->exec($sql);

                // Add data for lists
                $this->execSQLScript('sql/data');

                // Add occtax to search_path
                $this->addSchemaToSearchPath('occtax');
                $this->addSchemaToSearchPath('sig');
                $this->addSchemaToSearchPath('gestion');

            //} catch (Exception $e){
                //jLog::log("Cannot install PostgreSQL database structure");
                //jLog::log($e->getMessage());
            //}

        }

        //try{
        if ($this->firstExec('acl2') ) {
            $this->useDbProfile('auth');

            // Create subjects
            jAcl2DbManager::addSubjectGroup ('naturaliz.subject.group', 'occtax~jacl2.naturaliz.subject.group.name');
            jAcl2DbManager::addSubject( 'occtax.admin.config.gerer', 'occtax~jacl2.occtax.admin.config.gerer', 'naturaliz.subject.group');

            jAcl2DbManager::addSubject( 'requete.spatiale.maille_01', 'occtax~jacl2.requete.spatiale.maille_01', 'naturaliz.subject.group');
            jAcl2DbManager::addSubject( 'requete.spatiale.maille_02', 'occtax~jacl2.requete.spatiale.maille_02', 'naturaliz.subject.group');
            jAcl2DbManager::addSubject( 'requete.spatiale.cercle', 'occtax~jacl2.requete.spatiale.cercle', 'naturaliz.subject.group');
            jAcl2DbManager::addSubject( 'requete.spatiale.polygone', 'occtax~jacl2.requete.spatiale.polygone', 'naturaliz.subject.group');
            jAcl2DbManager::addSubject( 'requete.spatiale.import', 'occtax~jacl2.requete.spatiale.import', 'naturaliz.subject.group');
            jAcl2DbManager::addSubject( 'requete.spatiale.espace.naturel', 'occtax~jacl2.requete.spatiale.espace.naturel', 'naturaliz.subject.group');

            jAcl2DbManager::addSubject( 'requete.jdd.observation', 'occtax~jacl2.requete.jdd.observation', 'naturaliz.subject.group');
            jAcl2DbManager::addSubject( 'requete.observateur.observation', 'occtax~jacl2.requete.observateur.observation', 'naturaliz.subject.group');
            jAcl2DbManager::addSubject( 'requete.organisme.utilisateur', 'occtax~jacl2.requete.organisme.utilisateur', 'naturaliz.subject.group');
            jAcl2DbManager::addSubject( 'requete.utilisateur.observation', 'occtax~jacl2.requete.utilisateur.observation', 'naturaliz.subject.group');
            jAcl2DbManager::addSubject( 'visualisation.donnees.brutes', 'occtax~jacl2.visualisation.donnees.brutes', 'naturaliz.subject.group');
            jAcl2DbManager::addSubject( 'visualisation.donnees.maille_01', 'occtax~jacl2.visualisation.donnees.maille_01', 'naturaliz.subject.group');
            jAcl2DbManager::addSubject( 'visualisation.donnees.maille_02', 'occtax~jacl2.visualisation.donnees.maille_02', 'naturaliz.subject.group');
            jAcl2DbManager::addSubject( 'visualisation.donnees.sensibles', 'occtax~jacl2.visualisation.donnees.sensibles', 'naturaliz.subject.group');
            jAcl2DbManager::addSubject( 'visualisation.donnees.non.filtrees', 'occtax~jacl2.visualisation.donnees.non.filtrees', 'naturaliz.subject.group');
            jAcl2DbManager::addSubject( 'export.geometries.brutes.selon.diffusion', 'occtax~jacl2.export.geometries.brutes.selon.diffusion', 'naturaliz.subject.group');

            // create some users in jAuth
            require_once(JELIX_LIB_PATH.'auth/jAuth.class.php');
            require_once(JELIX_LIB_PATH.'plugins/auth/db/db.auth.php');

            // Create Jacl2 group
            for( $i=1; $i<=5; $i++ ) {
                jAcl2DbUserGroup::createGroup(
                    'naturaliz_profil_'.$i,
                    'naturaliz_profil_'.$i
                );
            }

            // Set rights on groups
            jAcl2DbManager::setRightsOnGroup(
                'naturaliz_profil_1',
                array(
                    'occtax.admin.config.gerer'=>false,
                    'requete.spatiale.maille_01'=>true,
                    'requete.spatiale.maille_02'=>true,
                    'requete.spatiale.cercle'=>true,
                    'requete.spatiale.polygone'=>true,
                    'requete.spatiale.import'=>true,
                    'requete.spatiale.espace.naturel'=>true,
                    'requete.jdd.observation'=>true,
                    'requete.observateur.observation'=>true,
                    'requete.organisme.utilisateur'=>true,
                    'requete.utilisateur.observation'=>true,
                    'visualisation.donnees.brutes'=>true,
                    'visualisation.donnees.maille_01'=>true,
                    'visualisation.donnees.maille_02'=>true,
                    'visualisation.donnees.sensibles'=>true,
                )
            );

            jAcl2DbManager::setRightsOnGroup(
                'naturaliz_profil_2',
                array(
                    'requete.spatiale.maille_01'=>true,
                    'requete.spatiale.maille_02'=>true,
                    'requete.spatiale.cercle'=>true,
                    'requete.spatiale.polygone'=>true,
                    'requete.spatiale.import'=>true,
                    'requete.spatiale.espace.naturel'=>true,
                    'requete.jdd.observation'=>true,
                    'requete.observateur.observation'=>true,
                    'requete.organisme.utilisateur'=>true,
                    'requete.utilisateur.observation'=>true,
                    'visualisation.donnees.brutes'=>true,
                    'visualisation.donnees.maille_01'=>true,
                    'visualisation.donnees.maille_02'=>true,
                    'visualisation.donnees.sensibles'=>true,
                )
            );

            jAcl2DbManager::setRightsOnGroup(
                'naturaliz_profil_3',
                array(
                    'requete.spatiale.maille_01'=>true,
                    'requete.spatiale.maille_02'=>true,
                    'requete.spatiale.cercle'=>true,
                    'requete.spatiale.polygone'=>true,
                    'requete.spatiale.import'=>true,
                    'requete.spatiale.espace.naturel'=>true,
                    'requete.jdd.observation'=>true,
                    'requete.observateur.observation'=>true,
                    'requete.utilisateur.observation'=>true,
                    'visualisation.donnees.brutes'=>true,
                    'visualisation.donnees.maille_01'=>true,
                    'visualisation.donnees.maille_02'=>true,
                    'visualisation.donnees.sensibles'=>true,
                )
            );

            jAcl2DbManager::setRightsOnGroup(
                'naturaliz_profil_4',
                array(
                    'requete.spatiale.maille_01'=>true,
                    'requete.spatiale.maille_02'=>true,
                    'requete.spatiale.espace.naturel'=>true,
                    'requete.jdd.observation'=>true,
                    'requete.observateur.observation'=>true,
                    'requete.utilisateur.observation'=>true,
                    'visualisation.donnees.brutes'=>true,
                    'visualisation.donnees.maille_01'=>true,
                    'visualisation.donnees.maille_02'=>true,
                    'visualisation.donnees.sensibles'=>true,
                )
            );

            jAcl2DbManager::setRightsOnGroup(
                'naturaliz_profil_5',
                array(
                    'requete.spatiale.maille_01'=>true,
                    'requete.spatiale.maille_02'=>true,
                    'requete.spatiale.espace.naturel'=>true,
                    'requete.jdd.observation'=>true,
                    'requete.observateur.observation'=>true,
                    'visualisation.donnees.brutes'=>true,
                    'visualisation.donnees.maille_01'=>true,
                    'visualisation.donnees.maille_02'=>true,
                )
            );

            // Add some rights for anonymous
            jAcl2DbManager::addRight('__anonymous', 'requete.spatiale.maille_02');
            jAcl2DbManager::addRight('__anonymous', 'visualisation.donnees.maille_02');

            // Add admin to group naturaliz_profil_1
            jAcl2DbUserGroup::addUserToGroup('admin', 'naturaliz_profil_1');

            // Ajout du droit d'accès à l'administration de Naturaliz pour l'admin
            jAcl2DbManager::addRight('admins', 'occtax.admin.config.gerer');
            jAcl2DbManager::addRight('admins', 'visualisation.donnees.non.filtrees');
            jAcl2DbManager::addRight('admins', 'export.geometries.brutes.selon.diffusion');

        }

        //}catch (Exception $e){
            //jLog::log($e->getMessage());
        //}

    }
}
