<?php
/**
* @package   lizmap
* @subpackage taxon
* @author    Michael Douchin
* @copyright 2011 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

class autocomplete {


    protected $separator = '=';

    protected function getSql($taxons_locaux='true', $taxons_bdd='true') {
        $sql = "
            SELECT foo.cd_nom AS value, foo.nom_valide, ts_headline(foo.val, query) AS label, foo.cd_ref, CASE
                WHEN cat.cat_nom IS NOT NULL THEN lower(unaccent((regexp_split_to_array(cat.cat_nom, ' '))[1]))
                ELSE 'no_image'
            END AS groupe
            FROM
            (
                SELECT f.cd_nom, f.cd_ref, f.nom_valide, f.group2_inpn,
                CASE
                        WHEN f.val = f.nom_valide THEN f.val
                        ELSE f.val || ' " . $this->separator . " ' || f.nom_valide
                END AS val,
                ts_rank(vec, query) AS rnk,
                query,
                similarity(trim( $1 ), val) AS sim
                FROM taxon.taxref_fts f,
                to_tsquery('french_text_search', regexp_replace( unaccent( trim( $1 ) ), '[^0-9a-zA-Z]+', ' & ', 'g') || ':*' ) AS query
        ";

        // Where
        $sql.= "
                WHERE True
        ";

        // Get only taxons locaux
        if($taxons_locaux == 'true'){
            $sql.= "
            AND f.loc IS NOT NULL AND f.loc NOT IN ('Q', 'A')
            ";
        }
        // Get only taxon in data
        if($taxons_bdd == 'true'){
            $sql.= "
            AND f.cd_ref IN (SELECT DISTINCT o.cd_ref FROM vm_observation o)
            ";
        }
        $sql.= "
                AND query @@ vec
                ORDER BY sim DESC, poids DESC, rnk DESC
                LIMIT $2
            ) foo LEFT JOIN taxon.t_group_categorie cat ON cat.groupe_nom = foo.group2_inpn
        ";
        return $sql;
    }

    /**
    * Get data from database and return an array
    * @param $sql Query to run
    * @param $profile Name of the DB profile
    * @return Result as an array
    */
    function query( $sql, $filterParams, $profile=null ) {
        $cnx = jDb::getConnection( $profile );
        $resultset = $cnx->prepare( $sql );

        $resultset->execute( $filterParams );
        return $resultset->fetchAll();
    }

    /**
    * Method called by the autocomplete input field for taxon search
    * @param $term Searched term
    * @return List of matching taxons
    */
    function getData($term, $limit=15, $taxons_locaux='true', $taxons_bdd='true') {

        $sql = $this->getSql($taxons_locaux, $taxons_bdd);

        $return = $this->query( $sql, array( $term, $limit) );
        return $return;
    }

}
