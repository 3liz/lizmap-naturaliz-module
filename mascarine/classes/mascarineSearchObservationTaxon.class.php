<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

jClasses::inc('mascarine~mascarineSearchObservation');

class mascarineSearchObservationTaxon extends mascarineSearchObservation {

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

        'inpn' => '<a href="http://inpn.mnhn.fr/espece/cd_nom/{$line->cd_nom}" target="_blank" title="{@mascarine~search.output.inpn.title@}"><i class="icon-info-sign">&nbsp;</i></a>',

        'filter' => '<a class="filterByTaxon" href="#" title="{@mascarine~search.output.filter.taxon.title@}"><i class="icon-filter"></i></a>'

    );

    protected $row_id = 'cd_nom';
    protected $row_label = 'nom_valide';

    protected $displayFields = array(
        'nom_valide' => array( 'type' => 'string', 'sortable' => "true"),
        'nom_vern' => array( 'type' => 'string', 'sortable' => "true"),
        'nbobs' => array( 'type' => 'num', 'sortable' => "true"),
        'groupe' => array( 'type' => 'string', 'sortable' => "true"),
        'inpn' => array( 'type' => 'string', 'sortable' => "0"),
        'filter' => array( 'type' => 'string', 'sortable' => "0")
    );

    function setSql() {
        parent::setSql();

        $sql = " SELECT f.cd_nom, f.nom_valide, count(DISTINCT id_obs) AS nbobs,";
        $sql.= " f.nom_vern,";
        $sql.= " (regexp_split_to_array( Coalesce( g1.cat_nom, g2.cat_nom) , ' '))[1] AS categorie";
        $sql.= " FROM (";
        $sql.= $this->sql;
        $sql.= " ) AS f";
        $sql.= " INNER JOIN taxref_consolide t ON t.cd_nom = f.cd_nom AND regne='Plantae'";
        $sql.= " LEFT JOIN t_group_categorie g1 ON g1.groupe_nom = t.group1_inpn";
        $sql.= " LEFT JOIN t_group_categorie g2 ON g2.groupe_nom = t.group2_inpn";$sql.= ' GROUP BY f.cd_nom, f.nom_valide, categorie, f.nom_vern';
        $sql.= ' ORDER BY f.cd_nom';

        $this->sql = $sql;
    }

    protected function getResult( $limit=50, $offset=0, $order="" ) {
        //~ jLog::log($this->sql);

        $cnx = jDb::getConnection();
        return $cnx->query( $this->sql );
    }
}

