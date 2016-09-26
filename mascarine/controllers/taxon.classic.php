<?php
/**
* @package   lizmap
* @subpackage taxon
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class taxonCtrl extends jController {

    /**
     * Autocompletion search
     *
    */
    function autocomplete() {

        $rep = $this->getResponse('json');

        $term = $this->param( 'term' );
        $limit = $this->intParam( 'limit', 10 );

        $autocomplete = jClasses::getService('mascarine~plantaeAutocomplete');
        $result = $autocomplete->getData( $term, $limit );

        $rep->data = $result;

        return $rep;
    }


    function index(){
        $rep = $this->getResponse('html');
        $form = jForms::create('mascarine~taxon_search');
        $tpl = new jTpl();
        $tpl->assign('form', $form);
        $rep->body->assign('MAIN', $tpl->fetch('mascarine~taxon_search'));
        return $rep;

    }


    function getSearchToken() {

        $rep = $this->getResponse('json');

        // Get form
        $form = jForms::create('mascarine~taxon_search');
        $form->initFromRequest();

        // Check form
        if ( !$form->check() ) {
            $return = array();
            $return['status'] = 0;
            $return['msg'] = array( jLocale::get( 'taxon~search.form.error.check' ) );
            $rep->data = $return;
            return $rep;
        }

        // Add field depending on given "group" value
        $dao_group = jDao::get('taxon~t_group_categorie');
        $groups = $dao_group->getGroupsInpnByRegne( $form->getData( 'group' ), 'Plantae' );
        $gr1 = array();
        $gr2 = array();
        foreach( $groups as $group ){
            if( $group->groupe_type == 'group1_inpn' )
                $gr1[] = $group->groupe_nom;
            else
                $gr2[] = $group->groupe_nom;
        }
        if( count( $gr1 ) > 0 ){
            $ctrl = new jFormsControlHidden( 'group1_inpn' );
            $form->addControl( $ctrl );
            $form->setData( 'group1_inpn', $gr1 );
        }
        if( count( $gr2 ) > 0 ){
            $ctrl = new jFormsControlHidden( 'group2_inpn' );
            $form->addControl( $ctrl );
            $form->setData( 'group2_inpn', $gr2 );
        }
        $ctrl = new jFormsControlHidden( 'regne' );
        $form->addControl( $ctrl );
        $form->setData( 'regne', 'Plantae' );

        // Get plantaeSearch instance
        jClasses::inc('mascarine~plantaeSearch');
        $token = md5( $form->id().time().session_id() );
        $plantaeSearch = new plantaeSearch( $token, $form->getAllData() );
        jForms::destroy('mascarine~taxon_search');

        // Get search description
        $description = $plantaeSearch->getSearchDescription();

        $rep->data = array(
            'status' => 1,
            'token' => $token,
            'recordsTotal' => $plantaeSearch->getRecordsTotal(),
            'description' => $description
        );

        return $rep;

    }


    /**
     * Classic search
     *
    */
    function search() {

        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'recordsTotal' => 0,
            'recordsFiltered' => 0,
            'data' => array(),
            'msg' => array()
        );
        jClasses::inc('mascarine~plantaeSearch');

        // Get plantaeSearch from token
        $token = $this->param('token');
        if( !isset( $_SESSION[plantaeSearch::sessionPrefix . $token] ) ){
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'taxon~search.invalid.token' );
            $rep->data = $return;
            return $rep;
        }
        $plantaeSearch = new plantaeSearch( $token );

        // Get data
        $limit = $this->intParam( 'limit', 20 );
        $offset = $this->intParam( 'offset', 0 );
        $order = $this->param( 'order', '' );
        try {
            $return['recordsTotal'] = $plantaeSearch->getRecordsTotal();
            $return['recordsFiltered'] = $plantaeSearch->getRecordsTotal();
            $return['data'] = $plantaeSearch->getData( $limit, $offset, $order );
            $return['status'] = 1;
        }
        catch( Exception $e ) {
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'taxon~search.form.error.query' );
            $rep->data = $return;
            return $rep;
        }

        // Return data
        $rep->data = $return;

        return $rep;
    }
}

