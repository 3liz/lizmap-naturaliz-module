<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class editCtrl extends jController {

    function getAddObservation() {
        $dao = jDao::get('mascarine~personne');
        $user = jAuth::getUserSession();
        $perso = $dao->getByUserLogin( $user->login );
        if ( !$perso ) {
            $rep = $this->getResponse('htmlfragment');
            jMessage::add( 'Aucun perso associé à votre profil. Cliquer sur "Gérer mon profil"');
            $rep->tplname='mascarine~add_obs';
            return $rep;
        }
        
        // Get form
        $form = jForms::get('mascarine~add_obs');
        if ( $form === null )
            $form = jForms::create('mascarine~add_obs');
        $form->setData( 'code_commune', $this->param('code_commune') );
        $form->setData( 'code_maille', $this->param('code_maille') );
        $form->setData( 'geo_wkt', $this->param('geo_wkt') );
        
        $rep = $this->getResponse('redirect');
        $rep->action = "mascarine~edit:returnAddObservation";
        return $rep;
    }
    
    function returnAddObservation() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~add_obs';
        
        $form = jForms::get('mascarine~add_obs');
        if ( $form === null ) {
            jMessage::add( 'Utiliser l\'interface pour accéder au formulaire', 'error');
            return $rep;
        }
        
        if ( $form->getData( 'code_commune') === null || $form->getData( 'code_maille' ) === null ) {
            jMessage::add( 'Le formulaire est incomplet', 'error');
            jMessage::add( 'Utiliser l\'interface pour accéder au formulaire', 'error');
            return $rep;
        }
        
        $rep->tpl->assign('form', $form);
        return $rep;
    }
    
    function submitAddObservation() {
    }
    
}
