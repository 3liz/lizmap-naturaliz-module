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

### Gestion de la sensibilité des données

La sensibilité des observations peut être décidée pendant l'import des données, ou bien après l'import, via une liste de conditions pré-établie.
La sensibilité des observations dépend en effet de nombreux critères sur les taxons, la position de l'observation, les commentaires, et d'autres conditions spécifiques.

L'application Naturaliz permet de stocker l'ensemble des critères de sensibilité dans la table `occtax.critere_sensibilite`, puis de les utiliser pour calculer automatiquement la sensibilitén de chaque observation via une fonction PostgreSQL `occtax.calcul_niveau_sensibilite`. Pour chacun des critères, la fonction teste les observations en fonction de la condition donnée, et pour les jeux de données (jdd_id) passé en paramètre optionnel. Le résultat est stocké dans la table `occtax.niveau_par_observation`, qui liste les observations à modifier, ainsi que la valeur de sensibilité calculée. Comme plusieurs critères peuvent impacter la même observation, la fonction choisi la sensibilité la plus forte et stocke alors une seule ligne par observation dans la table `occtax.niveau_par_observation_final`.

Pour pouvoir filtrer les observations sur lesquelles calculer la sensibilité, on passe en 1er paramètre un tableau d'entier contenant la liste des jdd_id. Pour pouvoir vérifier le calcul, on passe en 2ème paramètre de la fonction un booléen "simulation". S'il vaut TRUE, alors la fonction remplit les tables `occtax.niveau_par_observation` et `occtax.niveau_par_observation_final`, mais ne modifie pas les observations à partir de ces données.

Pour lancer la fonction sur l'ensemble des observations (tous les jdd_id), on peut par exemple lancer le SQL suivant:

```
SELECT occtax.critere_sensibilite(
    (
        SELECT array_agg(jdd_id)
        FROM occtax.jdd
    ),
    FALSE
);
```

NB: Si on veut pouvoir comprendre le nombre d'observations impactées par chacun des critères, on peut lire le contenu de la table `occtax.niveau_par_observation_compteur` qui fournit pour chaque critère (id et libelle) le nombre d'observation impactées, dans le champ `compteur`. La table rappelle aussi la `condition`.

Voir un exemple d'ajout de critères et de calcul de sensibilité automatique: doc/validation/validation_calcul_validation_sensibilite_via_ajout_de_criteres.sql

Cet exemple montre par exemple comment utiliser une jointure avec table spatiale (par exemple de zonages de sensibilité) pour créer un critère qui teste l'intersection entre les observations et des polygones.


### Gestion de la validité des données

Validite niveau et date -> expliquer grand public limité via localconfig et loggués limités via demande

* Voir un exemple d'ajout de critères et de calcul de validation automatique:

doc/validation/validation_calcul_validation_sensibilite_via_ajout_de_criteres.sql

* Projet QGIS exemple pour les validateurs : todo




#### Fonction de modification de la sensibilité des données

#### Vue matérialisée pour gérer la diffusion des données à partir de cette sensibilité

Les requêtes effectuées dans l'application font une jointure entre la table `observation` et la vue matérialisée `observation_diffusion`. Le champ utilisé pour faire les filtres et restreindre les données affichées est le champ `diffusion` qui contient un tableau JSON des diffusions possibles.

Pour l'instant dans l'application, cette diffusion n'est utilisée pour filtrer que si la personne n'a pas le droit de voir les données brutes, c'est-à-dire seulement pour les personnes non connectées, soit le grand public.

