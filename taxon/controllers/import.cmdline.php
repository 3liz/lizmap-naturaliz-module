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
            '-taxvern' => true,// Chemin complet vers le fichier de données TAXVERN au format CSV.
            '-taxvern_iso' => true,// Langue ISO `fra`, `rcf`
            '-menace' => true, // Chemin complet vers le fichier de menaces (listes rouges) au format CSV
            '-protection' => true, // Chemin complet vers le fichier des espèces protégées au format CSV
            '-version' => true, // Version du fichier Taxref. 11 par défaut
            '-correctionsql' => true, // Path to SQL file to correct some taxref data
            '-correctioncsv' => true, // Path to CSV file to correct some taxref data
            '-dbprofile' => true // Jelix database profile name
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
        - Vous devez préciser le chemin vers le fichier des données TAXVERN (noms vernaculaires). Vous pouvez mettre "non" si le fichier ne doit pas être pris en compte
        - Vous devez préciser le code ISO de langue des noms vernaculaires, disponible dans le champs iso639_3 de TAXVERN
        - Vous devez préciser le chemin vers le fichier CSV séparé par tabulation et encodé en UTF-8, contenant les menaces (taxons issu des listes rouges, filtrés sur la région) : à télécharger sur le site de l INPN
        - Vous devez préciser le chemin vers le fichier CSV séparé par tabulation et encodé en UTF-8, contenant les espèces protégées : à télécharger sur le site de l INPN
        - Vous devez préciser la version via le paramètre version : 7, 8, 9, 10 ou 11.
        - Vous pouvez donner un fichier SQL à lancer après import du taxref pour corriger certaines données. On peut utiliser un csv source à préciser ensuite : -correctionsql
        - Si le script de correction SQL attend un fichier CSV, vous pouvez fournir son chemin ici : -correctioncsv
        - Vous pouvez préciser un nom de profil de base de données (comme écrit dans le fichier lizmap/var/config/profiles.ini.php )

        Usage :
        php lizmap/scripts/script.php taxon~import:taxref -source [source] -taxvern [taxvern] -taxvern_iso [taxvern_iso] -menace [menace] -protection [protection] -version [version] -dbprofile [dbprofile]

        Exemple :
        php lizmap/scripts/script.php taxon~import:taxref -source /tmp/TAXREFv11.txt -taxvern /tmp/TAXVERNv11.txt -taxvern_iso rcf -menace /tmp/LR_Resultats_Guadeloupe_complet_export.csv -protection /tmp/PROTECTION_ESPECES_11.csv -version 11
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
        $version = $this->option('-version', '11');

        // Get import file
        $sqlPath = jApp::getModulePath('taxon') . 'install/sql/import.taxref.' . $version . '.pgsql.sql';
        if( !file_exists( $sqlPath ) )
            throw new jException('taxon~script.import.script.not.found');
        $sqlPathAfter = jApp::getModulePath('taxon') . 'install/sql/import.taxref.after.pgsql.sql';

        // Get file to import
        $tmpFolder = sys_get_temp_dir();
        $defaultSourcePath = $tmpFolder . '/TAXREF.txt';
        $taxvernSourcePath = $tmpFolder . '/TAXVERN.txt';
        $menaceSourcePath = $tmpFolder . '/LR_Resultats_Guadeloupe_export.csv';
        $protectionSourcePath = $tmpFolder . '/PROTECTION_ESPECES_11.csv';
        $source = $this->option('-source', $defaultSourcePath );
        $taxvern = $this->option('-taxvern', $taxvernSourcePath );
        $taxvern_iso = $this->option('-taxvern_iso', 'fra' );
        $menace = $this->option('-menace', $menaceSourcePath );
        $protection = $this->option('-protection', $protectionSourcePath );
        if( !file_exists( $source ) )
            throw new jException('taxon~script.import.source.not.found');
        $has_taxvern = True;
        if( !file_exists( $taxvern ) ){
            $has_taxvern = False;
            $taxvern = False;
            $taxvern_iso = 'fra';
            $taxvernSourcePath = Null;
        }
        if( !file_exists( $menace ) )
            throw new jException('taxon~script.import.menace.not.found');
        if( !file_exists( $protection ) )
            throw new jException('taxon~script.import.protection.not.found');

        // Copy source data to temporary folder
        copy($source, $defaultSourcePath );
        if($has_taxvern)
            copy($taxvern, $taxvernSourcePath );
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
        $assign['source'] = $defaultSourcePath;
        $assign['taxvern'] = $taxvernSourcePath;
        $assign['taxvern_iso'] = $taxvern_iso;
        $assign['menace'] = $menaceSourcePath ;
        $assign['protection'] = $protectionSourcePath;

        // Get the field corresponding to local for TAXREF among fr, gf, mar, gua, sm, sb, spm, may, epa, reu, taff, pf, nc, wf, cli
        $localConfig = jApp::configPath('localconfig.ini.php');
        $ini = new jIniFileModifier($localConfig);
        $colonne_locale = $ini->getValue('colonne_locale', 'taxon');
        if( !$colonne_locale )
            $colonne_locale = 'fr';
        $assign['colonne_locale'] = $colonne_locale;

        // Get endemicite description
        $endemicite_description_endemique = $ini->getValue('endemicite_description_endemique', 'taxon');
        if( !$endemicite_description_endemique )
            $endemicite_description_endemique = '';
        $assign['endemicite_description_endemique'] = $endemicite_description_endemique;

        $endemicite_description_subendemique = $ini->getValue('endemicite_description_subendemique', 'taxon');
        if( !$endemicite_description_subendemique )
            $endemicite_description_subendemique = '';
        $assign['endemicite_description_subendemique'] = $endemicite_description_subendemique;

        // Get the list of protection codes
        $liste_codes = array(
                'code_arrete_protection_simple',
                'code_arrete_protection_nationale',
                'code_arrete_protection_internationale',
                'code_arrete_protection_communautaire'
        );
        foreach($liste_codes as $code ){
                $cd = $ini->getValue($code, 'taxon');
                if( !$cd )
                    $cd = '';
                $code_arrete_protection = array_map( 'trim', explode(',', $cd ) );
                $code_arrete_protection = "'" . implode( "', '" , $code_arrete_protection ) . "'";
                $assign[$code] = $code_arrete_protection;
        }

        // Run structure changes queries
        // Use try catch because IF NOT EXISTS is not supported by old PG
        $newcols = array('cd_sup'=>'integer', 'sous_famille'=>'text', 'tribu'=>'text');
        foreach($newcols as $newcol => $format){
            $sql = "ALTER TABLE taxref ADD COLUMN $newcol $format;";
            try {
                $cnx->exec( $sql );
            } catch ( Exception $e ) {
                jLog::log( $e->getMessage(), 'error' );
            }
        }

        // Run import query
        $tpl->assign( $assign );
        $sql = $tpl->fetchFromString($sqlTpl, 'text');

        $sqlAfter = $tpl->fetchFromString($sqlTplAfter, 'text');

        // Optionally correction sql
        $sqlCorrection = '';
        $cor_sql = $this->option('-correctionsql', '' );
        $cor_csv = $this->option('-correctioncsv', '' );
        if( !empty($cor_sql) and !empty($cor_sql)
            and is_file($cor_sql) and is_file($cor_csv)
        ){
            $target_csv = $tmpFolder . '/taxref_correction.csv';
            copy($cor_csv, $target_csv );
            $tpl_c = new jTpl();
            $assign_c = array();
            $assign_c['source'] = $target_csv ;
            $tpl_c->assign( $assign_c );
            $sqlCorrection = $tpl_c->fetchFromString(jFile::read($cor_sql), 'text');
        }

        $sql = $sql . $sqlCorrection . $sqlAfter;

        try {
            $cnx->exec( $sql );
        } catch ( Exception $e ) {
            jLog::log( 'Error while executing the SQL below:', 'error' );
            jLog::log($sql, 'error');
            jLog::log( $e->getMessage(), 'error' );
            throw new jException('taxon~script.import.error');
        }

        return $rep;
    }
}
