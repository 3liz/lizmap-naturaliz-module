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

class occtaxSearchObservationJdd extends occtaxSearchObservation {

    protected $name = 'jdd';

    protected $orderClause = ' ORDER BY jdd_id';

    protected $returnFields = array(
        'jdd_id',
        'libelle',
        'nbobs',
        'nbtax',
    );

    protected $tplFields = array(
        'libelle' => '<a href="#" class="getMetadata jdd_id_{$line->jdd_id}">{$line->jdd_libelle}</a>
        &nbsp;<a class="filterByJdd" href="#" title="{@occtax~search.output.filter.jdd.title@}"><i class="icon-filter"></i></a>', // &nbsp;<a class="filterByJdd" href="#" title="{@occtax~search.output.filter.jdd.title@}"><i class="icon-filter"></i></a>
    );

    protected $row_id = 'jdd_id';

    protected $row_label = 'libelle';

    protected $displayFields = array(
        // 'jdd_id' => array( 'type' => 'string', 'sortable' => "true"),
        'libelle' => array( 'type' => 'string', 'sortable' => "true"),
        'nbobs' => array( 'type' => 'num', 'sortable' => "true", 'className' => 'dt-right'),
        'nbtax' => array( 'type' => 'num', 'sortable' => "true", 'className' => 'dt-right'),
    );

    public function __construct ($token=Null, $params=Null, $demande=Null, $login=Null) {
        $this->login = $login;

        // Reset querySelectors to group result by JDD
        $this->querySelectors = array(
            'occtax.jdd' => array(
                'alias' => 'j',
                'required' => True,
                'join' => '',
                'joinClause' => '',
                'returnFields' => array (
                    'j.jdd_id' => 'jdd_id',
                    'j.jdd_libelle' => 'jdd_libelle',
                )
            ),

            'occtax.vm_observation' => array(
                'alias' => 'o',
                'required' => True,
                'multi' => True,
                'join' => ' JOIN ',
                'joinClause' => ' ON j.jdd_id = o.jdd_id',
                'returnFields' => array(
                    'count(o.cle_obs) AS nbobs'=> Null,
                    'count(DISTINCT o.cd_ref) AS nbtax' => Null
                )
            ),

            // Need to join the v_observation_champs_validation view to get updated validation
            // we do not use validation_observation because the trigger should update observation accordingly
            // for ech_val = '2'
            'occtax.v_observation_champs_validation' => array(
                'alias' => 'oo',
                'required' => False,
                'join' => ' JOIN ',
                'joinClause' => "
                    ON oo.identifiant_permanent = o.identifiant_permanent ",
                'returnFields' => array(),
            ),
        );

        parent::__construct($token, $params, $demande, $login);
    }

    // Override getResult to get all data (no limit nor offset)
    protected function getResult( $limit=50, $offset=0, $order="" ) {
//jLog::log($this->sql);
        $cnx = jDb::getConnection('naturaliz_virtual_profile');
        return $cnx->query( $this->sql );
    }

}
