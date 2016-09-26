-- create extensions
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Schéma
CREATE SCHEMA occtax;
SET search_path TO occtax,public,pg_catalog;

-- Table nomenclature
CREATE TABLE nomenclature (
    champ text,
    code text,
    valeur text,
    description text
);

ALTER TABLE nomenclature ADD PRIMARY KEY (champ, code);

COMMENT ON TABLE nomenclature IS 'Stockage de la nomenclature pour les champs des tables qui ont des listes de valeurs prédéfinies.';
COMMENT ON COLUMN nomenclature.champ IS 'Nom du champ';
COMMENT ON COLUMN nomenclature.code IS 'Code associé à une valeur';
COMMENT ON COLUMN nomenclature.valeur IS 'Libellé court. Joue le rôle de valeur';
COMMENT ON COLUMN nomenclature.champ IS 'Description de la valeur';


-- Table principale des observations
CREATE TABLE observation (
    cle_obs bigserial NOT NULL PRIMARY KEY,
    statut_source text NOT NULL,
    reference_biblio text,
    jdd_id text,
    jdd_code text,
    identifiant_origine text,
    identifiant_permanent text,
    ds_publique text NOT NULL,
    code_idcnp_dispositif text,
    statut_observation text NOT NULL,
    cd_nom bigint,
    cd_ref bigint,
    nom_cite text NOT NULL,
    code_sensible text,
    denombrement_min integer,
    denombrement_max integer,
    objet_denombrement text,
    type_denombrement text,
    commentaire text,

    date_debut date NOT NULL,
    date_fin date NOT NULL,
    heure_debut time with time zone,
    heure_fin time with time zone,
    date_determination_obs date,

    altitude_min numeric(6,2),
    altitude_max numeric(6,2),
    profondeur_min numeric(6,2),
    profondeur_max numeric(6,2),
    toponyme text,
    code_departement text,
    x numeric,
    y numeric,
    cle_objet bigint,
    precision numeric,
    nature_objet_geo text,
    restriction_localisation_p text,
    restriction_maille text,
    restriction_commune text,
    restriction_totale text,
    floutage text NOT NULL,

    identite_observateur text NOT NULL,
    organisme_observateur text NOT NULL,
    determinateur text,
    validateur text,
    organisme_gestionnaire_donnees text NOT NULL,
    organisme_standard text,

    CONSTRAINT obs_statut_source_valide CHECK ( statut_source IN ( 'Te', 'Co', 'Li', 'NSP' ) ),
    CONSTRAINT obs_reference_biblio_valide CHECK ( (statut_source = 'Li' AND reference_biblio IS NOT NULL) OR statut_source != 'Li' ),
    CONSTRAINT obs_jdd_id_valide CHECK ( (statut_source IN ('Co', 'Te') AND jdd_id IS NOT NULL) OR statut_source NOT IN ('Co', 'Te') ),
    CONSTRAINT obs_jdd_code_valide CHECK ( (statut_source IN ('Co', 'Te') AND jdd_code IS NOT NULL) OR statut_source NOT IN ('Co', 'Te') ),
    CONSTRAINT obs_ds_publique_valide CHECK ( ds_publique IN ( 'Pu', 'Re', 'Ac', 'Pr', 'NSP' ) ),
    CONSTRAINT obs_statut_observation_valide CHECK ( statut_observation IN ( 'Pr', 'No' ) ),
    CONSTRAINT obs_objet_denombrement_valide CHECK (
        ( (denombrement_min IS NOT NULL OR denombrement_max IS NOT NULL) AND (objet_denombrement = ANY (ARRAY['In'::text, 'NSP'::text])) )
        OR (denombrement_min IS NULL AND denombrement_max IS NULL AND objet_denombrement IS NULL)
    ),
    CONSTRAINT obs_type_denombrement_valide CHECK ( type_denombrement IN ('Co', 'Es', 'Ca', 'NSP') ),
    CONSTRAINT obs_code_sensible_valide CHECK ( code_sensible IN ( '0', '1', '2', '3', '4' ) ),
    CONSTRAINT obs_dates_valide CHECK (date_debut <= date_fin AND date_debut + heure_debut <= date_fin + heure_fin),
    CONSTRAINT obs_nature_objet_geo_valide CHECK ( nature_objet_geo IS NULL OR nature_objet_geo IN ('St', 'In', 'NSP') ),
    CONSTRAINT obs_altitude_min_max_valide CHECK ( Coalesce( altitude_min, 0 ) <= Coalesce( altitude_max, 0 ) ),
    CONSTRAINT obs_profondeur_min_max_valide CHECK ( Coalesce( profondeur_min, 0 ) <= Coalesce( profondeur_max, 0 ) ),
    CONSTRAINT obs_restriction_localisation_p_valide CHECK ( restriction_localisation_p IS NULL OR restriction_localisation_p IN ('Oui', 'Non') ),
    CONSTRAINT obs_restriction_maille_valide CHECK ( restriction_maille IS NULL OR restriction_maille IN ('Oui', 'Non') ),
    CONSTRAINT obs_restriction_commune_valide CHECK ( restriction_commune IS NULL OR restriction_commune IN ('Oui', 'Non') ),
    CONSTRAINT obs_restriction_totale_valide CHECK ( restriction_totale IS NULL OR restriction_totale IN ('Oui', 'Non') ),
    CONSTRAINT obs_floutage_valide CHECK ( floutage IN ('Oui', 'Non', 'NSP') )
);

