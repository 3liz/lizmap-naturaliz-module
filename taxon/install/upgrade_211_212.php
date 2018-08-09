<?php
class taxonModuleUpgrader_211_212 extends jInstallerModule {

    public $targetVersions = array(
        '2.1.2'
    );
    public $date = '2018-08-08';

    function install() {
        if( $this->firstDbExec() ) {
            // modify jlx_user columns
            $this->useDbProfile('jauth_super');

            $sqlPath = $this->path . 'install/sql/upgrade/upgrade_2.1.1_2.1.2.sql';
            $sqlTpl = jFile::read( $sqlPath );
            $tpl = new jTpl();
            $sql = $tpl->fetchFromString($sqlTpl, 'text');
            $db = $this->dbConnection();
            $db->exec($sql);

            // Grant rights
            $sqlPath = $this->path . 'install/sql/grant_rights.sql';
            $sqlTpl = jFile::read( $sqlPath );
            $tpl = new jTpl();
            $prof = jProfiles::get('jdb', $this->dbProfile, true);
            $tpl->assign('DBNAME', $prof['database'] );
            $tpl->assign('DBUSER_READONLY', 'naturaliz' );
            $tpl->assign('DBUSER_OWNER', 'lizmap' );
            $sql = $tpl->fetchFromString($sqlTpl, 'text');
            $db = $this->dbConnection();
            $db->exec($sql);
        }
    }
}
