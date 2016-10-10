# Installation des modules Naturaliz pour Lizmap

Pour pouvoir installer l'application Naturaliz, vous devez au préalable avoir installé un serveur cartographique basé sur Lizmap. Vous pouvez cela utiliser les script de déploiement automatique **lizmap-box** pour cela. Nous considérons dans la suite de ce document que Lizmap Web Client a été installé et est fonctionnel.

## Pré-requis

### PostGreSQL

Avant l'installation des modules Naturaliz, vous devez vous assurer d'avoir créé au préalable une base de donnée PostGreSQL, ou d'en avoir déjà une existante. Vous devrez ensuite configurer le fichier de configuration de LizMap contenant les informations de connexion à la base de données PostGreSQL. Ce fichier est situé dans le répertoire **lizmap/var/config** de la racine de l'application Lizmap.

Pendant le processus d'installation de l'application, l'utilisateur PostGreSQL spécifié doit avoir les droits super-utilisateur, afin de pouvoir créer la structure (des droits hauts sont requis notamment pour les extensions). Vous pouvez utiliser l'utilisateur postgres. Un utilisateur "naturaliz" avec des droits limités doit aussi être créé pour l'application.
Modifier les informations (port, nom de la base, etc.). Le code suivant montre un exemple de création de cette base de données et de l'utilisateur.

```
sudo su postgres
# informations de connexion à modifier
DBPORT=5432
DBNAME=naturaliz
DBUSER=naturaliz
DBPASS=naturaliz # !!! MODIFIER CE MOT DE PASSE !!!

# création de l'utilisateur avec droits limités
createuser $DBUSER -p $DBPORT --no-createdb --no-createrole --no-superuser
psql -d template1 -p $DBPORT -c "ALTER USER "$DBUSER" WITH ENCRYPTED PASSWORD '"$DBPASS"' ;"
# création de la base de donnée
createdb -E UTF8 -p $DBPORT -O $DBUSER $DBNAME
psql -d $DBNAME -p $DBPORT -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'
psql -d $DBNAME -p $DBPORT -c 'CREATE EXTENSION IF NOT EXISTS postgis;'
exit

```


Créer un fichier pg_service.conf pour faciliter les accès au bases de données. Attention, sous Windows, le fichier de services doit répondre à certains critères pour être utilisable. Voir https://docs.qgis.org/2.14/fr/docs/user_manual/working_with_vector/supported_data.html#service-connection-file

```
cat > /etc/postgresql-common/pg_service.conf << EOF
[naturaliz]
host=127.0.0.1 # Adapter l'hôte si la bdd est externe
dbname=naturaliz
user=naturaliz
port=5432
password=naturaliz # !!! MODIFIER CE MOT DE PASSE !!!
EOF
```



## Installer les modules Naturaliz sur une application Lizmap

### Récupérer les modules

```
cd /tmp/
git clone git@projects.3liz.org:clients/naturaliz-reunion.git
cp -R naturaliz-reunion/* /srv/lizmap_web_client/lizmap/lizmap-modules/
cd /srv/lizmap_web_client/lizmap/lizmap-modules/
```

### Adapter les fichiers de configuration pour Lizmap

L'installateur lit certains fichiers de configuration, que vous devez donc créer et adapter à votre environnement avant de lancer l'installation. Des fichiers exemples sont fournis, que vous pouvez copier avant de les modifier.

#### Configuration locale

Les modules Naturaliz lisent dans le fichier **lizmap/var/config/localconfig.ini.php** des informations relatives à l'adaptation au contexte local: projection, codes spécifiques, etc. Vous pouvez copier le contenu du fichier **lizmap/lizmap-modules/localconfig.ini.php.dist** et le poser dans le fichier correspondant dans lizmap. Ce fichier doit contenir:

* la colonne des données TAXREF correspondant au lieu principal de l'installation (par exemple "gua" pour la Guadeloupe) : variable **colonne_locale** de la section [taxon]
* la liste des codes d'arrêtés de protection pour la zone concernée (par exemple *GUAM1,GUAO1,GUARA1,DV971,GUAI2* pour la Guadeloupe, ou encode *agri1, agri2, Bubul1, Bulbul2, Bulbul3, Bulbul4, Bulbul5, Bulbul6, Bulbul9, corbasi1, DV974, phelsuma1, phelsuma2, phelsuma3, phelsuma4, phelsuma5, REUEA2, REUEA3, REUEA4, REUEEA, REUEEI, REUI2, REUP* pour La Réunion ) : variable code_arrete_protection**code_arrete_protection** de la section  [taxon]
* le code SRID du système de coordonnées de références des données spatiales du projet : variable **srid** de la section [naturaliz].
* le mot de passe de l'utilisateur admin: variable **adminPassword** de la section [naturaliz].
* le code officiel (cf standard "Occurence de taxon", champ ) des habitats de la zone d'étude (par exemple GUAEAR )

