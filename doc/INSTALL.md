# Installation des modules Naturaliz pour Lizmap

Pour pouvoir installer l'application Naturaliz, vous devez au préalable avoir installé un serveur cartographique basé sur Lizmap. Vous pouvez cela utiliser les script de déploiement automatique **lizmap-box** pour cela. Nous considérons dans la suite de ce document que Lizmap Web Client a été installé et est fonctionnel.

> Attention: Pour que la recherche plein texte dans taxons fonctionne correctement, il est important de vérifier que la variable locale $LANG est bien spécifiée à fr_FR.UTF-8 avant l'installation de PostgreSQL. On peut par exemple ajouter cette ligne dans le fichier /etc/profile ```: ${LANG:=fr_FR.UTF-8}; export LANG``` et se déconnecter puis reconnecter, ou on peut exporter manuellement la variable.

Naturaliz s'appuie sur PostgreSQL pour stocker les données d'observations, mais aussi pour stocker les données liés aux utilisateurs (logins et mot de passe). Il faut donc préciser lors de l'installation via **lizmap-box** qu'on souhaite installer ces données des utilisateurs dans la base de données. Par exemple via les variable **lizmap_jauth_driver** passées dans la ligne de commande.


## Pré-requis PostGreSQL

### Base de données et utilisateurs

Avant l'installation des modules Naturaliz, vous devez vous assurer d'avoir créé au préalable une base de donnée PostGreSQL, ou d'en avoir déjà une existante. Si vous avez utilisé les scripts **lizmap-box**, une base de données **lizmap** a été créée.

Pendant le processus d'installation de l'application, l'utilisateur PostGreSQL spécifié doit avoir les droits super-utilisateur, afin de pouvoir créer la structure (des droits hauts sont requis notamment pour les extensions). Vous pouvez utiliser l'utilisateur **postgres** pendant la phase d'installation.


## Installer les modules Naturaliz sur une application Lizmap

### Utilisation du compte root

Il est fortement conseillé d'utiliser le compte root et non avec un simple sudo. Par exemple `sudo -E -s`

### Récupérer les modules

Vous pouvez le faire via l'outil git, en se connectant avec vos identifiants de la plateforme git (Gitlab ou Github). Ou bien vous rendre sur la plateforme, et télécharger au format ZIP, puis coller le ZIP dans le répertoire /root/ et dézipper.

Dans l'exemple suivant, nous utilisons la plateforme Github de 3liz, avec accès https: https://github.com/3liz/lizmap-naturaliz-module/

```bash
mkdir -p ~/naturaliz_modules
cd ~/naturaliz_modules

# Avec Git
git clone https://projects.3liz.org/clients/naturaliz-reunion.git naturaliz
cp -R ~/naturaliz_modules/naturaliz/* /srv/lizmap_web_client/lizmap/lizmap-modules/

# copier les modules dans le répertoire lizmap-modules de lizmap
ls -lh /srv/lizmap_web_client/lizmap/lizmap-modules/
```

### Adapter les fichiers de configuration pour Lizmap

L'installateur lit certains fichiers de configuration, que vous devez donc créer et adapter à votre environnement avant de lancer l'installation. Des fichiers exemples sont fournis, que vous pouvez copier avant de les modifier.

#### Configuration locale

Les modules Naturaliz lisent dans le fichier **lizmap/var/config/naturaliz.ini.php** des informations relatives à l'adaptation au contexte local: projection, codes spécifiques, etc. Vous pouvez copier le contenu du fichier **lizmap/lizmap-modules/naturaliz.ini.php.dist** et le poser dans le fichier correspondant dans lizmap. Ce fichier doit contenir:

