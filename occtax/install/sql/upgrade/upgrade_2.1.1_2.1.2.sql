BEGIN;
-- from 2.1.1 to 2.1.2

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
            WHERE o.identifiant_permanent = NEW.identifiant_permanent
            -- une donnée validée juste par le producteur ne devrait pas être considérée
            -- comme validée et donc accessible au grand public
            -- donc on applique seulement si ech_val = 2 cad niveau régional
            AND NEW.ech_val = 2
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
            -- donc on applique seulement si ech_val = 2 cad niveau régional
            AND NEW.ech_val = 2
            ;
            RETURN NEW;
        END IF;
    END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS trg_validation_renseigner_champs_observation ON occtax.validation_observation;
CREATE TRIGGER trg_validation_renseigner_champs_observation
AFTER INSERT OR UPDATE OR DELETE ON occtax.validation_observation
FOR EACH ROW EXECUTE PROCEDURE occtax.update_observation_set_validation_fields();

COMMIT;
