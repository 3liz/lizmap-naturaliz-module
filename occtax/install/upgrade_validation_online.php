<?php
class occtaxModuleUpgrader_validation_online extends jInstallerModule {

    public $targetVersions = array(
        '2.10.0',
    );
    public $date = '2021-07-29';

    function install() {
        if ($this->firstDbExec()) {
            // Get variables
            $localConfig = jApp::configPath('naturaliz.ini.php');
            $ini = new jIniFileModifier($localConfig);

            $colonne_locale = $ini->getValue('colonne_locale', 'naturaliz');
            if (empty($dbuser_readonly)) {
                $colonne_locale = 'reu';
            }
            $liste_rangs = $ini->getValue('liste_rangs', 'naturaliz');
            if (empty($dbuser_readonly)) {
                $liste_rangs = 'FM, GN, AGES, ES, SSES, NAT, VAR, SVAR, FO, SSFO, RACE, CAR, AB';
            }
            $liste_rangs = "'" . implode(
                  "', '",
                  array_map( 'trim', explode(',', $liste_rangs) )
            ) . "'";

            // SQL upgrade
            $this->useDbProfile('jauth_super');
            $db = $this->dbConnection(); // A PLACER TOUJOUR DERRIERE $this->useDbProfile('jauth_super');
            $sqlPath = $this->path . 'install/sql/upgrade/upgrade_validation_online.sql';
            $sqlTpl = jFile::read( $sqlPath );
            $tpl = new jTpl();
            $tpl->assign('colonne_locale', $colonne_locale);
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
            if (empty($dbuser_readonly)) {
                $dbuser_readonly = 'naturaliz';
            }
            if (empty($dbuser_owner)){
                $dbuser_owner = 'lizmap';
            }
            $tpl->assign('DBUSER_READONLY', $dbuser_readonly );
            $tpl->assign('DBUSER_OWNER', $dbuser_owner );
            $sql = $tpl->fetchFromString($sqlTpl, 'text');

            // Try to reapply some rights on possibly newly created tables
            // If it fails, no worries as it can be done manually after upgrade
            try {
                $db->exec($sql);
            }
            catch (Exception $e){
                jLog::log("Upgrade - Rights where not reapplied on database objects");
                jLog::log($e->getMessage());
            }

            // Ajout d'un nouveau droit de validation en ligne
            try{
                // Ajouter le droit d'utiliser l'outil de validation en ligne
                jAcl2DbManager::addSubject( 'validation.online.access', 'occtax~jacl2.validation.online.access', 'naturaliz.subject.group');
                jAcl2DbUserGroup::createGroup(
                    'naturaliz_validateurs',
                    'naturaliz_validateurs'
                );
                jAcl2DbManager::addRight('admins', 'validation.online.access');
                jAcl2DbManager::addRight('naturaliz_validateurs', 'validation.online.access');
            } catch (Exception $e){
                jLog::log("Erreur lors de l'ajout du droit de validation en ligne: validation.online.access");
                jLog::log($e->getMessage());
            }

        }
    }
}
