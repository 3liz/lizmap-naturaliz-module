<?php
/**
* @package   lizmap
* @subpackage mascarine
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
        'gdalogr' => array(
            'mnt' => true, // Full path to the dem raster containing elevation
            'habite' => true, // Full path to lieudit_habite Shapefile
            'non_habite' => false, // Full path to lieudit_non_habite Shapefile
            'oronyme' => false, // Full path to lieudit_oronyme Shapefile
            'toponyme_divers' => false // Full path to lieudit_toponyme_divers Shapefile
        )
    );

    /**
     * Help
     *
     *
     */
    public $help = array(

        'gdalogr' => 'Import des données des référentiels SIG depuis des ShapeFile et des raster.

        Passer le chemin complet vers les fichiers MNT, de lieu-dit habités, lieu-dit non habités, oronymes et toponymes divers. Seul le modèle numérique de terrain et les lieu-dit habités sont recquis.

        Usage :
        php lizmap/scripts/script.php occtax~import:gdalogr [mnt] [habite] [non_habite] [oronyme] [toponyme_divers]

        Exemple :
        php lizmap/scripts/script.php mascarine~import:gdalogr /tmp/DEPT971.asc /tmp/LIEU_DIT_HABITE.shp /tmp/LIEU_DIT_NON_HABITE.shp /tmp/ORONYME.shp /tmp/TOPONYME_DIVERS.shp
        ',
    );

    /**
    * Import des données référentiels depuis les données mnt et shapefile
    *
    */
    public function gdalogr() {

        $rep = $this->getResponse(); // cmdline response by default

        // Get parameters
        $mnt = $this->param('mnt');
        $habite = $this->param('habite');
        $non_habite = $this->param('non_habite');
        $oronyme = $this->param('oronyme');
        $toponyme_divers = $this->param('toponyme_divers');

        // Get import file
        $importFile = jApp::getModulePath('mascarine') . 'install/scripts/import_referentiels_sig_gdalogr.tpl';
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
        $assign['mnt'] = $mnt;
        $assign['habite'] = $habite;
        $assign['non_habite'] = $non_habite;
        $assign['oronyme'] = $oronyme;
        $assign['toponyme_divers'] = $toponyme_divers;
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
