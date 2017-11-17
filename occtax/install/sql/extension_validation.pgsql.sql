BEGIN;

--
-- Extension validation
--
SET search_path TO occtax,public;

-- table validation_regionale_ou_nationale
CREATE TABLE validation_regionale_ou_nationale (
    id_validation serial,
    cle_obs bigint,
    date_ctrl date NOT NULL,
    niv_val text NOT NULL,
    typ_val text NOT NULL,
    ech_val text NOT NULL,
    peri_val text NOT NULL,
    validateur integer NOT NULL,
    proc_vers text NOT NULL,
    producteur integer,
    date_contact date,
    procedure text,
    proc_ref text,
    commm_val text
);
ALTER TABLE validation_regionale_ou_nationale ADD PRIMARY KEY (id_validation);

ALTER TABLE validation_regionale_ou_nationale ADD CONSTRAINT validation_regionale_ou_nationale_cle_obs_fk FOREIGN KEY (cle_obs)
REFERENCES observation (cle_obs)
ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE validation_regionale_ou_nationale ADD CONSTRAINT validation_regionale_ou_nationale_validateur_fkey
FOREIGN KEY (validateur)
REFERENCES personne (id_personne)
ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE validation_regionale_ou_nationale ADD CONSTRAINT validation_regionale_ou_nationale_producteur_fkey
FOREIGN KEY (validateur)
REFERENCES personne (id_personne)
ON UPDATE RESTRICT ON DELETE RESTRICT;

COMMENT ON TABLE validation_regionale_ou_nationale IS 'Décrit les opérations de validation scientifique et le niveau de validation attribué à la donnée d''occurrence. Les contrôles de validation scientifique ont été effectués au niveau régional ou national. Il n''est possible de transmettre que 2 résultats de contrôle de validation au maximum via ce concept : l''un national, l''autre régional.';

COMMENT ON COLUMN validation_regionale_ou_nationale.date_ctrl IS 'Date de réalisation du contrôle de validation. Format AAAA-MM-JJ.';

COMMENT ON COLUMN validation_regionale_ou_nationale.niv_val IS 'Niveau de validité attribué à la donnée à la suite de son contrôle. Le niveau de validité et le libellé associé peuvent se trouver dans les nomenclatures NivValAutoValue et NivValManCom suivant qu''on a procédé à une validation automatique ou à une validation manuelle ou combinée.';

COMMENT ON COLUMN validation_regionale_ou_nationale.typ_val IS 'Type de validation effectué. Les valeurs permises sont décrites dans la nomenclature TypeValValue, et peuvent avoir été mises à jour : voir le site des standards de données, http://standards-sinp.mnhn.fr';

COMMENT ON COLUMN validation_regionale_ou_nationale.ech_val IS 'Echelle de validation de la donnée : indique quelle plateforme a réalisé les opérations de validation scientifique. Les valeurs possibles sont définies par la nomenclature EchelleValidationValue, susceptible d''évoluer au fil du temps.';

COMMENT ON COLUMN validation_regionale_ou_nationale.peri_val IS 'Périmètre de validation de la donnée. Il est défini par les valeurs de la nomenclature PerimetreValidationValue.';

COMMENT ON COLUMN validation_regionale_ou_nationale.validateur IS 'Validateur (personne et organisme ayant procédé à la validation, éventuellement mail). Voir PersonneType dans le standard occurrences de taxons pour savoir comment le remplir.';

COMMENT ON COLUMN validation_regionale_ou_nationale.producteur IS 'Personne recontactée par l''expert chez le producteur lorsque l''expert a eu besoin d''informations complémentaires de la part du producteur. Ensemble d''attributs de "PersonneType" (voir standard occurrences de taxons), identité, organisme, éventuellement mail, à remplir dès lors qu''un contact avec le producteyr a eu lieu.';

COMMENT ON COLUMN validation_regionale_ou_nationale.date_contact IS 'Date de contact avec le producteur par l''expert lors de la validation. Doit être rempli si une personne a été recontactée.';

COMMENT ON COLUMN validation_regionale_ou_nationale.procedure IS 'Procédure utilisée pour la validation de la donnée. Description succincte des opérations réalisées. Si l''on dispose déjà d''une référence qu''on a indiquée dans procRef, pour des raisons de volume de données, il n''est pas nécessire de remplir cet attribut.';

