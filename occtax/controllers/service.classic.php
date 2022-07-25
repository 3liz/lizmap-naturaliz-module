<?php

/**
 * @package   lizmap
 * @subpackage occtax
 * @author    Michaël Douchin
 * @copyright 2014 3liz
 * @link      http://3liz.com
 * @license    All rights reserved
 */

class serviceCtrl extends jController
{

    protected $srid = '4326';

    protected $mailles_a_utiliser = 'maille_02,maille_10';

    protected $geometryTypeTranslation = array(
        'point' => 'point', 'linestring' => 'ligne',
        'polygon' => 'polygone', 'nogeom' => 'sans_geometrie',
        'other' => 'autre'
    );

    function __construct($request)
    {

        // Get SRID
        $localConfig = jApp::configPath('naturaliz.ini.php');
        $ini = new jIniFileModifier($localConfig);
        $srid = $ini->getValue('srid', 'naturaliz');
        $this->srid = $srid;

        // Mailles
        $mailles_a_utiliser = $ini->getValue('mailles_a_utiliser', 'naturaliz');
        if (!$mailles_a_utiliser or empty(trim($mailles_a_utiliser))) {
            $mailles_a_utiliser = 'maille_02,maille_10';
        }
        $this->mailles_a_utiliser = array_map('trim', explode(',', $mailles_a_utiliser));

        parent::__construct($request);
    }

    function isConnected()
    {
        $rep = $this->getResponse('json');
        $return = array();
        $return['is_connected'] = jAuth::isConnected();
        $rep->data = $return;
        return $rep;
    }

    function initSearch()
    {

        $rep = $this->getResponse('json');

        // Create form
        $form = jForms::create('occtax~search');

        // Init form from request
        $cd_nom = $this->param('cd_nom');
        if (is_array($cd_nom) and count($cd_nom) > 0)
            $form->setData('cd_nom', $cd_nom);
        $form->initFromRequest();

        // Check form
        $fok = True;
        $fmsg = array();
        if (!$form->check()) {
            $fok = False;
            $fmsg[] = jLocale::get('occtax~search.form.error.check');
        }

        // Check the dates are OK
        $dmin = $form->getData('date_min');
        $dmax = $form->getData('date_max');
        if (!empty($dmax) and !empty($dmin) and (strtotime($dmax) - strtotime($dmin) < 0)) {
            $form->setErrorOn('date_min', jLocale::get('occtax~search.form.error.date'));
            $fmsg[] = jLocale::get('occtax~search.form.error.date');
            $fok = False;
        }

        if (!$fok) {
            $return = array();
            $return['status'] = 0;
            $return['msg'] = $fmsg;
            $rep->data = $return;
            return $rep;
        }

        // Get user login
        $login = Null;
        $user = jAuth::getUserSession();
        if ($user) {
            $login = $user->login;
        }

        // Get occtaxSearch instance
        jClasses::inc('occtax~occtaxSearchObservation');
        $params = $form->getAllData();

        $occtaxSearch = new occtaxSearchObservation(null, $params, null, $login);
        jForms::destroy('occtax~search');

        // Get search description
        $description = $occtaxSearch->getSearchDescription();

        // WFS link
        $wfsParams = array_merge(
            $occtaxSearch->getParams(),
            array(
                'service' => 'WFS',
                'request' => 'GetCapabilities',
                'version' => '1.0.0'
            )
        );
        $blackWfsParams = array(
            'reinit',
            'submit'
        );
        foreach ($blackWfsParams as $b) {
            unset($wfsParams[$b]);
        }
        foreach ($wfsParams as $k => $v) {
            if (empty($v))
                unset($wfsParams[$k]);
        }
        $wfsUrl = jUrl::getFull('occtax~wfs:index', $wfsParams);

        $rep->data = array(
            'status' => 1,
            'token' => $occtaxSearch->getToken(),
            'recordsTotal' => $occtaxSearch->getRecordsTotal(),
            'recordsExtent' => $occtaxSearch->getRecordsExtent(),
            'description' => $description,
            'wfsUrl' => $wfsUrl
        );

        return $rep;
    }


    /**
     * Classic search
     *
     */
    function search()
    {
        $groupBy = $this->param('group');
        if ($groupBy == 's') {
            return $this->__search('occtaxSearchObservationStats');
        } else if ($groupBy == 'm') {
            return $this->__search('occtaxSearchObservationMaille');
        } else if ($groupBy == 't') {
            return $this->__search('occtaxSearchObservationTaxon');
        } else if ($groupBy == 'j') {
            return $this->__search('occtaxSearchObservationJdd');
        } else {
            $map = $this->param('map');
            if ($map == 'on') {
                return $this->__search('occtaxSearchObservationExtent');
            } else {
                return $this->__search('occtaxSearchObservation');
            }
        }
    }


    /**
     * Protected search
     *
     */
    protected function __search($searchClassName)
    {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'recordsTotal' => 0,
            'recordsFiltered' => 0,
            'data' => array(),
            'msg' => array()
        );

