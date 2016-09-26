CREATE EXTENSION IF NOT EXISTS "postgis";

-- Schéma
CREATE SCHEMA mascarine;
SET search_path TO mascarine,public,pg_catalog;

-- Table m_nomenclature
CREATE TABLE m_nomenclature (
    champ text,
    code text,
    valeur text,
    description text,
    m_order integer
);

ALTER TABLE m_nomenclature ADD PRIMARY KEY (champ, code);

COMMENT ON TABLE m_nomenclature IS 'Stockage de la m_nomenclature pour les champs des tables qui ont des listes de valeurs prédéfinies.';
COMMENT ON COLUMN m_nomenclature.champ IS 'Nom du champ';
COMMENT ON COLUMN m_nomenclature.code IS 'Code associé à une valeur';
COMMENT ON COLUMN m_nomenclature.valeur IS 'Libellé court. Joue le rôle de valeur';
COMMENT ON COLUMN m_nomenclature.champ IS 'Description de la valeur';

CREATE TABLE organisme (
    id_org serial PRIMARY KEY,
    nom_org text,
    abreviation_org text
);

COMMENT ON TABLE organisme IS 'Liste des organismes des personnes participant aux observations.';
COMMENT ON COLUMN organisme.id_org IS 'Identifiant de l''organisme';
COMMENT ON COLUMN organisme.nom_org IS 'Nom de l''organisme';
COMMENT ON COLUMN organisme.abreviation_org IS 'Abreviation de l''organisme';

CREATE TABLE personne (
    id_perso serial PRIMARY KEY,
    civilite_perso text,
    nom_perso text,
    prenom_perso text,
    id_org integer,
    remarques_perso text,
    adresse_perso text,
    telephone_perso text,
    portable_perso text,
    email_perso text,
    usr_login text,
    CONSTRAINT personne_civilite_perso_valide CHECK ( civilite_perso IN ( 'M', 'F' ) )
);

COMMENT ON TABLE personne IS 'Liste des personnes participant aux observations.';
COMMENT ON COLUMN personne.id_perso IS 'Identifiant de la personne.';
COMMENT ON COLUMN personne.civilite_perso IS 'Civilité de la personne, table m_nomenclature, code M ou F';
COMMENT ON COLUMN personne.nom_perso IS 'Nom de la personne';
COMMENT ON COLUMN personne.prenom_perso IS 'Prenom de la personne';
COMMENT ON COLUMN personne.id_org IS 'Identifiant de l''organisme de la personne';
COMMENT ON COLUMN personne.remarques_perso IS 'Remarques sur la personne';
COMMENT ON COLUMN personne.adresse_perso IS 'Adresse de la personne';
COMMENT ON COLUMN personne.telephone_perso IS 'Telephone de la personne';
COMMENT ON COLUMN personne.portable_perso IS 'Portable de la personne';
COMMENT ON COLUMN personne.email_perso IS 'Email de la personne';
COMMENT ON COLUMN personne.usr_login IS 'Login de l''utilisateur associé à la personne, table jlx_user';

CREATE TABLE programme (
    id_prog serial PRIMARY KEY,
    nom_prog text NOT NULL,
    validateur text
);

COMMENT ON TABLE programme IS 'Liste des programmes d''observation.';
COMMENT ON COLUMN programme.id_prog IS 'Identifiant du programme';
COMMENT ON COLUMN programme.nom_prog IS 'Nom du programme';
COMMENT ON COLUMN programme.validateur IS 'Prénom, nom et/ou organisme de la personne ayant réalisée la validation scientifique de l’observation. Utilisé pour remplir le champ occtax.observation.validateur lors des exports vers le schéma occtax (trigger)';


CREATE TABLE m_observation (
    id_obs serial PRIMARY KEY,
    type_obs text,
    nature_obs text,
    forme_obs text,
    date_obs date,
    num_manuscrit text,
    id_prog integer,
    expertise_obs text,
    remarques_obs text,
    remarques_controle_obs text,
    validee_obs boolean,
    saved_obs boolean
);

