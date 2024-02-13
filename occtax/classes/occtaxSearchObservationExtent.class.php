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

class occtaxSearchObservationExtent extends occtaxSearchObservation {

    protected $name = 'extent';

    protected $returnFields = array(
        'cle_obs',
        'date_debut',
        //'lien_nom_valide',
        'lb_nom_valide',
        'menace_regionale',
        'menace_nationale',
        'menace_monde',
        'redlist_regionale',
        'redlist_nationale',
        'redlist_monde',
        'protection',
        'protectionlist',
        'geojson',
        'observateur',
        'type_diffusion',
    );

    protected $tplFields = array(
        //'lien_nom_valide' => '
            //<a class="getTaxonDetail cd_nom_{$line->cd_ref}" href="#" title="{@taxon~search.output.inpn.title@}">{$line->lb_nom_valide}</a>
            //{if !empty($line->menace_regionale)}&nbsp;<span class="redlist {$line->menace_regionale}" title="{@occtax~search.output.redlist_regionale.title@} : {$line->menace_regionale}">{$line->menace_regionale}</span>{/if}{if !empty($line->protection)}&nbsp;<span class="protectionlist {$line->protection}" title="{@occtax~search.output.protection.title@} : {$line->protection}">{$line->protection}</span>{/if}',

        'redlist_regionale' => '{if !empty($line->menace_regionale)}<span class="redlist {$line->menace_regionale}" title="{@occtax~search.output.redlist_regionale.title@} : {$line->menace_regionale}">{$line->menace_regionale}</span>{/if}',

        'redlist_nationale' => '{if !empty($line->menace_nationale)}<span class="redlist {$line->menace_nationale}" title="{@occtax~search.output.redlist_nationale.title@} : {$line->menace_nationale}">{$line->menace_nationale}</span>{/if}',

        'redlist_monde' => '{if !empty($line->menace_monde)}<span class="redlist {$line->menace_monde}" title="{@occtax~search.output.redlist_monde.title@} : {$line->menace_monde}">{$line->menace_monde}</span>{/if}',

        'protectionlist' => '{if !empty($line->protection)}&nbsp;<span class="protectionlist {$line->protection}" title="{@occtax~search.output.protection.title@} : {$line->protection}">{$line->protection}</span>{/if}',

        'observateur' => '
            <span class="identite_observateur" title="{$line->identite_observateur|eschtml}">
                {$line->identite_observateur|truncate:40}
            </span>
        ',
    );

    protected $row_id = 'cle_obs';