COMMENT ON TABLE observation IS 'Une observation a une seule source qui peut être de 3 types différents : terrain, littérature ou collection. Ils ont des attributs communs JddId et JddCode qui précisent le support de la source, par exemple, le nom de la base de données où est gérée la Donnée Source ou le nom de la collection. Si la source est Littérature, un attribut est nécessaire pour préciser les références bibliographiques. En plus des attributs sur la source, des attributs permettent de caractériser la DEE (sensibilité ...) et de caractériser le sujet de l’observation: le nom du taxon observé, le dénombrement.';

COMMENT ON COLUMN observation.cle_obs IS 'Attribut technique servant de clé primaire de l’observation. Cet attribut permet de faire le lien avec les autres fichiers fournis lors de l’échange';

COMMENT ON COLUMN observation.statut_source IS 'Indique si la DS de l’observation provient directement du terrain (via un
document informatisé ou une base de données), d’une collection ou de
la littérature';

COMMENT ON COLUMN observation.reference_biblio IS 'Référence de la source de l’observation lorsque celle-ci est de type « Littérature », de préférence au format ISO690. La référence bibliographique doit concerner l’observation même et non uniquement le taxon ou le protocole.';

COMMENT ON COLUMN observation.jdd_id IS 'Un identifiant pour la collection ou le jeu de données terrain d’où provient l’enregistrement. Exemple code IDCNP pour l’INPN : « 00-15 ».';

COMMENT ON COLUMN observation.jdd_code IS 'Le nom, l’acronyme, le code ou l’initiale identifiant la collection ou le jeu de données dont l’enregistrement de la Donnée Source provient. Exemple « INPN », « Silène », « BDMAP »';

COMMENT ON COLUMN observation.identifiant_origine IS 'Identifiant unique de la Donnée Source de l’observation dans la base de données, elle-même caractérisée par jddId et/ou jddCode, où est stockée et initialement gérée la Donnée Source. L’identifiant ne doit pas être la clé primaire technique, susceptible de varier selon les choix de gestion de l’outil de stockage.';

COMMENT ON COLUMN observation.identifiant_permanent IS 'Identifiant unique et pérenne de la Donnée Elémentaire d’Echange de l’observation dans le SINP attribué par la plateforme régionale ou thématique.';

COMMENT ON COLUMN observation.ds_publique IS 'Indique explicitement si la DS de la DEE est publique ou privée. Ce champ définit uniquement les droits nécessaires et suffisants des DS pour produire une DEE : l’attribut DSPublique ne doit être utilisé que pour indiquer si la DEE résultante est susceptible d’être floutée et ne doit pas être utilisé pour d’autres interprétations.';

COMMENT ON COLUMN observation.code_idcnp_dispositif IS 'Code du dispositif de collecte dans le cadre duquel la donnée a été collectée.';

COMMENT ON COLUMN observation.statut_observation IS 'Indique si le taxon a été observé directement ou indirectement (indices de présence), ou non observé';

COMMENT ON COLUMN observation.nom_cite IS 'Nom du taxon cité à l’origine par l’observateur. Celui-ci peut être le nom scientifique reprenant idéalement en plus du nom latin, l’auteur et la date. Cependant, si le nom initialement cité est un nom vernaculaire ou un nom scientifique incomplet alors c’est cette information qui doit être indiquée.';

COMMENT ON COLUMN observation.cd_nom IS 'Code du taxon « cd_nom » de TaxRef référençant au niveau national le taxon. Le niveau ou rang taxinomique de la DEE doit être celui de la DS.
Si le Cd_Nom pour le taxon observé existe alors il doit être renseigné. Si le taxon n’a pas de code TaxRef, alors se référer à la méthodologie TaxRef http://inpn.mnhn.fr/programme/referentiel-taxonomique-taxref. Ce champ est doit être considéré comme obligatoire si le taxon est présent dans TAXREF.';

