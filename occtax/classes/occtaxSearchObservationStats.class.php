<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

jClasses::inc('occtax~occtaxSearchObservation');

class occtaxSearchObservationStats extends occtaxSearchObservation {

    protected $maille = 'maille_02';

    protected $returnFields = array(
        'categorie',
        'categorie_image',
        'categorie_nom',
        'nbobs',
        //~ 'nb_maille',  // deactivate as the query is not optimized
        'nb_taxon_present',
        'nb_taxon_protege',
        //'nb_taxon_determinant' // deactivate
    );

    protected $tplFields = array(

        'categorie_image' => '<img src="{$j_basepath}css/images/taxon/{$line->categorie}.png" width="20px" title="{$line->categorie}"/>',

        'categorie_nom' => '<b>{$line->categorie}</b>'
    );

    protected $row_id = 'categorie';

    protected $displayFields = array(
        'categorie_image' => array( 'type' => 'string', 'sortable' => 0),
        'categorie_nom' => array( 'type' => 'string', 'sortable' => "true"),
        'nbobs' => array( 'type' => 'num', 'sortable' => "true"),
        //~ 'nb_maille' => array( 'type' => 'num', 'sortable' => "true"),
        'nb_taxon_present' => array( 'type' => 'num', 'sortable' => "true"),
        'nb_taxon_protege' => array( 'type' => 'num', 'sortable' => "true"),
        //'nb_taxon_determinant' => array( 'type' => 'num', 'sortable' => "true")
    );

    public function __construct ($token=Null, $params=Null, $demande=Null) {
        // Set maille depending on rights
        // do it first because parent::__construct do setSql
        if ( jAcl2::check("visualisation.donnees.maille_01") )
            $this->maille = 'maille_01';

        $this->querySelectors = array(

            'vm_observation' => array(
                'alias' => 'o',
                'required' => True,
                'join' => '',
                'joinClause' => '',
                'returnFields' => array(
                    'categorie' => 'categorie',
                    'count(o.cle_obs) AS nbobs'=> Null,
                    'count(DISTINCT o.cd_ref) AS nb_taxon_present' => Null,
                    "count(DISTINCT o.cd_ref) FILTER (WHERE o.protection IN ('EP', 'EPN', 'EPI', 'EPC')) AS nb_taxon_protege" => Null
                )
            )
        );
        // Remove ORDER BY
        $this->orderClause = '';

        parent::__construct($token, $params, $demande);
    }

    protected function getResult( $limit=50, $offset=0, $order="" ) {
//jLog::log($this->sql);
        $cnx = jDb::getConnection();
        return $cnx->query( $this->sql );
    }
}

