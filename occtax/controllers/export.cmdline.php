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
    protected $srid = '4326';

    protected $mailles_a_utiliser = 'maille_02,maille_10';

    protected $geometryTypeTranslation = array(
        'point'=>'point', 'linestring'=>'ligne',
        'polygon'=>'polygone', 'nogeom'=> 'sans_geometrie',
        'other'=>'autre'
    );

    /**
     * Options for the command line
    *  'method_name' => array('-option_name' => true/false)
    * true means that a value should be provided for the option on the command line
     */
    protected $allowed_options = array(
        'dee' => array(
            '-login' => true,
            '-output' => true
        ),
        'geojson' => array(
            '-locale' => true,
            '-login' => true,
            '-token' => true,
            '-output_directory' => true,
            '-projection' => true
        ),
        'csv' => array(
            '-locale' => true,
            '-login' => true,
            '-token' => true,
            '-output_directory' => true,
            '-projection' => true
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


    function __construct( $request ){

        // Get SRID
        $localConfig = jApp::configPath('naturaliz.ini.php');
        $ini = new jIniFileModifier($localConfig);
        $srid = $ini->getValue('srid', 'naturaliz');
        if( !empty(trim($srid)) ){
            $this->srid = trim($srid);
        }

        // Mailles
        $mailles_a_utiliser = $ini->getValue('mailles_a_utiliser', 'naturaliz');
        if( !$mailles_a_utiliser or empty(trim($mailles_a_utiliser)) ){
            $mailles_a_utiliser = 'maille_02,maille_10';
        }
        $this->mailles_a_utiliser = array_map('trim', explode(',', $mailles_a_utiliser));

        parent::__construct( $request );

    }


    /**
     * Export observation as DEE GML file
     *
     */
    function dee(){


        $rep = $this->getResponse(); // cmdline response by default

        jClasses::inc('occtax~occtaxSearchObservationBrutes');
        $token = null;

        $login = $this->option('-login');
        if (empty($login) or strtolower($login) == 'null') {
            $login = Null;
        }
        $occtaxSearch = new occtaxSearchObservationBrutes( $token, null, null, $login );
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

    private function zipFiles($files_to_zip, $temp_folder, $output_path) {
        // Create ZIP archive
        // Tried PHP builtin zipArchive class
        // NASTY BUG WHEN HAVING TOO HEAVY DATA !
        // Infinite Loop when calling zip->close()
        // So we use instead the bash zip tool via exec

        // Move files to temp folder
        $unlinks = array();
        foreach ($files_to_zip as $sourcefile=>$destpath) {
            rename($sourcefile, $temp_folder . '/' . $destpath);
            $unlinks[] = $temp_folder . '/' . $destpath;
        }

        // Zip files
        try {
            exec('cd "' . $temp_folder . '" && zip -r ' . $output_path . ' *');
        } catch (Exception $e) {
            jLog::log($e->getMessage(), 'error');
            return False;
        }

        // Remove files
        foreach ($unlinks as $file) {
            unlink($file);
        }
        jFile::removeDir($temp_folder);

        // Check file exists
        if (!(is_file($output_path))) {
            return False;
        }

        return True;
    }

    function geojson() {

        $rep = $this->getResponse();

        // Check parameters
        $token = $this->option('-token');
        if( !$token ){
            echo 'ERROR: ' . jLocale::get( 'occtax~search.invalid.token' ) . '\n';
            return $rep;
        }
        $projection = $this->option('-projection', '4326');
        $temp_folder_name = $this->option('-output_directory');
        if (empty($temp_folder_name)) {
            $temp_folder_name = $token;
        }

        // login
        $login = $this->option('-login');
        if (empty($login) or strtolower($login) == 'null') {
            $login = Null;
        }

        // Locale
        $locale = $this->option('-locale');
        if (empty($locale) or strtolower($locale) == '') {
            $locale = 'fr_FR';
        }
        jApp::config()->locale = $locale;

        // Get occtaxSearch from token
        jClasses::inc('occtax~occtaxExportObservation');
        $occtaxSearch = new occtaxExportObservation( $token, null, null, $projection, $login );
        if( !$occtaxSearch ){
            echo 'ERROR: ' . jLocale::get( 'occtax~search.invalid.token' ) . '\n';
            return $rep;
        }
        $limit = null;
        $offset = 0;

        // Generate file with GeoJSON content
        $geojson = $occtaxSearch->getGeoJSON($limit, $offset);

        // Prepare the list of generated files to zip
        $files_to_zip = array();
        $files_to_zip[$geojson] = 'export_observations.geojson';

        // Temp output folder
        $temp_folder = jApp::tempPath($temp_folder_name);
        jFile::createDir($temp_folder);

        // LISEZ-MOI.txt : Add readme file + search description to ZIP
        $lpath = $temp_folder . '/' . 'LISEZ-MOI_' . time() . session_id() . '.txt';
        jFile::write(
            $lpath,
            $occtaxSearch->getReadme('text', 'geojson')
        );
        $files_to_zip[$lpath] = 'LISEZ-MOI.txt';

        // Zip files
        $zpath = $temp_folder . '.zip';
        $zipit = $this->zipFiles($files_to_zip, $temp_folder, $zpath);
        if (!$zipit) {
            echo 'ERROR: ' . 'Cannot create ZIP file' . '\n';
            return $rep;
        }

        // Return response
        echo "SUCCESS: $zpath\n";
        return $rep;

    }


    function csv() {

        $rep = $this->getResponse();

        // Check parameters
        $token = $this->option('-token');
        if( !$token ){
            echo 'ERROR: ' . jLocale::get( 'occtax~search.invalid.token' ) . '\n';
            return $rep;
        }
        $projection = $this->option('-projection', '4326');
        $temp_folder_name = $this->option('-output_directory');
        if (empty($temp_folder_name)) {
            $temp_folder_name = $token;
        }

        // login
        $login = $this->option('-login');
        if (empty($login) or strtolower($login) == 'null') {
            $login = Null;
        }

        // Locale
        $locale = $this->option('-locale');
        if (empty($locale) or strtolower($locale) == '') {
            $locale = 'fr_FR';
        }
        jApp::config()->locale = $locale;

        // Get occtaxSearch from token
        jClasses::inc('occtax~occtaxExportObservation');
        $occtaxSearch = new occtaxExportObservation( $token, null, null, $projection, $login );
        if( !$occtaxSearch ){
            echo 'ERROR: ' . jLocale::get( 'occtax~search.invalid.token' ) . '\n';
            return $rep;
        }
        $limit = null;
        $offset = 0;

        // Get main observation data
        $limit = NULL; $offset = 0;
        $delimiter = ',';
        $principal = array();
        $geometryTypes = array(
            'point', 'linestring', 'polygon', 'nogeom'
        );
        $principal = array();
        try {
            $topic = 'principal';
            list ($csvs, $counter) = $occtaxSearch->writeCsv( $topic, $limit, $offset, $delimiter );
            foreach($geometryTypes as $geometryType){
                if($counter[$geometryType] == 0){
                    continue;
                }
                $csv = $csvs[$geometryType];
                $csvt = $occtaxSearch->writeCsvT( $topic, $delimiter, $geometryType );
                $principal[$geometryType] = array( $csv, $csvt );
            }
        }
        catch( Exception $e ) {
            echo 'ERROR: ' . jLocale::get( 'occtax~search.form.error.query' ) . '\n';
            return $rep;
        }

        // Prepare the list of generated files to zip
        $files_to_zip = array();

        // Add principal
        foreach($geometryTypes as $geometryType){
            if(!array_key_exists($geometryType, $principal)){
                continue;
            }
            if(file_exists($principal[$geometryType][0]) ){
                $files_to_zip[$principal[$geometryType][0]] = 'st_' . 'principal' . '_' . $this->geometryTypeTranslation[$geometryType] . '.csv';
            }
            if(file_exists($principal[$geometryType][1]) ){
                $files_to_zip[$principal[$geometryType][1]] = 'st_' . 'principal' . '_' . $this->geometryTypeTranslation[$geometryType] . '.csvt';
            }
        }
        // Get other files
        $topics = array(
            'commune',
            'departement',
            'maille_10',
            'espace_naturel',
            'masse_eau',
            'habitat',
            'attribut_additionnel'
        );

        // Mailles

        // Remove sensitive data if not enough rights
        if( jAcl2::checkByUser($login, "visualisation.donnees.maille_01") and in_array('maille_01', $this->mailles_a_utiliser) ) {
            $topics[] = 'maille_01';
        }
        if( jAcl2::checkByUser($login, "visualisation.donnees.maille_02") and in_array('maille_02', $this->mailles_a_utiliser) ) {
            $topics[] = 'maille_02';
        }
        if( !jAcl2::checkByUser($login, "visualisation.donnees.brutes") ) {
            $blackTopics = array(
                'attribut_additionnel',
                'espace_naturel'
            );
            $topics = array_diff(
                $topics,
                $blackTopics
            );
        }

        foreach( $topics as $topic ) {
            // Write data to CSV and get csv file path
            list ($csv, $counter) = $occtaxSearch->writeCsv($topic );
            $csvt = $occtaxSearch->writeCsvT( $topic );
            if($csv and $counter > 0){
                $data[$topic] = array( $csv, $csvt );
            }
        }

        // Add other csv files to ZIP
        $subdir = 'rattachements';
        foreach( $data as $topic=>$files ) {
            if(file_exists($files[0]) ){
                $files_to_zip[$files[0]] = $subdir . '/' . 'st_' . $topic . '.csv';
            }
            if(file_exists($files[1]) ){
                $files_to_zip[$files[1]] = $subdir . '/' . 'st_' . $topic . '.csvt';
            }
        }

        // Temp output folder
        $temp_folder = jApp::tempPath($temp_folder_name);
        jFile::createDir($temp_folder);
        jFile::createDir($temp_folder . '/' . $subdir);

        // LISEZ-MOI.txt : Add readme file + search description to ZIP
        $lpath = $temp_folder . '/' . 'LISEZ-MOI_' . time() . session_id() . '.txt';
        jFile::write(
            $lpath,
            $occtaxSearch->getReadme('text', 'csv')
        );
        $files_to_zip[$lpath] = 'LISEZ-MOI.txt';

        // Zip files
        $zpath = $temp_folder . '.zip';
        $zipit = $this->zipFiles($files_to_zip, $temp_folder, $zpath);
        if (!$zipit) {
            echo 'ERROR: ' . 'Cannot create ZIP file' . '\n';
            return $rep;
        }

        // Return response
        echo "SUCCESS: $zpath\n";
        return $rep;

    }
}
