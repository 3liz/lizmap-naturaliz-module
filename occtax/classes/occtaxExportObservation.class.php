<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

jClasses::inc('occtax~occtaxSearchObservationBrutes');

class occtaxExportObservation extends occtaxSearchObservationBrutes {

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
            'dee_floutage' => "String",
            'identifiant_origine' => "String",
            'jdd_code' => "String",
            'jdd_id' => "String",
            'organisme_gestionnaire_donnees' => "String",
            'org_transformation' => "String",
            'statut_source' => "String",
            'reference_biblio' => "String",
            'sensible' => "String",
            'sensi_niveau' => "String",

            // Descriptif sujet
            'obs_methode' => "String",
            'occ_etat_biologique' => "String",
            'occ_naturalite' => "String",
            'occ_sexe' => "String",
            'occ_stade_de_vie' => "String",
            'occ_statut_biogeographique' => "String",
            'occ_statut_biologique' => "String",
            'preuve_existante' => "String",
            'preuve_numerique' => "String",
            'preuve_non_numerique' => "String",
            'obs_contexte' => "String",
            'obs_description' => "String",
            'occ_methode_determination' => "String",

            // geometrie
            'precision_geometrie' => "Real",
            'nature_objet_geo' => "String",
            'geojson' => "String",
            'wkt' => "String",

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
            //'wkt' => "String"
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
                'o.dee_floutage' => 'dee_floutage',
                'o.identifiant_origine'=> 'identifiant_origine',
                'o.jdd_code'=> 'jdd_code',
                'o.jdd_id'=> 'jdd_id',
                'o.organisme_gestionnaire_donnees' => 'organisme_gestionnaire_donnees',
                'o.org_transformation' => 'org_transformation',
                'o.statut_source' => 'statut_source',
                'o.reference_biblio'=> 'reference_biblio',
                'o.sensible' => 'sensible',
                'o.sensi_niveau' => 'sensi_niveau',

                // descriptif sujet
                'o.preuve_non_numerique' => 'preuve_non_numerique',
                'o.obs_contexte' => 'obs_contexte',
                'o.preuve_numerique' => 'preuve_numerique',
                'o.preuve_existante' => 'preuve_existante',
                'o.occ_statut_biologique' => 'occ_statut_biologique',
                'o.occ_statut_biogeographique' => 'occ_statut_biogeographique',
                'o.occ_stade_de_vie' => 'occ_stade_de_vie',
                'o.occ_sexe' => 'occ_sexe',
                'o.occ_naturalite' => 'occ_naturalite',
                'o.occ_methode_determination' => 'occ_methode_determination',
                'o.occ_etat_biologique' => 'occ_etat_biologique',
                'o.obs_methode' => 'obs_methode',
                'o.obs_description' => 'obs_description',

                // validite
                'o.validite_niveau' => "validite_niveau",

                // geometrie
                'o.precision_geometrie' => 'precision_geometrie',
                'o.nature_objet_geo' => 'nature_objet_geo',

