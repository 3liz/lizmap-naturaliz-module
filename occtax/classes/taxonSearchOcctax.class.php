<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

jClasses::inc('taxon~taxonSearch');

class taxonSearchOcctax extends taxonSearch{

    protected $tplFields = array(
        'add' => '<a class="addTaxon" href="#" title="{@taxon~search.output.filter.title@}"><i class="icon-plus-sign"></i></a>'
    );

    protected $displayFields = array(
        'nom_valide' => array( 'type' => 'string', 'sortable' => "true"),
        'nom_vern' => array( 'type' => 'string', 'sortable' => "true"),
        'add' => array( 'type' => 'string', 'sortable' => "0")
    );

}
