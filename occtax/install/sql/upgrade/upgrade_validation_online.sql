-- Validation panier
DROP TABLE IF EXISTS occtax.validation_panier;
CREATE TABLE occtax.validation_panier (
    id serial NOT NULL PRIMARY KEY,
    usr_login character varying NOT NULL,
    identifiant_permanent text NOT NULL
);

ALTER TABLE occtax.validation_panier ADD CONSTRAINT validation_panier_usr_login_identifiant_permanent_key UNIQUE (usr_login, identifiant_permanent);

COMMENT ON TABLE occtax.validation_panier IS 'Panier d''observations retenues pour appliquer des actions en masse. Par exemple pour la validation scientifique manuelle.';
COMMENT ON COLUMN occtax.validation_panier.id IS 'Identifiant auto-incrémenté unique, clé primaire.';
COMMENT ON COLUMN occtax.validation_panier.usr_login IS 'Login de l''utilisateur qui fait la validation en ligne.';
COMMENT ON COLUMN occtax.validation_panier.identifiant_permanent IS 'Identifiant permanent de l''observation mise dans le panier.';


-- gestion.demande
-- modification de type_demande
ALTER TABLE gestion.demande DROP CONSTRAINT IF EXISTS demande_type_demande_valide ;
ALTER TABLE gestion.demande ADD CONSTRAINT demande_type_demande_valide CHECK (type_demande = ANY (ARRAY['EI'::text, 'MR'::text, 'GM'::text, 'SC'::text, 'PS'::text, 'AP'::text, 'AT'::text, 'CO'::text, 'AU'::text, 'VA'::text]))
;
COMMENT ON COLUMN gestion.demande.type_demande
IS 'Type de demande selon la typologie de la charte du SINP (EI = Etude d''impact,  MR = mission régalienne, GM = Gestion des milieux naturels, SC = Sensibilisation et communication, PS = publication scientifique, AP = Accès producteur, AT = Accès tête de réseau, CO = Conservation, AU = Autre, VA = Accès validateur)'
;

-- suppression d'une ancienne colonne ajouté par erreur lors du dev
ALTER TABLE gestion.demande DROP COLUMN IF EXISTS contexte_validation;

-- Ajout de la colonne d'id de la personne qui est validateyr
ALTER TABLE gestion.demande ADD COLUMN IF NOT EXISTS id_validateur integer;
COMMENT ON COLUMN gestion.demande.id_validateur IS 'Identifiant de la personne de la table occtax.personne à laquelle correspond la personne de cette demande. Utilisé pour remplir le champ occtax.validation_observation.validateur avec l''outil de validation en ligne. Doit être remplir uniquement si type_demande est VA';

ALTER TABLE gestion.demande DROP CONSTRAINT IF EXISTS demande_id_validateur_ok;
ALTER TABLE gestion.demande ADD CONSTRAINT demande_id_validateur_ok
CHECK ( (type_demande != 'VA') OR (id_validateur IS NOT NULL AND type_demande = 'VA') );

-- Fonction trigger qui lance la modification des champs validite_niveau et validite_date_validation
-- lorsque l'utilisateur modifie la table occtax.validation_observation
-- Cela crée un lien entre l'extension validation et les champs de la table observation
CREATE OR REPLACE FUNCTION occtax.update_observation_set_validation_fields() RETURNS TRIGGER AS $$
    BEGIN

        IF TG_OP = 'DELETE' THEN
            UPDATE occtax.observation o
            SET
                validite_niveau = '6', -- Non évalué
                validite_date_validation = NULL
            WHERE o.identifiant_permanent = OLD.identifiant_permanent
            -- une donnée validée juste par le producteur ne devrait pas être considérée
            -- comme validée et donc accessible au grand public
            -- donc on applique seulement si ech_val = '2' cad niveau régional
            AND OLD.ech_val = '2'
            ;
            RETURN OLD;
        ELSE
            UPDATE occtax.observation o
            SET
                validite_niveau = CASE WHEN NEW.niv_val IS NOT NULL THEN NEW.niv_val ELSE '6' END,
                validite_date_validation = NEW.date_ctrl
            WHERE o.identifiant_permanent = NEW.identifiant_permanent
            -- une donnée validée juste par le producteur ne devrait pas être considérée
            -- comme validée et donc accessible au grand public
            -- donc on applique seulement si ech_val = '2' cad niveau régional
            AND NEW.ech_val = '2'
            ;
            RETURN NEW;
        END IF;
    END;
$$ LANGUAGE plpgsql;


-- On crée une vue très simple pour récupérer seulement les 2 champs de validation de la table observation
-- cela permet de faire une jointure avec cette vue, sans besoin de tout prefixer en o. (vm_observation)
-- dans l'ensemble du code et surtout dans critere_additionnel de gestion.demande
-- car alors les autres champs de observation (date_debut, etc.) ne seront pas présents
CREATE OR REPLACE VIEW occtax.v_observation_champs_validation AS
SELECT identifiant_permanent,
Coalesce(validite_niveau, '6') AS validite_niveau, validite_date_validation
FROM occtax.observation
;
COMMENT ON VIEW occtax.v_observation_champs_validation
IS 'Une vue très simple pour récupérer seulement les 2 champs de validation de la table observation. cCla permet de faire une jointure avec cette vue, sans besoin de tout prefixer en o. (vm_observation) dans l''ensemble du code et surtout dans critere_additionnel de gestion.demande. Car alors les autres champs de observation (date_debut, etc.) ne seront pas ramenés par la jointure sur cette vue mais le seraient sur la table observation';
