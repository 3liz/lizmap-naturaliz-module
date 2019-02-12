BEGIN;

-- Modification du type du champ date_envoi_annuel
ALTER TABLE gestion.adherent ALTER COLUMN date_envoi_annuel TYPE text USING date_envoi_annuel::text;
COMMENT ON COLUMN gestion.adherent.date_envoi_annuel IS 'Date fixée pour la fourniture annuelle des nouvelles données et métadonnées au SINP. Au format texte, par ex: 15 décembre';

COMMIT;
