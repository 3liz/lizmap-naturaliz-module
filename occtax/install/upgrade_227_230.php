<?php
class occtaxModuleUpgrader_227_230 extends jInstallerModule {

    public $targetVersions = array(
        '2.3.0'
    );
    public $date = '2018-12-11';

    function install() {
        if( $this->firstDbExec() ) {
            // modify jlx_user columns
            $this->useDbProfile('jauth_super');
            $sqlPath = $this->path . 'install/sql/upgrade/upgrade_2.2.7_2.3.0.sql';
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