                 // reprojection needed for GeoJSON standard
                '(ST_AsGeoJSON( ST_Transform(o.geom, 4326), 6 ))::json AS geojson' => 'geom',
                '(ST_AsText( ST_Transform(o.geom, 4326) )) AS wkt' => 'geom',
                'ST_Transform(o.geom, 4326) AS geom' => 'geom',

            )
        ),

        'observation_diffusion'  => array(
            'alias' => 'od',
            'required' => True,
            'join' => ' JOIN ',
            'joinClause' => " ON od.cle_obs = o.cle_obs ",
            'returnFields' => array(
                "od.diffusion" => 'diffusion'
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
        'localisation_commune'  => array(
            'alias' => 'lc',
            'required' => false,
            'multi' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON lc.cle_obs = o.cle_obs ',
            'returnFields' => array(
                //"string_agg(DISTINCT lc.code_commune, '|') AS code_commune" => 'code_commune'
            )
        ),
        'localisation_masse_eau'  => array(
            'alias' => 'lme',
            'required' => False,
            'multi' => True,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON lme.cle_obs = o.cle_obs ',
            'returnFields' => array(
                //"string_agg(DISTINCT lme.code_me, '|') AS code_me" => ''
            )
        ),
        'v_localisation_espace_naturel'  => array(
            'alias' => 'len',
            'required' => False,
            'multi' => False,
            'join' => ' LEFT JOIN ',
            'joinClause' => ' ON len.cle_obs = o.cle_obs ',
            'returnFields' => array(
                //"string_agg(DISTINCT len.code_en, '|') AS code_en" => ''
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

    public function writeCsv( $topic, $limit=Null, $offset=0, $delimiter=',' ) {

        $cnx = jDb::getConnection();

        // Create temporary file name
        $path = '/tmp/' . time() . session_id() . $topic . '.csv';
        $fp = fopen($path, 'w');
        fwrite($fp, '');
        fclose($fp);
        chmod($path, 0666);

        // Build query
        $sql = "
            SELECT ";

        // Fields
        $attributes = $this->getExportedFields( $topic );
        if($topic == 'principal')
            $attributes = array_diff($attributes, array('geojson'));

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

        // Use COPY: DEACTIVATED BECAUSE NEEDS SUPERUSER PG RIGHTS
        $sqlcopy = " COPY (" . $sql ;
        $sqlcopy.= "
        )";
        $sqlcopy.= "
        TO " . $cnx->quote($path);
        $sqlcopy.= "
        WITH CSV DELIMITER " .$cnx->quote($delimiter);
        $sqlcopy.= " HEADER";
        //$cnx->exec($sql);

        // Write header
        $fd = fopen($path, 'w');
        fputcsv($fd, $attributes, $delimiter);

        // Fetch data and fill in the file
        $res = $cnx->query($sql);
        foreach($res as $line){
            $ldata = array();
            foreach($attributes as $att){
                $ldata[] = $line->$att;
            }
            fputcsv($fd, $ldata, $delimiter);
        }
        fclose($fd);

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
        $attributes = $attributes = array_diff(
            $this->returnFields,
            array('geojson', 'wkt')
        );
        $sql.= implode(', ', $attributes );
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




    public function getGML( $describeUrl, $limit=Null, $offset=0) {

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

        SELECT
        -- xmlagg(
            xmlelement(
                name \"gml:featureMember\",
                xmlelement(
                    name \"qgs:export_observation\",
                    xmlattributes(source.cle_obs AS \"gml:id\"),

                    -- box
                    xmlelement(
                        name \"gml:boundedBy\",
                        ST_AsGMl(2, geom, 6, 32)::xml
                    ),

                    -- geometry
                    xmlelement(
                        name \"qgs:geometry\",
                        ST_AsGMl(2, geom, 6)::xml
                    ),

                    -- fields
                        xmlforest (
        ";
        $attributes = $attributes = array_diff(
            $this->returnFields,
            array('geojson', 'wkt')
        );
        $attributes =  array_map(function($el){ return $el . ' AS "qgs:'.$el.'"'; }, $attributes);
        $sql.= implode(', ', $attributes );
        $sql.= "
                        )

                )
            )

--        )
        AS gml
        FROM source";
//jLog::log($sql);

        $cnx = jDb::getConnection();
        $q = $cnx->query( $sql );
        $featureMembers = '';
        $boundedBy = '';

        // Get feature members
        foreach( $q as $d){
            $featureMembers.=  $d->gml;
        }

        // Build full XML
        $tpl = new jTpl();
        $assign = array();
        $assign['url'] = $describeUrl;
        $assign['boundedBy'] = $boundedBy;
        $assign['featureMembers'] = $featureMembers;
        $tpl->assign($assign);

        $return = $tpl->fetch('occtax~wfs_getfeature_gml');

        return $return;

    }



}

