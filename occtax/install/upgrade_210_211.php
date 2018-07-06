<?php
class occtaxModuleUpgrader_210_211 extends jInstallerModule {

    public $targetVersions = array(
        '2.1.1'
    );
    public $date = '2018-07-06';

    function install() {
        if( $this->firstDbExec() ) {
            // modify jlx_user columns
            $this->useDbProfile('jauth');

            $sqlPath = $this->path . 'install/sql/upgrade/upgrade_2.1.0_2.1.1.sql';
            $sqlTpl = jFile::read( $sqlPath );
            $tpl = new jTpl();

            // Get SRID
            $localConfig = jApp::configPath('localconfig.ini.php');
            $ini = new jIniFileModifier($localConfig);
            $srid = $ini->getValue('srid', 'naturaliz');
            $tpl->assign('SRID', $srid);
            $sql = $tpl->fetchFromString($sqlTpl, 'text');
            $db = $this->dbConnection();
            $db->exec($sql);
        }
    }
}
