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
                'o.cle_objet'=> 'cle_objet',
                'o.identite_observateur' => 'identite_observateur',
                "
                CASE
                    WHEN o.cle_objet IS NOT NULL THEN 'GEO'
                    WHEN lm05.code_maille IS NOT NULL THEN 'M05'
                    WHEN lm10.code_maille IS NOT NULL THEN 'M10'
                    WHEN lc.code_commune IS NOT NULL THEN 'COM'
                    WHEN lme.code_me IS NOT NULL THEN 'ME'
                    WHEN len.code_en IS NOT NULL THEN 'EN'
                    WHEN o.code_departement IS NOT NULL THEN 'DEP'
                    ELSE 'NO'
                END AS source_objet
                " => "source_objet"
            )
        ),
        'objet_geographique' => array(
            'alias' => 'g',
            'required' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON g.cle_objet = o.cle_objet ',
            'returnFields' => array(
                'ST_AsGeoJSON( ST_Transform(g.geom, 4326), 8 ) AS geojson' => 'geom',
                'g.geom' => 'geom',
            )
        ),
        'localisation_maille_05'  => array(
            'alias' => 'lm05',
            'required' => True,
            'multi' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON lm05.cle_obs = o.cle_obs ',
            'returnFields' => array(
                //~ "string_agg(lm05.code_maille, '|') AS code_maille_05" => 'code_maille_05'
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
            'type'=> 'integer',
            'label'=> array(
                'dao'=>'taxon~taxref',
                'method'=>'get',
                'column'=>'nom_valide'
            )
        ),
        'geom' => array (
            'table' => 'objet_geographique',
            'clause' => ' AND ST_Intersects(g.geom, fg.fgeom ) ',
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
            'table' => 'observation',
            'clause' => ' AND o.identite_observateur ILIKE ( @ )',
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
    public function getSearchDescription(){
        $description = '';
        $params = $this->getParams();
        if ( $params ) {
            // Get search description for TAXON list
            if ( array_key_exists( 'search_token', $params ) && $params['search_token'] ) {
                $token = $params['search_token'];
                jClasses::inc('taxon~taxonSearch');
                $taxonSearch = new taxonSearch( $token );
                $description.= $taxonSearch->getSearchDescription();
            }
            // Get description for the other filter via parent class
            $description.= parent::getSearchDescription();
        }
        return $description;
    }

    protected function setWhereClause(){
        $sql = parent::setWhereClause();
        if( !jAcl2::check("visualisation.donnees.sensibles") ){
            $sql.= " AND o.cd_nom NOT IN (SELECT cd_nom FROM taxon.taxon_sensible) ";
        }

        $params = $this->getParams();
        if ( $params ) {
            if ( array_key_exists( 'search_token', $params ) && $params['search_token'] ) {
                $token = $params['search_token'];
                jClasses::inc('taxon~taxonSearch');
                $taxonSearch = new taxonSearch( $token );
                $tsFields = $taxonSearch->getFields();
                $tsRowIdIdx = array_search( 'cd_ref', $tsFields['return'] );
                $tsData = $taxonSearch->getData( $taxonSearch->getRecordsTotal(), 0 );
                $taxons = array();
                foreach( $tsData as $d ) {
                    $taxons[] = $d[ $tsRowIdIdx ];
                }
                $sql.= ' ' . str_replace(
                    '@',
                    implode( ', ', $taxons ),
                    $this->queryFilters['cd_nom']['clause']
                );
            }
        }
        return $sql;

    }

}

