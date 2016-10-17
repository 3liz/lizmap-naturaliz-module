# Import des couches SIG de référence
################################################

# WFS
################################################

# Znieff 1
echo "Znieff 1"
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME={$znieff1_terre}&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'ZNIEFF1' AS type_en, NOM AS nom_en, URL AS url FROM {$znieff1_terre}"
echo "Znieff 1 mer"
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME={$znieff1_mer}&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'ZNIEFF1' AS type_en, NOM AS nom_en, URL AS url FROM {$znieff1_mer}"


# Znieff 2
echo "Znieff 2"
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME={$znieff2_terre}&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'ZNIEFF2' AS type_en, NOM AS nom_en, URL AS url FROM {$znieff2_terre}"
echo "Znieff 2 mer"
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME={$znieff2_mer}&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'ZNIEFF2' AS type_en, NOM AS nom_en, URL AS url FROM {$znieff2_mer}"

# Sites Ramsar
echo "Ramsar"
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=Sites_Ramsar&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'RAMSAR' AS type_en, NOM AS nom_en, URL AS url FROM Sites_Ramsar"

# Parcs nationaux
# Coeur
echo "PN - Coeur"
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=Parcs_nationaux&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'CPN' AS type_en, ZONE AS nom_en, URL AS url FROM Parcs_nationaux WHERE ZONE = 'coeur'"
# Zone d'adhésion
echo "PN - zone d'adhésion"
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=Parcs_nationaux&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'AAPN' AS type_en, ZONE AS nom_en, URL AS url FROM Parcs_nationaux WHERE ZONE != 'coeur'"

# Terrains du Conservatoire du Littoral
echo "Conservatoire du littoral"
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=Terrains_du_Conservatoire_du_Littoral&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'SCL' AS type_en, NOM_SITE AS nom_en, URL_FICHE AS url FROM Terrains_du_Conservatoire_du_Littoral"

# Reserves_de_la_biosphere
echo "Reserves_de_la_biosphere"
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=Reserves_de_la_biosphere&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'MAB' AS type_en, CONCAT(NOM, ' - ', ZONE) AS nom_en, URL AS url FROM Reserves_de_la_biosphere"

# Reserves_biologiques
echo "Reserves_biologiques"
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=Reserves_biologiques&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, CASE D_I WHEN 'D' THEN 'RBD' ELSE 'RBI' END AS type_en, NOM AS nom_en, URL AS url FROM Reserves_biologiques" -dialect SQLITE

# Arretes_de_protection_de_biotope
echo "Arretes_de_protection_de_biotope"
ogr2ogr -append -s_srs "EPSG:3857" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=Arretes_de_protection_de_biotope&SRSNAME=EPSG:3857" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'APB' AS type_en, NOM AS nom_en, URL AS url FROM Arretes_de_protection_de_biotope"

# Masses d'eau cotieres
echo "MasseDEauCotiere"
ogr2ogr -append -s_srs "EPSG:4326" -t_srs "EPSG:{$srid}"  -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url_sandre}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=MasseDEauCotiere&SRSNAME=EPSG:4326" -nln masse_eau -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT CdEuMasseD AS code_me,  Concat( NomMasseDE, ' (', CdEuMasseD, ')' ) AS nom_me FROM MasseDEauCotiere"

# Masses d'eau souterraines
echo "MasseDEauSouterraine"
ogr2ogr -append -s_srs "EPSG:4326" -t_srs "EPSG:{$srid}"  -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" WFS:"{$wfs_url_sandre}?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=MasseDEauSouterraine&SRSNAME=EPSG:4326" -nln masse_eau -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT CdEuMasseD AS code_me,  Concat( NomMasseDE, ' (', CdEuMasseD, ')' ) AS nom_me FROM MasseDEauSouterraine"

