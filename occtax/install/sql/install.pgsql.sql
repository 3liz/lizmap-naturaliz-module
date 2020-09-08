
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DROP SCHEMA IF EXISTS occtax CASCADE;
DROP SCHEMA IF EXISTS sig CASCADE;
-- Schéma
CREATE SCHEMA occtax;
SET search_path TO occtax,public,pg_catalog;

-- Table nomenclature
CREATE TABLE nomenclature (
    champ text,
    code text,
    valeur text,
    description text,
    ordre smallint DEFAULT 0
);

ALTER TABLE nomenclature ADD PRIMARY KEY (champ, code);

COMMENT ON TABLE nomenclature IS 'Stockage de la nomenclature pour les champs des tables qui ont des listes de valeurs prédéfinies.';
COMMENT ON COLUMN nomenclature.champ IS 'Nom du champ';
COMMENT ON COLUMN nomenclature.code IS 'Code associé à une valeur';
COMMENT ON COLUMN nomenclature.valeur IS 'Libellé court. Joue le rôle de valeur';
COMMENT ON COLUMN nomenclature.champ IS 'Description de la valeur';
COMMENT ON COLUMN nomenclature.ordre IS 'Ordre d''apparition souhaité, utilisé par exemple dans les listes déroulantes du formulaire de recherche.';

-- Vue pour avoir une nomenclature à plat
DROP VIEW IF EXISTS occtax.v_nomenclature_plat CASCADE;
CREATE VIEW occtax.v_nomenclature_plat AS
WITH source AS (
    SELECT
    concat(o.champ, '_', o.code) AS k, o.valeur AS v
    FROM occtax.nomenclature AS o
    UNION ALL
    SELECT concat(replace(t.champ, 'statut_taxref', 'loc'), '_', t.code) AS k, t.valeur AS v
    FROM taxon.t_nomenclature AS t
)
SELECT
json_object(
    array_agg(k) ,
    array_agg(v)
) AS dict
FROM source
;


-- Table principale des observations
CREATE TABLE observation (
    cle_obs bigserial NOT NULL PRIMARY KEY,
    identifiant_permanent text NOT NULL,
    statut_observation text NOT NULL,
    cd_nom bigint,
    cd_ref bigint,
    version_taxref text,
    cd_nom_cite bigint,
    nom_cite text NOT NULL,

    denombrement_min integer,
    denombrement_max integer,
    objet_denombrement text,
    type_denombrement text,

    commentaire text,

    date_debut date NOT NULL,
    date_fin date NOT NULL,
    heure_debut time with time zone,
    heure_fin time with time zone,
    date_determination date,

    altitude_min numeric(6,2),
    altitude_moy numeric(6,2),
    altitude_max numeric(6,2),
    profondeur_min numeric(6,2),
    profondeur_moy numeric(6,2),
    profondeur_max numeric(6,2),

    code_idcnp_dispositif text,
    dee_date_derniere_modification timestamp with time zone NOT NULL,
    dee_date_transformation timestamp with time zone NOT NULL,
    dee_floutage text,
    diffusion_niveau_precision text,
    ds_publique text NOT NULL,
    identifiant_origine text,
    jdd_code text,
    jdd_id text,
    jdd_metadonnee_dee_id text NOT NULL,
    jdd_source_id text,
    organisme_gestionnaire_donnees text NOT NULL,
    org_transformation text NOT NULL,
    organisme_standard text,

    statut_source text NOT NULL,
    reference_biblio text,
    sensible text NOT NULL DEFAULT 0,
    sensi_date_attribution timestamp with time zone,
    sensi_niveau text NOT NULL DEFAULT 0,
    sensi_referentiel text,
    sensi_version_referentiel text,

    validite_niveau text,
    validite_date_validation date,

    precision_geometrie integer,
    nature_objet_geo text,

    descriptif_sujet jsonb,

    donnee_complementaire jsonb,

    CONSTRAINT obs_statut_source_valide CHECK ( statut_source IN ( 'Te', 'Co', 'Li', 'NSP' ) ),
    CONSTRAINT obs_reference_biblio_valide CHECK ( (statut_source = 'Li' AND reference_biblio IS NOT NULL) OR statut_source != 'Li' ),
    CONSTRAINT obs_ds_publique_valide CHECK ( ds_publique IN ( 'Pu', 'Re', 'Ac', 'Pr', 'NSP' ) ),
    CONSTRAINT obs_statut_observation_valide CHECK ( statut_observation IN ( 'Pr', 'No', 'NSP' ) ),
    CONSTRAINT obs_objet_denombrement_valide CHECK (
        ( denombrement_min IS NOT NULL AND denombrement_max IS NOT NULL AND objet_denombrement IN ('COL', 'CPL', 'HAM', 'IND', 'NID', 'NSP', 'PON', 'SURF', 'TIGE', 'TOUF')  )
        OR (denombrement_min IS NULL AND denombrement_max IS NULL AND Coalesce(objet_denombrement, 'NSP') = 'NSP')
    ),
    CONSTRAINT obs_type_denombrement_valide CHECK ( type_denombrement IN ('Co', 'Es', 'Ca', 'NSP') ),
    CONSTRAINT obs_diffusion_niveau_precision_valide CHECK ( diffusion_niveau_precision IS NULL OR diffusion_niveau_precision IN ( '0', '1', '2', '3', '4', '5', 'm01', 'm02' ) ),
    CONSTRAINT obs_dates_valide CHECK (date_debut <= date_fin AND date_debut + heure_debut <= date_fin + heure_fin),
    CONSTRAINT obs_precision_geometrie_valide CHECK ( precision_geometrie IS NULL OR precision_geometrie > 0 ),
    CONSTRAINT obs_altitude_min_max_valide CHECK ( Coalesce( altitude_min, 0 ) <= Coalesce( altitude_max, 0 ) ),
    CONSTRAINT obs_profondeur_min_max_valide CHECK ( Coalesce( profondeur_min, 0 ) <= Coalesce( profondeur_max, 0 ) ),
    CONSTRAINT obs_dee_floutage_valide CHECK ( dee_floutage IS NULL OR dee_floutage IN ('OUI', 'NON') ),
    CONSTRAINT obs_dee_date_derniere_modification_valide CHECK ( dee_date_derniere_modification >= dee_date_transformation ),
    CONSTRAINT obs_dee_floutage_ds_publique_valide CHECK ( ds_publique != 'Pr' OR ( ds_publique = 'Pr' AND dee_floutage IS NOT NULL ) ),
    CONSTRAINT obs_sensi_date_attribution_valide CHECK ( ( sensi_date_attribution IS NULL AND Coalesce(sensi_niveau, '0') = '0' ) OR  ( sensi_date_attribution IS NOT NULL  ) ),
    CONSTRAINT obs_sensi_niveau_valide CHECK ( sensi_niveau IN ( '0', '1', '2', '3', '4', '5', 'm01', 'm02' ) ),
    CONSTRAINT obs_sensi_referentiel_valide CHECK ( ( sensi_niveau != '0' AND sensi_referentiel IS NOT NULL) OR sensi_niveau = '0' ),
    CONSTRAINT obs_sensi_version_referentiel_valide CHECK ( ( sensi_niveau != '0' AND sensi_version_referentiel IS NOT NULL) OR sensi_niveau = '0' ),
    CONSTRAINT obs_version_taxref_valide CHECK (cd_nom IS NULL OR ( cd_nom IS NOT NULL AND cd_nom > 0 AND version_taxref IS NOT NULL) OR ( cd_nom IS NOT NULL AND cd_nom < 0 ))


);

SELECT AddGeometryColumn('observation', 'geom', {$SRID}, 'GEOMETRY', 2);
ALTER TABLE observation ADD CONSTRAINT obs_nature_objet_geo_valide CHECK ( (geom IS NOT NULL AND nature_objet_geo IN ('St', 'In', 'NSP')) OR geom IS NULL );


ALTER TABLE observation ADD COLUMN odata jsonb;

COMMENT ON COLUMN observation.cle_obs IS 'Attribut technique servant de clé primaire de l’observation. Cet attribut permet de faire le lien avec les autres fichiers fournis lors de l’échange';

COMMENT ON COLUMN observation.statut_source IS 'Indique si la DS de l’observation provient directement du terrain (via un document informatisé ou une base de données), d''une collection, de la littérature, ou n''est pas connu';

COMMENT ON COLUMN observation.reference_biblio IS 'Référence de la source de l’observation lorsque celle-ci est de type « Littérature », au format ISO690 La référence bibliographique doit concerner l''observation même et non uniquement le taxon ou le protocole.';

COMMENT ON COLUMN observation.sensible IS 'Indique si l''observation est sensible d''après les principes du SINP (cf : GT Donnée Sensible). Cet attribut est voué à disparaître pour la prochaine version du standard, l''attribut "sensibilite" permettant de porter une information plus complète et précise.';

COMMENT ON COLUMN observation.sensi_date_attribution IS 'Date à laquelle on a attribué un niveau de sensibilité à la donnée. C''est également la date à laquelle on a consulté le référentiel de sensibilité associé. Cet attribut est OBLIGATOIRE CONDITIONNEL : il DOIT être rempli si un niveau de sensibilité autre que celui par défaut a été renseigné dans l''attribut "sensibilite", et si "sensible" est différent de "0';

COMMENT ON COLUMN observation.sensi_niveau IS 'Indique si l''observation ou le regroupement est sensible d''après les principes du SINP et à quel degré. La manière de déterminer la sensibilité est définie dans le guide technique des données sensibles disponible sur la plate-forme naturefrance. Règles : Sans consultation de référentiel de sensibilité, le niveau est par défaut est 0 : DEE non sensible. La sensibilité d''une et une seule DEE d''un regroupement entraîne le même niveau de sensibilité pour le regroupement et pour toutes les observations de ce regroupement.';

COMMENT ON COLUMN observation.sensi_referentiel IS 'Référentiel de sensibilité consulté lors de l''attribution du niveau de sensibilité. Dans le cas où un référentiel de sensibilité n''existe pas : on inscrit ici le nom de l''organisme qui a assigné une sensibilité différente de 0, à titre transitoire. si un niveau de sensibilité différent de 0 a été renseigné, cet attribut DOIT être rempli';

