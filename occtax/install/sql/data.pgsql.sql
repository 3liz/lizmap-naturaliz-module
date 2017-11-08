SET search_path TO occtax,public,pg_catalog;

TRUNCATE TABLE nomenclature;

-- role_personne
INSERT INTO nomenclature VALUES ('role_personne', 'Obs', 'Observateur', NULL);
INSERT INTO nomenclature VALUES ('role_personne', 'Det', 'Déterminateur', NULL);
INSERT INTO nomenclature VALUES ('role_personne', 'Val', 'Validateur', NULL);

-- code_sensible
INSERT INTO nomenclature VALUES ('code_sensible', '4', 'Aucune diffusion (cas exceptionnel)', '');
INSERT INTO nomenclature VALUES ('code_sensible', '3', 'Département seulement', '');
INSERT INTO nomenclature VALUES ('code_sensible', '2', 'Département et maille 10x10 km', '');
INSERT INTO nomenclature VALUES ('code_sensible', '1', 'Département, maille, espace, commune, Znieff', '');
INSERT INTO nomenclature VALUES ('code_sensible', '0', 'Précision maximale telle que saisie (non sensible). Statut par défaut.', '');

-- validite_niveau
INSERT INTO nomenclature VALUES ('validite_niveau', '1', 'Certain', NULL);
INSERT INTO nomenclature VALUES ('validite_niveau', '2', 'Probable', NULL);
INSERT INTO nomenclature VALUES ('validite_niveau', '3', 'Douteux', NULL);
INSERT INTO nomenclature VALUES ('validite_niveau', '4', 'Invalide', NULL);
INSERT INTO nomenclature VALUES ('validite_niveau', '5', 'Non réalisable', NULL);
INSERT INTO nomenclature VALUES ('validite_niveau', '6', 'Non évalué', NULL);


INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '0', 'Inconnu', 'Le stade de vie de l''individu n''est pas connu.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '1', 'Indéterminé', 'Le stade de vie de l''individu n''a pu être déterminé (observation insuffisante pour la détermination).');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '2', 'Adulte', 'L''individu est au stade adulte.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '3', 'Juvénile', 'L''individu n''a pas encore atteint le stade adulte. C''est un individu jeune.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '4', 'Immature', 'Individu n''ayant pas atteint sa maturité sexuelle.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '5', 'Sub-adulte', 'Individu ayant presque atteint la taille adulte mais qui n''est pas considéré en tant que tel par ses congénères.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '6', 'Larve', 'Individu dans l''état où il est en sortant de l''œuf, état dans lequel il passe un temps plus ou moins long avant métamorphose.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '7', 'Chenille', 'Larve éruciforme des lépidoptères ou papillons.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '8', 'Têtard', 'Larve de batracien.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '9', 'Œuf', 'L''individu se trouve dans un œuf, ou au sein d''un regroupement d''œufs (ponte)');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '10', 'Mue', 'L''individu est en cours de mue (pour les reptiles : renouvellement de la peau, pour les oiseaux/mammifères : renouvellement du plumage/pelage, pour les cervidés : chute des bois).');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '11', 'Exuvie', 'L''individu est en cours d''exuviation : l''exuvie est une enveloppe (cuticule chitineuse ou peau) que le corps de l''animal a quittée lors de la mue ou de la métamorphose.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '12', 'Chrysalide', 'Nymphe des lépidoptères ou papillons.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '13', 'Nymphe', 'Stade de développement intermédiaire, entre larve et imago, pendant lequel l''individu ne se nourrit pas.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '14', 'Pupe', 'Nymphe des diptères.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '15', 'Imago', 'Stade final d''un individu dont le développement se déroule en plusieurs phases (en général, œuf, larve, imago).');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '16', 'Sub-imago', 'Stade de développement chez certains insectess : insecte mobile, incomplet et sexuellement immature, bien qu''évoquant assez fortement la forme définitive de l''adulte, l''imago.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '17', 'Alevin', 'L''individu, un poisson, est à un stade juvénile.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '18', 'Germination', 'L''individu est en cours de germination.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '19', 'Fané', 'L''individu est altéré dans ses couleurs et sa fraîcheur, par rapport à un individu normal.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '20', 'Graine', 'La graine est la structure qui contient et protège l''embryon végétal.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '21', 'Thalle, protothalle', 'Un thalle est un appareil végétatif ne possédant ni feuilles, ni tiges, ni racines, produit par certains organismes non mobiles.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '22', 'Tubercule', 'Un tubercule est un organe de réserve, généralement souterrain, assurant la survie des plantes pendant la saison d''hiver ou en période de sécheresse, et souvent leur multiplication par voie végétative.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '23', 'Bulbe', 'Un bulbe est une pousse souterraine verticale disposant de feuilles modifiées utilisées comme organe de stockage de nourriture par une plante à dormance.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '24', 'Rhizome', 'Le rhizome est une tige souterraine et parfois subaquatique remplie de réserves alimentaires chez certaines plantes vivaces.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '25', 'Emergent', 'L''individu est au stade émergent : sortie de l''œuf.');
INSERT INTO nomenclature VALUES ('occ_stade_de_vie', '26', 'Post-Larve', 'Stade qui suit immédiatement celui de la larve et présente certains caractères du juvénile.');


