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

class occtaxSearchObservationBrutes extends occtaxSearchObservation {

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
            'lb_nom_valide' => "String",

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
            //'geojson' => "String",
            'source_objet' => "String",

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
        ),

        'maille_02' => array(
            'cle_obs' => "Integer",
            'code_maille' => "String",
        ),

        //'maille_05' => array(
            //'cle_obs' => "Integer",
            //'code_maille' => "String",
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


    protected $querySelectors = array(
        'vm_observation' => array(
            'alias' => 'o',
            'required' => True,
            'join' => '',
            'joinClause' => '',
            'returnFields' => array(
                'o.cle_obs' => Null, // Null mean there wil be no GROUP BY for the field
                'o.identifiant_permanent'=> Null,
                'o.statut_observation'=> Null,
                'CASE WHEN o.cd_nom > 0 THEN o.cd_nom ELSE NULL END AS cd_nom' => Null,
                'CASE WHEN o.cd_ref > 0 THEN o.cd_ref ELSE NULL END AS cd_ref' => Null,
                'o.version_taxref' => Null,
                'o.nom_cite' => Null,
                'o.lb_nom_valide' => Null,

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
                'o.code_idcnp_dispositif'=> Null,
                'o.dee_date_derniere_modification'=> Null,
                'o.dee_date_transformation'=> Null,
                'o.dee_floutage' => Null,
                'o.diffusion_niveau_precision' => Null,
                'o.ds_publique'=> Null,
                'o.identifiant_origine'=> Null,
                'o.jdd_code'=> Null,
                'o.jdd_id'=> Null,
                'o.jdd_metadonnee_dee_id'=> Null,
                'o.jdd_source_id'=> Null,
                'o.organisme_gestionnaire_donnees' => Null,
                'o.organisme_standard' => Null,
                'o.org_transformation' => Null,
                'o.statut_source' => Null,
                'o.reference_biblio'=> Null,
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
                'ST_Transform(o.geom, 4326) AS geom' => Null,
                "o.source_objet" => Null,

                // diffusion
                "o.diffusion" => Null,

                // personnes
                "o.identite_observateur AS observateur" => Null,
                "o.validateur" => Null,
                "o.determinateur" => Null

            )
        )

    );


    protected $observation_exported_fields = array();

    protected $observation_exported_fields_unsensitive = array();

    protected $observation_exported_children = array();

    protected $observation_card_fields = array();

    protected $observation_card_fields_unsensitive = array();

    protected $observation_card_children = array();


    public function __construct ($token=Null, $params=Null, $demande=Null) {
        // Set fields from  Fields "principal"
        $this->returnFields = $this->getExportedFields( 'principal');
        $this->displayFields = $this->returnFields;

        // Fields with nomenclature
        $cnx = jDb::getConnection();
        $sql = 'SELECT DISTINCT champ FROM occtax.nomenclature';
        $nomreq = $cnx->query($sql);
        foreach($nomreq as $nom){
            $this->nomenclatureFields[] = $nom->champ;
        }

        parent::__construct($token, $params, $demande);
    }

    function setSql() {
        parent::setSql();
//jLog::log($this->sql);
    }

    // Override getResult to get all data (no limit nor offset)
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

        // Keep only data where diffusion is possible
        if( !jAcl2::check("visualisation.donnees.brutes") ){
            $sql.= " AND foo.diffusion ? 'c' ";
            $sql.= " AND foo.validite_niveau IN ( ".$this->validite_niveaux_grand_public." )";
        }
