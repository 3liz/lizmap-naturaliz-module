cd /home/mdouchin/Documents/3liz/DEAL_Mayotte/qgis/rep1/zonages

# Communes
psql service=naturaliz_mayotte_dev -c "TRUNCATE sig.commune RESTART IDENTITY"
ogr2ogr -append -s_srs "EPSG:4471" -t_srs "EPSG:4471" -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=sig" "depuisDEAL/L_COMMUNE_S_976/L_COMMUNE_S_976.shp" -nln commune -lco GEOMETRY_NAME=geom -gt 100000 -sql "SELECT cd_com AS code_commune, nom_minus AS nom_commune, '2020' AS annee_ref FROM L_COMMUNE_S_976" -nlt PROMOTE_TO_MULTI --config SHAPE_ENCODING ISO-8859-15
# vérification
psql service=naturaliz_mayotte_dev -c "SELECT code_commune, nom_commune, ST_Area(geom) FROM sig.commune LIMIT 1"


# mailles 1km
psql service=naturaliz_mayotte_dev -c "TRUNCATE sig.maille_01 RESTART IDENTITY"
ogr2ogr -append -a_srs "EPSG:4471" -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=sig" "depuis INPN/L_MYT_UTM38S/MYT_UTM38S1X1.shp" -nln maille_01 -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT CD_SIG AS code_maille, Concat(SUBSTR(CD_SIG, -8,3), '-', SUBSTR(CD_SIG, -4)) AS nom_maille, '2015' AS version_ref, 'Grille nationale (1km x 1km) Mayotte' AS nom_ref FROM MYT_UTM38S1X1"
# vérification
psql service=naturaliz_mayotte_dev -c "SELECT code_maille, nom_maille, ST_Area(geom) FROM sig.maille_01 LIMIT 1"


# mailles 2km
psql service=naturaliz_mayotte_dev -c "TRUNCATE sig.maille_02 RESTART IDENTITY"
ogr2ogr -append -a_srs "EPSG:4471" -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=sig" "depuis INPN/L_MYT_UTM38S/MYT_UTM38S2X2.shp" -nln maille_02 -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT Concat( Substr(Cast(Cast(\"left\" AS integer) AS character ), 0, 3), '-' , Substr(Cast(Cast(bottom AS integer) AS character ), 0, 4) ) AS code_maille, Concat( Substr(Cast(Cast(\"left\" AS integer) AS character ), 0, 3), '-' , Substr(Cast(Cast(bottom AS integer) AS character ), 0, 4) ) AS nom_maille, '2015' AS version_ref, 'Grille nationale (2km x 2km) Mayotte' AS nom_ref FROM MYT_UTM38S2X2"
# vérification
psql service=naturaliz_mayotte_dev -c "SELECT code_maille, nom_maille, ST_Area(geom) FROM sig.maille_02 LIMIT 1"


# mailles 5km
psql service=naturaliz_mayotte_dev -c "TRUNCATE sig.maille_05 RESTART IDENTITY"
ogr2ogr -append -a_srs "EPSG:4471" -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=sig" "depuis INPN/L_MYT_UTM38S/MYT_UTM38S5X5.shp" -nln maille_05 -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT CD_SIG AS code_maille, Concat(SUBSTR(CD_SIG, -8,3), '-', SUBSTR(CD_SIG, -4)) AS nom_maille, '2015' AS version_ref, 'Grille nationale (5km x 5km) Mayotte' AS nom_ref FROM MYT_UTM38S5X5"
# vérification
psql service=naturaliz_mayotte_dev -c "SELECT code_maille, nom_maille, ST_Area(geom) FROM sig.maille_05 LIMIT 1"


# mailles 10km
psql service=naturaliz_mayotte_dev -c "TRUNCATE sig.maille_10 RESTART IDENTITY"
ogr2ogr -append -a_srs "EPSG:4471" -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=sig" "depuis INPN/L_MYT_UTM38S/MYT_UTM38S10X10.shp" -nln maille_10 -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT CD_SIG AS code_maille, Concat(SUBSTR(CD_SIG, 11,3), '-', SUBSTR(CD_SIG, -4)) AS nom_maille, '2012' AS version_ref, 'Grille nationale (10km x 10km) Mayotte' AS nom_ref FROM MYT_UTM38S10X10"
# vérification
psql service=naturaliz_mayotte_dev -c "SELECT code_maille, nom_maille, ST_Area(geom) FROM sig.maille_10 LIMIT 1"


# espaces naturels
psql service=naturaliz_mayotte_dev -c "TRUNCATE sig.espace_naturel RESTART IDENTITY"