INSERT INTO nomenclature VALUES ('occ_statut_biogeographique', '0', 'Inconnu/cryptogène', 'Individu dont le taxon a une aire d’origine inconnue qui fait qu''on ne peut donc pas dire s’il est indigène ou introduit.');
INSERT INTO nomenclature VALUES ('occ_statut_biogeographique', '1', 'Non renseigné', 'Individu pour lequel l''information n''a pas été renseignée.');
INSERT INTO nomenclature VALUES ('occ_statut_biogeographique', '2', 'Présent (indigène ou indéterminé)', 'Individu d''un taxon présent au sens large dans la zone géographique considérée, c''est-à-dire taxon indigène ou taxon dont on ne sait pas s’il appartient à l''une des autres catégories. Le défaut de connaissance profite donc à l’indigénat.  Par indigène on entend : taxon qui est issu de la zone géographique considérée et qui s’y est naturellement développé sans contribution humaine, ou taxon qui est arrivé là sans intervention humaine (intentionnelle ou non) à partir d’une zone dans laquelle il est indigène6.  (NB : exclut les hybrides dont l’un des parents au moins est introduit dans la zone considérée)  Sont regroupés sous ce statut tous les taxons catégorisés « natif » ou « autochtone ».  Les taxons hivernant quelques mois de l’année entrent dans cette catégorie.');
INSERT INTO nomenclature VALUES ('occ_statut_biogeographique', '3', 'Introduit', 'Taxon introduit (établi ou possiblement établi) au niveau local.  Par introduit on entend : taxon dont la présence locale est due à une intervention humaine, intentionnelle ou non, ou taxon qui est arrivé dans la zone sans intervention humaine mais à partir d’une zone dans laquelle il est introduit.  Par établi (terme pour la faune, naturalisé pour la flore) on entend : taxon introduit qui forme des populations viables (se reproduisant) et durables qui se maintiennent dans le milieu naturel sans besoin d’intervention humaine.  Sont regroupés sous ce statut tous les taxons catégorisés « non-indigène », « exotique », « exogène », « allogène », « allochtone », « non-natif », « naturalisé » dans une publication scientifique.');
INSERT INTO nomenclature VALUES ('occ_statut_biogeographique', '4', 'Introduit envahissant', 'Individu d''un taxon introduit  localement, qui produit des descendants fertiles souvent en grand nombre, et qui a le potentiel pour s''étendre de façon exponentielle sur une grande aire, augmentant ainsi rapidement son aire de répartition. Cela induit souvent des conséquences écologiques, économiques ou sanitaires négatives. Sont regroupés sous ce statut tous les individus de taxons catégorisés "introduits envahissants", "exotiques envahissants", ou "invasif".');
INSERT INTO nomenclature VALUES ('occ_statut_biogeographique', '5', 'Introduit non établi (dont domestique)', 'Individu dont le taxon est introduit, qui se reproduit occasionnellement hors de son aire de culture ou captivité, mais qui ne peut se maintenir à l''état sauvage.');
INSERT INTO nomenclature VALUES ('occ_statut_biogeographique', '6', 'Occasionnel', 'Individu dont le taxon est occasionnel, non nicheur, accidentel ou exceptionnel dans la zone géographique considérée (par exemple migrateur de passage), qui est locale.');


INSERT INTO nomenclature VALUES ('ref_habitat', 'ANTMER', 'ANTMER', 'Habitats marins des départements d''outre-mer des Antilles. Correspond à la typologie HABITATS_ANTILLES de HABREF. Préconisations : Si on utilise le fichier ANTMER présent sur le site de l''INPN : on utilise le code CD_HAB, que l''on inclura dans l''attribut codeHabitat, code métier de l''habitat, qui correspond au LB_CODE de HABREF. Si on utilise HABREF, on prendra le CD_HAB directement, que l''on reportera dans l''attribut codeHabRef.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'BARC', 'BARC', 'Convention de Barcelone. On utilisera le code CAR/ASP.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'BBMEDFR', 'BBMEDFR', 'Biocénoses benthiques de Méditerranée. On utilisera le CD_BBMEDFR de la liste typologique, correspondant au LB_CODE d''HABREF.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'BRYOSOCIO', 'BRYOSOCIO', 'Synopsis bryosociologique. On utilisera le CD_SYNTAXON de la liste typologique, correspondant au LB_CODE d''HABREF.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'CH', 'CH', 'Cahier d''habitat. On utilisera le CD_CH de la liste typologique, correspondant au LB_CODE d''HABREF.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'CORINEBIOTOPES', 'CORINEBIOTOPES', 'CORINE Biotopes. On utilisera le CD_CB de la liste typologique, correspondant au LB_CODE d''HABREF.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'EUNIS', 'EUNIS', 'EUNIS Habitats. On utilisera le CD_EUNIS de la liste typologique, correspondant au LB_CODE d''HABREF.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'GMRC', 'GMRC', 'Géomorphologie des récifs coralliens. On utilisera le CD_GMRC de la liste typologique, correspondant au LB_CODE d''HABREF.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'GUYMER', 'GUYMER', 'Habitats marins du département d''outre-mer de Guyane. Correspond à la typologie HABITATS_GUYANE de HABREF. On utilisera le CD_HAB de la liste typologique, correspondant au LB_CODE d''HABREF.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'HABITATS_MARINS_ATLANTIQUE', 'HABITATS_MARINS_ATLANTIQUE', 'Typologie des habitats marins benthiques de la Manche, de la Mer du Nord et de l''Atlantique. On utilisera le CD_HAB de HabRef, qu''on reportera dans l''attribut codeHabref.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'HABITATS_MARINS_DOM', 'HABITATS_MARINS_DOM', 'Typologie des habitats marins benthiques des DOM. On utilisera le CD_HAB de HabRef, qu''on reportera dans l''attribut codeHabref.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'HABITATS_MARINS_MEDITERRANNEE', 'HABITATS_MARINS_MEDITERRANNEE', 'Typologie des habitats marins benthiques de la Méditerrannée. On utilisera le CD_HAB de HabRef, qu''on reportera dans l''attribut codeHabref.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'HABREF', 'HABREF', 'Référentiel d''habitats et de végétation.  On utilisera le code CD_HAB extrait de HABREF, dans l''attribut codeHabRef.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'HIC', 'HIC', 'Liste hiérarchisée et descriptifs des habitats d''intérêt communautaire de la directive Habitats. On utilisera le code CD_HAB extrait de HABREF, dans l''attribut codeHabRef.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'OSPAR', 'OSPAR', 'Convention OSPAR. On utilisera la désignation de l''habitat dans la partie II.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'PAL', 'PAL', 'Classification paléarctique. On utilisera le CD_PAL. Correspond à la typologie PAL_PHYSIS_2001 de HABREF.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'PALSPM', 'PALSPM', 'Habitats de St Pierre et Miquelon. On utilisera le CD_PAL.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'PHYTO_CH', 'PHYTO_CH', 'Unités phytosociologiques des cahiers d''habitats. On utilisera le code CD_HAB extrait de HABREF, dans l''attribut codeHabRef.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'PVF', 'PVF', 'Prodrome des végétations de France. On utilisera le CD_PVF1.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'PVF1', 'PVF1', 'Prodrome des végétations de France. On utilisera le CD_PVF1.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'PVF2', 'PVF2', 'Prodrome des végétations de France. On utilisera le CD_PVF2.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'REBENT', 'REBENT', 'Habitat benthique côtier (Bretagne). On utilisera le libellé de niveau le plus fin qui corresponde à l''habitat constaté.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'REUMER', 'REUMER', 'Habitats marins du département d''outre-mer de La Réunion. Correspond à la typologie HABITATS_REUNION de HABREF. On utilisera le CD_HAB.');
INSERT INTO nomenclature VALUES ('ref_habitat', 'SYNSYSTEME_EUROPEEN', 'SYNSYSTEME_EUROPEEN', 'Classification phytosociologique européenne. On utilisera le code CD_HAB extrait de HABREF, dans l''attribut codeHabRef.');


