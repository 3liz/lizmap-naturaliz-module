# Projet QGIS support de la publication

L'application Naturaliz se base sur Lizmap, et attend un projet QGIS configuré avec le plugin Lizmap pour pouvoir fonctionner.

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


## Génération du cache de tuiles

Les couches de fonds sont souvent très lourdes à afficher, car elle contiennent de nombreuses données, et font parfois appel à des ressources externes (IGN Géoportail, etc.). Il est donc très utile d'activer le cache serveur pour ces couches (avec durée 0 i.e. cache illimité en temps).

Lizmap propose un outil de prégénération du cache. Voir la doc: https://docs.3liz.com/fr/admin/cache.html

Voici un exemple de gestion du cache de tuile pour le fond Ortophoto du projet de la Réunion (modifier le nom des couches et autres paramètres selon vos besoins)

```bash
# Aller dans le répertoire racine de l'application Lizmap
cd /srv/lizmap_web_client

### Récupération des capacités WMTS
php lizmap/scripts/script.php lizmap~wmts:capabilities run borbonica

# renvoit :
For "cartes" and "EPSG:2975" from TileMatrix 0 to 9
For "Cartes IGN" and "EPSG:2975" from TileMatrix 0 to 9
For "TOPO" and "EPSG:2975" from TileMatrix 0 to 9
For "ortho" and "EPSG:2975" from TileMatrix 0 to 9
For "FOND_TOPO" and "EPSG:2975" from TileMatrix 0 to 9
For "BDORTHO" and "EPSG:2975" from TileMatrix 0 to 9

# Génération des tuiles du fond ortho
# test sur les 1er niveaux de zoom: 0 = 1/4M, 1 = 1/3M et 2 = 1/2M
# emprise sur l'île seulement via paramètre bbox, important pour éviter de générer des tuiles en mer !
php lizmap/scripts/script.php lizmap~wmts:seeding -v -bbox "314000,7633000,380000,7692000" run borbonica ortho "EPSG:2975" 0 2

# renvoit
The TileMatrixSet 'EPSG:2975'!
9 tiles to generate for "ortho" "EPSG:2975" "0" "314000,7633000,380000,7692000"
12 tiles to generate for "ortho" "EPSG:2975" "1" "314000,7633000,380000,7692000"
20 tiles to generate for "ortho" "EPSG:2975" "2" "314000,7633000,380000,7692000"
41 tiles to generate for "ortho" "EPSG:2975" between "0" and "2"
Start generation
================
Progression: 12%, 5 tiles generated on 41 tiles
Progression: 24%, 10 tiles generated on 41 tiles
Progression: 36%, 15 tiles generated on 41 tiles
Progression: 48%, 20 tiles generated on 41 tiles
Progression: 60%, 25 tiles generated on 41 tiles
Progression: 73%, 30 tiles generated on 41 tiles
Progression: 85%, 35 tiles generated on 41 tiles
Progression: 97%, 40 tiles generated on 41 tiles
================
End generation

```

Il faut le lancer sur l'ensemble des niveaux de zoom intéressants. Attention, cela peut prendre beaucoup de temps et de ressources. Il n'est pas forcément pertinent de générer tout le cache de tuiles jusqu'aux dernières échelles, qui doivent normalement être plus rapide à rendre, et les tuiles peuvent donc être créées à la demande.
