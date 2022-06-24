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

class occtaxModuleInstaller extends \Jelix\Installer\Module\Installer
{
    use installTrait;

    public function install(\Jelix\Installer\Module\API\InstallHelpers $helpers)
    {

        //try {
            $this->setupOcctaxDatabase($helpers->database()->dbConnection(), $this->getPath().'install/sql/');
            // Add data for lists
            $helpers->database()->execSQLScript('sql/data');

        //} catch (Exception $e){
            //jLog::log("Cannot install PostgreSQL database structure");
            //jLog::log($e->getMessage());
        //}


        $this->setupOcctaxRights();

    }
}
