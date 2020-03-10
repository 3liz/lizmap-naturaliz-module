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

            // taxon
            'cd_nom' => "Integer",
            'cd_ref' => "Integer",
            'version_taxref' => "String",
            'nom_cite' => "String",
            'lb_nom_valide' => "String",
            'nom_vern' => "String",
            'group2_inpn' => "String",
            'famille' => "String",
            'loc' => "String",
            //'statut_biogeographique' => "String",
            'menace' => "String",
            'protection' => "String",

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

        'maille_01' => array(
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

        //'maille_05' => array(
            //'cle_obs' => "Integer",
            //'code_maille' => "String",
            //'version_ref' => "String",
            //'nom_ref' => "String",
            //'type_info_geo' => "String",
        //),

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

    protected $observation_exported_children_unsensitive = array();

    protected $querySelectors = array(
        'vm_observation' => array(
            'alias' => 'o',
            'required' => True,
            'join' => '',
            'joinClause' => '',
            'returnFields' => array(
                'o.cle_obs' => Null, // Null signifie qu'on ne fait pas de GROUP BY pour ce champ
                'o.identifiant_permanent'=> Null,
                'o.statut_observation'=> Null,

                // taxon
                'CASE WHEN o.cd_nom > 0 THEN o.cd_nom ELSE NULL END AS cd_nom' => Null,
                'CASE WHEN o.cd_ref > 0 THEN o.cd_ref ELSE NULL END AS cd_ref' => Null,
                'o.version_taxref' => Null,
                'o.nom_cite' => Null,
                'o.lb_nom_valide' => Null,
                'o.nom_vern' => Null,
                'o.nom_vern_valide' => Null,
                'o.group2_inpn' => Null,
                'o.famille' => Null,
                'o.loc' => Null,
                'o.menace' => Null,
                'o.protection' => Null,

                // effectif
                'o.denombrement_min' => Null,
                'o.denombrement_max' => Null,
                'o.objet_denombrement' => Null,
                'o.type_denombrement' => Null,

                'o.commentaire' => Null,

                // dates
                "date_debut" => Null,
                "to_char( heure_debut::time, 'HH24:MI') AS heure_debut" => Null,
                "date_fin" => Null,
                "to_char( heure_fin::time, 'HH24:MI') AS heure_fin" => Null,
                "date_determination" => Null,

                // localisation
                'o.altitude_min' => Null,
                'o.altitude_moy' => Null,
                'o.altitude_max' => Null,
                'o.profondeur_min' => Null,
                'o.profondeur_moy' => Null,
                'o.profondeur_max' => Null,

                // source
                'o.code_idcnp_dispositif' => Null,
                'o.dee_date_derniere_modification' => Null,
                'o.dee_date_transformation' => Null,
                'o.dee_floutage' => Null,
                'o.diffusion_niveau_precision' => Null,
                'o.ds_publique' => Null,
                'o.identifiant_origine' => Null,
                'o.jdd_code' => Null,
                'o.jdd_id' => Null,
                'o.jdd_metadonnee_dee_id' => Null,
                'o.jdd_source_id' => Null,
                'o.organisme_gestionnaire_donnees' => Null,
                'o.organisme_standard' => Null,
                'o.org_transformation' => Null,
                'o.statut_source' => Null,
                'o.reference_biblio' => Null,
                'o.sensible' => Null,
                'o.sensi_date_attribution' => Null,
                'o.sensi_niveau' => Null,
                'o.sensi_referentiel' => Null,
                'o.sensi_version_referentiel' => Null,

                // descriptif du sujet
                'o.descriptif_sujet::json AS descriptif_sujet' => Null,

                // validite
                'o.validite_niveau' => Null,
                'o.validite_date_validation' => Null,

                // geometrie
                'o.precision_geometrie' => Null,
                'o.nature_objet_geo' => Null,

                // diffusion
                "o.diffusion" => Null,

                // personnes
                "o.identite_observateur AS observateur" => Null,
                "o.validateur" => Null,
                "o.determinateur" => Null

            )
        )

    );

    public function __construct ($token=Null, $params=Null, $demande=Null, $projection='4326') {

        // Limit fields to export (ie to export in this class)
        $children = 'observation_exported_children';
        if( !jAcl2::check("visualisation.donnees.brutes") ){
            $children = 'observation_exported_children_unsensitive';
        }
        $this->limitFields(
            'observation_exported_fields',
            'observation_exported_fields_unsensitive',
            $children
        );

        // Manage geometries
        // We do it here because it is used by the setSql method
        // We need to modify the returnFields of the querySelector depending on rights

        // CSV: output column "wkt"
        // GeoJSON: output "geom" and "geojson"
        $ckey = Null;
        $gkey = Null;

        // Change export projection
        $transform = "o.geom";
        if($projection == '4326'){
            $transform = "ST_Transform(o.geom, 4326)";
        }

        if (!jAcl2::check("visualisation.donnees.brutes") ) {
            // On ne peut pas voir toutes les données brutes = GRAND PUBLIC
            if (jAcl2::check("export.geometries.brutes.selon.diffusion")) {
                // on peut voir les géométries si la diffusion est 'g'
                $ckey = "CASE WHEN diffusion ? 'g' THEN (ST_AsText( ".$transform." )) ELSE NULL END AS wkt";
                $gkey = " CASE WHEN diffusion ? 'g' ";
                $gkey.= " THEN (ST_AsGeoJSON( ".$transform.", 6 ))::jsonb ";
                $gkey.= " ELSE NULL::jsonb ";
                $gkey.= " END AS geometry";
                // Utiliser comme avant la maille 10 au lieu de NULL pour le GeoJSON ?
                //(SELECT ST_AsGeoJSON(ST_Transform(m.geom, 1) FROM sig.maille_10 m WHERE ST_Intersects(lg.geom, m.geom) LIMIT 1)::jsonb As geometry,

            }else{
                // on ne peut pas voir les géométries même si la diffusion le permet
                $ckey = "NULL AS wkt";
                $gkey = "NULL::jsonb AS geometry";
            }
        }else{
            // On peut voir toutes les données brutes: admins ou personnes avec demandes
            $ckey = "ST_AsText(".$transform.") AS wkt";
            $gkey = "(ST_AsGeoJSON( ".$transform.", 6 ))::jsonb AS geometry";
        }
        if($ckey){
            $this->querySelectors['vm_observation']['returnFields'][$ckey] = Null;
        }
        if($gkey){
            $this->querySelectors['vm_observation']['returnFields'][$gkey] = Null;
            // On doit ajouter un champ geojson car ajouté dans group by de la requête
            $this->querySelectors['vm_observation']['returnFields']["NULL::text AS geojson"] = Null;
        }
        // For WFS export, add geometry only in 4326
        $this->querySelectors['vm_observation']['returnFields']["ST_Transform(o.geom, 4326) AS geom"] = Null;

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

        if($topic == 'principal'){
            $geometryTypes = array(
                'point', 'linestring', 'polygon', 'nogeom'
            );
        }else{
            $geometryTypes = array('other');
        }

        // Create temporary files
        $paths = array();
        foreach($geometryTypes as $geometryType){
            $path = '/tmp/' . time() . session_id() . $topic;
            if($geometryType != ''){
                $path.= '_' . $geometryType;
            }
            $path.= '.csv';
            $fp = fopen($path, 'w');
            fwrite($fp, '');
            fclose($fp);
            chmod($path, 0666);
            $paths[$geometryType] = $path;
        }


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
        if($topic == 'principal'){
            $sql.= $this->sql;
        }
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
        $fds = array();
        $geometry_type_count = array();
        foreach($geometryTypes as $geometryType){
            $fds[$geometryType] = fopen($paths[$geometryType], 'w');
            fputcsv($fds[$geometryType], $attributes, $delimiter);
            $geometry_type_count[$geometryType] = 0;
        }

        // Get nomenclature
        $sqlnom = "SELECT * FROM occtax.v_nomenclature_plat";
        $reqnom = $cnx->query($sqlnom);
        $codenom = array();
        foreach($reqnom as $nom){
            $codenom = (array)json_decode($nom->dict);
        }

        // Fetch data and fill in the file
        $res = $cnx->query($sql);
        $gt = 'other';
        $nblignes = 0;

        foreach($res as $line){
            $nblignes++;
            $ldata = array();

            foreach($attributes as $att){
                $val = $line->$att;
                // on transforme les champs en nomenclature
                if(in_array($att, $this->nomenclatureFields)
                    and array_key_exists($att . '_' . $val, $codenom)
                ){
                    $val = $codenom[$att . '_' . $val];
                }
                // On le fait aussi pour descriptif sujet
                if($att == 'descriptif_sujet'){
                    $dnew = array();
                    $jval = json_decode($val);
                    $di = 1;
                    if(is_array($jval)){
                        foreach($jval as $jitem){
                            $ditem = array();
                            foreach($jitem as $j=>$v){
                                $vv = $v;
                                if(in_array($j, $this->nomenclatureFields)
                                and array_key_exists($j . '_' . $v, $codenom)
                                ){

                                    $vv = $codenom[$j . '_' . $v];
                                }
                                $ditem[$j] = $vv;
                            }
                            $dnew["Groupe d'individus n°" . $di] = $ditem;
                            $di++;
                        }
                    }
                    $val = trim(json_encode($dnew, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT));
                    // Make it more readable
                    $val = str_replace(array('null','{','}','    "'), array('-','','',''), $val);
                    $val = trim(str_replace('"', '', $val));
                }
                // detect geometry type
                if($att == 'wkt' and $topic == 'principal'){
                    if( $val == '' ){
                        $gt = 'nogeom';
                    }else{
                        if (preg_match('#^(MULTI)?POINT#', $val)) {
                            $gt = 'point';
                        }
                        elseif (preg_match('#^(MULTI)?LINESTRING#', $val)) {
                            $gt = 'linestring';
                        }
                        elseif (preg_match('#^(MULTI)?POLYGON#', $val)) {
                            $gt = 'polygon';
                        }
                    }
                }
                $ldata[] = $val;
            }
            fputcsv($fds[$gt], $ldata, $delimiter);
            $geometry_type_count[$gt]+=1;
        }
        fclose($fds[$gt]);

        foreach($geometryTypes as $geometryType){
            if( !file_exists($paths[$geometryType]) ){
                //jLog::log( "Erreur lors de l'export en CSV");
                return Null;
            }
        }

        if($topic == 'principal'){
            return array($paths, $geometry_type_count);
        }else{
            return array($paths[$gt], $geometry_type_count[$gt]);
        }
    }

    public function writeCsvT( $topic, $delimiter=',', $geometryType='' ) {
        // Do not export topic if not defined in localConfig
        if ($topic!= 'principal' and !in_array($topic, $this->observation_exported_children) ) {
            return Null;
        }

        // Create temporary file
        $_dirname = '/tmp';
        //$_tmp_file = tempnam($_dirname, 'wrt');
        $_tmp_file = '/tmp/' . time() . session_id() . $topic;
        if($geometryType != ''){
            $_tmp_file.= '_' . $geometryType;
        }
        $_tmp_file.= '.csvt';

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
        $sql.= "lg.geometry,";

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
                    trim(translate(replace(replace(replace(replace((jsonb_pretty(array_to_json(array_agg(json_build_object(
                        'obs_methode',
                        dict->>(concat('obs_methode', '_', obs_methode)) ,

                        'occ_denombrement_min',
                        occ_denombrement_min,

                        'occ_denombrement_max',
                        occ_denombrement_max,

                        'occ_type_denombrement',
                        dict->>(concat('occ_type_denombrement', '_', occ_type_denombrement)),

                        'occ_objet_denombrement',
                        dict->>(concat('occ_objet_denombrement', '_', occ_objet_denombrement)),

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

                        'preuve_non_numerique',
                        preuve_non_numerique,

                        'obs_contexte',
                        obs_contexte,

                        'obs_description',
                        obs_description,

                        'occ_methode_determination',
                        dict->>(concat('occ_methode_determination', '_', occ_methode_determination))

                    )))::jsonb)::text), '    \"', ''), '    {', '- Groupe d''individus :'), '\"\"', '-'), 'null', '-'), '\"}[]', ' '))
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
                    occ_denombrement_min text,
                    occ_denombrement_max text,
                    occ_type_denombrement text,
                    occ_objet_denombrement text,
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
        $sql.= implode(', ', $group_attributes ) . ',dict,geojson,geometry';

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




    public function getGML( $describeUrl, $typename, $limit=Null, $offset=0) {

        $sql = "
        WITH source AS (
        ".$this->sql;

        $typenames = array(
          'export_observation_point' => 'POINT',
          'export_observation_linestring' => 'LINESTRING',
          'export_observation_polygon' => 'POLYGON',
          'export_observation_nogeom' => Null
        );
        $geometryType = $typenames[$typename];
        if($geometryType){
            $sql.= "
            AND GeometryType(geom) = '" . $geometryType .  "'
            ";
        }else{
            $sql.= "
            AND GeometryType(geom) NOT IN ('POINT', 'LINESTRING', 'POLYGON')
            ";
        }

        // Restrict to given $typename geometry type

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
                    name \"qgs:"  . $typename .  "\",
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
                    trim(translate(replace(replace(replace(replace((jsonb_pretty(array_to_json(array_agg(json_build_object(
                        'obs_methode',
                        dict->>(concat('obs_methode', '_', obs_methode)) ,

                        'occ_denombrement_min',
                        occ_denombrement_min,

                        'occ_denombrement_max',
                        occ_denombrement_max,

                        'occ_type_denombrement',
                        dict->>(concat('occ_type_denombrement', '_', occ_type_denombrement)),

                        'occ_objet_denombrement',
                        dict->>(concat('occ_objet_denombrement', '_', occ_objet_denombrement)),

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

                        'preuve_non_numerique',
                        preuve_non_numerique,

                        'obs_contexte',
                        obs_contexte,

                        'obs_description',
                        obs_description,

                        'occ_methode_determination',
                        dict->>(concat('occ_methode_determination', '_', occ_methode_determination))

                    )))::jsonb)::text), '    \"', ''), '    {', '- Groupe d''individus :'), '\"\"', '-'), 'null', '-'), '\"}[]', ' '))
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
            occ_denombrement_min text,
            occ_denombrement_max text,
            occ_type_denombrement text,
            occ_objet_denombrement text,
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
        if(!in_array('cle_obs', $group_attributes))
            $group_attributes[] = 'cle_obs';
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