        // Do not return data if not connected for observations
        if ($searchClassName == 'occtaxSearchObservation' || $searchClassName == 'occtaxSearchObservationExtent') {
            if (!jAcl2::check("visualisation.donnees.brutes")) {
                $return['status'] = 0;
                $return['msg'][] = jLocale::get('occtax~search.form.error.right');
                $rep->data = $return;
                return $rep;
            }
        }

        // Get occtaxSearch from token
        $token = $this->param('token');
        if (!$token || $token == '' || !isset($_SESSION['occtaxSearch' . $token])) {
            $return['status'] = 0;
            $return['msg'][] = jLocale::get('occtax~search.invalid.token');
            $rep->data = $return;
            return $rep;
        }

        jClasses::inc('occtax~' . $searchClassName);

        // Get user login
        $login = Null;
        $user = jAuth::getUserSession();
        if ($user) {
            $login = $user->login;
        }

        // Extent
        $extent = $this->param('extent');

        // Get instance
        // Add extent only for some contexts: map and observation table
        if ($searchClassName != 'occtaxSearchObservationExtent') {
            $occtaxSearch = new $searchClassName($token, null, null, $login);
        } else {
            $occtaxSearch = new $searchClassName($token, null, null, $login, $extent);
        }

        // Get data
        $limit = $this->intParam('limit');
        $offset = $this->intParam('offset');
        $order = $this->param('order', '');

        try {
            // Get only row count, no data
            $recordsTotal = $occtaxSearch->getRecordsTotal();
            $fields = $occtaxSearch->getFields();
            if ($searchClassName == 'occtaxSearchObservationExtent' and $this->intParam('rowcount', 0) == 1) {
                $return['recordsTotal'] = $recordsTotal;
                $return['status'] = 1;
                $return['recordsFiltered'] = $recordsTotal;
                $return['fields'] = $fields;
                $return['data'] = array();
                $rep->data = $return;
                return $rep;
            } else {
                // We can have heavy data: the result will give a file handler and path
                list($handler, $path) = $occtaxSearch->getData($limit, $offset, $order);
            }
        } catch (Exception $e) {
            $return['status'] = 0;
            $return['msg'][] = jLocale::get('occtax~search.form.error.query');
            $message = $e->getMessage();
            \jLog::log('Naturaliz error: ' . $message, 'error');
            $rep->data = $return;
            return $rep;
        }

        // Fill up JSON file
        $metadata = array();
        $metadata['recordsTotal'] = $recordsTotal;
        $metadata['status'] = 1;
        $metadata['recordsFiltered'] = $recordsTotal;
        $metadata['fields'] = $fields;
        $metadata = preg_replace('#^\{#', '', json_encode($metadata));
        //$metadata = json_encode($metadata);
        // Add metadata at the end of the file
        fwrite($handler, $metadata);
        fclose($handler);

        // Return data
        $rep = $this->getResponse('binary');
        $rep->mimeType = 'text/json; charset=utf-8';
        $rep->doDownload = false;
        $rep->outputFileName = 'naturaliz_observation_data';
        $rep->fileName = $path;
        $rep->deleteFileAfterSending = true;