//jLog::log($sql);
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

        // Keep only data where diffusion is possible
        if( !jAcl2::check("visualisation.donnees.brutes") ){
            $sql.= " AND foo.diffusion ? 'd' ";
            $sql.= " AND foo.validite_niveau IN ( ".$this->validite_niveaux_grand_public." )";
        }

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

        // Keep only data where diffusion is possible
        if( !jAcl2::check("visualisation.donnees.brutes") ){
            $sql.= " AND foo.diffusion ? 'm10' ";
            $sql.= " AND foo.validite_niveau IN ( ".$this->validite_niveaux_grand_public." )";
        }

        if( $response == 'sql' )
            $result = $sql;
        else
            $result = $cnx->query( $sql );
        return $result;
    }

    protected function getMaille05($response='result') {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT lm.cle_obs, lm.code_maille,";
        $sql.= " m.version_ref, m.nom_ref, lm.type_info_geo";
        $sql.= " FROM localisation_maille_05 AS lm";
        $sql.= " INNER JOIN maille_05 m ON lm.code_maille = m.code_maille";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.cle_obs = lm.cle_obs";

        // Keep only data where diffusion is possible
        if( !jAcl2::check("visualisation.donnees.brutes") ){
            $sql.= " AND ( foo.diffusion ? 'm05' )";
            $sql.= " AND foo.validite_niveau IN ( ".$this->validite_niveaux_grand_public." )";
        }

        if( $response == 'sql' )
            $result = $sql;
        else
            $result = $cnx->query( $sql );
        return $result;
    }

    protected function getMaille02($response='result') {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT lm.cle_obs, lm.code_maille,";
        $sql.= " m.version_ref, m.nom_ref, lm.type_info_geo";
        $sql.= " FROM localisation_maille_02 AS lm";
        $sql.= " INNER JOIN maille_02 m ON lm.code_maille = m.code_maille";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.cle_obs = lm.cle_obs";

        // Keep only data where diffusion is possible
        if( !jAcl2::check("visualisation.donnees.brutes") ){
            $sql.= " AND ( foo.diffusion ? 'm02' )";
            $sql.= " AND foo.validite_niveau IN ( ".$this->validite_niveaux_grand_public." )";
        }

        if( $response == 'sql' )
            $result = $sql;
        else
            $result = $cnx->query( $sql );
        return $result;
    }

    protected function getMaille01($response='result') {

        $cnx = jDb::getConnection();
        $sql = " SELECT DISTINCT lm.cle_obs, lm.code_maille,";
        $sql.= " m.version_ref, m.nom_ref, lm.type_info_geo";
        $sql.= " FROM localisation_maille_01 AS lm";
        $sql.= " INNER JOIN maille_01 m ON lm.code_maille = m.code_maille";
        $sql.= " INNER JOIN ( ";
        $sql.= $this->sql;
        $sql.= " ) AS foo ON foo.cle_obs = lm.cle_obs";

        // Keep only data where diffusion is possible
        if( !jAcl2::check("visualisation.donnees.brutes") ){
            $sql.= " AND ( foo.diffusion ? 'm01' )";
            $sql.= " AND foo.validite_niveau IN ( ".$this->validite_niveaux_grand_public." )";
        }

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

        // Keep only data where diffusion is possible
        if( !jAcl2::check("visualisation.donnees.brutes") ){
            $sql.= " AND foo.diffusion ? 'e' ";
            $sql.= " AND foo.validite_niveau IN ( ".$this->validite_niveaux_grand_public." )";
        }

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

        // Keep only data where diffusion is possible
        if( !jAcl2::check("visualisation.donnees.brutes") ){
            $sql.= " AND foo.diffusion ? 'e' ";
            $sql.= " AND foo.validite_niveau IN ( ".$this->validite_niveaux_grand_public." )";
        }

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
            case 'maille_10':
                $rs = $this->getMaille10($response);
                break;
            case 'maille_05':
                $rs = $this->getMaille05($response);
                break;
            case 'maille_02':
                $rs = $this->getMaille02($response);
                break;
            case 'maille_01':
                $rs = $this->getMaille01($response);
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
        $fields = array();

        // Principal topic : we should remove sensitive data
        if( $topic == 'principal' ){

            if(!jAcl2::check("visualisation.donnees.brutes")){
                // Get fields from exportdFields which are listed in unsensitive
                foreach($this->exportedFields['principal'] as $field=>$type){
                    if(in_array($field, $this->observation_exported_fields_unsensitive)){
                        $fields[$field] = $type;
                    }
                }
            }else{
                $fields = $this->exportedFields['principal'];
            }
        }
        // Other topic. We should just check if topic exists
        else{
            if( array_key_exists($topic, $this->exportedFields) ){
                $fields = $this->exportedFields[ $topic ];
            }
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


    public function limitFields(
        $variable = 'observation_exported_fields',
        $variable_unsensitive='observation_exported_fields_unsensitive',
        $children_variable = 'observation_exported_children'
    ){

        // Get configuration from ini file
        $localConfig = jApp::configPath('naturaliz.ini.php');
        $ini = new jIniFileModifier($localConfig);

        // Get values
        if($limited_fields = $ini->getValue($variable, 'naturaliz')){
            $this->$variable = array_map('trim', explode(',', $limited_fields));
        }
        // Get unsensitive
        if($limited_fields_unsensitive = $ini->getValue($variable_unsensitive, 'naturaliz')){
            $this->$variable_unsensitive = array_map('trim', explode(',', $limited_fields_unsensitive));
        }
        // Get children
        if($limited_children = $ini->getValue($children_variable, 'naturaliz')){
            $this->$children_variable = array_map('trim', explode(',', $limited_children));
        }

        // Override exported fields
        foreach( $this->exportedFields['principal'] as $field => $type ){
            if(!in_array($field, $this->$variable)){
                unset($this->exportedFields['principal'][$field]);
            }
        }

        // Remove children
        foreach( $this->exportedFields as $topic => $data ){
            if($topic == 'principal')
                continue;
            if(!in_array($topic, $this->$children_variable)){
                unset($this->exportedFields[$topic]);
            }
        }

        // Set fields from exportedFields "principal"
        $this->returnFields = $this->getExportedFields( 'principal');
        $this->displayFields = $this->returnFields;
    }


    public function writeDee($output=null){

        // Create temporary file name
        $path = '/tmp/' . time() . session_id() . '.dee.tmp';
        $fp = fopen($path, 'w');
        fwrite($fp, '');
        fclose($fp);
        chmod($path, 0666);

        // Build SQL
        $cnx = jDb::getConnection();
        $tpl = new jTpl();

        // Add subtable if geom query via intersection
        $geoFilter = '';
        if( $this->params
            and array_key_exists( 'geom', $this->queryFilters )
            and array_key_exists( 'geom', $this->params )
            and !empty($this->queryFilters['geom'])
        ){
            $v = $this->params['geom'];
            $geoFilter= ', (SELECT ST_Transform( ST_GeomFromText(' . $cnx->quote($v) . ', 4326), '. $this->srid .') AS fgeom';
            $geoFilter.= ' ) AS fg
            ';
        }

        $assign = array(
            'where' => $this->whereClause,
            'geoFilter' => $geoFilter,
            'path' => $cnx->quote($path)
        );
        $tpl->assign( $assign );
        $sql = $tpl->fetch('occtax~export_dee_sql');

        // Execute SQL to export DEE file
        $res = $cnx->query($sql);
        $fd = fopen($path, 'w');
        foreach($res as $line){
            fwrite($fd, $line->xml);
        }
        fclose($fd);
        if( !file_exists($path) ){
            return Null;
        }

        // Add header (use sed for performance)
        // Done here and not in postgres to avoid xmlagg on a big dataset
        $tpl = new jTpl();
        $u = $cnx->query('SELECT CAST(uuid_generate_v4() AS text) AS uuid;');
        $assign = array(
            'uuid' => $u->fetch()->uuid
        );
        $tpl->assign($assign);
        $header = $tpl->fetch('occtax~export_dee_header');
        $headerfile = '/tmp/' . time() . session_id() . '.dee.header';
        jFile::write($headerfile, $header);

        // Footer
        $footerfile = '/tmp/' . time() . session_id() . '.dee.footer';
        jFile::write($footerfile, '
        </gml:FeatureCollection>');

        // Use bash to concatenate
        if(!$output){
            $output = '/tmp/' . time() . session_id() . '.xml';
        }
        try{
            exec('cat "'. $headerfile.'" "'. $path .'" "'. $footerfile .'" > "'.$output . '"');
        }catch ( Exception $e ) {
            jLog::log( $e->getMessage(), 'error' );
            echo $e->getMessage() . "\n";
        }

        try{
            unlink($path);
            unlink($headerfile);
            unlink($footerfile);
        }catch ( Exception $e ) {
            jLog::log( $e->getMessage(), 'error' );
            echo $e->getMessage() . "\n";
        }
        if(file_exists($output)){
            return $output;
        }

        return null;

    }

}

