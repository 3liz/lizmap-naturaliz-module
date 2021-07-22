-- Validation panier
DROP TABLE IF EXISTS occtax.validation_panier;
CREATE TABLE occtax.validation_panier (
    id serial NOT NULL PRIMARY KEY,
    usr_login character varying NOT NULL,
    identifiant_permanent text NOT NULL
);

ALTER TABLE occtax.validation_panier ADD CONSTRAINT validation_panier_usr_login_identifiant_permanent_key UNIQUE (usr_login, identifiant_permanent);

COMMENT ON TABLE occtax.validation_panier IS 'Panier d''observations retenues pour appliquer des actions en masse. Par exemple pour la validation scientifique manuelle.';

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
