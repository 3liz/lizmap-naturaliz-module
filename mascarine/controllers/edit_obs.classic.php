<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class edit_obsCtrl extends jController {

    private $ini = null;

    private $types = array();

    private $forms = array(
            "general_obs",
            "personne_obs",
            "localisation_obs",
            "flore_obs",
            "detail_flore_obs",
            "pheno_flore_obs",
            "pop_flore_obs",
            "station_obs",
            "habitat_obs",
            "menace_obs",
            "document_obs"
        );

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

    private function checkForm( $form, $type, $id_obs ) {
        $key = explode( '~', $form->getSelector() );
        if ( count($key) != 2 )
            return form;

        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );

        $k = $key[1];
        $this->prepareForm( $form, $obs->type_obs );
        if ( in_array( $k, array('general_obs', 'localisation_obs', 'station_obs') ) ) {
          return $form->check();
        } else if ( $k == 'personne_obs' && $this->ini->getValue( $obs->type_obs, 'form:'.$k ) == 'required' ) {
            $dao = jDao::get('mascarine~perso_obs');
            if ( $dao->countPrimaryByObs( $id_obs ) == 0 ) {
                $form->setErrorOn('id', 'Au moins 1 observateur principal requis');
                return false;
            }
            return true;
        } else if ( $k == 'flore_obs' && $this->ini->getValue( $obs->type_obs, 'form:'.$k ) == 'required' ) {
            $dao = jDao::get('mascarine~flore_obs');
            if ( $dao->countByObs( $id_obs ) == 0 ) {
                $form->setErrorOn('id', 'Au moins 1 élément requis');
                return false;
            }
            foreach ( $dao->findByObs( $id_obs ) as $flore ) {
                $dForm = jForms::create( "mascarine~detail_flore_obs", $flore->id_flore_obs );
                $dForm->initFromDao( "mascarine~flore_obs" );
                if ( !$dForm->check() )
                    $form->setErrorOn('detail_'.$flore->cd_nom, 'Détail '.$flore->nom_complet.' incomplet');
                if ( $this->ini->getValue( $obs->type_obs, 'form:pheno_'.$k ) == 'required' ) {
                    $fDao = jDao::get('mascarine~pheno_flore_obs');
                    if ( $fDao->countByFloreObs( $id_obs, $flore->id_flore_obs ) == 0 )
                        $form->setErrorOn('pheno_'.$flore->cd_nom, 'Phénologie '.$flore->nom_complet.' incomplet');
                }
                if ( $this->ini->getValue( $obs->type_obs, 'form:pop_'.$k ) == 'required' ) {
                    $fDao = jDao::get('mascarine~pop_flore_obs');
                    if ( $fDao->countByFloreObs( $id_obs, $flore->id_flore_obs ) == 0 )
                        $form->setErrorOn('pop_'.$flore->cd_nom, 'Population '.$flore->nom_complet.' incomplet');
                }
            }
            return true;
        } else if ( $k == 'habitat_obs' && $this->ini->getValue( $obs->type_obs, 'form:'.$k ) == 'required' ) {
            $dao = jDao::get('mascarine~habitat_obs');
            if ( $dao->countByObs( $id_obs ) == 0 ) {
                $form->setErrorOn('id', 'Au moins 1 élément requis');
                return false;
            }
            return true;
        } else if ( $k == 'menace_obs' && $this->ini->getValue( $obs->type_obs, 'form:'.$k ) == 'required' ) {
            $dao = jDao::get('mascarine~menace_obs');
            if ( $dao->countByObs( $id_obs ) == 0 ) {
                $form->setErrorOn('id', 'Au moins 1 élément requis');
                return false;
            }
            return true;
        } else if ( $k == 'document_obs' && $this->ini->getValue( $obs->type_obs, 'form:'.$k ) == 'required' ) {
            jClasses::inc('mascarine~documentObservationSearch');
            $documentSearch = new documentObservationSearch( $id_obs, null );
            if ( $documentSearch->getRecordsTotal() == 0 ) {
                $form->setErrorOn('id', 'Au moins 1 élément requis');
                return false;
            }
            return true;
        }
        return true;
    }

    function __construct( $request ) {
        parent::__construct( $request );
        $iniFile = jApp::configPath('mascarine.ini.php');
        $this->ini = new jIniFileModifier($iniFile);

        $dao = jDao::get('mascarine~nomenclature');
        $this->types = $dao->findByField('type_obs');
    }

    function index() {
        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            $rep = $this->getResponse('htmlfragment');
            jMessage::add( 'Aucun identifiant d\'observation');
            $rep->tplname='mascarine~edit_obs';
            return $rep;
        }

        $forms = array(
              'general_obs' => jForms::create("mascarine~general_obs", $id_obs),
              'personne_obs' => jForms::create("mascarine~personne_obs"),
              'localisation_obs' => jForms::create("mascarine~localisation_obs", $id_obs),
              'flore_obs' => jForms::create("mascarine~flore_obs"),
              'station_obs' => jForms::create("mascarine~station_obs", $id_obs),
              'habitat_obs' => jForms::create("mascarine~habitat_obs"),
              'menace_obs' => jForms::create("mascarine~menace_obs"),
              'document_obs' => jForms::create("mascarine~document_obs")
        );
        $rep = $this->getResponse('redirect');
        $rep->action = "mascarine~edit_obs:view";
        $rep->params = array('id_obs'=>$id_obs);
        return $rep;
    }

    function remove() {
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

        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        if ( $obs == null ) {
            $return['msg'][] = 'id_obs invalide';
            $rep->data = $return;
            return $rep;
        }

        if ( $obs->validee_obs ) {
            $return['msg'][] = 'Validated observation cannot be removed!';
            $rep->data = $return;
            return $rep;
        }

        $obsDir = jApp::varPath("documents/".$id_obs);
        if ( is_dir( $obsDir ) )
          jFile::removeDir( $obsDir );

        $dao->delete( $id_obs );

        $return['msg'][] = 'Observation supprimée';
        $return['status'] = 1;
        $rep->data = $return;
        return $rep;
    }

    function view() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~edit_obs';

        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            jMessage::add( 'Aucun identifiant d\'observation');
            return $rep;
        }
        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );

        $forms = array(
              'general_obs' => jForms::get("mascarine~general_obs", $id_obs),
              'personne_obs' => jForms::get("mascarine~personne_obs"),
              'localisation_obs' => jForms::get("mascarine~localisation_obs", $id_obs),
              'flore_obs' => jForms::get("mascarine~flore_obs"),
              'station_obs' => jForms::get("mascarine~station_obs", $id_obs),
              'habitat_obs' => jForms::get("mascarine~habitat_obs"),
              'menace_obs' => jForms::get("mascarine~menace_obs"),
              'document_obs' => jForms::get("mascarine~document_obs")
        );

        foreach( $forms as $k=>$form) {
            if ( $form == null ) {
                jMessage::add( 'Utiliser l\'interface pour accéder au formulaire', 'error');
                return $rep;
            }
            if ( $this->ini->getValue( $obs->type_obs, 'form:'.$k ) == 'deactivate' ) {
                $forms[$k] = null;
                continue;
            }
            if ( $k == 'general_obs' ) {
                $form->initFromDao("mascarine~obs");
                if ( !jAcl2::check( 'observation.valider' ) ) {
                  $form->deactivate('valider_obs', true);
                  $form->deactivate('remarques_control_obs', true);
                }
                $form->getControl('type_obs')->setReadOnly( true );
                $form->check();
            } else if ( $k == 'station_obs' ) {
                $dao = jDao::get("mascarine~station_obs");
                $stat_obs = $dao->get( $id_obs );
                if( $stat_obs ){
                    $form->initFromDao("mascarine~station_obs");
                    $form->check();
                }
            } else if ( $k == 'localisation_obs' ) {
                $form->initFromDao("mascarine~loc_obs");
                $form->getControl('code_commune')->setReadOnly( true );
                $form->getControl('code_maille')->setReadOnly( true );
                $dao = jDao::get("mascarine~loc_obs");
                $loc_obs = $dao->get( $id_obs );
                if ( strtolower( $loc_obs->geom_type ) != 'point' ) {
                    $form->deactivate( 'coord_x' );
                    $form->deactivate( 'coord_y' );
                }
                $form->setData( 'geo_wkt', $dao->getGeomAsText( $id_obs, 4326 ) );
                $form->check();
            } else if ( $k == 'habitat_obs' ) {
                $nDao = jDao::get('occtax~nomenclature');
                $hDao = jDao::get('mascarine~habitat');
                $hResults = $hDao->findAll();
                $ref_habitats = array();
                $habitats = array();

                // Get only habitat defined in localconfig
                $localConfig = jApp::configPath('localconfig.ini.php');
                $localConfig = new jIniFileModifier($localConfig);
                $whiteliststr = $localConfig->getValue('habitats', 'mascarine');
                $whitelist = array_map( 'trim', explode( ',', $whiteliststr ) );
                foreach( $hResults as $h ) {
                    if( !in_array( $h->ref_habitat, $whitelist) )
                        continue;

                    $h->children = array();
                    if( !array_key_exists( $h->ref_habitat, $ref_habitats ) ) {
                        $ref_habitats[ $h->ref_habitat ] = $h;
                    }
                    $habitats[ $h->code_habitat ] = $h;
                    if ( array_key_exists( $h->code_habitat_parent, $habitats ) ) {
                        $hParent = $habitats[ $h->code_habitat_parent ];
                        $hParent->children[] = $h->code_habitat;
                    }
                }
                $rep->tpl->assign( 'ref_habitats', $ref_habitats );
                $rep->tpl->assign( 'habitats', $habitats );
            }
            $this->checkForm( $form, $obs->type_obs, $id_obs );
        }
        $rep->tpl->assign( $forms );
        $rep->tpl->assign( 'id_obs', $id_obs );
        $rep->tpl->assign( 'obs', $obs );
        return $rep;
    }

    function general() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~edit_obs_form';

        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            jMessage::add( 'Aucun identifiant d\'observation');
            return $rep;
        }
        $rep->tpl->assign( 'id_obs', $id_obs );

        $form = jForms::get("mascarine~general_obs", $id_obs);
        if ( $form == null ) {
            jMessage::add( 'Utiliser l\'interface pour accéder au formulaire', 'error');
            return $rep;
        }

        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );

        if ( !jAcl2::check( 'observation.valider' ) ) {
          $form->deactivate('valider_obs', true);
          $form->deactivate('remarques_control_obs', true);
        }

        $form->deactivate('type_obs', true);
        $form->initFromRequest();
        $form->deactivate('type_obs', false);

        if ( jAcl2::check( 'observation.valider' ) && $this->param('validee_obs') ) {
            $rep = $this->getResponse('redirect');
            $rep->action = "mascarine~edit_obs:validate";
            $rep->params = array('id_obs'=>$id_obs);
            return $rep;
        }

        $rep->tpl->assign( 'form', $form );
        $rep->tpl->assign( 'submit', 'mascarine~edit_obs:general' );
        $form->saveToDao("mascarine~obs");
        jMessage::add( 'Modifications enregistrées');
        // check for required
        $form->check();
        return $rep;
    }

    function validate() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~edit_obs_form';
        if ( !jAcl2::check( 'observation.valider' ) ) {
            jMessage::add( 'Opération non autorisée !');
            return $rep;
        }

        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            jMessage::add( 'Aucun identifiant d\'observation');
            return $rep;
        }
        $rep->tpl->assign( 'id_obs', $id_obs );
        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );

        $forms = array(
              'general_obs' => jForms::get("mascarine~general_obs", $id_obs),
              'personne_obs' => jForms::get("mascarine~personne_obs"),
              'localisation_obs' => jForms::get("mascarine~localisation_obs", $id_obs),
              'flore_obs' => jForms::get("mascarine~flore_obs"),
              'station_obs' => jForms::get("mascarine~station_obs", $id_obs),
              'habitat_obs' => jForms::get("mascarine~habitat_obs"),
              'menace_obs' => jForms::get("mascarine~menace_obs"),
              'document_obs' => jForms::get("mascarine~document_obs")
        );
        $forms['general_obs']->saveToDao("mascarine~obs");

        foreach( $forms as $k=>$form) {
            if ( $form == null ) {
                jMessage::add( 'Utiliser l\'interface pour accéder au formulaire', 'error');
                return $rep;
            }
            if ( $this->ini->getValue( $obs->type_obs, 'form:'.$k ) == 'deactivate' ) {
                $forms[$k] = null;
                continue;
            }
            if ( !$this->checkForm( $form, $obs->type_obs, $id_obs ) ) {
                $rep->tpl->assign( 'form', $forms['general_obs'] );
                $rep->tpl->assign( 'submit', 'mascarine~edit_obs:general' );
                jMessage::add( 'Observation non validée !', 'error');
                return $rep;
            }
        }
        $obs->validee_obs = True;
        $dao->update( $obs );
        jMessage::add( 'L\'observation "'.$obs->type_obs.' '.$obs->date_obs.' '.$obs->nature_obs.' '.$obs->forme_obs.'" a été validée !');
        return $rep;
    }

    function addPersonne() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~edit_obs_form';

        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            jMessage::add( 'Aucun identifiant d\'observation');
            return $rep;
        }
        $rep->tpl->assign( 'id_obs', $id_obs );

        $form = jForms::get("mascarine~personne_obs");
        if ( $form == null ) {
            jMessage::add( 'Utiliser l\'interface pour accéder au formulaire', 'error');
            return $rep;
        }

        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );

        $ctrl= new jFormsControlinput('id_obs');
        $form->addControl($ctrl);

        $form->initFromRequest();
        $rep->tpl->assign( 'form', $form );
        $rep->tpl->assign( 'submit', 'mascarine~edit_obs:addPersonne' );

        if ( !$form->check() ) {
            jMessage::add( 'Modifications non enregistrées', 'error');
            return $rep;
        }
        $form->saveToDao( 'mascarine~perso_obs' );
        jForms::destroy("mascarine~personne_obs");
        $form = jForms::create("mascarine~personne_obs");
        $rep->tpl->assign( 'form', $form );
        jMessage::add( 'Modifications enregistrées');
        return $rep;
    }

    function removePersonne() {
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

        $id_perso = $this->param( 'id_perso' );
        if ( $id_perso == null ) {
            $return['msg'][] = 'id_perso mandatory';
            $rep->data = $return;
            return $rep;
        }

        $dao = jDao::get('mascarine~perso_obs');
        $dao->delete( $id_obs, $id_perso );

        $return['msg'][] = 'Perso supprimé de l\'observation';
        $return['status'] = 1;

        if ( $dao->countPrimaryByObs( $id_obs ) == 0 ) {
            $obsDao = jDao::get("mascarine~obs");
            $obs = $obsDao->get( $id_obs );
            if ( $this->ini->getValue( $obs->type_obs, 'form:personne_obs' ) == 'required' )
                $return['check'] = 'Au moins 1 observateur principal requis';
        }
        $rep->data = $return;
        return $rep;
    }

    function localisation() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~edit_obs_form';

        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            jMessage::add( 'Aucun identifiant d\'observation');
            return $rep;
        }
        $rep->tpl->assign( 'id_obs', $id_obs );

        $form = jForms::get("mascarine~localisation_obs", $id_obs);
        if ( $form == null ) {
            jMessage::add( 'Utiliser l\'interface pour accéder au formulaire', 'error');
            return $rep;
        }

        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );

        $form->initFromRequest();
        $rep->tpl->assign( 'form', $form );
        $rep->tpl->assign( 'submit', 'mascarine~edit_obs:localisation' );

        $form->saveToDao("mascarine~loc_obs");
        jMessage::add( 'Modifications enregistrées');
        // check for required
        $form->check();
        return $rep;
    }

    function checkTaxon() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~edit_obs_form';

        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            jMessage::add( 'Aucun identifiant d\'observation');
            return $rep;
        }
        $rep->tpl->assign( 'id_obs', $id_obs );

        $form = jForms::get("mascarine~flore_obs");
        if ( $form == null ) {
            jMessage::add( 'Utiliser l\'interface pour accéder au formulaire', 'error');
            return $rep;
        }
        jForms::destroy("mascarine~flore_obs");

        $form = jForms::create("mascarine~flore_obs");
        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );
        $this->checkForm( $form, $obs->type_obs, $id_obs );

        $rep->tpl->assign( 'form', $form );
        $rep->tpl->assign( 'submit', 'mascarine~edit_obs:addTaxon' );
        return $rep;
    }

    function addTaxon() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~edit_obs_form';

        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            jMessage::add( 'Aucun identifiant d\'observation');
            return $rep;
        }
        $rep->tpl->assign( 'id_obs', $id_obs );

        $form = jForms::get("mascarine~flore_obs");
        if ( $form == null ) {
            jMessage::add( 'Utiliser l\'interface pour accéder au formulaire', 'error');
            return $rep;
        }

        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );

        $ctrl= new jFormsControlinput('id_obs');
        $form->addControl($ctrl);

        $form->initFromRequest();
        $rep->tpl->assign( 'form', $form );
        $rep->tpl->assign( 'submit', 'mascarine~edit_obs:addTaxon' );

        if ( !$form->check() || $form->getData('cd_nom') == 0 ) {
            $form->removeControl('id_obs');
            $this->checkForm( $form, $obs->type_obs, $id_obs );
            jMessage::add( 'Modifications non enregistrées', 'error');
            return $rep;
        }

        $form->saveToDao('mascarine~flore_obs');
        jForms::destroy("mascarine~flore_obs");

        $form = jForms::create("mascarine~flore_obs");
        $this->prepareForm( $form, $obs->type_obs );
        $this->checkForm( $form, $obs->type_obs, $id_obs );
        $rep->tpl->assign( 'form', $form );

        jMessage::add( 'Modifications enregistrées');
        return $rep;
    }

    function removeTaxon() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~edit_obs_form';

        $form = jForms::get("mascarine~flore_obs");

        $id_obs = $this->param( 'id_obs' );
        if ( $id_obs == null ) {
            jMessage::add( 'Aucun identifiant d\'observation', 'error');
            return $rep;
        }

        $rep->tpl->assign( 'id_obs', $id_obs );
        $rep->tpl->assign( 'form', $form );
        $rep->tpl->assign( 'submit', 'mascarine~edit_obs:addTaxon' );

        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );
        $this->checkForm( $form, $obs->type_obs, $id_obs );

        $cd_nom = $this->param( 'cd_nom' );
        if ( $cd_nom == null ) {
            jMessage::add( 'Aucun identifiant de taxon', 'error');
            return $rep;
        }

        $strate_flore = $this->param( 'strate_flore' );
        if ( $strate_flore == null ) {
            jMessage::add( 'Aucun identifiant de strate', 'error');
            $rep->data = $return;
            return $rep;
        }

        $id_flore_obs = $this->param( 'id_flore_obs' );
        if ( $id_flore_obs == null ) {
            jMessage::add( 'Aucun identifiant de taxon d\'observation', 'error');
            $rep->data = $return;
            return $rep;
        }

        // create conditions
        $conditions = jDao::createConditions();
        $conditions->addCondition('id_flore_obs','=',$id_flore_obs);
        $conditions->addCondition('id_obs','=',$id_obs);
        $conditions->addCondition('cd_nom','=',$cd_nom);
        $conditions->addCondition('strate_flore','=',$strate_flore);

        $dao = jDao::get('mascarine~flore_obs');
        $dao->deleteBy($conditions);

        jMessage::add( 'Taxon supprimé de l\'observation');
        jForms::destroy("mascarine~flore_obs");

        $form = jForms::create("mascarine~flore_obs");
        $this->prepareForm( $form, $obs->type_obs );
        $this->checkForm( $form, $obs->type_obs, $id_obs );
        $rep->tpl->assign( 'form', $form );
        return $rep;
    }

    function station() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~edit_obs_form';

        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            jMessage::add( 'Aucun identifiant d\'observation');
            return $rep;
        }
        $rep->tpl->assign( 'id_obs', $id_obs );

        $form = jForms::get("mascarine~station_obs", $id_obs);
        if ( $form == null ) {
            jMessage::add( 'Utiliser l\'interface pour accéder au formulaire', 'error');
            return $rep;
        }

        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );

        $form->initFromRequest();
        $rep->tpl->assign( 'form', $form );
        $rep->tpl->assign( 'submit', 'mascarine~edit_obs:station' );

        $form->saveToDao("mascarine~station_obs");
        jMessage::add( 'Modifications enregistrées');
        // check for required
        $form->check();
        return $rep;
    }

    function addHabitat() {
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

        $ref_habitat = $this->param( 'ref_habitat' );
        if ( $ref_habitat == null ) {
            $return['msg'][] = 'ref_habitat mandatory';
            $rep->data = $return;
            return $rep;
        }

        $code_habitat = $this->param( 'code_habitat' );
        if ( $code_habitat == null ) {
            $return['msg'][] = 'code_habitat mandatory';
            $rep->data = $return;
            return $rep;
        }

        $form = jForms::get("mascarine~habitat_obs");
        if ( $form == null ) {
            $return['msg'][] = 'Utiliser l\'interface pour accéder au formulaire';
            $rep->data = $return;
            return $rep;
        }

        $dao = jDao::get("mascarine~habitat_obs");
        $h = $dao->get($id_obs, $ref_habitat, $code_habitat);
        if( $h != null ) {
            $return['msg'][] = 'Information déjà présente';
            $rep->data = $return;
            return $rep;
        }

        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );

        $ctrl= new jFormsControlinput('id_obs');
        $form->addControl($ctrl);

        $form->initFromRequest();

        if ( !$form->check() ) {
            $return['msg'][] = 'Modifications non enregistrées';
            $rep->data = $return;
            return $rep;
        }
        $form->saveToDao('mascarine~habitat_obs');
        jForms::destroy("mascarine~habitat_obs");
        $form = jForms::create("mascarine~habitat_obs");

        $return['msg'][] = 'Habitat ajouté à l\'observation';
        $return['status'] = 1;

        $rep->data = $return;
        return $rep;
    }

    function removeHabitat() {
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

        $ref_habitat = $this->param( 'ref_habitat' );
        if ( $ref_habitat == null ) {
            $return['msg'][] = 'ref_habitat mandatory';
            $rep->data = $return;
            return $rep;
        }

        $code_habitat = $this->param( 'code_habitat' );
        if ( $code_habitat == null ) {
            $return['msg'][] = 'code_habitat mandatory';
            $rep->data = $return;
            return $rep;
        }

        $dao = jDao::get('mascarine~habitat_obs');
        $conditions = jDao::createConditions();
        $conditions->addCondition('id_obs','=',$id_obs);
        $conditions->addCondition('ref_habitat','=',$ref_habitat);
        $conditions->addCondition('code_habitat','=',$code_habitat);
        $dao->deleteBy($conditions);

        $return['msg'][] = 'Habitat supprimée de l\'observation';
        $return['status'] = 1;
        if ( $dao->countByObs( $id_obs ) == 0 ) {
            $obsDao = jDao::get("mascarine~obs");
            $obs = $obsDao->get( $id_obs );
            if ( $this->ini->getValue( $obs->type_obs, 'form:habitat_obs' ) == 'required' )
                $return['check'] = 'Au moins 1 élément requis';
        }
        $rep->data = $return;
        return $rep;
    }

    function addMenace() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~edit_obs_form';

        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            jMessage::add( 'Aucun identifiant d\'observation');
            return $rep;
        }
        $rep->tpl->assign( 'id_obs', $id_obs );

        $form = jForms::get("mascarine~menace_obs");
        if ( $form == null ) {
            jMessage::add( 'Utiliser l\'interface pour accéder au formulaire', 'error');
            return $rep;
        }

        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );

        $ctrl= new jFormsControlinput('id_obs');
        $form->addControl($ctrl);

        $form->initFromRequest();
        $rep->tpl->assign( 'form', $form );
        $rep->tpl->assign( 'submit', 'mascarine~edit_obs:addMenace' );

        if ( !$form->check() ) {
            jMessage::add( 'Modifications non enregistrées', 'error');
            return $rep;
        }
        $form->saveToDao('mascarine~menace_obs');
        jForms::destroy("mascarine~menace_obs");
        $form = jForms::create("mascarine~menace_obs");
        $rep->tpl->assign( 'form', $form );
        jMessage::add( 'Modifications enregistrées');
        return $rep;
    }

    function removeMenace() {
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

        $id_obs_menace = $this->param( 'id_obs_menace' );
        if ( $id_obs_menace == null ) {
            $return['msg'][] = 'id_obs_menace mandatory';
            $rep->data = $return;
            return $rep;
        }

        $dao = jDao::get('mascarine~menace_obs');
        $conditions = jDao::createConditions();
        $conditions->addCondition('id_obs','=',$id_obs);
        $conditions->addCondition('id_obs_menace','=',$id_obs_menace);
        $dao->deleteBy($conditions);

        $return['msg'][] = 'Menace supprimée de l\'observation';
        $return['status'] = 1;
        if ( $dao->countByObs( $id_obs ) == 0 ) {
            $obsDao = jDao::get("mascarine~obs");
            $obs = $obsDao->get( $id_obs );
            if ( $this->ini->getValue( $obs->type_obs, 'form:menace_obs' ) == 'required' )
                $return['check'] = 'Au moins 1 élément requis';
        }
        $rep->data = $return;
        return $rep;
    }

    function addDocument() {
        $rep = $this->getResponse('htmlfragment');
        $rep->tplname='mascarine~edit_obs_form';

        $id_obs = $this->param( 'id_obs' );
        if ( !$id_obs ) {
            jMessage::add( 'Aucun identifiant d\'observation');
            return $rep;
        }
        $rep->tpl->assign( 'id_obs', $id_obs );

        $form = jForms::get("mascarine~document_obs");
        if ( $form == null ) {
            jMessage::add( 'Utiliser l\'interface pour accéder au formulaire', 'error');
            return $rep;
        }

        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        $this->prepareForm( $form, $obs->type_obs );

        $ctrl= new jFormsControlinput('id_obs');
        $form->addControl($ctrl);

        $form->initFromRequest();
        $rep->tpl->assign( 'form', $form );
        $rep->tpl->assign( 'submit', 'mascarine~edit_obs:addDocument' );

        if ( !$form->check() ) {
            jMessage::add( 'Modifications non enregistrées', 'error');
            return $rep;
        }
        $fileName = filter_var( $form->getData( 'file_document' ), FILTER_SANITIZE_EMAIL );
        $fileType = $form->getData( 'type_document' );

        $obsDir = jApp::varPath("documents/".$id_obs);
        if ( !is_dir( $obsDir ) )
          jFile::createDir( $obsDir );

        $form->saveFile('file_document', $obsDir, $fileType.'_'.$fileName);

        jForms::destroy("mascarine~document_obs");
        $form = jForms::create("mascarine~document_obs");
        $rep->tpl->assign( 'form', $form );
        jMessage::add( 'Document enregistré');
        return $rep;
    }

    function removeDocument() {
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

        unlink( $filePath );

        $return['msg'][] = 'Document supprimé';
        $return['status'] = 1;

        jClasses::inc('mascarine~documentObservationSearch');
        $documentSearch = new documentObservationSearch( $id_obs, null );
        if ( $documentSearch->getRecordsTotal() == 0 ) {
            $obsDao = jDao::get("mascarine~obs");
            $obs = $obsDao->get( $id_obs );
            if ( $this->ini->getValue( $obs->type_obs, 'form:document_obs' ) == 'required' )
                $return['check'] = 'Au moins 1 élément requis';
        }

        $rep->data = $return;
        return $rep;
    }



    function enregistrer(){
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

        $dao = jDao::get("mascarine~obs");
        $obs = $dao->get( $id_obs );
        if ( $obs == null ) {
            $return['msg'][] = 'id_obs invalide';
            $rep->data = $return;
            return $rep;
        }

        if ( $obs->validee_obs ) {
            $return['msg'][] = 'Validated observation cannot be changed!';
            $rep->data = $return;
            return $rep;
        }

        $obs->saved_obs = True;
        try{
            $dao->update($obs);
            $return['msg'][] = 'Observation enregistrée';
            $return['status'] = 1;
        }catch( exception $e ) {
            $return['msg'][] = "Une erreur est survenue pendant l'enregistrement de l'observation";
            $return['status'] = 0;
        }

        $rep->data = $return;
        return $rep;
    }

}
