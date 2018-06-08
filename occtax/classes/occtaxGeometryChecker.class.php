<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class occtaxGeometryChecker {

    protected $x = Null;
    protected $y = Null;
    protected $srid = Null;
    protected $moduleName = Null;

    function __construct($x, $y, $srid, $moduleName, $type_maille=null){

        $this->x = $x;
        $this->y = $y;
        $this->srid = $srid;
        $this->moduleName = $moduleName;
        $this->type_maille = $type_maille;

    }

    function checkInput() {
        $msg = array();

        // Get x and y params
        if (!$this->x || !$this->y) {
            $msg[] = 'params invalid';
        }
        if ($this->x > 180.0 || $this->x < -180.0) {
            $msg[] = 'x invalid';
        }
        if ($this->y > 90.0 || $this->y < -90.0) {
            $msg[] = 'x invalid';
        }

        return $msg;

    }

    function getCommune() {

        // Define object to return
        $return = array(
            'status' => 0,
            'msg' => array()
        );

        // Check X and Y
        $return['msg'] = $this->checkInput();
        if( count($return['msg']) > 0 )
            return $return;

        $sql = 'SELECT c.code_commune, c.nom_commune, ST_AsGeoJSON( ST_Transform(c.geom, 4326), 8 ) AS geojson';
        $sql.= ' FROM commune c';
        $sql.= ', ( SELECT ST_Transform(ST_SetSRID(ST_MakePoint('.$this->x.', '.$this->y.'),4326), '. $this->srid .') as geom ) as tgeo';
        $sql.= ' WHERE ST_Within( tgeo.geom, c.geom )';
//~ jLog::log($sql);
        $cnx = jDb::getConnection();
        $result = $cnx->limitQuery( $sql, 0, 1 );
        $d = $result->fetch();
        if ( $d ) {
            $d->geojson = json_decode( $d->geojson );
            $return['status'] = 1;
            $return['result'] = $d;
        } else {
            $return['msg'][] = jLocale::get( $this->moduleName . '~search.getCommune.error' );
        }

        // Return data
        return $return;
    }


    function getMasseEau() {

        // Define object to return
        $return = array(
            'status' => 0,
            'msg' => array()
        );

        // Check X and Y
        $return['msg'] = $this->checkInput();
        if( count($return['msg']) > 0 )
            return $return;

        $sql = 'SELECT me.code_me, me.nom_me, ST_AsGeoJSON( ST_Transform(me.geom, 4326), 8 ) AS geojson';
        $sql.= ' FROM masse_eau me';
        $sql.= ', ( SELECT ST_Transform(ST_SetSRID(ST_MakePoint('.$this->x.', '.$this->y.'),4326), '. $this->srid .') as geom ) as tgeo';
        $sql.= ' WHERE ST_Within( tgeo.geom, me.geom )';
//~ jLog::log($sql);
        $cnx = jDb::getConnection();
        $result = $cnx->limitQuery( $sql, 0, 1 );
        $d = $result->fetch();
        if ( $d ) {
            $d->geojson = json_decode( $d->geojson );
            $return['status'] = 1;
            $return['result'] = $d;
        } else {
            $return['msg'][] = jLocale::get( $this->moduleName . '~search.getMasseEau.error' );
        }

        // Return data
        return $return;
    }

    function getMaille() {

        // Define object to return
        $return = array(
            'status' => 0,
            'msg' => array()
        );

        // Check X and Y
        $return['msg'] = $this->checkInput();
        if( count($return['msg']) > 0 )
            return $return;

        $maille = 'maille_02';
        if ( $this->type_maille == 'm01' and jAcl2::check("visualisation.donnees.maille_01") ){
          $maille = 'maille_01';
        }
        //if( $this->type_maille == 'm05')
            //$maille = 'maille_05';
        if( $this->type_maille == 'm10')
            $maille = 'maille_10';

        if($this->moduleName == 'occtax'){
            $sql = 'SELECT m.code_maille, m.nom_maille, ST_AsGeoJSON(ST_Transform( m.geom , 4326)) AS geojson ';
            $sql.= ' FROM '.$maille.' m';
            $sql.= ', (SELECT ST_Transform(ST_SetSRID(ST_MakePoint('.$this->x.', '.$this->y.'),4326), '. $this->srid .') as geom) as tgeo';
            $sql.= ', observation o';
            $sql.= ' JOIN observation_diffusion od ON od.cle_obs = o.cle_obs';
            $sql.= ' WHERE True';
            $sql.= ' AND ST_Within( tgeo.geom, m.geom )';
            $sql.= ' AND ST_Intersects( o.geom, m.geom )';
            $sql.= " AND ( od.diffusion ? 'g' OR od.diffusion ? '" . $this->type_maille . "' )";
        }
        if($this->moduleName == 'mascarine'){
            $sql = 'SELECT m.code_maille, m.nom_maille, ST_AsGeoJSON(ST_Transform( m.geom , 4326)) AS geojson ';
            $sql.= ' FROM '.$maille.' m';
            $sql.= ', (SELECT ST_Transform(ST_SetSRID(ST_MakePoint('.$this->x.', '.$this->y.'),4326), '. $this->srid .') as geom) as tgeo';
            $sql.= ' WHERE ST_Within( tgeo.geom, m.geom )';
        }

//jLog::log($sql);
        $cnx = jDb::getConnection();
        $result = $cnx->limitQuery( $sql, 0, 1 );
        $d = $result->fetch();

        if ( $d ) {
            $d->geojson = json_decode( $d->geojson );
            $return['status'] = 1;
            $return['result'] = $d;
        } else {
            $return['msg'][] = jLocale::get( $this->moduleName . '~search.getMaille.error' );
        }

        // Return data
        return $return;
    }


}
