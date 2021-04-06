
-- On colle dans une table une version temporaire de taxref 14. On a vérifié au préalable que la liste des champs n'avait pas évolué. Cette étape est nécessaire : on ne peut copier directement dans la table taxref car la structure de cette dernière est différente, des champs y ayant été ajoutés au fur et à mesure des évolutions de Taxref).
CREATE TABLE taxon.taxref_14 AS (SELECT * FROM taxon.taxref limit 0) ;
COMMENT ON TABLE taxon.taxref_14 IS 'Table stockant la version 14 de Taxref';
-- \COPY doit être sur une seule ligne
-- on peut aller dans le bon répertoire via
-- \cd /chemin/vers/le/repertoire/contenant/TAXREFv14/
\COPY taxon.taxref_14 (regne, phylum, classe, ordre, famille, sous_famille, tribu, group1_inpn, group2_inpn, cd_nom, cd_taxsup, cd_sup, cd_ref, rang, lb_nom, lb_auteur, nom_complet, nom_complet_html, nom_valide, nom_vern, nom_vern_eng, habitat, fr, gf, mar, gua, sm, sb, spm, may, epa, reu, sa, ta, taaf, pf, nc, wf, cli, url) FROM 'TAXREFv14.txt' DELIMITER E'\t' HEADER CSV;

-- Puis on écrase avec la version 13
TRUNCATE taxon.taxref RESTART IDENTITY CASCADE;
INSERT INTO taxon.taxref
(regne, phylum, classe, ordre, famille, sous_famille, tribu, group1_inpn, group2_inpn,
 cd_nom, cd_taxsup, cd_sup, cd_ref, rang, lb_nom, lb_auteur, nom_complet,
 nom_complet_html, nom_valide, nom_vern, nom_vern_eng, habitat,
 fr, gf, mar, gua, sm, sb, spm, may, epa, reu, sa, ta, taaf, pf, nc, wf, cli, url)
SELECT regne, phylum, classe, ordre, famille, sous_famille, tribu, group1_inpn, group2_inpn,  cd_nom, cd_taxsup, cd_sup, cd_ref, rang, lb_nom, lb_auteur, nom_complet,  nom_complet_html, nom_valide, nom_vern, nom_vern_eng, habitat,  fr, gf, mar, gua, sm, sb, spm, may, epa, reu, sa, ta, taaf, pf, nc, wf, cli, url
FROM taxon.taxref_14 ;

-- Vérification :
SELECT count(*) FROM taxon.taxref ;


-----------------------------
-- 4. Mise à jour de la table des statuts t_complement
-----------------------------

-- 4.1 Import de la table des statuts
-----------------------------
-- On importe au préalable la base des statuts associée à TAXREF -> création de la table taxon.statuts_especes_14
DROP TABLE IF EXISTS taxon.statuts_especes_14 ;
CREATE TABLE taxon.statuts_especes_14 (
        cd_nom INTEGER,
        cd_ref INTEGER,
        cd_sup INTEGER,
        cd_type_statut TEXT,
        lb_type_statut TEXT,
        regroupement_type TEXT,
        code_statut TEXT,
        label_statut TEXT,
        rq_statut TEXT,
        cd_sig TEXT,
        cd_doc TEXT,
        lb_nom TEXT,
        lb_auteur TEXT,
        nom_complet_html TEXT,
        nom_valide_html TEXT,
        regne TEXT,
        phylum TEXT,
        classe TEXT,
        ordre TEXT,
        famille TEXT,
        group1_inpn TEXT,
        group2_inpn TEXT,
        lb_adm_tr TEXT,
        niveau_admin TEXT,
        cd_iso3166_1 TEXT,
        cd_iso3166_2 TEXT,
        full_citation TEXT,
        doc_url TEXT,
        thematique TEXT,
        type_value TEXT
);

COMMENT ON TABLE taxon.statuts_especes_14 IS 'Statuts de taxon basés sur Taxref 14 (source : https://inpn.mnhn.fr/telechargement/referentielEspece/bdc-statuts-especes). La table ne contient pas les synonymes qui doivent donc être gérés via cd_ref';

