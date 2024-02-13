<?php
class occtaxModuleUpgrader_2_11_2__2_11_3 extends jInstallerModule {

    public $targetVersions = array(
        '2.11.3',
    );
    public $date = '2022-03-21';

    function install() {
        if ($this->firstDbExec()) {
            // Read the ini file
            $localConfig = jApp::varConfigPath('naturaliz.ini.php');
            $ini = new Jelix\IniFile\IniModifier($localConfig);

            // Add naturaliz_file cache profile
            \jFile::createDir(jApp::varPath('uploads/cache'));
            $profile_ini = new \Jelix\IniFile\IniModifier(jApp::varConfigPath('profiles.ini.php'));
            $profile_ini->setValue('driver', 'file', 'jcache:naturaliz_file_cache' );
            $profile_ini->setValue('ttl', '0', 'jcache:naturaliz_file_cache' );
            $profile_ini->setValue('enabled', '1', 'jcache:naturaliz_file_cache' );
            $profile_ini->setValue('cache_dir', 'var:cache/', 'jcache:naturaliz_file_cache' );
            $profile_ini->setValue('file_locking', '1', 'jcache:naturaliz_file_cache' );
            $profile_ini->setValue('directory_level', '0', 'jcache:naturaliz_file_cache' );
            $profile_ini->save();

        }
    }
}