COMMENT ON TABLE m_observation IS 'Liste des observations.';
COMMENT ON COLUMN m_observation.id_obs IS 'Identifiant de l''observation';
COMMENT ON COLUMN m_observation.type_obs IS 'Type ou protocole d''observation, table m_nomenclature';
COMMENT ON COLUMN m_observation.nature_obs IS 'Nature de l''observation, table m_nomenclature';
COMMENT ON COLUMN m_observation.forme_obs IS 'Forme de l''observation, table m_nomenclature';
COMMENT ON COLUMN m_observation.date_obs IS 'Date de l''observation';
COMMENT ON COLUMN m_observation.num_manuscrit IS 'Numéro du manuscrit de l''observation';
COMMENT ON COLUMN m_observation.id_prog IS 'Identifiant du programme d''observation, table programme';
COMMENT ON COLUMN m_observation.expertise_obs IS 'Expertise sur l''observation';
COMMENT ON COLUMN m_observation.remarques_obs IS 'Remarques sur l''observation';
COMMENT ON COLUMN m_observation.remarques_controle_obs IS 'Remarques de contrôle sur l''observation';
COMMENT ON COLUMN m_observation.validee_obs IS 'Est vrai seulement si l''observation a été validée scientifiquement. Une observation non validée ne peut être vue que par les profils avec des droits élevés. Une observation validée ne peut plus être modifiée.';
COMMENT ON COLUMN m_observation.saved_obs IS 'Permet de savoir si l''utilisateur considère l''observation comme enregistrée, cad prête à être validée par l''administrateur';

CREATE TABLE personne_obs (
    id_obs integer,
    id_perso integer,
    role_perso_obs text
);
ALTER TABLE personne_obs ADD PRIMARY KEY (id_obs, id_perso);
ALTER TABLE personne_obs ADD CONSTRAINT personne_obs_id_obs_fk FOREIGN KEY (id_obs) REFERENCES m_observation (id_obs) ON DELETE CASCADE;

COMMENT ON TABLE personne_obs IS 'Liste des personnes ayant participé à l''observation.';
COMMENT ON COLUMN personne_obs.id_obs IS 'Identifiant de l''observation';
COMMENT ON COLUMN personne_obs.id_perso IS 'Identifiant de la personne';
COMMENT ON COLUMN personne_obs.role_perso_obs IS 'Rôle de la personne lors de l''observation, table m_nomenclature';

CREATE TABLE localisation_obs (
    id_obs integer PRIMARY KEY,
    code_commune text,
    id_lieudit integer,
    code_maille text,
    coord_x double precision,
    coord_y double precision,
    alt_min real,
    alt_max real,
    alt_moy real,
    code_milieu text,
    description_loc text,
    remarques_loc text
);
SELECT AddGeometryColumn('localisation_obs', 'geom', {$SRID}, 'GEOMETRY', 2);

ALTER TABLE localisation_obs ADD CONSTRAINT localisation_obs_id_obs_fk FOREIGN KEY (id_obs) REFERENCES m_observation (id_obs) ON DELETE CASCADE;

COMMENT ON TABLE localisation_obs IS 'Liste des localisations d''observation.';
COMMENT ON COLUMN localisation_obs.id_obs IS 'Identifiant de l''observation, table observation';
COMMENT ON COLUMN localisation_obs.code_commune IS 'Code de la commune de l''observation, table commune';
COMMENT ON COLUMN localisation_obs.id_lieudit IS 'Identifiant du lieu-dit de l''observation, table lieudit';
COMMENT ON COLUMN localisation_obs.code_maille IS 'Code de la maille 1km de l''observation, table maille01';
COMMENT ON COLUMN localisation_obs.coord_x IS 'Coordonnée X de l''observation';
COMMENT ON COLUMN localisation_obs.coord_y IS 'Coordonnée Y de l''observation';
COMMENT ON COLUMN localisation_obs.alt_min IS 'Altitude minimum de l''observation';
COMMENT ON COLUMN localisation_obs.alt_max IS 'Altitude maximum de l''observation';
COMMENT ON COLUMN localisation_obs.alt_moy IS 'Altitude moyenne de l''observation';
COMMENT ON COLUMN localisation_obs.code_milieu IS 'Code du type de mileu';
COMMENT ON COLUMN localisation_obs.description_loc IS 'Description de la localisation de l''observation';
COMMENT ON COLUMN localisation_obs.remarques_loc IS 'Remarques sur la localisation de l''observation';

