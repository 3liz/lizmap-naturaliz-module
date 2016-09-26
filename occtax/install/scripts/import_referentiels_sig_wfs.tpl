# Import des couches SIG de référence
################################################

# WFS
################################################

# Znieff 1
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=Znieff1&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'ZNIEFF1' AS type_en, NOM AS nom_en, URL AS url FROM Znieff1"

# Znieff 2
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=Znieff2&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'ZNIEFF2' AS type_en, NOM AS nom_en, URL AS url FROM Znieff2"

# Sites Ramsar
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=Sites_Ramsar&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'RAMSAR' AS type_en, NOM AS nom_en, URL AS url FROM Sites_Ramsar"

# Parcs nationaux
# Coeur
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=Parcs_nationaux&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'CPN' AS type_en, ZONE AS nom_en, URL AS url FROM Parcs_nationaux WHERE ZONE = 'coeur'"
# Zone d'adhésion
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=Parcs_nationaux&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'AAPN' AS type_en, ZONE AS nom_en, URL AS url FROM Parcs_nationaux WHERE ZONE != 'coeur'"

# Terrains du Conservatoire du Littoral
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=Terrains_du_Conservatoire_du_Littoral&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'SCL' AS type_en, NOM_SITE AS nom_en, URL AS url FROM Terrains_du_Conservatoire_du_Littoral"

# Reserves_de_la_biosphere
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=Reserves_de_la_biosphere&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'MAB' AS type_en, CONCAT(NOM, ' - ', ZONE) AS nom_en, URL AS url FROM Reserves_de_la_biosphere"

# Arretes_de_protection_de_biotope
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=Arretes_de_protection_de_biotope&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'APB' AS type_en, NOM AS nom_en, URL AS url FROM Arretes_de_protection_de_biotope"

# Mailles_10
# bizarrement le SRS donné par le serveur est 2154 alors que la couche est bien en 32620 -> utilisation de a_srs pour forcer la projection de la donnée crée
ogr2ogr -append -a_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"http://ws.carmencarto.fr/WFS/119/glp_grille?service=WFS&request=GetFeature&version=1.1.0&typeName=glp_utm10km" -nln maille_10 -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT CD_SIG AS code_maille, Concat(SUBSTR(CD_SIG, 11,3), '-', SUBSTR(CD_SIG, -4)) AS nom_maille FROM glp_utm10km"

# Masses d'eau cotieres
ogr2ogr -append -s_srs "EPSG:4326" -t_srs "EPSG:{$srid}"  -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url_sandre}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=MasseDEauCotiere&SRSNAME=EPSG:4326" -nln masse_eau -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT CdEuMasseD AS code_me,  Concat( NomMasseDe, ' (', CdEuMasseD, ')' ) AS nom_me FROM MasseDEauCotiere"