COMMENT ON COLUMN observation.sensi_version_referentiel IS 'Version du référentiel consulté. Peut être une date si le référentiel n''a pas de numéro de version. Doit être rempli par "NON EXISTANTE" si un référentiel n''existait pas au moment de l''attribution de la sensibilité par un organisme. Autant que possible, on tentera d''utiliser la version en vigueur de ce référentiel.si un niveau de sensibilité différent de 0 a été renseigné, cet attribut DOIT être rempli.';

COMMENT ON COLUMN observation.jdd_id IS 'Identifiant pour la collection ou le jeu de données source d''où provient l''enregistrement. Un regroupement peut ne pas avoir existé dans le jeu de données source, et en conséquence, ne saurait avoir de jddId.';

COMMENT ON COLUMN observation.jdd_metadonnee_dee_id IS 'Identifiant permanent et unique de la fiche métadonnées du jeu de données auquel appartient la donnée. Cet identifiant est attribué par la plateforme';

COMMENT ON COLUMN observation.jdd_source_id IS 'Il peut arriver qu''on réutilise une donnée en provenance d''un autre jeu de données DEE déjà existant au sein du SINP. Cet attribut contient l''identifiant SINP du jeu de données qui est réutilisé.';

COMMENT ON COLUMN observation.jdd_code IS 'Nom, acronyme, ou code de la collection du jeu de données dont provient la donnée source. Exemples : "BDMAP", "FLORA", "BDN".';

COMMENT ON COLUMN observation.identifiant_origine IS 'Identifiant unique de la Donnée Source de l’observation dans la base de données du producteur où est stockée et initialement gérée la Donnée Source. La DS est caractérisée par jddId et/ou jddCode,. L''identifiant ne doit pas être la clé primaire technique, susceptible de varier selon les choix de gestion de l''outil de stockage.';

COMMENT ON COLUMN observation.identifiant_permanent IS 'Identifiant unique et pérenne de la Donnée Elémentaire d’Echange de l''observation dans le SINP attribué par la plate-forme régionale ou thématique. On se réfèrera au document sur les identifiants permanents présents sur la plate-forme NatureFrance : http://www.naturefrance.fr/sites/default/files/fichiers/ressources/pdf/sinp_identifiantpermanent.pdf';

COMMENT ON COLUMN observation.ds_publique IS 'Indique explicitement si la DS de la DEE est publique ou privée. Ce champ définit uniquement les droits nécessaires et suffisants des DS pour produire une DEE : l’attribut DSPublique ne doit être utilisé que pour indiquer si la DEE résultante est susceptible d’être floutée et ne doit pas être utilisé pour d’autres interprétations.';

COMMENT ON COLUMN observation.code_idcnp_dispositif IS 'Code du dispositif de collecte dans le cadre duquel la donnée a été collectée.';

COMMENT ON COLUMN observation.statut_observation IS 'Indique si le taxon a été observé directement ou indirectement (indices de présence), ou non observé';

COMMENT ON COLUMN observation.nom_cite IS 'Nom du taxon cité à l’origine par l’observateur. Celui-ci peut être le nom scientifique reprenant idéalement en plus du nom latin, l’auteur et la date. Cependant, si le nom initialement cité est un nom vernaculaire ou un nom scientifique incomplet alors c’est cette information qui doit être indiquée. C''est l''archivage brut de l''information taxonomique citée, et le nom le plus proche de la source disponible de la donnée. Règles : S''il n''y a pas de nom cité (quelqu''un qui prendrait une photo pour demander ce que c''est à un expert) : noter "Inconnu". Si le nom cité n''a pas été transmis par le producteur, ou qu''il y a eu une perte de cette information liée au système de d''information utilisé (nom cité non stocké par exemple) : noter "Nom perdu".';

COMMENT ON COLUMN observation.cd_nom IS 'Code du taxon « cd_nom » de TaxRef référençant au niveau national le taxon. Le niveau ou rang taxinomique de la DEE doit être celui de la DS.
Si le Cd_Nom pour le taxon observé existe alors il doit être renseigné. Si le taxon n’a pas de code TaxRef, alors se référer à la méthodologie TaxRef http://inpn.mnhn.fr/programme/referentiel-taxonomique-taxref. Ce champ est doit être considéré comme obligatoire si le taxon est présent dans TAXREF.';

COMMENT ON COLUMN observation.cd_ref IS 'Code du taxon « cd_ref » de TaxRef référençant au niveau national le taxon. Le niveau ou rang taxinomique de la DEE doit être celui de la DS. Si le Cd_Ref pour le taxon observé existe alors il doit être renseigné. Si le taxon n’a pas de code TaxRef, alors se référer à la méthodologie TaxRef http://inpn.mnhn.fr/programme/referentiel-taxonomique-taxref. Ce champ doit être considéré comme obligatoire si le taxon est présent dans TAXREF.';

COMMENT ON COLUMN observation.version_taxref IS 'Version du référentiel TAXREF utilisée pour le cdNom et le cdRef. Autant que possible au moment de l''échange, on tentera d''utiliser le référentiel en vigueur';

COMMENT ON COLUMN observation.diffusion_niveau_precision IS 'Niveau maximal de précision de la diffusion souhaitée par le producteur vers le grand public. Ne concerne que les DEE non sensibles (i.e. données dont le niveau de sensibilité est de 0). Cet attribut indique si le producteur souhaite que sa DEE non sensible soit diffusée comme toutes les autres, à la commune ou à la maille, ou de façon précise. Règle: Il ne peut être utilisé pour diffuser moins précisément des données que dans le cas de données dont au moins une, au sein d''un regroupement, est sensible suivant la définition du GT sensible. Si aucune donnée n''est sensible, alors le niveau maximal de précision de diffusion sera celui par défaut.';

COMMENT ON COLUMN observation.denombrement_min IS 'Nombre minimum d’individus du taxon composant l’observation';

COMMENT ON COLUMN observation.denombrement_max IS 'Nombre maximum d’individus du taxon composant l’observation';

COMMENT ON COLUMN observation.objet_denombrement IS 'Indique l’objet du dénombrement : individu, couple .... La nomenclature est à définir par extension thématique.';

COMMENT ON COLUMN observation.type_denombrement IS 'Méthode utilisée pour le dénombrement (Inspire)';

COMMENT ON COLUMN observation.commentaire IS 'Champ libre pour informations complémentaires indicatives';

COMMENT ON TABLE observation IS 'Une observation a une seule source qui peut être de 3 types différents : terrain, littérature ou collection. Ils ont des attributs communs JddId et JddCode qui précisent le support de la source, par exemple, le nom de la base de données où est gérée la Donnée Source ou le nom de la collection. Si la source est Littérature, un attribut est nécessaire pour préciser les références bibliographiques. En plus des attributs sur la source, des attributs permettent de caractériser la DEE (sensibilité ...) et de caractériser le sujet de l’observation: le nom du taxon observé, le dénombrement. Une observation est effectuée à une date au jour. En cas de doute sur la date exacte de l’observation, elle peut être représentée par des dates et heures de début et de fin présumées d’observation (période d’imprécision). L’heure de l’observation et la date de la détermination du taxon de l’observation peut être ajoutée.';

COMMENT ON COLUMN observation.date_debut IS 'Date du jour de l’observation dans le système grégorien. En cas d’imprécision, cet attribut représente la date la plus ancienne de la période d’imprécision. Norme ISO8601 : aaaa-mm-jj. Exemple : 2013-11-15';

COMMENT ON COLUMN observation.date_fin IS 'Date du jour de l’observation dans le système grégorien. En cas d’imprécision sur la date, cet attribut représente la date la plus récente de la période d’imprécision. Lorsqu’une observation est faite sur un jour, les dates de début et de fin sont les mêmes (cas le plus courant).
L’emprise temporelle de la DEE doit être la même que celle de la DS dont elle est issue. Si la date précise est connue alors elle est indiquée dans les deux champs :
DateDebut : 2011-02-25
DateFin : 2011-02-25
En cas de date précise inconnue, une fourchette de date dans laquelle l’observation a probablement été effectuée est indiquée dans les deux champs.
Exemple : Si la Date précise n’est pas connue, alors l’imprécision peut être donnée au mois :
DateDebut : 2011-09-01
DateFin : 2011-09-30';

COMMENT ON COLUMN observation.heure_debut IS 'Heure et minute dans le système local auxquelles l’observation du taxon a débuté. Norme ISO8601 : Thh:mmzzzzzz
T est écrit littéralement, hh représente l’heure, mm, les minutes, zzzzzz le fuseau horaire.
Exemple T19:20+01:00';

COMMENT ON COLUMN observation.heure_fin IS 'Heure et minute dans le système local auxquelles l’observation du taxon a pris fin.';

COMMENT ON COLUMN observation.date_determination IS 'Date de la dernière détermination du taxon de l’observation dans le système grégorien';

COMMENT ON COLUMN observation.altitude_min IS 'Altitude Minimum de l’observation en mètre.';

COMMENT ON COLUMN observation.altitude_moy IS 'Altitude moyenne de l''observation.';

COMMENT ON COLUMN observation.altitude_max IS 'Altitude Maximum de l’observation en mètre.';

COMMENT ON COLUMN observation.profondeur_min IS 'Profondeur Minimum de l’observation en mètres selon le référentiel des profondeurs indiqué dans les métadonnées (système de référence spatiale verticale).';

COMMENT ON COLUMN observation.profondeur_moy IS 'Profondeur moyenne de l''observation.';

COMMENT ON COLUMN observation.profondeur_max IS 'Profondeur Maximale de l’observation en mètres selon le référentiel des profondeurs indiqué dans les métadonnées (système de référence spatiale verticale).';

COMMENT ON COLUMN observation.precision_geometrie IS 'Estimation en mètre d’une zone tampon autour de l’objet géographique. Cette précision peut inclure la précision du moyen technique d’acquisition des coordonnées (GPS,...) et/ou du protocole naturaliste.
Ce champ ne peut pas être utilisé pour flouter la donnée.';

COMMENT ON COLUMN observation.nature_objet_geo IS 'Nature de la localisation transmise
Si la couche SIG ou un point (champs x,y) sont échangés alors ce champ doit être renseigné.';

