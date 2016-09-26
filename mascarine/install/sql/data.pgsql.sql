SET search_path TO mascarine,public,pg_catalog;
-- civilite_perso
INSERT INTO m_nomenclature VALUES ('civilite_perso', 'M', 'Monsieur', NULL, 1);
INSERT INTO m_nomenclature VALUES ('civilite_perso', 'F', 'Madame, Mademoiselle', NULL, 2);

-- ref_habitat
INSERT INTO m_nomenclature VALUES ('ref_habitat', 'PVF', 'Prodrome des végétations de France', NULL, 1);
INSERT INTO m_nomenclature VALUES ('ref_habitat', 'BRYOSOCIO', 'Synopsis bryosociologique', NULL, 2);
INSERT INTO m_nomenclature VALUES ('ref_habitat', 'BBMEDFR', 'biocénoses benthiques de Méditerranée', NULL, 3);
INSERT INTO m_nomenclature VALUES ('ref_habitat', 'PALSPM', 'Habitats de St Pierre et Miquelon', NULL, 4);
INSERT INTO m_nomenclature VALUES ('ref_habitat', 'ANTMER,', 'Habitats marins des départements d’outre-mer Antilles', NULL, 5);
INSERT INTO m_nomenclature VALUES ('ref_habitat', 'GUYMER,', 'Habitats marins des départements d’outre-mer Guyanne', NULL, 6);
INSERT INTO m_nomenclature VALUES ('ref_habitat', 'REUMER', 'Habitats marins des départements d’outre-mer Réunion', NULL, 7);
INSERT INTO m_nomenclature VALUES ('ref_habitat', 'CORINEBIOTOPES', 'CORINE Biotopes', NULL, 8);
INSERT INTO m_nomenclature VALUES ('ref_habitat', 'PAL', 'Classification paléarctique', NULL, 9);
INSERT INTO m_nomenclature VALUES ('ref_habitat', 'EUNIS', 'EUNIS Habitas', NULL, 10);
INSERT INTO m_nomenclature VALUES ('ref_habitat', 'GMRC', 'Géomorphologie des récifs coralliens', NULL, 11);
INSERT INTO m_nomenclature VALUES ('ref_habitat', 'CH', 'Cahier d’habitat', NULL, 12);
INSERT INTO m_nomenclature VALUES ('ref_habitat', 'OSPAR', 'Convention OSPAR', NULL, 13);
INSERT INTO m_nomenclature VALUES ('ref_habitat', 'BARC', 'Convention de Barcelone', NULL, 14);
INSERT INTO m_nomenclature VALUES ('ref_habitat', 'REBENT', 'Habitat benthique côtier (Bretagne)', NULL, 15);

-- type_obs
INSERT INTO m_nomenclature VALUES ('type_obs', 'MIG', 'MIG', NULL, 1);
INSERT INTO m_nomenclature VALUES ('type_obs', 'BIG', 'BIG', NULL, 2);
INSERT INTO m_nomenclature VALUES ('type_obs', 'BIC', 'BIC', NULL, 3);
INSERT INTO m_nomenclature VALUES ('type_obs', 'BIH', 'BIH', NULL, 4);
INSERT INTO m_nomenclature VALUES ('type_obs', 'ORC', 'Orchidées', NULL, 5);

-- nature_obs
INSERT INTO m_nomenclature VALUES ('nature_obs', 'N', 'Normalisé', NULL, 1);
INSERT INTO m_nomenclature VALUES ('nature_obs', 'B', 'Bibliographie', NULL, 2);
INSERT INTO m_nomenclature VALUES ('nature_obs', 'M', 'Manuscrit non normalisé', NULL, 3);
INSERT INTO m_nomenclature VALUES ('nature_obs', 'I', 'Informatique', NULL, 4);

-- forme_obs
INSERT INTO m_nomenclature VALUES ('forme_obs', 'G', 'Générale', NULL, 1);
INSERT INTO m_nomenclature VALUES ('forme_obs', 'S', 'Spécialisée', NULL, 2);
INSERT INTO m_nomenclature VALUES ('forme_obs', 'P', 'Partielle', NULL, 3);

