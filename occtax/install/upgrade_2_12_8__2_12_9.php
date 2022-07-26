<?php
class occtaxModuleUpgrader_2_12_8__2_12_9 extends jInstallerModule
{

    public $targetVersions = array(
        '2.12.9',
    );
    public $date = '2022-07-26';

    function install()
    {
        if ($this->firstDbExec()) {
            // Get variables
            // Keep here variable srid, colonne_locale
            $localConfig = jApp::configPath('naturaliz.ini.php');
            $ini = parse_ini_file($localConfig, true);
            $srid = '2975';
            if (array_key_exists('naturaliz', $ini) && array_key_exists('srid', $ini['naturaliz'])) {
                $srid = $ini['naturaliz']['srid'];
            }
            $colonne_locale = 'reu';
            if (array_key_exists('naturaliz', $ini) && array_key_exists('colonne_locale', $ini['naturaliz'])) {
                $srid = $ini['naturaliz']['colonne_locale'];
            }

            // SQL upgrade
            $this->useDbProfile('jauth_super');
            $db = $this->dbConnection(); // A PLACER TOUJOURS DERRIERE $this->useDbProfile('jauth_super');
            $sqlPath = $this->path . 'install/sql/upgrade/upgrade_2.12.8_2.12.9.sql';
            $sqlTpl = jFile::read($sqlPath);
            $tpl = new jTpl();
            // CAREFUL, SRID must be UPPERCASE
            $tpl->assign('SRID', $srid);
            $tpl->assign('colonne_locale', $colonne_locale);
            $sql = $tpl->fetchFromString($sqlTpl, 'text');
            $db->exec($sql);

            // Grant rights
            $sqlPath = $this->path . 'install/sql/grant_rights.sql';
            $sqlTpl = jFile::read($sqlPath);
            $tpl = new jTpl();
            $prof = jProfiles::get('jdb', $this->dbProfile, true);
            $tpl->assign('DBNAME', $prof['database']);
            $dbuser_readonly = 'naturaliz';
            if (array_key_exists('naturaliz', $ini) && array_key_exists('dbuser_readonly', $ini['naturaliz'])) {
                $dbuser_readonly = $ini['naturaliz']['dbuser_readonly'];
            }
            $dbuser_owner = 'naturaliz';
            if (array_key_exists('naturaliz', $ini) && array_key_exists('dbuser_owner', $ini['naturaliz'])) {
                $dbuser_owner = $ini['naturaliz']['dbuser_owner'];
            }
            $tpl->assign('DBUSER_READONLY', $dbuser_readonly);
            $tpl->assign('DBUSER_OWNER', $dbuser_owner);
            $sql = $tpl->fetchFromString($sqlTpl, 'text');

            // Try to reapply some rights on possibly newly created tables
            // If it fails, no worries as it can be done manually after upgrade
            try {
                $db->exec($sql);
            } catch (Exception $e) {
                jLog::log("Upgrade - Rights where not reapplied on database objects", 'error');
                jLog::log($e->getMessage(), 'error');
            }
        }
    }
}
