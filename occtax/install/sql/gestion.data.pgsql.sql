
TRUNCATE gestion.g_nomenclature RESTART IDENTITY;

INSERT INTO gestion.g_nomenclature VALUES ('type_demande', 'EI', 'Étude d''impact', NULL, 1);
INSERT INTO gestion.g_nomenclature VALUES ('type_demande', 'MR', 'Mission régalienne', NULL, 2);
INSERT INTO gestion.g_nomenclature VALUES ('type_demande', 'GM', 'Gestion des milieux naturels', NULL, 3);
INSERT INTO gestion.g_nomenclature VALUES ('type_demande', 'SC', 'Sensibilisation et communication', NULL, 4);
INSERT INTO gestion.g_nomenclature VALUES ('type_demande', 'PS', 'Publication scientifique', NULL, 5);
INSERT INTO gestion.g_nomenclature VALUES ('type_demande', 'AP', 'Accès producteur', NULL, 6);
INSERT INTO gestion.g_nomenclature VALUES ('type_demande', 'AT', 'Accès tête de réseau', NULL, 7);
INSERT INTO gestion.g_nomenclature VALUES ('type_demande', 'CO', 'Conservation', NULL, 8);
INSERT INTO gestion.g_nomenclature VALUES ('type_demande', 'AU', 'Autre', NULL, 9);

INSERT INTO gestion.g_nomenclature VALUES ('civilite', 'M', 'Monsieur', NULL, 1);
INSERT INTO gestion.g_nomenclature VALUES ('civilite', 'Mme', 'Madame', NULL, 2);
INSERT INTO gestion.g_nomenclature VALUES ('civilite', 'Mlle', 'Mademoiselle', NULL, 3);

INSERT INTO gestion.g_nomenclature VALUES ('statut_adhesion', 'Pré-adhérent', 'Pré-adhérent', NULL, 1);
INSERT INTO gestion.g_nomenclature VALUES ('statut_adhesion', 'Adhérent', 'Adhérent', NULL, 2);
INSERT INTO gestion.g_nomenclature VALUES ('statut_adhesion', 'Adhésion résiliée', 'Adhésion résiliée', NULL, 3);
INSERT INTO gestion.g_nomenclature VALUES ('statut_adhesion', 'Adhérent exclu', 'Adhérent exclu', NULL, 4);

INSERT INTO gestion.g_nomenclature VALUES ('statut_demande', 'A traiter', 'A traiter', NULL, 1);
INSERT INTO gestion.g_nomenclature VALUES ('statut_demande', 'Acceptée', 'Acceptée', NULL, 2);
INSERT INTO gestion.g_nomenclature VALUES ('statut_demande', 'Refusée', 'Refusée', NULL, 3);

INSERT INTO gestion.g_nomenclature VALUES ('type_echange_inpn', 'Import', 'Import', NULL, 1);
INSERT INTO gestion.g_nomenclature VALUES ('type_echange_inpn', 'Export', 'Export', NULL, 2);
