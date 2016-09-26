<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    René-Luc D'Hont
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class unvalidateObservationSearch {

    private $id = Null;

    private $params = array();

    private $imageUrl = '';

    private $dao = Null;

    private $conditions = Null;

    private $recordsTotal = Null;

    protected $returnFields = array(
      'id_obs',
      'type_obs',
      'nature_obs',
      'forme_obs',
      'date_obs',
      'geojson',
      'statut_obs',
      'edit_obs',
      'remove_obs'
    );

    protected $tplFields = array(
        'statut_obs' => '
            {assign $color = "orange"} {assign $val = "E"} {assign $title = "Édition en cours (non validée)"}
            {if $line->saved_obs == "t" }
                {assign $color = "blue"}
                {assign $val = "S"}
                {assign $title = "Observation sauvegardée"}
            {/if}
            {if $line->validee_obs == "t" }
                {assign $color = "green"}
                {assign $val = "V"}
                {assign $title = "Observation validée"}
            {/if}
            <span style="color:white; font-weight:bold; padding:3px; background-color:{$color};" title="{$title}">{$val}</span>
        ',

        'edit_obs' => '<a href="{jurl \'mascarine~edit_obs:index\',array(\'id_obs\'=>$line->id_obs)}" target="_blank" class="editObs"><i class="icon-edit"></i></a>',
        'remove_obs' => '<a href="{jurl \'mascarine~edit_obs:remove\',array(\'id_obs\'=>$line->id_obs)}" target="_blank" class="removeObs"><i class="icon-trash"></i></a>'
    );

    protected $row_id = 'id_obs';

    protected $row_label = Null;

    protected $displayFields = array(
      'type_obs' => array( 'type' => 'string', 'sortable' => "true"),
      'nature_obs' => array( 'type' => 'string', 'sortable' => "true"),
      'forme_obs' => array( 'type' => 'string', 'sortable' => "true"),
      'date_obs' => array( 'type' => 'string', 'sortable' => "true"),
      'statut_obs' => array('type' => 'string', 'sortable' => "0"),
      'edit_obs' => array( 'type' => 'string', 'sortable' => "0"),
      'remove_obs' => array( 'type' => 'string', 'sortable' => "0")
    );

    protected $labelFields = array(
      'nature_obs' => array(
        'dao'=>'mascarine~nomenclature',
        'property'=>'valeur'
      ),
      'forme_obs' => array(
        'dao'=>'mascarine~nomenclature',
        'property'=>'valeur'
      )
    );

    public function __construct ($id, $params=Null) {

        $this->id = $id;
        $this->params = $params;

        // Set dao
        $this->dao = jDao::get( 'mascarine~obs' );

        // Set up conditions
        if( !$this->conditions )
            $this->setConditions();

        // Get the number of total records
        if( !$this->recordsTotal )
            $this->setRecordsTotal();

    }

    /**
     * Get search id
    */
    public function id(){
        return $this->id;
    }

    /**
     * Get search parameters
    */
    public function getParams(){
      return $this->params;
    }

    /**
    * Get search fields properties
    */
    public function getFields(){
        return array(
            'return' => $this->returnFields,
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
    * Set the conditions for the query
    * and set the object property
    */
    function setConditions() {
        if ( !jAcl2::check( 'observation.creer' ) )
          return $this->conditions = Null;

        $conditions = jDao::createConditions();
        $conditions->startGroup('OR');
            $conditions->addCondition( 'validee_obs', '=', False );
            $conditions->addCondition( 'validee_obs','IS', null);
        $conditions->endGroup();
        $user = jAuth::getUserSession();
        if ( jAcl2::check( 'observation.modifier.organisme' )
         && !jAcl2::check( 'observation.modifier.toute' ) ) {
            $conditions->addCondition( 'id_org', '=', 0 );
        } else if ( !jAcl2::check( 'observation.modifier.organisme' ) ) {
            $conditions->addCondition( 'usr_login', '=', $user->login );
        }
        $this->conditions = $conditions;

        // Filter via form params
        if( $this->params ){
            foreach( $this->params as $k=>$v ){
                if( in_array( $k, $this->queryFields ) and $v ) {
                    $this->conditions->addCondition( $k, '=', $v );
                }
            }
        }

        // Order
        $this->conditions->addItemOrder('date_obs','desc');
        $this->conditions->addItemOrder('id_obs','desc');
    }


    /**
    * Calculate the total number of records
    * and set the object property
    */
    function setRecordsTotal() {
        if ( !jAcl2::check( 'observation.creer' ) )
          $this->recordsTotal = 0;
        else if( $this->conditions )
            $this->recordsTotal = $this->dao->countBy( $this->conditions );
    }

    /**
    * Search observation filtered by given parameters
    * @param $offset Offset for the query. Default 0
    * @param $limit Limit for the query. Default 20
    * @return List of matching taxons
    */
    function getData( $limit=20, $offset=0 ) {
        if ( !jAcl2::check( 'observation.creer' ) )
          return array();

        $result = $this->dao->findBy( $this->conditions, $offset, $limit );
        $data = $result->fetchAll();
        $d = array();

        // Get fields from result
        foreach( $data as $line ) {
            $item = array();
            // Get fields from result
            foreach( $this->returnFields as $field ) {
                if( property_exists( $line, $field ) and !array_key_exists($field, $this->tplFields) ) {
                    if ( array_key_exists($field, $this->labelFields) ) {
                        $dao = jDao::get( $this->labelFields[$field]['dao'] );
                        $f = null;
                        if ( $this->labelFields[$field]['dao'] == 'mascarine~nomenclature' )
                          $f = $dao->get( $field, $line->$field );
                        else
                          $f = $dao->get( $line->$field );
                        $prop = $this->labelFields[$field]['property'];
                        if ( $f != null )
                          $item[] = $f->$prop;
                        else
                          $item[] = null;
                    } else if( $field == 'geojson' )
                        $item[] = json_decode( $line->$field );
                    else
                        $item[] = $line->$field;
                }
                // Get template field
                if ( array_key_exists($field, $this->tplFields) ) {
                    $template = $this->tplFields[$field];
                    $tpl = new jTpl();
                    $assign = array();
                    if( $field == 'illustration' ){
                        $illustrationPath = '/css/illustrations/' . $line->cd_nom. '.jpg';
                        $imageUrl = '';
                        if( file_exists( jApp::wwwPath() . $illustrationPath) )
                            $illustration = jApp::wwwPath() . $illustrationPath;
                        else
                            $illustration = '';
                        $assign['illustration'] = $illustration;
                    }

                    $assign['line'] = $line;
                    $tpl->assign( $assign );
                    $val = $tpl->fetchFromString($template, 'html');
                    $item[] = $val;
                }
            }

            $d[] = $item;
        }

        $data = $d;
        return $data;
    }
}