COMMENT ON COLUMN observation.dee_date_derniere_modification IS 'Date de dernière modification de la donnée élémentaire d''échange. Postérieure à la date de transformation en DEE, égale dans le cas de l''absence de modification.';

COMMENT ON COLUMN observation.dee_date_transformation IS 'Date de transformation de la donnée source (DSP ou DSR) en donnée élémentaire d''échange (DEE).';

COMMENT ON COLUMN observation.dee_floutage IS 'Indique si un floutage a été effectué lors de la transformation en DEE. Cela ne concerne que des données d''origine privée.';

COMMENT ON COLUMN observation.organisme_gestionnaire_donnees IS 'Nom de l’organisme qui détient la Donnée Source (DS) de la DEE et qui en a la responsabilité. Si plusieurs organismes sont nécessaires, les séparer par des virgules.';

COMMENT ON COLUMN observation.org_transformation IS 'Nom de l''organisme ayant créé la DEE finale (plate-forme ou organisme mandaté par elle). Autant que possible, on utilisera des noms issus de l''annuaire du SINP lorsqu''il sera publié.';

COMMENT ON COLUMN observation.organisme_standard IS 'Nom(s) de(s) organisme(s) qui ont participés à la standardisation de la DS en DEE (codage, formatage, recherche des données obligatoires).';

COMMENT ON COLUMN observation.geom IS 'Géométrie de l''objet. Il peut être de type Point, Polygone ou Polyligne ou Multi, mais pas complexe (pas de mélange des types)';

COMMENT ON COLUMN observation.odata IS 'Field to store temporary data in json format, used for imports';

COMMENT ON COLUMN observation.validite_niveau IS 'Niveau de validité scientifique de l''observation';

COMMENT ON COLUMN observation.validite_date_validation IS 'Date de réalisation de la validation scientifique de l''observation';

COMMENT ON COLUMN observation.descriptif_sujet IS 'Donnée sur le descriptif_sujet, au format JSON.';
COMMENT ON COLUMN observation.donnee_complementaire IS 'Données complémentaires issues de la source de données, mais en dehors du format Occurences de taxon. Gardé ici pour conservation. Au format JSON';

COMMENT ON COLUMN occtax.observation.cd_nom_cite IS 'Code du taxon « cd_nom » de TaxRef référençant au niveau national le taxon tel qu''il a été initialement cité par l''observateur dans le champ nom_cite. Le rang taxinomique de la donnée doit être celui de la donnée d''origine. Par défaut, cd_nom = cd_nom_cite. cd_nom peut être modifié dans le cas de la procédure de validation après accord du producteur selon les règles définies dans le protocole régional de validation.' ;

-- Table personne
CREATE TABLE personne (
    id_personne serial,
    identite text NOT NULL,
    prenom text,
    nom text,
    mail text,
    id_organisme integer NOT NULL DEFAULT -1,
    anonymiser boolean,
    CONSTRAINT personne_identite_valide CHECK ( identite NOT LIKE '%,%' ),
    CONSTRAINT personne_identite_organisme_mail_key UNIQUE (identite, id_organisme, mail)
);
ALTER TABLE personne ADD PRIMARY KEY (id_personne);

COMMENT ON TABLE personne IS 'Liste des personnes participant aux observations. Cette table est remplie de manière automatique lors des imports de données. Il n''est pas assuré que chaque personne ne représente pas plusieurs homonymes.';
COMMENT ON COLUMN personne.id_personne IS 'Identifiant de la personne (valeur autoincrémentée)';
COMMENT ON COLUMN personne.identite IS 'Identité de la personne. NOM Prénom (organisme) de la personne ou des personnes concernées. Le nom est en majuscules, le prénom en minuscules, l''organisme entre parenthèses.';
COMMENT ON COLUMN personne.prenom IS 'Prénom de la personne.';
COMMENT ON COLUMN personne.nom IS 'Nom de la personne.';
COMMENT ON COLUMN personne.mail IS 'Email de la personne. Optionnel';
COMMENT ON COLUMN personne.id_organisme IS 'Identifiant de l''organisme, en lien avec la table observation. On utilise -1 par défaut, qui correspond à un organisme non défini, à remplacer par organisme inconnu ou indépendant.
Règles : "Indépendant" si la personne n''est pas affiliée à un organisme; "Inconnu" si l''affiliation à un organisme n''est pas connue.';
COMMENT ON COLUMN personne.anonymiser IS 'Si vrai, alors on ne doit pas diffuser le nom de l''observateur ou autre rôle, ni son organisme dans le détail des observations.';

-- Table pivot entre observation et personne
CREATE TABLE observation_personne (
    cle_obs bigint,
    id_personne integer,
    role_personne text ,
    CONSTRAINT observation_personne_valide CHECK ( role_personne IN ('Obs', 'Det', 'Val') )

);
ALTER TABLE observation_personne ADD PRIMARY KEY (cle_obs, id_personne, role_personne);

-- on supprime les lignes de observation_personne quand on supprime des observations
ALTER TABLE observation_personne ADD CONSTRAINT observation_personne_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;

-- on empêche la suppression de personnes référencées dans observation_personne
ALTER TABLE observation_personne ADD CONSTRAINT observation_personne_id_personne_fk FOREIGN KEY (id_personne) REFERENCES personne (id_personne) ON DELETE RESTRICT;

COMMENT ON TABLE observation_personne IS 'Table pivot entre les observations et les personnes. Le champ role_personne permet de renseigner le type de relation (voir nomenclature)';
COMMENT ON COLUMN observation_personne.cle_obs IS 'Indentifiant de l''observation';
COMMENT ON COLUMN observation_personne.id_personne IS 'Identifiant de la personne';
COMMENT ON COLUMN observation_personne.role_personne IS 'Rôle de la personne. Voir nomenclature.';


-- Table localisation_commune
CREATE TABLE localisation_commune (
    cle_obs bigint NOT NULL,
    code_commune text NOT NULL,
    type_info_geo text NOT NULL,
    CONSTRAINT localisation_commune_type_info_geo_valide CHECK ( type_info_geo IN ('1', '2') )
);

ALTER TABLE localisation_commune ADD PRIMARY KEY (cle_obs, code_commune);
ALTER TABLE localisation_commune ADD CONSTRAINT localisation_commune_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;

COMMENT ON TABLE localisation_commune IS 'Table de lien qui stocke la/les commune(s) où a été effectuée l’observation suivant le référentiel INSEE en vigueur.';

COMMENT ON COLUMN localisation_commune.cle_obs IS 'Clé de l observation';

COMMENT ON COLUMN localisation_commune.code_commune IS 'Code de la/les commune(s) où a été effectuée l’observation suivant le référentiel INSEE en vigueur.';

COMMENT ON COLUMN localisation_commune.type_info_geo IS 'Indique le type d''information géographique suivant la nomenclature TypeInfoGeoValue. Exemple : "1" pour "Géoréférencement", "2" pour "Rattachement"';

-- Table localisation_departement
CREATE TABLE localisation_departement (
    cle_obs bigint NOT NULL,
    code_departement text NOT NULL,
    type_info_geo text NOT NULL,
    CONSTRAINT localisation_departement_type_info_geo_valide CHECK ( type_info_geo IN ('1', '2') )
);

ALTER TABLE localisation_departement ADD PRIMARY KEY (cle_obs, code_departement);
ALTER TABLE localisation_departement ADD CONSTRAINT localisation_departement_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;

COMMENT ON TABLE localisation_departement IS 'Table de lien qui stocke le/les departement(s) où a été effectuée l’observation suivant le référentiel INSEE en vigueur.';

COMMENT ON COLUMN localisation_departement.cle_obs IS 'Clé de l observation';

COMMENT ON COLUMN localisation_departement.code_departement IS 'Code du/des departement(s) où a été effectuée l’observation suivant le référentiel INSEE en vigueur.';

COMMENT ON COLUMN localisation_departement.type_info_geo IS 'Indique le type d''information géographique suivant la nomenclature TypeInfoGeoValue. Exemple : "1" pour "Géoréférencement", "2" pour "Rattachement"';


-- Table localisation_maille_10
CREATE TABLE localisation_maille_10 (
    cle_obs bigint NOT NULL,
    code_maille text NOT NULL,
    type_info_geo text NOT NULL,
    CONSTRAINT localisation_maille_10_type_info_geo_valide CHECK ( type_info_geo IN ('1', '2') )
);

ALTER TABLE localisation_maille_10 ADD PRIMARY KEY (cle_obs, code_maille);
ALTER TABLE localisation_maille_10 ADD CONSTRAINT localisation_maille_10_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;

COMMENT ON TABLE localisation_maille_10 IS 'Table de lien entre une table maille_10 (optionnelle) et la table des observations. Elle recense la ou les mailles sur laquelle l’observation a eu lieu';

COMMENT ON COLUMN localisation_maille_10.cle_obs IS 'Clé de l observation';

COMMENT ON COLUMN localisation_maille_10.code_maille IS 'Cellule de la grille de référence nationale 10kmx10km dans laquelle se situe l’observation. Vocabulaire contrôlé : Référentiel « Grille nationale 10kmx10km », lien: http://inpn.mnhn.fr/telechargement/cartes-et-information-
geographique/ref , champ « CD_SIG »';

COMMENT ON COLUMN localisation_maille_10.type_info_geo IS 'Indique le type d''information géographique suivant la nomenclature TypeInfoGeoValue. Exemple : "1" pour "Géoréférencement", "2" pour "Rattachement"';


-- Table localisation_maille_05
CREATE TABLE localisation_maille_05 (
    cle_obs bigint NOT NULL,
    code_maille text NOT NULL,
    type_info_geo text NOT NULL,
    CONSTRAINT localisation_maille_05_type_info_geo_valide CHECK ( type_info_geo IN ('1', '2') )
);

ALTER TABLE localisation_maille_05 ADD PRIMARY KEY (cle_obs, code_maille);
ALTER TABLE localisation_maille_05 ADD CONSTRAINT localisation_maille_05_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;

COMMENT ON TABLE localisation_maille_05 IS 'Table de lien entre une table maille_05 (optionnelle) et la table des observations. Elle recense la ou les mailles sur laquelle l’observation a eu lieu';