# Reserves_naturelles_nationales
psql service=naturaliz_mayotte_dev -c "DELETE FROM sig.espace_naturel WHERE type_en = 'RNN'"
ogr2ogr -append -s_srs "EPSG:4471" -t_srs "EPSG:4471" -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=sig" "depuis INPN/MYT_RN2010/myt_rn2010.shp" -nln espace_naturel -lco GEOMETRY_NAME=geom -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'RNN' AS type_en, NOM AS nom_en, concat('http://inpn.mnhn.fr/espace/protege/', ID_MNHN) AS url, '2010' AS version_en FROM myt_rn2010"
# verification
psql service=naturaliz_mayotte_dev -c "SELECT code_en, nom_en, ST_Area(geom) FROM sig.espace_naturel WHERE type_en = 'RNN' LIMIT 1"

# HABREF
psql service=naturaliz_mayotte_dev -c "TRUNCATE occtax.habitat RESTART IDENTITY"
wget "https://inpn.mnhn.fr/docs/ref_habitats/HABREF_5.0/HABREF_50.zip" -O HABREF_50.zip
rm HAB*.csv TYPO*.csv Guide*.pdf _50.zipa
unzip HABREF_50.zip
ogr2ogr -append -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=occtax" "HABREF_50.csv" -nln habitat -gt 100000 -sql "SELECT 'HABREF' AS ref_habitat, CD_HAB AS code_habitat, CD_HAB_SUP AS code_habitat_parent, NIVEAU AS niveau_habitat, CASE WHEN LB_HAB_FR IS NULL OR LB_HAB_FR = '' THEN CASE WHEN Coalesce(LB_HAB_FR_COMPLET, '') != '' THEN LB_HAB_FR_COMPLET ELSE LB_HAB_EN END ELSE LB_HAB_FR END AS libelle_habitat, CASE WHEN Coalesce(LB_DESCRIPTION, '') != '' THEN LB_DESCRIPTION ELSE CASE WHEN Coalesce(LB_HAB_FR_COMPLET, '') != '' THEN LB_HAB_FR_COMPLET WHEN Coalesce(LB_HAB_FR, '') != '' THEN LB_HAB_FR ELSE LB_HAB_EN END END AS description_habitat, CD_HAB AS tri_habitat, CD_HAB AS cd_hab FROM HABREF_50" -dialect SQLITE
rm HABREF_50.zip
rm HAB*.csv TYPO*.csv Guide*.pdf
# verification
psql service=naturaliz_mayotte_dev -c "SELECT * FROM occtax.habitat LIMIT 1"

# Habitats marins
# pas de fichier

# Habitats terrestres
# pas de fichier

# Znieff 1
# Pour les ZNIEFF, le WFS est mauvais : encodage mauvais pour znieff mer 2, géométries absentes, etc.
# on doit utiliser le SHP !
psql service=naturaliz_mayotte_dev -c "DELETE FROM sig.espace_naturel WHERE type_en = 'ZNIEFF1'"
echo "Znieff 1"
ogr2ogr -append -s_srs "EPSG:32738" -t_srs "EPSG:4471" -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=sig" "depuis INPN/L_ZNIEFF_CONT_06/myt_znieff1/myt_znieff1.shp" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'ZNIEFF1' AS type_en, NOM AS nom_en, concat('http://inpn.mnhn.fr/espace/protege/', ID_MNHN) AS url, '01/2020' AS version_en FROM myt_znieff1"

# on doit utiliser le SHP !
echo "Znieff 1 mer"
ogr2ogr -append -s_srs "EPSG:32738" -t_srs "EPSG:4471" -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=sig" "depuis INPN/L_ZNIEFF_MER_S_976/myt_znieff1_mer/myt_znieff1_mer.shp" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'ZNIEFF1' AS type_en, NOM AS nom_en, concat('http://inpn.mnhn.fr/espace/protege/', ID_MNHN) AS url, '01/2020' AS version_en FROM myt_znieff1_mer"
# verification
psql service=naturaliz_mayotte_dev -c "SELECT code_en, type_en, ST_Area(geom) FROM sig.espace_naturel WHERE type_en = 'ZNIEFF1' LIMIT 1"