CREATE TABLE flore_obs (
    id_flore_obs serial PRIMARY KEY,
    id_obs integer NOT NULL,
    cd_nom integer NOT NULL,
    strate_flore text NOT NULL,
    statut_local_flore text,
    ad_standard_flore text,
    effectif_flore integer,
    remarques_flore text,
    cd_nom_phorophyte text
);
ALTER TABLE flore_obs ADD CONSTRAINT flore_obs_unique_mk UNIQUE ( id_obs, cd_nom, strate_flore );
ALTER TABLE flore_obs ADD CONSTRAINT flore_obs_id_obs_fk FOREIGN KEY (id_obs) REFERENCES m_observation (id_obs) ON DELETE CASCADE;

COMMENT ON TABLE flore_obs IS 'Liste des taxons observés pour chaque observation.';
COMMENT ON COLUMN flore_obs.id_flore_obs IS 'Identifiant unique pour le triplet id_obs, cd_nom, strate_flore';
COMMENT ON COLUMN flore_obs.id_obs IS 'Identifiant de l''observation, table observation';
COMMENT ON COLUMN flore_obs.cd_nom IS 'Code nom du taxon observé, vue taxref_consolide';
COMMENT ON COLUMN flore_obs.strate_flore IS 'Strate du taxon observé, table m_nomenclature';
COMMENT ON COLUMN flore_obs.statut_local_flore IS 'Statut local du taxon observé, table m_nomenclature';
COMMENT ON COLUMN flore_obs.ad_standard_flore IS 'Coefficient d''abondance du taxon observé, table m_nomenclature';
COMMENT ON COLUMN flore_obs.effectif_flore IS 'Effectif total du taxon observé';
COMMENT ON COLUMN flore_obs.remarques_flore IS 'Remarques sur le taxon observé';
COMMENT ON COLUMN flore_obs.cd_nom_phorophyte IS 'Code nom du taxon phorophyte du taxon observé, vue taxref_consolide';

CREATE TABLE pheno_flore_obs (
    id_pheno_flore_obs serial PRIMARY KEY,
    id_flore_obs integer NOT NULL,
    id_obs integer NOT NULL,
    cd_nom text NOT NULL,
    strate_flore text NOT NULL,
    dev_pheno_flore text,
    pheno_flore text,
    stade_pheno_flore text,
    remarques_pheno_flore text
);
ALTER TABLE pheno_flore_obs ADD CONSTRAINT pheno_flore_obs_id_flore_obs_fk FOREIGN KEY (id_flore_obs) REFERENCES flore_obs (id_flore_obs) ON DELETE CASCADE;
ALTER TABLE pheno_flore_obs ADD CONSTRAINT pheno_flore_obs_id_obs_fk FOREIGN KEY (id_obs) REFERENCES m_observation (id_obs) ON DELETE CASCADE;
COMMENT ON TABLE pheno_flore_obs IS 'Liste des caractéristiques phénologiques des taxons observés.';
COMMENT ON COLUMN pheno_flore_obs.id_pheno_flore_obs IS 'Identifiant de la phénologie du taxon observé';
COMMENT ON COLUMN pheno_flore_obs.id_flore_obs IS 'Identifiant unique pour le triplet id_obs, cd_nom, strate_flore';
COMMENT ON COLUMN pheno_flore_obs.id_obs IS 'Identifiant de l''observation, table observation';
COMMENT ON COLUMN pheno_flore_obs.cd_nom IS 'Code nom du taxon observé, vue taxref_consolide';
COMMENT ON COLUMN pheno_flore_obs.strate_flore IS 'Strate du taxon observé, table m_nomenclature';
COMMENT ON COLUMN pheno_flore_obs.dev_pheno_flore IS 'Développement phénologique du taxon observé, table nomencalature';
COMMENT ON COLUMN pheno_flore_obs.pheno_flore IS 'Phénologie du taxon observé, table nomencalature';
COMMENT ON COLUMN pheno_flore_obs.stade_pheno_flore IS 'Stade phénologique du taxon observé, table nomencalature';
COMMENT ON COLUMN pheno_flore_obs.remarques_pheno_flore IS 'Remarques sur la phénologie du taxon observé';

