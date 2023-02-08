<?php
/**
* @package   lizmap
* @subpackage occtax
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
    protected $code = Null;
    protected $type_maille = Null;

    function __construct($x, $y, $srid, $moduleName, $type_maille=null, $code=Null){

        $this->x = $x;
        $this->y = $y;
        $this->srid = $srid;
        $this->moduleName = $moduleName;
        $this->type_maille = $type_maille;
        $this->code = trim($code);

    }

    function checkInput() {
        $msg = array();
        if (empty($this->code)) {
            // Get x and y params
            if (!$this->x || !$this->y) {
                $msg[] = 'params invalid';
            }
            if ($this->x > 180.0 || $this->x < -180.0) {
                $msg[] = 'x invalid';
            }
            if ($this->y > 90.0 || $this->y < -90.0) {
                $msg[] = 'y invalid';
            }
        } else {
            if (!preg_match('#^[a-zA-Z0-9]+$#', $this->code) ) {
                $msg[] = 'code invalid';
            }
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

        $cnx = jDb::getConnection('naturaliz_virtual_profile');
        $sql = 'SELECT c.code_commune, c.nom_commune, ST_AsGeoJSON( ST_Transform(c.geom, 4326), 8 ) AS geojson';
        $sql.= ' FROM sig.commune c';
        if ($this->x) {
            $sql.= ', ( SELECT ST_Transform(ST_SetSRID(ST_MakePoint('.$this->x.', '.$this->y.'),4326), '. $this->srid .') as geom ) as tgeo';
            $sql.= ' WHERE ST_Within( tgeo.geom, c.geom )';
        }
        if ($this->code) {
            $sql.= ' WHERE c.code_commune = ' . $cnx->quote($this->code);
        }
//~ jLog::log($sql);
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

        $cnx = jDb::getConnection('naturaliz_virtual_profile');
        $sql = 'SELECT me.code_me, me.nom_me, ST_AsGeoJSON( ST_Transform(me.geom, 4326), 8 ) AS geojson';
        $sql.= ' FROM sig.masse_eau me';
        if ($this->x) {
            $sql.= ', ( SELECT ST_Transform(ST_SetSRID(ST_MakePoint('.$this->x.', '.$this->y.'),4326), '. $this->srid .') as geom ) as tgeo';
            $sql.= ' WHERE ST_Within( tgeo.geom, me.geom )';
        }
        if ($this->code) {
            $sql.= ' WHERE me.code_me = ' . $cnx->quote($this->code);
        }
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
        if ( $this->type_maille == 'm01' and jAcl2::checkByUser($login, "visualisation.donnees.maille_01") ){
          $maille = 'maille_01';
        }
        //if( $this->type_maille == 'm05')
            //$maille = 'maille_05';
        if( $this->type_maille == 'm10')
            $maille = 'maille_10';

        $cnx = jDb::getConnection('naturaliz_virtual_profile');
        if($this->moduleName == 'occtax'){
            $sql = 'SELECT m.code_maille, m.nom_maille, ST_AsGeoJSON(ST_Transform( m.geom , 4326)) AS geojson ';
            $sql.= ' FROM sig.'.$maille.' m';
            if ($this->x) {
                $sql.= ', (SELECT ST_Transform(ST_SetSRID(ST_MakePoint('.$this->x.', '.$this->y.'),4326), '. $this->srid .') as geom) as tgeo';
            }
            $sql.= ', occtax.observation o';
            $sql.= ' WHERE True';
            if ($this->x) {
                $sql.= ' AND ST_Within( tgeo.geom, m.geom )';
            }
            if ($this->code) {
                $sql.= ' AND m.code_maille = ' . $cnx->quote($this->code);
            }
            $sql.= ' AND ST_Intersects( o.geom, m.geom )';
            $sql.= " AND ( occtax.calcul_diffusion(o.sensi_niveau, o.ds_publique, o.diffusion_niveau_precision) ? 'g'
            OR
            occtax.calcul_diffusion(o.sensi_niveau, o.ds_publique, o.diffusion_niveau_precision) ? '" . $this->type_maille . "' )";
        }

// jLog::log($sql, 'error');
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
