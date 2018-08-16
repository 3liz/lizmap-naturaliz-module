#!/bin/sh

while getopts h:p:d:u:w:o: option
do
case "${option}"
in
h) DBHOST=${OPTARG};;
p) DBPORT=${OPTARG};;
d) DBNAME=${OPTARG};;
u) DBUSER=${OPTARG};;
w) DBPASS=${OPTARG};;
o) OUTPUTDIR=${OPTARG};;
esac
done



# Creation d'un fichier qui fait un lien vers tous les schemas
echo "<h3>Naturaliz - Liste des schemas</h3>" > $OUTPUTDIR/index.html

# On boucle sur les schemas
for SCHEMANAME in public taxon occtax gestion sig; do

    # On supprime le repertoire existant
    rm -rf $OUTPUTDIR/$SCHEMANAME

    # On cree le repertoire si besoin
    mkdir -p $OUTPUTDIR/$SCHEMANAME

    # On lance schemaspy sur ce schema PostgreSQL
    java -jar schemaspy-6.0.0.jar -t pgsql-mat -dp postgresql-42.2.4.jar -host $DBHOST -port $DBPORT -db $DBNAME -u $DBUSER -p $DBPASS -s $SCHEMANAME -o $OUTPUTDIR/$SCHEMANAME

    # On ajout le lien dans le fichier index.html
    echo "<li><a href=$SCHEMANAME/index.html>$SCHEMANAME</a></li>" >> $OUTPUTDIR/index.html

done
