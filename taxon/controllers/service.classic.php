<?php
/**
* @package   lizmap
* @subpackage taxon
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class serviceCtrl extends jController {

    /**
     * Autocompletion search
     *
    */
    function autocomplete() {

        $rep = $this->getResponse('json');

        $term = $this->param( 'term' );
        $limit = $this->intParam( 'limit', 10 );
        $taxons_locaux = $this->param( 'taxons_locaux' );
        $taxons_bdd = $this->param( 'taxons_bdd' );

        $autocomplete = jClasses::getService('taxon~autocomplete');
        $result = $autocomplete->getData( $term, $limit, $taxons_locaux, $taxons_bdd );

        $rep->data = $result;

        return $rep;
    }


    function index(){
        $rep = $this->getResponse('html');
        $form = jForms::create('taxon~search');
        $tpl = new jTpl();
        $tpl->assign('form', $form);
        $rep->body->assign('MAIN', $tpl->fetch('taxon~search'));
        return $rep;

    }


    function initSearch() {

        $rep = $this->getResponse('json');

        // Get form
        $form = jForms::create('taxon~search');
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
        $fgroup = $form->getData( 'group' );
        if(is_array($fgroup)){
            $groups = $dao_group->getGroupsInpnFromTable( $fgroup );
        }else{
            $groups = $dao_group->getGroupsInpn( $fgroup );
        }
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


        // Get taxonSearch instance
        jClasses::inc('taxon~taxonSearch');
        $token = md5( $form->id().time().session_id() );
        $taxonSearch = new taxonSearch( $token, $form->getAllData() );
        jForms::destroy('taxon~search');

        // Get search description
        $description = $taxonSearch->getSearchDescription();

        $rep->data = array(
            'status' => 1,
            'token' => $token,
            'recordsTotal' => $taxonSearch->getRecordsTotal(),
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
        jClasses::inc('taxon~taxonSearch');

        // Get taxonSearch from token
        $token = $this->param('token');
        if( !isset( $_SESSION[taxonSearch::sessionPrefix . $token] ) ){
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'taxon~search.invalid.token' );
            $rep->data = $return;
            return $rep;
        }
        $taxonSearch = new taxonSearch( $token );

        // Get data
        $limit = $this->intParam( 'limit', 20 );
        $offset = $this->intParam( 'offset', 0 );
        $order = $this->param( 'order', '' );
        try {
            $return['recordsTotal'] = $taxonSearch->getRecordsTotal();
            $return['recordsFiltered'] = $taxonSearch->getRecordsTotal();
            $return['data'] = $taxonSearch->getData( $limit, $offset, $order );
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

