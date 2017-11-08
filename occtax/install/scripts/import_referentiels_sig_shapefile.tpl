# Import des couches SIG de référence
################################################

# SHAPEFILES
##################################################

# Communes
# Utilisation de la BDTOPO. NB: Il serait préférable d'utiliser le WFS IGN
{if $commune}
ogr2ogr -append -s_srs "EPSG:{$srid}" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" "{$commune}" -nln commune -lco GEOMETRY_NAME=geom -gt 100000 -sql "SELECT CODE_INSEE AS code_commune, NOM AS nom_commune, {$commune_annee_ref} AS annee_ref FROM {$commune_name}" -nlt PROMOTE_TO_MULTI --config SHAPE_ENCODING ISO-8859-15
{/if}

# mailles 1km
{if $maille_01}
ogr2ogr -append -a_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" "{$maille_01}" -nln maille_01 -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT CD_SIG AS code_maille, Concat(SUBSTR(CD_SIG, -8,3), '-', SUBSTR(CD_SIG, -4)) AS nom_maille, '{$maille_01_version_ref}' AS version_ref, '{$maille_01_nom_ref}' AS nom_ref FROM {$maille_01_name}"
{/if}

# mailles 2km
{if $maille_02}
ogr2ogr -append -a_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" "{$maille_02}" -nln maille_02 -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT Concat( Substr(Cast(Cast(X_MIN AS integer) AS character ), 0, 3), '-' , Substr(Cast(Cast(Y_MIN AS integer) AS character ), 0, 4) ) AS code_maille, Concat( Substr(Cast(Cast(X_MIN AS integer) AS character ), 0, 3), '-' , Substr(Cast(Cast(Y_MIN AS integer) AS character ), 0, 4) ) AS nom_maille, '{$maille_02_version_ref}' AS version_ref, '{$maille_02_nom_ref}' AS nom_ref FROM {$maille_02_name}"
{/if}

# mailles 5km
{if $maille_05}
ogr2ogr -append -a_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" "{$maille_05}" -nln maille_05 -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT CD_SIG AS code_maille, Concat(SUBSTR(CD_SIG, -8,3), '-', SUBSTR(CD_SIG, -4)) AS nom_maille, '{$maille_05_version_ref}' AS version_ref, '{$maille_05_nom_ref}' AS nom_ref FROM {$maille_05_name}"
{/if}

# Mailles_10
{if $maille_10}
ogr2ogr -append -a_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" "{$maille_10}" -nln maille_10 -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT CD_SIG AS code_maille, Concat(SUBSTR(CD_SIG, 11,3), '-', SUBSTR(CD_SIG, -4)) AS nom_maille, '{$maille_10_version_ref}' AS version_ref, '{$maille_10_nom_ref}' AS nom_ref FROM {$maille_10_name}"
{/if}

# Reserves_naturelles_nationales
# Utilisation du SHP car WFS sans attributs:
{if $reserves_naturelles_nationales}
ogr2ogr -append -s_srs "EPSG:{$srid}" -t_srs "EPSG:{$srid}" -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema={$dbschema}" "{$reserves_naturelles_nationales}" -nln espace_naturel -lco GEOMETRY_NAME=geom -gt 100000 -sql "SELECT ST_Union(geometry), ID_MNHN AS code_en, 'RNN' AS type_en, NOM AS nom_en, 'http://inpn.mnhn.fr/espace/protege/' || ID_MNHN AS url, '{$rnn_version_en}' AS version_en FROM {$reserves_naturelles_nationales_name} GROUP BY ID_MNHN, NOM" -dialect SQLITE
{/if}

# HABREF
{if $habref}
ogr2ogr -append -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema=occtax" "{$habref}" -nln habitat -gt 100000 -sql "SELECT 'HABREF' AS ref_habitat, CD_HAB AS code_habitat, CD_HAB_SUP AS code_habitat_parent, NIVEAU AS niveau_habitat, CASE WHEN LB_HAB_FR IS NULL OR LB_HAB_FR = '' THEN CASE WHEN Coalesce(LB_HAB_FR_COMPLET, '') != '' THEN LB_HAB_FR_COMPLET ELSE LB_HAB_EN END ELSE LB_HAB_FR END AS libelle_habitat, CASE WHEN Coalesce(LB_DESCRIPTION, '') != '' THEN LB_DESCRIPTION ELSE CASE WHEN Coalesce(LB_HAB_FR_COMPLET, '') != '' THEN LB_HAB_FR_COMPLET WHEN Coalesce(LB_HAB_FR, '') != '' THEN LB_HAB_FR ELSE LB_HAB_EN END END AS description_habitat, CD_HAB AS tri_habitat, CD_HAB AS cd_hab FROM {$habref_name}" -dialect SQLITE
{/if}

# HABITATS complémentaires
{if $habitat_mer}
# Habitats marins
ogr2ogr -append -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema=occtax" "{$habitat_mer}" -nln habitat -gt 100000 -sql "SELECT 'ANTMER' AS ref_habitat, CD_HAB AS code_habitat, CD_HAB_SUP AS code_habitat_parent, NIVEAU AS niveau_habitat, LB_HAB_FR AS libelle_habitat, LB_HAB_FR AS description_habitat, CLÉ_TRI AS tri_habitat FROM TYPO_ANT_MER ORDER BY CLÉ_TRI" --config SHAPE_ENCODING ISO-8859-15
{/if}

# Habitats terrestres
{if $habitat_terre}
ogr2ogr -append -f PostgreSQL "PG:host={$dbhost} port={$dbport} user={$dbuser} password={$dbpassword} dbname={$dbname} active_schema=occtax" "{$habitat_terre}" -nln habitat -gt 100000
{/if}
