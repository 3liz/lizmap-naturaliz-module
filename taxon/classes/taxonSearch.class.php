<?php
/**
* @package   lizmap
* @subpackage taxon
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class taxonSearch {

    const sessionPrefix = 'taxonSearch';

    private $id = Null;

    private $params = array();

    private $imageUrl = '';

    private $dao = Null;

    private $conditions = Null;

    private $recordsTotal = Null;

    protected $returnFields = array(
        'cd_nom',
        'cd_ref',
        'nom_valide',
        'nom_vern',
        'group2_inpn',
        'redlist',
        'inpn',
        'illustration',
        'add'
    );

    protected $tplFields = array(
        'group2_inpn' => '
            {assign $image= "no_image"}
            {assign $groupe = ""}
            {if $line->cat_nom_1}
                {assign $image = $line->cat_nom_1}
                {assign $groupe = $line->cat_nom_1}
            {/if}
            {if $line->cat_nom_2}
                {assign $image = $line->cat_nom_2}
                {assign $groupe = $line->cat_nom_2}
            {/if}
            <img src="{$j_basepath}css/images/taxon/{$image}.png" width="20px" title="{$groupe}"/>
        ',

        'redlist' => '<span class="redlist {$line->menace}" title="{@taxon~search.output.redlist.title@} : {$libmenace}">{$line->menace}</span>',

        'inpn' => '<a href="http://inpn.mnhn.fr/espece/cd_nom/{$line->cd_nom}" target="_blank" title="{@taxon~search.output.inpn.title@}"><i class="icon-info-sign">&nbsp;</i></a>',

        'illustration' => '{if $illustration}<a href="{$illustration}" target="_blank" title="{@taxon~search.output.illustration.title@}"><i class="icon-picture">&nbsp;</i></a>{else}-{/if}',

        'add' => '<a class="addTaxon" href="#" title="{@taxon~search.output.add.title@}"><i class="icon-plus-sign"></i></a>'
    );

    protected $row_id = 'cd_nom';

    protected $row_label = 'nom_valide';

    protected $displayFields = array(
        'nom_valide' => array( 'type' => 'string', 'sortable' => "true"),
        'nom_vern' => array( 'type' => 'string', 'sortable' => "true"),
        'group2_inpn' => array( 'type' => 'string', 'sortable' => "0"),
        'redlist' => array( 'type' => 'string', 'sortable' => "0"),
        'inpn' => array( 'type' => 'string', 'sortable' => "0"),
        'illustration' => array( 'type' => 'string', 'sortable' => "0"),
        'add' => array( 'type' => 'string', 'sortable' => "0"),
    );

    protected $queryFields = array(
        'cd_ref',
        'group1_inpn',
        'group2_inpn',
        'habitat',
        'statut',
        'rarete',
        'endemicite',
        'invasibilite',
        'menace',
        'menace_monde',
        'protection',
        'det_znieff'
    );

    protected $queryFilters = array(
        'cd_ref' => array(
            'type'=> 'integer',
            'label'=> array(
                'dao'=>'taxon~taxref',
                'column'=>'nom_valide'
            )
        ),
        'group' => array(
            'type'=> 'string',
            'label'=> array(
                'dao'=>'taxon~t_group_categorie',
                'conditions'=>array(
                    array('cat_nom','=','$val'),
                ),
                'column'=>'cat_nom'
            )
        ),
        'habitat' => array(
            'type'=> 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'conditions'=>array(
                    array('champ','=','habitat'),
                    array('code','=','$val')
                ),
                'column'=>'valeur'
            )
        ),
        'statut' => array(
            'type'=> 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'conditions'=>array(
                    array('champ','=','statut'),
                    array('code','=','$val')
                ),
                'column'=>'valeur'
            )
        ),
        'rarete' => array(
            'type'=> 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'conditions'=>array(
                    array('champ','=','rarete'),
                    array('code','=','$val')
                ),
                'column'=>'valeur'
            )
        ),
        'endemicite' => array(
            'type'=> 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'conditions'=>array(
                    array('champ','=','endemicite'),
                    array('code','=','$val')
                ),
                'column'=>'valeur'
            )
        ),
        'invasibilite' => array(
            'type'=> 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'conditions'=>array(
                    array('champ','=','invasibilite'),
                    array('code','=','$val')
                ),
                'column'=>'valeur'
            )
        ),
        'menace' => array(
            'type'=> 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'conditions'=>array(
                    array('champ','=','menace'),
                    array('code','=','$val')
                ),
                'column'=>'valeur'
            )
        ),
        'menace_monde' => array(
            'type'=> 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'conditions'=>array(
                    array('champ','=','menace'),
                    array('code','=','$val')
                ),
                'column'=>'valeur'
            )
        ),
        'protection' => array(
            'type'=> 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'conditions'=>array(
                    array('champ','=','protection'),
                    array('code','=','$val')
                ),
                'column'=>'valeur'
            )
        ),
        'det_znieff' => array(
            'type'=> 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'conditions'=>array(
                    array('champ','=','det_znieff'),
                    array('code','=','$val')
                ),
                'column'=>'valeur'
            )
        )
    );

    public function __construct ($id, $params=Null) {

        $this->id = $id;
        $this->params = $params;

        // Set dao
        $this->dao = jDao::get( 'taxon~taxref' );

        // Get parameters from cache if no parameters given
        if( !$this->params ){
            $this->fromCache();
        }

        // Set up conditions
        if( !$this->conditions )
            $this->setConditions();

        // Get the number of total records
        if( !$this->recordsTotal )
            $this->setRecordsTotal();

        // Store to session
        $this->toCache();

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
     * Get search description
    */
    public function getSearchDescription(){
        $tpl = new jTpl();
        $filters = array();
        $qf = $this->queryFilters;
        foreach( $this->params as $k=>$v ){
            if( array_key_exists( $k, $qf ) and $v ){
                $filters[$k] = $this->getValueLabel($k, $v);
            }
        }
        $tpl->assign('filters', $filters);
        $description = $tpl->fetch('taxon~searchDescription');
        return $description;
    }

    private function getValueLabel( $k, $v ){
        $qf = $this->queryFilters;

        // Return value if no correspondance needed
        if( !array_key_exists( 'label', $qf[$k] ) )
            return $v;

        $qfl = $qf[$k]['label'];
        $dao = jDao::get( $qfl['dao']);
        $label = '';

        if( is_array($v) ){
            $sep = '';
            foreach( $v as $i ){
                $item = $dao->get($i);
                if( $item ){
                    $label.= $sep . $item->$qfl['column'];
                    $sep = ', ';
                }else{
                    $label.= $v;
                }
            }
        } else if( array_key_exists( 'conditions', $qfl ) ) {
            $daoConditions = jDao::createConditions();
            $conditions = $qfl['conditions'];
            foreach ( $conditions as $c ) {
                if ( count( $c ) != 3 )
                  continue;
                if ( $c[2] == '$val' )
                  $daoConditions->addCondition( $c[0], $c[1], $v);
                else
                  $daoConditions->addCondition( $c[0], $c[1], $c[2]);
            }
            $list = $dao->findBy( $daoConditions, 0, 1 );
            $item = $list->fetch();
            if($item)
                $label = $item->$qfl['column'];
            else
                $label = $v;
        }else{
            $item = $dao->get($v);
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
    * Set the conditions for the query
    * and set the object property
    */
    function setConditions() {
        $conditions = jDao::createConditions();
        $this->conditions = $conditions;

        // Filter via form params
        if( $this->params ){
            // Add filter
            foreach( $this->params as $k=>$v ){
                if( in_array( $k, $this->queryFields ) and $v ) {
                    if( $k == 'group2_inpn')
                        $this->conditions->addCondition( $k, 'IN', $v );
                    else
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
        if( $this->conditions )
            $this->recordsTotal = $this->dao->countBy( $this->conditions );
    }


    /**
    * Search species filtered by given parameters
    * @param $offset Offset for the query. Default 0
    * @param $limit Limit for the query. Default 20
    * @param $order Order for the query. Default:  nom_valide:asc
    * @return List of matching taxons
    */
    function getData( $limit=20, $offset=0, $order='nom_valide:asc' ) {

        // First set order
        $orderCol = 'nom_valide'; $orderDir = 'asc';
        $orderExp = explode( ':', $order );
        if( count( $orderExp ) == 2 ){
            $orderCol = $orderExp[0];
            $orderDir = $orderExp[1];
        }
        $this->conditions->addItemOrder( $orderCol, $orderDir );

        $result = $this->dao->findBy( $this->conditions, $offset, $limit );
        $data = $result->fetchAll();
        $d = array();

        // Get fields from result
        foreach( $data as $line ) {
            $item = array();
            // Get fields from result
            foreach( $this->returnFields as $field ) {
                if( property_exists( $line, $field ) and !array_key_exists($field, $this->tplFields) ) {
                    $item[] = $line->$field;
                }
            }

            // Get template fields
            foreach( $this->tplFields as $field=>$template ) {
                $tpl = new jTpl();
                $assign = array();
                if( $field == 'illustration' ){
                    $illustrationPath = '/css/illustrations/' . $line->cd_nom. '.jpg';
                    $imageUrl = '';
                    if( file_exists( jApp::wwwPath() . $illustrationPath) )
                        $illustration = $illustrationPath;
                    else
                        $illustration = '';
                    $assign['illustration'] = $illustration;
                }
                if( $field == 'redlist' ){
                    $daoN = jDao::get( 'taxon~t_nomenclature' );
                    $men = $daoN->get( 'menace', $line->menace );
                    $libmenace = $line->menace;
                    if( $men )
                        $libmenace = $men->valeur;
                    $assign['libmenace'] = $libmenace;

                }

                $assign['line'] = $line;
                $tpl->assign( $assign );
                $val = $tpl->fetchFromString($template, 'html');
                $item[] = $val;
            }

            $d[] = $item;
        }

        $data = $d;
        return $data;
    }

    /**
    * Store information to cache
    */
    public function toCache(){
        $_SESSION[static::sessionPrefix . $this->id] = array(
            'id' => $this->id,
            'params' => $this->params,
            'recordsTotal' => $this->recordsTotal
        );
    }

    /**
    * Retrieve information from cache
    */
    public function fromCache(){
        if( isset( $_SESSION[static::sessionPrefix . $this->id] ) ){
            $cache = $_SESSION[static::sessionPrefix . $this->id];
            $this->params = $cache['params'];
            $this->recordsTotal = $cache['recordsTotal'];

            // Set up conditions
            $this->setConditions();

            // Store to cache
            $this->toCache();
        }
    }

}