COMMENT ON COLUMN localisation_maille_05.cle_obs IS 'Clé de l observation';

COMMENT ON COLUMN localisation_maille_05.code_maille IS 'Cellule de la grille de référence nationale 5kmx5km dans laquelle se situe l’observation. Vocabulaire contrôlé : Référentiel « Grille nationale 5kmx5km », lien: http://inpn.mnhn.fr/telechargement/cartes-et-information-
geographique/ref , champ « CD_SIG »';

COMMENT ON COLUMN localisation_maille_05.type_info_geo IS 'Indique le type d''information géographique suivant la nomenclature TypeInfoGeoValue. Exemple : "1" pour "Géoréférencement", "2" pour "Rattachement"';


-- Table localisation_maille_02
CREATE TABLE localisation_maille_02 (
    cle_obs bigint NOT NULL,
    code_maille text NOT NULL,
    type_info_geo text NOT NULL,
    CONSTRAINT localisation_maille_02_type_info_geo_valide CHECK ( type_info_geo IN ('1', '2') )
);

ALTER TABLE localisation_maille_02 ADD PRIMARY KEY (cle_obs, code_maille);
ALTER TABLE localisation_maille_02 ADD CONSTRAINT localisation_maille_02_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;

COMMENT ON TABLE localisation_maille_02 IS 'Table de lien entre une table maille_02 (optionnelle) et la table des observations. Elle recense la ou les mailles sur laquelle l’observation a eu lieu';

COMMENT ON COLUMN localisation_maille_02.cle_obs IS 'Clé de l observation';

COMMENT ON COLUMN localisation_maille_02.code_maille IS 'Cellule de la grille de référence nationale 2x2 km dans laquelle se situe l’observation. Vocabulaire contrôlé : Référentiel « Grille nationale 02kmx02km », lien: http://inpn.mnhn.fr/telechargement/cartes-et-information-
geographique/ref , champ « CD_SIG »';

COMMENT ON COLUMN localisation_maille_02.type_info_geo IS 'Indique le type d''information géographique suivant la nomenclature TypeInfoGeoValue. Exemple : "1" pour "Géoréférencement", "2" pour "Rattachement"';

-- Table localisation_maille_01
CREATE TABLE localisation_maille_01 (
    cle_obs bigint NOT NULL,
    code_maille text NOT NULL,
    type_info_geo text NOT NULL,
    CONSTRAINT localisation_maille_01_type_info_geo_valide CHECK ( type_info_geo IN ('1', '2') )
);

ALTER TABLE localisation_maille_01 ADD PRIMARY KEY (cle_obs, code_maille);
ALTER TABLE localisation_maille_01 ADD CONSTRAINT localisation_maille_01_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;

COMMENT ON TABLE localisation_maille_01 IS 'Table de lien entre une table maille_01 (optionnelle) et la table des observations. Elle recense la ou les mailles sur laquelle l’observation a eu lieu';

COMMENT ON COLUMN localisation_maille_01.cle_obs IS 'Clé de l observation';

COMMENT ON COLUMN localisation_maille_01.code_maille IS 'Cellule de la grille de référence nationale 1x1 km dans laquelle se situe l’observation. Vocabulaire contrôlé : Référentiel « Grille nationale 01kmx01km », lien: http://inpn.mnhn.fr/telechargement/cartes-et-information-
geographique/ref , champ « CD_SIG »';

COMMENT ON COLUMN localisation_maille_01.type_info_geo IS 'Indique le type d''information géographique suivant la nomenclature TypeInfoGeoValue. Exemple : "1" pour "Géoréférencement", "2" pour "Rattachement"';


-- Table localisation_espace_naturel
CREATE TABLE localisation_espace_naturel (
    cle_obs bigint NOT NULL,
    code_en text NOT NULL,
    type_info_geo text NOT NULL,
    CONSTRAINT localisation_espace_naturel_type_info_geo_valide CHECK ( type_info_geo IN ('1', '2') )
);

ALTER TABLE localisation_espace_naturel ADD PRIMARY KEY (cle_obs, code_en);
ALTER TABLE localisation_espace_naturel ADD CONSTRAINT localisation_espace_naturel_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;

COMMENT ON TABLE localisation_espace_naturel IS 'Table de lien entre la localisation et l’espace naturel';

COMMENT ON COLUMN localisation_espace_naturel.cle_obs IS 'Clé de l observation';

COMMENT ON COLUMN localisation_espace_naturel.code_en IS 'Code de l’espace naturel sur lequel a été faite l’observation.';

COMMENT ON COLUMN localisation_espace_naturel.type_info_geo IS 'Indique le type d''information géographique suivant la nomenclature TypeInfoGeoValue. Exemple : "1" pour "Géoréférencement", "2" pour "Rattachement"';


-- Table localisation_masse_eau
CREATE TABLE localisation_masse_eau (
    cle_obs bigint,
    code_me text,
    type_info_geo text NOT NULL,
    CONSTRAINT localisation_masse_eau_type_info_geo_valide CHECK ( type_info_geo IN ('1', '2') )
);

ALTER TABLE localisation_masse_eau ADD PRIMARY KEY (cle_obs, code_me);
ALTER TABLE localisation_masse_eau ADD CONSTRAINT localisation_masse_eau_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;

COMMENT ON TABLE localisation_masse_eau IS 'Table de lien avec les masses d’eau';

COMMENT ON COLUMN localisation_masse_eau.cle_obs IS 'Identifiant de l'' observation';

COMMENT ON COLUMN localisation_masse_eau.code_me IS 'Code de la ou les masse(s) d’eau à la (aux)quelle(s) l’observation a été rattachée';

COMMENT ON COLUMN localisation_masse_eau.type_info_geo IS 'Indique le type d''information géographique suivant la nomenclature TypeInfoGeoValue. Exemple : "1" pour "Géoréférencement", "2" pour "Rattachement"';


-- Table listant les référentiels habitat
CREATE TABLE referentiel_habitat(
    ref_habitat text NOT NULL,
    libelle text NOT NULL,
    definition text NOT NULL,
    creation text NOT NULL,
    modification text NOT NULL
);
ALTER TABLE referentiel_habitat ADD PRIMARY KEY ( ref_habitat );

COMMENT ON TABLE referentiel_habitat IS 'Référentiel d''habitats et typologies. Source: http://standards-sinp.mnhn.fr/nomenclature/';
COMMENT ON COLUMN referentiel_habitat.ref_habitat IS 'Code du référentiel habitat';
COMMENT ON COLUMN referentiel_habitat.libelle IS 'Libellé du référentiel habitat';
COMMENT ON COLUMN referentiel_habitat.definition IS 'Définition du référentiel habitat';
COMMENT ON COLUMN referentiel_habitat.creation IS 'Date de création du référentiel habitat';
COMMENT ON COLUMN referentiel_habitat.modification IS 'Date de modification du référentiel habitat';


-- Table habitat compilant les différents habitat
CREATE TABLE habitat (
    ref_habitat text NOT NULL,
    code_habitat text NOT NULL,
    code_habitat_parent text,
    niveau_habitat integer,
    libelle_habitat text,
    description_habitat text,
    tri_habitat smallint,
    cd_hab text
    -- , CONSTRAINT habitat_ref_habitat_valide CHECK ( ref_habitat IN ('PVF', 'BRYOSOCIO', 'BBMEDFR', 'PALSPM', 'ANTMER', 'GUYMER', 'REUMER', 'CORINEBIOTOPES', 'PAL', 'EUNIS', 'GMRC', 'CH', 'OSPAR', 'BARC', 'REBENT') )
);

ALTER TABLE habitat ADD PRIMARY KEY ( ref_habitat, code_habitat );

COMMENT ON TABLE habitat IS 'Table recensant les habitats. Les codes des différents référentiels sont accessibles sur http://inpn.mnhn.fr/programme/referentiels-habitats ';
COMMENT ON COLUMN habitat.ref_habitat IS 'Code de référence de l''habitat. Voir la table de nomenclature pour les listes';
COMMENT ON COLUMN habitat.code_habitat IS 'Code de l''habitat. Correspond au lb_code d''HABREF ie le code unique dans la typologie.';
COMMENT ON COLUMN habitat.code_habitat_parent IS 'Code de l''habitat du parent, en lien avec le champ code_habitat';
COMMENT ON COLUMN habitat.niveau_habitat IS 'Niveau de l''habitat';
COMMENT ON COLUMN habitat.libelle_habitat IS 'Libellé de l''habitat';
COMMENT ON COLUMN habitat.description_habitat IS 'Description de l''habitat';
COMMENT ON COLUMN habitat.tri_habitat IS 'Clé de tri de l''habitat';
COMMENT ON COLUMN habitat.cd_hab IS 'Code HABREF de l''habitat. NULL si pas encore dans HABREF';

-- Table de lien habitat / localisation
CREATE TABLE localisation_habitat (
    cle_obs bigint NOT NULL,
    ref_habitat text NOT NULL,
    code_habitat text NOT NULL
);

ALTER TABLE localisation_habitat ADD PRIMARY KEY (cle_obs, ref_habitat, code_habitat);
ALTER TABLE localisation_habitat ADD CONSTRAINT localisation_habitat_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;

COMMENT ON TABLE localisation_habitat IS 'Table de lien etre les tables habitat et localisation';

COMMENT ON COLUMN localisation_habitat.cle_obs IS 'Clé de l observation';
COMMENT ON COLUMN localisation_habitat.ref_habitat IS 'Code référentiel de la bdd habitat où le taxon de l’observation a été identifié. Par exemple HABREF';
COMMENT ON COLUMN localisation_habitat.code_habitat IS 'Code de l’habitat où le taxon de l’observation a été identifié.';




-- Table attribut_additionnel
CREATE TABLE attribut_additionnel (
    cle_obs bigint NOT NULL,
    nom text NOT NULL,
    definition text NOT NULL,
    valeur text NOT NULL,
    unite text,
    thematique text NOT NULL,
    "type" text NOT NULL,

    CONSTRAINT attribut_additionnel_type_valide CHECK ("type" IS NULL OR ( "type" IN ('QTA', 'QUAL') )),
    CONSTRAINT attribut_additionnel_unite_valide CHECK ( ("type" = 'QTA' AND "unite" IS NOT NULL) OR "type" != 'QTA' )

);
ALTER TABLE attribut_additionnel ADD PRIMARY KEY (cle_obs, nom);
ALTER TABLE attribut_additionnel ADD CONSTRAINT attribut_additionnel_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;

