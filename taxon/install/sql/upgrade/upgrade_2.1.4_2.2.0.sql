BEGIN;

-- Ajout d'un champ ordre dans la table de nomenclature
ALTER TABLE taxon.t_nomenclature ADD COLUMN IF NOT EXISTS IF NOT EXISTS ordre smallint DEFAULT 0;
COMMENT ON COLUMN taxon.t_nomenclature.ordre IS 'Ordre d''apparition souhaité, utilisé par exemple dans les listes déroulantes du formulaire de recherche.';



TRUNCATE t_nomenclature RESTART IDENTITY;

-- t_nomenclature
-- statut
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('statut', 'I', 'Indigène', NULL, 1);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('statut', 'E', 'Exotique', NULL, 2);

-- rareté
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('rarete', 'E', 'Exceptionnel', NULL, 1);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('rarete', 'R', 'Rare', NULL, 2);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('rarete', 'C', 'Commun', NULL, 3);

-- endémicité
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('endemicite', 'E', 'Endémique', NULL, 1);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('endemicite', 'S', 'Subendémique', NULL, 2);

-- invasibilité
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('invasibilite', 'NE', 'Non envahissant', NULL, 1);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('invasibilite', 'PE', 'Potentiellement envahissant', NULL, 2);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('invasibilite', 'E', 'Envahissant', NULL, 3);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('invasibilite', 'EM', 'Envahissant majeur', NULL, 4);

-- menace
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('menace', 'EX', 'Éteinte au niveau mondial', '#000000', 11);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('menace', 'EW', 'Éteinte à l''état sauvage', '#3D1951', 10);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('menace', 'RE', 'Disparue au niveau régional', '#5A1A63', 9);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('menace', 'CR', 'En danger critique', '#D3001B', 8);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('menace', 'EN', 'En danger', '#FBBF00', 7);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('menace', 'VU', 'Vulnérable', '#FFED00', 6);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('menace', 'NT', 'Quasi menacée', '#FBF2CA', 5);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('menace', 'LC', 'Préoccupation mineure', '#78B74A', 4);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('menace', 'DD', 'Données insuffisante', '#D3D4D5', 3);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('menace', 'NA', 'Non applicable', '#919294', 2);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('menace', 'NE', 'Non évaluée', ' #FFFFFF', 1);


-- protection
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('protection', 'EPN', 'Protection nationale', NULL, 1);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('protection', 'EPC', 'Protection communautaire (UE)', NULL, 2);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('protection', 'EPI', 'Protection internationale', NULL, 3);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('protection', 'EPA', 'Autre statut', 'Autre statut d''espèce (espèce invasive de lutte obligatoire, etc.)', 4);


-- déterminantn ZNIEFF
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('det_znieff', '1', 'Niveau 1', NULL, 1);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('det_znieff', '2', 'Niveau 2', NULL, 2);

-- habitats
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('habitat', '1', 'Marin', 'Espèces vivant uniquement en milieu marin', 1);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('habitat', '2', 'Eau douce', 'Espèces vivant uniquement en milieu d’eau douce', 2);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('habitat', '3', 'Terrestre', 'Espèces vivant uniquement en milieu terrestre', 3);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('habitat', '4', 'Marin & Eau douce', 'Espèces effectuant une partie de leur cycle de vie en eau douce et l’autre partie en mer (espèces diadromes, amphidromes, anadromes ou catadromes).', 4);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('habitat', '5', 'Marin & Terrestre', 'Cas des pinnipèdes, des tortues et des oiseaux marins par exemple.', 5);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('habitat', '6', 'Eau saumâtre', 'Espèces vivant exclusivement en eau saumâtre.', 6);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('habitat', '7', 'Continental (terrestre et/ou eau douce)', 'Espèces continentales (non marines) dont on ne sait pas si elles sont terrestres et/ou d’eau douce (taxons provenant de Fauna Europaea).', 7);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('habitat', '8', 'Continental (terrestre et eau douce)', 'Espèces terrestres effectuant une partie de leur cycle en eau douce (odonates par exemple), ou fortement liées au milieu aquatique (loutre par exemple).', 8);


