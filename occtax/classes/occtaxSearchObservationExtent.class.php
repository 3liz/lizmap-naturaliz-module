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
                "date_debut" => Null,
                'ST_AsGeoJSON( ST_Transform(o.geom, 4326), 6 ) AS geojson' => Null,
                "identite_observateur" => Null,
                "menace_regionale" => Null,
                "menace_nationale" => Null,
                "menace_monde" => Null,
                "o.protection" => Null,
            )
        )

    );

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


    protected function setSql(){
        // Get parent sql
        parent::setSql();

        $sql = "
        WITH
        source AS (
        ".$this->sql."
        ),
        kmeans AS (
            SELECT *,
            ST_ClusterKMeans(geom, 100) OVER () kmeans_cid
            FROM source
        )
        SELECT
        kmeans_cid AS id,
        count(cle_obs) AS nb_obs,
        ST_AsGeoJSON( ST_Transform(ST_Centroid(st_convexhull(st_collect(geom))), 4326), 6 ) AS geojson
        FROM kmeans
        GROUP BY kmeans_cid
        ORDER BY id
        ";

        //$this->sql = $sql;
    }


}
