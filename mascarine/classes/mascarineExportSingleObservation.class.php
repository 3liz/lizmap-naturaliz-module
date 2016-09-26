<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

jClasses::inc('mascarine~mascarineExportObservation');

class mascarineExportSingleObservation extends mascarineExportObservation {

    protected $returnFields = array();

    public function __construct ($id, $params=Null) {

        parent::__construct($id, $params);

    }

}
