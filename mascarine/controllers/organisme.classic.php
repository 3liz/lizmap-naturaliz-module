<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class organismeCtrl extends jController {

    function add() {
        // Get form
        $form = jForms::get('mascarine~organisme');
        if ( $form === null )
            $form = jForms::create('mascarine~organisme');
        
        $rep = $this->getResponse('redirect');
        $rep->action = "mascarine~organisme:view";
        return $rep;
    }
    
    function view() {
        $rep = $this->getResponse('htmlfragment');
        $form = jForms::get('mascarine~organisme');
        if ( $form === null ) {
            return $rep;
        }
          
        $rep->tplname='mascarine~organisme'; 
        $rep->tpl->assign('form', $form);
        return $rep;
    }
    
    function submitAdd() {
        $rep = $this->getResponse('json');

        // Define object to return
        $return = array(
            'status' => 0,
            'msg' => array()
        );
        
        $form = jForms::get('mascarine~organisme');
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
        $id_org = $form->saveToDao('mascarine~organisme');
        jForms::destroy('mascarine~organisme');
        
        $return['status'] = 1;
        $return['msg'][] = 'Organisme ajouté';
        
        $dao = jDao::get('mascarine~organisme');
        $return['result'] = $dao->get( $id_org );
        $rep->data = $return;
        return $rep;
    }
    
}
