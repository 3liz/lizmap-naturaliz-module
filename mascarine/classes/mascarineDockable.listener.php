<?php
class mascarineDockableListener extends jEventListener{

        function onmapDockable ($event) {
            $coord = jApp::coord();
            if ($coord->moduleName == 'mascarine') {

                $project = $event->getParam( 'project' );
                $repository = $event->getParam( 'repository' );
                $lrep = lizmap::getProject( $repository . '~' .$project );
                $configOptions = $lrep->getOptions();
                $bp = jApp::config()->urlengine['basePath'];

                $localConfig = jApp::configPath('localconfig.ini.php');
                $localConfig = new jIniFileModifier($localConfig);
                $srid = $localConfig->getValue('srid', 'naturaliz');

                // Create search form
                $searchForm = jForms::create("mascarine~taxon_search");

                $assign = array(
                    'form' => $searchForm
                );
                $content = array( 'mascarine~taxon_search', $assign );

                $dock = new lizmapMapDockItem(
                    'taxon',
                    jLocale::get("taxon~search.dock.title"),
                    $content,
                    9 ,
                    $bp.'css/taxon.search.css'//,
                    //    $bp.'js/mascarine.search.js'
                );
                $event->add($dock);

                $form = jForms::create("mascarine~search");
                $formUpload = jForms::create("occtax~upload_geojson");
                $formTax = jForms::create("mascarine~taxon_search");

                $assign = array(
                    'form' => $form,
                    'formUpload' => $formUpload,
                    'formTax' => $formTax
                );
                $content = array( 'mascarine~search', $assign );

                $dock = new lizmapMapDockItem(
                    'mascarine',
                    jLocale::get("mascarine~search.dock.title"),
                    $content,
                    10,
                    $bp.'css/mascarine.search.css',
                    $bp.'js/mascarine.search.js'
                );
                $event->add($dock);

                if ( jAcl2::check( 'observation.creer' ) ) {
                    $formWrite = jForms::create("mascarine~draw_write");
                    $datasource = new jFormsStaticDatasource();
                    $datasource->data = array( 'EPSG:4326'=>'EPSG:4326','EPSG:'.$srid=>'EPSG:'.$srid );
                    $formWrite->getControl( 'proj' )->datasource = $datasource;
                    $formWrite->setData( 'proj', 'EPSG:4326' );

                    $formGPX = jForms::create("mascarine~upload_gpx");

                    $assign = array(
                        'formWrite' => $formWrite,
                        'formUpload' => $formGPX
                    );

                    $edit = new lizmapMapDockItem(
                        'mascarine_edit',
                        jLocale::get("mascarine~observation.edit.title"),
                        array( 'mascarine~edit', $assign ),
                        11,
                        $bp.'css/mascarine.edit.css',
                        $bp.'js/mascarine.edit.js'
                    );
                    $event->add($edit);
                }


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

                $wmsInfo['WMSServiceTitle'] = $ini->getValue('projectName', 'mascarine');
                $wmsInfo['WMSServiceAbstract'] = html_entity_decode( $ini->getValue('projectDescription', 'mascarine') );

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
    }
?>
