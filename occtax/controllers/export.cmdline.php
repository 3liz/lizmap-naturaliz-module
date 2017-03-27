<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    3liz
* @copyright 2017 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class exportCtrl extends jControllerCmdLine {

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
        'dee' => array(
            '-output' => true // Path
        )
    );

    /**
     * Help
     *
     *
     */
    public $help = array(


        'dee' => 'Exporter les données au format DEE

        Usage :
        php lizmap/scripts/script.php occtax~export:dee -output /tmp/donnees_dee.xml
        '
    );


    /**
     * Export observation as DEE GML file
     *
     */
    function dee(){


        $rep = $this->getResponse(); // cmdline response by default
        $data = array();
        $return = array();
        $attributes = array();

        jClasses::inc('occtax~occtaxSearchObservationBrutes');
        $token = null;
        $occtaxSearch = new occtaxSearchObservationBrutes( $token, null );
        if( !$occtaxSearch ){
            echo (jLocale::get( 'occtax~search.invalid.token' ) . "\n");
        }

        $output = $this->option('-output');
        if( !$output)
            echo "Pas de chemin passé via option -output \n";

        $dee = $occtaxSearch->writeDee($output);
        if( file_exists($dee) ) {
            echo('Export effectué dans le fichier : '.$dee . "\n");
        }

        // Add readme file + search description to ZIP
        //$rep->content->addContentFile( 'LISEZ-MOI.txt', $occtaxSearch->getReadme() );

        return $rep;
    }

}
