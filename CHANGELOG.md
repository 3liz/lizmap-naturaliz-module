# CHANGELOG

### 2.7.5 - 12/10/2020

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

### 2.7.3 - 08/09/2020

* Occtax - Improve install script

### 2.7.4 - 08/09/2020

* Occtax - Try/catch pour ajout des droits & fichier SQL de remplacement

### 2.7.3 - 08/09/2020

* Occtax - Improve install script

### 2.7.2 - 08/09/2020

* Gestion - Improve install script

### 2.7.1 - 08/09/2020

* Gestion - Remove foreign key demande_user_login_fk

### 2.7.0 - 08/09/2020

* Occtax/Gestion - Refonte de l'installation
* Occtax - remove useless old code
* Validation - Ajout champ identifiant_origine dans v_observation_validation
* Carte - Zoom sur observation. Ne pas aller à l'échelle maximum_observation_scale si on est à + grande échelle
* Interface - fiche observation masquée si autre onglet ouvert
* Demandes - Tentative d'amélioration de performance: sous-requête & demandes actives
* Taxref - ajout menace régionale, variables de configuration, nettoyage

### 2.6.1 - 03/07/2020

* Taxon - déplacement des images de catégories dans install/www/
* Revert "CSS/JS - Move files to install/www and use upgrade to copy them"

### 2.6.0 - 02/07/2020

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

###
