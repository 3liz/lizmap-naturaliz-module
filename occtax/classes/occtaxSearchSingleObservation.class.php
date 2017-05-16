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

    private $observation_card_fields = array();

    private $observation_card_children = array();

    public function __construct ($token=Null, $params=Null, $demande=Null) {


        // Limit fields to export (ie to "display in the card" in this class)
        $localConfig = jApp::configPath('localconfig.ini.php');
        $ini = new jIniFileModifier($localConfig);
        if($observation_card_fields = $ini->getValue('observation_card_fields', 'occtax')){
            $this->observation_card_fields = array_map('trim', explode(',', $observation_card_fields));
        }
        if($observation_card_children = $ini->getValue('observation_card_children', 'occtax')){
            $this->observation_card_children = array_map('trim', explode(',', $observation_card_children));
        }

        // Override exported fields
        foreach( $this->exportedFields['principal'] as $field => $type ){
            if(!in_array($field, $this->observation_card_fields)){
                unset($this->exportedFields['principal'][$field]);
            }
        }
        // Remove children
        foreach( $this->exportedFields as $topic => $data ){
            if($topic == 'principal')
                continue;
            if(!in_array($topic, $this->observation_card_children)){
                unset($this->exportedFields[$topic]);
            }
        }

        parent::__construct($token, $params, $demande);

    }

}