-- role_perso_obs
INSERT INTO m_nomenclature VALUES ('role_perso_obs', 'Re', 'Rédacteur', NULL, 1);
INSERT INTO m_nomenclature VALUES ('role_perso_obs', 'P', 'Observateur principal', NULL, 2);
INSERT INTO m_nomenclature VALUES ('role_perso_obs', 'S', 'Observateur secondaire', NULL, 3);
INSERT INTO m_nomenclature VALUES ('role_perso_obs', 'A', 'Accompagnateur', NULL, 4);
INSERT INTO m_nomenclature VALUES ('role_perso_obs', 'D', 'Découvreur', NULL, 5);
INSERT INTO m_nomenclature VALUES ('role_perso_obs', 'Ra', 'Rapporteur', NULL, 6);

-- code_milieu
INSERT INTO m_nomenclature VALUES ('code_milieu', 'crête', 'Crête', NULL, 1);
INSERT INTO m_nomenclature VALUES ('code_milieu', 'route', 'Route', NULL, 2);
INSERT INTO m_nomenclature VALUES ('code_milieu', 'cours d''eau', 'Cours d''eau', NULL, 3);
INSERT INTO m_nomenclature VALUES ('code_milieu', 'étang', 'Etang', NULL, 4);
INSERT INTO m_nomenclature VALUES ('code_milieu', 'chablis', 'Chablis', NULL, 5);
INSERT INTO m_nomenclature VALUES ('code_milieu', 'autre', 'Autre milieu', NULL, 6);

-- strate_flore
INSERT INTO m_nomenclature VALUES ('strate_flore', '-', 'Toute strate', NULL, 0);
INSERT INTO m_nomenclature VALUES ('strate_flore', 'A', 'Strate arborée haute > 7m', NULL, 1);
INSERT INTO m_nomenclature VALUES ('strate_flore', 'a1', 'Strate arbustive haute > 4m', NULL, 2);
INSERT INTO m_nomenclature VALUES ('strate_flore', 'a2', 'Strate arbustive basse > 1.5m', NULL, 3);
INSERT INTO m_nomenclature VALUES ('strate_flore', 'H', 'Strate herbacée < 1.5m', NULL, 4);
INSERT INTO m_nomenclature VALUES ('strate_flore', 'E', 'Strate épiphytique', NULL, 5);
INSERT INTO m_nomenclature VALUES ('strate_flore', 'M', 'Strate muscinale', NULL, 6);
INSERT INTO m_nomenclature VALUES ('strate_flore', 'T', 'Strate terrestre', NULL, 7);
INSERT INTO m_nomenclature VALUES ('strate_flore', 'R', 'Strate épilithique', NULL, 8);

-- statut_local_flore
INSERT INTO m_nomenclature VALUES ('statut_local_flore', 'W', 'W', NULL, 1);
INSERT INTO m_nomenclature VALUES ('statut_local_flore', 'P', 'P', NULL, 2);

-- ad_standard_flore
INSERT INTO m_nomenclature VALUES ('ad_standard_flore', 'p', 'p', NULL, 1);
INSERT INTO m_nomenclature VALUES ('ad_standard_flore', '+', '+', NULL, 2);
INSERT INTO m_nomenclature VALUES ('ad_standard_flore', '1', '1', NULL, 3);
INSERT INTO m_nomenclature VALUES ('ad_standard_flore', '2', '2', NULL, 4);
INSERT INTO m_nomenclature VALUES ('ad_standard_flore', '3', '3', NULL, 5);
INSERT INTO m_nomenclature VALUES ('ad_standard_flore', '4', '4', NULL, 6);
INSERT INTO m_nomenclature VALUES ('ad_standard_flore', '5', '5', NULL, 7);
INSERT INTO m_nomenclature VALUES ('ad_standard_flore', 'r', 'r', NULL, 8);
INSERT INTO m_nomenclature VALUES ('ad_standard_flore', 'i', 'i', NULL, 9);

-- dev_pheno_flore
INSERT INTO m_nomenclature VALUES ('dev_pheno_flore', 'A', 'Adulte', NULL, 1);
INSERT INTO m_nomenclature VALUES ('dev_pheno_flore', 'J', 'Juvénile', NULL, 2);
INSERT INTO m_nomenclature VALUES ('dev_pheno_flore', 'Pl', 'Plantule', NULL, 3);
INSERT INTO m_nomenclature VALUES ('dev_pheno_flore', 'G', 'Germination', NULL, 4);

