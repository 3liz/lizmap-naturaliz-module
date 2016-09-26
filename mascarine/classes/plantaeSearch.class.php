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

class plantaeSearch extends taxonSearch{
    
    const sessionPrefix = 'plantaeSearch';

    protected $queryFields = array(
        'regne',
        'cd_ref',
        'group1_inpn',
        'group2_inpn',
        'habitat',
        'statut',
        'rarete',
        'endemicite',
        'invasibilite',
        'menace',
        'menace_monde',
        'protection',
        'det_znieff'
    );
    
    public function __construct ($id, $params=Null) {
        if ( $params != null )
          $params['regne'] = 'Plantae';
        else if ( $params == null && $id == null )
          $params = array('regne' => 'Plantae');
        parent::__construct($id, $params);
    }
}