* la **colonne locale des données TAXREF** correspondant au lieu principal de l'installation (par exemple "gua" pour la Guadeloupe) : variable **colonne_locale** de la section [taxon]
* un **intitulé** pour les zones correspondant à l'endémicité (endémique et subendémique): variables **endemicite_description_endemique** (ex: Réunion) et **endemicite_description_subendemique** (Ex: Mascareignes)
* la **liste des rangs** de taxons pour initialiser (seulement lors de l'installation ou de l'import d'une nouvelle version de taxref) la vue matérialisée de recherche plein texte. Variable **liste_rangs**. Par exemple `FM, GN, AGES, ES, SSES, NAT, VAR, SVAR, FO, SSFO, RACE, CAR, AB, KD, PH, CL, OR, SBFM, TR, SBOR, IFOR, SBCL`

* le **code SRID** du système de coordonnées de références des données spatiales du projet : variable **srid** de la section [naturaliz].
* le **libellé de la projection locale**: variable **libelle_srid**
* le **mot de passe de l'utilisateur admin**: variable **adminPassword** de la section [naturaliz].
* la **liste des types de mailles à utiliser** de la section [naturaliz]. Par exemple: `mailles_a_utiliser=maille_02,maille_10`
* la **liste des niveaux de validité**, séparés par virgule, pour filtrer les observations pour le grand public, c'est-à-dire que seules les observations qui ont un niveau de validité correspondant à un des éléments de la liste pourront être visibles pour le grand public. Variable **validite_niveaux_grand_public** de la section [naturaliz]. Par exemple validite_niveaux_grand_public=1,2
* la **taille maximale du polygone ou cercle de requête** que l'utilisateur peut dessiner sur la carte: **maxAreaQuery** . On met une valeur en m2, ou -1 pour désactiver le contrôle
* la **couleur de bordure** des observations affichées (mailles et ronds): **strokeColor** Par défault à "#FFFFFF80". On peut gérer la transparence, par exemple via #fff0 pour une transparence totale
* la **configuration des classes de légende** pour les affichages par maille: **legend_class**. On peut utiliser autant de legend_class[] que nécessaire, et on doit les écrire avec les informations suivantes séparées par point-virgule: intitulé de la classe; borne inférieure; borne supérieure; couleur. Ex: legend_class[]="De 1 à 10 observations; 1; 10; #FFFBC3"
* Les **rayons min et max pour les cercles représentant les mailles** : **legend_min_radius** et **legend_max_radius**. L'application calcule automatiquement le rayon pour une classe à partir de ces 2 valeurs et du nombre de classes. Les valeurs doivent être indiquées pour que le cercle tienne dans un carré de 1000m de côté. L'application calcule le rayon en fonction de la maille ( X2 pour les mailles 2km, X10 pour les mailles de 10km, etc.. Par exemple 100 et 410 m respectivement.
* La **liste des champs à afficher ou à exporter** dans la fiche d'observation (détail) et l'export en CSV ou WFS: **observation_card_fields**, **observation_card_fields_unsensitive**, **observation_card_children**, **observation_exported_fields** **observation_exported_fields_unsensitive**, **observation_exported_children**
* L'ordre d'affichage des items dans la barre de menu de gauche: **menuOrder**. Par exemple `menuOrder=home, occtax-presentation, switcher, occtax, dataviz, print, measure, permaLink, occtax-legal, taxon, metadata`
* liste des menaces à afficher respectivement dans le formulaire de recherche, l'icône menace à côté du nom de taxon, et dans le tableau des statistiques des taxons `search_form_menace_fields`, `taxon_detail_menace` et `taxon_table_menace_fields`
* utilisateur PostgreSQL avec accès en lecture seule: **dbuser_readonly**. Par exemple `dbuser_readonly=naturaliz`
* utilisateur PostgreSQL avec propriété sur les objets: **dbuser_owner**. Par exemple `dbuser_owner=lizmap`
* Échelle maximum où zoomer avec le bouton de zoom par observation: **maximum_observation_scale**. Par exemple `maximum_observation_scale=24000`
* Liste de localisations pour récupérer les statuts des taxons dans la fiche: **statut_localisations**. Par exemple `statut_localisations=fra,reu`
* Type du lien pour récupérer les détails d'un taxon: **taxon_detail_source_type**: `api` pour afficher un panneau avec des informations issues de l'API du MNHN, ou `url` pour ouvrir une page externe à l'application, contenant le détail du taxon.
* URL à utiliser pour voir la fiche détaillée: **taxon_detail_source_url**. Si le type du lien est API, cette URL est utilisée pour le bouton "Voir la fiche complète" situé en haut du panneau de détail d'un taxon. Si le type est URL, cliquer sur un nom de taxon ouvre simplement l'URL. On utilise dans cette URL le texte `CD_NOM` qui sera remplacé par le bon cd_nom. Par exemple: `https://inpn.mnhn.fr/espece/cd_nom/CD_NOM`


Pour le module mascarine:

* le code officiel (cf standard "Occurence de taxon", champ ) des habitats de la zone d'étude (par exemple GUAEAR )

Voir l'exemple naturaliz.ini.php.dist à la racine de ce dépôt.

```bash
# aller à la racine de Lizmap Web Client
cd /srv/lizmap_web_client/

# copie le fichier de configuration naturaliz
cp lizmap/lizmap-modules/occtax/install/config/naturaliz.ini.php.dist lizmap/var/config/naturaliz.ini.php

# editer le fichier
nano lizmap/var/config/naturaliz.ini.php # Faire les modifications nécessaires
```

Exemple de contenu

```ini
;<?php die(''); ?>
;for security reasons , don't remove or modify the first line

; put here configuration variables that are specific to this installation

[naturaliz]

; projection de reference
srid=2975
libelle_srid="Projection locale"
appName=Naturaliz

defaultRepository=
defaultProject=
projectName=Occurences de Taxon
projectDescription=Cette application permet de consulter les observations faunistiques et floristiques.
projectCss=""


; champ determinant le statut local : valeures possibles fr, gf, mar, gua, sm, sb, spm, may, epa, reu, sa, ta, taff, pf, nc, wf, cli
colonne_locale=reu
endemicite_description_endemique=Réunion
endemicite_description_subendemique=Mascareignes

; liste séparée par virgule de mailles à utiliser. Par ex: maille_01,maille_10
mailles_a_utiliser=maille_02,maille_10


; liste de niveaux de validite à restreindre pour le grand public
validite_niveaux_grand_public=1,2

; taille maximum en m2 des polygones dessinés pour rechercher des observations
; -1 permet une taille illimitée
maxAreaQuery=-1

; couleur de  bordure des mailles et des cercles
strokeColor=#FFFFFF80

; configuration des classes de légende pour les mailles
; on doit mettre, dans l'ordre et séparé par point-virgule:
; intitulé de la classe; borne inférieure; borne supérieure; couleur
legend_class="De 1 à 10 observations; 1; 10; #FFFBC3|De 11 à 100 observations; 11; 100; #FFFF00|De 101 à 500 observations; 101; 500; #FFAD00|Supérieur à 500 observations; 501; 1000000; #FF5500"

; rayon min et max pour les ronds représentant les mailles
; ( pour tenir dans un carré de 1000 m)
legend_min_radius=100
legend_max_radius=410

; liste blanche des champs à afficher dans la fiche d'observation
observation_card_fields="cle_obs, dee_date_derniere_modification, identifiant_permanent, statut_observation, nom_cite, lb_nom_valide, nom_vern, cd_nom, group2_inpn, famille, loc, menace_regionale, protection, denombrement_min, denombrement_max, objet_denombrement, commentaire, date_debut, date_fin, date_determination, ds_publique, jdd_metadonnee_dee_id, organisme_gestionnaire_donnees, statut_source, sensi_niveau, observateur, determinateur, validateur, descriptif_sujet, obs_methode, occ_denombrement_min, occ_denombrement_max, occ_type_denombrement, occ_objet_denombrement, occ_etat_biologique, occ_naturalite, occ_sexe, occ_stade_de_vie, occ_statut_biologique, obs_contexte, obs_description, occ_methode_determination, validite_niveau, validite_date_validation, precision_geometrie"

; liste blanche des champs à afficher pour le grand public dans la fiche
observation_card_fields_unsensitive=cle_obs, identifiant_permanent, statut_source, nom_cite, date_debut, date_fin, organisme_gestionnaire_donnees, source_objet, code_commune, code_departement, code_maille_10

; liste blanche des données filles à afficher dans la fiche
;observation_card_children=commune, departement, maille_01, maille_02, maille_10, espace_naturel, masse_eau, habitat, attribut_additionnel
observation_card_children=commune, departement, maille_01, maille_02, maille_10, espace_naturel, masse_eau, habitat

; liste blanche des champs à exporter
observation_exported_fields="cle_obs, identifiant_permanent, identifiant_origine, statut_observation, cd_nom, cd_ref, version_taxref, nom_cite, lb_nom_valide, nom_valide, nom_vern, group1_inpn, group2_inpn, famille, loc, menace_regionale, protection, denombrement_min, denombrement_max, type_denombrement, objet_denombrement, commentaire, date_debut, heure_debut, date_fin, heure_fin, altitude_moy, profondeur_moy, date_determination, ds_publique, jdd_metadonnee_dee_id, dee_date_derniere_modification, jdd_code, reference_biblio, organisme_gestionnaire_donnees, statut_source, sensi_niveau, observateur, determinateur, validateur, descriptif_sujet, validite_niveau, validite_date_validation, precision_geometrie, nature_objet_geo, wkt"

; liste blanche des champs à exporter pour le grand public
observation_exported_fields_unsensitive=cle_obs, identifiant_permanent, statut_source, nom_cite, date_debut, date_fin, organisme_gestionnaire_donnees, source_objet, code_commune, code_departement, code_maille_10, wkt

; liste blanche des données filles à exporter
;observation_exprted_children=commune, departement, maille_01, maille_02, maille_10, espace_naturel, masse_eau, habitat, attribut_additionnel
observation_exported_children=commune, departement, maille_01, maille_02, maille_10, espace_naturel, masse_eau, habitat

; liste blanche des données filles à exporter pour le grand public
observation_exported_children_unsensitive="commune, departement, maille_02, maille_10"

; liste des menaces à afficher dans le tableau des stats sur les taxons
taxon_table_menace_fields=menace_nationale, menace_monde

; menace à afficher à côté du nom du taxon dans les tableaux de détail (taxon et observations)
taxon_detail_nom_menace=menace_nationale

; liste des champs menaces à afficher dans le formulaire de recherche
search_form_menace_fields=menace_nationale, menace_monde

; ordre des items de menu Lizmap (barre de menu de gauche)
menuOrder=home, occtax-presentation, switcher, occtax, dataviz, print, measure, permaLink, occtax-legal, taxon, metadata

; utilisateur PostgreSQL avec accès en lecture seule
dbuser_readonly=naturaliz

; utilisateur PostgreSQL avec propriété sur les objets
dbuser_owner=lizmap

; Echelle maximum où zoomer avec le bouton de zoom par observation
maximum_observation_scale=25000

; Liste de localisations pour récupérer les statuts des taxons dans la fiche
statut_localisations=fra,reu

```

#### Configuration des accès à PostgreSQL

Vous devez vérifier dans le fichier `lizmap/var/config/profiles.ini.php`
les informations de connexion à la base de données PostGreSQL : l'utilisateur
doit **avoir des droits élevé pour l'installation**. Vous pouvez par exemple
utiliser l'utilisateur *postgres*.

Dans la section [jdb:jauth], modifier les variables "user" et "password"
pour utiliser par exemple l'utilisateur "postgres". Vous pouvez aussi modifier
l'hôte de connexion, le port et le nom de la base de données si besoin.

Si vous avez installé Lizmap via **lizmap-box**, vous devez remplacer
l'utilisateur *lizmap* par *postgres* et remplacer le mot de passe par
celui entré pour postgres.


```bash
cd /srv/lizmap_web_client/
nano lizmap/var/config/profiles.ini.php
```

Vous aurez alors un contenu du type

```ini
[jdb:jauth]
driver=pgsql
database=naturaliz
host=localhost
port=5432
user=postgres
password="********"
persistent=off
```

### Lancer l'installation des modules Naturaliz

Modifiez les droits pour que l'application puisse écrire dans les répertoires
temporaires, puis lancer l'installateur de l'application.

```bash
cd /srv/lizmap_web_client/
lizmap/install/set_rights.sh
php lizmap/install/installer.php
```

Si l'installation s'est bien passée, vous ne devez pas voir d'erreurs affichées
dans le log. Si ce n'est pas le cas, vérifier les fichiers de configuration,
notamment l'accès à la base de données.

Exemple de retour convenable:

```
Installation start..
[notice] Installation starts for the entry point index
All modules dependencies are ok
Module taxon installed
Module occtax installed
Module occtax_admin installed
All modules are installed or upgraded for the entry point index
[notice] Installation starts for the entry point admin
All modules dependencies are ok
Module taxon installed
Module occtax installed
Module occtax_admin installed
All modules are installed or upgraded for the entry point admin
[notice] Installation starts for the entry point script
All modules dependencies are ok
Module taxon installed
Module occtax installed
Module occtax_admin installed
All modules are installed or upgraded for the entry point script
Installation ended.

```

Une fois cette installation réussie, vous avez maintenant une base de donnée qui
contient l'ensemble des schémas nécessaires à l'application, avec les tables et fonctions.

Il faut maintenant créer un utilisateur aux droits limités, qui sera utilisé par
l'application Web pour lancer les requêtes:

* créer un utilisateur `naturaliz` dans PostgreSQL
* donner les **droits** d'accès à la base de données, aux tables et aux fonctions.

Vous pouvez créer l'utilisateur naturaliz via les commandes suivantes (ou via
votre client PostgreSQL, par exemple PgAdmin)


```bash
su postgres

# informations de connexion A ADAPTER
DBPORT=5432
DBNAME=lizmap
DBUSER=naturaliz
DBPASS=naturaliz # !!! MODIFIER CE MOT DE PASSE !!!

# création de l'utilisateur avec droits limités
createuser $DBUSER -p $DBPORT --no-createdb --no-createrole --no-superuser
psql -d template1 -p $DBPORT -c "ALTER USER "$DBUSER" WITH ENCRYPTED PASSWORD '"$DBPASS"' ;"

# Ajout des droits sur les objets de la base pour naturaliz
psql -d $DBNAME -p $DBPORT -c "GRANT CONNECT ON DATABASE $DBNAME TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "GRANT USAGE ON SCHEMA public,taxon,sig,occtax TO $DBUSER";
psql -d $DBNAME -p $DBPORT -c "GRANT SELECT ON ALL TABLES IN SCHEMA occtax,sig,taxon TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "GRANT INSERT ON ALL TABLES IN SCHEMA occtax TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public,occtax,sig,taxon TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public,occtax,sig,taxon TO $DBUSER;"

# Pour le module gestion (optionnel)
psql -d $DBNAME -p $DBPORT -c "GRANT USAGE ON SCHEMA gestion TO $DBUSER";
psql -d $DBNAME -p $DBPORT -c "GRANT SELECT ON ALL TABLES IN SCHEMA gestion TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA gestion TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA gestion TO $DBUSER;"

# Pour le module mascarine (optionnel)
psql -d $DBNAME -p $DBPORT -c "GRANT USAGE ON SCHEMA mascarine TO $DBUSER";
psql -d $DBNAME -p $DBPORT -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA mascarine TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA mascarine TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA mascarine TO $DBUSER;"

exit

```


On peut aussi faire cela plus directement ainsi. ATTENTION: remplacer le nom de
la base naturaliz par votre nom (ex: naturaliz_reunion)

```sql
-- Ajout des droits sur les objets de la base pour naturaliz
GRANT CONNECT ON DATABASE naturaliz TO naturaliz;
GRANT USAGE ON SCHEMA public,taxon,sig,occtax TO naturaliz;
GRANT SELECT ON ALL TABLES IN SCHEMA occtax,sig,taxon TO naturaliz;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO naturaliz;
GRANT INSERT ON ALL TABLES IN SCHEMA occtax TO naturaliz;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public,occtax,sig,taxon TO naturaliz;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public,occtax,sig,taxon TO naturaliz;

-- Pour le module gestion (optionnel)
GRANT USAGE ON SCHEMA gestion TO naturaliz;
GRANT SELECT ON ALL TABLES IN SCHEMA gestion TO naturaliz;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA gestion TO naturaliz;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA gestion TO naturaliz;

-- Pour le module mascarine (optionnel)
GRANT USAGE ON SCHEMA mascarine TO naturaliz;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA mascarine TO naturaliz;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA mascarine TO naturaliz;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA mascarine TO naturaliz;
```


Pour l'utilisateur lizmap qui n'est pas superuser mais a les droits sur la base
de données Lizmap (création, suppression de tables, schéma, etc.)

```sql
-- Ajout des droits sur les objets de la base pour lizmap
GRANT CONNECT ON DATABASE naturaliz TO lizmap;
GRANT ALL PRIVILEGES ON SCHEMA public,taxon,sig,occtax TO lizmap;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public,taxon,sig,occtax TO lizmap;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public,occtax,sig,taxon TO lizmap;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public,occtax,sig,taxon TO lizmap;

-- Pour le module gestion (optionnel)
GRANT ALL PRIVILEGES ON SCHEMA gestion TO lizmap;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA gestion TO lizmap;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA gestion TO lizmap;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA gestion TO lizmap;

```


Une fois cet utlisateur créé et les droits appliqués, vous devez modifier
le fichier de configuration des profils `lizmap/var/config/profiles.ini.php` pour
remplacer l'utilisateur "postgres" par l'utilisateur avec droits limités "naturaliz"
dans la section `[jdb:jauth]`. Il faut ensuite copier/coller les informations
de cette section, et créer une nouvelle section `[jdb:jauth_super]` qui aura les
mêmes informations, mais avec des droits superuser (elle sera utilisée pour les
mises à jours notamment).

```bash
cd /srv/lizmap_web_client/

# Remplir le fichier de profiles avec les informations nécessaire (2 sections jdb:jauth et jdb:jauth_super)
nano lizmap/var/config/profiles.ini.php

# rétablir les droits de l'application Lizmap
lizmap/install/set_rights.sh www-data www-data
```


Dans le fichier `lizmap/var/config/profiles.ini.php`, vous aurez donc les 2
sections `[jdb:jauth]` et `[jdb:jauth_super]` suivantes (adapter les mots de
passe, et nom de la bdd si besoin):

```ini
[jdb:jauth]
driver=pgsql
database=naturaliz
host=localhost
port=5432
user=naturaliz
password="********"
persistent=off

[jdb:jauth_super]
driver=pgsql
database=naturaliz
host=localhost
port=5432
user=postgres
password="********"
persistent=off

```


**IMPORTANT** L'application utilise un service PostgreSQL pour certaines
fonctionnalités, comme l'export PDF des cartes. Vous devez donc configurer
ce service sur le serveur.

```bash
nano /etc/postgresql-common/pg_service.conf
```

# y mettre le contenu suivant, en adaptant bien sûr le nom de la base de données et mot de passe
```ini
[naturaliz]
host=localhost
dbname=naturaliz
user=naturaliz
port=5432
password=naturaliz
```

# tester via
```bash
psql service=naturaliz
```



## Importer les données de référence

L'installateur a créé la structure dans la base de données PostGreSQL (schéma,
tables, vues, etc.), mais aucune donnée n'a encore été importée, à part les
listes liées à la nomenclature du standard TAXREF et du schéma Occurence de
taxons. Les imports peuvent être réalisés via des scripts de l'application.
Pour cela, il faut bien avoir configuré le fichier `lizmap/var/config/profiles.ini.php`
comme décrit précédemment.

