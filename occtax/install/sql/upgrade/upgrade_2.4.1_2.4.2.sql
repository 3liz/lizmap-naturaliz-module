DROP VIEW IF EXISTS occtax.v_nomenclature_plat CASCADE;
CREATE VIEW occtax.v_nomenclature_plat AS
WITH source AS (
    SELECT
    concat(o.champ, '_', o.code) AS k, o.valeur AS v
    FROM occtax.nomenclature AS o
    UNION ALL
    SELECT concat(replace(t.champ, 'statut_taxref', 'loc'), '_', t.code) AS k, t.valeur AS v
    FROM taxon.t_nomenclature AS t
)
SELECT
json_object(
    array_agg(k) ,
    array_agg(v)
) AS dict
FROM source
;
