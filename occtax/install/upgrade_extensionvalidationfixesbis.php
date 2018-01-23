<?php
class occtaxModuleUpgrader_extensionvalidationfixesbis extends jInstallerModule {

    public $targetVersions = array(
        '2.0.3'
    );
    public $date = '2018-01-23';

    function install() {
        if( $this->firstDbExec() ) {
            // modify jlx_user columns
            $this->useDbProfile('jauth');
            $this->execSQLScript('sql/upgrade/extension_validation_fixes_bis');
        }
    }

}