CREATE TABLE pop_flore_obs (
    id_pop_flore_obs serial PRIMARY KEY,
    id_flore_obs integer NOT NULL,
    id_obs integer NOT NULL,
    cd_nom text NOT NULL,
    strate_flore text NOT NULL,
    classe_pop_flore text,
    nombre_pop_flore integer,
    borne_inf_pop_flore integer,
    borne_sup_pop_flore integer,
    remarques_pop_flore text
);
ALTER TABLE pop_flore_obs ADD CONSTRAINT pop_flore_obs_id_flore_obs_fk FOREIGN KEY (id_flore_obs) REFERENCES flore_obs (id_flore_obs) ON DELETE CASCADE;
ALTER TABLE pop_flore_obs ADD CONSTRAINT pop_flore_obs_id_obs_fk FOREIGN KEY (id_obs) REFERENCES m_observation (id_obs) ON DELETE CASCADE;
COMMENT ON TABLE pop_flore_obs IS 'Liste des caractéristiques de population des taxons observés.';
COMMENT ON COLUMN pop_flore_obs.id_pop_flore_obs IS 'Identifiant de la population du taxon observé';
COMMENT ON COLUMN pop_flore_obs.id_flore_obs IS 'Identifiant unique pour le triplet id_obs, cd_nom, strate_flore';
COMMENT ON COLUMN pop_flore_obs.id_obs IS 'Identifiant de l''observation, table observation';
COMMENT ON COLUMN pop_flore_obs.cd_nom IS 'Code nom du taxon observé, vue taxref_consolide';
COMMENT ON COLUMN pop_flore_obs.strate_flore IS 'Strate du taxon observé, table m_nomenclature';
COMMENT ON COLUMN pop_flore_obs.classe_pop_flore IS 'Classe de population du taxon observé, table nomencalature';
COMMENT ON COLUMN pop_flore_obs.nombre_pop_flore IS 'Nombre d''individu de la classe de population du taxon observé';
COMMENT ON COLUMN pop_flore_obs.borne_inf_pop_flore IS 'Borne inférieur du nombre d''individu de la dlasse de population du taxon observé';
COMMENT ON COLUMN pop_flore_obs.borne_sup_pop_flore IS 'Borne supérieur du nombre d''individu de la dlasse de population du taxon observé';
COMMENT ON COLUMN pop_flore_obs.remarques_pop_flore IS 'Remarques sur la population du taxon observé';

CREATE TABLE station_obs (
    id_obs integer PRIMARY KEY,
    exposition_station text,
    lumiere_station text,
    pente_min_station real,
    pente_moy_station real,
    pente_max_station real,
    alt_min_station real,
    alt_moy_station real,
    alt_max_station real,
    aire_station double precision,
    aire_unit_station text,
    recouvrement_station real,
    hauteur_station real,
    hauteur_min_station real,
    hauteur_max_station real,
    hauteur_canopee_station real,
    remarques_station_obs text
);

ALTER TABLE station_obs ADD CONSTRAINT station_obs_id_obs_fk FOREIGN KEY (id_obs) REFERENCES m_observation (id_obs) ON DELETE CASCADE;

COMMENT ON TABLE station_obs IS 'Liste des stations d''observation.';
COMMENT ON COLUMN station_obs.id_obs IS 'Identifiant de l''observation, table observation';
COMMENT ON COLUMN station_obs.exposition_station IS 'Exposition de la station, table m_nomenclature';
COMMENT ON COLUMN station_obs.lumiere_station IS 'Lumière de la station, table m_nomenclature';
COMMENT ON COLUMN station_obs.pente_min_station IS 'Pente minimum de la station';
COMMENT ON COLUMN station_obs.pente_moy_station IS 'Pente moyenne de la station';
COMMENT ON COLUMN station_obs.pente_max_station IS 'Pente maximum de la station';
COMMENT ON COLUMN station_obs.alt_min_station IS 'Altitude minimum de la station';
COMMENT ON COLUMN station_obs.alt_moy_station IS 'Altitude moyenne de la station';
COMMENT ON COLUMN station_obs.alt_max_station IS 'Altitude maximum de la station';
COMMENT ON COLUMN station_obs.aire_station IS 'Aire de la station';
COMMENT ON COLUMN station_obs.aire_unit_station IS 'Unité de l''aire de la station, table m_nomenclature';
COMMENT ON COLUMN station_obs.recouvrement_station IS 'Recouvrement de la station';
COMMENT ON COLUMN station_obs.hauteur_station IS 'Hauteur de la station';
COMMENT ON COLUMN station_obs.hauteur_min_station IS 'Hauteur minimum de la station';
COMMENT ON COLUMN station_obs.hauteur_min_station IS 'Hauteur maximum de la station';
COMMENT ON COLUMN station_obs.hauteur_canopee_station IS 'Hauteur de la canopée de la station';
COMMENT ON COLUMN station_obs.remarques_station_obs IS 'Remarques sur la station';

