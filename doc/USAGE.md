# Naturaliz - Guide d'utilisation

## Import de données

### Import manuel via des scripts SQL

Lors de l'installation, une structure de données conforme au standard "Occurences de taxon" a été créée dans la base de données. Pour pouvoir exploiter l'application, il faut importer des données d'observations.


Une fois les données importées, il faut absolument rafraîchir certaines vues matérialisées utilisées par l'application.

```sql

-- Vue qui calcul la sensibilité des données pour contrôler leur diffusion
REFRESH MATERIALIZED VIEW observation_diffusion;

-- Vue qui rassemble à plat dans une seule entité la plupart des informations sur les observations
REFRESH MATERIALIZED VIEW occtax.vm_observation;

```

### Import assisté depuis l'interface Web

Une entrée de menu permet de proposer à l'utilisateur ayant les droits requis de téléverser dans l'application un fichier CSV, puis de lancer

* la validation du jeu de données: champs requis, format des données, respect des règles du standard Occurences de Taxon
* l'import des données dans la base, avec un statut "A valider". Les observations importées ne seront visibles que par les administrateurs de la base dans l'application

Le fichier CSV attendu doit correspondre à un modèle bien spécfique, avec une liste minimal de champs, nommés correctements. Un fichier CSV exemple est disponible dans les sources.

## Jeux de données

todo: expliquer la notion et les tables utilisées

## Gestion de la sensibilité des données

Les modalités de diffusion des données sont définies par la charte régionale du SINP.
Cette dernière prévoit deux niveaux d’accès : experts et professionnels, ou grand public.
Les experts et professionnels accèdent aux données précisément géolocalisées
sur la base d’une demande à formuler sur Borbonica.
Les adhérents à la charte régionale bénéficient d’un accès facilité.
Le grand public accède aux données à des données moins précises.
Le niveau de diffusion au grand public résulte de la combinaison de plusieurs paramètres,
hiérarchisés ci-dessous (du plus important au moins important) :

* **statut de validation** de la donnée (champ `validite_niveau`) : seules les données dont la validité est ‘Certaine’ ou ‘Probable’ sont visibles ;
* **sensibilité de la donnée** (champ `sensi_niveau`) : les données relatives à des taxons menacés faisant l’objet d’atteintes directes ou indirectes (braconnage, dérangement…) sont floutées. Voir ci-dessous ;
* **statut public ou privé** de la donnée (champ `ds_publique`) : les données publiques sont diffusées sans floutage ;
* **souhait de diffusion du producteur**` (champ `diffusion_niveau_precision`) : le producteur peut souhaiter une diffusion avec la précision géographique d’origine ou après floutage à la maille de 2 km.

Le logigramme suivant synthétise les différents cas de figure possibles:

![Logigramme diffusion des données](media/diagramme_diffusion_donnees.png)


### Calcul automatique de sensibilité selon des critères

La sensibilité des observations peut être décidée pendant l'import des données, ou bien après l'import, via une liste de conditions pré-établie.
La sensibilité des observations dépend en effet de nombreux critères sur les taxons, la position de l'observation, les commentaires, et d'autres conditions spécifiques.

L'application Naturaliz permet de stocker l'ensemble des critères de sensibilité dans la table `occtax.critere_sensibilite`, puis de les utiliser pour calculer automatiquement la sensibilitén de chaque observation via une fonction PostgreSQL `occtax.calcul_niveau_sensibilite`. Pour chacun des critères, la fonction teste les observations en fonction de la condition donnée, et pour les jeux de données (jdd_id) passé en paramètre optionnel. Le résultat est stocké dans la table `occtax.niveau_par_observation`, qui liste les observations à modifier, ainsi que la valeur de sensibilité calculée. Comme plusieurs critères peuvent impacter la même observation, la fonction choisi la sensibilité la plus forte et stocke alors une seule ligne par observation dans la table `occtax.niveau_par_observation_final`.

Pour pouvoir filtrer les observations sur lesquelles calculer la sensibilité, on passe en 1er paramètre un tableau d'entier contenant la liste des jdd_id. Pour pouvoir vérifier le calcul, on passe en 2ème paramètre de la fonction un booléen "simulation". S'il vaut TRUE, alors la fonction remplit les tables `occtax.niveau_par_observation` et `occtax.niveau_par_observation_final`, mais ne modifie pas les observations à partir de ces données.

Pour lancer la fonction sur un sous-ensemble des observations (certains jdd_id), on peut par exemple lancer le SQL suivant:

```sql
-- Lancement du calcul
SELECT occtax.critere_sensibilite(
    -- on passe un tableau de jdd_id sur lesquels appliquer le calcul
    ARRAY[123, 456]::text[],
    -- si on le souhaite sur toutes les observations, on met NULL à la place
    -- NULL,
    -- pas une simulation, on modifie la table occtax.observation
    False
);

