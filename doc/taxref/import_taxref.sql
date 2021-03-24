/* Script mettant à jour les données de Taxref 12.0 vers Taxref 13.0
---------------------------------------------------------------------------
Finalisé le 16/09/2020 par Valentin Le Tellier à partir des fichiers type de Michaël Douchin :
https://projects.3liz.org/clients/naturaliz-reunion/blob/master/doc/taxref/maj_observation_apres_import_nouveau_taxref_via_taxref_changes.sql
https://projects.3liz.org/clients/naturaliz-reunion/blob/master/taxon/install/sql/import.taxref.after.pgsql.sql

Le script peut être adapté par d'autres plates-formes régionales utilisant l'outil Naturaliz. Pour cela, remplacer les codes relatifs à La Réunin par ceux relatifs à la région concernée. Des balises TODO permettent de signaler à quels endroits cela doit être fait dans le script.

------------
Modifs apportées entre v2 et v3 :
- Suppression des lignes qui étaient commentées et conservées pour mémoire (parties 4.4, 4.7), plus utiles du fait de la modification de la gestion de l'information sur les menaces dans les dernières versions de Taxref,car (i) à partir de la v12 de la base de statuts, tout est dans une seule table, intégrant les protections, (ii) désormais le premier INSERT dans t_complement se base sur taxref UNION taxref_local (et plus seulement taxref_valide).
- Modification de la partie 4.4 pour traiter le champ menace_regionale (autrefois : champ menace qui n'existe plus désormais)
- Ajout d'une partie 4.5 Mise à jour du champ menace_nationale
---------------------------

------------
Modifs apportées entre v1 et v2 :
- ajout de la partie 4.2 Mise à jour si besoin de la table t_nomenclature pour avoir des catégories de statut adaptées
- partie 9 sur l'export TAXREF
- mise à jour optionnelle du champ invasibilité (partie 4.7)
---------------------------



Plan :
----------------------------
1. Import de taxon.taxref_13
        1.1 Table taxon.taxref
        1.2 Tables taxref_changes et cd_nom_disparus
2. Mise à jour de Taxref_local
3. Modification de la table observation
        3.1 Etat de lieux des modifications impactant les jdd déjà rentrés
        3.2 Traitement des retraits de cd_nom qui concernent des observations de la table occtax.observation
        3.3 Traitement des modifications de cd_ref
        3.4 Mise à jour dans la table observation des taxons issus de taxref_local
        3.5 Mise à jour du champ version_taxref
4. Mise à jour de la table des statuts t_complement
        4.1 Import de la table des statuts
        4.2 Mise à jour si besoin de la table t_nomenclature pour avoir des catégories de statut adaptées
        4.3 Vidage puis remplissage de t_complement et traitement des champs statut, endemicite et invasibilite
        4.4 Mise à jour du champ menace_regionale
        4.5 Mise à jour du champ menace_nationale
        4.6 Mise à jour du champ menace_monde
        4.7 Mise à jour du champ protection
        4.8 Mise à jour du champ det_znieff
        4.9 Mise à jour optionnelle du champ invasibilité
5. Enrichissement des noms vernaculaires
6. Vérification
7. Mise à jour de la table critere_validation
8. Mise à jour de la table critere_sensibilite
9. Export dans une table à plat d'une synthèse de taxref 13
10. Rafraîchissement des vues matérialisées
11. Nettoyage

*/

----------------------------
-- 0. Préparation
----------------------------

-- Import des tables distantes depuis la dév depuis la prod
----------------------------
-- Pour éviter d'importer deux fois les tables csv source depuis le FTP, on peut les appeler en FDW depuis la base de dév une fois que l'import en dév est fait
IMPORT FOREIGN SCHEMA taxon
LIMIT TO (cd_nom_disparus_13, statuts_especes_13, taxref_changes_13, taxvern_13)
FROM SERVER bdd_dev INTO occtax_dev;

-- Récupération des fichiers source sur le site de l'INPN.
----------------------------
/* Pour mémoire, le fichier archive Zip téléchargeable sur https://inpn.mnhn.fr/telechargement/referentielEspece/taxref/13.0/menu comporte huit fichiers :
    TAXREFv13.txt, le référentiel en lui-même (595 373 lignes),
    TAXVERNv13.txt, le référentiel des noms vernaculaires (57 848 lignes),
    TAXREF_CHANGES.txt, tableau décrivant l’ensemble des modifications depuis la version précédente (117 394 lignes),
    TAXREF_LIENS.txt, tableau permettant un lien unique vers les bases de données nomenclaturales ou taxonomiques (1 377 520 lignes),
    CDNOM_DISPARUS.xls, tableau listant les CD_NOM de niveau spécifique anciennement diffusés mais qui ne le sont plus dans la dernière version, avec les causes de leur disparition ou les CD_NOM de remplacement dans le cas des doublons (8874 lignes),
    trois fichiers habitats_note.csv, rangs_note.csv et statuts_note.csv qui permettent d'interpréter respectivement la colonne Habitat, la colonne Rang et les colonnes de statuts biogéographiques dans les territoires (FR, GF, etc).
*/


-----------------------------
-- 1. Import de Taxref 13
-----------------------------

-- 1.1 Table taxon.taxref
-----------------------------

-- on sauvegarde avant momentanément la version 12
CREATE TABLE taxon.taxref_12 AS (SELECT * FROM taxon.taxref) ;
COMMENT ON TABLE taxon.taxref_12 IS 'Table stockant la précédente version de Taxref, pour mémoire (v12)';

-- Vérifications :
SELECT count(*) FROM taxon.taxref ; -- 570 623 lignes
SELECT count(*) FROM taxon.taxref_12 ; -- 570 623 lignes
SELECT * FROM taxon.taxref_12 limit 10 ; -- structure OK

-- On colle dans une table une version temporaire de taxref 13. On a vérifié au préalable que la liste des champs n'avait pas évolué. Cette étape est nécessaire : on ne peut copier directement dans la table taxref car la structure de cette dernière est différente, des champs y ayant été ajoutés au fur et à mesure des évolutions de Taxref).
CREATE TABLE taxon.taxref_13 AS (SELECT * FROM taxon.taxref limit 0) ;
COMMENT ON TABLE taxon.taxref_13 IS 'Table stockant la version 13 de Taxref';

COPY taxon.taxref_13
(regne, phylum, classe, ordre, famille, sous_famille, tribu, group1_inpn, group2_inpn,
 cd_nom, cd_taxsup, cd_sup, cd_ref, rang, lb_nom, lb_auteur, nom_complet,
 nom_complet_html, nom_valide, nom_vern, nom_vern_eng, habitat,
 fr, gf, mar, gua, sm, sb, spm, may, epa, reu, sa, ta, taaf, pf, nc, wf, cli, url)
FROM '/tmp/TAXREFv13.txt' DELIMITER E'\t' HEADER CSV;
-- En prod : INSERT INTO taxon.taxref_13 (SELECT * FROM occtax_dev.taxref) ;

-- Par rapport à taxref_12, pas de nouveau champ, mais les champs sous-famille et tribu sont déplacés après le champ famille (ils étaient à la fin dans taxref_12)

SELECT count(*) FROM taxon.taxref_13 ; --595 373 lignes : conforme au fichier d'origine

-- Puis on écrase avec la version 12
TRUNCATE taxref RESTART IDENTITY CASCADE;
INSERT INTO taxref
(regne, phylum, classe, ordre, famille, sous_famille, tribu, group1_inpn, group2_inpn,
 cd_nom, cd_taxsup, cd_sup, cd_ref, rang, lb_nom, lb_auteur, nom_complet,
 nom_complet_html, nom_valide, nom_vern, nom_vern_eng, habitat,
 fr, gf, mar, gua, sm, sb, spm, may, epa, reu, sa, ta, taaf, pf, nc, wf, cli, url)
SELECT regne, phylum, classe, ordre, famille, sous_famille, tribu, group1_inpn, group2_inpn,  cd_nom, cd_taxsup, cd_sup, cd_ref, rang, lb_nom, lb_auteur, nom_complet,  nom_complet_html, nom_valide, nom_vern, nom_vern_eng, habitat,  fr, gf, mar, gua, sm, sb, spm, may, epa, reu, sa, ta, taaf, pf, nc, wf, cli, url
FROM taxon.taxref_13 ;
RESET client_encoding ;

-- Vérification :
SELECT count(*) FROM taxon.taxref ; --595 373 lignes, comme taxref_13


-- 1.2 Import des tables taxref_changes et cd_nom_disparus
-----------------------------

-- Importer le fichier TAXREF_CHANGES
DROP TABLE IF EXISTS taxon.taxref_changes_13;
CREATE TABLE taxon.taxref_changes_13 (
    cd_nom TEXT,
    num_version_init TEXT,
    num_version_final TEXT,
    champ TEXT,
    valeur_init TEXT,
    valeur_final TEXT,
    type_change TEXT
);
COPY taxon.taxref_changes_13 FROM '/tmp/TAXREF_CHANGES.txt' DELIMITER E'\t' HEADER CSV;

-- Vérifications :
SELECT count(*) FROM taxon.taxref_changes_13 ; --117 394 lignes : conforme au fichier d'origine
SELECT * FROM taxon.taxref_changes_13 LIMIT 10;

-- Importer le fichier CD_NOMS_DISPARUS
-- à générer avant au format csv à partir du xls du MNHN, si besoin
DROP TABLE IF EXISTS taxon.cd_nom_disparus_13;
CREATE TABLE taxon.cd_nom_disparus_13 (
    cd_nom TEXT,
    plus_recente_diffusion TEXT,
    cd_nom_remplacement TEXT,
    cd_raison_suppression TEXT,
    raison_suppression TEXT
);

COPY taxon.cd_nom_disparus_13 FROM '/tmp/CDNOM_DISPARUS.csv' DELIMITER '$' HEADER CSV;

SELECT count(*) FROM taxon.cd_nom_disparus_13 ; --8 874 lignes : conforme au fichier d'origine
SELECT * FROM taxon.cd_nom_disparus_13 ;

-----------------------------
-- 2. Mise à jour de Taxref_local
-----------------------------

-- Mise à jour de cd_nom_valide pour les taxons locaux désormais intégrés à Taxref (pour la traçabilité). Les lignes concernées ne sont plus appelées par les vues associées (ex : vue taxref_consolide_non_filtre contient filtre WHERE taxref_local.cd_nom_valide IS NULL)
WITH loc AS (
    SELECT tl.group2_inpn, tl.cd_nom AS cd_nom_old, t.cd_nom AS cd_nom_new, t.cd_ref AS cd_ref_new, tl.nom_valide, tl.nom_vern, t.nom_valide AS nom_valide_new, t.nom_vern AS nom_vern_new, t.rang, t.reu
    FROM taxon.taxref_local tl
    INNER JOIN taxon.taxref t ON TRIM(LOWER(unaccent(tl.lb_nom)))=TRIM(LOWER(unaccent(t.lb_nom)))
        WHERE cd_nom_valide IS NULL -- on ne prend pas les taxons déjà intégrés à l'occasion de précédentes mises à jour de Taxref
        -- 6 taxons concernés : Geopelia cuneata, Serinus canaria, Cacatua galerita, Mustela putorius furo, Dais cotinifolia, Neocaridina
    )
UPDATE taxon.taxref_local tl
SET cd_nom_valide=loc.cd_nom_new::INTEGER
FROM loc
WHERE cd_nom=loc.cd_nom_old ; -- 6 lignes mise à jour


-----------------------------
-- 3. Modification de la table observation
-----------------------------

-- 3.1 Etat de lieux des modifications impactant les jdd déjà rentrés
-----------------------------
SELECT o.cd_nom AS cd_nom_taxon_modif, t.group2_inpn, t.lb_nom AS nom_taxon_modif, t.nom_vern AS nom_vern_taxon_modif,
        tc.champ, tc.type_change, d.raison_suppression, tc.valeur_init, tc.valeur_final,
        CASE WHEN tc.champ IN ('CD_REF','CD_SUP','CD_TAXSUP') THEN tinit.nom_valide ELSE NULL END AS nom_init,
        CASE WHEN tc.champ IN ('CD_REF','CD_SUP','CD_TAXSUP') THEN tfinal.nom_valide ELSE NULL END AS nom_final,
        count(cle_obs) AS nb_obs, array_agg(DISTINCT jdd_code) AS liste_jdd_concernes
