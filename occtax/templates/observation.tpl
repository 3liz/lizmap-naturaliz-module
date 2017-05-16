<div class="" style="min-width:250px;">
    <h3>
        <span class="title">
            <span class="text">{@occtax~observation.fiche.title@}</span>
            </span>
    </h3>

    <div style="height:100%;overflow:auto;">

    <h3 class="dock-subtitle">{@occtax~observation.title.quoi@}</h3>
    <div class="dock-content">
        <table class="table table-condensed table-striped">
            {if array_key_exists('cle_obs', $data)}
            <tr>
                <th>{@occtax~observation.output.cle_obs@}</th>
                <td>{$data['cle_obs']}</td>
            </tr>
            {/if}

            {if array_key_exists('identifiant_permanent', $data)}
            <tr>
            <tr>
                <th>{@occtax~observation.output.identifiant_permanent@}</th>
                <td>{$data['identifiant_permanent']}</td>
            </tr>
            {/if}

            {if array_key_exists('statut_observation', $data)}
            <tr>
                <th>{@occtax~observation.output.statut_observation@}</th>
                <td>{$data['statut_observation']}</td>
            </tr>
            {/if}

            {if array_key_exists('cd_nom', $data)}
            <tr>
                <th>{@occtax~observation.output.cd_nom@}</th>
                <td>{$data['cd_nom']}</td>
            </tr>
            {/if}

            {if array_key_exists('cd_ref', $data)}
            <tr>
                <th>{@occtax~observation.output.cd_ref@}</th>
                <td>{$data['cd_ref']}</td>
            </tr>
            {/if}

            {if array_key_exists('nom_cite', $data)}
            <tr>
                <th>{@occtax~observation.output.nom_cite@}</th>
                <td>{$data['nom_cite']}</td>
            </tr>
            {/if}

            {if array_key_exists('denombrement_min', $data)}
            <tr>
                <th>{@occtax~observation.output.denombrement_min@}</th>
                <td>{$data['denombrement_min']}</td>
            </tr>
            {/if}

            {if array_key_exists('denombrement_max', $data)}
            <tr>
                <th>{@occtax~observation.output.denombrement_max@}</th>
                <td>{$data['denombrement_max']}</td>
            </tr>
            {/if}

            {if array_key_exists('objet_denombrement', $data)}
            <tr>
                <th>{@occtax~observation.output.objet_denombrement@}</th>
                <td>{$data['objet_denombrement']}</td>
            </tr>
            {/if}

            {if array_key_exists('type_denombrement', $data)}
            <tr>
                <th>{@occtax~observation.output.type_denombrement@}</th>
                <td>{$data['type_denombrement']}</td>
            </tr>
            {/if}

            {if array_key_exists('commentaire', $data)}
            <tr>
                <th>{@occtax~observation.output.commentaire@}</th>
                <td>{$data['commentaire']}</td>
            </tr>
            {/if}
        </table>
    </div>



    <h3 class="dock-subtitle">{@occtax~observation.title.source@}</h3>
    <div class="dock-content">
        <table class="table table-condensed table-striped">
            {if array_key_exists('code_idcnp_dispositif', $data)}
            <tr>
                <th>{@occtax~observation.output.code_idcnp_dispositif@}</th>
                <td>{$data['code_idcnp_dispositif']}</td>
            </tr>
            {/if}

            {if array_key_exists('dee_date_derniere_modification', $data)}
            <tr>
                <th>{@occtax~observation.output.dee_date_derniere_modification@}</th>
                <td>{$data['dee_date_derniere_modification']}</td>
            </tr>
            {/if}

            {if array_key_exists('dee_date_transformation', $data)}
            <tr>
                <th>{@occtax~observation.output.dee_date_transformation@}</th>
                <td>{$data['dee_date_transformation']}</td>
            </tr>
            {/if}

            {if array_key_exists('dee_floutage', $data)}
            <tr>
                <th>{@occtax~observation.output.dee_floutage@}</th>
                <td>{$data['dee_floutage']}</td>
            </tr>
            {/if}

            {if array_key_exists('diffusion_niveau_precision', $data)}
            <tr>
                <th>{@occtax~observation.output.diffusion_niveau_precision@}</th>
                <td>{$data['diffusion_niveau_precision']}</td>
            </tr>
            {/if}

            {if array_key_exists('ds_publique', $data)}
            <tr>
                <th>{@occtax~observation.output.ds_publique@}</th>
                <td>{$data['ds_publique']}</td>
            </tr>
            {/if}

            {if array_key_exists('identifiant_origine', $data)}
            <tr>
                <th>{@occtax~observation.output.identifiant_origine@}</th>
                <td>{$data['identifiant_origine']}</td>
            </tr>
            {/if}

            {if array_key_exists('jdd_code', $data)}
            <tr>
                <th>{@occtax~observation.output.jdd_code@}</th>
                <td>{$data['jdd_code']}</td>
            </tr>
            {/if}

            {if array_key_exists('jdd_id', $data)}
            <tr>
                <th>{@occtax~observation.output.jdd_id@}</th>
                <td>{$data['jdd_id']}</td>
            </tr>
            {/if}

            {if array_key_exists('jdd_metadonnee_dee_id', $data)}
            <tr>
                <th>{@occtax~observation.output.jdd_metadonnee_dee_id@}</th>
                <td>{$data['jdd_metadonnee_dee_id']}</td>
            </tr>
            {/if}

            {if array_key_exists('jdd_source_id', $data)}
            <tr>
                <th>{@occtax~observation.output.jdd_source_id@}</th>
                <td>{$data['jdd_source_id']}</td>
            </tr>
            {/if}

            {if array_key_exists('organisme_gestionnaire_donnees', $data)}
            <tr>
                <th>{@occtax~observation.output.organisme_gestionnaire_donnees@}</th>
                <td>{$data['organisme_gestionnaire_donnees']}</td>
            </tr>
            {/if}

            {if array_key_exists('org_transformation', $data)}
            <tr>
                <th>{@occtax~observation.output.org_transformation@}</th>
                <td>{$data['org_transformation']}</td>
            </tr>
            {/if}

            {if array_key_exists('statut_source', $data)}
            <tr>
                <th>{@occtax~observation.output.statut_source@}</th>
                <td>{$data['statut_source']}</td>
            </tr>
            {/if}

            {if array_key_exists('reference_biblio', $data)}
            <tr>
                <th>{@occtax~observation.output.reference_biblio@}</th>
                <td>{$data['reference_biblio']}</td>
            </tr>
            {/if}

            {if array_key_exists('sensible', $data)}
            <tr>
                <th>{@occtax~observation.output.sensible@}</th>
                <td>{$data['sensible']}</td>
            </tr>
            {/if}

            {if array_key_exists('sensi_date_attribution', $data)}
            <tr>
                <th>{@occtax~observation.output.sensi_date_attribution@}</th>
                <td>{$data['sensi_date_attribution']}</td>
            </tr>
            {/if}

            {if array_key_exists('sensi_niveau', $data)}
            <tr>
                <th>{@occtax~observation.output.sensi_niveau@}</th>
                <td>{$data['sensi_niveau']}</td>
            </tr>
            {/if}

            {if array_key_exists('sensi_referentiel', $data)}
            <tr>
                <th>{@occtax~observation.output.sensi_referentiel@}</th>
                <td>{$data['sensi_referentiel']}</td>
            </tr>
            {/if}

            {if array_key_exists('sensi_version_referentiel', $data)}
            <tr>
                <th>{@occtax~observation.output.sensi_version_referentiel@}</th>
                <td>{$data['sensi_version_referentiel']}</td>
            </tr>
            {/if}

            {if array_key_exists('validite_niveau', $data)}
            <tr>
                <th>{@occtax~observation.output.validite_niveau@}</th>
                <td>{$data['validite_niveau']}</td>
            </tr>
            {/if}

            {if array_key_exists('validite_date_validation', $data)}
            <tr>
                <th>{@occtax~observation.output.validite_date_validation@}</th>
                <td>{$data['validite_date_validation']}</td>
            </tr>
            {/if}
        </table>
    </div>

    {if array_key_exists('descriptif_sujet', $data) and !empty($data['descriptif_sujet'])}
    <h3 class="dock-subtitle">{@occtax~observation.title.descriptif.sujet@}</h3>
    <div class="dock-content">

        {assign $descriptif_sujet = json_decode($data['descriptif_sujet'])}

        <ul class="nav nav-tabs">
        {assign $i = 0}
        {foreach $descriptif_sujet as $ds}
          <li><a data-toggle="tab" href="#descriptif_sujet_{$i}">Descriptif du sujet {$i}</a></li>
        {assign $i = $i + 1}
        {/foreach}
        </ul>

        <div class="tab-content">
        {assign $i = 0}
        {foreach $descriptif_sujet as $ds}
          <div id="descriptif_sujet_{$i}" class="tab-pane">
            <table class="table table-condensed table-striped">
                {foreach $ds as $key => $val}
                {if in_array($key, $observation_card_fields)}
                <tr>
                    <th>{@occtax~observation.output.$key@}</th>
                    <td>{$val}</td>
                </tr>
                {/if}
                {/foreach}
            </table>
          </div>
        {assign $i = $i + 1}
        {/foreach}
        </div>
    </div>
    {/if}


    <h3 class="dock-subtitle">{@occtax~observation.title.qui@}</h3>
    <div class="dock-content">
        <table class="table table-condensed table-striped">

            {if array_key_exists('observateur', $data)}
            <tr>
                <th>{@occtax~observation.output.observateur@}</th>
                <td>{$data['observateur']}</td>
            </tr>
            {/if}

            {if array_key_exists('determinateur', $data)}
            <tr>
                <th>{@occtax~observation.output.determinateur@}</th>
                <td>{$data['determinateur']}</td>
            </tr>
            {/if}

            {if array_key_exists('validateur', $data)}
            <tr>
                <th>{@occtax~observation.output.validateur@}</th>
                <td>{$data['validateur']}</td>
            </tr>
            {/if}

        </table>
    </div>

    <h3 class="dock-subtitle">{@occtax~observation.title.quand@}</h3>
    <div class="dock-content">
        <table class="table table-condensed table-striped">

            {if array_key_exists('date_debut', $data)}
            <tr>
                <th>{@occtax~observation.output.date_debut@}</th>
                <td>{$data['date_debut']}</td>
            </tr>
            {/if}

            {if array_key_exists('heure_debut', $data)}
            <tr>
                <th>{@occtax~observation.output.heure_debut@}</th>
                <td>{$data['heure_debut']}</td>
            </tr>
            {/if}

            {if array_key_exists('date_fin', $data)}
            <tr>
                <th>{@occtax~observation.output.date_fin@}</th>
                <td>{$data['date_fin']}</td>
            </tr>
            {/if}

            {if array_key_exists('heure_fin', $data)}
            <tr>
                <th>{@occtax~observation.output.heure_fin@}</th>
                <td>{$data['heure_fin']}</td>
            </tr>
            {/if}

            {if array_key_exists('date_determination', $data)}
            <tr>
                <th>{@occtax~observation.output.date_determination@}</th>
                <td>{$data['date_determination']}</td>
            </tr>
            {/if}

        </table>
    </div>

    <h3 class="dock-subtitle">{@occtax~observation.title.ou@}</h3>
    <div class="dock-content">
        <table class="table table-condensed table-striped">

            {if array_key_exists('altitude_min', $data)}
            <tr>
                <th>{@occtax~observation.output.altitude_min@}</th>
                <td>{$data['altitude_min']}</td>
            </tr>
            {/if}

            {if array_key_exists('altitude_moy', $data)}
            <tr>
                <th>{@occtax~observation.output.altitude_moy@}</th>
                <td>{$data['altitude_moy']}</td>
            </tr>
            {/if}

            {if array_key_exists('altitude_max', $data)}
            <tr>
                <th>{@occtax~observation.output.altitude_max@}</th>
                <td>{$data['altitude_max']}</td>
            </tr>
            {/if}

            {if array_key_exists('profondeur_min', $data)}
            <tr>
                <th>{@occtax~observation.output.profondeur_min@}</th>
                <td>{$data['profondeur_min']}</td>
            </tr>
            {/if}

            {if array_key_exists('profondeur_moy', $data)}
            <tr>
                <th>{@occtax~observation.output.profondeur_moy@}</th>
                <td>{$data['profondeur_moy']}</td>
            </tr>
            {/if}

            {if array_key_exists('profondeur_max', $data)}
            <tr>
                <th>{@occtax~observation.output.profondeur_max@}</th>
                <td>{$data['profondeur_max']}</td>
            </tr>
            {/if}

            {if array_key_exists('habitat', $children)}
            <tr>
                <th>{@occtax~observation.output.code_habitat@}</th>
                <td>
                {foreach $children['habitat'] as $item}
                    {$item->code_habitat}<br/>
                {/foreach}
                </td>
            </tr>
            {/if}

            {if array_key_exists('habitat', $children)}
            <tr>
                <th>{@occtax~observation.output.ref_habitat@}</th>
                <td>
                {foreach $children['habitat'] as $item}
                    {$item->ref_habitat}<br/>
                {/foreach}
                </td>
            </tr>
            {/if}

            {if array_key_exists('precision_geometrie', $data)}
            <tr>
                <th>{@occtax~observation.output.precision_geometrie@}</th>
                <td>{$data['precision_geometrie']}</td>
            </tr>
            {/if}

            {if array_key_exists('nature_objet_geo', $data)}
            <tr>
                <th>{@occtax~observation.output.nature_objet_geo@}</th>
                <td>{$data['nature_objet_geo']}</td>
            </tr>
            {/if}

            {if array_key_exists('commune', $children)}
            <tr>
                <th>{@occtax~observation.output.code_commune@}</th>
                <td>
                {foreach $children['commune'] as $item}
                    {$item->code_commune} {$item->nom_commune} ({$item->annee_ref})<br/>
                {/foreach}
                </td>
            </tr>
            {/if}

            {if array_key_exists('departement', $children)}
            <tr>
                <th>{@occtax~observation.output.code_departement@}</th>
                <td>

                {foreach $children['departement'] as $item}
                    {$item->code_departement} {$item->nom_departement} ({$item->annee_ref})<br/>
                {/foreach}
                </td>
            </tr>
            {/if}

            {if array_key_exists('espace_naturel', $children)}
            <tr>
                <th>{@occtax~observation.output.code_en@}</th>
                <td>
                {foreach $children['espace_naturel'] as $item}
                    {$item->code_en} - {$item->nom_en} ({$item->type_en}) (version {$item->version_en})<br/>
                {/foreach}
                </td>
            </tr>
            {/if}

            {if array_key_exists('maille', $children)}
            <tr>
                <th>{@occtax~observation.output.code_maille@}</th>
                <td>
                {foreach $children['maille'] as $item}
                    {$item->code_maille} (version {$item->version_ref})<br/>
                {/foreach}
                </td>
            </tr>
            {/if}

            {if array_key_exists('masse_eau', $children)}
            <tr>
                <th>{@occtax~observation.output.code_me@}</th>
                <td>
                {foreach $children['masse_eau'] as $item}
                    {$item->code_me} (version {$item->version_me}, {$item->date_me})<br/>
                {/foreach}
                </td>
            </tr>
            {/if}

        </table>
    </div>

    {if array_key_exists('attribut_additionnel', $children)}
    <h3 class="dock-subtitle">{@occtax~observation.title.aa@}</h3>
    <div class="dock-content">


        <table class="table table-condensed table-striped">
            {foreach $children['attribut_additionnel'] as $item}
            <tr>
                <th title="{$item->definition}">{$item->nom} ({$item->thematique} - {$item->type})</th>
                <td>{$item->valeur} {$item->unite}</td>
            </tr>
            {/foreach}
        </table>
        <br/><br/>
    </div>
    {/if}

    </div>
</div>
