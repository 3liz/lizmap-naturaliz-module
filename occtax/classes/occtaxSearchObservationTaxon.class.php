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

    protected $name = 'stats';

    protected $orderClause = '';

    protected $returnFields = array(
        'cd_ref',
        'nom_valide',
        'nom_vern_valide',
        'nbobs',
        'groupe',
        'redlist_regionale',
        'redlist_nationale',
        'redlist_monde',
        'protectionlist',
        //'filter'
    );

    protected $tplFields = array(

        'nom_valide' => '{if !(empty($line->url))}<a class="getTaxonDetail" href="#" title="{@taxon~search.output.inpn.title@}">{$line->lb_nom_valide}</a>{else}{$line->lb_nom_valide}{/if}&nbsp;<a class="filterByTaxon" href="#" title="{@occtax~search.output.filter.taxon.title@}"><i class="icon-filter"></i></a>

        ',

        'groupe' => '<img src="{$j_basepath}taxon/css/images/groupes/{$categories[$line->categorie]}.png" width="20px" title="{$line->categorie}"/>
        ',

        //'filter' => '<a class="filterByTaxon" href="#" title="{@occtax~search.output.filter.taxon.title@}"><i class="icon-filter"></i></a>',

        'redlist_regionale' => '{if !empty($line->menace_regionale)}<span class="redlist {$line->menace_regionale}" title="{@occtax~search.output.redlist_regionale.title@} : {$line->menace_regionale}">{$line->menace_regionale}</span>{/if}',

        'redlist_nationale' => '{if !empty($line->menace_nationale)}<span class="redlist {$line->menace_nationale}" title="{@occtax~search.output.redlist_nationale.title@} : {$line->menace_nationale}">{$line->menace_nationale}</span>{/if}',

        'redlist_monde' => '{if !empty($line->menace_monde)}<span class="redlist {$line->menace_monde}" title="{@occtax~search.output.redlist_monde.title@} : {$line->menace_monde}">{$line->menace_monde}</span>{/if}',

        'protectionlist' => '{if !empty($line->protection)}&nbsp;<span class="protectionlist {$line->protection}" title="{@occtax~search.output.protection.title@} : {$line->protection}">{$line->protection}</span>{/if}',


    );

    protected $row_id = 'cd_ref';

    protected $row_label = 'nom_valide';

    protected $displayFields = array(
        'nom_valide' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'lb_nom_valide'),
        'nom_vern_valide' => array( 'type' => 'string', 'sortable' => "true"),
        'nbobs' => array( 'type' => 'num', 'sortable' => "true"),
        'groupe' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'categorie', 'className' => 'dt-center'),
        'redlist_regionale' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'menace_regionale', 'className' => 'dt-center'),
        'redlist_nationale' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'menace_nationale', 'className' => 'dt-center'),
        'redlist_monde' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'menace_monde', 'className' => 'dt-center'),
        'protectionlist' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'protection', 'className' => 'dt-center'),
        //'filter' => array( 'type' => 'string', 'sortable' => 0, 'className' => 'dt-center')
    );

    public function __construct ($token=Null, $params=Null, $demande=Null, $login=Null) {
        $this->login = $login;

        $this->querySelectors = array(

            'occtax.vm_observation' => array(
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
                    'o.menace_regionale' => 'menace_regionale',
                    'o.menace_nationale' => 'menace_nationale',
                    'o.menace_monde' => 'menace_monde',
                    'o.protection' => 'protection',
                    'count(o.cle_obs) AS nbobs'=> Null
                )
            )
        );

        // Get local configuration (application name, projects name, list of fields, etc.)
        $localConfig = jApp::configPath('naturaliz.ini.php');
        $ini = new jIniFileModifier($localConfig);

        // Hide menace fields depending on configuration
        $taxon_table_menace_fields = $ini->getValue('taxon_table_menace_fields', 'naturaliz');
        if (empty($taxon_table_menace_fields)) {
            $taxon_table_menace_fields = 'menace_nationale, menace_monde';
        }
        $menace_fields = array_map('trim', explode(',', $taxon_table_menace_fields));
        $all_menace = array('menace_regionale', 'menace_nationale', 'menace_monde');
        foreach ($all_menace as $menace) {
            if (!in_array($menace, $menace_fields)) {
                unset($this->querySelectors['occtax.vm_observation']['returnFields'][$menace]);
                $red = str_replace('menace_', 'redlist_', $menace);
                unset($this->displayFields[$red]);
            }
        }

        // Get t_group_categorie lowered and unaccentuated names
        $tpl_categories = $this->getGroupNormalizedCategories();
        $this->tplFields['groupe'] = $tpl_categories . $this->tplFields['groupe'];

        parent::__construct($token, $params, $demande, $login);

        // Override parent (ie observations) recordsTotal
        // Problems : this re-run the taxon query to count the result
        $this->setRecordsTotal();

    }

}

