<?php
class occtaxModuleUpgrader_212_213 extends jInstallerModule {

    public $targetVersions = array(
        '2.1.4'
    );
    public $date = '2018-08-16';

    function install() {
        if( $this->firstDbExec() ) {
            // modify jlx_user columns
            $this->useDbProfile('jauth_super');
            $sqlPath = $this->path . 'install/sql/upgrade/upgrade_2.1.3_2.1.4.sql';
            $sql = jFile::read( $sqlPath );
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
