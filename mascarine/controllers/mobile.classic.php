<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    3liz
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class mobileCtrl extends jController {

    // Allow only for high profiles
    public $pluginParams = array(
        '*' => array( 'jacl2.right'=>'observation.creer' )
    );

    // Get login and password from request header and authenticate user
    function __construct( $request ){
        if (isset($_SERVER['PHP_AUTH_USER'])) {
          $ok = jAuth::login($_SERVER['PHP_AUTH_USER'], $_SERVER['PHP_AUTH_PW']);
        }

        parent::__construct( $request );

    }


    /*
     * Export nomenclature, organismes, persons and programs into JSON
     *
     * @return JSON object
     */
    function exportList(){

        $rep = $this->getResponse('json');

        $tables = array(
            'nomenclature' => 'm_nomenclature',
            'organisme' => '(SELECT * FROM organisme ORDER BY nom_org) AS o',
            'personne'  => '(SELECT * FROM personne ORDER BY nom_perso, prenom_perso) AS p',
            'programme' => 'programme',
            'habitat' => 'habitat'
        );

        $data = array();

        // Global options
        $localConfig = jApp::configPath('localconfig.ini.php');
        $ini = new jIniFileModifier($localConfig);
        $srid = $ini->getValue('srid', 'naturaliz');
        $data['config'] = array(
            'srid' => $srid,
            'projectName' => $ini->getValue('projectName', 'mascarine')
        );

        // Data
        foreach( $tables as $item=>$table ){
            $sql = '
                SELECT array_to_json( array_agg( row_to_json( a ) ) ) AS j
                FROM (
                    SELECT *
                    FROM ' . $table . '
                ) a;
            ';
            $cnx = jDb::getConnection();
            $rs = $cnx->query( $sql );
            foreach( $rs as $rec ){
                $json = json_decode( $rec->j );
                if ( $json == null )
                    $data[$item] = array();
                else
                    $data[$item] = $json;
            }
        }

        $rep->data = $data;
        return $rep;

    }



    /*
     * Export taxons index into JSON
     *
     * @return JSON object
     */
    function exportTaxonIndex(){

        $rep = $this->getResponse('json');

        $sql = "
            SELECT array_to_json( array_agg( a.idx ) ) AS j
            FROM (
                SELECT DISTINCT lower( substring(nom_complet from 1 for 2) ) as idx
                FROM taxon.taxref_consolide
                WHERE regne = 'Plantae'
                AND cd_nom = cd_ref
            ) a
        ";
        $cnx = jDb::getConnection();
        $rs = $cnx->query( $sql );
        foreach( $rs as $rec ){
            $json = json_decode( $rec->j );
        }

        $rep->data = $json;
        return $rep;

    }



    /*
     * Export taxons into JSON
     *
     * @return JSON object
     */
    function exportTaxon(){
        $idx = $this->param('idx');
        $filter = '';
        if ( $idx )
            $filter = 'AND lower( substring(nom_complet from 1 for 2) ) = lower(\''.$idx.'\')';

        $rep = $this->getResponse('json');

        $sql = "
            SELECT array_to_json( array_agg( row_to_json( a ) ) ) AS j
            FROM (
                SELECT cd_nom, cd_ref, nom_complet
                FROM taxon.taxref_consolide
                WHERE regne = 'Plantae'
                AND cd_nom = cd_ref
                ".$filter."
            ) a
        ";
        $cnx = jDb::getConnection();
        $rs = $cnx->query( $sql );
        foreach( $rs as $rec ){
            $json = json_decode( $rec->j );
        }

        $rep->data = $json;
        return $rep;

    }



    /*
     * Export observations into JSON
     *
     * @return JSON object
     */
    function exportObservation(){

        $rep = $this->getResponse('json');

        $sql = "
            SELECT array_to_json( array_agg( row_to_json( a ) ) ) AS j
            FROM (
                SELECT o.id_obs, o.date_obs, o.type_obs, pr.nom_prog,
                array_agg( DISTINCT p.nom_perso || ' ' || p.prenom_perso ) AS personnes,
                ST_AsGeoJSON( l.geom, 8) AS geom,
                array_agg( DISTINCT t.nom_complet ) AS taxons
                FROM mascarine.m_observation o
                INNER JOIN mascarine.programme pr ON pr.id_prog = o.id_prog
                INNER JOIN mascarine.localisation_obs l ON l.id_obs = o.id_obs
                INNER JOIN mascarine.personne_obs po ON po.id_obs = o.id_obs
                INNER JOIN mascarine.personne p ON p.id_perso = po.id_perso
                INNER JOIN mascarine.flore_obs f ON f.id_obs = o.id_obs
                INNER JOIN taxon.taxref_consolide t ON t.cd_nom = f.cd_nom
                WHERE TRUE
        ";
        if ( !jAcl2::check( 'observation.valider' ) ){
            $sql.= "
            AND validee_obs IS TRUE
            ";
        }
        $sql.= "
                GROUP BY o.id_obs, o.date_obs, o.type_obs, pr.nom_prog, l.geom
            ) a
        ";
        $cnx = jDb::getConnection();
        $rs = $cnx->query( $sql );
        foreach( $rs as $rec ){
            $json = json_decode( $rec->j );
        }
        if( !$json )
           $json = array();

        $rep->data = $json;
        return $rep;

    }


    /*
     * Export constraints for form inputs
     *
     * @return JSON object
     */
    function exportFormConstraints(){

        $rep = $this->getResponse('json');

        $iniFile = jApp::configPath('mascarine.ini.php');
        $ini = parse_ini_file( $iniFile, true );

        $rep->data = $ini;
        return $rep;

    }



    /*
     * Import observations from JSON file
     * This file can be sent by mobile application
     *
     * @return JSON object
     */
    function importObservation(){
        $rep = $this->getResponse('json');

        $json = $this->param('observation', Null);
        $observation = json_decode( $json );
        if( !$observation ){
            $rep->data = array(
                'status'=> 0,
                'errors'=> 'No observation given !',
                'id_obs'=> Null
            );
            return $rep;
        }

        // Get SRID
        $localConfig = jApp::configPath('localconfig.ini.php');
        $ini = new jIniFileModifier($localConfig);
        $srid = $ini->getValue('srid', 'naturaliz');
        $x = Null; $y = Null;

        // Get forms constraints
        $iniFile = jApp::configPath('mascarine.ini.php');
        $ini =  new jIniFileModifier($iniFile);
        $imports = array();
        $ok = true;

        $simpleForms = array(
            'general'=> array('name'=>'general_obs', 'dao'=> 'observation'),
            'localisation'=> array('name'=>'localisation_obs', 'dao'=>'loc_obs'),
            'station'=> array('name'=>'station_obs', 'dao'=>'station_obs')
        );
        $multiForms = array(
            'personne'=> array('name'=>'personne_obs', 'dao'=> 'perso_obs', 'parentkey'=>'id_obs'),
            'menace'=> array('name'=>'menace_obs', 'dao'=> 'menace_obs', 'parentkey'=>'id_obs'),
            'habitat'=> array('name'=>'habitat_obs', 'dao'=> 'habitat_obs', 'parentkey'=>'id_obs'),
            'flore' => array('name'=>'flore_obs', 'dao'=> 'flore_obs', 'key'=>'id_flore_obs', 'parentkey'=>'id_obs',
                'children' => array(
                    'pheno' => array('name'=>'pheno_flore_obs', 'dao'=> 'pheno_flore_obs', 'parentkey'=>'id_flore_obs'),
                    'pop' => array('name'=>'pop_flore_obs', 'dao'=> 'pop_flore_obs', 'parentkey'=>'id_flore_obs')
                )
            )
        );

        $id_obs = $observation->id_obs;
        $db_id = Null;
        $type_obs = $observation->type_obs;
        $import = array();
        $records = array();
        $ok = True;
        $import['errors'] = array();
        $import['db_id'] = Null;
        $import['mobile_id'] = $id_obs;
        $obs = $observation->data;

        if( property_exists($observation, 'db_id') and intval($observation->db_id) > 0 ){
            $import['errors'][] = 'Observation has already been imported';
            $ok = False;
            $rep->data = array(
                'status'=> 0,
                'errors'=> $import['errors'],
                'id_obs'=> $id_obs
            );
            jLog::log(json_encode($import));
            return $rep;
        }

        // Check if observation already exists for this id
        $cacheId = 'mascarine_observation_import_' . $id_obs;
        $db_id_prev = jCache::get($cacheId);
        $dao = jDao::get('observation');
        if( $db_id_prev and $dao->get($db_id_prev) ){
            $import['errors'][] = 'Observation already exists in database';
            $ok = False;
            $rep->data = array(
                'status'=> 0,
                'errors'=> $import['errors'],
                'id_obs'=> $id_obs
            );
            jLog::log(json_encode($import));
            return $rep;
        }

        // Simple forms: general, localisation, station
        foreach( $simpleForms as $key=>$formConfig){
            $formData = $obs->$formConfig['name'];
            $return = $this->createDaoRecordFromJson(
                $type_obs,
                $formConfig['name'],
                $formData,
                $formConfig['dao']
            );
            $ok = $return['ok'];
            $import['errors'] = array_merge( $return['errors'], $import['errors'] );
            if( !$ok )
                break;

            // Insert record
            $dao = jDao::get( $formConfig['dao'] );
            if( $db_id )
                $return['record']->id_obs = $db_id;
            try{
                try{
                    $dao->insert( $return['record'] );
                    if( !$db_id )
                        $db_id = $return['record']->id_obs;
                    // For localisation, hardcode the geometry update
                    if( $key == 'localisation' ){
                        $geo_wkt = $formData->geo_wkt;
                        $x = $formData->coord_x;
                        $y = $formData->coord_y;
                        $dao->updateGeomFromText($return['record']->id_obs, $geo_wkt, 4326, $srid);
                    }
                }catch( Exception $e){
                    $import['errors'][] = 'Error saving observation : '.$formConfig['name'] . ' - '.$e->getMessage();
                    $ok = False;
                }
            }catch( Exception $e ){
                $import['errors'][] = 'Error saving observation : '.$formConfigChild['name'];
                $ok = False;
            }
            if( !$ok )
                break;
        }

        // Multi forms: personne, menace, habitat
        foreach( $multiForms as $key=>$formConfig){
            if( !$ok )
                break;
            $records[$formConfig['name']] = array();
            foreach( $obs->$formConfig['name'] as $data ){
                if( !$ok )
                    break;

                // Build record
                $return = $this->createDaoRecordFromJson(
                    $type_obs,
                    $formConfig['name'],
                    $data,
                    $formConfig['dao']
                );
                $ok = $return['ok'];
                $import['errors'] = array_merge( $return['errors'], $import['errors'] );
                if( !$ok )
                    break;

                // Insert record
                $dao = jDao::get( $formConfig['dao'] );
                if( $db_id )
                    $return['record']->id_obs = $db_id;
                try{
                    if( $dao->insert( $return['record'] ) ){
                        if( !$db_id )
                            $db_id = $return['record']->id_obs;
                    }else{
                        $import['errors'][] = 'Error saving observation : '.$formConfig['name'];
                        $ok = False;
                    }
                }catch( Exception $e ){
                    $import['errors'][] = 'Error saving observation : '.$formConfigChild['name'];
                    $ok = False;
                }
                if( !$ok )
                    break;

                // Store created key
                if( array_key_exists( 'key', $formConfig ) ){
                    $parentkey = $return['record']->$formConfig['key'];
                }

                // Children (only for flore at present)
                if( array_key_exists( 'children', $formConfig ) ){
                    // Get cd_nom (a bit hard-coded here...)
                    $cd_nom = $return['record']->cd_nom;
                    $strate_flore = $return['record']->strate_flore;

                    foreach( $formConfig['children'] as $keyChild=>$formConfigChild){
                        if( !$ok )
                            break;
                        $dao = jDao::get( $formConfigChild['dao'] );
                        foreach( $data->$formConfigChild['name'] as $dataChild ){
                            if( !$ok )
                                break;

                            $return = $this->createDaoRecordFromJson(
                                $type_obs, $formConfigChild['name'],
                                $dataChild,
                                $formConfigChild['dao']
                            );
                            $ok = $return['ok'];
                            $import['errors'] = array_merge( $return['errors'], $import['errors'] );
                            if( !$ok )
                                break;

                            // insert
                            $return['record']->cd_nom = $cd_nom; // hard-coded :(
                            $return['record']->strate_flore = $strate_flore; // hard-coded :(
                            $return['record']->$formConfigChild['parentkey'] = $parentkey;
                            if( $db_id )
                                $return['record']->id_obs = $db_id;

                            try{
                                if( !($dao->insert( $return['record'] ) ) ){
                                    $import['errors'][] = 'Error saving observation : '.$formConfigChild['name'];
                                    $ok = False;
                                }
                            }catch( Exception $e ){
                                $import['errors'][] = 'Error saving observation : '.$formConfigChild['name'];
                                $ok = False;
                            }
                        }
                    }
                }

            }
        }

        // Add maille and commune
        if( $ok and $x and $y ){

            // Get helper class
            jClasses::inc('occtax~occtaxGeometryChecker');
            $mgc = new occtaxGeometryChecker($x, $y, $srid, 'mascarine');

            // Commune
            $getCommune = $mgc->getCommune();
            if( $getCommune[ 'status' ] == 0 ){
                $import['errors'] = array_merge( $import['errors'], $getCommune[ 'msg' ]);
                $ok = False;
            }

            // Maille
            $getMaille = $mgc->getMaille();
            if( $getMaille[ 'status' ] == 0 ){
                $import['errors'] = array_merge( $import['errors'], $getMaille[ 'msg' ]);
                $ok = False;
            }

            if( $ok ) {
                // Get localisation object
                $dao_loc = jDao::get('loc_obs');
                $loc = $dao_loc->getByObs($db_id);

                // Update data
                $loc->code_commune = $getCommune[ 'result' ]->code_commune;
                $loc->code_maille = $getMaille[ 'result' ]->code_maille;
                $dao_loc->update($loc);

            }
        }

        // In case of errors in the process, delete all data
        if( !$ok ){
            $dao = jDao::get('observation');
            $dao->delete( $db_id );
            $rep->data = array(
                'status'=> 0,
                'errors'=> $import['errors'],
                'id_obs'=> $id_obs
            );
            jLog::log( 'Errors occured while importing observation - deleting db_id=' . $db_id );
            jLog::log(json_encode($import));
            return $rep;
        }

        // Save correspondance between mobile obs id and saved obs id
        $key = 'mascarine_observation_import_' . $id_obs;
        $cacheExpiration = 5;
        jCache::set( $key, $db_id, $cacheExpiration );
        jLog::log('Observation has been imported: mobile id=' . $id_obs . ' , db_id=' . $db_id);

        // Return success data
        $rep->data = array(
            'status'=> 1,
            'errors'=> Null,
            'id_obs'=> $id_obs,
            'db_id'=>$db_id
        );
        return $rep;

    }

    private function createDaoRecordFromJson( $type_obs, $formName, $formData, $dao ){

        $return = array();
        $return['ok'] = true;
        $return['errors'] = array();
        $return['record'] = Null;

        $iniFile = jApp::configPath('mascarine.ini.php');
        $ini =  new jIniFileModifier($iniFile);

        if( $ini->getValue( $type_obs, 'form:'.$formName ) != 'deactivate' ){
            $record = jDao::createRecord( $dao );
            foreach( $formData as $ref=>$value ){

                $conf = $ini->getValue(
                    $type_obs.'.'.$ref,
                    'form:'.$formName
                );

                if( $conf == 'required' and empty($value) ){
                    $ok = false;
                    $return['ok'] = false;
                    $return['errors'][] = "No value given for a required field: ".$ref;
                    break;
                }

                if( $conf != 'deactivate' and !empty($value) and property_exists( $record, $ref) ){
                    $record->$ref = $value;
                }

            }
            // Remove obs id for general_obs
            if( array_key_exists('id_obs', $formData)  )
                $record->id_obs = Null;

            $return['record'] = $record;
        }

        return $return;

    }

}
