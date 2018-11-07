<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

jClasses::inc('occtax~occtaxSearch');

class occtaxSearchObservation extends occtaxSearch {

    protected $orderClause = ' ORDER BY date_debut DESC';

    protected $returnFields = array(
        'cle_obs',
        'date_debut',
        'nom_cite',
        'geojson',
        'identite_observateur',
        'source_objet',
        'detail'
    );

    protected $tplFields = array(
        'detail' => '<a class="openObservation" href="#" title="{@occtax~search.output.detail.title@}"><i class="icon-file"></i></a>'
    );

    protected $row_id = 'cle_obs';

    protected $displayFields = array(
        'date_debut' => array( 'type' => 'string', 'sortable' => "true"),
        'nom_cite' => array( 'type' => 'string', 'sortable' => "true"),
        'identite_observateur' => array( 'type' => 'string', 'sortable' => "true"),
        'source_objet' => array( 'type' => 'string', 'sortable' => "true"),
        'detail' => array( 'type' => 'string', 'sortable' => 0)
    );

    protected $querySelectors = array(
        'vm_observation' => array(
            'alias' => 'o',
            'required' => True,
            'join' => '',
            'joinClause' => '',
            'returnFields' => array(
                'o.cle_obs'=> Null,
                'o.nom_cite' => Null,
                'o.cd_nom' => Null,
                "date_debut" => Null,
                "source_objet" => Null,
                'ST_AsGeoJSON( ST_Transform(o.geom, 4326), 6 ) AS geojson' => Null,
                'o.geom' => Null,
                "o.diffusion" => Null,
                "identite_observateur" => Null
            )
        )
    );

