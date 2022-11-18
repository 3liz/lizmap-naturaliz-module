<?php
/**
* @package   lizmap
* @subpackage occtax
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

        $monfichier = jApp::configPath('naturaliz.ini.php');
        $ini = new jIniFileModifier($monfichier);

        $defaultRep = $ini->getValue('defaultRepository', 'naturaliz');
        $defaultProject = $ini->getValue('defaultProject', 'naturaliz');

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
            jMessage::add( 'Configuration de Occtax incomplète', 'error' );
            return $rep;
        }

        $rep = parent::index();

        if ( $rep instanceof jResponseHtml ) {
            $rep->body->assign( 'auth_url_return', jUrl::get('occtax~default:index') );

            // For occtax we need to add all JQuery
            // In Lizmap it is done only if the use has edition capabilities
            $confUrlEngine = &jApp::config()->urlengine;
            $basePath = $confUrlEngine['basePath'];
            $lang = jLocale::getCurrentLang();
            $www = $confUrlEngine['jelixWWWPath'];

            $rep->addJSLink($www.'jquery/include/jquery.include.js');
            $rep->addJSLink($www.'js/jforms_jquery.js');

            // Add datepickers jForms js
            $confDate = &jApp::config()->datepickers;
            $rep->addJSLink($confDate['default']);
            if (isset($confDate['default.js'])) {
                $js = $confDate['default.js'];
                foreach ($js as $file) {
                    $file = str_replace('$lang', $lang, $file);
                    if (strpos($file, 'jquery.ui.datepicker-en.js') !== false) {
                        continue;
                    }
                    $rep->addJSLink($file);
                }
            }

            // Add other jForms js
            $rep->addJSLink($basePath.'assets/js/ckeditor5/ckeditor.js');
            $rep->addJSLink($basePath.'assets/js/ckeditor5/ckeditor_lizmap.js');
            $rep->addJSLink($basePath.'assets/js/fileUpload/jquery.fileupload.js');
            $rep->addJsLink($basePath.'assets/js/fileUpload/jquery.iframe-transport.js');

            $rep->addJSLink($basePath.'assets/js/bootstrapErrorDecoratorHtml.js');

            // Get local configuration (application name, projects name, etc.)
            $localConfig = jApp::configPath('naturaliz.ini.php');
            $ini = new jIniFileModifier($localConfig);

            $rep->body->assign( 'WMSServiceTitle', $ini->getValue('projectName', 'naturaliz') );
            $rep->title = $ini->getValue('projectName', 'naturaliz');
            $rep->body->assign( 'repositoryLabel', $ini->getValue('appName', 'naturaliz') );


            // sumoselect
            $rep->addJsLink($basePath . 'occtax/js/sumoselect/jquery.sumoselect.min.js');
            $rep->addCSSLink($basePath . 'occtax/css/sumoselect/sumoselect.css');


            // For recent versions of Lizmap Wbe Client, since 3.4.0, we need to add some OpenLayers 2.13.1 JS files
            // Which have been removed from the OL 2 build
            // TODO - For future versions of LWC, we should use OL >= 6
            $xmlPath = jApp::appPath('project.xml');
            $xmlLoad = simplexml_load_file($xmlPath);
            $version = (string) $xmlLoad->info->version;
            $exp_version = explode('.', $version);
            $major = (integer) $exp_version[0];
            $minor = (integer) $exp_version[1];
            if ($major >= 4 || ($major = 3 && $minor >= 4)) {
                $rep->addJsLink($basePath . 'occtax/js/OpenLayers_2_13_1/Strategy.js');
                $rep->addJsLink($basePath . 'occtax/js/OpenLayers_2_13_1/Strategy/Cluster.js');

            }

            // occtax
            $rep->addJsLink($basePath . 'occtax/js/occtax.js');
            $rep->addJsLink($basePath . 'occtax/js/occtax.search.js');

            // Add nomenclature
            $nomenclature = array();
            $daot = jDao::get('taxon~t_nomenclature', 'naturaliz_virtual_profile');
            foreach($daot->findAll() as $nom){
                $nomenclature[$nom->champ . '|' . $nom->code] = $nom->valeur;
            }
            $rep->addJSCode("var t_nomenclature = " . json_encode($nomenclature) . ';');
            // Occtax nomenclature
            $nomenclature = array();
            $sqlnom = "SELECT * FROM occtax.nomenclature";
            $cnx = jDb::getConnection('naturaliz_virtual_profile');
            $reqnom = $cnx->query($sqlnom);
            foreach($reqnom as $nom){
                $nomenclature[$nom->champ . '|' . $nom->code] = $nom->valeur;
            }
            $rep->addJSCode("var occtax_nomenclature = " . json_encode($nomenclature) . ';');

            // Add locales
            $locales = $this->getLocales();
            $rep->addJSCode("var naturalizLocales = " . json_encode($locales) . ';');

            // Add validation API URL
            $validationProperties = array(
                'url' => jUrl::getFull('occtax~validation:index')
            );
            $rep->addJSCode("var naturalizValidationProperties = " . json_encode($validationProperties) . ';');

            $rep->addHeadContent( '<style>' . $ini->getValue('projectCss', 'naturaliz') . '</style>');
        }

        return $rep;
    }

    private function getLocales ($lang=Null) {

        if (!$lang) {
            $lang = jLocale::getCurrentLang().'_'.jLocale::getCurrentCountry();
        }

        $data = array();
        $sources = array(
            'occtax'=> array(
                'search',
                'validation',
            ),
        );

        foreach ($sources as $module=>$files) {
            foreach ($files as $lang_file) {
                $path = jApp::getModulePath($module).'locales/'.$lang.'/'.$lang_file.'.UTF-8.properties';
                if (file_exists($path)) {
                    $lines = file($path);
                    foreach ($lines as $lineNumber => $lineContent) {
                        if (!empty($lineContent) and $lineContent != '\n') {
                            $exp = explode('=', trim($lineContent));
                            if (!empty($exp[0])) {
                                $data[$exp[0]] = jLocale::get($module.'~'.$lang_file.'.'.$exp[0], null, $lang);
                            }
                        }
                    }
                }
            }
        }
        return $data;
    }
}