INSERT INTO nomenclature VALUES ('occ_statut_biologique', '0', 'Inconnu', 'Inconnu : Le statut biologique de l''individu n''est pas connu.');
INSERT INTO nomenclature VALUES ('occ_statut_biologique', '1', 'Non renseigné', 'Non renseigné : Le statut biologique de l''individu n''a pas été renseigné.');
INSERT INTO nomenclature VALUES ('occ_statut_biologique', '2', 'Non Déterminé', 'Non déterminé : Le statut biologique de l''individu n''a pas pu être déterminé.');
INSERT INTO nomenclature VALUES ('occ_statut_biologique', '3', 'Reproduction', 'Reproduction : Le sujet d''observation en est au stade de reproduction (nicheur, gravide, carpophore, floraison, fructification…)');
INSERT INTO nomenclature VALUES ('occ_statut_biologique', '4', 'Hibernation', 'Hibernation : L’hibernation est un état d’hypothermie régulée, durant plusieurs jours ou semaines qui permet aux animaux de conserver leur énergie pendant l’hiver. ');
INSERT INTO nomenclature VALUES ('occ_statut_biologique', '5', 'Estivation', 'Estivation : L''estivation est un phénomène analogue à celui de l''hibernation, au cours duquel les animaux tombent en léthargie. L''estivation se produit durant les périodes les plus chaudes et les plus sèches de l''été.');
INSERT INTO nomenclature VALUES ('occ_statut_biologique', '6', 'Halte migratoire', 'Halte migratoire : Indique que l''individu procède à une halte au cours de sa migration, et a été découvert sur sa zone de halte.');
INSERT INTO nomenclature VALUES ('occ_statut_biologique', '7', 'Swarming', 'Swarming : Indique que l''individu a un comportement de swarming : il se regroupe avec d''autres individus de taille similaire, sur une zone spécifique, ou en mouvement.');
INSERT INTO nomenclature VALUES ('occ_statut_biologique', '8', 'Chasse / alimentation', 'Chasse / alimentation : Indique que l''individu est sur une zone qui lui permet de chasser ou de s''alimenter.');
INSERT INTO nomenclature VALUES ('occ_statut_biologique', '9', 'Pas de reproduction', 'Pas de reproduction : Indique que l''individu n''a pas un comportement reproducteur. Chez les végétaux : absence de fleurs, de fruits…');
INSERT INTO nomenclature VALUES ('occ_statut_biologique', '10', 'Passage en vol', 'Passage en vol : Indique que l''individu  est de passage et en vol.');
INSERT INTO nomenclature VALUES ('occ_statut_biologique', '11', 'Erratique', 'Erratique : Individu d''une ou de populations d''un taxon qui ne se trouve, actuellement, que de manière occasionnelle dans les limites d’une région. Il a été retenu comme seuil, une absence de 80% d''un laps de temps donné (année, saisons...).');
INSERT INTO nomenclature VALUES ('occ_statut_biologique', '12', 'Sédentaire', 'Sédentaire : Individu demeurant à un seul emplacement, ou restant toute l''année dans sa région d''origine, même s''il effectue des déplacements locaux.');


