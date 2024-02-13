<?php
class occtaxModuleUpgrader_234_235 extends jInstallerModule {

    public $targetVersions = array(
        '2.3.5'
    );
    public $date = '2019-05-02';

    function install() {
        if( $this->firstDbExec() ) {
            // modify jlx_user columns
            $this->useDbProfile('jauth_super');
            $sqlPath = $this->path . 'install/sql/upgrade/upgrade_2.3.4_2.3.5.sql';
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
            $localConfig = jApp::configPath('naturaliz.ini.php');
            $ini = new jIniFileModifier($localConfig);
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
