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
    protected $orderClause = '';

    protected $returnFields = array(
        'cd_ref',
        'lb_nom_valide',
        'nom_vern_valide',
        'nbobs',
        'groupe',
        'inpn',
        'filter'
    );

    protected $tplFields = array(
        'groupe' => '<img src="{$j_basepath}css/images/taxon/{$line->categorie}.png" width="20px" title="{$line->categorie}"/>',

        'inpn' => '{if !(empty($line->url))}<a href="{$line->url}" target="_blank" title="{@taxon~search.output.inpn.title@}"><i class="icon-info-sign">&nbsp;</i></a>{/if}',

        'filter' => '<a class="filterByTaxon" href="#" title="{@occtax~search.output.filter.taxon.title@}"><i class="icon-filter"></i></a>'

    );

    protected $row_id = 'cd_ref';
    protected $row_label = 'lb_nom_valide';

    protected $displayFields = array(
        'lb_nom_valide' => array( 'type' => 'string', 'sortable' => "true"),
        'nom_vern_valide' => array( 'type' => 'string', 'sortable' => "true"),
        'nbobs' => array( 'type' => 'num', 'sortable' => "true"),
        'groupe' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'categorie'),
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
                    'o.cd_ref' => 'cd_ref',
                    'o.lb_nom_valide' => 'lb_nom_valide',
                    'o.nom_vern_valide' => 'nom_vern_valide',
                    'o.url' => 'url',
                    'o.categorie' => 'categorie',
                    'count(o.cle_obs) AS nbobs'=> Null
                )
            )
        );

        parent::__construct($token, $params, $demande);

        // Override parent (ie observations) recordsTotal
        // Problems : this re-run the taxon query to count the result
        $this->setRecordsTotal();

    }


}