FROM occtax.observation o
LEFT JOIN taxon.taxref_changes_13 tc ON o.cd_nom::TEXT = tc.cd_nom
LEFT JOIN taxon.cd_nom_disparus_13 d ON d.cd_nom::INTEGER = o.cd_nom
LEFT JOIN taxon.taxref_12 t ON o.cd_nom = t.cd_nom
LEFT JOIN taxon.taxref_12 tinit ON tc.valeur_init = tinit.cd_nom::TEXT
LEFT JOIN taxon.taxref tfinal ON tc.valeur_final = tfinal.cd_nom::TEXT
WHERE UPPER(tc.champ) IN ('CD_NOM','CD_REF','CD_SUP','CD_TAXSUP', 'HABITAT', 'LB_NOM', 'LB_AUTEUR', 'NOM_VERN', 'REU') -- on ne regarde pas les champs concernant les statuts biogéographiques hors Réunion (TODO : pour d'autres régions, remplacer reu par le champ correspondant au statut biogéograpique de la région concernée)
        AND (tc.cd_nom IS NOT NULL OR d.cd_nom IS NOT NULL)
--AND d.cd_raison_suppression = '1'
GROUP BY o.cd_nom, t.group2_inpn, t.lb_nom, t.nom_vern, tc.champ, tc.type_change, d.raison_suppression,
                tc.valeur_init, tc.valeur_final, tinit.nom_valide, tfinal.nom_valide
ORDER BY tc.champ, tc.type_change, t.group2_inpn, t.lb_nom
;

--> 4 taxons concernées seulement pas des retraits de cd_nom


-- 3.2 Traitement des retraits de cd_nom qui concernent des observations de la table occtax.observation
-----------------------------

/* Il n'existe aucune ligne dans TAXREF_CHANGES avec une modification du champ CD_NOM --> seulement des RETRAIT ou des AJOUT
* Seules les lignes concernant les RETRAIT nous intéressent (car les ajouts ne sont pas référencées par les observations normalement)
* Pour les raison de retrait = 1 --> on va chercher dans la source CDNOM_DISPARUS ou dans le nouveau Taxref le nouveau CD_NOM ("cd_nom de remplacement à utiliser.")
* Pour les raisons de retrait = 2 ("cd_nom non diffusé mais toujours existant : taxon diffusé à tort, non présent et jamais mentionné en France") ou 3 ("cd_nom à supprimer : enregistrement ambigü à revoir dans les données.") --> on crée si besoin une nouvelle ligne dans taxref_local et on contacte Taxref pour voir si l'erreur vient de Taxref ou bien des données acquises localement
*/

-- a/ retraits de cas 1 (cd_nom de remplacement à utiliser)

-- Lancer la requête d'UPDATE des cd_nom et cd_ref de occtax.observation à partir de taxref_changes
WITH r AS (
-- Liste des obs concernées :
        SELECT o.cle_obs, o.nom_cite,
                o.cd_nom AS cd_nom_old, t.cd_nom::INTEGER AS cd_nom_new,
                t12.lb_nom AS nom_old, t.lb_nom AS nom_new,
                o.cd_ref AS cd_ref_old, t.cd_ref AS cd_ref_new,
                d.cd_raison_suppression
        FROM occtax.observation o
        LEFT JOIN taxon.taxref_changes_13 AS tc ON o.cd_nom::TEXT = tc.cd_nom
        LEFT JOIN taxon.cd_nom_disparus_13 d ON d.cd_nom = tc.cd_nom
        LEFT JOIN taxon.taxref_12 t12 ON t12.cd_nom = o.cd_nom
        LEFT JOIN taxon.taxref t ON t.cd_nom=d.cd_nom_remplacement::INTEGER
        WHERE TRUE
        AND tc.champ = 'CD_NOM'
        AND tc.type_change = 'RETRAIT'
        AND d.cd_raison_suppression = '1'
        AND cd_nom_remplacement IS NOT NULL
        ORDER BY o.nom_cite
        /* 41 obs
        - Cestrum elegans : cd_nom 706025 --> 673447
        - Erigeron annuus : cd_nom 521661 --> 96740
        SELECT * FROM taxref_12 WHERE cd_nom IN (706025,521661, 673447, 96740) -- a priori il s'agissait de doublons
        */
        )
UPDATE occtax.observation AS o
SET cd_nom = r.cd_nom_new,
cd_ref=r.cd_ref_new,
dee_date_derniere_modification = now()
FROM r WHERE r.cle_obs = o.cle_obs
;

-- b/ Retraits de cas 2 et 3
-- Liste des lignes concernées
SELECT o.cle_obs, o.nom_cite,
        o.cd_nom AS cd_nom_old, t.cd_nom::INTEGER AS cd_nom_new,
        t12.lb_nom AS nom_old, t.lb_nom AS nom_new,
        o.cd_ref AS cd_ref_old, t.cd_ref AS cd_ref_new,
        d.cd_raison_suppression
FROM occtax.observation o
LEFT JOIN taxon.taxref_changes_13 AS tc ON o.cd_nom::TEXT = tc.cd_nom
LEFT JOIN taxon.cd_nom_disparus_13 d ON d.cd_nom = tc.cd_nom
LEFT JOIN taxon.taxref_12 t12 ON t12.cd_nom = o.cd_nom
LEFT JOIN taxon.taxref t ON t.cd_nom=d.cd_nom_remplacement::INTEGER
WHERE TRUE
AND tc.champ = 'CD_NOM'
AND tc.type_change = 'RETRAIT'
AND d.cd_raison_suppression IN ('2', '3')
ORDER BY o.nom_cite ;-- 0 ligne concernée

-- Puis, il faut créer des lignes spécifiques dans taxon.taxref_13_local pour ces taxons et mettre à jour les observations en conséquence.
-- Sans objet ici

-- c/ retraits dont la raison n'est pas renseignée
-- Liste des observations concernées :
SELECT o.cle_obs, o.nom_cite,
        o.cd_nom AS cd_nom_old, t.cd_nom::INTEGER AS cd_nom_new,
        t12.lb_nom AS nom_old, t.lb_nom AS nom_new,
        o.cd_ref AS cd_ref_old, t.cd_ref AS cd_ref_new,
        d.cd_raison_suppression
FROM occtax.observation o
LEFT JOIN taxon.taxref_changes_13 AS tc ON o.cd_nom::TEXT = tc.cd_nom
LEFT JOIN taxon.cd_nom_disparus_13 d ON d.cd_nom = tc.cd_nom
LEFT JOIN taxon.taxref_12 t12 ON t12.cd_nom = o.cd_nom
LEFT JOIN taxon.taxref t ON t.cd_nom=d.cd_nom_remplacement::INTEGER
WHERE TRUE
AND tc.champ = 'CD_NOM'
AND tc.type_change = 'RETRAIT'
AND cd_nom_remplacement IS NULL
ORDER BY o.nom_cite ;
/* 3 obs pour 2 taxons :
Ctenopteris Blume ex Kunze cd_nom = 672559
Valamugil sp, cd_nom = 348427 */

-- Traitement de Ctenopteris Blume ex Kunze
-- taxon de remplacement : nom_complet = Ctenopteris Newman, 1851 [nom. illeg. superfl.]nom_valide : Polypodium L., 1753, cd_nom = 200267, cd_ref = 196545
-- TODO : Vérifier avec producteur

SELECT * FROM taxref WHERE lb_nom ilike ('Ctenopteris%') ORDER BY lb_nom ;
UPDATE observation
SET cd_nom = 200267, cd_ref = 196545, dee_date_derniere_modification = now()
WHERE cd_nom = 672559 ; -- 2 lignes mises à jour

-- Traitement de Valamugil sp
SELECT * FROM taxref WHERE lb_nom ilike ('Valamugil%') ;
-- taxon de remplacement : n'existe pas MNHN contacté pour voir pourquoi le taxon a été retiré

--SELECT * FROM taxref_local_source
SELECT Setval('taxon.taxref_local_cd_nom_seq', (SELECT Coalesce(min(cd_nom)-1, -1) FROM taxon.taxref_local ), false );
INSERT INTO taxon.taxref_local
 (regne, phylum, classe, ordre, famille, sous_famille, tribu, group1_inpn, group2_inpn, cd_nom, cd_sup, cd_ref, rang, lb_nom, lb_auteur, nom_complet, nom_valide, nom_vern, habitat, reu, local_bdd_code, local_identifiant_origine, local_identifiant_origine_ref)
SELECT regne, phylum, classe, ordre, famille, sous_famille, tribu, group1_inpn, group2_inpn,
        nextval('taxon.taxref_local_cd_nom_seq'::regclass),
        cd_sup,
        (nextval('taxon.taxref_local_cd_nom_seq'::regclass) +1),
        rang, lb_nom, lb_auteur, nom_complet, nom_valide, nom_vern, habitat, reu, 'rnnesp', cd_nom, cd_ref
FROM taxref_12
WHERE cd_nom = 348427
AND NOT EXISTS (SELECT lb_nom FROM taxon.taxref_local WHERE lb_nom = 'Valamugil'); -- 1 ligne

SELECT * FROM taxref_local WHERE lb_nom ilike ('Valamugil%') ; -- cd_nom = -152 en prod (-144 en dev)

UPDATE observation
SET cd_nom = -152, cd_ref = -152, dee_date_derniere_modification = now()
WHERE cd_nom = 348427 ; -- 1 ligne mise à jour

-- 3.3 Traitement des modifications de cd_ref
-----------------------------
WITH r AS (
        SELECT --DISTINCT o.cd_nom
        o.cle_obs, o.cd_nom, o.cd_ref, tc.valeur_final AS cd_ref_new, o.jdd_code
        FROM occtax.observation o
        LEFT JOIN taxon.taxref_changes_13 tc ON o.cd_ref::TEXT = tc.valeur_init
        WHERE TRUE
        AND o.cd_nom::TEXT = tc.cd_nom
        AND tc.champ = 'CD_REF'
        AND tc.type_change = 'MODIFICATION'
        ) --1586 obs pour 50 taxons

UPDATE occtax.observation o
SET
cd_ref = r.cd_ref_new::BIGINT,
dee_date_derniere_modification = now()
FROM r
WHERE r.cle_obs = o.cle_obs
; --1584 lignes

-- 3.4 Mise à jour dans la table observation des taxons issus de taxref_local
-----------------------------
WITH loc AS (
    SELECT tl.group2_inpn, tl.cd_nom AS cd_nom_old, t.cd_nom AS cd_nom_new, t.cd_ref AS cd_ref_new, tl.nom_valide, tl.nom_vern, t.nom_valide AS nom_valide_new, t.nom_vern AS nom_vern_new, t.rang, tl.cd_nom_valide
    FROM taxon.taxref_local tl
    INNER JOIN taxon.taxref t ON TRIM(LOWER(unaccent(tl.lb_nom)))=TRIM(LOWER(unaccent(t.lb_nom)))
    ),
maj AS (
    SELECT o.cle_obs,
    o.cd_nom AS cd_nom_old,
    loc.cd_nom_new,
    o.cd_ref AS cd_ref_old,
    loc.cd_ref_new
    FROM occtax.observation o
    INNER JOIN loc ON loc.cd_nom_old=o.cd_nom
    )

UPDATE occtax.observation o
SET cd_nom=maj.cd_nom_new::INTEGER,
    cd_ref=maj.cd_ref_new::INTEGER,
        version_taxref='13.0',
    dee_date_derniere_modification=now()
FROM maj
WHERE o.cle_obs=maj.cle_obs
; -- 12 lignes concernées


-- 3.5 Mise à jour du champ version_taxref
-----------------------------
UPDATE occtax.observation o
SET version_taxref='12.0'
WHERE o.cd_nom>0 -- Seulement pour les taxons dans Taxref (pas ceux dans Taxref_local)
; -- 453 976 lignes modifiées

UPDATE observation SET version_taxref=NULL
WHERE cd_nom < 0; -- 869 lignes


-----------------------------
-- 4. Mise à jour de la table des statuts t_complement
-----------------------------

-- 4.1 Import de la table des statuts
-----------------------------
-- On importe au préalable la base des statuts associée à TAXREF -> création de la table taxon.statuts_especes_13
DROP TABLE IF EXISTS taxon.statuts_especes_13 ;
CREATE TABLE taxon.statuts_especes_13 (
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

COMMENT ON TABLE taxon.statuts_especes_13 IS 'Statuts de taxon basés sur Taxref 13 (source : https://inpn.mnhn.fr/telechargement/referentielEspece/bdc-statuts-especes). La table ne contient pas les synonymes qui doivent donc être gérés via cd_ref';

SET client_encoding TO 'ISO-8859-15';
COPY taxon.statuts_especes_13
(cd_nom ,cd_ref ,cd_sup ,cd_type_statut ,lb_type_statut ,regroupement_type ,code_statut ,label_statut ,rq_statut ,cd_sig ,cd_doc ,lb_nom ,lb_auteur ,nom_complet_html ,nom_valide_html ,regne ,phylum ,classe ,ordre ,famille ,group1_inpn ,group2_inpn ,lb_adm_tr ,niveau_admin ,cd_iso3166_1 ,cd_iso3166_2 ,full_citation ,doc_url ,thematique ,type_value)
FROM '/tmp/BDC_STATUTS_13.csv' DELIMITER ',' HEADER CSV; -- 893 093 lignes
RESET client_encoding ;
SHOW client_encoding ;

-- Attention, la base ne contient pas les synonymes, qu'il faut donc traiter.
-- Par exemple Arenaria interpres (cd_nom = cd_ref = 3239) est le nom du taxon de référence, synonyme de Tringa interpres (cd_nom = 3241) qui ne figure pas dans statuts_especes_13 sur la liste rouge Réunion
SELECT * FROM statuts_especes_13
WHERE cd_nom IN (3241, 3239) AND lb_type_statut='Liste rouge nationale' AND lb_adm_tr='Réunion' ;


-- 4.2 Mise à jour si besoin de la table t_nomenclature pour avoir des catégories de statut adaptées
-----------------------------
-- TODO : cette partie doit être adaptée par chaque région, en fonction des données de référence disponibles, par exemple sur le niveau d'invasibilité des taxons (information renseignée de manière incomplète dans Taxref)


-- Endémicité
SELECT * FROM t_nomenclature WHERE champ = 'endemicite' AND code IN  ('E', 'S');
UPDATE t_nomenclature SET valeur = 'Endémique de La Réunion' WHERE champ = 'endemicite' AND code = 'E';
UPDATE t_nomenclature SET valeur = 'Endémique des Mascareignes' WHERE champ = 'endemicite' AND code = 'S';

-- Statut :
SELECT * FROM t_nomenclature
WHERE champ = 'statut'
/* Avant la modification, on avait :
statut$I$Indigène$$1
statut$E$Exotique$$2
*/

DELETE FROM t_nomenclature WHERE champ = 'statut' ;
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES
('statut', 'I', 'Indigène', ' Taxons pour lesquels reu IN (P, S, E, Z, B, W, X)', 1),
('statut', 'E', 'Exotique', 'Taxons pour lesquels reu IN (I, J, M, Y, D, A, Q)', 2),
('statut', 'ND', 'Non documenté', 'Taxon non documenté, cad pour lequels reu =C ou NULL', 3) ;

-- Protection :
SELECT * FROM t_nomenclature
WHERE champ = 'protection'
/* Avant la modification, on avait :
protection$EPN$Protection nationale$$1
protection$EPC$Protection communautaire (UE)$$2
protection$EPI$Protection internationale$$3
protection$EPA$Autre statut$Autre statut d'espèce (espèce invasive de lutte obligatoire, etc.)$4
*/

DELETE FROM t_nomenclature WHERE champ = 'protection' AND code IN ('EPC', 'EPI', 'EPA') ; -- on ne garde que la protection nationale, qui intéresse plus les utilisateurs


-- Invasibilité :
SELECT * FROM t_nomenclature
WHERE champ = 'invasibilite'
/* Avant la modification, on avait :
invasibilite$NE$Non envahissant$$1
invasibilite$PE$Potentiellement envahissant$$2
invasibilite$E$Envahissant$$3
invasibilite$EM$Envahissant majeur$$4
*/

DELETE FROM t_nomenclature WHERE champ = 'invasibilite' ;
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES
('invasibilite', 'E', 'Envahissant', 'Taxon envahissant d''après Taxref corrigé par l''analyse réalisée par le GEIR (pour les plantes) et Taxref uniquement (pour les animaux)', 1),
('invasibilite', 'PE', 'Potentiellement envahissant', 'Taxon potentiellement envahissant d''après l''analyse réalisée par le GEIR', 2),
('invasibilite', 'ND', 'Exotique à risque invasif non documenté', 'Taxon sans caractère envahissant connu à La Réunion d''après l''analyse réalisée par le GEIR. Taxons pour lesquels reu IN (I, M, Y, D, A, Q), qui ne sont pas déjà cités dans un autre statut PE ou E', 3) ;


-- 4.3 Vidage puis remplissage de t_complement et traitement des champs statut, endemicite et invasibilite
-----------------------------

COMMENT ON TABLE taxon.t_complement
    IS 'Stockage des données complémentaires sur les taxons, non présentes dans TAXREF : données locales (endémicité, invasibilité, etc.), déterminants ZNIEFF, menaces... La table contient tous les taxons, y compris les synonymes.';
-- Ancienne valeur du commentaire pour mémoire : COMMENT ON TABLE taxon.t_complement IS 'Stockage des données complémentaires sur les taxons, non présents dans TAXREF : données locales (endémicité, invasibilité, etc.), déterminants ZNIEFF';

DELETE FROM t_complement WHERE cd_nom_fk IN (SELECT cd_nom FROM taxref UNION SELECT cd_nom FROM taxref_local); -- 570 304 lignes supprimées
INSERT INTO taxon.t_complement(cd_nom_fk, statut, endemicite, invasibilite) -- on ne renseigne pas le champ rarete à La Réunion car pas d'info
SELECT cd_nom,
        -- statut
                CASE
                                WHEN reu IN ('I', 'J', 'M', 'Y', 'D', 'A', 'Q') THEN 'E' -- Exotique. vlt 28/11/2019 : j'ai rajouté Y (introduit éteint), A (Absent), Q (mentionné par erreur) et D (douteux : Taxon dont la présence dans la zone géographique considérée n'est pas avérée (en attente de confirmation)). Peut être complété aussi à la partie 4.8 lorsqu'on a plus d'informations sur l'invasibilité (et donc le caractère exotique) des taxons

                                WHEN reu IN ('P', 'S', 'E', 'Z', 'B', 'W', 'X') THEN 'I' -- Indigène. vlt 28/11/2019 : j'ai rajouté Z (endémique éteint), W (Disparu), X (Eteint) et B (Occasionnel)

                                ELSE 'ND' -- non documenté, correspond à reu = 'C' et à reu NULL
                END AS statut,

                -- rarete : COMMENTE CAR SUJET A DEBAT
                -- CASE
                                -- WHEN reu IN ('B', 'M') THEN 'R'
                                -- WHEN reu IN ('E', 'I', 'J', 'P', 'S') THEN 'C'
                                -- WHEN reu IN ('C') THEN 'E'
                                -- ELSE NULL
                -- END AS rarete,

                -- endemicite
                CASE
                                WHEN reu IN ('E', 'Z') THEN 'E'
                                WHEN reu IN ('S') THEN 'S'
                                ELSE NULL
                END AS endemicite,

                -- invasibilite
                CASE
                        WHEN reu IN ('J') THEN 'E' -- envahissant. Si des informations plus )précises  existent localement sur le niveau d'invasibilité, les renseigner spécifiquement comme indiqué à la partie 4.8 ci-dessous
                        WHEN reu IN ('I', 'M', 'Y', 'D', 'A', 'Q') THEN 'ND'-- Exotique sans caractère invasif documenté. toutes les exotiques non classées J
                        ELSE NULL
                END AS invasibilite

