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
                $menuOrder = $ini->getValue('menuOrder', 'occtax');
                if( empty($maxAreaQuery) )
                    $maxAreaQuery = 32000000;
                if( empty($menuOrder) )
                    $menuOrder = 'home, taxon, metadata, switcher, occtax, dataviz, print, measure, permaLink';

                $menuOrder = array_map('trim', explode(',', $menuOrder));
                $mi = 0; $mo = array();
                foreach($menuOrder as $menu){
                    $mo[$menu] = $mi;
                    $mi++;
                }
                $occtaxClientConfig = array(
                    'maxAreaQuery'=> (integer)$maxAreaQuery,
                    'menuOrder' => $mo
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



                // Get local configuration (application name, projects name, etc.)
                $localConfig = jApp::configPath('localconfig.ini.php');
                $ini = new jIniFileModifier($localConfig);

                // PRESENTATION
                $presentationTpl = new jTpl();
                $presentation = '';
                $projectDescriptionConfig = $ini->getValue('projectDescription', 'occtax');
                if( !empty($projectDescriptionConfig) ){
                    $presentation = html_entity_decode( $projectDescriptionConfig );
                }

                // Read file beside QGIS project if existing
                // This overrides previous presentation !!
                $presentationSource = jFile::read( $lproj->getQgisPath() . '.presentation.html');
                $dtpl = new jTpl();
                $dassign = array(
                    'presentation' => $presentationSource
                );
                $dtpl->assign($dassign);
                if( $presentationSource ){
                    $presentation = $dtpl->fetch('presentation');
                }

                // Add presentation dock only if we have data
                if(!empty($presentation)){
                    $dock = new lizmapMapDockItem(
                        'occtax-presentation',
                        'Présentation',
                        $presentation,
                        2
                    );
                    $event->add($dock);
                }


                // MENTIONS LEGALES
                $legal = '';
                $legalSource = jFile::read( $lproj->getQgisPath() . '.legal.html');
                $dtpl = new jTpl();
                $dassign = array(
                    'legal' => $legalSource
                );
                $dtpl->assign($dassign);
                if( $legalSource ){
                    $legal = $dtpl->fetch('mentions_legales');
                }
                if(!empty($legal)){
                    $dock = new lizmapMapDockItem(
                        'occtax-legal',
                        'Mentions légales',
                        $legal,
                        2
                    );
                    $event->add($dock);
                }
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
            //$coord = jApp::coord();
            //if ($coord->moduleName == 'occtax') {
                //$project = $event->getParam( 'project' );
                //$repository = $event->getParam( 'repository' );
                //$lproj = lizmap::getProject( $repository . '~' .$project );
                //$configOptions = $lproj->getOptions();
                //$bp = jApp::config()->urlengine['basePath'];

                //$assign = array(
                //);
                //$content = array( 'occtax~results', $assign );

                //$dock = new lizmapMapDockItem(
                    //'occtax_tables',
                    //jLocale::get("occtax~search.dock.title"),
                    //$content,
                    //10,
                    //NULL,
                    //NULL
                //);
                //$event->add($dock);
            //}

        }

    }

?>
