-- SCRIPT MODELE POUR IMPORT DE DONNEES DANS LA BASE DE DONNEES SINP - BORBONICA
   -----------------------------------------------------------------------------

-- VERSION 6 finalisée pour août 2020 - Jean-Cyrille Notter (PNRun)-  relecture/corrections/ajouts Valentin Le Tellier (DEAL 974) V 6.0

---------------------------------------------------------------------------------------
-- script pour modèle de saisie sous forme de tableur d’un jeu de données fictif dont le code serait pnrun_data_2018 et le jdd_id IN ('99999')

--> le jdd_code et le jdd_id sont donc les variables à remplacer de manière automatique pour adapter le code
--> jdd IN ('99999') replacer (par ex) par ('12345','67890')

--> (ARRAY['99999']) replacer (par ex) par (ARRAY['12345','67890'])

--> pour INSERT INTO occtax.jdd le faire au cas pas cas

---------------------------------------------------------------------------------------
-- Je conseille de lire ce script puis de l'enregistrer en le personnalisant et en supprimant un grand nombre de commentaires
---------------------------------------------------------------------------------------
-- coordonnées en xy
-- coordonnées sous forme wkt (en commentaire)
-- Pour l'import, il est utile de faire appel au standard occurrences de taxons mis en oeuvre dans Borbonica, en particulier pour les champs contrôlés par des listes de valeurs fermées.
-- Au 17/09/2018, la version mise en oeuvre est la version 1.2.1 consultable ici : http://standards-sinp.mnhn.fr/occurrences_de_taxons_v1-2-1/
-- les métadonnées sont à saisir sur https://inpn.mnhn.fr/mtd/

------------------------------
-- PLAN DU DOCUMENT :

-- PREAMBULE : Fonctionnement de Naturaliz et lien avec l'organisation du SINP

-- PARTIE 0 : Remplissage de la table divers.suivi_imports
-- ------------------------------------------------

-- PARTIE I : Import des données source
-- ------------------------------------------------
-- 		1 Personnes et organismes
-- 			1.1 - organismes
-- 			1.2 - personnes -> observateurs
-- 		2 - Métadonnées
--			2.0 import des tables brutes de métadonnées
-- 			2.1 cadre
-- 			2.2 jdd
-- 		3 - Import des observations
-- 		4 - Import des autres tables éventuelles (1)
--		5 - Import des autres tables éventuelles (2)
-- 		6 - modifications éventuelles d’erreurs détectées et confirmées par le producteur
--		– Il peut s’agir de mettre à jour (UPDATE) certains champs erronés.
-- 		- Remplacement des valeurs '' par des valeurs NULL pour nettoyer le jdd
-- 		7 - Analyse du jeu de données à partir de la fonction jdd_analyse

-- PARTIE II : Import des taxons qui ne sont pas dans Taxref et liens entre les identifiants de taxons locaux et cd_nom du TAXREF
-- ------------------------------------------------
-- 		1 - Vérification des cdnom du fdw
-- 		2 - Complément si besoin de taxref_local_source
-- 		3 - Complément si besoin de taxref_local
-- 		4 - Mise à jour des vues matérialisées liées à Taxref

-- PARTIE III : Import des données dans occtax
-- ------------------------------------------------
-- 		1 - Suppression des données avant réimport
-- 		2 - Import dans la table occtax.observation
-- 		3 - Vidage puis remplissage de lien_observation_identifiant_permanent
-- 		4 - Renseignement des personnes associées aux observations
-- 			4.0 vérifications préalables
-- 			4.1 table organisme
-- 			4.2 table personne
-- 			4.3 table observation_personne
-- 		5 - Rattachement géographique
-- 		6 - Enrichissement de la donnée avec des paramètres calculés dans Borbonica
-- 		7 - Validation des données
-- 			7.1 Cohérence et conformité
-- 			7.2 Vérification des doublons
-- 			7.3 Validation scientifique (= sur le fond) des données
-- 			7.4 quelques vérifications
-- 		8 - Mise à jour des critères de sensibilité et de diffusion
-- 			8.1 Mise à jour des critères de sensibilité
-- 			8.2 Mise à jour des critères de diffusion
-- 		9 - Métadonnées sur l'action d'import (table jdd_import)
-- 			9.1 acteur
-- 			9.2 jdd_import

-- PARTIE IV : Création d’une demande d’accès aux données importées
-- ------------------------------------------------
-- 		1 - Import dans la table organisme
-- 		2 - Import dans la table acteur
-- 		3 - Création de l'utilisateur via l'interface d'administration de Lizmap
-- 		4 - Import dans la table demande

-- PARTIE V : Nettoyage et stockage du rapport d'import + Suivi de l'import
-- ------------------------------------------------
-- 		1 - Nettoyage des tables provisoires
-- 		2 - Stockage du rapport d'import
-- 		3 - Suivi de l'import


------------------------------
-- PREAMBULE : fonctionnement de Naturaliz et lien avec l'organisation du SINP
------------------------------
-- Le fonctionnement de Naturaliz (Borbonica à La Réunion, Karunati en Guadeloupe, Mayotte (en cours de déploiement)) est basé sur plusieurs outils :
		-- - une base de données spatiale PostgreSQL/PostGIS, dans une version de dev (diffusée sur dev.borbonica.re) et une version de prod (diffusée sur www.borbonica.re)
		-- - deux applications internet accessibles via dev.borbonica.re (permettant de tester les nouveaux développements avant mise en production) et www.borbonica.re (site officiel accessible au grand public et aux professionnels). Ces applications sont basées sur des projets QGIS transformés grâce au plugin Lizmap.
		-- - un site Internet www.borbonica.re en cours de développement côté La Réunion (échéance : août 2019) pour y intégrer en plus de l'application ci-dessus une page d'accueil, une documentation utilisateur (tutoriels)...
		-- - un Gitlab permettant d'échanger sur les développements en cours de l'application et contenant une doc administrateurs (https://projects.3liz.org/clients/naturaliz-reunion). Le Gitlab est partagé depuis 2019 entre 3Liz, PNG, DEAL Guadeloupe, PNRun et DEAL Réunion.
		-- - l'application nationale de saisie de métadonnées de l'INPN, qui permet de compléter les informations très basiques de métadonnées déjà renseignées dans la base de données (tables cadre, jdd et jdd_import)
		-- - un FTP stockant notamment les bases de données, les projets QGIS utilisés et les autres éléments requis pour les applications web
		-- - le FTP et le site Internet sont hébergés sur le serveur localisé au Port payé par le PNRun et la DEAL à Cahri. Le Gitlab est stocké sur les serveurs de 3Liz, prestataire en charge du développement de Naturaliz pour La Réunion et la Guadeloupe.

-- L'intégration de nouvelles données naturalistes dans Naturaliz repose sur plusieurs opérations successives reposant sur ces outils et décrites dans le présent document. Elle permet in fine de :
		-- - intégrer des données issues de formats informatiques divers (tableur, SIG...) dans une base de données PostgreSQL
		-- - formater ces données dans le format standard SINP "occurrence de taxon" mis en oeuvre dans Naturaliz
		-- - tester la validité des données
		-- - les enrichir avec certains paramètres calculés automatiquement (altitude, milieu naturel concerné)
		-- - valoriser les données sous la forme de fiches de métadonnées sur le site national de l'INPN

-- Les données sont récoltées auprès de producteurs en particulier dans le cadre de l'adhésion à la charte régionale du SINP. Chaque producteur s'engage à verser ses données historiques au moment de l'adhésion puis les nouvelles données acquises annuellement à une date fixe.

-- L'intégration de données de producteurs nécessite des échanges avec le producteur a minima à ces étapes clés :
		-- - à réception des données : s'assurer que la donnée est complète (idéalement en s'appuyant sur le format standard de saisie publié sur http://www.naturefrance.fr/la-reunion/format-standard-de-donnees). Lever les doutes éventuels sur l'interprétation de certains points
		-- - une fois l'import réalisé en base de développement : transmettre le rapport d'import provisoire et les informations de connexion au producteur. Lui demander validation du rapport et test des données sur dev.borbonica.re grâce à ses identifiants
		-- - une fois l'import réalisé en base de production : transmettre le rapport d'import définitif et les identifiants créés sur www.borbonica.re

-- Le détail des différentes phases d'import est décrit dans le document "qui fait quoi des administrateurs" validé le 25/04/2017 par la DEAL et le PNRun, en particulier dans son annexe 2. Des informations plus détaillées sur le fonctionnement du SINP à La Réunion sont accessibles sur le portail régional http://www.naturefrance.fr/la-reunion.

/*Pour info et mémoire : qq rq de Solène Robert (MNHN)

    La date de dernière modification n'est pas renseignée lorsqu'il n'y a pas eu de modification.
    Pour la date de transformation, c'est un attribut que nous envisageons de supprimer dans la prochaine version du standard (à débattre en GT Standard).

	En toute logique, quand il n'y a pas de dénombrement, il n'y a pas non plus d'objet dénombrement. Je préconise donc dans ce cas de laisser null.
=> 	denombrement_min = denombrement_max = objet_denombrement = type_denombrement = NULL*/

-----------------------------------------------------------------------
BEGIN;
SET search_path TO taxon, occtax, gestion, sig, fdw, divers, public;


------------------------------
-- PARTIE 0 : Remplissage de la table divers.suivi_imports
------------------------------

--  à la reception d'un nouveau jeu de données (JDD), remplir "manuellement" ou en utilisant le morceau de script ci-dessous la table divers.suivi_imports de la base de données lizmap => production (n'existe pas en dev)
-- ceci n'est fait qu'une fois par jdd et donc à la réception ou à l'import en dev
--> aller sur la base de Prod

SELECT Setval('divers.suivi_imports_id_seq1', (SELECT max(id) FROM divers.suivi_imports) );

INSERT INTO divers.suivi_imports
 (
	nom_jdd,
	decription_detaillee,
	date_reception,
	date_import_dev,
	date_import_prod,
	nb_donnees,
	importateur_initiales,
	commentaire,
	jdd_id
)
SELECT
	'pnrun_data_2018' AS nom_jdd, --> S'il n'y a qu'un JDD prendre le jdd_code pour "nom_jdd", sinon, donner un nom au lot
	'blablabla' AS decription_detaillee, --> S'il n'y a qu'un JDD prendre le jdd_description pour "nom_jdd", sinon, décrire lot
	'2018-12-01' AS  date_reception,
	NULL AS date_import_dev,
	NULL AS date_import_prod,
	'5555' AS nb_donnees, -- Nombre total de données dans le fichier source fourni par le producteur
	'JCN' AS importateur_initiales, -- 'VLT' AS importateur_initiales,
	'blablabla' AS commentaire,
	ARRAY['99999']-- null AS jdd_id