FROM (SELECT cd_nom, reu FROM taxref UNION SELECT cd_nom, reu FROM taxref_local) tt  -- vlt 28/11/2019 : attention à bien se baser sur taxref et pas taxref valide, sinon on n'a pas les synonymes et on perd environ 50% des lignes
ON CONFLICT (cd_nom_fk) DO NOTHING; --> 595 474 lignes ajoutées contre 249 672 lignes ajoutées avant avec Taxref_valide


-- 4.4 Mise à jour du champ menace_regionale
-----------------------------

-- Etat des lieux préalable des listes rouges à prendre en compte :
SELECT lb_type_statut,  lb_adm_tr, cd_sig, code_statut, label_statut, full_citation, count(*)
FROM taxon.statuts_especes_13
WHERE lb_type_statut ILIKE 'Liste rouge%'
GROUP BY lb_type_statut, lb_adm_tr, cd_sig, full_citation, code_statut, label_statut
ORDER BY lb_type_statut, lb_adm_tr, code_statut, label_statut ; -- Pour La Réunion, 3 LR de statut national : faune (2010), flore (2010), coraux constructeurs (2020). Prendre lb_adm_tr = 'Réunion'

WITH taxref_mnhn_et_local AS (
                SELECT cd_nom, cd_ref FROM taxon.taxref UNION SELECT cd_nom, cd_ref FROM taxref_local

        ), menace AS (
                SELECT DISTINCT t.cd_ref, t.cd_nom, s.code_statut
                FROM taxref_mnhn_et_local t
                INNER JOIN taxon.statuts_especes_13 s ON s.cd_nom = t.cd_nom
                WHERE s.lb_type_statut='Liste rouge nationale' AND s.lb_adm_tr='Réunion' -- 1 398 lignes -- TODO : remplacer ici par le nom de la région concernée. On prend pour renseigner ce champ la liste de niveau national. En effet, pour le îles, la distinction entre volet local d'une liste rouge nationale et liste rouge régionale est ténue.

        ), menace_des_synonymes AS ( -- on est obligé de procéder en deux temps car du fait des mises en synonymies successives, on peut avoir pour un taxon et son synonyme des statuts différents !
                SELECT DISTINCT t.cd_ref, t.cd_nom, s.code_statut
                FROM taxref_mnhn_et_local t
                INNER JOIN taxon.statuts_especes_13 s ON (t.cd_ref = s.cd_nom AND s.cd_nom <> t.cd_nom)
                WHERE s.lb_type_statut='Liste rouge nationale' AND s.lb_adm_tr='Réunion' -- 7 379lignes -- TODO : remplacer ici par le nom de la région concernée

        ), synthese_menace AS (
                SELECT * FROM menace
                UNION
                SELECT * FROM menace_des_synonymes
                ORDER BY cd_ref -- 5774 lignes
                )
UPDATE taxon.t_complement t
SET menace_regionale = synthese_menace.code_statut
FROM synthese_menace
WHERE synthese_menace.cd_nom = t.cd_nom_fk ; -- 5774 lignes MAJ


-- 4.5 Mise à jour du champ menace_nationale
-----------------------------

-- Etat des lieux préalable des listes rouges à prendre en compte :
SELECT lb_type_statut,  lb_adm_tr, cd_sig, code_statut, label_statut, full_citation, count(*)
FROM taxon.statuts_especes_13
WHERE lb_type_statut ILIKE 'Liste rouge%'
GROUP BY lb_type_statut, lb_adm_tr, cd_sig, full_citation, code_statut, label_statut
ORDER BY lb_type_statut, lb_adm_tr, code_statut, label_statut ; -- Pour La Réunion, 3 LR de statut national : faune (2010), flore (2010), coraux constructeurs (2020). Prendre lb_adm_tr = 'Réunion'

WITH taxref_mnhn_et_local AS (
                SELECT cd_nom, cd_ref FROM taxon.taxref UNION SELECT cd_nom, cd_ref FROM taxref_local

        ), menace AS (
                SELECT DISTINCT t.cd_ref, t.cd_nom, s.code_statut
                FROM taxref_mnhn_et_local t
                INNER JOIN taxon.statuts_especes_13 s ON s.cd_nom = t.cd_nom
                WHERE s.lb_type_statut='Liste rouge nationale' AND s.lb_adm_tr='Réunion' -- 1 398 lignes -- TODO : remplacer ici par le nom de la région concernée.

        ), menace_des_synonymes AS ( -- on est obligé de procéder en deux temps car du fait des mises en synonymies successives, on peut avoir pour un taxon et son synonyme des statuts différents !
                SELECT DISTINCT t.cd_ref, t.cd_nom, s.code_statut
                FROM taxref_mnhn_et_local t
                INNER JOIN taxon.statuts_especes_13 s ON (t.cd_ref = s.cd_nom AND s.cd_nom <> t.cd_nom)
                WHERE s.lb_type_statut='Liste rouge nationale' AND s.lb_adm_tr='Réunion' -- 7 379lignes -- TODO : remplacer ici par le nom de la région concernée

        ), synthese_menace AS (
                SELECT * FROM menace
                UNION
                SELECT * FROM menace_des_synonymes
                ORDER BY cd_ref -- 5774 lignes
                )
