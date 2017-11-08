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
        'wfs' => array(
            '-wfs_url' => true, // URL of the INPN WFS server. Example : http://ws.carmencarto.fr/WFS/119/glp_inpn
            '-wfs_url_sandre' => true, // URL of the Sandre WFS server.
            '-wfs_url_grille' => true, // URL of the INPN WFS giving the 10x10km grid.

            '-znieff1_terre_version_en' => true,
            '-znieff1_mer_version_en' => true,
            '-znieff2_terre_version_en' => true,
            '-znieff2_mer_version_en' => true,
            '-ramsar_version_en' => true,
            '-cpn_version_en' => true,
            '-aapn_version_en' => true,
            '-scl_version_en' => true,
            '-rb_version_en' => true,
            '-mab_version_en' => true,
            '-apb_version_en' => true,
            '-cotieres_version_me' => true,
            '-cotieres_date_me' => true,
            '-souterraines_version_me' => true,
            '-souterraines_date_me' => true
        ),

        'shapefile' => array(
            '-commune' => true, // Full path to commune Shapefile
            '-maille_01' => true, // Full path to maille_01 Shapefile
            '-maille_02' => true, // Full path to maille_02 Shapefile
            '-maille_05' => true, // Full path to maille_05 Shapefile
            '-maille_10' => true, // Full path to maille_10 Shapefile
            '-reserves_naturelles_nationales' => true, // Full path to Shapefile reserves naturelles,
            '-habref' => true, // Full path to the HABREF csv file
            '-habitat_mer' => true, // Full path to the marine habitat file : http://inpn.mnhn.fr/telechargement/referentiels/habitats#habitats_marins_om
            '-habitat_terre' => true, // Full path to the terestrial habitat source

            '-commune_annee_ref' => true,
            '-departement_annee_ref' => true,
            '-maille_01_version_ref' => true,
            '-maille_01_nom_ref' => true,
            '-maille_02_version_ref' => true,
            '-maille_02_nom_ref' => true,
            '-maille_05_version_ref' => true,
            '-maille_05_nom_ref' => true,
            '-maille_10_version_ref' => true,
            '-maille_10_nom_ref' => true,
            '-rnn_version_en' => true
        ),

        'purge' => array(
            '-sig' => true, // list of tables to empty. Ex "commune,departement,maille_01,maille_02,maille_05,maille_10,espace_naturel,masse_eau"
            '-occtax' => true // list of tables to empty in schema occtax  Ex: habitat
        )
    );

    /**
     * Help
     *
     *
     */
    public $help = array(


        'purge' => 'Purge les données des référentiels dans les tables. On doit ajouter la liste des tables du schéma sig et du schéma occtax à supprimer

        Usage :
        php lizmap/scripts/script.php occtax~import:purge -sig "commune,departement,maille_01,maille_02,maille_05,maille_10,espace_naturel,masse_eau" -occtax "habitat"
        Ou pour une seule table
        php lizmap/scripts/script.php occtax~import:purge -sig commune
        ',


        'wfs' => 'Import des données des référentiels SIG depuis le WFS.

        Usage :
        php lizmap/scripts/script.php occtax~import:wfs -wfs_url [wfs_url] -wfs_url_sandre [wfs_url_sandre] -wfs_url_grille [wfs_url_grille] -znieff1_terre_version_en "2015-02" -znieff1_mer_version_en "2016-05" -znieff2_terre_version_en "2015-02" -znieff2_mer_version_en "2016-05" -ramsar_version_en "" -cpn_version_en "2015-10" -aapn_version_en "2015-10" -scl_version_en "2016-03" -mab_version_en "" -rb_version_en "2010" -apb_version_en "2012" -cotieres_version_me 2 -cotieres_date_me "2016-11-01" -souterraines_version_me 2 -souterraines_date_me "2016-11-01"

        Exemple :
        php lizmap/scripts/script.php occtax~import:wfs -wfs_url "http://ws.carmencarto.fr/WFS/119/glp_inpn" -wfs_url_sandre "http://services.sandre.eaufrance.fr/geo/mdo_GLP" -wfs_url_grille "http://ws.carmencarto.fr/WFS/119/glp_grille" -znieff1_terre_version_en "2015-02" -znieff1_mer_version_en "2016-05" -znieff2_terre_version_en "2015-02" -znieff2_mer_version_en "2016-05" -ramsar_version_en "" -cpn_version_en "2015-10" -aapn_version_en "2015-10" -scl_version_en "2016-03" -mab_version_en "" -rb_version_en "2010" -apb_version_en "2012" -cotieres_version_me 2 -cotieres_date_me "2016-11-01" -souterraines_version_me 2 -souterraines_date_me "2016-11-01"
        ',



        'shapefile' => 'Import des données des référentiels SIG depuis des ShapeFile.

        Passer le chemin complet vers les fichiers de communes, mailles 1x1km, mailles 2x2km, réserves naturelles nationales et les habitats les habitats. Les réserves sont optionnelles. Les habitats aussi.

        Usage :
        php lizmap/scripts/script.php occtax~import:shapefile -commune [communes] -maille_01 [maille_01] -maille_02 [maille_02] -maille_05 [maille_05] -maille_10 [maille_10]  -reserves_naturelles_nationales [reserves_naturelles_nationales] -habref [habref] -habitat_mer [habitat_mer] -habitat_terre [habitat_terre] -commune_annee_ref "2013" -departement_annee_ref "2013" -maille_01_version_ref "2015" -maille_01_nom_ref "Grille nationale (1km x 1km) Réunion" -maille_02_version_ref "2015" -maille_02_nom_ref "Grille nationale (2km x 2km) Réunion" -maille_05_version_ref "2015" -maille_05_nom_ref "Grille nationale (5km x 5km) Réunion" -maille_10_version_ref "2012" -maille_10_nom_ref "Grille nationale (10km x 10km) Réunion" -rnn_version_en "2010"

        Exemple :
        php lizmap/scripts/script.php occtax~import:shapefile -commune /tmp/communes.shp maille_01 /tmp/maille_01.shp -maille_02 /tmp/maille_02.shp -maille_05 /tmp/maille_05.shp -maille_10 /tmp/maille_10.shp -reserves_naturelles_nationales /tmp/reserves_naturelles_nationales.shp -habref /tmp/HABREF_20.csv -habitat_mer /tmp/TYPO_ANT_MER_09-01-2011.xls -habitat_terre /tmp/EAR_Guadeloupe.csv -commune_annee_ref "2013" -departement_annee_ref "2013" -maille_01_version_ref "2015" -maille_01_nom_ref "Grille nationale (1km x 1km) Réunion" -maille_02_version_ref "2015" -maille_02_nom_ref "Grille nationale (2km x 2km) Réunion" -maille_05_version_ref "2015" -maille_05_nom_ref "Grille nationale (5km x 5km) Réunion" -maille_10_version_ref "2012" -maille_10_nom_ref "Grille nationale (10km x 10km) Réunion" -rnn_version_en "2010"
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

        $sig = $this->option('-sig');
        $occtax = $this->option('-occtax');

        $sql = "BEGIN;";
        if($sig){
            $tables = array_map('trim', explode(',', $sig));
            foreach($tables as $table){
                $sql.= "TRUNCATE sig.".strtolower($table)." RESTART IDENTITY;";
            }
        }

        if($occtax){
            $tables = array_map('trim', explode(',', $occtax));
            foreach($tables as $table){
                $sql.= "TRUNCATE occtax.".strtolower($table)." RESTART IDENTITY;";
            }
        }

        $sql.= "COMMIT;";

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
        $wfs_url = $this->option('-wfs_url');
        $wfs_url_sandre = $this->option('-wfs_url_sandre');
        $wfs_url_grille = $this->option('-wfs_url_grille');

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

        // Replace options in template
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


        $assign['znieff1_terre_version_en'] = $this->option('-znieff1_terre_version_en');
        $assign['znieff1_mer_version_en'] = $this->option('-znieff1_mer_version_en');
        $assign['znieff2_terre_version_en'] = $this->option('-znieff2_terre_version_en');
        $assign['znieff2_mer_version_en'] = $this->option('-znieff2_mer_version_en');
        $assign['ramsar_version_en'] = $this->option('-ramsar_version_en');
        $assign['cpn_version_en'] = $this->option('-cpn_version_en');
        $assign['aapn_version_en'] = $this->option('-aapn_version_en');
        $assign['scl_version_en'] = $this->option('-scl_version_en');
        $assign['mab_version_en'] = $this->option('-mab_version_en');
        $assign['rb_version_en'] = $this->option('-rb_version_en');
        $assign['apb_version_en'] = $this->option('-apb_version_en');
        $assign['cotieres_version_me'] = $this->option('-cotieres_version_me');
        $assign['cotieres_date_me'] = $this->option('-cotieres_date_me');
        $assign['souterraines_version_me'] = $this->option('-souterraines_version_me');
        $assign['souterraines_date_me'] = $this->option('-souterraines_date_me');


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

        // Get options
        $commune = $this->option('-commune');
        $maille_01 = $this->option('-maille_01');
        $maille_02 = $this->option('-maille_02');
        $maille_05 = $this->option('-maille_05');
        $maille_10 = $this->option('-maille_10');
        $reserves_naturelles_nationales = $this->option('-reserves_naturelles_nationales');
        $habref = $this->option('-habref');
        $habitat_mer = $this->option('-habitat_mer');
        $habitat_terre = $this->option('-habitat_terre');

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
        $assign['commune'] = $commune;
        $assign['commune_name'] = pathinfo($commune, PATHINFO_FILENAME);
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
        $assign['habref'] = $habref;
        $assign['habref_name'] = pathinfo($habref, PATHINFO_FILENAME);
        $assign['habitat_mer'] = $habitat_mer;
        $assign['habitat_mer_name'] = pathinfo($habitat_mer, PATHINFO_FILENAME);
        $assign['habitat_terre'] = $habitat_terre;
        $assign['habitat_terre_name'] = pathinfo($habitat_terre, PATHINFO_FILENAME);
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

        $assign['commune_annee_ref'] = $this->option('-commune_annee_ref');
        $assign['departement_annee_ref'] = $this->option('-departement_annee_ref');
        $assign['maille_01_version_ref'] = $this->option('-maille_01_version_ref');
        $assign['maille_01_nom_ref'] = $this->option('-maille_01_nom_ref');
        $assign['maille_02_version_ref'] = $this->option('-maille_02_version_ref');
        $assign['maille_02_nom_ref'] = $this->option('-maille_02_nom_ref');
        $assign['maille_05_version_ref'] = $this->option('-maille_05_version_ref');
        $assign['maille_05_nom_ref'] = $this->option('-maille_05_nom_ref');
        $assign['maille_10_version_ref'] = $this->option('-maille_10_version_ref');
        $assign['maille_10_nom_ref'] = $this->option('-maille_10_nom_ref');
        $assign['rnn_version_en'] = $this->option('-rnn_version_en');


        // Run import
        $tpl->assign( $assign );
        $script = $tpl->fetchFromString($template, 'text');

        $output = array();
        $retVal = 1;
        jLog::log( $script );
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
