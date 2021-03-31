cd /home/mdouchin/Documents/3liz/PNR_Martinique/naturaliz/sig

#Récupérer la BDTOPO Licence Ouverte
ftp://BDTOPO_V3_NL_ext:Ohp3quaz2aideel4@ftp3.ign.fr/BDTOPO_3-0_2020-12-15/BDTOPO_3-0_TOUSTHEMES_SHP_RGAF09UTM20_D972_2020-12-15.7z

# Communes
psql service=naturaliz_martinique_dev -c "TRUNCATE sig.commune RESTART IDENTITY"
ogr2ogr -append -s_srs "EPSG:5490" -t_srs "EPSG:5490" -f PostgreSQL "PG:service=naturaliz_martinique_dev active_schema=sig" "BDTOPO_3-0_TOUSTHEMES_SHP_RGAF09UTM20_D972_2020-12-15/BDTOPO/1_DONNEES_LIVRAISON_2021-01-00019/BDT_3-0_SHP_RGAF09UTM20_D972-ED2020-12-15/ADMINISTRATIF/COMMUNE.shp" -nln commune -lco GEOMETRY_NAME=geom -gt 100000 -sql "SELECT INSEE_COM AS code_commune, NOM AS nom_commune, '2021' AS annee_ref FROM COMMUNE" -nlt PROMOTE_TO_MULTI --config SHAPE_ENCODING UTF-8
# vérification
psql service=naturaliz_martinique_dev -c "SELECT code_commune, nom_commune, ST_Area(geom) FROM sig.commune LIMIT 1"

# Référentiels INPN
# https://inpn.mnhn.fr/telechargement/cartes-et-information-geographique/ref/referentiels

# mailles 1km
wget https://inpn.mnhn.fr/docs/Shape/MTQ_UTM20N1X1.zip
psql service=naturaliz_martinique_dev -c "TRUNCATE sig.maille_01 RESTART IDENTITY"
ogr2ogr -append -s_srs "EPSG:32620" -t_srs "EPSG:5490" -f PostgreSQL "PG:service=naturaliz_martinique_dev active_schema=sig" "MTQ_UTM20N1X1.shp" -nln maille_01 -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT CD_SIG AS code_maille, Concat(SUBSTR(CD_SIG, -8,3), '-', SUBSTR(CD_SIG, -4)) AS nom_maille, '2015' AS version_ref, 'Grille nationale (1km x 1km) Martinique' AS nom_ref FROM MTQ_UTM20N1X1"
# vérification
psql service=naturaliz_martinique_dev -c "SELECT code_maille, nom_maille, ST_Area(geom) FROM sig.maille_01 LIMIT 1"


