-- Métadonnées

-- Ajout du champ url_fiche dans la table occtax.cadre
ALTER TABLE occtax.cadre ADD COLUMN IF NOT EXISTS url_fiche text;
COMMENT ON COLUMN occtax.cadre.url_fiche IS 'URL de la fiche descriptive du cadre d''acquisition. Selon que la fiche est déjà publiée ou pas sur l''INPN, la fiche est au format "grand public" (de type https://inpn.mnhn.fr/espece/cadre/5313 pour le jdd_id = 10607) ou moins ergonomique issue de l''application de métadonnées (de type https://inpn.mnhn.fr/mtd/cadre/edit/5313). Ce champ est rempli lors de l''import d''un nouveau jeu de données avec la valeur par défaut https://inpn.mnhn.fr/mtd/cadre/edit/ + jdd_id. Il doit être mis à jour manuellement le cas échéant à chaque nouvel import des données régionales dans l''INPN pour prendre son format définitif https://inpn.mnhn.fr/espece/cadre/5313 + cadre_id.' ;

UPDATE occtax.cadre SET url_fiche = CONCAT('https://inpn.mnhn.fr/mtd/cadre/edit/', cadre_id)
WHERE url_fiche IS NULL;

-- Ajout du champ url_fiche dans la table occtax.jdd
ALTER TABLE occtax.jdd ADD COLUMN IF NOT EXISTS url_fiche TEXT ;
COMMENT ON COLUMN occtax.jdd.url_fiche IS 'URL de la fiche descriptive du jeu de données. Selon que la fiche est déjà publiée ou pas sur l''INPN, la fiche est au format "grand public" (de type https://inpn.mnhn.fr/espece/jeudonnees/10607 pour le jdd_id = 10607) ou moins ergonomique issue de l''application de métadonnées (de type https://inpn.mnhn.fr/mtd/cadre/jdd/edit/10607). Ce champ est rempli lors de l''import d''un nouveau jeu de données avec la valeur par défaut https://inpn.mnhn.fr/mtd/cadre/jdd/edit/ + jdd_id. Il doit être mis à jour manuellement le cas échéant à chaque nouvel import des données régionales dans l''INPN pour prendre son format définitif https://inpn.mnhn.fr/espece/jeudonnees/ + jdd_id.';

UPDATE occtax.jdd SET url_fiche = CONCAT('https://inpn.mnhn.fr/mtd/cadre/jdd/edit/', jdd_id)
WHERE url_fiche IS NULL;