ON CONFLICT DO NOTHING
;


------------------------------
-- PARTIE I : Import des données source
------------------------------

-- rq : éviter les caractères spéciaux + majuscules + espaces dans les noms de champs des tables à importer qui rendent les manipulations plus lourdes sous PostgreSQL (il faut alors mettre entre "). Il est recommandé de renommer les champs en conséquence et de conserver dans une table la correspondance entre anciens et nouveaux noms (par exemple dans le fichier « description_donnees_source » annexé au rapport d’import.
-- Avant l'import, penser à enregistrer le fichier en CSV, UTF8
-- le codage du fichier est primordial UTF8 !!!

------------------------------------
-- 1 Personnes et organismes

-- 1.1 - organismes
-- Les organismes et surtout l'id_organisme sont utilisés dans les métadonnées, dans la table des personnes...
-- Si de nouveaux organismes ont été saisis en utilisant le fichier modèle de saisie, exporter les lignes correspondantes de l'onglet organismes dans un fichier spécifique -> organismes.csv.

-- Les noms d’organisme doivent être écrits en intégrant les éventuels accents (y compris sur les majuscules), et en n’abusant pas des majuscules (voir la manière dont sont nommés les organismes déjà intégrés à occtax.organisme)


DROP TABLE IF EXISTS fdw.pnrun_data_2018_organismes;

CREATE TABLE fdw.pnrun_data_2018_organismes (
	id_organisme	text, --Identifiant de l'organisme.
	nom_organisme	text, --Nom de l'organisme.  --ATTENTION = orgobs
	sigle	text, --Sigle de la structure
	responsable	text, --Nom de la personne responsable de la structure, pour les envois postaux officiels
	adresse1	text, --Adresse de niveau 1
	adresse2	text, --Adresse de niveau 2
	cs	text, --Courrier spécial
	cp	text, --Code postal
	commune	text, --Commune
	cedex	text --CEDEX
);

COPY fdw.pnrun_data_2018_organismes FROM '/tmp/organismes.csv'
HEADER CSV DELIMITER ',' ;

-- SELECT * FROM fdw.pnrun_data_2018_organismes ;

-- NB : Les organismes nouvreaux sont importés dans la base de données -> III 4.1 : table organisme
-- Faire cet import si nécessaire avant l'import des observateurs afin de pouvoir compléter manuellement le "id_organisme" de la table "acteur"

------------------------------------
-- 1.2 - personnes -> observateurs
DROP TABLE IF EXISTS fdw.pnrun_data_2018_acteurs;
CREATE TABLE fdw.pnrun_data_2018_acteurs (
	nom	text,
	prenom	text,
	orgobs	text,
	id_organisme	text,
	mail	text,
	identite	text,
	anonyme	text
) ;

COPY fdw.pnrun_data_2018_acteurs FROM '/tmp/acteurs.csv'
HEADER CSV DELIMITER ',' ;

-- SELECT * FROM fdw.pnrun_data_2018_acteurs;


------------------------------------
-- 2 Métadonnées -> cadre et JDD

-- Remplissage des tables occtax.cadre et occtax.jdd contenant les métadonnées
-- Chaque jeu de données doit être associé à une fiche de métadonnées de jdd spécifique, et une fiche de cadre d'acquisition qui peut être partagée avec d'autres jdd.
-- les métadonnées sont à saisir sur https://inpn.mnhn.fr/mtd/

--Pour rappel :
------------------------------
-- métadonnées pour les tables occtax.cadre et occtax.jdd
------------------------------
-- exemple de JDD:
-- Identifiant du cadre d'acquisition : T13407
-- Libellé du cadre d'acquisition : Trucs de La Réunion
-- Code du jeu de données : T99999
-- Libellé du jeu de données : Observations faites en 2018 par PNRun
-- Date de création : 18/02/2019
-- Nom du créateur : sig@reunion-parcnational.fr
-- Date de mise à jour : 18/02/2019
-- Nom de l'opérateur de la mise à jour : toto
-- 80BFF849-2F1E-4F3B-E053-2614A8C0E4BD
-- cadre  = 6386AA2E-7590-5FE3-E053-2614A8C00573
-- Rq : cadre_id (occtax.cadre) correspond à jdd_cadre (occtax.jdd)


-- 2.0 import des tables brutes de métadonnées
-- -> pour des livraisons à multiples CA et JDD -> cf 2e exemple pour l'import du CA et du JDD

DROP TABLE IF EXISTS fdw.ca_pnrun_data_2018 ;

CREATE TABLE fdw.ca_pnrun_data_2018 (
	cadre_id	text,
	cadre_uuid	text,
	libelle	text,
	description	text,
	date_lancement	text,
	date_cloture	text,
	m_ouvrage	text,
	m_oeuvre	text,
	code_m_ouvrage	text,
	code_m_oeuvre	text
) ;

COPY fdw.ca_pnrun_data_2018 FROM '/tmp/CA_pnrun_data_2018.csv'
HEADER CSV DELIMITER ',' ;


DROP TABLE IF EXISTS fdw.jdd_pnrun_data_2018 ;

CREATE TABLE fdw.jdd_pnrun_data_2018 (
	jdd_cadre	text,
	jdd_id	text,
	jdd_code	text,
	jdd_description	text,
	id_sinp_jdd	text,
	jdd_libelle	text,
	date_minimum_de_diffusion	text,
	m_ouvrage	text,
	m_oeuvre	text,
	code_m_ouvrage	text,
	code_m_oeuvre	text
) ;

COPY fdw.jdd_pnrun_data_2018 FROM '/tmp/JDD_pnrun_data_2018.csv'
HEADER CSV DELIMITER ',' ;


-- 2.1 cadre
-- s'il s'agit d'un nouveau cadre de saisie de données
-- Il est recommandé au préalable d'indiquer ici la liste des organismes à associer au cadre d'acquisition et au jeu de données, ainsi que leur id_organisme. Cela facilitera l'intégration dans les tables CA et JDD. Il faut bien faire attention au petit décalage qui peut exister entre les id_organisme en dév et prod. Il est conseillé de vérifier en amont si ce décalage exsiste pour penser le cas échéant à l'adapter lors de l'import en prod.

-- vérifier le id_organisme :
SELECT id_organisme FROM organisme WHERE sigle='TOTO' -- par ex
--

INSERT INTO occtax.cadre
    (cadre_id, cadre_uuid, libelle, description, ayants_droit, date_lancement, date_cloture)
SELECT
	'13407' AS cadre_id, -- ce champ est fourni par l'application nationale de métadonnées où il s'intitule "Identifiant du cadre d'acquisition",
	'76EFAEAB-7FA6-70A1-E053-2614A8C07E17' AS cadre_uuid, -- ce champ est fourni par l'application nationale de métadonnées où il s'intitule "Identifiant du cadre d'acquisition"
	'données de toto' AS libelle, -- nom défini par l'importateur, correspondant au champ "Libellé du cadre d'acquisition" de l'application nationale
	'données de toto récoltées par jour de pluie' AS description, -- nom défini par l'importateur, correspondant au champ "Description" de l'application nationale
	'[
		{"role": "Maître d''ouvrage",
		"id_organisme": 999},
		{"role": "Maître d''oeuvre",
		"id_organisme": 999}
	]'::jsonb AS ayants_droit,
		-- Valeurs possibles : Maître d''ouvrage, Maître d''oeuvre, Autre...
		-- compléter avec l’id_organisme issu de la table organisme
	'2019-01-01'::date AS date_lancement, -- défini par l'importateur, correspondant au champ du même nom de l'application nationale
	'2019-12-31'::date AS date_cloture -- défini par l'importateur, correspondant au champ du même nom de l'application nationale
WHERE NOT EXISTS (SELECT cadre_id FROM occtax.cadre WHERE cadre_id = '13407');

-- SELECT * FROM occtax.cadre ORDER BY cadre_id ;

-- Si le cadre existe déjà :
-- il faut alors mettre à jour si besoin les champs pour que le cadre soit cohérent avec les nouvelles données apportées par le nouveau jdd importé (en particulier date_lancement, date_cloture, ayants_droit)


INSERT INTO occtax.cadre
    (cadre_id, cadre_uuid, libelle, description, ayants_droit, date_lancement, date_cloture)
SELECT
	cadre_id,
	cadre_uuid,
	libelle,
	description,
	json_build_array(
	json_build_object(
		'role', 'Maître d''ouvrage',
		'id_organisme', code_m_ouvrage::integer),
	json_build_object(
		'role', 'Maître d''oeuvre',
		'id_organisme', code_m_oeuvre::integer)
	)::jsonb AS ayants_droit,
	date_lancement,
	date_cloture
FROM fdw.ca_pnrun_data_2018;


-- 2.2 jdd
-- pour le id_sinp_jdd et jdd_id, les récupérer sur l'application nationale de gestion des métadonnées
-- https://inpn.mnhn.fr/mtd/ qu'il faut remplir au préalable.
-- Chaque jeu de données doit être associé à une fiche de métadonnées de jdd spécifique, et une
-- fiche de cadre d'acquisition qui peut être partagée avec d'autres jdd)

INSERT INTO occtax.jdd
    (jdd_id, jdd_code, jdd_description, id_sinp_jdd, jdd_cadre, ayants_droit, jdd_libelle, date_minimum_de_diffusion)