# Znieff 2
psql service=naturaliz_mayotte_dev -c "DELETE FROM sig.espace_naturel WHERE type_en = 'ZNIEFF2'"
echo "Znieff 2"
ogr2ogr -append -s_srs "EPSG:32738" -t_srs "EPSG:4471" -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=sig" "depuis INPN/L_ZNIEFF_CONT_06/myt_znieff2/myt_znieff2.shp" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'ZNIEFF2' AS type_en, NOM AS nom_en, concat('http://inpn.mnhn.fr/espace/protege/', ID_MNHN) AS url, '01/2020' AS version_en FROM myt_znieff2"
echo "Znieff 2 mer"
ogr2ogr -append -s_srs "EPSG:32738" -t_srs "EPSG:4471" -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=sig" "depuis INPN/L_ZNIEFF_MER_S_976/myt_znieff2_mer/myt_znieff2_mer.shp" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'ZNIEFF2' AS type_en, NOM AS nom_en, concat('http://inpn.mnhn.fr/espace/protege/', ID_MNHN) AS url, '01/2020' AS version_en FROM myt_znieff2_mer"
# verification
psql service=naturaliz_mayotte_dev -c "SELECT code_en, type_en, ST_Area(geom) FROM sig.espace_naturel WHERE type_en = 'ZNIEFF2' LIMIT 1"


# Sites Ramsar
echo "Ramsar"
#psql service=naturaliz_mayotte_dev -c "DELETE FROM sig.espace_naturel WHERE type_en = 'RAMSAR'"
ogr2ogr -append -s_srs "EPSG:4471" -t_srs "EPSG:4471" -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=sig" "depuis INPN/L_RAMSAR_BADAMIERS/myt_ramsar/myt_ramsar2016_11/N_ENP_RAMSAR_S_976.shp" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'RAMSAR' AS type_en, NOM_SITE AS nom_en, URL_FICHE AS url, '11/2016' AS version_en FROM N_ENP_RAMSAR_S_976"  --config SHAPE_ENCODING ISO-8859-15
# verification
psql service=naturaliz_mayotte_dev -c "SELECT code_en, type_en, nom_en, ST_Area(geom) FROM sig.espace_naturel WHERE type_en = 'RAMSAR' LIMIT 1"

# Parc national
# aucun à Mayotte

# Parcs naturel marin PNM
#psql service=naturaliz_mayotte_dev -c "DELETE FROM sig.espace_naturel WHERE type_en = 'PNM'"
echo "PNM - Parc naturel marin de Mayotte"
ogr2ogr -append -s_srs "EPSG:4471" -t_srs "EPSG:4471" -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=sig" WFS:"http://ws.carmencarto.fr/WMS/119/myt_inpn?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=pnm&SRSNAME=EPSG:4471" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'PNM' AS type_en, NOM AS nom_en, URL AS url, '04/2015' AS version_en FROM pnm"

echo "PNM - Parc naturel marin des Glorieuses"
ogr2ogr -append -s_srs "EPSG:4471" -t_srs "EPSG:4471" -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=sig" WFS:"http://ws.carmencarto.fr/WMS/119/myt_inpn?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=Parc_naturel_marin_des_Glorieuses&SRSNAME=EPSG:4471" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'PNM' AS type_en, NOM AS nom_en, URL AS url, '04/2015' AS version_en FROM Parc_naturel_marin_des_Glorieuses"
# verification
psql service=naturaliz_mayotte_dev -c "SELECT code_en, type_en, nom_en, ST_Area(geom) FROM sig.espace_naturel WHERE type_en = 'PNM' LIMIT 2"


# Terrains du Conservatoire du Littoral
# psql service=naturaliz_mayotte_dev -c "DELETE FROM sig.espace_naturel WHERE type_en = 'PNM'"
echo "Conservatoire du littoral"
ogr2ogr -append -s_srs "EPSG:4471" -t_srs "EPSG:4471" -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=sig" WFS:"http://ws.carmencarto.fr/WMS/119/myt_inpn?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=Terrains_du_Conservatoire_du_Littoral&SRSNAME=EPSG:4471" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'SCL' AS type_en, NOM_SITE AS nom_en, URL_FICHE AS url, '03/2018' AS version_en FROM Terrains_du_Conservatoire_du_Littoral"
# verification
psql service=naturaliz_mayotte_dev -c "SELECT code_en, type_en, nom_en, ST_Area(geom) FROM sig.espace_naturel WHERE type_en = 'SCL' LIMIT 2"


# Reserves_de_la_biosphere
# aucun à Mayotte

# Reserves_biologiques
# aucun à Mayotte