COMMENT ON COLUMN observation.cd_ref IS 'Code du taxon « cd_ref » de TaxRef référençant au niveau national le taxon. Le niveau ou rang taxinomique de la DEE doit être celui de la DS.
Si le Cd_Ref pour le taxon observé existe alors il doit être renseigné. Si le taxon n’a pas de code TaxRef, alors se référer à la méthodologie TaxRef http://inpn.mnhn.fr/programme/referentiel-taxonomique-taxref. Ce champ doit être considéré comme obligatoire si le taxon est présent dans TAXREF.
';

COMMENT ON COLUMN observation.code_sensible IS 'Du protocole SINP : Ce sont les données répondant aux critères visés à l article L. 124-4 du code de l environnement dont la consultation ou la communication porte atteinte notamment à la protection de l environnement auquel elles se rapportent. ». La caractéristaion de la sensibilité est définie par le GT données sensibles du SINP';

COMMENT ON COLUMN observation.denombrement_min IS 'Nombre minimum d’individus du taxon composant l’observation';

COMMENT ON COLUMN observation.denombrement_max IS 'Nombre maximum d’individus du taxon composant l’observation';

COMMENT ON COLUMN observation.objet_denombrement IS 'Indique l’objet du dénombrement : individu, couple .... La nomenclature est à définir par extension thématique.';

COMMENT ON COLUMN observation.type_denombrement IS 'Méthode utilisée pour le dénombrement (Inspire)';

COMMENT ON COLUMN observation.commentaire IS 'Champ libre pour informations complémentaires indicatives';


COMMENT ON TABLE observation IS 'Une observation est effectuée à une date au jour. En cas de doute sur la date exacte de l’observation, elle peut être représentée par des dates et heures de début et de fin présumées d’observation (période d’imprécision). L’heure de l’observation et la date de la détermination du taxon de l’observation peut être ajoutée.';

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

COMMENT ON COLUMN observation.date_determination_obs IS 'Date de la dernière détermination du taxon de l’observation dans le système grégorien';

COMMENT ON COLUMN observation.altitude_min IS 'Altitude Minimum de l’observation en mètre. Si une seule mesure d’altitude moyenne est mesurée : inscrire la valeur dans les deux champs';

COMMENT ON COLUMN observation.altitude_max IS 'Altitude Maximum de l’observation en mètre. Si une seule mesure d’altitude moyenne est mesurée : inscrire la valeur dans les deux champs';

COMMENT ON COLUMN observation.profondeur_min IS 'Profondeur Minimum de l’observation en mètre selon le référentiel des profondeurs indiqué dans les métadonnées. Si une seule mesure de profondeur moyenne est mesurée : inscrire la valeur dans les deux champs';

COMMENT ON COLUMN observation.profondeur_max IS 'Profondeur Maximale de l’observation en mètre selon le référentiel des profondeurs indiqué dans les métadonnées. Si une seule mesure de profondeur moyenne est mesurée : inscrire la valeur dans les deux champs';

COMMENT ON COLUMN observation.toponyme IS 'Nom propre du lieu où a été effectuée l’observation. Si plusieurs toponymes sont notés, ils sont listés dans le même champ et séparés par une virgule «, »
Référentiel Préconisé : Toponymie des cartes IGN 1/25 000';

COMMENT ON COLUMN observation.code_departement IS 'Département sur lequel est localisé le taxon observé.
Codes départementaux de l’INSEE : http://www.insee.fr/fr/methodes/nomenclatures/cog/departement.asp';

COMMENT ON COLUMN observation.x IS 'Longitude, coordonnée X de l’observation.
Si les coordonnées sont projetées, alors l’unité est le mètre et le nombre est un entier.
Si les coordonnées ne sont pas projetées, alors l’unité est le degré décimal, et le nombre a jusqu’à 5 chiffres décimaux.
Le système de projection est précisé dans les métadonnées.
Rappel : le point ne doit pas représenter un centroïde (de maille, de commune...). Dans ce cas, il faut véhiculer les fichiers Commune ou Maille.';

COMMENT ON COLUMN observation.y IS 'Latitude, coordonnée Y de l’observation.';

COMMENT ON COLUMN observation.cle_objet IS 'Attribut technique permettant de faire le lien avec l’objet géographique du fichier SIG « St_SIG »
Si l’observation est localisée par un objet géographique, alors CleObjet doit être renseigné';

COMMENT ON COLUMN observation.precision IS 'Estimation en mètre d’une zone tampon autour de l’objet géographique. Cette précision peut inclure la précision du moyen technique d’acquisition des coordonnées (GPS,...) et/ou du protocole naturaliste.
Ce champ ne peut pas être utilisé pour flouter la donnée.';

COMMENT ON COLUMN observation.nature_objet_geo IS 'Nature de la localisation transmise
Si la couche SIG ou un point (champs x,y) sont échangés alors ce champ doit être renseigné.';

COMMENT ON COLUMN observation.restriction_localisation_p IS 'Indique si l’information de la localisation précise est diffusable ou non.';