Voir l'exemple localconfig.ini.php.dist à la racine de ce dépôt.

```
cd /srv/lizmap_web_client/
cp lizmap/lizmap-modules/localconfig.ini.php.dist lizmap/var/config/localconfig.ini.php
nano lizmap/var/config/localconfig.ini.php # Faire les modifications nécessaires
```

Exemple de contenu:

```
[modules]
lizmap.installparam=demo

taxon.access=2
occtax.access=2
occtax_admin.access=2
;mascarine.access=2
;mascarine_admin.access=2

[taxon]
; champ determinant le statut local : valeures possibles fr, gf, mar, gua, sm, sb, spm, may, epa, reu, taff, pf, nc, wf, cli
colonne_locale=reu
; liste des codes des arr  t  s de protection qui concernent la zone de travail
code_arrete_protection=agri1, agri2, Bubul1, Bulbul2, Bulbul3, Bulbul4, Bulbul5, Bulbul6, Bulbul9, corbasi1, DV974, phelsuma1, phelsuma2, phelsuma3, phelsuma4, phelsuma5, REUEA2, REUE$

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

```

#### Configuration des accès à PostgreSQL

Vous devez vérifier dans le fichier **lizmap/var/config/profiles.ini.php** les informations de connexion à la base de données PostGreSQL : l'utilisateur doit **avoir des droits élevé pour l'installation**.
Dans la section [jdb:jauth], modifier les variables "user" et "password" pour utiliser par exemple l'utilisateur "postgres". Vous pouvez aussi modifier l'hôte de connexion, le port et le nom de la base de données si besoin.


### Lancer l'installation des modules Naturaliz

Modifiez les droits pour que l'application puisse écrire dans les répertoires temporaires, puis lancer l'installateur de l'application

```
cd /srv/lizmap_web_client/
lizmap/install/set_rights.sh
php lizmap/install/installer.php
```

Si l'installation s'est bien passée, vous ne devez pas voir d'erreurs affichées dans le log. Si ce n'est pas le cas, vérifier les fichiers de configuration, notamment l'accès à la base de données.


## Importer les données de référence

L'installateur a créé la structure dans la base de données PostGreSQL (schéma, tables, vues, etc.), mais aucune donnée n'a encore été importée, à part les listes liées à la nomenclature du standard TAXREF et du schéma Occurence de taxons.

### Import TAXREF : données officielles des taxons

Pour pouvoir effectuer des recherche via le module taxon, vous devez au préalable récupérer les données officielles du TAXREF, puis les importer.

Les fichiers concernant TAXREF, les menaces (listes rouges) et les protections sont téléchargés directement depuis la plateforme SINP (site du MNHN)

#### Taxref

Le fichier officiel du taxref, par exemple *TAXREFv90.txt*

* Source: https://inpn.mnhn.fr/telechargement/referentielEspece/taxref/9.0/menu
* Lien: https://inpn.mnhn.fr/telechargement/referentielEspece/taxref/9.0/zip

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

Exemple : PROTECTION_ESPECES_90.csv

On doit spécifier dans le fichier lizmap/var/config/localconfig.ini.php la liste des codes des arrêtés sur les protections des espèces, par exemple GUAM1,GUAO1,GUARA1,DV971,GUAI2 pour la Guadeloupe

* Source: https://inpn.mnhn.fr/telechargement/referentielEspece/reglementation
* Lien: https://inpn.mnhn.fr/telechargement/referentielEspece/reglementation/zip

