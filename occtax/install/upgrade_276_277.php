<?php
class occtaxModuleUpgrader_276_277 extends jInstallerModule {

    public $targetVersions = array(
        '2.7.7'
    );
    public $date = '2020-11-26';

    function install() {
        if( $this->firstDbExec() ) {
            // Get variables
            $localConfig = jApp::configPath('naturaliz.ini.php');
            $ini = new jIniFileModifier($localConfig);

            $colonne_locale = $ini->getValue('colonne_locale', 'naturaliz');
            if(empty($colonne_locale)){
                $colonne_locale = 'reu';
            }

            // Add new entries in configuration file
            $statut_localisations = $ini->getValue('statut_localisations', 'naturaliz');
            if (empty($statut_localisations)) {
                  $ini->setValue('statut_localisations', 'fra,'.$colonne_locale, 'naturaliz');
            }
            $taxon_detail_source_type = $ini->getValue('taxon_detail_source_type', 'naturaliz');
            if (empty($taxon_detail_source_type)) {
                  $ini->setValue('taxon_detail_source_type', 'api', 'naturaliz');
            }
            $taxon_detail_source_url = $ini->getValue('taxon_detail_source_url', 'naturaliz');
            if (empty($taxon_detail_source_url)) {
                  $ini->setValue('taxon_detail_source_url', '', 'naturaliz');
            }

            // modify jlx_user columns
            $this->useDbProfile('jauth_super');
            $db = $this->dbConnection(); // A PLACER TOUJOUR DERRIERE $this->useDbProfile('jauth_super');
            $sqlPath = $this->path . 'install/sql/upgrade/upgrade_2.7.6_2.7.7.sql';
            $sqlTpl = jFile::read( $sqlPath );
            $tpl = new jTpl();
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
            }
            if(empty($dbuser_owner)){
                $dbuser_owner = 'lizmap';
            }
            $ini->save();

            $tpl->assign('DBUSER_READONLY', $dbuser_readonly );
            $tpl->assign('DBUSER_OWNER', $dbuser_owner );
            $sql = $tpl->fetchFromString($sqlTpl, 'text');
            $db->exec($sql);


        }
    }
}