SET client_encoding TO 'ISO-8859-15';
-- \copy doit être sur une seule ligne
-- \cd BDC-Statuts-v14
\COPY taxon.statuts_especes_14 (cd_nom ,cd_ref ,cd_sup ,cd_type_statut ,lb_type_statut ,regroupement_type ,code_statut ,label_statut ,rq_statut ,cd_sig ,cd_doc ,lb_nom ,lb_auteur ,nom_complet_html ,nom_valide_html ,regne ,phylum ,classe ,ordre ,famille ,group1_inpn ,group2_inpn ,lb_adm_tr ,niveau_admin ,cd_iso3166_1 ,cd_iso3166_2 ,full_citation ,doc_url ,thematique ,type_value) FROM 'BDC_STATUTS_14.csv' DELIMITER ',' HEADER CSV;
RESET client_encoding ;
SHOW client_encoding ;

-- 4.2 Mise à jour si besoin de la table t_nomenclature pour avoir des catégories de statut adaptées
-----------------------------
-- TODO : cette partie doit être adaptée par chaque région, en fonction des données de référence disponibles, par exemple sur le niveau d'invasibilité des taxons (information renseignée de manière incomplète dans Taxref)

-- Endémicité
SELECT * FROM taxon.t_nomenclature WHERE champ = 'endemicite' AND code IN  ('E', 'S');
UPDATE taxon.t_nomenclature SET valeur = 'Endémique de la Martinique' WHERE champ = 'endemicite' AND code = 'E';
UPDATE taxon.t_nomenclature SET valeur = 'Endémique des Petites Antilles' WHERE champ = 'endemicite' AND code = 'S';

-- Invasibilité : vérifier que c'est OK
SELECT * FROM taxon.t_nomenclature WHERE champ = 'invasibilite';
DELETE FROM taxon.t_nomenclature WHERE champ = 'invasibilite' ;
INSERT INTO taxon.t_nomenclature (champ, code, valeur, description, ordre) VALUES
('invasibilite', 'E', 'Envahissant', 'Taxon envahissant d''après Taxref', 1),
('invasibilite', 'PE', 'Potentiellement envahissant', 'Taxon potentiellement envahissant d''après l''analyse réalisée par le GEIR', 2),
('invasibilite', 'ND', 'Exotique à risque invasif non documenté', 'Taxon sans caractère envahissant connu. Taxons pour lesquels la colonne locale (ex: fra) IN (I, M, Y, D, A, Q), qui ne sont pas déjà cités dans un autre statut PE ou E', 3) ;


-- Vidage puis remplissage de t_complement et traitement des champs statut, endemicite et invasibilite
-- ATTENTION: remplacer la colonne locale utilisée
-----------------------------
-- Suppression des données
DELETE FROM taxon.t_complement WHERE cd_nom_fk IN (
    SELECT cd_nom FROM taxon.taxref
    UNION
    SELECT cd_nom FROM taxon.taxref_local
);

-- Insertion des données
INSERT INTO taxon.t_complement (cd_nom_fk, statut, endemicite, invasibilite)
SELECT cd_nom,
-- statut
CASE
    -- Exotique. vlt 28/11/2019 : j'ai rajouté Y (introduit éteint), A (Absent), Q (mentionné par erreur) et D (douteux : Taxon dont la présence dans la zone géographique considérée n'est pas avérée (en attente de confirmation)).
    WHEN mar IN ('I', 'J', 'M', 'Y', 'D', 'A', 'Q')
    THEN 'E'

    -- Indigène. vlt 28/11/2019 : j'ai rajouté Z (endémique éteint), W (Disparu), X (Eteint) et B (Occasionnel)
    WHEN mar IN ('P', 'S', 'E', 'Z', 'B', 'W', 'X')
    THEN 'I'

    -- non documenté, correspond à mar = 'C' et à mar NULL
    ELSE 'ND'
END AS statut,

-- rarete : COMMENTE CAR SUJET A DEBAT
-- CASE
    -- WHEN mar IN ('B', 'M') THEN 'R'
    -- WHEN mar IN ('E', 'I', 'J', 'P', 'S') THEN 'C'
    -- WHEN mar IN ('C') THEN 'E'
    -- ELSE NULL
-- END AS rarete,

-- endemicite
CASE
    WHEN mar IN ('E', 'Z') THEN 'E'
    WHEN mar IN ('S') THEN 'S'
    ELSE NULL
END AS endemicite,

