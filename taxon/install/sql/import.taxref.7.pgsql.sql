TRUNCATE taxref RESTART IDENTITY CASCADE;
SET client_encoding TO 'Latin1';
COPY taxref
(regne, phylum, classe, ordre, famille, group1_inpn, group2_inpn, cd_nom, cd_taxsup, cd_ref, rang, lb_nom, lb_auteur, nom_complet, nom_valide, nom_vern, nom_vern_eng, habitat, fr, gf, mar, gua, sm, sb, spm, may, epa, reu, taaf, pf, nc, wf, cli, url)
FROM '{$source}' DELIMITER E'\t' HEADER CSV;
RESET client_encoding;

-- Ajout des données dans la table taxref_valide
TRUNCATE TABLE taxref_valide;
INSERT INTO taxref_valide (regne, phylum, classe, ordre, famille, group1_inpn, group2_inpn, cd_nom, cd_taxsup, cd_ref, rang, lb_nom, lb_auteur, nom_complet, nom_valide, nom_vern, nom_vern_eng, habitat, fr, gf, mar, gua, sm, sb, spm, may, epa, reu, taaf, pf, nc, wf, cli, url)
SELECT regne, phylum, classe, ordre, famille, group1_inpn, group2_inpn, cd_nom, cd_taxsup, cd_ref, rang, lb_nom, lb_auteur, nom_complet, nom_valide, nom_vern, nom_vern_eng, habitat, fr, gf, mar, gua, sm, sb, spm, may, epa, reu, taaf, pf, nc, wf, cli, url
FROM taxref
WHERE cd_nom = cd_ref
AND rang IN ('AGES','ES','SMES','MES','SSES','NAT','HYB','CVAR','VAR','SVAR','FO','SSFO','FOES','LIN','CLO','CAR','RACE','MO','AB');
