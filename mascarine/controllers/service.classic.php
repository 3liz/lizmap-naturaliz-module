<?php
/**
* @package   lizmap
* @subpackage mascarine
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
        $form = jForms::create('mascarine~search');

        // Init form from request
        $cd_nom = $this->param('cd_nom');
        if( is_array( $cd_nom ) and count( $cd_nom ) > 0 )
            $form->setData('cd_nom', $cd_nom);
        $form->initFromRequest();

        // Check form
        if ( !$form->check() ) {
            $return = array();
            $return['status'] = 0;
            $return['msg'] = array( jLocale::get( 'mascarine~search.form.error.check' ) );
            $rep->data = $return;
            return $rep;
        }
        // Get mascarineSearch instance
        jClasses::inc('mascarine~mascarineSearchObservationObs');
        $token = md5( $form->id().time().session_id() );
        $mascarineSearch = new mascarineSearchObservationObs( $token, $form->getAllData() );
        jForms::destroy('mascarine~search');

        // Get search description
        $description = $mascarineSearch->getSearchDescription();

        $rep->data = array(
            'status' => 1,
            'token' => $token,
            'recordsTotal' => $mascarineSearch->getRecordsTotal(),
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

        // Get mascarineSearch from token
        $token = $this->param('token');
        if( !$token || $token=='' || !isset( $_SESSION['mascarineSearch' . $token] ) ){
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'mascarine~search.invalid.token' );
            $rep->data = $return;
            return $rep;
        }
        jClasses::inc('mascarine~'.$searchClassName);
        $mascarineSearch = new $searchClassName( $token, null );

        // Get data
        $limit = $this->intParam( 'limit' );
        $offset = $this->intParam( 'offset' );
        $order = $this->param( 'order', '' );
        try {
            $return['recordsTotal'] = $mascarineSearch->getRecordsTotal();
            $return['recordsFiltered'] = $mascarineSearch->getRecordsTotal();
            $return['data'] = $mascarineSearch->getData( $limit, $offset, $order );
            $return['status'] = 1;
            $return['fields'] = $mascarineSearch->getFields();
        }
        catch( Exception $e ) {
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'mascarine~search.form.error.query' );
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
          return $this->__search( 'mascarineSearchObservationStats' );
        else if( $groupBy == 'm' )
          return $this->__search( 'mascarineSearchObservationMaille' );
        else if ( $groupBy == 't' )
          return $this->__search( 'mascarineSearchObservationTaxon' );
        else if ( $groupBy == 'e' )
          return $this->__search( 'mascarineExportObservation' );
        else
          return $this->__search( 'mascarineSearchObservationObs' );
    }

    /**
     * Search stats
     *
     */
    function searchStats() {
        return $this->__search( 'mascarineSearchObservationStats' );
    }

    /**
     * Search group by maille
     *
     */
    function searchGroupByMaille() {
        return $this->__search( 'mascarineSearchObservationMaille' );
    }

    /**
     * Search group by taxon
     *
     */
    function searchGroupByTaxon() {
        return $this->__search( 'mascarineSearchObservationTaxon' );
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

        // Get mascarineSearch from token
        $token = $this->param('token');
        if( !$token || $token=='' || !isset( $_SESSION['mascarineSearch' . $token] ) ){
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'mascarine~search.invalid.token' );
            $rep->data = $return;
            return $rep;
        }
        $searchClassName = 'mascarineExportObservation';
        jClasses::inc('mascarine~'.$searchClassName);
        $mascarineSearch = new $searchClassName( $token, null );

        // Get main observation data
        $limit = $this->intParam( 'limit' );
        $offset = $this->intParam( 'offset' );
        $order = $this->param( 'order', '' );
        try {
            $return = $mascarineSearch->getData( $limit, $offset, $order );

            $topic = 'principal';
            $attributes = $mascarineSearch->getCsvFields( $topic );
            $csv = $mascarineSearch->writeCsv( $return, $topic );
            $types = $mascarineSearch->getCsvFields( $topic, 'type' );
            $csvt = $mascarineSearch->writeCsvT( $topic );
            $data[$topic] = array( $csv, $csvt );
        }
        catch( Exception $e ) {
            $rep = $this->getResponse('json');
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'mascarine~search.form.error.query' );
            $rep->data = $return;
            return $rep;
        }


        // Get other files
        $topics = array(
            'sig',
            'commune',
            'maille',
            'habitat',
            'menace'
        );

        // Remove sensitive data if not enough rights
        if( !jAcl2::check("visualisation.donnees.brutes") ) {
            $blackTopics = array(
                'sig',
                'habitat',
                'menace'
            );
            $topics = array_diff(
                $topics,
                $blackTopics
            );
        }

        foreach( $topics as $topic ) {
            // Get data for the given topic
            $return = $mascarineSearch->getTopicData( $topic );
            if( !$return )
                continue;

            // Get field list
            $attributes = $mascarineSearch->getCsvFields( $topic );

            // Write data to CSV and get csv file path
            $csv = $mascarineSearch->writeCsv( $return, $topic );
            $csvt = $mascarineSearch->writeCsvT( $topic );

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
        $readme = jApp::configPath('mascarine-export-LISEZ-MOI.txt');
        if( is_file( $readme ) ){
            $content = jFile::read( $readme );
            $content.= "\r";

            // Add search description
            $content.= "Filtres de recherche utilisés :\r\n";
            $getSearchDescription = $mascarineSearch->getSearchDescription();
            $content.= strip_tags( $getSearchDescription );

            $rep->content->addContentFile( 'LISEZ-MOI.txt', $content );
        }


        $rep->zipFilename = 'donnees_mascarine_export.zip';
        return $rep;
    }


    function getCommune() {
        $rep = $this->getResponse('json');

        // Get x and y params
        $x = $this->floatParam('x');
        $y = $this->floatParam('y');

        jClasses::inc('occtax~occtaxGeometryChecker');
        $mgc = new occtaxGeometryChecker($x, $y, $this->srid, 'mascarine');
        $return = $mgc->getCommune();

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
        $mgc = new occtaxGeometryChecker($x, $y, $this->srid, 'mascarine');
        $return = $mgc->getMaille();

        // Return data
        $rep->data = $return;

        return $rep;
    }


    function intersectGeometry() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'status' => 0,
            'msg' => array(),
            'result'=> array()
        );

        // Get wkt param
        $wkt = $this->param('wkt');
        if (!$wkt) {
            $return['msg'][] = 'params invalid';
            $rep->data = $return;
            return $rep;
        }

        $cnx = jDb::getConnection();

        $sql = "SELECT ST_AsGeoJSON( geom) AS geojson, code_commune, code_maille
