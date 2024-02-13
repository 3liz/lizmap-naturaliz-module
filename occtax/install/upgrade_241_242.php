<?php
class occtaxModuleUpgrader_241_242 extends jInstallerModule {

    public $targetVersions = array(
        '2.4.2'
    );
    public $date = '2019-12-24';

    function install() {
        if( $this->firstDbExec() ) {
            // Get variables
            $localConfig = jApp::varConfigPath('naturaliz.ini.php');
            $ini = new Jelix\IniFile\IniModifier($localConfig);

            // modify jlx_user columns
            $this->useDbProfile('jauth_super');
            $db = $this->dbConnection(); // A PLACER TOUJOUR DERRIERE $this->useDbProfile('jauth_super');
            $sqlPath = $this->path . 'install/sql/upgrade/upgrade_2.4.1_2.4.2.sql';
            $sqlTpl = jFile::read( $sqlPath );
            $tpl = new jTpl();
            $colonne_locale = $ini->getValue('colonne_locale', 'naturaliz');
            $tpl->assign('colonne_locale', $colonne_locale);
            $liste_rangs = $ini->getValue('liste_rangs', 'naturaliz');
            if(empty($liste_rangs)){
              $liste_rangs = "FM, GN, AGES, ES, SSES, NAT, VAR, SVAR, FO, SSFO, RACE, CAR, AB";
            }
            $liste_rangs = "'" . implode(
                  "', '",
                  array_map( 'trim', explode(',', $liste_rangs) )
            ) . "'";
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