    protected $displayFields = array(
        'date_debut' => array( 'type' => 'string', 'sortable' => "true", 'className' => 'dt-center'),
        //'lien_nom_valide' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'lb_nom_valide'),
        'lb_nom_valide' => array( 'type' => 'string', 'sortable' => "true"),
        //'menace_regionale' => array( 'type' => 'string', 'sortable' => "true"),
        //'menace_nationale' => array( 'type' => 'string', 'sortable' => "true"),
        //'menace_monde' => array( 'type' => 'string', 'sortable' => "true"),
        'redlist_regionale' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'menace_regionale', 'className' => 'dt-center'),
        'redlist_nationale' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'menace_nationale', 'className' => 'dt-center'),
        'redlist_monde' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'menace_monde', 'className' => 'dt-center'),
        'protectionlist' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'protection', 'className' => 'dt-center'),
        'observateur' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'identite_observateur'),
    );

    protected $querySelectors = array(
        'occtax.vm_observation' => array(
            'alias' => 'o',
            'required' => True,
            'join' => '',
            'joinClause' => '',
            'returnFields' => array(
                'o.cle_obs'=> Null,
                'o.lb_nom_valide' => Null,
                'o.cd_ref' => Null,
                "o.date_debut" => Null,
                // On ne met pas ici la sortie geojson
                // car elles vont dépendre du statut connecté et de la diffusion
                // 'ST_AsGeoJSON( ST_Transform(o.geom, 4326), 6 ) AS geojson' => Null,
                // "ST_Centroid(o.geom) AS geom" => NULL,
                "o.identite_observateur" => Null,
                "o.menace_regionale" => Null,
                "o.menace_nationale" => Null,
                "o.menace_monde" => Null,
                "o.protection" => Null,
                // Est ce que la géométrie est affichable en brut,
                "
                    CASE
                        WHEN geom IS NOT NULL THEN
                            CASE
                                WHEN o.diffusion ? 'g' THEN 'precise'
                                ELSE 'floutage'
                            END
                        ELSE 'vide'
                    END AS type_diffusion
                " => Null,
            )
        )

    );

    protected $extent = null;

    /**
     * construct
    */
    public function __construct ($token=Null, $params=Null, $demande=Null, $login=Null, $extent=null) {
        $this->login = $login;
        $this->extent = trim($extent);

        // Get local configuration (application name, projects name, list of fields, etc.)
        $localConfig = jApp::configPath('naturaliz.ini.php');
        $ini = new jIniFileModifier($localConfig);

        // Hide menace fields depending on configuration
        $taxon_detail_nom_menace = $ini->getValue('taxon_detail_nom_menace', 'naturaliz');
        if (empty($taxon_detail_nom_menace)) {
            $taxon_detail_nom_menace = 'menace_regionale';
        }
        $all_menace = array('menace_regionale', 'menace_nationale', 'menace_monde');

        $new_returnfields = array();
        $del_fields = array();
        foreach ($all_menace as $menace) {
            if ($menace != $taxon_detail_nom_menace) {
                unset($this->querySelectors['occtax.vm_observation']['returnFields'][$menace]);
                unset($this->displayFields[$menace]);
                unset($this->tplFields[$menace]);
                $del_fields[] = $menace;
                $red = str_replace('menace_', 'redlist_', $menace);
                unset($this->displayFields[$red]);
                unset($this->tplFields[$red]);
                $del_fields[] = $red;
            }
        }
        foreach ($this->returnFields as $ret) {
            if (in_array($ret, $del_fields)) {
                continue;
            }
            $new_returnfields[] = $ret;
        }
        $this->returnFields = $new_returnfields;

        parent::__construct($token, $params, $demande, $login);
    }

    /**
     * Récupération de la géométrie en fonction du statut de connexion
     * et de la diffusion des données
     *
     */
    protected function setReturnedGeometryFields()
    {

        if (!jAcl2::checkByUser($this->login, "visualisation.donnees.brutes") ) {
            // On ne peut pas voir toutes les données brutes = GRAND PUBLIC
            if (jAcl2::checkByUser($this->login, "visualisation.donnees.brutes.selon.diffusion")) {
                // on peut voir les géométries si la diffusion est 'g'
                // Liste: ["g", "d", "m10", "m02", "m01", "e", "c", "z"]
                $geojson_expression = "
                    CASE WHEN diffusion ? 'g'
                        THEN ST_AsGeoJSON( ST_Transform(o.geom, 4326), 6 )
                        ELSE NULL::text
                    END AS geojson
                ";
                $centroid_expression = "
                    CASE WHEN diffusion ? 'g'
                        THEN ST_Centroid(o.geom)
                        ELSE NULL
                    END AS geom
                ";

                // Utiliser comme avant la maille 10 au lieu de NULL pour le GeoJSON ?
                //(SELECT ST_AsGeoJSON(ST_Transform(m.geom, 1) FROM sig.maille_10 m WHERE ST_Intersects(lg.geom, m.geom) LIMIT 1)::jsonb As geometry,
            }else{
                // on ne peut pas voir les géométries même si la diffusion le permet
                $geojson_expression = "NULL::text AS geojson";
                $centroid_expression = "NULL AS geom";
            }
        }else{
            // On peut voir toutes les données brutes: admins ou personnes avec demandes
            $geojson_expression = "ST_AsGeoJSON( ST_Transform(o.geom, 4326), 6 ) AS geojson";
            $centroid_expression = "ST_Centroid(o.geom) AS geom";
        }

        // On défini l'expression pour le GeoJSON dans le querySelectors
        $this->querySelectors['occtax.vm_observation']['returnFields'][$geojson_expression] = Null;
        $this->querySelectors['occtax.vm_observation']['returnFields'][$centroid_expression] = Null;
    }

    protected function setWhereClause(){
        // Get parent sql
        $sql = parent::setWhereClause();

        // Extent
        // Only used for the observation table and geometries in the map
        // Do not filter for other contexts
        if ($this->extent){
            $extent_filter = $this->getExtentFilter();
            if ($extent_filter) {
                $sql.= $extent_filter;
            }
        }

        // On récupère seulement les données avec diffusion ? 'g'
        // sauf si droit de voir les données brutes
        if (!jAcl2::checkByUser($this->login, "visualisation.donnees.brutes") ) {
            $sql.= " AND diffusion ? 'g' ";
        }

        return $sql;

    }

    /**
     * Get the number of records returned
     * For this context with extent given, dynamically calculate the row count
    */
    public function getRecordsTotal(){
        $recordsTotal = 0;
        if( $this->sql ) {
            $cnx = jDb::getConnection('naturaliz_virtual_profile');
            $sql = "SELECT count(*) AS nb FROM (";
            $sql.= $this->sql;
            $sql.= ") AS foo;";
            $result = $cnx->query( $sql );
            foreach( $result->fetchAll() as $line ) {
                $recordsTotal = $line->nb;
            }
        }

        return $recordsTotal;
    }

    protected function getExtentFilter() {
        $bbox = $this->extent;
        if ($bbox) {
            $explode_bbox = explode(',', $bbox);
            $has_extent = False;
            if (count($explode_bbox) == 4) {
                $xmin = floatval(trim($explode_bbox[0]));
                $ymin = floatval(trim($explode_bbox[1]));
                $xmax = floatval(trim($explode_bbox[2]));
                $ymax = floatval(trim($explode_bbox[3]));
            } else {
                // Fake filter
                $xmin = $ymin = $xmax = $ymax = '0.0';
            }
            $extent_filter = ' AND ST_Intersects(o.geom,';
            $extent_filter.= ' ST_Transform( ST_MakeEnvelope(';
            $extent_filter.= $xmin.', '.$ymin.', '.$xmax;
            $extent_filter.= ', '.$ymax.', 4326), '.$this->srid.')';
            $extent_filter.= ')
';
            return $extent_filter;
        }
        return null;
    }

}
