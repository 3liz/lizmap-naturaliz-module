<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    3liz
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class observationCtrl extends jController {

    /**
     * Get observation detail
     *
     */
    function getObservation() {

        $rep = $this->getResponse('htmlfragment');
        $return = array();
        $attributes = array();

        // Get form
        $form = jForms::create('mascarine~search');

        // Init form from request
        $id = $this->param('id');
        $form->initFromRequest();
        if( $id )
            $form->setData('id_obs', $id);

        // Get mascarineSearch instance
        jClasses::inc('mascarine~mascarineSearchObservation');
        $token = md5( $form->id().time().session_id() );
        $mascarineSearch = new mascarineSearchObservation( $token, $form->getAllData() );
        jForms::destroy('mascarine~search');
        jClasses::inc('mascarine~mascarineExportSingleObservation');
        $mascarineSearch = new mascarineExportSingleObservation( $token, null );

        // Get data
        $limit = 1;
        $offset = 0;
        try {
            $return = $mascarineSearch->getData( $limit, $offset );
            $fields = $mascarineSearch->getFields();
            $attributes = $fields['display'];
        }
        catch( Exception $e ) {
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'mascarine~search.form.error.query' );
            $rep->data = $return;
            return $rep;
        }

        // Insert main data into an array (for the template)
        $data = array();
        if( count( $return ) > 0 ) {
            foreach($return as $line){
                $i = 0;
                foreach($fields['display'] as $attr){
                    $data[$attr] = $line[$i];
                    $i++;
                };
            }
        }

        // Get child data
        $topics = array(
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

        $children = array();
        foreach( $topics as $topic ) {
            // Get data for the given topic
            $return = $mascarineSearch->getTopicData( $topic );
            if( !$return )
                continue;

            $children[$topic] = $return;
        }

        $tpl = new jTpl();
        $tpl->assign('data', $data);
        $tpl->assign('children', $children);
        $content = $tpl->fetch('mascarine~observation');

        $rep->addContent( $content );

        return $rep;
    }


    function unvalid() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'recordsTotal' => 0,
            'recordsFiltered' => 0,
            'data' => array(),
            'msg' => array()
        );

        $dao = jDao::get('mascarine~personne');
        $user = jAuth::getUserSession();
        $perso = $dao->getByUserLogin( $user->login );

        jClasses::inc('mascarine~unvalidateObservationSearch');
        $unvalidateSearch = new unvalidateObservationSearch( $perso->id_perso, null );

        // Get data
        $limit = $this->intParam( 'limit', 20 );
        $offset = $this->intParam( 'offset', 0 );
        try {
            $return['recordsTotal'] = $unvalidateSearch->getRecordsTotal();
            $return['recordsFiltered'] = $unvalidateSearch->getRecordsTotal();
            $return['data'] = $unvalidateSearch->getData( $limit, $offset );
            $return['status'] = 1;
            $return['fields'] = $unvalidateSearch->getFields();
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

    function personnes() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'recordsTotal' => 0,
            'recordsFiltered' => 0,
            'data' => array(),
            'msg' => array()
        );

        $id_obs = $this->param( 'id_obs' );
        if ( $id_obs == null ) {
            $return['status'] = 0;
            $return['msg'][] = 'id_obs mandatory';
            $rep->data = $return;
            return $rep;
        }

        jClasses::inc('mascarine~personneObservationSearch');
        $personneSearch = new personneObservationSearch( $id_obs, null );

        // Get data
        $limit = $this->intParam( 'limit', 20 );
        $offset = $this->intParam( 'offset', 0 );
        try {
            $return['recordsTotal'] = $personneSearch->getRecordsTotal();
            $return['recordsFiltered'] = $personneSearch->getRecordsTotal();
            $return['data'] = $personneSearch->getData( $limit, $offset );
            $return['status'] = 1;
            $return['fields'] = $personneSearch->getFields();
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

    function taxons() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'recordsTotal' => 0,
            'recordsFiltered' => 0,
            'data' => array(),
            'msg' => array()
        );

        $id_obs = $this->param( 'id_obs' );
        if ( $id_obs == null ) {
            $return['status'] = 0;
            $return['msg'][] = 'id_obs mandatory';
            $rep->data = $return;
            return $rep;
        }

        jClasses::inc('mascarine~taxonObservationSearch');
        $taxonSearch = new taxonObservationSearch( $id_obs, null );

        // Get data
        $limit = $this->intParam( 'limit', 20 );
        $offset = $this->intParam( 'offset', 0 );
        try {
            $return['recordsTotal'] = $taxonSearch->getRecordsTotal();
            $return['recordsFiltered'] = $taxonSearch->getRecordsTotal();
            $return['data'] = $taxonSearch->getData( $limit, $offset );
            $return['status'] = 1;
            $return['fields'] = $taxonSearch->getFields();
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

    function habitats() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'recordsTotal' => 0,
            'recordsFiltered' => 0,
            'data' => array(),
            'msg' => array()
        );

        $id_obs = $this->param( 'id_obs' );
        if ( $id_obs == null ) {
            $return['status'] = 0;
            $return['msg'][] = 'id_obs mandatory';
            $rep->data = $return;
            return $rep;
        }

        jClasses::inc('mascarine~habitatObservationSearch');
        $habitatSearch = new habitatObservationSearch( $id_obs, null );

        // Get data
        $limit = $this->intParam( 'limit', 20 );
        $offset = $this->intParam( 'offset', 0 );
        try {
            $return['recordsTotal'] = $habitatSearch->getRecordsTotal();
            $return['recordsFiltered'] = $habitatSearch->getRecordsTotal();
            $return['data'] = $habitatSearch->getData( $limit, $offset );
            $return['status'] = 1;
            $return['fields'] = $habitatSearch->getFields();
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

    function menaces() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'recordsTotal' => 0,
            'recordsFiltered' => 0,
            'data' => array(),
            'msg' => array()
        );

        $id_obs = $this->param( 'id_obs' );
        if ( $id_obs == null ) {
            $return['status'] = 0;
            $return['msg'][] = 'id_obs mandatory';
            $rep->data = $return;
            return $rep;
        }

        jClasses::inc('mascarine~menaceObservationSearch');
        $menaceSearch = new menaceObservationSearch( $id_obs, null );

        // Get data
        $limit = $this->intParam( 'limit', 20 );
        $offset = $this->intParam( 'offset', 0 );
        try {
            $return['recordsTotal'] = $menaceSearch->getRecordsTotal();
            $return['recordsFiltered'] = $menaceSearch->getRecordsTotal();
            $return['data'] = $menaceSearch->getData( $limit, $offset );
            $return['status'] = 1;
            $return['fields'] = $menaceSearch->getFields();
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

    function documents() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'recordsTotal' => 0,
            'recordsFiltered' => 0,
            'data' => array(),
            'msg' => array()
        );

        $id_obs = $this->param( 'id_obs' );
        if ( $id_obs == null ) {
            $return['status'] = 0;
            $return['msg'][] = 'id_obs mandatory';
            $rep->data = $return;
            return $rep;
        }

        jClasses::inc('mascarine~documentObservationSearch');
        $documentSearch = new documentObservationSearch( $id_obs, null );

        // Get data
        $limit = $this->intParam( 'limit', 20 );
        $offset = $this->intParam( 'offset', 0 );
        try {
            $return['recordsTotal'] = $documentSearch->getRecordsTotal();
            $return['recordsFiltered'] = $documentSearch->getRecordsTotal();
            $return['data'] = $documentSearch->getData( $limit, $offset );
            $return['status'] = 1;
            $return['fields'] = $documentSearch->getFields();
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

    function document() {
        $rep = $this->getResponse('json');
        $return = array(
            'status' => 0,
            'msg' => array()
        );

        $id_obs = $this->param( 'id_obs' );
        if ( $id_obs == null ) {
            $return['msg'][] = 'id_obs mandatory';
            $rep->data = $return;
            return $rep;
        }

        $document = $this->param( 'document' );
        if ( $document == null ) {
            $return['msg'][] = 'document mandatory';
            $rep->data = $return;
            return $rep;
        }

        $filePath = jApp::varPath("documents/".$id_obs.'/'.$document);
        if ( !is_file( $filePath ) ) {
            $return['msg'][] = 'document is not a file';
            $rep->data = $return;
            return $rep;
        }

        $rep = $this->getResponse('binary');
        $rep->fileName = $filePath;
        return $rep;
    }
}
