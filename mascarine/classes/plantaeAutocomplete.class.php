<?php
/**
* @package   lizmap
* @subpackage mascarine
* @author    Michaël Douchin
* @copyright 2014 3liz
* @link      http://3liz.com
* @license    All rights reserved
*/

jClasses::inc('taxon~autocomplete');

class plantaeAutocomplete extends autocomplete {

    protected function getSql() {
        $sql = "
            SELECT foo.cd_nom AS value, foo.nom_valide, ts_headline(foo.val, query) AS label, foo.cd_ref, CASE
                WHEN cat.cat_nom IS NOT NULL THEN (regexp_split_to_array(cat.cat_nom, ' '))[1]
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
                FROM taxref_fts f
        ";
        // On fait une jointure sur TAXREF pour filtrer seulement les Plantae
        // On le fait sur tout TAXREF pour avoir les taxons valides et les non valides
        // on ne le fait pas sur taxref_consolide car ce dernier ne contient que les taxons valides (et on veut les synonymes pour l'autocomplétion)
        $sql.= "
                INNER JOIN
                (
                    SELECT nom_valide, cd_nom, cd_ref
                    FROM taxref
                    WHERE regne = 'Plantae'
                    UNION ALL
                    SELECT nom_valide, cd_nom, cd_ref
                    FROM taxref_local
                    WHERE regne = 'Plantae'
                ) AS t
                ON (f.cd_nom = t.cd_nom AND f.cd_ref = t.cd_ref),
        ";

        $sql.= "
                to_tsquery('french_text_search', regexp_replace( unaccent( trim( $1 ) ), '[^0-9a-zA-Z]+', ' & ', 'g') || ':*' ) AS query
                WHERE query @@ vec
                ORDER BY sim DESC, poids DESC, rnk DESC
                LIMIT $2
            ) foo LEFT JOIN t_group_categorie cat ON cat.groupe_nom = foo.group2_inpn
        ";
        return $sql;
    }
}
