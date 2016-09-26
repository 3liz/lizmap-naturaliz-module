# Naturaliz - Guide d'utilisation des modules

## Taxon

Module de gestion des données TAXREF



## Occtax

Module de gestion des données au format Occurence de Taxon

### Gestion des listes rouges et des espèces protégées

todo

## Mascarine

Module de saisie d'observation floristiques en suivant les bordereaux d'inventaire conçus par le Conservatoire Botanique National de Mascarin (CBN-CBIE Mascarine, La Réunion)

### Validation des données saisies

Les données saisies à travers l'interface (ou via l'outil mobile) tombent dans un sas de validation. Le gestionnaire des données de l'application (profil 1) doit valider manuellement chaque observation pour qu'elles soient consultable par l'ensemble des utilisateurs (sinon, seul l'auteur et le gestionnaire peuvent les consulter).

Une fois validée, les observations de Mascarine peuvent être automatiquement exportées vers le schéma "Occurence de taxons" (occtax). Pour cela, il faut se connecter à la base de données, et lancer la fonction **mascarine.export_validated_mascarine_observation_into_occtax** en passant en paramètre une liste d'identifiants d'observations. Par exemple

```
SELECT mascarine.export_validated_mascarine_observation_into_occtax(o.id_obs) FROM mascarine.m_observation o WHERE validee_obs = 1 AND blablalba;
```

