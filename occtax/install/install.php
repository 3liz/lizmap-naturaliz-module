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
require_once(__DIR__.'/installTrait.php');

// class occtaxModuleInstaller extends \Jelix\Installer\Module\Installer
class occtaxModuleInstaller extends jInstallerModule
{
    use installTrait;

    // public function install(\Jelix\Installer\Module\API\InstallHelpers $helpers)
    public function install()
    {
        // Install database structure
        $sqlDirPath = $this->path.'install/sql/';
        $db = $this->dbConnection();
        // LWC >= 3.6
        // $sqlDirPath = $this->getPath() . 'install/sql/';
        // $db = $helpers->database()->dbConnection()
        $this->setupOcctaxDatabase($db, $sqlDirPath);

        // Add data for lists
        $this->execSQLScript('sql/data');
        // LWC >= 3.6
        // $helpers->database()->execSQLScript('sql/data');

        // Setup groups and rights
        $this->setupOcctaxRights();

        // Copy CSS and JS assets
        // We use overwrite to be sure the new versions of the JS files
        // will be used
        $overwrite = true;
        $this->copyDirectoryContent('www', jApp::wwwPath(), $overwrite);
    }
}