COMMENT ON COLUMN observation.restriction_maille IS 'Indique si l’information de la localisation à la maille est diffusable ou non.';

COMMENT ON COLUMN observation.restriction_commune IS 'Indique si l’information de la localisation à la commune est diffusable ou non.';

COMMENT ON COLUMN observation.restriction_totale IS 'Indique si l’information de la localisation de l’observation est diffusable ou non.';

COMMENT ON COLUMN observation.floutage IS 'Indique si la donnée a été dégradée ou non';

COMMENT ON COLUMN observation.identite_observateur IS 'Prénom et nom de la ou les personnes ayant réalisées l’observation.
Règle d’écriture : Nom Prénom.
Si plusieurs personnes ont fait l’observation : concaténer les différentes identités séparées par des virgules «, »
Si l’observateur requiert l’anonymat, noter « Anonyme », s’il est inconnu
« NSP »';

COMMENT ON COLUMN observation.organisme_observateur IS 'Nom de l’organisme ou des organismes du ou des observateurs dans le cadre du/desquels ils ont réalisés l’observation.
Si l’observation n’a pas été faite dans le cadre d’un organisme, noter
« indépendant »';

COMMENT ON COLUMN observation.determinateur IS 'Prénom, nom et organisme de la ou les personnes ayant réalisé la détermination taxonomique de l’observation
Règle d’écriture : Nom Prénom (Organisme)
Si l’identité de l’individu n’est pas transmise : noter l’organisme seul : Organisme
Si plusieurs personnes ont fait la détermination : concaténer les différents noms séparés par des virgules: Nom1 Prénom1 (Organisme1), Nom2 Prénom2 (Organisme2)';

COMMENT ON COLUMN observation.validateur IS 'Prénom, nom et/ou organisme de la personne ayant réalisée la validation scientifique de l’observation. Si ce champ est vide cela signifie qu’il n’y a pas eu de validation formelle de la détermination taxonomique. Ce champ est susceptible d’évoluer après les conclusions du GT Validation du SINP.
Règle d’écriture : Nom Prénom (Organisme)
Si l’identité de l’individu n’est pas transmise : Règle d’écriture : Organisme
Si plusieurs personnes ont fait la validation : concaténer les différents noms séparés par des virgules: Nom1 Prénom1 (Organisme1), Nom2 Prénom2 (Organisme2)';

COMMENT ON COLUMN observation.organisme_gestionnaire_donnees IS 'Nom de l’organisme qui détient la Donnée Source (DS) de la DEE et qui en a la responsabilité
Si l’observation est gérée par une personne propre non liée à un organisme, noter son nom ou « indépendant »';

COMMENT ON COLUMN observation.organisme_standard IS 'Nom(s) de(s) organisme(s) qui ont participés à la standardisation de la DS en DEE (codage, formatage, recherche des données obligatoires)';


-- Table objet_geographique
CREATE TABLE objet_geographique (
    cle_objet bigserial NOT NULL PRIMARY KEY
);
SELECT AddGeometryColumn('objet_geographique', 'geom', {$SRID}, 'GEOMETRY', 2);

COMMENT ON TABLE objet_geographique IS 'Geometrie de l’observation d’occurrence de taxon. Elle peut être simple (point, ligne, polygone) ou multiple (multipoint, multiligne, multipolygone). Elle ne peut pas être complexe (point et ligne ou polygone et ligne par exemple). Elle ne représente pas un territoire de rattachement (le centroïde de la commune, la surface d’une maille) mais la localisation réelle de l’observation.';

COMMENT ON COLUMN objet_geographique.cle_objet IS 'Clé de l objet géographique';
COMMENT ON COLUMN objet_geographique.geom IS 'Géométrie de l''objet. Il peut être de type Point, Polygone ou Polyligne';

ALTER TABLE objet_geographique ADD CONSTRAINT geo_geom_valide CHECK (geom IS NOT NULL);

-- Table localisation_commune
CREATE TABLE localisation_commune (
    cle_obs bigint NOT NULL,
    code_commune text NOT NULL
);

ALTER TABLE localisation_commune ADD PRIMARY KEY (cle_obs, code_commune);
ALTER TABLE localisation_commune ADD CONSTRAINT localisation_commune_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;

COMMENT ON TABLE localisation_commune IS 'Table de lien qui stocke la/les commune(s) où a été effectuée l’observation suivant le référentiel INSEE en vigueur.';

COMMENT ON COLUMN localisation_commune.cle_obs IS 'Clé de l observation';

COMMENT ON COLUMN localisation_commune.code_commune IS 'Code de la/les commune(s) où a été effectuée l’observation suivant le référentiel INSEE en vigueur.';

