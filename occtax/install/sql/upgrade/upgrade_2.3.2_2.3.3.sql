BEGIN;

-- Modification du type du champ date_envoi_annuel
ALTER TABLE gestion.adherent ALTER COLUMN date_envoi_annuel TYPE text USING date_envoi_annuel::text;
COMMENT ON COLUMN gestion.adherent.date_envoi_annuel IS 'Date fixée pour la fourniture annuelle des nouvelles données et métadonnées au SINP. Au format texte, par ex: 15 décembre';


-- Modification du trigger pour appliquer les changements sur observation depuis validation_observation
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


DROP TRIGGER IF EXISTS trg_validation_renseigner_champs_observation ON occtax.validation_observation;
CREATE TRIGGER trg_validation_renseigner_champs_observation
AFTER INSERT OR UPDATE OR DELETE ON occtax.validation_observation
FOR EACH ROW EXECUTE PROCEDURE occtax.update_observation_set_validation_fields();

COMMIT;
