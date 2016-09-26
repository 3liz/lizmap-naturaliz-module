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

class occtaxExportObservation extends occtaxSearchObservation {

    protected $returnFields = array();

    protected $tplFields = array();

    protected $displayFields = array();

    protected $csvFields = array(

        'principal' => array(
            'cle_obs' => "Integer",
            'statut_source' => "String",
            'reference_biblio' => "String",
            'jdd_id' => "String",
            'jdd_code' => "String",
            'identifiant_origine' => "String",
            'identifiant_permanent' => "String",
            'ds_publique' => "String",
            'code_idcnp_dispositif' => "String",
            'statut_observation' => "String",
            'cd_nom' => "Integer",
            'cd_ref' => "Integer",
            'nom_cite' => "String",
            'code_sensible' => "String",
            'denombrement_min' => "Integer",
            'denombrement_max' => "Integer",
            'objet_denombrement' => "String",
            'commentaire' => "String",
            'date_debut' => "Date",
            'heure_debut' => "Time",
            'date_fin' => "Date",
            'heure_fin' => "Time",
            'date_determination_obs' => "Date",
            'altitude_min' => "Real(6.2)",
            'altitude_max' => "Real(6.2)",
            'profondeur_min' => "Real(6.2)",
            'profondeur_max' => "Real(6.2)",
            'toponyme' => "String",
            'code_departement' => "String",
            'x' => "Real",
            'y' => "Real",
            'cle_objet' => "Integer",
            'precision' => "Real",
            'nature_objet_geo' => "String",
            'restriction_localisation_p' => "String",
            'restriction_maille' => "String",
            'restriction_commune' => "String",
            'restriction_totale' => "String",
            'floutage' => "String",
            'identite_observateur' => "String",
            'organisme_observateur' => "String",
            'determinateur' => "String",
            'validateur' => "String",
            'organisme_gestionnaire_donnees' => "String",
            'organisme_standard' => "String",
        ),

        'sig' => array(
            'cle_objet' => "Integer",
            'wkt' => "String",
        ),

        'commune' => array(
            'cle_obs' => "Integer",
            'code_commune' => "String",
            'nom_commune' => "String",
        ),

        'maille' => array(
            'cle_obs' => "Integer",
            'code_maille' => "String"
        ),

        'espace_naturel' => array(
            'cle_obs' => "Integer",
            'type_en' => "String",
            'code_en' => "String",
            'nom_en' => "String",
        ),

        'masse_eau' => array(
            'cle_obs' => "Integer",
            'code_me' => "String",
        ),

        'habitat' => array(
            'cle_obs' => "Integer",
            'code_habitat' => "String",
            'ref_habitat' => "String",
        ),

        'attribut_additionnel' => array(
            'cle_obs' => "Integer",
            'parametre' => "String",
            'valeur' => "String",
        )
    );

    protected $unsensitiveCsvFields = array(
        'principal' => array(
            'cle_obs' => "Integer",
            'statut_source' => "String",
            'nom_cite' => "String",
            'date_debut' => "Date",
            'date_fin' => "Date",
            'organisme_observateur' => "String",
            'organisme_gestionnaire_donnees' => "String"
        )
    );

