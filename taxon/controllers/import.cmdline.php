<?php
/**
* @package   lizmap
* @subpackage taxon
* @author    your name
* @copyright 2011 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class importCtrl extends jControllerCmdLine {

    /**
    * Parameters to the command line
     * 'method_name' => array('parameter_name' => true/false)
     * false means that the parameter is optionnal. All parameters which follow an optional parameter
     * is optional
    */
    protected $allowed_parameters = array(
    );

    /**
     * Options for the command line
    *  'method_name' => array('-option_name' => true/false)
    * true means that a value should be provided for the option on the command line
     */
    protected $allowed_options = array(
        'taxref' => array(
            '-source' => true,// Chemin complet vers le fichier de données TAXREF au format CSV
            '-menace' => true, // Chemin complet vers le fichier de menaces (listes rouges) au format CSV
            '-protection' => true, // Chemin complet vers le fichier des espèces protégées au format CSV
            '-version' => true, // Version du fichier Taxref. 9 par défaut
            '-dbprofile' => false // Jelix database profile name
        )
    );

    /**
     * Help
     *
     *
     */
    public $help = array(
        'taxref' => 'Import des données TAXREF dans la base de données.
        - Vous devez préciser le chemin vers le fichier source des données TAXREF via le paramètre source, et il sera copié dans le répertoire temporaire de votre serveur. Sinon, le script suppose que le chemin du fichier source de TAXREF est /tmp/TAXREF.txt
        - Vous devez préciser le chemin vers le fichier CSV séparé par tabulation et encodé en UTF-8, contenant les menaces (taxons issu des listes rouges, filtrés sur la région) : à télécharger sur le site de l INPN
        - Vous devez préciser le chemin vers le fichier CSV séparé par tabulation et encodé en UTF-8, contenant les espèces protégées : à télécharger sur le site de l INPN
        - Vous devez préciser la version via le paramètre version : 7, 8 ou 9.
        - Vous pouvez préciser un nom de profil de base de données (comme écrit dans le fichier lizmap/var/config/profiles.ini.php )

        Usage :
        php lizmap/scripts/script.php taxon~import:taxref -source [source] -menace [menace] -protection [protection] -version [version] -dbprofile [dbprofile]

        Exemple :
        php lizmap/scripts/script.php taxon~import:taxref -source /tmp/TAXREFv90.txt -menace /tmp/LR_Resultats_Guadeloupe_complet_export.csv -protection /tmp/PROTECTION_ESPECES_90.csv -version 9
        '
    );



    function index() {
        $rep = $this->getResponse(); // cmdline response by default
        $rep->addContent("Hello, it works !");
        return $rep;
    }


    /**
    * Import des données TAXREF dans la base de données.
    *
    */
    public function taxref() {

        $rep = $this->getResponse(); // cmdline response by default

        //~ // Get version number given
        $version = $this->option('-version', '9');

        // Get import file
        $sqlPath = jApp::getModulePath('taxon') . 'install/sql/import.taxref.' . $version . '.pgsql.sql';
        if( !file_exists( $sqlPath ) )
            throw new jException('taxon~script.import.script.not.found');
        $sqlPathAfter = jApp::getModulePath('taxon') . 'install/sql/import.taxref.after.pgsql.sql';

        // Get file to import
        $tmpFolder = sys_get_temp_dir();
        $defaultSourcePath = $tmpFolder . '/TAXREF.txt';
        $menaceSourcePath = $tmpFolder . '/LR_Resultats_Guadeloupe_complet_export.csv';
        $protectionSourcePath = $tmpFolder . '/PROTECTION_ESPECES_90.csv';
        $source = $this->option('-source', $defaultSourcePath );
        $menace = $this->option('-menace', $menaceSourcePath );
        $protection = $this->option('-protection', $protectionSourcePath );
        if( !file_exists( $source ) )
            throw new jException('taxon~script.import.source.not.found');
        if( !file_exists( $menace ) )
            throw new jException('taxon~script.import.menace.not.found');
        if( !file_exists( $protection ) )
            throw new jException('taxon~script.import.protection.not.found');

        // Copy source data to temporary folder
        copy($source, $defaultSourcePath );
        copy($menace, $menaceSourcePath );
        copy($protection, $protectionSourcePath );

        // Get default profile
        $profileConfig = jApp::configPath('profiles.ini.php');
        $ini = new jIniFileModifier( $profileConfig );
        $defaultProfile = $ini->getValue( 'default', 'jdb' );

        // Try to use the optional given db profile
        $cnx = jDb::getConnection( $defaultProfile );
        $userprofile = $this->option('-dbprofile', '' );
        if( !empty($userprofile) ){
            try {
                $cnx = jDb::getConnection( $userprofile );
            } catch ( Exception $e ) {
                $cnx = jDb::getConnection( $defaultProfile );
            }
        }

        // Get content of SQL template script
        $sqlTpl = jFile::read( $sqlPath );
        $sqlTplAfter = jFile::read( $sqlPathAfter );
        $tpl = new jTpl();
        $assign = array();

        // Replace source path in SQL script and run import
        $assign['source'] = $defaultSourcePath ;
        $assign['menace'] = $menaceSourcePath ;
        $assign['protection'] = $protectionSourcePath ;

        // Get the field corresponding to local for TAXREF among fr, gf, mar, gua, sm, sb, spm, may, epa, reu, taff, pf, nc, wf, cli
        $localConfig = jApp::configPath('localconfig.ini.php');
        $ini = new jIniFileModifier($localConfig);
        $colonne_locale = $ini->getValue('colonne_locale', 'taxon');
        if( !$colonne_locale )
            $colonne_locale = 'fr';
        $assign['colonne_locale'] = $colonne_locale;

        // Get the list of protection codes
        $code_arrete_protection = $ini->getValue('code_arrete_protection', 'taxon');
        if( !$code_arrete_protection )
            $code_arrete_protection = '';
        $code_arrete_protection = array_map( 'trim', explode(',', $code_arrete_protection ) );
        $code_arrete_protection = "'" . implode( "', '" , $code_arrete_protection ) . "'";
        $assign['code_arrete_protection'] = $code_arrete_protection;

        // Run structure changes queries
        // Use try catch because IF NOT EXISTS is not supported by old PG
        $sql = "ALTER TABLE taxref ADD COLUMN cd_sup integer;";
        try {
            $cnx->exec( $sql );
        } catch ( Exception $e ) {
            jLog::log( $e->getMessage(), 'error' );
        }

        // Run import query
        $tpl->assign( $assign );
        $sql = $tpl->fetchFromString($sqlTpl, 'text');
        $sqlAfter = $tpl->fetchFromString($sqlTplAfter, 'text');
        $sql = $sql . $sqlAfter;
        try {
            $cnx->exec( $sql );
        } catch ( Exception $e ) {
            jLog::log( $e->getMessage(), 'error' );
            throw new jException('taxon~script.import.error');
        }

        return $rep;
    }
}
