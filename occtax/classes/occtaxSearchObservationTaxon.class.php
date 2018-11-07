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

class occtaxSearchObservationTaxon extends occtaxSearchObservation {

    protected $returnFields = array(
        'cd_nom',
        'nom_valide',
        'nom_vern',
        'nbobs',
        'groupe',
        'inpn',
        'filter'
    );

    protected $tplFields = array(
        'groupe' => '<img src="{$j_basepath}css/images/taxon/{$line->categorie}.png" width="20px" title="{$line->categorie}"/>',

        'inpn' => '<a href="{$line->url}" target="_blank" title="{@taxon~search.output.inpn.title@}"><i class="icon-info-sign">&nbsp;</i></a>',

        'filter' => '<a class="filterByTaxon" href="#" title="{@occtax~search.output.filter.taxon.title@}"><i class="icon-filter"></i></a>'

    );

    protected $row_id = 'cd_nom';
    protected $row_label = 'nom_valide';

    protected $displayFields = array(
        'nom_valide' => array( 'type' => 'string', 'sortable' => "true"),
        'nom_vern' => array( 'type' => 'string', 'sortable' => "true"),
        'nbobs' => array( 'type' => 'num', 'sortable' => "true"),
        'groupe' => array( 'type' => 'string', 'sortable' => "true"),
        'inpn' => array( 'type' => 'string', 'sortable' => 0),
        'filter' => array( 'type' => 'string', 'sortable' => 0)
    );

    public function __construct ($token=Null, $params=Null, $demande=Null) {

        $this->querySelectors = array(

            'vm_observation' => array(
                'alias' => 'o',
                'required' => True,
                'join' => '',
                'joinClause' => '',
                'returnFields' => array(
                    'o.cd_nom' => 'cd_nom',
                    'o.nom_valide' => 'nom_valide',
                    'o.nom_vern' => 'nom_vern',
                    'o.url' => 'url',
                    'o.categorie' => 'categorie',
                    'count(o.cle_obs) AS nbobs'=> Null
                )
            )
        );
        // Remove ORDER BY
        $this->orderClause = '';


        parent::__construct($token, $params, $demande);
    }

    protected function getResult( $limit=50, $offset=0, $order='' ) {
        //jLog::log($this->sql);
        $cnx = jDb::getConnection();
        return $cnx->query( $this->sql );
    }
}

