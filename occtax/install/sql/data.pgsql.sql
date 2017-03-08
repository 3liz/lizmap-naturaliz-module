SET search_path TO occtax,public,pg_catalog;

TRUNCATE TABLE nomenclature;

-- role_personne
INSERT INTO nomenclature VALUES ('role_personne', 'Obs', 'Observateur', NULL);
INSERT INTO nomenclature VALUES ('role_personne', 'Det', 'Déterminateur', NULL);
INSERT INTO nomenclature VALUES ('role_personne', 'Val', 'Validateur', NULL);

-- statut_source
INSERT INTO nomenclature VALUES ('statut_source', 'Te', 'Terrain', 'l’observation provient directement d’une base de données ou d’un document issu de la
prospection sur le terrain');
INSERT INTO nomenclature VALUES ('statut_source', 'Co', 'Collection', 'l’observation concerne une base de données de collection');
INSERT INTO nomenclature VALUES ('statut_source', 'Li', 'Littérature', 'l’observation a été extraite d’un article ou un ouvrage scientifique');
INSERT INTO nomenclature VALUES ('statut_source', 'NSP', 'Ne Sait Pas', 'la source est inconue');

-- ds_publique
INSERT INTO nomenclature VALUES ('ds_publique', 'Pu', 'Publique', 'La Donnée Source est publique qu’elle soit produite en « régie » ou « acquise »');
INSERT INTO nomenclature VALUES ('ds_publique', 'Re', 'Publique Régie', 'La Donnée Source est publique et a été produite directement par un organisme ayant autorité publique avec ses moyens humains et techniques propres.');
INSERT INTO nomenclature VALUES ('ds_publique', 'Ac', 'Publique Acquise', 'La donnée-source a été produite par un organisme privé (associations, bureaux d’étude...) ou une personne physique à titre personnel. Les droits patrimoniaux exclusifs ou non exclusifs, de copie, traitement et diffusion sans limitation ont été acquis à titre gracieux ou payant, sur marché ou par convention, par un organisme ayant autorité publique. La donnée-source est devenue publique.');
INSERT INTO nomenclature VALUES ('ds_publique', 'Pr', 'Privée', 'La Donnée Source a été produite par un organisme privé ou un individu à titre personnel. Aucun organisme ayant autorité publique n’a acquis les droits patrimoniaux, la Donnée Source reste la propriété de l’organisme ou de l’individu privé. Seul ce cas autorise un floutage géographique de la DEE');
INSERT INTO nomenclature VALUES ('ds_publique', 'NSP', 'Ne sait pas', 'L’information indiquant si la Donnée Source est publique ou privée n’est pas connue.');

-- statut_observation
INSERT INTO nomenclature VALUES ('statut_observation', 'Pr', 'Présent', 'Un ou plusieurs individus du taxon ont étéeffectivement observés et/ou des indices témoignant de la présence du taxon');
INSERT INTO nomenclature VALUES ('statut_observation', 'No', 'Non Observé', 'L’observateur n’a pas détecté un taxon particulier, recherché suivant le protocole adéquat à la localisation et à la date de l’observation. Le taxon peut être présent et non vu, temporairement absent, ou réellement absent.');

-- code_sensible
INSERT INTO nomenclature VALUES ('code_sensible', '4', 'Aucune diffusion (cas exceptionnel)', '');
INSERT INTO nomenclature VALUES ('code_sensible', '3', 'Département seulement', '');
INSERT INTO nomenclature VALUES ('code_sensible', '2', 'Département et maille 10x10 km', '');
INSERT INTO nomenclature VALUES ('code_sensible', '1', 'Département, maille, espace, commune, Znieff', '');
INSERT INTO nomenclature VALUES ('code_sensible', '0', 'Précision maximale telle que saisie (non sensible). Statut par défaut.', '');

-- objet_denombrement
INSERT INTO nomenclature VALUES ('objet_denombrement', 'In', 'Individu', 'Dénombrement de chaque ...');
INSERT INTO nomenclature VALUES ('objet_denombrement', 'NSP', 'Ne Sait Pas', 'La méthode de dénombrement n’est pas connue');

-- type_denombrement
INSERT INTO nomenclature VALUES ('type_denombrement', 'Co', 'Compté', 'Dénombrement par énumération des individus');
INSERT INTO nomenclature VALUES ('type_denombrement', 'Es', 'Estimé', 'Dénombrement qualifié d’estimé lorsque le produit concerné n’a fait l’objet d’aucune action de détermination de cette valeur du paramètre par le biais d’une technique de mesure.');
INSERT INTO nomenclature VALUES ('type_denombrement', 'Ca', 'Calculé', 'Dénombrement par opération mathématique');
INSERT INTO nomenclature VALUES ('type_denombrement', 'NSP', 'Ne Sait Pas', 'La méthode de dénombrement n’est pas connue');

-- nature_objet_geo
INSERT INTO nomenclature VALUES ('nature_objet_geo', 'St', 'Stationnel', 'Le taxon observé est présent sur l’ensemble de l’objet géographique');
INSERT INTO nomenclature VALUES ('nature_objet_geo', 'In', 'Inventoriel', 'Le taxon observé est présent quelque part dans l’objet géographique');
INSERT INTO nomenclature VALUES ('nature_objet_geo', 'NSP', 'Ne Sait Pas', 'L’information est inconnue');

-- type_en
INSERT INTO nomenclature VALUES ('type_en', 'CPN', 'Coeur de parc national', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'AAPN', 'Aire d’adhésion de parc national', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'RIPN', 'Réserve intégrale de parc national', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'PNM', 'Parc naturel marin', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'PNR', 'Parc naturel régional', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'RNN', 'Réserve naturelle nationale', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'RNC', 'Réserve naturelle de Corse', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'RNR', 'Réserve naturelle régionale', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'PRN', 'Périmètre de protection de réserve naturelle', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'RBD', 'Réserve biologique', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'RBI', 'Réserve biologique intégrale', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'RNCFS', 'Réserve nationale de chasse et faune sauvage', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'RCFS', 'Réserve de chasse et de faune sauvage', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'APB', 'Arrêté de protection de biotope', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'MAB', 'Réserve de biosphère (Man and Biosphère)', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'SCL', 'Site du Conservatoire du littoral', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'RAMSAR', 'Site Ramsar Zone humide d’importance internationale', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'ASPIM', 'Aire spécialement protégée d’importance méditerranéenne', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'SCEN', 'Site de Conservatoire d’espaces naturels', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'ENS', 'Espace naturel sensible', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'OSPAR', 'Zone marine protégée de la convention OSPAR', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'APIA', 'Zone protégée de la convention d’Apia', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'CARTH', 'Zone protégée de la convention de Carthagène', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'ANTAR', 'Zone protégée du Traité de l’Antarctique', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'NAIRO', 'Zone spécialement protégée de la convention de Nairobi', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'ZHAE', 'Zone humide acquise par une Agence de l’eau', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'BPM', 'Bien inscrit sur la liste du patrimoine mondial de l’UNESCO', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'N2000', 'Natura 2000', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'ZNIEFF1', 'Zone Naturelle d’Intérêt Ecologique Faunistique et Floristique type 1', NULL);
INSERT INTO nomenclature VALUES ('type_en', 'ZNIEFF2', 'Zone Naturelle d’Intérêt Ecologique Faunistique et Floristique type 2', NULL);

-- validite_niveau
INSERT INTO nomenclature VALUES ('validite_niveau', '1', 'Certain', NULL);
INSERT INTO nomenclature VALUES ('validite_niveau', '2', 'Probable', NULL);
INSERT INTO nomenclature VALUES ('validite_niveau', '3', 'Douteux', NULL);
INSERT INTO nomenclature VALUES ('validite_niveau', '4', 'Invalide', NULL);
INSERT INTO nomenclature VALUES ('validite_niveau', '5', 'Non réalisable', NULL);
INSERT INTO nomenclature VALUES ('validite_niveau', '6', 'Non évalué', NULL);