CREATE TABLE menace_obs (
    id_obs_menace serial PRIMARY KEY,
    id_obs integer,
    type_menace text,
    valeur_menace text,
    statut_menace text,
    remarques_menace text
);


ALTER TABLE menace_obs ADD CONSTRAINT menace_obs_id_obs_fk FOREIGN KEY (id_obs) REFERENCES m_observation (id_obs) ON DELETE CASCADE;

COMMENT ON TABLE menace_obs IS 'Liste des menances d''observation.';
COMMENT ON COLUMN menace_obs.id_obs_menace IS 'Identifiant de la menace d''observation';
COMMENT ON COLUMN menace_obs.id_obs IS 'Identifiant de l''observation, table observation';
COMMENT ON COLUMN menace_obs.type_menace IS 'Type de menace, table m_nomenclature';
COMMENT ON COLUMN menace_obs.valeur_menace IS 'Valeur de menace, table m_nomenclature';
COMMENT ON COLUMN menace_obs.statut_menace IS 'Statut de menace, table m_nomenclature';
COMMENT ON COLUMN menace_obs.remarques_menace IS 'Remarques sur la menace menace';

CREATE TABLE habitat_obs (
    id_obs integer,
    code_habitat text NOT NULL,
    ref_habitat text NOT NULL
);
ALTER TABLE habitat_obs ADD PRIMARY KEY ( id_obs, code_habitat, ref_habitat );
ALTER TABLE habitat_obs ADD CONSTRAINT habitat_obs_id_obs_fk FOREIGN KEY (id_obs) REFERENCES m_observation (id_obs) ON DELETE CASCADE;

COMMENT ON TABLE habitat_obs IS 'Liste des habitats d''observation.';
COMMENT ON COLUMN habitat_obs.id_obs IS 'Identifiant de l''observation, table observation';
COMMENT ON COLUMN habitat_obs.code_habitat IS 'Code de l''habitat, table habitat';
COMMENT ON COLUMN habitat_obs.ref_habitat IS 'Code de référence de l''habitat, table nomenclature d''occtax';


-- Correspondance entre les type_obs de mascarine et le code_idcnp_dispositif de occtax
CREATE TABLE lien_type_mascarine_metadonnee_occtax (
    type_obs text,
    code_idcnp_dispositif text,
    jdd_id text
);
ALTER TABLE lien_type_mascarine_metadonnee_occtax ADD PRIMARY KEY ( type_obs, code_idcnp_dispositif );
COMMENT ON TABLE lien_type_mascarine_metadonnee_occtax IS 'Table de lien entre les types d''observation (BIC, MIG, etc.) et le code IDCNP du dispositif ainsi que les jdd_code et jdd_id. Utilisé lors de la création automatique d''observation dans occtax à partir de données de mascarine validées';
COMMENT ON COLUMN lien_type_mascarine_metadonnee_occtax.type_obs IS 'Type ou protocole d''observation, table m_nomenclature';
COMMENT ON COLUMN lien_type_mascarine_metadonnee_occtax.code_idcnp_dispositif IS 'Code du dispositif de collecte dans le cadre duquel la donnée a été collectée.';
COMMENT ON COLUMN lien_type_mascarine_metadonnee_occtax.jdd_id IS 'Un identifiant pour la collection ou le jeu de données terrain d’où provient l’enregistrement. Exemple code IDCNP pour l’INPN : « 00-15 ».';



-- Indexes
CREATE INDEX ON personne (id_org);
CREATE INDEX ON personne_obs (id_obs);

CREATE INDEX ON localisation_obs USING gist (geom);
CREATE INDEX ON localisation_obs (code_commune);
CREATE INDEX ON localisation_obs (code_maille);
CREATE INDEX ON localisation_obs (id_obs);

CREATE INDEX ON flore_obs (cd_nom);
CREATE INDEX ON flore_obs (strate_flore);
CREATE INDEX ON flore_obs (id_obs);

CREATE INDEX ON pheno_flore_obs (id_obs);
CREATE INDEX ON pheno_flore_obs (cd_nom);
CREATE INDEX ON pheno_flore_obs (strate_flore);
CREATE INDEX ON pheno_flore_obs (id_obs, cd_nom, strate_flore);
CREATE INDEX ON pop_flore_obs (id_obs);
CREATE INDEX ON pop_flore_obs (cd_nom);
CREATE INDEX ON pop_flore_obs (strate_flore);
CREATE INDEX ON pop_flore_obs (id_obs, cd_nom, strate_flore);

