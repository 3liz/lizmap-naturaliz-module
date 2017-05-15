TRUNCATE taxref RESTART IDENTITY CASCADE;
SET client_encoding TO 'Latin1';
COPY taxref
(regne, phylum, classe, ordre, famille, group1_inpn, group2_inpn, cd_nom, cd_taxsup, cd_ref, rang, lb_nom, lb_auteur, nom_complet, nom_valide, nom_vern, nom_vern_eng, habitat, fr, gf, mar, gua, sm, sb, spm, may, epa, reu, taaf, pf, nc, wf, cli, url)
FROM '{$source}' DELIMITER E'\t' HEADER CSV;
RESET client_encoding;
