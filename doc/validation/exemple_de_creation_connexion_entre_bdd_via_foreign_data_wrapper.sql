-- EN TANT QUE postgres
--

-- Créer l'extension
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Donner les droits d'utilisation
GRANT USAGE ON FOREIGN DATA WRAPPER postgres_fdw TO lizmap;

-- EN TANT QU'utilisateur lizmap
--

-- Créer un schéma pour y importer les données
CREATE SCHEMA IF NOT EXISTS occtax_production;

-- Référencer le serveur externe
CREATE SERVER bdd_production
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', dbname 'lizmap', port '5432');

-- Préciser l'utilisateur qui se connecte (lien entre user local et user distant)
-- on utilise naturaliz car seulement en lecture
CREATE USER MAPPING
FOR lizmap
SERVER bdd_production
OPTIONS (user 'naturaliz', password '*******');

-- Créer des tables étrangères
-- PostgreSQL permet d'importer automatiquement la structure des tables
-- On peut limiter les tables à récupérer
IMPORT FOREIGN SCHEMA occtax
LIMIT TO (observation, validation_observation)
FROM SERVER bdd_production INTO occtax_production;

-- Tester
SELECT count(cle_obs) FROM occtax_production.observation;

-- Pour supprimer
DROP SERVER bdd_production CASCADE;