-- statuts officiel de TAXREF (par ex pour colonne GUA)
-- Table TAXREF_STATUTS
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('statut_taxref', 'P', 'Présent (indigène ou indéterminé)', 'Taxon présent au sens large dans la zone géographique considérée, c’est-à-dire taxon indigène ou taxon dont on ne sait pas s’il appartient à l’une des autres catégories. Le défaut de connaissance profite donc à l’indigénat.

Par indigène on entend : taxon qui est issu de la zone géographique considérée et qui s’y est naturellement développé sans contribution humaine, ou taxon qui est arrivé là sans intervention humaine (intentionnelle ou non) à partir d’une zone dans laquelle il est indigène .
(NB : exclus les hybrides dont l’un des parents au moins est introduit dans la zone considérée)

Sont regroupés sous ce statut tous les taxons catégorisés « natif » ou « autochtone ».
Les taxons hivernant quelques mois de l’année entrent dans cette catégorie.', 1);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('statut_taxref', 'B', 'Occasionnel', 'Taxon occasionnel (migrateur de passage) ou observé de manière exceptionnelle (taxon accidentel dans la zone géographique considérée).', 2);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('statut_taxref', 'E', 'Endémique', 'Taxon naturellement restreint à la zone géographique considérée.', 3);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('statut_taxref', 'S', 'Subendémique', 'Taxon naturellement restreint à une zone un peu plus grande que la zone géographique considérée mais dont les principales populations se situent dans la zone géographique considérée.
Pour l’Outre-mer, on applique ce statut à l’endémisme régional :
- pour la Guyane française = endémique du plateau des Guyanes,
- pour les Antilles françaises = endémique des petites Antilles.,
- pour Mayotte = endémique des Comores,
- pour la Réunion = endémique des Mascareignes,
- pour les TAAF = endémique de la South Indian Ocean Province', 4);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('statut_taxref', 'C', 'Cryptogène', 'Taxon dont l’aire d’origine est inconnue et dont on ne peut donc pas dire s’il est indigène ou introduit.', 5);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('statut_taxref', 'I', 'Introduit', 'Taxon introduit (établi ou possiblement établi) dans la zone géographique considérée.

Par introduit on entend : taxon dont la présence dans la zone géographique considérée est due à une intervention humaine, intentionnelle ou non, ou taxon qui est arrivé dans la zone sans intervention humaine mais à partir
d’une zone dans laquelle il est introduit.
Par établi (terme pour la faune, = naturalisé pour la flore) on entend : taxon introduit qui forme des populations viables (se reproduisant) et durables qui se maintiennent dans le milieu naturel sans besoin d’intervention humaine.

Sont regroupés sous ce statut tous les taxons catégorisés « non-indigène », « exotique », « exogène », « allogène », « allochtone », « non-natif », « naturalisé » (en anglais : alien) dans une publication scientifique.', 6);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('statut_taxref', 'J', 'Introduit envahissant', 'Taxon introduit dans la zone géographique considérée, qui produit des descendants fertiles souvent en grand nombre, et qui a le potentiel pour s’étendre de façon exponentielle sur une grande aire, augmentant ainsi rapidement son aire de répartition. Cela induit souvent des conséquences écologiques, économiques ou sanitaires négatives (IUCN, 2000).

Sont regroupés sous ce statut tous les taxons catégorisés « introduite envahissante », « exotique envahissant » ou « invasif » (invasive en anglais) dans une publication scientifique.', 7);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('statut_taxref', 'M', 'Introduit non établi (dont domestique)', 'Taxon introduit qui peut occasionnellement se reproduire en dehors de son aire de culture ou de captivité, mais qui ne peut se maintenir à l’état sauvage car ne pouvant former de populations viables sans intervention humaine, et qui dépend donc d’introductions répétées pour se maintenir dans la nature.

Sont regroupés sous ce statut tous les taxons catégorisés « introduit occasionnel », « subspontané », « échappé de culture » (en anglais : casual alien (faune) ou acclimatised alien (flore)).
Ce statut inclut les taxons strictement domestiques (faune) ou uniquement cultivés (flore).', 8);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('statut_taxref', 'D', 'Douteux', 'Taxon dont la présence dans la zone géographique considérée n’est pas avérée (en attente de confirmation).', 9);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('statut_taxref', 'A', 'Absent', 'Taxon non présent dans la zone géographique considérée.', 10);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('statut_taxref', 'W', 'Disparu', 'Taxon qui n’est plus présent à l’état sauvage dans la zone géographique considérée mais qui n’est pas globalement éteint.
Rq : en cas de doute sur la présence ancienne ou non du taxon à l’état sauvage, utiliser le statut absent (A).', 11);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('statut_taxref', 'X', 'Éteint', 'Taxon globalement éteint (= ayant totalement disparu de la surface du globe terrestre).', 12);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('statut_taxref', 'Y', 'Introduit éteint / disparu', 'Taxon introduit par le passé mais aujourd’hui disparu de la zone géographique considérée (W) ou éteint (X).', 13);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('statut_taxref', 'Z', 'Endémique éteint', 'Taxon endémique et aujourd’hui disparu, donc globalement éteint (X).', 14);
INSERT INTO t_nomenclature (champ, code, valeur, description, ordre) VALUES ('statut_taxref', 'Q', 'Mentionné par erreur', 'Taxon mentionné par erreur comme présent sur le territoire considéré.', 15);

COMMIT;
