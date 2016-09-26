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

class occtaxSearchObservationTaxon extends occtaxSearchObservation {

    protected $returnFields = array(
        'cd_nom',
        'nom_valide',
        'nom_vern',
        'nbobs',
        'groupe',
        'inpn',
        'filter'
    );

    protected $tplFields = array(
        'groupe' => '<img src="{$j_basepath}css/images/taxon/{$line->categorie}.png" width="30px" title="{$line->categorie}"/>',

        'inpn' => '<a href="http://inpn.mnhn.fr/espece/cd_nom/{$line->cd_nom}" target="_blank" title="{@occtax~search.output.inpn.title@}"><i class="icon-info-sign">&nbsp;</i></a>',

        'filter' => '<a class="filterByTaxon" href="#" title="{@occtax~search.output.filter.taxon.title@}"><i class="icon-filter"></i></a>'

    );

    protected $row_id = 'cd_nom';
    protected $row_label = 'nom_valide';

    protected $displayFields = array(
        'nom_valide' => array( 'type' => 'string', 'sortable' => "true"),
        'nom_vern' => array( 'type' => 'string', 'sortable' => "true"),
        'nbobs' => array( 'type' => 'num', 'sortable' => "true"),
        'groupe' => array( 'type' => 'string', 'sortable' => "true"),
        'inpn' => array( 'type' => 'string', 'sortable' => 0),
        'filter' => array( 'type' => 'string', 'sortable' => 0)
    );

    public function __construct ($id, $params=Null) {

        // Remove unnecessary LEFT JOIN to improve performances
        $this->querySelectors['localisation_maille_05']['required'] = False;
        $this->querySelectors['localisation_maille_10']['required'] = False;
        $this->querySelectors['localisation_commune']['required'] = False;
        $this->querySelectors['localisation_masse_eau']['required'] = False;
        $this->querySelectors['v_localisation_espace_naturel']['required'] = False;
        $this->querySelectors['observation']['returnFields'] = array(
            'o.cle_obs'=> 'cle_obs',
            'o.nom_cite' => 'nom_cite',
            'o.cd_nom' => 'cd_nom',
            "to_char(date_debut, 'YYYY-MM-DD') AS date_debut" => 'date_debut',
            'o.cle_objet'=> 'cle_objet',
            'o.identite_observateur' => 'identite_observateur'
        );
        // Remove ORDER BY
        $this->orderClause = '';


        parent::__construct($id, $params);
    }

    function setSql() {
        parent::setSql();

        $sql = " SELECT f.cd_nom, t.nom_valide, count(DISTINCT cle_obs) AS nbobs,";
        $sql.= " t.nom_vern,";
        $sql.= " (regexp_split_to_array( Coalesce( g1.cat_nom, g2.cat_nom) , ' '))[1] AS categorie";
        $sql.= " FROM (";
        $sql.= $this->sql;
        $sql.= " ) AS f";
        $sql.= " INNER JOIN taxref_consolide t ON t.cd_nom = f.cd_nom";
        $sql.= " LEFT JOIN t_group_categorie g1 ON g1.groupe_nom = t.group1_inpn";
        $sql.= " LEFT JOIN t_group_categorie g2 ON g2.groupe_nom = t.group2_inpn";
        $sql.= ' GROUP BY f.cd_nom, t.nom_valide, categorie, t.nom_vern';
        $sql.= ' ORDER BY t.nom_valide';

        $this->sql = $sql;
    }

    protected function getResult( $limit=50, $offset=0, $order='' ) {
        //~ jLog::log($this->sql);
        $cnx = jDb::getConnection();
        return $cnx->query( $this->sql );
    }
}