SELECT
  	'99999' AS jdd_id,-- ce champ est fourni par l'application nationale de métadonnées où il s'intitule "ID"
  	'pnrun_data_2018' AS jdd_code,-- nom défini par l'importateur, correspondant au champ "Libellé court" de l'application nationale. Le nom du jeu de données doit être suffisamment explicite en transcrivant la thématique et/ou le nom du producteur et/ou la date d'export - ajouter date et producteur si besoin
	'Inventaire de la Flore patrimoniale dans le Coeur du Parc national réalisé en 2018' AS jdd_description,-- nom défini par l'importateur, correspondant au champ "Description" de l'application nationale. Le nom doit être le plus intelligible possible possible pour un utilisateur extérieur. Il doit notamment préciser la période temporelle couverte par les données, en particulier pour permettre de différencier différents jeux de données successifs d'un même cadre d'acquisition.
	'76EFAEAB-7FA7-70A1-E053-2614A8C07E17' AS id_sinp_jdd,-- ce champ est fourni par l'application nationale de métadonnées où il s'intitule "Identifiant SINP du jeu de données :"
 	'13407' AS jdd_cadre, -- ce champ est fourni par l'application nationale de métadonnées où il s'intitule "Identifiant du cadre d'acquisition" (fiche cadre d'acquisition). C’est une clef étrangère vers cadre.cadre_id
	'[
		{"role": "Maître d''ouvrage",
		"id_organisme": 999
		},
		{"role": "Maître d''oeuvre",
		"id_organisme": 999
		}
	]'::jsonb AS ayants_droit,
	'Observations opportunistes de dahuts (PNRun, 2015-2018)' AS jdd_libelle,  -- libellé court du jeu de données, qui apparaîtra notamment dans le menu de recherche de jdd sur Borbonica et doit donc être le plus intelligible possible pour un utilisateur extérieur. jdd_libelle est construit ainsi : [Suivi/inventaire/observations...de] [groupe/espèce] [éventuellement lieu] ([Ayants-droits indiqués pour le jdd], [export mm/aaaa s'il s'agit de données historiques issues d'un cadre pérenne] [année début - année fin dans les autres cas]
	'2025-01-01'::date AS date_minimum_de_diffusion -- exemple ou NULL -> pour certains JDD en cas de publication scientifique à la demande du producteur
WHERE NOT EXISTS (SELECT jdd_id FROM occtax.jdd WHERE jdd_id = '99999');


INSERT INTO occtax.jdd
    (jdd_id, jdd_code, jdd_description, id_sinp_jdd, jdd_cadre, ayants_droit, jdd_libelle, date_minimum_de_diffusion)
SELECT
	jdd_id,
	jdd_code,
	jdd_description,
	id_sinp_jdd,
	jdd_cadre,
	json_build_array(
		json_build_object(
			'role', 'Maître d''ouvrage',
			'id_organisme', code_m_ouvrage::integer),
		json_build_object(
			'role', 'Maître d''oeuvre',
			'id_organisme', code_m_oeuvre::integer)
	)::jsonb AS ayants_droit,
	jdd_libelle,
	null AS date_minimum_de_diffusion
FROM fdw.jdd_pnrun_data_2018;


-- SELECT * FROM occtax.jdd ORDER BY jdd_code ;

------------------------------------
-- 3 - import des observations
DROP TABLE IF EXISTS fdw.pnrun_data_2018_observations ;

CREATE TABLE fdw.pnrun_data_2018_observations (
	idorigine	text, --idOrigine
	jdd_id	text, --jddid
	statobs	text, --statObs
	nomcite	text, --nomCite
	cdnom	text, --cdNom
	observateur_1	text,
	observateur_2	text,
	observateur_3	text,
	denbrmin	text, --denbrMin
	denbrmax	text, --denbrMax
	objdenbr	text, --objDenbr
	typdenbr	text, --typDenbr
	comment	text,
	datedebut	text, --dateDebut
	datefin	text, --dateFin
	x	text, -- à mettre en commentaire si coordonnées en wkt
	y	text, -- à mettre en commentaire si coordonnées en wkt
--	wkt text
	natobjgeo	text, --natObjGeo
	precisgeo	text, --precisGeo
	altmoy	text, --altMoy
	obsdescr	text, --obsDescr
	refbiblio text, --refBiblio
	obsmeth	text, --obsMeth
	ocetatbio	text, --ocEtatBio
	ocnat	text, --ocNat
	ocsex	text, --ocSex
	ocstade	text, --ocStade
	ocstatbio	text, --ocStatBio
	preuveoui	text, --preuveOui
	preuvnum	text, --preuvNum
	preuvnonum	text, --preuvNoNum
	obsctx	text, --obsCtx
	statsource	text, --statSource
	difnivprec	text, --difNivPrec
	dspublique	text, --dSPublique
	ocmethdet	text --ocMethDet
) ;

COPY fdw.pnrun_data_2018_observations FROM '/tmp/observations.csv'
HEADER CSV DELIMITER ',' ;
-- Le délimiteur ',' peut parfois poser soucis s’il est présent dans les champs. Essayer alors un autre délimiteur en recourant à un caractère peu commun  (par exemple '$').

-- Création d’une clef primaire :
-- Cela permet d’accélérer les requêtes et s’avère indispensable pour permettre une utilisation correcte de la table lien_identifiant_permanent, en particulier en cas de ré-import. Si le jeu de données initial ne comprend pas d’identifiant d’origine unique, il faut soit utiliser plusieurs champs pour créer la clef primaire, soit créer un champ de toute pièce (par exemple un serial pour remplir le champ idorigine. Le producteur doit en être informé afin qu’il puisse utiliser cet identifiant pour l’avenir).

ALTER TABLE fdw.pnrun_data_2018_observations ADD CONSTRAINT pk_pnrun_data_2018_observations PRIMARY KEY (idorigine) ;  -- la clé primaire nous évite la création a posteriori d'un index

-- SELECT * FROM fdw.pnrun_data_2018_observations ;

------------------------------------
-- 4 - import des autres tables éventuelles : obs complémentaires, tables pivots, table taxref_local (cf modèle proposé si nécessaire)...

------------------------------------
-- 5 - import des autres tables éventuelles : obs complémentaires, tables pivots, table taxref_local (cf modèle proposé si nécessaire)...

------------------------------------
-- 6 - modifications éventuelles d’erreurs détectées et confirmées par le producteur
--		– Il peut s’agir de mettre à jour (UPDATE) certains champs erronés.

------------------------------------
-- 7 - Analyse du jeu de données à partir de la fonction jdd_analyse
-- La fonction permet de calculer et stocker les valeurs uniques de chaque champ dans la table fdw.jdd_analyse
-- Le résultat de la vue fdw.v_jdd_analyse peut ensuite être utilisé dans le rapport d'import (fichier « description_donnees_source » annexé au rapport d’import) et pour faciliter le formatage des données

-- Nettoyage du jdd : suppression des espaces en bout de chaîne et remplacement des valeurs '' par des valeurs NULL
SELECT divers.nettoyage_valeurs_null_et_espaces('pnrun_data_2018_observations') ;

SELECT divers.analyse_jdd ('pnrun_data_2018_observations', 100) ; -- évolution de la fonction :
-- le 1er argument est le nom de la table à analyser, qui doit être dans le schéma fdw. Le 2ème argument correspond au nombre maximum de valeurs différentes que l'on souhaite afficher dans l'analyse d'un champ
-- exemple avec 100 valeurs uniques listés
SELECT * FROM divers.v_jdd_analyse ;


-------------------------------------------------------------------------------------
-- PARTIE II : import des taxons qui ne sont pas dans Taxref et liens entre les identifiants de taxons locaux et cd_nom du TAXREF
-------------------------------------------------------------------------------------


-- 1 - Vérification des cdnom du fdw
-- Il s’agit de vérifier si le rattachement taxonomique a bien été effectué. Pour cela, on vérifie si le nomcite est cohérent avec le nom_complet renvoyé par Taxref. La vérification est manuelle et peut être facilitée en cas de nombre

SELECT r.nomcite, r.cdnom, t.cd_ref, r.cdnom::integer - t.cd_ref::integer AS diff, t.nom_vern, t.nom_complet, t.nom_valide, t.rang, t.reu
FROM fdw.pnrun_data_2018_observations r
LEFT JOIN taxon.taxref_consolide_non_filtre t ON t.cd_nom=r.cdnom::INTEGER
-- WHERE t.cd_nom IS NULL-- en décommentant, on a la liste des taxons manquants, à intégrer dans Taxref_local si l’importateur a vérifié qu’ils n’étaient effectivement pas rattachables à Taxref
-- WHERE nomcite <> t.nom_complet  -– en décommentant, on a la liste des seuls taxons dont le nom ne correspond pas exactement avec le nom latin de Taxref. Cela permet de faciliter la vérification manuelle.
GROUP BY r.nomcite, r.cdnom, t.cd_nom, t.cd_ref, t.nom_vern, t.nom_complet,t.nom_valide, t.rang, t.reu
ORDER BY t.nom_valide
-- diff permet de voir tout de suite si cdnom = cdref
--> s'il y a des taxons à ajouter => remplir taxref_local_source + taxref_local comme indiqué dans les parties suivantes, qui peuvent être sautées si aucun taxon n’est à ajouter.
-- exemple avec un reptile NAC :

------------------------------------
-- 2 - Complément si besoin de taxref_local_source

INSERT INTO taxref_local_source
	(code, titre, description, info_url, taxon_url)
SELECT
	'Tagada' AS code,
	'Taxons de reptile non présents dans TAXREF' AS titre,
	'Taxons de reptile non présents dans TAXREF' AS description,
	'http://Tagada.org/' AS info_url,
	'http://Tagada.org/' AS taxon_url
	WHERE NOT EXISTS (SELECT code FROM taxon.taxref_local_source WHERE code = 'Tagada') ;

-- SELECT * FROM taxref_local_source;

------------------------------------
-- 3 - Complément si besoin de taxref_local
/* Attention d'utiliser pour le remplissage de group1_inpn et group2_inpn des valeurs présentes dans Taxref, ces valeurs pouvant légèrement évoluer entre deux versions de Taxref. Ces deux champs sont en effet utilisés entre autres pour produire des statistiques sur les données.
SELECT DISTINCT group1_inpn FROM taxref ORDER BY group1_inpn ;
SELECT DISTINCT group2_inpn FROM taxref ORDER BY group2_inpn ;
*/

-- Mettre à jour le serial. La séquence est négative pour les taxons locaux
SELECT Setval('taxon.taxref_local_cd_nom_seq', (SELECT Coalesce(min(cd_nom)-1, -1) FROM taxon.taxref_local ), false );

INSERT INTO taxon.taxref_local
 (regne, phylum, classe, ordre, famille, group1_inpn, group2_inpn, cd_nom, cd_sup, cd_ref, rang, lb_nom, lb_auteur, nom_complet, nom_valide, nom_vern, habitat, reu, local_bdd_code, local_identifiant_origine, local_identifiant_origine_ref, sous_famille, tribu)
SELECT
	'Animalia',
	'Chordata',
	NULL,
	'Squamata',
	'Telidae',
	'Chordés', -- group1_inpn
	'Reptiles', -- group2_inpn
	nextval('taxon.taxref_local_cd_nom_seq'::regclass),
	NULL,
	(nextval('taxon.taxref_local_cd_nom_seq'::regclass) +1),
	'ES',
	'Tupinambis merianae',
	'Duméril & Bibron, 1839',
	'Tupinambis merianae Duméril & Bibron, 1839 ',
	'Tupinambis merianae',
	'Lézar bizar'
	'3',
	NULL,
	'Tagada',
	'Tupinambis merianae',
	'Tupinambis merianae',
	NULL,
	NULL
WHERE NOT EXISTS (SELECT lb_nom FROM taxon.taxref_local WHERE lb_nom = 'Tupinambis merianae');

-- répéter cet INSERT autant de fois qu'il y a de nouveaux taxons
-- sinon créer un fichier avec la structure du Taxref contenant les nouveaux taxons et l'importer

-- ATTENTION:  il faut compléter le script avec un CASE pour les observations sans cd_nom à l'import de la table fdw.pnrun_data_2018_observations (cf III - 2 - exemple mis en commentaire)
--> ajouter autant de cas que de nouveaux taxons dans taxref_local


-- Ajout d'une ligne dans t_complement, nécessaire pour que le taxon ressorte dans les filtres de recherche sur Borbonica
INSERT INTO t_complement (cd_nom_fk, statut, endemicite, invasibilite) -- on ne renseigne pas les autres champs de la table relatifs à la menace, à la protection... car normalement tous les taxons menacés ou protégés figurent déjà dans Taxref
SELECT
	(SELECT cd_nom FROM taxref_local ORDER BY cd_nom ASC limit 1) AS cd_nom_fk, -- correspond au dernier cd_nom ajouté dans taxref_local. En cas d'ajout multiple de taxons, récupérer les cd_nom dans taxref_local et les renseigner à la main
	'E' AS statut, -- Valeurs possibles : E = exotique | I = Indigène | ND = Non documenté (ex : cryptogène, ou tous les taxons pour lesquels on n'a pas d'info)
	NULL AS endemicite, -- Valeurs possibles : E = endémique Réunion | SE = endémique Mascareignes | NULL
	'ND' AS invasibilite -- Valeurs possibles : E = Envahissant | PE = Potentiellement envahissant | ND = Exotique sans caractère invasif documenté | NULL
ON CONFLICT DO NOTHING ;

-- Vérification
SELECT * FROM t_complement
WHERE cd_nom_fk IN (SELECT cd_nom FROM taxref_local ORDER BY cd_nom ASC limit 1) ;



------------------------------------
-- 4 - Mise à jour des vues matérialisées liées à Taxref, seulement si de nouveaux taxons ont été ajoutés

SET default_text_search_config TO french_text_search;
REFRESH MATERIALIZED VIEW taxref_valide; -- taxref_valide
REFRESH MATERIALIZED VIEW taxref_consolide; -- taxref_consolide
REFRESH MATERIALIZED VIEW taxref_consolide_non_filtre; -- taxref_consolide_non_filtre
REFRESH MATERIALIZED VIEW taxref_fts; -- taxref_fts


-------------------------------------------------------------------------------------
-- PARTIE III : Import des données dans occtax
-------------------------------------------------------------------------------------


-- 1- Suppression des données avant réimport

-- Faire le point au préalable sur les imports ayant déjà eu lieu pour ce jdd :
-- SELECT * FROM jdd_import WHERE (jdd_id = '99999') ;

-- Le cas échéant, supprimer les données déjà importées pour les écraser avec le nouvel import :
-- SELECT count(*) FROM observation WHERE (jdd_id = '99999');
-- DELETE FROM occtax.observation WHERE (jdd_id = '99999');

------------------------------------
-- 2- import dans la table occtax.observation

-- On vérifie avant le nombre de nouvelles lignes attendues à la fin
-- SELECT count(*) FROM fdw.pnrun_data_2018_observations
--WHERE idorigine NOT IN ('x') -- On peut dans certains cas choisir d’écarter lors de l’import certaines données, par exemple parce qu’il s’agit de doublons ou de données signalées invalides par le producteur ;

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
		CASE
			WHEN loip.id_sinp_occtax IS NOT NULL THEN loip.id_sinp_occtax
			ELSE CAST(uuid_generate_v4() AS text)
		END AS id_sinp_occtax, -- On a vérifié lors de l'import des sources que la table importée dispose bien de valeurs uniques et pérennes (clef primaire)

		CASE
			WHEN s.statobs = 'Présent' THEN 'Pr'
			WHEN s.statobs = 'Non Observé' THEN 'No'
			ELSE 'No' -- 'Pr' au choix...
		END AS statut_observation,

        -- taxons
		s.cdnom::bigint AS cd_nom,
		-- CASE  --> ajouter autant de cas que de nouveaux taxons dans taxref_local
			-- WHEN s.cd_nom is NULL THEN (SELECT cd_nom FROM taxref_local WHERE lb_nom = 'Tupinambis merianae' )
			-- ELSE s.cd_nom::bigint
		-- END AS cd_nom,
		--s.cdnom::bigint AS cd_ref,
		(SELECT cd_ref FROM taxon.taxref WHERE cd_nom = s.cdnom::bigint) AS cd_ref, -- si le cdref n'est pas rempli
		-- CASE  --> ajouter autant de cas que de nouveaux taxons dans taxref_local
			-- WHEN s.cd_nom is NULL THEN (SELECT cd_nom FROM taxref_local WHERE lb_nom = 'Tupinambis merianae' )
			-- ELSE s.cd_ref::bigint
		-- END AS cd_ref,

		-- Faire attention que les cd_ref soient valides - cf script ci-dessus (II - 1)

		s.cdnom::bigint AS cd_nom_cite,

		'12.0' AS version_taxref, -- Adapter si besoin en fonction de la version mise en œuvre dans Borbonica (une nouvelle version sortie chaque année)
		s.nomcite AS nom_cite,

        -- denombrement
		-- "non dénombrement" avec présence => denombrement_min = denombrement_max = objet_denombrement = type_denombrement = NULL
		s.denbrmin::INTEGER AS denombrement_min,

		CASE
			WHEN (TRIM(s.denbrmax) is NULL and TRIM(s.denbrmin) is not NULL) THEN s.denbrmin::INTEGER
			ELSE s.denbrmax::INTEGER
		END AS denombrement_max,

		CASE
			WHEN trim(s.objdenbr) = 'Colonie' THEN 'COL'
			WHEN trim(s.objdenbr) = 'Couple' THEN 'CPL'
			WHEN trim(s.objdenbr) = 'Hampe florale' THEN 'HAM'
			WHEN trim(s.objdenbr) = 'Individu' THEN 'IND'
			WHEN trim(s.objdenbr) = 'Nid' THEN 'NID'
			WHEN trim(s.objdenbr) = 'Ne Sait Pas' THEN 'NSP'
			WHEN trim(s.objdenbr) = 'Ponte' THEN 'PON'
			WHEN trim(s.objdenbr) = 'Surface' THEN 'SURF'
			WHEN trim(s.objdenbr) = 'Tige' THEN 'TIGE'
			WHEN trim(s.objdenbr) = 'Touffe' THEN 'TOUF'
			ELSE 'NSP'
		END AS objet_denombrement,
		CASE
			WHEN trim(s.typdenbr) = 'Calculé' THEN 'Ca'
			WHEN trim(s.typdenbr) = 'Estimé' THEN 'Es'
			WHEN trim(s.typdenbr) = 'Compté' THEN 'Co'
			WHEN trim(s.typdenbr) = 'Ne Sait Pas' THEN 'NSP'
			ELSE 'NSP'
		END AS type_denombrement,

        -- commentaires -- à adapter !!!
	-- On doit s'efforcer d'importer les informations de l'ensemble des champs du jdd source, sans perte, quitte à les intégrer dans les champs commentaires si aucun autre champ ne permet de le faire. Une solution intéressante consiste également à utiliser les champs attributs additionnels si besoin (voir plus bas).
		concat_ws(' - '::TEXT, TRIM(s.comment),
				CASE  -- exemple de ce qui peut être ajouté
					WHEN (s.denbrmax is NULL and s.denbrmin::INTEGER > 999)  THEN 'dénombrement minimum - colonie'
					ELSE NULL
				END) AS commentaire,

        -- dates
		-- bien vérifier les formats -> adapter le case en fonction de la saisie
		CASE
			WHEN s.datedebut = '????' THEN '01/01/2011'::DATE -- doit être complété en fonction des jeux de données
			ELSE s.datedebut::DATE
		END AS date_debut,
		CASE
			WHEN s.datefin = '????' THEN '31/12/2019'::DATE
			ELSE s.datefin::DATE
		END AS date_fin,

		NULL AS heure_debut,
		NULL AS heure_fin,
--		NULL::time with time zone AS heure_debut,
--		NULL::time with time zone AS heure_fin,
		NULL as date_determination,

	-- dates de modifications & transformation
		CASE WHEN loip.id_sinp_occtax IS NOT NULL THEN loip.dee_date_derniere_modification
			ELSE now()
		END AS dee_date_derniere_modification,
		CASE WHEN loip.dee_date_transformation IS NOT NULL THEN loip.dee_date_transformation
			ELSE now()
		END AS dee_date_transformation,
		'NON'::text AS dee_floutage, -- pas de données floutées en entrée dans le cadre du SINP 974

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

	-- diffusion_niveau_precision, -- n'utiliser que 'maille 2 km' ou 'précise' dans le modèle de saisie
		CASE
--			WHEN trim(s.difnivprec) = 'tout' THEN '0'
--			WHEN trim(s.difnivprec) = 'commune' THEN '1'
--			WHEN trim(s.difnivprec) = 'maille 10 km' THEN '2'
			WHEN trim(s.difnivprec) = 'maille 2 km' THEN 'm02'
--			WHEN trim(s.difnivprec) = 'département' THEN '3'
--			WHEN trim(s.difnivprec) = 'non diffusé' THEN '4'
			WHEN trim(s.difnivprec) = 'précise' THEN '5'
			ELSE '5'
		END AS diffusion_niveau_precision,

	-- ds_publique
		CASE
			WHEN trim(s.dspublique) = 'Publique' THEN 'Pu'
			WHEN trim(s.dspublique) = 'Publique Régie' THEN 'Re' -- gelé avec occtax 2.0
			WHEN trim(s.dspublique) = 'Publique Acquise' THEN 'Ac' -- gelé avec occtax 2.0
			WHEN trim(s.dspublique) = 'Privée' THEN 'Pr'
			WHEN trim(s.dspublique) = 'Ne sait pas' THEN 'NSP'
			ELSE 'NSP'
		END AS ds_publique,

	-- idorigine
		s.idorigine AS id_origine,

	-- JDD : on reprend ici les éléments déjà utilisés pour renseigner la table jdd
		j.jdd_code AS jdd_code,
		j.jdd_id AS jdd_id,
		j.id_sinp_jdd AS id_sinp_jdd,

	--producteur-gestionnaire - orgGestDat
		'Parc régional de La Réunion' AS organisme_gestionnaire_donnees,

	--mise en base SINP
		-- 'DEAL974' AS org_transformation,
		'Parc national de La Réunion' AS org_transformation,

	--sources
        CASE
            WHEN LOWER(s.statsource) = 'terrain' THEN 'Te'
            WHEN LOWER(s.statsource) = 'collection' THEN 'Co'
            WHEN LOWER(s.statsource) = 'littérature' THEN 'Li'
            WHEN LOWER(s.statsource) = 'ne sait pas' THEN 'NSP'
            ELSE null
        END AS statut_source,

	-- références bibliographiques : à compléter si nécessaire avec les infos du producteur -> existe a minima quand il y a de nouveaux taxons, qui font souvent l’objet de publications scientifiques
		TRIM(s.refbiblio) AS reference_biblio,

	-- sensibilite : remplissage provisoire à ce stade car une fonction spécifique la calcule une fois l'import réalisé (cf. plus bas)
		now()::timestamp with time zone AS sensi_date_attribution,
		'm02' AS sensi_niveau,
		'http://www.naturefrance.fr/la-reunion/referentiel-de-sensibilite' AS sensi_referentiel,
		'1.4.0' AS sensi_version_referentiel, -- voir occtax.sensibilite_referentiel

	-- descriptif du sujet
		json_build_array (json_build_object(

		-- MÉTHODE D'OBSERVATION
			'obs_technique',
		CASE
			WHEN trim(s.obsmeth) = 'Vu' THEN '0'
			WHEN trim(s.obsmeth) = 'Entendu' THEN '1'
			WHEN trim(s.obsmeth) = 'Coquilles d''œuf' THEN '2'
			WHEN trim(s.obsmeth) = 'Ultrasons' THEN '3'
			WHEN trim(s.obsmeth) = 'Empreintes' THEN '4'
			WHEN trim(s.obsmeth) = 'Exuvie' THEN '5'
			WHEN trim(s.obsmeth) = 'Fèces/Guano/Épreintes' THEN '6'
			WHEN trim(s.obsmeth) = 'Mues' THEN '7'
			WHEN trim(s.obsmeth) = 'Nid/Gîte' THEN '8'
			WHEN trim(s.obsmeth) = 'Pelote de réjection' THEN '9'
			WHEN trim(s.obsmeth) = 'Restes dans pelote de réjection' THEN '10'
			WHEN trim(s.obsmeth) = 'Poils/plumes/phanères' THEN '11'
			WHEN trim(s.obsmeth) = 'Restes de repas' THEN '12'
			WHEN trim(s.obsmeth) = 'Spore' THEN '13'
			WHEN trim(s.obsmeth) = 'Pollen' THEN '14'
			WHEN trim(s.obsmeth) = 'Oosphère' THEN '15'
			WHEN trim(s.obsmeth) = 'Ovule' THEN '16'
			WHEN trim(s.obsmeth) = 'Fleur' THEN '17'
			WHEN trim(s.obsmeth) = 'Feuille' THEN '18'
			WHEN trim(s.obsmeth) = 'ADN environnemental' THEN '19'
			WHEN trim(s.obsmeth) = 'Autre' THEN '20'
			WHEN trim(s.obsmeth) = 'Inconnu' THEN '21'
			WHEN trim(s.obsmeth) = 'Mine' THEN '22'
			WHEN trim(s.obsmeth) = 'Galerie/terrier' THEN '23'
			WHEN trim(s.obsmeth) = 'Oothèque' THEN '24'
			WHEN trim(s.obsmeth) = 'Vu et entendu' THEN '25'
--			WHEN trim(s.obsmeth) = 'Contact olfactif' THEN '26'	 -- Code supplémentaire
			ELSE '21' -- inconnu
		END,

		-- ETAT BIOLOGIQUE
			'occ_etat_biologique',
		CASE
			WHEN LOWER(s.ocetatbio) ='observé vivant' THEN '2'
			WHEN LOWER(s.ocetatbio) ='trouvé mort' THEN '3'
			WHEN LOWER(s.ocetatbio) ='NSP' THEN '0'
			WHEN LOWER(s.ocetatbio) ='Non renseigné' THEN '1'
			ELSE '1' -- Non renseigné
		END,

		-- NATURALITE
			'occ_naturalite',
		CASE
			WHEN trim(s.ocnat) = 'Inconnu' THEN '0'
			WHEN trim(s.ocnat) = 'Sauvage' THEN '1'
			WHEN trim(s.ocnat) = 'Cultivé/élevé' THEN '2'
			WHEN trim(s.ocnat) = 'Planté' THEN '3'
			WHEN trim(s.ocnat) = 'Féral' THEN '4'
			WHEN trim(s.ocnat) = 'Subspontané' THEN '5'
			ELSE '0' -- inconnu
		END,

		-- SEXE
			'occ_sexe',
		CASE
			WHEN trim(s.ocsex) = 'Inconnu' THEN '0'
			WHEN trim(s.ocsex) = 'Indéterminé' THEN '1'
			WHEN trim(s.ocsex) = 'Femelle' THEN '2'
			WHEN trim(s.ocsex) = 'Mâle' THEN '3'
			WHEN trim(s.ocsex) = 'Hermaphrodite' THEN '4'
			WHEN trim(s.ocsex) = 'Mixte' THEN '5'
			WHEN trim(s.ocsex) = 'Non renseigné' THEN '6'
			ELSE '6' -- Non renseigné
		END,

		-- STADE DE VIE
			'occ_stade_de_vie',
		CASE
			WHEN trim(s.ocstade) = 'Inconnu' THEN '0'
			WHEN trim(s.ocstade) = 'Indéterminé' THEN '1'
			WHEN trim(s.ocstade) = 'Adulte' THEN '2'
			WHEN trim(s.ocstade) = 'Juvénile' THEN '3'
			WHEN trim(s.ocstade) = 'Immature' THEN '4'
			WHEN trim(s.ocstade) = 'Sub-adulte' THEN '5'
			WHEN trim(s.ocstade) = 'Larve' THEN '6'
			WHEN trim(s.ocstade) = 'Chenille' THEN '7'
			WHEN trim(s.ocstade) = 'Têtard' THEN '8'
			WHEN trim(s.ocstade) = 'Œuf' THEN '9'
			ELSE '0' -- inconnu
		END,

		-- DENOMBREMENT DETAILLE
			'occ_denombrement_min', s.denbrmin::INTEGER,

			'occ_denombrement_max',
		CASE
			WHEN (TRIM(s.denbrmax) is NULL and TRIM(s.denbrmin) is not NULL) THEN s.denbrmin::INTEGER
			ELSE s.denbrmax::INTEGER
		END,

			'occ_objet_denombrement',
		CASE
			WHEN trim(s.objdenbr) = 'Colonie' THEN 'COL'
			WHEN trim(s.objdenbr) = 'Couple' THEN 'CPL'
			WHEN trim(s.objdenbr) = 'Hampe florale' THEN 'HAM'
			WHEN trim(s.objdenbr) = 'Individu' THEN 'IND'
			WHEN trim(s.objdenbr) = 'Nid' THEN 'NID'
			WHEN trim(s.objdenbr) = 'Ne Sait Pas' THEN 'NSP'
			WHEN trim(s.objdenbr) = 'Ponte' THEN 'PON'
			WHEN trim(s.objdenbr) = 'Surface' THEN 'SURF'
			WHEN trim(s.objdenbr) = 'Tige' THEN 'TIGE'
			WHEN trim(s.objdenbr) = 'Touffe' THEN 'TOUF'
			WHEN trim(s.objdenbr) = 'Autre' THEN 'AUTR'
			ELSE 'NSP'
		END,

			'occ_type_denombrement',
		CASE
			WHEN trim(s.typdenbr) = 'Calculé' THEN 'Ca'
			WHEN trim(s.typdenbr) = 'Estimé' THEN 'Es'
			WHEN trim(s.typdenbr) = 'Compté' THEN 'Co'
			WHEN trim(s.typdenbr) = 'Ne Sait Pas' THEN 'NSP'
			ELSE 'NSP'
		END,

		-- STATUT BIOGEOGRAPHIQUE
			'occ_statut_biogeographique','1', -- non renseigné

		-- STATUT BIOLOGIQUE
			'occ_statut_biologique',
		CASE
			WHEN trim(s.ocstatbio) = 'Inconnu' THEN '0'
			WHEN trim(s.ocstatbio) = 'Non renseigné' THEN '1'
			WHEN trim(s.ocstatbio) = 'Non Déterminé' THEN '2'
			WHEN trim(s.ocstatbio) = 'Reproduction' THEN '3'
			WHEN trim(s.ocstatbio) = 'Hibernation' THEN '4'
			WHEN trim(s.ocstatbio) = 'Estivation' THEN '5'
			WHEN trim(s.ocstatbio) = 'Halte migratoire' THEN '6'
			WHEN trim(s.ocstatbio) = 'Swarming' THEN '7'
			WHEN trim(s.ocstatbio) = 'Chasse / alimentation' THEN '8'
			WHEN trim(s.ocstatbio) = 'Pas de reproduction' THEN '9'
			WHEN trim(s.ocstatbio) = 'Passage en vol' THEN '10'
			WHEN trim(s.ocstatbio) = 'Erratique' THEN '11'
			WHEN trim(s.ocstatbio) = 'Sédentaire' THEN '12'
			ELSE '1' -- Non renseigné
		END,

		-- PREUVE EXISTANTE
			'preuve_existante',
		CASE
			WHEN trim(s.preuveoui) = 'NSP' THEN '0'
			WHEN trim(s.preuveoui) = 'Oui' THEN '1'
			WHEN trim(s.preuveoui) = 'Non' THEN '2'
			WHEN trim(s.preuveoui) = 'NonAcquise' THEN '3'
			ELSE '0' -- NSP
		END,

		-- PREUVE NUM
			'url_preuve_numerique', NULL,

		-- PREUVE NON NUM
			'preuve_non_numerique', NULL,

		-- CONTEXTE
			'obs_contexte', TRIM(s.obsctx),

		-- DESCRIPTION
			'obs_description', TRIM(s.obsdescr),

		--  DETERMINATION
			'occ_methode_determination', TRIM(s.ocmethdet)

		))::jsonb AS descriptif_sujet,

		-- données complémentaires
		NULL AS donnee_complementaire,	-- ce champ peut éventuellement être utilisé pour stocker d’autres informations non prévues au standard, mais il vaut mieux y préférer l’utilisation de la table attribut_additionnel

		-- precision géométrie
		s.precision::INTEGER AS precision_geometrie,

		-- nature géométrie
		CASE
			WHEN LOWER(s.natobjgeo) = 'stationnel' THEN 'St'
			WHEN LOWER(s.natobjgeo) = 'inventoriel' THEN 'In'
			WHEN LOWER(s.natobjgeo) = 'ne sait pas' THEN 'NSP'
			ELSE 'NSP'
		END  AS nature_objet_geo,

		-- TRIM(s.natobjgeo) IS NOT NULL THEN TRIM(s.natobjgeo), -si saisie 'St', 'In' et 'NSP'

		-- ATTENTION : pour les géométries => le "." est le séparateur décimal et non la ","
		-- geom -> xy (dans les cas où la géométrie des points est indiquée sous forme de coordonnées XY)
		CASE
			WHEN s.x IS NOT NULL AND s.y IS NOT NULL
			THEN ST_SetSrid(ST_GeomFromText('POINT(' || s.x || ' ' || s.y || ')', 2975), 2975) -- Format RGR92 déjà utilisé
			-- THEN st_transform(st_GeomFromText('POINT(' || regexp_replace( s.x, ',', '.') || ' ' || regexp_replace(s.y,',', '.') || ')', 32740),2975), -- WGS84 utm40s (GPS) -> RGR92 utm40s
			ELSE NULL
		END AS geom,

		-- geom -> wkt (dans les cas où la géométrie des points est indiquée sous forme de WKT)
		-- CASE
		-- WHEN wkt IS NOT NULL
			-- THEN ST_SetSrid(ST_GeomFromText(s.wkt, 2975), 2975)
			-- -- THEN ST_Transform(ST_GeomFromText(s.wkt, 4326),2975) --  WGS84 (lon/lat) (GPS) -> RGR92 utm40s
			-- -- THEN ST_SetSrid(ST_GeomFromText((regexp_replace((regexp_replace( s.wkt, ',', '.')), ',', '.')), 2975), 2975) -- si ","
			-- ELSE NULL
		-- END AS geom,

		-- odata : champ permettant éventuellement de stocker de manière provisoire des informations utiles à l’import, qui ne seront pas diffusées ensuite
		NULL AS odata


FROM

-- table source
fdw.pnrun_data_2018_observations  AS s

-- table de(s) jdd
INNER JOIN occtax.jdd j ON j.jdd_id = s.jdd_id

-- jointure pour récupérer les identifiants permanents si déjà créés lors d'un import passé
LEFT JOIN occtax.lien_observation_identifiant_permanent AS loip ON loip.jdd_id IN ('99999')
AND loip.id_origine = s.idorigine::TEXT
-- s'il y a plusieurs jdd ajouter :
-- AND loip.jdd_id = s.jdd_id -- (ou j.jdd_id)

WHERE TRUE  ; -- On peut éventuellement ajouter ici des filtres pour écarter lors de l’import des données du jeu de données source, comme évoqué plus haut

-- Si le champ cd_nom_cite n'a pas été renseigné ci-dessus :
-- UPDATE occtax.observation
-- set cd_nom_cite = cd_nom
-- WHERE jdd_id IN ('99999');

-- Vérifications
SELECT count(*) FROM observation WHERE jdd_id IN ('99999')  ;


------------------------------------
-- 3- Vidage puis remplissage de lien_observation_identifiant_permanent pour garder en mémoire les identifiants permanents en cas d'un réimport futur

DELETE FROM occtax.lien_observation_identifiant_permanent
WHERE jdd_id IN ('99999')   ;

INSERT INTO occtax.lien_observation_identifiant_permanent
(jdd_id, id_origine, id_sinp_occtax, dee_date_derniere_modification, dee_date_transformation)
SELECT o.jdd_id, o.id_origine, o.id_sinp_occtax, o.dee_date_derniere_modification, o.dee_date_transformation
FROM occtax.observation o
WHERE jdd_id IN ('99999')
ORDER BY o.cle_obs
;

-- Vérification
SELECT * FROM occtax.lien_observation_identifiant_permanent
WHERE jdd_id IN ('99999');


------------------------------------
-- 4-  Renseignement des personnes associées aux observations (observateurs, déterminateurs)
--"role_personne";"Det";"Déterminateur"
--"role_personne";"Obs";"Observateur"
-- NB : les validateurs sont pas traités ici ; si les données sont déjà validées --> cf 9.3 -- les déterminateurs sont traités comme les observateurs

-- 4.0 vérifications préalables

-- Couples observations/personnes déjà renseignées pour ce jeu de données :
SELECT count(*) FROM occtax.observation_personne LEFT JOIN occtax.observation USING (cle_obs)
WHERE jdd_id IN ('99999');

-- recherche de doublons dans occtax.personne

SELECT tab1.id_personne, tab1.identite, tab1.mail, tab1.id_organisme, tab2.id_personne, tab2.identite, tab2.mail, tab2.id_organisme
FROM occtax.personne tab1, occtax.personne tab2

WHERE trim(lower(unaccent(tab1.identite)))=trim(lower(unaccent(tab2.identite)))
	AND tab1.id_organisme=tab2.id_organisme
--	AND tab1.mail=tab2.mail
	AND tab1.id_personne<>tab2.id_personne
    AND tab1.id_personne=(SELECT MAX(id_personne) FROM occtax.personne tab
    WHERE tab.id_personne=tab1.id_personne)
ORDER BY tab1.id_personne


-- ATTENTION : bien gérer dans son script pour créer identite_personne
-- "Si la personne n'est pas connue (non mentionnée dans la source) : noter INCONNU en lieu et place de NOM Prénom."
-- => seule identité est "normée"
-- Nous avons choisi de mettre "INCONNU" pour remplacer null
-- ATTENTION  par la suite de bien gérer dans son script pour créer identite
-- Ne pas faire : INCONNU Inconnu - DUPONT Inconnu - INCONNU Cunégonde
-- Faire : INCONNU - DUPONT - Cunégonde (la casse permet de différencier nom et prénom)
-- exemple de script pour des "null" en prénom pour créer des identités (à compléter / modifier si nécessaire) :
-- INSERT INTO occtax.personne
-- (identite, mail, prenom, nom, anonymiser, id_organisme)
-- SELECT DISTINCT
-- TRIM(CONCAT(UPPER(TRIM(o.nom)), ' ', INITCAP(TRIM(o.prenom)))) AS identite,
-- CASE
-- WHEN o.contact <> '_' THEN TRIM(o.contact)
-- ELSE NULL
-- END AS mail,
-- CASE
-- WHEN o.prenom is null THEN 'INCONNU'
-- ELSE INITCAP(TRIM(o.prenom))
-- END AS prenom,
-- TRIM(UPPER(o.nom)) AS nom,
-- TRUE AS anonymiser, -- on anonymise tout le monde
-- o.id_organisme
-- FROM fdw.noi_observateurs204 o
-- -- on fait une jointure sur la table personne pour ne pas insérer les données déjà présentes
-- LEFT JOIN occtax.personne p ON unaccent(p.identite) = unaccent(TRIM(CONCAT(UPPER(TRIM(o.nom)), ' ', INITCAP(TRIM(COALESCE(o.prenom, 'INCONNU')))))) and p.id_organisme = o.id_organisme
-- WHERE p.id_personne IS NULL
-- on conflict DO NOTHING;


-- 4.1 table organisme

--> I 1.1

SELECT Setval('occtax.organisme_id_organisme_seq', (SELECT max(id_organisme) FROM occtax.organisme) );
INSERT INTO occtax.organisme
(nom_organisme, sigle, responsable, adresse1, adresse2, cs, cp, commune, cedex, commentaire)
VALUES (
	'CYNORKIS',
	Null,
	'Dominique HOAREAU - Gérant',
	'18 chemin Michel Debré',
	NULL,
	NULL,
	'97417',
	'SAINT-DENIS',
	NULL,
	NULL
	)
ON CONFLICT DO NOTHING;

-- 4.2 table personne

--> I 1.2

-- Nom et l’identifiant organisme doivent obligatoirement être remplis
-- verification orgobs --> id_organisme non null
--  On vérifie avant si on arrive bien à rattacher chaque personne à un organisme
SELECT b.id_organisme, a.nom
FROM fdw.pnrun_data_2018_acteurs AS a , occtax.organisme AS b
WHERE LOWER(TRIM(b.nom_organisme)) = LOWER(TRIM(a.orgobs))
-- ou
SELECT  a.nom, a.orgobs, b.nom_organisme
FROM fdw.pnrun_data_2018_acteurs AS a , occtax.organisme AS b
WHERE b.id_organisme = a.id_organisme::integer

-- Puis on insère dans la table personne
SELECT Setval('occtax.personne_id_personne_seq', (SELECT max(id_personne) FROM occtax.personne ) );

-- Attention si le nom est vide et le prénom non vide

INSERT INTO occtax.personne
(identite, mail, prenom, nom, anonymiser, id_organisme)
SELECT DISTINCT
	TRIM(CONCAT(UPPER(TRIM(o.nom)), ' ', INITCAP(TRIM(o.prenom)))) AS identite, -- obligatoirement nom est connu !
	TRIM(LOWER(o.mail)) AS mail,
	CASE
		WHEN o.prenom is NULL THEN 'Inconnu'
		ELSE INITCAP(TRIM(o.prenom))
	END AS prenom,
	UPPER(TRIM(o.nom)) AS nom,
	CASE
		WHEN TRIM(o.anonyme) = 'non' THEN FALSE
		WHEN TRIM(o.anonyme) = 'oui' THEN TRUE
		ELSE TRUE
	END AS anonymiser, -- Vérifier si nécessaire avec le producteur s’il souhaite que le nom des observateurs soit anonymisé pour le grand public et les utilisateurs connectés
	o.id_organisme::INTEGER AS id_organisme
FROM fdw.pnrun_data_2018_acteurs o
-- on fait une jointure sur la table personne pour ne pas insérer les données déjà présentes
LEFT JOIN occtax.personne p ON unaccent(p.identite) = TRIM(CONCAT(UPPER(unaccent(TRIM(o.nom))), ' ', INITCAP(unaccent(TRIM(o.prenom))))) and p.id_organisme= o.id_organisme::integer
WHERE p.id_personne IS NULL AND o.nom IS NOT NULL AND o.id_organisme IS NOT NULL -- test ajouté pour éviter les lignes vides dans le fichier "acteurs"
ON CONFLICT DO NOTHING
;

-- 4.3 table observation_personne
-- elle peut contenir des observateurs et des déterminateurs
--  pour les validateurs -> gérés dans occtax.validation_observation

--observateur_1

INSERT INTO occtax.observation_personne (cle_obs, id_personne, role_personne)
SELECT DISTINCT
    o.cle_obs,
    p.id_personne,
    'Obs' AS role_personne
FROM occtax.observation AS o
INNER JOIN fdw.pnrun_data_2018_observations AS t ON t.idorigine = o.id_origine
-- s'il y a plusieurs jdd ajouter :
-- AND t.jdd_id = o.jdd_id
INNER JOIN fdw.pnrun_data_2018_acteurs AS op ON LOWER(op.identite) = LOWER(t.observateur_1)
INNER JOIN occtax.personne AS p ON unaccent(p.identite) = unaccent(TRIM(op.identite)) AND p.id_organisme = op.id_organisme::INTEGER
WHERE True
AND o.jdd_id IN ('99999')
ON CONFLICT DO NOTHING
;

-- On vérifie qu'on a bien au moins un observateur/observation : liste des observations « orphelines »
SELECT o.cle_obs, op.id_personne, op.role_personne
FROM occtax.observation o
LEFT JOIN occtax.observation_personne op USING(cle_obs)
WHERE o.jdd_id IN ('99999')
AND op.id_personne IS NULL
ORDER BY o.cle_obs, op.id_personne ;


-- On vérifie qu'une observation n'a pas plusieurs observateurs à ce stade => si c'est le cas l'observateur n'est pas défini de manière unique entre le fichier d'observation et la table occtax.personne
--> c'est le cas si dans le fichier des observateurs fourni par le producteur, une "identité" peut être rattachée à plusieurs organismes. Dans ce cas il faut que dans le fichier d'observation cette différence puisse se faire => identité+organisme apparaissent

Select o.id_origine, count (o.id_origine) AS nb_obs
from occtax.observation as o
LEFT JOIN occtax.observation_personne as p USING (cle_obs)
where  o.jdd_id = '99999'
group by o.id_origine
having count (o.id_origine) > 1
;

--observateur_2

INSERT INTO occtax.observation_personne (cle_obs, id_personne, role_personne)
SELECT DISTINCT
    o.cle_obs,
    p.id_personne,
    'Obs' AS role_personne
FROM occtax.observation AS o
INNER JOIN fdw.pnrun_data_2018_observations AS t ON t.idorigine = o.id_origine
INNER JOIN fdw.pnrun_data_2018_acteurs AS op ON LOWER(op.identite) = LOWER(t.observateur_2)
INNER JOIN occtax.personne AS p ON unaccent(p.identite) = unaccent(TRIM(op.identite)) AND p.id_organisme = op.id_organisme::INTEGER
WHERE True
AND o.jdd_id IN ('99999')
ON CONFLICT DO NOTHING
;

--observateur_3

INSERT INTO occtax.observation_personne (cle_obs, id_personne, role_personne)
SELECT DISTINCT
    o.cle_obs,
    p.id_personne,
    'Obs' AS role_personne
FROM occtax.observation AS o
INNER JOIN fdw.pnrun_data_2018_observations AS t ON t.idorigine = o.id_origine
INNER JOIN fdw.pnrun_data_2018_acteurs AS op ON LOWER(op.identite) = LOWER(t.observateur_3)
INNER JOIN occtax.personne AS p ON unaccent(p.identite) = unaccent(TRIM(op.identite)) AND p.id_organisme = op.id_organisme::INTEGER
WHERE True
AND o.jdd_id IN ('99999')
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
-- FROM dw.pnrun_data_2018_observations AS t
-- JOIN occtax.observation o ON t.idorigine=o.id_origine
-- WHERE t.precisgeo = 'rattachement La Réunion' ; --> si une colonne precisgeo par exemple a été ajoutée pour les données sensible sans coordonnées

-- Rattachement automatique : la fonction occtax.occtax_update_spatial_relationships permet de valaduler automatiquement les observations géolocalisaées aux entités géographiques de référence (mailles, communes, masses d’eau, espaces naturels). Elle est à lancer systématiquement.

SELECT occtax.occtax_update_spatial_relationships(ARRAY['99999']);

-- Qq vérifications
-- On vérifie qu'on a le bon nombre de lignes insérées dans les tables de localisation (une ligne par observation si on n'est pas en mer)
SELECT count(*)
FROM occtax.localisation_commune
LEFT JOIN occtax.observation o USING (cle_obs)
WHERE o.jdd_id IN ('99999');

SELECT count(*)
FROM occtax.localisation_masse_eau
LEFT JOIN occtax.observation o USING (cle_obs)
WHERE o.jdd_id IN ('99999');

SELECT count(*)
FROM occtax.localisation_maille_10
LEFT JOIN occtax.observation o USING (cle_obs)
WHERE o.jdd_id IN ('99999');

SELECT count(*)
FROM occtax.localisation_maille_02
LEFT JOIN occtax.observation o USING (cle_obs)
WHERE o.jdd_id IN ('99999');

SELECT count(*)
FROM occtax.localisation_departement
LEFT JOIN occtax.observation o USING (cle_obs)
WHERE o.jdd_id IN ('99999');


------------------------------------
-- 6- Enrichissement de la donnée avec des paramètres calculés dans Borbonica
-- Ces paramètres peuvent être utiles par exemple pour la phase de validation automatique ou encore pour générer des statistiques globales sur les données. On utilise pour cela la table attribut_additionnel
-- Ajout de l'altitude calculée par le MNT à 10 m
-- On supprime ce qui a déjà été renseigné le cas échéant

DELETE FROM occtax.attribut_additionnel a
WHERE cle_obs IN (SELECT cle_obs FROM occtax.observation WHERE jdd_id IN ('99999'))
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
WHERE o.jdd_id IN ('99999')
AND st_value(r.rast,st_centroid(o.geom))::numeric(6,2) IS NOT NULL
;
-- Vérification
SELECT *
FROM occtax.attribut_additionnel a
WHERE cle_obs IN (SELECT cle_obs FROM occtax.observation WHERE jdd_id IN ('99999'))
AND a.nom='altitude_mnt';


-- Ajout de l'occupation du sol à partir de la table oiseaux_habitat
-- On supprime ce qui a déjà été renseigné le cas échéant
DELETE FROM occtax.attribut_additionnel a
WHERE cle_obs IN (SELECT cle_obs FROM occtax.observation WHERE jdd_id IN ('99999'))
AND a.nom='occupation_sol_stoc';

-- Puis on insère
INSERT INTO occtax.attribut_additionnel(cle_obs, nom, definition, valeur, unite, thematique, type)
SELECT  cle_obs,
		'occupation_sol_stoc' AS nom,
		'Occupation du sol déduite à partir de la table "STOC" oiseaux_habitat' AS definition,
		min(h.id::INTEGER) AS valeur,
		NULL AS unite,
		'occupation du sol' AS thematique,
		'QUAL' AS type
FROM occtax.observation o
LEFT JOIN taxon.taxref_valide t USING(cd_nom)
INNER JOIN sig.oiseaux_habitat h ON st_intersects(st_centroid(o.geom), h.geom)
WHERE o.jdd_id IN ('99999')
AND t.group2_inpn IN ('Reptiles', 'Amphibiens', 'Oiseaux') -- on n'a besoin de cette information que dans le cadre de la validation des données oiseaux, amphibiens et reptiles
GROUP BY cle_obs
HAVING count(h.id)=1 -- on exclut les cas où des polygones se superposent (problème devant être réglé à terme)
;
-- Vérification
SELECT *
FROM occtax.attribut_additionnel a
WHERE cle_obs IN (SELECT cle_obs FROM occtax.observation WHERE jdd_id IN ('99999'))
AND a.nom='occupation_sol_stoc';


------------------------------------
-- 7- Validation des données
-- 7.1 On vérifie tout d'abord la cohérence et la conformité des données (validation sur la forme) en lançant la fonction de contrôle
-- Cette fonction lance une batterie de tests types (script spécifique commun à tous les jeux de données)
-- Les observations présentant des anomalies doivent être vérifiées à la main et discutées avec le producteur. Si l'anomalie est confirmée, elle doit être soit corrigée, soit écartée lors de l'import en base de production pour ne pas intégrer le SINP.

SELECT divers.fonction_controle_coherence_conformite(ARRAY['99999']);
SELECT * FROM divers.controle_coherence_conformite ;


-- Export pour vérification
SELECT c.jdd_code, c.cle_obs, c.id_origine, c.libelle_test, c.description_anomalie, c.nom_cite, t.nom_valide, t.nom_vern, t.group2_inpn, CONCAT(t.reu, ' - ', st.valeur) AS reu, c.habitat AS habitat_taxref, c.wkt
FROM divers.controle_coherence_conformite c
LEFT JOIN occtax.observation o USING(cle_obs)
LEFT JOIN taxref t USING (cd_nom)
LEFT JOIN (SELECT * FROM taxon.t_nomenclature WHERE champ = 'habitat') hab ON hab.code=t.habitat
LEFT JOIN (SELECT * FROM taxon.t_nomenclature WHERE champ = 'statut_taxref') st ON st.code=t.reu
 ;

-- Synthèse : liste des anomalies constatées (pour alimentation du rapport d’import et discussion avec le producteur de données)
SELECT c.description_anomalie, string_agg(DISTINCT lb_nom || ' (' || t.group2_inpn || ')', ', ' ORDER BY lb_nom || ' (' || t.group2_inpn || ')') AS taxons, count(*)
FROM divers.controle_coherence_conformite c
LEFT JOIN observation o USING (cle_obs)
LEFT JOIN taxref_valide t USING (cd_ref)
GROUP BY c.description_anomalie;


-- 7.2 Vérification des doublons
-- Il s’agit de rechercher si le jeu de données importé contient des doublons, c’est-à-dire des observations qui concernent le même taxon, la même date, les mêmes observateurs et le même lieu que des observations d’autres jeux de données déjà importés dans Borbonica. Pour cela, la fonction identifie automatiquement les doublons potentiels, ie les observations concernant la même date et le même taxon et qui sont à moins de 10 km l’une de l’autre (ce paramétrage peut être modifié dans le script). CEs doublons sont stockés dans la table divers.controle_doublons qui contient dans chacun de ses champs la valeur de la table du jdd importé à gauche et celle de jdd comparé à droite. L'analyse de cette table permet manuellement de confirmer s'il s'agit ou pas d'un vrai doublon

-- Vérification des doublons externes (ie entre les observations du jdd importé et celles de tous les autres jdd déjà importés dans Borbonica) :
SELECT divers.fonction_controle_doublons(ARRAY['99999'], 100,  FALSE) ;
SELECT * FROM divers.controle_doublons ;

-- Vérification des doublons internes (ie au sein du ou des jdd importés) :
SELECT divers.fonction_controle_doublons(ARRAY['99999'], 1,  TRUE) ;
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
'6' AS validite_niveau, -- Si un niveau de validation est indiqué par le producteur ou la tête de réseau, il doit être précisé ici et sera utilisé plus bas dans le script (cf. partie 9 relative à la validation). Sinon, laisser 6 par défaut.
now()::DATE AS validite_date_validation, -- Si une date de validation est indiquée par le producteur ou la tête de réseau, elle doit être précisée ici et sera utilisée plus bas dans le script (cf. partie 9 relative à la validation). Sinon, laisser now() par défaut.


'M' AS typ_val, -- M = validation manuelle
'2' AS ech_val, -- Echelle de validation régionale (par les têtes de réseau).
-- S’il s’agit d’une validation par le producteur, indiquer '1'
-- S’il s’agit d’une validation nationale, indiquer '3'  --> fichiers du MNHN par ex
'1' AS peri_val, --convenu '1' (=périmètre minimal) avec les têtes de réseau (on ne valide à ce stade que l'occurrence de tel taxon, à tel endroit, à telle date)
(SELECT id_personne FROM occtax.personne WHERE(LOWER(identite) = 'sanchez mickaël' and id_organisme = 41)) AS validateur, -- le nom du validateur doit être adapté ici
(SELECT proc_vers FROM validation_procedure ORDER BY id DESC LIMIT 1) AS proc_vers, -- On récupère automatiquement le numéro de la dernière version du protocole de validation
NULL AS producteur,
NULL AS date_contact,
(SELECT procedure FROM validation_procedure ORDER BY id DESC LIMIT 1) AS procedure,
(SELECT proc_ref FROM validation_procedure ORDER BY id DESC LIMIT 1) AS proc_ref,
'Données validées avant import dans Borbonica par xxxxxxxxxxxxxxxx' AS comm_val -- Commentaire éventuel
FROM occtax.observation AS o
INNER JOIN fdw.pnrun_data_2018_observations AS t ON t.idorigine = o.id_origine
WHERE o.jdd_id IN ('99999')
ON CONFLICT DO NOTHING
;

--  Validation automatique : lancer la fonction occtax.calcul_niveau_validite
-- On rafraîchit dans un premier temps la vue matérialisée vm_observation car la fonction de validation fait appel à cette vue
REFRESH MATERIALIZED VIEW occtax.vm_observation ;

SELECT occtax.calcul_niveau_validation(
	ARRAY['99999'],
	(SELECT id_personne FROM personne WHERE identite='Administrateur Borbonica'),
	FALSE -- pas une simulation
);


-- 7.4 quelques vérifications : il s’agit de vérifier la bonne application de la validation automatique, et d’en assurer une synthèse pour intégration au rapport d’import et transmission au producteur

-- Calcul de statistiques
SELECT
    niv_val AS niveau_validite,
    (SELECT valeur FROM occtax.nomenclature WHERE champ='validite_niveau' AND code = niv_val) AS niveau_validite_libelle,
    (SELECT valeur FROM occtax.nomenclature WHERE champ='type_validation' AND code = typ_val) AS type_validite,
    count(DISTINCT v.id_sinp_occtax) AS nb_obs
FROM
    occtax.validation_observation AS v
WHERE v.ech_val = '2'
AND id_sinp_occtax IN (
	SELECT id_sinp_occtax FROM occtax.observation WHERE jdd_id IN ('99999')
)
GROUP BY niv_val, typ_val
ORDER BY niv_val
;


-- Détail des critères de validation automatique utilisés sur le jdd
SELECT n.valeur AS niveau_validite,
	string_agg(DISTINCT t.lb_nom, ', ' ORDER BY t.lb_nom) AS taxons_concernes,
	v.comm_val,
	count(o.cle_obs) AS nb_obs,
	(count(o.cle_obs)::NUMERIC (8,1)/(SELECT count(cle_obs) FROM occtax.observation WHERE o.jdd_id IN ('99999'))::NUMERIC (8,1))::NUMERIC (4,3) AS pourcentage -- attention au nb de données du jdd si > 1 000 000 ne fonctionne pas !
FROM occtax.observation o
LEFT JOIN occtax.validation_observation v USING(id_sinp_occtax)
LEFT JOIN occtax.nomenclature n ON n.code=v.niv_val AND champ='niv_val_auto'
LEFT JOIN taxon.taxref_valide t USING (cd_ref)
WHERE o.jdd_id IN ('99999') AND ech_val='2' and typ_val='A'
GROUP BY n.valeur, v.niv_val, v.comm_val, o.jdd_id
ORDER BY v.niv_val, v.comm_val ;


------------------------------------
-- 8- Mise à jour des critères de sensibilité et de diffusion
-- 8.1 Mise à jour des critères de sensibilité

-- La fonction occtax.calcul_niveau_sensibilite calcule automatiquement dans la table occtax.observation les informations liées à la sensibilité des données. Ces informations sont issues de la table critere_sensibilite, elle-même découlant du référentiel de données sensibles téléchargeable à l’adresse suivante, pour information : http://www.naturefrance.fr/la-reunion/referentiel-de-sensibilite

SELECT occtax.calcul_niveau_sensibilite(
	ARRAY['99999'],
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
	AND jdd_id IN ('99999')

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
	WHERE jdd_id IN ('99999')
	GROUP BY o.cd_ref, t.lb_nom, t.nom_vern
	ORDER BY t.lb_nom
	)

SELECT o.cd_ref, tax.lb_nom, tax.nom_vern, o.nom_cite, sensi_niveau, n.valeur AS sensi_libelle, count(cle_obs) AS nb_obs, tax.nb_total_obs
FROM occtax.observation o
LEFT JOIN n ON n.code=o.sensi_niveau
LEFT JOIN tax ON o.cd_ref=tax.cd_ref
WHERE jdd_id IN ('99999')
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
	WHERE o.jdd_id in ('99999')
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
	(id_acteur, nom, prenom, civilite, tel_1, tel_2, courriel, fonction, id_organisme, remarque, bulletin_information, service, date_maj, en_poste)
VALUES
	(
	nextval('gestion.acteur_id_acteur_seq'::regclass),
	'XXX',
	'yyy',
	'M.',
	'0262123456', -- ou NULL
	'0692123456', -- ou NULL
	'x@y.fr', -- ou NULL
	'personne utile pour SINP', -- ou NULL
	(SELECT id_organisme FROM organisme WHERE nom_organisme='toto'),
	'gfhtshrtjtyk', -- ou NULL
	TRUE,-- ou FALSE
	'service de la personne utile pour SINP', -- ou NULL
	now(),
	TRUE -- ou FALSE
	)
ON CONFLICT DO NOTHING;


-- 9.2 jdd_import

SELECT Setval('occtax.jdd_import_id_import_seq', (SELECT max(id_import) FROM occtax.jdd_import ) );
INSERT INTO jdd_import (
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
	'99999' AS jdd_id,
	'2019-09-13'::DATE AS date_reception, -- A compléter en fonction de la date de réception des données (ie la date à laquelle les derniers éléments nécessaires à l’import ont été transmis par le producteur)
	now()::date AS date_import,
	(SELECT count(idorigine) FROM fdw.pnrun_data_2018_observations) AS nb_donnees_source,-- attention s'il y a plusieurs jdd il faut filtrer par JDD
	count(o.cle_obs) AS nb_donnees_import,
	min(date_debut) AS date_obs_min,
	max(date_fin) AS date_obs_max,
	'1er import en base de prod' AS libelle, -- Compléter. Il peut s’agir ici d’expliquer par exemple qu’il s’agit d’un réimport.
	'Rapport d''import v 1.0' AS remarque, -- Compléter. On peut préciser le nom du rapport d’import accompagnant le jdd, ou bien expliquer qu’il y a eu des échanges avec le producteur pour clarifier tel ou tel point.
	(SELECT id_acteur FROM acteur WHERE courriel = 'x@y.fr') AS acteur_referent, -- compléter à partir du nom de l’acteur référent pour le compte du producteur
	(SELECT id_acteur FROM acteur WHERE courriel = 'jean-cyrille.notter@reunion-parcnational.fr') AS acteur_importateur
FROM occtax.observation AS o
WHERE jdd_id IN ('99999')
;

-- Vérification
SELECT * FROM occtax.jdd_import WHERE jdd_id in ('99999') ;

-- Requête permettant d’obtenir les caractéristiques principales de l’import, utiles ensuite pour renseigner le rapport d’import :
SELECT 	id_import,
		i.libelle AS libelle_import,
		jdd.jdd_cadre,
		CONCAT('https://inpn.mnhn.fr/mtd/cadre/export/xml/GetRecordById?id=', jdd.jdd_cadre) AS fiche_ca,
		-- CONCAT('https://inpn.mnhn.fr/espece/cadre/', jdd.jdd_cadre) AS fiche_ca, -- URL publique de la fiche une fois qu’elle a également été intégrée au SINP national
		i.jdd_id,
		jdd.jdd_code,
		jdd.jdd_description,
		CONCAT('https://inpn.mnhn.fr/mtd/cadre/jdd/export/xml/GetRecordById?id=', jdd.id_sinp_jdd) AS fiche_jdd,
		-- CONCAT('https://inpn.mnhn.fr/espece/jeudonnees/', jdd.jdd_id) AS fiche_jdd, -- URL publique de la fiche une fois qu’elle a également été intégrée au SINP national
		i.date_reception,
		i.date_import,
		referent.prenom || ' ' || referent.nom AS referent,
		importateur.prenom || ' ' || importateur.nom AS importateur,
		i.remarque
FROM occtax.jdd_import i
LEFT JOIN occtax.jdd USING (jdd_id)
LEFT JOIN gestion.acteur referent ON i.acteur_referent=referent.id_acteur
LEFT JOIN gestion.acteur importateur ON i.acteur_importateur=importateur.id_acteur
WHERE jdd_id in ('99999')
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
    ARRAY['1', '2', '3', '4', '5', '6'] AS 	validite_niveau, -- {1,2,3,4,5,6}
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

DROP TABLE fdw.pnrun_data_2018_observations ;
DROP TABLE fdw.pnrun_data_2018_organismes ;
DROP TABLE fdw.pnrun_data_2018_acteurs ;

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

-- ----------------	SERVER bdd_dev
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
SET date_import_dev = (SELECT date_import from occtax_dev.jdd_import where jdd_id = '99999')
WHERE nom_jdd = 'pnrun_data_2018';
-- s'il y a plusieurs JDD, en choisir un pour la rqt de la date_import

-------------------------------------
--> A FAIRE A L'IMPORT EN PROD SUR LA BASE DE PROD
-------------------------------------
-- s'il n'y a qu'un JDD
UPDATE divers.suivi_imports
SET date_import_prod = (SELECT date_import from occtax.jdd_import where jdd_id = '99999')
WHERE jdd_id ='99999';
-- s'il y a plusieurs JDD, en choisir un pour la rqt de la date_import

END ;
COMMIT;
-- JCN - VLT  V 6.0 – le 2020-06