UPDATE taxon.t_complement t
SET menace_nationale = synthese_menace.code_statut
FROM synthese_menace
WHERE synthese_menace.cd_nom = t.cd_nom_fk ; -- 5774 lignes MAJ


-- 4.6 Mise à jour du champ menace_monde
-----------------------------
WITH taxref_mnhn_et_local AS (
                SELECT cd_nom, cd_ref FROM taxon.taxref UNION SELECT cd_nom, cd_ref FROM taxref_local

        ), menace AS (
                SELECT DISTINCT t.cd_ref, t.cd_nom, s.code_statut
                FROM taxref_mnhn_et_local t
                INNER JOIN taxon.statuts_especes_13 s ON s.cd_nom = t.cd_nom
                WHERE s.lb_type_statut='Liste rouge mondiale' -- 14 687 lignes

        ), menace_des_synonymes AS ( -- on est obligé de procéder en deux temps car du fait des mises en synonymies successives, on peut avoir pour un taxon et son synonyme des statuts différents !
                SELECT DISTINCT t.cd_ref, t.cd_nom, s.code_statut
                FROM taxref_mnhn_et_local t
                INNER JOIN taxon.statuts_especes_13 s ON (t.cd_ref = s.cd_nom AND s.cd_nom <> t.cd_nom)
                WHERE s.lb_type_statut='Liste rouge mondiale' -- 39 417 lignes

        ), synthese_menace AS (
                SELECT * FROM menace
                UNION
                SELECT * FROM menace_des_synonymes
                ORDER BY cd_ref -- 53 854 lignes
                )
UPDATE taxon.t_complement t
SET menace_monde = synthese_menace.code_statut
FROM synthese_menace
WHERE synthese_menace.cd_nom = t.cd_nom_fk ; -- 53 854 lignes MAJ


-- 4.7 Mise à jour du champ protection
-----------------------------

-- Etat des lieux préalable des protections à prendre en compte :
SELECT lb_type_statut,  lb_adm_tr, cd_sig, code_statut, label_statut, full_citation, count(*)
FROM taxon.statuts_especes_13
WHERE lb_type_statut ILIKE 'Protection%'
GROUP BY lb_type_statut, lb_adm_tr, cd_sig, full_citation, code_statut, label_statut
ORDER BY lb_type_statut, lb_adm_tr, code_statut, label_statut ;

-- Correction préalable d'une erreur avérée concernant Phelsuma inexpectata, qui est protégée nationale (mais a été listée par erreur sous le nom Phelsuma ornata dans l'arrêté ministériel)
INSERT INTO taxon.statuts_especes_13
SELECT  pheine.cd_nom, pheine.cd_ref, pheine.cd_sup, phebor.cd_type_statut, phebor.lb_type_statut, phebor.regroupement_type,
                phebor.code_statut, phebor.label_statut, phebor.rq_statut, phebor.cd_sig, phebor.cd_doc, pheine.lb_nom,
                pheine.lb_auteur, pheine.nom_complet_html, pheine.nom_valide_html, pheine.regne, pheine.phylum, pheine.classe,
                pheine.ordre, pheine.famille, pheine.group1_inpn, pheine.group2_inpn, phebor.lb_adm_tr, phebor.niveau_admin, phebor.cd_iso3166_1, phebor.cd_iso3166_2,
                phebor.full_citation, phebor.doc_url, phebor.thematique, phebor.type_value
FROM (
        SELECT * FROM taxon.statuts_especes_13 WHERE cd_nom = 528679 LIMIT 1-- lb_nom = 'Phelsuma inexpectata'
        ) AS pheine,
        (SELECT * FROM taxon.statuts_especes_13 WHERE cd_nom = 432597 and code_statut = 'REUEA2'-- Phelsuma borbonica, qui est sur le même arrêté que Ph. borbonica
        ) AS phebor ; -- 1 ligne ajoutée

-- Mise à jour de la table t_complement
WITH taxref_mnhn_et_local AS (
                SELECT cd_nom, cd_ref FROM taxon.taxref UNION SELECT cd_nom, cd_ref FROM taxref_local

        ), protection AS (
                SELECT DISTINCT t.cd_ref, t.cd_nom, s.code_statut
                FROM taxref_mnhn_et_local t
                INNER JOIN taxon.statuts_especes_13 s ON s.cd_nom = t.cd_nom -- 513 lignes
                WHERE   (lb_adm_tr IN ('France', 'Réunion') AND lb_type_statut ILIKE 'Protection%') -- TODO : à adapter en fonction des régions
                                OR code_statut = 'NTAA1' -- mal rempli dans la v11, la v12 et la v13 de la BDD statuts -- 8388 lignes

        ), protection_des_synonymes AS ( -- on est obligé de procéder en deux temps car du fait des mises en synonymies successives, on peut avoir pour un taxon et son synonyme des statuts différents !
                SELECT DISTINCT t.cd_ref, t.cd_nom, s.code_statut
                FROM taxref_mnhn_et_local t
                INNER JOIN taxon.statuts_especes_13 s ON (t.cd_ref = s.cd_nom AND s.cd_nom <> t.cd_nom) -- 1 780 lignes
                WHERE   (lb_adm_tr IN ('France', 'Réunion') AND lb_type_statut ILIKE 'Protection%') -- TODO : à adapter en fonction des régions
                                OR code_statut = 'NTAA1'

        ), union_protection AS (
                SELECT * FROM protection
                UNION
                SELECT * FROM protection_des_synonymes
                ORDER BY cd_ref -- 27 685 lignes

        ), synthese_protection AS (
                SELECT cd_nom, code_statut,

                        CASE
                                WHEN code_statut IN ('REUEA2', 'REUEA3', 'REUEA4', 'REUI2', 'VP974', 'NTAA1', 'NFM1', 'NMAMmar2', 'NMAMmar3', 'NMAMmar5', 'NTM1') THEN 'EPN'
                                /*WHEN code_statut IN ('IBO1', 'IBO2', 'IBOAC', 'IBOAE', 'IBOAS', 'IBOAW', 'IBOC', 'IBOEU', 'REUEA2', 'REUEA3', 'REUEA4', 'REUI2', 'VP974', 'NFM1', 'NMAMmar2', 'NMAMmar3', 'NMAMmar5', 'NTM1', 'NTAA1', 'IAO3') THEN 'EPI'
                                WHEN code_statut IN ('REUP', 'Bubul1', 'Bulbul2', 'Bulbul3', 'Bulbul4', 'Bulbul5', 'Bulbul6', 'Bulbul9', 'corbasi1', 'phelsuma1', 'phelsuma2', 'phelsuma3', 'phelsuma4', 'phelsuma5', 'REUEEA', 'REUEEI', 'REUnoEEEA2', 'agri1', 'agri2', 'PV97', 'REUnoEEEA', 'REUnoEEEV') THEN 'EPA'
                                ELSE NULL*/
                        END AS protection,

                -- TODO : si on ne retient plus que la protection nationale, le champ note n'est plus utile à renseigner
                        CASE
                                WHEN code_statut IN ('REUEA2', 'REUEA3', 'REUEA4', 'REUI2', 'VP974', 'NTAA1', 'NFM1', 'NMAMmar2', 'NMAMmar3', 'NMAMmar5', 'NTM1') THEN 0 -- EPN
                                --WHEN cd_protection IN ({$code_arrete_protection_communautaire}) THEN 1
                                WHEN code_statut IN ('IBO1', 'IBO2', 'IBOAC', 'IBOAE', 'IBOAS', 'IBOAW', 'IBOC', 'IBOEU', 'REUEA2', 'REUEA3', 'REUEA4', 'REUI2', 'VP974', 'NFM1', 'NMAMmar2', 'NMAMmar3', 'NMAMmar5', 'NTM1', 'NTAA1', 'IAO3') THEN 2 -- EPI
                                WHEN code_statut IN ('REUP', 'Bubul1', 'Bulbul2', 'Bulbul3', 'Bulbul4', 'Bulbul5', 'Bulbul6', 'Bulbul9', 'corbasi1', 'phelsuma1', 'phelsuma2', 'phelsuma3', 'phelsuma4', 'phelsuma5', 'REUEEA', 'REUEEI', 'REUnoEEEA2', 'agri1', 'agri2', 'PV97', 'REUnoEEEA', 'REUnoEEEV') THEN 3 -- EPA
                                ELSE NULL
                        END AS note
                FROM union_protection -- 27 685 lignes

        ), synthese_protection_priorisee AS (
                SELECT DISTINCT cd_nom,
                        FIRST_VALUE(code_statut) OVER (PARTITION BY cd_nom ORDER BY note) AS code_statut,
                        FIRST_VALUE(protection) OVER (PARTITION BY cd_nom ORDER BY note) AS protection
                FROM synthese_protection -- 21 370 lignes
                )

UPDATE taxon.t_complement t SET protection = s.protection
FROM synthese_protection_priorisee s
WHERE s.cd_nom = t.cd_nom_fk ; -- 2226 lignes MAJ




-- 4.8 Mise à jour du champ det_znieff
-----------------------------
WITH taxref_mnhn_et_local AS (
                SELECT cd_nom, cd_ref FROM taxon.taxref UNION SELECT cd_nom, cd_ref FROM taxref_local

        ), znieff AS (
                SELECT DISTINCT t.cd_ref, t.cd_nom
                FROM taxref_mnhn_et_local t
                INNER JOIN taxon.statuts_especes_13 s ON s.cd_nom = t.cd_nom
                WHERE cd_type_statut='ZDET' AND lb_adm_tr IN ('Réunion') -- 1 139 lignes

        ), znieff_des_synonymes AS ( -- on est obligé de procéder en deux temps car du fait des mises en synonymies successives, on peut avoir pour un taxon et son synonyme des statuts différents !
                SELECT DISTINCT t.cd_ref, t.cd_nom
                FROM taxref_mnhn_et_local t
                INNER JOIN taxon.statuts_especes_13 s ON (t.cd_ref = s.cd_nom AND s.cd_nom <> t.cd_nom)
                WHERE cd_type_statut='ZDET' AND lb_adm_tr IN ('Réunion') -- 2058 lignes

        ), synthese_znieff AS (
                SELECT * FROM znieff
                UNION
                SELECT * FROM znieff_des_synonymes
                ORDER BY cd_ref -- 3 163 lignes
                )
UPDATE taxon.t_complement t SET det_znieff = 'Déterminante'
FROM synthese_znieff s
WHERE s.cd_nom = t.cd_nom_fk ; -- 3 195 lignes MAJ

-- En prod : INSERT INTO taxon.taxref_13 (SELECT * FROM occtax_dev.taxref) ;


-- 4.9 Mise à jour optionnelle du champ invasibilité
-----------------------------
-- Lorsque l'information existe, on peut aller plus loin que le seul statut J indiqué par Taxref pour remplir le champ invasibilite de la table taxon.t_complement. A La Réunion, on le fait depuis 2020, à partir de deux fichiers disjoints issus du GEIR : un pour la flore et un pour la faune

-- 4.9.1 Traitement de la flore
-------------------------------
DROP TABLE IF EXISTS taxon.invasibilite_flore_reu ;
CREATE TABLE taxon.invasibilite_flore_reu(
        famille TEXT,
        cd_taxref TEXT,
        nom_scientifique TEXT,
        synonymes TEXT,
        nom_vern TEXT,
        fiche TEXT,
        carte_borbonica TEXT,
        reglementation TEXT,
        milieux_anthropiques_confines TEXT,
        milieux_anthropiques_non_confines TEXT,
        milieux_naturels TEXT,
        statut_reu_propose TEXT,
        invasibilite_constatee TEXT,
        caractere_envahissant TEXT,
        maitrise_developpement TEXT,
        maitrise_dispersion TEXT,
        controle_fruits TEXT,
        evacuation_dechets TEXT,
        autre_conseil TEXT,
        lutte_reunion_et_monte TEXT,
        eradicable_reunion TEXT,
        observations TEXT,
        sources TEXT,
        synthese_invasibilite TEXT,
        fiche_inpn TEXT, -- ce champ et les suivants sont rajoutés au moment de l'import en vue de compléter ensuite le fichier source du GEIR
        id INTEGER
        ) ;


