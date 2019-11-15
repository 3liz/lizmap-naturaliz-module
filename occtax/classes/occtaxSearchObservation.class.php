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
        'lb_nom_valide',
        'geojson',
        'observateur',
        'source_objet',
        'detail'
    );

    protected $tplFields = array(
        'observateur' => '
            <span class="identite_observateur" title="{$line->identite_observateur|eschtml}">
                {$line->identite_observateur|truncate:40}
            </span>
        ',
        'detail' => '<a class="openObservation" href="#" title="{@occtax~search.output.detail.title@}"><i class="icon-file"></i></a>'
    );

    protected $row_id = 'cle_obs';

    protected $displayFields = array(
        'date_debut' => array( 'type' => 'string', 'sortable' => "true", 'className' => 'dt-center'),
        'lb_nom_valide' => array( 'type' => 'string', 'sortable' => "true"),
        'observateur' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'identite_observateur'),
        'source_objet' => array( 'type' => 'string', 'sortable' => "true", 'className' => 'dt-center'),
        'detail' => array( 'type' => 'string', 'sortable' => 0, 'className' => 'dt-center')
    );

    protected $querySelectors = array(
        'vm_observation' => array(
            'alias' => 'o',
            'required' => True,
            'join' => '',
            'joinClause' => '',
            'returnFields' => array(
                'o.cle_obs'=> Null,
                'o.lb_nom_valide' => Null,
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
            'clause' => ' AND code_me ?| ARRAY[@]',
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
            'clause' => ' AND type_en ?| ARRAY[@]',
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

        // TAXONS
        'group' => array (
            'table' => 'vm_observation',
            'clause' => ' AND o.categorie IN ( @ )',
            'type' => 'string'
        ),

        'habitat' => array (
            'table' => 'vm_observation',
            'clause' => ' AND o.habitat IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'method'=>'getLabel',
                'champ'=>'habitat',
                'column'=>'valeur'
            )
        ),

        //'statut' => array (
            //'table' => 'vm_observation',
            //'clause' => ' AND o.statut IN ( @ )',
            //'type' => 'string',
            //'label'=> array(
                //'dao'=>'taxon~t_nomenclature',
                //'method'=>'getLabel',
                //'champ'=>'statut',
                //'column'=>'valeur'
            //)
        //),

        //'endemicite' => array (
            //'table' => 'vm_observation',
            //'clause' => ' AND o.endemicite IN ( @ )',
            //'type' => 'string',
            //'label'=> array(
                //'dao'=>'taxon~t_nomenclature',
                //'method'=>'getLabel',
                //'champ'=>'endemicite',
                //'column'=>'valeur'
            //)
        //),

        //'invasibilite' => array (
            //'table' => 'vm_observation',
            //'clause' => ' AND o.invasibilite IN ( @ )',
            //'type' => 'string',
            //'label'=> array(
                //'dao'=>'taxon~t_nomenclature',
                //'method'=>'getLabel',
                //'champ'=>'invasibilite',
                //'column'=>'valeur'
            //)
        //),

        'menace' => array (
            'table' => 'vm_observation',
            'clause' => ' AND o.menace IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'method'=>'getLabel',
                'champ'=>'menace',
                'column'=>'valeur'
            )
        ),

        'protection' => array (
            'table' => 'vm_observation',
            'clause' => ' AND o.protection IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'method'=>'getLabel',
                'champ'=>'protection',
                'column'=>'valeur'
            )
        ),


        //'nom_valide' => array (
            //'table' => 'vm_observation',
            //'clause' => ' AND o.nom_valide ILIKE ( @ )',
            //'type' => 'partial'
        //),
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
            $description.= $parent_description;

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

//jLog::log($sql);
        return $sql;

    }


}

