<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    3liz
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

jClasses::inc('mascarine~mascarineSearchObservation');

class mascarineExportObservation extends mascarineSearchObservation {

    protected $returnFields = array();

    protected $tplFields = array();

    protected $displayFields = array();

    protected $csvFields = array(

        'principal' => array(
            'id_obs' => "Integer",
            'date_obs' => "Date",
            'type_obs' => 'String',
            'nature_obs' => 'String',
            'forme_obs' => 'String',
            'num_manuscrit' => "String",
            'remarques_obs' => 'String',
            'cd_nom' => "Integer",
            'nom_valide' => "String",
            'nom_vern' => "String",
            'strate_flore' => "String",
            'statut_local_flore' => 'String',
            'effectif_flore' => 'String',
            'personnes' =>'String',
            'code_commune' => "String",
            'nom_commune' => "String",
            'code_maille' => "String",
            'alt_min_station' => 'Integer',
            'alt_moy_station' => 'Integer',
            'alt_max_station' => 'Integer',
        ),

        'sig' => array(
            'id_obs' => "Integer",
            'wkt' => "String"
        ),

        'commune' => array(
            'id_obs' => "Integer",
            'code_commune' => "String",
            'nom_commune' => "String",
        ),

        'maille' => array(
            'id_obs' => "Integer",
            'code_maille' => "String"
        ),

        'habitat' => array(
            'id_obs' => "Integer",
            'code_habitat' => "String",
            'ref_habitat' => "String",
            'libelle_habitat' => "String"
        ),

        'menace' => array(
            'id_obs' => "Integer",
            'type_menace' => "String",
            'valeur_menace' => "String",
            'statut_menace' => "String"
        )

    );

    protected $unsensitiveCsvFields = array(
        'principal' => array(
            'id_obs' => "Integer",
            'date_obs' => "Date",
            'type_obs' => 'String',
            'cd_nom' => "Integer",
            'nom_valide' => "String",
            'nom_vern' => "String",
            'code_commune' => "String",
            'nom_commune' => "String",
            'code_maille' => "String",
        )
    );


    protected $querySelectors = array(
        'm_observation' => array(
            'alias' => 'o',
            'required' => True,
            'join' => '',
            'joinClause' => '',
            'returnFields' => array(
                'o.id_obs'=> 'id_obs',
                'o.date_obs' => 'date_obs',
                'o.type_obs' => 'type_obs',
                'o.nature_obs' => 'nature_obs',
                'o.forme_obs' => 'forme_obs',
                'o.num_manuscrit' => 'num_manuscrit',
                'o.remarques_obs' => 'remarques_obs'
            )
        ),
        'localisation_obs' => array(
            'alias' => 'l',
            'required' => True,
            'join' => ' INNER JOIN ',
            'joinClause' => ' ON o.id_obs = l.id_obs ',
            'returnFields' => array(
                'ST_AsGeoJSON( ST_Transform(l.geom, 4326), 8 ) AS geojson' => 'geom',
                'l.geom' => 'geom',
                'l.code_maille' => 'code_maille',
            )
        ),
        'station_obs' => array(
            'alias' => 's',
            'required' => True,
            'join' => ' INNER JOIN ',
            'joinClause' => ' ON o.id_obs = s.id_obs ',
            'returnFields' => array(
                's.alt_min_station' => 'alt_min_station',
                's.alt_moy_station' => 'alt_moy_station',
                's.alt_max_station' => 'alt_max_station',
            )
        ),
        'flore_obs' => array(
            'alias' => 'fo',
            'required' => True,
            'join' => ' INNER JOIN ',
            'joinClause' => ' ON o.id_obs = fo.id_obs AND fo.cd_nom IS NOT NULL ',
            'returnFields' => array(
                'fo.cd_nom'=>'cd_nom',
                'fo.statut_local_flore' => 'statut_local_flore',
                'fo.effectif_flore' => 'effectif_flore',
                'fo.strate_flore'=>'strate_flore'
            )
        ),
        'taxref_consolide' => array(
            'alias' => 't',
            'required' => True,
            'join' => ' INNER JOIN ',
            'joinClause' => ' ON fo.cd_nom = t.cd_nom ',
            'returnFields' => array(
                't.nom_vern'=>'nom_vern',
                't.nom_valide'=>'nom_valide'
            )
        ),
        'personne_obs' => array(
            'alias' => 'po',
            'required' => True,
            'join' => ' INNER JOIN ',
            'joinClause' => " ON po.id_obs = o.id_obs AND po.role_perso_obs IN ( 'P', 'S' )",
            'returnFields' => array(
            )
        ),
        'personne' => array(
            'alias' => 'p',
            'required' => True,
            'multi' => True,
            'join' => ' INNER JOIN ',
            'joinClause' => ' ON p.id_perso = po.id_perso ',
            'returnFields' => array(
                "string_agg( p.nom_perso || ' ' || p.prenom_perso || ' (' || org.abreviation_org || ')' , ', ' ) AS personnes" => 'personnes',
            )
        ),
        'organisme' => array(
            'alias' => 'org',
            'required' => True,
            'multi' => True,
            'join' => ' INNER JOIN ',
            'joinClause' => ' ON org.id_org = p.id_org ',
            'returnFields' => array(
            )
        ),
        'commune'  => array(
            'alias' => 'c',
            'required' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON l.code_commune = c.code_commune ',
            'returnFields' => array(
                'c.code_commune' => 'code_commune',
                'c.nom_commune' => 'nom_commune'
            )
        )

    );