COMMENT ON TABLE taxon.invasibilite_flore_reu IS 'Tableau issu du GEIR indiquant les niveaux d''invasibilité des plantes exotiques à La Réunion. A vocation à être mis à jour régulièrement';

COPY taxon.invasibilite_flore_reu
FROM '/tmp/Liste_PEE_Tutti_La Réunion_v11082020.csv' DELIMITER '$' HEADER CSV; -- 1091 lignes

-- Correction manuelle d'erreurs ou omissions :
UPDATE taxon.invasibilite_flore_reu
SET cd_taxref = '80138' WHERE cd_taxref = '80138 ?' ;
UPDATE taxon.invasibilite_flore_reu
SET cd_taxref = NULL WHERE cd_taxref = ' ' ;
UPDATE taxon.invasibilite_flore_reu
SET cd_taxref = 80140 WHERE nom_scientifique = 'Actinidia deliciosa (A. Chev.) C.F. Liang et A.R. Ferguson' ;
UPDATE taxon.invasibilite_flore_reu
SET cd_taxref = NULL WHERE nom_scientifique = 'Memecylon caeruleum' ;
UPDATE taxon.invasibilite_flore_reu
SET cd_taxref = 631008 WHERE nom_scientifique = 'Schefflera pubigera (Brongn. ex Planch.) Frodin' ;
UPDATE taxon.invasibilite_flore_reu
SET cd_taxref = 701783 WHERE nom_scientifique = 'Plerandra elegantissima (H.J. Veitch ex Mast.) Lowry, G.M. Plunkett et Frodin' ;
UPDATE taxon.invasibilite_flore_reu
SET cd_taxref = 634899 WHERE nom_scientifique = 'Mimosa tenuiflora' ;
UPDATE taxon.invasibilite_flore_reu
SET cd_taxref = 79707 WHERE nom_scientifique = 'Acacia retinoides' ;

-- On vérifie si certains taxons sont dans taxref_local et on met à jour le cd_taxref en conséquence si besoin
WITH r AS (
        SELECT i.nom_scientifique, tl.cd_nom
        FROM taxon.invasibilite_flore_reu i
        INNER JOIN taxref_local tl ON i.nom_scientifique = tl.lb_nom
        WHERE tl.cd_nom_valide IS NULL
        ORDER BY i.nom_scientifique
        )
UPDATE taxon.invasibilite_flore_reu i
SET cd_taxref = r.cd_nom
FROM r
WHERE i.nom_scientifique = r.nom_scientifique ; -- 1 ligne mise à jour en prod


-- On vérifie le cd_taxref indiqué
ALTER TABLE taxon.invasibilite_flore_reu ADD COLUMN cd_nom_verifie INTEGER ;

-- On complète déjà sur la base du cd_taxref_renseigné
WITH r AS (
        SELECT i.nom_scientifique, t.lb_nom, i.synthese_invasibilite, t.reu, t.cd_nom
        FROM taxon.invasibilite_flore_reu i
        INNER JOIN (
                SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu FROM taxref
                UNION
                SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu FROM taxref_local WHERE cd_nom_valide IS NULL
                )t ON i.cd_taxref::INTEGER = t.cd_nom
        WHERE cd_nom_verifie IS NULL
                AND group1_inpn IN ('Trachéophytes', 'Bryophytes')  -- 806 lignes
                -- AND lower(lb_nom) <> lower(TRIM(i.nom_scientifique)) -- pour vérifier qu'il n'y ait pas d'erreurs : tout est bon sauf quelques coquilles orthographiques signalées, et quelques code_taxref erronnés corrigés plus haut
        ORDER BY lb_nom
        )
UPDATE taxon.invasibilite_flore_reu i
SET cd_nom_verifie = r.cd_nom
FROM r
WHERE i.nom_scientifique = r.nom_scientifique AND cd_nom_verifie IS NULL ; -- 806 MAJ

-- On complète ensuite sur la base du nom_scientifique en prenant déjà le nom du taxon de référence
WITH r AS (
SELECT i.nom_scientifique, t.lb_nom, i.synthese_invasibilite, t.reu, t.cd_nom
FROM taxon.invasibilite_flore_reu i
INNER JOIN (
        SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu FROM taxref
        UNION
        SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu FROM taxref_local WHERE cd_nom_valide IS NULL
        )t ON lower(lb_nom) = lower(TRIM(i.nom_scientifique))
WHERE cd_nom_verifie IS NULL
        AND group1_inpn IN ('Trachéophytes', 'Bryophytes')
        AND t.cd_nom = t.cd_ref-- 78 lignes supplémentaires
ORDER BY lb_nom
        )

UPDATE taxon.invasibilite_flore_reu i
SET cd_nom_verifie = r.cd_nom
FROM r
WHERE i.nom_scientifique = r.nom_scientifique AND cd_nom_verifie IS NULL ; -- 78 MAJ

-- On complète ensuite sur la base du nom_scientifique en prenant ensuite un autre nom
WITH r AS (
SELECT i.nom_scientifique, t.lb_nom, i.synthese_invasibilite, t.reu, t.cd_nom
FROM taxon.invasibilite_flore_reu i
INNER JOIN (
        SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu FROM taxref
        UNION
        SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu FROM taxref_local WHERE cd_nom_valide IS NULL
        )t ON lower(lb_nom) = lower(TRIM(i.nom_scientifique))
WHERE cd_nom_verifie IS NULL
        AND group1_inpn IN ('Trachéophytes', 'Bryophytes')
        AND t.cd_nom <> t.cd_ref-- 7 lignes supplémentaires
ORDER BY lb_nom
        )

UPDATE taxon.invasibilite_flore_reu i
SET cd_nom_verifie = r.cd_nom
FROM r
WHERE i.nom_scientifique = r.nom_scientifique AND cd_nom_verifie IS NULL ; -- 5 lignes mises à jour -- TODO : vérifier après retour IB quel cd_nom prendre pour les deux taxons homonymes

-- bilan
SELECT nom_scientifique FROM taxon.invasibilite_flore_reu WHERE cd_nom_verifie IS NULL ORDER BY nom_scientifique ; --> envoi à Taxref match au cas où

-- synthèse de la réconciliation taxonomique
SELECT i.nom_scientifique, t.lb_nom, t.nom_complet, t.nom_valide, t.cd_nom, t.cd_ref, t.reu
FROM taxon.invasibilite_flore_reu i
INNER JOIN (
        SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu FROM taxref
        UNION
        SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu FROM taxref_local WHERE cd_nom_valide IS NULL
        )t ON i.cd_nom_verifie = t.cd_nom
ORDER BY lb_nom;

-- Mise à jour de la table t_complement :

-- Etat des lieux préalable et après UPDATE :
SELECT statut, count(*) FROM t_complement GROUP BY statut ;
/* Avant l'UPDATE :
E$52212
I$47871
ND$496326
Après l'UPDATE :
E$52620
I$47865
ND$495924
*/
SELECT invasibilite , count(*) from t_complement group by invasibilite ;
/* Avant l'UPDATE :
E$789
ND$51383
Après l'UPDATE :
E$819
ND$51406
PE$355
$543829
$544243
*/

WITH r AS (
        SELECT t.cd_nom, t.lb_nom, i.synthese_invasibilite, t.reu
        FROM (
                SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu FROM taxref
                UNION
                SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu FROM taxref_local WHERE cd_nom_valide IS NULL
                )t
        INNER JOIN taxon.invasibilite_flore_reu i ON i.cd_nom_verifie = t.cd_nom
        WHERE group1_inpn IN ('Trachéophytes', 'Bryophytes')
        ORDER BY lb_nom
        )
UPDATE taxon.t_complement tc
SET invasibilite =
        CASE
                WHEN r.synthese_invasibilite = 'Espèce envahissante' THEN 'E'
                WHEN r.synthese_invasibilite = 'Potentiellement envahissante' THEN 'PE'
                WHEN r.synthese_invasibilite = 'Exotique à risque invasif non documenté' THEN 'ND'
        END,
        statut = 'E'-- par définition, les espèces du fichier GEIR sont exotiques
FROM r
WHERE r.cd_nom = tc.cd_nom_fk ;

-- Mise à jour de la table taxref_local : -- on ne fait pas la même chose pour Taxref, qui doit rester la base de référence identique à celle diffusée par le MNHN sous peine de générer des confusions
WITH r AS (
        SELECT t.cd_nom, t.lb_nom, i.synthese_invasibilite, t.reu
        FROM (
                SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu FROM taxref
                UNION
                SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu FROM taxref_local WHERE cd_nom_valide IS NULL
                )t
        INNER JOIN taxon.invasibilite_flore_reu i ON i.cd_nom_verifie = t.cd_nom
        WHERE group1_inpn IN ('Trachéophytes', 'Bryophytes')
        ORDER BY lb_nom
        )
UPDATE taxon.taxref_local t
SET reu = 'J'
FROM r
WHERE r.cd_nom = t.cd_nom AND r.synthese_invasibilite = 'Espèce envahissante'; -- 0 mises à jour


-- 4.9.2 Traitement de la faune
-------------------------------
DROP TABLE IF EXISTS taxon.invasibilite_faune_reu ;
CREATE TABLE taxon.invasibilite_faune_reu(
        categorie TEXT,
        cd_taxref TEXT,
        rang TEXT,
        classe TEXT,
        sous_classe TEXT,
        infra_classe TEXT,
        cohorte TEXT,
        super_ordre TEXT,
        ordre TEXT,
        sous_ordre TEXT,
        infra_ordre TEXT,
        super_famille TEXT,
        famille TEXT,
        sous_famille TEXT,
        tribu TEXT,
        nom_scientifique TEXT,
        synonymes TEXT,
        nom_vern TEXT,
        fiches TEXT,
        carte_borbonica TEXT,
        reglementation TEXT,
        milieux_anthropiques_confines TEXT,
        milieux_anthropiques_non_confines TEXT,
        milieux_naturels TEXT,
        domestique TEXT,
        reu TEXT,
        statut_reu_propose TEXT,
        invasibilite_constatee TEXT,
        caractere_envahissant TEXT,
        gestion_reunion TEXT,
        envahissante_monde TEXT,
        usages TEXT,
        cites TEXT,
        fsc_decalaration TEXT,
        fsc_cc_ao TEXT,
        "references" TEXT,
        remarques TEXT,
        ari_seor_2011 TEXT,
        ari_arda_2011 TEXT,
        etude_noi_2012 TEXT,
        ari_oncfs_2012 TEXT,
        avis_oncfs_2011 TEXT,
        ari_micropoda_2018 TEXT,
        avis_csrpn_2016 TEXT,
        avis_membre_cdnps_2018 TEXT,
        avis_reptiles_974 TEXT,
        synthese_invasibilite TEXT,
        fiche_inpn TEXT, -- ce champ et les suivants sont rajoutés au moment de l'import en vue de compléter ensuite le fichier source du GEIR
        id INTEGER
        ) ;

COMMENT ON TABLE taxon.invasibilite_faune_reu IS 'Tableau issu du GEIR indiquant les niveaux d''invasibilité des animaux exotiques à La Réunion. A vocation à être mis à jour régulièrement';

COPY taxon.invasibilite_faune_reu
FROM '/tmp/Liste_AEE_Tutti_La Réunion_v12082020.csv' DELIMITER '$' HEADER CSV; -- 1408 lignes

SELECT * FROM taxon.invasibilite_faune_reu ;

-- Correction manuelle d'erreurs ou omissions :
UPDATE taxon.invasibilite_faune_reu
SET cd_taxref = NULL WHERE cd_taxref = ' ' ;
UPDATE taxon.invasibilite_faune_reu
SET cd_taxref = 638391 WHERE nom_scientifique = 'Gryllodes sigillatus' ; -- TODO : confirmer par IB
UPDATE taxon.invasibilite_faune_reu
SET cd_taxref = NULL WHERE nom_scientifique IS NULL AND cd_taxref IN ('216336', '219009', '906182') ; -- cd_taxref erronnés correspondant à des lignes d'ordre et sous-classe

-- On vérifie si certains taxons sont dans taxref_local et on met à jour le cd_taxref en conséquence si besoin
WITH r AS (
        SELECT i.nom_scientifique, tl.cd_nom
        FROM taxon.invasibilite_faune_reu i
        INNER JOIN taxref_local tl ON i.nom_scientifique = tl.lb_nom
        WHERE tl.cd_nom_valide IS NULL
        ORDER BY i.nom_scientifique
        )
