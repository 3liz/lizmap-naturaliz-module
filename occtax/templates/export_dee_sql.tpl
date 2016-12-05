COPY (

WITH observations AS (
SELECT
xmlelement(
    name "cont:SujetObservation",
    xmlattributes(o.cle_obs AS "gml:id"),

-- Descriptif sujet
    XMLELEMENT(
        name "cont:EstDecritPar",
        XMLELEMENT(
            name "cont:DescriptifSujet",
            xmlforest (
                o.preuve_non_numerique as "cont:preuveNonNumerique",
                o.obs_contexte AS "cont:obsContexte",
                o.preuve_numerique AS "cont:preuveNumerique",
                o.preuve_existante AS "cont:preuveExistante",
                o.occ_statut_biologique AS "cont:occStatutBiologique",
                o.occ_statut_biogeographique AS "cont:occStatutBiogeographique",
                o.occ_stade_de_vie AS "cont:occStadeDeVie",
                o.occ_sexe AS "cont:occSexe",
                o.occ_naturalite AS "cont:occNaturalite",
                o.occ_methode_determination AS "cont:occMethodeDetermination",
                o.occ_etat_biologique AS "cont:occEtatBiologique",
                o.obs_methode AS "cont:obsMethode",
                o.obs_description AS "cont:obsDescription"
            )
        )
    ),

-- Attributs additionels
    XMLELEMENT(
        name "cont:APour",
        (string_agg( distinct
            xmlelement(
                name "cont:AttributAdditionel",
                xmlforest(
                    aa.type as "cont:typeAttribut",
                    aa.thematique as "cont:thematiqueAttribut",
                    aa.unite as "cont:uniteAttribut",
                    aa.valeur as "cont:valeurAttribut",
                    aa.definition as "cont:definitionAttribut",
                    aa.nom as "cont:nomAttribut"
                )
            )::text, ''
        )  FILTER (WHERE aa.nom IS NOT NULL))::xml
    ),

-- Département
    XMLELEMENT(
        name "cont:SeSitueSurDepartement",
        (string_agg( DISTINCT
            xmlelement(
                name "cont:Departement",
                xmlforest(
                    ldep.type_info_geo as "cont:typeInfoGeo",
                    dep.annee_ref as "cont:anneeRef",
                    ldep.code_departement as "cont:codeDepartement"
                )
            )::text, ''
        )  FILTER (WHERE ldep.code_departement IS NOT NULL))::xml
    ),

-- Masses d'eau
    XMLELEMENT(
        name "cont:SeSitueSurMasseEau",
        (string_agg( distinct
            xmlelement(
                name "cont:MasseEau",
                xmlforest(
                    lme.type_info_geo as "cont:typeInfoGeo",
                    me.version_me as "cont:versionME",
                    me.date_me as "cont:dateME",
                    lme.code_me as "cont:codeME"
                )
            )::text, ''
        ) FILTER (WHERE lme.code_me IS NOT NULL))::xml
    ),

-- Mailles 10
    XMLELEMENT(
        name "cont:SeSitueSurMaille",
        (string_agg( distinct
            xmlelement(
                name "cont:Maille10x10",
                xmlforest(
                    lm10.type_info_geo as "cont:typeInfoGeo",
                    m10.nom_ref as "cont:nomRef",
                    m10.version_ref as "cont:versionRef",
                    lm10.code_maille as "cont:codeMaille"
                )
            )::text, ''
        ) FILTER (WHERE lm10.code_maille IS NOT NULL))::xml
    ),

-- Communes
    XMLELEMENT(
        name "cont:SeSitueSurCommune",
        (string_agg( distinct
            xmlelement(
                name "cont:Commune",
                xmlforest(
                    lc.type_info_geo as "cont:typeInfoGeo",
                    com.annee_ref as "cont:anneeRef",
                    com.nom_commune as "cont:nomCommune",
                    lc.code_commune as "cont:codeCommune"
                )
            )::text, ''
        ) FILTER (WHERE lc.code_commune IS NOT NULL))::xml
    ),

-- Source
    XMLELEMENT(
        name "cont:EstSourcePar",
        XMLELEMENT(
            name "cont:Source",
            xmlconcat(
                xmlforest (
                    o.statut_source as "cont:statutSource",
                    o.sensi_version_referentiel AS "cont:sensiVersionReferentiel",
                    o.sensi_referentiel AS "cont:sensiReferentiel",
                    o.sensi_niveau AS "cont:sensiNiveau",
                    o.sensi_date_attribution AS "cont:sensiDateAttribution",
                    o.sensible AS "cont:sensible"
                ),
                XMLELEMENT(
                    name "cont:orgTransformation",
                    XMLELEMENT(
                        NAME "cont:OrganismeType",
                        XMLFOREST(
                            o.organisme_gestionnaire_donnees AS "cont:nomOrganisme"
                        )
                    )
                ),
                XMLELEMENT(
                    name "cont:organismeGestionnaireDonnee",
                    XMLELEMENT(
                        NAME "cont:OrganismeType",
                        XMLFOREST(
                            o.organisme_gestionnaire_donnees AS "cont:nomOrganisme"
                        )
                    )
                ),

                xmlforest (
                    o.jdd_source_id as "cont:jddSourceId",
                    o.jdd_metadonnee_dee_id AS "cont:jddMetadonneeDEEId",
                    o.ds_publique AS "cont:dSPublique",
                    o.diffusion_niveau_precision AS "cont:diffusionNiveauPrecision",
                    o.dee_floutage AS "cont:dEEFloutage",
                    o.dee_date_transformation AS "cont:dEEDateTransformation",
                    o.dee_date_derniere_modification AS "cont:dEEDateDerniereModification",
                    o.code_idcnp_dispositif AS "cont:codeIDCNPDispositif"
                )

            )
        )
    ),


-- Espaces naturels
    XMLELEMENT(
        name "cont:SeSitueSurEspaceNaturel",
        (string_agg( distinct
            xmlelement(
                name "cont:EspaceNaturel",
                xmlforest(
                    len.type_info_geo as "cont:typeInfoGeo",
                    len.version_en as "cont:versionEN",
                    len .code_en as "cont:codeEN",
                    len.type_en as "cont:typeEN"
                )
            )::text, ''
        ) FILTER (WHERE len.code_en IS NOT NULL))::xml
    ),

    xmlelement(
        NAME "cont:commentaire",
        o.commentaire
    ),

-- organisme standard
    XMLELEMENT(
        name "cont:organismeStandard",
        XMLELEMENT(
            NAME "cont:OrganismeType",
            XMLFOREST(
                o.organisme_gestionnaire_donnees AS "cont:nomOrganisme"
            )
        )
    ),

-- Validateurs
    XMLELEMENT(
        name "cont:validateur",
        (string_agg( distinct
            xmlelement(
                name "cont:PersonneType",
                xmlconcat(
                    XMLELEMENT(
                        name "cont:organisme",
                        XMLELEMENT(
                            NAME "cont:OrganismeType",
                            XMLFOREST(
                              pval.organisme AS "cont:nomOrganisme"
                            )
                        )
                    ),

                    xmlforest(
                        pval.mail as "cont:mail",
                        pval.identite as "cont:identite"
                    )
                )
            )::text, ''
        ) FILTER (WHERE pval.id_personne IS NOT NULL))::xml
    ),

    xmlelement(
        NAME "cont:dateDetermination",
        o.date_determination
    ),

-- Déterminateur
    XMLELEMENT(
        name "cont:determinateur",
        (string_agg( distinct
            xmlelement(
                name "cont:PersonneType",
                xmlconcat(
                    XMLELEMENT(
                        name "cont:organisme",
                        XMLELEMENT(
                            NAME "cont:OrganismeType",
                            XMLFOREST(
                              pdet.organisme AS "cont:nomOrganisme"
                            )
                        )
                    ),

                    xmlforest(
                        pdet.mail as "cont:mail",
                        pdet.identite as "cont:identite"
                    )
                )
            )::text, ''
        ) FILTER (WHERE pdet.id_personne IS NOT NULL))::xml
    ),

    xmlconcat(
        xmlforest(
            o.version_taxref as "cont:versionTAXREF",
            o.cd_ref as "cont:cdRef",
            o.cd_nom as "cont:cdNom"
        )
    ),

-- Observateurs
    XMLELEMENT(
        name "cont:observateur",
        xmlagg(
            xmlelement(
                name "cont:PersonneType",
                xmlconcat(
                    XMLELEMENT(
                        name "cont:organisme",
                        XMLELEMENT(
                            NAME "cont:OrganismeType",
                            XMLFOREST(
                              pobs.organisme AS "cont:nomOrganisme"
                            )
                        )
                    ),

                    xmlforest(
                        pobs.mail as "cont:mail",
                        pobs.identite as "cont:identite"
                    )
                )
            )
        ) FILTER (WHERE pobs.id_personne IS NOT NULL)
    ),

-- profondeurs
    xmlconcat(
        xmlforest(
            o.profondeur_min as "cont:profondeurMin",
            o.profondeur_moy as "cont:profondeurMoyenne",
            o.profondeur_max as "cont:profondeurMax"
        )
    ),

-- dénombrement
    XMLELEMENT(
        name "cont:denombrement",
        XMLELEMENT(
            NAME "cont:DenombrememntType",
            XMLFOREST(
                o.type_denombrement AS "cont:typeDenombrement",
                o.objet_denombrement AS "cont:objetDenombrement",
                o.denombrement_max AS "cont:denombrementMax",
                o.denombrement_min AS "cont:denombrementMin"
            )
        )
    ),


-- Habitats
    XMLELEMENT(
        name "cont:habitat",
        (string_agg( distinct
            xmlelement(
                name "cont:HabitatType",
                xmlforest(
                    hab.cd_hab as "cont:codeHabRef",
                    'TODO' as "cont:versionRef",
                    lhab.code_habitat as "cont:codeHabitat",
                    lhab.ref_habitat as "cont:refHabitat"
                )
            )::text, ''
        ) FILTER (WHERE lhab.code_habitat IS NOT NULL))::xml
    ),

-- altitude et dates
    xmlconcat(
        xmlforest(
            o.altitude_min as "cont:altitudeMin",
            o.altitude_moy as "cont:altitudeMoyenne",
            o.altitude_max as "cont:altitudeMax",
            o.date_debut + o.heure_debut AS "cont:dateDebut",
            o.date_fin + o.heure_fin AS "cont:dateFin"
        )
    ),

-- objet geo
    XMLELEMENT(
        name "cont:objetGeo",
        XMLELEMENT(
            NAME "cont:ObjetGeographiqueType",
            xmlattributes(o.cle_obs AS "gml:id"),
            xmlconcat(
                XMLFOREST(
                    o.precision_geometrie AS "cont:precisionGeometrie",
                    o.nature_objet_geo AS "cont:natureObjetGeo"
                ),
                xmlelement(
                    NAME "cont:geometrie",
                    ST_AsGML(o.geom)::xml
                )
            )
        )
    ),

    xmlconcat(
        xmlforest(
            o.nom_cite as "cont:nomCite",
            o.statut_observation as "cont:statutObservation",
            o.identifiant_permanent as "cont:identifiantPermanent"
        )
    )

) AS "xml"


FROM occtax.observation o
INNER JOIN v_observateur pobs ON pobs.cle_obs = o.cle_obs
LEFT JOIN v_validateur pval ON pval.cle_obs = o.cle_obs
LEFT JOIN v_determinateur pdet ON pdet.cle_obs = o.cle_obs
LEFT JOIN localisation_departement ldep ON ldep.cle_obs = o.cle_obs
LEFT JOIN departement dep ON dep.code_departement = ldep.code_departement
LEFT JOIN localisation_commune lc ON lc.cle_obs = o.cle_obs
LEFT JOIN commune com ON com.code_commune = lc.code_commune
LEFT JOIN localisation_masse_eau lme ON lme.cle_obs = o.cle_obs
LEFT JOIN masse_eau me ON me.code_me = lme.code_me
LEFT JOIN localisation_maille_10 lm10 ON lm10.cle_obs = o.cle_obs
LEFT JOIN maille_10 m10 ON m10.code_maille = lm10.code_maille
LEFT JOIN v_localisation_espace_naturel len ON len.cle_obs = o.cle_obs
LEFT JOIN localisation_habitat lhab ON lhab.cle_obs = o.cle_obs
LEFT JOIN habitat hab ON hab.code_habitat = lhab.code_habitat AND lhab.ref_habitat = hab.ref_habitat
LEFT JOIN attribut_additionnel aa ON aa.cle_obs = o.cle_obs

{$geoFilter}

{$where}

GROUP BY o.cle_obs
-- LIMIT 3000

)

SELECT
    xmlelement(
        name "gml:featureMember",
        observations."xml"
    )::text AS "xml"
FROM observations

)  TO {$path};


