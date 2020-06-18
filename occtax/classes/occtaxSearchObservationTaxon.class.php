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
        'nom_valide',
        'nom_vern_valide',
        'nbobs',
        'groupe',
        'redlist',
        'protectionlist',
        //'filter'
    );

    protected $tplFields = array(

        'nom_valide' => '{if !(empty($line->url))}<a class="getTaxonDetail" href="#" title="{@taxon~search.output.inpn.title@}">{$line->lb_nom_valide}</a>{else}{$line->lb_nom_valide}{/if}&nbsp;<a class="filterByTaxon" href="#" title="{@occtax~search.output.filter.taxon.title@}"><i class="icon-filter"></i></a>

        ',

        'groupe' => '<img src="{$j_basepath}css/images/taxon/{$line->categorie}.png" width="20px" title="{$line->categorie}"/>',

        //'filter' => '<a class="filterByTaxon" href="#" title="{@occtax~search.output.filter.taxon.title@}"><i class="icon-filter"></i></a>',

        'redlist' => '{if !empty($line->menace)}<span class="redlist {$line->menace}" title="{@taxon~search.output.redlist.title@} : {$line->menace}">{$line->menace}</span>{/if}',
        'protectionlist' => '{if !empty($line->protection)}&nbsp;<span class="protectionlist {$line->protection}" title="{@taxon~search.output.protection.title@} : {$line->protection}">{$line->protection}</span>{/if}',

    );

    protected $row_id = 'cd_ref';

    protected $row_label = 'nom_valide';

    protected $displayFields = array(
        'nom_valide' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'lb_nom_valide'),
        'nom_vern_valide' => array( 'type' => 'string', 'sortable' => "true"),
        'nbobs' => array( 'type' => 'num', 'sortable' => "true"),
        'groupe' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'categorie', 'className' => 'dt-center'),
        'redlist' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'menace', 'className' => 'dt-center'),
        'protectionlist' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'protection', 'className' => 'dt-center'),
        //'filter' => array( 'type' => 'string', 'sortable' => 0, 'className' => 'dt-center')
    );

    public function __construct ($token=Null, $params=Null, $demande=Null, $login=Null) {

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
                    'o.menace' => 'menace',
                    'o.protection' => 'protection',
                    'count(o.cle_obs) AS nbobs'=> Null
                )
            )
        );

        parent::__construct($token, $params, $demande, $login);

        // Override parent (ie observations) recordsTotal
        // Problems : this re-run the taxon query to count the result
        $this->setRecordsTotal();

    }


}