UPDATE taxon.invasibilite_faune_reu i
SET cd_taxref = r.cd_nom
FROM r
WHERE i.nom_scientifique = r.nom_scientifique ; -- 24 lignes mises à jour en dév, 25 en prod


-- On vérifie le cd_taxref indiqué
ALTER TABLE taxon.invasibilite_faune_reu ADD COLUMN cd_nom_verifie INTEGER ;

-- On complète déjà sur la base du cd_taxref_renseigné
WITH r AS (
        SELECT i.nom_scientifique, t.lb_nom, i.synthese_invasibilite, t.reu, t.cd_nom, t.cd_ref, t.rang
        FROM taxon.invasibilite_faune_reu i
        INNER JOIN (
                SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu, rang FROM taxref
                UNION
                SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu, rang FROM taxref_local WHERE cd_nom_valide IS NULL
                )t ON i.cd_taxref::INTEGER = t.cd_nom
        WHERE cd_nom_verifie IS NULL
                AND group1_inpn NOT IN ('Trachéophytes', 'Bryophytes')  -- 370 lignes
                --AND lower(lb_nom) <> lower(TRIM(i.nom_scientifique)) -- pour vérifier qu'il n'y ait pas d'erreurs : tout est bon sauf quelques coquilles orthographiques signalées et non bloquantes, et quelques code_taxref erronnés corrigés plus haut
        ORDER BY lb_nom
        )
UPDATE taxon.invasibilite_faune_reu i
SET cd_nom_verifie = r.cd_nom
FROM r
WHERE i.nom_scientifique = r.nom_scientifique AND cd_nom_verifie IS NULL ; -- 368 MAJ en prod


-- On complète ensuite sur la base du nom_scientifique en prenant déjà le nom du taxon de référence
WITH r AS (
        SELECT i.nom_scientifique, t.lb_nom, i.synthese_invasibilite, t.reu, i.cd_taxref, t.cd_nom, t.cd_ref, t.rang
        FROM taxon.invasibilite_faune_reu i
        INNER JOIN (
                SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu, rang FROM taxref
                UNION
                SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu, rang FROM taxref_local WHERE cd_nom_valide IS NULL
                )t ON lower(lb_nom) = lower(TRIM(i.nom_scientifique))
        WHERE cd_nom_verifie IS NULL
                AND group1_inpn NOT IN ('Trachéophytes', 'Bryophytes')
                AND t.cd_nom = t.cd_ref-- 26 lignes
        ORDER BY lb_nom
        )

UPDATE taxon.invasibilite_faune_reu i
SET cd_nom_verifie = r.cd_nom
FROM r
WHERE i.nom_scientifique = r.nom_scientifique AND cd_nom_verifie IS NULL ; -- 26 MAJ en prod

-- On complète ensuite sur la base du nom_scientifique en prenant ensuite un autre nom
WITH r AS (
        SELECT i.nom_scientifique, t.lb_nom, i.synthese_invasibilite, t.reu, i.cd_taxref, t.cd_nom, t.cd_ref, t.rang, group2_inpn
        FROM taxon.invasibilite_faune_reu i
        INNER JOIN (
                SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu, rang, group2_inpn FROM taxref
                UNION
                SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu, rang, group2_inpn FROM taxref_local WHERE cd_nom_valide IS NULL
                )t ON lower(lb_nom) = lower(TRIM(i.nom_scientifique))
        WHERE cd_nom_verifie IS NULL
                AND group1_inpn NOT IN ('Trachéophytes', 'Bryophytes')
                AND t.cd_nom <> t.cd_ref-- 2 lignes
        ORDER BY lb_nom
        )

UPDATE taxon.invasibilite_faune_reu i
SET cd_nom_verifie = r.cd_nom
FROM r
WHERE i.nom_scientifique = r.nom_scientifique AND cd_nom_verifie IS NULL ; -- 2 MAJ

-- bilan
SELECT nom_scientifique AS nom_complet,
        CONCAT_WS('-', classe,sous_classe,infra_classe,cohorte,super_ordre,ordre,sous_ordre,infra_ordre,super_famille,famille,sous_famille,tribu) AS classification,
        id AS fk
        FROM taxon.invasibilite_faune_reu
        WHERE cd_nom_verifie IS NULL AND nom_scientifique IS NOT NULL
        ORDER BY nom_scientifique ; --> envoi à Taxref match au cas où

-- synthèse de la réconciliation taxonomique
SELECT i.nom_scientifique, t.lb_nom, t.nom_complet, t.nom_valide, t.cd_nom, t.cd_ref, t.reu
FROM taxon.invasibilite_faune_reu i
INNER JOIN (
        SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu FROM taxref
        UNION
        SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu FROM taxref_local WHERE cd_nom_valide IS NULL
        )t ON i.cd_nom_verifie = t.cd_nom
ORDER BY lb_nom;

-- Mise à jour de la table t_complement :

-- Etat des lieux préalable et après UPDATE :
SELECT statut, count(*) FROM t_complement GROUP BY statut ;
/* Avant l'UPDATE :
E$52621
I$47862
ND$495932

Après l'UPDATE :
E$52879
I$47855
ND$495681
*/
SELECT invasibilite , count(*) from t_complement group by invasibilite ;
/* Avant l'UPDATE :
E$820
ND$50999
PE$355
$544241

Après l'UPDATE :
E$820
ND$50895
PE$667
$544033
*/
SELECT DISTINCT rang FROM invasibilite_faune_reu WHERE cd_nom_verifie IS NOT NULL --> Renvoie « Forme », Espèce, Sous-espèce, que des taxons avec nom_scientifique renseigné

WITH r AS (
        SELECT t.cd_nom, t.lb_nom, i.synthese_invasibilite, t.reu
        FROM (
                SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu FROM taxref
                UNION
                SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu FROM taxref_local WHERE cd_nom_valide IS NULL
                )t
        INNER JOIN taxon.invasibilite_faune_reu i ON i.cd_nom_verifie = t.cd_nom
        WHERE group1_inpn NOT IN ('Trachéophytes', 'Bryophytes')
        ORDER BY lb_nom -- 395 lignes
        )
UPDATE taxon.t_complement tc
SET invasibilite =
        CASE
                WHEN r.synthese_invasibilite = 'Envahissant' THEN 'E'
                WHEN r.synthese_invasibilite = 'Potentiellement envahissant' THEN 'PE'
                WHEN r.synthese_invasibilite = 'Exotique à risque invasif non documenté' THEN 'ND'
        END,
        statut = 'E'-- par définition, les espèces du fichier GEIR sont exotiques
FROM r
WHERE r.cd_nom = tc.cd_nom_fk ; -- 396 MAJ

-- Mise à jour de la table taxref_local : -- on ne fait pas la même chose pour Taxref, qui doit rester la base de référence identique à celle diffusée par le MNHN sous peine de générer des confusions
WITH r AS (
        SELECT t.cd_nom, t.lb_nom, i.synthese_invasibilite, t.reu
        FROM (
                SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu FROM taxref
                UNION
                SELECT group1_inpn, cd_nom, cd_ref, lb_nom, nom_complet, nom_valide, reu FROM taxref_local WHERE cd_nom_valide IS NULL
                )t
        INNER JOIN taxon.invasibilite_faune_reu i ON i.cd_nom_verifie = t.cd_nom
        WHERE group1_inpn NOT IN ('Trachéophytes', 'Bryophytes')
        ORDER BY lb_nom
        )
UPDATE taxon.taxref_local t
SET reu = 'J'
FROM r
WHERE r.cd_nom = t.cd_nom AND r.synthese_invasibilite = 'Envahissant'; -- 0 mises à jour

-- 4.9.3 Vérifications ultimes :
--------------------

-- On vérifie qu'il n'y a pas d'incohérences , a minima entre statut et invasibilite. Les anomalies par rapport à reu devront être remontées à Taxref :
SELECT statut, invasibilite, reu, count(*)
FROM t_complement tc
LEFT JOIN (
        SELECT cd_nom, reu FROM taxref
        UNION SELECT cd_nom, reu FROM taxref
        ) t ON t.cd_nom = tc.cd_nom_fk
GROUP BY statut, invasibilite, reu
ORDER BY statut, invasibilite, reu ;

-----------------------------
-- 5. Enrichissement des noms vernaculaires
-----------------------------

--Vérification préalable de la manière dont nom_vern est renseigné dans taxref :
SELECT nom_vern
FROM taxref
WHERE reu IS NOT NULL AND nom_vern IS NOT NULL AND group2_inpn = 'Oiseaux';

-- Import du fichier taxvern_13
DROP TABLE IF EXISTS taxon.taxvern_13;
CREATE TABLE taxon.taxvern_13 (
    cd_vern TEXT,
    cd_nom TEXT,
    lb_vern TEXT,
    nom_vern_source TEXT,
    langue TEXT,
    "iso639_3" TEXT,
    pays TEXT
);
COPY taxon.taxvern_13 FROM '/tmp/TAXVERNv13_corrige_mdouchin.txt' DELIMITER E'\t' HEADER CSV; -- 57 848 lignes

-- Vérification :
SELECT * FROM taxon.taxvern_13 --57 848 lignes ;

-- Pour éviter d'intégrer des noms en doublon, on va éclater puis agglomérer les noms français issus de Taxvern (langue = français et créole) et de Taxref.
WITH noms_vern_taxref_et_taxvern AS (
                SELECT 1 AS ordre, cd_nom::INTEGER, lb_vern AS nom_vern_orig, -- le champ ordre permet plus bas de prendre en premier le nom créole
                REGEXP_SPLIT_TO_TABLE(
                                lb_vern,
                                ', '
                        ) AS nom_vern_eclate
                FROM taxon.taxvern_13
                WHERE iso639_3 IN ('rcf') -- rcf = Créole réunionnais. fra = français. TODO : à adapter pour une autre région.

                UNION
                SELECT 2 AS ordre, cd_nom, nom_vern AS nom_vern_orig,
                REGEXP_SPLIT_TO_TABLE(
                                nom_vern,
                                ', '
                        ) AS nom_vern_eclate
                FROM taxon.taxref
                WHERE nom_vern IS NOT NULL

                UNION
                SELECT 3 AS ordre, cd_nom::INTEGER, lb_vern AS nom_vern_orig,
                REGEXP_SPLIT_TO_TABLE(
                                lb_vern,
                                ', '
                        ) AS nom_vern_eclate
                FROM taxon.taxvern_13
                WHERE iso639_3 IN ('rcf', 'fra') -- fra = français
                ORDER BY ordre, cd_nom, nom_vern_orig -- 43 268 lignes

        ), complement_taxvern_13 AS (
                SELECT t.cd_ref, t.cd_nom, string_agg(DISTINCT TRIM(nom_vern_eclate), ', ') AS nom_vern_new
                FROM taxref t
                INNER JOIN noms_vern_taxref_et_taxvern s ON s.cd_nom = t.cd_nom -- 30 423 lignes
                GROUP BY t.cd_ref, t.cd_nom

        ), complement_taxvern_13_des_synonymes AS ( -- on est obligé de procéder en deux temps car du fait des mises en synonymies successives, on peut avoir pour un taxon et son synonyme des statuts différents !
                SELECT t.cd_ref, t.cd_nom, string_agg(DISTINCT TRIM(nom_vern_eclate), ', ') AS nom_vern_new
                FROM taxref t
                INNER JOIN noms_vern_taxref_et_taxvern s ON (t.cd_ref = s.cd_nom AND s.cd_nom <> t.cd_nom)
                GROUP BY t.cd_ref, t.cd_nom -- 111 890  lignes

        ), synthese_taxvern_13 AS (
                SELECT * FROM complement_taxvern_13
                UNION
                SELECT * FROM complement_taxvern_13_des_synonymes
                ORDER BY cd_ref
                )

UPDATE taxref t SET nom_vern = synthese_taxvern_13.nom_vern_new
FROM synthese_taxvern_13
WHERE t.cd_nom = synthese_taxvern_13.cd_nom
; -- 139 221 lignes

