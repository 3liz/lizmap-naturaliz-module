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
        'filter'
    );

    protected $tplFields = array(

        'nom_valide' => '{if !(empty($line->url))}<a href="{$line->url}" target="_blank" title="{@taxon~search.output.inpn.title@}">{$line->lb_nom_valide}</a>{else}{$line->lb_nom_valide}{/if}',

        'groupe' => '<img src="{$j_basepath}css/images/taxon/{$line->categorie}.png" width="20px" title="{$line->categorie}"/>',

        'filter' => '<a class="filterByTaxon" href="#" title="{@occtax~search.output.filter.taxon.title@}"><i class="icon-filter"></i></a>',

        'redlist' => '<span class="redlist {$line->menace}" title="{@taxon~search.output.redlist.title@} : {$line->lib_menace}">{$line->menace}</span>',

    );

    protected $row_id = 'cd_ref';
    protected $row_label = 'lb_nom_valide';

    protected $displayFields = array(
        'nom_valide' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'lb_nom_valide'),
        'nom_vern_valide' => array( 'type' => 'string', 'sortable' => "true"),
        'nbobs' => array( 'type' => 'num', 'sortable' => "true"),
        'groupe' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'categorie', 'className' => 'dt-center'),
        'redlist' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'menace', 'className' => 'dt-center'),
        'filter' => array( 'type' => 'string', 'sortable' => 0, 'className' => 'dt-center')
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
                    'o.menace' => 'menace',
                    'count(o.cle_obs) AS nbobs'=> Null
                )
            ),
            't_nomenclature' => array(
                'alias' => 'n',
                'required' => True,
                'join' => ' LEFT JOIN ',
                'joinClause' => " ON n.champ = 'menace' AND o.menace = n.code ",
                'returnFields' => array(
                    "n.valeur AS lib_menace" => 'valeur'
                )
            )
        );

        parent::__construct($token, $params, $demande);

        // Override parent (ie observations) recordsTotal
        // Problems : this re-run the taxon query to count the result
        $this->setRecordsTotal();

    }


}

