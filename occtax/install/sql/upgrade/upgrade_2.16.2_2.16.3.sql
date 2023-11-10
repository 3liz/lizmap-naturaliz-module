-- Remplacement du test d'intersection sur les mailles 10
UPDATE occtax.critere_conformite
SET condition = $$
ST_Intersects(
    (SELECT ST_union(geom) FROM sig.maille_10),
    ST_Transform(
        ST_SetSRID(ST_MakePoint(o.longitude::real, o.latitude::real), __SOURCE_SRID__),
        (SELECT srid FROM geometry_columns WHERE f_table_schema = 'occtax' AND f_table_name = 'observation')
    )
)$$
WHERE code = 'obs_geometrie_localisation_dans_maille'
;

DROP FUNCTION IF EXISTS occtax.intersects_maille_10(real, real, integer);
