<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2016 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class wfsCtrl extends jController {

    protected $srid = '4326';
    protected $params = '';
    protected $search = Null;


    function __construct( $request ){

        // Get SRID
        $localConfig = jApp::varConfigPath('naturaliz.ini.php');
        $ini = new Jelix\IniFile\IniModifier($localConfig);
        $srid = $ini->getValue('srid', 'naturaliz');
        $this->srid = $srid;
        parent::__construct( $request );

    }

    function index(){

        if (isset($_SERVER['PHP_AUTH_USER'])) {
          $ok = jAuth::login($_SERVER['PHP_AUTH_USER'], $_SERVER['PHP_AUTH_PW']);
        }

        $rep = $this->getResponse('redirect');

        if(!jAcl2::check("visualisation.donnees.brutes")){
            jMessage::add(jLocale::get('view~default.repository.access.denied'), 'AuthorizationRequired');
            return $this->serviceException();
        }

        // Get parameters
        if(!$this->getServiceParameters())
          return $this->serviceException();

        // Return the appropriate action
        $service = strtoupper($this->iParam('SERVICE'));
        $request = strtoupper($this->iParam('REQUEST'));
        if($request == "GETCAPABILITIES")
          return $this->GetCapabilities();
        elseif ($request == "GETFEATURE")
          return $this->GetFeature();
        elseif ($request == "DESCRIBEFEATURETYPE")
          return $this->DescribeFeatureType();
        else {
            jMessage::add('REQUEST '.$request.' not supported by Lizmap Web Client', 'InvalidRequest');
            return $this->serviceException();
        }
    }


    /**
    * Get a request parameter
    * whatever its case
    * and returns its value.
    * @param $param request parameter.
    * @return String Request parameter value.
    */
    private function iParam($param){

        $pParams = jApp::coord()->request->params;
        foreach($pParams as $k=>$v){
            if(strtolower($k) == strtolower($param)){
                return $v;
            }
        }
        return Null;
    }

    /**
    * Send an OGC service Exception
    * @param $SERVICE the OGC service
    * @return XML OGC Service Exception.
    */
    public function serviceException(){
        $messages = jMessage::getAll();
        if (!$messages) {
            $messages = array();
        }
        $rep = $this->getResponse('xml');
        $rep->contentTpl = 'lizmap~wms_exception';
        $rep->content->assign('messages', $messages);
        jMessage::clearAll();

        foreach( $messages as $code=>$msg ){
            if( $code == 'AuthorizationRequired' )
                $rep->setHttpStatus(401, $code);

        }

        return $rep;
    }

  /**
  * Get parameters and set classes for the project and repository given.
  *
  * @return array List of needed variables : $params, $lizmapProject, $lizmapRepository, $lizmapCache.
  */
  private function getServiceParameters(){

    // Get and normalize the passed parameters
    $pParams = jApp::coord()->request->params;
    try {
        $lizmapProxy = jClasses::getService('lizmap~lizmapProxy');
        $params = $lizmapProxy->normalizeParams($pParams);
    } catch(Exception $e) {
        $params = \Lizmap\Request\Proxy::normalizeParams($pParams);
    }

    // Build search based on parameters
    jClasses::inc('occtax~occtaxExportObservation');

    // URL Decode some Params
    foreach($params as $k=>$v){
      if(in_array($k, array('observateur', 'autocomplete', 'group', 'group1_inpn', 'group2_inpn'))){
        if(is_array($v)){
          $av = array();
          foreach($v as $vv){
            $av[] = urldecode($vv);
          }
          $params[$k] = $av;
        }else{
          $params[$k] = urldecode($v);
        }
      }
    }

    // Get user login
    $login = Null;
    $user = jAuth::getUserSession();
    if ($user) {
        $login = $user->login;
    }

    $occtaxSearch = new occtaxExportObservation( null, $params, null, '4326', $login );
    $this->search = $occtaxSearch;

    // Define class private properties
    $this->params = $params;

    return true;
  }



  /**
  * GetCapabilities
  * @return JSON configuration file for the specified project.
  */
  protected function GetCapabilities(){
        $service = strtolower($this->params['service']);

        $rep = $this->getResponse('binary');
        $rep->mimeType = 'text/xml;charset=UTF-8';

        $tpl = new jTpl();

        $assign = array();
        $assign['title'] = 'Requête sur les observations';
        $assign['abstract'] = preg_replace(
          '#&|linebreak|\*#',
          ' ',
          $this->search->getSearchDescription('text')
        );
        $assign['url'] = urlencode(jUrl::getFull('occtax~wfs:index', $this->params));
        $assign['srs'] = 'EPSG:4326';
        $assign['minx'] = '-180.0';
        $assign['maxx'] = '180.0';
        $assign['miny'] = '-90.0';
        $assign['maxy'] = '90.0';
        $tpl->assign($assign);
        $data = $tpl->fetch('occtax~wfs_getcapabilities');

        $rep->content = $data;
        $rep->doDownload  =  false;
        $rep->outputFileName  =  'naturaliz_'.$service.'_capabilities.xml';

    return $rep;
  }


  /**
  * DescribeFeatureType
  * @return JSON configuration file for the specified project.
  */
  protected function DescribeFeatureType(){
        $service = strtolower($this->params['service']);

        $rep = $this->getResponse('binary');
        $rep->mimeType = 'text/xml;charset=UTF-8';

        $tpl = new jTpl();

        $assign = array();
        $keys = $this->search->getExportedFields( 'principal', 'name' );
        $vals = $this->search->getExportedFields( 'principal', 'type' );
        $assign['attributes'] = array_combine($keys, $vals);

        $typename = 'export_observation_point';
        $typenames = array(
          'export_observation_point' => 'gml:PointPropertyType',
          'export_observation_linestring' => 'gml:LineStringPropertyType',
          'export_observation_polygon' => 'gml:MultiPolygonPropertyType',
          'export_observation_nogeom' => 'String'
        );
        $p_typename = $this->params['typename'];
        if (array_key_exists($p_typename, $typenames)) {
          $typename = $p_typename;
          $geometryType = $typenames[$p_typename];
        }
        $assign['typename'] = $typename;
        $assign['geometryType'] = $typenames[$p_typename];

        $tpl->assign($assign);
        $data = $tpl->fetch('occtax~wfs_describefeaturetype');

        $rep->content = $data;
        $rep->doDownload  =  false;
        $rep->outputFileName  =  'naturaliz_'.$service.'_capabilities.xml';

    return $rep;
  }

  /**
  * GetFeature
  */
  private function GetFeature(){
        $service = strtolower($this->params['service']);

        $rep = $this->getResponse('binary');
        $rep->mimeType = 'text/xml;charset=UTF-8';

        $params = array_merge(
            $this->params,
            array(
                'request'=> 'DescribeFeatureType',
                'outputformat' => 'XMLSCHEMA'
            )
        );

        $describeUrl = urlencode(jUrl::getFull('occtax~wfs:index', $params));

        $typename = 'export_observation_point';
        $typenames = array(
          'export_observation_point' => 'gml:PointPropertyType',
          'export_observation_linestring' => 'gml:LineStringPropertyType',
          'export_observation_polygon' => 'gml:MultiPolygonPropertyType',
          'export_observation_nogeom' => 'String'
        );
        $p_typename = $this->params['typename'];
        if (array_key_exists($p_typename, $typenames)) {
          $typename = $p_typename;
        }

        $path = $this->search->getGML($describeUrl, $typename);

        $rep->fileName = $path;
        $rep->doDownload  =  false;
        $rep->outputFileName  =  'naturaliz_'.$service.'_data.gml';

    return $rep;
  }
}
