<?php
class occtaxModuleUpgrader_extensionvalidation extends jInstallerModule {

    public $targetVersions = array(
        '2.0.1'
    );
    public $date = '2017-11-17';

    function install() {
        if( $this->firstDbExec() ) {
            // modify jlx_user columns
            $this->useDbProfile('jauth');
            $this->execSQLScript('sql/extension_validation');
        }
    }

}
