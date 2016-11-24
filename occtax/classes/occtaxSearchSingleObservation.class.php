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

    protected $returnFields = array();

    public function __construct ($token=Null, $params=Null) {

        parent::__construct($token, $params);

    }

}
