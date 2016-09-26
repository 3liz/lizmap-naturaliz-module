<?php
    class occtaxDockableListener extends jEventListener{

        function onmapDockable ($event) {
            $coord = jApp::coord();
            if ($coord->moduleName == 'occtax') {
                $project = $event->getParam( 'project' );
                $repository = $event->getParam( 'repository' );
                $lrep = lizmap::getProject( $repository . '~' .$project );
                $configOptions = $lrep->getOptions();
                $bp = jApp::config()->urlengine['basePath'];

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

                $assign = array(
                    'form' => $form,
                    'formUpload' => $formUpload,
                    'formTax' => $formTax
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
                $wmsInfo = $lrep->getWMSInformation();
                // WMS GetCapabilities Url
                $wmsGetCapabilitiesUrl = jAcl2::check(
                    'lizmap.tools.displayGetCapabilitiesLinks',
                    $repository
                );
                if ( $wmsGetCapabilitiesUrl ) {
                    $wmsGetCapabilitiesUrl = $lrep->getData('wmsGetCapabilitiesUrl');
                }

                // Get local configuration (application name, projects name, etc.)
                $localConfig = jApp::configPath('localconfig.ini.php');
                $ini = new jIniFileModifier($localConfig);

                $wmsInfo['WMSServiceTitle'] = $ini->getValue('projectName', 'occtax');
                $wmsInfo['WMSServiceAbstract'] = html_entity_decode( $ini->getValue('projectDescription', 'occtax') );

                $metadataTpl->assign(array_merge(array(
                    'repository'=>$repository,
                    'project'=>$lrep->getKey(),
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
                $lrep = lizmap::getProject( $repository . '~' .$project );
                $configOptions = $lrep->getOptions();
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
    }

?>
