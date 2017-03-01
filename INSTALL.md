# Installation des modules Naturaliz pour Lizmap

Pour pouvoir installer l'application Naturaliz, vous devez au préalable avoir installé un serveur cartographique basé sur Lizmap. Vous pouvez cela utiliser les script de déploiement automatique **lizmap-box** pour cela. Nous considérons dans la suite de ce document que Lizmap Web Client a été installé et est fonctionnel.

> Attention: Pour que la recherche plein texte dans taxons fonctionne correctement, il est important de vérifier que la variable locale $LANG est bien spécifiée à fr_FR.UTF-8 avant l'installation de PostgreSQL.

Naturaliz s'appuie sur PostgreSQL pour stocker les données d'observations, mais aussi pour stocker les données liés aux utilisateurs (logins et mot de passe). Il faut donc préciser lors de l'installation via **lizmap-box** qu'on souhaite installer ces données des utilisateurs dans la base de données. Par exemple via les variable **lizmap_jauth_driver** passées dans la ligne de commande.


## Pré-requis PostGreSQL

### Base de données et utilisateurs

Avant l'installation des modules Naturaliz, vous devez vous assurer d'avoir créé au préalable une base de donnée PostGreSQL, ou d'en avoir déjà une existante. Si vous avez utilisé les scripts **lizmap-box**, une base de données **lizmap** a été créée.

Pendant le processus d'installation de l'application, l'utilisateur PostGreSQL spécifié doit avoir les droits super-utilisateur, afin de pouvoir créer la structure (des droits hauts sont requis notamment pour les extensions). Vous pouvez utiliser l'utilisateur **postgres** pendant la phase d'installation.


## Installer les modules Naturaliz sur une application Lizmap

### Récupérer les modules

Vous pouvez le faire via l'outil git, en se connectant avec vos identifiants de la plateforme git (Gitlab ou Github). Ou bien vous rendre sur la plateforme, et télécharger au format ZIP, puis coller le ZIP dans le répertoire /tmp/ et dézipper.

Dans l'exemple suivant, nous utilisons la plateforme Gitlab de 3liz, avec accès https: https://projects.3liz.org/clients/naturaliz-reunion.git

```
cd /tmp/
git clone https://projects.3liz.org/clients/naturaliz-reunion.git naturaliz
cp -R /tmp/naturaliz/* /srv/lizmap_web_client/lizmap/lizmap-modules/
ls -lh /srv/lizmap_web_client/lizmap/lizmap-modules/
```

### Adapter les fichiers de configuration pour Lizmap

L'installateur lit certains fichiers de configuration, que vous devez donc créer et adapter à votre environnement avant de lancer l'installation. Des fichiers exemples sont fournis, que vous pouvez copier avant de les modifier.

#### Configuration locale

Les modules Naturaliz lisent dans le fichier **lizmap/var/config/localconfig.ini.php** des informations relatives à l'adaptation au contexte local: projection, codes spécifiques, etc. Vous pouvez copier le contenu du fichier **lizmap/lizmap-modules/localconfig.ini.php.dist** et le poser dans le fichier correspondant dans lizmap. Ce fichier doit contenir:

* la colonne des données TAXREF correspondant au lieu principal de l'installation (par exemple "gua" pour la Guadeloupe) : variable **colonne_locale** de la section [taxon]
* une description pour les zones correspondant à l'endémicité (endémique et subendémique): variables **endemicite_description_endemique** (ex: Réunion) et **endemicite_description_subendemique** (Ex: Mascareignes)
* la liste des codes d'arrêtés de protection pour la zone concernée: variables **code_arrete_protection_simple**, **code_arrete_protection_internationale**, **code_arrete_protection_nationale**, **code_arrete_protection_communautaire** de la section  [taxon]
* le code SRID du système de coordonnées de références des données spatiales du projet : variable **srid** de la section [naturaliz].
* le mot de passe de l'utilisateur admin: variable **adminPassword** de la section [naturaliz].

Pour le module mascarine:

* le code officiel (cf standard "Occurence de taxon", champ ) des habitats de la zone d'étude (par exemple GUAEAR )

Voir l'exemple localconfig.ini.php.dist à la racine de ce dépôt.

```
cd /srv/lizmap_web_client/
cp lizmap/lizmap-modules/localconfig.ini.php.dist lizmap/var/config/localconfig.ini.php
nano lizmap/var/config/localconfig.ini.php # Faire les modifications nécessaires
```

Exemple de contenu:

```
;<?php die(''); ?>
;for security reasons , don't remove or modify the first line

; put here configuration variables that are specific to this installation


[modules]
lizmap.installparam=demo

taxon.access=2
occtax.access=2
occtax_admin.access=2
;mascarine.access=0
;mascarine_admin.access=0

[taxon]
; champ determinant le statut local : valeures possibles fr, gf, mar, gua, sm, sb, spm, may, epa, reu, sa, ta, taff, pf, nc, wf, cli
colonne_locale=reu
endemicite_description_endemique=Réunion
endemicite_description_subendemique=Mascareignes

; liste des codes des arr  t  s de protection qui concernent la zone de travail
code_arrete_protection_simple="agri1,agri2,Bubul1,Bulbul2,Bulbul3,Bulbul4,Bulbul5,Bulbul6,Bulbul9,corbasi1,phelsuma1,phelsuma2,phelsuma3,phelsuma4,phelsuma5,PV97,REUEEA,REUEEI,REUP"
code_arrete_protection_internationale="CCA,CCB,CCC,CCD,IAAP,IAO2,IAO3,IAO4,IBA2,IBA3,IBE1,IBE2,IBE3,IBOAE,IBO1,IBO2,IOS5"
code_arrete_protection_communautaire="CDH2,CDH4,CDH5,CDO1,CDO21,CDO22,CDO31,CDO32"
code_arrete_protection_nationale="DV974,NM,NMAMmar2,NM2,NO3,NO4,NO6,NTAA1,NTM1,NTM8,OC3,REUEA2,REUEA3,REUEA4,REUI2"


[naturaliz]
; projection de reference
srid=2975
appName=Naturaliz

[occtax]
defaultRepository=
defaultProject=
projectName=Occurences de Taxon
projectDescription=Cette application permet de consulter les observations faunistiques et floristiques.
projectCss=""

; typename WFS pour les imports
znieff1_terre=Znieff1
znieff1_mer=Znieff1_mer
znieff2_terre=Znieff2
znieff2_mer=Znieff2_mer

```

#### Configuration des accès à PostgreSQL

Vous devez vérifier dans le fichier **lizmap/var/config/profiles.ini.php** les informations de connexion à la base de données PostGreSQL : l'utilisateur doit **avoir des droits élevé pour l'installation**. Vous pouvez par exemple utiliser l'utilisateur *postgres*

Dans la section [jdb:jauth], modifier les variables "user" et "password" pour utiliser par exemple l'utilisateur "postgres". Vous pouvez aussi modifier l'hôte de connexion, le port et le nom de la base de données si besoin.

Si vous avez installé Lizmap via **lizmap-box**, vous devez remplacer l'utilisateur *lizmap* par *postgres* et remplacer le mot de passe par celui entré pour postgres.


```
cd /srv/lizmap_web_client/
nano lizmap/var/config/profiles.ini.php
```

### Lancer l'installation des modules Naturaliz

Modifiez les droits pour que l'application puisse écrire dans les répertoires temporaires, puis lancer l'installateur de l'application

```
cd /srv/lizmap_web_client/
lizmap/install/set_rights.sh
php lizmap/install/installer.php
```

Si l'installation s'est bien passée, vous ne devez pas voir d'erreurs affichées dans le log. Si ce n'est pas le cas, vérifier les fichiers de configuration, notamment l'accès à la base de données.

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

Une fois cette étape validée, l'application naturaliz est bien installée. Il faut maintenant

* importer des données de référence
* importer des données d'observation faunistiques ou floristiques


## Importer les données de référence

