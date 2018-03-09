-- Ajout des données de recherche plein texte
BEGIN;

-- Mise à jour des vues matérialisées
REFRESH MATERIALIZED VIEW taxref_valide;
REFRESH MATERIALIZED VIEW taxref_fts;

-- Donnees complementaires
DELETE FROM t_complement WHERE cd_nom_fk IN (SELECT cd_nom FROM taxref);
INSERT INTO t_complement
(
    cd_nom_fk,
    statut,
--    rarete,
    endemicite,
    invasibilite
)
SELECT cd_nom,

-- statut
CASE
        WHEN {$colonne_locale} IN ('I', 'J', 'M') THEN 'E'
        WHEN {$colonne_locale} IN ('P', 'S', 'E') THEN 'I'
        ELSE NULL
END AS statut,

-- rarete : COMMENTE CAR SUJET A DEBAT
-- CASE
        -- WHEN {$colonne_locale} IN ('B', 'M') THEN 'R'
        -- WHEN {$colonne_locale} IN ('E', 'I', 'J', 'P', 'S') THEN 'C'
        -- WHEN {$colonne_locale} IN ('C') THEN 'E'
        -- ELSE NULL
-- END AS rarete,

-- endemicite
CASE
        WHEN {$colonne_locale} IN ('E', 'Z') THEN 'E'
        WHEN {$colonne_locale} IN ('S') THEN 'S'
        ELSE NULL
END AS endemicite,

-- invasibilite
CASE
    WHEN reu IN ('J') THEN 'E' -- envahissant
    ELSE NULL
END AS invasibilite

FROM taxref_valide
;

-- Adaptation de la nomenclature au contexte local
UPDATE t_nomenclature SET description = '{$endemicite_description_endemique}' WHERE champ = 'endemicite' AND code = 'E';
UPDATE t_nomenclature SET description = '{$endemicite_description_subendemique}' WHERE champ = 'endemicite' AND code = 'S';


-- Menaces
TRUNCATE menaces RESTART IDENTITY;
COPY menaces
FROM '{$menace}' DELIMITER ',' CSV;

-- INSERT taxon pas encore présents dans t_complement
INSERT INTO t_complement (cd_nom_fk, menace)
SELECT DISTINCT b.cd_nom, a.categorie_france
FROM menaces a
INNER JOIN taxref b ON a.cd_nom = b.cd_nom
WHERE NOT EXISTS (SELECT cd_nom_fk FROM t_complement)
;

-- UPDATE tous les taxons qui ont une menace
UPDATE t_complement c
SET menace = a.categorie_france
FROM menaces a
INNER JOIN taxref b ON a.cd_nom = b.cd_nom
WHERE c.cd_nom_fk = b.cd_nom
AND a.categorie_france IS NOT NULL
;


-- PROTECTION
TRUNCATE TABLE protections RESTART IDENTITY;
COPY protections FROM '{$protection}' DELIMITER ',' HEADER CSV;


-- INSERT taxon pas encore présents dans t_complement
INSERT INTO t_complement (cd_nom_fk, protection)
SELECT DISTINCT a.cd_nom::integer,
CASE
    WHEN a.cd_protection IN ({$code_arrete_protection_nationale}) THEN 'EPN'
    WHEN a.cd_protection IN ({$code_arrete_protection_internationale}) THEN 'EPI'
    WHEN a.cd_protection IN ({$code_arrete_protection_communautaire}) THEN 'EPC'
    WHEN a.cd_protection IN ({$code_arrete_protection_simple}) THEN 'EPA'
    ELSE NULL
END AS "protection"
FROM protections a
WHERE NOT EXISTS (SELECT cd_nom_fk FROM t_complement)
AND a.cd_protection IN (
    {$code_arrete_protection_simple},
    {$code_arrete_protection_nationale},
    {$code_arrete_protection_internationale},
    {$code_arrete_protection_communautaire}
)
;

-- UPDATE tous les taxons qui ont une protection
UPDATE t_complement c
SET protection =
CASE
    WHEN a.cd_protection IN ({$code_arrete_protection_nationale}) THEN 'EPN'
    WHEN a.cd_protection IN ({$code_arrete_protection_internationale}) THEN 'EPI'
    WHEN a.cd_protection IN ({$code_arrete_protection_communautaire}) THEN 'EPC'
    WHEN a.cd_protection IN ({$code_arrete_protection_simple}) THEN 'EPA'
    ELSE NULL
END
FROM protections a
WHERE c.cd_nom_fk::text = a.cd_nom
AND a.cd_protection IN (
    {$code_arrete_protection_simple},
    {$code_arrete_protection_nationale},
    {$code_arrete_protection_internationale},
    {$code_arrete_protection_communautaire}
)
;


REFRESH MATERIALIZED VIEW taxref_consolide;
REFRESH MATERIALIZED VIEW taxref_consolide_all;

COMMIT;