-----------------------------
-- 6. Vérification :
-----------------------------
-- On vérifie à la fin que chaque obs a bien une correspondance dans taxref_valide
SELECT cle_obs, o.cd_nom, o.cd_ref, o.nom_cite, o.jdd_code, o.validite_niveau
FROM occtax.observation o
LEFT JOIN (
SELECT cd_nom, cd_ref FROM taxon.taxref UNION SELECT cd_nom, cd_ref FROM taxref_local
) t USING (cd_nom)
WHERE t.cd_nom IS NULL ; --> 0 ligne, pas de pb !


-----------------------------
-- 7. Mise à jour de la table critere_validation
-----------------------------
/* a) Dans le fichier source : remplacer à la main les cd_ref calculés pour les lignes comportant une remarque expliquant comment les générer (du type :
WHERE famille IN ('Cheloniidae', 'Dermochelyidae') AND cd_ref NOT IN (77330, 77338, 77347, 77360, 77367) AND rang IN ('ES', 'SSES').
15 critères sont concernés : code_critere IN ('tortues_marines_1', 'tortues_marines_2', 'cetaces_1', 'cetaces_2', 'chiropteres_21', 'chiropteres_22', 'reptiles_amphibiens_1', 'reptiles_amphibiens_2', 'oiseaux_5', 'mammiferes_terrestres_2_non_réalisable', 'mammiferes_terrestres_1_douteux1', 'mammiferes_terrestres_6_probable2', 'mammiferes_terrestres_5_probable1', 'poissons_crustaces_eau_douce_2.1', 'poissons_crustaces_eau_douce_2.2')
 )
*/

-- On peut s'aider de ce script par exemple :
SELECT array_agg(DISTINCT cd_nom ORDER BY cd_nom) AS liste_cd_nom,
'[' || string_agg(DISTINCT cd_ref::TEXT, ', ' ORDER BY cd_ref::TEXT) || ']' AS liste_cd_ref,
string_agg(DISTINCT nom_valide, ', ' ORDER BY nom_valide) AS liste_noms_valides,
count(DISTINCT cd_ref) AS nb_taxons
FROM (SELECT cd_nom::INTEGER, cd_ref::INTEGER, nom_valide, famille, rang, ordre, group2_inpn, reu, habitat FROM taxon.taxref UNION SELECT cd_nom, cd_ref, nom_valide, famille, rang, ordre, group2_inpn, reu, habitat FROM taxref_local WHERE cd_nom_valide IS NULL) r
WHERE cd_ref NOT IN (562828, 680116, 418785, 418787, 535062, 432658, 418786, -67, 418790, 528800, 418788, 432662, 418789, 538982, 418791, 528798, 432665, -95, 595657, 595346, 418793, 418771, 423148, 418772, 528790, 426003, 418766, 418765, 418767, 419256, 69346, 423547, 528788, 535102, 419269, 200266, 528794, 562550, 67208, 67246, 67058, 698292, 418774, 533446, 418775, 586405, 418777, 424994, 67606, 418779, 418903, 419271, 424268, 439162, 418783, 418784, 424606, 418773, -8, 424726, 419260, 424810, 418900, 558379, 551353, 888347, 69772, 908451, 425955, 425957, 425809, 425199, 418898, 162673, 784805, 68827, 68823, 425982, 425983, 67804, 418768, 560582, 559719)
AND rang IN ('ES', 'SSES')
AND habitat IN ('2','4')
AND (lower(famille) IN ('atyidae', 'palaemonidae', 'sesarmidae', 'varunidae', 'portunidae') OR group2_inpn='Poissons');

-- b) Puis on réimporte complétement la table des critères de validation : voir script spécifique associé au protocole de validation


-- c) On vérifie qu'il n'y a pas de cd_nom orphelins dans taxref_12
SELECT r.cd_nom, array_agg(r.code_critere) AS criteres
FROM (SELECT code_critere, unnest(cd_nom)::INTEGER cd_nom FROM critere_validation) r
LEFT JOIN taxon.taxref t ON t.cd_nom::INTEGER=r.cd_nom
WHERE t.cd_nom IS NULL AND r.cd_nom>0
GROUP BY r.cd_nom
ORDER BY r.cd_nom ; -- 0 ligne --> OK !


-- d) Idem dans Taxref_local (on ne prend que les taxons dont cd_nom_valide est NULL car les autres ont été intégrés à Taxref depuis)
SELECT r.cd_nom, array_agg(r.code_critere) AS criteres
FROM (SELECT code_critere, unnest(cd_nom)::INTEGER cd_nom FROM critere_validation) r
LEFT JOIN taxon.taxref_local t ON t.cd_nom::INTEGER=r.cd_nom
WHERE (t.cd_nom IS NULL OR t.cd_nom_valide IS NOT NULL) AND r.cd_nom<0
GROUP BY r.cd_nom
ORDER BY r.cd_nom ; -- 0 ligne --> OK !


-- e) On exporte les colonnes sur la liste de cd_ref et de noms_valides à jour pour mettre à jour le fichier source au format .ods
SELECT c.code_critere, array_agg(DISTINCT t.cd_ref) AS liste_cd_ref, array_agg(DISTINCT t.nom_valide ORDER BY t.nom_valide) AS liste_nom_valide, count(DISTINCT cd_ref) AS nb_taxons
FROM (SELECT code_critere, unnest(cd_nom)::INTEGER cd_nom FROM critere_validation) c
LEFT JOIN (SELECT cd_nom::INTEGER, cd_ref::INTEGER, nom_valide FROM taxon.taxref
                        UNION SELECT cd_nom, cd_ref, nom_valide FROM taxon.taxref_local WHERE cd_nom_valide IS NULL) t USING (cd_nom)
GROUP BY c.code_critere
ORDER BY c.code_critere;
-- on fait la MAJ "à la main"


-- f) Si besoin, on met à jour "à la main" les différentes vues appelées par la table critere_valideation avec les nouveaux cd_nom
-- Sans objet pour la v13


-----------------------------
-- 8. Mise à jour de la table critere_sensibilite
-- TODO : non fait le 28/07/2020 (vérif à faire sur les insectes)
-----------------------------

-- a) On vérifie qu'il n'y a pas de cd_nom orphelins dans le nouveau Taxref
SELECT r.cd_nom
FROM (SELECT unnest(cd_nom)::INTEGER cd_nom FROM critere_sensibilite) r
LEFT JOIN taxon.taxref t ON t.cd_nom::INTEGER=r.cd_nom
WHERE t.cd_nom IS NULL AND r.cd_nom>0
GROUP BY r.cd_nom
ORDER BY r.cd_nom ; -- 2 lignes : cd_nom IN (713713, 713716)

SELECT * FROM taxref_12 WHERE cd_nom IN (713713, 713716)
/*
Apocryptophagus Ashmead, 1904 | cd_nom = 713716
Philocaenus Grandi, 1952 | cd_nom = 713713
TODO : revoir avec PVBMT si gênant ou pas, et si d'autres taxons sont à ajouter (postulat de départ : la quasi intégralité des taxons indigènes est potentiellement sensible)
*/

-- b) Idem dans Taxref_local (on ne prend que les taxons dont cd_nom_valide est NULL car les autres ont été intégrés à Taxref depuis)
SELECT r.cd_nom
FROM (SELECT unnest(cd_nom)::INTEGER cd_nom FROM critere_sensibilite) r
LEFT JOIN taxon.taxref_local t ON t.cd_nom::INTEGER=r.cd_nom
WHERE (t.cd_nom IS NULL OR t.cd_nom_valide IS NOT NULL) AND r.cd_nom<0
GROUP BY r.cd_nom
ORDER BY r.cd_nom ; -- 0 ligne --> OK !

-- c) Si besoin, on modifie dans la table source, puis on réimporte --> voir script spécifique


-- d) On fait la mise à jour à la main du fichier source au format ods

-----------------------------
-- 9. Export dans une table à plat d'une synthèse de taxref 13
-----------------------------

-- 9.1 Liste des espèces et sous-espèces de Taxref (sans synonymes), tous statuts reu confondus
-----------------------------
SELECT count(*) FROM taxref t
WHERE cd_nom = cd_ref AND (t.rang = ANY (ARRAY['ES'::text, 'SSES'::text]))
-- AND t.reu IS NOT NULL AND (t.reu <> ALL (ARRAY['Q'::character varying::text, 'A'::character varying::text]))
-- 198 693 lignes attendues et 13 148 si on se limite aux taxons présents à La Réunion selon Taxref

COPY (
        WITH syn AS (
                         SELECT t_1.cd_ref,
                                string_agg(DISTINCT t_1.lb_nom, ', '::text ORDER BY t_1.lb_nom) AS synonymes
                           FROM taxon.taxref t_1
                          WHERE TRUE
                                        -- AND t_1.reu IS NOT NULL AND (t_1.reu <> ALL (ARRAY['Q'::character varying::text, 'A'::character varying::text]))
                                        AND t_1.cd_nom <> t_1.cd_ref
                                        AND (t_1.rang = ANY (ARRAY['ES'::text, 'SSES'::text]))
                                        GROUP BY t_1.cd_ref
                          )
        SELECT
                t.group2_inpn,
                t.classe,
                t.ordre,
                t.famille,
                t.cd_nom,
                t.cd_ref,
                        CASE t.rang
                                WHEN 'ES'::text THEN 'Espèce'::text
                                WHEN 'SSES'::text THEN 'Sous-espèce'::text
                                ELSE NULL::text
                        END AS rang,
                t.lb_nom,
                t.nom_complet,
                t.nom_valide,
                t.nom_vern,
                t.nom_vern_eng,
                syn.synonymes AS noms_synonymes,
                (SELECT CONCAT (code, ' - ', valeur) FROM t_nomenclature n
                WHERE n.champ = 'statut_taxref' AND n.code = t.reu) AS indigenat_reunion,
                t.url
           FROM taxon.taxref t
           LEFT JOIN syn USING (cd_ref)

          WHERE TRUE
                        --AND t.reu IS NOT NULL AND (t.reu <> ALL (ARRAY['Q'::character varying::text, 'A'::character varying::text]))
                        AND t.cd_nom = t.cd_ref
                        AND (t.rang = ANY (ARRAY['ES'::text, 'SSES'::text]))
          GROUP BY t.group1_inpn, t.group2_inpn, t.classe, t.ordre, t.famille, t.cd_nom, t.cd_ref, t.rang, t.lb_nom, t.nom_complet, t.nom_valide, t.nom_vern, t.nom_vern_eng, syn.synonymes, t.reu, t.url
          ORDER BY t.group1_inpn, t.group2_inpn, t.ordre, t.famille, t.nom_complet
 )
  TO '/tmp/export_taxref_13_noms_valides.csv' HEADER CSV DELIMITER '$';