-- pheno_flore
INSERT INTO m_nomenclature VALUES ('pheno_flore', 'Fr', 'Fructification', NULL, 1);
INSERT INTO m_nomenclature VALUES ('pheno_flore', 'B', 'Bouton', NULL, 2);
INSERT INTO m_nomenclature VALUES ('pheno_flore', 'S', 'Scénescent', NULL, 3);
INSERT INTO m_nomenclature VALUES ('pheno_flore', 'Fl', 'Floraison', NULL, 4);
INSERT INTO m_nomenclature VALUES ('pheno_flore', 'D', 'Dissémination', NULL, 5);
INSERT INTO m_nomenclature VALUES ('pheno_flore', 'V', 'Végétatif', NULL, 6);
INSERT INTO m_nomenclature VALUES ('pheno_flore', 'Fc', 'Feuilles caduques', NULL, 7);
INSERT INTO m_nomenclature VALUES ('pheno_flore', 'Fe', 'Fertile', NULL, 8);

-- stade_pheno_flore
INSERT INTO m_nomenclature VALUES ('stade_pheno_flore', '1', 'Début', NULL, 1);
INSERT INTO m_nomenclature VALUES ('stade_pheno_flore', '2', 'Pleine', NULL, 2);
INSERT INTO m_nomenclature VALUES ('stade_pheno_flore', '3', 'Fin', NULL, 3);
INSERT INTO m_nomenclature VALUES ('stade_pheno_flore', 'Td', 'Tiges desséchées', NULL, 4);

-- classe_pop_flore
INSERT INTO m_nomenclature VALUES ('classe_pop_flore', 'A', ' Adulte', NULL, 1);
INSERT INTO m_nomenclature VALUES ('classe_pop_flore', 'J', 'Juvénile', NULL, 2);
INSERT INTO m_nomenclature VALUES ('classe_pop_flore', 'Pl', 'Plantule', NULL, 3);
INSERT INTO m_nomenclature VALUES ('classe_pop_flore', 'G', 'Germination', NULL, 4);

-- exposition_station
INSERT INTO m_nomenclature VALUES ('exposition_station', 'N', 'N', NULL, NULL);
INSERT INTO m_nomenclature VALUES ('exposition_station', 'NE', 'NE', NULL, NULL);
INSERT INTO m_nomenclature VALUES ('exposition_station', 'E', 'E', NULL, NULL);
INSERT INTO m_nomenclature VALUES ('exposition_station', 'SE', 'SE', NULL, NULL);
INSERT INTO m_nomenclature VALUES ('exposition_station', 'S', 'S', NULL, NULL);
INSERT INTO m_nomenclature VALUES ('exposition_station', 'SO', 'SO', NULL, NULL);
INSERT INTO m_nomenclature VALUES ('exposition_station', 'O', 'O', NULL, NULL);
INSERT INTO m_nomenclature VALUES ('exposition_station', 'NO', 'NO', NULL, NULL);
INSERT INTO m_nomenclature VALUES ('exposition_station', 'ONO', 'ONO', NULL, NULL);
INSERT INTO m_nomenclature VALUES ('exposition_station', 'OSO', 'OSO', NULL, NULL);
INSERT INTO m_nomenclature VALUES ('exposition_station', 'SSO', 'SSO', NULL, NULL);
INSERT INTO m_nomenclature VALUES ('exposition_station', 'SSE', 'SSE', NULL, NULL);
INSERT INTO m_nomenclature VALUES ('exposition_station', 'ESE', 'ESE', NULL, NULL);
INSERT INTO m_nomenclature VALUES ('exposition_station', 'ENE', 'ENE', NULL, NULL);
INSERT INTO m_nomenclature VALUES ('exposition_station', 'NNE', 'NNE', NULL, NULL);

-- lumiere_station
INSERT INTO m_nomenclature VALUES ('lumiere_station', '1', 'Ouvert', NULL, 1);
INSERT INTO m_nomenclature VALUES ('lumiere_station', '2', 'Semi-ombragé', NULL, 2);
INSERT INTO m_nomenclature VALUES ('lumiere_station', '3', 'Ombragé', NULL, 3);

-- aire_unit_station
INSERT INTO m_nomenclature VALUES ('aire_unit_station', 'm2', 'm²', NULL, 1);
INSERT INTO m_nomenclature VALUES ('aire_unit_station', 'ha', 'ha', NULL, 2);

