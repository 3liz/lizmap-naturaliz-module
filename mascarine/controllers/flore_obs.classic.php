<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class flore_obsCtrl extends jController {
    private $ini = null;
    
    private $types = array();
        
    private function prepareForm( $form, $type ) {
        $key = explode( '~', $form->getSelector() );
        if ( count($key) != 2 )
          return form;
        $key = $key[1];
        foreach( $form->getControls() as $ctrl ) {
            if ($ctrl->type == 'submit' || $ctrl->type == 'hidden' || $ctrl->type == 'button')
              continue;
            $val = $this->ini->getValue( 
                $type.'.'.$ctrl->ref,
                'form:'.$key
            );
            if ( $val == 'deactivate' )
                $form->deactivate( $ctrl->ref, True );
            else if ( $val == 'required' )
                $ctrl->required = True;
        }
        return $form;
    }
    
    function __construct( $request ) {
        parent::__construct( $request );
        $monfichier = jApp::configPath('mascarine.ini.php');
        $this->ini = new jIniFileModifier ($monfichier);
        
        $dao = jDao::get('mascarine~nomenclature');
        $this->types = $dao->findByField('type_obs');
    }

    function detail() {
        $rep = $this->getResponse('redirect');
        $rep->action = "mascarine~flore_obs:viewDetail";
        
        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            return $rep;
        }
        
        $rep->params = array(
            'id_obs'=>$id_obs
        );
        
        $cd_nom = $this->param( 'cd_nom' );
        if ( !$cd_nom ) {
            return $rep;
        }
        
        $strate_flore = $this->param( 'strate_flore' );
        if ( !$strate_flore ) {
            return $rep;
        }
        
        $rep->params = array(
            'id_obs'=>$id_obs,
            'cd_nom'=>$cd_nom,
            'strate_flore'=>$strate_flore
        );
        
        $id_flore_obs = $this->param( 'id_flore_obs' );
        if ( !$id_flore_obs ) {
            return $rep;
        }
        
        $rep->params = array(
            'id_obs'=>$id_obs,
            'cd_nom'=>$cd_nom,
            'strate_flore'=>$strate_flore,
            'id_flore_obs'=>$id_flore_obs
        );
        
        $form = jForms::create( "mascarine~detail_flore_obs", $id_flore_obs );
        $form->initFromDao( "mascarine~flore_obs" );
        
        return $rep;
    }

    function viewDetail() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~detail_flore_obs';
        
        $id_flore_obs = $this->param( 'id_flore_obs' );
        if ( !$id_flore_obs ) {
            jMessage::add( 'Aucun identifiant d\'observation flore', 'error' );
            return $rep;
        }
        
        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            jMessage::add( 'Aucun identifiant d\'observation', 'error' );
            return $rep;
        }
        
        $rep->params = array(
            'id_obs'=>$id_obs
        );
        
        $cd_nom = $this->param( 'cd_nom' );
        if ( !$cd_nom ) {
            jMessage::add( 'Aucun taxon', 'error' );
            return $rep;
        }
        
        $strate_flore = $this->param( 'strate_flore' );
        if ( !$strate_flore ) {
            jMessage::add( 'Aucune strate', 'error' );
            return $rep;
        }
        
        $rep->params = array(
            'id_obs'=>$id_obs,
            'cd_nom'=>$cd_nom,
            'strate_flore'=>$strate_flore,
            'id_flore_obs'=>$id_flore_obs
        );
        
        $form = jForms::get( "mascarine~detail_flore_obs", $id_flore_obs );
        if ( $form == null ) {
            jMessage::add( 'Utiliser l\'interface pour accéder au formulaire', 'error');
            return $rep;
        }
        
        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );
        
        $dao = jDao::get( 'taxon~taxref' );
        $taxref = $dao->get( $cd_nom );
        $form->setData( 'cd_nom_nom_valide', $taxref->nom_valide );
        
        $dao = jDao::get( 'mascarine~nomenclature' );
        $strate_flore = $dao->get( 'strate_flore', $strate_flore );
        $form->setData( 'strate_flore_valeur', $strate_flore->valeur );
        
        $cd_nom_phorophyte = $form->getData( 'cd_nom_phorophyte' );
        if ( $cd_nom_phorophyte != null ) {
            $phorophyte = $dao->get( $cd_nom_phorophyte );
            $form->setData( 'cd_nom_phorophyte_autocomplete', $phorophyte->nom_valide );
        }
        
        $rep->tpl->assign( 'id_obs', $id_obs );
        $rep->tpl->assign( 'cd_nom', $cd_nom );
        $rep->tpl->assign( 'strate_flore', $strate_flore->code );
        $rep->tpl->assign( 'id_flore_obs', $id_flore_obs );
        $rep->tpl->assign( 'form', $form );
        
        return $rep;
    }

    function submitDetail() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'status' => 0,
            'msg' => array()
        );
        
        $id_flore_obs = $this->param( 'id_flore_obs' );
        if ( !$id_flore_obs ) {
            $return['msg'][] = 'Aucun identifiant d\'observation flore';
            $rep->data = $return;
            return $rep;
        }
        
        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            $return['msg'][] = 'Aucun identifiant d\'observation';
            $rep->data = $return;
            return $rep;
        }
        
        $cd_nom = $this->param( 'cd_nom' );
        if ( !$cd_nom ) {
            $return['msg'][] = 'Aucun taxon';
            $rep->data = $return;
            return $rep;
        }
        
        $strate_flore = $this->param( 'strate_flore' );
        if ( !$strate_flore ) {
            $return['msg'][] = 'Aucune strate';
            return $rep;
        }
        
        $form = jForms::get( "mascarine~detail_flore_obs", $id_flore_obs );
        if ( $form == null ) {
            $return['msg'][] = 'Utiliser l\'interface pour accéder au formulaire';
            $rep->data = $return;
            return $rep;
        }
        
        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );
        
        $form->initFromRequest();
        if ( !$form->check() ) {
            $return['msg'][] = 'Formulaire invalide';
            $rep->data = $return;
            return $rep;
        }
        $form->saveToDao( "mascarine~flore_obs" );
        jForms::destroy( "mascarine~detail_flore_obs", $id_flore_obs );
        
        $return['status'] = 1;
        $return['msg'][] = 'Détail mis à jour';
        $rep->data = $return;
        return $rep;
    }
    
    function pheno() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~pheno_flore_obs';
        
        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            jMessage::add( 'Aucun identifiant d\'observation', 'error' );
            return $rep;
        }
        
        $rep->params = array(
            'id_obs'=>$id_obs
        );
        
        $cd_nom = $this->param( 'cd_nom' );
        if ( !$cd_nom ) {
            jMessage::add( 'Aucun taxon', 'error' );
            return $rep;
        }
        
        $strate_flore = $this->param( 'strate_flore' );
        if ( !$strate_flore ) {
            jMessage::add( 'Aucune strate', 'error' );
            return $rep;
        }
        
        $rep->params = array(
            'id_obs'=>$id_obs,
            'cd_nom'=>$cd_nom,
            'strate_flore'=>$strate_flore
        );
        
        $id_flore_obs = $this->param( 'id_flore_obs' );
        if ( !$id_flore_obs ) {
            jMessage::add( 'Aucune d\'observation flore', 'error' );
            return $rep;
        }
        
        $rep->params = array(
            'id_obs'=>$id_obs,
            'cd_nom'=>$cd_nom,
            'strate_flore'=>$strate_flore,
            'id_flore_obs'=>$id_flore_obs
        );
        
        $form = jForms::get( "mascarine~pheno_flore_obs" );
        if ( $form == null ) {
            $form = jForms::create( "mascarine~pheno_flore_obs" );
        }
        
        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );
        
        $form->setData('id_obs',$id_obs);
        $form->setData('cd_nom',$cd_nom);
        $form->setData('strate_flore',$strate_flore);
        $form->setData('id_flore_obs',$id_flore_obs);
        
        $rep->tpl->assign( 'id_obs', $id_obs );
        $rep->tpl->assign( 'cd_nom', $cd_nom );
        $rep->tpl->assign( 'strate_flore', $strate_flore );
        $rep->tpl->assign( 'id_flore_obs', $id_flore_obs );
        $rep->tpl->assign( 'form', $form );
        
        return $rep;
    }
    
    function phenos() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'recordsTotal' => 0,
            'recordsFiltered' => 0,
            'data' => array(),
            'msg' => array()
        );
        
        $id_flore_obs = $this->param( 'id_flore_obs' );
        if ( $id_flore_obs == null ) {
            $return['status'] = 0;
            $return['msg'][] = 'id_flore_obs mandatory';
            $rep->data = $return;
            return $rep;
        }
        
        $id_obs = $this->param( 'id_obs' );
        if ( $id_obs == null ) {
            $return['status'] = 0;
            $return['msg'][] = 'id_obs mandatory';
            $rep->data = $return;
            return $rep;
        }
        
        $cd_nom = $this->param( 'cd_nom' );
        if ( $cd_nom == null ) {
            $return['status'] = 0;
            $return['msg'][] = 'cd_nom mandatory';
            $rep->data = $return;
            return $rep;
        }
        
        $strate_flore = $this->param( 'strate_flore' );
        if ( $strate_flore == null ) {
            $return['status'] = 0;
            $return['msg'][] = 'strate_flore mandatory';
            $rep->data = $return;
            return $rep;
        }
        
        jClasses::inc('mascarine~phenoFloreObservationSearch');
        $phenoFloreSearch = new phenoFloreObservationSearch( array('id_flore_obs'=>$id_flore_obs, 'id_obs'=>$id_obs, 'cd_nom'=>$cd_nom, 'strate_flore'=>$strate_flore), null );
        
        // Get data
        $limit = $this->intParam( 'limit', 20 );
        $offset = $this->intParam( 'offset', 0 );
        try {
            $return['recordsTotal'] = $phenoFloreSearch->getRecordsTotal();
            $return['recordsFiltered'] = $phenoFloreSearch->getRecordsTotal();
            $return['data'] = $phenoFloreSearch->getData( $limit, $offset );
            $return['status'] = 1;
            $return['fields'] = $phenoFloreSearch->getFields();
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
    
    function addPheno() {
        // reponse if form not already create
        $rep = $this->getResponse('json');
        $return = array(
            'status' => 0,
            'msg' => array()
        );
        
        // verify form
        $form = jForms::get( "mascarine~pheno_flore_obs" );
        if ( $form == null ) {
            $return['msg'][] = 'Utiliser l\'interface pour accéder au formulaire';
            $rep->data = $return;
            return $rep;
        }
        
        $rep = $this->getResponse('redirect');
        $rep->action = "mascarine~flore_obs:pheno";
        
        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            jMessage::add( 'Aucun identifiant d\'observation', 'error' );
            return $rep;
        }
        
        $rep->params = array(
            'id_obs'=>$id_obs
        );
        
        $cd_nom = $this->param( 'cd_nom' );
        if ( !$cd_nom ) {
            jMessage::add( 'Aucun taxon', 'error' );
            return $rep;
        }
        $rep->params = array(
            'id_obs'=>$id_obs,
            'cd_nom'=>$cd_nom
        );
        
        $strate_flore = $this->param( 'strate_flore' );
        if ( !$strate_flore ) {
            jMessage::add( 'Aucune strate', 'error' );
            return $rep;
        }
        
        $rep->params = array(
            'id_obs'=>$id_obs,
            'cd_nom'=>$cd_nom,
            'strate_flore'=>$strate_flore
        );
        
        $id_flore_obs = $this->param( 'id_flore_obs' );
        if ( !$id_flore_obs ) {
            jMessage::add( 'Aucune identifiant d\'observation de flore', 'error' );
            return $rep;
        }
        
        $rep->params = array(
            'id_obs'=>$id_obs,
            'cd_nom'=>$cd_nom,
            'strate_flore'=>$strate_flore,
            'id_flore_obs'=>$id_flore_obs
        );
        
        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );
        
        $form->initFromRequest();
        if ( !$form->check() ) {
            $return['msg'][] = 'Formulaire invalide';
            $rep->data = $return;
            return $rep;
        }
        
        $form->saveToDao( "mascarine~pheno_flore_obs" );
        jForms::destroy( "mascarine~pheno_flore_obs" );
        
        return $rep;
    }
    
    function editPheno() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~edit_pheno_flore_obs';
        
        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            jMessage::add( 'Aucun identifiant d\'observation', 'error' );
            return $rep;
        }
        
        $cd_nom = $this->param( 'cd_nom' );
        if ( !$cd_nom ) {
            jMessage::add( 'Aucun taxon', 'error' );
            return $rep;
        }
        
        $strate_flore = $this->param( 'strate_flore' );
        if ( !$strate_flore ) {
            jMessage::add( 'Aucune strate', 'error' );
            return $rep;
        }
        
        $id_flore_obs = $this->param( 'id_flore_obs' );
        if ( !$id_flore_obs ) {
            jMessage::add( 'Aucune identifiant d\'observation de flore', 'error' );
            return $rep;
        }
        
        $id_pheno_flore_obs = $this->param( 'id_pheno_flore_obs' );
        if ( !$id_pheno_flore_obs ) {
            jMessage::add( 'Aucun identifiant de pheno' );
            return $rep;
        }
        
        $form = jForms::get( "mascarine~pheno_flore_obs", $id_pheno_flore_obs );
        if ( $form == null ) {
            $form = jForms::create( "mascarine~pheno_flore_obs", $id_pheno_flore_obs );
        }
        
        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );
        $submits = $form->getSubmits();
        $submit = $submits['submit'];
        $submit->label = 'Modifier';
        
        $form->initFromDao( "mascarine~pheno_flore_obs" );
        
        $form->setData('id_obs',$id_obs);
        $form->setData('cd_nom',$cd_nom);
        $form->setData('strate_flore',$strate_flore);
        $form->setData('id_flore_obs',$id_flore_obs);
        
        $rep->tpl->assign( 'id_obs', $id_obs );
        $rep->tpl->assign( 'cd_nom', $cd_nom );
        $rep->tpl->assign( 'strate_flore', $strate_flore );
        $rep->tpl->assign( 'id_flore_obs', $id_flore_obs );
        $rep->tpl->assign( 'id_pheno_flore_obs', $id_pheno_flore_obs );
        $rep->tpl->assign( 'form', $form );
        
        return $rep;
    }
    
    function updatePheno() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'status' => 0,
            'msg' => array()
        );
        
        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            $return['msg'][] = 'Aucun identifiant d\'observation';
            $rep->data = $return;
            return $rep;
        }
        
        $cd_nom = $this->param( 'cd_nom' );
        if ( !$cd_nom ) {
            $return['msg'][] = 'Aucun taxon';
            $rep->data = $return;
            return $rep;
        }
        
        $strate_flore = $this->param( 'strate_flore' );
        if ( !$strate_flore ) {
            $return['msg'][] = 'Aucune strate';
            $rep->data = $return;
            return $rep;
        }
        
        $id_flore_obs = $this->param( 'id_flore_obs' );
        if ( !$id_flore_obs ) {
            $return['msg'][] = 'Aucun identifiant d\'observation de taxon';
            $rep->data = $return;
            return $rep;
        }
        
        $id_pheno_flore_obs = $this->param( 'id_pheno_flore_obs' );
        if ( !$id_pheno_flore_obs ) {
            $return['msg'][] = 'Aucun identifiant de pheno';
            $rep->data = $return;
            return $rep;
        }
        
        $form = jForms::get( "mascarine~pheno_flore_obs", $id_pheno_flore_obs );
        if ( $form == null ) {
            $return['msg'][] = 'Utiliser l\'interface pour accéder au formulaire';
            $rep->data = $return;
            return $rep;
        }
        
        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );
        
        $form->initFromRequest();
        if ( !$form->check() ) {
            $return['msg'][] = 'Formulaire invalide';
            $rep->data = $return;
            return $rep;
        }
        
        $form->saveToDao( "mascarine~pheno_flore_obs" );
        jForms::destroy( "mascarine~pheno_flore_obs", $id_pheno_flore_obs );
        
        $return['status'] = 1;
        $return['msg'][] = 'Phénologie mise à jour';
        $rep->data = $return;
        return $rep;
    }
    
    function removePheno() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'status' => 0,
            'msg' => array()
        );
        
        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            $return['msg'][] = 'Aucun identifiant d\'observation';
            $rep->data = $return;
            return $rep;
        }
        
        $cd_nom = $this->param( 'cd_nom' );
        if ( !$cd_nom ) {
            $return['msg'][] = 'Aucun taxon';
            $rep->data = $return;
            return $rep;
        }
        
        $strate_flore = $this->param( 'strate_flore' );
        if ( !$strate_flore ) {
            $return['msg'][] = 'Aucune strate';
            return $rep;
        }
        
        $id_flore_obs = $this->param( 'id_flore_obs' );
        if ( !$id_flore_obs ) {
            $return['msg'][] = 'Aucun identifiant d\'observation de taxon';
            return $rep;
        }
        
        $id_pheno_flore_obs = $this->param( 'id_pheno_flore_obs' );
        if ( !$id_pheno_flore_obs ) {
            $return['msg'][] = 'Aucun identifiant de pheno';
            return $rep;
        }
        
        // create conditions
        $conditions = jDao::createConditions();
        $conditions->addCondition('id_obs','=',$id_obs);
        $conditions->addCondition('cd_nom','=',$cd_nom);
        $conditions->addCondition('strate_flore','=',$strate_flore);
        $conditions->addCondition('id_flore_obs','=',$id_flore_obs);
        $conditions->addCondition('id_pheno_flore_obs','=',$id_pheno_flore_obs);
        
        $dao = jDao::get('mascarine~pheno_flore_obs');
        $dao->deleteBy($conditions);
        
        $return['msg'][] = 'Effectif supprimé';
        $return['status'] = 1;
        $rep->data = $return;
        return $rep;
    }
    
    function pop() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~pop_flore_obs';
        
        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            jMessage::add( 'Aucun identifiant d\'observation', 'error' );
            return $rep;
        }
        
        $rep->params = array(
            'id_obs'=>$id_obs
        );
        
        $cd_nom = $this->param( 'cd_nom' );
        if ( !$cd_nom ) {
            jMessage::add( 'Aucun taxon', 'error' );
            return $rep;
        }
        $rep->params = array(
            'id_obs'=>$id_obs,
            'cd_nom'=>$cd_nom
        );
        
        $strate_flore = $this->param( 'strate_flore' );
        if ( !$strate_flore ) {
            jMessage::add( 'Aucune strate', 'error' );
            return $rep;
        }
        
        $rep->params = array(
            'id_obs'=>$id_obs,
            'cd_nom'=>$cd_nom,
            'strate_flore'=>$strate_flore
        );
        
        $id_flore_obs = $this->param( 'id_flore_obs' );
        if ( !$id_flore_obs ) {
            jMessage::add( 'Aucune d\'observation flore', 'error' );
            return $rep;
        }
        
        $rep->params = array(
            'id_obs'=>$id_obs,
            'cd_nom'=>$cd_nom,
            'strate_flore'=>$strate_flore,
            'id_flore_obs'=>$id_flore_obs
        );
        
        $form = jForms::get( "mascarine~pop_flore_obs" );
        if ( $form == null ) {
            $form = jForms::create( "mascarine~pop_flore_obs" );
        }
        
        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );
        
        $form->setData('id_obs',$id_obs);
        $form->setData('cd_nom',$cd_nom);
        $form->setData('strate_flore',$strate_flore);
        $form->setData('id_flore_obs',$id_flore_obs);
        
        $rep->tpl->assign( 'id_obs', $id_obs );
        $rep->tpl->assign( 'cd_nom', $cd_nom );
        $rep->tpl->assign( 'strate_flore', $strate_flore );
        $rep->tpl->assign( 'id_flore_obs', $id_flore_obs );
        $rep->tpl->assign( 'form', $form );
        
        return $rep;
    }
    
    function pops() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'recordsTotal' => 0,
            'recordsFiltered' => 0,
            'data' => array(),
            'msg' => array()
        );
        
        $id_flore_obs = $this->param( 'id_flore_obs' );
        if ( $id_flore_obs == null ) {
            $return['status'] = 0;
            $return['msg'][] = 'id_flore_obs mandatory';
            $rep->data = $return;
            return $rep;
        }
        
        $id_obs = $this->param( 'id_obs' );
        if ( $id_obs == null ) {
            $return['status'] = 0;
            $return['msg'][] = 'id_obs mandatory';
            $rep->data = $return;
            return $rep;
        }
        
        $cd_nom = $this->param( 'cd_nom' );
        if ( $cd_nom == null ) {
            $return['status'] = 0;
            $return['msg'][] = 'cd_nom mandatory';
            $rep->data = $return;
            return $rep;
        }
        
        $strate_flore = $this->param( 'strate_flore' );
        if ( $strate_flore == null ) {
            $return['status'] = 0;
            $return['msg'][] = 'strate_flore mandatory';
            $rep->data = $return;
            return $rep;
        }
        
        jClasses::inc('mascarine~popFloreObservationSearch');
        $popFloreSearch = new popFloreObservationSearch( array('id_flore_obs'=>$id_flore_obs, 'id_obs'=>$id_obs, 'cd_nom'=>$cd_nom, 'strate_flore'=>$strate_flore), null );
        
        // Get data
        $limit = $this->intParam( 'limit', 20 );
        $offset = $this->intParam( 'offset', 0 );
        try {
            $return['recordsTotal'] = $popFloreSearch->getRecordsTotal();
            $return['recordsFiltered'] = $popFloreSearch->getRecordsTotal();
            $return['data'] = $popFloreSearch->getData( $limit, $offset );
            $return['status'] = 1;
            $return['fields'] = $popFloreSearch->getFields();
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
    
    function addPop() {
        // reponse if form not already create
        $rep = $this->getResponse('json');
        $return = array(
            'status' => 0,
            'msg' => array()
        );
        
        // verify form
        $form = jForms::get( "mascarine~pop_flore_obs" );
        if ( $form == null ) {
            $return['msg'][] = 'Utiliser l\'interface pour accéder au formulaire';
            $rep->data = $return;
            return $rep;
        }
        
        $rep = $this->getResponse('redirect');
        $rep->action = "mascarine~flore_obs:pop";
        
        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            jMessage::add( 'Aucun identifiant d\'observation', 'error' );
            return $rep;
        }
        
        $rep->params = array(
            'id_obs'=>$id_obs
        );
        
        $cd_nom = $this->param( 'cd_nom' );
        if ( !$cd_nom ) {
            jMessage::add( 'Aucun taxon', 'error' );
            return $rep;
        }
        $rep->params = array(
            'id_obs'=>$id_obs,
            'cd_nom'=>$cd_nom
        );
        
        $strate_flore = $this->param( 'strate_flore' );
        if ( !$strate_flore ) {
            jMessage::add( 'Aucune strate', 'error' );
            return $rep;
        }
        
        $rep->params = array(
            'id_obs'=>$id_obs,
            'cd_nom'=>$cd_nom,
            'strate_flore'=>$strate_flore
        );
        
        $id_flore_obs = $this->param( 'id_flore_obs' );
        if ( !$id_flore_obs ) {
            jMessage::add( 'Aucune identifiant d\'observation de flore', 'error' );
            return $rep;
        }
        
        $rep->params = array(
            'id_obs'=>$id_obs,
            'cd_nom'=>$cd_nom,
            'strate_flore'=>$strate_flore,
            'id_flore_obs'=>$id_flore_obs
        );
        
        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );
        
        $form->initFromRequest();
        if ( !$form->check() ) {
            $return['msg'][] = 'Formulaire invalide';
            $rep->data = $return;
            return $rep;
        }
        
        $form->saveToDao( "mascarine~pop_flore_obs" );
        jForms::destroy( "mascarine~pop_flore_obs" );
        
        return $rep;
    }
    
    function editPop() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~edit_pop_flore_obs';
        
        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            jMessage::add( 'Aucun identifiant d\'observation', 'error' );
            return $rep;
        }
        
        $cd_nom = $this->param( 'cd_nom' );
        if ( !$cd_nom ) {
            jMessage::add( 'Aucun taxon', 'error' );
            return $rep;
        }
        
        $strate_flore = $this->param( 'strate_flore' );
        if ( !$strate_flore ) {
            jMessage::add( 'Aucune strate', 'error' );
            return $rep;
        }
        
        $id_flore_obs = $this->param( 'id_flore_obs' );
        if ( !$id_flore_obs ) {
            jMessage::add( 'Aucune identifiant d\'observation de flore', 'error' );
            return $rep;
        }
        
        $id_pop_flore_obs = $this->param( 'id_pop_flore_obs' );
        if ( !$id_pop_flore_obs ) {
            jMessage::add( 'Aucun identifiant de pheno' );
            return $rep;
        }
        
        $form = jForms::get( "mascarine~pop_flore_obs", $id_pop_flore_obs );
        if ( $form == null ) {
            $form = jForms::create( "mascarine~pop_flore_obs", $id_pop_flore_obs );
        }
        
        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );
        $submits = $form->getSubmits();
        $submit = $submits['submit'];
        $submit->label = 'Modifier';
        
        $form->initFromDao( "mascarine~pop_flore_obs" );
        
        $form->setData('id_obs',$id_obs);
        $form->setData('cd_nom',$cd_nom);
        $form->setData('strate_flore',$strate_flore);
        $form->setData('id_flore_obs',$id_flore_obs);
        
        $rep->tpl->assign( 'id_obs', $id_obs );
        $rep->tpl->assign( 'cd_nom', $cd_nom );
        $rep->tpl->assign( 'strate_flore', $strate_flore );
        $rep->tpl->assign( 'id_flore_obs', $id_flore_obs );
        $rep->tpl->assign( 'id_pop_flore_obs', $id_pop_flore_obs );
        $rep->tpl->assign( 'form', $form );
        
        return $rep;
    }
    
    function updatePop() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'status' => 0,
            'msg' => array()
        );
        
        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            $return['msg'][] = 'Aucun identifiant d\'observation';
            $rep->data = $return;
            return $rep;
        }
        
        $cd_nom = $this->param( 'cd_nom' );
        if ( !$cd_nom ) {
            $return['msg'][] = 'Aucun taxon';
            $rep->data = $return;
            return $rep;
        }
        
        $strate_flore = $this->param( 'strate_flore' );
        if ( !$strate_flore ) {
            $return['msg'][] = 'Aucune strate';
            $rep->data = $return;
            return $rep;
        }
        
        $id_flore_obs = $this->param( 'id_flore_obs' );
        if ( !$id_flore_obs ) {
            $return['msg'][] = 'Aucun identifiant d\'observation de taxon';
            $rep->data = $return;
            return $rep;
        }
        
        $id_pop_flore_obs = $this->param( 'id_pop_flore_obs' );
        if ( !$id_pop_flore_obs ) {
            $return['msg'][] = 'Aucun identifiant d\'effectif';
            $rep->data = $return;
            return $rep;
        }
        
        $form = jForms::get( "mascarine~pop_flore_obs", $id_pop_flore_obs );
        if ( $form == null ) {
            $return['msg'][] = 'Utiliser l\'interface pour accéder au formulaire';
            $rep->data = $return;
            return $rep;
        }
        
        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );
        
        $form->initFromRequest();
        if ( !$form->check() ) {
            $return['msg'][] = 'Formulaire invalide';
            $rep->data = $return;
            return $rep;
        }
        
        $form->saveToDao( "mascarine~pop_flore_obs" );
        jForms::destroy( "mascarine~pop_flore_obs", $id_pop_flore_obs );
        
        $return['status'] = 1;
        $return['msg'][] = 'Effectif mis à jour';
        $rep->data = $return;
        return $rep;
    }
    
    function removePop() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'status' => 0,
            'msg' => array()
        );
        
        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            $return['msg'][] = 'Aucun identifiant d\'observation';
            $rep->data = $return;
            return $rep;
        }
        
        $cd_nom = $this->param( 'cd_nom' );
        if ( !$cd_nom ) {
            $return['msg'][] = 'Aucun taxon';
            $rep->data = $return;
            return $rep;
        }
        
        $strate_flore = $this->param( 'strate_flore' );
        if ( !$strate_flore ) {
            $return['msg'][] = 'Aucune strate';
            return $rep;
        }
        
        $id_flore_obs = $this->param( 'id_flore_obs' );
        if ( !$id_flore_obs ) {
            $return['msg'][] = 'Aucun identifiant d\'observation de taxon';
            return $rep;
        }
        
        $id_pop_flore_obs = $this->param( 'id_pop_flore_obs' );
        if ( !$id_pop_flore_obs ) {
            $return['msg'][] = 'Aucun identifiant d\'effectif';
            return $rep;
        }
        
        // create conditions
        $conditions = jDao::createConditions();
        $conditions->addCondition('id_obs','=',$id_obs);
        $conditions->addCondition('cd_nom','=',$cd_nom);
        $conditions->addCondition('strate_flore','=',$strate_flore);
        $conditions->addCondition('id_flore_obs','=',$id_flore_obs);
        $conditions->addCondition('id_pop_flore_obs','=',$id_pop_flore_obs);
        
        $dao = jDao::get('mascarine~pop_flore_obs');
        $dao->deleteBy($conditions);
        
        $return['msg'][] = 'Effectif supprimé';
        $return['status'] = 1;
        $rep->data = $return;
        return $rep;
    }
}
