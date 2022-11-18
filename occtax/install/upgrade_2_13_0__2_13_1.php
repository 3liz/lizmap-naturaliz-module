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
require_once(__DIR__ . '/upgradeTrait.php');
class occtaxModuleUpgrader_2_13_0__2_13_1 extends jInstallerModule //\Jelix\Installer\Module\Installer
{
    use upgradeTrait;

    public $targetVersions = array(
        '2.13.1',
    );
    public $date = '2022-11-18';

    protected $sqlUpgradeFile = 'upgrade/upgrade_2.13.0_2.13.1.sql';

    protected $sqlGrantFile = 'grant_rights.sql';

    //function install(\Jelix\Installer\Module\API\InstallHelpers $helpers)
    function install()
    {
        // Get path
        // $sqlDirPath = $this->getPath() . 'install/sql/';
        $sqlDirPath = $this->path . 'install/sql/';

        // Get database connection
        // $helpers->database()->useDbProfile('jauth_super');
        // $db = $helpers->database()->dbConnection();
        $this->useDbProfile('jauth_super');
        $db = $this->dbConnection(); // A PLACER TOUJOURS DERRIERE $this->useDbProfile('jauth_super');

        // Naturaliz specific config file
        // $localConfig = jApp::varConfigPath('naturaliz.ini.php');
        $localConfig = jApp::configPath('naturaliz.ini.php');

        // Upgrade structure
        $this->upgradeDatabaseStructure($localConfig, $db, $sqlDirPath . $this->sqlUpgradeFile);

        // Grant rights
        $sqlPath = $sqlDirPath . $this->sqlGrantFile;
        $this->grantRightsToDatabaseObjects($localConfig, $db, $sqlDirPath . $this->sqlUpgradeFile);
    }
}
