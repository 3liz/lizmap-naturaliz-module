<?php

class datatableZone extends jZone {

    protected $_tplname='datatable';

    protected function _prepareTpl(){
        $classId = $this->param('classId');
        $classModule = 'taxon';
        $className = $classId;

        $match = preg_match('/(?P<classModule>\w+)~(?P<className>\w+)/', $classId, $matches);
        if ( $match == 1 && $matches['classModule'] != null ) {
            $classModule = $matches['classModule'];
            $className = $matches['className'];
        }

        $localeModule = $this->param('localeModule');
        if ( !$localeModule )
          $localeModule = $classModule;

        jClasses::inc( $classId );
        // Get taxonSearch instance
        $search = new $className( $this->param('objectId') );

        $this->_tpl->assign('tableId', $this->param('tableId'));
        $this->_tpl->assign('localeModule', $localeModule);
        $this->_tpl->assign('fields', $search->getFields());
     }

}
