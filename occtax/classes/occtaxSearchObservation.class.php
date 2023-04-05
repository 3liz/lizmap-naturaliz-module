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
        'id_sinp_occtax',
        'date_debut_buttons',
        'lien_nom_valide',
        'geojson',
        //'source_objet',
        'observateur',
        'validite',
        'type_diffusion',
    );

    protected $tplFields = array(
        'date_debut_buttons' => '
            {$line->date_debut}
            <br/><a class="openObservation" href="#" title="{@occtax~search.output.detail.title@}"><i class="icon-file"></i></a>
            <a class="zoomToObservation {$line->type_diffusion}" href="#" title="{jlocale "search.output.zoom.title".".".$line->type_diffusion}">
                <i class="icon-search"></i>
            </a>

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
            <span class="niv_val n{$line->niv_val_regionale}" title="{@occtax~validation.input.niv_val@}: {$line->niv_val_regionale}" >
                {$line->niv_val_text}
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
        'validite' => array( 'type' => 'string', 'sortable' => "true", 'className' => 'dt-center', 'sorting_field' => 'niv_val_text'),
    );

    protected $querySelectors = array(
        'occtax.vm_observation' => array(
            'alias' => 'o',
            'required' => True,
            'join' => '',
            'joinClause' => '',
            'returnFields' => array(
                'o.cle_obs'=> Null,
                'o.id_sinp_occtax'=> Null,
                'o.lb_nom_valide' => Null,
                'o.cd_nom' => Null,
                'o.cd_ref' => Null,
                "o.date_debut" => Null,
                "o.source_objet" => Null,
                // On ne met pas ici les champs liés à la géométrie
                // car cela dépend du statut connecté et de la diffusion
                // 'ST_AsGeoJSON( ST_Transform(o.geom, 4326), 6 ) AS geojson' => Null,
                // 'o.geom' => Null,
                "o.diffusion" => Null,
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

                "o.identite_observateur" => Null,
                "o.menace_regionale" => Null,
                "o.menace_nationale" => Null,
                "o.menace_monde" => Null,
                "o.protection" => Null,

                // Validation
                "'no' AS in_panier" => Null,
                "o.niv_val_producteur" => NULL,
                "o.validation_producteur->>'date_ctrl' AS date_ctrl_producteur" => Null,
                "o.niv_val_regionale" => Null,
                "o.validation_regionale->>'date_ctrl' AS date_ctrl_regionale" => Null,
                "o.validation_regionale->>'validateur' AS validateur_regionale" => Null,
                "(SELECT dict->>concat('validite_niveau_', Coalesce(o.niv_val_regionale, '6')) FROM occtax.v_nomenclature_plat) AS niv_val_text"=> Null,
                "o.niv_val_nationale" => Null,
                "o.validation_nationale->>'date_ctrl' AS date_ctrl_nationale" => Null,

            )
        ),

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
                'column'=>'nom_valide',
                'html'=>'<a href="#" class="getTaxonDetail cd_nom_{$item->cd_nom}">{$item->nom_valide}</a>'
            )
        ),

        'geom' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND ST_Intersects(o.geom, fg.fgeom ) ',
            'type' => 'geom'
        ),

        'date_min' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND ( o.date_debut >= @::timestamp OR o.date_fin >= @::timestamp ) ',
            'type' => 'timestamp'
        ),
        'date_max' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND ( o.date_debut <= @::timestamp OR o.date_fin <= @::timestamp ) ',
            'type' => 'timestamp'
        ),
        'code_commune' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND o.code_commune ?| ARRAY[@]',
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~commune',
                'method'=>'get',
                'column'=>'nom_commune'
            )
        ),
        'code_masse_eau' => array (
            'table' => 'occtax.vm_observation',
            'clause' => ' AND o.code_me ?| ARRAY[@]',
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
            'clause' => ' AND o.type_en ?| ARRAY[@]',
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
                'column'=>'jdd_code',
                'html'=>'<a href="#" class="getMetadata jdd_id_{$item->jdd_id}">{$item->jdd_libelle}</a>'
            )
        ),

        'niv_val_producteur' => array (
            'table' => 'occtax.vm_observation',
            'clause' => " AND o.niv_val_producteur IN ( @ )",
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~nomenclature',
                'method'=>'getValiditeNiveau',
                'column'=>'valeur',
                'html'=>'<span class="niv_val n{$item->code}">{$item->valeur}</span>'
            )
        ),
        'niv_val_regionale' => array (
            'table' => 'occtax.vm_observation',
            'clause' => " AND o.niv_val_regionale IN ( @ )",
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~nomenclature',
                'method'=>'getValiditeNiveau',
                'column'=>'valeur',
                'html'=>'<span class="niv_val n{$item->code}">{$item->valeur}</span>'
            )
        ),
        'niv_val_nationale' => array (
            'table' => 'occtax.vm_observation',
            'clause' => " AND o.niv_val_nationale IN ( @ )",
            'type' => 'string',
            'label'=> array(
                'dao'=>'occtax~nomenclature',
                'method'=>'getValiditeNiveau',
                'column'=>'valeur',
                'html'=>'<span class="niv_val n{$item->code}">{$item->valeur}</span>'
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
                'column'=>'valeur',
                'html'=>'<span class="redlist {$item->code}">{$item->valeur}</span>'
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
                'column'=>'valeur',
                'html'=>'<span class="redlist {$item->code}">{$item->valeur}</span>',
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
                'column'=>'valeur',
                'html'=>'<span class="redlist {$item->code}">{$item->valeur}</span>'
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
                'column'=>'valeur',
                'html'=>'<span class="protectionlist {$item->code}">{$item->valeur}</span>'
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

        // Gestion des champs de menace
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

        // Validation basket status, added only for people with right
        // Only needed in the observation table result, code 'observation'
        // And in the observation card
        if (in_array($this->name, array('observation', 'brute', 'single', 'export')) && $this->login) {

            // If the user can use the validation too, fetch the correct data for in_panier
            if (jAcl2::checkByUser($login, 'validation.online.access' )) {

                // Remplacement de la valeur in_panier par une recherche sur la table validation_panier
                unset($this->querySelectors['occtax.vm_observation']['returnFields']["'no' AS in_panier"]);
                // Add new table with join parameter to check if observation is in the basket
                $this->querySelectors['occtax.validation_panier'] = array(
                    'alias' => 'vp',
                    'required' => True,
                    //'multi' => False,
                    'join' => ' LEFT JOIN ',
                    'joinClause' => "
                        ON vp.id_sinp_occtax = o.id_sinp_occtax
                        AND vp.usr_login = '".$this->login."' ",
                    'returnFields' => array(
                        "vp.id_sinp_occtax AS in_panier"=> Null,
                    ),
                );

                // Change the first column to add the panier button (star)
                if (array_key_exists('date_debut_buttons', $this->tplFields)) {
                    $this->tplFields['date_debut_buttons'] .= '
                        {if !empty($line->in_panier)}{assign $action="remove"}{else}{assign $action="add"}{/if}
                        <a class="occtax_validation_button datatable" href="#{$action}@{$line->id_sinp_occtax}" title="{@occtax~validation.button.validation_basket.$action.help@}"><i class="icon-star{if empty($line->in_panier)}-empty{/if}"></i></a>
                    ';
                }

                // We must use a JOIN from the v_validation_regionale
                // To retrieve dynamic data and not use vm_observation
                // vm_observation
                // unset($this->querySelectors['occtax.vm_observation']['returnFields']["o.validation_regionale"]);
                unset($this->querySelectors['occtax.vm_observation']['returnFields']["o.niv_val_regionale"]);
                unset($this->querySelectors['occtax.vm_observation']['returnFields']["o.validation_regionale->>'date_ctrl' AS date_ctrl_regionale"]);
                unset($this->querySelectors['occtax.vm_observation']['returnFields']["o.validation_regionale->>'validateur' AS validateur_regionale"]);
                unset($this->querySelectors['occtax.vm_observation']['returnFields']["(SELECT dict->>concat('validite_niveau_', Coalesce(o.niv_val_regionale, '6')) FROM occtax.v_nomenclature_plat) AS niv_val_text"]);
                // queryFilters
                $this->querySelectors['occtax.v_validation_regionale'] = array(
                    'alias' => 'oo',
                    'required' => True,
                    'join' => ' LEFT JOIN ',
                    'joinClause' => "
                        ON oo.id_sinp_occtax = o.id_sinp_occtax ",
                    'returnFields' => array(
                        'oo.niv_val_regionale' => Null,
                        'oo.date_ctrl_regionale' => Null,
                        "(SELECT dict->>concat('validite_niveau_', Coalesce(oo.niv_val_regionale, '6'))
                        FROM occtax.v_nomenclature_plat) AS niv_val_text"=> Null,
                        "(
                            SELECT concat(
                                identite,
                                CASE
                                    WHEN organisme IS NULL OR organisme = '' THEN ''
                                    ELSE ' (' || organisme|| ')'
                                END
                            ) AS validateur
                            FROM occtax.v_validateurs AS ovv
                            WHERE ech_val = '2' AND ovv.id_sinp_occtax = oo.id_sinp_occtax
                            LIMIT 1

                        ) AS validateur_regionale" => Null,

                    ),
                );
                $this->queryFilters['niv_val_regionale']['table'] = 'occtax.v_validation_regionale';
                $this->queryFilters['niv_val_regionale']['clause'] = " AND oo.niv_val_regionale IN ( @ )";

            }

            // Allow validator to see the full name of observers
            // Replace identite_observateur by identite_observateur_non_floute AS identite_observateur
            // todo
        }

        // Manage geometries
        // We do it here because it is used by the setSql method
        // We need to modify the returnFields of the querySelector depending on rights
        $this->setReturnedGeometryFields();

        parent::__construct($token, $params, $demande, $login);
    }

    /**
     * Récupération des champs de géométrie en fonction du statut de connexion
     * et de la diffusion des données
     * Chaque classe héritée doit gérer son propre jeu de champs
     * Par ex: geojson, wkt, etc.
     *
     */
    protected function setReturnedGeometryFields()
    {
        if (!jAcl2::checkByUser($this->login, "visualisation.donnees.brutes") ) {
            // On ne peut pas voir toutes les données brutes = GRAND PUBLIC
            if (jAcl2::checkByUser($this->login, "export.geometries.brutes.selon.diffusion")) {
                // on peut voir les géométries si la diffusion est 'g'
                $geom_expression = " CASE WHEN diffusion ? 'g' ";
                $geom_expression.= " THEN o.geom ";
                $geom_expression.= " ELSE NULL::geometry(point, 4326) ";
                $geom_expression.= " END AS geom";

                $geojson_expression = " CASE WHEN diffusion ? 'g' ";
                $geojson_expression.= " THEN ST_AsGeoJSON( ST_Transform(o.geom, 4326), 6 ) ";
                $geojson_expression.= " ELSE NULL::text ";
                $geojson_expression.= " END AS geojson";
                // Utiliser comme avant la maille 10 au lieu de NULL pour le GeoJSON ?
                //(SELECT ST_AsGeoJSON(ST_Transform(m.geom, 1) FROM sig.maille_10 m WHERE ST_Intersects(lg.geom, m.geom) LIMIT 1)::jsonb As geometry,
            }else{
                // on ne peut pas voir les géométries même si la diffusion le permet
                $geom_expression = " NULL::geometry(point, 4326) AS geom";
                $geojson_expression = "NULL::text AS geojson";
            }
        }else{
            // On peut voir toutes les données brutes: admins ou personnes avec demandes
            $geom_expression = "o.geom";
            $geojson_expression = "ST_AsGeoJSON( ST_Transform(o.geom, 4326), 6 ) AS geojson";
        }

        // On défini l'expression pour le GeoJSON dans le querySelectors
        $this->querySelectors['occtax.vm_observation']['returnFields'][$geom_expression] = Null;
        $this->querySelectors['occtax.vm_observation']['returnFields'][$geojson_expression] = Null;
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
            $description = "<b>$titre</b> :<br/>".$description;
        }

        return $description;
    }

    protected function setWhereClause(){
        $sql = parent::setWhereClause();

        // Dot not query sensitive data if user has queried via spatial tools
        // to avoid guessing position of sensitive data
        // Pour les mailles, pas de souci
        if( !jAcl2::checkByUser($this->login, "visualisation.donnees.brutes") ){
            // Paramètres sensibles
            // NB: code_maille est utilisé pour les requêtes par maille 01, 02 et 10
            $blackQueryParams = array(
                'code_maille',
                // la maille n'est plus passée en code mais utilisée comme géométrie
                // dans queryFilter, plus de code_maille du coup pas besoin ici normalement
                'code_masse_eau',
                'code_commune'
            );
            $matchDiffusionCodeFromParam = array(
                'code_maille_10' => 'm10',
                'code_commune' => 'c',
                'code_masse_eau' => 'c',
                // on considère qu'une masse d'eau est comme une commune
                // car pas de code 'me' dans le champ diffusion
            );

            // On boucle sur les paramètres
            foreach( $this->params as $param=>$v ){
                if( array_key_exists($param, $this->queryFilters)
                    && $v
                    && !in_array($this->queryFilters[$param]['type'], array('geom'))
                ){
                    // Si le paramètre passé est dans la liste sensible
                    // on ajoute un filtre pour ne montrer que les données 'g' et
                    if( in_array($param, $blackQueryParams) ){
                        $filterSql = '';
                        // Keep only data with open diffusion
                        $filterSql.= " AND ( o.diffusion ? 'g' ";
                        // Keep also some more data based on query type
                        if( array_key_exists($param, $matchDiffusionCodeFromParam) ){
                            $filterSql.= " OR o.diffusion ? '".$matchDiffusionCodeFromParam[$param]."' ";
                        }
                        $filterSql.= ' ) ';
                        // \jLog::log($filterSql);
                        $sql.= $filterSql;

                    }
                }
            }
        }

        // Show only validated data for unauthenticated users ("grand public")
        // Désactivé pour passage en OpenData en mars 2023 : le public doit pouvoir
        // avoir accès à toutes les données
        // if( !jAcl2::checkByUser($this->login, "visualisation.donnees.brutes") ){
        //     $sql.= " AND niv_val_regionale IN ( ".$this->validite_niveaux_grand_public." ) ";
        // }

        return $sql;

    }


}
