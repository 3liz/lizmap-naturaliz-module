<?php

/**
 * @package   lizmap
 * @subpackage occtax
 * @author    Michaël Douchin
 * @contributor Laurent Jouanneau
 * @copyright 2014-2022 3liz
 * @link      http://3liz.com
 * @license    All rights reserved
 */
require_once(__DIR__.'/upgradeTrait.php');
class occtaxModuleUpgrader_2_16_0__2_16_1 extends jInstallerModule //\Jelix\Installer\Module\Installer
{
    use upgradeTrait;

    public $targetVersions = array(
        '2.16.1',
    );
    public $date = '2023-05-12';

    protected $sqlUpgradeFile = 'upgrade/upgrade_2.16.0_2.16.1.sql';

    protected $sqlGrantFile = 'grant_rights.sql';

    //function install(\Jelix\Installer\Module\API\InstallHelpers $helpers)
    function install()
    {
        if ($this->firstDbExec()) {
            // Get path
            // $sqlDirPath = $this->getPath() . 'install/sql/';
            $sqlDirPath = $this->path.'install/sql/';

            // Get database connection
            // $helpers->database()->useDbProfile('jauth_super');
            // $db = $helpers->database()->dbConnection();
            $this->useDbProfile('jauth_super');
            $db = $this->dbConnection(); // A PLACER TOUJOURS DERRIERE $this->useDbProfile('jauth_super');

            // Naturaliz specific config file
            // $localConfig = jApp::varConfigPath('naturaliz.ini.php');
            $localConfig = jApp::configPath('naturaliz.ini.php');

            // Upgrade structure
            $this->upgradeDatabaseStructure($localConfig, $db, $sqlDirPath.$this->sqlUpgradeFile);

            // Grant rights
            $this->grantRightsToDatabaseObjects($localConfig, $db, $sqlDirPath.$this->sqlGrantFile);

            // Ajout du droit visualisation.donnees.brutes.selon.diffusion
            try{
                jAcl2DbManager::createRight(
                    'visualisation.donnees.brutes.selon.diffusion',
                    'occtax~jacl2.visualisation.donnees.brutes.selon.diffusion',
                    'naturaliz.subject.group'
                );
            } catch (Exception $e){
                jLog::log("Erreur lors de l'ajout du droit visualisation.donnees.brutes.selon.diffusion");
                jLog::log($e->getMessage());
            }

        }
    }
}
