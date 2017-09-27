<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    3liz
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

jClasses::inc('occtax~occtaxSearchObservationBrutes');

class occtaxSearchSingleObservation extends occtaxSearchObservationBrutes {

    protected $observation_card_fields = array();

    protected $observation_card_fields_unsensitive = array();

    protected $observation_card_children = array();

    public function __construct ($token=Null, $params=Null, $demande=Null) {


        // Limit fields to export (ie to "display in the card" in this class)
        $this->limitFields(
            'observation_card_fields',
            'observation_card_fields_unsensitive',
            'observation_card_children'
        );

        parent::__construct($token, $params, $demande);

    }

}
