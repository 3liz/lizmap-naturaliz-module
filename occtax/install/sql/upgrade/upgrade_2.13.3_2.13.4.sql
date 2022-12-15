-- Suppression d'une règle inutile sur les dénombrements non null
DELETE FROM occtax.critere_conformite 
WHERE code IN ('obs_denombrement_min_not_null', 'obs_denombrement_max_not_null')
AND type_critere = 'not_null'
;
