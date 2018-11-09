<?php
class occtaxViewListener extends jEventListener{

    function onmainviewGetMaps ($event) {
        // Get local configuration (application name, projects name, etc.)
        $localConfig = jApp::configPath('naturaliz.ini.php');
        $ini = new jIniFileModifier($localConfig);

        $defaultRep = $ini->getValue('defaultRepository', 'naturaliz');
        $defaultProject = $ini->getValue('defaultProject', 'naturaliz');

        $request->params['repository'] = $defaultRep;
        $request->params['project'] = $defaultProject;

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
                    $mrep->childItems[] = new lizmapMainViewItem(
                        'occtax_'.$lproj->getData('id'),
                        $projectName,
                        $projectName .'&nbsp;: <br/>'.$projectDescription,
                        $lproj->getData('proj'),
                        $lproj->getData('bbox'),
                        jUrl::get('occtax~default:index'),
                        jUrl::get('view~media:illustration', array("repository"=>$lproj->getData('repository'),"project"=>$lproj->getData('id'))),
                        2,
                        'naturaliz',
                        'map'
                    );
                    $event->add( $mrep );
                }
            }
        }
    }
}
?>
