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

    function getSearchToken() {

        $rep = $this->getResponse('json');

        // Get form
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
        $token = md5( $form->id().time().session_id() );
        $occtaxSearch = new occtaxSearchObservation( $token, $form->getAllData() );
        jForms::destroy('occtax~search');

        // Get search description
        $description = $occtaxSearch->getSearchDescription();

        $rep->data = array(
            'status' => 1,
            'token' => $token,
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
        $data = array();

        $return = array();
        $attributes = array();

        // Get occtaxSearch from token
        $token = $this->param('token');
        if( !$token || $token=='' || !isset( $_SESSION['occtaxSearch' . $token] ) ){
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'occtax~search.invalid.token' );
            $rep->data = $return;
            return $rep;
        }
        $searchClassName = 'occtaxExportObservation';
        jClasses::inc('occtax~'.$searchClassName);
        $occtaxSearch = new $searchClassName( $token, null );

        // Get main observation data
        $limit = $this->intParam( 'limit' );
        $offset = $this->intParam( 'offset' );
        $order = $this->param( 'order', '' );
        try {
            $return = $occtaxSearch->getData( $limit, $offset, $order );
            $topic = 'principal';
            $attributes = $occtaxSearch->getCsvFields( $topic );
            $csv = $occtaxSearch->writeCsv( $return, $topic );
            $types = $occtaxSearch->getCsvFields( $topic, 'type' );
            $csvt = $occtaxSearch->writeCsvT( $topic );
            $data[$topic] = array( $csv, $csvt );
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
            'sig',
            'commune',
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
                'espace_naturel',
                'sig'
            );
            $topics = array_diff(
                $topics,
                $blackTopics
            );
        }

        foreach( $topics as $topic ) {
            // Get data for the given topic
            $return = $occtaxSearch->getTopicData( $topic );
            if( !$return )
                continue;

            // Get field list
            $attributes = $occtaxSearch->getCsvFields( $topic );

            // Write data to CSV and get csv file path
            $csv = $occtaxSearch->writeCsv( $return, $topic );
            $csvt = $occtaxSearch->writeCsvT( $topic );

            $data[$topic] = array( $csv, $csvt );
        }

        // Add csv files to ZIP
        foreach( $data as $topic=>$files ) {
            $rep->content->addFile( $files[0], 'st_' . $topic . '.csv' );
            $rep->content->addFile( $files[1], 'st_' . $topic . '.csvt' );
            unlink( $files[0] );
            unlink( $files[1] );
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

