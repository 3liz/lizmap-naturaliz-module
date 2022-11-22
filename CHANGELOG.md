# Changelog

## Unreleased

### Fixed

### Added

## 2.13.1 - 2022-11-22

### Changed

* Formulaire de recherche - amélioration de l'interface de recherche par attributs de taxon
  * Remplacement des listes déroulantes par des listes de boutons poussoirs
  * Utilisation d'images pour les groupes taxonomiques et les habitats
  * Utilisation des couleurs pour les menaces
  * Rendu plus compact du formulaire (marges, espacements, taille des polices)
* Gestion - Amélioration du projet de gestion
  * Nouvelle couche v_jdd_spatial pour visualiser les emprises des JDD et supprimer les observations
  * Nouvelle couche ZEE pour rafraîchir les vues matérialisées
* Documentation - Amélioration du fichier USAGE.md

### Fixed

* Taxon - Correction des données d'installation pour taxon.t_group_categorie

### Added

* Installation & mise à jour - amélioration des scripts et support de Lizmap Web Client 3.6
* Import des référentiels SIG - Martinique : Ajout de l'UNESCO dans le script d'import SIG

### Backend

* Code interne - Déplacement des fichiers CSS et JavaScript

## 2.13.0 - 2022-09-30

* Import Web
  * Amélioration des fonctions SQL: test des doublons, prise en compte des organismes, email par défaut
  * Ajout des variables dans l'interface d'administration: organismes, email par défaut.
  * Ajout automatique d'un item dans la table occtax.jdd_import
  * Utilisation d'une liste déroulante pour le champ "Organisme gestionnaire de données"
* Import Web et Gestion - Projet QGIS & Lizmap pour la gestion et la validation des imports
* Doc - Amélioration de la documentation pour l'import CSV

## 2.12.10 - 2022-07-26

* SQL - Correction de bugs sur les vues matérialisées

## 2.12.9 - 2022-07-26

* SQL - Ajout d'un index sur le champ `odata` de la table observation pour améliorer
  les performances des requêtes par maille en mode non connecté

## 2.12.8 - 2022-07-25

* Doc - Gestion: amélioration du projet QGIS de gestion & ajout configuration Lizmap pour publication
* Vue matérialisée - Amélioration des requêtes pour consolider les données dans vm_observation
* Formulaire de recherche - Autocomplétion taxon et JDD: permettre l'ajout multiple sans fermer la popup
* Tableau des observations - Correction du bug sur le tri par niveau de validité
* Import CSV - Correction de la visibilité des observations importées
* Fiche taxon - ajout de commentaire dans la récupération du contexte pour les menaces
* Adaptation de l'installation pour Lizmap 3.6


## 2.12.7 - 2022-06-21

* Corrections dans les fichiers de locales
* Corrections dans les dépendances des fichiers module.xml

## 2.12.6 - 2022-06-09

* Fiche taxon - Listes rouges: ajout du contexte Nicheur, Visiteur, etc.

## 2.12.5 - 2022-05-13

* Import CSV
  - Améliorations et ajout d'une fonction de validation
  - Contrôle moins stricte de la valeur de l'identifiant du JDD (UUID)
  - Amélioration de la documentation
* Historique de recherche
  * Création d'une table dans la base PostgreSQL pour stocker l'historique
    et script de migration pour récupérer les données actuelles depuis le cache

## 2.12.4 - 2022-04-06

* Outil d'import:
  * Ajout d'un contrôle sur le nombre de colonnes de l'entête et de la 1ère ligne
  * Correction du fichier CSV exemple (mauvaises valeurs pour les observateurs et déterminateurs)
* Historique de recherche
  * Adaptation dynamique de la hauteur en fonction de la taille de la fenêtre
    pour éviter la double barre de défilement
  * Correction du répertoire de destination par défaut pour le stockage
* Métadonnées JDD - Autoriser l'utilisation d'un jdd_id non entier

## 2.12.3 - 2022-03-30