-- invasibilite
CASE
    -- envahissant. Si des informations plus précises existent localement
    -- sur le niveau d'invasibilité, les renseigner spécifiquement
    WHEN mar IN ('J')
    THEN 'E'
    -- Exotique sans caractère invasif documenté. toutes les exotiques non classées J
    WHEN mar IN ('I', 'M', 'Y', 'D', 'A', 'Q')
    THEN 'ND'
    ELSE NULL
END AS invasibilite

-- On récupère les cd_nom des taxon de TAXREF et de la table taxref_local
-- vlt 28/11/2019 : attention à bien se baser sur taxref et pas taxref valide,
-- sinon on n'a pas les synonymes et on perd environ 50% des lignes
FROM (
    SELECT cd_nom, mar FROM taxon.taxref
    UNION
    SELECT cd_nom, mar FROM taxon.taxref_local
) tt
ON CONFLICT (cd_nom_fk) DO NOTHING;


-- 4.4 Mise à jour du champ menace_regionale
-----------------------------

-- Etat des lieux préalable des listes rouges à prendre en compte :
SELECT lb_type_statut, lb_adm_tr, cd_sig, code_statut, label_statut, full_citation, count(*)
FROM taxon.statuts_especes_14
WHERE lb_type_statut ILIKE 'Liste rouge%'
GROUP BY lb_type_statut, lb_adm_tr, cd_sig, full_citation, code_statut, label_statut
ORDER BY lb_type_statut, lb_adm_tr, code_statut, label_statut ;

-- Insertion des menaces
WITH
taxref_mnhn_et_local AS (
    SELECT cd_nom, cd_ref FROM taxon.taxref
    UNION
    SELECT cd_nom, cd_ref FROM taxon.taxref_local
),

menace AS (
    -- On prend pour renseigner ce champ la liste de niveau national.
    -- En effet, pour le îles, la distinction entre volet local
    -- d'une liste rouge nationale et liste rouge régionale est ténue.
    -- TODO : remplacer ici par le nom de la région concernée.
    SELECT DISTINCT t.cd_ref, t.cd_nom, s.code_statut
    FROM taxref_mnhn_et_local t
    INNER JOIN taxon.statuts_especes_14 s ON s.cd_nom = t.cd_nom
    WHERE s.lb_type_statut='Liste rouge nationale' AND s.lb_adm_tr='Martinique'
),

menace_des_synonymes AS (
    -- on est obligé de procéder en deux temps car du fait des mises en synonymies successives,
    -- on peut avoir pour un taxon et son synonyme des statuts différents !
    -- TODO : remplacer ici par le nom de la région concernée
    SELECT DISTINCT t.cd_ref, t.cd_nom, s.code_statut
    FROM taxref_mnhn_et_local t
    INNER JOIN taxon.statuts_especes_14 s ON (t.cd_ref = s.cd_nom AND s.cd_nom <> t.cd_nom)
    WHERE s.lb_type_statut='Liste rouge nationale' AND s.lb_adm_tr='Martinique'

), synthese_menace AS (
    SELECT * FROM menace
    UNION
    SELECT * FROM menace_des_synonymes
    ORDER BY cd_ref -- 2174 lignes
)
UPDATE taxon.t_complement t
SET menace_regionale = synthese_menace.code_statut
FROM synthese_menace
WHERE synthese_menace.cd_nom = t.cd_nom_fk ;


-- Mise à jour du champ menace_nationale
-----------------------------

-- Etat des lieux préalable des listes rouges à prendre en compte :
SELECT lb_type_statut,  lb_adm_tr, cd_sig, code_statut, label_statut, full_citation, count(*)
FROM taxon.statuts_especes_14
WHERE lb_type_statut ILIKE 'Liste rouge%'
GROUP BY lb_type_statut, lb_adm_tr, cd_sig, full_citation, code_statut, label_statut
ORDER BY lb_type_statut, lb_adm_tr, code_statut, label_statut ;

