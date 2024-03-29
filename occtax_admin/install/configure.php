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

class occtax_adminModuleConfigurator extends \Jelix\Installer\Module\Configurator {

    public function getDefaultParameters() {
        return array();
    }

    public function declareUrls(EntryPointUrlModifier $registerOnEntryPoint)
    {
        // set the occtax_admin url on the admin entrypoint
        $registerOnEntryPoint->havingName(
            'admin',
            array(
                new MapInclude('urls.xml', '/occtax_admin'),
            )
        );
    }


    function configure(\Jelix\Installer\Module\API\ConfigurationHelpers $helpers)
    {

    }
}