-- Table localisation_departement
CREATE TABLE localisation_departement (
    cle_obs bigint NOT NULL,
    code_departement text NOT NULL
);

ALTER TABLE localisation_departement ADD PRIMARY KEY (cle_obs, code_departement);
ALTER TABLE localisation_departement ADD CONSTRAINT localisation_departement_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;

COMMENT ON TABLE localisation_departement IS 'Table de lien qui stocke le/les departement(s) où a été effectuée l’observation suivant le référentiel INSEE en vigueur.';

COMMENT ON COLUMN localisation_departement.cle_obs IS 'Clé de l observation';

COMMENT ON COLUMN localisation_departement.code_departement IS 'Code du/des departement(s) où a été effectuée l’observation suivant le référentiel INSEE en vigueur.';


-- Table localisation_maille_10
CREATE TABLE localisation_maille_10 (
    cle_obs bigint NOT NULL,
    code_maille text NOT NULL
);

ALTER TABLE localisation_maille_10 ADD PRIMARY KEY (cle_obs, code_maille);
ALTER TABLE localisation_maille_10 ADD CONSTRAINT localisation_maille_10_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;

COMMENT ON TABLE localisation_maille_10 IS 'Table de lien entre une table maill_10 (optionnelle) et la table des observations. Elle recense la ou les mailles sur laquelle l’observation a eu lieu';

COMMENT ON COLUMN localisation_maille_10.cle_obs IS 'Clé de l observation';

COMMENT ON COLUMN localisation_maille_10.code_maille IS 'Cellule de la grille de référence nationale 10kmx10km dans laquelle se situe l’observation. Vocabulaire contrôlé : Référentiel « Grille nationale 10kmx10km », lien: http://inpn.mnhn.fr/telechargement/cartes-et-information-
geographique/ref , champ « CD_SIG »';


-- Table localisation_maille_05
CREATE TABLE localisation_maille_05 (
    cle_obs bigint NOT NULL,
    code_maille text NOT NULL
);

ALTER TABLE localisation_maille_05 ADD PRIMARY KEY (cle_obs, code_maille);
ALTER TABLE localisation_maille_05 ADD CONSTRAINT localisation_maille_05_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;

COMMENT ON TABLE localisation_maille_05 IS 'Table de lien entre une table maille_05 (optionnelle) et la table des observations. Elle recense la ou les mailles sur laquelle l’observation a eu lieu';

COMMENT ON COLUMN localisation_maille_05.cle_obs IS 'Clé de l observation';

COMMENT ON COLUMN localisation_maille_05.code_maille IS 'Cellule de la grille de référence nationale 5kmx5km dans laquelle se situe l’observation. Vocabulaire contrôlé : Référentiel « Grille nationale 5kmx5km », lien: http://inpn.mnhn.fr/telechargement/cartes-et-information-
geographique/ref , champ « CD_SIG »';



-- Table localisation_espace_naturel
CREATE TABLE localisation_espace_naturel (
    cle_obs bigint NOT NULL,
    code_en text NOT NULL
);

ALTER TABLE localisation_espace_naturel ADD PRIMARY KEY (cle_obs, code_en);
ALTER TABLE localisation_espace_naturel ADD CONSTRAINT localisation_espace_naturel_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;

COMMENT ON TABLE localisation_espace_naturel IS 'Table de lien entre la localisation et l’espace naturel';

COMMENT ON COLUMN localisation_espace_naturel.cle_obs IS 'Clé de l observation';

COMMENT ON COLUMN localisation_espace_naturel.code_en IS 'Code de l’espace naturel sur lequel a été faite l’observation.';


-- Table localisation_masse_eau
CREATE TABLE localisation_masse_eau (
    cle_obs bigint,
    code_me text
);

ALTER TABLE localisation_masse_eau ADD PRIMARY KEY (cle_obs, code_me);
ALTER TABLE localisation_masse_eau ADD CONSTRAINT localisation_masse_eau_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;

COMMENT ON TABLE localisation_masse_eau IS 'Table de lien avec les masses d’eau';

COMMENT ON COLUMN localisation_masse_eau.cle_obs IS 'Identifiant de l'' observation';

COMMENT ON COLUMN localisation_masse_eau.code_me IS 'Code de la ou les masse(s) d’eau à la (aux)quelle(s) l’observation a été rattachée';



-- Table habitat compilant les différents habitat dont corine biotope
CREATE TABLE habitat (
ref_habitat text NOT NULL,
code_habitat text NOT NULL,
code_habitat_parent text,
niveau_habitat integer,
libelle_habitat text,
description_habitat text,
tri_habitat smallint
-- , CONSTRAINT habitat_ref_habitat_valide CHECK ( ref_habitat IN ('PVF', 'BRYOSOCIO', 'BBMEDFR', 'PALSPM', 'ANTMER', 'GUYMER', 'REUMER', 'CORINEBIOTOPES', 'PAL', 'EUNIS', 'GMRC', 'CH', 'OSPAR', 'BARC', 'REBENT') )
);
ALTER TABLE habitat ADD PRIMARY KEY ( ref_habitat, code_habitat );

