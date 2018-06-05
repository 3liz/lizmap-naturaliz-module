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

        // Copy CSS and JS files
        $this->copyDirectoryContent('www', jApp::wwwPath());

        // Install occtax schema into database if needed
        if ($this->firstDbExec()) {

            // Add occtax schema and tables
            $sqlPath = $this->path . 'install/sql/install.pgsql.sql';
            $sqlTpl = jFile::read( $sqlPath );

            // Add extension validation
            $sqlPath = $this->path . 'install/sql/extension_validation.pgsql.sql';
            $sqlTpl.= jFile::read( $sqlPath );
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

            // Add occtax to search_path
            $profileConfig = jApp::configPath('profiles.ini.php');
            $ini = new jIniFileModifier($profileConfig);
            $defaultProfile = $ini->getValue('default', 'jdb');
            $search_path = $ini->getValue('search_path', 'jdb:' . $defaultProfile);
            if( empty( $search_path ) )
                $search_path = 'public';
            if( !preg_match( '#sig#', $search_path ) ){
                $search_path = $search_path . ',sig';
                $ini->setValue('search_path', $search_path, 'jdb:' . $defaultProfile);
            }
            if( !preg_match( '#occtax#', $search_path ) ){
                $search_path = $search_path . ',occtax';
                $ini->setValue('search_path', $search_path, 'jdb:' . $defaultProfile);
            }
            $ini->save();

        }

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

            // create some users in jAuth
            require_once(JELIX_LIB_PATH.'auth/jAuth.class.php');
            require_once(JELIX_LIB_PATH.'plugins/auth/db/db.auth.php');

            $authconfig = $this->config->getValue('auth','coordplugins');
            $confIni = parse_ini_file(jApp::configPath($authconfig), true);
            $authConfig = jAuth::loadConfig($confIni);
            $driver = new dbAuthDriver($authConfig['Db']);
            $cn = $this->dbConnection();

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

            jAcl2DbManager::setRightsOnGroup(
                '__anonymous',
                array(
                    'requete.spatiale.maille_02'=>true,
                    'visualisation.donnees.maille_02'=>true
                )
            );

            // Add admin to group naturaliz_profil_1
            jAcl2DbUserGroup::addUserToGroup('admin', 'naturaliz_profil_1');

            // Ajout du droit d'accès à l'administration de Naturaliz pour l'admin
            jAcl2DbManager::setRightsOnGroup(
                'admins',
                array(
                    'occtax.admin.config.gerer'=>true
                )
            );

            //Modify admin password
            $localConfig = jApp::configPath('localconfig.ini.php');
            $ini = new jIniFileModifier($localConfig);
            $adminPassword = $ini->getValue('adminPassword', 'naturaliz');
            if( $adminPassword ){
                jAuth::changePassword('admin', $adminPassword );
            }
        }


        // Modifiy localconfig to add responses
        $this->config->setValue('csv', 'occtax~jResponseCsv', 'responses');
        $this->config->setValue('geojson', 'occtax~jResponseGeoJson', 'responses');


    }
}
