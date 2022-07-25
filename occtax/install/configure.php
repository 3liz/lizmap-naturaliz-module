<?php

/**
 * @author    Laurent Jouanneau
 * @copyright 2022 3liz
 *
 * @see      http://3liz.com
 *
 * @license    Mozilla Public Licence
 */

use Jelix\Routing\UrlMapping\EntryPointUrlModifier;
use Jelix\Routing\UrlMapping\MapEntry\MapInclude;
use Jelix\Routing\UrlMapping\MapEntry\ModuleUrl;

class occtaxModuleConfigurator extends \Jelix\Installer\Module\Configurator {

    public function getDefaultParameters() {
        return array();
    }

    function configure(\Jelix\Installer\Module\API\ConfigurationHelpers $helpers)
    {
        // Copy export readme files
        $readmeDestinationPath = jApp::varConfigPath('occtax-export-LISEZ-MOI.csv.txt');
        if (!file_exists($readmeDestinationPath)) {
            $helpers->copyFile('config/LISEZ-MOI.csv.md', $readmeDestinationPath);
        }
        $readmeDestinationPath = jApp::varConfigPath('occtax-export-LISEZ-MOI.geojson.txt');
        if (!file_exists($readmeDestinationPath)) {
            $helpers->copyFile('config/LISEZ-MOI.geojson.md', $readmeDestinationPath);
        }

        // Copy naturaliz configuration file
        $naturalizConfigPath = jApp::varConfigPath('naturaliz.ini.php');
        if (!file_exists($naturalizConfigPath)) {
            $helpers->copyFile('config/naturaliz.ini.php.dist', $naturalizConfigPath);
        }

    }
}
