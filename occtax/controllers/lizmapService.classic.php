<?php
/**
* Php proxy to access map services
* @package   lizmap
* @subpackage occtax
* @author    3liz
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

include jApp::getModulePath('lizmap').'controllers/service.classic.php';

class lizmapServiceCtrl extends serviceCtrl {

    private $data = array(

        'b' => array(
            'layers' => array(
                'observation_brute_point',
                'observation_brute_linestring',
                'observation_brute_polygon',
                'observation_brute_centroid'
            ),
            'originSql' => array(
                'POINT' => "SELECT * FROM tpl_observation_brute_point",
                'LINESTRING' => "SELECT * FROM tpl_observation_brute_linestring",
                'POLYGON' => "SELECT * FROM tpl_observation_brute_polygon"
            ),
            'attributeTable' => array (
                'source' => 'observation_brute_centroid',
                'columns' => array (
                    "cle_obs" => "Identifiant",
                    "date_debut" => "Date",
                    "nom_cite" => "Nom cité",
                    "cd_nom" => "CD_NOM",
                    "identite_observateur" => "Observateur",
                )

            )
        ),

        'm01' => array(
            'layers' => array(
                'observation_maille'
            ),
            'attributeTable' => array(
                'source' => 'observation_maille',
                'columns' => array (
                    "maille" => "Code maille",
                    "nbobs" => "Nombre d'observations",
                    "nbtax" => "Nombre de taxons",
                )
            )

        ),
        'm02' => array(
            'layers' => array(
                'observation_maille'
            ),
            'attributeTable' => array(
                'source' => 'observation_maille',
                'columns' => array (
                    "maille" => "Code maille",
                    "nbobs" => "Nombre d'observations",
                    "nbtax" => "Nombre de taxons",
                )
            )

        ),
        //'m05' => array(
            //'layers' => array(
                //'observation_maille'
            //),
            //'attributeTable' => array(
                //'source' => 'observation_maille',
                //'columns' => array (
                    //"maille" => "Code maille",
                    //"nbobs" => "Nombre d'observations",
                    //"nbtax" => "Nombre de taxons",
                //)
            //)

        //),
        'm10' => array(
            'layers' => array(
                'observation_maille'
            ),
            'attributeTable' => array(
                'source' => 'observation_maille',
                'columns' => array (
                    "maille" => "Code maille",
                    "nbobs" => "Nombre d'observations",
                    "nbtax" => "Nombre de taxons",
                )
            )

        )

    );


    /**
    * GetPrint
    * @param string $repository Lizmap Repository
    * @param string $project Name of the project : mandatory
    * @return Image rendered by the Map Server.
    */
    function GetPrint(){

    // Get parameters
    if(!$this->getServiceParameters())
        return $this->serviceException();

    $url = $this->services->wmsServerURL.'?';

    $localConfig = jApp::configPath('localconfig.ini.php');
    $ini = new jIniFileModifier($localConfig);

    $mailles_a_utiliser = $ini->getValue('mailles_a_utiliser', 'occtax');
    if( !$mailles_a_utiliser or empty(trim($mailles_a_utiliser)) ){
        $mailles_a_utiliser = 'maille_02,maille_10';
    }
    $mailles_a_utiliser = array_map('trim', explode(',', $mailles_a_utiliser));

    // Create temporary project from template if needed
    // And modify layers datasource via passed token and datatype
    $token = $this->params['token'];
    $datatype = $this->params['datatype']; // m01 = maille 1, m02 = maille 2 , m05 = maille 5, m10 = maille 10, b = données brutes
    $dynamic = Null;
    if( $token and $datatype ) {

        if( !jAcl2::check("visualisation.donnees.brutes") and $datatype == 'b' and in_array('maille_01', $mailles_a_utiliser) )
            $datatype = 'm01';
        if( !jAcl2::check("visualisation.donnees.maille_01") and $datatype == 'm01' and in_array('maille_02', $mailles_a_utiliser))
            $datatype = 'm02';

        // Get source project params
        $project = $this->iParam('project');
        $repository = $this->iParam('repository');
        $lrep = lizmap::getRepository($repository);
        $ser = lizmap::getServices();
        $random = time();

        // Store template project in same directory as original one to keep references to layers and media files
        $tempProjectPath = realpath($lrep->getPath()) . '/' . $project . '_' . $token . '_' . $datatype .'_' . $random . '.qgs';

        // Get source project path and read content
        $projectTemplatePath = realpath($lrep->getPath()) . '/' . $project . ".qgs";
        $projectTemplate = jFile::read($projectTemplatePath);

        // First set the temp content as the source
        $newProjectContent = $projectTemplate;

        // Replace datasource for observation_maille
        if( $datatype == 'm01' or $datatype == 'm02' or $datatype == 'm05' or $datatype == 'm10'){
            if( $datatype == 'm10' ){
                jClasses::inc('occtax~occtaxSearchObservationMaille10');
                $occtaxSearch = new occtaxSearchObservationMaille10( $token, null );
            }
            //elseif( $datatype == 'm05' ){
                //jClasses::inc('occtax~occtaxSearchObservationMaille05');
                //$occtaxSearch = new occtaxSearchObservationMaille05( $token, null );
            //}
            elseif( $datatype == 'm02' ){
                jClasses::inc('occtax~occtaxSearchObservationMaille02');
                $occtaxSearch = new occtaxSearchObservationMaille02( $token, null );
            }
            else{
                jClasses::inc('occtax~occtaxSearchObservationMaille');
                $occtaxSearch = new occtaxSearchObservationMaille( $token, null );
            }

            $target = $occtaxSearch->getSql();

            $target = str_replace(
                'FROM (',
                ', ST_Centroid(m.geom) AS geom FROM (',
                $target
            );

            // Dans QGIS 2.18, il ne faut pas remplacer de la même manière
            // ce qui est dans <maplayer et ce qui est dans <layer-tree-layer
            // on choisit de ne remplacer que le <maplauyer
            // on n'utilise pas htmlentities car on veut échapper les " et pas les remplacer par code html
            // On utilise le préfixe pour cela
            $target = str_replace( '<', '&lt;', $target );
            $target = str_replace( '"', '\"', $target );
            $pref = 'table="(';
            $source =  'SELECT * FROM tpl_observation_maille';
            $newProjectContent = str_replace(
                $pref . $source,
                $pref . $target,
                $newProjectContent
            );

            // Replace attribute table source
            // todo
            $newProjectContent = str_replace(
                'vectorLayer="observation_brute_centroid"',
                'vectorLayer="observation_maille"',
                $newProjectContent
            );

            // Replace width of square under maille for maille 10
            if( $datatype == 'm10' or $datatype == 'm02' or $datatype == 'm01'){
                $mint = (int)preg_replace('#m0?#', '', $datatype);
                $newProjectContent = str_replace(
                    '<prop k="size_dd_expression" v="2000"/>',
                    '<prop k="size_dd_expression" v="'.$mint.'000"/>',
                    $newProjectContent
                );
            }



        }

        // Données brutes
        if( $datatype == 'b'){
             // Limit and offset
            $lo = '';
            $limit = (integer)$this->iParam('limit');
            $offset = (integer)$this->iParam('offset');
            if( !$limit or $limit <=0)
                $limit = 50;
            $lo.= " LIMIT " . $limit;
            if( $offset > 0 )
                $lo.= " OFFSET " . $offset;

            // Get target SQL
            jClasses::inc('occtax~occtaxSearchObservation');
            $occtaxSearch = new occtaxSearchObservation( $token, null );
            $target = $occtaxSearch->getSql();
            $target.= $lo;
            $target = str_replace( '<', '&lt;', $target );
            $target = str_replace( '"', '\"', $target );

            // Replace source SQL by target depending on geometry type
            foreach( $this->data[$datatype]['originSql'] as $geomtype=>$source ){
                $targetFinal = str_replace(
                    'WHERE 2>1',
                    "WHERE 2>1 AND GeometryType( g.geom ) IN ('" . $geomtype . "', 'MULTI" . $geomtype . "')",
                    $target
                );
                $pref = 'table="( ';
                $newProjectContent = str_replace(
                    $pref.$source,
                    $pref.$targetFinal,
                    $newProjectContent
                );
            }

            // Replace observation_brute_centroid (used for attribute table)
            // So that we have a layer containing all data for all geometry types
            // This layer will be used for the attribute table
            $targetFinal = str_replace(
                'g.geom FROM',
                'ST_Centroid(g.geom) AS geom FROM',
                $target
            );
            $source = "SELECT * FROM tpl_observation_brute_centroid";
            $pref = 'table="( ';
            $newProjectContent = str_replace(
                $pref.$source,
                $pref.$targetFinal,
                $newProjectContent
            );
        }

        // Set attribute table with correct source and columns
        $displayColumns = '<displayColumns>';
        $tplText = '
          <column width="0" attribute="{$attribute}" sortByRank="0" hAlignment="1" heading="{$heading}" sortOrder="0">
            <backgroundColor alpha="0" red="0" blue="0" green="0"/>
          </column>
        ';
        foreach( $this->data[$datatype]['attributeTable']['columns'] as $attribute=>$heading ) {
            $tpl = new jTpl();
            $assign = array (
                'attribute' => $attribute,
                'heading' => $heading
            );
            $tpl->assign( $assign );
            $displayColumns.= $tpl->fetchFromString( $tplText, 'text' );
        }
        $displayColumns.= '</displayColumns>';
        $newProjectContent = preg_replace(
            "#<displayColumns>.*</displayColumns>#s",
            $displayColumns,
            $newProjectContent
        );
        if( $datatype == 'm02' or $datatype == 'm10' ) {
            $newProjectContent = str_replace(
                'vectorLayer="observation_brute_centroid"',
                'vectorLayer="observation_maille"',
                $newProjectContent
            );
        }

        // Get search description via token
        $descriptionFormat = 'html';
        $descriptionDrawLegend = true;
        if( $datatype == 'b' ) {
            $descriptionDrawLegend = false;
        }
        $getSearchDescription = '';
        $getSearchDescription.= '
        <style>
            div{
                font-family: Serif;
                font-size: 0.6em !important;
            }
            table, td {
                font-family: Serif;
                font-size:0.9em !important;
            }
        </style>
        ';
        $getSearchDescription.= '<div>' . $occtaxSearch->getSearchDescription($descriptionFormat, $descriptionDrawLegend) . '</div>';
        $getSearchDescription = htmlspecialchars( $getSearchDescription );
        $newProjectContent = str_replace(
            'Pas de filtres actifs',
            $getSearchDescription,
            $newProjectContent
        );

        // Replace layernames to avoid QGIS Server layer cache
        $t = time();
        $displayLayers = array();
        foreach( $this->data[$datatype]['layers'] as $l ) {
            $newProjectContent = preg_replace(
                '/' . $l . '/i',
                $l . '_' . $t,
                $newProjectContent
            );
            $displayLayers[] = $l . '_' . $t;
        }

        // Write the new project in the cache directory
        jFile::write($tempProjectPath, $newProjectContent);

        // Replace map parameter by the newly created one
        $mapParam = $tempProjectPath;
        $this->params['map'] = $mapParam;

        // QGIS 2.18 expects layers in reversed order compared to 2.14
        // Do it only for added layers (it's already take into account in last point releases of Lizmap)
        $lizservices = lizmap::getServices();
        $qgisServerVersion = (integer)str_replace('.', '', $lizservices->qgisServerVersion);
        if( $qgisServerVersion >= 218 ){
            $displayLayers = array_reverse($displayLayers );
            $this->params['layers'] = $this->params['layers'] . "," . implode( ',', $displayLayers );
            $this->params['map0:layers'] = $this->params['map0:layers'] . "," . implode( ',', $displayLayers );
        }
        else{
            $this->params['layers'] = implode( ',', $displayLayers ) . "," . $this->params['layers'];
            $this->params['map0:layers'] = implode( ',', $displayLayers ) . "," . $this->params['map0:layers'];
        }

        $dynamic = $tempProjectPath;

    }

    // Filter the parameters of the request
    // for querying GetPrint
    $data = array();
    $paramsBlacklist = array('module', 'action', 'C', 'repository','project');
    foreach($this->params as $key=>$val){
        if(!in_array($key, $paramsBlacklist)){
            $data[] = strtolower($key).'='.urlencode($val);
        }
    }
    $querystring = $url . implode('&', $data);

    // Get data form server
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_HEADER, 0);
    curl_setopt($ch, CURLOPT_URL, $querystring);
    curl_setopt( $ch, CURLOPT_SSL_VERIFYPEER, false );
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    $data = curl_exec($ch);
    $info = curl_getinfo($ch);
    $mime = $info['content_type'];
    curl_close($ch);

    // Delete temp file
    unlink($tempProjectPath);

    $rep = $this->getResponse('binary');
    $rep->mimeType = $mime;
    $rep->content = $data;
    $rep->doDownload  =  false;

    $appName = $ini->getValue('projectName', 'occtax');
    $rep->outputFileName  =  $appName . ' - impression des résultats' . '.' . $this->params['format'];

    // Log
    $logContent ='
     <a href="'.jUrl::get('lizmap~service:index',jApp::coord()->request->params).'" target="_blank">'.$this->params['template'].'<a>
     ';
    $eventParams = array(
        'key' => 'print',
        'content' => $logContent,
        'repository' => $this->repository->getKey(),
        'project' => $this->project->getKey()
    );
    jEvent::notify('LizLogItem', $eventParams);

    return $rep;
    }

}

