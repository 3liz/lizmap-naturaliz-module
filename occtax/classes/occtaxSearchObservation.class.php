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
        'observation' => array(
            'alias' => 'o',
            'required' => True,
            'join' => '',
            'joinClause' => '',
            'returnFields' => array(
                'o.cle_obs'=> 'cle_obs',
                'o.nom_cite' => 'nom_cite',
                'o.cd_nom' => 'cd_nom',
                "to_char(date_debut, 'YYYY-MM-DD') AS date_debut" => 'date_debut',
                "
                CASE
                    WHEN o.geom IS NOT NULL THEN 'GEO'
                    WHEN lm10.code_maille IS NOT NULL THEN 'M10'
                    WHEN lc.code_commune IS NOT NULL THEN 'COM'
                    WHEN lme.code_me IS NOT NULL THEN 'ME'
                    WHEN len.code_en IS NOT NULL THEN 'EN'
                    WHEN ld.code_departement IS NOT NULL THEN 'DEP'
                    ELSE 'NO'
                END AS source_objet
                " => "source_objet",
                'ST_AsGeoJSON( ST_Transform(o.geom, 4326), 8 ) AS geojson' => 'geom',
                'o.geom' => 'geom',
            )
        ),
        'v_observateur'  => array(
            'alias' => 'pobs',
            'required' => True,
            'multi' => True,
            'join' => ' JOIN ',
            'joinClause' => " ON pobs.cle_obs = o.cle_obs ",
            'returnFields' => array(
                "string_agg(pobs.identite, ', ') AS identite_observateur" => 'identite_observateur'
            )
        ),

        'localisation_maille_10'  => array(
            'alias' => 'lm10',
            'required' => True,
            'multi' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON lm10.cle_obs = o.cle_obs ',
            'returnFields' => array(
                //~ "string_agg(lm10.code_maille, '|') AS code_maille_10" => 'code_maille_10'
            )
        ),
        'localisation_commune'  => array(
            'alias' => 'lc',
            'required' => True,
            'multi' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON lc.cle_obs = o.cle_obs ',
            'returnFields' => array(
                //~ "string_agg(lc.code_commune, '|') AS code_commune" => ''
            )
        ),
        'localisation_departement'  => array(
            'alias' => 'ld',
            'required' => True,
            'multi' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON ld.cle_obs = o.cle_obs ',
            'returnFields' => array(
                //~ "string_agg(lc.code_commune, '|') AS code_commune" => ''
            )
        ),
        'localisation_masse_eau'  => array(
            'alias' => 'lme',
            'required' => True,
            'multi' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON lme.cle_obs = o.cle_obs ',
            'returnFields' => array(
                //~ "string_agg(lme.code_me, '|') AS code_me" => ''
            )
        ),
        'v_localisation_espace_naturel'  => array(
            'alias' => 'len',
            'required' => True,
            'multi' => False,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON len.cle_obs = o.cle_obs ',
            'returnFields' => array(
            )
        ),

    );

    protected $queryFilters = array(
        'cle_obs' => array (
            'table' => 'observation',
            'clause' => ' AND o.cle_obs IN (@)',
            'type'=> 'string'
        ),
        'cd_nom' => array (
            'table' => 'observation',
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
            'table' => 'observation',
            'clause' => ' AND ST_Intersects(o.geom, fg.fgeom ) ',
            'type' => 'geom'
        ),
        'date_min' => array (
            'table' => 'observation',
            'clause' => ' AND ( date_debut >= @::timestamp OR date_fin >= @::timestamp ) ',
            'type' => 'timestamp'
        ),
        'date_max' => array (
            'table' => 'observation',
            'clause' => ' AND ( date_debut <= @::timestamp OR date_fin <= @::timestamp ) ',
            'type' => 'timestamp'
        ),
        'code_commune' => array (
            'table' => 'localisation_commune',
            'clause' => ' AND lc.code_commune IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~commune',
                'method'=>'get',
                'column'=>'nom_commune'
            )
        ),
        'code_masse_eau' => array (
            'table' => 'localisation_masse_eau',
            'clause' => ' AND lme.code_me IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~masse_eau',
                'method'=>'get',
                'column'=>'nom_me'
            )
        ),

        'observateur' => array (
            'table' => 'v_observateur',
            'clause' => ' AND o.cle_obs IN (SELECT cle_obs FROM v_observateur vo WHERE vo.identite ILIKE ( @ )  )',
            'type' => 'partial'
        ),

        'type_en' => array (
            'table' => 'v_localisation_espace_naturel',
            'clause' => ' AND len.type_en IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~nomenclature',
                'method'=>'getTypeEn',
                'column'=>'valeur'
            )
        ),

        'jdd_id' => array (
            'table' => 'observation',
            'clause' => ' AND o.jdd_id IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~jdd',
                'method'=>'get',
                'column'=>'jdd_code'
            )
        ),
    );


    /**
     * Get search description
    */
    public function getSearchDescription($format='html'){
        $description = '';
        $params = $this->getParams();
        if ( $params ) {
            // Get search description for TAXON list
            if ( count($this->taxon_params) > 0 ){
                $token = $params['search_token'];
                jClasses::inc('taxon~taxonSearch');
                $taxonSearch = new taxonSearch( $token );
                $description.= $taxonSearch->getSearchDescription();
            }
            // Get description for the other filter via parent class
            $description.= parent::getSearchDescription($format);
        }
        return $description;
    }

    protected function setWhereClause(){
        $sql = parent::setWhereClause();

        // sensibilité
        if( !jAcl2::check("visualisation.donnees.sensibles") ){
            $sql.= " AND o.cd_nom NOT IN (SELECT cd_nom FROM taxon.taxon_sensible) ";
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
                        $csql.= ' ( ' . implode(',', $values)  .' ) ';
                    }else{
                        $csql.= ' ' . $this->myquote($value) . ' ';
                    }

                    $tsql[] = $csql;
                }

                if( count($tsql) > 0 ){
                    $taxonSql = " AND o.cd_ref IN (SELECT cd_ref FROM taxon.taxref_consolide WHERE ";
                    $taxonSql.= implode( ' AND ', $tsql  ) . " ) ";
                    $sql.= $taxonSql;
                }
            }
        }
        return $sql;

    }

}