### Import TAXREF : données officielles des taxons

Pour pouvoir effectuer des recherche via le module taxon, vous devez au
préalable récupérer les données officielles du TAXREF, puis les importer.

Les fichiers concernant TAXREF, les menaces (listes rouges) et les protections sont téléchargés directement depuis la plateforme SINP (site du MNHN)

#### Fichier officiel TAXREF

**Source**: ZIP du TAXREF: https://inpn.mnhn.fr/telechargement/referentielEspece/taxref/14.0/menu

Ce ZIP contient plusieurs fichiers intéressants:

* **TAXREFv14.txt**: les données brutes TAXREF
* **TAXREF_CHANGES.txt**: les modifications réalisées depuis la dernière version du TAXREF
* **TAXVERNv14.txt**: les noms vernaculaires

#### Base de connaissance des statuts

**Source**: ZIP BDC Statuts: https://inpn.mnhn.fr/telechargement/referentielEspece/bdc-statuts-especes

Ce ZIP contient un fichier **BDC_STATUTS_14.csv** qui référence les **menaces** et les statuts de **protection** en fonction de la localisation de la plateforme.

#### Lancer l'import des données TAXREF dans l'application

Une fois les données récupérées, vous pouvez l'import de données. L'import du taxref se fait à la main, via des scripts SQL, en se connectant à la base de données PostgreSQL via un client comme PgAdmin. Un fichier d'exemple est fourni: [fichier exemple d'import](doc/taxref/import_taxref.sql)

