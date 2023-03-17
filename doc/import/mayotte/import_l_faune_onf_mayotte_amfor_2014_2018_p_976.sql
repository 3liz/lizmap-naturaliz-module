
BEGIN;
SET search_path TO taxon, occtax, gestion, sig, fdw, divers, public;


SELECT Setval('divers.suivi_imports_id_seq1', (SELECT max(id) FROM divers.suivi_imports) );


-- Cadre: https://inpn.mnhn.fr/espece/cadre/25856
-- JDD: https://inpn.mnhn.fr/espece/jeudonnees/40895

INSERT INTO divers.suivi_imports
 (
        nom_jdd,
        description_detaillee,
        date_reception,
        date_import_dev,
        date_import_prod,
        nb_donnees,
        importateur_initiales,
        commentaire,
        jdd_id
)
SELECT
        'Données FAUNE des inventaires préalables aux aménagements des forêts domaniales et départementales de Mayotte' AS nom_jdd, --> S'il n'y a qu'un JDD prendre le jdd_code pour "nom_jdd", sinon, donner un nom au lot
        'La liste d''espèces, mesures et informations relevées sont associées à un point géolocalisé qui correspond au centre de la placette (voir l''onglet généalogie). Aussi, lors de l''acheminement entre placettes, des relevés supplémentaires relatifs à des espèces de faune ou de flore peuvent être géoréférencés. ' AS decription_detaillee, --> S'il n'y a qu'un JDD prendre le jdd_description pour "nom_jdd", sinon, décrire lot
        '2018-12-01' AS  date_reception,
        NULL AS date_import_dev,
        NULL AS date_import_prod,
        '420' AS nb_donnees, -- Nombre total de données dans le fichier source fourni par le producteur
        'AH' AS importateur_initiales, -- 'VLT' AS importateur_initiales,
        '' AS commentaire,
        ARRAY['T40895'] -- null AS jdd_id
ON CONFLICT DO NOTHING
;


------------------------------
-- PARTIE I : Import des données source
------------------------------

-- organismes
-- todo vérifier

DROP TABLE IF EXISTS fdw.l_faune_onf_2014_2018_organismes;
CREATE TABLE fdw.l_faune_onf_2014_2018_organismes (
    id_organisme integer,
    nom_organisme text,
    abreviation_organisme text
);

-- Ouvrir la console psql (shell PostgreSQL)
-- On remplace COPY par \COPY : cela permet de donner un chemin de fichier sur sa machine
-- au lieu d'avoir à envoyer d'abord le fichier sur le serveur dans /tmp/
-- une fois dans psql, on peut aller dans le répertoire via \cd ou bien donner le chemin absolu du fichier
\cd /home/mdouchin/Documents/3liz/DEAL_Mayotte/echange/Pltf_SINP976_1/TABLES/RefOrganisme
\COPY fdw.l_faune_onf_2014_2018_organismes FROM 'sinp976_organismes.csv' HEADER CSV DELIMITER ',' ;
SELECT * FROM fdw.l_faune_onf_2014_2018_organismes;

-- ajout manuel de la DAAF qui était manquante dans le fichier CSV
INSERT INTO fdw.l_faune_onf_2014_2018_organismes
VALUES (16, 'Direction de l''Alimentation, de l''Agriculture et de la Forêt de Mayotte', 'DAAF')
;

-- Insérer les organismes dans la table occtax.organisme
INSERT INTO occtax.organisme
(nom_organisme, sigle)
SELECT
    nom_organisme,
    abreviation_organisme
FROM fdw.l_faune_onf_2014_2018_organismes
ON CONFLICT (nom_organisme) DO NOTHING
;


-- Bien vérifier qu'on a aussi les organismes issus des observateurs
-- voir plus loin


------------------------------------
-- 1.2 - personnes -> observateurs

-- ATTENTION, bien vérifier avant que la liste des observateurs décrits dans la table des observations
-- est bien dans le fichier CSV des acteurs sinp976_autorites.csv

DROP TABLE IF EXISTS fdw.l_faune_onf_2014_2018_acteurs;
CREATE TABLE fdw.l_faune_onf_2014_2018_acteurs (
    id_autorite text,
    nom_auteur text,
    prenom_auteur text,
    nom_agrege text,
    abreviation_autorite text,
    email text,
    id_organisme text,
    nom_organisme text,
    abreviation_organisme text
);
\cd /home/mdouchin/Documents/3liz/DEAL_Mayotte/echange/Pltf_SINP976_1/TABLES/RefOrganisme
\COPY fdw.l_faune_onf_2014_2018_acteurs FROM 'sinp976_autorites.csv' HEADER CSV DELIMITER ';' ;

SELECT * FROM fdw.l_faune_onf_2014_2018_acteurs;

-- Ajout dans la table occtax.personne

-- on ajoute d'abord une contrainte d'unicité pour éviter des doublons si réimport
ALTER TABLE occtax.personne ADD UNIQUE (identite, id_organisme);
-- la contrainte créée s'appelle personne_identite_id_organisme_key

INSERT INTO occtax.personne
(identite, prenom, nom, mail, id_organisme, anonymiser)
SELECT
    trim(concat(upper(trim(nom_auteur)), ' ', initcap(trim(prenom_auteur)))) AS identite,
    initcap(trim(prenom_auteur)) AS prenom,
    upper(trim(nom_auteur)) AS nom,
    email AS mail,
    o.id_organisme,
    False AS anonymiser
FROM fdw.l_faune_onf_2014_2018_acteurs AS a
LEFT JOIN occtax.organisme AS o
    ON o.sigle = a.abreviation_organisme
ON CONFLICT ON CONSTRAINT personne_identite_id_organisme_key DO NOTHING
;

-- Il est normal d'avoir plusieurs lignes dans la table personne avec la même identité.
-- On a autant de lignes que de combinaison identité / organisme


-- Il faut aussi ajouter les observateurs issus d'un découpage du champ _observateu
-- NB Cela crée un complexité inutile. Mieux vaudrait avoir toutes les données EXHAUSTIVES
-- dans les CSV acteurs et organismes
-- Table des observateurs
CREATE TABLE fdw.l_faune_onf_2014_2018_observateurs (
    cpt integer,
    observateurs text,
    obs1 text,
    orga1 text,
    st1 text,
    obs2 text,
    orga2 text,
    st2 text,
    obs3 text,
    orga3 text,
    st3 text,
    obs4 text,
    orga4 text,
    st4 text
);
-- import du fichier
-- psql
\cd /home/mdouchin/Documents/3liz/DEAL_Mayotte/echange/Pltf_SINP976_1/TABLES/RefOrganisme
\COPY fdw.l_faune_onf_2014_2018_observateurs FROM 'TC_observateursFauneONF.csv' HEADER CSV DELIMITER ';' ;
SELECT count(*) FROM fdw.l_faune_onf_2014_2018_observateurs;
-- 79: normalement le même nombre que le nombre de valeurs distinctes de _observateu de la table des observations (car issus d'un extraction puis split)

-- Il faut corriger à la main cette table, car le sigle SRF correspond en fait à CDM/DRTM/SRF
-- Correction ici et dans la table des observations
-- Manuel, par lecture des lignes
UPDATE fdw.l_faune_onf_2014_2018_observateurs
SET (observateurs, orga1, orga2, orga3, orga4)
= (replace(observateurs, 'SRF', 'CDM/DRTM/SRF'), replace(orga1, 'SRF', 'CDM/DRTM/SRF'), replace(orga2, 'SRF', 'CDM/DRTM/SRF'), replace(orga3, 'SRF', 'CDM/DRTM/SRF'), replace(orga4, 'SRF', 'CDM/DRTM/SRF'))
;
-- verification
SELECT observateurs, orga1, orga2, orga3, orga4
FROM fdw.l_faune_onf_2014_2018_observateurs
WHERE observateurs LIKE '%SRF%';

-- ATTENTION, il faudra aussi faire ce SRF -> CDM/DRTM/SRF
-- dans la table des observations importées depuis le CSV


-- Rajout des personnes manquantes dans la table personne
-- Pour les trouver tous, mega requête
SELECT DISTINCT
obs1, orga1,
(SELECT id_organisme FROM occtax.organisme WHERE sigle = orga1)
--, p.identite
FROM fdw.l_faune_onf_2014_2018_observateurs AS o
LEFT JOIN occtax.personne AS p
    ON concat(p.prenom, ' ', p.nom) = obs1
WHERE True
AND obs1 IS NOT NULL
-- si pas de personne, il faut l'ajouter
AND identite IS NULL
UNION
SELECT DISTINCT
obs2, orga2,
(SELECT id_organisme FROM occtax.organisme WHERE sigle = orga2)
--, p.identite
FROM fdw.l_faune_onf_2014_2018_observateurs AS o
LEFT JOIN occtax.personne AS p
    ON concat(p.prenom, ' ', p.nom) = obs2
WHERE True
AND obs2 IS NOT NULL
-- si pas de personne, il faut l'ajouter
AND identite IS NULL
UNION
SELECT DISTINCT
obs3, orga3,
(SELECT id_organisme FROM occtax.organisme WHERE sigle = orga3)
--, p.identite
FROM fdw.l_faune_onf_2014_2018_observateurs AS o
LEFT JOIN occtax.personne AS p
    ON concat(p.prenom, ' ', p.nom) = obs3
WHERE True
AND obs3 IS NOT NULL
-- si pas de personne, il faut l'ajouter
AND identite IS NULL
UNION
SELECT DISTINCT
obs4, orga4,
(SELECT id_organisme FROM occtax.organisme WHERE sigle = orga4)
--, p.identite
FROM fdw.l_faune_onf_2014_2018_observateurs AS o
LEFT JOIN occtax.personne AS p
    ON concat(p.prenom, ' ', p.nom) = obs4
WHERE True
AND obs4 IS NOT NULL
-- si pas de personne, il faut l'ajouter
AND identite IS NULL
;

-- qui renvoit
-- Houbiate ATTOUMANE  ONF 3
-- Hamada Ali  CDM/DRTM/SRF    5
-- Chanrane XXX    CDM/DRTM/SRF    5
-- Oukacha RADJABOU    ONF 3

-- ON insert manuellement car sinon il faudrait découper le nom/prénom pour le séparer -> plus rapide à la mano dans ce cas
-- IL FAUDRA REMPLACE Ali par ALI et XXX par INCONNU mais dans un 2ème temps,
INSERT INTO occtax.personne
(identite, prenom, nom, mail, id_organisme, anonymiser)
VALUES
('RADJABOU Oukacha', 'Oukacha', 'RADJABOU', NULL, 3, False),
('XXX Chanrane', 'Chanrane', 'XXX', NULL, 5, False),
('Ali Hamada', 'Hamada', 'Ali', NULL, 5, False),
('ATTOUMANE Houbiate', 'Houbiate', 'ATTOUMANE', NULL, 3, False)
ON CONFLICT ON CONSTRAINT personne_identite_id_organisme_key DO NOTHING
;



------------------------------------
-- 2 Métadonnées -> cadre et JDD

-- On remplit d'abord les informations sur le CADRE et le JDD sur la plateforme nationale
-- les métadonnées sont à saisir sur https://inpn.mnhn.fr/mtd/
-- Cadre: https://inpn.mnhn.fr/espece/cadre/25856
-- JDD: https://inpn.mnhn.fr/espece/jeudonnees/40895
-- Remplissage des tables occtax.cadre et occtax.jdd contenant les métadonnées


--Pour rappel :
------------------------------
-- métadonnées pour les tables occtax.cadre et occtax.jdd
------------------------------

-- 2.1 cadre
-- s'il s'agit d'un nouveau cadre de saisie de données
-- Il est recommandé au préalable d'indiquer ici la liste des organismes à associer au cadre d'acquisition et au jeu de données, ainsi que leur id_organisme. Cela facilitera l'intégration dans les tables CA et JDD. Il faut bien faire attention au petit décalage qui peut exister entre les id_organisme en dév et prod. Il est conseillé de vérifier en amont si ce décalage exsiste pour penser le cas échéant à l'adapter lors de l'import en prod.

-- vérifier le id_organisme :
SELECT id_organisme FROM occtax.organisme WHERE sigle='ONF'; -- par ex

-- on vérifie si le cadre existe
SELECT * FROM occtax.cadre WHERE cadre_id = 'T25856';

INSERT INTO occtax.cadre
    (cadre_id, cadre_uuid, libelle, description, ayants_droit, date_lancement, date_cloture)
SELECT
        'T25856' AS cadre_id,
        'AADC610C-1566-7740-E053-2614A8C0710E' AS cadre_uuid,
        'Élaboration des aménagements des forêts domaniales et départementales de Mayotte' AS libelle,
        'Les premiers aménagements (plans de gestion) des forêts publiques mahoraises ont été élaborés au travers des études et inventaires réalisées par l’Office National des Forêts (ONF). L’objectif principal des inventaires ou "descriptions des peuplements forestiers" est la différentiation des grands types de peuplements au sein d’une forêt.   Dans le but d’évaluer l’état de santé et les capacités de renouvellement des forêts et d''identifier les actions de gestion à mener, ces inventaires s’intéressent à la composition floristique et à l’abondance des espèces dans chaque strate de végétation à travers leur structure verticale et horizontale.  Ces données sont associées à toutes les données faune / flore saisies et levées par l''ONF (entre 2014 et 2018) dans le cadre de l''élaboration des premiers aménagements des forêts domaniales et départementales. ' AS description,
        '[
                {"role": "Contact principal", "id_organisme": 3},
                {"role": "Financeur", "id_organisme": 3},
                {"role": "Maitre d''ouvrage", "id_organisme": 3},
                {"role": "Maître d''oeuvre", "id_organisme": 3},
                {"role": "Maître d''oeuvre", "id_organisme": 5},
                {"role": "Maître d''oeuvre", "id_organisme": 2}
        ]'::jsonb AS ayants_droit,
        '2014-01-01'::date AS date_lancement,
        '2018-12-31'::date AS date_cloture
