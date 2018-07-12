BEGIN;

-- INFO
-- * Il n'existe aucune ligne dans TAXREF_CHANGES avec une modification du champ CD_NOM --> seulement des RETRAIT ou des AJOUT
-- * Seules les lignes concernant les RETRAIT nous intéressent (car les ajouts ne sont pas référencées par les observations)
-- * Pour les raison de retrait == 1 --> on va chercher dans la source CDNOM_DISPARUS le nouveau CD_NOM
-- * Pour les raisons de retrait == 2 -> on ne fait rien, car le taxon peut revenir
-- * Pour les raison de retrait == 3 --> on déplace les observations dans une autre table "occtax.observation_retrait_taxon_cas_3


-- Schéma de travail
CREATE SCHEMA IF NOT EXISTS fdw;

-- importer le fichier TAXREF_CHANGES
DROP TABLE IF EXISTS fdw.taxref_changes;
CREATE TABLE fdw.taxref_changes (
    cd_nom text,
    num_version_init text,
    num_version_final text,
    champ text,
    valeur_init text,
    valeur_final text,
    type_change text
);
COPY fdw.taxref_changes FROM '/tmp/TAXREF_CHANGES_UTF-8.txt' DELIMITER E'\t' HEADER CSV;

-- Importer le fichier CD_NOMS_DISPARUS
DROP TABLE IF EXISTS fdw.cd_nom_disparus;
CREATE TABLE fdw.cd_nom_disparus (
    cd_nom text,
    plus_recente_diffusion text,
    cd_nom_remplacement text,
    cd_raison_suppression text,
    raison_suppression text
);
COPY fdw.cd_nom_disparus FROM '/tmp/CDNOM_DISPARUS.csv' DELIMITER E'\t' HEADER CSV;

--  Lister et récupérer dans une table l'ensemble des cd_nom qui sont marqués "RETRAIT" dans le TAXREF_CHANGES ET qui concernent des observations de la table occtax.observation
DROP TABLE IF EXISTS fdw.observation_chg_taxon_cd_nom;
CREATE TABLE fdw.observation_chg_taxon_cd_nom AS
SELECT o.cle_obs, o.cd_nom, o.cd_ref
FROM occtax.observation o,
fdw.taxref_changes AS tc
LEFT JOIN fdw.cd_nom_disparus d ON d.cd_nom = tc.cd_nom
WHERE TRUE
AND tc.champ = 'CD_NOM'
AND tc.type_change = 'RETRAIT'
AND d.cd_raison_suppression = '1'
AND o.cd_nom::text = tc.cd_nom
;

-- Lancer la requête d'UPDATE des cd_nom de occtax.observation à partir de taxref_changes
UPDATE occtax.observation AS o
SET cd_nom =  cd_nom_remplacement::bigint,
dee_date_derniere_modification = now()
FROM fdw.taxref_changes AS tc
LEFT JOIN fdw.cd_nom_disparus d ON d.cd_nom = tc.cd_nom
WHERE TRUE
AND tc.champ= 'CD_NOM'
AND tc.type_change = 'RETRAIT'
AND d.cd_raison_suppression = '1'
AND o.cd_nom::text = tc.cd_nom
;

-- Lancer la requête d'UPDATE des cd_ref de occtax.observation à partir de TAXREF v8
-- pour les observations concernées par RETRAIT de cd_nom avec cd_raison_suppresion = 1
UPDATE occtax.observation AS o
SET cd_ref = t.cd_ref,
dee_date_derniere_modification = now()
FROM taxon.taxref AS t
WHERE  TRUE
AND t.cd_nom = o.cd_nom
AND o.cle_obs IN ( SELECT DISTINCT c.cle_obs FROM fdw.observation_chg_taxon_cd_nom AS c )
;

-- Metre à jour le CD_REF pour les observations concernées par un CD_NOM qui a changé de CD_REF
-- TEST
SELECT o.cle_obs, o.cd_nom, o.cd_ref, valeur_init, valeur_final, o.identifiant_origine, o.jdd_id
FROM occtax.observation o,
fdw.taxref_changes tc
WHERE TRUE
AND o.cd_nom::text = tc.cd_nom
AND tc.champ = 'CD_REF'
AND tc.type_change = 'MODIFICATION'
AND o.cd_ref::text = tc.valeur_init
;
-- UPDATE
UPDATE occtax.observation o
-- SET cd_ref = tc.valeur_final::bigint -- cd_ref doit aussi être modifié
SET
cd_ref = tc.valeur_final::bigint,
dee_date_derniere_modification = now()
FROM fdw.taxref_changes tc
WHERE TRUE
AND o.cd_nom::text = tc.cd_nom
AND tc.champ = 'CD_REF'
AND tc.type_change = 'MODIFICATION'
AND o.cd_ref::text = tc.valeur_init
;

-- Modifier le cd_nom dans la table taxon.taxon_sensible, au cas où des taxons sont concernés
-- ( cette table est utilisée par le PN Guadeloupe en amont des critères de sensibilité)
UPDATE taxon.taxon_sensible AS o
SET cd_nom = cd_nom_remplacement::bigint
FROM fdw.taxref_changes AS tc
LEFT JOIN fdw.cd_nom_disparus d ON d.cd_nom = tc.cd_nom
WHERE TRUE
AND tc.champ = 'CD_NOM'
AND tc.type_change = 'RETRAIT'
AND cd_raison_suppression = '1'
AND o.cd_nom::text = tc.cd_nom
;