INSERT INTO nomenclature VALUES ('obs_methode', '0', 'Vu', 'Observation directe d''un individu vivant.');
INSERT INTO nomenclature VALUES ('obs_methode', '1', 'Entendu', 'Observation acoustique d''un individu vivant.');
INSERT INTO nomenclature VALUES ('obs_methode', '2', 'Coquilles d''œuf', 'Observation indirecte via coquilles d''œuf.');
INSERT INTO nomenclature VALUES ('obs_methode', '3', 'Ultrasons', 'Observation acoustique indirecte d''un individu vivant avec matériel spécifique permettant de transduire des ultrasons en sons perceptibles par un humain.');
INSERT INTO nomenclature VALUES ('obs_methode', '4', 'Empreintes', 'Observation indirecte via empreintes.');
INSERT INTO nomenclature VALUES ('obs_methode', '5', 'Exuvie', 'Observation indirecte : une exuvie.');
INSERT INTO nomenclature VALUES ('obs_methode', '6', 'Fèces/Guano/Epreintes', 'Observation indirecte par les excréments');
INSERT INTO nomenclature VALUES ('obs_methode', '7', 'Mues', 'Observation indirecte par des plumes, poils, phanères, peau, bois... issus d''une mue.');
INSERT INTO nomenclature VALUES ('obs_methode', '8', 'Nid/Gîte', 'Observation indirecte par présence d''un nid ou d''un gîte non occupé au moment de l''observation.');
INSERT INTO nomenclature VALUES ('obs_methode', '9', 'Pelote de réjection', 'Identifie l''espèce ayant produit la pelote de réjection.');
INSERT INTO nomenclature VALUES ('obs_methode', '10', 'Restes dans pelote de réjection', 'Identifie l''espèce à laquelle appartiennent les restes retrouvés dans la pelote de réjection (os ou exosquelettes, par exemple).');
INSERT INTO nomenclature VALUES ('obs_methode', '11', 'Poils/plumes/phanères', 'Observation indirecte de l''espèce par ses poils, plumes ou phanères, non nécessairement issus d''une mue.');
INSERT INTO nomenclature VALUES ('obs_methode', '12', 'Restes de repas', 'Observation indirecte par le biais de restes de l''alimentation de l''individu.');
INSERT INTO nomenclature VALUES ('obs_methode', '13', 'Spore', 'Identification d''un individu ou groupe d''individus d''un taxon par l''observation de spores, corpuscules unicellulaires ou pluricellulaires pouvant donner naissance sans fécondation à un nouvel individu. Chez les végétaux, corpuscules reproducteurs donnant des prothalles rudimentaires mâles et femelles (correspondant respectivement aux grains de pollen et au sac embryonnaire), dont les produits sont les gamètes.');
INSERT INTO nomenclature VALUES ('obs_methode', '14', 'Pollen', 'Observation indirecte d''un individu ou groupe d''individus d''un taxon par l''observation de pollen, poussière très fine produite dans les loges des anthères et dont chaque grain microscopique est un utricule ou petit sac membraneux contenant le fluide fécondant (d''apr. Bouillet 1859).');
INSERT INTO nomenclature VALUES ('obs_methode', '15', 'Oosphère', 'Observation indirecte. Cellule sexuelle femelle chez les végétaux qui, après sa fécondation, devient l''oeuf.');
INSERT INTO nomenclature VALUES ('obs_methode', '16', 'Ovule', 'Observation indirecte. Organe contenant le gamète femelle. Macrosporange des spermaphytes.');
INSERT INTO nomenclature VALUES ('obs_methode', '17', 'Fleur', 'Identification d''un individu ou groupe d''individus d''un taxon par l''observation  de fleurs. La fleur correspond à un ensemble de feuilles modifiées, en enveloppe florale et en organe sexuel, disposées sur un réceptacle. Un pédoncule la relie à la tige. (ex : chaton).');
INSERT INTO nomenclature VALUES ('obs_methode', '18', 'Feuille', 'Identification d''un individu ou groupe d''individus d''un taxon par l''observation  de feuilles. Organe aérien très important dans la nutrition de la plante, lieu de la photosynthèse qui aboutit à des composés organiques (sucres, protéines) formant la sève.');
INSERT INTO nomenclature VALUES ('obs_methode', '19', 'ADN environnemental', 'Séquence ADN trouvée dans un prélèvement environnemental (eau ou sol).');
INSERT INTO nomenclature VALUES ('obs_methode', '20', 'Autre', 'Pour tout cas qui ne rentrerait pas dans la présente liste. Le nombre d''apparitions permettra de faire évoluer la nomenclature.');
INSERT INTO nomenclature VALUES ('obs_methode', '21', 'Inconnu', 'Inconnu : La méthode n''est pas mentionnée dans les documents de l''observateur (bibliographie par exemple).');
INSERT INTO nomenclature VALUES ('obs_methode', '22', 'Mine', 'Galerie forée dans l''épaisseur d''une feuille, entre l''épiderme supérieur et l''épiderme inférieur par des larves');
INSERT INTO nomenclature VALUES ('obs_methode', '23', 'Galerie/terrier', 'Galerie forée dans le bois, les racines ou les tiges, par des larves (Lépidoptères, Coléoptères, Diptères) ou creusée dans la terre (micro-mammifères, mammifères... ).');
INSERT INTO nomenclature VALUES ('obs_methode', '24', 'Oothèque', 'Membrane-coque qui protège la ponte de certains insectes et certains mollusques.');
INSERT INTO nomenclature VALUES ('obs_methode', '25', 'Vu et entendu', 'Vu et entendu : l''occurrence a à la fois été vue et entendue.');


INSERT INTO nomenclature VALUES ('preuve_existante', '0', 'Inconnu', 'Indique que la personne ayant fourni la donnée ignore s''il existe une preuve, ou qu''il est indiqué dans la donnée qu''il y a eu une preuve qui a pu servir pour la détermination, sans moyen de le vérifier.');
INSERT INTO nomenclature VALUES ('preuve_existante', '1', 'Oui', 'Indique qu''une preuve existe ou a existé pour la détermination, et est toujours accessible.');
INSERT INTO nomenclature VALUES ('preuve_existante', '2', 'Non', 'Indique l''absence de preuve.');
INSERT INTO nomenclature VALUES ('preuve_existante', '3', 'Non acquise', 'NonAcquise : La donnée de départ mentionne une preuve, ou non, mais n''est pas suffisamment standardisée pour qu''il soit possible de récupérer des informations. L''information n''est donc pas acquise lors du transfert.');


INSERT INTO nomenclature VALUES ('sensi_niveau', '0', 'Maximale', 'Précision maximale telle que saisie (non sensible). Statut par défaut');
INSERT INTO nomenclature VALUES ('sensi_niveau', '1', 'Département, maille, espace, commune, ZNIEFF', 'Département, maille, espace, commune, ZNIEFF.');
INSERT INTO nomenclature VALUES ('sensi_niveau', '2', 'Département et maille 10 x 10 km', 'Département et maille 10 x 10 km.');
INSERT INTO nomenclature VALUES ('sensi_niveau', '3', 'Département seulement', 'Département seulement.');
INSERT INTO nomenclature VALUES ('sensi_niveau', '4', 'Aucune diffusion (cas exceptionnel)', 'Aucune diffusion (cas exceptionnel).');


INSERT INTO nomenclature VALUES ('sensible', 'NON', 'Non', 'Indique que la donnée n''est pas sensible (par défaut, équivalent au niveau "0" des niveaux de sensibilité).');
INSERT INTO nomenclature VALUES ('sensible', 'OUI', 'Oui', 'Indique que la donnée est sensible.');