-- type_menace
INSERT INTO m_nomenclature VALUES ('type_menace', '1', 'Aménagements, entretien', NULL, 1);
INSERT INTO m_nomenclature VALUES ('type_menace', '2', 'Coulées volcaniques', NULL, 2);
INSERT INTO m_nomenclature VALUES ('type_menace', '3', 'Cyclone', NULL, 3);
INSERT INTO m_nomenclature VALUES ('type_menace', '4', 'Crue', NULL, 4);
INSERT INTO m_nomenclature VALUES ('type_menace', '5', 'Erosion, éboulis', NULL, 5);
INSERT INTO m_nomenclature VALUES ('type_menace', '6', 'Eutrophisation', NULL, 6);
INSERT INTO m_nomenclature VALUES ('type_menace', '7', 'Invasions EEE', NULL, 7);
INSERT INTO m_nomenclature VALUES ('type_menace', '8', 'Menaces faune / Parasitisme', NULL, 8);
INSERT INTO m_nomenclature VALUES ('type_menace', '9', 'Remblais', NULL, 9);
INSERT INTO m_nomenclature VALUES ('type_menace', '10', 'Surexploitation, braconnage, cueillette', NULL, 10);
INSERT INTO m_nomenclature VALUES ('type_menace', '11', 'Surfréquentation, piétinement', NULL, 11);
INSERT INTO m_nomenclature VALUES ('type_menace', '12', 'Incendies', NULL, 12);
INSERT INTO m_nomenclature VALUES ('type_menace', '13', 'Activités agricoles, exploitation forestière', NULL, 13);

-- valeur_menace
INSERT INTO m_nomenclature VALUES ('valeur_menace', 'ND', 'Non déterminée', NULL, 1);
INSERT INTO m_nomenclature VALUES ('valeur_menace', 'NA', 'Non applicable', NULL, 2);
INSERT INTO m_nomenclature VALUES ('valeur_menace', 'FM', 'Faible à moyenne', NULL, 3);
INSERT INTO m_nomenclature VALUES ('valeur_menace', 'MF', 'Moyenne à forte', NULL, 4);
INSERT INTO m_nomenclature VALUES ('valeur_menace', 'F', 'Forte', NULL, 5);

-- statut_menace
INSERT INTO m_nomenclature VALUES ('statut_menace', 'A', 'Menace active', NULL, 1);
INSERT INTO m_nomenclature VALUES ('statut_menace', 'P', 'Menace potentielle', NULL, 2);

-- type_document
INSERT INTO m_nomenclature VALUES ('type_document', 'photo', 'Photo', NULL, 1);
INSERT INTO m_nomenclature VALUES ('type_document', 'croquis', 'Croquis, Schéma', NULL, 2);
INSERT INTO m_nomenclature VALUES ('type_document', 'scan', 'Scan bordereau', NULL, 3);
INSERT INTO m_nomenclature VALUES ('type_document', 'autre', 'Autre', NULL, 4);

-- Correspondance entre type_obs et code_idcnp_dispositif
INSERT INTO lien_type_mascarine_metadonnee_occtax VALUES ( 'BIC', 'KaruFlore', 'PNG-karuflore');
INSERT INTO lien_type_mascarine_metadonnee_occtax VALUES ( 'BIG', 'KaruFlore', 'PNG-karuflore');
INSERT INTO lien_type_mascarine_metadonnee_occtax VALUES ( 'BIH', 'KaruFlore', 'PNG-karuflore');
INSERT INTO lien_type_mascarine_metadonnee_occtax VALUES ( 'MIG', 'KaruFlore', 'PNG-karuflore');
INSERT INTO lien_type_mascarine_metadonnee_occtax VALUES ( 'ORC', 'Orchidées', 'PNG-orchidees');

-- Jeux de données occtax correspondants à mascarine
INSERT INTO occtax.jdd ( jdd_id, jdd_code, jdd_description ) VALUES ( 'PNG-orchidees', 'PNG Orchidées', 'Jeu de données Orchidées du Parc National de Guadeloupe');
INSERT INTO occtax.jdd ( jdd_id, jdd_code, jdd_description ) VALUES ( 'PNG-karuflore', 'PNG KaruFlore', 'Jeu de données KaruFlore du Parc National de Guadeloupe');