# Arretes_de_protection_de_biotope
# psql service=naturaliz_mayotte_dev -c "DELETE FROM sig.espace_naturel WHERE type_en = 'APB'"
echo "Arretes_de_protection_de_biotope"
ogr2ogr -append -s_srs "EPSG:4471" -t_srs "EPSG:4471" -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=sig" WFS:"http://ws.carmencarto.fr/WMS/119/myt_inpn?SERVICE=WFS&VERSION=1.0.0&REQUEST=GetFeature&TYPENAME=Arretes_de_protection_de_biotope&SRSNAME=EPSG:4471" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'APB' AS type_en, NOM AS nom_en, URL AS url, '2010' AS version_en FROM Arretes_de_protection_de_biotope"
# verification
psql service=naturaliz_mayotte_dev -c "SELECT code_en, type_en, nom_en, ST_Area(geom) FROM sig.espace_naturel WHERE type_en = 'APB' LIMIT 2"


# Masses d'eau
# Trouvé via http://www.sandre.eaufrance.fr/Rechercher-un-jeu-de-donnees?keyword=mayotte
# Choix du référentiel VRAP2016

# Masses d'eau cotieres
echo "MasseDEauCotiere_VRAP2016_MYT"
# psql service=naturaliz_mayotte_dev -c "TRUNCATE sig.masse_eau RESTART IDENTITY"
# NB: Je ne sais pas où trouver la version
# URL http://www.sandre.eaufrance.fr/atlas/srv/fre/catalog.search#/metadata/0f80a3df-0479-425e-b117-84c41373d832
ogr2ogr -append -a_srs "EPSG:4471" -s_srs "EPSG:4471" -t_srs "EPSG:4471"  -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=sig" WFS:"https://services.sandre.eaufrance.fr/geo/MasseDEau_VRAP2016?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature&TYPENAME=sa:MasseDEauCotiere_VRAP2016_MYT&srsname=EPSG:4471" -nln masse_eau -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT CdEuMasseDEau AS code_me,  Concat( NomMasseDEau, ' (', CdEuMasseDEau, ')' ) AS nom_me, 2 AS version_me, DateMajMasseDEau AS date_me FROM MasseDEauCotiere_VRAP2016_MYT"



# Masses d'eau souterraines
echo "MasseDEauSouterraine_VRAP2016_MYT"
# NB: Je ne sais pas où trouver la version
# URL http://www.sandre.eaufrance.fr/atlas/srv/fre/catalog.search#/metadata/0f80a3df-0479-425e-b117-84c41373d832
ogr2ogr -append -a_srs "EPSG:4471" -s_srs "EPSG:4471" -t_srs "EPSG:4471"  -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=sig" WFS:"https://services.sandre.eaufrance.fr/geo/MasseDEau_VRAP2016?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature&TYPENAME=sa:MasseDEauSouterraine_VRAP2016_MYT&srsname=EPSG:4471" -nln masse_eau -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT CdEuMasseDEau AS code_me,  Concat( NomMasseDEau, ' (', CdEuMasseDEau, ')' ) AS nom_me, 2 AS version_me, DateMajMasseDEau AS date_me FROM MasseDEauSouterraine_VRAP2016_MYT"


# verification
psql service=naturaliz_mayotte_dev -c "SELECT code_me, nom_me, ST_Area(geom) FROM sig.masse_eau LIMIT 2"

# correction des géométries des masses d'eau et des espaces naturels
psql service=naturaliz_mayotte_dev -c "ALTER TABLE sig.espace_naturel ALTER COLUMN geom SET DATA TYPE geometry(MULTIPOLYGON, 4471) USING ST_Multi(geom)::geometry(MULTIPOLYGON, 4471);"
psql service=naturaliz_mayotte_dev -c "ALTER TABLE sig.masse_eau ALTER COLUMN geom SET DATA TYPE geometry(MULTIPOLYGON, 4471) USING ST_Multi(geom)::geometry(MULTIPOLYGON, 4471);"


# Département : on a importé la ZEE de Mayotte. Mais soucis de polygones
# On importe une donnée plus propre: L_ZMMYT_S_976.shp
cd /qgis/commun/referentiels/DONNEE_GENERIQUE/N_ADMINISTRATIF
# psql service=naturaliz_mayotte_dev -c "TRUNCATE sig.departement RESTART IDENTITY"
ogr2ogr -append -s_srs "EPSG:4471" -t_srs "EPSG:4471" -f PostgreSQL "PG:service=naturaliz_mayotte_dev active_schema=sig" "departement.shp" -nln departement -lco GEOMETRY_NAME=geom -gt 100000 -sql "SELECT '976' AS code_departement, 'Mayotte' AS nom_departement, '2021' AS annee_ref FROM departement" -nlt PROMOTE_TO_MULTI --config SHAPE_ENCODING ISO-8859-15
# test
psql service=naturaliz_mayotte_dev -c "SELECT code_departement, nom_departement, ST_Area(geom) FROM sig.departement LIMIT 1"
