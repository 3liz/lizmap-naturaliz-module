INSERT INTO nomenclature (champ, code, valeur, description) VALUES ('occ_objet_denombrement', 'COL', 'Colonie', 'Nombre de colonies observées.') ON CONFLICT DO NOTHING;
INSERT INTO nomenclature (champ, code, valeur, description) VALUES ('occ_objet_denombrement', 'CPL', 'Couple', 'Nombre de couples observé.') ON CONFLICT DO NOTHING;
INSERT INTO nomenclature (champ, code, valeur, description) VALUES ('occ_objet_denombrement', 'HAM', 'Hampe florale', 'Nombre de hampes florales observées.') ON CONFLICT DO NOTHING;
INSERT INTO nomenclature (champ, code, valeur, description) VALUES ('occ_objet_denombrement', 'IND', 'Individu', 'Nombre d''individus observés.') ON CONFLICT DO NOTHING;
INSERT INTO nomenclature (champ, code, valeur, description) VALUES ('occ_objet_denombrement', 'NID', 'Nid', 'Nombre de nids observés.') ON CONFLICT DO NOTHING;
INSERT INTO nomenclature (champ, code, valeur, description) VALUES ('occ_objet_denombrement', 'NSP', 'Ne Sait Pas', 'La méthode de dénombrement n''est pas connue.') ON CONFLICT DO NOTHING;
INSERT INTO nomenclature (champ, code, valeur, description) VALUES ('occ_objet_denombrement', 'PON', 'Ponte', 'Nombre de pontes observées.') ON CONFLICT DO NOTHING;
INSERT INTO nomenclature (champ, code, valeur, description) VALUES ('occ_objet_denombrement', 'SURF', 'Surface', 'Zone aréale occupée par le taxon, en mètres carrés.') ON CONFLICT DO NOTHING;
INSERT INTO nomenclature (champ, code, valeur, description) VALUES ('occ_objet_denombrement', 'TIGE', 'Tige', 'Nombre de tiges observées.') ON CONFLICT DO NOTHING;
INSERT INTO nomenclature (champ, code, valeur, description) VALUES ('occ_objet_denombrement', 'TOUF', 'Touffe', 'Nombre de touffes observées.') ON CONFLICT DO NOTHING;

INSERT INTO nomenclature (champ, code, valeur, description) VALUES ('occ_type_denombrement', 'Ca', 'Calculé', 'Calculé : Dénombrement par opération mathématique') ON CONFLICT DO NOTHING;
INSERT INTO nomenclature (champ, code, valeur, description) VALUES ('occ_type_denombrement', 'Co', 'Compté', 'Compté : Dénombrement par énumération des individus') ON CONFLICT DO NOTHING;
INSERT INTO nomenclature (champ, code, valeur, description) VALUES ('occ_type_denombrement', 'Es', 'Estimé', 'Estimé : Dénombrement qualifié d’estimé lorsque le produit concerné n''a fait l''objet d''aucune action de détermination de cette valeur du paramètre par le biais d''une technique de mesure.') ON CONFLICT DO NOTHING;
INSERT INTO nomenclature (champ, code, valeur, description) VALUES ('occ_type_denombrement', 'NSP', 'Ne sait pas', 'Ne sait Pas : La méthode de dénombrement n’est pas connue') ON CONFLICT DO NOTHING;