INSERT INTO nomenclature VALUES ('statut_observation', 'No', 'Non observé', 'Non Observé : L''observateur n''a pas détecté un taxon particulier, recherché suivant le protocole adéquat à la localisation et à la date de l''observation. Le taxon peut être présent et non vu, temporairement absent, ou réellement absent.');
INSERT INTO nomenclature VALUES ('statut_observation', 'NSP', 'Ne Sait Pas', 'Ne Sait Pas : l''information n''est pas connue');
INSERT INTO nomenclature VALUES ('statut_observation', 'Pr', 'Présent', 'Présent : Un ou plusieurs individus du taxon ont été effectivement observés et/ou des indices témoignant de la présence du taxon');


INSERT INTO nomenclature VALUES ('statut_source', 'Co', 'Collection', 'Collection : l''observation concerne une base de données de collection.');
INSERT INTO nomenclature VALUES ('statut_source', 'Li', 'Littérature', 'Littérature : l''observation a été extraite d''un article ou un ouvrage scientifique.');
INSERT INTO nomenclature VALUES ('statut_source', 'NSP', 'Ne Sait Pas', 'Ne Sait Pas : la source est inconnue.');
INSERT INTO nomenclature VALUES ('statut_source', 'Te', 'Terrain', 'Terrain : l''observation provient directement d''une base de données ou d''un document issu de la prospection sur le terrain.');


INSERT INTO nomenclature VALUES ('type_aa', 'QTA', 'Quantitatif', 'Le paramètre est de type quantitatif : il peut être mesuré par une valeur numérique.    Exemples : âge précis, taille, nombre de cercles ligneux...');
INSERT INTO nomenclature VALUES ('type_aa', 'QUAL', 'Qualitatif', 'Le paramètre est de type qualitatif : Il décrit une qualité qui ne peut être définie par une quantité numérique.     Exemples : individu âgé / individu jeune, eau trouble, milieu clairsemé…');


INSERT INTO nomenclature VALUES ('type_denombrement', 'Ca', 'Calculé', 'Calculé : Dénombrement par opération mathématique');
INSERT INTO nomenclature VALUES ('type_denombrement', 'Co', 'Compté', 'Compté : Dénombrement par énumération des individus');
INSERT INTO nomenclature VALUES ('type_denombrement', 'Es', 'Estimé', 'Estimé : Dénombrement qualifié d’estimé lorsque le produit concerné n''a fait l''objet d''aucune action de détermination de cette valeur du paramètre par le biais d''une technique de mesure.');
INSERT INTO nomenclature VALUES ('type_denombrement', 'NSP', 'Ne sait pas', 'Ne sait Pas : La méthode de dénombrement n’est pas connue');


INSERT INTO nomenclature VALUES ('type_en', 'AAPN', 'AAPN', 'Aire d’adhésion de parc national');
INSERT INTO nomenclature VALUES ('type_en', 'ANTAR', 'ANTAR', 'Zone protégée du Traité de l''Antarctique');
INSERT INTO nomenclature VALUES ('type_en', 'APB', 'APB', 'Arrêté de protection de biotope');
INSERT INTO nomenclature VALUES ('type_en', 'APIA', 'APIA', 'Zone protégée de la convention d''Apia');
INSERT INTO nomenclature VALUES ('type_en', 'ASPIM', 'ASPIM', 'Aire spécialement protégée d’importance méditerranéenne');
INSERT INTO nomenclature VALUES ('type_en', 'BPM', 'BPM', 'Bien inscrit sur la liste du patrimoine mondial de l''UNESCO');
INSERT INTO nomenclature VALUES ('type_en', 'CARTH', 'CARTH', 'Zone protégée de la convention de Carthagène');
INSERT INTO nomenclature VALUES ('type_en', 'CNP', 'CNP', 'Coeur de parc national. Valeur gelée le 15/06/2016 et remplacée par "CPN"');
INSERT INTO nomenclature VALUES ('type_en', 'ENS', 'ENS', 'Espace naturel sensible');
INSERT INTO nomenclature VALUES ('type_en', 'MAB', 'MAB', 'Réserve de biosphère (Man and Biosphère)');
INSERT INTO nomenclature VALUES ('type_en', 'N2000', 'N2000', 'Natura 2000');
INSERT INTO nomenclature VALUES ('type_en', 'NAIRO', 'NAIRO', 'Zone spécialement protégée de la convention de Nairobi');
INSERT INTO nomenclature VALUES ('type_en', 'OSPAR', 'OSPAR', 'Zone marine protégée de la convention OSPAR');
INSERT INTO nomenclature VALUES ('type_en', 'PNM', 'PNM', 'Parc naturel marin');
INSERT INTO nomenclature VALUES ('type_en', 'PNR', 'PNR', 'Parc naturel régional');
INSERT INTO nomenclature VALUES ('type_en', 'PRN', 'PRN', 'Périmètre de protection de réserve naturelle');
INSERT INTO nomenclature VALUES ('type_en', 'RAMSAR', 'RAMSAR', 'Site Ramsar : Zone humide d''importance internationale');
INSERT INTO nomenclature VALUES ('type_en', 'RBD', 'RBD', 'Réserve biologique');
INSERT INTO nomenclature VALUES ('type_en', 'RBI', 'RBI', 'Réserve biologique intégrale');
INSERT INTO nomenclature VALUES ('type_en', 'RCFS', 'RCFS', 'Réserve de chasse et de faune sauvage');
INSERT INTO nomenclature VALUES ('type_en', 'RIPN', 'RIPN', 'Réserve intégrale de parc national');
INSERT INTO nomenclature VALUES ('type_en', 'RNC', 'RNC', 'Réserve naturelle de Corse');
INSERT INTO nomenclature VALUES ('type_en', 'RNCFS', 'RNCFS', 'Réserve nationale de chasse et faune sauvage');
INSERT INTO nomenclature VALUES ('type_en', 'RNN', 'RNN', 'Réserve naturelle nationale');
INSERT INTO nomenclature VALUES ('type_en', 'RNR', 'RNR', 'Réserve naturelle régionale');
INSERT INTO nomenclature VALUES ('type_en', 'SCEN', 'SCEN', 'Site de Conservatoire d’espaces naturels');
INSERT INTO nomenclature VALUES ('type_en', 'SCL', 'SCL', 'Site du Conservatoire du littoral');
INSERT INTO nomenclature VALUES ('type_en', 'ZHAE', 'ZHAE', 'Zone humide acquise par une Agence de l’eau');
INSERT INTO nomenclature VALUES ('type_en', 'ZNIEFF', 'ZNIEFF', 'Zone Naturelle d’Intérêt Ecologique Faunistique et Floristique (type non précisé)');
INSERT INTO nomenclature VALUES ('type_en', 'ZNIEFF1', 'ZNIEFF1', 'Zone Naturelle d’Intérêt Ecologique Faunistique et Floristique de type I');
INSERT INTO nomenclature VALUES ('type_en', 'ZNIEFF2', 'ZNIEFF2', 'Zone Naturelle d’Intérêt Ecologique Faunistique et Floristique de type II');