* Outil d'import:
  * Ajout d'un filtre pour masquer dans les résultats de recherche les observations
  qui ont été importées mais pas encore activées par les administrateurs
  * Correction du bug sur le test de conformité des géométries par rapport aux mailles 10km
  * Correction des scripts SQL

## 2.12.2 - 2022-03-29

* Outil d'import: améliorations diverses
  * Ajout d'un lien pour télécharger un fichier Excel avec la nomenclature des champs
    du standard
  * Augmentation de la limite de taille du CSV (de 200 ko à 2 Mo)
  * Correction des droits sur les tables pour permettre la modification en ligne
  * Ajout d'un test de conformité sur le champ nature_objet_geo
  * Ajout d'une géométrie représentant l'enveloppe des observations dans la vue
    qui montre les différents imports

## 2.12.1 - 2022-03-28

* Outil d'import - Correction du script SQL d'installation

## 2.12.0 - 2022-03-28

* Ajout d'un outil de validation et d'import des données d'observations
  à partir d'un fichier CSV:
  * contrôle de conformité selon le standard "Occurrences de Taxon"
  * import des observations et ventilation dans les tables liées
    (personnes, observation_personne, organisme, etc.)
* Ajout de vues pour visualiser:
  * la liste des imports en attente de validation par l'administrateur: `occtax.v_import_web_liste`
  * les données d'observations importées: `occtax.v_import_web_observations`

## 2.11.4 - 2022-03-21

* Historique de recherche - modification du fichier de stockage des historiques des utilisateurs
  pour prendre en compte des installation avec la configuration séparée du code source

## 2.11.3 - 2022-03-21

* Historique de recherche:
  * Suppression de l'historique de recherche du navigateur lorsqu'un utilisateur se connecte
  * Déplacement du stockage de l'historique de recherche dans un répertoire système stable
  pour éviter sa suppression lors du vidage du cache
* Statistiques: mise à jour du projet support des statistiques `doc/qgis/stat_naturaliz.qgs`

## 2.11.2 - 2022-02-09

* Refonte du bouton de zoom sur les résultats: il s'appuie maintenant
  sur l'emprise totale de l'ensemble des observations renvoyées par la recherche
  et pas sur les géométries affichées initialement sur la carte
* Historique de recherche - Ajout des items favoris créés hors connexion dans les favoris
  de l'utilisateur lorsqu'il se reconnecte
* Légères modifications de l'affichage des menaces dans la fiche Taxon:
  * le nom du statut est affiché au lieu du nom du groupe. Ex: "liste rouge nationale" au lieu de "liste rouge"
  * une icône avec la couleur de la menace est affichée à côté de la valeur
  * l'infobulle au survol de la souris est traitée en JavaScript (affichage plus rapide)
* Adaptations du code pour Lizmap Web Client >= 3.5
* Recherche - Ajout de données de tests pour l'envoi de polygones GeoJSON

## 2.11.1 - 2021-01-11

* Correction d'un bug sur le script de mise à jour vers la 2.11.0

## 2.11.0 - 2021-01-11

* Recherche: modification du champ de recherche pour filtrer les jeux de données (JDD):
  * le champ se présente comme pour la recherche d'un taxon, avec une autocomplétion
  qui recherche dans l'identifiant, le libellé et la description du JDD,
  * l'utilisateur peut ajouter 1 à plusieurs JDD dans une liste,
* Panneau de résultats: ajout d'un nouvel onglet contenant la liste des JDD concernés
  ainsi sur le décompte des observations et des taxons distincts pour chaque JDD.
* Ajout de la possibilité d'ouvrir un panneau, accessible en cliquant sur le libellés des JDD,
  qui affiche:
  * les informations détaillées du JDD,
  * les informations détaillées du cadre d'acquisition (si renseigné),
  * un bouton permettant d'ouvrir l'URL précisée dans la base vers un site externe (ex: INPN)

## 2.10.6 - 2021-11-02

