<?php

require_once (JELIX_LIB_PATH.'forms/jFormsDatasource.class.php');
jClasses::inc('admin~listProjectDatasource');

class listOcctaxProjectDatasource extends listProjectDatasource
{


  public function getData($form)
  {
    $pdata = array();
    $criteria = $form->getData($this->criteriaFrom);
    if ( $criteria && array_key_exists($criteria, $this->data ) ) {
        $rep = lizmap::getRepository( $criteria );
        $projects = $rep->getProjects();
        foreach ($projects as $p) {
            // We do not want to avoid hidden project, because the project base for naturaliz is hidden.
            // if it is planed to restore this code, and if the module will be
            // compatible only with Lizmap 3.5+, use $p->getBooleanOption('hideProject')
            //$pOptions = $p->getOptions();
            //if (property_exists($pOptions,'hideProject') && $pOptions->hideProject == 'True')
                //continue;
            $pdata[ $p->getData('id') ] = (string)  $p->getData('title');
        }
    }
    return $pdata;
  }

}
