BEGIN;
-- from 2.1.0 to 2.1.1

ALTER TABLE gestion.demande
    ALTER geom DROP NOT NULL,
    ALTER libelle_geom DROP NOT NULL
;

ALTER TABLE gestion.demande ALTER COLUMN geom type geometry(MultiPolygon, {$SRID}) using ST_Multi(geom);

COMMIT;
