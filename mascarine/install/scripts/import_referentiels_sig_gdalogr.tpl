# Import des couches SIG de référence
################################################

# MNT
#######

raster2pgsql -d -s {$srid} -C -I -r -M {$mnt} -F -Y -t 100x100 public.mnt | PGPASSWORD={$dbpassword} psql -d {$dbname} -p {$dbport} -h {$dbhost} -U {$dbuser}

# SHAPEFILES Lieu-dit
##################################################

# Habité
# Utilisation de la BDTOPO. NB: Il serait préférable d'utiliser le WFS IGN
ogr2ogr -append -s_srs "EPSG:{$srid}" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" "{$habite}" -nln lieudit -lco GEOMETRY_NAME=geom -gt 100000 -sql "SELECT ID AS code_lieudit, NOM AS nom_lieudit, NATURE AS nature_lieudit, IMPORTANCE AS importance_lieudit FROM LIEU_DIT_HABITE" --config SHAPE_ENCODING ISO-8859-15

# Non habité
{if $non_habite}
ogr2ogr -append -s_srs "EPSG:{$srid}" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" "{$non_habite}" -nln lieudit -lco GEOMETRY_NAME=geom -gt 100000 -sql "SELECT ID AS code_lieudit, NOM AS nom_lieudit, NATURE AS nature_lieudit, IMPORTANCE AS importance_lieudit FROM LIEU_DIT_NON_HABITE" --config SHAPE_ENCODING ISO-8859-15
{/if}

# Oronyme
{if $oronyme}
ogr2ogr -append -s_srs "EPSG:{$srid}" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" "{$oronyme}" -nln lieudit -lco GEOMETRY_NAME=geom -gt 100000 -sql "SELECT ID AS code_lieudit, NOM AS nom_lieudit, NATURE AS nature_lieudit, IMPORTANCE AS importance_lieudit FROM ORONYME" --config SHAPE_ENCODING ISO-8859-15
{/if}

# Toponyme divers
{if $toponyme_divers}
ogr2ogr -append -s_srs "EPSG:{$srid}" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" "{$toponyme_divers}" -nln lieudit -lco GEOMETRY_NAME=geom -gt 100000 -sql "SELECT ID AS code_lieudit, NOM AS nom_lieudit, NATURE AS nature_lieudit, IMPORTANCE AS importance_lieudit FROM TOPONYME_DIVERS" --config SHAPE_ENCODING ISO-8859-15
{/if}
