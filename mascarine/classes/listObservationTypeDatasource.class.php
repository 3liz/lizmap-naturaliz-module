<?php

require_once (JELIX_LIB_PATH.'forms/jFormsDatasource.class.php');

class listObservationTypeDatasource implements jIFormsDatasource
{
  protected $formId = 0;

  protected $data = array();

  function __construct($id)
  {
    $this->formId = $id;
    $mydata = array();
    
    $monfichier = jApp::configPath('mascarine.ini.php');
    $ini = new jIniFileModifier ($monfichier);
    
    $dao = jDao::get('mascarine~nomenclature');
    $types = $dao->findByField('type_obs');
    foreach($dao->findByField('type_obs') as $type) {
        $val = $ini->getValue( $type->code, 'activated_types' );
        if( $val || $val === null )
            $mydata[$type->code] = (string) $type->valeur;
    }
    $this->data = $mydata;
  }

  public function getData($form)
  {
    return $this->data;
  }

  public function getLabel($key)
  {
    if(isset($this->data[$key]))
      return $this->data[$key];
    else
      return null;
  }

}
