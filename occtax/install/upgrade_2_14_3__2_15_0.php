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
require_once(__DIR__.'/upgradeTrait.php');
class occtaxModuleUpgrader_2_14_3__2_15_0 extends jInstallerModule //\Jelix\Installer\Module\Installer
{
    use upgradeTrait;

    public $targetVersions = array(
        '2.15.0',
    );
    public $date = '2023-03-29';

    protected $sqlUpgradeFile = 'upgrade/upgrade_2.14.3_2.15.0.sql';

    protected $sqlGrantFile = 'grant_rights.sql';

    //function install(\Jelix\Installer\Module\API\InstallHelpers $helpers)
    function install()
    {
        if ($this->firstDbExec()) {
            // Get path
            // $sqlDirPath = $this->getPath() . 'install/sql/';
            $sqlDirPath = $this->path.'install/sql/';

            // Get database connection
            // $helpers->database()->useDbProfile('jauth_super');
            // $db = $helpers->database()->dbConnection();
            $this->useDbProfile('jauth_super');
            $db = $this->dbConnection(); // A PLACER TOUJOURS DERRIERE $this->useDbProfile('jauth_super');

            // Naturaliz specific config file
            // $localConfig = jApp::varConfigPath('naturaliz.ini.php');
            $localConfig = jApp::configPath('naturaliz.ini.php');

            // Upgrade structure
            $this->upgradeDatabaseStructure($localConfig, $db, $sqlDirPath.$this->sqlUpgradeFile);

            // Grant rights
            $this->grantRightsToDatabaseObjects($localConfig, $db, $sqlDirPath.$this->sqlGrantFile);

            // Modifier le fichier de configuration naturaliz.ini.php
            // Get configuration from ini file
            $ini = new jIniFileModifier($localConfig);
            // Champs pour lesquels chercher / remplacer du contenu
            $configConcernedFields = array(
                'observation_card_fields',
                'observation_card_fields_unsensitive',
                'observation_exported_fields',
                'observation_exported_fields_unsensitive',

            );
            // Champs renommés dans le standard
            $renamed_fields = array(
                'identifiant_origine' => 'id_origine',
                'identifiant_permanent' => 'id_sinp_occtax',
                'jdd_metadonnee_dee_id' => 'id_sinp_jdd',
                'obs_methode' => 'obs_technique',
            );
            // Champs supprimés du standard
            $deleted_fields = array(
                'jdd_source_id',
                'sensible',
                'organisme_standard',
            );
            foreach($configConcernedFields as $item) {
                $oldContent = $ini->getValue($item, 'naturaliz');
                if (empty($oldContent)) {
                    continue;
                }
                # Champs renommés
                foreach($renamed_fields as $old=>$new) {
                    $newContent = str_replace($old, $new, $oldContent);
                    $ini->setValue($item, $newContent, 'naturaliz');
                }
                # Champs supprimés
                foreach($deleted_fields as $old) {
                    $newContent = str_replace($old, '', $oldContent);
                    $ini->setValue($item, $newContent, 'naturaliz');
                }

            }
            $ini->save();
        }
    }
}
