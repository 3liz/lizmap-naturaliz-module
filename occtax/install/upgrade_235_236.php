<?php
class occtaxModuleUpgrader_235_236 extends jInstallerModule {

    public $targetVersions = array(
        '2.3.6'
    );
    public $date = '2019-10-04';

    function install() {
        if( $this->firstDbExec() ) {
            try{
                // Ajouter le droit export.geometries.brutes.selon.diffusion
                jAcl2DbManager::addSubject( 'export.geometries.brutes.selon.diffusion', 'occtax~jacl2.export.geometries.brutes.selon.diffusion', 'naturaliz.subject.group');
                jAcl2DbManager::addRight('admins', 'export.geometries.brutes.selon.diffusion');
            } catch (Exception $e){
                jLog::log("Erreur lors de l'ajout du droit export.geometries.brutes.selon.diffusion");
                jLog::log($e->getMessage());
            }

            // modify jlx_user columns
            $this->useDbProfile('jauth_super');
            $sqlPath = $this->path . 'install/sql/upgrade/upgrade_2.3.5_2.3.6.sql';
            $sql = jFile::read( $sqlPath );
            $db = $this->dbConnection();
            $db->exec($sql);

            // Grant rights
            $sqlPath = $this->path . 'install/sql/grant_rights.sql';
            $sqlTpl = jFile::read( $sqlPath );
            $tpl = new jTpl();
            $prof = jProfiles::get('jdb', $this->dbProfile, true);
            $tpl->assign('DBNAME', $prof['database'] );
            $localConfig = jApp::varConfigPath('naturaliz.ini.php');
            $ini = new Jelix\IniFile\IniModifier($localConfig);
            $dbuser_readonly = $ini->getValue('dbuser_readonly', 'naturaliz');
            $dbuser_owner = $ini->getValue('dbuser_owner', 'naturaliz');
            if(empty($dbuser_readonly)){
                $dbuser_readonly = 'naturaliz';
                $ini->setValue('dbuser_readonly', 'naturaliz', 'naturaliz');
            }
            if(empty($dbuser_owner)){
                $dbuser_owner = 'lizmap';
                $ini->setValue('dbuser_owner', 'lizmap', 'naturaliz');
            }
            $ini->save();

            $tpl->assign('DBUSER_READONLY', $dbuser_readonly );
            $tpl->assign('DBUSER_OWNER', $dbuser_owner );
            $sql = $tpl->fetchFromString($sqlTpl, 'text');
            $db->exec($sql);

        }
    }
}
