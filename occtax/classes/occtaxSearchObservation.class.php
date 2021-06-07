<?php
/**
* @package   lizmap
* @subpackage occtax
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

jClasses::inc('occtax~occtaxSearch');

class occtaxSearchObservation extends occtaxSearch {

    protected $name = 'observation';

    protected $orderClause = ' ORDER BY date_debut DESC';

    protected $returnFields = array(
        'cle_obs',
        'date_debut',
        'identifiant_permanent',
        'date_debut_buttons',
        'lien_nom_valide',
        'geojson',
        //'source_objet',
        'observateur',
        'validite',
    );

    protected $tplFields = array(
        'date_debut_buttons' => '
            {$line->date_debut}
            <br/><a class="openObservation" href="#" title="{@occtax~search.output.detail.title@}"><i class="icon-file"></i></a>
            <a class="zoomToObservation" href="#" title="{@occtax~search.output.zoom.title@}"><i class="icon-search"></i></a>
            {if !empty($line->in_panier)}<i class="icon-shopping-cart" title="{@validation.span.validation_basket.inside.title@}"></i>{/if}

        ',

        'lien_nom_valide' => '
            <a class="getTaxonDetail cd_nom_{$line->cd_ref}" href="#" title="{@taxon~search.output.inpn.title@}">
                {$line->lb_nom_valide}
            </a>

            {if !empty($line->menace_regionale)}
            &nbsp;<span class="redlist {$line->menace_regionale}" title="{@occtax~search.output.redlist_regionale.title@} : {$line->menace_regionale}">{$line->menace_regionale}</span>
            {/if}

            {if !empty($line->protection)}
            &nbsp;
            <span class="protectionlist {$line->protection}" title="{@occtax~search.output.protection.title@} : {$line->protection}">{$line->protection}</span>
            {/if}',

        'observateur' => '
            <span class="identite_observateur" title="{$line->identite_observateur|eschtml}">
                {$line->identite_observateur|truncate:40}
            </span>
        ',

        'validite' => '
            <span class="niv_val n{$line->niv_val}" title="{@occtax~validation.input.niv_val@}: {$line->niv_val}" >
                {$line->niv_val}
            </span>
        ',
    );

    protected $row_id = 'cle_obs';

    protected $displayFields = array(
        //'date_debut' => array( 'type' => 'string', 'sortable' => "true", 'className' => 'dt-center'),
        'date_debut_buttons' => array( 'type' => 'string', 'sortable' => "true", 'className' => 'dt-center', 'sorting_field' => 'date_debut'),
        'lien_nom_valide' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'lb_nom_valide'),
        //'source_objet' => array( 'type' => 'string', 'sortable' => "true", 'className' => 'dt-center'),
        'observateur' => array( 'type' => 'string', 'sortable' => "true", 'sorting_field' => 'identite_observateur'),
        'validite' => array( 'type' => 'string', 'sortable' => "true", 'className' => 'dt-center', 'sorting_field' => 'vo.niv_val'),
    );

    protected $querySelectors = array(
        'occtax.vm_observation' => array(
            'alias' => 'o',
            'required' => True,
            'join' => '',
            'joinClause' => '',
            'returnFields' => array(
                'o.cle_obs'=> Null,
                'o.identifiant_permanent'=> Null,
                'o.lb_nom_valide' => Null,
                'o.cd_nom' => Null,
                'o.cd_ref' => Null,
                "date_debut" => Null,
                "source_objet" => Null,
                'ST_AsGeoJSON( ST_Transform(o.geom, 4326), 6 ) AS geojson' => Null,
                'o.geom' => Null,
                "o.diffusion" => Null,
                "identite_observateur" => Null,
                "o.menace_regionale" => Null,
                "o.menace_nationale" => Null,
                "o.menace_monde" => Null,
                "o.protection" => Null,
                "'no' AS in_panier" => Null,
                "o.validite_niveau AS niv_val" => Null,
            )
        )

    );

    protected $queryFilters = array(
        'cle_obs' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND o.cle_obs IN (@)',
            'type'=> 'string'
        ),
        'cd_nom' => array (
            'table' => 'occtax.vm_observation',
            // space before o.cd_ref are VERY important as used in regex to search/replace prefix
            // for demands and use in subqueries
            'clause' => ' AND ( o.cd_ref IN (@) OR o.cd_ref IN (
                WITH RECURSIVE parcours_taxref(cd_ref, cd_sup) AS (
                    SELECT cd_ref, cd_sup
                    FROM taxon.taxref
                    WHERE cd_nom IN (@)
                UNION ALL
                    SELECT n.cd_ref, n.cd_sup
                    FROM
                    taxon.taxref AS n,
                    parcours_taxref AS w
                    WHERE 2>1 -- pas true sinon remplace par listener gestion
                    AND n.cd_sup = w.cd_ref
                )
                SELECT DISTINCT cd_ref
                FROM parcours_taxref
            )) ',
            'type'=> 'integer',
            'label'=> array(
                'dao'=>'taxon~taxref',
                'method'=>'get',
                'column'=>'nom_valide'
            )
        ),

        'geom' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND ST_Intersects(o.geom, fg.fgeom ) ',
            'type' => 'geom'
        ),

        'date_min' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND ( date_debut >= @::timestamp OR date_fin >= @::timestamp ) ',
            'type' => 'timestamp'
        ),
        'date_max' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND ( date_debut <= @::timestamp OR date_fin <= @::timestamp ) ',
            'type' => 'timestamp'
        ),
        'code_commune' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND code_commune ?| ARRAY[@]',
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~commune',
                'method'=>'get',
                'column'=>'nom_commune'
            )
        ),
        'code_masse_eau' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND code_me ?| ARRAY[@]',
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~masse_eau',
                'method'=>'get',
                'column'=>'nom_me'
            )
        ),

        'observateur' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND o.cle_obs IN (SELECT cle_obs FROM occtax.v_observateur vo WHERE vo.identite ILIKE ( @ )  )',
            'type' => 'partial'
        ),

        'type_en' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND type_en ?| ARRAY[@]',
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~nomenclature',
                'method'=>'getTypeEn',
                'column'=>'valeur'
            )
        ),

        'jdd_id' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND o.jdd_id IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~jdd',
                'method'=>'get',
                'column'=>'jdd_code'
            )
        ),

        'validite_niveau' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND o.validite_niveau IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~nomenclature',
                'method'=>'getValiditeNiveau',
                'column'=>'valeur'
            )
        ),

        // TAXONS
        'group' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND o.categorie IN ( @ )',
            'type' => 'string'
        ),

        'habitat' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND o.habitat IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'method'=>'getLabel',
                'champ'=>'habitat',
                'column'=>'valeur'
            )
        ),

        'statut' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND o.statut IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'method'=>'getLabel',
                'champ'=>'statut',
                'column'=>'valeur'
            )
        ),

        'endemicite' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND o.endemicite IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'method'=>'getLabel',
                'champ'=>'endemicite',
                'column'=>'valeur'
            )
        ),

        'invasibilite' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND o.invasibilite IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'method'=>'getLabel',
                'champ'=>'invasibilite',
                'column'=>'valeur'
            )
        ),

        'menace_regionale' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND o.menace_regionale IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'method'=>'getLabel',
                'champ'=>'menace',
                'column'=>'valeur'
            )
        ),
        'menace_nationale' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND o.menace_nationale IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'method'=>'getLabel',
                'champ'=>'menace',
                'column'=>'valeur'
            )
        ),
        'menace_monde' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND o.menace_monde IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'method'=>'getLabel',
                'champ'=>'menace',
                'column'=>'valeur'
            )
        ),

        'protection' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND o.protection IN ( @ )',
            'type' => 'string',
            'label'=> array(
                'dao'=>'taxon~t_nomenclature',
                'method'=>'getLabel',
                'champ'=>'protection',
                'column'=>'valeur'
            )
        ),

        //'nom_valide' => array (
            //'table' => 'occtax.vm_observation',
            //'clause' => ' AND o.nom_valide ILIKE ( @ )',
            //'type' => 'partial'
        //),
    );

    /**
     * construct - Change geometry value depending on logged user
    */
    public function __construct ($token=Null, $params=Null, $demande=Null, $login=Null) {
        $this->login = $login;

        if (array_key_exists('lien_nom_valide', $this->tplFields)) {
            // Get local configuration (application name, projects name, list of fields, etc.)
            $localConfig = jApp::configPath('naturaliz.ini.php');
            $ini = new jIniFileModifier($localConfig);

            // Choose menace field depending on configuration
            // Displayed on Observations table
            $taxon_detail_nom_menace = $ini->getValue('taxon_detail_nom_menace', 'naturaliz');
            $all_menace = array('menace_regionale', 'menace_nationale', 'menace_monde');
            if (!in_array(trim($taxon_detail_nom_menace), $all_menace)) {
                $taxon_detail_nom_menace = 'menace_regionale';
            }
            $menace = str_replace('menace_', '', trim($taxon_detail_nom_menace));
            $old_template =  $this->tplFields['lien_nom_valide'];
            $new_template = str_replace(
                'regionale',
                $menace,
                $old_template
            );

            $this->tplFields['lien_nom_valide'] = $new_template;

        }

        // For demand, do not get all taxon child recursively
        // as it is a performance killer
        if ($demande) {
            $this->queryFilters['cd_nom'] = array (
                'table' => 'occtax.vm_observation',
                // space before o.cd_ref are VERY important as used in regex to search/replace prefix
                // for demands and use in subqueries
                'clause' => ' AND o.cd_ref IN (@)',
                'type'=> 'integer',
                'label'=> array(
                    'dao'=>'taxon~taxref',
                    'method'=>'get',
                    'column'=>'nom_valide'
                )
            );
        }

        // Validation basket
        // Do it only for occtaxSearchObservation, not for Maille, Stats & Taxon
        if ($this->name == 'observation' && $this->login && jAcl2::check( 'occtax.admin.config.gerer' )) {
            // Remove fake in_panier field
            unset($this->querySelectors['vm_observation']['returnFields']["'no' AS in_panier"]);
            // Add new table with join parameter to check if observation is in the basket
            $this->querySelectors['validation_panier'] = array(
                'alias' => 'vp',
                'required' => True,
                //'multi' => False,
                'join' => ' LEFT JOIN ',
                'joinClause' => "
                    ON vp.identifiant_permanent = o.identifiant_permanent
                    AND vp.usr_login = '".$this->login."' ",
                'returnFields' => array(
                    "vp.identifiant_permanent AS in_panier"=> Null,
                ),
            );

            // Add new join with occtax.validation_observation
            unset($this->querySelectors['vm_observation']['returnFields']["o.validite_niveau AS niv_val"]);
            $this->querySelectors['validation_observation'] = array(
                'alias' => 'vo',
                'required' => True,
                //'multi' => False,
                'join' => ' LEFT JOIN ',
                'joinClause' => "
                    ON vo.identifiant_permanent = o.identifiant_permanent AND ech_val = '2'",
                'returnFields' => array(
                    "CASE WHEN vo.niv_val IS NOT NULL THEN vo.niv_val ELSE '6' END AS niv_val"=> Null,
                ),
            );

            // Allow validator to see the full name of observers
            // Replace identite_observateur by identite_observateur_non_floute AS identite_observateur
        }


        parent::__construct($token, $params, $demande, $login);
    }


    /**
     * Get search description
    */
    public function getSearchDescription($format='html', $drawLegend=true){
        $description = '';
        $params = $this->getParams();
        if ( $params ) {

            // Get description for the other filter via parent class
            $parent_description = parent::getSearchDescription($format, $drawLegend);

            // Get search description for TAXON list
            $description.= $parent_description;

        }

        if( $format=='html' ){
            $titre = jLocale::get('occtax~search.description.active.filters');
            $description = "<b>$titre</b> :<br/>" . $description;
        }

        return $description;
    }

    protected function setWhereClause(){
        $sql = parent::setWhereClause();

        // Dot not query sensitive data if user has queried via spatial tools
        // to avoid guessing position of sensitive data
        $login = $this->login;
        if( !jAcl2::checkByUser($login, "visualisation.donnees.brutes") ){
            $qf = $this->queryFilters;
            $blackQueryParams = array('code_maille', 'code_masse_eau', 'code_commune');
            $qMatch = array(
                'code_maille_10' => 'm10',
                'code_commune' => 'c'
            );
            foreach( $this->params as $k=>$v ){
                if( array_key_exists( $k, $qf ) and $v and !in_array($qf[$k]['type'], array('geom'))){
                    if( in_array($k, $blackQueryParams) ){
                        $asql = '';
                        // Keep only data with open diffusion
                        $asql.= " AND ( diffusion ? 'g' ";
                        // Keep also some more data based on query type
                        if( array_key_exists($k, $qMatch) ){
                            $asql.= " OR diffusion ? '".$qMatch[$k]."' ";
                        }
                        $asql.= ' ) ';
//jLog::log($asql);
                        $sql.= $asql;

                    }
                }
            }
        }

        // Show only validated data for unlogged users
        if( !jAcl2::checkByUser($login, "visualisation.donnees.brutes") ){
            $sql.= " AND o.validite_niveau IN ( ".$this->validite_niveaux_grand_public." )";
        }

        return $sql;

    }


}

