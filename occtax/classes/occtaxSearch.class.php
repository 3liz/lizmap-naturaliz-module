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

    private $params = array();

    private $recordsTotal = Null;

    protected $returnFields = array();

    protected $tplFields = array();

    protected $row_id = Null;

    protected $row_label = Null;

    protected $displayFields = array();

    protected $sql = '';

    private $selectClause = '';

    private $fromClause = '';

    private $whereClause = '';

    private $groupByFields = array();

    private $groupClause = '';

    protected $querySelectors = array();

    protected $queryFilters = array();

    protected $srid = '4326';

    public function __construct ($token=Null, $params=Null) {

        // Get SRID
        $localConfig = jApp::configPath('localconfig.ini.php');
        $ini = new jIniFileModifier($localConfig);
        $srid = $ini->getValue('srid', 'naturaliz');
        if( $srid )
            $this->srid = $srid;

        // Get parameters from cache if no parameters given
        $cache = jCache::get('occtaxSearch' . $token);
        if($cache){
jLog::log( 'cache hit = ' . $token );
            $this->params = $cache['params'];
            $this->recordsTotal = $cache['recordsTotal'];
            $this->token = $token;
        }else{
jLog::log( 'no cache hit');
            $this->token = time().session_id();
            $this->params = $params;
        }

        if(empty($this->params))
            return false;

        // Build SQL query
        $this->setSql();

jLog::log( $this->sql);

        // Get the number of total records
        if( !$this->recordsTotal and $this->token )
            $this->setRecordsTotal();

        // Store to cache
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
     * Get search description
    */
    public function getSearchDescription(){
        $tpl = new jTpl();
        $filters = array();
        $qf = $this->queryFilters;
        foreach( $this->params as $k=>$v ){
            if( array_key_exists( $k, $qf ) and $v and $qf[$k]['type'] != 'geom' ){
                $filters[$k] = $this->getValueLabel($k, $v);
            }
        }
        $tpl->assign('filters', $filters);
        $tpl->assign('nb', $this->recordsTotal );
        $s = '';
        if( $this->recordsTotal > 1 )
            $s = 's';
        $tpl->assign('s', $s  );
        $description = $tpl->fetch('occtax~searchDescription');
        return $description;
    }

    private function getValueLabel( $k, $v ){
        $qf = $this->queryFilters;

        // Return value if no correspondance needed
        if( !array_key_exists( 'label', $qf[$k] ) )
            return $v;

        $qfl = $qf[$k]['label'];
        $dao = jDao::get( $qfl['dao']);
        $method = $qfl['method'];
        $label = '';

        if( is_array($v) ){
            $sep = '';
            foreach( $v as $i ){
                $item = $dao->$method($i);
                if( $item ){
                    $label.= $sep . $item->$qfl['column'];
                    $sep = ', ';
                }else{
                    $label.= $v;
                }
            }
        }else{
            $item = $dao->$method($v);
            if($item)
                $label = $item->$qfl['column'];
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
            $fields = $tdata['returnFields'];

            // Check if "group by" needed and add fields to groupByFields
            $multi = array_key_exists( 'multi', $tdata );

            // Get table alias
            $alias = $tdata['alias'];

            // Add fields to select and optionnally groupByFields
            foreach( $fields as $field => $type ){
                // Build select clause for this table
                $sql.= $c . $field;
                $c = ",
                ";
                $a = $alias . '.';
                if( $type == 'source_objet' )
                    $a = '';
                // Add fields to groupByField array
                if( !$multi ){
                    if( !is_array( $type ) ){
                        $gField = $a . $type;
                        $groupByFields[] = $gField;
                    }else{
                        foreach( $type as $ty ){
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


    private function myquote($term){
        $cnx = jDb::getConnection();
        return $cnx->quote($term);
    }

    protected function setWhereClause(){
        $sql = " WHERE 2>1 ";

        if( $this->params ){
            $qf = $this->queryFilters;
            foreach( $this->params as $k=>$v ){
                if( array_key_exists( $k, $qf ) and array_key_exists( 'table', $qf[$k] ) and $v ){
                    $q = $qf[$k];

                    // IF filter by uploaded geojson
                    if( $q['type'] == 'geom' ){
                        $geoFilter = ' , ( SELECT ';
                        $geoFilter.= ' ST_Transform( ST_GeomFromText(' . $cnx->quote($v) . ', 4326), '. $this->srid .') AS fgeom';
                        $geoFilter.= ' ) AS fg
';
                        $this->fromClause.= $geoFilter;
                    }


                    if( is_array( $v ) ){
                        if( in_array( $q['type'], array( 'string', 'timestamp', 'geom' ) ) )
                            $v = array_map( 'myquote', $v );
                        $v = implode( ', ', $v );
                    }
                    else{
                        $cnx = jDb::getConnection();
                        if( in_array( $q['type'], array( 'string', 'timestamp', 'geom' ) ) )
                            $v = $cnx->quote( $v );
                        if( $q['type'] == 'partial' )
                            $v = $cnx->quote( '%' . $v .    '%' );
                    }
                    $sql.= ' ' . str_replace('@', $v, $q['clause']);
                    $sql.= '
';
                }
            }
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
                // else if the key corresponds to a template field
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
        $cache = array(
            'params' => $this->params,
            'recordsTotal' => $this->recordsTotal
        );

        jCache::set('occtaxSearch' . $this->token, $cache, 0);

    }


}

