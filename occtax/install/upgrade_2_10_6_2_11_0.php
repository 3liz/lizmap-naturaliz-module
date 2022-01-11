<?php
class occtaxModuleUpgrader_2_10_6_2_11_0 extends jInstallerModule {

    public $targetVersions = array(
        '2.11.0',
    );
    public $date = '2022-01-11';

    function install() {
        if ($this->firstDbExec()) {
            // Read the ini file
            $localConfig = jApp::configPath('naturaliz.ini.php');
            $ini = new jIniFileModifier($localConfig);

            // SQL upgrade
            $this->useDbProfile('jauth_super');
            $db = $this->dbConnection(); // A PLACER TOUJOUR DERRIERE $this->useDbProfile('jauth_super');
            $sqlPath = $this->path . 'install/sql/upgrade/upgrade_2.10.6_2.11.0.sql';
            $sqlTpl = jFile::read( $sqlPath );
            $tpl = new jTpl();

            // Keep example of more complex SQL commented
            // $colonne_locale = $ini->getValue('colonne_locale', 'naturaliz');
            // if (empty($dbuser_readonly)) {
            //     $colonne_locale = 'reu';
            // }
            // $liste_rangs = $ini->getValue('liste_rangs', 'naturaliz');
            // if (empty($dbuser_readonly)) {
            //     $liste_rangs = 'FM, GN, AGES, ES, SSES, NAT, VAR, SVAR, FO, SSFO, RACE, CAR, AB';
            // }
            // $liste_rangs = "'" . implode(
            //       "', '",
            //       array_map( 'trim', explode(',', $liste_rangs) )
            // ) . "'";
            // $tpl->assign('colonne_locale', $colonne_locale);
            // $tpl->assign('liste_rangs', $liste_rangs);
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
            if (empty($dbuser_readonly)) {
                $dbuser_readonly = 'naturaliz';
            }
            if (empty($dbuser_owner)){
                $dbuser_owner = 'lizmap';
            }
            $tpl->assign('DBUSER_READONLY', $dbuser_readonly );
            $tpl->assign('DBUSER_OWNER', $dbuser_owner );
            $sql = $tpl->fetchFromString($sqlTpl, 'text');

            // Try to reapply some rights on possibly newly created tables
            // If it fails, no worries as it can be done manually after upgrade
            try {
                $db->exec($sql);
            }
            catch (Exception $e){
                jLog::log("Upgrade - Rights where not reapplied on database objects");
                jLog::log($e->getMessage());
            }

        }
    }
}