WHERE NOT EXISTS (SELECT cadre_id FROM occtax.cadre WHERE cadre_id = 'T25856')
;

SELECT * FROM occtax.cadre ORDER BY cadre_id ;

-- 2.2 jdd
-- pour le id_sinp_jdd et jdd_id, les récupérer sur l'application nationale de gestion des métadonnées
-- https://inpn.mnhn.fr/mtd/ qu'il faut remplir au préalable.
-- Chaque jeu de données doit être associé à une fiche de métadonnées de jdd spécifique, et une
-- fiche de cadre d'acquisition qui peut être partagée avec d'autres jdd)

-- exemple de JDD:
-- Identifiant du cadre d'acquisition : T25856
-- Libellé du cadre d'acquisition : Élaboration des aménagements des forêts domaniales et départementales de Mayotte
-- Code du jeu de données : T40895
-- Libellé du jeu de données : Données FAUNE des inventaires préalables aux aménagements des forêts domaniales et départementales de Mayotte
-- Date de création : 10/06/2020
-- Nom du créateur : agencemayotte@onf.fr
-- Date de mise à jour :
-- Nom de l'opérateur de la mise à jour : AH
-- 80BFF849-2F1E-4F3B-E053-2614A8C0E4BD
-- cadre  = 6386AA2E-7590-5FE3-E053-2614A8C00573

-- Rq : cadre_id (occtax.cadre) correspond à jdd_cadre (occtax.jdd)


INSERT INTO occtax.jdd
    (jdd_id, jdd_code, jdd_description, id_sinp_jdd, jdd_cadre, ayants_droit, jdd_libelle, date_minimum_de_diffusion)