COMMENT ON TABLE habitat IS 'Table recensant les habitats. Les codes des différents référentiels sont accessibles sur http://inpn.mnhn.fr/programme/referentiels-habitats ';
COMMENT ON COLUMN habitat.ref_habitat IS 'Code de référence de l''habitat. Voir la table de nomenclature pour les listes';
COMMENT ON COLUMN habitat.code_habitat IS 'Code de l''habitat';
COMMENT ON COLUMN habitat.code_habitat_parent IS 'Code de l''habitat du parent';
COMMENT ON COLUMN habitat.niveau_habitat IS 'Niveau de l''habitat';
COMMENT ON COLUMN habitat.libelle_habitat IS 'Libellé de l''habitat';
COMMENT ON COLUMN habitat.description_habitat IS 'Description de l''habitat';
COMMENT ON COLUMN habitat.tri_habitat IS 'Clé de tri de l''habitat';


-- Table de lien habitat / localisaiton
CREATE TABLE localisation_habitat (
    cle_obs bigint NOT NULL,
    code_habitat text NOT NULL
);

ALTER TABLE localisation_habitat ADD PRIMARY KEY (cle_obs, code_habitat);
ALTER TABLE localisation_habitat ADD CONSTRAINT localisation_habitat_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;


COMMENT ON TABLE localisation_habitat IS 'Table de lien etre les tables habitat et localisation';

COMMENT ON COLUMN localisation_habitat.cle_obs IS 'Clé de l observation';

COMMENT ON COLUMN localisation_habitat.code_habitat IS 'Code de l’habitat où le taxon de l’observation a été identifié.';




-- Table attribut_additionnel
CREATE TABLE attribut_additionnel (
    cle_obs bigint NOT NULL,
    parametre text NOT NULL,
    valeur text NOT NULL

);
ALTER TABLE attribut_additionnel ADD PRIMARY KEY (cle_obs, parametre);
ALTER TABLE attribut_additionnel ADD CONSTRAINT attribut_additionnel_cle_obs_fk FOREIGN KEY (cle_obs) REFERENCES observation (cle_obs) ON DELETE CASCADE;

COMMENT ON TABLE attribut_additionnel IS 'Les attributs additionnels sont des informations non prévues par le cœur de standard qui peuvent être ajoutées si besoin et sous réserve que l’information ajoutée soit décrite de manière satisfaisante directement dans le standard. De plus ces attributs ne doivent pas être utilisés pour modifier le sens d’un attribut du cœur du standard ou d’une extension.';

COMMENT ON COLUMN attribut_additionnel.cle_obs IS 'Cle de l observation';

COMMENT ON COLUMN attribut_additionnel.parametre IS 'Libellé de l’attribut ajouté.
La définition explicite du libellé du paramètre doit être fournie, avec notamment l’unité.
Exemple : Température. Définition : Température de l’air relevée au thermomètre électronique en degré Celsius';

COMMENT ON COLUMN attribut_additionnel.valeur IS 'Valeur du paramètre.
La valeur doit être explicite. Si elle est codée, le libellé du code doit être fourni dans la définition du paramètre.
Exemple : 17';


CREATE TABLE jdd (
jdd_id text NOT NULL PRIMARY KEY,
jdd_code text NOT NULL,
jdd_description text
);

COMMENT ON TABLE jdd IS 'Recense les jeux de données officiels du standard Occurence de taxons. Un jeu de données correspond souvent à une base de données';
COMMENT ON COLUMN jdd.jdd_id IS 'Un identifiant pour la collection ou le jeu de données terrain d’où provient l’enregistrement. Exemple code IDCNP pour l’INPN : « 00-15 ».';
COMMENT ON COLUMN jdd.jdd_code IS 'Le nom, l’acronyme, le code ou l’initiale identifiant la collection ou le jeu de données dont l’enregistrement de la Donnée Source provient. Exemple « INPN », « Silène », « BDMAP »';
COMMENT ON COLUMN jdd.jdd_description IS 'Description du jeu de données';



-- Table lien_observation_identifiant_permanent
-- utilisée pour ne pas perdre les enregistrements permanents lors d'un réimport et écrasement de données d'un même jdd
CREATE TABLE lien_observation_identifiant_permanent (
jdd_id text NOT NULL,
identifiant_origine text NOT NULL,
identifiant_permanent text NOT NULL
);

