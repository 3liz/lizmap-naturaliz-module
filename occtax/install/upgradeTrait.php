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

trait upgradeTrait
{
    /**
     * Launch the SQL upgrade script.
     */
    protected function upgradeDatabaseStructure($localConfig, $db, $sqlPath)
    {
        // Parse naturaliz ini file and get needed values
        $ini = parse_ini_file($localConfig, true);
        $srid = '2975';
        if (array_key_exists('naturaliz', $ini) && array_key_exists('srid', $ini['naturaliz'])) {
            $srid = $ini['naturaliz']['srid'];
        }
        $colonne_locale = 'reu';
        if (array_key_exists('naturaliz', $ini) && array_key_exists('colonne_locale', $ini['naturaliz'])) {
            $colonne_locale = $ini['naturaliz']['colonne_locale'];
        }
        $liste_rangs = 'FM, GN, AGES, ES, SSES, NAT, VAR, SVAR, FO, SSFO, RACE, CAR, AB';
        if (array_key_exists('naturaliz', $ini) && array_key_exists('liste_rangs', $ini['naturaliz'])) {
            $liste_rangs = $ini['naturaliz']['liste_rangs'];
        }
        $liste_rangs = "'" . implode(
            "', '",
            array_map('trim', explode(',', $liste_rangs))
        ) . "'";

        // Read SQL template file
        $sqlTpl = jFile::read($sqlPath);

        // Assign template variables
        $tpl = new jTpl();
        $tpl->assign('SRID', $srid); // CAREFUL, SRID variable must be UPPERCASE
        $tpl->assign('colonne_locale', $colonne_locale);
        $tpl->assign('liste_rangs', $liste_rangs);
        $sql = $tpl->fetchFromString($sqlTpl, 'text');

        // Run SQL query
        $db->exec($sql);
    }

    /**
     * Grant the rights to all the database object for the "read-only"
     * declared user.
     *
     */
    protected function grantRightsToDatabaseObjects($localConfig, $db, $sqlPath)
    {

        // Parse naturaliz ini file and get needed values
        $ini = parse_ini_file($localConfig, true);
        $dbuser_readonly = 'naturaliz';
        if (array_key_exists('naturaliz', $ini) && array_key_exists('dbuser_readonly', $ini['naturaliz'])) {
            $dbuser_readonly = $ini['naturaliz']['dbuser_readonly'];
        }
        $dbuser_owner = 'naturaliz';
        if (array_key_exists('naturaliz', $ini) && array_key_exists('dbuser_owner', $ini['naturaliz'])) {
            $dbuser_owner = $ini['naturaliz']['dbuser_owner'];
        }

        // Get database name
        $prof = jProfiles::get('jdb', $this->dbProfile, true);

        // Read SQL template file
        $sqlTpl = jFile::read($sqlPath);

        // Assign template variables
        $tpl = new jTpl();
        $tpl->assign('DBUSER_READONLY', $dbuser_readonly);
        $tpl->assign('DBUSER_OWNER', $dbuser_owner);
        $tpl->assign('DBNAME', $prof['database']);
        $sql = $tpl->fetchFromString($sqlTpl, 'text');

        // Try to reapply some rights on possibly newly created tables
        // If it fails, no worries as it can be done manually after upgrade
        try {
            // Run SQL query
            $db->exec($sql);
        } catch (Exception $e) {
            jLog::log("Upgrade - Rights where not reapplied on database objects", 'error');
            jLog::log($e->getMessage(), 'error');
        }
    }
}