-- Pour rafraîchir les résultats sur la plateforme, il faut lancer le rafraîchissement des 2 vues
-- Vue qui calcul la sensibilité des données pour contrôler leur diffusion
REFRESH MATERIALIZED VIEW occtax.observation_diffusion;

-- Vue qui rassemble à plat dans une seule entité la plupart des informations sur les observations
REFRESH MATERIALIZED VIEW occtax.vm_observation;
```

NB: Si on veut pouvoir comprendre le nombre d'observations impactées par chacun des critères, on peut lire le contenu de la table `occtax.niveau_par_observation_compteur` qui fournit pour chaque critère (id et libelle) le nombre d'observation impactées, dans le champ `compteur`. La table rappelle aussi la `condition`.

Voir [un exemple d'ajout de critères et de calcul de sensibilité automatique](doc/validation/validation_calcul_validation_sensibilite_via_ajout_de_criteres.sql) qui montre comment utiliser les tables de critères, et comment faire une jointure avec table spatiale (par exemple de zonages de sensibilité) pour créer un critère qui teste l'intersection entre les observations et des polygones. Des exemples complexes montrent comment utiliser un filtre sur `descriptif_sujet`


### Vue matérialisée pour gérer la diffusion des données à partir de cette sensibilité

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


## Gestion de la validité scientifique des données

Le grand public (personnes non connectées à l'application) ne doivent pas pouvoir visualiser certaines observations. Pour cela, il existe la variable de configuration `validite_niveaux_grand_public` modifiable depuis l'interface d'administration, menu Occtax.

Par défaut, les personnes non connectées ne peuvent visualiser que les données dont le niveau de validation est 1 ou 2

* Voir un exemple d'ajout de critères et de calcul de validation automatique:

doc/validation/validation_calcul_validation_sensibilite_via_ajout_de_criteres.sql

* Projet QGIS exemple pour les validateurs : todo


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

#### taxref_fts

Vue matérialisée pour le stockage des informations de recherche plein texte visible dans l'application naturaliz.

Cette vue se base sur une UNION des taxons, valides ou non, des tables taxref et taxref_local. On n'a gardé que les taxons des rangs FM, GN, AGES, ES, SSES, NAT, VAR, SVAR, FO, SSFO, RACE, CAR, AB

Un champ poids permet de prioriser la recherche dans cet ordre, avec les poids respectifs 6, 4 et 2:
* noms (nom_valide) des taxons valides (cd_nom = cd_ref)
* noms vernaculaires (nom_vern) des taxons valides (cd_nom = cd_ref)
* noms (nom_complet) des taxons synonymes (cd_nom != cd_ref)

Cette vue doit être rafraîchie dès qu'on modifie les données dans les tables taxref et/ou taxref_local: `REFRESH MATERIALIZED VIEW taxon.taxref_fts`

### Création des catégories

La table de correspondance `taxon.t_group_categorie` permet d'attribuer un nom de groupe de taxon grand public à un taxon à partir des informations issues de Taxref (champs group2_inpn et group1_inpn). Ce nom grand public est ensuite utilisé dans Naturaliz dans le formulaire de recherche par groupe, ou encore pour l'affichage du pictogramme dans le résultat des recherches, en se basant sur le champ "libelle_court" de la vue vm_observation.

Certains pictogrammes sont fournis par défaut dans l'application, et copiés lors de la première installation vers le répertoire `lizmap/www/taxon/css/images/groupes/` (relatif à la racine de l'application Lizmap Web Client).

Les **noms des fichiers des pictogrammes** correspondent à la version en **minuscule** et **sans accent** du champ `libelle_court`. Par exemple pour les mammifères, le `libelle_court` vaut "Mammifères", et le fichier correspondant est `lizmap/www/taxon/css/images/groupes/mammiferes.png`.

Les pictogrammes proposés doivent avoir une taille idéale de 100x100 pixels. Quelques sources possibles:

* Algues brunes : http://commons.wikimedia.org/wiki/File:Algae_Pengo.svg
* Algues routes : http://commons.wikimedia.org/wiki/File:Algae_Pengo.svg
* Algues vertes : https://openclipart.org/detail/7020/seaweed-by-johnny_automatic-7020
* Amphibien : https://openclipart.org/detail/188718/oak-tree-by-iggyoblomov-188718 https://openclipart.org/detail/7273/frog-silhouette-by-wipp https://openclipart.org/detail/172425/frog-01-by-solvera-172425
* Angiosperm https://openclipart.org/detail/49339/blue-flower-motif-by-sheikh_tuhin https://openclipart.org/detail/192841/black-flower-by-k4r573n-192841
* Annelides https://openclipart.org/detail/184727/worm-by-arking-184727 https://openclipart.org/detail/184727/worm-by-arking-184727
* Arachnides https://openclipart.org/detail/179190/spider-by-liftarn-179190 https://openclipart.org/detail/20842/spider-by-yves_guillou  https://openclipart.org/detail/73135/spider-by-redccshirt
* Ascidies = éponges https://openclipart.org/detail/124009/sponge-by-papapishu
* Bivalves https://openclipart.org/detail/169356/mussel--mejill%C3%83%C2%B3n-by-ainara14 https://openclipart.org/detail/174565/shell-by-gosc-174565
* Céphalopodes https://openclipart.org/detail/122101/inky-by-dear_theophilus
* Crustacés
* Entognathes = Insectes
* Fougères
* Gastéropodes
* Gymnospermes https://openclipart.org/detail/175675/evergreen-by-warszawianka-175675
* Hépatiques et Anthocérotes = lichen/mousses
* Hydrozoaires = bactéries
* Insectes https://openclipart.org/detail/69/ant-icon-by-rejon https://openclipart.org/detail/32947/wasp-bw-by-j_alves
* Mammifères https://openclipart.org/detail/116629/rabbit-silhouette-by-kuba https://openclipart.org/detail/14496/kangaroo-contour-by-nicubunu https://openclipart.org/detail/1198/cat-silhouette-by-liftarn https://openclipart.org/detail/855/elephant-silhouet-by-molumen
* Myriapodes = mille pattes
* Octocoralliaires = gorgone
* Oiseaux https://openclipart.org/detail/34927/uccello_profilo_01_archi_01-by-francesco_rollandin https://openclipart.org/detail/4416/kiwi-(bird)-by-flomar
* Poissons https://openclipart.org/detail/27770/fishblack-by-moreno https://openclipart.org/detail/20224/hammerhead-shark-by-wsnaccad-20224
* Reptiles https://openclipart.org/detail/84985/lizards-by-voyeg3r
* Scléractioniaires = coraux


**NB**: Une fois les données de la table `taxon.t_group_categorie` modifiées, il faut raffraîchir la vue matérialisée via

```sql
REFRESH MATERIALIZED VIEW occtax.vm_observation ;
```

## Module Occtax

Module de gestion des données au format Occurence de Taxon


### Gestion des listes rouges et des espèces protégées




## Module Gestion

Gestion des accès via table demande. Nous avons simplifié l'utilisation des groupes pour gérer les accès:

- Groupe **admins** = les super-utilisateurs de l'application (plateforme régionale) qui peuvent accéder à toutes les données sans restriction
- Groupe **acteurs** = les personnes qui peuvent voir les données brutes, mais filtrées selon certains critères, comme les taxons, la validité
- Groupe virtuel **anonymous** = les personnes non connectées à l'application.

Les droits d'accès du groupe *acteurs* peuvent être gérés finement avec la table demande. Une demande est définie par:

- des champs de **description générale* : identité de l'acteur (=personne) et de l'organisme à l'origine de la demande, description littérale et date de la demande,etc.
- des champs définissant la **période de validité de l'accès** : l'accès n'est ouvert qu'entre les dates définies par date_validite_min et date_validite_max
- des **champs de filtre**, utilisés pour restreindre l'accès de l'acteur aux données : géométrie de zone d'étude... Un champ générique intitulé critere_additionnel a été ajouté afin de pouvoir affiner de manière très poussée le filtre sans créer un nouveau champ à chaque fois. Les critères doivent être écrits en langage SQL au format TEXT (ie entre ' ', en pensant donc bien à doublers les ' si besoin, par exemple : critere_additionnel='jdd_code=''geir_201805'''). L'ensemble des filtres sont cumulatifs : l'application opère des filtres AND et pas OR.


Un acteur peut avoir plusieurs demandes en cours : les droits d'accès sont alors cumulatifs, l'accès lui étant ouvert à l'ensemble des données couvertes par les demandes en cours.

Les acteurs sont gérés dans des tables créées lors de l'installation par le module gestion, dans la table `gestion.acteur`.

Un exemple de script SQL est disponible dans les sources de l'application: [ajout_demande.sql](referentiels/gestion/ajout_demande.sql). Il montre comment insérer des nouveaux acteurs, organismes, etc., et comment leur donner des droits sur les données.

Le module de gestion des adhésions permettra également une gestion plus ergonomique de ces aspects via les possibilités offertes par les formulaires QGIS et la publication sur Lizmap.

### Export des données

#### Depuis l'application

L'application permet d'exporter les données résultats d'une requête sous plusieurs formats. La liste des champs exportés est définie dans le fichier de configuration local de l'application `lizmap/var/config/naturaliz.ini.php`, dans les variables suivantes :

```
; liste blanche des champs à exporter
observation_exported_fields=cle_obs, identifiant_permanent, identifiant_origine, statut_observation, cd_nom, cd_ref, version_taxref, nom_cite, nom_valide, nom_vern, group1_inpn, group2_inpn, denombrement_min, denombrement_max, type_denombrement, objet_denombrement, commentaire, date_debut, heure_debut, date_fin, heure_fin, altitude_moy, profondeur_moy, date_determination, ds_publique, jdd_metadonnee_dee_id, dee_date_derniere_modification, jdd_code, reference_biblio, organisme_gestionnaire_donnees, statut_source, sensi_niveau, observateur, determinateur, validateur, descriptif_sujet, validite_niveau, validite_date_validation, precision_geometrie, nature_objet_geo, wkt

