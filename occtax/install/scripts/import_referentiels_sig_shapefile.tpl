# Import des couches SIG de référence
################################################

# SHAPEFILES
##################################################

# Communes
# Utilisation de la BDTOPO. NB: Il serait préférable d'utiliser le WFS IGN
ogr2ogr -append -s_srs "EPSG:{$srid}" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" "{$communes}" -nln commune -lco GEOMETRY_NAME=geom -gt 100000 -sql "SELECT CODE_INSEE AS code_commune, NOM AS nom_commune FROM COMMUNE" -nlt PROMOTE_TO_MULTI --config SHAPE_ENCODING ISO-8859-15

# mailles 1km
ogr2ogr -append -a_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" "{$maille_01}" -nln maille_01 -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT Concat( Substr(Cast(Cast(XMIN AS integer) AS character ), 0, 3), '-' , Substr(Cast(Cast(YMIN AS integer) AS character ), 0, 4) ) AS code_maille, Concat( Substr(Cast(Cast(XMIN AS integer) AS character ), 0, 3), '-' , Substr(Cast(Cast(YMIN AS integer) AS character ), 0, 4) ) AS nom_maille FROM grille_1000m_gwada_dep_ama_poly" --config SHAPE_ENCODING ISO-8859-15

# mailles 2km
ogr2ogr -append -a_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" "{$maille_02}" -nln maille_02 -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT Concat( Substr(Cast(Cast(XMIN AS integer) AS character ), 0, 3), '-' , Substr(Cast(Cast(YMIN AS integer) AS character ), 0, 4) ) AS code_maille, Concat( Substr(Cast(Cast(XMIN AS integer) AS character ), 0, 3), '-' , Substr(Cast(Cast(YMIN AS integer) AS character ), 0, 4) ) AS nom_maille FROM grille_2000m_gwada_dep_ama_poly" --config SHAPE_ENCODING ISO-8859-15

# mailles 5km a)
ogr2ogr -append -a_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" "{$maille_05}" -nln maille_05 -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT Concat( Substr(Cast(Cast(XMIN AS integer) AS character ), 0, 3), '-' , Substr(Cast(Cast(YMIN AS integer) AS character ), 0, 4) ) AS code_maille, Concat( Substr(Cast(Cast(XMIN AS integer) AS character ), 0, 3), '-' , Substr(Cast(Cast(YMIN AS integer) AS character ), 0, 4) ) AS nom_maille FROM grille_5000 WHERE XMIN < 1000000" --config SHAPE_ENCODING ISO-8859-15

# mailles 5km b)
ogr2ogr -append -a_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" "{$maille_05}" -nln maille_05 -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT Concat( Substr(Cast(Cast(XMIN AS integer) AS character ), 0, 4), '-' , Substr(Cast(Cast(YMIN AS integer) AS character ), 0, 4) ) AS code_maille, Concat( Substr(Cast(Cast(XMIN AS integer) AS character ), 0, 4), '-' , Substr(Cast(Cast(YMIN AS integer) AS character ), 0, 4) ) AS nom_maille FROM grille_5000 WHERE XMIN >= 1000000" --config SHAPE_ENCODING ISO-8859-15

# Reserves_naturelles_nationales
# Utilisation du SHP car WFS sans attributs:
ogr2ogr -append -s_srs "EPSG:{$srid}" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" "{$reserves_naturelles_nationales}" -nln espace_naturel -lco GEOMETRY_NAME=geom -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'RNN' AS type_en, NOM AS nom_en, CONCAT('http://inpn.mnhn.fr/espace/protege/', ID_MNHN) AS url FROM glp_rnn2012" --config SHAPE_ENCODING ISO-8859-15

# HABITATS
{if $habitat_mer}
# Habitats marins
ogr2ogr -append -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema=occtax" "{$habitat_mer}" -nln habitat -gt 100000 -sql "SELECT 'ANTMER' AS ref_habitat, CD_HAB AS code_habitat, CD_HAB_SUP AS code_habitat_parent, NIVEAU AS niveau_habitat, LB_HAB_FR AS libelle_habitat, LB_HAB_FR AS description_habitat, CLÉ_TRI AS tri_habitat FROM TYPO_ANT_MER ORDER BY CLÉ_TRI" --config SHAPE_ENCODING ISO-8859-15
{/if}

{if $habitat_terre}
# Habitats terrestres
ogr2ogr -append -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema=occtax" "{$habitat_terre}" -nln habitat -gt 100000
{/if}