Comme le grand public ne peut pas accéder aux données brutes sur la carte (onglet Observations) ou via les exports (seul l'export CSV lui est possible sans la géométrie), les garde-fous sont positionnés sur les mailles renvoyées, et sur les possibilités de recherche spatiale.

Dans ce cas, la diffusion est utilisée dans les situations suivantes :

* la récupération d'une maille à interroger, lorsqu'on clique sur la carte pour récupérer une maille sur laquelle filtrer (boutons spatiaux du formulaire de recherche).

    - le fichier `occtax/controllers/service.classic.php` utilise la fonction `getMaille` de la classe `occtax/classes/occtaxGeometryChecker.class.php`
    - cette fonction `getMaille` ne renvoit une maille que si au moins une observation a été trouvée en dessous avec les crtières de diffusion via `$sql.= " AND ( od.diffusion ? 'g' OR od.diffusion ? '" . $this->type_maille . "' )";`
    - si aucune maille n'est trouvée, un message "Aucune donnée d'observation pour cette maille." est affiché, et l'utilisateur ne peut donc pas faire de recherche spatiale pour cette maille.

* l'affichage des maille 1, 2 ou 10 sur la carte est filtré selon la diffusion, si on n'a pas le droit de voir les données brutes. On considère que le fait d'afficher à la maille 1, 2 ou 10 répond au floutage nécessaire. Donc on filtre

    - fichier `occtax/classes/occtaxSearchObservationMaille.class.php`
    - la fonction `__construct` modifie les `querySelectors`, c'est à dire les champs retournés. Elle vide la géométrie de maille retournée si la diffusion ne permet pas de la récupérer.
    - le récupération des mailles est faite par une sous-requête sur les observations, englobée dans une requête de regroupement des mailles.
    - Par exemple pour la maille 02, la géométrie retournée dans la sous-requête est renvoyée par `CASE WHEN od.diffusion ? 'g' OR WHEN od.diffusion ? 'm02' THEN geom ELSE NULL END geom`. Cette géométrie brute réelle ou vide est ensuite utilisée par la requête supérieure qui renvoit les mailles (avec le décompte des observations et la géométrie de chaque maille). Ne sont donc renvoyées que les mailles pour qui la diffusion est 'g' ou 'm02' (ou 'm10').


* le filtrage des données lorsque l'utilisateur a fait une requête spatiale par masse d'eau ou commune pour le grand public (et donc pas par maille). On ne liste que les données dont la diffusion correspond au type de requête spatiale utilisée, via l'ajout du filtre dans la clause WHERE. Le but est d'empêcher que les utilisateurs fassent des recherches de commune en commune, ou de masse d'eau en masse d'eau, pour deviner en recoupant où sont les mailles d'observations sensibles (une commune ou masse d'eau pourrait découper un petit coin dans une maille, et limiter fortement le floutage à la maille). On ne récupère donc pas les données dont la diffusion est m02 ou m10 lorsqu'on fait une recherche par commune ou par masse d'eau. C'est cohérent

    - le fichier `occtax/classes/occtaxSearchObservation.class.php`
    - la fonction `setWhereClause` ajoute un filtre dans les conditios suivantes : si l'utilisateur n'a pas le droit de voir les données brutes et si un filtre spatial a été ajouté,
    - recherche par commune : le formulaire passe le paramètre `code_commune` . Le filtre ajouté est `AND ( diffusion ? 'g'  OR diffusion ? 'c'  )` si on a fait une recherche par commune
    - recherche par masse d'eau: le formulaire passe le paramètre `code_me`. Le filtre ajouté est `AND ( diffusion ? 'g'  ) ` si on a fait une recherche par masse d'eau
    - recherche par maille 1: le formulaire passe les paramètres `type_maille=m01` et `code_maille=1kmUTM40E330S7668` et `geom=POLYGON de la maille`. Aucun filtre n'est ajouté
    - recherche par maille 2: le formulaire passe les paramètres `type_maille=m02` et `code_maille=2kmUTM40E330S7668` et `geom=POLYGON de la maille`. Aucun filtre n'est ajouté
    - recherche par maille 10: le formulaire passe les paramètres `type_maille=10` et `code_maille=10kmUTM40E330S7670` et `geom=POLYGON de la maille`. Aucun filtre n'est ajouté

* l'export des données rattachées dans le CSV (communes, mailles 10, 02, 01, départements, etc.) est filtrée, si on n'a pas le droit de voir les données brutes

    - fichier `occtax/classes/occtaxSearchObservationBrutes.class.php`
    - fonctions `getDepartement`, `getCommune`, `getMaille01`, `getMaille02`, `getMaille10`, `getEspaceNaturel`, `getMasseEau`
    - Le filtre ajouté dépend du type de rattachement.
    - Par exemple pour les mailles 2 : `AND ( foo.diffusion ? 'm02')`