; liste blanche des champs à exporter pour le grand public
observation_exported_fields_unsensitive=cle_obs, identifiant_permanent, statut_source, nom_cite, date_debut, date_fin, organisme_gestionnaire_donnees, source_objet, code_commune, code_departement, code_maille_10, wkt

; liste blanche des données filles à exporter
;observation_exported_children=commune, departement, maille_02, maille_10, espace_naturel, masse_eau, habitat, attribut_additionnel
observation_exported_children=commune, departement, maille_02, maille_10, espace_naturel, masse_eau, habitat

; liste blanche des données filles à exporter pour le grand public
observation_exported_children_unsensitive="commune, departement, maille_02, maille_10"



```

Ces variables influencent la liste des champs exportés (CSV, WFS) et aussi la liste des champs visibles dans la


Pour paramétrer le texte qui est écrit dans le fichier LISEZ-MOI.txt à la racine du ZIP, vous pouvez modifier le fichier suivant, relativement à la racine de l'application Lizmap : `lizmap/var/config/occtax-export-LISEZ-MOI.txt`
Ce fichier est ensuite complété par l'application avec:

* les informations sur la requête (paramètres de recherche),
* sur le résultat (nombre d'observations),
* la liste des jeux de données de la plate-forme.


### Fiche de détail d'une observation

L'application permet d'afficher pour chaque observation une fiche. Les champs contenus dans cette fiche, ainsi que les données rattachées, sont définis dans le fichier de configuration local de l'application `lizmap/var/config/naturaliz.ini.php`, dans les variables suivantes :

```
; liste blanche des champs à afficher dans la fiche d'observation
observation_card_fields=cle_obs,statut_observation, nom_cite, denombrement_min, denombrement_max, objet_denombrement, commentaire, date_debut, date_fin, date_determination, ds_publique, jdd_metadonnee_dee_id, organisme_gestionnaire_donnees, statut_source, sensi_niveau, observateur, determinateur, validateur, descriptif_sujet, obs_methode, occ_denombrement_min, occ_denombrement_max, occ_type_denombrement, occ_objet_denombrement, occ_etat_biologique, occ_naturalite, occ_sexe, occ_stade_de_vie, occ_statut_biologique, obs_contexte, obs_description, occ_methode_determination,  validite_niveau, validite_date_validation, precision_geometrie



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