* Historique de recherche:

    - suppression de la géométrie précédente
      lors de l'activation d'une nouvelle recherche
    - enregistrement pérenne de l'historique pour les utilisateurs connectés

* Correction d'un dysfonctionnement sur l'outil de zoom sur les observation

## 2.10.4 - 2021-10-28

* Historique de recherche :
  - support de la sélection multiple des items de recherche (utile par exemple pour supprimer plusieurs items en une fois)
  - correction d'un bug sur le mauvais affichage des géométries de recherche

## 2.10.3 - 2021-10-14

* Ajout d'un nouveau panneau "Mes recherches" avec l'historique des recherches
* Corrections diverses sur la recherche
* Correction de l'affichage "gros trait bleu" sur les mailles au survol
* Correction de l'affichage de la fiche de validité d'une observation
  lorsque la demande utilise des champs de vm_observation (ex: group2_inpn)

## 2.10.2 - 2021-09-02

* Export WFS - Correction du filtrage des données par demande
* Impression - désactivation de l'impression des résultats sur la carte (observations et mailles) : incompatible avec le nouveau rendu par cluster

## 2.10.1 - 2021-08-22

* Validation - Correction d'un bug sur la rechercher lorsque le filtre par niveau de validité est appliqué
* Admin - Ajout de la version dans la page de visualisation de la configuration du module Occtax

## 2.10.0 - 2021-07-29

* Validation - Ajout d'un outil de validation en ligne (échelle régionale)

## 2.9.2 - 2021-07-22

* Fiche taxon - Correction de l'affichage pour Lizmap Web Client >= 3.4
* Carte - Observations: compatibilité de l'affichage par cluster pour LWC >= 3.4.0
## 2.9.1 - 2021-06-23

* Backend - getData: écriture des données dans un fichier pour éviter souci RAM
* CI - Update te CI and the changelog file
* Carte - Augmentation des observations max de 4000 à 15000
* Documentation - Ajout d'un chapitre sur la diffusion des données

## 2.9.0 - 2021-06-08

* Carte - Amélioration du rendu des observations brutes
  - affichage en mode cluster (déplacement de points), pour mieux gérer la superposition des observations
  - affichage découplé entre le tableau de résultats et la carte, pour afficher toutes les observations
  et pas seulement les 100 visibles dans le tableau
  - plusieurs symbologies: par menace, par protection, par date
* Légende - possibilité de masquer/afficher la légende

## 2.8.3 - 2021-04-16

* Add script entry point in composer.json for occtax autoconfig-access

## 2.8.2 - 2021-04-16

* Fix - Zoom sur l'observation: utilisation des map.resolutions si map.scales non défini
* Installation/Upgrade - Ajout d'une vue manquante taxon.taxref_consolide
* Recherche spatiale - Correction de la recherche par maille

## 2.8.1 - 2021-04-15

* Fix upgrade de la 2.7.8 à la 2.8.0

## 2.8.0 - 2021-04-02

* Amélioration des scripts d'installation
* Structure PostgreSQL - Suppression des search_path et déclaration obligatoire des schémas
* Occtax - Ajout du script SQL avec les fonctions du schéma divers
* Taxon - Ajout de 2 scripts exemple pour l'import TAXREF (plus simple pour Martinique)
* Occtax - Adaptation du listener pour afficher le projet naturaliz à Limap Web Client >= 3.4
* Taxon - suppression du script d'import PHP de Taxref
* Mascarine - Suppression des modules dépréciés
* Doc - Modification pour l'import du TAXREF (manuel)

## 2.7.8 - 2021-03-18

* Fix bug dans le SQL des vues matérialisées
* Doc & script - suppression des scripts d'import de données SIG

## 2.7.6 - 2020-10-28

* Gestion - demande: suppression des champs cd_ref, group1_inpn et 2, validite_niveau
* Export - retourne seulement les JDD des observations exportées
* Zoom sur observation - correction bug de mauvaise échelle / max_scale
* Occtax - Correction souci des icônes taxon avec accent

## 2.7.5 - 2020-10-12