* todo : vérifier ces critères lorsqu'on va activer le droit pour le grand public (personnes non connectées) de voir l'onglet "observations" sur l'appli. Il faudra filtrer les données via `AND ( foo.diffusion ? 'g')`. Et aussi pour l'export CSV. On pourrait alors toujours faire un CASE WHEN pour que la géométrie sortie soit dépendante du champ diffusion


## Gestion des personnes (observateurs)

### Gestion de la localisation spatiale

Lorsqu'on a importé un jeu de données, il faut raffraîchir les rattachements des observations aux données spatiales (mailles, espaces naturels, communes, etc.). Pour cela, il suffit d'utiliser la fonction PostgreSQL `occtax.occtax_update_spatial_relationships(text[])` . Elle attend 1 variable en entrée : un tableau TEXT[] contenant la liste des jdd_id sur lesquels lancer la modification. Par exemple:

```
SELECT occtax_update_spatial_relationships(
    ARRAY['jdd-test', 'autre-jdd-test']
);
```

Pour le faire sur toutes les observations

```
SELECT occtax_update_spatial_relationships(
    (SELECT array_agg(DISTINCT jdd_id) FROM occtax.observation)
);
```

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

### Structure du schéma taxon

Le schéma taxon de la base de données comporte des tables, vues et fonctions qui permettent à l'application de fonctionner (stockage des cd_nom et cd_ref pour les observations, recherche de taxons par critères, recherche plein texte pour trouver une espèce, etc.).

Nous décrivons certaines tables, vues et fonctions.

#### taxref_valide

Vue matérialisée pour récupérer uniquement les taxons valides (cd_nom = cd_ref) dans la table taxref et dans la table taxref_local.

Elle fait une union entre les 2 tables source et ne conserve que les taxons des rangs FM, GN, AGES, ES, SSES, NAT, VAR, SVAR, FO, SSFO, RACE, CAR, AB.

Elle doit être rafraîchie dès qu'on réalise un import dans une ou l'autre des tables sources: `REFRESH MATERIALIZED VIEW taxon.taxref_valide;`

#### taxref_consolide

Vue matérialisée pour gérer l'association des données du TAXREF (taxref) et des taxons locaux (taxref_local) avec les données complémentaires sur les statuts, la protection, les menaces (t_complement).

Seuls les taxons valides sont présents dans cette table (car elle dépend de la vue matérialisée taxref_valide )

Elle est principalement utilisée pour récupérer les cd_ref des sous-ensembles de taxons à filtrer lorsqu'on chercher des observations. Par exemple, voici une sous-requête pour trouver les observations avec des taxons en danger (o est l'alias de la table occtax.observation):

```
AND o.cd_ref IN (SELECT cd_ref FROM taxon.taxref_consolide WHERE "menace" = 'EN'  )
```

C'est une vue matérialisée, c'est-à-dire une vue qui se comporte comme une table, et qu'on doit mettre à jour suite à un import de taxons (dans taxref ou taxref_local), ou suite à la mise à jour de taxref_valide, via `REFRESH MATERIALIZED VIEW taxon.taxref_consolide;`

#### taxref_consolide_all

Elle consolide aussi les informations du Taxref et des taxons locaux, mais en prenant tous les taxons, pas seulement les valides.
Cette vue est plus simple, et ne contient que les champs cd_nom, group1_inpn et group2_inpn. Elle est utilisée pour le tableau des statistiques et doit être aussi rafraîchie: `REFRESH MATERIALIZED VIEW taxon.taxref_consolide_all`

#### taxref_fts

Vue matérialisée pour le stockage des informations de recherche plein texte visible dans l'application naturaliz.

Cette vue se base sur une UNION des taxons, valides ou non, des tables taxref et taxref_local. On n'a gardé que les taxons des rangs FM, GN, AGES, ES, SSES, NAT, VAR, SVAR, FO, SSFO, RACE, CAR, AB

Un champ poids permet de prioriser la recherche dans cet ordre, avec les poids respectifs 6, 4 et 2:
* noms (nom_valide) des taxons valides (cd_nom = cd_ref)
* noms vernaculaires (nom_vern) des taxons valides (cd_nom = cd_ref)
* noms (nom_complet) des taxons synonymes (cd_nom != cd_ref)

Cette vue doit être rafraîchie dès qu'on modifie les données dans les tables taxref et/ou taxref_local: `REFRESH MATERIALIZED VIEW taxon.taxref_fts`




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