# mailles 2km
# Créer les mailles avec QGIS
psql service=naturaliz_martinique_dev -c "TRUNCATE sig.maille_02 RESTART IDENTITY"
ogr2ogr -append -s_srs "EPSG:32620" -t_srs "EPSG:5490" -f PostgreSQL "PG:service=naturaliz_martinique_dev active_schema=sig" "MTQ_UTM20N2X2.shp" -nln maille_02 -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT Concat( Substr(Cast(Cast(\"left\" AS integer) AS character ), 0, 3), '-' , Substr(Cast(Cast(bottom AS integer) AS character ), 0, 4) ) AS code_maille, Concat( Substr(Cast(Cast(\"left\" AS integer) AS character ), 0, 3), '-' , Substr(Cast(Cast(bottom AS integer) AS character ), 0, 4) ) AS nom_maille, '2015' AS version_ref, 'Grille nationale (2km x 2km) Martinique' AS nom_ref FROM MTQ_UTM20N2X2"
# vérification
psql service=naturaliz_martinique_dev -c "SELECT code_maille, nom_maille, ST_Area(geom) FROM sig.maille_02 LIMIT 1"


# mailles 5km
wget https://inpn.mnhn.fr/docs/Shape/MTQ_UTM20N5X5.zip
psql service=naturaliz_martinique_dev -c "TRUNCATE sig.maille_05 RESTART IDENTITY"
ogr2ogr -append -s_srs "EPSG:32620" -t_srs "EPSG:5490" -f PostgreSQL "PG:service=naturaliz_martinique_dev active_schema=sig" "MTQ_UTM20N5X5.shp" -nln maille_05 -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT CD_SIG AS code_maille, Concat(SUBSTR(CD_SIG, -8,3), '-', SUBSTR(CD_SIG, -4)) AS nom_maille, '2015' AS version_ref, 'Grille nationale (5km x 5km) Martinique' AS nom_ref FROM MTQ_UTM20N5X5"
# vérification
psql service=naturaliz_martinique_dev -c "SELECT code_maille, nom_maille, ST_Area(geom) FROM sig.maille_05 LIMIT 1"


# mailles 10km
wget https://inpn.mnhn.fr/docs/Shape/MTQ_UTM20N10X10.zip
psql service=naturaliz_martinique_dev -c "TRUNCATE sig.maille_10 RESTART IDENTITY"
ogr2ogr -append -s_srs "EPSG:32620" -t_srs "EPSG:5490" -f PostgreSQL "PG:service=naturaliz_martinique_dev active_schema=sig" "MTQ_UTM20N10X10.shp" -nln maille_10 -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT CD_SIG AS code_maille, Concat(SUBSTR(CD_SIG, 11,3), '-', SUBSTR(CD_SIG, -4)) AS nom_maille, '2012' AS version_ref, 'Grille nationale (10km x 10km) Martinique' AS nom_ref FROM MTQ_UTM20N10X10"
# vérification
psql service=naturaliz_martinique_dev -c "SELECT code_maille, nom_maille, ST_Area(geom) FROM sig.maille_10 LIMIT 1"


# espaces naturels
psql service=naturaliz_martinique_dev -c "TRUNCATE sig.espace_naturel RESTART IDENTITY"

# Reserves_naturelles_nationales
wget https://inpn.mnhn.fr/docs/Shape/mtq_rnn.zip

psql service=naturaliz_martinique_dev -c "DELETE FROM sig.espace_naturel WHERE type_en = 'RNN'"
ogr2ogr -append -s_srs "EPSG:32620" -t_srs "EPSG:5490" -f PostgreSQL "PG:service=naturaliz_martinique_dev active_schema=sig" "mtq_rnn2019_12/N_ENP_RNN_S_972.shp" -nln espace_naturel -lco GEOMETRY_NAME=geom -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'RNN' AS type_en, NOM_SITE AS nom_en, concat('http://inpn.mnhn.fr/espace/protege/', ID_MNHN) AS url, '12/2019' AS version_en FROM N_ENP_RNN_S_972"
# verification
psql service=naturaliz_martinique_dev -c "SELECT code_en, nom_en, ST_Area(geom) FROM sig.espace_naturel WHERE type_en = 'RNN' LIMIT 1"

# HABREF
psql service=naturaliz_martinique_dev -c "TRUNCATE occtax.habitat RESTART IDENTITY"
wget "https://inpn.mnhn.fr/docs/ref_habitats/HABREF_5.0/HABREF_50.zip" -O HABREF_50.zip
rm HAB*.csv TYPO*.csv Guide*.pdf _50.zipa
unzip HABREF_50.zip
ogr2ogr -append -f PostgreSQL "PG:service=naturaliz_martinique_dev active_schema=occtax" "HABREF_50.csv" -nln habitat -gt 100000 -sql "SELECT 'HABREF' AS ref_habitat, CD_HAB AS code_habitat, CD_HAB_SUP AS code_habitat_parent, NIVEAU AS niveau_habitat, CASE WHEN LB_HAB_FR IS NULL OR LB_HAB_FR = '' THEN CASE WHEN Coalesce(LB_HAB_FR_COMPLET, '') != '' THEN LB_HAB_FR_COMPLET ELSE LB_HAB_EN END ELSE LB_HAB_FR END AS libelle_habitat, CASE WHEN Coalesce(LB_DESCRIPTION, '') != '' THEN LB_DESCRIPTION ELSE CASE WHEN Coalesce(LB_HAB_FR_COMPLET, '') != '' THEN LB_HAB_FR_COMPLET WHEN Coalesce(LB_HAB_FR, '') != '' THEN LB_HAB_FR ELSE LB_HAB_EN END END AS description_habitat, CD_HAB AS tri_habitat, CD_HAB AS cd_hab FROM HABREF_50" -dialect SQLITE
rm HABREF_50.zip
rm HAB*.csv TYPO*.csv Guide*.pdf
# verification
psql service=naturaliz_martinique_dev -c "SELECT * FROM occtax.habitat LIMIT 1"

# Habitats marins
# pas de fichier

# Habitats terrestres
# pas de fichier

# Znieff 1
# Znieff 2
# Pas de fichier sur le site de l'INPN

# Sites Ramsar
echo "Ramsar"
#psql service=naturaliz_martinique_dev -c "DELETE FROM sig.espace_naturel WHERE type_en = 'RAMSAR'"
wget https://inpn.mnhn.fr/docs/Shape/mtq_ramsar.zip
ogr2ogr -append -s_srs "EPSG:32620" -t_srs "EPSG:5490" -f PostgreSQL "PG:service=naturaliz_martinique_dev active_schema=sig" "mtq_ramsar2012.shp" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'RAMSAR' AS type_en, NOM AS nom_en, '' AS url, '2012' AS version_en FROM mtq_ramsar2012"
# verification
psql service=naturaliz_martinique_dev -c "SELECT code_en, type_en, nom_en, ST_Area(geom) FROM sig.espace_naturel WHERE type_en = 'RAMSAR' LIMIT 1"

# Parc national
# aucun à Martinique

# Par naturel régional
wget https://inpn.mnhn.fr/docs/Shape/mtq_pnr.zip
ogr2ogr -append -s_srs "EPSG:32620" -t_srs "EPSG:5490" -f PostgreSQL "PG:service=naturaliz_martinique_dev active_schema=sig" "mtq_pnr2013.shp" -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'PNR' AS type_en, NOM AS nom_en, concat('http://inpn.mnhn.fr/espace/protege/', ID_MNHN) AS url, '2013' AS version_en FROM mtq_pnr2013"
# verification
psql service=naturaliz_martinique_dev -c "SELECT code_en, type_en, nom_en, ST_Area(geom) FROM sig.espace_naturel WHERE type_en = 'PNR' LIMIT 1"

# Parcs naturel marin PNM
#psql service=naturaliz_martinique_dev -c "DELETE FROM sig.espace_naturel WHERE type_en = 'PNM'"
wget https://inpn.mnhn.fr/docs/Shape/mtq_pnm.zip
echo "PNM - Parc naturel marin de Martinique"
ogr2ogr -append -s_srs "EPSG:32620" -t_srs "EPSG:5490" -f PostgreSQL "PG:service=naturaliz_martinique_dev active_schema=sig" mtq_pnm2019_12/N_ENP_PNM_S_972.shp -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'PNM' AS type_en, NOM_SITE AS nom_en, concat('http://inpn.mnhn.fr/espace/protege/', ID_MNHN) AS url, '12/2019' AS version_en FROM N_ENP_PNM_S_972"
# verification
psql service=naturaliz_martinique_dev -c "SELECT code_en, type_en, nom_en, ST_Area(geom) FROM sig.espace_naturel WHERE type_en = 'PNM' LIMIT 2"


# Terrains du Conservatoire du Littoral
# psql service=naturaliz_martinique_dev -c "DELETE FROM sig.espace_naturel WHERE type_en = 'PNM'"
echo "Conservatoire du littoral"
wget https://inpn.mnhn.fr/docs/Shape/mtq_cdl.zip
ogr2ogr -append -s_srs "EPSG:32620" -t_srs "EPSG:5490" -f PostgreSQL "PG:service=naturaliz_martinique_dev active_schema=sig" mtq_cdl2018_03/N_ENP_SCL_S_972.shp -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'SCL' AS type_en, NOM_SITE AS nom_en, URL_FICHE AS url, '03/2018' AS version_en FROM N_ENP_SCL_S_972"
# verification
psql service=naturaliz_martinique_dev -c "SELECT code_en, type_en, nom_en, ST_Area(geom) FROM sig.espace_naturel WHERE type_en = 'SCL' LIMIT 2"


# Reserves_de_la_biosphere
# aucun à Martinique

# Reserves_biologiques intégrale
echo "Réserves biologiques intégrales"
wget https://inpn.mnhn.fr/docs/Shape/mtq_rb.zip
ogr2ogr -append -s_srs "EPSG:32620" -t_srs "EPSG:5490" -f PostgreSQL "PG:service=naturaliz_martinique_dev active_schema=sig" mtq_rb2019_03/N_ENP_RB_S_972.shp -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'RBI' AS type_en, NOM_SITE AS nom_en, URL_FICHE AS url, '03/2019' AS version_en FROM N_ENP_RB_S_972"
# verification
psql service=naturaliz_martinique_dev -c "SELECT code_en, type_en, nom_en, ST_Area(geom) FROM sig.espace_naturel WHERE type_en = 'RBI' LIMIT 4"


# Arretes_de_protection_de_biotope
# psql service=naturaliz_martinique_dev -c "DELETE FROM sig.espace_naturel WHERE type_en = 'APB'"
echo "Arretes_de_protection_de_biotope"
wget https://inpn.mnhn.fr/docs/Shape/mtq_apb.zip
ogr2ogr -append -s_srs "EPSG:32620" -t_srs "EPSG:5490" -f PostgreSQL "PG:service=naturaliz_martinique_dev active_schema=sig" mtq_apb/mtq_apb2016_03/N_ENP_APB_S_972.shp -nln espace_naturel -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT ID_MNHN AS code_en, 'APB' AS type_en, NOM_SITE AS nom_en, URL_FICHE AS url, '03/2016' AS version_en FROM N_ENP_APB_S_972"
# verification
psql service=naturaliz_martinique_dev -c "SELECT code_en, type_en, nom_en, ST_Area(geom) FROM sig.espace_naturel WHERE type_en = 'APB' LIMIT 2"

# Masses d'eau
# Trouvé via http://www.sandre.eaufrance.fr/Rechercher-un-jeu-de-donnees?keyword=Martinique
# Choix du référentiel VRAP2016

# Masses d'eau cotieres
echo "MasseDEauCotiere_VRAP2016_MYT"
# psql service=naturaliz_martinique_dev -c "TRUNCATE sig.masse_eau RESTART IDENTITY"
# NB: Je ne sais pas où trouver la version
# URL http://www.sandre.eaufrance.fr/atlas/srv/fre/catalog.search#/metadata/0f80a3df-0479-425e-b117-84c41373d832
ogr2ogr -append -a_srs "EPSG:5490" -s_srs "EPSG:5490" -t_srs "EPSG:5490"  -f PostgreSQL "PG:service=naturaliz_martinique_dev active_schema=sig" WFS:"https://services.sandre.eaufrance.fr/geo/MasseDEau_VRAP2016?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature&TYPENAME=sa:MasseDEauCotiere_VRAP2016_MYT&srsname=EPSG:5490" -nln masse_eau -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT CdEuMasseDEau AS code_me,  Concat( NomMasseDEau, ' (', CdEuMasseDEau, ')' ) AS nom_me, 2 AS version_me, DateMajMasseDEau AS date_me FROM MasseDEauCotiere_VRAP2016_MYT"



# Masses d'eau souterraines
echo "MasseDEauSouterraine_VRAP2016_MYT"
# NB: Je ne sais pas où trouver la version
# URL http://www.sandre.eaufrance.fr/atlas/srv/fre/catalog.search#/metadata/0f80a3df-0479-425e-b117-84c41373d832
ogr2ogr -append -a_srs "EPSG:5490" -s_srs "EPSG:5490" -t_srs "EPSG:5490"  -f PostgreSQL "PG:service=naturaliz_martinique_dev active_schema=sig" WFS:"https://services.sandre.eaufrance.fr/geo/MasseDEau_VRAP2016?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature&TYPENAME=sa:MasseDEauSouterraine_VRAP2016_MYT&srsname=EPSG:5490" -nln masse_eau -lco GEOMETRY_NAME=geom -lco PG_USE_COPY=YES -gt 100000 -sql "SELECT CdEuMasseDEau AS code_me,  Concat( NomMasseDEau, ' (', CdEuMasseDEau, ')' ) AS nom_me, 2 AS version_me, DateMajMasseDEau AS date_me FROM MasseDEauSouterraine_VRAP2016_MYT"


# verification
psql service=naturaliz_martinique_dev -c "SELECT code_me, nom_me, ST_Area(geom) FROM sig.masse_eau LIMIT 2"

# correction des géométries des masses d'eau et des espaces naturels
psql service=naturaliz_martinique_dev -c "ALTER TABLE sig.espace_naturel ALTER COLUMN geom SET DATA TYPE geometry(MULTIPOLYGON, 4471) USING ST_Multi(geom)::geometry(MULTIPOLYGON, 4471);"
psql service=naturaliz_martinique_dev -c "ALTER TABLE sig.masse_eau ALTER COLUMN geom SET DATA TYPE geometry(MULTIPOLYGON, 4471) USING ST_Multi(geom)::geometry(MULTIPOLYGON, 4471);"
