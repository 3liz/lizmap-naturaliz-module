# Naturaliz - Guide d'utilisation

## Projet QGIS

### Publication avec Lizmap

N'importe quel projet QGIS peut être utilisé pour support de la carte de l'application Naturaliz. Il suffit de configurer le projet avec le plugin Lizmap.

Une fois ce projet configuré et publié, vous pouvez configurer via l'interface d'administration de Lizmap, dans le menu Occtax, le répertoire et le projet utilisé pour l'application.

Vous pouvez aussi modifier directement ce paramètre dans le fichier `lizmap/var/config/localconfig.ini.php` de l'application, dans la section occtax. Il faut utiliser les codes du répertoire Lizmap et du projet.

```
[occtax]
defaultRepository=
defaultProject=
```

### Caractéristiques spécifiques pour Naturaliz

En plus d'une publication classique, il y a quelques points à prendre en compte dans le projet QGIS support.

#### Impression

Certaines couches doivent être ajoutées pour permettre à l'application d'imprimer les résultats de requête visibles sur l'application Web. En effet, ces résultats, visibles sur le navigateur, ne sont pas dans des couches du projet QGIS, et QGIS ne peut donc pas normalement imprimer ces données.

Pour cela, il faut ajouter 4 couches pour gérer les différents types de résultats (mailles ou données brutes), et gérer les différents types de géométrie (point, lignes, polygones), et leur donner un style adéquat. Dans les sources de l'application, vous pouvez trouver des fichiers QLR qui répondent à ce besoin (voir le répertoire `naturaliz/occtax/install/print` )

* observation_brute_centroid
* observation_brute_linetring
* observation_brute_point
* observation_brute_polygon
* observation_maille

Ces couches peuvent être ajoutées dans un groupe nommé **Hidden**, à la racine de l'arbre des couches du projet QGIS, pour être exploitables mais non visibles dans l'application web.

Pour qu'elles fonctionnent, il faut utiliser une connexion PostgreSQL vers la base à l'aide d'un **service PostgreSQL**, nommé **naturaliz**

Voir l'aide de QGIS sur les services :
* Côté bureautique : https://docs.qgis.org/2.18/en/docs/user_manual/working_with_vector/supported_data.html#service-connection-file
* Côté serveur : http://docs.qgis.org/testing/en/docs/user_manual/working_with_ogc/ogc_server_support.html#connection-to-service-file


#### Informations sur le projet

L'application Naturaliz permet d'utiliser des fichiers HTML externes pour remplacer le contenu du panneau d'information du projet.

Pour cela, il faut créer des fichiers HTML pour chaque section:

* **Présentation de la plateforme**: peut contenir une description du SINP, des acteurs locaux, de l'application.
* **Mentions légales**: décrit les informatinos légales (déclaration CNIL), propriétés des données, conditions de diffusions, etc.

Ces fichiers doivent porter le nom du projet, ainsi qu'un nom défini. Par exemple, si le projet QGIS s'appelle naturaliz.qgs, alors les fichiers devront s'appeler:

* **naturaliz.qgs.presentation.html** pour la présentation de l'application
* **naturaliz.qgs.legal.html** pour les informations légales

Pour créer ces fichiers HTML, nous conseillons d'écrire un texte simple, au format Markdown, puis de l'exporter en HTML via l'application **Remarkable** (disponible sous Linux: http://remarkableapp.github.io/) ou via un convertisseur en ligne, par exemple http://parsedown.org/demo


## Module Taxon

Module de gestion des données TAXREF



## Module Occtax

Module de gestion des données au format Occurence de Taxon


### Gestion des listes rouges et des espèces protégées


### Import des données d'observation


### Gestion de la validité des données

Validite niveau et date -> expliquer grand public limité via localconfig et loggués limités via demande

### Gestion de la sensibilité des données

Sensibilité -> montrer requete pour faire un update des champs de sensibilité à partir de critères
Voir fonction https://projects.3liz.org/clients/naturaliz-reunion/issues/48


## Module Gestion

Gestion des accès via table demande. Nous avons simplifié l'utilisation des groupes pour gérer les accès:

* Groupe admins = les super-utilisateurs de l'application (plateforme régionale) qui peuvent accéder à toutes les données sans restriction
* Groupe acteurs = les personnes qui peuvent voir les données brutes, mais filtrées selon certains critères, comme les taxons, la validité
* Groupe virtuel anonymous = les personnes non connectées à l'application.

Les acteurs vont être gérés dans des tables créées lors de l'installation par le module **gestion**.

Un exemple de script SQL est disponible dans les sources de l'application, et montre comment insérer des nouveaux acteurs, organismes, etc., et comment leur donner des droits sur les données.

`referentiels/gestion/ajout_demande.sql`


### Export des données

Vous pouvez exporter les données au format DEE via l'application en utilisant la ligne de commande.
Vous pouvez préciser en option le chemin vers le fichier à exporter, via l'option *-output*

```
cd /srv/lizmap_web_client/
php lizmap/scripts/script.php occtax~export:dee -output /tmp/donnees_dee.xml
```


## Module Mascarine

Module de saisie d'observation floristiques en suivant les bordereaux d'inventaire conçus par le Conservatoire Botanique National de Mascarin (CBN-CBIE Mascarine, La Réunion)

### Validation des données saisies

Les données saisies à travers l'interface (ou via l'outil mobile) tombent dans un sas de validation. Le gestionnaire des données de l'application (profil 1) doit valider manuellement chaque observation pour qu'elles soient consultable par l'ensemble des utilisateurs (sinon, seul l'auteur et le gestionnaire peuvent les consulter).

Une fois validée, les observations de Mascarine peuvent être automatiquement exportées vers le schéma "Occurence de taxons" (occtax). Pour cela, il faut se connecter à la base de données, et lancer la fonction **mascarine.export_validated_mascarine_observation_into_occtax** en passant en paramètre une liste d'identifiants d'observations. Par exemple

```
SELECT mascarine.export_validated_mascarine_observation_into_occtax(o.id_obs) FROM mascarine.m_observation o WHERE validee_obs = 1 AND blablalba;
```

