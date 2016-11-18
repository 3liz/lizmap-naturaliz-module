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

    protected $exportedFields = array(

        'principal' => array(
            'cle_obs' => "Integer",
            'identifiant_permanent' => "String",
            'statut_observation' => "String",
            'cd_nom' => "Integer",
            'cd_ref' => "Integer",
            'version_taxref' => "String",
            'nom_cite' => "String",

            // effectif
            'denombrement_min' => "Integer",
            'denombrement_max' => "Integer",
            'objet_denombrement' => "String",
            'type_denombrement' => "String",

            'commentaire' => "String",

            // dates
            'date_debut' => "Date",
            'heure_debut' => "Time",
            'date_fin' => "Date",
            'heure_fin' => "Time",
            'date_determination' => "Date",

            // localisation
            'altitude_min' => "Real(6.2)",
            'altitude_moy' => "Real(6.2)",
            'altitude_max' => "Real(6.2)",
            'profondeur_min' => "Real(6.2)",
            'profondeur_moy' => "Real(6.2)",
            'profondeur_max' => "Real(6.2)",

            // source
            'code_idcnp_dispositif' => "String",
            'dee_date_derniere_modification' => "String",
            'dee_date_transformation' => "String",
            'dee_floutage' => "String",
            'diffusion_niveau_precision' => "String",
            'ds_publique' => "String",
            'identifiant_origine' => "String",
            'jdd_code' => "String",
            'jdd_id' => "String",
            'jdd_metadonnee_dee_id' => "String",
            'jdd_source_id' => "String",
            'organisme_gestionnaire_donnees' => "String",
            'org_transformation' => "String",
            'statut_source' => "String",
            'reference_biblio' => "String",
            'sensible' => "String",
            'sensi_date_attribution' => "String",
            'sensi_niveau' => "String",
            'sensi_referentiel' => "String",
            'sensi_version_referentiel' => "String",

            // geometrie
            'precision_geometrie' => "Real",
            'nature_objet_geo' => "String",
            'geojson' => "String",
            'source_objet' => "String",

            // referentiels
            'code_commune' => "String",
            'code_maille_05' => "String",
            'code_maille_10' => "String",

            // acteurs
            'observateur' => "String",
            'determinateur' => "String",
            'validateur' => "String",
        ),

        'commune' => array(
            'cle_obs' => "Integer",
            'code_commune' => "String",
            'nom_commune' => "String",
            'annee_ref' => "Integer",
            'type_info_geo' => "String",
        ),

        'departement' => array(
            'cle_obs' => "Integer",
            'code_departement' => "String",
            'nom_departement' => "String",
            'annee_ref' => "Integer",
            'type_info_geo' => "String",
        ),

        'maille' => array(
            'cle_obs' => "Integer",
            'code_maille' => "String",
            'version_ref' => "String",
            'nom_ref' => "String",
            'type_info_geo' => "String",
        ),

        'espace_naturel' => array(
            'cle_obs' => "Integer",
            'type_en' => "String",
            'code_en' => "String",
            'nom_en' => "String",
            'version_en' => "String",
            'type_info_geo' => "String",
        ),

        'masse_eau' => array(
            'cle_obs' => "Integer",
            'code_me' => "String",
            'version_me' => "String",
            'date_me' => "String",
            'type_info_geo' => "String",
        ),

        'habitat' => array(
            'cle_obs' => "Integer",
            'code_habitat' => "String",
            'ref_habitat' => "String",
        ),

        'attribut_additionnel' => array(
            'cle_obs' => "Integer",
            'nom' => "String",
            'definition' => "String",
            'valeur' => "String",
            'unite' => "String",
            'thematique' => "String",
            'type' => "String",
        )
    );

    protected $unsensitiveExportedFields = array(
        'principal' => array(
            'cle_obs' => "Integer",
            'statut_source' => "String",
            'nom_cite' => "String",
            'date_debut' => "Date",
            'date_fin' => "Date",
            'organisme_gestionnaire_donnees' => "String",
            'source_objet' => "String",
            'code_commune' => "String",
            'code_maille_10' => "String"
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
                'o.identifiant_permanent'=> 'identifiant_permanent',
                'o.statut_observation'=> 'statut_observation',
                'CASE WHEN o.cd_nom > 0 THEN o.cd_nom ELSE NULL END AS cd_nom' => 'cd_nom',
                'CASE WHEN o.cd_ref > 0 THEN o.cd_ref ELSE NULL END AS cd_ref' => 'cd_ref',
                'o.version_taxref' => 'version_taxref',
                'o.nom_cite' => 'nom_cite',

                // effectif
                'o.denombrement_min' => 'denombrement_min',
                'o.denombrement_max' => 'denombrement_max',
                'o.objet_denombrement' => 'objet_denombrement',
                'o.type_denombrement' => 'type_denombrement',

                'o.commentaire' => 'commentaire',

                // dates
                "to_char( date_debut, 'YYYY-MM-DD') AS date_debut" => 'date_debut',
                "to_char( heure_debut::time, 'HH24:MI') AS heure_debut" => 'heure_debut',
                "to_char( date_fin, 'YYYY-MM-DD') AS date_fin" => 'date_fin',
                "to_char( heure_fin::time, 'HH24:MI') AS heure_fin" => 'heure_fin',
                "to_char( date_determination, 'YYYY-MM-DD') AS date_determination" => 'date_determination',

                // localisation
                'o.altitude_min' => 'altitude_min',
                'o.altitude_moy' => 'altitude_moy',
                'o.altitude_max' => 'altitude_max',
                'o.profondeur_min' => 'profondeur_min',
                'o.profondeur_moy' => 'profondeur_moy',
                'o.profondeur_max' => 'profondeur_max',

                // source
                'o.code_idcnp_dispositif'=> 'code_idcnp_dispositif',
                'o.dee_date_derniere_modification'=> 'dee_date_derniere_modification',
                'o.dee_date_transformation'=> 'dee_date_transformation',
                'o.dee_floutage' => 'dee_floutage',
                'o.diffusion_niveau_precision' => 'diffusion_niveau_precision',
                'o.ds_publique'=> 'ds_publique',
                'o.identifiant_origine'=> 'identifiant_origine',
                'o.jdd_code'=> 'jdd_code',
                'o.jdd_id'=> 'jdd_id',
                'o.jdd_metadonnee_dee_id'=> 'jdd_metadonnee_dee_id',
                'o.jdd_source_id'=> 'jdd_source_id',
                'o.organisme_gestionnaire_donnees' => 'organisme_gestionnaire_donnees',
                'o.org_transformation' => 'org_transformation',
                'o.statut_source' => 'statut_source',
                'o.reference_biblio'=> 'reference_biblio',
                'o.sensible' => 'sensible',
                'o.sensi_date_attribution' => 'sensi_date_attribution',
                'o.sensi_niveau' => 'sensi_niveau',
                'o.sensi_referentiel' => 'sensi_referentiel',
                'o.sensi_version_referentiel' => 'sensi_version_referentiel',

                // geometrie
                'o.precision_geometrie' => 'precision_geometrie',
                'o.nature_objet_geo' => 'nature_objet_geo',
                '(ST_AsGeoJSON( ST_Transform(o.geom, 4326), 8 ))::json AS geojson' => 'geom',
                'ST_Transform(o.geom, 4326) AS geom' => 'geom',
                "CASE
                    WHEN o.geom IS NOT NULL THEN 'GEO'
                    WHEN lm05.code_maille IS NOT NULL THEN 'M05'
                    WHEN lm10.code_maille IS NOT NULL THEN 'M10'
                    WHEN lc.code_commune IS NOT NULL THEN 'COM'
                    WHEN lme.code_me IS NOT NULL THEN 'ME'
                    WHEN len.code_en IS NOT NULL THEN 'EN'
                    WHEN ld.code_departement IS NOT NULL THEN 'DEP'
                    ELSE 'NO'
                END AS source_objet" => "source_objet"
            )
        ),

        // personnes
        'v_observateur'  => array(
            'alias' => 'pobs',
            'required' => True,
            'multi' => True,
            'join' => ' JOIN ',
            'joinClause' => " ON pobs.cle_obs = o.cle_obs ",
            'returnFields' => array(
                "string_agg( DISTINCT concat( pobs.identite, ' (' || pobs.organisme|| ')' ), ', ' ) AS observateur" => 'observateur'
            )
        ),
        'v_validateur'  => array(
            'alias' => 'pval',
            'required' => True,
            'multi' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => " ON pval.cle_obs = o.cle_obs ",
            'returnFields' => array(
                "string_agg( DISTINCT concat( pval.identite, ' (' || pval.organisme|| ')' ), ', ' ) AS validateur" => 'validateur'
            )
        ),
        'v_determinateur'  => array(
            'alias' => 'pdet',
            'required' => True,
            'multi' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => " ON pdet.cle_obs = o.cle_obs ",
            'returnFields' => array(
                "string_agg( DISTINCT concat( pdet.identite, ' (' || pdet.organisme|| ')' ), ', ' ) AS determinateur" => 'determinateur'
            )
        ),

        // spatial
        'localisation_maille_05'  => array(
            'alias' => 'lm05',
            'required' => True,
            'multi' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON lm05.cle_obs = o.cle_obs ',
            'returnFields' => array(
                "string_agg(lm05.code_maille, '|') AS code_maille_05" => 'code_maille_05'
            )
        ),
        'localisation_maille_10'  => array(
            'alias' => 'lm10',
            'required' => True,
            'multi' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON lm10.cle_obs = o.cle_obs ',
            'returnFields' => array(
                "string_agg(lm10.code_maille, '|') AS code_maille_10" => 'code_maille_10'
            )
        ),
        'localisation_commune'  => array(
            'alias' => 'lc',
            'required' => True,
            'multi' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON lc.cle_obs = o.cle_obs ',
            'returnFields' => array(
                "string_agg(lc.code_commune, '|') AS code_commune" => 'code_commune'
            )
        ),
        'localisation_departement'  => array(
            'alias' => 'ld',
            'required' => True,
            'multi' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON ld.cle_obs = o.cle_obs ',
            'returnFields' => array(
                //"string_agg(lc.code_commune, '|') AS code_commune" => ''
            )
        ),
        'localisation_masse_eau'  => array(
            'alias' => 'lme',
            'required' => True,
            'multi' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON lme.cle_obs = o.cle_obs ',
            'returnFields' => array(
                //"string_agg(lme.code_me, '|') AS code_me" => ''
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


    public function __construct ($token=Null, $params=Null) {
        // Set fields from exportedFields "principal"
        $this->returnFields = $this->getExportedFields( 'principal');
        $this->displayFields = $this->returnFields;

        parent::__construct($token, $params);
    }

    function setSql() {
        parent::setSql();
    }

    protected function getResult( $limit=50, $offset=0, $order="" ) {
        $cnx = jDb::getConnection();
        return $cnx->query( $this->sql );
    }


    protected function getCommune($response='result') {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT lc.cle_obs, lc.code_commune, c.nom_commune, c.annee_ref, lc.type_info_geo";
        $sql.= " FROM localisation_commune AS lc";
        $sql.= " INNER JOIN commune c ON c.code_commune = lc.code_commune";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.cle_obs = lc.cle_obs";
        if( $response == 'sql' )
            $result = $sql;
        else
            $result = $cnx->query( $sql );

        return $result;
    }

    protected function getDepartement($response='result') {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT ld.cle_obs, ld.code_departement, d.nom_departement, d.annee_ref, ld.type_info_geo";
        $sql.= " FROM localisation_departement AS ld";
        $sql.= " INNER JOIN departement d ON d.code_departement = ld.code_departement";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.cle_obs = ld.cle_obs";
        if( $response == 'sql' )
            $result = $sql;
        else
            $result = $cnx->query( $sql );
        return $result;
    }

    protected function getMaille10($response='result') {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT lm.cle_obs, lm.code_maille,";
        $sql.= " m.version_ref, m.nom_ref, lm.type_info_geo";
        $sql.= " FROM localisation_maille_10 AS lm";
        $sql.= " INNER JOIN maille_10 m ON lm.code_maille = m.code_maille";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.cle_obs = lm.cle_obs";

        if( $response == 'sql' )
            $result = $sql;
        else
            $result = $cnx->query( $sql );
        return $result;
    }

    protected function getEspaceNaturel($response='result') {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT len.cle_obs, en.type_en, len.code_en,";
        $sql.= " en.nom_en, en.version_en, len.type_info_geo";
        $sql.= " FROM localisation_espace_naturel AS len";
        $sql.= " INNER JOIN espace_naturel en ON en.code_en = len.code_en";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.cle_obs = len.cle_obs";
        if( $response == 'sql' )
            $result = $sql;
        else
            $result = $cnx->query( $sql );
        return $result;
    }

    protected function getMasseEau($response='result') {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT lme.cle_obs, lme.code_me,";
        $sql.= " me.version_me, me.date_me, lme.type_info_geo";
        $sql.= " FROM localisation_masse_eau AS lme";
        $sql.= " INNER JOIN masse_eau me ON me.code_me = lme.code_me";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.cle_obs = lme.cle_obs";
        if( $response == 'sql' )
            $result = $sql;
        else
            $result = $cnx->query( $sql );
        return $result;
    }

    protected function getHabitat($response='result') {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT lh.cle_obs, lh.code_habitat, h.ref_habitat";
        $sql.= " FROM localisation_habitat AS lh";
        $sql.= " INNER JOIN habitat h ON h.code_habitat = lh.code_habitat AND h.ref_habitat = lh.ref_habitat";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.cle_obs = lh.cle_obs";
        if( $response == 'sql' )
            $result = $sql;
        else
            $result = $cnx->query( $sql );
        return $result;
    }

    protected function getAttributAdditionnel($response='result') {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT aa.cle_obs, aa.nom, aa.definition,";
        $sql.= " aa.valeur, aa.unite, aa.thematique, aa.type";
        $sql.= " FROM attribut_additionnel AS aa";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.cle_obs = aa.cle_obs";
        if( $response == 'sql' )
            $result = $sql;
        else
            $result = $cnx->query( $sql );
        return $result;
    }

    public function getTopicData( $topic, $response='result' ) {
        switch( $topic ) {
            case 'commune':
                $rs = $this->getCommune($response);
                break;
            case 'departement':
                $rs = $this->getDepartement($response);
                break;
            case 'maille':
                $rs = $this->getMaille10($response);
                break;
            case 'espace_naturel':
                $rs = $this->getEspaceNaturel($response);
                break;
            case 'masse_eau':
                $rs = $this->getMasseEau($response);
                break;
            case 'habitat':
                $rs = $this->getHabitat($response);
                break;
            case 'attribut_additionnel':
                $rs = $this->getAttributAdditionnel($response);
                break;
            default:
                return Null;
        }
        $return = Null;
        if( $response == 'result'){
            if( $rs->rowCount() )
                $return = $rs;
        }else{
            $return = $rs;
        }
        return $return;
    }

    public function getExportedFields( $topic, $format='name' ) {
        $return = array();
        if( !jAcl2::check("visualisation.donnees.brutes") and $topic == 'principal' ){
            $fields = $this->unsensitiveExportedFields['principal'];

        // Maille to choose
        $m = 2;
        if ( jAcl2::check("visualisation.donnees.maille_01") )
            $m = '1';
        }
        else{
            $fields = $this->exportedFields[ $topic ];
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

    public function writeCsv( $topic, $limit=Null, $offset=0, $delimiter=',' ) {

        $cnx = jDb::getConnection();

        // Create temporary file name
        $path = '/tmp/' . time() . session_id() . $topic . '.csv';
        $fp = fopen($path, 'w');
        fwrite($fp, '');
        fclose($fp);
        chmod($path, 0666);

        // Build COPY query
        $sql = " COPY (
            SELECT ";

        // Fields
        $attributes = $this->getExportedFields( $topic );
        $sql.= implode(', ', $attributes );

        // SQL
        $sql.= "
            FROM (
        ";
        if($topic == 'principal')
            $sql.= $this->sql;
        else{
            $sql.= $this->getTopicData($topic, 'sql');
        }

        // Limit and offset
        if( $limit ){
            $sql.= "
            LIMIT ".$limit;
            if( $offset ){
                $sql.= "
                OFFSET ".$offset;
            }
        }
        $sql.= ") foo";
        $sql.= "
        )";

        $sql.= "
        TO " . $cnx->quote($path);
        $sql.= "
        WITH CSV DELIMITER " .$cnx->quote($delimiter);
        $sql.= " HEADER";
//jLog::log( $sql);
        $cnx->exec($sql);
        if( !file_exists($path) ){
            //jLog::log( "Erreur lors de l'export en CSV");
            return Null;
        }
        return $path;

    }

    public function writeCsvT( $topic, $delimiter=',' ) {

        // Create temporary file
        $_dirname = '/tmp';
        //$_tmp_file = tempnam($_dirname, 'wrt');
        $_tmp_file = '/tmp/' . time() . session_id() . $topic . '.csvt';
        if (!($fd = @fopen($_tmp_file, 'wb'))) {
            $_tmp_file = $_dirname . '/' . uniqid('wrt');
            if (!($fd = @fopen($_tmp_file, 'wb'))) {
                throw new jException('jelix~errors.file.write.error', array ($file, $_tmp_file));
            }
        }

        // Get fields types
        $types = $this->getExportedFields( $topic, 'type' );

        // Write CSV header
        fputcsv($fd, $types, $delimiter);

        fclose($fd);
        return $_tmp_file;
    }


    public function getGeoJSON( $limit=Null, $offset=0) {

        $sql = "
        WITH source AS (
        ".$this->sql;
        if( $limit ){
            $sql.= " LIMIT ".$limit;
            if( $offset ){
                $sql.= " OFFSET ".$offset;
            }
        }
        $sql.= "
        )

        SELECT row_to_json(fc, True) AS geojson
        FROM (
            SELECT
                'FeatureCollection' As type,
                array_to_json(array_agg(f)) As features
            FROM (
                SELECT
                    'Feature' As type,
        ";
        if( jAcl2::check("visualisation.donnees.brutes") ){
            $sql.= "lg.geojson::json As geometry,";
        }else{
            $sql.= "(SELECT ST_AsGeoJSON(m.geom, 1) FROM sig.maille_10 m WHERE ST_Intersects(lg.geom, m.geom) LIMIT 1)::json As geometry,";
        }

        $sql.= "
                    row_to_json(
                        ( SELECT l FROM
                            (
                                SELECT ";
        $sql.= implode(', ', $this->returnFields );
        $sql.= "
                            ) As l
                        )
                    ) As properties
                FROM source As lg
            ) As f
        ) As fc";
//jLog::log($sql);

        $cnx = jDb::getConnection();
        $q = $cnx->query( $sql );
        $return = '';
        foreach( $q as $d){
            $return =  $d->geojson;
            break;
        }
        return $return;

    }


    public function createWfsService(){

        // Get QGIS project template
        $template = jFile::read(jApp::getModulePath('occtax'). '/install/qgis/wfs_template.qgs');
        $tpl = new jTpl();
        $sql = $this->sql;
        $sql = str_replace( '<', '&lt;', $sql );
        $sql = str_replace( '"', '\"', $sql );
        $assign = array(
            'dbname' => 'naturaliz-reunion',
            'dbuser' => 'mdouchin',
            'dbpass' => 'tation',
            'dbport' => '5433',
            'sql' => $sql,
            'ows_server_title' => 'Naturaliz - Requête sur les observations',
            'ows_server_abstract' => 'Filtres de recherches :
            '.$this->getSearchDescription()
        );
        $tpl->assign($assign);
        $content = $tpl->fetchFromString($template, 'text');

//faut ajouter occtax. devant les tables
//faut remplacer le truc geojson par vrai géométrie

        $targetPath = '/tmp/test.qgs';
        jFile::write( $targetPath, $content );
        return $targetPath;

    }

}

