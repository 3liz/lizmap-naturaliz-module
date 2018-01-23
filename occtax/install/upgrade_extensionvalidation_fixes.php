<?php
class occtaxModuleUpgrader_extensionvalidation extends jInstallerModule {

    public $targetVersions = array(
        '2.0.2'
    );
    public $date = '2018-01-23';

    function install() {
        if( $this->firstDbExec() ) {
            // modify jlx_user columns
            $this->useDbProfile('jauth');
            $this->execSQLScript('sql/extension_validation_fixes');
        }
    }

}