* Gestion - Simplification des requêtes de demande: ajout direct des filtres sans passer par occtaxSearchObservation
* Export/Fiche - Menaces: affichage du libellé au lieu du code
* Fiche taxon - ajout bouton fermer & correction des ajouts multiples si plusieurs clics
* Taxon - Ajout d'un libelle_court à t_group_category et utilisation version normalisée pour image
* Gestion - Demandes: requête directe sur les cd_nom sans requête récursive
* Install - SQL: ajout occtax.cadre et gestion.acteur.en_poste
* Fiche taxon - déplacement du bouton de lien en haut
* Fiche taxon - Ajout des informations sur les statuts
* Taxon - Modification sur script d'ajout des droits pour occtax
* Taxon - correction mineures sur les scripts install & upgrade
* Taxon - Nouvelle version du script complet d'import TAXREF
* Interface - Basculer les boutons de carte sous la fiche taxon

## 2.7.3 - 2020-09-08

* Occtax - Improve install script

## 2.7.4 - 2020-09-08

* Occtax - Try/catch pour ajout des droits & fichier SQL de remplacement

## 2.7.3 - 2020-09-08

* Occtax - Improve install script

## 2.7.2 - 2020-09-08

* Gestion - Improve install script

## 2.7.1 - 2020-09-08

* Gestion - Remove foreign key demande_user_login_fk

## 2.7.0 - 2020-09-08

* Occtax/Gestion - Refonte de l'installation
* Occtax - remove useless old code
* Validation - Ajout champ identifiant_origine dans v_observation_validation
* Carte - Zoom sur observation. Ne pas aller à l'échelle maximum_observation_scale si on est à + grande échelle
* Interface - fiche observation masquée si autre onglet ouvert
* Demandes - Tentative d'amélioration de performance: sous-requête & demandes actives
* Taxref - ajout menace régionale, variables de configuration, nettoyage

## 2.6.1 - 2020-07-03

* Taxon - déplacement des images de catégories dans install/www/
* Revert "CSS/JS - Move files to install/www and use upgrade to copy them"

## 2.6.0 - 2020-07-02

* CSS/JS - Move files to install/www and use upgrade to copy them
* Interface - homogénéisation des couleurs
* Fiche observation - Zoom auto au moment de l'affichage de la fiche
* Observation - Restrict zoom to a maximum scale read in config
* Fiche observation - fix bug d'affichage après dev export asynchrone
* Export - localisation des messages
* Export - Remove old code && adapt JS
* Export - lancement de la tâche en asynchrone, avec page d'attente
* Interface - Tous les boutons sont bleus foncés
* Recherche - sélections multiples: améliorations comportement sumoselect
* Conservation des paramètres après déconnexion
* Interface - déblocage du panneau de gauche seulement à l'affichage des données sur la carte
* Recherche - ajout de la bbox dans l'URL & vidage si réinitialisation
* Impression - correction d'un bug si pas de résultat
* Recherche - Listes multiples: ajout d'un passage à la ligne pour les longs textes
* Gestion - Correction bug de requête si demande contient un filtre taxons
* Recherche - sélection multiple dans les liste: correction bug visibilité
* Fiche observation - Ajout du décompte des observations et de la position, désactivation des boutons si début ou fin
* Taxon - déplacement de menace et protection dans 2 colonnes & correction tooltip
* Tableau des taxons - Icônes menace et protection à côté du nom valide
* Détail d'une observation - ajout de bouton précédent, suivant et zoom
* Liste d'observations - ajout d'un bouton de zoom
* Fix some bugs after last commit BIS
* Fix some bugs after last commit
* Recherche - sélection multiple sur les listes déroulantes via sumoselect
* Modification dynamique de l'URL à chaque recherche, qui permet de relancer la recherche
* Recherche - désactivation du panneau de recherche si recherche en cours
* Session - message de reconnexion et rechargement si la session a expirée
* Stats - améliorations des matérialisées
* Recherche - fix bug réinitialisation & Impression - fix bug quand pas de données
