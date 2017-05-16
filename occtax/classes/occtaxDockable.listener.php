<?php
    class occtaxDockableListener extends jEventListener{

        function onmapDockable ($event) {
            $coord = jApp::coord();
            if ($coord->moduleName == 'occtax') {
                $project = $event->getParam( 'project' );
                $repository = $event->getParam( 'repository' );
                $lproj = lizmap::getProject( $repository . '~' .$project );
                $configOptions = $lproj->getOptions();
                $bp = jApp::config()->urlengine['basePath'];

                // TAXON dock
                // Create search form
                $searchForm = jForms::create("taxon~search");

                $assign = array(
                    'form' => $searchForm
                );
                $content = array( 'taxon~search', $assign );

                $dock = new lizmapMapDockItem(
                    'taxon',
                    jLocale::get("taxon~search.dock.title"),
                    $content,
                    9,
                    $bp.'css/taxon.search.css'
                    //~ $bp.'taxon/taxon.js'
                );
                $event->add($dock);

                // OCCTAX dock
                $form = jForms::create("occtax~search");
                $formUpload = jForms::create("occtax~upload_geojson");
                $formTax = jForms::create("taxon~search");

                // Remove some fields via rights
                if( !jAcl2::check("requete.jdd.observation") ){
                    $form->deactivate( 'jdd_id' );
                }
                if( !jAcl2::check("requete.observateur.observation") ){
                    $form->deactivate( 'observateur' );
                }
                if( !jAcl2::check("visualisation.donnees.brutes") ){
                    $form->deactivate( 'validite_niveau' );
                }

                // Get configuration for some client side occtax parameters
                // Get local configuration (application name, projects name, etc.)
                $localConfig = jApp::configPath('localconfig.ini.php');
                $ini = new jIniFileModifier($localConfig);
                $maxAreaQuery = $ini->getValue('maxAreaQuery', 'occtax');
                if( empty($maxAreaQuery) )
                    $maxAreaQuery = 32000000;
                $occtaxClientConfig = array(
                    'maxAreaQuery'=> (integer)$maxAreaQuery
                );

                $assign = array(
                    'form' => $form,
                    'formUpload' => $formUpload,
                    'formTax' => $formTax,
                    'occtaxClientConfig' => json_encode($occtaxClientConfig)
                );
                $content = array( 'occtax~search', $assign );

                $dock = new lizmapMapDockItem(
                    'occtax',
                    jLocale::get("occtax~search.dock.title"),
                    $content,
                    10,
                    $bp.'css/occtax.search.css',
                    $bp.'js/occtax.search.js'
                );
                $event->add($dock);


                // OVERRIDE METADATA
                $metadataTpl = new jTpl();
                // Get the WMS information
                $wmsInfo = $lproj->getWMSInformation();
                // WMS GetCapabilities Url
                $wmsGetCapabilitiesUrl = jAcl2::check(
                    'lizmap.tools.displayGetCapabilitiesLinks',
                    $repository
                );
                if ( $wmsGetCapabilitiesUrl ) {
                    $wmsGetCapabilitiesUrl = $lproj->getData('wmsGetCapabilitiesUrl');
                }

                // Get local configuration (application name, projects name, etc.)
                $localConfig = jApp::configPath('localconfig.ini.php');
                $ini = new jIniFileModifier($localConfig);

                // Get description
                //$wmsInfo['WMSServiceTitle'] = $ini->getValue('projectName', 'occtax');
                $projectDescription = '';
                $projectDescriptionConfig = $ini->getValue('projectDescription', 'occtax');
                if( !empty($projectDescriptionConfig) ){
                    $projectDescription = html_entity_decode( $projectDescriptionConfig );
                }

                // Read file beside QGIS project if existing and override previous description
                $presentation = jFile::read( $lproj->getQgisPath() . '.presentation.html');
                $legal = jFile::read( $lproj->getQgisPath() . '.legal.html');
                $dtpl = new jTpl();
                $dassign = array(
                    'presentation' => $presentation,
                    'legal' => $legal
                );
                $dtpl->assign($dassign);
                if( $presentation or $legal ){
                    $projectDescription = $dtpl->fetch('application_metadata');
                }

                // Put dynamic content in WMSServiceTitle
                // (not in abstract to avoid autoreplacement of line break with <br>
                // The occtax.js Javascript will use this as a source to replace #metadata content
                $wmsInfo['WMSServiceTitle'] = '<div id="occtax-metadata">'.$projectDescription.'</div>';

                $metadataTpl->assign(array_merge(array(
                    'repository'=>$repository,
                    'project'=>$lproj->getKey(),
                    'wmsGetCapabilitiesUrl' => $wmsGetCapabilitiesUrl
                ), $wmsInfo));
                $dock = new lizmapMapDockItem(
                    'metadata',
                    jLocale::get('view~map.metadata.link.label'),
                    $metadataTpl->fetch('view~map_metadata'),
                    2
                );
                $event->add($dock);

            }
        }


        function onmapMiniDockable ( $event ) {
            $coord = jApp::coord();
            if ($coord->moduleName == 'occtax') {
                $project = $event->getParam( 'project' );
                $repository = $event->getParam( 'repository' );
                $lproj = lizmap::getProject( $repository . '~' .$project );
                $configOptions = $lproj->getOptions();
                $bp = jApp::config()->urlengine['basePath'];

                // Override lizmap default print dock
                if ( property_exists($configOptions,'print')
                    && $configOptions->print == 'True') {

                    $tpl = new jTpl();
                    $dock = new lizmapMapDockItem(
                        'print',
                        jLocale::get('view~map.print.navbar.title'),
                        $tpl->fetch('view~map_print'),
                        3,
                        Null,
                        $bp.'js/occtax.print.js'
                    );
                    $event->add($dock);
                }
            }

        }

        function onmapRightDockable ( $event ) {

        }


        function onmapBottomDockable ( $event ) {
            $coord = jApp::coord();
            if ($coord->moduleName == 'occtax') {
                $project = $event->getParam( 'project' );
                $repository = $event->getParam( 'repository' );
                $lproj = lizmap::getProject( $repository . '~' .$project );
                $configOptions = $lproj->getOptions();
                $bp = jApp::config()->urlengine['basePath'];


                // OCCTAX bottom dock
                $assign = array(
                );
                $content = array( 'occtax~results', $assign );

                $dock = new lizmapMapDockItem(
                    'occtax_tables',
                    jLocale::get("occtax~search.dock.title"),
                    $content,
                    10,
                    NULL,
                    NULL
                );
                $event->add($dock);
            }

        }

    }

?>
