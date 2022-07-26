-- Index sur le champ odata de occtax.observation
DROP INDEX IF EXISTS observation_odata_import_time;
CREATE INDEX observation_odata_import_time ON occtax.observation USING gin (odata);