COMMENT ON TABLE lien_observation_identifiant_permanent IS 'Table utilisée pour conserver les identifiants permanents générés lors de l''import des observations. Cela permet de réutiliser les mêmes identifiants permanents lors d''un réimport par écrasement des données.';


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
CREATE INDEX ON localisation_masse_eau (code_me);
CREATE INDEX ON localisation_masse_eau (cle_obs);

CREATE INDEX ON nomenclature (champ, code);

CREATE INDEX ON objet_geographique USING GIST (geom);

CREATE INDEX ON observation (cd_nom);
CREATE INDEX ON observation (date_debut, date_fin DESC);
CREATE INDEX ON observation (cle_objet);
CREATE INDEX ON observation (jdd_id);

CREATE INDEX ON habitat (ref_habitat);
CREATE INDEX ON habitat (code_habitat);
CREATE INDEX ON habitat (code_habitat_parent);

CREATE INDEX ON jdd (jdd_code);

CREATE INDEX ON lien_observation_identifiant_permanent (jdd_id, identifiant_origine);

-----------------------
-- Tables SIG
-----------------------

-- Schéma
CREATE SCHEMA sig;
SET search_path TO sig,public,pg_catalog;

-- Table maille_10 = 10km
CREATE TABLE maille_10 (
    code_maille text PRIMARY KEY,
    nom_maille text
);
SELECT AddGeometryColumn('maille_10', 'geom', {$SRID}, 'POLYGON', 2);

COMMENT ON TABLE maille_10 IS 'Liste des mailles 10km du territoire.';

COMMENT ON COLUMN maille_10.code_maille IS 'Code de la maille 10km. Ex: 10kmUTM20W510N1660';

COMMENT ON COLUMN maille_10.nom_maille IS 'Code court de la maille 10km. Ex: 510-1660';

COMMENT ON COLUMN maille_10.geom IS 'Géométrie de la maille.';


-- Table maille_05 = 5km
CREATE TABLE maille_05 (
    code_maille text PRIMARY KEY,
    nom_maille text
);
SELECT AddGeometryColumn('maille_05', 'geom', {$SRID}, 'POLYGON', 2);

COMMENT ON TABLE maille_05 IS 'Liste des mailles 5km du territoire.';

COMMENT ON COLUMN maille_05.code_maille IS 'Code de la maille 5km.';

COMMENT ON COLUMN maille_05.nom_maille IS 'Code court de la maille 5km.';

COMMENT ON COLUMN maille_05.geom IS 'Géométrie de la maille.';


-- Table maille_01  = 1km
CREATE TABLE maille_01 (
    id_maille serial PRIMARY KEY,
    code_maille text UNIQUE,
    nom_maille text
);
SELECT AddGeometryColumn('maille_01', 'geom', {$SRID}, 'POLYGON', 2);

COMMENT ON TABLE maille_01 IS 'Liste des mailles 1km du territoire.';

COMMENT ON COLUMN maille_01.code_maille IS 'Code de la maille 1km.';

COMMENT ON COLUMN maille_01.nom_maille IS 'Code court de la maille 1km. Ex: 510-1660';

COMMENT ON COLUMN maille_01.geom IS 'Géométrie de la maille.';

-- Table maille_02  = 2km
CREATE TABLE maille_02 (
    id_maille serial PRIMARY KEY,
    code_maille text UNIQUE,
    nom_maille text
);
SELECT AddGeometryColumn('maille_02', 'geom', {$SRID}, 'POLYGON', 2);

COMMENT ON TABLE maille_02 IS 'Liste des mailles 2km du territoire.';

COMMENT ON COLUMN maille_02.code_maille IS 'Code de la maille 1km.';

COMMENT ON COLUMN maille_02.nom_maille IS 'Code court de la maille 2km. Ex: 510-1660';

COMMENT ON COLUMN maille_02.geom IS 'Géométrie de la maille.';


-- Table commune
CREATE TABLE commune (
    code_commune text PRIMARY KEY,
    nom_commune text NOT NULL
);
SELECT AddGeometryColumn('commune', 'geom', {$SRID}, 'MULTIPOLYGON', 2);

COMMENT ON TABLE commune IS 'Liste les communes';

COMMENT ON COLUMN commune.code_commune IS 'Code de la commune suivant le référentiel INSEE en vigueur.';

COMMENT ON COLUMN commune.nom_commune IS 'Nom de la commune suivant le référentiel INSEE en vigueur.';

COMMENT ON COLUMN commune.geom IS 'Géométrie de la commune.';

-- Table departement
CREATE TABLE departement (
    code_departement text PRIMARY KEY,
    nom_departement text NOT NULL
);
SELECT AddGeometryColumn('departement', 'geom', {$SRID}, 'MULTIPOLYGON', 2);

COMMENT ON TABLE departement IS 'Liste les départements';

COMMENT ON COLUMN departement.code_departement IS 'Code du département suivant le référentiel INSEE en vigueur.';

