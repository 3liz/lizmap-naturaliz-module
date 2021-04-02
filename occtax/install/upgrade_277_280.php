<?php
class occtaxModuleUpgrader_277_280 extends jInstallerModule {

    public $targetVersions = array(
        '2.8.0'
    );
    public $date = '2021-04-02';

    function install() {
        if( $this->firstDbExec() ) {
            // Get variables
            $localConfig = jApp::configPath('naturaliz.ini.php');
            $ini = new jIniFileModifier($localConfig);

            $colonne_locale = $ini->getValue('colonne_locale', 'naturaliz');
            if(empty($dbuser_readonly)){
                $colonne_locale = 'reu';
            }
            $liste_rangs = $ini->getValue('liste_rangs', 'naturaliz');
            if(empty($dbuser_readonly)){
                $liste_rangs = 'FM, GN, AGES, ES, SSES, NAT, VAR, SVAR, FO, SSFO, RACE, CAR, AB';
            }

            // SQL upgrade
            $this->useDbProfile('jauth_super');
            $db = $this->dbConnection(); // A PLACER TOUJOUR DERRIERE $this->useDbProfile('jauth_super');
            $sqlPath = $this->path . 'install/sql/upgrade/upgrade_2.7.7_2.8.0.sql';
            $sqlTpl = jFile::read( $sqlPath );
            $tpl = new jTpl();
            $tpl->assign('colonne_locale', $colonne_locale);
            $tpl->assign('liste_rangs', $liste_rangs);
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
            }
            if(empty($dbuser_owner)){
                $dbuser_owner = 'lizmap';
            }

            $tpl->assign('DBUSER_READONLY', $dbuser_readonly );
            $tpl->assign('DBUSER_OWNER', $dbuser_owner );
            $sql = $tpl->fetchFromString($sqlTpl, 'text');
            $db->exec($sql);


        }
    }
}
