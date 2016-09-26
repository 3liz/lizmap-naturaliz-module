<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class usr_login_personneCtrl extends jController {

    function index() {
        $rep = $this->getResponse('redirect');
        
        $dao = jDao::get('mascarine~personne');
        $user = jAuth::getUserSession();
        $perso = $dao->getByUserLogin( $user->login );
        if ( $perso != null ) {
            $rep->action = "mascarine~personne:modify";
            return $rep;
        }
        
        // Get form
        $form = jForms::get('mascarine~usr_login_personne');
        if ( $form === null )
            $form = jForms::create('mascarine~usr_login_personne');
        
        $rep = $this->getResponse('redirect');
        $rep->action = "mascarine~usr_login_personne:view";
        return $rep;
    }
    
    function view() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~usr_login_personne';
        
        $form = jForms::get('mascarine~usr_login_personne');
        if ( $form === null ) {
            return $rep;
        }
           
        $rep->tpl->assign('form', $form);
        return $rep;
    }
    
    function submit() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'status' => 0,
            'msg' => array()
        );
        
        $form = jForms::get('mascarine~usr_login_personne');
        if ( $form === null ) {
            $return['msg'][] = 'form invalid';
            $rep->data = $return;
            return $rep;
        }
        $form->initFromRequest();
        if ( !$form->check() ) {
            $return['msg'][] = 'form invalid';
            $rep->data = $return;
            return $rep;
        }
        
        $dao = jDao::get('mascarine~personne');
        $perso = null;
        if ( $form->getData( 'select_perso' ) == '1' ) {
            $perso = $dao->get( $form->getData( 'id_perso' ) );
        } else {
            $id_perso = $form->saveToDao('mascarine~personne');
            jForms::destroy('mascarine~usr_login_personne');
            $perso = $dao->get( $id_perso );
            $return['msg'][] = 'Perso créé';
        }
        
        $user = jAuth::getUserSession();
        $perso->usr_login = $user->login;
        
        if ( $form->getData( 'select_org' ) != '1' ) {
            $perso->id_org = $form->saveToDao('mascarine~organisme');
        }
        
        $dao->update( $perso );
        
        $return['status'] = 1;
        $return['msg'][] = 'Perso lié';
        
        $return['result'] = 
        $rep->data = $return;
        return $rep;
    }
    
}