CREATE INDEX ON menace_obs (id_obs);
CREATE INDEX ON habitat_obs (id_obs);

CREATE INDEX ON m_nomenclature (champ,code);


SET search_path TO sig,public,pg_catalog;

-- Table lieudit
CREATE TABLE lieudit (
    id_lieudit serial PRIMARY KEY,
    code_lieudit text NOT NULL,
    nom_lieudit text NOT NULL,
    nature_lieudit text,
    importance_lieudit integer
);
SELECT AddGeometryColumn('lieudit', 'geom', {$SRID}, 'POINT', 2);

COMMENT ON TABLE lieudit IS 'Liste des lieux-dit';
COMMENT ON COLUMN lieudit.id_lieudit IS 'Identifiant automatique du lieu-dit.';
COMMENT ON COLUMN lieudit.code_lieudit IS 'Identifiant du lieu-dit.';
COMMENT ON COLUMN lieudit.nom_lieudit IS 'Nom du lieu-dit.';
COMMENT ON COLUMN lieudit.nature_lieudit IS 'Nature du lieu-dit.';
COMMENT ON COLUMN lieudit.importance_lieudit IS 'Importance du lieu-dit.';
COMMENT ON COLUMN lieudit.geom IS 'Géométrie, point, du lieu-dit.';

-- Indexes
CREATE INDEX ON lieudit USING gist (geom);



-- TRIGGERS

-- Trigger to update altitudes when modifying localisation_obs geometry or creating new line
CREATE OR REPLACE FUNCTION mascarine.calcul_altitude_observation()
RETURNS TRIGGER AS
$BODY$
DECLARE
myrecord record;
BEGIN
    IF TG_OP = 'UPDATE'  THEN
    -- If the user has not modified the geometry, do nothing
            IF OLD.geom = NEW.geom THEN
                    RETURN new;
            END IF;
    END IF;

    -- Get altitude
    WITH alt AS (
        SELECT ( ST_intersection( m.rast, NEW.geom) ).val::integer AS altitude
        FROM public.mnt m
        WHERE TRUE
        AND ST_Intersects( NEW.geom, m.rast)

    )
    SELECT INTO myrecord
    avg( altitude )::integer AS alt_moy, min( altitude )::integer AS alt_min, max( altitude )::integer AS alt_max
    FROM alt;

    NEW.alt_min:= myrecord.alt_min;
    NEW.alt_max:= myrecord.alt_max;
    NEW.alt_moy:= myrecord.alt_moy;

    -- Get commune id
    IF NEW.code_commune IS NULL THEN
        SELECT INTO myrecord
        code_commune
        FROM sig.commune c
        WHERE ST_Intersects(NEW.geom, c.geom)
        LIMIT 1;

        NEW.code_commune = myrecord.code_commune;
    END IF;

    -- Get maille id
    IF NEW.code_maille IS NULL THEN
        SELECT INTO myrecord
        code_maille
        FROM sig.maille_01 m
        WHERE ST_Intersects(NEW.geom, m.geom)
        LIMIT 1;

        NEW.code_maille = myrecord.code_maille;
    END IF;


    RETURN NEW;
END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE;

CREATE TRIGGER trg_localisation_obs_geom_modified
BEFORE INSERT OR UPDATE OF geom ON mascarine.localisation_obs
FOR EACH ROW EXECUTE PROCEDURE mascarine.calcul_altitude_observation();



-- Fonction d'export automatique vers occtax d'une observation validée
CREATE OR REPLACE FUNCTION mascarine.export_validated_mascarine_observation_into_occtax(m_id_obs integer)
  RETURNS INTEGER AS
