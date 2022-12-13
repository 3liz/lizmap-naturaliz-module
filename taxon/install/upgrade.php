<?php

/**
 * @package   lizmap
 * @subpackage filter
 * @author    3liz
 * @copyright 2011-2019 3liz
 * @link      http://3liz.com
 * @license   Mozilla Public License : http://www.mozilla.org/MPL/
 */

class taxonModuleUpgrader extends jInstallerModule
{

    function install()
    {
        // Copy CSS and JS assets
        // We do not overwrite to avoid changing the taxon icons
        $overwrite = false;
        $this->copyDirectoryContent('www', jApp::wwwPath(), $overwrite);

        // We should overwrite the CSS file
        $overwrite = true;
        $this->copyFile('www/taxon/css/taxon.search.css', jApp::wwwPath() . '/taxon/css/taxon.search.css', $overwrite);
    }
}