L'installateur a créé la structure dans la base de données PostGreSQL (schéma, tables, vues, etc.), mais aucune donnée n'a encore été importée, à part les listes liées à la nomenclature du standard TAXREF et du schéma Occurence de taxons.

### Import TAXREF : données officielles des taxons

Pour pouvoir effectuer des recherche via le module taxon, vous devez au préalable récupérer les données officielles du TAXREF, puis les importer.

Les fichiers concernant TAXREF, les menaces (listes rouges) et les protections sont téléchargés directement depuis la plateforme SINP (site du MNHN)

#### Taxref

Le fichier officiel du taxref, par exemple *TAXREFv10.0.txt*

* Source: https://inpn.mnhn.fr/telechargement/referentielEspece/taxref/10.0/menu
* Lien: https://inpn.mnhn.fr/telechargement/referentielEspece/taxref/10.0/zip

#### Menaces (listes rouges)

Le fichier des listes rouges, par exemple *LR_Resultats_Guadeloupe_complet_export.csv*.  On utilise pour remplir la colonne menace de la table t_complement le champ *CATEGORIE_FR* et non *CATEGORIE_MONDE*

* Source: https://inpn.mnhn.fr/telechargement/acces-par-thematique/listes-rouges# Aller dans *Liste rouge Réunion* puis cliquer sur *Publication et résultats* puis sur *Réunion: consulter tous les résultats* Puis *Exporter les données: CSV*
* Lien (exemple, peut changer): https://inpn.mnhn.fr/telechargement/acces-par-thematique/listes-rouges/FR/territoire/REU?6578706f7274=1&d-7649687-e=1

* Colonnes:

  ```
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
  ```

#### Protections

Exemple : PROTECTION_ESPECES_10.csv

On doit spécifier dans le fichier lizmap/var/config/localconfig.ini.php la liste des codes des arrêtés sur les protections des espèces, par exemple GUAM1,GUAO1,GUARA1,DV971,GUAI2 pour la Guadeloupe

* Source: https://inpn.mnhn.fr/telechargement/referentielEspece/reglementation
* Lien: https://inpn.mnhn.fr/telechargement/referentielEspece/reglementation/zip

Attention, on doit convertir le fichier Excel ( ex: PROTECTION_ESPECES_10.xls ) au format CSV (ex: PROTECTION_ESPECES_10.csv ). Pour cela, utiliser LibreOffice pour ouvrir le fichier Excel, et "Enregistrer sous" avec les options suivantes:
* format Texte CSV (.csv)
* Jeu de caractères: Unicode ( UTF-8 )
* Séparateur de champ: virgule ','
* Séparateur de texte: guillemet double '"'
* Conserver la première ligne avec le nom des champs

* Colonnes:

  ```
  cd_nom text,
  cd_protection text,
  nom_cite text,
  syn_cite text,
  nom_francais_cite text,
  precisions text,
  cd_nom_cite text
  ```

#### Lancer l'import des données TAXREF dans l'application

Une fois les données récupérées, vous pouvez l'import de données via la commande suivante:

```
cd /srv/lizmap_web_client/
php lizmap/scripts/script.php taxon~import:taxref -source /tmp/referentiels/taxref/10/TAXREFv10.0.txt -menace /tmp/referentiels/menaces/LR_Resultats_Réunion_export_.csv -protection /tmp/referentiels/protection/ESPECES_REGLEMENTEES_10/PROTECTION_ESPECES_10.csv -version 10
```

Le premier paramètre passé est le chemin complet vers le fichier CSV contenant les données. Le 2ème est le chemin vers le fichier des menaces (taxons sur listes rouges, filtré pour la région concernée).Le 3ème est le fichier contenant les taxon protégés. Vous pouvez pointer vers d'autres chemins de fichiers, et le script se chargera de copier les données dans le répertoire temporaire puis lancera l'import.
Le dernier paramètre est la version du fichier TAXREF (7, 8, 9 ou 10 sont possibles).

Vous pouvez voir l'aide de la commande via:

```
php lizmap/scripts/script.php help taxon~import:taxref
```

**NB** Les fichiers concernant les menaces (listes rouges) et les protections sont téléchargés directement depuis la plateforme SINP:


### Import Occurences de taxon : données de références

Certaines données spatiales de références sont nécessaires au fonctionnement de l'application :

* les communes et les département de la zone concernée
* les mailles 1x1km, 2x2km, 5x5km et 10x10km
* les espaces naturels (Parc, réserves de biotope, ZNIEFF 1 et 2, etc.)
* les masses d'eau

Ces données peuvent être récupérées sur le site du MNHN : http://inpn.mnhn.fr/telechargement/cartes-et-information-geographique
Nous conseillons de récupérer au maximum les données au format WFS (Web Feature Service), pour être sûr d'avoir les données les plus à jour.
Certaines données doivent être récupérées ailleurs, comme par exemple les communes et les mailles 1x1km et 2x2km.

Les habitats doivent aussi être récupérés et importés.

* Liste des habitats standards HABREF, téléchargeable ici https://inpn.mnhn.fr/telechargement/referentiels/habitats/
* Liste des habitats marins, par exemple TYPO_ANT_MER ( Liste des habitats marins des Antilles (Martinique, Guadeloupe) )
* Liste des habitats terrestres, par exemple ceux de la Carte Écologique d'Alain Rousteau