COMMENT ON TABLE attribut_additionnel IS 'Les attributs additionnels sont des informations non prévues par le cœur de standard qui peuvent être ajoutées si besoin et sous réserve que l’information ajoutée soit décrite de manière satisfaisante directement dans le standard. De plus ces attributs ne doivent pas être utilisés pour modifier le sens d’un attribut du cœur du standard ou d’une extension.';

COMMENT ON COLUMN attribut_additionnel.cle_obs IS 'Cle de l observation';

COMMENT ON COLUMN attribut_additionnel.nom IS 'Libellé court et implicite de l''attribut';
COMMENT ON COLUMN attribut_additionnel.definition IS 'Définition précise et complète de l''attribut';
COMMENT ON COLUMN attribut_additionnel.valeur IS 'Valeur qualitative ou quantitative de l''attribut';
COMMENT ON COLUMN attribut_additionnel.type IS 'Indique si l''attribut additionnel est de type quantitatif ou qualitatif.';
COMMENT ON COLUMN attribut_additionnel.unite IS 'Unité de mesure de l’attribut additionnel. Exemple : degré Celsius, mètre, kilogramme, hectare). Règle : Les unités doivent être exprimées en système international dès que possible (°C, m, kg, ha, etc.)';
COMMENT ON COLUMN attribut_additionnel.thematique IS 'Thématique relative à l''attribut additionnel (mot-clé). La première lettre doit toujours être en majuscule, le reste en minuscules.';


CREATE TABLE jdd (
    jdd_id text NOT NULL PRIMARY KEY,
    jdd_code text NOT NULL,
    jdd_libelle text,
    jdd_description text,
    jdd_metadonnee_dee_id text NOT NULL,
    jdd_cadre text,
    ayants_droit jsonb,
    date_minimum_de_diffusion date
);

COMMENT ON TABLE jdd IS 'Recense les jeux de données officiels du standard Occurence de taxons. Un jeu de données correspond souvent à une base de données';
COMMENT ON COLUMN jdd.jdd_id IS 'Un identifiant pour la collection ou le jeu de données terrain d’où provient l’enregistrement. Exemple code IDCNP pour l’INPN : « 00-15 ».';
COMMENT ON COLUMN jdd.jdd_code IS 'Le nom, l’acronyme, le code ou l’initiale identifiant la collection ou le jeu de données dont l’enregistrement de la Donnée Source provient. Exemple « INPN », « Silène », « BDMAP »';
COMMENT ON COLUMN jdd.jdd_libelle IS 'Libellé court et intelligible du jeu de données';
COMMENT ON COLUMN jdd.jdd_description IS 'Description du jeu de données';
COMMENT ON COLUMN jdd.jdd_metadonnee_dee_id IS 'Identifiant permanent et unique de la fiche métadonnées du jeu de données auquel appartient la donnée. Cet identifiant est attribué par la plateforme';
COMMENT ON COLUMN jdd.jdd_cadre IS 'Cadre d''acquisition qui permet de regrouper des jdd de même producteur. Ex: on peut avoir un jdd_id par annee pour le même cadre d''acquisition';
COMMENT ON COLUMN jdd.ayants_droit IS 'Liste et rôle des structures ayant des droits sur le jeu de données, et rôle concerné (ex : financeur, maître d''oeuvre...). Stocker les structures via leur id_organisme';
COMMENT ON COLUMN jdd.date_minimum_de_diffusion IS 'Pour les données de recherche, les producteurs peuvent attendre que la publication scientifique soit publiée avant de diffuser les données. Cette date est utilisée dans le requête de création de la vue matérialisée occtax.vm_observation pour ne pas prendre en compte les données dont la date minimum n''est pas atteinte';

-- Table lien_observation_identifiant_permanent
-- utilisée pour ne pas perdre les enregistrements permanents lors d'un réimport et écrasement de données d'un même jdd
CREATE TABLE lien_observation_identifiant_permanent (
    jdd_id text NOT NULL,
    identifiant_origine text NOT NULL,
    identifiant_permanent text NOT NULL,
    dee_date_derniere_modification timestamp with time zone,
    dee_date_transformation timestamp with time zone
);

COMMENT ON TABLE lien_observation_identifiant_permanent IS 'Table utilisée pour conserver les identifiants permanents générés lors de l''import des observations. Cela permet de réutiliser les mêmes identifiants permanents lors d''un réimport par écrasement des données.';

COMMENT ON COLUMN lien_observation_identifiant_permanent.jdd_id IS 'Identifiant du jeu de données';

COMMENT ON COLUMN lien_observation_identifiant_permanent.identifiant_origine IS 'Identifiant d''origine de la données';

COMMENT ON COLUMN lien_observation_identifiant_permanent.dee_date_derniere_modification IS 'Date de dernière modification de la donnée élémentaire d''échange. Postérieure à la date de transformation en DEE, égale dans le cas de l''absence de modification.';

COMMENT ON COLUMN lien_observation_identifiant_permanent.dee_date_transformation IS 'Date de transformation de la donnée source (DSP ou DSR) en donnée élémentaire d''échange (DEE).';

ALTER TABLE occtax.lien_observation_identifiant_permanent
ADD CONSTRAINT lien_observation_identifiant__jdd_id_identifiant_origine_id_key UNIQUE (jdd_id, identifiant_origine, identifiant_permanent);


-- Table organisme
CREATE TABLE "organisme" (
    id_organisme serial PRIMARY KEY,
    nom_organisme text NOT NULL,
    sigle TEXT, -- Sigle de la structure
    responsable text, -- Nom de la personne responsable de la structure, pour les envois postaux officiels
    adresse1 TEXT, -- Adresse de niveau 1
    adresse2 TEXT, -- Adresse de niveau 2
    cs TEXT, -- Courrier spécial
    cp integer, -- Code postal
    commune TEXT, -- Commune
    cedex TEXT, -- CEDEX
    csr boolean, -- Indique si la structure est membre du Comité de suivi régional du SINP
    commentaire character varying, -- Commentaire sur la structure
    uuid_national text, -- Identifiant national (UUID)
    date_maj timestamp without time zone DEFAULT (now())::timestamp without time zone -- Date à laquelle l'enregistrement a été modifé pour la dernière fois (rempli automatiquement)
);
ALTER TABLE "organisme" ADD UNIQUE (nom_organisme);


COMMENT ON TABLE "organisme" IS 'Organismes listés dans l''application. Par exemple, les organismes liés aux observations peuvent être liés à cette table. Ou les demandes du module optionnel de gestion sont rattachées à un organisme.';
COMMENT ON COLUMN "organisme".id_organisme IS 'Identifiant de l''organisme.';
COMMENT ON COLUMN "organisme".nom_organisme IS 'Nom de l''organisme.';
COMMENT ON COLUMN occtax.organisme.sigle IS 'Sigle de la structure' ;
COMMENT ON COLUMN occtax.organisme.responsable IS 'Nom de la personne responsable de la structure, pour les envois postaux officiels' ;
COMMENT ON COLUMN occtax.organisme.adresse1 IS 'Adresse de niveau 1' ;
COMMENT ON COLUMN occtax.organisme.adresse2 IS 'Adresse de niveau 2' ;
COMMENT ON COLUMN occtax.organisme.cs IS 'Courrier spécial' ;
COMMENT ON COLUMN occtax.organisme.cp IS 'Code postal' ;
COMMENT ON COLUMN occtax.organisme.commune IS 'Commune' ;
COMMENT ON COLUMN occtax.organisme.cedex IS 'CEDEX' ;
COMMENT ON COLUMN occtax.organisme.csr IS 'Indique si la structure est membre du Comité de suivi régional du SINP' ;
COMMENT ON COLUMN occtax.organisme.commentaire IS 'Commentaire sur la structure' ;
COMMENT ON COLUMN occtax.organisme.uuid_national IS 'Identifiant de l''organisme au niveau national (uuid)';
COMMENT ON COLUMN occtax.organisme.date_maj IS 'Date à laquelle l''enregistrement a été modifé pour la dernière fois (rempli automatiquement)' ;

-- Fonction trigger mettant à jour un champ date_maj automatiquement
DROP FUNCTION IF EXISTS occtax.maj_date();
CREATE OR REPLACE FUNCTION occtax.maj_date()
RETURNS trigger AS
$BODY$
    BEGIN
        NEW.date_maj=current_TIMESTAMP(0);
        RETURN NEW ;
    END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


-- Trigger mettant à jour le champ automatiquement
CREATE TRIGGER tr_date_maj
  BEFORE UPDATE
  ON occtax.organisme
  FOR EACH ROW
  EXECUTE PROCEDURE occtax.maj_date();

-- Ajout d'un organisme avec id = -1 pour faciliter les imports (en évitant soucis de contraintes de clé étrangère)
INSERT INTO organisme (id_organisme, nom_organisme, commentaire)
VALUES (-1, 'Non défini', 'Organisme non défini. Utiliser pour éviter les soucis de contrainte de clé étrangère avec la table personne. Il faut utiliser l''organisme inconnu ou indépendant à la place')
ON CONFLICT DO NOTHING
;

-- Contrainte d'intégrité entre personne et organisme
ALTER TABLE personne DROP CONSTRAINT IF EXISTS personne_id_organisme_fkey;
ALTER TABLE personne ADD CONSTRAINT personne_id_organisme_fkey
FOREIGN KEY (id_organisme)
REFERENCES organisme (id_organisme) MATCH SIMPLE
ON UPDATE CASCADE
ON DELETE RESTRICT;


-- View to help query observateurs, determinateurs, validateurs
CREATE OR REPLACE VIEW v_observateur AS
SELECT
CASE WHEN p.anonymiser IS TRUE THEN 'ANONYME' ELSE p.identite END AS identite,
CASE WHEN p.anonymiser IS TRUE THEN '' ELSE p.mail END AS mail,
CASE WHEN p.anonymiser IS TRUE OR lower(p.identite) = lower(nom_organisme) THEN NULL ELSE Coalesce(nom_organisme, 'INCONNU') END AS organisme,
op.id_personne, op.cle_obs, p.prenom, p.nom, p.anonymiser,
p.identite AS identite_non_floutee,
p.mail AS mail_non_floute,
Coalesce(nom_organisme, 'INCONNU') AS organisme_non_floute

