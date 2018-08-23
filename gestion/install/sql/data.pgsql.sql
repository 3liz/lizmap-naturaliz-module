SET search_path TO gestion,public,pg_catalog;
-- civilite_perso

TRUNCATE g_nomenclature RESTART IDENTITY;

INSERT INTO g_nomenclature VALUES ('type_demande', 'EI', 'Étude d''impact', NULL, 1);
INSERT INTO g_nomenclature VALUES ('type_demande', 'MR', 'Mission régalienne', NULL, 2);
INSERT INTO g_nomenclature VALUES ('type_demande', 'GM', 'Gestion des milieux naturels', NULL, 3);
INSERT INTO g_nomenclature VALUES ('type_demande', 'SC', 'Sensibilisation et communication', NULL, 4);
INSERT INTO g_nomenclature VALUES ('type_demande', 'PS', 'Publication scientifique', NULL, 5);
INSERT INTO g_nomenclature VALUES ('type_demande', 'AP', 'Accès producteur', NULL, 6);
INSERT INTO g_nomenclature VALUES ('type_demande', 'AT', 'Accès tête de réseau', NULL, 7);
INSERT INTO g_nomenclature VALUES ('type_demande', 'CO', 'Conservation', NULL, 8);
INSERT INTO g_nomenclature VALUES ('type_demande', 'AU', 'Autre', NULL, 9);
