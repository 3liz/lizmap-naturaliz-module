<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

jClasses::inc('mascarine~mascarineSearch');

class mascarineSearchObservation extends mascarineSearch {

    protected $orderClause = ' ORDER BY date_obs DESC';

    protected $returnFields = array(
        'id_obs',
        'date_obs',
        'num_manuscrit',
        'geojson',
        'code_maille',
        'cd_nom',
        'nom_valide',
        'nom_vern',
        'strate_flore',
        'code_commune',
        'nom_commune'
    );

    protected $row_id = 'id_obs';

    protected $querySelectors = array(
        'm_observation' => array(
            'alias' => 'o',
            'required' => True,
            'join' => '',
            'joinClause' => '',
            'returnFields' => array(
                'o.id_obs'=> 'id_obs',
                'o.date_obs' => 'date_obs',
                'o.num_manuscrit' => 'num_manuscrit'
            )
        ),
        'localisation_obs' => array(
            'alias' => 'l',
            'required' => True,
            'join' => ' INNER JOIN ',
            'joinClause' => ' ON o.id_obs = l.id_obs ',
            'returnFields' => array(
                'ST_AsGeoJSON( ST_Transform(l.geom, 4326), 8 ) AS geojson' => 'geom',
                'l.geom' => 'geom',
                'l.code_maille' => 'code_maille'
            )
        ),
        'flore_obs' => array(
            'alias' => 'fo',
            'required' => True,
            'join' => ' INNER JOIN ',
            'joinClause' => ' ON o.id_obs = fo.id_obs AND fo.cd_nom IS NOT NULL ',
            'returnFields' => array(
                'fo.cd_nom'=>'cd_nom',
                'fo.strate_flore'=>'strate_flore'
            )
        ),
        'taxref_consolide' => array(
            'alias' => 't',
            'required' => True,
            'join' => ' INNER JOIN ',
            'joinClause' => ' ON fo.cd_nom = t.cd_nom ',
            'returnFields' => array(
                't.nom_vern'=>'nom_vern',
                't.nom_valide'=>'nom_valide'
            )
        ),
        'commune'  => array(
            'alias' => 'c',
            'required' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON l.code_commune = c.code_commune ',
            'returnFields' => array(
                'c.code_commune' => 'code_commune',
                'c.nom_commune' => 'nom_commune'
            )
        )

    );

    protected $queryFilters = array(
        'id_obs' => array (
            'table' => 'm_observation',
            'clause' => ' AND o.id_obs IN (@)',
            'type'=> 'string'
        ),
        'cd_nom' => array (
            'table' => 'flore_obs',
            'clause' => ' AND fo.cd_nom IN (@)',
            'type'=> 'integer',
            'label'=> array(
                'dao'=>'taxon~taxref',
                'method'=>'get',
                'column'=>'nom_valide'
            )
        ),
        'geom' => array (
            'table' => 'localisation_obs',
            'clause' => ' AND ST_Within(l.geom, fg.fgeom ) ',
            'type' => 'geom'
        ),
        'date_min' => array (
            'table' => 'm_observation',
            //'clause' => " AND ( date_obs::integer >= to_char( @::timestamp, 'YYYYMMDD')::integer ) ",
            'clause' => " AND date_obs >= @ ",
            'type' => 'timestamp'
        ),
        'date_max' => array (
            'table' => 'm_observation',
            //'clause' => " AND ( date_obs::integer <= to_char( @::timestamp, 'YYYYMMDD')::integer ) ",
            'clause' => " AND date_obs <= @ ",
            'type' => 'timestamp'
        ),
        'code_commune' => array (
            'table' => 'localisation_obs',
            'clause' => ' AND l.code_commune IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~commune',
                'method'=>'get',
                'column'=>'nom_commune'
            )
        )
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
                jClasses::inc('mascarine~plantaeSearch');
                $taxonSearch = new plantaeSearch( $token );
                $description.= $taxonSearch->getSearchDescription();
            }
            // Get description for the other filter via parent class
            $description.= parent::getSearchDescription();
        }
        return $description;
    }


}

