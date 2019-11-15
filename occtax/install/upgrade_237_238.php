<?php
class occtaxModuleUpgrader_237_238 extends jInstallerModule {

    public $targetVersions = array(
        '2.3.8'
    );
    public $date = '2019-11-15';

    function install() {
        if( $this->firstDbExec() ) {
            // Get variables
            $db = $this->dbConnection();
            $localConfig = jApp::configPath('naturaliz.ini.php');
            $ini = new jIniFileModifier($localConfig);

            // modify jlx_user columns
            $this->useDbProfile('jauth_super');
            $sqlPath = $this->path . 'install/sql/upgrade/upgrade_2.3.7_2.3.8.sql';
            $sqlTpl = jFile::read( $sqlPath );
            $tpl = new jTpl();
            $colonne_locale = $ini->getValue('colonne_locale', 'naturaliz');
            $tpl->assign('colonne_locale', $colonne_locale);
            $sql = $tpl->fetchFromString($sqlTpl, 'text');
            $db->exec($sql);

            // Grant rights
            $sqlPath = $this->path . 'install/sql/grant_rights.sql';
            $sqlTpl = jFile::read( $sqlPath );
            $tpl = new jTpl();
            $prof = jProfiles::get('jdb', $this->dbProfile, true);
            $tpl->assign('DBNAME', $prof['database'] );

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
            try {
                $db->exec($sql);
            } catch (Exception $e){
                jLog::log("Erreur lors de la mise à jour");
                jLog::log($e->getMessage());
            }

        }
    }
}
