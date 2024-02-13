<?php
class occtaxModuleUpgrader_233_234 extends jInstallerModule {

    public $targetVersions = array(
        '2.3.4'
    );
    public $date = '2019-02-25';

    function install() {
        if( $this->firstDbExec() ) {
            // modify jlx_user columns
            $this->useDbProfile('jauth_super');
            $sqlPath = $this->path . 'install/sql/upgrade/upgrade_2.3.3_2.3.4.sql';
            $sql = jFile::read( $sqlPath );
            $db = $this->dbConnection();
            try {
                $db->exec($sql);
            } catch (Exception $e){
                jLog::log("Erreur lors de la mise à jour");
                jLog::log($e->getMessage());
            }

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
            $db = $this->dbConnection();
            try {
                $db->exec($sql);
            } catch (Exception $e){
                jLog::log("Erreur lors de la mise à jour");
                jLog::log($e->getMessage());
            }

        }
    }
}
