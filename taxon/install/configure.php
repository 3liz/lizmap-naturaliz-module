<?php

/**
 * @author    Laurent Jouanneau
 * @copyright 2022 3liz
 *
 * @see      http://3liz.com
 *
 * @license    All rights reserved
 */

use Jelix\Routing\UrlMapping\EntryPointUrlModifier;
use Jelix\Routing\UrlMapping\MapEntry\MapInclude;
use Jelix\Routing\UrlMapping\MapEntry\ModuleUrl;

class taxonModuleConfigurator extends \Jelix\Installer\Module\Configurator {

    public function getDefaultParameters() {
        return array();
    }

    function configure(\Jelix\Installer\Module\API\ConfigurationHelpers $helpers)
    {
        // Copy taxon configuration
        $taxonConfFile = jApp::configPath('taxon.ini.php');
        if (!file_exists($taxonConfFile)) {
            $helpers->copyFile('config/taxon.ini.php', $taxonConfFile);
        }

        $helpers->copyDirectoryContent('www', jApp::wwwPath());
    }
}