COMMENT ON COLUMN validation_regionale_ou_nationale.proc_vers IS 'Version de la procédure utilisée.';

COMMENT ON COLUMN validation_regionale_ou_nationale.proc_ref IS 'Référence permettant de retrouver la procédure : URL, référence biblio, texte libre. Exemple : https://inpn.mnhn.fr/docs-web/docs/download/146208';

COMMENT ON COLUMN validation_regionale_ou_nationale.commm_val IS 'Commentaire sur la validation.';


-- table validation_producteur
CREATE TABLE validation_producteur (
    id_validation serial,
    cle_obs bigint,
    niv_val text NOT NULL,
    date_ctrl date,
    validateur integer,
    procedure text
);
ALTER TABLE validation_producteur ADD PRIMARY KEY (id_validation);

ALTER TABLE validation_producteur ADD CONSTRAINT validation_producteur_cle_obs_fk FOREIGN KEY (cle_obs)
REFERENCES observation (cle_obs)
ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE validation_producteur ADD CONSTRAINT validation_producteur_validateur_fkey FOREIGN KEY (validateur)
REFERENCES personne (id_personne)
ON UPDATE restrict ON DELETE RESTRICT;

COMMENT ON TABLE validation_producteur IS 'Indique les contrôles de validation scientifique et le niveau de validation attribué à la donnée d''occurrence par
le producteur.';

COMMENT ON COLUMN validation_producteur.id_validation IS 'Identifiant unique';

COMMENT ON COLUMN validation_producteur.date_ctrl IS 'Date de validation par le producteur. Format AAAA-MM-JJ.';

COMMENT ON COLUMN validation_regionale_ou_nationale.niv_val IS 'Niveau de validité attribué par le producteur. Ne doit pas contenir de codes ou d''abréviations, sauf si la nomenclature de validation fournie par le SINP est utilisée (auquel cas les codes de cette nomenclature sont autorisés).';

COMMENT ON COLUMN validation_producteur.validateur IS 'Personne ayant procédé à la validation (et organisme). Ce concept est composé de 3 attributs (Voir PersonneType)';

COMMENT ON COLUMN validation_producteur.procedure IS 'Endroit où trouver la procédure de validation scientifique qui a été utilisée. Url, référence bibliographique ou texte libre sont acceptés.';


-- validation
INSERT INTO nomenclature VALUES ('niv_val_auto', '1', 'Certain - très probable', 'La donnée présente un haut niveau de vraisemblance (très majoritairement cohérente) selon le protocole automatique appliquée. Le résultat de la procédure correspond à la définition optimale de satisfaction de l’ensemble des critères du protocole automatique, par exemple, lorsque la localité correspond à la distribution déjà connue et que les autres paramètres écologiques (date de visibilité, altitude, etc.) sont dans la gamme habituelle de valeur.');
INSERT INTO nomenclature VALUES ('niv_val_auto', '2', 'Probable', 'La donnée est cohérente et plausible selon le protocole automatique appliqué mais ne satisfait pas complétement (intégralement) l’ensemble des critères automatiques appliqués. La donnée présente une forte probabilité d’être juste. Elle ne présente aucune discordance majeure sur les critères jugés les plus importants mais elle satisfait seulement à un niveau intermédiaire, ou un ou plusieurs des critères automatiques appliqués.');
INSERT INTO nomenclature VALUES ('niv_val_auto', '3', 'Douteux', 'La donnée concorde peu selon le protocole automatique appliqué. La donnée est peu cohérente ou incongrue. Elle ne satisfait pas ou peu un ou plusieurs des critères automatiques appliqués. Elle ne présente cependant pas de discordance majeure sur les critères jugés les plus importants qui permettraient d’attribuer le plus faible niveau de validité (invalide).');
INSERT INTO nomenclature VALUES ('niv_val_auto', '4', 'Invalide', 'La donnée ne concorde pas selon la procédure automatique appliquée. Elle présente au moins une discordance majeure sur un des critères jugés les plus importants ou la majorité des critères déterminants sont discordants. Elle est considérée comme trop improbable (aberrante notamment au regard de l’aire de répartition connue, des paramètres biotiques et abiotiques de la niche écologique du taxon). Elle est considérée comme invalide.');
INSERT INTO nomenclature VALUES ('niv_val_auto', '5', 'Non réalisable', 'La donnée a été soumise à l’ensemble du processus de validation mais l’opérateur (humain ou machine) n’a pas pu statuer sur le niveau de fiabilité, notamment à cause des points suivants : état des connaissances du taxon insuffisantes, ou informations insuffisantes sur l’observation.');

