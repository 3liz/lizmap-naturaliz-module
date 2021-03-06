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

                // Get local configuration (application name, projects name, list of fields, etc.)
                $localConfig = jApp::configPath('naturaliz.ini.php');
                $ini = new jIniFileModifier($localConfig);

                // TAXON dock
                // Create search form
                //$searchForm = jForms::create("taxon~search");
                //$assign = array(
                    //'form' => $searchForm
                //);
                //$content = array( 'taxon~search', $assign );
                $content = '';

                $dock = new lizmapMapDockItem(
                    'taxon',
                    jLocale::get("taxon~search.dock.title"),
                    $content,
                    9,
                    jUrl::get('jelix~www:getfile', array('targetmodule'=>'taxon', 'file'=>'css/taxon.search.css'))
                );
                $event->add($dock);

                // OCCTAX dock
                $form = jForms::create("occtax~search");
                $cnx = jDb::getConnection();
                $sql = "SELECT min(date_debut)::text AS date_min FROM occtax.observation;";
                $result = $cnx->query( $sql );
                $date_min = '1600-01-01';
                foreach( $result->fetchAll() as $line ) {
                    $date_min = $line->date_min;
                }
                $form->setData('date_min', $date_min);
                $form->setData('date_max', strftime("%Y-%m-%d",strtotime('now')));

                $formUpload = jForms::create("occtax~upload_geojson");

                // Remove some fields via rights
                if (!jAcl2::check("requete.jdd.observation")) {
                    $form->deactivate( 'jdd_id' );
                }
                if (!jAcl2::check("requete.observateur.observation")) {
                    $form->deactivate( 'observateur' );
                }
                if (!jAcl2::check("visualisation.donnees.brutes")) {
                    $form->deactivate( 'validite_niveau' );
                }

                // Remove form fields by config
                $search_form_menace_fields = $ini->getValue('search_form_menace_fields', 'naturaliz');
                if (empty($search_form_menace_fields)) {
                    $search_form_menace_fields = 'menace_nationale, menace_monde';
                }
                $menace_fields = array_map('trim', explode(',', $search_form_menace_fields));
                $all_menace = array('menace_regionale', 'menace_nationale', 'menace_monde');
                foreach ($all_menace as $menace) {
                    if (!in_array($menace, $menace_fields)) {
                        $form->deactivate($menace);
                    }
                }

                // Get configuration for some client side occtax parameters
                // Get local configuration (application name, projects name, etc.)

                $maxAreaQuery = $ini->getValue('maxAreaQuery', 'naturaliz');
                $menuOrder = $ini->getValue('menuOrder', 'naturaliz');
                $srid = $ini->getValue('srid', 'naturaliz');
                $libelle_srid = $ini->getValue('libelle_srid', 'naturaliz');
                $maximum_observation_scale = $ini->getValue('maximum_observation_scale', 'naturaliz');
                if (empty($maxAreaQuery) )
                    $maxAreaQuery = 32000000;
                if (empty($menuOrder) )
                    $menuOrder = 'home, taxon, metadata, switcher, occtax, dataviz, print, measure, permaLink';
                if (empty($srid) )
                    $srid = '2154';
                if (empty($libelle_srid) )
                    $libelle_srid = 'Projection locale';
                if (empty($maximum_observation_scale) )
                    $maximum_observation_scale = 25000;

                // Menaces

                $menuOrder = array_map('trim', explode(',', $menuOrder));
                $mi = 0; $mo = array();
                foreach($menuOrder as $menu){
                    $mo[$menu] = $mi;
                    $mi++;
                }

                $strokeColor = $ini->getValue('strokeColor', 'naturaliz');
                if (empty($strokeColor) )
                    $strokeColor = 'white';
                $colonne_locale = $ini->getValue('colonne_locale', 'naturaliz');
                if (empty($colonne_locale) )
                    $colonne_locale = 'fra';
                $statut_localisations = $ini->getValue('statut_localisations', 'naturaliz');
                if (empty($statut_localisations) )
                    $statut_localisations = $colonne_locale;
                $statut_localisations = array_map('trim', explode(',', $statut_localisations));
                $taxon_detail_source_type = $ini->getValue('taxon_detail_source_type', 'naturaliz');
                if (!in_array($taxon_detail_source_type, array('api', 'url')))
                    $taxon_detail_source_type = 'api';
                $taxon_detail_source_url = $ini->getValue('taxon_detail_source_url', 'naturaliz');
                if (empty($taxon_detail_source_url))
                    $taxon_detail_source_url = '';
                $occtaxClientConfig = array(
                    'colonne_locale'=> $colonne_locale,
                    'maxAreaQuery'=> (integer)$maxAreaQuery,
                    'strokeColor' => $strokeColor,
                    'menuOrder' => $mo,
                    'is_connected' => jAuth::isConnected(),
                    'maximum_observation_scale'=> (integer)$maximum_observation_scale,
                    'statut_localisations'=> $statut_localisations,
                    'taxon_detail_source_type'=> $taxon_detail_source_type,
                    'taxon_detail_source_url'=> $taxon_detail_source_url,
                );

                $mailles_a_utiliser = $ini->getValue('mailles_a_utiliser', 'naturaliz');
                if (!$mailles_a_utiliser or empty(trim($mailles_a_utiliser))) {
                    $mailles_a_utiliser = 'maille_02,maille_10';
                }
                $mailles_a_utiliser = array_map('trim', explode(',', $mailles_a_utiliser));

                $assign = array(
                    'form' => $form,
                    'formUpload' => $formUpload,
                    'occtaxClientConfig' => json_encode($occtaxClientConfig),
                    'mailles_a_utiliser' => $mailles_a_utiliser,
                    'srid' => $srid,
                    'libelle_srid' => $libelle_srid
                );
                $content = array( 'occtax~search', $assign );

                $dock = new lizmapMapDockItem(
                    'occtax',
                    jLocale::get("occtax~search.dock.title"),
                    $content,
                    10,
                    jUrl::get('jelix~www:getfile', array('targetmodule'=>'occtax', 'file'=>'css/occtax.search.css')),

                    Null // JS loaded in occtax default controller
                );
                $event->add($dock);


                // PRESENTATION
                $presentationTpl = new jTpl();
                $presentation = '';
                $projectDescriptionConfig = $ini->getValue('projectDescription', 'naturaliz');
                if (!empty($projectDescriptionConfig)) {
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
                if ($presentationSource) {
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
                if ($legalSource) {
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
                        jUrl::get('jelix~www:getfile', array('targetmodule'=>'occtax', 'file'=>'js/occtax.print.js'))
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
