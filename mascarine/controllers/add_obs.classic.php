<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class add_obsCtrl extends jController {

    function index() {
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
        $rep->action = "mascarine~add_obs:view";
        return $rep;
    }

    function view() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~add_obs';

        $dao = jDao::get('mascarine~personne');
        $user = jAuth::getUserSession();
        $perso = $dao->getByUserLogin( $user->login );
        if ( !$perso ) {
            jMessage::add( 'Aucun perso associé à votre profil. Cliquer sur "Gérer mon profil"');
            return $rep;
        }

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

    function submit() {
        $rep = $this->getResponse('redirect');
        $rep->action = "mascarine~add_obs:view";

        $dao = jDao::get('mascarine~personne');
        $user = jAuth::getUserSession();
        $perso = $dao->getByUserLogin( $user->login );
        if ( !$perso ) {
            return $rep;
        }

        $form = jForms::get('mascarine~add_obs');
        if ( $form === null ) {
            return $rep;
        }
        $form->initFromRequest();
        if ( !$form->check() ) {
            return $rep;
        }

        if ( $form->getData( 'code_commune') == '' || $form->getData( 'code_maille' ) == '' ) {
            return $rep;
        }

        if ( $form->getData('geo_wkt') == '' ) {
            jMessage::add( 'Le formulaire est incomplet', 'error');
            jMessage::add( 'Utiliser l\'interface pour accéder au formulaire', 'error');
            return $rep;
        }

        $id_obs = $form->saveToDao('mascarine~obs');

        $form->addControl( new jFormsControlHidden('id_obs') );
        $form->setData( 'id_obs', $id_obs );
        $form->saveToDao('mascarine~loc_obs');

        // Get SRID
        $localConfig = jApp::configPath('localconfig.ini.php');
        $ini = new jIniFileModifier($localConfig);
        $srid = $ini->getValue('srid', 'naturaliz');

        $dao = jDao::get('mascarine~loc_obs');
        $dao->updateGeomFromText( $id_obs, $form->getData('geo_wkt'), 4326, $srid );

        $dao = jDao::get('mascarine~perso_obs');
        if ( $form->getData('first_obs') == '1' ) {
            $rec = jDao::createRecord('mascarine~perso_obs');
            $rec->id_obs = $id_obs;
            $rec->id_perso = $perso->id_perso;
            $rec->role_perso_obs = 'P';
            $dao->insert( $rec );
        } else {
            $rec1 = jDao::createRecord('mascarine~perso_obs');
            $rec1->id_obs = $id_obs;
            $rec1->id_perso = $perso->id_perso;
            $rec1->role_perso_obs = $form->getData('perso_obs');
            $dao->insert( $rec1 );
            $rec2 = jDao::createRecord('mascarine~perso_obs');
            $rec2->id_obs = $id_obs;
            $rec2->id_perso = $form->getData('id_perso');
            $rec2->role_perso_obs = 'P';
            $dao->insert( $rec2 );
        }
        jForms::destroy('mascarine~add_obs');
        jMessage::add( 'Observation créée');

        $rep->action = "mascarine~edit_obs:index";
        $rep->params = array('id_obs'=>$id_obs);
        return $rep;
    }

}