FROM observation_personne op
INNER JOIN personne p ON p.id_personne = op.id_personne AND op.role_personne = 'Obs'
INNER JOIN organisme o ON o.id_organisme = p.id_organisme
;



CREATE INDEX IF NOT EXISTS personne_id_organisme_idx ON personne (id_organisme);
CREATE INDEX IF NOT EXISTS personne_identite_lower_idx ON occtax.personne (lower(identite));
CREATE INDEX IF NOT EXISTS organisme_nom_organisme_lower_idx ON occtax.organisme (lower(nom_organisme));

-- imports
CREATE TABLE jdd_import (
    id_import serial PRIMARY KEY,
    jdd_id TEXT NOT NULL,
    libelle text,
    remarque text,
    date_reception date not null,
    date_import date not null,
    nb_donnees_source integer,
    nb_donnees_import integer,
    date_obs_min date,
    date_obs_max date
);

ALTER TABLE jdd_import ADD CONSTRAINT jdd_import_jdd_id_fkey
FOREIGN KEY (jdd_id)
REFERENCES occtax.jdd(jdd_id) MATCH SIMPLE
ON UPDATE CASCADE
ON DELETE RESTRICT
;

COMMENT ON TABLE jdd_import IS 'Enregistre les actions d''import de données dans l''application. Cette table doit être renseignée manuellement à chaque import de données dans le schéma occtax. Cela permet d''avoir un suivi et un descriptif des imports successifs effectués sur l''application.';
COMMENT ON COLUMN jdd_import.id_import IS 'Identifiant unique auto-incrémenté de l''import.';
COMMENT ON COLUMN jdd_import.jdd_id IS 'Identifiant du jeu de données (jdd_id). En lien avec la table occtax.jdd';
COMMENT ON COLUMN jdd_import.libelle IS 'Libellé de l''import';
COMMENT ON COLUMN jdd_import.remarque IS 'Remarque générale sur l''import';
COMMENT ON COLUMN jdd_import.date_reception IS 'Date de la réception des données (envoyée par le producteur)';
COMMENT ON COLUMN jdd_import.date_import IS 'Date à laquelle l''import a été effectué';
COMMENT ON COLUMN jdd_import.nb_donnees_source IS 'Nombre d''items dans le jeu de données source, avant import (par exemple le nombre de lignes dans le fichier CSV, sauf entête)';
COMMENT ON COLUMN jdd_import.nb_donnees_import IS 'Nombre de données réellement importé pendant l''import dans la table occtax.observation (si des clauses WHERE ont été utilisées pour filtrer sur certaines observations)';
COMMENT ON COLUMN jdd_import.date_obs_min IS 'Date minimale des observations importées pour le jdd';
COMMENT ON COLUMN jdd_import.date_obs_max IS 'Date maximale des observations importées pour le jdd';


-- table jdd_correspondance_taxon
CREATE TABLE jdd_correspondance_taxon (
    jdd_id text,
    jdd_cadre text,
    taxon_origine text,
    cd_nom integer,
    version_taxref text
);

ALTER TABLE jdd_correspondance_taxon ADD PRIMARY KEY (jdd_id, taxon_origine);

COMMENT ON TABLE jdd_correspondance_taxon IS 'Table de correspondance entre les codes d''espèces d''origine trouvés dans les jeux de données et le code cd_nom TAXREF';

COMMENT ON COLUMN jdd_correspondance_taxon.jdd_id IS 'Identifiant du jeu de données';
COMMENT ON COLUMN jdd_correspondance_taxon.jdd_cadre IS 'Cadre d''acquisition qui permet de regrouper des jdd de même producteur. Ex: on peut avoir un jdd_id par annee pour le même cadre d''acquisition';
COMMENT ON COLUMN jdd_correspondance_taxon.taxon_origine IS 'Code du taxon dans le jeu de données d''origine';
COMMENT ON COLUMN jdd_correspondance_taxon.cd_nom IS 'Code officiel du taxref (cd_nom)';
COMMENT ON COLUMN jdd_correspondance_taxon.version_taxref IS 'Version du taxref utilisé';





-- Indexes
CREATE INDEX ON attribut_additionnel (cle_obs);

CREATE INDEX ON localisation_commune (cle_obs);
CREATE INDEX ON localisation_commune (code_commune);
CREATE INDEX ON localisation_departement (cle_obs);
CREATE INDEX ON localisation_departement (code_departement);
CREATE INDEX ON localisation_espace_naturel (code_en);
CREATE INDEX ON localisation_espace_naturel (cle_obs);
CREATE INDEX ON localisation_habitat (code_habitat);
CREATE INDEX ON localisation_habitat (cle_obs);
CREATE INDEX ON localisation_maille_10 (code_maille);
CREATE INDEX ON localisation_maille_10 (cle_obs);
CREATE INDEX ON localisation_maille_05 (code_maille);
CREATE INDEX ON localisation_maille_05 (cle_obs);
CREATE INDEX ON localisation_maille_02 (code_maille);
CREATE INDEX ON localisation_maille_02 (cle_obs);
CREATE INDEX ON localisation_maille_01 (code_maille);
CREATE INDEX ON localisation_maille_01 (cle_obs);
CREATE INDEX ON localisation_masse_eau (code_me);
CREATE INDEX ON localisation_masse_eau (cle_obs);

CREATE INDEX ON nomenclature (champ, code);

CREATE INDEX ON observation USING GIST (geom);
CREATE INDEX ON observation (cd_nom);
CREATE INDEX ON observation (date_debut, date_fin DESC);
CREATE INDEX ON observation (jdd_id);
CREATE INDEX ON observation USING GIN (descriptif_sujet);

CREATE INDEX ON personne (identite);

CREATE INDEX ON observation_personne (cle_obs);
CREATE INDEX ON observation_personne (id_personne);
CREATE INDEX ON observation_personne (role_personne);

CREATE INDEX ON habitat (ref_habitat);
CREATE INDEX ON habitat (code_habitat);
CREATE INDEX ON habitat (code_habitat_parent);

CREATE INDEX ON jdd (jdd_code);

CREATE INDEX ON lien_observation_identifiant_permanent (jdd_id, identifiant_origine);

CREATE INDEX ON jdd_correspondance_taxon (jdd_id);

-----------------------
-- Tables SIG
-----------------------

-- Schéma
CREATE SCHEMA sig;
SET search_path TO sig,public,pg_catalog;

-- Table maille_10 = 10km
CREATE TABLE maille_10 (
    id_maille serial PRIMARY KEY,
    code_maille text UNIQUE,
    nom_maille text,
    version_ref text NOT NULL,
    nom_ref text NOT NULL
);
SELECT AddGeometryColumn('maille_10', 'geom', {$SRID}, 'POLYGON', 2);

COMMENT ON TABLE maille_10 IS 'Liste des mailles 10km du territoire.';

COMMENT ON COLUMN maille_10.code_maille IS 'Code de la maille 10km. Ex: 10kmUTM20W510N1660';

COMMENT ON COLUMN maille_10.nom_maille IS 'Code court de la maille 10km. Ex: 510-1660';

COMMENT ON COLUMN maille_10.version_ref IS 'Version du référentiel en vigueur pour le code et le nom de la maille';

COMMENT ON COLUMN maille_10.nom_ref IS 'Nom de la couche de maille utilisée : Concaténation des éléments des colonnes "couche" et "territoire" de la page http://inpn.mnhn.fr/telechargement/cartes-et-information-geographique/ref On n''utilisera que les grilles nationales (les grilles européennes sont proscrites). Exemple : Grilles nationales (10 km x10 km) TAAF';

COMMENT ON COLUMN maille_10.geom IS 'Géométrie de la maille.';


-- Table maille_05 = 5km
CREATE TABLE maille_05 (
    id_maille serial PRIMARY KEY,
    code_maille text UNIQUE,
    nom_maille text,
    version_ref text NOT NULL,
    nom_ref text NOT NULL
);
SELECT AddGeometryColumn('maille_05', 'geom', {$SRID}, 'POLYGON', 2);

COMMENT ON TABLE maille_05 IS 'Liste des mailles 5km du territoire.';

COMMENT ON COLUMN maille_05.code_maille IS 'Code de la maille 5km.';

COMMENT ON COLUMN maille_05.nom_maille IS 'Code court de la maille 5km.';

COMMENT ON COLUMN maille_05.geom IS 'Géométrie de la maille.';

COMMENT ON COLUMN maille_05.version_ref IS 'Version du référentiel en vigueur pour le code et le nom de la maille';

COMMENT ON COLUMN maille_05.nom_ref IS 'Nom de la couche de maille utilisée : Concaténation des éléments des colonnes "couche" et "territoire" de la page http://inpn.mnhn.fr/telechargement/cartes-et-information-geographique/ref On n''utilisera que les grilles nationales (les grilles européennes sont proscrites).';

COMMENT ON COLUMN maille_05.geom IS 'Géométrie de la maille.';

-- Table maille_01  = 1km
CREATE TABLE maille_01 (
    id_maille serial PRIMARY KEY,
    code_maille text UNIQUE,
    nom_maille text,
    version_ref text NOT NULL,
    nom_ref text NOT NULL
);
SELECT AddGeometryColumn('maille_01', 'geom', {$SRID}, 'POLYGON', 2);

COMMENT ON TABLE maille_01 IS 'Liste des mailles 1km du territoire.';

COMMENT ON COLUMN maille_01.code_maille IS 'Code de la maille 1km.';

COMMENT ON COLUMN maille_01.nom_maille IS 'Code court de la maille 1km. Ex: 510-1660';

COMMENT ON COLUMN maille_01.version_ref IS 'Version du référentiel en vigueur pour le code et le nom de la maille';

COMMENT ON COLUMN maille_01.nom_ref IS 'Nom de la couche de maille utilisée : Concaténation des éléments des colonnes "couche" et "territoire" de la page http://inpn.mnhn.fr/telechargement/cartes-et-information-geographique/ref On n''utilisera que les grilles nationales (les grilles européennes sont proscrites).';

