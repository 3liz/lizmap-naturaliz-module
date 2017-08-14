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

#### Informations sur le projet

L'application Naturaliz permet d'utiliser des fichiers HTML externes pour remplacer le contenu du panneau d'information du projet.

Pour cela, il faut créer des fichiers HTML pour chaque section:

* **Présentation de la plateforme**: peut contenir une description du SINP, des acteurs locaux, de l'application.
* **Mentions légales**: décrit les informatinos légales (déclaration CNIL), propriétés des données, conditions de diffusions, etc.

Ces fichiers doivent porter le nom du projet, ainsi qu'un nom défini. Par exemple, si le projet QGIS s'appelle naturaliz.qgs, alors les fichiers devront s'appeler:

* **naturaliz.qgs.presentation.html** pour la présentation de l'application
* **naturaliz.qgs.legal.html** pour les informations légales

Pour créer ces fichiers HTML, nous conseillons d'écrire un texte simple, au format Markdown, puis de l'exporter en HTML via l'application **Remarkable** (disponible sous Linux: http://remarkableapp.github.io/) ou via un convertisseur en ligne, par exemple http://parsedown.org/demo


#### Statistiques globales.

L'application permet d'afficher un à plusieurs graphiques, basés sur les données de la base. Pour cela, on utilise l'outil Dataviz, disponible depuis Lizmap Web Client 3.2.

Chaque graphique s'appuie sur une couche du projet QGIS. On peut donc créer des couches à partir d'une requête, via le gestionnaire de bases de données de QGIS, puis utiliser cette couche comme source pour le graphique.

Quatre exemples sont proposés dans les sources de naturaliz. On peut les ouvrir via les fichiers QLR qui se trouvent dans le répertoire `occtax/install/qgis/statistiques/`, avec le menu QGIS `Couches / Ajouter depuis un fichier de définition de couche (QLR)`


#### Impression


L'impression se base sur la fonctionnalité de QGIS, à travers un composeur d'impression. Vous devez donc créer un nouveau composeur, et aussi ajouter certaines couches pour la visualisation du résultat des requêtes.

##### Créer un composeur d'impression

L'impression se base sur un **modèle de composeur** qui comporte certaines spécificités. Vous pouvez ajouter à votre projet QGIS un composeur d'impression à partir du modèle `composeur_impression.qpt` situé dans le répertoire `naturaliz/occtax/install/`, via le menu `Projet / Gestionnaire de composeurs`.

Une fois le composeur créé vous pouvez adapter:
* Le logo utilisé: vous devez absolument utiliser un logo situé dans le répertoire `media` situé à côté du projet QGIS
* Le titre : configurer le contenu textuel pour ce titre

Le bloc texte avec la mention "Pas de filtres actifs" **ne doit pas être modifié**, car il sera rempli automatiquement par l'application (avec la légende et les critères de recherche).

En page 2, le tableau de données **ne doit pas être modifié**. En effet il sera configuré de manière automatique par l'application.

##### Couches pour afficher les résultats des requêtes

Certaines couches doivent être ajoutées pour permettre à l'application d'imprimer les résultats de requête visibles sur l'application Web. En effet, ces résultats, visibles sur le navigateur, ne sont pas dans des couches du projet QGIS, et QGIS ne peut donc pas normalement imprimer ces données.

Pour cela, il faut ajouter 4 couches pour gérer les différents types de résultats (mailles ou données brutes), et gérer les différents types de géométrie (point, lignes, polygones), et leur donner un style adéquat. Dans les sources de l'application, vous pouvez trouver des fichiers QLR qui répondent à ce besoin (voir le répertoire `naturaliz/occtax/install/print` )

* observation_brute_centroid
* observation_brute_linetring
* observation_brute_point
* observation_brute_polygon
* observation_maille

Ces couches peuvent être ajoutées dans un groupe nommé **Hidden**, à la racine de l'arbre des couches du projet QGIS, pour être exploitables mais non visibles dans l'application web. Par contre, il faut **absolument** que ce groupe soit placé au-dessus des autres couches dans la légende (pour qu'elles soient visibles à l'impression).

Après avoir ajouté ces couches, il faut **absolument spécifier leur système de projection** (par exemple : EPSG:2975). Vous pouvez pour cela par exemple faire un clic-droit sur le groupe qui les contient, et choisir `Définir le SCR du groupe`.

Pour qu'elles fonctionnent, il faut utiliser une connexion PostgreSQL vers la base à l'aide d'un **service PostgreSQL**, nommé **naturaliz**, et que l'utilisateur configuré dans ce service ait bien accès aux vues du schéma sig.

Voir l'aide de QGIS sur les services :
* Côté bureautique : https://docs.qgis.org/2.18/en/docs/user_manual/working_with_vector/supported_data.html#service-connection-file
* Côté serveur : http://docs.qgis.org/testing/en/docs/user_manual/working_with_ogc/ogc_server_support.html#connection-to-service-file


## Import de données

Lors de l'installation, une structure de données conforme au standard "Occurences de taxon" a été créée dans la base de données. Pour pouvoir exploiter l'application, il faut importer des données d'observations.

## Jeux de données

todo: expliquer la notion et les tables utilisées

### Gestion de la validité des données

Validite niveau et date -> expliquer grand public limité via localconfig et loggués limités via demande

### Gestion de la sensibilité des données

Sensibilité -> montrer requete pour faire un update des champs de sensibilité à partir de critères
Voir fonction https://projects.3liz.org/clients/naturaliz-reunion/issues/48


## Gestion des personnes (observateurs)

## Gestion de la localisation spatiale

### Identifiants permanents

décrire la table lien identifiant permanent

DONNEES SOURCES
id  observateurs    x
1   bob 1
2   martin  2

OCCTAX.OBSERVATION
cle_obs identifiant_permanent   identifiant_origine
34  AABB-CCERER 1
45  FFGSDSGF-HHFDH  2

lien_observation_identifiant_permanent
jdd_id  identifiant_origine identifiant_permanent
pnrun   1   AABB-CCERER
pnrun   2   FFGSDSGF-HHFDH


Quand on supprime toutes les données d'un JDD avant réimport
* on crée un identifiant_permanent seulement pour celles qui n'en ont pas (on se base sur l'id du jdd source comme identifiant_origine et sur la table lien_observation_identifiant_permanent )
* toutes les données du jeu source déjà importée, qui avaient été modifiée entre 2 imports, vont bien être réimportées avec leurs données à jour
* on modifie le cle_obs de notre bdd, et donc si c'est utilisé par d'autre bdd (qui importent nos données) alors elles peuvent perdre le lien ! Ces bdd de destination doivent donc se baser sur l'identifiant_permanent et le champ `cle_obs` (qui rentre dans leur identifiant d'origine) pour faire la correspondance. Notre champ `identifiant_permanent` est donc enregistré dans leur champ `identifiant_origine` (pour les données provenant de notre bdd dans leur bdd)


On peut créer autant de jdd, que d'année, par exemple, pour éviter la suppression de toutes les données qui étaient dans la base de données.


## Module Taxon

Module de gestion des données TAXREF



## Module Occtax

Module de gestion des données au format Occurence de Taxon


### Gestion des listes rouges et des espèces protégées




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



## TODO

