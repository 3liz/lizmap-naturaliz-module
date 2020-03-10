<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class serviceCtrl extends jController {

    protected $srid = '4326';

    protected $mailles_a_utiliser = 'maille_02,maille_10';

    protected $geometryTypeTranslation = array(
        'point'=>'point', 'linestring'=>'ligne',
        'polygon'=>'polygone', 'nogeom'=> 'sans_geometrie',
        'other'=>'autre'
    );

    function __construct( $request ){

        // Get SRID
        $localConfig = jApp::configPath('naturaliz.ini.php');
        $ini = new jIniFileModifier($localConfig);
        $srid = $ini->getValue('srid', 'naturaliz');
        $this->srid = $srid;

        // Mailles
        $mailles_a_utiliser = $ini->getValue('mailles_a_utiliser', 'naturaliz');
        if( !$mailles_a_utiliser or empty(trim($mailles_a_utiliser)) ){
            $mailles_a_utiliser = 'maille_02,maille_10';
        }
        $this->mailles_a_utiliser = array_map('trim', explode(',', $mailles_a_utiliser));

        parent::__construct( $request );

    }

    function initSearch() {

        $rep = $this->getResponse('json');

        // Create form
        $form = jForms::create('occtax~search');

        // Init form from request
        $cd_nom = $this->param('cd_nom');
        if( is_array( $cd_nom ) and count( $cd_nom ) > 0 )
            $form->setData('cd_nom', $cd_nom);
        $form->initFromRequest();

        // Check form
        $fok = True;
        $fmsg = array();
        if ( !$form->check() ) {
            $fok = False;
            $fmsg[] = jLocale::get( 'occtax~search.form.error.check' );
        }

        // Check the dates are OK
        $dmin = $form->getData('date_min');
        $dmax = $form->getData('date_max');
        if( !empty($dmax) and !empty($dmin) and (strtotime($dmax) - strtotime($dmin) < 0) ){
            $form->setErrorOn('date_min', jLocale::get('occtax~search.form.error.date'));
            $fmsg[] = jLocale::get('occtax~search.form.error.date');
            $fok = False;
        }

        if(!$fok){
            $return = array();
            $return['status'] = 0;
            $return['msg'] = $fmsg;
            $rep->data = $return;
            return $rep;
        }


        // Get occtaxSearch instance
        jClasses::inc('occtax~occtaxSearchObservation');
        $params = $form->getAllData();

        $occtaxSearch = new occtaxSearchObservation( null, $params );
        jForms::destroy('occtax~search');

        // Get search description
        $description = $occtaxSearch->getSearchDescription();

        // WFS link
        $wfsParams = array_merge(
            $occtaxSearch->getParams(),
            array(
                'service'=> 'WFS',
                'request'=> 'GetCapabilities',
                'version' => '1.0.0'
            )
        );
        $blackWfsParams = array(
            'reinit',
            'submit'
        );
        foreach($blackWfsParams as $b){
            unset($wfsParams[$b]);
        }
        foreach($wfsParams as $k=>$v){
            if(empty($v))
                unset($wfsParams[$k]);
        }
        $wfsUrl = jUrl::getFull('occtax~wfs:index', $wfsParams );

        $rep->data = array(
            'status' => 1,
            'token' => $occtaxSearch->getToken(),
            'recordsTotal' => $occtaxSearch->getRecordsTotal(),
            'description' => $description,
            'wfsUrl' => $wfsUrl
        );

        return $rep;

    }


    /**
     * Protected search
     *
     */
    protected function __search( $searchClassName ) {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'recordsTotal' => 0,
            'recordsFiltered' => 0,
            'data' => array(),
            'msg' => array()
        );

        // Get occtaxSearch from token
        $token = $this->param('token');
        if( !$token || $token=='' || !isset( $_SESSION['occtaxSearch' . $token] ) ){
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'occtax~search.invalid.token' );
            $rep->data = $return;
            return $rep;
        }

        jClasses::inc('occtax~'.$searchClassName);

        $occtaxSearch = new $searchClassName( $token, null );

        // Get data
        $limit = $this->intParam( 'limit' );
        $offset = $this->intParam( 'offset' );
        $order = $this->param( 'order', '' );
        try {
            $return['recordsTotal'] = $occtaxSearch->getRecordsTotal();
            $return['recordsFiltered'] = $occtaxSearch->getRecordsTotal();
            $return['data'] = $occtaxSearch->getData( $limit, $offset, $order );
            $return['status'] = 1;
            $return['fields'] = $occtaxSearch->getFields();
        }
        catch( Exception $e ) {
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'occtax~search.form.error.query' );
            $rep->data = $return;
            return $rep;
        }

        // Return data
        $rep->data = $return;

        return $rep;
    }


    /**
     * Classic search
     *
     */
    function search() {
        $groupBy = $this->param('group');
        if( $groupBy == 's' )
          return $this->__search( 'occtaxSearchObservationStats' );
        else if( $groupBy == 'm' )
          return $this->__search( 'occtaxSearchObservationMaille' );
        else if ( $groupBy == 't' )
          return $this->__search( 'occtaxSearchObservationTaxon' );
        //else if ( $groupBy == 'e' )
          //return $this->__search( 'occtaxExportObservation' );
        else
          return $this->__search( 'occtaxSearchObservation' );
    }

    /**
     * Search stats
     *
     */
    function searchStats() {
        return $this->__search( 'occtaxSearchObservationStats' );
    }

    /**
     * Search group by maille
     *
     */
    function searchGroupByMaille() {
        $class = 'occtaxSearchObservationMaille';
        $m = $this->param('type_maille', 'm02');
        if($m == 'm02' or (!jAcl2::check("visualisation.donnees.maille_01") and $m == 'm01')){
            $class = 'occtaxSearchObservationMaille02';
        }
        //if($m == 'm05'){
            //$class = 'occtaxSearchObservationMaille05';
        //}
        if($m == 'm10'){
            $class = 'occtaxSearchObservationMaille10';
        }
        return $this->__search( $class );
    }

    /**
     * Search group by taxon
     *
     */
    function searchGroupByTaxon() {
        return $this->__search( 'occtaxSearchObservationTaxon' );
    }


    /**
     * Export observation into GeoJSON
     *
     */
    function exportGeoJSON(){


        if( !jAcl2::check("visualisation.donnees.brutes") ) {
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'occtax~search.form.error.right' );
            $rep->data = $return;
            return $rep;
        }

        $rep = $this->getResponse('json');
        $data = array();
        $return = array();
        $attributes = array();

        // Get occtaxSearch from token
        $token = $this->param('token');
        jClasses::inc('occtax~occtaxExportObservation');

        $projection = $this->param('projection', '4326');
        $occtaxSearch = new occtaxExportObservation( $token, null, null, $projection );
        if( !$occtaxSearch ){
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'occtax~search.invalid.token' );
            $rep->data = $return;
            return $rep;
        }

        $limit = $this->intParam('limit');
        $offset = $this->intParam('offset');
        $geojson = $occtaxSearch->getGeoJSON($limit, $offset);

        $rep = $this->getResponse('zip');

        // Add geojson
        $rep->content->addFile( $geojson , 'export_observations.geojson' );

        // Add readme file + search description to ZIP
        $rep->content->addContentFile( 'LISEZ-MOI.txt', $occtaxSearch->getReadme('text', 'geojson') );

        $rep->zipFilename = 'export_observations.zip';

        return $rep;
    }

    /**
     * Export observations into CSV
     *
     */
    function exportCsv() {

        $rep = $this->getResponse('zip');

        $data = array();
        $return = array();
        $attributes = array();

        // Get occtaxSearch from token
        $token = $this->param('token');
        $projection = $this->param('projection', '4326');
        jClasses::inc('occtax~occtaxExportObservation');
        $occtaxSearch = new occtaxExportObservation( $token, null, null, $projection );
        if( !$occtaxSearch ){
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'occtax~search.invalid.token' );
            $rep->data = $return;
            return $rep;
        }

        // Get main observation data
        $limit = $this->intParam( 'limit' );
        $offset = $this->intParam( 'offset' );
        $delimiter = ',';
        $order = $this->param( 'order', '' );
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
            $rep = $this->getResponse('json');
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'occtax~search.form.error.query' );
            $rep->data = $return;
            return $rep;
        }

        // Add principal
        foreach($geometryTypes as $geometryType){
            if(!array_key_exists($geometryType, $principal)){
                continue;
            }
            if(file_exists($principal[$geometryType][0]) ){
                $rep->content->addFile( $principal[$geometryType][0], 'st_' . 'principal' . '_' . $this->geometryTypeTranslation[$geometryType] . '.csv' );
                unlink( $principal[$geometryType][0] );
            }
            if(file_exists($principal[$geometryType][1]) ){
                $rep->content->addFile( $principal[$geometryType][1], 'st_' . 'principal' . '_' . $this->geometryTypeTranslation[$geometryType] . '.csvt' );
                unlink( $principal[$geometryType][1] );
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
        if( jAcl2::check("visualisation.donnees.maille_01") and in_array('maille_01', $this->mailles_a_utiliser) ) {
            $topics[] = 'maille_01';
        }
        if( jAcl2::check("visualisation.donnees.maille_02") and in_array('maille_02', $this->mailles_a_utiliser) ) {
            $topics[] = 'maille_02';
        }
        if( !jAcl2::check("visualisation.donnees.brutes") ) {
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
        $rep->content->addEmptyDir($subdir);
        foreach( $data as $topic=>$files ) {
            if(file_exists($files[0]) ){
                $rep->content->addFile( $files[0], $subdir . '/' . 'st_' . $topic . '.csv' );
                unlink( $files[0] );
            }
            if(file_exists($files[1]) ){
                $rep->content->addFile( $files[1], $subdir . '/' . 'st_' . $topic . '.csvt' );
                unlink( $files[1] );
            }
        }

        // Add readme file + search description to ZIP
        $rep->content->addContentFile( 'LISEZ-MOI.txt', $occtaxSearch->getReadme('text', 'csv') );

        $rep->zipFilename = 'export_observations.zip';
        return $rep;
    }


    function getCommune() {
        $rep = $this->getResponse('json');

        // Get x and y params
        $x = $this->floatParam('x');
        $y = $this->floatParam('y');

        jClasses::inc('occtax~occtaxGeometryChecker');
        $mgc = new occtaxGeometryChecker($x, $y, $this->srid, 'occtax');
        $return = $mgc->getCommune();

        // Return data
        $rep->data = $return;

        return $rep;
    }


    function getMasseEau() {
        $rep = $this->getResponse('json');

        // Get x and y params
        $x = $this->floatParam('x');
        $y = $this->floatParam('y');

        jClasses::inc('occtax~occtaxGeometryChecker');
        $mgc = new occtaxGeometryChecker($x, $y, $this->srid, 'occtax');
        $return = $mgc->getMasseEau();

        // Return data
        $rep->data = $return;

        return $rep;
    }

    function getMaille() {
        $rep = $this->getResponse('json');

        // Get x and y params
        $x = $this->floatParam('x');
        $y = $this->floatParam('y');
        $type_maille = $this->param('type_maille');

        jClasses::inc('occtax~occtaxGeometryChecker');
        $mgc = new occtaxGeometryChecker($x, $y, $this->srid, 'occtax', $type_maille);
        $return = $mgc->getMaille();

        // Return data
        $rep->data = $return;

        return $rep;
    }


    function uploadGeoJSON() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'status' => 0,
            'msg' => array()
        );


        if( !jAcl2::check("requete.spatiale.import") ) {
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'occtax~search.form.error.right' );
            $rep->data = $return;
            return $rep;
        }

        $form = jForms::get("occtax~upload_geojson");
        if( !$form )
          $form = jForms::create("occtax~upload_geojson");
        $form->initFromRequest();
        if ( !$form->check() ) {
            //$return['msg'] = $form->getErrors();
            $return['msg'][] = 'Fichier invalide';
            $rep->data = $return;
            return $rep;
        }

        $ext = strtolower( pathinfo($_FILES['geojson']['name'], PATHINFO_EXTENSION) );
        if ( $ext != 'json' && $ext != 'geojson' ) {
            $return['msg'][] = 'Fichier json requis';
            $rep->data = $return;
            return $rep;
        }

        $time = time();
        $form->saveFile( 'geojson', jApp::varPath('uploads'), $time .'_'. $_FILES['geojson']['name'] );
        $json = jFile::read( jApp::varPath('uploads/'. $time .'_'. $_FILES['geojson']['name'] ) );
        $json = json_decode( $json );
        $return['result'] = $json;
        if ( $json && property_exists( $json, 'type' )
          && $json->type == 'FeatureCollection'
          && property_exists( $json, 'features' ) ) {
            $return['msg'][] = 'Fichier valide';
            $return['status'] = 1;
            $return['result'] = $json;
        } else
            $return['msg'][] = 'GeoJSON invalide';
        jForms::destroy("occtax~upload_geojson");

        // Return data
        $rep->data = $return;

        return $rep;
    }


}

