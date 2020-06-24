<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class exportCtrl extends jController {

    protected $srid = '4326';

    protected $mailles_a_utiliser = 'maille_02,maille_10';

    protected $geometryTypeTranslation = array(
        'point'=>'point', 'linestring'=>'ligne',
        'polygon'=>'polygone', 'nogeom'=> 'sans_geometrie',
        'other'=>'autre'
    );

    function __construct( $request ){

        // Get SRID
        $localConfig = jApp::configPath('naturaliz.ini.php');
        $ini = new jIniFileModifier($localConfig);
        $srid = $ini->getValue('srid', 'naturaliz');
        $this->srid = $srid;

        // Mailles
        $mailles_a_utiliser = $ini->getValue('mailles_a_utiliser', 'naturaliz');
        if( !$mailles_a_utiliser or empty(trim($mailles_a_utiliser)) ){
            $mailles_a_utiliser = 'maille_02,maille_10';
        }
        $this->mailles_a_utiliser = array_map('trim', explode(',', $mailles_a_utiliser));

        parent::__construct( $request );

    }

    function init() {

        $rep = $this->getResponse('json');

        // Get params
        $token = $this->param('token');
        $format = $this->param('format', 'CSV');
        $projection = $this->param('projection', 'locale');

        if( $format != 'CSV' && !jAcl2::check("visualisation.donnees.brutes") ) {
            $return['status'] = 0;
            $return['msg'][] = jLocale::get( 'occtax~search.form.error.right' );
            $rep->data = $return;
            return $rep;
        }

        // Create export token
        $export_token = md5($format . $token . $projection . microtime(true));
        $_SESSION['occtax_export_'.$export_token] = 'wait';

        // Create file path
        $logfile = jApp::tempPath($export_token . '.log');

        // Get user login
        $login = 'null';
        $user = jAuth::getUserSession();
        if ($user) {
            $ulogin = $user->login;
            if (!empty($ulogin)) {
                $login = $ulogin;
            }
        }

        // Get locale
        $locale = jApp::config()->locale;

        // Execute long export task
        $path = jApp::scriptsPath();
        $cmd = ' php ' . $path . 'script.php';
        $cmd.= ' occtax~export:' . strtolower($format);
        $cmd.= ' -login ' . $login;
        $cmd.= ' -locale ' . $locale;
        $cmd.= ' -token ' . $token;
        $cmd.= ' -projection ' . $projection;
        $cmd.= ' -output_directory ' . 'export_observation_' . date("Y-m-d_H-i-s");
//jLog::log($cmd);
        exec($cmd . " > " . $logfile . " &");

        // Redirect to display page
        $rep = $this->getResponse('redirect');
        $rep->action = 'occtax~export:wait';
        $rep->params = $this->params();
        $rep->params['token'] = $export_token;

        return $rep;
    }

    function wait() {

        $rep = $this->getResponse('json');

        // params
        $token = $this->param('token');
        $format = $this->param('format', 'CSV');
        $projection = $this->param('projection', 'locale');

        $rep = $this->getResponse('html');
        $rep->title = 'Export';
        $rep->body->assign('repositoryLabel', 'Export');
        $rep->body->assign('isConnected', jAuth::isConnected());
        $rep->body->assign('user', jAuth::getUserSession());

        // Add JS code to refresh
        $rep->addJSCode("var token = '" . $token . "'; ");
        $checkUrl = jUrl::getFull(
            'occtax~export:check',
            $this->params()
        );
        $rep->addJSCode("var checkUrl = '" . $checkUrl . "'; ");
        $jslink = jUrl::get(
            'jelix~www:getfile',
            array('targetmodule'=>'occtax', 'file'=>'js/occtax.export.js')
        );
        $rep->addJSLink($jslink);

        // Locales
        $locales = $this->getLocales();
        $rep->addJSCode("var naturalizLocales = " . json_encode($locales) . ';');

        $tpl = new jTpl();
        $rep->body->assign('MAIN', '<div id="waitExport" ><p style="background:lightblue; padding:5px">'.jLocale::get( 'occtax~search.export.pending.title'). '</p><p>' . jLocale::get( 'occtax~search.export.pending.description') . '</p></div>');

        return $rep;
    }


    function check() {
        $rep = $this->getResponse('json');

        // params
        $token = $this->param('token');

        // Get log path
        $log = jApp::tempPath($token . '.log');
        $logcontent = jFile::read($log);
        if(!array_key_exists('occtax_export_'.$token, $_SESSION) ){
            $data = array(
                'status'=> 'error',
                'message' => array(
                    'title'=>jLocale::get( 'occtax~search.export.expired.request'),
                    'description'=>''
                )
            );
        }else{
            $ses = $_SESSION['occtax_export_'.$token];
            if(!empty($logcontent)){
                $data = array(
                    'status'=> 'ok',
                    'url'=> jUrl::getFull(
                        'occtax~export:download',
                        $this->params()
                    ),
                    'message' => array(
                        'title'=>jLocale::get( 'occtax~search.export.file.created'),
                        'description'=>jLocale::get( 'occtax~search.export.success.download.file')
                    )
                );
            }else{
                $data = array(
                    'status'=> 'wait',
                    'message' => array(
                        'title'=>jLocale::get( 'occtax~search.export.pending.title'),
                        'description'=>jLocale::get( 'occtax~search.export.pending.description')
                    )
                );
            }
        }
        $rep->data = $data;

        return $rep;
    }


    function download() {
        $rep = $this->getResponse('json');

        // params
        $token = $this->param('token');

        // Check token in session
        if (!array_key_exists('occtax_export_'.$token, $_SESSION)) {
            $data = array(
                'status'=> 'error',
                'message' => array(
                    'title'=>jLocale::get( 'occtax~search.export.expired.request'),
                    'description'=>''
                )
            );
            $rep->data = $data;
            return $rep;
        }

        // Get log path
        $logfile = jApp::tempPath($token . '.log');
        $logcontent = jFile::read($logfile);
        if (!empty($logcontent)) {
            if (preg_match('#^ERROR#', $logcontent)) {
                $message = str_replace('ERROR: ', '', $logcontent);
                $rep->data = array(
                    'status'=>'error',
                    'message' => array(
                        'title'=>$message,
                        'description'=>''
                    )
                );
                return $rep;
            } elseif (preg_match('#^SUCCESS#', $logcontent)) {
                $outputfile = trim(str_replace('SUCCESS: ', '', $logcontent));

                if (file_exists($outputfile)) {
                    $rep = $this->getResponse('binary');
                    $rep->deleteFileAfterSending = true;
                    $rep->fileName = $outputfile;
                    $rep->outputFileName = 'export_observations.zip';
                    $rep->mimeType = 'archive/zip';
                    $rep->doDownload = true;
                    unlink($logfile);
                    clearstatcache();
                    unset($_SESSION['occtax_export_'.$token]);
                    return $rep;
                } else {
                    $rep->data = array(
                        'status'=>'error',
                        'message' => array(
                            'title'=>jLocale::get( 'occtax~search.export.zip.not.found'),
                            'description'=>''
                        )
                    );
                    return $rep;
                }
            } else {
                $rep->data = array(
                    'status'=>'error',
                    'message' => array(
                        'title'=>jLocale::get( 'occtax~search.export.log.wrong.content'),
                        'description'=>''
                    )
                );
                return $rep;
            }

        }else {
            $rep->data = array(
                'status'=>'error',
                'message' => array(
                    'title'=>jLocale::get( 'occtax~search.export.log.empty'),
                    'description'=>''
                )
            );
            return $rep;
        }
    }

    private function getLocales ($lang=Null) {

        if (!$lang) {
            $lang = jLocale::getCurrentLang().'_'.jLocale::getCurrentCountry();
        }

        $data = array();
        $path = jApp::getModulePath('occtax').'locales/'.$lang.'/search.UTF-8.properties';
        if (file_exists($path)) {
            $lines = file($path);
            foreach ($lines as $lineNumber => $lineContent) {
                if (!empty($lineContent) and $lineContent != '\n') {
                    $exp = explode('=', trim($lineContent));
                    if (!empty($exp[0])) {
                        $data[$exp[0]] = jLocale::get('occtax~search.'.$exp[0], null, $lang);
                    }
                }
            }
        }
        return $data;
    }
}

