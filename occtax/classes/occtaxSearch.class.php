<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class occtaxSearch {

    protected $token = Null;

    protected $params = array();

    protected $taxon_params = array();

    protected $taxon_params_list = array(
        "cd_ref",
        "filter",
        "group",
        "group1_inpn",
        "group2_inpn",
        "habitat",
        "statut",
        "endemicite",
        "invasibilite",
        "menace",
        "protection"
    );

    protected $recordsTotal = Null;

    protected $returnFields = array();

    protected $tplFields = array();

    protected $row_id = Null;

    protected $row_label = Null;

    protected $displayFields = array();

    protected $validite_niveaux_grand_public = '1';

    protected $sql = '';

    private $selectClause = '';

    private $fromClause = '';

    protected $whereClause = '';

    private $groupByFields = array();

    private $groupClause = '';

    protected $querySelectors = array();

    protected $queryFilters = array();

    protected $srid = '4326';

    protected $demande = Null;

    protected $legend_classes = array();

    protected $legend_min_radius = 100;

    protected $legend_max_radius = 410;

    protected $nomenclatureFields = array();

    public function __construct ($token=Null, $params=Null, $demande=Null) {

        // Set demande to avoid inifite loop while fetching sql for demande
        $this->demande = $demande;

        // Get SRID
        $localConfig = jApp::configPath('naturaliz.ini.php');
        $ini = new jIniFileModifier($localConfig);
        $srid = $ini->getValue('srid', 'naturaliz');
        if( $srid )
            $this->srid = $srid;

        // Get parameters from cache if no parameters given
        $cache = $this->getFromCache($token);
        if($cache){
            $this->params = $cache['params'];
            $this->recordsTotal = $cache['recordsTotal'];
            $this->token = $token;
        }else{
            $this->token = time().session_id();
            // Remove useless params
            foreach ($params as $k=>$v) {
                if (is_array($v) and $v == array('')) {
                    $params[$k] = "";
                }
            }
            $this->params = $params;
        }

        if(empty($this->params))
            return false;

        // Niveaux de validité des observations accessibles au grand public
        $vniv = $ini->getValue('validite_niveaux_grand_public', 'naturaliz');
        if( !$vniv )
            $vniv = '1';
        $vniv = implode( ', ', array_map(function($item){return $this->myquote($item);}, explode(',', $vniv)));
        $this->validite_niveaux_grand_public = $vniv;

        // Build SQL query
        $this->setSql();
//jLog::log($this->sql);
        // Get the number of total records
        if( !$this->recordsTotal and $this->token and !$this->demande )
            $this->setRecordsTotal();

        // Store to cache
        if(!$this->demande)
            $this->writeToCache();

    }

    /**
     * Get search id
    */
    public function getToken(){
        return $this->token;
    }

    /**
     * Get search parameters
    */
    public function getParams(){
      return $this->params;
    }


    /**
     * Set legend classes for grid from configuration
    */
    protected function setLegendClasses(){
        // Get min, max, and colors for classes
        $localConfig = jApp::configPath('naturaliz.ini.php');
        $ini = new jIniFileModifier($localConfig);
        $legend_classes = $ini->getValue('legend_class', 'naturaliz');
        if( !$legend_classes or empty($legend_classes) ){
            $legend_classes = array();
            $legend_classes[] = "De 1 à 10 observations; 1; 10; #FFFBC3";
            $legend_classes[] = "De 11 à 100 observations; 11; 100; #FFFF00";
            $legend_classes[] = "De 101 à 500 observations; 101; 500; #FFAD00";
            $legend_classes[] = "Supérieur à 500 observations; 501; 1000000; #FF5500";
        }
        $this->legend_classes = explode('|', $legend_classes);
        $legend_min_radius = $ini->getValue('legend_min_radius', 'naturaliz');
        $legend_max_radius = $ini->getValue('legend_max_radius', 'naturaliz');
        if($legend_min_radius)
            $this->legend_min_radius = $legend_min_radius;
        if($legend_max_radius)
            $this->legend_max_radius = $legend_max_radius;
    }


    /**
     * Get search description
    */
    public function getSearchDescription($format='html', $drawLegend=true){
        $tpl = new jTpl();
        $filters = array();
        $qf = $this->queryFilters;
        foreach( $this->params as $k=>$v ){
            if( array_key_exists( $k, $qf ) and $v and $qf[$k]['type'] != 'geom' ){
                if (is_array($v)) {
                    $labels = array();
                    foreach ($v as $vv) {
                        $labels[] = $this->getValueLabel($k, $vv);
                    }
                    $filters[$k] = implode(', ', $labels);
                } else {
                    $filters[$k] = $this->getValueLabel($k, $v);
                }
            }
            if($k == 'code_maille' and $v){
                $filters[$k] = $this->getValueLabel($k, $v);
            }
            if($k == 'geom' and $v and empty($this->params['code_maille'])){
                $l = preg_replace('#([A-Z]+).+#', '\1', $v);
                $l = preg_replace('#POLYGON|MULTIPOLYGON#','Polygone', $l);
                $filters[$k] = $l;
            }
        }
        $tpl->assign('filters', $filters);
        $tpl->assign('nb', $this->recordsTotal );
        $s = '';
        if( $this->recordsTotal > 1 )
            $s = 's';
        $tpl->assign('s', $s  );

        if($format=='html'){
            $legend_classes = array();
            if($drawLegend)
                $legend_classes = $this->drawLegend();

            $tpl->assign('legend_classes', $legend_classes );
            $description = $tpl->fetch('occtax~searchDescription');
        }
        else{
            $description = $tpl->fetch('occtax~searchDescription_text');
        }
        return $description;
    }

    private function drawLegend(){
        // Add legend classes
        $this->setLegendClasses();
        $legend_classes = array();
        foreach($this->legend_classes as $class){
            $legend_classes[] = array_map( 'trim', explode(';', $class) );
        }
        return $legend_classes;
    }

    public function getReadme($format='html', $type='csv'){
        $readme = jApp::configPath("occtax-export-LISEZ-MOI.$type.txt");
        $content = '';
        if( is_file( $readme ) ){
            // replace line end
            $content = jFile::read( $readme );
            $content = str_replace("\n", "\r\n", $content);
            $content.= "\r\n\r\n";

            // Add search description
            $content.= "Filtres de recherche utilisés :\r\n";
            $getSearchDescription = $this->getSearchDescription($format);
            $getSearchDescription = str_replace('\n', "\r\n", $getSearchDescription);
            $getSearchDescription = str_replace('linebreak', "\r\n", $getSearchDescription);
            $content.= strip_tags( $getSearchDescription );

            // Add jdd list
            $osParams = $this->getParams();
            $dao_jdd = jDao::get('occtax~jdd');
            $content.= "\r\n\r\n";
            $content.= "Jeux de données :\r\n";

            if( array_key_exists( 'jdd_id', $osParams ) and $osParams['jdd_id'] ){
                $jdd_id = $osParams['jdd_id'];
                $jdd = $dao_jdd->get( $jdd_id );
                if( $jdd ){
                    $content.= '  * ' . $jdd->jdd_libelle . ' ( ' . $jdd->jdd_description . " )\r\n";
                }
            }else{
                $jdds = $dao_jdd->getJddList();
                foreach( $jdds as $jdd ){
                    $content.= '  * ' . $jdd->jdd_libelle . ' ( ' . $jdd->jdd_description . " )\r\n";
                }
                $content.= "\r\n\r\n";
                $content.= 'NB: La liste des jeux de données (JDD) ci-dessus montre l\'ensemble des JDD disponibles dans la plate-forme. Elle n\'est pas filtrée en fonction des résultats.';
            }

        }
        return $content;
    }

    private function getValueLabel( $k, $v ){
        $qf = $this->queryFilters;

        // Return value if $k not in queryFilters e.g: mailles
        if( !array_key_exists( $k, $qf ) )
            return $v;

        // Return value if no correspondance needed
        if( !array_key_exists( 'label', $qf[$k] ) ){
            return $v;
        }

        $qfl = $qf[$k]['label'];
        $dao = jDao::get( $qfl['dao']);
        $method = $qfl['method'];
        $champ = null;
        if( array_key_exists( 'champ', $qfl ) ){
            $champ = $qfl['champ'];
        }
        $label = '';
        if( is_array($v) ){
            $sep = '';
            foreach( $v as $i ){
                if(!empty($champ)){
                    $item = $dao->$method($i, $champ);
                }else{
                    $item = $dao->$method($i);
                }
                if( $item ){
                    $col = (string)$qfl['column'];
                    $label.= $sep . $item->$col;
                    $sep = ', ';
                }else{
                    $label.= $v;
                }
            }
        }else{
            if(!empty($champ)){
                $item = $dao->$method($v, $champ);
            }else{
                $item = $dao->$method($v);
            }
            if($item){
                $col = (string)$qfl['column'];
                $label = $item->$col;
            }
            else
                $label = $v;
        }

        return $label;
    }

    /**
     * Get search fields properties
    */
    public function getFields(){
        return array(
            'return' => $this->returnFields,
            'tpl' => $this->tplFields,
            'row_id' => $this->row_id,
            'row_label' => $this->row_label,
            'display' => $this->displayFields
        );
    }

    /**
     * Get the number of records returned
    */
    public function getRecordsTotal(){
        return $this->recordsTotal;
    }

    /**
    * Calculate the total number of records
    * and set the object property
    */
    function setRecordsTotal() {
        if( $this->sql ) {
            $cnx = jDb::getConnection();
            $sql = "SELECT count(*) AS nb FROM (";
            $sql.= $this->sql;
            $sql.= ") AS foo;";
            $result = $cnx->query( $sql );
            foreach( $result->fetchAll() as $line ) {
                $this->recordsTotal = $line->nb;
            }
        }
    }

    protected function setSql() {
        // Build SQL query depending on passed parameters
        $this->selectClause = $this->setSelectClause().'
';
        $this->fromClause = $this->setFromClause().'
';
        $this->whereClause = $this->setWhereClause().'
';
        $this->groupClause = $this->setGroupClause();

        $this->sql = '';
        $this->sql.= $this->selectClause;
        $this->sql.= $this->fromClause;
        $this->sql.= $this->whereClause;
        $this->sql.= $this->groupClause;

//jLog::log($this->sql);
    }


    public function getSql() {
        return $this->sql;
    }


    protected function setSelectClause(){
        $sql = " SELECT ";
        $c = "";
        $groupByFields = array();
        foreach( $this->querySelectors as $table => $tdata ){
            // Add select fields
            if( !array_key_exists('returnFields', $tdata) )
                continue;
            $fields = $tdata['returnFields'];
            if( count($fields) == 0 )
                continue;

            // Check if "group by" needed and add fields to groupByFields
            $multi = array_key_exists( 'multi', $tdata );

            // Get table alias
            $alias = $tdata['alias'];
            // Add fields to select and optionnally groupByFields
            foreach( $fields as $field => $group ){

                // Build select clause for this table
                $sql.= $c . $field;
                $c = ",
                ";
                $a = $alias . '.';
                if( $group == 'source_objet' ) // remove source_objet from SELECT
                    $a = '';

                // Add fields to groupByField array
                if( !$multi and !empty($group)){

                    if( !is_array( $group ) ){
                        $gField = $a . $group;
                        $groupByFields[] = $gField;
                    }else{
                        foreach( $group as $ty ){
                            $gField = $a . $ty;
                            $groupByFields[] = $gField;
                        }
                    }
                }
            }
        }
        if( count( $groupByFields ) > 0 )
            $this->groupByFields = $groupByFields;

        return $sql;
    }

    protected function setFromClause(){
        $sql = " FROM ";
        if( $this->params ){
            $t = array();
            // Add required tables
            $qs = $this->querySelectors;
            foreach( $qs as $table => $d ){
                $required = $d['required'];
                if( $required ){
                    $sql.= ' ' . $d['join'];
                    if( substr(trim($table), 0, 1) == '(' )
                        $sql.= $table;
                    else
                        $sql.= ' "' . $table . '" ';
                    $sql.= ' AS ' . $d['alias'] . ' ';
                    $sql.= $d['joinClause'] . ' ';
                    $sql.= '
';
                    $t[] = $table;
                }
            }

            // Add tables only if needed by where clause
            $qf = $this->queryFilters;
            foreach( $this->params as $k=>$v ){
                if( ( array_key_exists( $k, $qf ) and $v ) ){
                    $q = $qf[$k];
                    if( array_key_exists( 'table', $q)  and !in_array( $q['table'], $t ) ){
                        $d = $this->querySelectors[$q['table']];
                        $sql.= ' ' . $d['join'];
                        $sql.= ' "' . $q['table'] . '" ';
                        $sql.= ' AS ' . $d['alias'] . ' ';
                        $sql.= $d['joinClause'] . ' ';
                    $sql.= '
';                        $t[] = $q['table'];
                    }
                }
            }

        }

        return $sql;
    }


    protected function myquote($term){
        $cnx = jDb::getConnection();
        return $cnx->quote(trim($term));
    }

    public function getWhereClause(){
        return $this->whereClause;
    }

    protected function setWhereClause(){
        $sql = " WHERE True ";
        $cnx = jDb::getConnection();

        if( $this->params ){
            foreach( $this->params as $k=>$v ){
                if( array_key_exists( $k, $this->queryFilters ) and array_key_exists( 'table', $this->queryFilters[$k] ) and $v ){
                    $q = $this->queryFilters[$k];

                    // Geometrie
                    if( $q['type'] == 'geom' ){
                        $wktgeom = $v;
                        if( preg_match('#\%#', $v) ){
                            // On vient du WFS. Il faut decoder
                            $wktgeom = urldecode($v);
                        }
                        $geoFilter= ', (SELECT ST_Transform( ST_GeomFromText(' . $cnx->quote($wktgeom) . ', 4326), '. $this->srid .') AS fgeom';
                        $geoFilter.= ' ) AS fg
';
                        $this->fromClause.= $geoFilter;
                    }

                    // Prise en compte des inputs de type array (ex: cd_nom[])
                    if( is_array( $v ) ){
                        if( in_array( $q['type'], array( 'string', 'timestamp', 'geom' ) ) ){
                            $v = array_map( function($item){return $this->myquote($item);}, $v );
                        }
                        $v = implode( ', ', $v );
                    }

                    // Valeurs simples
                    else{
                        $cnx = jDb::getConnection();
                        // Cas des recherche standard
                        if( in_array( $q['type'], array( 'string', 'timestamp', 'geom' ) ) )
                            $v = $cnx->quote( $v );
                        // Cas des recherches de type LIKE : type partial
                        if( $q['type'] == 'partial' )
                            $v = $cnx->quote( '%' . $v .    '%' );
                    }

                    // Remplacement de @ par la valeur du formulaire
                    $sql.= ' ' . str_replace('@', $v, $q['clause']);
                    $sql.= '
';
                }
            }
        }

        // Add restriction coming from demande table
        if( jAuth::isConnected() and !$this->demande ){
            $filters = jEvent::notify('getOcctaxFilters')->getResponse();
            foreach($filters as $filter){
                $sql.= $filter;
            }
            //jLog::log(json_encode($filters));
        }

        return $sql;
    }

    protected function setGroupClause(){
        $groupClause = '';
        if( count( $this->groupByFields ) > 0 )
            $groupClause = implode( ', ', $this->groupByFields );
        if( $groupClause )
            $groupClause = ' GROUP BY ' . $groupClause;
        return $groupClause;
    }


    protected function setOrderClause( $order ){
        $orderClause = '';
        if( !$order or empty( $order ) )
            return $orderClause;

        $orderCol = $this->returnFields[0]; $orderDir = 'asc';
        $orderExp = explode( ':', $order );
        if(
            count( $orderExp ) == 2
            && preg_match( '#^([a-zA-Z_])+$#', $orderExp[0] )
            && in_array( strtoupper( $orderExp[1] ), array( 'ASC', 'DESC' )   )
        ){
            $orderCol = $orderExp[0];
            if( array_key_exists($orderCol, $this->displayFields) && array_key_exists('sorting_field', $this->displayFields[$orderCol]) ){
                $orderCol = $this->displayFields[$orderCol]['sorting_field'];
            }
            $orderDir = strtoupper( $orderExp[1] );
            $orderClause = " ORDER BY " . $orderCol . " " . $orderDir;
        }
        return $orderClause;
    }

    /**
    * Search result filtered by given parameters
    * @param $offset Offset for the query. Default 0
    * @param $limit Limit for the query. Default 25
    * @return The query result
    */
    protected function getResult( $limit=50, $offset=0, $order="" ) {
        $cnx = jDb::getConnection();
        $orderClause = $this->setOrderClause( $order );
        $sql = $this->sql . " " . $orderClause;
        return $cnx->limitQuery( $sql, $offset, $limit );
    }


    /**
    * Search data filtered by given parameters
    * @param $offset Offset for the query. Default 0
    * @param $limit Limit for the query. Default 25
    * @return List of matching data
    */
    function getData( $limit=50, $offset=0, $order="" ) {
        $result = $this->getResult( $limit, $offset, $order );
        $data = $result->fetchAll();

        $d = array();
        foreach( $data as $line ) {
            $item = array();
            // Get fields from result
            foreach( $this->returnFields as $field ) {
                // If property key is one of the columns returned by the query
                if( property_exists( $line, $field ) ) {
                    $val = $line->$field;
                    if( $field == 'geojson' and is_string($val) ){
                        $val = json_decode( $val );
                    }
                    $item[] = $val;
                    unset($val);
                }
                // if the key corresponds to a template field
                if( array_key_exists( $field, $this->tplFields ) ){
                    $tpl = new jTpl();
                    $tpl->assign('line', $line);
                    $template = $this->tplFields[$field];
                    $val = $tpl->fetchFromString( $template, 'html' );
                    $item[] = $val;
                }

            }
            // Add line
            $d[] = $item;
            unset($item);
        }
        $data = $d;
        return $data;
    }

    /**
    * Store information to cache
    */
    public function writeToCache(){
        $_SESSION['occtaxSearch' . $this->token] = array(
            'token' => $this->token,
            'params' => $this->params,
            'recordsTotal' => $this->recordsTotal
        );
    }

    /**
    * Retrieve information from cache
    */
    public function getFromCache($token){
        if( !empty($token) and isset( $_SESSION['occtaxSearch' . $token] ) ){
            $cache = $_SESSION['occtaxSearch' . $token];
            return $cache;
        }
        return Null;
    }


}

