<?php

/**
 * @package   lizmap
 * @subpackage occtax
 * @author    Michael Douchin
 * @copyright 2021 3liz
 * @link      http://3liz.com
 * @license    All rights reserved
 */

class autocomplete
{

    /**
     * Construct the SQL query
     *
     * @param string $searchType If 'filter', return data corresponding to the given term
     *                           else return all data
     * @return string SQL query
     */
    protected function getSql($searchType = 'filter')
    {
        if ($searchType == 'filter') {
            $sql = "
                SELECT
                    *, ts_headline(foo.val, query) AS label
                FROM
                (
                    SELECT jdd_id, jdd_libelle, jdd_description,
                    concat(jdd_id, ' - ', jdd_libelle) AS val,
                    ts_rank(
                        to_tsvector(unaccent(coalesce(concat(jdd_id, ' ', jdd_libelle, ' ', jdd_description ),'')) )::tsvector,
                        query
                    ) AS rnk,
                    query,
                    similarity(trim( $1 ), concat(jdd_id, ' ', jdd_libelle, ' ', jdd_description )) AS sim
                    FROM occtax.jdd AS j,
                    to_tsquery('french_text_search', regexp_replace( unaccent( trim( $1 ) ), '[^0-9a-zA-Z]+', ' & ', 'g') || ':*' ) AS query

                    WHERE True
                    AND query @@ to_tsvector( unaccent(coalesce(concat(jdd_id, ' ', jdd_libelle, ' ', jdd_description ),'')) )::tsvector
                    ORDER BY sim DESC, rnk DESC
                    LIMIT $2
                ) foo
            ";
        } else {
            $sql = "
                SELECT jdd_id, jdd_libelle, jdd_description,
                concat(jdd_id, ' - ', jdd_libelle) AS label,
                1 AS rnk,
                NULL AS query,
                1 AS sim
                FROM occtax.jdd AS j
                WHERE True
                ORDER BY jdd_libelle
                LIMIT $1
            ";
        }

        return $sql;
    }

    /**
     * Get data from database and return an array
     * @param $sql Query to run
     * @param $profile Name of the DB profile
     * @return Result as an array
     */
    function query($sql, $filterParams, $profile = null)
    {
        $cnx = jDb::getConnection($profile);
        $resultset = $cnx->prepare($sql);

        $resultset->execute($filterParams);
        return $resultset->fetchAll();
    }

    /**
     * Method called by the autocomplete input field for taxon search
     * @param $term Searched term
     * @return List of matching taxons
     */
    function getData($term, $limit = 50)
    {
        if (trim($term) == '') {
            $sql = $this->getSql('all');
            $filterParams = array($limit);
        } else {
            $sql = $this->getSql('filter');
            $filterParams = array($term, $limit);
        }

        $return = $this->query($sql, $filterParams);
        return $return;
    }
}