    protected $queryFilters = array(
        'cle_obs' => array (
            'table' => 'vm_observation',
            'clause' => ' AND o.cle_obs IN (@)',
            'type'=> 'string'
        ),
        'cd_nom' => array (
            'table' => 'vm_observation',
            'clause' => ' AND o.cd_ref IN (@)',
            //'clause' => ' AND o.cd_ref = ANY ( ARRAY[ @ ] )',
            'type'=> 'integer',
            'label'=> array(
                'dao'=>'taxon~taxref',
                'method'=>'get',
                'column'=>'nom_valide'
            )
        ),
        'geom' => array (
            'table' => 'vm_observation',
            'clause' => ' AND ST_Intersects(o.geom, fg.fgeom ) ',
            'type' => 'geom'
        ),
        'date_min' => array (
            'table' => 'vm_observation',
            'clause' => ' AND ( date_debut >= @::timestamp OR date_fin >= @::timestamp ) ',
            'type' => 'timestamp'
        ),
        'date_max' => array (
            'table' => 'vm_observation',
            'clause' => ' AND ( date_debut <= @::timestamp OR date_fin <= @::timestamp ) ',
            'type' => 'timestamp'
        ),
        'code_commune' => array (
            'table' => 'vm_observation',
            'clause' => ' AND code_commune ?| ARRAY[@]',
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~commune',
                'method'=>'get',
                'column'=>'nom_commune'
            )
        ),
        'code_masse_eau' => array (
            'table' => 'vm_observation',
            'clause' => ' AND lme.code_me ?| ARRAY[@]',
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~masse_eau',
                'method'=>'get',
                'column'=>'nom_me'
            )
        ),

        'observateur' => array (
            'table' => 'vm_observation',
            'clause' => ' AND o.cle_obs IN (SELECT cle_obs FROM v_observateur vo WHERE vo.identite ILIKE ( @ )  )',
            'type' => 'partial'
        ),

        'type_en' => array (
            'table' => 'vm_observation',
            'clause' => ' AND len.type_en ?| ARRAY[@]',
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~nomenclature',
                'method'=>'getTypeEn',
                'column'=>'valeur'
            )
        ),

        'jdd_id' => array (
            'table' => 'vm_observation',
            'clause' => ' AND o.jdd_id IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~jdd',
                'method'=>'get',
                'column'=>'jdd_code'
            )
        ),

        'validite_niveau' => array (
            'table' => 'vm_observation',
            'clause' => ' AND o.validite_niveau IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~nomenclature',
                'method'=>'getValiditeNiveau',
                'column'=>'valeur'
            )
        ),
    );


    /**
     * construct - Change geometry value depending on logged user
    */
    public function __construct ($token=Null, $params=Null, $demande=Null) {

        parent::__construct($token, $params, $demande);
    }


    /**
     * Get search description
    */
    public function getSearchDescription($format='html', $drawLegend=true){
        $description = '';
        $params = $this->getParams();
        if ( $params ) {

            // Get description for the other filter via parent class
            $parent_description = parent::getSearchDescription($format, $drawLegend);

            // Get search description for TAXON list
            if ( count($this->taxon_params) > 0 ){
                $token = $params['search_token'];
                jClasses::inc('taxon~taxonSearch');
                $taxonSearch = new taxonSearch( $token );
                $description.= $taxonSearch->getSearchDescription();

                $mat = array();
                $test = preg_match('#^' . jLocale::get('occtax~search.description.no.filters') . '#', $parent_description, $mat);
                if( !$test ){
                    $description.= $parent_description;
                }else{
                    $description.= preg_replace('#^' . jLocale::get('occtax~search.description.no.filters') . '#', '', $parent_description);
                }
            }else{
                $description.= $parent_description;
            }


        }

        if( $format=='html' ){
            $titre = jLocale::get('occtax~search.description.active.filters');
            $description = "<b>$titre</b> :<br/>" . $description;
        }

        return $description;
    }

    protected function setWhereClause(){
        $sql = parent::setWhereClause();

        // Dot not query sensitive data if user has queried via spatial tools
        // to avoid guessing position of sensitive data
        if( !jAcl2::check("visualisation.donnees.brutes") ){
            $qf = $this->queryFilters;
            $blackQueryParams = array('code_maille', 'code_masse_eau', 'code_commune');
            $qMatch = array(
                'code_maille_10' => 'm10',
                'code_commune' => 'c'
            );
            foreach( $this->params as $k=>$v ){
                if( array_key_exists( $k, $qf ) and $v and $qf[$k]['type'] != 'geom' ){
                    if( in_array($k, $blackQueryParams) ){
                        $asql = '';
                        // Keep only data with open diffusion
                        $asql.= " AND ( diffusion ? 'g' ";
                        // Keep also some more data based on query type
                        if( array_key_exists($k, $qMatch) ){
                            $asql.= " OR diffusion ? '".$qMatch[$k]."' ";
                        }
                        $asql.= ' ) ';
//jLog::log($asql);
                        $sql.= $asql;

                    }
                }
            }
        }

        // Show only validated data for unlogged users
        if( !jAcl2::check("visualisation.donnees.brutes") ){
            $sql.= " AND o.validite_niveau IN ( ".$this->validite_niveaux_grand_public." )";
        }

        // taxons
        $params = $this->getParams();
        if ( $params ) {
            // Get taxon from taxon search
            if ( array_key_exists( 'search_token', $params ) && $params['search_token'] ) {
                $token = $params['search_token'];
                jClasses::inc('taxon~taxonSearch');

                $taxonSearch = new taxonSearch( $token );
                $tsFields = $taxonSearch->getFields();

                $conditions = $taxonSearch->getConditions();

                $tsql = array();
                foreach($conditions->condition->conditions as $condition){
                    $csql = '"' . $condition['field_id'];
                    $csql.= '" ' . $condition['operator'];

                    $value = $condition['value'];
                    if(is_array($value)){
                        $values = array_map( function($item){return $this->myquote($item);}, $value );
                        // on doit faire le quote ici car on ne passe pas par jelix pour construire le sql
                        $csql.= ' ( ' . implode(',', $values)  .' ) ';
                    }else{
                        if($condition['operator'] == 'IN'){
                            $csql.= ' ( ';
                        }
                        $csql.= ' ' . $this->myquote($value) . ' ';
                        if($condition['operator'] == 'IN'){
                            $csql.= ' ) ';
                        }
                    }
                    $tsql[] = $csql;

                }
                if( count($tsql) > 0 ){
                    $taxonSql = " AND o.cd_ref IN (SELECT cd_ref FROM taxon.taxref_consolide_non_filtre WHERE ";
                    $taxonSql.= implode( ' AND ', $tsql  ) . " ) ";
                    $sql.= $taxonSql;
                }
            }
        }
//jLog::log($sql);
        return $sql;

    }


}

