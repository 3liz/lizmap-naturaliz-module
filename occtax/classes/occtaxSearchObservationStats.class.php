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

class occtaxSearchObservationStats extends occtaxSearchObservation {

    protected $maille = 'maille_02';

    protected $returnFields = array(
        'categorie',
        'categorie_image',
        'categorie_nom',
        'nbobs',
        //~ 'nb_maille',  // deactivate as the query is not optimized
        'nb_taxon_present',
        'nb_taxon_protege',
        'nb_taxon_determinant'
    );

    protected $tplFields = array(

        'categorie_image' => '<img src="{$j_basepath}css/images/taxon/{$line->categorie}.png" width="20px" title="{$line->categorie}"/>',

        'categorie_nom' => '<b>{$line->categorie}</b>'
    );

    protected $row_id = 'categorie';

    protected $displayFields = array(
        'categorie_image' => array( 'type' => 'string', 'sortable' => 0),
        'categorie_nom' => array( 'type' => 'string', 'sortable' => "true"),
        'nbobs' => array( 'type' => 'num', 'sortable' => "true"),
        //~ 'nb_maille' => array( 'type' => 'num', 'sortable' => "true"),
        'nb_taxon_present' => array( 'type' => 'num', 'sortable' => "true"),
        'nb_taxon_protege' => array( 'type' => 'num', 'sortable' => "true"),
        'nb_taxon_determinant' => array( 'type' => 'num', 'sortable' => "true")
    );

    public function __construct ($token=Null, $params=Null, $demande=Null) {
        // Set maille depending on rights
        // do it first because parent::__construct do setSql
        if ( jAcl2::check("visualisation.donnees.maille_01") )
            $this->maille = 'maille_01';

        // Remove unnecessary LEFT JOIN to improve performances
        $this->querySelectors['localisation_maille_05']['required'] = False;
        $this->querySelectors['localisation_maille_10']['required'] = False;
        $this->querySelectors['localisation_commune']['required'] = False;
        $this->querySelectors['localisation_departement']['required'] = False;
        $this->querySelectors['localisation_masse_eau']['required'] = False;
        $this->querySelectors['v_localisation_espace_naturel']['required'] = False;
        $this->querySelectors['observation']['returnFields'] = array(
            'o.cle_obs'=> 'cle_obs',
            'o.nom_cite' => 'nom_cite',
            'o.cd_nom' => 'cd_nom',
            "to_char(date_debut, 'YYYY-MM-DD') AS date_debut" => 'date_debut'
        );
        $this->querySelectors['v_observateur']['returnFields'] = array(
            "string_agg(pobs.identite, ', ') AS identite_observateur" => 'identite_observateur'
        );
        // Remove ORDER BY
        $this->orderClause = '';

        parent::__construct($token, $params, $demande);
    }

    protected function setSql() {
        parent::setSql();

        // Get maille type (1 or 2)
        $m = substr( $this->maille, -1 );

        $sql = " SELECT (regexp_split_to_array( Coalesce( tgc1.cat_nom, tgc2.cat_nom, 'Autres' ), ' '))[1] AS categorie,";
        $sql.= " Count(DISTINCT f.cle_obs) AS nbobs,";
        //~ $sql.= " Count(DISTINCT m.id_maille) AS nb_maille,";
        $sql.= " Count(DISTINCT f.cd_nom) AS nb_taxon_present,";
        $sql.= " Count(DISTINCT t1.cd_nom) AS nb_taxon_protege,";
        $sql.= " Count(DISTINCT t2.cd_nom) AS nb_taxon_determinant";
        $sql.= " FROM (";
        $sql.= $this->sql;
        $sql.= " ) AS f";
        //~ $sql.= ' LEFT JOIN "' . $this->maille .'" AS m ON ST_Intersects( f.geom, m.geom ) ';
        $sql.= " LEFT JOIN taxref_consolide AS t ON t.cd_nom = f.cd_nom";
        $sql.= " LEFT JOIN taxref_consolide AS t1 ON t1.cd_nom = f.cd_nom AND t1.protection IN ('EP')";
        $sql.= " LEFT JOIN taxref_consolide AS t2 ON t2.cd_nom = f.cd_nom AND t2.det_znieff IN ('1')";
        $sql.= " LEFT JOIN t_group_categorie tgc1 ON tgc1.groupe_nom = t.group1_inpn AND tgc1.groupe_type = 'group1_inpn'";
        $sql.= " LEFT JOIN t_group_categorie tgc2 ON tgc2.groupe_nom = t.group2_inpn AND tgc2.groupe_type = 'group2_inpn'";
        $sql.= " GROUP BY tgc1.cat_nom, tgc2.cat_nom";
        $sql.= " ORDER BY categorie";

        $this->sql = $sql;
    }
    protected function getResult( $limit=50, $offset=0, $order="" ) {
        //~ jLog::log($this->sql);
        $cnx = jDb::getConnection();
        return $cnx->query( $this->sql );
    }
}

