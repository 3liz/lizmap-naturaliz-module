<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    your name
* @copyright 2011 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class importCtrl extends jControllerCmdLine {

    /**
    * Options to the command line
    *  'method_name' => array('-option_name' => true/false)
    * true means that a value should be provided for the option on the command line
    */
    protected $allowed_options = array(
    );

    /**
     * Parameters for the command line
     * 'method_name' => array('parameter_name' => true/false)
     * false means that the parameter is optionnal. All parameters which follow an optional parameter
     * is optional
     */
    protected $allowed_parameters = array(
        'wfs' => array(
            'wfs_url' => false, // URL of the INPN WFS server. Example : http://ws.carmencarto.fr/WFS/119/glp_inpn
            'wfs_url_sandre' => false, // URL of the Sandre WFS server.
            'wfs_url_grille' => false // URL of the INPN WFS giving the 10x10km grid.
        ),

        'shapefile' => array(
            'communes' => true, // Full path to commune Shapefile
            'maille_01' => true, // Full path to maille_01 Shapefile
            'maille_02' => true, // Full path to maille_02 Shapefile
            'maille_05' => true, // Full path to maille_05 Shapefile
            'maille_10' => true, // Full path to maille_10 Shapefile
            'reserves_naturelles_nationales' => false, // Full path to Shapefile reserves naturelles,
            'habitat_mer' => false, // Full path to the marine habitat file : http://inpn.mnhn.fr/telechargement/referentiels/habitats#habitats_marins_om
            'habitat_terre' => false // Full path to the terestrial habitat source

        )
    );

    /**
     * Help
     *
     *
     */
    public $help = array(


        'purge' => 'Purge les données des référentiels dans les tables.

        Usage :
        php lizmap/scripts/script.php occtax~import:purge
        ',

        'wfs' => 'Import des données des référentiels SIG depuis le WFS.

        Usage :
        php lizmap/scripts/script.php occtax~import:wfs [wfs_url] [wfs_url_sandre] [wfs_url_grille]

        Exemple :
        php lizmap/scripts/script.php occtax~import:wfs http://ws.carmencarto.fr/WFS/119/glp_inpn http://services.sandre.eaufrance.fr/geo/mdo_GLP http://ws.carmencarto.fr/WFS/119/glp_grille
        ',



        'shapefile' => 'Import des données des référentiels SIG depuis des ShapeFile.

        Passer le chemin complet vers les fichiers de communes, mailles 1x1km, mailles 2x2km, réserves naturelles nationales et les habitats les habitats. Les réserves sont optionnelles. Les habitats aussi.

        Usage :
        php lizmap/scripts/script.php occtax~import:shapefile [communes] [maille_01] [maille_02] [maille_05] [maille_10] [reserves_naturelles_nationales] [habitat_mer] [habitat_terre]

        Exemple :
        php lizmap/scripts/script.php occtax~import:shapefile /tmp/communes.shp /tmp/maille_01.shp /tmp/maille_02.shp /tmp/maille_05.shp /tmp/maille_10.shp /tmp/reserves_naturelles_nationales.shp /tmp/TYPO_ANT_MER_09-01-2011.xls /tmp/EAR_Guadeloupe.csv
        ',
    );


    /**
    * Purge les données de référentiels (pour faciliter réimport)
    *
    */
    public function purge() {

        $rep = $this->getResponse(); // cmdline response by default

        // Get default profile
        $profileConfig = jApp::configPath('profiles.ini.php');
        $ini = new jIniFileModifier( $profileConfig );
        $defaultProfile = $ini->getValue( 'default', 'jdb' );

        // Try to use the optional given db profile
        $cnx = jDb::getConnection( $defaultProfile );

        $sql = "BEGIN;
        TRUNCATE sig.commune RESTART IDENTITY;
        TRUNCATE sig.departement RESTART IDENTITY;
        TRUNCATE sig.espace_naturel RESTART IDENTITY;
        TRUNCATE sig.masse_eau RESTART IDENTITY;
        TRUNCATE sig.maille_01 RESTART IDENTITY;
        TRUNCATE sig.maille_02 RESTART IDENTITY;
        TRUNCATE sig.maille_05 RESTART IDENTITY;
        TRUNCATE sig.maille_10 RESTART IDENTITY;
        COMMIT;
        ";

        try {
            $cnx->exec( $sql );
        } catch ( Exception $e ) {
            jLog::log( $e->getMessage(), 'error' );
        }

        return $rep;

    }


    /**
    * Import des données référentiels depuis un serveur WFS
    *
    */
    public function wfs() {

        $rep = $this->getResponse(); // cmdline response by default

        $localConfig = jApp::configPath('localconfig.ini.php');
        $ini = new jIniFileModifier($localConfig);

        $assign = array();

        // Get WFS url
        $wfs_url = $this->param('wfs_url');
        $wfs_url_sandre = $this->param('wfs_url_sandre');
        $wfs_url_grille = $this->param('wfs_url_grille');

        if( empty($wfs_url) )
            $wfs_url = $ini->getValue('wfs_url', 'occtax');
        if( empty($wfs_url) )
            $wfs_url = 'http://ws.carmencarto.fr/WFS/119/glp_inpn';

        if( empty($wfs_url_sandre) )
            $wfs_url_sandre = $ini->getValue('wfs_url_sandre', 'occtax');
        if( empty($wfs_url_sandre) )
            $wfs_url_sandre = 'http://services.sandre.eaufrance.fr/geo/mdo_GLP';

        if( empty($wfs_url_grille) )
            $wfs_url_grille = $ini->getValue('wfs_url_grille', 'occtax');
        if( empty($wfs_url_grille) )
            $wfs_url_grille = 'http://ws.carmencarto.fr/WFS/119/glp_grille';

        $assign['wfs_url'] = $wfs_url;
        $assign['wfs_url_sandre'] = $wfs_url_sandre;
        $assign['wfs_url_grille'] = $wfs_url_grille;

        // Get import file
        $importFile = jApp::getModulePath('occtax') . 'install/scripts/import_referentiels_sig_wfs.tpl';
        if( !file_exists( $importFile ) )
            throw new jException('occtax~script.import.script.not.found');

        // Get default profile
        $profileConfig = jApp::configPath('profiles.ini.php');
        $pini = new jIniFileModifier( $profileConfig );
        $defaultProfile = $pini->getValue( 'default', 'jdb' );

        // Get content of SQL template script
        $template = jFile::read( $importFile );
        $tpl = new jTpl();

        // Replace parameters in template
        $assign['dbhost'] = $pini->getValue( 'host', 'jdb:' . $defaultProfile );
        $assign['dbname'] = $pini->getValue( 'database', 'jdb:' . $defaultProfile );
        $assign['dbuser'] = $pini->getValue( 'user', 'jdb:' . $defaultProfile );
        $assign['dbpassword'] = $pini->getValue( 'password', 'jdb:' . $defaultProfile );
        $assign['dbport'] = $pini->getValue( 'port', 'jdb:' . $defaultProfile );

        $assign['dbschema'] = 'sig';

        $srid = $ini->getValue('srid', 'naturaliz');
        if( !$srid )
            $srid = '4326';
        $assign['srid'] = $srid;

        // Some typenames are different for different carmen WFS servers
        $znieff1_terre = $ini->getValue('znieff1_terre', 'occtax');
        if( !$znieff1_terre )
            $znieff1_terre = 'Znieff1';
        $assign['znieff1_terre'] = $znieff1_terre;

        $znieff1_mer = $ini->getValue('znieff1_mer', 'occtax');
        if( !$znieff1_mer )
            $znieff1_mer = 'Znieff1_mer';
        $assign['znieff1_mer'] = $znieff1_mer;

        $znieff2_terre = $ini->getValue('znieff2_terre', 'occtax');
        if( !$znieff2_terre )
            $znieff2_terre = 'Znieff2';
        $assign['znieff2_terre'] = $znieff2_terre;

        $znieff2_mer = $ini->getValue('znieff2_mer', 'occtax');
        if( !$znieff2_mer )
            $znieff2_mer = 'Znieff2_mer';
        $assign['znieff2_mer'] = $znieff2_mer;

        // Run import
        $tpl->assign( $assign );
        $command = $tpl->fetchFromString($template, 'text');
        jLog::log($command);
        $script = $command;

        $output = array();
        $retVal = 1;
        exec( $script, $output, $retVal );
        $outputStr = '';

        if( count($output) > 0 ){
            $outputStr=implode('<br />',$output);
            jLog::log(  $outputStr );
        }

        //~ echo $script;

        return $rep;
    }

    /**
    * Import des données référentiels depuis les données shapefile
    *
    */
    public function shapefile() {

        $rep = $this->getResponse(); // cmdline response by default

        // Get parameters
        $communes = $this->param('communes');
        $maille_01 = $this->param('maille_01');
        $maille_02 = $this->param('maille_02');
        $maille_05 = $this->param('maille_05');
        $maille_10 = $this->param('maille_10');
        $reserves_naturelles_nationales = $this->param('reserves_naturelles_nationales');
        $habitat_mer = $this->param('habitat_mer');
        $habitat_terre = $this->param('habitat_terre');

        // Get import file
        $importFile = jApp::getModulePath('occtax') . 'install/scripts/import_referentiels_sig_shapefile.tpl';
        if( !file_exists( $importFile ) )
            throw new jException('occtax~script.import.script.not.found');

        // Get default profile
        $profileConfig = jApp::configPath('profiles.ini.php');
        $ini = new jIniFileModifier( $profileConfig );
        $defaultProfile = $ini->getValue( 'default', 'jdb' );

        // Get content of SQL template script
        $template = jFile::read( $importFile );
        $tpl = new jTpl();
        $assign = array();

        // Replace parameters in template
        $assign['communes'] = $communes;
        $assign['communes_name'] = pathinfo($communes, PATHINFO_FILENAME);
        $assign['maille_01'] = $maille_01;
        $assign['maille_01_name'] = pathinfo($maille_01, PATHINFO_FILENAME);
        $assign['maille_02'] = $maille_02;
        $assign['maille_02_name'] = pathinfo($maille_02, PATHINFO_FILENAME);
        $assign['maille_05'] = $maille_05;
        $assign['maille_05_name'] = pathinfo($maille_05, PATHINFO_FILENAME);
        $assign['maille_10'] = $maille_10;
        $assign['maille_10_name'] = pathinfo($maille_10, PATHINFO_FILENAME);
        $assign['reserves_naturelles_nationales'] = $reserves_naturelles_nationales;
        $assign['reserves_naturelles_nationales_name'] = pathinfo($reserves_naturelles_nationales, PATHINFO_FILENAME);
        $assign['habitat_mer'] = $habitat_mer;
        $assign['habitat_terre'] = $habitat_terre;
        $assign['dbhost'] = $ini->getValue( 'host', 'jdb:' . $defaultProfile );
        $assign['dbname'] = $ini->getValue( 'database', 'jdb:' . $defaultProfile );
        $assign['dbuser'] = $ini->getValue( 'user', 'jdb:' . $defaultProfile );
        $assign['dbpassword'] = $ini->getValue( 'password', 'jdb:' . $defaultProfile );
        $assign['dbport'] = $ini->getValue( 'port', 'jdb:' . $defaultProfile );
        $assign['dbschema'] = 'sig';

        $localConfig = jApp::configPath('localconfig.ini.php');
        $ini = new jIniFileModifier($localConfig);
        $srid = $ini->getValue('srid', 'naturaliz');
        if( !$srid )
            $srid = '4326';
        $assign['srid'] = $srid;

        // Run import
        $tpl->assign( $assign );
        $script = $tpl->fetchFromString($template, 'text');

        $output = array();
        $retVal = 1;
        exec( $script, $output, $retVal );
        $outputStr = '';

        if (count($output)>0){
            $outputStr=implode('<br />',$output);
            throw new jException( 'occtax~import.ogr2ogr.error', array( $outputStr ) );
        }

        //~ echo $script;

        return $rep;

    }

}
