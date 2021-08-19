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

    protected $name = 'single';

    protected $observation_card_fields = array();

    protected $observation_card_fields_unsensitive = array();

    protected $observation_card_children = array();

    protected $observation_exported_children_unsensitive = array();

    public function __construct ($token=Null, $params=Null, $demande=Null, $login=Null) {
        $this->login = $login;

        // Limit fields to export (ie to "display in the card" in this class)
        $children = 'observation_exported_children';
        if( !jAcl2::checkByUser($login, "visualisation.donnees.brutes") ){
            $children = 'observation_exported_children_unsensitive';
        }
        $this->limitFields(
            'observation_card_fields',
            'observation_card_fields_unsensitive',
            $children
        );

        parent::__construct($token, $params, $demande, $login);

    }

    public function getExportedFields( $topic, $format='name' ) {
        $exported_fields = parent::getExportedFields($topic, $format);
        if ($topic == 'principal') {
            $exported_fields[] = 'geojson';
        }
        return $exported_fields;
    }

    // We need to override the getData
    // Since this parent function now uses a file to avoid memory issues
    function getData( $limit=50, $offset=0, $order="" ) {
        list($handler, $path) = parent::getData($limit, $offset, $order);
        $json = jFile::read($path);
        $json = str_replace('{"data": ', '', $json);
        $json = str_replace(']],', ']]', $json);
        fclose($handler);
        unlink($path);

        return json_decode($json);
    }

}
