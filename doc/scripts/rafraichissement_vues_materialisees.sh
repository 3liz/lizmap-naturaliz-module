#!/bin/bash

# copie du fichier sql dans le tmp pour que postgres puisse l'utiliser
cp /root/scripts/vues_materialisees/grant_rights.sql /tmp/
chmod 777 /tmp/grant_rights.sql

### DEV
echo "### BASE DE DEV"
echo "REFRESH MATERIALIZED VIEWS"
echo `date +"%Y-%m-%d %T"`
sudo -u postgres psql -d lizmap_dev -c "SELECT occtax.manage_materialized_objects('refresh', False, NULL);"
echo "* refresh done !"
echo `date +"%Y-%m-%d %T"`

echo "GRANT RIGHTS"
sudo -u postgres psql -d lizmap_dev -f /tmp/grant_rights.sql
echo "* rights granted"

echo "------------------"

### PROD
echo "### BASE DE PROD"
echo "REFRESH MATERIALIZED VIEWS"
echo `date +"%Y-%m-%d %T"`
sudo -u postgres psql -d lizmap -c "SELECT occtax.manage_materialized_objects('refresh', False, NULL);"
echo "* refresh done !"
echo `date +"%Y-%m-%d %T"`

echo "GRANT RIGHTS"
sudo -u postgres psql -d lizmap -f /tmp/grant_rights.sql
echo "* rights granted"