Pour pouvoir lancer les commandes SQL qui copient les données depuis les fichiers `txt` ou `csv`, il faut:

* soit envoyer le fichier au préalable sur le serveur dans un répertoire accessible à PostgreSQL (ex: `/tmp/`)
* soit utiliser la commande `psql` et le mode `\copy` qui remplace l'utilisation de `COPY` et permet de spécifier un fichier sur la machine locale et non le serveur

**Note** Une fois l'import finalisé, il peut être intéressant de vérifier que les données de protection et de menaces font bien référence à des taxons présents dans le TAXREF (CD_NOM).



### Import Occurences de taxon : données de références

Certaines données spatiales de références sont nécessaires au fonctionnement de l'application :

* les communes et les département de la zone concernée
* les mailles 1x1km, 2x2km, 5x5km et 10x10km
* les espaces naturels (Parc, réserves de biotope, ZNIEFF 1 et 2, etc.)
* les masses d'eau

Ces données peuvent être récupérées sur le site du MNHN : https://inpn.mnhn.fr/telechargement/cartes-et-information-geographique/ref/referentiels

Nous conseillons de récupérer au maximum les données au format WFS
(Web Feature Service), pour être sûr d'avoir les données les plus à jour.
Certaines données doivent être récupérées ailleurs, comme par exemple les
communes et les mailles 1x1km et 2x2km.