    public function __construct ($id, $params=Null) {
        // Set fields from csvFields "principal"
        $this->returnFields = $this->getCsvFields( 'principal' );
        $this->displayFields = $this->returnFields;

        parent::__construct($id, $params);
    }

    function setSql() {
        parent::setSql();
    }

    protected function getResult( $limit=50, $offset=0, $order="" ) {
        $cnx = jDb::getConnection();
//~ jLog::log( $this->sql );
        return $cnx->query( $this->sql );
    }

    protected function getSig() {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT g.id_obs, ST_AsEWKT( g.geom ) AS wkt";
        $sql.= " FROM localisation_obs AS g";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.id_obs = g.id_obs";

        $result = $cnx->query( $sql );
        return $result;
    }

    protected function getCommune() {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT lc.id_obs, lc.code_commune, c.nom_commune";
        $sql.= " FROM localisation_obs AS lc";
        $sql.= " INNER JOIN commune c ON c.code_commune = lc.code_commune";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.id_obs = lc.id_obs";

        $result = $cnx->query( $sql );
        return $result;
    }

    protected function getMaille() {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT lm.id_obs, lm.code_maille";
        $sql.= " FROM localisation_obs AS lm";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.id_obs = lm.id_obs";

        $result = $cnx->query( $sql );
        return $result;
    }

    protected function getHabitat() {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT lh.id_obs, lh.code_habitat, h.ref_habitat, h.libelle_habitat";
        $sql.= " FROM habitat_obs AS lh";
        $sql.= " INNER JOIN habitat h ON h.code_habitat = lh.code_habitat";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.id_obs = lh.id_obs";

        $result = $cnx->query( $sql );
        return $result;
    }

    protected function getMenace() {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT mo.id_obs, n1.valeur AS type_menace, n2.valeur AS valeur_menace, n3.valeur AS statut_menace";
        $sql.= " FROM menace_obs AS mo";
        $sql.= " INNER JOIN m_nomenclature n1 ON n1.champ = 'type_menace' AND n1.code = mo.type_menace";
        $sql.= " INNER JOIN m_nomenclature n2 ON n2.champ = 'valeur_menace' AND n2.code = mo.valeur_menace";
        $sql.= " INNER JOIN m_nomenclature n3 ON n3.champ = 'statut_menace' AND n3.code = mo.statut_menace";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.id_obs = mo.id_obs";

        $result = $cnx->query( $sql );
        return $result;
    }

    public function getTopicData( $topic ) {
        switch( $topic ) {
            case 'sig':
                $rs = $this->getSig();
                break;
            case 'commune':
                $rs = $this->getCommune();
                break;
            case 'maille':
                $rs = $this->getMaille();
                break;
            case 'habitat':
                $rs = $this->getHabitat();
                break;
            case 'menace':
                $rs = $this->getMenace();
                break;
            default:
                return Null;
        }
        if( $rs->rowCount() )
            return $rs;
        else
            return Null;
    }

    public function getCsvFields( $topic, $format='name' ) {
        $return = array();
        if( !jAcl2::check("visualisation.donnees.brutes") and $topic == 'principal' ){
            $fields = $this->unsensitiveCsvFields['principal'];
        }
        else{
            $fields = $this->csvFields[ $topic ];
        }
        if( $format == 'name' ) {
            // Return name (key)
            foreach( $fields as $k=>$v) {
                $return[] = $k;
            }
        }
        else {
            // Return field type (val)
            foreach( $fields as $k=>$v) {
                $return[] = $v;
            }
        }

        return $return;
    }

    public function writeCsv( $data, $topic, $delimiter=',' ) {

        // Create temporary file
        $_dirname = '/tmp';
        $_tmp_file = tempnam($_dirname, 'wrt');
        if (!($fd = @fopen($_tmp_file, 'wb'))) {
            $_tmp_file = $_dirname . '/' . uniqid('wrt');
            if (!($fd = @fopen($_tmp_file, 'wb'))) {
                throw new jException('jelix~errors.file.write.error', array ($file, $_tmp_file));
            }
        }

        // Get attribute for given topic
        $attributes = $this->getCsvFields( $topic );

        // Write CSV header
        fputcsv($fd, $attributes, $delimiter);


        // Write CSV data
        foreach ($data as $line) {
            if( is_array( $line ) ){
                $a = $line;
            }else{
                $a = array();
                foreach( $attributes as $att )
                    $a[] = $line->$att;
            }
            // default php csv handle
            fputcsv($fd, $a, $delimiter);
        }
        fclose($fd);

        return $_tmp_file;

    }

    public function writeCsvT( $topic, $delimiter=',' ) {

        // Create temporary file
        $_dirname = '/tmp';
        $_tmp_file = tempnam($_dirname, 'wrt');
        if (!($fd = @fopen($_tmp_file, 'wb'))) {
            $_tmp_file = $_dirname . '/' . uniqid('wrt');
            if (!($fd = @fopen($_tmp_file, 'wb'))) {
                throw new jException('jelix~errors.file.write.error', array ($file, $_tmp_file));
            }
        }

        // Get fields types
        $types = $this->getCsvFields( $topic, 'type' );

        // Write CSV header
        fputcsv($fd, $types, $delimiter);

        fclose($fd);
        return $_tmp_file;
    }


}