FROM (
SELECT
ST_INTERSECTION(
  ST_Transform( m.geom, 4326 ),
  ST_INTERSECTION(
    ST_Transform( c.geom, 4326 ),
    ST_GeomFromText(".$cnx->quote($wkt).", 4326 )
  )
) AS geom, c.code_commune, m.code_maille
FROM sig.commune c, sig.maille_01 m
WHERE ST_Intersects(
    ST_GeomFromText(".$cnx->quote($wkt).", 4326 )
  , ST_Transform( m.geom, 4326 )
) AND ST_Intersects( m.geom, c.geom)
) i
WHERE CASE WHEN GeometryType( geom ) = 'LINESTRING' THEN ST_LENGTH( geom ) > 1.0e-10
           WHEN GeometryType( geom ) = 'POLYGON' THEN ST_AREA( geom ) > 1.0e-10
           WHEN GeometryType( geom ) = 'POINT' THEN True END;";

        $rs = $cnx->query( $sql );
        while( $r = $rs->fetch()){
            $r->geojson = json_decode( $r->geojson );
            $return['result'][] = $r;
        }

        // Return data
        $rep->data = $return;

        return $rep;
    }


    function testGeometry() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'status' => 0,
            'msg' => array()
        );

        // Get wkt param
        $wkt = $this->param('wkt');
        if (!$wkt) {
            $return['msg'][] = 'params invalid';
            $rep->data = $return;
            return $rep;
        }

        $cnx = jDb::getConnection();

        $sql = "SELECT ST_AsGeoJSON( geom) AS geojson, code_commune, code_maille
