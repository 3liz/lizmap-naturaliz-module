<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

jClasses::inc('mascarine~mascarineSearchObservation');

class mascarineSearchObservationMaille extends mascarineSearchObservation {

    protected $maille = 'maille_02';

    protected $returnFields = array(
        'mid',
        'maille',
        'nbobs',
        'nbtax',
        'color',
        'rayon',
        'geojson',
        'filter'
    );

    protected $tplFields = array(
        'filter' => '<a class="filterByMaille" href="#" title="{@mascarine~search.output.filter.maille.title@}"><i class="icon-filter"></i></a>'
    );

    protected $row_id = 'mid';

    protected $displayFields = array(
        'maille' => array( 'type' => 'string', 'sortable' => "true"),
        'nbobs' => array( 'type' => 'num', 'sortable' => "true"),
        'nbtax' => array( 'type' => 'num', 'sortable' => "true"),
        'filter' => array( 'type' => 'string', 'sortable' => "0")
    );

    public function __construct ($id, $params=Null) {
        // Set maille depending on rights
        // do it first because parent::__construct do setSql
        if ( jAcl2::check("visualisation.donnees.maille_01") )
            $this->maille = 'maille_01';

        parent::__construct($id, $params);
    }

    function setSql() {
        parent::setSql();

        // Get maille type (1 or 2)
        $m = substr( $this->maille, -1 );

        $sql = ' SELECT m.id_maille AS mid, m.nom_maille AS maille, ';
        $sql.= " count(f.id_obs) AS nbobs, count(DISTINCT f.cd_nom) AS nbtax, ";

        $sql.= "
            CASE
                WHEN count(DISTINCT f.id_obs) = 1 THEN 200
                WHEN count(DISTINCT f.id_obs) >= 2 AND count(DISTINCT f.id_obs) <= 5 THEN 270
                WHEN count(DISTINCT f.id_obs) >= 6 AND count(DISTINCT f.id_obs) <= 20 THEN 340
                ELSE 410
            END * " . $m . " AS rayon,
            CASE
                WHEN count(DISTINCT f.id_obs) = 1 THEN '#FFFBC3'::text
                WHEN count(DISTINCT f.id_obs) >= 2 AND count(DISTINCT f.id_obs) <= 5 THEN '#FFFF00'::text
                WHEN count(DISTINCT f.id_obs) >= 6 AND count(DISTINCT f.id_obs) <= 20 THEN '#FFAD00'::text
                ELSE '#FF5500'::text
            END AS color
        ";

        $sql.= ", ST_AsGeoJSON( ST_Transform( ST_Centroid(m.geom), 4326 ) ) AS geojson";
        $sql.= " FROM (";
        $sql.= $this->sql;
        $sql.= " ) AS f";
        $sql.= ' INNER JOIN "' . $this->maille .'" AS m ';
        $sql.= ' ON ST_Within( f.geom, m.geom ) ';
        $sql.= ' GROUP BY m.id_maille, m.nom_maille, m.geom';

        $this->sql = $sql;
    }

    protected function getResult( $limit=50, $offset=0, $order="" ) {
        //~ jLog::log($this->sql);
        $cnx = jDb::getConnection();
        return $cnx->query( $this->sql );
    }
}

