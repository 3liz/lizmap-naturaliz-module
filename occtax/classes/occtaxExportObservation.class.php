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
            'organisme_standard' => "String",
            'organisme_gestionnaire_donnees' => "String",
            'org_transformation' => "String",
            'statut_source' => "String",
            'reference_biblio' => "String",
            'sensible' => "String",
            'sensi_date_attribution' => "String",
            'sensi_niveau' => "String",
            'sensi_referentiel' => "String",
            'sensi_version_referentiel' => "String",

            // Descriptif sujet
            'descriptif_sujet' => "String",

            // Validité
            'validite_niveau' => 'String',
            'validite_date_validation' => 'String',

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

        'maille_10' => array(
            'cle_obs' => "Integer",
            'code_maille' => "String",
            'version_ref' => "String",
            'nom_ref' => "String",
            'type_info_geo' => "String",
        ),


        'maille_02' => array(
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

    protected $observation_exported_fields = array();

    protected $observation_exported_fields_unsensitive = array();

    protected $observation_exported_children = array();

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
                'o.organisme_standard' => 'organisme_standard',
                'o.org_transformation' => 'org_transformation',
                'o.statut_source' => 'statut_source',
                'o.reference_biblio'=> 'reference_biblio',
                'o.sensible' => 'sensible',
                'o.sensi_date_attribution' => 'sensi_date_attribution',
                'o.sensi_niveau' => 'sensi_niveau',
                'o.sensi_referentiel' => 'sensi_referentiel',
                'o.sensi_version_referentiel' => 'sensi_version_referentiel',

                // descriptif du sujet
                'o.descriptif_sujet::json AS descriptif_sujet' => 'descriptif_sujet',

                // validite
                'o.validite_niveau' => 'validite_niveau',
                'o.validite_date_validation' => 'validite_date_validation',

                // geometrie
                'o.precision_geometrie' => 'precision_geometrie',
                'o.nature_objet_geo' => 'nature_objet_geo',

                 // reprojection needed for GeoJSON standard
                '(ST_AsGeoJSON( ST_Transform(o.geom, 4326), 6 ))::jsonb AS geojson' => 'geom',

                // Le WKT est exporté dans le CSV, pour le grand public également
                // donc on ne diffuse la geom que si la diffusion est possible cad 'g'
                "CASE WHEN od.diffusion ? 'g' THEN (ST_AsText( ST_Transform(o.geom, 4326) )) ELSE NULL END AS wkt" => 'geom',
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

    public function __construct ($token=Null, $params=Null, $demande=Null) {

        // Limit fields to export (ie to export in this class)
        $this->limitFields(
            'observation_exported_fields',
            'observation_exported_fields_unsensitive',
            'observation_exported_children'
        );

        parent::__construct($token, $params, $demande);
    }

    function setSql() {
        parent::setSql();
    }

    protected function getResult( $limit=50, $offset=0, $order="" ) {
        $cnx = jDb::getConnection();
        return $cnx->query( $this->sql );
    }

    public function writeCsv( $topic, $limit=Null, $offset=0, $delimiter=',' ) {
        // Do not export topic if not defined in localConfig
        if( $topic!= 'principal' and !in_array($topic, $this->observation_exported_children) ){
            return Null;
        }

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

        if($topic == 'principal'){
            $attributes = array_diff($attributes, array('geojson'));
        }

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

//jLog::log($sql);

        // Use COPY: DEACTIVATED BECAUSE NEEDS SUPERUSER PG RIGHTS
        //$sqlcopy = " COPY (" . $sql ;
        //$sqlcopy.= "
        //)";
        //$sqlcopy.= "
        //TO " . $cnx->quote($path);
        //$sqlcopy.= "
        //WITH CSV DELIMITER " .$cnx->quote($delimiter);
        //$sqlcopy.= " HEADER";
        //$cnx->exec($sqlcopy);

        // Write header
        $fd = fopen($path, 'w');
        fputcsv($fd, $attributes, $delimiter);

        // Get nomenclature
        $sqlnom = "SELECT * FROM occtax.v_nomenclature_plat";
        $reqnom = $cnx->query($sqlnom);
        $codenom = array();
        foreach($reqnom as $nom){
            $codenom = (array)json_decode($nom->dict);
        }

        // Fetch data and fill in the file
        $res = $cnx->query($sql);
        foreach($res as $line){
            $ldata = array();
            foreach($attributes as $att){
                $val = $line->$att;
                // on transforme les champs en nomenclature
                if(in_array($att, $this->nomenclatureFields)){
                    $val = $codenom[$att . '_' . $val];
                }
                // On le fait aussi pour descriptif sujet
                if($att == 'descriptif_sujet'){
                    $dnew = array();
                    $jval = json_decode($val);
                    foreach($jval as $jitem){
                        $ditem = array();
                        foreach($jitem as $j=>$v){
                            $vv = $v;
                            if(in_array($j, $this->nomenclatureFields)){
                                $vv = $codenom[$j . '_' . $v];
                            }
                            $ditem[$j] = $vv;
                        }
                        $dnew[] = $ditem;
                    }
                    $val = json_encode($dnew, JSON_UNESCAPED_UNICODE);
                }
                $ldata[] = $val;
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
        // Do not export topic if not defined in localConfig
        if( $topic!= 'principal' and !in_array($topic, $this->observation_exported_children) ){
            return Null;
        }

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

        // Build query
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

--        SELECT row_to_json(fc, True) AS geojson
--        FROM (
            SELECT
                'FeatureCollection' As type,
--                array_to_json(array_agg(f)) As features
                row_to_json(f)
            FROM (
                SELECT
                    'Feature' As type,
        ";
        if( jAcl2::check("visualisation.donnees.brutes") ){
            $sql.= "lg.geojson::jsonb As geometry,";
        }else{
            $sql.= "(SELECT ST_AsGeoJSON(m.geom, 1) FROM sig.maille_10 m WHERE ST_Intersects(lg.geom, m.geom) LIMIT 1)::jsonb As geometry,";
        }

        $sql.= "
                    row_to_json(
                        ( SELECT l FROM
                            (
                                SELECT ";
        $attributes = array_diff(
            $this->returnFields,
            array('geojson', 'wkt')
        );

        // Use nomenclature to replace code values with label
        $attributes =  array_map(
            function($el){
                $champ = $el;
                if(in_array($el, $this->nomenclatureFields)){
                    $champ = "dict->>(concat('".$el."', '_', ".$el."))";
                }
                if($el == 'descriptif_sujet'){
                    $champ = "
                    REPLACE(replace((jsonb_pretty(array_to_json(array_agg(json_build_object(
                        'obs_methode',
                        dict->>(concat('obs_methode', '_', obs_methode)) ,
                        'occ_etat_biologique',
                        dict->>(concat('occ_etat_biologique', '_', occ_etat_biologique)),
                        'occ_naturalite',
                        dict->>(concat('occ_naturalite', '_', occ_naturalite)),
                        'occ_sexe',
                        dict->>(concat('occ_sexe', '_', occ_sexe)),
                        'occ_stade_de_vie',
                        dict->>(concat('occ_stade_de_vie', '_', occ_stade_de_vie)),
                        'occ_statut_biogeographique',
                        dict->>(concat('occ_statut_biogeographique', '_', occ_statut_biogeographique)),
                        'occ_statut_biologique',
                        dict->>(concat('occ_statut_biologique', '_', occ_statut_biologique)),
                        'preuve_existante',
                        dict->>(concat('preuve_existante', '_', preuve_existante)),
                        'preuve_numerique',
                        preuve_numerique,
                        'preuve_numerique',
                        preuve_non_numerique,
                        'obs_contexte',
                        obs_contexte,
                        'obs_description',
                        obs_description,
                        'occ_methode_determination',
                        dict->>(concat('occ_methode_determination', '_', occ_methode_determination))
                    )))::jsonb)::text), '\"', ''), ':', ' : ')
                    ";
                }
                // Ajout du nom de champ
                $champ.= ' AS "'.$el.'"';
                return $champ;
            },
            $attributes
        );
        $sql.= implode(', ', $attributes );
        $sql.= "
                            ) As l
                        )
                    ) As properties
                FROM source As lg
                LEFT JOIN LATERAL
                jsonb_to_recordset(lg.descriptif_sujet::jsonb) AS (
                    obs_methode text,
                    occ_etat_biologique text,
                    occ_naturalite text,
                    occ_sexe text,
                    occ_stade_de_vie text,
                    occ_statut_biogeographique text,
                    occ_statut_biologique text,
                    preuve_existante text,
                    preuve_numerique text,
                    preuve_non_numerique text,
                    obs_contexte text,
                    obs_description text,
                    occ_methode_determination text
                ) ON TRUE,
                (SELECT dict::jsonb AS dict FROM occtax.v_nomenclature_plat ) AS v_nomenclature_plat
        ";

        $group_attributes = $attributes = array_diff(
            $this->returnFields,
            array('geojson', 'wkt', 'descriptif_sujet')
        );
        $sql.= " GROUP BY ";
        $sql.= implode(', ', $group_attributes ) . ',dict,geojson';

        $sql.= "

            ) As f
--        ) As fc
        ";

//jLog::log($sql);

        // Create temporary file name
        $path = '/tmp/' . time() . session_id() . '.geojson';
        $fp = fopen($path, 'w');
        fwrite($fp, '');
        fclose($fp);
        chmod($path, 0666);

        // Write header
        $fd = fopen($path, 'w');
        $g_head = '
        {
          "type": "FeatureCollection",
          "features": [
        ';
        fwrite($fd, $g_head);

        // Write features
        $cnx = jDb::getConnection();
        $query = $cnx->query( $sql );
        $v = '';
        foreach( $query as $feature){
            fwrite($fd, $v . $feature->row_to_json);
            $v = ',';
        }

        // Write end
        $g_tail = '
          ]
        }';
        fwrite($fd, $g_tail);

        fclose($fd);

        if( !file_exists($path) ){
            //jLog::log( "Erreur lors de l'export en CSV");
            return Null;
        }
        return $path;

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
        $attributes =  array_map(
            function($el){
                $champ = $el;
                if(in_array($el, $this->nomenclatureFields)){
                    $champ = "dict->>(concat('".$el."', '_', ".$el."))";
                }
                if($el == 'descriptif_sujet'){
                    $champ = "
                    REPLACE(replace((jsonb_pretty(array_to_json(array_agg(json_build_object(
                        'obs_methode',
                        dict->>(concat('obs_methode', '_', obs_methode)) ,
                        'occ_etat_biologique',
                        dict->>(concat('occ_etat_biologique', '_', occ_etat_biologique)),
                        'occ_naturalite',
                        dict->>(concat('occ_naturalite', '_', occ_naturalite)),
                        'occ_sexe',
                        dict->>(concat('occ_sexe', '_', occ_sexe)),
                        'occ_stade_de_vie',
                        dict->>(concat('occ_stade_de_vie', '_', occ_stade_de_vie)),
                        'occ_statut_biogeographique',
                        dict->>(concat('occ_statut_biogeographique', '_', occ_statut_biogeographique)),
                        'occ_statut_biologique',
                        dict->>(concat('occ_statut_biologique', '_', occ_statut_biologique)),
                        'preuve_existante',
                        dict->>(concat('preuve_existante', '_', preuve_existante)),
                        'preuve_numerique',
                        preuve_numerique,
                        'preuve_numerique',
                        preuve_non_numerique,
                        'obs_contexte',
                        obs_contexte,
                        'obs_description',
                        obs_description,
                        'occ_methode_determination',
                        dict->>(concat('occ_methode_determination', '_', occ_methode_determination))
                    )))::jsonb)::text), '\"', ''), ':', ' : ')
                    ";
                }
                // Ajout du nom de balise XML
                $champ.= ' AS "qgs:'.$el.'"';
                return $champ;
            },
            $attributes
        );
        $sql.= implode(', ', $attributes );
        $sql.= "
                        )

                )
            )

--        )
        AS gml
        FROM source
        LEFT JOIN LATERAL
        jsonb_to_recordset(source.descriptif_sujet::jsonb) AS (
            obs_methode text,
            occ_etat_biologique text,
            occ_naturalite text,
            occ_sexe text,
            occ_stade_de_vie text,
            occ_statut_biogeographique text,
            occ_statut_biologique text,
            preuve_existante text,
            preuve_numerique text,
            preuve_non_numerique text,
            obs_contexte text,
            obs_description text,
            occ_methode_determination text
        ) ON TRUE,
        (SELECT dict::jsonb AS dict FROM occtax.v_nomenclature_plat ) AS v_nomenclature_plat";

        $group_attributes = $attributes = array_diff(
            $this->returnFields,
            array('geojson', 'wkt', 'descriptif_sujet')
        );
        $sql.= " GROUP BY ";
        $sql.= implode(', ', $group_attributes ) . ',dict,geom';

        // Create temporary file name
        $path = '/tmp/' . time() . session_id() . '.gml';
        $fp = fopen($path, 'w');
        fwrite($fp, '');
        fclose($fp);
        chmod($path, 0666);

        // Write header
        $fd = fopen($path, 'w');
        $gml_head = '<wfs:FeatureCollection xmlns:wfs="http://www.opengis.net/wfs" xmlns:ogc="http://www.opengis.net/ogc" xmlns:gml="http://www.opengis.net/gml" xmlns:ows="http://www.opengis.net/ows" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:qgs="http://www.qgis.org/gml" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.opengis.net/wfs http://schemas.opengis.net/wfs/1.0.0/wfs.xsd http://www.qgis.org/gml ';
        $gml_head.= $describeUrl;
        $gml_head.= '">';
        fwrite($fd, $gml_head);

        // Write bounding box
        $boundedBy = ''; // not needed by QGIS. Do not compute it (avoid useless things)
        fwrite($fd, $boundedBy);

        // Write features
        $cnx = jDb::getConnection();
        $query = $cnx->query( $sql );
        foreach( $query as $feature){
            fwrite($fd, $feature->gml);
        }

        // Write end
        $gml_tail = '</wfs:FeatureCollection>';
        fwrite($fd, $gml_tail);
        fclose($fd);

        if( !file_exists($path) ){
            //jLog::log( "Erreur lors de l'export en CSV");
            return Null;
        }
        return $path;

    }



}