todo : ajouter comment fonctionne la table demande, en précisant notamment qu'on opère des filtres AND et non OR entre les différents champs de la table demande . (important pour cd_ref, group1_inpn, group2_inpn )

### Export des données

#### Depuis l'application

L'application permet d'exporter les données résultats d'une requête sous plusieurs formats. La liste des champs exportés est définie dans le fichier de configuration local de l'application `lizmap/var/config/localconfig.ini.php`, dans les variables suivantes :

```
; liste blanche des champs à exporter
observation_exported_fields=cle_obs, identifiant_permanent, identifiant_origine, statut_observation, cd_nom, cd_ref, version_taxref, nom_cite, nom_valide, nom_vern, group1_inpn, group2_inpn, denombrement_min, denombrement_max, type_denombrement, objet_denombrement, commentaire, date_debut, heure_debut, date_fin, heure_fin, altitude_moy, profondeur_moy, date_determination, ds_publique, jdd_metadonnee_dee_id, dee_date_derniere_modification, jdd_code, reference_biblio, organisme_gestionnaire_donnees, statut_source, sensi_niveau, observateur, determinateur, validateur, descriptif_sujet, validite_niveau, validite_date_validation, precision_geometrie, nature_objet_geo, wkt

; liste blanche des champs à exporter pour le grand public
observation_exported_fields_unsensitive=cle_obs, identifiant_permanent, statut_source, nom_cite, date_debut, date_fin, organisme_gestionnaire_donnees, source_objet, code_commune, code_departement, code_maille_10, wkt

; liste blanche des données filles à exporter
;observation_exported_children=commune, departement, maille_02, maille_10, espace_naturel, masse_eau, habitat, attribut_additionnel
observation_exported_children=commune, departement, maille_02, maille_10, espace_naturel, masse_eau, habitat

```

Ces variables influencent la liste des champs exportés (CSV, WFS) et aussi la liste des champs visibles dans la


Pour paramétrer le texte qui est écrit dans le fichier LISEZ-MOI.txt à la racine du ZIP, vous pouvez modifier le fichier suivant, relativement à la racine de l'application Lizmap : `lizmap/var/config/occtax-export-LISEZ-MOI.txt`
Ce fichier est ensuite complété par l'application avec:

* les informations sur la requête (paramètres de recherche),
* sur le résultat (nombre d'observations),
* la liste des jeux de données de la plate-forme.


### Fiche de détail d'une observation

L'application permet d'afficher pour chaque observation une fiche. Les champs contenus dans cette fiche, ainsi que les données rattachées, sont définis dans le fichier de configuration local de l'application `lizmap/var/config/localconfig.ini.php`, dans les variables suivantes :

```
; liste blanche des champs à afficher dans la fiche d'observation
observation_card_fields=cle_obs,statut_observation, nom_cite, denombrement_min, denombrement_max, objet_denombrement, commentaire, date_debut, date_fin, date_determination, ds_publique, jdd_metadonnee_dee_id, organisme_gestionnaire_donnees, statut_source, sensi_niveau, observateur, determinateur, validateur, descriptif_sujet, obs_methode, occ_etat_biologique, occ_naturalite, occ_sexe, occ_stade_de_vie, occ_statut_biologique, obs_contexte, obs_description, occ_methode_determination, validite_niveau, validite_date_validation, precision_geometrie

; liste blanche des champs à afficher pour le grand public dans la fiche
observation_card_fields_unsensitive=cle_obs, identifiant_permanent, statut_source, nom_cite, date_debut, date_fin, organisme_gestionnaire_donnees, source_objet, code_commune, code_departement, code_maille_10

; liste blanche des données filles à afficher dans la fiche
;observation_card_children=commune, departement, maille_02, maille_10, espace_naturel, masse_eau, habitat, attribut_additionnel
observation_card_children=commune, departement, maille_02, maille_10, espace_naturel, masse_eau, habitat
```


#### Export DEE

Vous pouvez exporter les données au format DEE via l'application en utilisant la ligne de commande.
Vous pouvez préciser en option le chemin vers le fichier à exporter, via l'option *-output*

Pour cet export, la variable de configuration `observation_exported_fields` n'a pas d'impact : tous les champs sont exportés.

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

