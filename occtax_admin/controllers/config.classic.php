<?php
/**
* Mascarine administration
* @package   lizmap
* @subpackage admin
* @author    3liz
* @copyright 2012 3liz
* @link      http://3liz.com
* @license Mozilla Public License : http://www.mozilla.org/MPL/
*/

class configCtrl extends jController {

    // Configure access via jacl2 rights management
    public $pluginParams = array(
        '*' => array( 'jacl2.right'=>'occtax.admin.config.gerer'),
        'modify' => array( 'jacl2.right'=>'lizmap.admin.services.update'),
        'edit' => array( 'jacl2.right'=>'lizmap.admin.services.update'),
        'save' => array( 'jacl2.right'=>'lizmap.admin.services.update'),
        'validate' => array( 'jacl2.right'=>'lizmap.admin.services.update')

    );

    private $ini = null;

    function __construct( $request ) {
        parent::__construct( $request );
        $monfichier = jApp::varConfigPath('naturaliz.ini.php');
        $this->ini = new \Jelix\IniFile\IniModifier ($monfichier);
    }

    /**
     * Display a summary of the information taken from the ~ configuration file.
     *
     * @return Administration backend for the repositories.
     */
    function index() {
        $rep = $this->getResponse('html');

        // Create the form
        $form = jForms::create('occtax_admin~config');

        // Set form data values
        foreach ( $form->getControls() as $ctrl ) {
            if ( $ctrl->type != 'submit' ){
                $val = $this->ini->getValue( $ctrl->ref, 'naturaliz' );
                if( $ctrl->ref == 'projectDescription' or $ctrl->ref == 'projectCss' )
                    $val =  html_entity_decode( $val );
                $form->setData( $ctrl->ref, $val );
            }
        }

        // Get the module version from the XML file
        $xmlFile = jApp::getModulePath('occtax').'module.xml';
        $xmlLoad = simplexml_load_file($xmlFile);
        $version = (string) $xmlLoad->info->version;

        $tpl = new jTpl();
        $tpl->assign( 'form', $form );
        $tpl->assign( 'version', $version );
        $rep->body->assign('MAIN', $tpl->fetch('config_view'));
        $rep->body->assign('selectedMenuItem','occtax_config');

        return $rep;
    }



    /**
     * Modification of the configuration.
     * @return Redirect to the form display action.
     */
    public function modify(){

        // Create the form
        $form = jForms::create('occtax_admin~config');

        // Set form data values
        foreach ( $form->getControls() as $ctrl ) {
            if ( $ctrl->type != 'submit' ){
                $val = $this->ini->getValue( $ctrl->ref, 'naturaliz' );
                if( $ctrl->ref == 'projectDescription' or $ctrl->ref == 'projectCss' )
                    $val =  html_entity_decode( $val );
                $form->setData( $ctrl->ref, $val );
            }
        }

        // redirect to the form display action
        $rep= $this->getResponse("redirect");
        $rep->action="occtax_admin~config:edit";
        return $rep;
    }


    /**
     * Display the form to modify the config.
     * @return Display the form.
     */
    public function edit(){
        $rep = $this->getResponse('html');

        // Get the form
        $form = jForms::get('occtax_admin~config');

        if ( !$form ) {
            // redirect to default page
            jMessage::add('error in edit');
            $rep =  $this->getResponse('redirect');
            $rep->action ='occtax_admin~config:index';
            return $rep;
        }
        // Display form
        $tpl = new jTpl();
        $tpl->assign('form', $form);
        $rep->body->assign('MAIN', $tpl->fetch('occtax_admin~config_edit'));
        $rep->body->assign('selectedMenuItem','occtax_config');
        return $rep;
  }


  /**
  * Save the data for the config.
  * @return Redirect to the index.
  */
  function save(){
    $form = jForms::get('occtax_admin~config');

    // token
    $token = $this->param('__JFORMS_TOKEN__');
    if( !$token ){
      // redirection vers la page d'erreur
      $rep= $this->getResponse("redirect");
      $rep->action="occtax_admin~config:index";
      return $rep;
    }

    // If the form is not defined, redirection
    if( !$form ){
      $rep= $this->getResponse("redirect");
      $rep->action="occtax_admin~config:index";
      return $rep;
    }

    // Set the other form data from the request data
    $form->initFromRequest();

    // Check the form
    if ( !$form->check() ) {
      // Errors : redirection to the display action
      $rep = $this->getResponse('redirect');
      $rep->action='occtax_admin~config:edit';
      $rep->params['errors']= "1";
      return $rep;
    }

    // Save the data
    foreach ( $form->getControls() as $ctrl ) {
        if ( $ctrl->type != 'submit' ){
            $val = $form->getData( $ctrl->ref );
            if( $ctrl->ref == 'projectDescription' or $ctrl->ref == 'projectCss' )
                $val = htmlentities( $val );
            $this->ini->setValue( $ctrl->ref, $val, 'naturaliz' );
        }
    }
    $this->ini->save();

    // Redirect to the validation page
    $rep= $this->getResponse("redirect");
    $rep->action="occtax_admin~config:validate";

    return $rep;
  }


  /**
  * Validate the data for the config : destroy form and redirect.
  * @return Redirect to the index.
  */
  function validate(){

    // Destroy the form
    if($form = jForms::get('occtax_admin~config')){
      jForms::destroy('occtax_admin~config');
    }

    // Redirect to the index
    $rep= $this->getResponse("redirect");
    $rep->action="occtax_admin~config:index";

    return $rep;
  }

}
