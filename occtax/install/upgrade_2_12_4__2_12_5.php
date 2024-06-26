<?php
class occtaxModuleUpgrader_2_12_4__2_12_5 extends jInstallerModule
{

    public $targetVersions = array(
        '2.12.5',
    );
    public $date = '2022-05-13';

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
            $sqlPath = $this->path . 'install/sql/upgrade/upgrade_2.12.4_2.12.5.sql';
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

            // Insert data in occtax.historique_recherche from existing cache files (old way of storing history)
            // Get all logins
            try {
                $sql = 'SELECT DISTINCT usr_login FROM jlx_user';
                $logins = $db->query($sql);
                $has_content = False;
                $inserts = array();
                foreach ($logins as $item) {
                    $login = $item->usr_login;
                    $key = 'naturaliz_history_' . $login;
                    $profile = 'naturaliz_file_cache';
                    $history = jCache::get($key, $profile);
                    if ($history) {
                        $has_content = true;
                        $line_data = '(' . $db->quote($login) . ', $$' . $history . '$$::jsonb)';
                        $inserts[] = $line_data;
                    }
                }
                if ($has_content) {
                    $sql_insert = ' INSERT INTO occtax.historique_recherche ("usr_login", "history") VALUES ';
                    $sql_insert .= implode(', ', $inserts);
                    $sql_insert .= ' ON CONFLICT DO NOTHING;';
                    $db->exec($sql_insert);
                }
            } catch (Exception $e) {
                jLog::log("Upgrade - Errors while migrating search history from cache to database");
                jLog::log($e->getMessage());
            }
        }
    }
}