Les habitats doivent aussi être récupérés et importés.

* Liste des habitats standards HABREF, téléchargeable ici https://inpn.mnhn.fr/telechargement/referentiels/habitats/
* Liste des habitats marins, par exemple TYPO_ANT_MER ( Liste des habitats marins des Antilles (Martinique, Guadeloupe) )
* Liste des habitats terrestres, par exemple ceux de la Carte Écologique d'Alain Rousteau

Il faut créer la couche Mailles 2x2 à partir de la couche 1x1, dans QGIS, via la procédure suivante:

* Menu Vecteur / Outils de recherche / Grille vecteur
* Etendue de la grille : choisir la couche de mailles 1x1km
* Cliquer sur le bouton "Mettre à jour l'emprise depuis la couche"
* Paramètres : mettre `2000` dans la case `X`
* Cocher "Grille en sortie en tant que polygone"
* Choisir un fichier de sortie ( le mettre au même endroit que le fichier des mailles 1x1km
* Lancer le traitement via le bouton OK

Pour pouvoir importer ces données dans la base, il faut le faire manuellement.
Nous conseillons fortement d'utiliser l'outil en ligne de commande `ogr2ogr`
qui permet de bien contrôler les options d'import: encodage, renommage de champs, filtres, etc.

Un script exemple est disponible dans le code source de naturaliz:

* [Import pour Mayotte](sig/import_referentiels_sig_mayotte.sh)
* [Import pour la Martinique](sig/import_referentiels_sig_martinique.sh)

Ces scripts contiennent une liste de commandes à lancer manuellement une à une.

Pour pouvoir lancer ces commandes ogr2ogr d'import, il faut d'abord installer Gdal:

* Sous Linux, il faut installer Gdal, avec la commande `apt install gdal-bin`
* Sous Windows, il faut avoir préalablement installé QGIS, puis lancer l'invite de commande `Osgeo4W Shell`

Il faut aussi avoir configuré un **service PostgreSQL** pour pouvoir accéder à
la base de données sur laquelle l'application Naturaliz est installée.

Dans les scripts, certaines commandes commentées permettent de supprimer les
données SIG, par exemple suite à une erreur d'import, pour repartir de zéro.
Par exemple:

* Suppression des communes: `psql service=naturaliz_pnrmartinique_dev -c "TRUNCATE sig.commune RESTART IDENTITY"`
* Suppression des RNN dans la table des espaces naturels: `psql service=naturaliz_pnrmartinique_dev -c "DELETE FROM sig.espace_naturel WHERE type_en = 'RNN'"`


Script SQL de création dynamique de grilles

```sql
BEGIN;

TRUNCATE sig.maille_02 RESTART IDENTITY;
WITH
taille AS (
	SELECT 2000 AS maille
),
metadata AS (
	SELECT
	maille,
	(maille/1000) || 'kmUTM20' AS code_maille_prefix,
	'2022' AS version_ref,
	'Grille nationale (' || (maille/1000) || 'km x ' || (maille/1000) || 'km) Martinique' AS nom_ref
	FROM taille
),
forme AS (
	SELECT ST_Union(geom) AS geom
	FROM sig.maille_10
),
bounds AS (
	SELECT
	maille,
	ST_Xmin(geom) AS x_min, ST_Xmax(geom) AS x_max,
	ST_Ymin(geom) AS y_min, ST_Ymax(geom) AS y_max,
	ST_Xmax(geom)::int - ST_Xmin(geom)::int AS largeur,
	(ST_Xmax(geom)::int - ST_Xmin(geom)::int)/maille AS nb_largeur,
	ST_Ymax(geom)::int - ST_Ymin(geom)::int AS hauteur,
	(ST_Ymax(geom)::int - ST_Ymin(geom)::int)/maille AS nb_hauteur
	FROM forme, metadata
),
env AS (
	SELECT gx,
	(x_min + gx * maille)::int AS x_min,
	(y_min + gy * maille)::int AS y_min,
	(x_min + (gx+1) * maille)::int AS x_max,
	(y_min + (gy+1) * maille)::int AS y_max
	FROM bounds AS b,
	generate_series(0, nb_largeur - 1) AS gx,
	generate_series(0, nb_hauteur - 1) AS gy
),
grille AS (
	SELECT
	t.*,
	e.*,
	ST_MakeEnvelope(e.x_min, e.y_min, e.x_max, e.y_max, 5490)::geometry(polygon, 5490) AS geom
	FROM env AS e, metadata AS t
),
final AS (
	SELECT
	row_number() OVER() AS id_maille,
	concat(
		code_maille_prefix,
		'W', (x_min/1000)::int,
		'N', (y_min/1000)::int
	) AS code_maille,
	concat(
		(x_min/1000)::int, '-', (y_min/1000)::int
	) AS nom_maille,
	version_ref,
	nom_ref,
	g.geom
	FROM grille AS g
	JOIN forme AS f
	ON ST_Intersects(ST_Centroid(g.geom), f.geom)
)
INSERT INTO sig.maille_02
(code_maille, nom_maille, version_ref, nom_ref, geom)
SELECT code_maille, nom_maille, version_ref, nom_ref, geom
FROM final
ORDER BY id_maille
;

COMMIT;
```

Pour les **départements**, il faut choisir quelle géométrie est utilisée. Par défaut, l'application n'importe aucune données dans la table département. Vous devez ajouter une ou plusieurs lignes si vous souhaitez que les exports donnent le code du département. Pour les îles, comme La Réunion ou la Guadeloupe, il peut être intéressant d'utiliser la Zone économique exclusive comme géométrie du département. Pour cela on peut, par exemple pour La Réunion:

* importer le fichier SHP de la zone économique exclusive dans la base de données, schéma sig, avec le nom de table "zone_economique_exclusive"
* lancer la requête SQL suivante pour ajouter cette géométrie dans la table des départements

```sql
DELETE FROM sig.departement;
INSERT INTO sig.departement
(code_departement, nom_departement, annee_ref, geom)
SELECT '974', 'La Réunion', 2017, st_multi(geom)::geometry(MULTIPOLYGON,2975)
FROM sig.zone_economique_exclusive;
```

## Configuration LDAP


Pour le projet Naturaliz, l'authentification peut se faire via ldap.
Pour cela, il y a un module spécifique ldapdao. Il est activé, mais
pas l'authentification ldap.

Pour se faire, après l'installation, il faut modifier les fichiers
`lizmap/var/config/admin/config.ini.php` et `lizmap/var/config/index/config.ini.php`,
en modifiant le nom du fichier pour le plugin auth.

dans `lizmap/var/config/admin/config.ini.php` :

```ini
[coordplugins]
auth="admin/authldap.coord.ini.php"
```
et dans `lizmap/var/config/index/config.ini.php`

```ini
[coordplugins]
auth="index/authldap.coord.ini.php"
```

Il faut parfois aussi installer le certificat racine SSL du serveur ldap, sur le serveur
apache/php, sinon la connexion au ldap ne pourra se faire. En tant que root:

```bash
cp lizmap/install/png_ldap.crt /usr/local/share/ca-certificates
update-ca-certificates
service nginx restart
```


## Configuration diverses

On peut augmenter le temps de session PHP pour éviter des déconnexions suite à une inactivité.
Par exemple

```bash
nano /etc/php/7.4/fpm/php.ini

# modifier la variable session.gc_maxlifetime. Par exemple ici à 7H
session.gc_maxlifetime = 25200

# Enregistrer et recharger
service php7.4-fpm reload
```


## Mise à jour

Lorsqu'une nouvelle version des modules Naturaliz est sortie, il faut les mettre à jour. Par exemple via ce type de procédure

```bash
# 1 - mettre à jour les modules via git
cd /CHEMIN/REPERTOIRE/SOURCE/MODULES
git status -s
git fetch origin
git merge origin/master

# 2 - copier les modules dans l'application Lizmap
cp -R /CHEMIN/REPERTOIRE/SOURCE/MODULES/* /srv/lizmap_web_client/lizmap/lizmap-modules/

# 3 - lancer l'installateur de Lizmap pour mettre à jour
cd /srv/lizmap_web_client/
lizmap/install/clean_vartmp.sh
lizmap/install/set_rights.sh
php lizmap/install/installer.php
lizmap/install/set_rights.sh
```
