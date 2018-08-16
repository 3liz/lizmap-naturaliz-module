## Introduction

La structure de la base de données est documentée via l'outil Schemaspy: http://schemaspy.org/.

Pour voir les scripts de création de la base, il faut regarder les fichier `install.pgsql.sql` contenus dans les répertoires `install/sql/` des modules.

## Documentation SchemaSpy

Pour créer la documentation, il faut lancer un script en ligne de commande, en passant les paramètre attendus.

```
# Se placer dans le repertoire contenant le script de génération
cd doc/database/schemaspy/

# Lancer la commande avec les bons paramètres
./generation_documentation_schemaspy.sh -h localhost -p 5432 -d naturaliz -u postgres -w ***** -o html

```

Cela va créer un fichier `index.html` dans le répertoire `html/` avec un lien pour chacun des schémas vers la documentation.
