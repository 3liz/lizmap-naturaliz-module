<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class personneCtrl extends jController {

    function add() {
        // Get form
        $form = jForms::get('mascarine~personne');
        if ( $form === null )
            $form = jForms::create('mascarine~personne');
        
        $id_org = $this->param( 'id_org' );
        if ( $id_org )
          $form->setData( 'id_org', $id_org );
        
        $rep = $this->getResponse('redirect');
        $rep->action = "mascarine~personne:view";
        return $rep;
    }
    
    function modify() {
        $rep = $this->getResponse('redirect');
        
        $id = $this->param( 'id' );
        if ( !jAcl2::check('auth.users.modify') )
            $id = null;
        $perso = null;
        $session_perso = False;
        
        $dao = jDao::get('mascarine~personne');
        if ( !$id ) {
            $user = jAuth::getUserSession();
            $perso = $dao->getByUserLogin( $user->login );
            if ( !$perso ) {
                $rep->action = 'mascarine~usr_login_personne:index';
                return $rep;
            }
            $id = $perso->id_perso;
            $session_perso = True;
        }
        
        if ( !$session_perso )
            $perso = $dao->get( $id );
        
        if ( !$perso )
          return $rep;
          
        $form = jForms::get('mascarine~personne', $id);
        if ( $form === null )
            $form = jForms::create('mascarine~personne', $id);
        $form->initFromDao('mascarine~personne');
        
        $rep->action = "mascarine~personne:view";
        $rep->params = array('id' => $id);
        return $rep;
    }
    
    function view() {
        $rep = $this->getResponse('htmlfragment');
        
        $form = null;
        $id = $this->param( 'id' );
        if ( !$id )
          $form = jForms::get('mascarine~personne');
        else
          $form = jForms::get('mascarine~personne', $id);
          
        if ( $form === null ) {
            return $rep;
        }
          
        $rep->tplname='mascarine~personne';
        $rep->tpl->assign('id', $id);
        $rep->tpl->assign('form', $form);
        return $rep;
    }
    
    function create() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'status' => 0,
            'msg' => array()
        );
        
        $form = jForms::get('mascarine~personne');
        if ( $form === null ) {
            $return['msg'][] = 'form mandatory';
            $rep->data = $return;
            return $rep;
        }
        $form->initFromRequest();
        if ( !$form->check() ) {
            $return['msg'][] = 'form invalid';
            $rep->data = $return;
            return $rep;
        }
        $id_perso = $form->saveToDao('mascarine~personne');
        jForms::destroy('mascarine~personne');
        
        $return['status'] = 1;
        $return['msg'][] = 'Personne ajouté';
        
        $dao = jDao::get('mascarine~personne');
        $return['result'] = $dao->get( $id_perso );
        $rep->data = $return;
        return $rep;
    }
    
    function update() {
        $rep = $this->getResponse('json');
        
        // Define object to return
        $return = array(
            'status' => 0,
            'msg' => array()
        );
        
        $id = $this->param( 'id' );
        if ( !$id ) {
            $return['msg'][] = 'Id mandatory';
            $rep->data = $return;
            return $rep;
        }
        
        $form = jForms::get( 'mascarine~personne', $id );
        if ( $form === null ) {
            $return['msg'][] = 'form mandatory';
            $rep->data = $return;
            return $rep;
        }
        $form->initFromRequest();
        if ( !$form->check() ) {
            $return['msg'][] = 'form invalid';
            $rep->data = $return;
            return $rep;
        }
        $form->saveToDao('mascarine~personne');
        jForms::destroy( 'mascarine~personne', $id );
        
        $return['status'] = 1;
        $return['msg'][] = 'Mise à jour réussi';
        
        $rep->data = $return;
        return $rep;
    }
    
}