FROM (
SELECT
ST_INTERSECTION(
  ST_Transform( m.geom, 4326 ),
  ST_INTERSECTION(
    ST_Transform( c.geom, 4326 ),
    ST_GeomFromText(".$cnx->quote($wkt).", 4326 )
  )
) AS geom, c.code_commune, m.code_maille
FROM sig.commune c, sig.maille_01 m
WHERE ST_Intersects(
    ST_GeomFromText(".$cnx->quote($wkt).", 4326 )
  , ST_Transform( m.geom, 4326 )
) AND ST_Intersects( m.geom, c.geom)
) i
WHERE CASE WHEN GeometryType( geom ) = 'LINESTRING' THEN ST_LENGTH( geom ) > 1.0e-10
           WHEN GeometryType( geom ) = 'POLYGON' THEN ST_AREA( geom ) > 1.0e-10
           WHEN GeometryType( geom ) = 'POINT' THEN True END;";

        $rs = $cnx->query( $sql );
        if($rs->rowCount() != 1){
            $return['msg'][] = 'Has to be cut in '.$rs->rowCount().' objects';
            $rep->data = $return;
            return $rep;
        }
        $return['status'] = 1;
        $return['msg'][] = 'geom valid';
        while( $r = $rs->fetch()){
            $r->geojson = json_decode( $r->geojson );
            $return['result'][] = $r;
        }

        // Return data
        $rep->data = $return;

        return $rep;
    }


    function saveTemp() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'status' => 0,
            'msg' => array()
        );

        // Get wkt param
        $geojson = $this->param('geojson');
        if (!$geojson) {
            $return['msg'][] = 'params invalid';
            $rep->data = $return;
            return $rep;
        }

        $geojson_decode = json_decode( $geojson );
        //"type": "FeatureCollection"
        if ( !property_exists( $geojson_decode, 'type' ) || $geojson_decode->type != "FeatureCollection" ) {
            $return['msg'][] = 'geojson invalid';
            $rep->data = $return;
            return $rep;
        }

        // save geojson where it has to be saved

        $return['status'] = 1;
        $return['msg'][] = 'geojson valid';
        $rep->data = $return;

        return $rep;
    }


    function uploadGPX() {
        $rep = $this->getResponse('xml');

        $form = jForms::get("mascarine~upload_gpx");
        if( !$form )
          $form = jForms::create("mascarine~upload_gpx");
        $form->initFromRequest();
        if ( !$form->check() ) {
            $rep->content = '<gpx
 version="1.0"
 creator="ExpertGPS 1.1 - http://www.topografix.com"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 xmlns="http://www.topografix.com/GPX/1/0"
 xsi:schemaLocation="http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd">Fichier invalide</gpx>';
            return $rep;
        }

        $ext = strtolower( pathinfo($_FILES['gpx']['name'], PATHINFO_EXTENSION) );
        if ( $ext != 'gpx' ) {
            $rep->content = '<gpx
 version="1.0"
 creator="ExpertGPS 1.1 - http://www.topografix.com"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 xmlns="http://www.topografix.com/GPX/1/0"
 xsi:schemaLocation="http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd">Fichier gpx requis</gpx>';
            return $rep;
        }

        $time = time();
        $form->saveFile( 'gpx', jApp::varPath('uploads'), $time .'_'. $_FILES['gpx']['name'] );
        $gpx = jFile::read( jApp::varPath('uploads/'. $time .'_'. $_FILES['gpx']['name'] ) );

        jForms::destroy("mascarine~upload_gpx");

        // Return data
        $rep->sendXMLHeader = false;
        $rep->content = $gpx;

        return $rep;
    }

}