COMMENT ON COLUMN maille_01.geom IS 'Géométrie de la maille.';

-- Table maille_02  = 2km
CREATE TABLE maille_02 (
    id_maille serial PRIMARY KEY,
    code_maille text UNIQUE,
    nom_maille text,
    version_ref text NOT NULL,
    nom_ref text NOT NULL
);
SELECT AddGeometryColumn('maille_02', 'geom', {$SRID}, 'POLYGON', 2);

COMMENT ON TABLE maille_02 IS 'Liste des mailles 2km du territoire.';

COMMENT ON COLUMN maille_02.code_maille IS 'Code de la maille 1km.';

COMMENT ON COLUMN maille_02.nom_maille IS 'Code court de la maille 2km. Ex: 510-1660';

COMMENT ON COLUMN maille_02.version_ref IS 'Version du référentiel en vigueur pour le code et le nom de la maille';

COMMENT ON COLUMN maille_02.nom_ref IS 'Nom de la couche de maille utilisée : Concaténation des éléments des colonnes "couche" et "territoire" de la page http://inpn.mnhn.fr/telechargement/cartes-et-information-geographique/ref On n''utilisera que les grilles nationales (les grilles européennes sont proscrites).';

COMMENT ON COLUMN maille_02.geom IS 'Géométrie de la maille.';


-- Table commune
CREATE TABLE commune (
    code_commune text PRIMARY KEY,
    nom_commune text NOT NULL,
    annee_ref integer NOT NULL,
    CONSTRAINT commune_annee_ref_valide CHECK (annee_ref > 1900 AND annee_ref <= (date_part('year', now()))::integer )
);
SELECT AddGeometryColumn('commune', 'geom', {$SRID}, 'MULTIPOLYGON', 2);

COMMENT ON TABLE commune IS 'Liste les communes';

COMMENT ON COLUMN commune.code_commune IS 'Code de la commune suivant le référentiel INSEE en vigueur.';

COMMENT ON COLUMN commune.nom_commune IS 'Nom de la commune suivant le référentiel INSEE en vigueur.';

COMMENT ON COLUMN commune.annee_ref IS 'Année de production du référentiel INSEE, qui sert à déterminer quel est le référentiel en vigueur pour le code et le nom de la commune';

COMMENT ON COLUMN commune.geom IS 'Géométrie de la commune.';

-- Table departement
CREATE TABLE departement (
    code_departement text PRIMARY KEY,
    nom_departement text NOT NULL,
    annee_ref integer NOT NULL
    CONSTRAINT departement_annee_ref_valide CHECK (annee_ref > 1900 AND annee_ref <= (date_part('year', now()))::integer )
);
SELECT AddGeometryColumn('departement', 'geom', {$SRID}, 'MULTIPOLYGON', 2);

COMMENT ON TABLE departement IS 'Liste les départements';

COMMENT ON COLUMN departement.code_departement IS 'Code du département suivant le référentiel INSEE en vigueur.';

COMMENT ON COLUMN departement.nom_departement IS 'Nom du département suivant le référentiel INSEE en vigueur.';

COMMENT ON COLUMN departement.annee_ref IS 'Année de production du référentiel INSEE, qui sert à déterminer quel est le référentiel en vigueur.';

COMMENT ON COLUMN departement.geom IS 'Géométrie du département.';


-- Table espace_naturel
CREATE TABLE espace_naturel (
    code_en text PRIMARY KEY,
    type_en text NOT NULL,
    nom_en text,
    url text,
    version_en text NOT NULL,
    CONSTRAINT en_type_en_valide CHECK (type_en IN ('CPN', 'AAPN', 'RIPN', 'PNM', 'PNR', 'RNN', 'RNC', 'RNR', 'PRN', 'RBD', 'RBI', 'RNCFS', 'RCFS', 'APB', 'MAB', 'SCL', 'RAMSAR', 'ASPIM', 'SCEN', 'ENS', 'OSPAR', 'APIA', 'CARTH', 'ANTAR', 'NAIRO', 'ZHAE', 'BPM', 'N2000', 'ZNIEFF1', 'ZNIEFF2') )
);
SELECT AddGeometryColumn('espace_naturel', 'geom', {$SRID}, 'GEOMETRY', 2);

COMMENT ON TABLE espace_naturel IS 'L’espace naturel sur lequel a été faite l’observation.';

COMMENT ON COLUMN espace_naturel.code_en IS 'Code de l’espace naturel sur lequel a été faite l’observation.';

COMMENT ON COLUMN espace_naturel.type_en IS 'Indique le type d’espace naturel ou de zonage sur lequel a été faite l’observation.';

COMMENT ON COLUMN espace_naturel.version_en IS 'Version du référentiel consulté respectant la norme ISO 8601, sous la forme YYYY-MM-dd (année-mois-jour), YYYY-MM (année-mois), ou YYYY (année).';

COMMENT ON COLUMN espace_naturel.geom IS 'Géometrie de l''espace naturel.';


-- Table masse_eau
CREATE TABLE masse_eau (
    code_me text PRIMARY KEY,
    nom_me text UNIQUE NOT NULL,
    version_me integer NOT NULL,
    date_me date NOT NULL,
    CONSTRAINT masse_eau_version_me_valide CHECK ( version_me IN ('1', '2', '3') ),
    CONSTRAINT masse_eau_date_me_valide CHECK ( date_me < now()::date )
);
SELECT AddGeometryColumn('masse_eau', 'geom', {$SRID}, 'GEOMETRY', 2);

COMMENT ON TABLE masse_eau IS 'Liste des masses d’eau du territoire.';

COMMENT ON COLUMN masse_eau.code_me IS 'Code de la masse d’eau.';

COMMENT ON COLUMN masse_eau.nom_me IS 'Nom de la masse d’eau.';

COMMENT ON COLUMN masse_eau.version_me IS 'Version du référentiel masse d''eau utilisé et prélevé sur le site du SANDRE, telle que décrite sur le site du SANDRE. Autant que possible au moment de l''échange, on tentera d''utiliser le référentiel en vigueur (en date du 06/10/2015, 2 pour la version intermédiaire). Exemple : 2, pour Version Intermédiaire 2013.';

COMMENT ON COLUMN masse_eau.date_me IS 'Date de consultation ou de prélèvement du référentiel sur le site du SANDRE. Attention, pour une même version, les informations peuvent changer d''une date à l''autre.';

COMMENT ON COLUMN masse_eau.geom IS 'Géométrie de la masse d’eau.';

-- Indexes
CREATE INDEX ON commune USING gist (geom);
CREATE INDEX ON departement USING gist (geom);

CREATE INDEX ON maille_10 USING gist (geom);
CREATE INDEX ON maille_10 (code_maille);
CREATE INDEX ON maille_05 USING gist (geom);
CREATE INDEX ON maille_05 (code_maille);
CREATE INDEX ON maille_01 USING gist (geom);
CREATE INDEX ON maille_01 (code_maille);
CREATE INDEX ON maille_02 USING gist (geom);
CREATE INDEX ON maille_02 (code_maille);

CREATE INDEX ON masse_eau USING gist (geom);

CREATE INDEX ON espace_naturel USING gist (geom);
CREATE INDEX ON espace_naturel (type_en);

-- View to help query espace_naturel
CREATE OR REPLACE VIEW occtax.v_localisation_espace_naturel AS
SELECT len.cle_obs, len.code_en, len.type_info_geo, en.type_en, en.version_en
FROM occtax.localisation_espace_naturel AS len
INNER JOIN sig.espace_naturel AS en ON en.code_en = len.code_en;



-- Function to create a regular grid
CREATE OR REPLACE FUNCTION st_fishnet(geom_table text, geom_col text, cellsize float8)
  RETURNS SETOF geometry AS
$BODY$
DECLARE
  sql     TEXT;

BEGIN

    sql := 'WITH
    extent as (
      SELECT ST_Extent(' || geom_col ||') as bbox
      FROM ' || geom_table ||'),

    bnds as (
      SELECT ST_XMin(bbox) as xmin, ST_YMin(bbox) as
              ymin, ST_XMax(bbox) as xmax, ST_YMax(bbox) as ymax
      FROM extent),

    raster as (
      SELECT ST_MakeEmptyRaster(
              ceil((xmax-xmin)/' || cellsize ||')::integer,
              ceil((ymax-ymin)/' || cellsize ||')::integer,
      xmin, ymax, '|| cellsize ||') AS rast
      FROM bnds)

    SELECT (ST_PixelAsPolygons(rast)).geom
    FROM raster;';

     RETURN QUERY EXECUTE sql;

END
$BODY$
LANGUAGE plpgsql STABLE
COST 100;


-- Vues nécessaires pour la fonction d'impression
DROP VIEW IF EXISTS sig.tpl_observation_maille;
CREATE OR REPLACE VIEW sig.tpl_observation_maille AS
SELECT id_maille AS mid, nom_maille AS maille, 10 AS nbobs, 3 AS nbtax, 410 AS rayon, 'red'::text AS color, ''::text AS geojson, ST_Centroid( geom )::geometry(POINT, {$SRID}) AS geom FROM sig.maille_02;

DROP VIEW IF EXISTS sig.tpl_observation_brute_point;
CREATE OR REPLACE VIEW sig.tpl_observation_brute_point AS
SELECT 1::integer AS cle_obs, ''::text AS nom_cite, '1'::bigint AS cd_nom, '2015-01-01'::text AS date_debut, ''::text AS identite_observateur, 'GEO'::text AS source_objet, ''::text AS geojson,
(SELECT geom FROM occtax.observation LIMIT 1 )::geometry(Point, {$SRID}) AS geom;

DROP VIEW IF EXISTS sig.tpl_observation_brute_linestring;
CREATE OR REPLACE VIEW sig.tpl_observation_brute_linestring AS
SELECT 1::integer AS cle_obs, ''::text AS nom_cite, '1'::bigint AS cd_nom, '2015-01-01'::text AS date_debut, ''::text AS identite_observateur, 'GEO'::text AS source_objet, ''::text AS geojson,
(SELECT ST_ExteriorRing(ST_Buffer(geom, 1000)) AS geom FROM occtax.observation LIMIT 1)::geometry(Linestring, {$SRID}) AS geom;