Attention, on doit convertir le fichier Excel ( ex: PROTECTION_ESPECES_90.xls ) au format CSV (ex: PROTECTION_ESPECES_90.csv ). Pour cela, utiliser LibreOffice pour ouvrir le fichier Excel, et "Enregistrer sous" avec les options suivantes:
* format CSV
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
php lizmap/scripts/script.php taxon~import:taxref /tmp/TAXREFv90.txt /tmp/LR_Resultats_Guadeloupe_export.csv /tmp/PROTECTION/PROTECTION_ESPECES_90.csv 9
```

Le premier paramètre passé est le chemin complet vers le fichier CSV contenant les données. Le 2ème est le chemin vers le fichier des menaces (taxons sur listes rouges, filtré pour la région concernée).Le 3ème est le fichier contenant les taxon protégés. Vous pouvez pointer vers d'autres chemins de fichiers, et le script se chargera de copier les données dans le répertoire temporaire puis lancera l'import.
Le dernier paramètre est la version du fichier TAXREF (7, 8 ou 9 sont possibles).

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

* Liste des habitats marins, par exemple TYPO_ANT_MER ( Liste des habitats marins des Antilles (Martinique, Guadeloupe) )
* Liste des habitats terrestres, par exemple ceux de la Carte Écologique d'Alain Rousteau

Deux scripts permettent d'importer ces données dans la base, un pour les données WFS, et un autre pour les données Shapefile, Excel et CSV:

* Shapefile : les communes, les mailles 1 et 2, les réserves naturelles nationales, et les habitats
* WFS : les différents espaces naturels disponibles via le serveur, les mailles 10, les masses d'eau

Lancer l'import des données via les commandes suivantes:

```
cd /srv/lizmap_web_client/
# Installation de gdal-bin pour disposer de l'outil ogr2ogr utilisé par le script d'import
apt-get install gdal-bin

# Import des données depuis les Shapefile pour les communes, mailles 1 et 2.
# Import optionnel des réserves naturelles nationales et des habitats
# Vous devez spécifier le chemin complet vers les fichiers dans cet ordre : communes, mailles 1x1km, mailles 2x2km et optionnellement les réserves et les habitats
php lizmap/scripts/script.php occtax~import:shapefile "/tmp/sig/COMMUNE.SHP" "/tmp/sig/grille_1000m_gwada_dep_ama_poly.shp" "/tmp/sig/grille_2000m_gwada_dep_ama_poly.shp" "/tmp/sig/grille_5000.shp" "/tmp/sig/glp_rnn2012.shp" "/tmp/csv/habitats/TYPO_ANT_MER_09-01-2011.xls" "/tmp/csv/habitats/EAR_Guadeloupe.csv"

# Import des données depuis les serveurs WFS officiels
# Vous devez préciser l'URL des serveurs WFS pour les données INPN et pour les données Sandre (masses d'eau)
php lizmap/scripts/script.php occtax~import:wfs http://ws.carmencarto.fr/WFS/119/glp_inpn http://services.sandre.eaufrance.fr/geo/mdo_GLP

# Import des données de relief (Modèle numérique de terrain = MNT ) et des lieu-dits en shapefiles
# Vous devez spécifier les chemins complet vers les fichiers dans cet ordre: MNT, lieux-dits habités, lieux-dits non-habités, oronymes et toponymes divers ( Source IGN )
php lizmap/scripts/script.php mascarine~import:gdalogr "/tmp/sig/DEPT971.asc" "/tmp/sig/LIEU_DIT_HABITE.SHP" "/tmp/sig/LIEU_DIT_NON_HABITE.SHP" "/tmp/sig/ORONYME.SHP" "/tmp/sig/TOPONYME_DIVERS.SHP"

```

## Finaliser l'installation

### Modifier l'utilisateur de la base de données

La base est installée et les données importées. Vous pouvez maintenant

* modifier donner les droits d'accès à la base de données, aux tables et fonctions pour l'utilisateur naturaliz,

```
sudo su - postgres
DBPORT=5432
DBNAME=naturaliz
DBUSER=naturaliz
psql -d $DBNAME -p $DBPORT -c "GRANT CONNECT ON DATABASE $DBNAME TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "GRANT USAGE ON SCHEMA public,taxon,sig,occtax,mascarine TO $DBUSER";
psql -d $DBNAME -p $DBPORT -c "GRANT SELECT ON ALL TABLES IN SCHEMA occtax,sig,taxon TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public,mascarine TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "GRANT INSERT ON ALL TABLES IN SCHEMA occtax TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public,occtax,sig,taxon,mascarine TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public,occtax,sig,taxon,mascarine TO $DBUSER;"
psql -d $DBNAME -p $DBPORT -c "ALTER ROLE $DBUSER SET search_path TO taxon,occtax,mascarine,sig,public;"
exit

```


* puis modifier le fichier de configuration des profils pour remplacer l'utilisateur "postgres" par l'utilisateur avec droits limités "naturaliz":

```
cd /srv/lizmap_web_client/

# modifier le paramètre user et password de la section [jdb:jauth] du fichier de profiles
nano lizmap/var/config/profiles.ini.php

# rétablir les droits
lizmap/install/set_rights.sh www-data www-data
```



## Configuration LDAP


Pour le projet Naturaliz, l'authentification doit se faire via ldap.
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