        return $rep;
    }

    /**
     * Search stats
     *
     */
    function searchStats()
    {
        return $this->__search('occtaxSearchObservationStats');
    }

    /**
     * Search group by maille
     *
     */
    function searchGroupByMaille()
    {
        $class = 'occtaxSearchObservationMaille';
        $m = $this->param('type_maille', 'm02');
        if ($m == 'm02' or (!jAcl2::check("visualisation.donnees.maille_01") and $m == 'm01')) {
            $class = 'occtaxSearchObservationMaille02';
        }
        //if($m == 'm05'){
        //$class = 'occtaxSearchObservationMaille05';
        //}
        if ($m == 'm10') {
            $class = 'occtaxSearchObservationMaille10';
        }
        return $this->__search($class);
    }

    /**
     * Search group by taxon
     *
     */
    function searchGroupByTaxon()
    {
        return $this->__search('occtaxSearchObservationTaxon');
    }

    /**
     * Search group by JDD
     *
     */
    function searchGroupByJdd()
    {
        return $this->__search('occtaxSearchObservationJdd');
    }


    /**
     * Get the complete data of a given taxon
     *
     * @httpparam string $cd_nom Taxon Idenfifier
     */
    function getTaxon()
    {
        $rep = $this->getResponse('json');

        // Get x and y params
        $cd_nom = trim($this->intParam('cd_nom'));
        $return = array(
            'status' => 0,
            'msg' => array()
        );
        if (empty($cd_nom)) {
            $msg[] = 'cd_nom invalide';
            $rep->data = $return;
            return $rep;
        }

        $cnx = jDb::getConnection('naturaliz_virtual_profile');
        $sql = ' SELECT cd_nom, nom_valide';
        $sql .= ' FROM taxon.taxref_consolide';
        $sql .= ' WHERE cd_ref = ' . $cd_nom;
        $result = $cnx->limitQuery($sql, 0, 1);
        $d = $result->fetch();
        if ($d) {
            //$d->geojson = json_decode( $d->geojson );
            $return['status'] = 1;
            $return['result'] = $d;
        } else {
            $return['msg'][] = jLocale::get($this->moduleName . '~search.getCommune.error');
        }
        // Return data
        $rep->data = $return;

        return $rep;
    }

    function getCommune()
    {
        $rep = $this->getResponse('json');

        // Get x and y params
        $x = $this->floatParam('x');
        $y = $this->floatParam('y');
        $code = trim($this->param('code'));

        jClasses::inc('occtax~occtaxGeometryChecker');
        $mgc = new occtaxGeometryChecker($x, $y, $this->srid, 'occtax', null, $code);
        $return = $mgc->getCommune();

        // Return data
        $rep->data = $return;

        return $rep;
    }


    function getMasseEau()
    {
        $rep = $this->getResponse('json');

        // Get x and y params
        $x = $this->floatParam('x');
        $y = $this->floatParam('y');
        $code = trim($this->param('code'));

        jClasses::inc('occtax~occtaxGeometryChecker');
        $mgc = new occtaxGeometryChecker($x, $y, $this->srid, 'occtax', null, $code);
        $return = $mgc->getMasseEau();

        // Return data
        $rep->data = $return;

        return $rep;
    }

    function getMaille()
    {
        $rep = $this->getResponse('json');

        // Get x and y params
        $x = $this->floatParam('x');
        $y = $this->floatParam('y');
        $type_maille = $this->param('type_maille');
        if (is_array($type_maille) && count($type_maille) > 0) {
            $type_maille = $type_maille[0];
        }
        $code = trim($this->param('code'));

        jClasses::inc('occtax~occtaxGeometryChecker');
        $mgc = new occtaxGeometryChecker($x, $y, $this->srid, 'occtax', $type_maille, $code);
        $return = $mgc->getMaille();

        // Return data
        $rep->data = $return;

        return $rep;
    }


    function uploadGeoJSON()
    {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'status' => 0,
            'msg' => array()
        );

        if (!jAcl2::check("requete.spatiale.import")) {
            $return['status'] = 0;
            $return['msg'][] = jLocale::get('occtax~search.form.error.right');
            $rep->data = $return;
            return $rep;
        }

        $form = jForms::get("occtax~upload_geojson");
        if (!$form)
            $form = jForms::create("occtax~upload_geojson");
        $form->initFromRequest();
        if (!$form->check()) {
            //$return['msg'] = $form->getErrors();
            $return['msg'][] = 'Fichier invalide';
            $rep->data = $return;
            return $rep;
        }

        $ext = strtolower(pathinfo($_FILES['geojson']['name'], PATHINFO_EXTENSION));
        if ($ext != 'json' && $ext != 'geojson') {
            $return['msg'][] = 'Fichier json requis';
            $rep->data = $return;
            return $rep;
        }

        $time = time();
        $form->saveFile('geojson', jApp::varPath('uploads'), $time . '_' . $_FILES['geojson']['name']);
        $json = jFile::read(jApp::varPath('uploads/' . $time . '_' . $_FILES['geojson']['name']));
        $json = json_decode($json);
        $return['result'] = $json;
        if (
            $json && property_exists($json, 'type')
            && $json->type == 'FeatureCollection'
            && property_exists($json, 'features')
        ) {
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


    /**
     * Autocompletion search for the form input
     * At present only for the jdd field
     *
     */
    function autocomplete()
    {

        $rep = $this->getResponse('json');

        $term = $this->param('field', 'jdd');
        $term = $this->param('term');
        $limit = $this->intParam('limit', 50);

        $autocomplete = jClasses::getService('occtax~autocomplete');
        $result = $autocomplete->getData($term, $limit);

        $rep->data = $result;

        return $rep;
    }


    /**
     * Get the complete data of a given JDD
     *
     * @httpparam string $jdd_id Dataset identifier
     */
    function getJdd()
    {
        $rep = $this->getResponse('json');

        // Get x and y params
        $jdd_id = trim($this->intParam('jdd_id', -1));
        $return = array(
            'status' => 0,
            'msg' => array()
        );
        if (empty($jdd_id)) {
            $msg[] = 'jdd_id invalide';
            $rep->data = $return;
            return $rep;
        }

        $cnx = jDb::getConnection('naturaliz_virtual_profile');
        $sql = ' SELECT jdd_id, jdd_code, jdd_libelle, jdd_description';
        $sql .= ' FROM occtax.jdd';
        $sql .= ' WHERE jdd_id = ' . $jdd_id . '::text';
        $result = $cnx->limitQuery($sql, 0, 1);
        $d = $result->fetch();
        if ($d) {
            //$d->geojson = json_decode( $d->geojson );
            $return['status'] = 1;
            $return['result'] = $d;
        } else {
            $return['msg'][] = jLocale::get($this->moduleName . '~search.getCommune.error');
        }

        // Return data
        $rep->data = $return;

        return $rep;
    }
}