-- Insertion
WITH taxref_mnhn_et_local AS (
    SELECT cd_nom, cd_ref FROM taxon.taxref
    UNION
    SELECT cd_nom, cd_ref FROM taxon.taxref_local
),
menace AS (
    -- TODO : remplacer ici par le nom de la région concernée.
    SELECT DISTINCT t.cd_ref, t.cd_nom, s.code_statut
    FROM taxref_mnhn_et_local t
    INNER JOIN taxon.statuts_especes_14 s ON s.cd_nom = t.cd_nom
    WHERE s.lb_type_statut='Liste rouge nationale' AND s.lb_adm_tr='Martinique'

),
menace_des_synonymes AS (
    -- on est obligé de procéder en deux temps car du fait des mises en synonymies successives,
    -- on peut avoir pour un taxon et son synonyme des statuts différents !
    -- TODO : remplacer ici par le nom de la région concernée
    SELECT DISTINCT t.cd_ref, t.cd_nom, s.code_statut
    FROM taxref_mnhn_et_local t
    INNER JOIN taxon.statuts_especes_14 s ON (t.cd_ref = s.cd_nom AND s.cd_nom <> t.cd_nom)
    WHERE s.lb_type_statut='Liste rouge nationale' AND s.lb_adm_tr='Martinique'
),
synthese_menace AS (
    SELECT * FROM menace
    UNION
    SELECT * FROM menace_des_synonymes
    ORDER BY cd_ref
)
UPDATE taxon.t_complement t
SET menace_nationale = synthese_menace.code_statut
FROM synthese_menace
WHERE synthese_menace.cd_nom = t.cd_nom_fk ;


-- Mise à jour du champ menace_monde
-----------------------------
WITH
taxref_mnhn_et_local AS (
    SELECT cd_nom, cd_ref FROM taxon.taxref
    UNION
    SELECT cd_nom, cd_ref FROM taxon.taxref_local
), menace AS (
    SELECT DISTINCT t.cd_ref, t.cd_nom, s.code_statut
    FROM taxref_mnhn_et_local t
    INNER JOIN taxon.statuts_especes_14 s ON s.cd_nom = t.cd_nom
    WHERE s.lb_type_statut='Liste rouge mondiale'

), menace_des_synonymes AS (
    -- on est obligé de procéder en deux temps car du fait des mises en synonymies successives,
    -- on peut avoir pour un taxon et son synonyme des statuts différents !
    SELECT DISTINCT t.cd_ref, t.cd_nom, s.code_statut
    FROM taxref_mnhn_et_local t
    INNER JOIN taxon.statuts_especes_14 s ON (t.cd_ref = s.cd_nom AND s.cd_nom <> t.cd_nom)
    WHERE s.lb_type_statut='Liste rouge mondiale'

), synthese_menace AS (
    SELECT * FROM menace
    UNION
    SELECT * FROM menace_des_synonymes
    ORDER BY cd_ref
    )
UPDATE taxon.t_complement t
SET menace_monde = synthese_menace.code_statut
FROM synthese_menace
WHERE synthese_menace.cd_nom = t.cd_nom_fk ;


-- Mise à jour du champ protection
-----------------------------

-- Etat des lieux préalable des protections à prendre en compte :
SELECT lb_type_statut,  lb_adm_tr, cd_sig, code_statut, label_statut, full_citation, count(*)
FROM taxon.statuts_especes_14
WHERE lb_type_statut ILIKE 'Protection%'
GROUP BY lb_type_statut, lb_adm_tr, cd_sig, full_citation, code_statut, label_statut
ORDER BY lb_type_statut, lb_adm_tr, code_statut, label_statut ;

