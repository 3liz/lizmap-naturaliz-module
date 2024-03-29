<?php
class occtaxModuleUpgrader_2_12_1__2_12_2 extends jInstallerModule
{

    public $targetVersions = array(
        '2.12.2',
    );
    public $date = '2022-03-29';

    function install()
    {
        if ($this->firstDbExec()) {
            // Get variables
            $localConfig = jApp::varConfigPath('naturaliz.ini.php');
            $ini = new Jelix\IniFile\IniModifier($localConfig);
            $srid = $ini->getValue('srid', 'naturaliz');

            // SQL upgrade
            $this->useDbProfile('jauth_super');
            $db = $this->dbConnection(); // A PLACER TOUJOUR DERRIERE $this->useDbProfile('jauth_super');
            $sqlPath = $this->path . 'install/sql/import.sql';
            $sqlTpl = jFile::read($sqlPath);
            $tpl = new jTpl();
            $tpl->assign('SRID', $srid);
            $sql = $tpl->fetchFromString($sqlTpl, 'text');
            $db->exec($sql);

            // Grant rights
            $sqlPath = $this->path . 'install/sql/grant_rights.sql';
            $sqlTpl = jFile::read($sqlPath);
            $tpl = new jTpl();
            $prof = jProfiles::get('jdb', $this->dbProfile, true);
            $tpl->assign('DBNAME', $prof['database']);
            $dbuser_readonly = $ini->getValue('dbuser_readonly', 'naturaliz');
            $dbuser_owner = $ini->getValue('dbuser_owner', 'naturaliz');
            if (empty($dbuser_readonly)) {
                $dbuser_readonly = 'naturaliz';
            }
            if (empty($dbuser_owner)) {
                $dbuser_owner = 'lizmap';
            }
            $tpl->assign('DBUSER_READONLY', $dbuser_readonly);
            $tpl->assign('DBUSER_OWNER', $dbuser_owner);
            $sql = $tpl->fetchFromString($sqlTpl, 'text');

            // Try to reapply some rights on possibly newly created tables
            // If it fails, no worries as it can be done manually after upgrade
            try {
                $db->exec($sql);
            } catch (Exception $e) {
                jLog::log("Upgrade - Rights where not reapplied on database objects");
                jLog::log($e->getMessage());
            }
        }
    }
}
