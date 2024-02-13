<?php

/**
 * @package   lizmap
 * @subpackage filter
 * @author    3liz
 * @copyright 2011-2024 3liz
 * @link      http://3liz.com
 * @license   Mozilla Public License : http://www.mozilla.org/MPL/
 */

class taxonModuleUpgrader extends \Jelix\Installer\Module\Installer
{
    public function install(\Jelix\Installer\Module\API\InstallHelpers $helpers)
    {
        // Copy CSS and JS assets
        // We do not overwrite to avoid changing the taxon icons
        $overwrite = false;
        $helpers->copyDirectoryContent('www', jApp::wwwPath(), $overwrite);

        // We should overwrite the CSS file
        $overwrite = true;
        $helpers->copyFile('www/taxon/css/taxon.search.css', jApp::wwwPath() . '/taxon/css/taxon.search.css', $overwrite);
    }
}
