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

class mascarineSearchObservationObs extends mascarineSearchObservation {

    protected $maille = 'maille_02';

    protected $orderClause = ' ORDER BY date_obs DESC';

    protected $returnFields = array(
        'id_obs',
        'date_obs',
        'nbtax',
        'maille',
        'num_manuscrit',
        'geojson',
        'detail'
    );

    protected $tplFields = array(
        'detail' => '<a class="openObservation" href="#" title="{@mascarine~search.output.detail.title@}"><i class="icon-file"></i></a>'
    );

    protected $row_id = 'id_obs';

    protected $displayFields = array(
        'id_obs' => array( 'type' => 'string', 'sortable' => "true"),
        'date_obs' => array( 'type' => 'string', 'sortable' => "true"),
        'nbtax' => array( 'type' => 'num', 'sortable' => "true"),
        'maille' => array( 'type' => 'string', 'sortable' => "true"),
        'num_manuscrit' => array( 'type' => 'string', 'sortable' => "true"),
        'detail' => array( 'type' => 'string', 'sortable' => 0)
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

        $sql = ' SELECT id_obs, date_obs, count(DISTINCT f.cd_nom) AS nbtax, m.nom_maille AS maille, num_manuscrit, geojson';
        $sql.= ' FROM (';
        $sql.= $this->sql;
        $sql.= ' ) AS f';
        $sql.= ' INNER JOIN "' . $this->maille .'" AS m ';
        $sql.= ' ON ST_Within( f.geom, m.geom ) ';
        $sql.= ' GROUP BY id_obs, date_obs, m.nom_maille, num_manuscrit, geojson';
        $sql.= ' ORDER BY date_obs';

        $this->sql = $sql;
    }

    protected function getResult( $limit=50, $offset=0, $order="" ) {
        //~ jLog::log($this->sql);
        $cnx = jDb::getConnection();
        return $cnx->query( $this->sql );
    }
}