COMMENT ON COLUMN departement.nom_departement IS 'Nom du département suivant le référentiel INSEE en vigueur.';

COMMENT ON COLUMN departement.geom IS 'Géométrie du département.';


-- Table espace_naturel
CREATE TABLE espace_naturel (
    code_en text PRIMARY KEY,
    type_en text NOT NULL,
    nom_en text,
    url text,
    CONSTRAINT en_type_en_valide CHECK (type_en IN ('CPN', 'AAPN', 'RIPN', 'PNM', 'PNR', 'RNN', 'RNC', 'RNR', 'PRN', 'RBD', 'RBI', 'RNCFS', 'RCFS', 'APB', 'MAB', 'SCL', 'RAMSAR', 'ASPIM', 'SCEN', 'ENS', 'OSPAR', 'APIA', 'CARTH', 'ANTAR', 'NAIRO', 'ZHAE', 'BPM', 'N2000', 'ZNIEFF1', 'ZNIEFF2') )
);
SELECT AddGeometryColumn('espace_naturel', 'geom', {$SRID}, 'GEOMETRY', 2);

COMMENT ON TABLE espace_naturel IS 'L’espace naturel sur lequel a été faite l’observation.';

COMMENT ON COLUMN espace_naturel.code_en IS 'Code de l’espace naturel sur lequel a été faite l’observation.';

COMMENT ON COLUMN espace_naturel.type_en IS 'Indique le type d’espace naturel ou de zonage sur lequel a été faite l’observation.';

COMMENT ON COLUMN espace_naturel.geom IS 'Géometrie de l''espace naturel.';


-- Table masse_eau
CREATE TABLE masse_eau (
    code_me text PRIMARY KEY,
    nom_me text UNIQUE NOT NULL
);
SELECT AddGeometryColumn('masse_eau', 'geom', {$SRID}, 'GEOMETRY', 2);

COMMENT ON TABLE masse_eau IS 'Liste des masses d’eau du territoire.';

COMMENT ON COLUMN masse_eau.code_me IS 'Code de la masse d’eau.';

COMMENT ON COLUMN masse_eau.nom_me IS 'Nom de la masse d’eau.';

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

-- View to help queries from espace_naturel
CREATE OR REPLACE VIEW occtax.v_localisation_espace_naturel AS
SELECT len.cle_obs, len.code_en, en.type_en
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
CREATE OR REPLACE VIEW sig.tpl_observation_maille AS
SELECT id_maille AS mid, nom_maille AS maille, 10 AS nbobs, 3 AS nbtax, 410 AS rayon, 'red'::text AS color, ''::text AS geojson, ST_Centroid( geom ) AS geom FROM maille_02;

CREATE OR REPLACE VIEW sig.tpl_observation_brute_point AS
SELECT 1::integer AS cle_obs, ''::text AS nom_cite, '1'::bigint AS cd_nom, '2015-01-01'::text AS date_debut, '1'::integer AS cle_objet, ''::text AS identite_observateur, 'GEO'::text AS source_objet, ''::text AS geojson, ST_GeomFromText('POINT(649878 1785015)', 32620)::geometry(Point, 32620) AS geom;

CREATE OR REPLACE VIEW sig.tpl_observation_brute_linestring AS
SELECT 1::integer AS cle_obs, ''::text AS nom_cite, '1'::bigint AS cd_nom, '2015-01-01'::text AS date_debut, '1'::integer AS cle_objet, ''::text AS identite_observateur, 'GEO'::text AS source_objet, ''::text AS geojson, ST_GeomFromText('LINESTRING(649878 1785015, 649871 1785011, 649877 1785014)', 32620)::geometry(Linestring, 32620) AS geom;

CREATE OR REPLACE VIEW sig.tpl_observation_brute_polygon AS
SELECT 1::integer AS cle_obs, ''::text AS nom_cite, '1'::bigint AS cd_nom, '2015-01-01'::text AS date_debut, '1'::integer AS cle_objet, ''::text AS identite_observateur, 'GEO'::text AS source_objet, ''::text AS geojson, ST_GeomFromText('POLYGON((649878 1785015, 649879 1785011, 649877 1785014, 649878 1785015))', 32620)::geometry(Polygon, 32620) AS geom;

CREATE OR REPLACE VIEW sig.tpl_observation_brute_centroid AS
SELECT 1::integer AS cle_obs, ''::text AS nom_cite, '1'::bigint AS cd_nom, '2015-01-01'::text AS date_debut, '1'::integer AS cle_objet, ''::text AS identite_observateur, 'GEO'::text AS source_objet, ''::text AS geojson, st_centroid(ST_GeomFromText('POINT(649878 1785015)', 32620))::geometry(Point, 32620) AS geom;