-- Mise à jour de la table t_complement
WITH taxref_mnhn_et_local AS (
    SELECT cd_nom, cd_ref FROM taxon.taxref
    UNION
    SELECT cd_nom, cd_ref FROM taxon.taxref_local

),
protection AS (
    -- TODO : à adapter en fonction des régions
    -- NB: 'NTAA1' mal rempli dans la v11, la v13 et la v14 de la BDD statuts
    SELECT DISTINCT t.cd_ref, t.cd_nom, s.code_statut
    FROM taxref_mnhn_et_local t
    INNER JOIN taxon.statuts_especes_14 s ON s.cd_nom = t.cd_nom -- 513 lignes
    WHERE (lb_adm_tr IN ('France', 'Martinique') AND lb_type_statut ILIKE 'Protection%')
    OR code_statut = 'NTAA1'
),
protection_des_synonymes AS (
    -- on est obligé de procéder en deux temps car du fait des mises en synonymies successives,
    -- on peut avoir pour un taxon et son synonyme des statuts différents !
     -- TODO : à adapter en fonction des régions
    SELECT DISTINCT t.cd_ref, t.cd_nom, s.code_statut
    FROM taxref_mnhn_et_local t
    INNER JOIN taxon.statuts_especes_14 s ON (t.cd_ref = s.cd_nom AND s.cd_nom <> t.cd_nom)
    WHERE   (lb_adm_tr IN ('France', 'Martinique') AND lb_type_statut ILIKE 'Protection%')
    OR code_statut = 'NTAA1'
),
union_protection AS (
    SELECT * FROM protection
    UNION
    SELECT * FROM protection_des_synonymes
    ORDER BY cd_ref -- 27 685 lignes
),
synthese_protection AS (
    SELECT cd_nom, code_statut, 'EPN' AS protection,
    -- TODO : si on ne retient plus que la protection nationale, le champ note n'est plus utile à renseigner
    0 AS note
    FROM union_protection
),
synthese_protection_priorisee AS (
    SELECT DISTINCT cd_nom,
    FIRST_VALUE(code_statut) OVER (PARTITION BY cd_nom ORDER BY note) AS code_statut,
    FIRST_VALUE(protection) OVER (PARTITION BY cd_nom ORDER BY note) AS protection
    FROM synthese_protection
)

UPDATE taxon.t_complement t SET protection = s.protection
FROM synthese_protection_priorisee s
WHERE s.cd_nom = t.cd_nom_fk
;


-- Mise à jour du champ det_znieff
-----------------------------
WITH taxref_mnhn_et_local AS (
    SELECT cd_nom, cd_ref FROM taxon.taxref
    UNION
    SELECT cd_nom, cd_ref FROM taxon.taxref_local

),
znieff AS (
    SELECT DISTINCT t.cd_ref, t.cd_nom
    FROM taxref_mnhn_et_local t
    INNER JOIN taxon.statuts_especes_14 s ON s.cd_nom = t.cd_nom
    WHERE cd_type_statut='ZDET' AND lb_adm_tr IN ('Martinique')

),
znieff_des_synonymes AS (
    -- on est obligé de procéder en deux temps car du fait des mises en synonymies successives,
    -- on peut avoir pour un taxon et son synonyme des statuts différents !
    SELECT DISTINCT t.cd_ref, t.cd_nom
    FROM taxref_mnhn_et_local t
    INNER JOIN taxon.statuts_especes_14 s ON (t.cd_ref = s.cd_nom AND s.cd_nom <> t.cd_nom)
    WHERE cd_type_statut='ZDET' AND lb_adm_tr IN ('Martinique')

),
synthese_znieff AS (
    SELECT * FROM znieff
    UNION
    SELECT * FROM znieff_des_synonymes
    ORDER BY cd_ref
)
UPDATE taxon.t_complement t SET det_znieff = 'Déterminante'
FROM synthese_znieff s
WHERE s.cd_nom = t.cd_nom_fk ;


-- Nom vernaculaires
--Vérification préalable de la manière dont nom_vern est renseigné dans taxref :
-- Si pas de souci d'encodage, on continue, sinon essayer SET client_encoding TO 'ISO-8859-15';
SELECT nom_vern
FROM taxon.taxref
WHERE mar IS NOT NULL AND nom_vern IS NOT NULL AND group2_inpn = 'Oiseaux';

-- Import du fichier taxvern_14
DROP TABLE IF EXISTS taxon.taxvern_14;
CREATE TABLE taxon.taxvern_14 (
    cd_vern TEXT,
    cd_nom TEXT,
    lb_vern TEXT,
    nom_vern_source TEXT,
    langue TEXT,
    "iso639_3" TEXT,
    pays TEXT
);
-- ATTENTION: le fichier TAXVERNv14 comporte des soucis qu'il faut corriger à la main (des tabulations en trop)
-- \cd ..
\COPY taxon.taxvern_14 FROM 'TAXVERNv14.txt' DELIMITER E'\t' HEADER CSV;

-- Vérification :
SELECT * FROM taxon.taxvern_14 LIMIT 10;

