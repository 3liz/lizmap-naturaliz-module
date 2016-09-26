<?php
/**
* Mascarine administration
* @package   lizmap
* @subpackage mascarine_admin
* @author    3liz
* @copyright 2014 3liz
* @link      http://3liz.com
* @license Mozilla Public License : http://www.mozilla.org/MPL/
*/

class formsCtrl extends jController {

    // Configure access via jacl2 rights management
    public $pluginParams = array(
        '*' => array( 'jacl2.right'=>'mascarine.admin.config.gerer')
    );

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

    function __construct( $request ) {
        parent::__construct( $request );
        $monfichier = jApp::configPath('mascarine.ini.php');
        $this->ini = new jIniFileModifier ($monfichier);

        $dao = jDao::get('mascarine~nomenclature');
        $this->types = $dao->findByField('type_obs');
    }

    function index() {
        $activated_types = array();
        foreach( $this->types as $type ) {
            $val = $this->ini->getValue(
                    $type->code,
                    'activated_types'
                );
            if ( $val === null )
                $val = true;
            $activated_types[$type->code] = $val;
        }

        $forms = array();
        foreach ( $this->forms as $key ) {
            $form = jForms::create( 'mascarine~'.$key );
            $controls = array();
            foreach( $form->getControls() as $ctrl ) {
                if ($ctrl->type == 'submit' || $ctrl->type == 'hidden' || $ctrl->type == 'button')
                  continue;
                $selections = array();
                foreach( $this->types as $type ) {
                    $val = $this->ini->getValue(
                        $type->code.'.'.$ctrl->ref,
                        'form:'.$key
                    );
                    if ( !$val )
                        $val = 'activate';
                    $selections[$type->code] = $val;
                }
                $controls[$ctrl->ref] = $selections;
            }
            $roles = array();
            foreach( $this->types as $type ) {
                $val = $this->ini->getValue(
                        $type->code,
                        'form:'.$key
                    );
                if ( !$val )
                    $val = 'activate';
                $roles[$type->code] = $val;
            }
            $forms[$key] = (object) array(
                'jform'=>$form,
                'roles'=>null,
                'controls'=>null,
                'label'=>jLocale::get("mascarine~observation.form.".$key)
            );
            $forms[$key]->roles = $roles;
            $forms[$key]->controls = $controls;
        }

        $rep = $this->getResponse('redirect');
        $rep->action = "mascarine_admin~forms:index";
        //return $rep;

        $rep = $this->getResponse('html');
        $tpl = new jTpl();

        $tpl->assign( 'forms', $forms );
        $tpl->assign( 'types', $this->types );
        $tpl->assign( 'activated_types', $activated_types );

        $rep->body->assign('MAIN', $tpl->fetch('mascarine_admin~forms'));
        $rep->body->assign('selectedMenuItem','mascarine_forms');
        return $rep;
    }

    function submit() {
        foreach( $this->types as $type ) {
            $this->ini->setValue(
                $type->code,
                $this->param($type->code, 'off' ),
                'activated_types'
            );
        }

        foreach ( $this->forms as $key ) {
            $form = jForms::create( 'mascarine~'.$key );
            foreach( $this->types as $type ) {
                $this->ini->setValue(
                    $type->code,
                    $this->param($key.':'.$type->code, 'activate' ),
                    'form:'.$key
                );
            }
            foreach( $form->getControls() as $ctrl ) {
                if ($ctrl->type == 'submit' || $ctrl->type == 'hidden' || $ctrl->type == 'button')
                  continue;
                foreach( $this->types as $type ) {
                    $this->ini->setValue(
                        $type->code.'.'.$ctrl->ref,
                        $this->param($key.':'.$type->code.':'.$ctrl->ref, 'activate' ),
                        'form:'.$key
                    );
                }
            }
        }
        $this->ini->save();

        $rep = $this->getResponse('redirect');
        $rep->action = "mascarine_admin~forms:index";
        return $rep;
    }

}