INSERT INTO nomenclature VALUES ('type_info_geo', '1', 'Géoréférencement', 'Géoréférencement de l''objet géographique. L''objet géographique est celui sur lequel on a effectué l''observation.');
INSERT INTO nomenclature VALUES ('type_info_geo', '2', 'Rattachement', 'Rattachement à l''objet géographique : l''objet géographique n''est pas la géoréférence d''origine, ou a été déduit d''informations autres.');


INSERT INTO nomenclature VALUES ('type_regroupement', 'AUTR', 'AUTR', 'La valeur n''est pas contenue dans la présente liste. Elle doit être complétée par d''autres informations.');
INSERT INTO nomenclature VALUES ('type_regroupement', 'CAMP', 'CAMP', 'Campagne de prélèvement');
INSERT INTO nomenclature VALUES ('type_regroupement', 'INVSTA', 'INVSTA', 'Inventaire stationnel');
INSERT INTO nomenclature VALUES ('type_regroupement', 'LIEN', 'LIEN', 'Lien : Indique un lien fort entre 2 observations. (Une occurrence portée par l''autre, une symbiose, un parasitisme…)');
INSERT INTO nomenclature VALUES ('type_regroupement', 'NSP', 'NSP', 'Ne sait pas : l''information n''est pas connue.');
INSERT INTO nomenclature VALUES ('type_regroupement', 'OBS', 'OBS', 'Observations');
INSERT INTO nomenclature VALUES ('type_regroupement', 'OP', 'OP', 'Opération de prélèvement');
INSERT INTO nomenclature VALUES ('type_regroupement', 'PASS', 'PASS', 'Passage');
INSERT INTO nomenclature VALUES ('type_regroupement', 'POINT', 'POINT', 'Point de prélèvement ou point d''observation.');
INSERT INTO nomenclature VALUES ('type_regroupement', 'REL', 'REL', 'Relevé (qu''il soit phytosociologique, d''observation, ou autre...)');
INSERT INTO nomenclature VALUES ('type_regroupement', 'STRAT', 'STRAT', 'Strate');


INSERT INTO nomenclature VALUES ('version_masse_eau', '1', '1', 'Version issue du rapportage 2010 pour l''Europe');
INSERT INTO nomenclature VALUES ('version_masse_eau', '2', '2', 'Version intermédiaire de 2013 (interne)');
INSERT INTO nomenclature VALUES ('version_masse_eau', '3', '3', 'Version issue du rapportage 2016 pour l''Europe');


INSERT INTO nomenclature VALUES ('ds_publique', 'Ac', 'Publique acquise', 'Publique Acquise : La donnée-source a été produite par un organisme privé (associations, bureaux d’étude…) ou une personne physique à titre personnel. Les droits patrimoniaux exclusifs ou non exclusifs, de copie, traitement et diffusion sans limitation ont été acquis à titre gracieux ou payant, sur marché ou par convention, par un organisme ayant autorité publique. La donnée-source est devenue publique.  ');
INSERT INTO nomenclature VALUES ('ds_publique', 'NSP', 'Ne sait pas', 'Ne sait pas : L’information indiquant si la Donnée Source est publique ou privée n’est pas connue.');
INSERT INTO nomenclature VALUES ('ds_publique', 'Pr', 'Privée', 'Privée : La Donnée Source a été produite par un organisme privé ou un individu à titre personnel. Aucun organisme ayant autorité publique n''a acquis les droits patrimoniaux,  la Donnée Source reste la propriété de l’organisme ou de l’individu privé. Seul ce cas autorise un floutage géographique de la DEE.');
INSERT INTO nomenclature VALUES ('ds_publique', 'Pu', 'Publique', 'Publique : La Donnée Source est publique qu’elle soit produite en « régie » ou « acquise ».');
INSERT INTO nomenclature VALUES ('ds_publique', 'Re', 'Publique Régie', 'Publique Régie : La Donnée Source est publique et a été produite directement par un organisme ayant autorité publique avec ses moyens humains et techniques propres.');


INSERT INTO nomenclature VALUES ('nature_objet_geo', 'In', 'Inventoriel', 'Inventoriel : Le taxon observé est présent quelque part dans l’objet géographique');
INSERT INTO nomenclature VALUES ('nature_objet_geo', 'NSP', 'Ne sait pas', 'Ne Sait Pas : L’information est inconnue');
INSERT INTO nomenclature VALUES ('nature_objet_geo', 'St', 'Stationnel', 'Stationnel : Le taxon observé est présent sur l’ensemble de l’objet géographique');


INSERT INTO nomenclature VALUES ('dee_floutage', 'NON', 'Non', 'Non : indique qu''aucun floutage n''a eu lieu.');
INSERT INTO nomenclature VALUES ('dee_floutage', 'OUI', 'Oui', 'Oui : indique qu''un floutage a eu lieu.');