### Statistiques sur les observations

Pour réaliser des statistiques sur les données de la base, on utilise PostgreSQL et on enregistre les requêtes comme des **vues matérialisées**, dans un schéma **stats**.

Pour mettre à jour régulièrement les statistiques, il faut rafraîchir les vues matérialisées. Pour cela, une fonction utilitaire a été créée, nommée `occtax.manage_materialized_objects`, qui s'appuie sur une table `occtax.materialized_object_list` listant les vues à rafraîchir, avec un ordre bien défini (pour gérer les dépendances de vues).

On peut lancer manuellement le rafraîchissement des vues matérialisées via la requête suivante:

```sql
-- la fonction a 3 paramètres
-- p_action: 'refresh' ou 'delete'. On utilisera très rarement 'delete' qui supprime tout
-- p_cascade: True ou False. utilisé pour 'delete'. Permet de supprimer en cascade
-- p_object_schema: NULL ou nom du schéma. Si rempli, la fonction ne travaille que sur les objet de ce schéma
--
SELECT occtax.manage_materialized_objects('refresh', False, NULL);

```

On peut alors utiliser le script bash  [rafraichissement_vues_materialisees.sh](doc/scripts/rafraichissement_vues_materialisees.sh) pour rafraîchir les vues. Il peut être lancé via `crontab` toutes les nuits

```bash
0 5 * * * /root/scripts/vues_materialisees/rafraichissement_vues_materialisees.sh > /root/scripts/vues_materialisees/rafraichissement_vues_materialisees.log
```

Pour fonctionner, le script bash a besoin d'un fichier SQL [grant_rights.sql](doc/scripts/grant_rights.sql) qui réapplique les droits sur les objets après rafraichissement des vues. Il faut bien sûr adapter le script bash et le fichier SQL selon son environnement (nom des utilisateurs, nom des bases de données)

Une fois les vues matérialisées crées et remplies, il faut utiliser un projet QGIS pour publier les graphiques via Lizmap. Le fichier de projet QGIS et la configuration Lizmap sont les suivants

* [projet QGIS](doc/qgis/stat_borbonica.qgs)
* [configuration Lizmap](doc/qgis/stat_borbonica.qgs.cfg)
