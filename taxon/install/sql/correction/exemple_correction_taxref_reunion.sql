
BEGIN;

CREATE TEMPORARY TABLE correction_taxref
(cd_nom bigint, cd_ref bigint, nom_complet text, reu text, nom_vern text, langue text, iso text, pays text)
ON COMMIT DROP;
;

COPY correction_taxref
(cd_nom, cd_ref, nom_complet, reu, nom_vern, langue, iso, pays)
FROM '{$source}' DELIMITER ',' HEADER CSV
;

UPDATE taxref t SET nom_vern = c.nom_vern
FROM correction_taxref c
WHERE c.cd_nom = t.cd_nom;

RESET client_encoding;

COMMIT;
