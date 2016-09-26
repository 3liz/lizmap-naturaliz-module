<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    René-Luc D'Hont
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class personneObservationSearch {

    private $id = Null;

    private $params = array();

    private $imageUrl = '';

    private $dao = Null;

    private $conditions = Null;

    private $recordsTotal = Null;

    protected $returnFields = array(
      'id_perso',
      'nom_perso',
      'prenom_perso',
      'perso',
      'id_org',
      'role_perso_obs',
      'remove_perso'
    );

    protected $tplFields = array(
      'perso' => '{$line->nom_perso} {$line->prenom_perso}',
      'remove_perso' => '<a href="{jurl \'mascarine~edit_obs:removePersonne\',array(\'id_obs\'=>$line->id_obs,\'id_perso\'=>$line->id_perso)}" target="_blank" class="remove"><i class="icon-trash"></a>'
    );

    protected $row_id = 'id_perso';

    protected $row_label = Null;

    protected $displayFields = array(
      'perso' => array( 'type' => 'string', 'sortable' => "true"),
      'id_org' => array( 'type' => 'string', 'sortable' => "true"),
      'role_perso_obs' => array( 'type' => 'string', 'sortable' => "true"),
      'remove_perso' => array( 'type' => 'string', 'sortable' => "0")
    );

    protected $labelFields = array(
      'id_org' => array(
        'dao'=>'mascarine~organisme',
        'property'=>'abreviation_org'
      ),
      'role_perso_obs' => array(
        'dao'=>'mascarine~nomenclature',
        'property'=>'valeur'
      )
    );

    public function __construct ($id, $params=Null) {

        $this->id = $id;
        $this->params = $params;

        // Set dao
        $this->dao = jDao::get( 'mascarine~personne_observation' );

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
        $conditions->addCondition( 'id_obs', '=', $this->id );
        $this->conditions = $conditions;

        // Filter via form params
        if( $this->params ){
            foreach( $this->params as $k=>$v ){
                if( in_array( $k, $this->queryFields ) and $v ) {
                    $this->conditions->addCondition( $k, '=', $v );
                }
            }
        }
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
                        $item[] = $f->$prop;
                    } else
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