Il faut créer la couche Mailles 2x2 à partir de la couche 1x1, dans QGIS
* Menu Vecteur / Outils de recherche / Grille vecteur
* Etendue de la grille : choisir la couche de mailles 1x1km
* Cliquer sur le bouton "Mettre à jour l'emprise depuis la couche"
* Paramètres : mettre 2000 dans la case X
* Cocher "Grille en sortie en tant que polygone"
* Choisir un fichier de sortie ( le mettre au même endroit que le fichier des mailles 1x1km
* Lancer le traitement via le bouton OK


Deux scripts permettent d'importer ces données dans la base, un pour les données WFS, et un autre pour les données Shapefile, Excel et CSV:

* Shapefile : les communes, les mailles 1 et 2, les réserves naturelles nationales, et les habitats
* WFS : les différents espaces naturels disponibles via le serveur, les mailles 10, les masses d'eau

Pour que l'import des données via les serveurs WFS fonctionne, il faut absolument préciser dans le fichier **lizmap/var/config/localconfig.ini.php** les paramètres suivants dans la partie **[occtax]**

```

; typename WFS pour les imports
znieff1_terre=reu_znieff1
znieff1_mer=reu_znieff1_mer
znieff2_terre=reu_znieff2
znieff2_mer=reu_znieff2_mer

```

Lancer l'import des données via les commandes suivantes:

```
cd /srv/lizmap_web_client/
# Installation de gdal-bin pour disposer de l'outil ogr2ogr utilisé par le script d'import
apt-get install gdal-bin

# Import des données depuis les Shapefile pour les communes, mailles 1 et 2.
# Import optionnel des réserves naturelles nationales et des habitats
# Vous devez spécifier le chemin complet vers les fichiers : communes, mailles 1x1km, mailles 2x2km et optionnellement les réserves et les habitats

# Exemple 1/ Guadeloupe
php lizmap/scripts/script.php occtax~import:shapefile -commune "/tmp/sig/COMMUNE.SHP" -maille_01 "/tmp/sig/grille_1000m_gwada_dep_ama_poly.shp" -maille_02 "/tmp/sig/grille_2000m_gwada_dep_ama_poly.shp" -maille_05 "/tmp/sig/grille_5000.shp" -maille_10 "/tmp/sig/grille_10000m" -reserves_naturelles_nationales "/tmp/sig/glp_rnn2012.shp" -habref "/tmp/csv/HABREF_20/HABREF_20.csv" -habitat_mer "/tmp/csv/habitats/TYPO_ANT_MER_09-01-2011.xls" -habitat_terre "/tmp/csv/habitats/EAR_Guadeloupe.csv" -commune_annee_ref "2013" -departement_annee_ref "2013" -maille_01_version_ref "2015" -maille_01_nom_ref "Grille nationale (1km x 1km) Réunion" -maille_02_version_ref "2015" -maille_02_nom_ref "Grille nationale (2km x 2km) Réunion" -maille_05_version_ref "2015" -maille_05_nom_ref "Grille nationale (5km x 5km) Réunion" -maille_10_version_ref "2012" -maille_10_nom_ref "Grille nationale (10km x 10km) Réunion" -rnn_version_en "2010"

# Exemple 2/ La Réunion
php lizmap/scripts/script.php occtax~import:shapefile -commune "/tmp/referentiels/sig/COMMUNE.SHP" -maille_01 "/tmp/referentiels/sig/REU_UTM40S1X1.shp" -maille_02 "/tmp/referentiels/sig/REU_UTM40S2X2.shp" -maille_05 "/tmp/referentiels/sig/REU_UTM40S5X5.shp" -maille_10 "/tmp/referentiels/sig/REU_UTM40S10X10.shp" -reserves_naturelles_nationales "/tmp/referentiels/sig/RN.shp" -habref "/tmp/referentiels/habitats/HABREF_20/HABREF_20.csv" -commune_annee_ref "2013" -departement_annee_ref "2013" -maille_01_version_ref "2015" -maille_01_nom_ref "Grille nationale (1km x 1km) Réunion" -maille_02_version_ref "2015" -maille_02_nom_ref "Grille nationale (2km x 2km) Réunion" -maille_05_version_ref "2015" -maille_05_nom_ref "Grille nationale (5km x 5km) Réunion" -maille_10_version_ref "2012" -maille_10_nom_ref "Grille nationale (10km x 10km) Réunion" -rnn_version_en "2010"

# Import des données depuis les serveurs WFS officiels
# Vous devez préciser l'URL des serveurs WFS pour les données INPN et pour les données Sandre (masses d'eau)
php lizmap/scripts/script.php occtax~import:wfs -wfs_url "http://ws.carmencarto.fr/WFS/119/reu_inpn" -wfs_url_sandre "http://services.sandre.eaufrance.fr/geo/mdo_REU" -wfs_url_grille "http://ws.carmencarto.fr/WFS/119/reu_grille" -znieff1_terre_version_en "2015-02" -znieff1_mer_version_en "2016-05" -znieff2_terre_version_en "2015-02" -znieff2_mer_version_en "2016-05" -ramsar_version_en "" -cpn_version_en "2015-10" -aapn_version_en "2015-10" -scl_version_en "2016-03" -mab_version_en "" -rb_version_en "2010" -apb_version_en "2012" -cotieres_version_me 2 -cotieres_date_me "2016-11-01" -souterraines_version_me 2 -souterraines_date_me "2016-11-01"

# Pour le module MASCARINE seulement
# Import des données de relief (Modèle numérique de terrain = MNT ) et des lieu-dits en shapefiles
# ATTENTION: seulement nécessaire si le module mascarine (saisie flore) est utilisé.
# Vous devez spécifier les chemins complet vers les fichiers dans cet ordre: MNT, lieux-dits habités, lieux-dits non-habités, oronymes et toponymes divers ( Source IGN )
php lizmap/scripts/script.php mascarine~import:gdalogr "/tmp/sig/DEPT971.asc" "/tmp/sig/LIEU_DIT_HABITE.SHP" "/tmp/sig/LIEU_DIT_NON_HABITE.SHP" "/tmp/sig/ORONYME.SHP" "/tmp/sig/TOPONYME_DIVERS.SHP"

```

Suppression des référentiels géographiques

```
# On peut supprimer tout ou partie des données (avant réimport par exemple), via la commande purge, en passant une liste des tables séparées par virgule
php lizmap/scripts/script.php occtax~import:purge -sig "commune,departement,maille_01,maille_02,maille_05,maille_10,espace_naturel,masse_eau" -occtax "habitat"
# ou pour une table par exemple
php lizmap/scripts/script.php occtax~import:purge -sig "espace_naturel"
```

## Finaliser l'installation

### PostgreSQL: ajouter un utilisateur naturaliz aux droits limités

La base est installée et les données importées. Vous pouvez maintenant:

* créer un utilisateur **naturaliz**
* donner les **droits** d'accès à la base de données, aux tables et aux fonctions.

```
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
psql -d $DBNAME -p $DBPORT -c "ALTER ROLE $DBUSER SET search_path TO taxon,occtax,sig,public;"

# Pour le module gestion (optionnel)
psql -d $DBNAME -p $DBPORT -c "GRANT USAGE ON SCHEMA gestion TO $DBUSER";
psql -d $DBNAME -p $DBPORT -c "GRANT SELECT ON ALL TABLES IN SCHEMA gestion TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA gestion TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA gestion TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "ALTER ROLE $DBUSER SET search_path TO taxon,occtax,gestion,sig,public;"

# Pour le module mascarine (optionnel)
psql -d $DBNAME -p $DBPORT -c "GRANT USAGE ON SCHEMA mascarine TO $DBUSER";
psql -d $DBNAME -p $DBPORT -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA mascarine TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA mascarine TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA mascarine TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "ALTER ROLE $DBUSER SET search_path TO taxon,occtax,mascarine,sig,public;"

exit

```




* puis modifier le fichier de configuration des profils pour remplacer l'utilisateur "postgres" par l'utilisateur avec droits limités "naturaliz":

```
cd /srv/lizmap_web_client/

# modifier le paramètre user et password de la section [jdb:jauth] du fichier de profiles
nano lizmap/var/config/profiles.ini.php

# rétablir les droits de l'application Lizmap
lizmap/install/set_rights.sh www-data www-data
```

## Activer les modules dans l'interface d'administration

Les modules **occtax_admin** et **mascarine_admin** doivent être déclarés dans la configuration de Lizmap, pour permettre leur visualisation dans l'interface graphique. Pour cela, il faut modifier le fichier **lizmap/var/config/mainconfig.ini.php** et ajouter **, occtax_admin~*@classic** à la variable **admin** de la section **[simple_urlengine_entrypoints]**

```
cd /srv/lizmap_web_client/
nano lizmap/var/config/mainconfig.ini.php

# remplacer la ligne
admin="jacl2db~*@classic, jacl2db_admin~*@classic, jauthdb_admin~*@classic, master_admin~*@classic, admin~*@classic, jauth~*@classic"
# par
admin="jacl2db~*@classic, jacl2db_admin~*@classic, jauthdb_admin~*@classic, master_admin~*@classic, admin~*@classic, jauth~*@classic, occtax_admin~*@classic"

# Si vous avez aussi activé le module mascarine, vous devez aussi l'ajouter, pour avoir
admin="jacl2db~*@classic, jacl2db_admin~*@classic, jauthdb_admin~*@classic, master_admin~*@classic, admin~*@classic, jauth~*@classic, occtax_admin~*@classic, mascarine_admin~*@classic"

```


## Configuration LDAP


Pour le projet Naturaliz, l'authentification peut se faire via ldap.
Pour cela, il y a un module spécifique ldapdao. Il est activé, mais
pas l'authentification ldap.

Pour se faire, après l'installation, il faut modifier les fichiers
lizmap/var/config/admin/config.ini.php et lizmap/var/config/index/config.ini.php,
en modifiant le nom du fichier pour le plugin auth.

dans lizmap/var/config/admin/config.ini.php :

```
[coordplugins]
auth="admin/authldap.coord.ini.php"
```
et dans lizmap/var/config/index/config.ini.php

```
[coordplugins]
auth="index/authldap.coord.ini.php"
```

Il faut aussi installer le certificat racine SSL du serveur ldap, sur le serveur
apache/php, sinon la connexion au ldap ne pourra se faire. En tant que root:

```
cp lizmap/install/png_ldap.crt /usr/local/share/ca-certificates
update-ca-certificates
service nginx restart
```