INSERT INTO nomenclature VALUES ('niv_val_mancom', '1', 'Certain - très probable', 'Certain - très probable : La donnée est exacte. Il n’y a pas de doute notable et significatif quant à l’exactitude de l’observation ou de la détermination du taxon. La validation a été réalisée notamment à partir d’une preuve de l’observation qui confirme la détermination du producteur ou après vérification auprès de l’observateur et/ou du déterminateur.');
INSERT INTO nomenclature VALUES ('niv_val_mancom', '2', 'Probable', 'Probable : La donnée présente un bon niveau de fiabilité. Elle est vraisemblable et crédible. Il n’y a, a priori, aucune raison de douter de l’exactitude de la donnée mais il n’y a pas d’éléments complémentaires suffisants disponibles ou évalués (notamment la présence d’une preuve ou la possibilité de revenir à la donnée source) permettant d’attribuer un plus haut niveau de certitude.');
INSERT INTO nomenclature VALUES ('niv_val_mancom', '3', 'Douteux', 'Douteux : La donnée est peu vraisemblable ou surprenante mais on ne dispose pas d’éléments suffisants pour attester d’une erreur manifeste. La donnée est considérée comme douteuse.');
INSERT INTO nomenclature VALUES ('niv_val_mancom', '4', 'Invalide', 'Invalide : La donnée a été infirmée (erreur manifeste/avérée) ou présente un trop bas niveau de fiabilité. Elle est considérée comme trop improbable (aberrante notamment au regard de l’aire de répartition connue, des paramètres biotiques et abiotiques de la niche écologique du taxon, la preuve révèle une erreur de détermination). Elle est considérée comme invalide.');
INSERT INTO nomenclature VALUES ('niv_val_mancom', '5', 'Non réalisable', 'Non réalisable : La donnée a été soumise à l’ensemble du processus de validation mais l’opérateur (humain ou machine) n’a pas pu statuer sur le niveau de fiabilité, notamment à cause des points suivants : état des connaissances du taxon insuffisantes, ou informations insuffisantes sur l’observation.');

INSERT INTO nomenclature VALUES ('criticite', '1', 'Mineure', 'Mineure : La modification n''est pas de nature à modifier le niveau de validité de la donnée.');
INSERT INTO nomenclature VALUES ('criticite', '2', 'Majeure', 'Majeure : La modification est de nature à modifier le niveau de validité de la donnée.');

INSERT INTO nomenclature VALUES ('typ_val', 'A', 'Automatique', 'Automatique : Résulte d''une validation automatique');
INSERT INTO nomenclature VALUES ('typ_val', 'C', 'Combinée', 'Combinée : Résulte de la combinaison d''une validation automatique et d''une validation manuelle');
INSERT INTO nomenclature VALUES ('typ_val', 'M', 'Manuelle', 'Manuelle : Résulte d''une validation manuelle (intervention d''un expert)');

INSERT INTO nomenclature VALUES ('peri_val', '1', 'Périmètre minimal', 'Périmètre minimal : Validation effectuée sur la base des attributs minimaux, à savoir le lieu, la date, et le taxon.');
INSERT INTO nomenclature VALUES ('peri_val', '2', 'Périmètre maximal', 'Périmètre élargi : validation scientifique sur la base des attributs minimaux, lieu, date, taxon, incluant également des  vérifications sur d''autres attributs, précisés dans la procédure de validation associé.');

INSERT INTO nomenclature VALUES ('ech_val', '1', 'Validation producteur', 'Validation scientifique des données par le producteur');
INSERT INTO nomenclature VALUES ('ech_val', '2', 'Validation régionale', 'Validation scientifique effectuée par la plateforme régionale');
INSERT INTO nomenclature VALUES ('ech_val', '3', 'Validation nationale', 'Validation scientifique effectuée par la plateforme nationale');


COMMIT;
