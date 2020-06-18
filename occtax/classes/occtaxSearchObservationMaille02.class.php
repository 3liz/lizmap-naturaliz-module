<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

jClasses::inc('occtax~occtaxSearchObservationMaille');

class occtaxSearchObservationMaille02 extends occtaxSearchObservationMaille {

    protected $maille = 'maille_02';

    public function __construct ($token=Null, $params=Null, $demande=Null, $login=Null) {
        parent::__construct($token, $params, $demande, $login);
    }

}
