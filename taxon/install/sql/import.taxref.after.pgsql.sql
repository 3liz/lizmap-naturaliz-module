-- Ajout des données de recherche plein texte
BEGIN;
TRUNCATE taxref_fts RESTART IDENTITY CASCADE;

-- Noms valides
INSERT INTO taxref_fts (cd_nom, cd_ref, val, nom_valide, poids, group2_inpn, vec)
SELECT cd_nom, cd_ref, nom_valide, nom_valide, 6,
group2_inpn, to_tsvector( unaccent(coalesce(nom_valide,'')) )
FROM taxref
WHERE cd_nom = cd_ref
AND rang IN ('AGES','ES','SMES','MES','SSES','NAT','HYB',
'CVAR','VAR','SVAR','FO','SSFO','FOES','LIN','CLO','CAR','RACE','MO','AB')
;

-- Noms vernaculaires
INSERT INTO taxref_fts (cd_nom, cd_ref, val, nom_valide, poids, group2_inpn, vec)
SELECT cd_nom, cd_ref, nom_vern, nom_valide, 4,
group2_inpn, to_tsvector( unaccent(coalesce(nom_vern,'')) )
FROM taxref
WHERE cd_nom = cd_ref AND nom_vern IS NOT NULL AND nom_vern != ''
AND rang IN ('AGES','ES','SMES','MES','SSES','NAT','HYB',
'CVAR','VAR','SVAR','FO','SSFO','FOES','LIN','CLO','CAR','RACE','MO','AB')
;

-- Noms synonymes
INSERT INTO taxref_fts (cd_nom, cd_ref, val, nom_valide, poids, group2_inpn, vec)
SELECT cd_nom, cd_ref, nom_complet, nom_valide, 2,
group2_inpn, to_tsvector( unaccent(coalesce(nom_complet,'')) )
FROM taxref
WHERE cd_nom != cd_ref
AND rang IN ('AGES','ES','SMES','MES','SSES','NAT','HYB',
'CVAR','VAR','SVAR','FO','SSFO','FOES','LIN','CLO','CAR','RACE','MO','AB')
;


-- Donnees complementaires
TRUNCATE TABLE t_complement RESTART IDENTITY;
INSERT INTO t_complement (cd_nom_fk, statut, rarete, endemicite)
SELECT cd_nom,
-- statut
CASE
        WHEN {$colonne_locale} IN ('I', 'J', 'M') THEN 'E'
        WHEN {$colonne_locale} IN ('P', 'S', 'E') THEN 'I'
        ELSE NULL
END AS statut,
-- rarete
CASE
        WHEN {$colonne_locale} IN ('B', 'M') THEN 'R'
        WHEN {$colonne_locale} IN ('E', 'I', 'J', 'P', 'S') THEN 'C'
        WHEN {$colonne_locale} IN ('C') THEN 'E'
        ELSE NULL
END AS rarete,
-- endemicite
CASE
        WHEN {$colonne_locale} IN ('E', 'Z') THEN 'E'
        WHEN {$colonne_locale} IN ('S') THEN 'S'
        ELSE NULL
END AS endemicite
FROM taxref_valide
;

-- Adaptation de la nomenclature au contexte local
UPDATE t_nomenclature SET description = '{$endemicite_description_endemique}' WHERE champ = 'endemicite' AND code = 'E';
UPDATE t_nomenclature SET description = '{$endemicite_description_subendemique}' WHERE champ = 'endemicite' AND code = 'S';

-- MENACES = TAXON DES LISTES ROUGES
CREATE TEMPORARY TABLE redlist (
    cd_nom integer NOT NULL, -- Identifiant unique du nom scientifique
    cd_ref integer, -- Identifiant (CD_NOM) du taxon de référence (nom retenu)
    nom_scientifique text,
    auteur text,
    nom_commun text,
    rang text,
    famille text,
    endemisme text,
    population text,
    commentaire text,
    categorie_france text,
    criteres_france text,
    tendance text,
    liste_rouge_source text,
    annee_publi text,
    categorie_lr_europe text,
    categorie_lr_monde text
) ON COMMIT DROP
;

COPY redlist
FROM '{$menace}' DELIMITER ',' CSV;
CREATE INDEX ON redlist (cd_nom);

-- INSERT taxon pas encore présents dans t_complement
INSERT INTO t_complement (cd_nom_fk, menace)
SELECT DISTINCT b.cd_nom, a.categorie_france
FROM redlist a
INNER JOIN taxref b ON a.cd_nom = b.cd_nom
WHERE NOT EXISTS (SELECT cd_nom_fk FROM t_complement)
;

-- UPDATE tous les taxons qui ont une menace
UPDATE t_complement c
SET menace = a.categorie_france
FROM redlist a
INNER JOIN taxref b ON a.cd_nom = b.cd_nom
WHERE c.cd_nom_fk = b.cd_nom
AND a.categorie_france IS NOT NULL
;


-- PROTECTION
CREATE TEMPORARY TABLE protection_espece (
    cd_nom text,
    cd_protection text,
    nom_cite text,
    syn_cite text,
    nom_francais_cite text,
    precisions text,
    cd_nom_cite text
) ON COMMIT DROP
;
COPY protection_espece FROM '{$protection}' DELIMITER ',' HEADER CSV;
CREATE INDEX ON protection_espece (cd_nom);

-- INSERT taxon pas encore présents dans t_complement
INSERT INTO t_complement (cd_nom_fk, protection)
SELECT DISTINCT a.cd_nom::integer,
CASE
    WHEN a.cd_protection IN ({$code_arrete_protection_nationale}) THEN 'EPN'
    WHEN a.cd_protection IN ({$code_arrete_protection_internationale}) THEN 'EPI'
    WHEN a.cd_protection IN ({$code_arrete_protection_communautaire}) THEN 'EPC'
    ELSE 'EP'
END AS "protection"
FROM protection_espece a
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
    ELSE 'EP'
END
FROM protection_espece a
WHERE c.cd_nom_fk::text = a.cd_nom
AND a.cd_protection IN (
    {$code_arrete_protection_simple},
    {$code_arrete_protection_nationale},
    {$code_arrete_protection_internationale},
    {$code_arrete_protection_communautaire}
)
;



COMMIT;
