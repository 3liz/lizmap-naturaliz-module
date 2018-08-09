BEGIN;

-- Ajout des droits sur les objets de la base pour naturaliz
GRANT CONNECT ON DATABASE {$DBNAME} TO {$DBUSER_READONLY};
GRANT USAGE ON SCHEMA public,taxon,sig,occtax,gestion TO {$DBUSER_READONLY};
GRANT SELECT ON ALL TABLES IN SCHEMA occtax,sig,taxon,gestion TO {$DBUSER_READONLY};
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO {$DBUSER_READONLY};
GRANT INSERT ON ALL TABLES IN SCHEMA occtax TO {$DBUSER_READONLY};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public,occtax,sig,taxon,gestion TO {$DBUSER_READONLY};
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public,occtax,sig,taxon,gestion TO {$DBUSER_READONLY};
ALTER ROLE {$DBUSER_READONLY} SET search_path TO taxon,occtax,gestion,sig,public;

-- Ajout des droits sur les objets de la base pour lizmap
GRANT CONNECT ON DATABASE {$DBNAME} TO {$DBUSER_OWNER};
GRANT ALL PRIVILEGES ON SCHEMA public,taxon,sig,occtax,gestion TO {$DBUSER_OWNER};
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public,taxon,sig,occtax,gestion TO {$DBUSER_OWNER};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public,occtax,sig,taxon,gestion TO {$DBUSER_OWNER};
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public,occtax,sig,taxon,gestion TO {$DBUSER_OWNER};
ALTER ROLE {$DBUSER_OWNER} SET search_path TO taxon,occtax,gestion,sig,public;

COMMIT;