$BODY$
DECLARE
myrecord record;
mynewobs RECORD;
BEGIN

    SELECT INTO myrecord
    id_obs, validee_obs, type_obs, remarques_obs, date_obs, id_prog
    FROM mascarine.m_observation mo
    WHERE mo.id_obs = m_id_obs;

    -- Do action only when validee_obs devient TRUE
    IF myrecord.validee_obs = FALSE OR myrecord.validee_obs IS NULL THEN
            RETURN 0;
    END IF;

    -- Insertion de la géométrie dans objet_geographique
    INSERT INTO occtax.objet_geographique ( geom )
    SELECT DISTINCT s.geom
    FROM (SELECT geom FROM mascarine.localisation_obs WHERE id_obs = myrecord.id_obs) AS s
    LEFT JOIN occtax.objet_geographique og ON og.geom = s.geom
    WHERE 2>1
    AND og.cle_objet IS NULL
    ;

    -- Ajout dans la table observation
    INSERT INTO occtax.observation
    SELECT
    nextval('occtax.observation_cle_obs_seq'::regclass) AS cle_obs,
    'Te' statut_source,
    NULL AS reference_biblio,

    ( SELECT jdd_id FROM mascarine.lien_type_mascarine_metadonnee_occtax WHERE type_obs = myrecord.type_obs ) AS jdd_id,

    (   SELECT jdd_code FROM occtax.jdd
        WHERE jdd_id = ( SELECT jdd_id FROM mascarine.lien_type_mascarine_metadonnee_occtax WHERE type_obs = myrecord.type_obs )
    ) AS jdd_code,

    myrecord.id_obs::text AS identifiant_origine,
    CAST(uuid_generate_v4() AS text) AS identifiant_permanent,
    'Re' AS ds_publique,

    ( SELECT code_idcnp_dispositif FROM mascarine.lien_type_mascarine_metadonnee_occtax WHERE type_obs = myrecord.type_obs ) AS code_idcnp_dispositif,

    'Pr' AS statut_observation,
    f.cd_nom::bigint AS cd_nom,
    f.cd_nom::bigint AS cd_ref,
    ( SELECT nom_complet FROM taxon.taxref_consolide WHERE cd_nom = f.cd_nom::bigint ) AS nom_cite,
    '0' AS code_sensible,

    -- Dénombrement
    Coalesce(
        Sum( (SELECT Sum( borne_inf_pop_flore  ) FROM mascarine.pop_flore_obs pfo WHERE pfo.id_flore_obs = f.id_flore_obs GROUP BY id_flore_obs ) ),
        Sum( (SELECT Sum( nombre_pop_flore  ) FROM mascarine.pop_flore_obs pfo WHERE pfo.id_flore_obs = f.id_flore_obs GROUP BY id_flore_obs ) ),
        Sum( f.effectif_flore )
    ) AS denombrement_min,
    Coalesce(
        Sum( (SELECT Sum( borne_sup_pop_flore  ) FROM mascarine.pop_flore_obs pfo WHERE pfo.id_flore_obs = f.id_flore_obs GROUP BY id_flore_obs ) ),
        Sum( (SELECT Sum( nombre_pop_flore  ) FROM mascarine.pop_flore_obs pfo WHERE pfo.id_flore_obs = f.id_flore_obs GROUP BY id_flore_obs ) ),
        Sum( f.effectif_flore )
    ) AS denombrement_max,
    CASE
            WHEN Coalesce(
                Sum( (SELECT Sum( borne_sup_pop_flore  ) FROM mascarine.pop_flore_obs pfo WHERE pfo.id_flore_obs = f.id_flore_obs GROUP BY id_flore_obs ) ),
                Sum( (SELECT Sum( nombre_pop_flore  ) FROM mascarine.pop_flore_obs pfo WHERE pfo.id_flore_obs = f.id_flore_obs GROUP BY id_flore_obs ) ),
                Sum( f.effectif_flore )
            ) IS NULL THEN NULL
            ELSE 'In'::text
    END AS objet_denombrement,
    'NSP' AS type_denombrement,
    myrecord.remarques_obs AS commentaire,

    -- Emprise temporelle
    myrecord.date_obs AS date_debut,
    myrecord.date_obs AS date_fin,
    NULL AS heure_debut,
    NULL AS heure_fin,
    NULL as date_determination,

    -- Localisation
    ( SELECT alt_min FROM mascarine.localisation_obs WHERE id_obs = myrecord.id_obs ) AS altitude_min,
    ( SELECT alt_max FROM mascarine.localisation_obs WHERE id_obs = myrecord.id_obs ) AS altitude_max,
    NULL AS profondeur_min,
    NULL AS profondeur_max,
    ( SELECT nom_lieudit FROM sig.lieudit a INNER JOIN mascarine.localisation_obs b ON a.id_lieudit = b.id_lieudit WHERE b.id_obs = myrecord.id_obs) AS toponyme,
    '971' AS code_departement,
    NULL AS x,
    NULL AS y,
    ( SELECT cle_objet FROM occtax.objet_geographique og WHERE og.geom = (SELECT geom FROM mascarine.localisation_obs WHERE id_obs = myrecord.id_obs) ) AS cle_objet,
    NULL AS precision,
    'St' AS nature_objet_geo,
    'Non' AS restriction_localisation_p,
    'Non' AS restriction_maille,
    'Non' AS restriction_commune,
    'Non' AS restriction_totale,
    'Non' AS floutage,

    -- Acteurs
    (
        SELECT String_agg( nom_perso || ' ' || prenom_perso, ', ' ORDER BY po.role_perso_obs) AS identite
        FROM mascarine.personne p
        INNER JOIN mascarine.personne_obs po ON po.id_perso = p.id_perso
        WHERE po.id_obs = myrecord.id_obs
        AND po.role_perso_obs IN ( 'P', 'S' )
        GROUP BY myrecord.id_obs
    ) AS identite_observateur,
    (
        SELECT String_agg( nom_org, ', ' ORDER BY po.role_perso_obs ) AS organisme
        FROM mascarine.organisme o
        INNER JOIN mascarine.personne p ON p.id_org = o.id_org
        INNER JOIN mascarine.personne_obs po ON po.id_perso = p.id_perso
        WHERE po.id_obs = myrecord.id_obs
        AND po.role_perso_obs IN ( 'P', 'S' )
        GROUP BY myrecord.id_obs
    ) AS organisme_observateur,
    NULL AS determinateur,
    ( SELECT validateur FROM mascarine.programme WHERE id_prog = myrecord.id_prog ) AS validateur,
    'PNG' AS organisme_gestionnaire_donnees,
    'PNG' AS organisme_standard

    FROM mascarine.flore_obs AS f
    WHERE TRUE
    AND f.id_obs = myrecord.id_obs
    GROUP BY myrecord.id_prog, myrecord.id_obs, f.cd_nom
    ;

    -- Récupération de l'identifiant de l'observation créé et d'autres informations
    CREATE TEMPORARY TABLE mascarine_occtax_records
    ON COMMIT DROP
    AS
    SELECT
        o.cle_obs,
        ( SELECT geom FROM mascarine.localisation_obs WHERE id_obs = myrecord.id_obs ) AS geom,
        ( SELECT code_commune FROM mascarine.localisation_obs WHERE id_obs = myrecord.id_obs ) AS code_commune
    FROM occtax.observation o
    WHERE TRUE
    AND o.identifiant_origine = myrecord.id_obs::text
    AND o.jdd_id = ( SELECT jdd_id FROM mascarine.lien_type_mascarine_metadonnee_occtax WHERE type_obs = myrecord.type_obs )
    ;


    -- Ajout des données de la nouvelle obs occtax dans un record
    SELECT INTO mynewobs
    cle_obs, geom, code_commune
    FROM mascarine_occtax_records
    LIMIT 1;

    -- localisation_commune
    -- Via code_commune enregistré dans localisation_obs
    INSERT INTO occtax.localisation_commune
    SELECT s.cle_obs, code_commune
    FROM mascarine_occtax_records s
    ;

    -- -- localisation_maille_10
    -- PAR INTERSECTION AVEC LES GEOMETRIES
    INSERT INTO occtax.localisation_maille_10
    SELECT s.cle_obs, m.code_maille
    FROM mascarine_occtax_records s
    INNER JOIN sig.maille_10 m ON ST_Intersects( s.geom, m.geom )
    ;

    -- -- localisation_maille_05
    -- PAR INTERSECTION AVEC LES GEOMETRIES
    INSERT INTO occtax.localisation_maille_05
    SELECT s.cle_obs, m.code_maille
    FROM mascarine_occtax_records s
    INNER JOIN sig.maille_05 m ON ST_Intersects( s.geom, m.geom )
    ;

    -- -- -- localisation_masse_eau
    -- PAR INTERSECTION AVEC LES GEOMETRIES
    INSERT INTO occtax.localisation_masse_eau
    SELECT s.cle_obs, m.code_me
    FROM mascarine_occtax_records s
    INNER JOIN sig.masse_eau m ON ST_Intersects( s.geom, m.geom )
    ;

    -- localisation_espace_naturel
    -- PAR INTERSECTION AVEC LES GEOMETRIES
    INSERT INTO occtax.localisation_espace_naturel
    SELECT s.cle_obs, en.code_en
    FROM mascarine_occtax_records s
    INNER JOIN sig.espace_naturel en ON ST_Intersects( s.geom, en.geom )
    ;

    RETURN mynewobs.cle_obs;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