INSERT INTO nomenclature VALUES ('diffusion_niveau_precision', '0', 'Standard', 'Diffusion standard : à la maille, à la ZNIEFF, à la commune, à l’espace protégé (statut par défaut).');
INSERT INTO nomenclature VALUES ('diffusion_niveau_precision', '1', 'Commune', 'Diffusion floutée de la DEE par rattachement à la commune.');
INSERT INTO nomenclature VALUES ('diffusion_niveau_precision', '2', 'Maille', 'Diffusion floutée par rattachement à la maille 10 x 10 km');
INSERT INTO nomenclature VALUES ('diffusion_niveau_precision', '3', 'Département', 'Diffusion floutée par rattachement au département.');
INSERT INTO nomenclature VALUES ('diffusion_niveau_precision', '4', 'Aucune', 'Aucune diffusion (cas exceptionnel), correspond à une donnée de sensibilité 4.');
INSERT INTO nomenclature VALUES ('diffusion_niveau_precision', '5', 'Précise', 'Diffusion telle quelle : si une donnée précise existe, elle doit être diffusée telle quelle.');


INSERT INTO nomenclature VALUES ('objet_denombrement', 'COL', 'Colonie', 'Nombre de colonies observées.');
INSERT INTO nomenclature VALUES ('objet_denombrement', 'CPL', 'Couple', 'Nombre de couples observé.');
INSERT INTO nomenclature VALUES ('objet_denombrement', 'HAM', 'Hampe florale', 'Nombre de hampes florales observées.');
INSERT INTO nomenclature VALUES ('objet_denombrement', 'IND', 'Individu', 'Nombre d''individus observés.');
INSERT INTO nomenclature VALUES ('objet_denombrement', 'NID', 'Nid', 'Nombre de nids observés.');
INSERT INTO nomenclature VALUES ('objet_denombrement', 'NSP', 'Ne Sait Pas', 'La méthode de dénombrement n''est pas connue.');
INSERT INTO nomenclature VALUES ('objet_denombrement', 'PON', 'Ponte', 'Nombre de pontes observées.');
INSERT INTO nomenclature VALUES ('objet_denombrement', 'SURF', 'Surface', 'Zone aréale occupée par le taxon, en mètres carrés.');
INSERT INTO nomenclature VALUES ('objet_denombrement', 'TIGE', 'Tige', 'Nombre de tiges observées.');
INSERT INTO nomenclature VALUES ('objet_denombrement', 'TOUF', 'Touffe', 'Nombre de touffes observées.');


INSERT INTO nomenclature VALUES ('echelle_validation', '1', 'Validation producteur', 'Validation scientifique des données par le producteur');
INSERT INTO nomenclature VALUES ('echelle_validation', '2', 'Validation régionale', 'Validation scientifique effectuée par la plateforme régionale');
INSERT INTO nomenclature VALUES ('echelle_validation', '3', 'Validation nationale', 'Validation scientifique effectuée par la plateforme nationale');


INSERT INTO nomenclature VALUES ('niveau_validation_automatique', '1', 'Certain - très probable', 'La donnée présente un haut niveau de vraisemblance (très majoritairement cohérente) selon le protocole automatique appliquée. Le résultat de la procédure correspond à la définition optimale de satisfaction de l’ensemble des critères du protocole automatique, par exemple, lorsque la localité correspond à la distribution déjà connue et que les autres paramètres écologiques (date de visibilité, altitude, etc.) sont dans la gamme habituelle de valeur.');
INSERT INTO nomenclature VALUES ('niveau_validation_automatique', '2', 'Probable', 'La donnée est cohérente et plausible selon le protocole automatique appliqué mais ne satisfait pas complétement (intégralement) l’ensemble des critères automatiques appliqués. La donnée présente une forte probabilité d’être juste. Elle ne présente aucune discordance majeure sur les critères jugés les plus importants mais elle satisfait seulement à un niveau intermédiaire, ou un ou plusieurs des critères automatiques appliqués.');
INSERT INTO nomenclature VALUES ('niveau_validation_automatique', '3', 'Douteux', 'La donnée concorde peu selon le protocole automatique appliqué. La donnée est peu cohérente ou incongrue. Elle ne satisfait pas ou peu un ou plusieurs des critères automatiques appliqués. Elle ne présente cependant pas de discordance majeure sur les critères jugés les plus importants qui permettraient d’attribuer le plus faible niveau de validité (invalide).');
INSERT INTO nomenclature VALUES ('niveau_validation_automatique', '4', 'Invalide', 'La donnée ne concorde pas selon la procédure automatique appliquée. Elle présente au moins une discordance majeure sur un des critères jugés les plus importants ou la majorité des critères déterminants sont discordants. Elle est considérée comme trop improbable (aberrante notamment au regard de l’aire de répartition connue, des paramètres biotiques et abiotiques de la niche écologique du taxon). Elle est considérée comme invalide.');
INSERT INTO nomenclature VALUES ('niveau_validation_automatique', '5', 'Non réalisable', 'La donnée a été soumise à l’ensemble du processus de validation mais l’opérateur (humain ou machine) n’a pas pu statuer sur le niveau de fiabilité, notamment à cause des points suivants : état des connaissances du taxon insuffisantes, ou informations insuffisantes sur l’observation.');
INSERT INTO nomenclature VALUES ('occ_etat_biologique', '0', 'NSP', 'Inconnu (peut être utilisé pour les virus ou les végétaux fanés par exemple).');
INSERT INTO nomenclature VALUES ('occ_etat_biologique', '1', 'Non renseigné', 'L''information n''a pas été renseignée.');
INSERT INTO nomenclature VALUES ('occ_etat_biologique', '2', 'Observé vivant', 'L''individu a été observé vivant.');
INSERT INTO nomenclature VALUES ('occ_etat_biologique', '3', 'Trouvé mort', 'L''individu a été trouvé mort : Cadavre entier ou crâne par exemple. La mort est antérieure au processus d''observation.');