-- TAXREF_LOCAL
-- Penser à regarder le contenu de la table taxref_local qui contient des cd_nom négatifs ( et normalement pas de cd_ref )
-- Si des taxons ont été intégrés au TAXREF, il faut :
-- * créer une table de correspondance avec taxref_local.cd_nom = cd_nom_new_taxref
-- * mettre à jour la table occtax.observation pour remplacer le cd_nom négatif par le cd_nom du nouveau TAXREF
-- * supprimer les lignes de taxref_local concernées
CREATE TABLE IF NOT EXISTS fdw.taxon_local_correspondance (
    nom_local text,
    cd_nom_local integer NOT NULL UNIQUE,
    cd_nom_new_taxref integer NOT NULL,
    cd_ref_new_taxref integer NOT NULL
);

-- Insérer les valeurs manuellement après controle de la table taxref_local, par exemple :
-- INSERT INTO fdw.taxon_local_correspondance VALUES ( 'karunatus guadalupus', -12345678, 888888, 999999 );

-- Faire l'update de la table observation
UPDATE occtax.observation AS o
SET ( cd_nom, cd_ref ) = ( lc.cd_nom_new_taxref, lc.cd_ref_new_taxref )
FROM fdw.taxon_local_correspondance lc
WHERE o.cd_nom = lc.cd_nom_local
;
-- Supprimer les lignes de taxon_local concernées par des taxons intégrés au TAXREF_V_N+1
DELETE FROM taxon.taxref_local
WHERE cd_nom IN ( SELECT DISTINCT cd_nom_local FROM fdw.taxon_local_correspondance )
;

-- Mis à jour taxref_local un champ destiné à assurer la traçabilité.
-- Traitement de la table taxref_local
-- TODO : a vérifier

-- 1/ Mise à jour de cd_nom_valide pour les taxons locaux désormais intégrés à Taxref
WITH loc AS (
    SELECT tl.cd_nom AS cd_nom_old, t.cd_nom AS cd_nom_new, t.cd_ref AS cd_ref_new, tl.lb_nom, tl.nom_vern, t.nom_vern, tl.group2_inpn, t.rang, tl.cd_nom_valide
    FROM taxon.taxref_local tl
    INNER JOIN taxon.taxref t USING(lb_nom)
    )
UPDATE taxon.taxref_local tl
SET cd_nom_valide=loc.cd_nom_new
FROM loc
WHERE cd_nom=loc.cd_nom_old
;

-- 2/ Mise à jour de la table occtax.observation en conséquence
WITH loc AS (
    SELECT tl.cd_nom AS cd_nom_old, t.cd_nom AS cd_nom_new, t.cd_ref AS cd_ref_new, tl.lb_nom, tl.nom_vern, t.nom_vern, tl.group2_inpn, t.rang, tl.cd_nom_valide
    FROM taxon.taxref_local tl
    INNER JOIN taxon.taxref t USING(lb_nom)
    ),
maj AS (
    SELECT o.cle_obs,
    o.cd_nom AS cd_nom_old,
    loc.cd_nom_new,
    o.cd_ref AS cd_ref_old,
    loc.cd_ref_new
    FROM occtax.observation o
    INNER JOIN loc ON loc.cd_nom_old=o.cd_nom
    )

UPDATE occtax.observation o
SET cd_nom=maj.cd_nom_new,
    cd_ref=maj.cd_ref_new,
    dee_date_derniere_modification=now()
FROM maj
WHERE o.cle_obs=maj.cle_obs
;
-------------------------------------------------------------------------

-- Déplacer les observations du cas RETRAIT , raison 3 dans une autre table occtax/observation_taxon_invalide
-- TODO : il est plus judicieux de garder les obs concernées et de les mettre en douteuses si besoin. Mettre une nouvelle ligne dans taxref_local si besoin
CREATE TABLE IF NOT EXISTS occtax.observation_retrait_taxon_cas_3 (
    cle_obs bigint NOT NULL,
    identifiant_permanent text NOT NULL,
    cd_nom bigint NOT NULL,
    cd_ref bigint NOT NULL,
    jdd_id text NOT NULL,
    identifiant_origine text NOT NULL
);
INSERT INTO occtax.observation_retrait_taxon_cas_3
SELECT o.cle_obs, o.identifiant_permanent, o.cd_nom, o.cd_ref, o.jdd_id, o.identifiant_origine
FROM occtax.observation o,
fdw.taxref_changes AS tc
LEFT JOIN fdw.cd_nom_disparus d ON d.cd_nom = tc.cd_nom
WHERE TRUE
AND tc.champ = 'CD_NOM'
AND tc.type_change = 'RETRAIT'
AND cd_raison_suppression = '3'
AND o.cd_nom::text = tc.cd_nom
;

-- Supprimer les observation de occtax.observation concernées par ces modifications de cas 3
DELETE FROM occtax.observation
WHERE TRUE
AND identifiant_permanent IN (
    SELECT DISTINCT identifiant_permanent FROM occtax.observation_retrait_taxon_cas_3
)
;

-- Mise à jour du champ version_taxref de occtax.observation
UPDATE occtax.observation o
SET version_taxref='11.0'
WHERE o.cd_nom>0 -- Seulement pour les taxons dans Taxref (pas ceux dans Taxref_local)
;

-- A FINALISER
-- Valentin vérifie comment gérer les taxons qui était dans taxref_local et qui sont maintenant dans taxref v N+1 : soit via table taxon_local_correspondance soit via nouveau champ cd_nom_valide -> privilégier la 2ème.
-- pour les retraits de type 2, ajouter le taxon dans taxref_local pour ne pas perdre les correspondances sur ces taxon disparus

-- PENSE BETE : a vérifier et à faire

-- Rafraîchir les vues matérialisées basées sur occtax.observation
-- Relancer les scripts de calcul de la sensibilité et de la validation

COMMIT;
