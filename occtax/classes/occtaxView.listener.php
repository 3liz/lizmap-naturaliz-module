<?php
class occtaxViewListener extends jEventListener{

    function onmainviewGetMaps ($event) {
        // Get local configuration (application name, projects name, etc.)
        $localConfig = jApp::varConfigPath('naturaliz.ini.php');
        $ini = new \Jelix\IniFile\IniModifier($localConfig);

        $defaultRep = $ini->getValue('defaultRepository', 'naturaliz');
        $defaultProject = $ini->getValue('defaultProject', 'naturaliz');

        $applicationName = $ini->getValue('appName', 'naturaliz');
        $projectName = $ini->getValue('projectName', 'naturaliz');
        $projectDescription = html_entity_decode($ini->getValue('projectDescription', 'naturaliz') );

        if ( $defaultRep && $defaultProject ) {
            $lrep = lizmap::getRepository( $defaultRep );
            if ( $lrep ) {
                $lproj = lizmap::getProject($defaultRep.'~'.$defaultProject);
                if ( $lproj ) {
                    jClasses::inc('lizmapMainViewItem');
                    $mrep = new lizmapMainViewItem('app_naturaliz', $applicationName);

                    // Get Lizmap version
                    $xmlPath = jApp::appPath('project.xml');
                    $xmlLoad = simplexml_load_file($xmlPath);
                    $version = (string) $xmlLoad->info->version;
                    $exp_version = explode('.', $version);
                    $major = (integer) $exp_version[0];
                    $minor = (integer) $exp_version[1];

                    // Return different array depending on Lizmap version
                    if ($major < 3 || ($major = 3 && $minor <= 3)) {
                        $mrep->childItems[] = new lizmapMainViewItem(
                            'occtax_'.$lproj->getData('id'),
                            $projectName,
                            $projectName.'&nbsp;: <br/>'.$projectDescription,
                            $lproj->getData('proj'),
                            $lproj->getData('bbox'),
                            jUrl::get('occtax~default:index'),
                            jUrl::get('view~media:illustration', array("repository"=>$lproj->getData('repository'),"project"=>$lproj->getData('id'))),
                            2,
                            'naturaliz',
                            'map'
                        );
                    } else {
                        $mrep->childItems[] = new lizmapMainViewItem(
                            'occtax_'.$lproj->getData('id'),
                            $projectName,
                            $projectName.'&nbsp;: <br/>'.$projectDescription,
                            '', // keywords added here in LWC 3.4
                            $lproj->getData('proj'),
                            $lproj->getData('bbox'),
                            jUrl::get('occtax~default:index'),
                            jUrl::get('view~media:illustration', array("repository"=>$lproj->getData('repository'),"project"=>$lproj->getData('id'))),
                            2,
                            'naturaliz',
                            'map'
                        );
                    }

                    // Add response
                    $event->add( $mrep );
                }
            }
        }
    }
}
?>
