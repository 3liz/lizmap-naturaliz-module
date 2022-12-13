BEGIN;

-- Ajout des droits sur les objets de la base pour naturaliz
GRANT CONNECT ON DATABASE {$DBNAME} TO "{$DBUSER_READONLY}";
GRANT USAGE ON SCHEMA public,taxon,sig,occtax,gestion TO "{$DBUSER_READONLY}";
GRANT SELECT ON ALL TABLES IN SCHEMA occtax,sig,taxon,gestion TO "{$DBUSER_READONLY}";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "{$DBUSER_READONLY}";
GRANT INSERT ON ALL TABLES IN SCHEMA occtax TO "{$DBUSER_READONLY}";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public,occtax,sig,taxon,gestion TO "{$DBUSER_READONLY}";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public,occtax,sig,taxon,gestion TO "{$DBUSER_READONLY}";

-- Ajout des droits sur les objets de la base pour lizmap
GRANT CONNECT ON DATABASE {$DBNAME} TO "{$DBUSER_OWNER}";
GRANT ALL PRIVILEGES ON SCHEMA public,taxon,sig,occtax,gestion TO "{$DBUSER_OWNER}";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public,taxon,sig,occtax,gestion TO "{$DBUSER_OWNER}";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public,occtax,sig,taxon,gestion TO "{$DBUSER_OWNER}";
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public,occtax,sig,taxon,gestion TO "{$DBUSER_OWNER}";

-- Ajout des droits de création et modification pour la validation en ligne
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE occtax.validation_panier TO "{$DBUSER_READONLY}";
GRANT SELECT, INSERT, UPDATE ON TABLE occtax.validation_observation TO "{$DBUSER_READONLY}";
-- On doit aussi donner les droits en modification sur occtax.observation
-- car le trigger copie les données depuis validation_observation vers validatite_niveau et validite_date_validation
-- pour l'échelon ech_val = '2' (régional) lors de la modification de validation_observation
GRANT SELECT, UPDATE ON TABLE occtax.observation TO "{$DBUSER_READONLY}";
-- Aussi la vue pour la validation v_observation_champs_validation
GRANT SELECT ON TABLE occtax.v_observation_champs_validation TO "{$DBUSER_READONLY}";

-- Droits pour l'ajout de données via l'outil d'import
GRANT INSERT, UPDATE, DELETE ON TABLE
occtax.observation, occtax.lien_observation_identifiant_permanent, occtax.organisme, occtax.personne, occtax.observation_personne,
occtax.localisation_commune, occtax.localisation_departement,
occtax.localisation_maille_10, occtax.localisation_maille_05,
occtax.localisation_maille_02, occtax.localisation_maille_01,
occtax.localisation_masse_eau, occtax.localisation_espace_naturel,
occtax.localisation_habitat
TO "{$DBUSER_READONLY}";

-- Droits pour l'ajout et la modification dans taxon.medias
-- cache des photographies de l'API INPN
GRANT SELECT, INSERT, UPDATE ON TABLE taxon.medias TO "{$DBUSER_READONLY}";

COMMIT;