SELECT
        'T40895' AS jdd_id,
        'Données FAUNE des inventaires AMF' AS jdd_code,
        'La liste d''espèces, mesures et informations relevées sont associées à un point géolocalisé qui correspond au centre de la placette (voir l''onglet généalogie). Aussi, lors de l''acheminement entre placettes, des relevés supplémentaires relatifs à des espèces de faune ou de flore peuvent être géoréférencés. Période: du 01/01/2014 au 31/12/2018' AS jdd_description,
        'AAEEEA9C-B887-40CC-E053-2614A8C03D42' AS id_sinp_jdd,
        'T25856' AS jdd_cadre,
        '[
                {"role": "Producteur", "id_organisme": 3}
        ]'::jsonb AS ayants_droit,

        -- libellé court du jeu de données, qui apparaîtra notamment dans le menu de recherche de jdd sur Borbonica et doit donc être le plus intelligible possible pour un utilisateur extérieur. jdd_libelle est construit ainsi : [Suivi/inventaire/observations...de] [groupe/espèce] [éventuellement lieu] ([Ayants-droits indiqués pour le jdd], [export mm/aaaa s'il s'agit de données historiques issues d'un cadre pérenne] [année début - année fin dans les autres cas]
        'Données FAUNE des inventaires AMF (ONF, 2014-2018)' AS jdd_libelle,

        -- exemple ou NULL -> pour certains JDD en cas de publication scientifique à la demande du producteur
        -- '2021-06-01'::date AS date_minimum_de_diffusion
        NULL AS date_minimum_de_diffusion
        -- ATTENTION il faut mettre NULL pour pouvoir voir des observations car occtax.vm_observation filtre sur ce champs
WHERE NOT EXISTS (SELECT jdd_id FROM occtax.jdd WHERE jdd_id = 'T40895');

SELECT * FROM occtax.jdd ORDER BY jdd_code ;

------------------------------------
-- 3 - import des observations
DROP TABLE IF EXISTS fdw.l_faune_onf_2014_2018_observations ;

CREATE TABLE fdw.l_faune_onf_2014_2018_observations (
    idorigine text,
    jdd_id text,
    statobs text,
    nom_vern_mah text,
    nom_complet text,
    cdnom text,
    observateur_1 text,
    observateur_2 text,
    observateur_3 text,
    observateur_4 text,
    denbrmin text,
    denbrmax text,
    objdenbr text,
    typdenbr text,
    comment text,
    datedebut text,
    datefin text,
    x text,
    y text,
    maille text,
    natobjgeo text,
    precisgeo text,
    altmoy text,
    obsdescr text,
    refbiblio text,
    obsmeth text,
    ocetatbio text,
    ocnat text,
    ocsex text,
    ocstade text,
    ocstatbio text,
    preuveoui text,
    preuvnum text,
    preuvnonum text,
    obsctx text,
    statsource text,
    difnivprec text,
    dspublique text,
    ocmethdet text,
    strate text,
    coeffad text,
    taxrefvalues text,
    _lr_w text,
    _lr_may text,
    _nombre text,
    _orgobs text,
    _nom_vern_fr text,
    _observateu text
);

-- On utilise psql pour la copie des données
\cd /home/mdouchin/Documents/3liz/DEAL_Mayotte/echange/inventaires/DEAL_MAYOTTE_LOT_1/ONF/JDDs/
\COPY fdw.l_faune_onf_2014_2018_observations FROM 'L_Faune_ONF_Mayotte_AmFor_2014_2017_P_976.csv' HEADER CSV DELIMITER ';' ;

-- Création d’une clef primaire :
ALTER TABLE fdw.l_faune_onf_2014_2018_observations ADD CONSTRAINT pk_l_faune_onf_2014_2018_observations PRIMARY KEY (idorigine) ;  -- la clé primaire nous évite la création a posteriori d'un index

SELECT * FROM fdw.l_faune_onf_2014_2018_observations LIMIT 1;

-- CORRECTION MANUELLE SRF -> CDM/DRTM/SRF
UPDATE fdw.l_faune_onf_2014_2018_observations
SET (_orgobs, _observateu) =
( replace(_orgobs, 'SRF', 'CDM/DRTM/SRF'), replace(_observateu, 'SRF', 'CDM/DRTM/SRF') )
;
-- verification
SELECT _orgobs, _observateu
FROM fdw.l_faune_onf_2014_2018_observations
WHERE _observateu LIKE '%SRF%';

------------------------------------
-- 7 - Analyse du jeu de données à partir de la fonction jdd_analyse
-- La fonction permet de calculer et stocker les valeurs uniques de chaque champ dans la table fdw.jdd_analyse
-- Le résultat de la vue fdw.v_jdd_analyse peut ensuite être utilisé dans le rapport d'import (fichier « description_donnees_source » annexé au rapport d’import) et pour faciliter le formatage des données

-- Nettoyage du jdd : suppression des espaces en bout de chaîne et remplacement des valeurs '' par des valeurs NULL
SELECT divers.nettoyage_valeurs_null_et_espaces('l_faune_onf_2014_2018_observations') ;

-- le 1er argument est le nom de la table à analyser, qui doit être dans le schéma fdw. Le 2ème argument correspond au nombre maximum de valeurs différentes que l'on souhaite afficher dans l'analyse d'un champ
-- exemple avec 100 valeurs uniques listés
SELECT divers.analyse_jdd ('l_faune_onf_2014_2018_observations', 150) ;
SELECT * FROM divers.v_jdd_analyse ;
-- Exemple pour lister les valeurs de statobs
SELECT * FROM divers.v_jdd_analyse WHERE champ='statobs';


-------------------------------------------------------------------------------------
-- PARTIE II : import des taxons qui ne sont pas dans Taxref et liens entre les identifiants de taxons locaux et cd_nom du TAXREF
-------------------------------------------------------------------------------------


-- 1 - Vérification des cdnom du fdw
-- Il s’agit de vérifier si le rattachement taxonomique a bien été effectué. Pour cela, on vérifie si le nomcite est cohérent avec le nom_complet renvoyé par Taxref. La vérification est manuelle et peut être facilitée en cas de nombre

SELECT
r.nom_complet, r.cdnom,
t.cd_ref,
r.cdnom::integer - t.cd_ref::integer AS diff,
t.nom_vern, t.nom_complet, t.nom_valide, t.rang, t.may
FROM fdw.l_faune_onf_2014_2018_observations r
LEFT JOIN taxon.taxref_consolide_non_filtre t
    ON t.cd_nom=r.cdnom::INTEGER
-- WHERE t.cd_nom IS NULL
-- en décommentant le WHERE, on a la liste des taxons manquants, à intégrer dans Taxref_local si l’importateur a vérifié qu’ils n’étaient effectivement pas rattachables à Taxref
-- WHERE r.nom_complet <> t.nom_complet  -– en décommentant, on a la liste des seuls taxons dont le nom ne correspond pas exactement avec le nom latin de Taxref. Cela permet de faciliter la vérification manuelle.
GROUP BY r.nom_complet, r.cdnom, t.cd_nom, t.cd_ref, t.nom_vern, t.nom_complet,t.nom_valide, t.rang, t.may
ORDER BY t.nom_valide
-- diff permet de voir tout de suite si cdnom = cdref
--> s'il y a des taxons à ajouter => remplir taxref_local_source + taxref_local comme indiqué dans les parties suivantes, qui peuvent être sautées si aucun taxon n’est à ajouter.

-- Pour ce JDD Faune ONF, aucun taxon manquant

-------------------------------------------------------------------------------------
-- PARTIE III : Import des données dans occtax
-------------------------------------------------------------------------------------


-- 1- Suppression des données avant réimport

-- Faire le point au préalable sur les imports ayant déjà eu lieu pour ce jdd :
SELECT * FROM occtax.jdd_import WHERE (jdd_id = 'T40895') ;

-- Le cas échéant, supprimer les données déjà importées pour les écraser avec le nouvel import :
-- SELECT count(*) FROM observation WHERE (jdd_id = 'T40895');
-- DELETE FROM occtax.observation WHERE (jdd_id = 'T40895');

------------------------------------
-- 2- import dans la table occtax.observation

-- On vérifie avant le nombre de nouvelles lignes attendues à la fin
SELECT count(*) FROM fdw.l_faune_onf_2014_2018_observations
--WHERE idorigine NOT IN ('x') -- On peut dans certains cas choisir d’écarter lors de l’import certaines données, par exemple parce qu’il s’agit de doublons ou de données signalées invalides par le producteur ;


-- ATTENTION, avant import; faire la jointure avec l export INPN pour avoir:
-- En effet, le JDD a déjà été envoyé au MNHN, qui l'a intégré et a produit un identifiant permanent
-- Fichier St_Principal.csv
-- * id_sinp_occtax = celui généré par l'INPN = colonne idSINPOcc
-- * id_origine = celui généré par AH = colonne idOrigine

DROP TABLE IF EXISTS fdw.l_faune_onf_2014_2018_export_inpn;
CREATE TABLE fdw.l_faune_onf_2014_2018_export_inpn (
    cleObs text,
    cleGrp text,
    statSource text,
    refBiblio text,
    idJdd text,
    idOrigine text,
    orgGestDat text,
    idSINPOcc text,
    dSPublique text,
    statObs text,
    cdNom text,
    nomCite text,
    denbrMin text,
    denbrMax text,
    objDenbr text,
    comment text,
    dateDebut text,
    dateFin text,
    dateDet text,
    altMin text,
    altMoy text,
    altMax text,
    profMin text,
    profMoy text,
    profMax text,
    nomLieu text,
    cleObjet text,
    identObs text,
    detminer text,
    sensiNiveau text,
    sensiNiveauValue text
)
;
CREATE INDEX ON fdw.l_faune_onf_2014_2018_export_inpn (idJdd);

-- Import des données récupérées de l'INPN. Le fichier contient tous les jeux de données, et pas seulement celui sur la faune ONF: il faudra filtrer par idJdd
-- On lance la commande psql
\cd /home/mdouchin/Documents/3liz/DEAL_Mayotte/echange/inventaires/transfer_484603_files_07a4cf86/
\COPY fdw.l_faune_onf_2014_2018_export_inpn FROM 'St_Principal.csv' HEADER CSV DELIMITER ';' ;
\x auto
SELECT count(*)
FROM fdw.l_faune_onf_2014_2018_export_inpn
WHERE idjdd = 'AAEEEA9C-B887-40CC-E053-2614A8C03D42'
;
-- Fichier St_Principal.csv
-- * id_sinp_occtax = celui généré par l'INPN = colonne idSINPOcc
-- * id_origine = celui généré par AH = colonne idOrigine
-- On en compte seulement 419 alors que le jeu des observation en a 420 !
-- on teste
SELECT
o.idorigine, i.idorigine, i.idsinpocc, i.idjdd
FROM fdw.l_faune_onf_2014_2018_observations AS o
LEFT JOIN fdw.l_faune_onf_2014_2018_export_inpn AS i
    ON i.idorigine = o.idorigine
ORDER BY i.idjdd DESC
;
-- -> la ligne en plus dans le csv par rapport à l'export INPN est
-- idorigine  = 'b0756f9d-af5b-4d13-94a3-a07d3bff36dd'
-- Pour cette obs, la datedebut = '15-Jun'. On doit rejeter cette obs.
-- C'est probablement pour cela que l'INPN ne l'a pas intégrée

-- Import des données
-- On modifie la séquence pour être sûr d'avoir une future valeur libre
SELECT Setval('occtax.observation_cle_obs_seq', (SELECT max(cle_obs) FROM occtax.observation ) );

INSERT INTO occtax.observation
(
        cle_obs,
        id_sinp_occtax,
        statut_observation,
        cd_nom,
        cd_ref,
        cd_nom_cite,
        version_taxref,
        nom_cite,
        denombrement_min,
        denombrement_max,
        objet_denombrement,
        type_denombrement,
        commentaire,
        date_debut,
        date_fin,
        heure_debut,
        heure_fin,
        date_determination,
        dee_date_derniere_modification,
        dee_date_transformation,
        altitude_min,
        altitude_moy,
        altitude_max,
        profondeur_min,
        profondeur_moy,
        profondeur_max,
        dee_floutage,
        diffusion_niveau_precision,
        ds_publique,
        id_origine,
        jdd_code,
        jdd_id,
        id_sinp_jdd,
        organisme_gestionnaire_donnees,
        org_transformation,
        statut_source,
        reference_biblio,
        sensi_date_attribution,
        sensi_niveau,
        sensi_referentiel,
        sensi_version_referentiel,
        validite_niveau,
        validite_date_validation,
        descriptif_sujet,
        donnee_complementaire,
        precision_geometrie,
        nature_objet_geo,
        geom,
        odata
)
SELECT
    -- identifiants
    nextval('occtax.observation_cle_obs_seq'::regclass) AS cle_obs,

    -- On a vérifié lors de l'import des sources que la table importée dispose bien de valeurs uniques et pérennes (clef primaire)
    -- dans le cas de donnée déjà envoyées vers l'INPN,
    -- , c'est l'inpn qui a définit l'identifiant permanent
    -- On doit conserver celui récupéré dans l'export fait depuis la plateforme nationale

    -- code utilisé si c'est la plateforme régionale qui définit les id permanents
    -- CASE
            -- WHEN loip.id_sinp_occtax IS NOT NULL THEN loip.id_sinp_occtax
            -- ELSE CAST(uuid_generate_v4() AS text)
    -- END AS id_sinp_occtax,

    -- code dans le cas où c'est l'inpn qui le définit
    CASE
            WHEN inpn.idsinpocc IS NOT NULL THEN inpn.idsinpocc
            ELSE CAST(uuid_generate_v4() AS text)
    END AS id_sinp_occtax,

    s.statobs AS statut_observation,

    -- taxons

    -- cd_nom
    s.cdnom::bigint AS cd_nom,
    -- CASE  --> ajouter autant de cas que de nouveaux taxons dans taxref_local
            -- WHEN s.cd_nom is NULL THEN (SELECT cd_nom FROM taxref_local WHERE lb_nom = 'Tupinambis merianae' )
            -- ELSE s.cd_nom::bigint
    -- END AS cd_nom,
    --s.cdnom::bigint AS cd_ref,

    -- cd_ref
    (SELECT cd_ref FROM taxon.taxref WHERE cd_nom = s.cdnom::bigint) AS cd_ref, -- si le cdref n'est pas rempli
    -- CASE  --> ajouter autant de cas que de nouveaux taxons dans taxref_local
            -- WHEN s.cd_nom is NULL THEN (SELECT cd_nom FROM taxref_local WHERE lb_nom = 'Tupinambis merianae' )
            -- ELSE s.cd_ref::bigint
    -- END AS cd_ref,

    -- Faire attention que les cd_ref soient valides - cf script ci-dessus (II - 1)

    s.cdnom::bigint AS cd_nom_cite,

    '13.0' AS version_taxref, -- Adapter si besoin en fonction de la version mise en œuvre dans Borbonica (une nouvelle version sortie chaque année)
    s.nom_complet AS nom_cite,

    -- denombrement
    -- "non dénombrement" avec présence => denombrement_min = denombrement_max = objet_denombrement = type_denombrement = NULL
    s.denbrmin::INTEGER AS denombrement_min,

    CASE
            WHEN (TRIM(s.denbrmax) is NULL OR TRIM(s.denbrmax) = 'N/A') and TRIM(s.denbrmin) is not NULL
                THEN trim(s.denbrmin)::INTEGER
            ELSE s.denbrmax::INTEGER
    END AS denombrement_max,

    CASE
            WHEN trim(s.objdenbr) = 'NSP' THEN 'NSP'
            ELSE 'NSP'
    END AS objet_denombrement,
    CASE
            WHEN trim(s.typdenbr) = 'Ca' THEN 'Ca'
            WHEN trim(s.typdenbr) = 'Es' THEN 'Es'
            WHEN trim(s.typdenbr) = 'Co' THEN 'Co'
            WHEN trim(s.typdenbr) = 'NSP' THEN 'NSP'
            ELSE 'NSP'
    END AS type_denombrement,

    -- commentaires -- à adapter !!!
    -- On doit s'efforcer d'importer les informations de l'ensemble des champs du jdd source, sans perte, quitte à les intégrer dans les champs commentaires si aucun autre champ ne permet de le faire. Une solution intéressante consiste également à utiliser les champs attributs additionnels si besoin (voir plus bas).
    concat(_observateu, ' - ', TRIM(s.comment)) AS commentaire,

    -- dates
    -- bien vérifier les formats -> adapter le case en fonction de la saisie
    -- SELECT * FROM divers.v_jdd_analyse WHERE champ='datedebut';
    -- Une des dates est '15-Jun', idorigine = 'b0756f9d-af5b-4d13-94a3-a07d3bff36dd' -> on doit rejeter cette obs
    -- dans ce JDD, la date est écrite au format AAAAMMJJ: 20150923
    to_date(s.datedebut, 'YYYYmmdd') AS date_debut,
    to_date(s.datefin, 'YYYYmmdd') AS date_fin,

    NULL AS heure_debut,
    NULL AS heure_fin,
--              NULL::time with time zone AS heure_debut,
--              NULL::time with time zone AS heure_fin,
    NULL as date_determination,

    -- dates de modifications & transformation
    -- on ne l'a pas dans le fichier exporté depuis l'INPN
    -- On fait quoi ?
    CASE
        WHEN loip.id_sinp_occtax IS NOT NULL
            THEN loip.dee_date_derniere_modification
        ELSE now()
    END AS dee_date_derniere_modification,

    CASE
        WHEN loip.dee_date_transformation IS NOT NULL
            THEN loip.dee_date_transformation
        ELSE now()
    END AS dee_date_transformation,

    -- altitudes -- ces éléments sont recalculés plus bas via le MNT pour être stockés dans des attributs additionnels. Il s’agit ici de stocker les altitudes éventuellement fournies par le producteur
    NULL as altitude_min,
    CASE
            WHEN s.altmoy is NULL then NULL
            ELSE s.altmoy::NUMERIC
            -- ELSE regexp_replace( s.altmoy, ',', '.')::NUMERIC -- au cas où le séparateur décimal est ","
    END AS altitude_moy,
    NULL as altitude_max,

    -- profondeurs
    NULL AS profondeur_min,
    NULL AS profondeur_moy,
    NULL AS profondeur_max,


    'NON'::text AS dee_floutage, -- pas de données floutées en entrée dans le cadre du SINP 976 ?

    -- diffusion_niveau_precision, -- n'utiliser que 'maille 2 km' ou 'précise' dans le modèle de saisie
    CASE
        -- WHEN trim(s.difnivprec) = 'tout' THEN '0'
        -- WHEN trim(s.difnivprec) = 'commune' THEN '1'
        -- WHEN trim(s.difnivprec) = 'maille 10 km' THEN '2'
        -- WHEN trim(s.difnivprec) = 'maille 2 km' THEN 'm02'
        -- WHEN trim(s.difnivprec) = 'département' THEN '3'
        -- WHEN trim(s.difnivprec) = 'non diffusé' THEN '4'
        -- WHEN trim(s.difnivprec) = 'précise' THEN '5'
        WHEN trim(s.difnivprec) = '5' THEN '5'
        ELSE '5'
    END AS diffusion_niveau_precision,

    -- ds_publique
    CASE
        -- WHEN trim(s.dspublique) = 'Publique' THEN 'Pu'
        -- WHEN trim(s.dspublique) = 'Publique Régie' THEN 'Re' -- gelé avec occtax 2.0
        -- WHEN trim(s.dspublique) = 'Publique Acquise' THEN 'Ac' -- gelé avec occtax 2.0
        -- WHEN trim(s.dspublique) = 'Privée' THEN 'Pr'
        -- WHEN trim(s.dspublique) = 'Ne sait pas' THEN 'NSP'
        WHEN trim(s.dspublique) = 'Pu' THEN 'Pu'
        WHEN trim(s.dspublique) = 'NSP' THEN 'NSP'
        ELSE 'NSP'
    END AS ds_publique,

    -- idorigine
    s.idorigine AS id_origine,

    -- JDD : on reprend ici les éléments déjà utilisés pour renseigner la table jdd
    j.jdd_code AS jdd_code,
    j.jdd_id AS jdd_id,
    j.id_sinp_jdd AS id_sinp_jdd,

    --producteur-gestionnaire - orgGestDat
    'Office National des Forêts' AS organisme_gestionnaire_donnees,

    --mise en base SINP
    'DEAL_May' AS org_transformation,

    --sources
    CASE
        WHEN LOWER(s.statsource) = 'te' THEN 'Te'
        WHEN LOWER(s.statsource) = 'co' THEN 'Co'
        WHEN LOWER(s.statsource) = 'li' THEN 'Li'
        WHEN LOWER(s.statsource) = 'nsp' THEN 'NSP'
        ELSE NULL
    END AS statut_source,

    -- références bibliographiques : à compléter si nécessaire avec les infos du producteur -> existe a minima quand il y a de nouveaux taxons, qui font souvent l’objet de publications scientifiques
    TRIM(s.refbiblio) AS reference_biblio,

    -- sensibilite : remplissage provisoire à ce stade car une fonction spécifique la calcule une fois l'import réalisé (cf. plus bas)
    now()::timestamp with time zone AS sensi_date_attribution,
    -- on prend la plus large
    'm02' AS sensi_niveau,
    'http://www.naturefrance.fr/la-reunion/referentiel-de-sensibilite' AS sensi_referentiel,
    '1.4.0' AS sensi_version_referentiel, -- voir occtax.sensibilite_referentiel


    -- validation : remplissage provisoire à ce stade car une fonction spécifique calcul_niveau_validation la calcule une fois l'import réalisé (cf. plus bas)
    '6' AS validite_niveau, -- Si un niveau de validation est indiqué par le producteur ou la tête de réseau, il doit être précisé ici et sera utilisé plus bas dans le script (cf. partie 9 relative à la validation). Sinon, laisser 6 par défaut.
    now()::DATE AS validite_date_validation, -- Si une date de validation est indiquée par le producteur ou la tête de réseau, elle doit être précisée ici et sera utilisée plus bas dans le script (cf. partie 9 relative à la validation). Sinon, laisser now() par défaut.

    -- descriptif du sujet
    json_build_array (json_build_object(

        -- MÉTHODE D'OBSERVATION
        -- SELECT * FROM divers.v_jdd_analyse WHERE champ='obsmeth';
        'obs_technique',
        -- CASE
        -- WHEN trim(s.obsmeth) = 'Vu' THEN '0'
        -- WHEN trim(s.obsmeth) = 'Entendu' THEN '1'
        -- WHEN trim(s.obsmeth) = 'Coquilles d''œuf' THEN '2'
        -- WHEN trim(s.obsmeth) = 'Ultrasons' THEN '3'
        -- WHEN trim(s.obsmeth) = 'Empreintes' THEN '4'
        -- WHEN trim(s.obsmeth) = 'Exuvie' THEN '5'
        -- WHEN trim(s.obsmeth) = 'Fèces/Guano/Épreintes' THEN '6'
        -- WHEN trim(s.obsmeth) = 'Mues' THEN '7'
        -- WHEN trim(s.obsmeth) = 'Nid/Gîte' THEN '8'
        -- WHEN trim(s.obsmeth) = 'Pelote de réjection' THEN '9'
        -- WHEN trim(s.obsmeth) = 'Restes dans pelote de réjection' THEN '10'
        -- WHEN trim(s.obsmeth) = 'Poils/plumes/phanères' THEN '11'
        -- WHEN trim(s.obsmeth) = 'Restes de repas' THEN '12'
        -- WHEN trim(s.obsmeth) = 'Spore' THEN '13'
        -- WHEN trim(s.obsmeth) = 'Pollen' THEN '14'
        -- WHEN trim(s.obsmeth) = 'Oosphère' THEN '15'
        -- WHEN trim(s.obsmeth) = 'Ovule' THEN '16'
        -- WHEN trim(s.obsmeth) = 'Fleur' THEN '17'
        -- WHEN trim(s.obsmeth) = 'Feuille' THEN '18'
        -- WHEN trim(s.obsmeth) = 'ADN environnemental' THEN '19'
        -- WHEN trim(s.obsmeth) = 'Autre' THEN '20'
        -- WHEN trim(s.obsmeth) = 'Inconnu' THEN '21'
        -- WHEN trim(s.obsmeth) = 'Mine' THEN '22'
        -- WHEN trim(s.obsmeth) = 'Galerie/terrier' THEN '23'
        -- WHEN trim(s.obsmeth) = 'Oothèque' THEN '24'
        -- WHEN trim(s.obsmeth) = 'Vu et entendu' THEN '25'
        -- WHEN trim(s.obsmeth) = 'Contact olfactif' THEN '26'
        -- Code supplémentaire
        CASE
            WHEN trim(s.obsmeth) = '0' THEN '0'
            ELSE '21' -- inconnu
        END,

        -- ETAT BIOLOGIQUE
        'occ_etat_biologique',
        CASE
            -- WHEN LOWER(s.ocetatbio) = 'observé vivant' THEN '2'
            -- WHEN LOWER(s.ocetatbio) = 'trouvé mort' THEN '3'
            -- WHEN LOWER(s.ocetatbio) = 'NSP' THEN '0'
            -- WHEN LOWER(s.ocetatbio) = 'Non renseigné' THEN '1'
            WHEN LOWER(s.ocetatbio) = '2' THEN '2'
            ELSE '1' -- Non renseigné
        END,

        -- NATURALITE
        'occ_naturalite',
        CASE
            -- WHEN trim(s.ocnat) = 'Inconnu' THEN '0'
            -- WHEN trim(s.ocnat) = 'Sauvage' THEN '1'
            -- WHEN trim(s.ocnat) = 'Cultivé/élevé' THEN '2'
            -- WHEN trim(s.ocnat) = 'Planté' THEN '3'
            -- WHEN trim(s.ocnat) = 'Féral' THEN '4'
            -- WHEN trim(s.ocnat) = 'Subspontané' THEN '5'
            WHEN trim(s.ocnat) = '0' THEN '0'
            ELSE '0' -- inconnu
        END,

        -- SEXE
        'occ_sexe',
        CASE
            -- WHEN trim(s.ocsex) = 'Inconnu' THEN '0'
            -- WHEN trim(s.ocsex) = 'Indéterminé' THEN '1'
            -- WHEN trim(s.ocsex) = 'Femelle' THEN '2'
            -- WHEN trim(s.ocsex) = 'Mâle' THEN '3'
            -- WHEN trim(s.ocsex) = 'Hermaphrodite' THEN '4'
            -- WHEN trim(s.ocsex) = 'Mixte' THEN '5'
            -- WHEN trim(s.ocsex) = 'Non renseigné' THEN '6'
            WHEN trim(s.ocsex) = '0' THEN '0'
            ELSE '6' -- Non renseigné
        END,

        -- STADE DE VIE
        'occ_stade_de_vie',
        CASE
            -- WHEN trim(s.ocstade) = 'Inconnu' THEN '0'
            -- WHEN trim(s.ocstade) = 'Indéterminé' THEN '1'
            -- WHEN trim(s.ocstade) = 'Adulte' THEN '2'
            -- WHEN trim(s.ocstade) = 'Juvénile' THEN '3'
            -- WHEN trim(s.ocstade) = 'Immature' THEN '4'
            -- WHEN trim(s.ocstade) = 'Sub-adulte' THEN '5'
            -- WHEN trim(s.ocstade) = 'Larve' THEN '6'
            -- WHEN trim(s.ocstade) = 'Chenille' THEN '7'
            -- WHEN trim(s.ocstade) = 'Têtard' THEN '8'
            -- WHEN trim(s.ocstade) = 'Œuf' THEN '9'
            WHEN trim(s.ocstade) = '0' THEN '0'
            ELSE '0' -- inconnu
        END,

        -- DENOMBREMENT DETAILLE
        'occ_denombrement_min', s.denbrmin::INTEGER,

        'occ_denombrement_max',
        CASE
            WHEN (TRIM(s.denbrmax) is NULL OR TRIM(s.denbrmax) = 'N/A') and TRIM(s.denbrmin) is not NULL
                THEN s.denbrmin::INTEGER
            ELSE s.denbrmax::INTEGER
        END,

        'occ_objet_denombrement',

        CASE
            WHEN trim(s.objdenbr) = 'NSP' THEN 'NSP'
            ELSE 'NSP'
        END,

        'occ_type_denombrement',
        CASE
            WHEN trim(s.typdenbr) = 'Ca' THEN 'Ca'
            WHEN trim(s.typdenbr) = 'Es' THEN 'Es'
            WHEN trim(s.typdenbr) = 'Co' THEN 'Co'
            WHEN trim(s.typdenbr) = 'NSP' THEN 'NSP'
            ELSE 'NSP'
        END,


        -- STATUT BIOGEOGRAPHIQUE
        -- une seul valeur dans le csv: ocstatbio = '0'
        'occ_statut_biogeographique',
        s.ocstatbio,

        -- STATUT BIOLOGIQUE
        -- pas de colonne correspondante dans le CSV
        'occ_statut_biologique',
        '1',

        -- PREUVE EXISTANTE
        'preuve_existante', s.preuveoui,

        -- PREUVE NUM
        'url_preuve_numerique', s.preuvnum,

        -- PREUVE NON NUM
        'preuve_non_numerique', s.preuvnonum,

        -- CONTEXTE
        'obs_contexte', s.obsctx,

        -- DESCRIPTION
        'obs_description', s.obsdescr,

        --  DETERMINATION
        'occ_methode_determination', s.ocmethdet

    ))::jsonb AS descriptif_sujet,

    -- données complémentaires
    NULL AS donnee_complementaire,  -- ce champ peut éventuellement être utilisé pour stocker d’autres informations non prévues au standard, mais il vaut mieux y préférer l’utilisation de la table attribut_additionnel

    -- precision géométrie
    s.precisgeo::INTEGER AS precision_geometrie,

    -- nature géométrie
    CASE
            WHEN LOWER(s.natobjgeo) = 'st' THEN 'St'
            WHEN LOWER(s.natobjgeo) = 'in' THEN 'In'
            WHEN LOWER(s.natobjgeo) = 'nsp' THEN 'NSP'
            ELSE 'NSP'
    END  AS nature_objet_geo,

    -- TRIM(s.natobjgeo) IS NOT NULL THEN TRIM(s.natobjgeo), -si saisie 'St', 'In' et 'NSP'

    -- ATTENTION : pour les géométries => le "." est le séparateur décimal et non la ","
    -- geom -> xy (dans les cas où la géométrie des points est indiquée sous forme de coordonnées XY)
    CASE
            WHEN s.x IS NOT NULL AND s.y IS NOT NULL
            THEN ST_SetSrid(ST_GeomFromText('POINT(' || s.x || ' ' || s.y || ')', 4471), 4471) -- Format RGR92 déjà utilisé
            -- THEN st_transform(st_GeomFromText('POINT(' || regexp_replace( s.x, ',', '.') || ' ' || regexp_replace(s.y,',', '.') || ')', 32740),4471), -- WGS84 utm40s (GPS) -> RGR92 utm40s
            ELSE NULL
    END AS geom,

    -- geom -> wkt (dans les cas où la géométrie des points est indiquée sous forme de WKT)
    -- CASE
    -- WHEN wkt IS NOT NULL
            -- THEN ST_SetSrid(ST_GeomFromText(s.wkt, 4471), 4471)
            -- -- THEN ST_Transform(ST_GeomFromText(s.wkt, 4326),4471) --  WGS84 (lon/lat) (GPS) -> RGR92 utm40s
            -- -- THEN ST_SetSrid(ST_GeomFromText((regexp_replace((regexp_replace( s.wkt, ',', '.')), ',', '.')), 4471), 4471) -- si ","
            -- ELSE NULL
    -- END AS geom,

    -- odata : champ permettant éventuellement de stocker de manière provisoire des informations utiles à l’import, qui ne seront pas diffusées ensuite
    json_build_object('_observateu', _observateu) AS odata


FROM

-- table source
fdw.l_faune_onf_2014_2018_observations  AS s

-- table de(s) jdd
-- attention, dans ce jdd, le jdd_id de la source CSV est en fait le id_sinp_jdd au sens INPN
INNER JOIN occtax.jdd j
    ON j.id_sinp_jdd = s.jdd_id

-- jointure pour récupérer les identifiants permanents si déjà créés lors d'un import passé
LEFT JOIN occtax.lien_observation_identifiant_permanent AS loip
    ON loip.jdd_id IN ('T40895')
    AND loip.id_origine = s.idorigine::TEXT

-- jointure pour récupérer l'identifiant permanent si la plateforme nationale l'a déjà généré
LEFT JOIN fdw.l_faune_onf_2014_2018_export_inpn AS inpn
    ON inpn.idjdd = 'AAEEEA9C-B887-40CC-E053-2614A8C03D42'
    AND inpn.idorigine = s.idorigine

-- s'il y a plusieurs jdd ajouter :
-- AND loip.jdd_id = s.jdd_id -- (ou j.jdd_id)

WHERE TRUE

-- on a une référence dans l'export inpn
AND inpn.idorigine IS NOT NULL


; -- On peut éventuellement ajouter ici des filtres pour écarter lors de l’import des données du jeu de données source, comme évoqué plus haut



-- Si le champ cd_nom_cite n'a pas été renseigné ci-dessus :
-- UPDATE occtax.observation
-- set cd_nom_cite = cd_nom
-- WHERE jdd_id IN ('T40895');

-- Vérifications
SELECT count(*) FROM occtax.observation WHERE jdd_id IN ('T40895')  ;


------------------------------------
-- 3- Vidage puis remplissage de lien_observation_identifiant_permanent pour garder en mémoire les identifiants permanents en cas d'un réimport futur

DELETE FROM occtax.lien_observation_identifiant_permanent
WHERE jdd_id IN ('T40895')   ;

INSERT INTO occtax.lien_observation_identifiant_permanent
(jdd_id, id_origine, id_sinp_occtax, dee_date_derniere_modification, dee_date_transformation)
SELECT o.jdd_id, o.id_origine, o.id_sinp_occtax, o.dee_date_derniere_modification, o.dee_date_transformation
FROM occtax.observation o
WHERE jdd_id IN ('T40895')
ORDER BY o.cle_obs
;

-- Vérification
SELECT * FROM occtax.lien_observation_identifiant_permanent
WHERE jdd_id IN ('T40895');


------------------------------------
-- 4-  Renseignement des personnes associées aux observations (observateurs, déterminateurs)
--"role_personne";"Det";"Déterminateur"
--"role_personne";"Obs";"Observateur"
-- NB : les validateurs sont pas traités ici ; si les données sont déjà validées --> cf 9.3 -- les déterminateurs sont traités comme les observateurs

-- 4.0 vérifications préalables

-- Couples observations/personnes déjà renseignées pour ce jeu de données :
SELECT count(*)
FROM occtax.observation_personne
LEFT JOIN occtax.observation USING (cle_obs)
WHERE jdd_id IN ('T40895');

-- recherche de doublons dans occtax.personne

SELECT tab1.id_personne, tab1.identite, tab1.mail, tab1.id_organisme, tab2.id_personne, tab2.identite, tab2.mail, tab2.id_organisme
FROM occtax.personne tab1, occtax.personne tab2

WHERE trim(lower(unaccent(tab1.identite)))=trim(lower(unaccent(tab2.identite)))
        AND tab1.id_organisme=tab2.id_organisme
--      AND tab1.mail=tab2.mail
        AND tab1.id_personne<>tab2.id_personne
    AND tab1.id_personne=(SELECT MAX(id_personne) FROM occtax.personne tab
    WHERE tab.id_personne=tab1.id_personne)
ORDER BY tab1.id_personne
;

-- ATTENTION : bien gérer dans son script pour créer identite_personne
-- "Si la personne n'est pas connue (non mentionnée dans la source) : noter INCONNU en lieu et place de NOM Prénom."
-- => seule identité est "normée"
-- Nous avons choisi de mettre "INCONNU" pour remplacer null
-- ATTENTION  par la suite de bien gérer dans son script pour créer identite
-- Ne pas faire : INCONNU Inconnu - DUPONT Inconnu - INCONNU Cunégonde
-- Faire : INCONNU - DUPONT - Cunégonde (la casse permet de différencier nom et prénom)



-- 4.1 table organisme

--> I 1.1

-- Exemple d'ajout manuel d'un organisme
-- SELECT Setval('occtax.organisme_id_organisme_seq', (SELECT max(id_organisme) FROM occtax.organisme) );
-- INSERT INTO occtax.organisme
-- (nom_organisme, sigle, responsable, adresse1, adresse2, cs, cp, commune, cedex, commentaire)
-- VALUES (
        -- 'CYNORKIS',
        -- Null,
        -- 'Dominique HOAREAU - Gérant',
        -- '18 chemin Michel Debré',
        -- NULL,
        -- NULL,
        -- '97417',
        -- 'SAINT-DENIS',
        -- NULL,
        -- NULL
        -- )
-- ON CONFLICT DO NOTHING;

-- 4.2 table personne

--> I 1.2


-- 4.3 table observation_personne
-- elle peut contenir des observateurs et des déterminateurs
--  pour les validateurs -> gérés dans occtax.validation_observation

-- on doit faire le rapprochement avec la table fdw.l_faune_onf_2014_2018_observateurs importée depuis CSV
-- TODO: mieux préparer les données pour que les tables fdw.l_faune_onf_2014_2018_acteurs et fdw.l_faune_onf_2014_2018_organismes suffisent
-- cela évite de faire 2 fois le travail de manière différente...

-- on vérifie que le lien 1:1 existe bien entre les observations et le CSV des observateurs
SELECT
o.cle_obs, o.odata, t.observateurs, t.obs1
FROM occtax.observation AS o
INNER JOIN fdw.l_faune_onf_2014_2018_observateurs AS t
    ON o.odata->>'_observateu' = t.observateurs
WHERE True
AND o.jdd_id = 'T40895'
ORDER BY cle_obs
;
-- OK: on trouve bien 419 lignes

-- On pourra insérer les données via ce type de requête
-- TOUJOUR BIEN VERIFIE le nom de lignes retournées. Il doit être égale au nombre d'observations, au moins pour les observateurs 1
-- ( les autres peuvent ne pas être remplis)

SELECT
o.cle_obs, t.observateurs, t.obs1, t.orga1, p.identite
FROM occtax.observation AS o
INNER JOIN fdw.l_faune_onf_2014_2018_observateurs AS t
    ON o.odata->>'_observateu' = t.observateurs
INNER JOIN occtax.personne AS p
    ON concat(p.prenom, ' ', p.nom) = obs1
    AND p.id_organisme = (SELECT id_organisme FROM occtax.organisme WHERE sigle = orga1)
WHERE True
AND obs1 IS NOT NULL
AND o.jdd_id = 'T40895'
ORDER BY cle_obs
;

-- Remplissage
--observateur_1

INSERT INTO occtax.observation_personne (cle_obs, id_personne, role_personne)
SELECT
o.cle_obs, p.id_personne, 'Obs'
FROM occtax.observation AS o
INNER JOIN fdw.l_faune_onf_2014_2018_observateurs AS t
    ON o.odata->>'_observateu' = t.observateurs
INNER JOIN occtax.personne AS p
    ON concat(p.prenom, ' ', p.nom) = obs1
    AND p.id_organisme = (SELECT id_organisme FROM occtax.organisme WHERE sigle = orga1)
WHERE True
AND obs1 IS NOT NULL
AND o.jdd_id = 'T40895'
ORDER BY cle_obs
ON CONFLICT DO NOTHING
;

-- On vérifie qu'on a bien au moins un observateur/observation : liste des observations « orphelines » qui doit ne pas renvoyer de lignes à ce stade (observateur_1)
SELECT o.cle_obs, op.id_personne, op.role_personne
FROM occtax.observation o
LEFT JOIN occtax.observation_personne op USING(cle_obs)
WHERE o.jdd_id IN ('T40895')
AND op.id_personne IS NULL
ORDER BY o.cle_obs, op.id_personne ;


-- On vérifie qu'une observation n'a pas plusieurs observateurs à ce stade => si c'est le cas l'observateur n'est pas défini de manière unique entre le fichier d'observation et la table occtax.personne
--> c'est le cas si dans le fichier des observateurs fourni par le producteur, une "identité" peut être rattachée à plusieurs organismes. Dans ce cas il faut que dans le fichier d'observation cette différence puisse se faire => identité+organisme apparaissent

Select o.id_origine, count (o.id_origine) AS nb_obs
from occtax.observation as o
LEFT JOIN occtax.observation_personne as p USING (cle_obs)
where  o.jdd_id = 'T40895'
group by o.id_origine
having count (o.id_origine) > 1
;

-- On reproduit pour observateur_2, observateur_3 et observateur_4
-- ON CHANGE BIEN LE CHAMPS DE JOINTURE et tous les champs contenant 1

-- observateur 2
INSERT INTO occtax.observation_personne (cle_obs, id_personne, role_personne)
SELECT
o.cle_obs, p.id_personne, 'Obs'
FROM occtax.observation AS o
INNER JOIN fdw.l_faune_onf_2014_2018_observateurs AS t
    ON o.odata->>'_observateu' = t.observateurs
INNER JOIN occtax.personne AS p
    ON concat(p.prenom, ' ', p.nom) = obs2
    AND p.id_organisme = (SELECT id_organisme FROM occtax.organisme WHERE sigle = orga2)
WHERE True
AND obs2 IS NOT NULL
AND o.jdd_id = 'T40895'
ORDER BY cle_obs
ON CONFLICT DO NOTHING
;


-- observateur_3
INSERT INTO occtax.observation_personne (cle_obs, id_personne, role_personne)
SELECT
o.cle_obs, p.id_personne, 'Obs'
FROM occtax.observation AS o
INNER JOIN fdw.l_faune_onf_2014_2018_observateurs AS t
    ON o.odata->>'_observateu' = t.observateurs
INNER JOIN occtax.personne AS p
    ON concat(p.prenom, ' ', p.nom) = obs3
    AND p.id_organisme = (SELECT id_organisme FROM occtax.organisme WHERE sigle = orga3)
WHERE True
AND obs3 IS NOT NULL
AND o.jdd_id = 'T40895'
ORDER BY cle_obs
ON CONFLICT DO NOTHING
;

-- observateur_4
INSERT INTO occtax.observation_personne (cle_obs, id_personne, role_personne)
SELECT
o.cle_obs, p.id_personne, 'Obs'
FROM occtax.observation AS o
INNER JOIN fdw.l_faune_onf_2014_2018_observateurs AS t
    ON o.odata->>'_observateu' = t.observateurs
INNER JOIN occtax.personne AS p
    ON concat(p.prenom, ' ', p.nom) = obs4
    AND p.id_organisme = (SELECT id_organisme FROM occtax.organisme WHERE sigle = orga4)
WHERE True
AND obs4 IS NOT NULL
AND o.jdd_id = 'T40895'
ORDER BY cle_obs
ON CONFLICT DO NOTHING
;

-- Déterminateurs
-- Si des déterminateurs sont précisés en plus des observateurs, reprendre les étapes ci-dessus puis lors de l’insertion dans la table observation_personne, remplacer 'Obs' par 'Det'
-- ou les différencier directement dans le script ci-dessus :
-- exemple pour différencier observateur (Obs) et déterminateur (Det) :
    -- CASE
        -- WHEN nomdechamps = 'determinateur' THEN 'Det'
        -- ELSE 'Obs'
    -- END AS role_personne


-- Validateur
-- si les données sont déjà validées --> cf 9.3  -> gérés dans occtax.validation_observation

------------------------------------
-- 5- rattachement géographique

-- Rattachement manuel (pour mémoire) : lorsque certaines observations ne sont pas géolocalisées mais qu’elles disposent d’une entité de rattachement (par exemple la commune ou le département), une insertion manuelle dans la table occtax.localisation_commune / occtax.localisation_departement peut être nécessaire.

-- Attention, le modèle de saisie ne permet pas cette possibilité=> le modifier à la demande si nécessaire pour des données historiques

-- Attention, la charte n'autorise pas à fournir de donnée floutée au département si la géométrie précise existe ! Si la donnée est sensible, elle est rentrée avec son XY et c'est le référentiel de données sensibles qui lui attribue un sensi_niveau utilisé pour gérer la diffusion. Les seules données rattachables à une entité géo sont celles dont on n'a pas l'info, par ex des données issues de biblio anciennes avec mention uniquement de la commune

-- Exemple de rattachement au département, s'il n'y a pas de coordonnées
-- INSERT INTO occtax.localisation_departement (cle_obs, code_departement, type_info_geo)
-- SELECT  o.cle_obs,
-- '974', -- La Réunion ôté
-- '1'  -- information de géoréférencement et pas de rattachement
-- FROM dw.l_faune_onf_2014_2018_observations AS t
-- JOIN occtax.observation o ON t.idorigine=o.id_origine
-- WHERE t.precisgeo = 'rattachement La Réunion' ; --> si une colonne precisgeo par exemple a été ajoutée pour les données sensible sans coordonnées

-- Rattachement automatique : la fonction occtax.occtax_update_spatial_relationships permet de valaduler automatiquement les observations géolocalisaées aux entités géographiques de référence (mailles, communes, masses d’eau, espaces naturels). Elle est à lancer systématiquement.

SELECT occtax.occtax_update_spatial_relationships(ARRAY['T40895']);

-- Qq vérifications
-- On vérifie qu'on a le bon nombre de lignes insérées dans les tables de localisation (une ligne par observation si on n'est pas en mer)
SELECT count(*)
FROM occtax.localisation_commune
LEFT JOIN occtax.observation o USING (cle_obs)
WHERE o.jdd_id IN ('T40895');

SELECT count(*)
FROM occtax.localisation_masse_eau
LEFT JOIN occtax.observation o USING (cle_obs)
WHERE o.jdd_id IN ('T40895');

SELECT count(*)
FROM occtax.localisation_maille_10
LEFT JOIN occtax.observation o USING (cle_obs)
WHERE o.jdd_id IN ('T40895');

SELECT count(*)
FROM occtax.localisation_maille_02
LEFT JOIN occtax.observation o USING (cle_obs)
WHERE o.jdd_id IN ('T40895');

SELECT count(*)
FROM occtax.localisation_departement
LEFT JOIN occtax.observation o USING (cle_obs)
WHERE o.jdd_id IN ('T40895');


------------------------------------
-- 6- Enrichissement de la donnée avec des paramètres calculés dans Borbonica
-- Ces paramètres peuvent être utiles par exemple pour la phase de validation automatique ou encore pour générer des statistiques globales sur les données. On utilise pour cela la table attribut_additionnel
-- Ajout de l'altitude calculée par le MNT à 10 m
-- On supprime ce qui a déjà été renseigné le cas échéant

-- TODO : PAS FAIT A MAYOTTE
DELETE FROM occtax.attribut_additionnel a
WHERE cle_obs IN (SELECT cle_obs FROM occtax.observation WHERE jdd_id IN ('T40895'))
AND a.nom='altitude_mnt'
;
-- Puis on insère
INSERT INTO occtax.attribut_additionnel(cle_obs, nom, definition, valeur, unite, thematique, type)
SELECT  cle_obs,
                'altitude_mnt' AS nom,
                'Altitude déduite du MNT à 10m' AS definition,
                st_value(r.rast,st_centroid(o.geom))::numeric(6,2) AS valeur,
                'm' AS unite,
                'Altitude' AS thematique,
                'QTA' AS type
FROM occtax.observation o
INNER JOIN sig.mnt_10m r ON st_intersects(st_centroid(o.geom), r.rast)
WHERE o.jdd_id IN ('T40895')
AND st_value(r.rast,st_centroid(o.geom))::numeric(6,2) IS NOT NULL
;
-- Vérification
SELECT *
FROM occtax.attribut_additionnel a
WHERE cle_obs IN (SELECT cle_obs FROM occtax.observation WHERE jdd_id IN ('T40895'))
AND a.nom='altitude_mnt';




------------------------------------
-- 7- Validation des données
-- 7.1 On vérifie tout d'abord la cohérence et la conformité des données (validation sur la forme) en lançant la fonction de contrôle
-- Cette fonction lance une batterie de tests types (script spécifique commun à tous les jeux de données)
-- Les observations présentant des anomalies doivent être vérifiées à la main et discutées avec le producteur. Si l'anomalie est confirmée, elle doit être soit corrigée, soit écartée lors de l'import en base de production pour ne pas intégrer le SINP.

-- PAS FAIT A MAYOTTE IL FAUT MODIFIER LA FONCTION
SELECT divers.fonction_controle_coherence_conformite(ARRAY['T40895']);
SELECT * FROM divers.controle_coherence_conformite ;


-- Export pour vérification
-- PAS FAIT A MAYOTTE IL FAUT MODIFIER LA FONCTION
SELECT c.jdd_code, c.cle_obs, c.id_origine, c.libelle_test, c.description_anomalie, c.nom_cite, t.nom_valide, t.nom_vern, t.group2_inpn, CONCAT(t.may, ' - ', st.valeur) AS may, c.habitat AS habitat_taxref, c.wkt
FROM divers.controle_coherence_conformite c
LEFT JOIN occtax.observation o USING(cle_obs)
LEFT JOIN taxon.taxref t USING (cd_nom)
LEFT JOIN (SELECT * FROM taxon.t_nomenclature WHERE champ = 'habitat') hab ON hab.code=t.habitat
LEFT JOIN (SELECT * FROM taxon.t_nomenclature WHERE champ = 'statut_taxref') st ON st.code=t.may
 ;

-- Synthèse : liste des anomalies constatées (pour alimentation du rapport d’import et discussion avec le producteur de données)
-- PAS FAIT A MAYOTTE IL FAUT MODIFIER LA FONCTION
SELECT c.description_anomalie, string_agg(DISTINCT lb_nom || ' (' || t.group2_inpn || ')', ', ' ORDER BY lb_nom || ' (' || t.group2_inpn || ')') AS taxons, count(*)
FROM divers.controle_coherence_conformite c
LEFT JOIN observation o USING (cle_obs)
LEFT JOIN taxref_valide t USING (cd_ref)
GROUP BY c.description_anomalie;


-- 7.2 Vérification des doublons
-- Il s’agit de rechercher si le jeu de données importé contient des doublons, c’est-à-dire des observations qui concernent le même taxon, la même date, les mêmes observateurs et le même lieu que des observations d’autres jeux de données déjà importés dans Borbonica. Pour cela, la fonction identifie automatiquement les doublons potentiels, ie les observations concernant la même date et le même taxon et qui sont à moins de 10 km l’une de l’autre (ce paramétrage peut être modifié dans le script). CEs doublons sont stockés dans la table divers.controle_doublons qui contient dans chacun de ses champs la valeur de la table du jdd importé à gauche et celle de jdd comparé à droite. L'analyse de cette table permet manuellement de confirmer s'il s'agit ou pas d'un vrai doublon

-- Vérification des doublons externes (ie entre les observations du jdd importé et celles de tous les autres jdd déjà importés dans Borbonica) :

-- PAS FAIT A MAYOTTE IL FAUT MODIFIER LA FONCTION
-- Il manque occtax.v_descriptif_sujet_decodee
SELECT divers.fonction_controle_doublons(ARRAY['T40895'], 100,  FALSE) ;
SELECT * FROM divers.controle_doublons ;

-- Vérification des doublons internes (ie au sein du ou des jdd importés) :
SELECT divers.fonction_controle_doublons(ARRAY['T40895'], 1,  TRUE) ;
SELECT * FROM divers.controle_doublons ;


-- 7.3 Validation scientifique (= sur le fond) des données

-- Informations sur la validation manuelle si une telle validation a déjà été réalisée par les têtes de réseau ou par le producteur lui-même. Cette validation n'est pas systématique et certains producteurs n'ont pas mis en place de système de validation interne

SELECT Setval('occtax.validation_observation_id_validation_seq', (SELECT max(id_validation) FROM occtax.validation_observation ) );

INSERT INTO occtax.validation_observation
( id_validation,
  id_sinp_occtax,
  date_ctrl,
  niv_val,
  typ_val,
  ech_val,
  peri_val,
  validateur,
  proc_vers,
  producteur,
  date_contact,
  procedure,
  proc_ref,
  comm_val)
SELECT
nextval('occtax.validation_observation_id_validation_seq'::regclass) AS id_validation,
o.id_sinp_occtax AS id_sinp_occtax,
o.validite_date_validation AS date_ctrl, -- Si le niveau de validation a été utilisé antérieurement lors du remplissage de la table occtax.observation plus haut pour le champ date_ctrl. Sinon, il faut renseigner une valeur fixe selon les indications de validation fournies par la tête de réseau ou le producteur pour ce jeu de données.
o.validite_niveau AS niv_val,
'M' AS typ_val, -- M = validation manuelle
'2' AS ech_val, -- Echelle de validation régionale (par les têtes de réseau).
-- S’il s’agit d’une validation par le producteur, indiquer '1'
-- S’il s’agit d’une validation nationale, indiquer '3'  --> fichiers du MNHN par ex
'1' AS peri_val, --convenu '1' (=périmètre minimal) avec les têtes de réseau (on ne valide à ce stade que l'occurrence de tel taxon, à tel endroit, à telle date)
(SELECT id_personne FROM occtax.personne WHERE(LOWER(identite) = 'sanchez mickaël' and id_organisme = 41)) AS validateur, -- le nom du validateur doit être adapté ici
(SELECT proc_vers FROM occtax.validation_procedure ORDER BY id DESC LIMIT 1) AS proc_vers, -- On récupère automatiquement le numéro de la dernière version du protocole de validation
NULL AS producteur,
NULL AS date_contact,
(SELECT procedure FROM occtax.validation_procedure ORDER BY id DESC LIMIT 1) AS procedure,
(SELECT proc_ref FROM occtax.validation_procedure ORDER BY id DESC LIMIT 1) AS proc_ref,
'Données validées avant import dans Borbonica par xxxxxxxxxxxxxxxx' AS comm_val -- Commentaire éventuel
FROM occtax.observation AS o
INNER JOIN fdw.l_faune_onf_2014_2018_observations AS t ON t.idorigine = o.id_origine
WHERE o.jdd_id IN ('T40895')
ON CONFLICT DO NOTHING
;

--  Validation automatique : lancer la fonction occtax.calcul_niveau_validite
-- On rafraîchit dans un premier temps la vue matérialisée vm_observation car la fonction de validation fait appel à cette vue
REFRESH MATERIALIZED VIEW occtax.vm_observation ;

SELECT occtax.calcul_niveau_validation(
        ARRAY['T40895'],
        (SELECT id_personne FROM personne WHERE identite='Administrateur Borbonica'),
        FALSE -- pas une simulation
);


-- 7.4 quelques vérifications : il s’agit de vérifier la bonne application de la validation automatique, et d’en assurer une synthèse pour intégration au rapport d’import et transmission au producteur

-- Calcul de statistiques
SELECT nn.code AS niveau_validite,
nn.valeur AS niveau_validite,
nt.valeur AS type_validite,
count(DISTINCT o.cle_obs) AS nb_obs
FROM (SELECT code, valeur FROM occtax.nomenclature WHERE champ='validite_niveau')nn
LEFT JOIN occtax.observation o ON nn.code=COALESCE(o.validite_niveau, '6')
LEFT JOIN occtax.validation_observation v ON v.id_sinp_occtax=o.id_sinp_occtax AND v.ech_val='2'  -- si on ne veut que les validations de niveau régional
LEFT JOIN (SELECT code, valeur FROM occtax.nomenclature WHERE champ='type_validation')nt ON nt.code=COALESCE(v.typ_val,'A')
WHERE o.jdd_id IN ('T40895')
GROUP BY nn.code, nn.valeur, nt.valeur
ORDER BY nn.code ;

-- Détail des critères de validation automatique utilisés sur le jdd
SELECT n.valeur AS niveau_validite,
        string_agg(DISTINCT t.lb_nom, ', ' ORDER BY t.lb_nom) AS taxons_concernes,
        v.comm_val,
        count(o.cle_obs) AS nb_obs,
        (count(o.cle_obs)::NUMERIC (8,1)/(SELECT count(cle_obs) FROM occtax.observation WHERE o.jdd_id IN ('T40895'))::NUMERIC (8,1))::NUMERIC (4,3) AS pourcentage -- attention au nb de données du jdd si > 1 000 000 ne fonctionne pas !
FROM occtax.observation o
LEFT JOIN occtax.validation_observation v USING(id_sinp_occtax)
LEFT JOIN occtax.nomenclature n ON n.code=v.niv_val AND champ='niv_val_auto'
LEFT JOIN taxon.taxref_valide t USING (cd_ref)
WHERE o.jdd_id IN ('T40895') AND ech_val='2' and typ_val='A'
GROUP BY n.valeur, v.niv_val, v.comm_val, o.jdd_id
ORDER BY v.niv_val, v.comm_val ;


------------------------------------
-- 8- Mise à jour des critères de sensibilité et de diffusion
-- 8.1 Mise à jour des critères de sensibilité

-- La fonction occtax.calcul_niveau_sensibilite calcule automatiquement dans la table occtax.observation les informations liées à la sensibilité des données. Ces informations sont issues de la table critere_sensibilite, elle-même découlant du référentiel de données sensibles téléchargeable à l’adresse suivante, pour information : http://www.naturefrance.fr/la-reunion/referentiel-de-sensibilite

SELECT occtax.calcul_niveau_sensibilite(
        ARRAY['T40895'],
        FALSE -- pas une simulation
);
-- Par défaut, pour les groupes taxonomiques non encore traités par le référentiel de données sensibles, on met ensuite une sensibilité de niveau m02 par mesure de sécurité (à terme, tous les groupes taxonomiques seront traités)

UPDATE occtax.observation o
SET
        sensi_date_attribution=now()::timestamp with time zone,
        sensi_niveau='m02',
        sensi_referentiel=(SELECT description FROM sensibilite_referentiel ORDER BY sensi_version_referentiel DESC LIMIT 1),
        sensi_version_referentiel=(SELECT sensi_version_referentiel FROM sensibilite_referentiel ORDER BY sensi_version_referentiel DESC LIMIT 1)
FROM taxon.taxref_valide t
WHERE o.cd_ref=t.cd_ref
        AND t.group2_inpn NOT IN ('Amphibiens', 'Mammifères', 'Oiseaux', 'Reptiles', 'Arachnides', 'Insectes', 'Gymnospermes', 'Ptéridophytes', 'Fougères', 'Angiospermes')
        AND NOT (t.habitat IN ('2','4') AND (lower(t.famille) IN ('atyidae', 'palaemonidae', 'sesarmidae', 'varunidae', 'portunidae') OR t.group2_inpn='Poissons')) -- poissons et macro-crustacés d'eau douce déjà traités
        AND jdd_id IN ('T40895')

-- On vérifie l'application de la sensibilité : liste des taxons dont certaines observations sont sensibles :
WITH n AS (
        SELECT code, valeur
        FROM occtax.nomenclature
        WHERE champ='sensi_niveau'
        ),

tax AS (
        SELECT o.cd_ref, t.lb_nom, t.nom_vern, count(cle_obs) AS nb_total_obs
        FROM occtax.observation o
        LEFT JOIN taxref_valide t USING(cd_ref)
        WHERE jdd_id IN ('T40895')
        GROUP BY o.cd_ref, t.lb_nom, t.nom_vern
        ORDER BY t.lb_nom
        )

SELECT o.cd_ref, tax.lb_nom, tax.nom_vern, o.nom_cite, sensi_niveau, n.valeur AS sensi_libelle, count(cle_obs) AS nb_obs, tax.nb_total_obs
FROM occtax.observation o
LEFT JOIN n ON n.code=o.sensi_niveau
LEFT JOIN tax ON o.cd_ref=tax.cd_ref
WHERE jdd_id IN ('T40895')
AND sensi_niveau <> '0'
GROUP BY o.cd_ref, tax.lb_nom, tax.nom_vern, o.nom_cite, sensi_niveau,  n.valeur, nb_total_obs
ORDER BY tax.lb_nom, tax.nom_vern ;


-- 8.2 Mise à jour des critères de diffusion

-- Vue qui rassemble à plat dans une seule entité la plupart des informations sur les observations, utilisée ensuite pour la diffusion des données sur www.borbonica.re
REFRESH MATERIALIZED VIEW occtax.vm_observation;

-- Vérification : niveau de diffusion appliqués aux données du jeu de données
WITH od AS (
	SELECT
	o.cle_obs,
	occtax.calcul_diffusion(o.sensi_niveau, o.ds_publique, o.diffusion_niveau_precision) AS diffusion
	FROM occtax.observation AS o
	WHERE o.jdd_id in ('T40895')
)
SELECT
	od.diffusion AS code_diffusion,
	CASE
		WHEN od.diffusion::TEXT ILIKE '%g%' THEN 'Diffusion grand public avec géométrie précise'
		WHEN od.diffusion::TEXT ILIKE '%m02%' THEN 'Diffusion grand public à la maille de 2 km'
		WHEN od.diffusion::TEXT ILIKE '%c%' THEN 'Diffusion grand public à la commune'
		WHEN od.diffusion::TEXT ILIKE '%m10%' THEN 'Diffusion grand public à la maille de 10 km'
		WHEN od.diffusion::TEXT ILIKE 'd%' THEN 'Diffusion grand public au département'
		WHEN od.diffusion is NULL THEN 'Pas de diffusion grand public'
	END AS libelle_diffusion,
	count(od.cle_obs) AS nb_obs
FROM od
GROUP BY diffusion
ORDER BY diffusion ;


------------------------------------
-- 9 Métadonnées sur l'action d'import (table jdd_import)

-- S’assurer avant que les organismes soient bien importés (=> 4.1 table organisme)

-- 9.1 acteur
-- généralement 2 acteurs :
        -- l'importateur dans la base SINP (VLT, JCN...)
        -- le gestionnaire de la BD d'origine

-- Si l’acteur n’est pas déjà renseigné dans la table gestion.acteur, il faut l’y rajouter selon le script suivant :
SELECT Setval('gestion.acteur_id_acteur_seq', (SELECT max(id_acteur) FROM gestion.acteur) );
INSERT INTO gestion.acteur
(id_acteur, nom, prenom, civilite, tel_1, tel_2, courriel, fonction, id_organisme, remarque, bulletin_information, service, date_maj)
VALUES
        (
        nextval('gestion.acteur_id_acteur_seq'::regclass),
        'HYPOLITE',
        'Alexandre',
        'M.',
        NULL, -- ou NULL
        NULL, -- ou NULL
        'alexandre.hypolite@developpement-durable.gouv.fr', -- ou NULL
        'Chargé de mission SINP', -- ou NULL
        (SELECT id_organisme FROM occtax.organisme WHERE sigle ='DEAL_May'),
        NULL, -- ou NULL
        FALSE,-- ou FALSE
        'Unité Biodiversité', -- ou NULL
        now()
        )
ON CONFLICT DO NOTHING;

-- AJOUTER AUSSI LE REFERENT POUR LE JDD
-- Selon la page https://inpn.mnhn.fr/espece/jeudonnees/40895
-- LARTIGUE Jeannette
INSERT INTO gestion.acteur
(id_acteur, nom, prenom, civilite, tel_1, tel_2, courriel, fonction, id_organisme, remarque, bulletin_information, service, date_maj)
VALUES
        (
        nextval('gestion.acteur_id_acteur_seq'::regclass),
        'LARTIGUE',
        'Jeannette',
        'Mme',
        NULL, -- ou NULL
        NULL, -- ou NULL
        'agencemayotte@onf.fr', -- ou NULL
        NULL, -- ou NULL
        (SELECT id_organisme FROM occtax.organisme WHERE sigle ='ONF'),
        NULL, -- ou NULL
        True,-- ou FALSE
        NULL, -- ou NULL
        now()
        )
ON CONFLICT DO NOTHING;


-- 9.2 jdd_import

SELECT Setval('occtax.jdd_import_id_import_seq', (SELECT max(id_import) FROM occtax.jdd_import ) );
INSERT INTO occtax.jdd_import (
        jdd_id,
        date_reception,
        date_import,
        nb_donnees_source,
        nb_donnees_import,
        date_obs_min,
        date_obs_max,
        libelle,
        remarque,
        acteur_referent,
        acteur_importateur
        )
SELECT
        'T40895' AS jdd_id,
        '2019-09-13'::DATE AS date_reception, -- A compléter en fonction de la date de réception des données (ie la date à laquelle les derniers éléments nécessaires à l’import ont été transmis par le producteur)
        now()::date AS date_import,
        (SELECT count(idorigine) FROM fdw.l_faune_onf_2014_2018_observations) AS nb_donnees_source,-- attention s'il y a plusieurs jdd il faut filtrer par JDD
        count(o.cle_obs) AS nb_donnees_import,
        min(date_debut) AS date_obs_min,
        max(date_fin) AS date_obs_max,
        '1er import en base de prod' AS libelle, -- Compléter. Il peut s’agir ici d’expliquer par exemple qu’il s’agit d’un réimport.
        'Rapport d''import v 1.0. Une des observation n''a pas été importée, car elle avait été rejetée par l''INPN et n''est donc pas présente dans l''export INPN.' AS remarque, -- Compléter. On peut préciser le nom du rapport d’import accompagnant le jdd, ou bien expliquer qu’il y a eu des échanges avec le producteur pour clarifier tel ou tel point.
        (SELECT id_acteur FROM gestion.acteur WHERE courriel = 'agencemayotte@onf.fr') AS acteur_referent, -- compléter à partir du nom de l’acteur référent pour le compte du producteur
        (SELECT id_acteur FROM gestion.acteur WHERE courriel = 'alexandre.hypolite@developpement-durable.gouv.fr') AS acteur_importateur
FROM occtax.observation AS o
WHERE jdd_id IN ('T40895')
;

-- Vérification
SELECT * FROM occtax.jdd_import WHERE jdd_id in ('T40895') ;

-- Requête permettant d’obtenir les caractéristiques principales de l’import, utiles ensuite pour renseigner le rapport d’import :
SELECT  id_import,
                i.libelle AS libelle_import,
                jdd.jdd_cadre,
                -- CONCAT('https://inpn.mnhn.fr/mtd/cadre/export/xml/GetRecordById?id=', jdd.jdd_cadre) AS fiche_ca,
                CONCAT('https://inpn.mnhn.fr/espece/cadre/', replace(jdd.jdd_cadre, 'T', '')) AS fiche_ca, -- URL publique de la fiche une fois qu’elle a également été intégrée au SINP national
                i.jdd_id,
                jdd.jdd_code,
                jdd.jdd_description,
                -- CONCAT('https://inpn.mnhn.fr/mtd/cadre/jdd/export/xml/GetRecordById?id=', jdd.id_sinp_jdd) AS fiche_jdd,
                CONCAT('https://inpn.mnhn.fr/espece/jeudonnees/', replace(jdd.jdd_id, 'T', '')) AS fiche_jdd, -- URL publique de la fiche une fois qu’elle a également été intégrée au SINP national
                i.date_reception,
                i.date_import,
                referent.prenom || ' ' || referent.nom AS referent,
                importateur.prenom || ' ' || importateur.nom AS importateur,
                i.remarque
FROM occtax.jdd_import i
LEFT JOIN occtax.jdd USING (jdd_id)
LEFT JOIN gestion.acteur referent ON i.acteur_referent=referent.id_acteur
LEFT JOIN gestion.acteur importateur ON i.acteur_importateur=importateur.id_acteur
WHERE jdd_id in ('T40895')
ORDER BY jdd_id;


------------------------------
-- PARTIE IV : Création d’une demande d’accès aux données importées
------------------------------

------------------------------------
-- 1. Import dans la table organisme
-- Import dans la table organisme
-- on vérifie si l'organisme y figure déjà, et si non on le rajoute
SELECT * FROM occtax.organisme WHERE nom_organisme='zzz';
--
-- cf partie I 2 + II 4.1 -> voir si les organismes ont été importés

------------------------------------
-- 2. Import dans la table acteur
-- on vérifie au préalable si l'acteur y figure déjà, et si non on le rajoute

-- si import Cf partie III 10.1 acteur


------------------------------------
-- 3. Création de l'utilisateur via l'interface d'administration de Lizmap

-- créer l'utilisateur via l'interface d'administration de Lizmap -> admin -> utilisateurs -> créer
-- mdp pour le profil  XXX - x@y.fr
--
-- On peut prendre comme règle pour les utilisateurs de concaténer la première lettre du prénom avec le nom, par exemple mdouchin pour Michaël Douchin.
-- Le placer ensuite dans un profil avec droits de voir les données brutes (en l'occurrence : en plus de users, groupe par défaut, il faut le placer dans le groupe naturaliz_profil_1)


------------------------------------
-- 4. Import dans la table demande

-- critère additionnel "dynamique" - ex pour le PNRun

SELECT Setval('gestion.demande_id_seq', (SELECT max(id) FROM gestion.demande) );

INSERT INTO demande (
        usr_login,
        id_acteur,
        id_organisme,
        motif,
        type_demande,
        date_demande,
        commentaire,
        date_validite_min,
        date_validite_max,
        cd_ref,
        group1_inpn,
        group2_inpn,
        libelle_geom,
        validite_niveau,
        geom,
        motif_anonyme,
        statut,
        detail_decision,
        critere_additionnel
        )
SELECT
    'pnrun_plus' AS usr_login,
    (SELECT id_acteur FROM acteur WHERE courriel = 'jean-cyrille.notter@reunion-parcnational.fr') AS id_acteur,
    (SELECT id_organisme FROM organisme WHERE nom_organisme ILIKE 'Parc national de La Réunion') AS id_organisme,
    'Accès du producteur aux données qu''il a fournies' AS motif,
    'AP' AS type_demande,
    now()::date AS date_demande,
    'Accès du producteur à ses propres données' AS commentaire,
    now()::date AS date_validite_min,
    now() + '2 year'::interval AS date_validite_max,
    NULL AS cd_ref,
    NULL AS group1_inpn,
    NULL AS group2_inpn,
    'Département de La Réunion sans ZEE' AS libelle_geom,
    ARRAY['1', '2', '3', '4', '5', '6'] AS      validite_niveau, -- {1,2,3,4,5,6}
    (SELECT geom FROM sig.departement WHERE code_departement='974') AS geom,
        FALSE AS motif_anonyme,
        'Acceptée' AS statut,
        'Accès systématique d''un producteur à ses données' AS detail_decision,
    'jdd_code IN (WITH jdd AS (
        SELECT jsonb_array_elements(jdd.ayants_droit) ->> ''id_organisme''::text AS id_organisme,
            jdd.jdd_code
           FROM occtax.jdd)
        SELECT jdd_code
                        FROM jdd
                        WHERE id_organisme = (SELECT id_organisme FROM organisme WHERE nom_organisme ILIKE ''Parc national de La Réunion'')::text)' AS critere_additionnel
ON CONFLICT DO NOTHING
;

-- "AP" => "Accès producteur"
-- "AT" => "Accès tête de réseau"
-- "AU" => "Autre"
-- "CO" => "Conservation"
-- "EI" => "Étude d'impact"
-- "GM" => "Gestion des milieux naturels"
-- "MR" => "Mission régalienne"
-- "PS" => "Publication scientifique"
-- "SC" => "Sensibilisation et communication"

------------------------------------
-- Vérification
SELECT *
FROM gestion.demande
WHERE id_acteur = (SELECT id_acteur FROM acteur WHERE courriel = 'x@y.fr')
AND type_demande = 'AP'
;


------------------------------
-- PARTIE V : Nettoyage et stockage du rapport d'import + Suivi de l'import
------------------------------

------------------------------------
-- 1. Nettoyage des tables provisoires
-- on supprime toutes les tables provisoires créées pour l'import (liste des tables à adapter selon le jeu de données si besoin)

DROP TABLE fdw.l_faune_onf_2014_2018_observations ;
DROP TABLE fdw.l_faune_onf_2014_2018_organismes ;
DROP TABLE fdw.l_faune_onf_2014_2018_acteurs ;

------------------------------------
-- 2. Stockage du rapport d'import

-- Penser à créer sur l'espace de stockage Alfresco un dossier spécifique au jeu de données importé et à placer dans ce dossier
-- (i)     le rapport d'import relu par le producteur (avec toutes ses annexes)
-- (ii)    les données sources transmises par le producteur (différents fichiers potentiellement) ainsi que copie des mails utilisés pour l'import (échanges avec le producteur pouvant apporter des informations complémentaires aux seules données source)


------------------------------------
-- 3. Suivi de l'import
------------------------------------
-- S'il n'y a qu'un JDD prendre le jdd_code pour "nom_jdd", sinon, donner un nom au lot
------------------------------------
-- NB préparation des fdw afin de pouvoir voir certaines données en "prod" du serveur de "dev"

-- ----------------     SERVER bdd_dev
-- IMPORT FOREIGN SCHEMA occtax
-- LIMIT TO ( jdd_import )
-- FROM SERVER bdd_dev INTO occtax_dev;
------------------------------------

--- ATENTION !!!! -> droits postgres nécessaires pour utiliser les FDW
--> en "dev" comme en "prod" il faut aller sur la BD "prod" : le fichier à maj est en "prod"

-------------------------------------
--> A FAIRE A L'IMPORT EN DEV SUR LA BASE DE PROD (droits postgres)
-------------------------------------
-- s'il n'y a qu'un JDD

UPDATE divers.suivi_imports
SET date_import_dev = (SELECT date_import FROM occtax.jdd_import WHERE jdd_id = 'T40895')
WHERE jdd_id ='{T40895}';



-- s'il y a plusieurs JDD, en choisir un pour la rqt de la date_import

-------------------------------------
--> A FAIRE A L'IMPORT EN PROD SUR LA BASE DE PROD
-------------------------------------
-- s'il n'y a qu'un JDD
UPDATE divers.suivi_imports
SET date_import_prod = (SELECT date_import from occtax.jdd_import where jdd_id = 'T40895')
WHERE jdd_id ='{40895}';
-- s'il y a plusieurs JDD, en choisir un pour la rqt de la date_import

END ;
COMMIT;
-- JCN - VLT  V 6.0 – le 2020-06
