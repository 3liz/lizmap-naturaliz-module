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
            'wfs_url_sandre' => false, // URL of the INPN WFS server.
        ),

        'shapefile' => array(
            'communes' => true, // Full path to commune Shapefile
            'maille_01' => true, // Full path to maille_01 Shapefile
            'maille_02' => true, // Full path to maille_02 Shapefile
            'maille_05' => true, // Full path to maille_05 Shapefile
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

        'wfs' => 'Import des données des référentiels SIG depuis le WFS.

        Usage :
        php lizmap/scripts/script.php occtax~import:wfs [wfs_url] [wfs_url_sandre]

        Exemple :
        php lizmap/scripts/script.php occtax~import:wfs http://ws.carmencarto.fr/WFS/119/glp_inpn http://services.sandre.eaufrance.fr/geo/mdo_GLP
        ',



        'shapefile' => 'Import des données des référentiels SIG depuis des ShapeFile.

        Passer le chemin complet vers les fichiers de communes, mailles 1x1km, mailles 2x2km, réserves naturelles nationales et les habitats les habitats. Les réserves sont optionnelles. Les habitats aussi.

        Usage :
        php lizmap/scripts/script.php occtax~import:shapefile [communes] [maille_01] [maille_02] [maille_05] [reserves_naturelles_nationales] [habitat_mer] [habitat_terre]

        Exemple :
        php lizmap/scripts/script.php occtax~import:shapefile /tmp/communes.shp /tmp/maille_01.shp /tmp/maille_02.shp /tmp/maille_05.shp /tmp/reserves_naturelles_nationales.shp /tmp/TYPO_ANT_MER_09-01-2011.xls /tmp/EAR_Guadeloupe.csv
        ',
    );


    /**
    * Import des données référentiels depuis un serveur WFS
    *
    */
    public function wfs() {

        $rep = $this->getResponse(); // cmdline response by default

        // Get WFS url
        $wfs_url = $this->param('wfs_url', 'http://ws.carmencarto.fr/WFS/119/glp_inpn');
        $wfs_url_sandre = $this->param('wfs_url_sandre', 'http://services.sandre.eaufrance.fr/geo/mdo_GLP');

        // Get import file
        $importFile = jApp::getModulePath('occtax') . 'install/scripts/import_referentiels_sig_wfs.tpl';
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
        $assign['wfs_url'] = $wfs_url;
        $assign['wfs_url_sandre'] = $wfs_url_sandre;
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

        if( count($output) > 0 ){
            $outputStr=implode('<br />',$output);
            throw new jException( 'occtax~import.ogr2ogr.error', array( $outputStr ) );
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
        $assign['maille_01'] = $maille_01;
        $assign['maille_02'] = $maille_02;
        $assign['maille_05'] = $maille_05;
        $assign['reserves_naturelles_nationales'] = $reserves_naturelles_nationales;
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
