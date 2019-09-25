BEGIN;

-- Ajout des droits sur les objets de la base pour naturaliz
GRANT USAGE ON SCHEMA public,taxon,sig,occtax,stats,gestion TO "naturaliz";
GRANT SELECT ON ALL TABLES IN SCHEMA occtax,stats,sig,taxon,gestion TO "naturaliz";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "naturaliz";
GRANT INSERT ON ALL TABLES IN SCHEMA occtax TO "naturaliz";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public,occtax,stats,sig,taxon,gestion TO "naturaliz";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public,occtax,stats,sig,taxon,gestion TO "naturaliz";
ALTER ROLE "naturaliz" SET search_path TO taxon,occtax,stats,gestion,sig,public;

-- Ajout des droits sur les objets de la base pour lizmap
GRANT ALL PRIVILEGES ON SCHEMA public,taxon,sig,occtax,stats,gestion TO "lizmap";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public,taxon,sig,occtax,stats,gestion TO "lizmap";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public,occtax,stats,sig,taxon,gestion TO "lizmap";
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public,occtax,stats,sig,taxon,gestion TO "lizmap";
ALTER ROLE "lizmap" SET search_path TO taxon,occtax,stats,gestion,sig,public;

COMMIT;
