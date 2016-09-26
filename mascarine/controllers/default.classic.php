<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    your name
* @copyright 2011 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

include jApp::getModulePath('view').'controllers/lizMap.classic.php';

class defaultCtrl extends lizMapCtrl {

    // Override this variable to force virtual project to be visible
    protected $forceHiddenProjectVisible = true;

    function __construct ( $request){
        $monfichier = jApp::configPath('localconfig.ini.php');
        $ini = new jIniFileModifier($monfichier);

        $defaultRep = $ini->getValue('defaultRepository', 'mascarine');
        $defaultProject = $ini->getValue('defaultProject', 'mascarine');

        $request->params['repository'] = $defaultRep;
        $request->params['project'] = $defaultProject;

        parent::__construct( $request );
    }

    /**
    *
    */
    function index() {
        // Get repository data
        $repository = $this->param('repository');
        // Get the project
        $project = filter_var($this->param('project'), FILTER_SANITIZE_STRING);
        if ( !$repository || !$project ) {
            $rep = $this->getResponse('redirect');
            $rep->action = 'view~default:index';
            jMessage::add( 'Configuration de Mascarine incomplète', 'error' );
            return $rep;
        }

        $rep = parent::index();
        if ( $rep instanceof jResponseHtml ) {
            $rep->body->assign( 'auth_url_return', jUrl::get('mascarine~default:index') );
            $bp = jApp::config()->urlengine['basePath'];

            // Get local configuration (application name, projects name, etc.)
            $localConfig = jApp::configPath('localconfig.ini.php');
            $ini = new jIniFileModifier($localConfig);

            $rep->body->assign( 'WMSServiceTitle', $ini->getValue('projectName', 'mascarine') );
            $rep->title = $ini->getValue('projectName', 'mascarine');
            $rep->body->assign( 'repositoryLabel', $ini->getValue('appName', 'naturaliz') );

            $rep->addCssLink( $bp.'css/jquery.fileupload.css' );
            $rep->addJsLink( $bp.'js/fileUpload/jquery.iframe-transport.js' );
            $rep->addJsLink( $bp.'js/fileUpload/jquery.fileupload.js' );
            $rep->addJsLink( $bp.'js/mascarine.js' );

            $rep->addHeadContent( '<style>' . $ini->getValue('projectCss', 'mascarine') . '</style>');
        }
        return $rep;
    }
}

