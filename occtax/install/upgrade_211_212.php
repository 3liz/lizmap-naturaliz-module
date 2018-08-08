<?php
class occtaxModuleUpgrader_211_212 extends jInstallerModule {

    public $targetVersions = array(
        '2.1.2'
    );
    public $date = '2018-08-08';

    function install() {
        if( $this->firstDbExec() ) {
            // modify jlx_user columns
            $this->useDbProfile('jauth');

            $sqlPath = $this->path . 'install/sql/upgrade/upgrade_2.1.1_2.1.2.sql';
            $sqlTpl = jFile::read( $sqlPath );
            $tpl = new jTpl();

            // Get SRID
            //$localConfig = jApp::configPath('localconfig.ini.php');
            //$ini = new jIniFileModifier($localConfig);
            //$srid = $ini->getValue('srid', 'naturaliz');
            //$tpl->assign('SRID', $srid);
            $sql = $tpl->fetchFromString($sqlTpl, 'text');
            $db = $this->dbConnection();
            $db->exec($sql);
        }
    }
}
