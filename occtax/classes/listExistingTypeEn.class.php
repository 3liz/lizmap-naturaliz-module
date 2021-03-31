<?php
/**
* @package   lizmap
* @subpackage taxon
* @author    3liz
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class listExistingTypeEn implements jIFormsDatasource
{
  protected $formId = 0;

  protected $datas = array();

  function __construct($id)
  {
    $this->formId = $id;
    $cnx = jDb::getConnection('naturaliz_virtual_profile');
    $sql = "
        SELECT DISTINCT n.code, n.valeur
        FROM occtax.nomenclature n
        LEFT JOIN sig.espace_naturel en ON en.type_en = n.code
        WHERE TRUE
        AND en.code_en IS NOT NULL
        ORDER BY n.valeur
    ";
    $res = $cnx->query($sql);
    $data = array();
    foreach( $res as $line ) {
        $data[$line->code] = $line->valeur;
    }
    $this->datas = $data;
  }

  public function getData($form)
  {
    return ($this->datas);
  }

  public function getLabel($key)
  {
    if(isset($this->datas[$key]))
      return $this->datas[$key];
    else
      return null;
  }

}
