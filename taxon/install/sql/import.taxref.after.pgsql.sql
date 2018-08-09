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
-- ON INSERE AUSSI LES SYNONYMES
WITH s AS (
    SELECT DISTINCT t.cd_nom, m.categorie_france AS menace
    FROM taxon.taxref t
    INNER JOIN taxon.menaces m ON m.cd_nom = t.cd_nom OR m.cd_nom = t.cd_ref OR m.cd_ref = t.cd_ref
    WHERE TRUE
)
INSERT INTO t_complement (cd_nom_fk, menace)
SELECT DISTINCT s.cd_nom, s.menace
FROM s
ON CONFLICT (cd_nom_fk)
DO NOTHING;

-- UPDATE tous les taxons déjà présent dans t_complement mais avec menace différente
WITH s AS (
    SELECT DISTINCT t.cd_nom, m.categorie_france AS menace
    FROM taxon.taxref t
    INNER JOIN taxon.menaces m ON m.cd_nom = t.cd_nom OR m.cd_nom = t.cd_ref OR m.cd_ref = t.cd_ref
    WHERE TRUE
)
UPDATE t_complement c
SET menace = s.menace
FROM s
WHERE c.cd_nom_fk = s.cd_nom AND (c.menace != s.menace OR c.menace IS NULL);


-- PROTECTION
TRUNCATE TABLE protections RESTART IDENTITY;
COPY protections FROM '{$protection}' DELIMITER ',' HEADER CSV;



-- INSERT taxon pas encore présents dans t_complement
-- LES SYNONYMES SONT INCLUS VIA CLAUSE WITH
WITH ss AS (
    SELECT DISTINCT t.cd_nom,
    CASE
        WHEN p.cd_protection IN ({$code_arrete_protection_nationale}) THEN 'EPN'
        WHEN p.cd_protection IN ({$code_arrete_protection_communautaire}) THEN 'EPC'
        WHEN p.cd_protection IN ({$code_arrete_protection_internationale}) THEN 'EPI'
        WHEN p.cd_protection IN ({$code_arrete_protection_simple}) THEN 'EPA'
        ELSE NULL
    END AS "protection",
    CASE
        WHEN p.cd_protection IN ({$code_arrete_protection_nationale}) THEN 0
        WHEN p.cd_protection IN ({$code_arrete_protection_communautaire}) THEN 1
        WHEN p.cd_protection IN ({$code_arrete_protection_internationale}) THEN 2
        WHEN p.cd_protection IN ({$code_arrete_protection_simple}) THEN 3
        ELSE NULL
    END AS "note"
    FROM taxon.taxref t
    INNER JOIN taxon.protections p ON p.cd_nom::integer = t.cd_nom OR p.cd_nom::integer = t.cd_ref
    WHERE TRUE
    AND p.cd_protection IN (
        {$code_arrete_protection_simple},
        {$code_arrete_protection_nationale},
        {$code_arrete_protection_internationale},
        {$code_arrete_protection_communautaire}
    )
),
s AS (
 SELECT DISTINCT cd_nom, FIRST_VALUE(protection) OVER (PARTITION BY cd_nom ORDER BY note) AS protection
 FROM ss
)
INSERT INTO t_complement (cd_nom_fk, protection)
SELECT DISTINCT s.cd_nom, s."protection"
FROM s
ON CONFLICT (cd_nom_fk)
DO NOTHING
;
-- UPDATE tous les taxons qui ont une protection
WITH ss AS (
    SELECT DISTINCT t.cd_nom,
    CASE
        WHEN p.cd_protection IN ({$code_arrete_protection_nationale}) THEN 'EPN'
        WHEN p.cd_protection IN ({$code_arrete_protection_communautaire}) THEN 'EPC'
        WHEN p.cd_protection IN ({$code_arrete_protection_internationale}) THEN 'EPI'
        WHEN p.cd_protection IN ({$code_arrete_protection_simple}) THEN 'EPA'
        ELSE NULL
    END AS "protection",
    CASE
        WHEN p.cd_protection IN ({$code_arrete_protection_nationale}) THEN 0
        WHEN p.cd_protection IN ({$code_arrete_protection_communautaire}) THEN 1
        WHEN p.cd_protection IN ({$code_arrete_protection_internationale}) THEN 2
        WHEN p.cd_protection IN ({$code_arrete_protection_simple}) THEN 3
        ELSE NULL
    END AS "note"
    FROM taxon.taxref t
    INNER JOIN taxon.protections p ON p.cd_nom::integer = t.cd_nom OR p.cd_nom::integer = t.cd_ref
    WHERE TRUE
    AND p.cd_protection IN (
        {$code_arrete_protection_simple},
        {$code_arrete_protection_nationale},
        {$code_arrete_protection_internationale},
        {$code_arrete_protection_communautaire}
    )
),
s AS (
 SELECT DISTINCT cd_nom, FIRST_VALUE(protection) OVER (PARTITION BY cd_nom ORDER BY note) AS protection
 FROM ss
)
UPDATE t_complement c
SET protection = s.protection
FROM s
WHERE c.cd_nom_fk = s.cd_nom AND (c.protection != s.protection OR c.protection IS NULL)
;

-- Noms vernaculaires
-- TAXVERN
{if $taxvern}
TRUNCATE TABLE taxon.taxvern RESTART IDENTITY;
COPY taxon.taxvern FROM '{$taxvern}' DELIMITER E'\t' HEADER CSV;

UPDATE taxon.taxref t
SET nom_vern =
CASE
    WHEN nom_vern IS NULL OR trim(nom_vern) = '' THEN trim(v.lb_vern)
    ELSE concat(
        trim(nom_vern),
        ', ',
        trim(replace(trim(v.lb_vern), trim(nom_vern), ''), ' ,-')
    )
END
FROM taxon.taxvern v
WHERE (t.cd_nom = v.cd_nom OR t.cd_ref = v.cd_nom)
AND "iso639_3" IN ('fra', '{$taxvern_iso}')
;
{/if}

REFRESH MATERIALIZED VIEW taxref_consolide;
REFRESH MATERIALIZED VIEW taxref_consolide_all;

COMMIT;
