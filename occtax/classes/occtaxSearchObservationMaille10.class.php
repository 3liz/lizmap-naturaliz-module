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

class occtaxSearchObservationMaille10 extends occtaxSearchObservationMaille {

    protected $maille = 'maille_10';

    public function __construct ($token=Null, $params=Null, $demande=Null, $login=Null) {
        $this->login = $login;
        parent::__construct($token, $params, $demande, $login);
    }

}
