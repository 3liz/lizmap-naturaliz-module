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
        'nbobs' => array( 'type' => 'num', 'sortable' => "true"),
        'nbtax' => array( 'type' => 'num', 'sortable' => "true"),
        'filter' => array( 'type' => 'string', 'sortable' => 0)
    );

    public function __construct ($token=Null, $params=Null, $demande=Null) {
        // Set maille depending on rights
        // do it first because parent::__construct do setSql
        if ( $this->maille == 'maille_01' and !jAcl2::check("visualisation.donnees.maille_01") )
            $this->maille = 'maille_02';

        // Remove unnecessary LEFT JOIN to improve performances
        $this->querySelectors['localisation_maille_05']['required'] = False;
        $this->querySelectors['localisation_maille_10']['required'] = False;
        $this->querySelectors['localisation_commune']['required'] = False;
        $this->querySelectors['localisation_departement']['required'] = False;
        $this->querySelectors['localisation_masse_eau']['required'] = False;
        $this->querySelectors['v_localisation_espace_naturel']['required'] = False;
        $this->querySelectors['observation']['returnFields'] = array(
            'o.cle_obs'=> 'cle_obs',
            'o.nom_cite' => 'nom_cite',
            'o.cd_nom' => 'cd_nom',
            "to_char(date_debut, 'YYYY-MM-DD') AS date_debut" => 'date_debut'
        );


        // Change geometry exported value for users depending on sensibiliy
        if( !jAcl2::check("visualisation.donnees.brutes") ){
            $question = "WHEN od.diffusion ? 'g' ";
            if($this->maille == 'maille_01' and jAcl2::check("visualisation.donnees.maille_01")){
                $question.= " OR od.diffusion ? 'm01' ";
            }
            if($this->maille == 'maille_02'){
                $question.= " OR od.diffusion ? 'm02' ";
            }
            //if($this->maille == 'maille_05'){
                //$question.= " OR od.diffusion ? 'm05' ";
            //}
            if($this->maille == 'maille_10'){
                $question.= " OR od.diffusion ? 'm10' ";
            }
            $this->querySelectors['observation']['returnFields']["
                CASE
                    $question
                    THEN geom
                    ELSE NULL
                END AS geom
            "] = 'geom';

        }else{
            $this->querySelectors['observation']['returnFields']['o.geom'] = 'geom';
        }



        $this->querySelectors['v_observateur']['returnFields'] = array(
            "string_agg(pobs.identite, ', ') AS identite_observateur" => 'identite_observateur'
        );
        // Remove ORDER BY
        $this->orderClause = '';

        parent::__construct($token, $params, $demande);

    }

    protected function setSql() {
        parent::setSql();

        // Get maille type (1 or 2)
        $m = 2;
        if(jAcl2::check("visualisation.donnees.maille_01") and $this->maille == 'maille_01')
            $m = 1;
        if($this->maille == 'maille_02')
            $m = 2;
        //if($this->maille == 'maille_05')
            //$m = 5;
        if($this->maille == 'maille_10')
            $m = 10;

        // Build SQL
        $sql = ' SELECT m.code_maille AS mid, m.nom_maille AS maille, ';
        $sql.= " count(f.cle_obs) AS nbobs, count(DISTINCT f.cd_nom) AS nbtax, ";

        $sql.= "
            CASE
            ";

        // Get legend classes parameters
        $this->setLegendClasses();
        $nb = count($this->legend_classes);

        // Radius
        $inter = $this->legend_max_radius - $this->legend_min_radius;
        $step = $inter / $nb;
        $x = 0;
        foreach($this->legend_classes as $class){
            $rad = $this->legend_min_radius + $x * $step;
            $c = array_map( 'trim', explode(';', $class) );
            $sql.= "
            WHEN count(DISTINCT f.cle_obs) >= $c[1] AND count(DISTINCT f.cle_obs) <= $c[2] THEN $rad
            ";
            $x++;
        }
        $sql.= "
                ELSE " . $this->legend_max_radius . "
            END * $m AS rayon,";

        // Color
        $sql.= "
            CASE
            ";
        foreach($this->legend_classes as $class){
            $c = array_map( 'trim', explode(';', $class) );
            $sql.= "
                WHEN count(DISTINCT f.cle_obs) >= $c[1] AND count(DISTINCT f.cle_obs) <= $c[2] THEN '$c[3]'::text
            ";
        }
        $sql.= "
                ELSE 'black'::text
            END AS color
        ";

        $sql.= ", ST_AsGeoJSON( ST_Transform( ST_Centroid(m.geom), 4326 ), 6 ) AS geojson";
        $sql.= " FROM (";
        $sql.= $this->sql;
        $sql.= " ) AS f";
        $sql.= ' INNER JOIN "' . $this->maille .'" AS m ';
        $sql.= ' ON ST_Intersects( m.geom, f.geom  ) ';
        $sql.= ' GROUP BY m.code_maille, m.nom_maille, m.geom';

        $this->sql = $sql;

//jLog::log($this->sql);
    }

    protected function getResult( $limit=50, $offset=0, $order="" ) {
//jLog::log($this->sql);
        $cnx = jDb::getConnection();
        return $cnx->query( $this->sql );
    }

}