-- Pour éviter d'intégrer des noms en doublon, on va éclater puis agglomérer les noms français issus de Taxvern (langue = français et créole) et de Taxref.
-- TODO : à adapter pour une autre région, notamment le champ iso639_3 pour le code du créole local
-- rcf = Créole réunionnais
-- gcg = Créole guadeloupéen (et martiniquais car ils partagent le même code)
-- fra = français.
WITH
noms_vern_taxref_et_taxvern AS (
    SELECT
    -- le champ ordre permet plus bas de prendre en premier le nom créole
    1 AS ordre, cd_nom::INTEGER, lb_vern AS nom_vern_orig,
    REGEXP_SPLIT_TO_TABLE(
        lb_vern,
        ', '
    ) AS nom_vern_eclate
    FROM taxon.taxvern_14
    WHERE iso639_3 IN ('rcf')

    UNION

    SELECT
    2 AS ordre, cd_nom, nom_vern AS nom_vern_orig,
    REGEXP_SPLIT_TO_TABLE(
        nom_vern,
        ', '
    ) AS nom_vern_eclate
    FROM taxon.taxref
    WHERE nom_vern IS NOT NULL

    UNION

    SELECT
    3 AS ordre, cd_nom::INTEGER, lb_vern AS nom_vern_orig,
    REGEXP_SPLIT_TO_TABLE(
        lb_vern,
        ', '
    ) AS nom_vern_eclate
    FROM taxon.taxvern_14
    WHERE iso639_3 IN ('rcf', 'fra')
    ORDER BY ordre, cd_nom, nom_vern_orig -- 43 268 lignes
),

complement_taxvern_14 AS (
    SELECT t.cd_ref, t.cd_nom, string_agg(DISTINCT TRIM(nom_vern_eclate), ', ') AS nom_vern_new
    FROM taxon.taxref t
    INNER JOIN noms_vern_taxref_et_taxvern s ON s.cd_nom = t.cd_nom
    GROUP BY t.cd_ref, t.cd_nom
),

complement_taxvern_14_des_synonymes AS (
    -- on est obligé de procéder en deux temps car du fait des mises en synonymies successives,
    -- on peut avoir pour un taxon et son synonyme des statuts différents !
    SELECT t.cd_ref, t.cd_nom, string_agg(DISTINCT TRIM(nom_vern_eclate), ', ') AS nom_vern_new
    FROM taxon.taxref t
    INNER JOIN noms_vern_taxref_et_taxvern s ON (t.cd_ref = s.cd_nom AND s.cd_nom <> t.cd_nom)
    GROUP BY t.cd_ref, t.cd_nom
),

synthese_taxvern_14 AS (
    SELECT * FROM complement_taxvern_14
    UNION
    SELECT * FROM complement_taxvern_14_des_synonymes
    ORDER BY cd_ref
)
UPDATE taxon.taxref t SET nom_vern = synthese_taxvern_14.nom_vern_new
FROM synthese_taxvern_14
WHERE t.cd_nom = synthese_taxvern_14.cd_nom
;


-- Rafraîchissement des vues matérialisées
-----------------------------
REFRESH MATERIALIZED VIEW taxon.taxref_valide;
REFRESH MATERIALIZED VIEW taxon.taxref_consolide;
REFRESH MATERIALIZED VIEW taxon.taxref_consolide_non_filtre;

DROP TEXT SEARCH CONFIGURATION IF EXISTS french_text_search;
CREATE TEXT SEARCH CONFIGURATION french_text_search (COPY = french);
ALTER TEXT SEARCH CONFIGURATION french_text_search ALTER MAPPING FOR hword, hword_part, word, asciihword, asciiword, hword_asciipart WITH unaccent, french_stem;
SET default_text_search_config TO french_text_search;

REFRESH MATERIALIZED VIEW taxon.taxref_fts;
REFRESH MATERIALIZED VIEW occtax.vm_observation ;


-- 11. Nettoyage
-----------------------------
--Supprimer les tables inutiles

-- Terminé en prod sur Borbonica par VLT le 12/08/2020 (sauf les TODO à revoir)


DROP TABLE IF EXISTS taxon.taxref_14 ; --(désormais intégré à taxon.taxref)
DROP TABLE IF EXISTS taxon.taxvern_14 ; --noms réintégrés dans nom_vern de taxref
DROP TABLE IF EXISTS taxon.taxref_changes ;
DROP TABLE IF EXISTS taxon.protections ;
DROP TABLE IF EXISTS taxon.menaces ;