INSERT INTO nomenclature VALUES ('niveau_validation_manuelle_combine', '1', 'Certain - très probable', 'Certain - très probable : La donnée est exacte. Il n’y a pas de doute notable et significatif quant à l’exactitude de l’observation ou de la détermination du taxon. La validation a été réalisée notamment à partir d’une preuve de l’observation qui confirme la détermination du producteur ou après vérification auprès de l’observateur et/ou du déterminateur.');
INSERT INTO nomenclature VALUES ('niveau_validation_manuelle_combine', '2', 'Probable', 'Probable : La donnée présente un bon niveau de fiabilité. Elle est vraisemblable et crédible. Il n’y a, a priori, aucune raison de douter de l’exactitude de la donnée mais il n’y a pas d’éléments complémentaires suffisants disponibles ou évalués (notamment la présence d’une preuve ou la possibilité de revenir à la donnée source) permettant d’attribuer un plus haut niveau de certitude.');
INSERT INTO nomenclature VALUES ('niveau_validation_manuelle_combine', '3', 'Douteux', 'Douteux : La donnée est peu vraisemblable ou surprenante mais on
ne dispose pas d’éléments suffisants pour attester d’une erreur manifeste. La donnée est considérée comme douteuse.');
INSERT INTO nomenclature VALUES ('niveau_validation_manuelle_combine', '4', 'Invalide', 'Invalide : La donnée a été infirmée (erreur manifeste/avérée) ou présente un trop bas niveau de fiabilité. Elle est considérée comme trop improbable (aberrante notamment au regard de l’aire de répartition connue, des paramètres biotiques et abiotiques de la niche écologique du taxon, la preuve révèle une erreur de détermination). Elle est considérée comme invalide.');
INSERT INTO nomenclature VALUES ('niveau_validation_manuelle_combine', '5', 'Non réalisable', 'Non réalisable : La donnée a été soumise à l’ensemble du processus de validation mais l’opérateur (humain ou machine) n’a pas pu statuer sur le niveau de fiabilité, notamment à cause des points suivants : état des connaissances du taxon insuffisantes, ou informations insuffisantes sur l’observation.');


INSERT INTO nomenclature VALUES ('niveau_criticite_validation', '1', 'Mineure', 'Mineure : La modification n''est pas de nature à modifier le niveau de validité de la donnée.');
INSERT INTO nomenclature VALUES ('niveau_criticite_validation', '2', 'Majeure', 'Majeure : La modification est de nature à modifier le niveau de validité de la donnée.');


INSERT INTO nomenclature VALUES ('type_validation', 'A', 'Automatique', 'Automatique : Résulte d''une validation automatique');
INSERT INTO nomenclature VALUES ('type_validation', 'C', 'Combinée', 'Combinée : Résulte de la combinaison d''une validation automatique et d''une validation manuelle');
INSERT INTO nomenclature VALUES ('type_validation', 'M', 'Manuelle', 'Manuelle : Résulte d''une validation manuelle (intervention d''un expert)');


INSERT INTO nomenclature VALUES ('perimetre_validation', '1', 'Périmètre minimal', 'Périmètre minimal : Validation effectuée sur la base des attributs minimaux, à savoir le lieu, la date, et le taxon.');
INSERT INTO nomenclature VALUES ('perimetre_validation', '2', 'Périmètre maximal', 'Périmètre élargi : validation scientifique sur la base des attributs minimaux, lieu, date, taxon, incluant également des  vérifications sur d''autres attributs, précisés dans la procédure de validation associé.');


INSERT INTO nomenclature VALUES ('occ_naturalite', '0', 'Inconnu', 'Inconnu : la naturalité du sujet est inconnue');
INSERT INTO nomenclature VALUES ('occ_naturalite', '1', 'Sauvage', 'Sauvage : Qualifie un animal ou végétal à l''état sauvage, individu autochtone, se retrouvant dans son aire de répartition naturelle et dont les individus sont le résultat d''une reproduction naturelle, sans intervention humaine.');
INSERT INTO nomenclature VALUES ('occ_naturalite', '2', 'Cultivé/élevé', 'Cultivé/élevé : Qualifie un individu d''une population allochtone introduite volontairement dans des espaces non naturels dédiés à la culture, ou à l''élevage.');
INSERT INTO nomenclature VALUES ('occ_naturalite', '3', 'Planté', 'Planté : Qualifie un végétal d''une population allochtone introduite ponctuellement et  volontairement dans un espace naturel/semi naturel.');
INSERT INTO nomenclature VALUES ('occ_naturalite', '4', 'Féral', 'Féral : Qualifie un animal élevé retourné à l''état sauvage, individu d''une population allochtone.');
INSERT INTO nomenclature VALUES ('occ_naturalite', '5', 'Subspontané', 'Subspontané : Qualifie un végétal d''une population allochtone, introduite volontairement, qui persiste plus ou moins longtemps dans sa station d’origine et qui a une dynamique propre peu étendue et limitée aux alentours de son implantation initiale. "Echappée des jardins".');


INSERT INTO nomenclature VALUES ('occ_sexe', '0', 'Inconnu', 'Inconnu : Il n''y a pas d''information disponible pour cet individu.');
INSERT INTO nomenclature VALUES ('occ_sexe', '1', 'Indéterminé', 'Indéterminé : Le sexe de l''individu n''a pu être déterminé');
INSERT INTO nomenclature VALUES ('occ_sexe', '2', 'Femelle', 'Féminin : L''individu est de sexe féminin.');
INSERT INTO nomenclature VALUES ('occ_sexe', '3', 'Mâle', 'Masculin : L''individu est de sexe masculin.');
INSERT INTO nomenclature VALUES ('occ_sexe', '4', 'Hermaphrodite', 'Hermaphrodite : L''individu est hermaphrodite.');
INSERT INTO nomenclature VALUES ('occ_sexe', '5', 'Mixte', 'Mixte : Sert lorsque l''on décrit plusieurs individus.');
INSERT INTO nomenclature VALUES ('occ_sexe', '6', 'Non renseigné', 'Non renseigné : l''information n''a pas été renseignée dans le document à l''origine de la donnée.');