    protected $querySelectors = array(
        'observation' => array(
            'alias' => 'o',
            'required' => True,
            'join' => '',
            'joinClause' => '',
            'returnFields' => array(
                'o.cle_obs' => 'cle_obs',
                'o.statut_source' => 'statut_source',
                'o.reference_biblio'=> 'reference_biblio',
                'o.jdd_id'=> 'jdd_id',
                'o.jdd_code'=> 'jdd_code',
                'o.identifiant_origine'=> 'identifiant_origine',
                'o.identifiant_permanent'=> 'identifiant_permanent',
                'o.ds_publique'=> 'ds_publique',
                'o.code_idcnp_dispositif'=> 'code_idcnp_dispositif',
                'o.statut_observation'=> 'statut_observation',
                'CASE WHEN o.cd_nom > 0 THEN o.cd_nom ELSE NULL END AS cd_nom' => 'cd_nom',
                'CASE WHEN o.cd_ref > 0 THEN o.cd_ref ELSE NULL END AS cd_ref' => 'cd_ref',
                'o.nom_cite' => 'nom_cite',
                'o.code_sensible' => 'code_sensible',
                'o.denombrement_min' => 'denombrement_min',
                'o.denombrement_max' => 'denombrement_max',
                //'o.type_denombrement' => 'type_denombrement',
                'o.objet_denombrement' => 'objet_denombrement',
                'o.commentaire' => 'commentaire',

                // Emprise temporelle
                "to_char( date_debut, 'YYYY-MM-DD') AS date_debut" => 'date_debut',
                "to_char( heure_debut::time, 'HH24:MI') AS heure_debut" => 'heure_debut',
                "to_char( date_fin, 'YYYY-MM-DD') AS date_fin" => 'date_fin',
                "to_char( heure_fin::time, 'HH24:MI') AS heure_fin" => 'heure_fin',
                "to_char( date_determination_obs, 'YYYY-MM-DD') AS date_determination_obs" => 'date_determination_obs',

                // Localisation
                'o.altitude_min' => 'altitude_min',
                'o.altitude_max' => 'altitude_max',
                'o.profondeur_min' => 'profondeur_min',
                'o.profondeur_max' => 'profondeur_max',
                'o.toponyme' => 'toponyme',
                'o.code_departement' => 'code_departement',
                'o.x' => 'x',
                'o.y' => 'y',
                'o.cle_objet' => 'cle_objet',
                'o.precision' => 'precision',
                'o.nature_objet_geo' => 'nature_objet_geo',
                'o.restriction_localisation_p' => 'restriction_localisation_p',
                'o.restriction_maille' => 'restriction_maille',
                'o.restriction_commune' => 'restriction_commune',
                'o.restriction_totale' => 'restriction_totale',
                'o.floutage' => 'floutage',

                // Acteurs
                'o.identite_observateur' => 'identite_observateur',
                'o.organisme_observateur' => 'organisme_observateur',
                'o.determinateur' => 'determinateur',
                'o.validateur' => 'validateur',
                'o.organisme_gestionnaire_donnees' => 'organisme_gestionnaire_donnees',
                'o.organisme_standard' => 'organisme_standard',
            )
        ),

        'objet_geographique' => array(
            'alias' => 'g',
            'required' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON g.cle_objet = o.cle_objet ',
            'returnFields' => array(
                'ST_AsGeoJSON( ST_Transform(g.geom, 4326), 8 ) AS geojson' => 'geom',
                'g.geom' => 'geom',
            )
        ),
        'localisation_maille_05'  => array(
            'alias' => 'lm05',
            'required' => True,
            'multi' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON lm05.cle_obs = o.cle_obs ',
            'returnFields' => array(
                //~ "string_agg(lm05.code_maille, '|') AS code_maille_05" => 'code_maille_05'
            )
        ),
        'localisation_maille_10'  => array(
            'alias' => 'lm10',
            'required' => True,
            'multi' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON lm10.cle_obs = o.cle_obs ',
            'returnFields' => array(
                //~ "string_agg(lm10.code_maille, '|') AS code_maille_10" => 'code_maille_10'
            )
        ),
        'localisation_commune'  => array(
            'alias' => 'lc',
            'required' => True,
            'multi' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON lc.cle_obs = o.cle_obs ',
            'returnFields' => array(
                //~ "string_agg(lc.code_commune, '|') AS code_commune" => ''
            )
        ),
        'localisation_masse_eau'  => array(
            'alias' => 'lme',
            'required' => True,
            'multi' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON lme.cle_obs = o.cle_obs ',
            'returnFields' => array(
                //~ "string_agg(lme.code_me, '|') AS code_me" => ''
            )
        ),
        'v_localisation_espace_naturel'  => array(
            'alias' => 'len',
            'required' => True,
            'multi' => False,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON len.cle_obs = o.cle_obs ',
            'returnFields' => array(
            )
        ),


    );


    public function __construct ($id, $params=Null) {
        // Set fields from csvFields "principal"
        $this->returnFields = $this->getCsvFields( 'principal');
        $this->displayFields = $this->returnFields;

        parent::__construct($id, $params);
    }

    function setSql() {
        parent::setSql();
    }

    protected function getResult( $limit=50, $offset=0, $order="" ) {
        $cnx = jDb::getConnection();
        return $cnx->query( $this->sql );
    }

    protected function getSig() {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT g.cle_objet, ST_AsEWKT( g.geom ) AS wkt";
        $sql.= " FROM objet_geographique AS g";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.cle_objet = g.cle_objet";

        $result = $cnx->query( $sql );
        return $result;
    }

    protected function getCommune() {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT lc.cle_obs, lc.code_commune, c.nom_commune";
        $sql.= " FROM localisation_commune AS lc";
        $sql.= " INNER JOIN commune c ON c.code_commune = lc.code_commune";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.cle_obs = lc.cle_obs";

        $result = $cnx->query( $sql );
        return $result;
    }

    protected function getMaille() {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT lm.cle_obs, lm.code_maille";
        $sql.= " FROM localisation_maille_10 AS lm";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.cle_obs = lm.cle_obs";

        $result = $cnx->query( $sql );
        return $result;
    }

    protected function getEspaceNaturel() {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT len.cle_obs, en.type_en, len.code_en, en.nom_en";
        $sql.= " FROM localisation_espace_naturel AS len";
        $sql.= " INNER JOIN espace_naturel en ON en.code_en = len.code_en";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.cle_obs = len.cle_obs";

        $result = $cnx->query( $sql );
        return $result;
    }

    protected function getMasseEau() {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT lme.cle_obs, lme.code_me";
        $sql.= " FROM localisation_masse_eau AS lme";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.cle_obs = lme.cle_obs";

        $result = $cnx->query( $sql );
        return $result;
    }

    protected function getHabitat() {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT lh.cle_obs, lh.code_habitat, h.ref_habitat";
        $sql.= " FROM localisation_habitat AS lh";
        $sql.= " INNER JOIN habitat h ON h.code_habitat = lh.code_habitat";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.cle_obs = lh.cle_obs";

        $result = $cnx->query( $sql );
        return $result;
    }

    protected function getAttributAdditionnel() {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT aa.cle_obs, aa.parametre, aa.valeur";
        $sql.= " FROM attribut_additionnel AS aa";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.cle_obs = aa.cle_obs";

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
            case 'espace_naturel':
                $rs = $this->getEspaceNaturel();
                break;
            case 'masse_eau':
                $rs = $this->getMasseEau();
                break;
            case 'habitat':
                $rs = $this->getHabitat();
                break;
            case 'attribut_additionnel':
                $rs = $this->getAttributAdditionnel();
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

