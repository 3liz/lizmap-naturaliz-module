<?php
/**
* @package   lizmap
* @subpackage gestion
* @author    3liz
* @copyright 2016 3liz
* @link      http://3liz.com
* @license    Mozilla Public Licence
*/


class gestionModuleInstaller extends jInstallerModule {

    function install() {

        // Install gestion structure into database if needed
        if ($this->firstDbExec()) {

            // Droits : Pouvoir voir toutes les données non filtrées même si pas de demande
            jAcl2DbManager::addSubject( 'visualisation.donnees.non.filtrees', 'occtax~jacl2.visualisation.donnees.non.filtrees', 'naturaliz.subject.group');
            jAcl2DbManager::setRightsOnGroup(
                'admins',
                array(
                    'visualisation.donnees.non.filtrees'=>true
                )
            );


        }
    }
}