-- 9.2 Export de Taxref enrichi Réunion
-----------------------------
 -- Export de TAXREF permettant de lister les noms valides et les synonymes des taxons de rang espèces (ES) ou sous-espèces (SSES) présents à La Réunion (ou y ayant été présents autrefois), et de préciser leurs statuts. Les taxons faisant l’objet d’observations à La Réunion mais pas encore intégrés à Taxref sont également intégrés.
 COPY (

 WITH stats AS (
                SELECT cd_ref,
                                max(COALESCE(date_fin, date_debut)) AS date_derniere_obs,
                                count(cle_obs) AS nb_obs
                FROM observation
                WHERE validite_niveau IN ('1', '2') AND statut_observation = 'Pr'
                GROUP BY cd_ref

                ),stats_completes AS (
                SELECT cd_ref,
                                max(COALESCE(date_fin, date_debut)) AS date_derniere_obs,
                                count(cle_obs) AS nb_obs
                FROM observation
                WHERE statut_observation = 'Pr' -- on prend toutes les données, même non validées
                GROUP BY cd_ref

        ),t AS (
                SELECT group1_inpn, group2_inpn, phylum, classe, ordre, famille, cd_nom, cd_ref, rang, lb_nom, nom_complet, nom_valide, nom_vern, nom_vern_eng, reu, habitat, url
                FROM taxon.taxref
                WHERE
                        ((reu IS NOT NULL AND reu NOT IN ('Q', 'A')) OR cd_ref IN (SELECT cd_ref FROM stats))
                        AND cd_nom = cd_ref AND rang IN ('ES', 'SSES')
                UNION
                SELECT group1_inpn, group2_inpn, phylum, classe, ordre, famille, cd_nom, cd_ref, rang, lb_nom, nom_complet, nom_valide, nom_vern, nom_vern_eng, reu, habitat, url
                FROM taxon.taxref_local
                WHERE
                        ((reu IS NOT NULL AND reu NOT IN ('Q', 'A')) OR cd_ref IN (SELECT cd_ref FROM stats))
                        AND cd_nom = cd_ref AND rang IN ('ES', 'SSES')  AND cd_nom_valide IS NULL

        ), syn AS (
         SELECT cd_ref,
                string_agg(DISTINCT lb_nom, ', '::text ORDER BY lb_nom) AS synonymes
          FROM taxon.taxref
          WHERE reu IS NOT NULL AND (reu <> ALL (ARRAY['Q'::character varying::text, 'A'::character varying::text])) AND cd_nom <> cd_ref AND (rang = ANY (ARRAY['ES'::text, 'SSES'::text]))
          GROUP BY cd_ref

        )

SELECT t.group1_inpn,
    t.group2_inpn,
    t.classe,
    t.ordre,
    t.famille,
    t.cd_nom,
    t.cd_ref,
        CASE t.rang
                WHEN 'ES'::text THEN 'Espèce'::text
                WHEN 'SSES'::text THEN 'Sous-espèce'::text
                ELSE NULL::text
        END AS rang,
    t.lb_nom,
    t.nom_complet,
    t.nom_valide,
    t.nom_vern,
    t.nom_vern_eng,
    syn.synonymes AS noms_synonymes,
        (SELECT CONCAT (code, ' - ', valeur) FROM t_nomenclature n
                WHERE n.champ = 'statut_taxref' AND n.code = t.reu) AS indigenat_reunion,
    (SELECT valeur FROM t_nomenclature n
                WHERE n.champ = 'statut' AND n.code = tc.statut) AS indigenat_reunion_simplifie,
    (SELECT valeur FROM t_nomenclature n
                WHERE n.champ = 'invasibilite' AND n.code = tc.invasibilite)  AS invasibilite,
        (SELECT CONCAT (code, ' - ', valeur) FROM t_nomenclature n
                WHERE n.champ = 'habitat' AND n.code = t.habitat)  AS invasibilite,
        string_agg(DISTINCT
                                (SELECT CONCAT(code, ' - ', valeur) FROM t_nomenclature n
                                WHERE n.champ = 'menace' AND n.code = tc.menace
                                ),
                                ' - '::text
                        ) AS liste_rouge_uicn,
           CASE
                        WHEN tc.protection IS NOT NULL THEN string_agg(DISTINCT p.full_citation, ' | '::text)
                        ELSE NULL
                END AS protection_nationale,
        /* On retire momentanément ce statut, car il est incomplètement rempli dans la base statuts de Taxref 13. En attente des correctifs à apporter par le MNHN pour l'afficher à nouveau
        cites.label_statut AS cites,
        */
        pna_pdc.doc_gestion || ' (statut : ' || pna_pdc.statut || ')' AS pna_pdc,
        string_agg(DISTINCT eee.full_citation, ' | ') AS regl_eee,
    --string_agg(DISTINCT (label_statut, ' | '::text) AS reglementation_autre, -- TODO : revoir ce point si on veut toutes les réglementations autres (les lister d'abord)
        COALESCE(stats.nb_obs, 0) AS nb_obs_validees,
        COALESCE(stats_completes.nb_obs, 0) AS nb_obs_toutes, -- utile pour l'export à destination des têtes de réseau, peut être retiré pour l'export grand public
        stats.date_derniere_obs,
    s.libelle || ' (niveau de sensibilité : ' ||
        CASE s.niveau
            WHEN 'm02' THEN 'floutage à la maille de 2km'
            WHEN '2' THEN 'floutage à la maille de 10 km'
            ELSE s.niveau
        END || ')' AS donnees_sensibles,
        CONCAT('https://carte.borbonica.re/?bbox=290232.410465,7630908.369317,379767.589535,7699091.630683&taxons_bdd=1&cd_nom[0]=',
                           t.cd_ref,
                           '&cd_ref=',
                           t.cd_ref,
                           '&') AS carte_borbonica,
    t.url AS fiche_inpn
FROM t
LEFT JOIN syn USING (cd_ref)
LEFT JOIN taxon.t_complement tc ON tc.cd_nom_fk::INTEGER = t.cd_ref
LEFT JOIN taxon.pna_pdc ON pna_pdc.cd_ref = t.cd_ref
LEFT JOIN (SELECT unnest(cd_nom) AS cd_nom, niveau, libelle FROM occtax.critere_sensibilite s
                   ) s ON s.cd_nom = t.cd_ref
LEFT JOIN (
        SELECT * FROM taxon.statuts_especes_13
        WHERE lb_adm_tr IN ('France', 'Réunion') AND lb_type_statut ILIKE 'Protection%'
                  ) p ON t.cd_ref = p.cd_ref

LEFT JOIN (
        SELECT cd_ref, code_statut, full_citation, label_statut FROM taxon.statuts_especes_13
        WHERE code_statut IN ('Bubul1', 'Bulbul2', 'Bulbul3', 'Bulbul4', 'Bulbul5', 'Bulbul6', 'Bulbul9', 'corbasi1', 'phelsuma1', 'phelsuma2', 'phelsuma3', 'phelsuma4', 'phelsuma5', 'REUEEA', 'REUEEI', 'REUEJ', 'agri1', 'agri2')

        UNION -- Arrêté perruche, qui à terme sera intégré à la base connaissances de Taxref
        SELECT (SELECT cd_ref FROM taxref WHERE lb_nom = 'Psittacula krameri' LIMIT 1),
                'Perruche' AS code_statut,
                'Arrêté N°2020-2490/SG/DRECV du 21 juillet 2020 portant organisation de la destruction des spécimens de la Perruche à collier Psittacula krameri présents dans le milieu naturel, au titre de l’article L411.8 du code de l’environnement, sur le territoire de La Réunion' AS full_citation,
                'Arrêté de destruction des perruches en milieu naturel à La Réunion' AS label_statut

        UNION -- oubli d'un taxon dans la base statut associée à Taxref pour REUEJ (arrêté flore EEE niveau 2)
        SELECT 81831 AS cd_ref, -- Alternanthera philoxeroides (Mart.) Griseb., 1879
                'REUEJ' AS code_statut,
                'Arrêté du 1er avril 2019 relatif à la prévention de l''introduction et de la propagation des espèces végétales exotiques envahissantes sur le territoire de La Réunion - Interdiction de toutes activités portant sur des spécimens vivants. [JORF n°0086 du 11 avril 2019]' AS full_citation,
                'Prévention de l''introduction et de la propagation des espèces végétales exotiques envahissantes sur le territoire de La Réunion : Annexe 1' AS label_statut
                --Vérification également faite dans Taxref_local pour les taxons qui ne sont pas non plus dans Taxref (aucun n'est pour le moment signalé dans Borbonica)

        -- toutes les espèces non citées par ces arrêtés, et donc non autorisées
        UNION -- Arrêté faune de niveau 1
        SELECT t.cd_ref,
                'REUnoEEEA' AS code_statut,
                'Arrêté du 9 février 2018 relatif à la prévention de l''introduction et de la propagation des espèces animales exotiques envahissantes sur le territoire de La Réunion' AS full_citation,
                'Prévention de l''introduction et de la propagation des espèces animales exotiques envahissantes sur le territoire de la Réunion : Annexe 1' AS label_statut
        FROM t
        LEFT JOIN (SELECT cd_ref FROM taxon.statuts_especes_13 WHERE code_statut IN ('REUnoEEEA')) prov ON prov.cd_ref = t.cd_ref
        WHERE prov.cd_ref IS NULL AND t.phylum = 'Chordata' AND t.ordre = 'Decapoda'
                        AND t.cd_ref NOT IN (2489, 528686, 432662, 3741, 69772, 528760, 2694, 432594, 3364, 432689, 528806) -- on repêche des oublis dans la base statuts associée à Taxref 13. Vérification également faite dans Taxref_local pour les taxons qui ne sont pas non plus dans Taxref (aucun n'est pour le moment signalé dans Borbonica)

        UNION -- Arrêté flore de niveau 1
        SELECT t.cd_ref,
                'REUnoEEEV' AS code_statut,
                'Arrêté du 9 février 2018 relatif à la prévention de l''introduction et de la propagation des espèces végétales exotiques envahissantes sur le territoire de La Réunion' AS full_citation,
                'Prévention de l''introduction et de la propagation des espèces végétales exotiques envahissantes sur le territoire de la Réunion : Annexe 1' AS label_statut
        FROM t
        LEFT JOIN (SELECT cd_ref FROM taxon.statuts_especes_13 WHERE code_statut IN ('REUnoEEEV')) prov ON prov.cd_ref = t.cd_ref
        WHERE prov.cd_ref IS NULL AND group1_inpn = 'Trachéophytes'
                        AND t.cd_ref NOT IN (709390, 705908, 94066, 103175, 762632) -- on repêche des oublis dans la base statuts associée à Taxref 13. Vérification également faite dans Taxref_local pour les taxons qui ne sont pas non plus dans Taxref (aucun n'est pour le moment signalé dans Borbonica)
                        AND t.cd_ref NOT IN (SELECT cd_ref FROM statuts_especes_13 WHERE code_statut = 'REUEJ') -- On ne liste que les espèces qui ne sont pas déjà dans l'arrêté de niveau 2 (vu avec Isabelle Bracco par mail du 31/07/2020, ce sera à faire de la même manière pour la faune quand l'arrêté faune de niveau 2 sera également signé)

        ) eee ON t.cd_ref = eee.cd_ref
LEFT JOIN (
        SELECT * FROM taxon.statuts_especes_13 WHERE label_statut ILIKE '%washington%'
                  ) cites ON t.cd_ref = cites.cd_nom
LEFT JOIN stats ON stats.cd_ref = t.cd_ref
LEFT JOIN stats_completes ON stats_completes.cd_ref = t.cd_ref
   /*
LEFT JOIN ( SELECT cd_protection, article, intitule, arrete, url_inpn, cd_doc, url, date_arrete, type
           FROM taxon.protection_especes_types_11
          WHERE protection_especes_types_11.type <> 'Protection'::text AND (protection_especes_types_11.intitule ~~* '%reunion%'::text OR protection_especes_types_11.intitule ~~* '%réunion%'::text OR protection_especes_types_11.cd_protection ~~* '%974%'::text)) a ON e.cd_protection = a.cd_protection*/

GROUP BY t.group1_inpn, t.group2_inpn, t.classe, t.ordre, t.famille, t.cd_nom, t.cd_ref, t.rang, t.lb_nom, t.nom_complet, t.nom_valide, t.nom_vern, t.nom_vern_eng, syn.synonymes, t.reu, t.habitat, tc.invasibilite, tc.statut, pna_pdc.statut, pna_pdc.doc_gestion, s.libelle, s.niveau, t.url, tc.protection, cites.label_statut, stats.nb_obs, stats.date_derniere_obs, stats_completes.nb_obs
ORDER BY t.group1_inpn, t.group2_inpn, t.ordre, t.famille, t.nom_complet
)
  TO '/tmp/export_taxref_13_noms_valides_reu.csv' HEADER CSV DELIMITER '$';


-- 10. Rafraîchissement des vues matérialisées
-----------------------------
REFRESH MATERIALIZED VIEW taxref_valide;
REFRESH MATERIALIZED VIEW taxref_consolide;
REFRESH MATERIALIZED VIEW taxref_consolide_non_filtre;
SET default_TEXT_search_config TO french_TEXT_search;
REFRESH MATERIALIZED VIEW taxref_fts;
REFRESH MATERIALIZED VIEW occtax.vm_observation ;


-- 11. Nettoyage
-----------------------------
--Supprimer les tables inutiles

-- Terminé en prod sur Borbonica par VLT le 12/08/2020 (sauf les TODO à revoir)


DROP TABLE taxon.taxref_13 ; --(désormais intégré à taxon.taxref)
DROP TABLE taxon.taxvern_13 ; --noms réintégrés dans nom_vern de taxref
DROP TABLE taxon.taxvern_12 ; --obsolète
DROP TABLE taxon.taxref_changes_13 ; --(désormais intégré à taxon.taxref_changes)
DROP TABLE taxon.taxref_changes_12 ;
DROP TABLE taxon.taxref_changes ;
DROP TABLE IF EXISTS taxon.protections ;
DROP TABLE IF EXISTS taxon.menaces ;
DROP TABLE taxon.invasibilite_flore_reu ;
DROP TABLE taxon.invasibilite_faune_reu ;