DROP VIEW IF EXISTS sig.tpl_observation_brute_polygon;
CREATE OR REPLACE VIEW sig.tpl_observation_brute_polygon AS
SELECT 1::integer AS cle_obs, ''::text AS nom_cite, '1'::bigint AS cd_nom, '2015-01-01'::text AS date_debut, ''::text AS identite_observateur, 'GEO'::text AS source_objet, ''::text AS geojson,
(SELECT ST_Buffer(geom, 1000) AS geom FROM occtax.observation LIMIT 1)::geometry(Polygon, {$SRID}) AS geom;

DROP VIEW IF EXISTS sig.tpl_observation_brute_centroid;
CREATE OR REPLACE VIEW sig.tpl_observation_brute_centroid AS
SELECT 1::integer AS cle_obs, ''::text AS nom_cite, '1'::bigint AS cd_nom, '2015-01-01'::text AS date_debut, ''::text AS identite_observateur, 'GEO'::text AS source_objet, ''::text AS geojson, (SELECT geom FROM occtax.observation LIMIT 1)::geometry(Point, {$SRID}) AS geom;


-- Fonction pour calculer la sensibilité des données
SET search_path TO occtax,sig,public,pg_catalog;

-- Vue matérialisée pour connaître la diffusion des données
CREATE MATERIALIZED VIEW observation_diffusion AS
SELECT
o.cle_obs,
CASE
    --non sensible : précision maximale, sauf si diffusion_niveau_precision est NOT NULL et != 5
    WHEN sensi_niveau = '0' THEN
        CASE
            WHEN o.ds_publique IN ('Ac', 'Pu', 'Re') THEN '["g", "d", "m10", "m02", "m01", "e", "c", "z"]'::jsonb
            ELSE
                CASE
                    -- tout sauf geom (diffusion standard régionale)
                    WHEN diffusion_niveau_precision = 'm01' THEN '["d", "m10", "m02", "m01", "e", "c", "z"]'::jsonb

                    -- tout sauf geom (diffusion standard régionale)
                    WHEN diffusion_niveau_precision = 'm02' THEN '["d", "m10", "m02", "e", "c", "z"]'::jsonb

                    -- tout sauf geom et maille 2 (diffusion standard nationale):
                    WHEN diffusion_niveau_precision = '0' THEN '["d", "m10", "e", "c", "z"]'::jsonb

                    -- commune et département
                    WHEN diffusion_niveau_precision = '1' THEN '["d", "c"]'::jsonb

                    -- maille 10 et département
                    WHEN diffusion_niveau_precision = '2' THEN '["d", "m10"]'::jsonb

                    -- département
                    WHEN diffusion_niveau_precision = '3'  THEN '["d"]'::jsonb

                    -- non diffusé
                    WHEN diffusion_niveau_precision = '4' THEN NULL::jsonb

                    -- diffusion telle quelle. Si donnée existe, on fourni
                    WHEN diffusion_niveau_precision = '5'  THEN '["g", "d", "m10", "m02", "m01", "e", "c", "z"]'::jsonb

                    ELSE '["d", "m10", "m02", "m01", "e", "c", "z"]'::jsonb
                END
        END

    -- m02 = département, maille 10, maille 2
    WHEN sensi_niveau = 'm02' THEN '["d", "m10", "m02"]'::jsonb

    -- m01 = département, maille 10, maille 2, maille 1
    WHEN sensi_niveau = 'm01' THEN '["d", "m10", "m02", "m01"]'::jsonb

    -- 1 = tout sauf geom et maille 2 et 1: département, maille 10, espace naturel, commune, znieff
    WHEN sensi_niveau = '1' THEN '["d", "m10", "e", "c", "z"]'::jsonb

    -- 2 = département, maille 10
    WHEN sensi_niveau = '2' THEN '["d", "m10"]'::jsonb

    -- 3 = département
    WHEN sensi_niveau = '3' THEN '["d"]'::jsonb

    -- 4 = non diffusé
    WHEN sensi_niveau = '4' THEN NULL::jsonb

    -- aucune valeur
    ELSE NULL::jsonb
END as diffusion

FROM occtax.observation o
;

DROP INDEX IF EXISTS observation_diffusion_cle_obs_idx;
DROP INDEX IF EXISTS observation_diffusion_diffusion_idx;
CREATE INDEX observation_diffusion_cle_obs_idx ON observation_diffusion (diffusion);
CREATE INDEX observation_diffusion_diffusion_idx ON observation_diffusion (cle_obs);


-- Fonction pour calculer les relations entre les observations et les données spatiales
DROP FUNCTION IF EXISTS occtax.occtax_update_spatial_relationships(text[]);
CREATE OR REPLACE FUNCTION occtax.occtax_update_spatial_relationships(jdd_id text[])
  RETURNS integer AS
$BODY$
DECLARE sql_text TEXT;
DECLARE row_count_value INTEGER;
BEGIN

sql_text := '
-- -- localisation_commune
DELETE FROM occtax.localisation_commune
WHERE cle_obs IN (
    SELECT cle_obs FROM occtax.observation WHERE jdd_id = ANY ( $1 ) AND geom IS NOT NULL
);
INSERT INTO occtax.localisation_commune
SELECT DISTINCT
    o.cle_obs,
    c.code_commune,
    ''2'' AS type_info_geo
FROM occtax.observation o
INNER JOIN sig.commune c ON ST_Intersects( o.geom, c.geom )
WHERE 2>1
AND o.jdd_id = ANY ( $1 )
;

-- Départements
DELETE FROM occtax.localisation_departement
WHERE cle_obs IN (
    SELECT cle_obs FROM occtax.observation WHERE jdd_id = ANY ( $1 ) AND geom IS NOT NULL
);
INSERT INTO occtax.localisation_departement
SELECT DISTINCT
    o.cle_obs,
    d.code_departement,
    ''2'' AS type_info_geo
FROM occtax.observation o
INNER JOIN sig.departement d ON ST_Intersects( o.geom, d.geom )
WHERE 2>1
AND o.jdd_id = ANY ( $1 )
;

-- -- -- localisation_maille_10
DELETE FROM occtax.localisation_maille_10
WHERE cle_obs IN (
    SELECT cle_obs FROM occtax.observation WHERE jdd_id = ANY ( $1 ) AND geom IS NOT NULL
);
INSERT INTO occtax.localisation_maille_10
SELECT DISTINCT
    o.cle_obs,
    m.code_maille,
    ''2'' AS type_info_geo
FROM occtax.observation o
INNER JOIN sig.maille_10 m ON ST_Intersects( o.geom, m.geom )
WHERE 2>1
AND o.jdd_id = ANY ( $1 )
AND o.geom IS NOT NULL
;

-- -- -- localisation_maille_05
DELETE FROM occtax.localisation_maille_05
WHERE cle_obs IN (
    SELECT cle_obs FROM occtax.observation WHERE jdd_id = ANY ( $1 ) AND geom IS NOT NULL
);
INSERT INTO occtax.localisation_maille_05
SELECT DISTINCT
    o.cle_obs,
    m.code_maille,
    ''2'' AS type_info_geo
FROM occtax.observation o
INNER JOIN sig.maille_05 m ON ST_Intersects( o.geom, m.geom )
WHERE 2>1
AND o.jdd_id = ANY ( $1 )
AND o.geom IS NOT NULL
;

-- -- -- localisation_maille_02
DELETE FROM occtax.localisation_maille_02
WHERE cle_obs IN (
    SELECT cle_obs FROM occtax.observation WHERE jdd_id = ANY ( $1 ) AND geom IS NOT NULL
);
INSERT INTO occtax.localisation_maille_02
SELECT DISTINCT
    o.cle_obs,
    m.code_maille,
    ''2'' AS type_info_geo
FROM occtax.observation o
INNER JOIN sig.maille_02 m ON ST_Intersects( o.geom, m.geom )
WHERE 2>1
AND o.jdd_id = ANY ( $1 )
AND o.geom IS NOT NULL
;

-- -- -- localisation_maille_01
DELETE FROM occtax.localisation_maille_01
WHERE cle_obs IN (
    SELECT cle_obs FROM occtax.observation WHERE jdd_id = ANY ( $1 ) AND geom IS NOT NULL
);
INSERT INTO occtax.localisation_maille_01
SELECT DISTINCT
    o.cle_obs,
    m.code_maille,
    ''2'' AS type_info_geo
FROM occtax.observation o
INNER JOIN sig.maille_01 m ON ST_Intersects( o.geom, m.geom )
WHERE 2>1
AND o.jdd_id = ANY ( $1 )
AND o.geom IS NOT NULL
;

-- -- -- localisation_masse_eau
DELETE FROM occtax.localisation_masse_eau
WHERE cle_obs IN (
    SELECT cle_obs FROM occtax.observation WHERE jdd_id = ANY ( $1 ) AND geom IS NOT NULL
);
INSERT INTO occtax.localisation_masse_eau
SELECT DISTINCT
    o.cle_obs,
    m.code_me,
    ''2'' AS type_info_geo
FROM occtax.observation o
INNER JOIN sig.masse_eau m ON ST_Intersects( o.geom, m.geom )
WHERE 2>1
AND o.jdd_id = ANY ( $1 )
AND o.geom IS NOT NULL
;

-- -- -- localisation_espace_naturel
DELETE FROM occtax.localisation_espace_naturel
WHERE cle_obs IN (
    SELECT cle_obs FROM occtax.observation WHERE jdd_id = ANY ( $1 ) AND geom IS NOT NULL
);
INSERT INTO occtax.localisation_espace_naturel
SELECT DISTINCT
    o.cle_obs,
    en.code_en,
    ''2'' AS type_info_geo
FROM occtax.observation o
INNER JOIN sig.espace_naturel en ON ST_Intersects( o.geom, en.geom )
WHERE 2>1
AND o.jdd_id = ANY ( $1 )
AND o.geom IS NOT NULL
;

';

-- RAISE NOTICE '%s' , sql_text;

EXECUTE format(sql_text)
USING jdd_id;
RETURN 1;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

