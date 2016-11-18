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

    function __construct( $request ){

        // Get SRID
        $localConfig = jApp::configPath('localconfig.ini.php');
        $ini = new jIniFileModifier($localConfig);
        $srid = $ini->getValue('srid', 'naturaliz');
        $this->srid = $srid;
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
        if ( !$form->check() ) {
            $return = array();
            $return['status'] = 0;
            $return['msg'] = array( jLocale::get( 'occtax~search.form.error.check' ) );
            $rep->data = $return;
            return $rep;
        }

        // Get occtaxSearch instance
        jClasses::inc('occtax~occtaxSearchObservation');
        $occtaxSearch = new occtaxSearchObservation( null, $form->getAllData() );
        jForms::destroy('occtax~search');

        // Get search description
        $description = $occtaxSearch->getSearchDescription();

        $rep->data = array(
            'status' => 1,
            'token' => $occtaxSearch->getToken(),
            'recordsTotal' => $occtaxSearch->getRecordsTotal(),
            'description' => $description
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
        if( !jCache::get('occtaxSearch' . $token)  ){
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
        else if ( $groupBy == 'e' )
          return $this->__search( 'occtaxExportObservation' );
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
        return $this->__search( 'occtaxSearchObservationMaille' );
    }

    /**
     * Search group by taxon
     *
     */
    function searchGroupByTaxon() {
        return $this->__search( 'occtaxSearchObservationTaxon' );
    }


    /**
     * Export observations
     *
     */
    function exportObservation() {

        $rep = $this->getResponse('zip');
        $format = $this->param('format', 'geojson');

        $data = array();
        $return = array();
        $attributes = array();

        // Get occtaxSearch from token
        $token = $this->param('token');
        jClasses::inc('occtax~occtaxExportObservation');
        $occtaxSearch = new occtaxExportObservation( $token, null );
        if( !$occtaxSearch ){
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'occtax~search.invalid.token' );
            $rep->data = $return;
            return $rep;
        }

        // Get main observation data
        $limit = $this->intParam( 'limit' );
        $offset = $this->intParam( 'offset' );
        $order = $this->param( 'order', '' );
        try {
            if( strtolower($format) == 'csv' ){
                $topic = 'principal';
                $csv = $occtaxSearch->writeCsv( $topic, $limit, $offset );
                $csvt = $occtaxSearch->writeCsvT( $topic );
                $data[$topic] = array( $csv, $csvt );
            }elseif( strtolower($format) == 'geojson' ){
                $geojson = $occtaxSearch->getGeoJSON($limit, $offset);
                $rep = $this->getResponse('binary');
                $rep->content = $geojson;
                $rep->doDownload  =  false;
                $rep->mimeType = 'text/json; charset=utf-8';
                $rep->outputFileName = 'export_observations';
                return $rep;
            }
        }
        catch( Exception $e ) {
            $rep = $this->getResponse('json');
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'occtax~search.form.error.query' );
            $rep->data = $return;
            return $rep;
        }


        // Get other files
        $topics = array(
            'commune',
            'departement',
            'maille',
            'espace_naturel',
            'masse_eau',
            'habitat',
            'attribut_additionnel'
        );

        // Remove sensitive data if not enough rights
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
            $csv = $occtaxSearch->writeCsv($topic );
            $csvt = $occtaxSearch->writeCsvT( $topic );
            $data[$topic] = array( $csv, $csvt );
        }

        // Add csv files to ZIP
        foreach( $data as $topic=>$files ) {
            if(file_exists($files[0]) ){
                $rep->content->addFile( $files[0], 'st_' . $topic . '.csv' );
                unlink( $files[0] );
            }
            if(file_exists($files[1]) ){
                $rep->content->addFile( $files[1], 'st_' . $topic . '.csvt' );
                unlink( $files[1] );
            }

        }

        // Add readme file + search description to ZIP
        $readme = jApp::configPath('occtax-export-LISEZ-MOI.txt');
        if( is_file( $readme ) ){
            $content = jFile::read( $readme );
            $content.= "\r";

            // Add search description
            $content.= "Filtres de recherche utilisés :\r\n";
            $getSearchDescription = $occtaxSearch->getSearchDescription();
            $content.= strip_tags( $getSearchDescription );

            // Add jdd list
            $osParams = $occtaxSearch->getParams();
            $dao_jdd = jDao::get('occtax~jdd');
            $content.= "\r";
            $content.= "Jeux de données : \r\n";

            if( array_key_exists( 'jdd_id', $osParams ) and $osParams['jdd_id'] ){
                $jdd_id = $osParams['jdd_id'];
                $jdd = $dao_jdd->get( $jdd_id );
                if( $jdd )
                    $content.= '  * ' . $jdd->jdd_code . ' ( ' . $jdd->jdd_description . ' )
';
            }else{
                $jdds = $dao_jdd->findAll();
                foreach( $jdds as $jdd ){
                    $content.= '  * ' . $jdd->jdd_code . ' ( ' . $jdd->jdd_description . ' )
';
                }
            }
            $rep->content->addContentFile( 'LISEZ-MOI.txt', $content );
        }

        $rep->zipFilename = 'donnees_echange_observations_naturaliz.zip';
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

        jClasses::inc('occtax~occtaxGeometryChecker');
        $mgc = new occtaxGeometryChecker($x, $y, $this->srid, 'occtax');
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

