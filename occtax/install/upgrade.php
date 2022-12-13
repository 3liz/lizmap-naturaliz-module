<?php

/**
 * @package   lizmap
 * @subpackage occtax
 * @author    3liz
 * @copyright 2011-2019 3liz
 * @link      http://3liz.com
 * @license   Mozilla Public License : http://www.mozilla.org/MPL/
 */

class occtaxModuleUpgrader extends jInstallerModule
{

    function install()
    {
        // Copy CSS and JS assets
        // We use overwrite to be sure the new versions of the JS files
        // will be used
        $overwrite = true;
        $this->copyDirectoryContent('www', jApp::wwwPath(), $overwrite);
    }
}
