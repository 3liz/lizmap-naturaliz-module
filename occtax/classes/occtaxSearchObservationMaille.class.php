<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

jClasses::inc('occtax~occtaxSearchObservation');

class occtaxSearchObservationMaille extends occtaxSearchObservation {

    protected $name = 'maille';

    protected $maille = 'maille_01';

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
        'filter' => '<a class="filterByMaille" href="#" title="{@occtax~search.output.filter.maille.title@}"><i class="icon-filter"></i></a>'
    );

    protected $row_id = 'mid';

    protected $displayFields = array(
        'maille' => array( 'type' => 'string', 'sortable' => "true"),
        'nbobs' => array( 'type' => 'num', 'sortable' => "true", 'className' => 'dt-right'),
        'nbtax' => array( 'type' => 'num', 'sortable' => "true", 'className' => 'dt-right'),
        'filter' => array( 'type' => 'string', 'sortable' => 0, 'className' => 'dt-center')
    );

    protected $orderClause = ' ORDER BY id_maille';

    public function __construct ($token=Null, $params=Null, $demande=Null, $login=Null) {
        $this->login = $login;

        // Set maille depending on rights
        // do it first because parent::__construct do setSql
        if ( $this->maille == 'maille_01' and
            !jAcl2::checkByUser($login, "visualisation.donnees.maille_01")
        ){
            $this->maille = 'maille_02';
        }

        // Reset querySelectors to group result by maille
        $this->querySelectors = array(
            'sig.'.$this->maille => array(
                'alias' => 'm',
                'required' => True,
                'join' => '',
                'joinClause' => '',
                'returnFields' => array (
                    'id_maille' => 'id_maille', // PKEY added here to improve GroupAggregate performance
                    'code_maille AS mid' => Null, // With id_maille added, no need to group by following cols
                    'nom_maille AS maille' => Null,
                    'ST_AsGeoJSON( ST_Transform( ST_Centroid(m.geom), 4326 ), 6 ) AS geojson' => Null,
                    'ST_Centroid(m.geom) AS geom' => Null
                )
            ),

            'occtax.vm_observation' => array(
                'alias' => 'o',
                'required' => True,
                'multi' => True,
                'join' => ' JOIN ',
                'joinClause' => ' ON m.code_maille = code_' . $this->maille . '_unique',
                'returnFields' => array(
                    'count(o.cle_obs) AS nbobs'=> Null,
                    'count(DISTINCT o.cd_ref) AS nbtax' => Null
                )
            )
        );

        // Get maille type (1 or 2)
        $m = 2;
        if(jAcl2::checkByUser($login, "visualisation.donnees.maille_01") and $this->maille == 'maille_01')
            $m = 1;
        if($this->maille == 'maille_02')
            $m = 2;
        if($this->maille == 'maille_10')
            $m = 10;

        // Get legend classes parameters
        $this->setLegendClasses();
        $nb = count($this->legend_classes);

        // Radius
        $inter = $this->legend_max_radius - $this->legend_min_radius;
        $step = $inter / $nb;
        $x = 0;
        $sqlr = "
            CASE
            ";
        foreach($this->legend_classes as $class){
            $rad = $this->legend_min_radius + $x * $step;
            $c = array_map( 'trim', explode(';', $class) );
            $sqlr.= "
            WHEN count(o.cle_obs) >= $c[1] AND count(o.cle_obs) <= $c[2] THEN $rad
            ";
            $x++;
        }
        $sqlr.= "
                ELSE " . $this->legend_max_radius . "
            END * $m AS rayon";
        $this->querySelectors['sig.'.$this->maille]['returnFields'][$sqlr] = array();

        // Color
        $sqlc = "
            CASE
            ";
        foreach($this->legend_classes as $class){
            $c = array_map( 'trim', explode(';', $class) );
            $sqlc.= "
                WHEN count(o.cle_obs) >= $c[1] AND count(o.cle_obs) <= $c[2] THEN '$c[3]'::text
            ";
        }
        $sqlc.= "
                ELSE 'black'::text
            END AS color
        ";
        $this->querySelectors['sig.'.$this->maille]['returnFields'][$sqlc] = array();
        parent::__construct($token, $params, $demande, $login);

    }

    protected function setWhereClause(){
        $sql = parent::setWhereClause();

        // Filter geometry for users depending on sensibiliy
        $login = $this->login;
        if( !jAcl2::checkByUser($login, "visualisation.donnees.brutes") ){
            $question = "AND ( o.diffusion ? 'g' ";
            if($this->maille == 'maille_01' and jAcl2::checkByUser($login, "visualisation.donnees.maille_01")){
                $question.= " OR o.diffusion ? 'm01' ";
            }
            if($this->maille == 'maille_02'){
                $question.= " OR o.diffusion ? 'm02' ";
            }
            if($this->maille == 'maille_10'){
                $question.= " OR o.diffusion ? 'm10' ";
            }

            $sql.= $question . ')';
        }
        return $sql;

    }

    // Override getResult to get all data (no limit nor offset)
    protected function getResult( $limit=50, $offset=0, $order="" ) {
//jLog::log($this->sql);
        $cnx = jDb::getConnection('naturaliz_virtual_profile');
        return $cnx->query( $this->sql );
    }

}

