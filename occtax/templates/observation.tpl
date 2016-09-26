<div class="" style="min-width:250px;">
    <h3>
        <span class="title">
            <span class="text">{@occtax~observation.fiche.title@}</span>
                <i class="pull-right close icon-remove icon-white"></i>
            </span>
    </h3>

    <div style="height:100%;overflow:auto;">

    <h3 class="dock-subtitle">{@occtax~observation.title.quoi@}</h3>
    <div class="dock-content">
        <table class="table table-condensed table-striped">

            <tr>
                <th>{@occtax~observation.output.statut_source@}</th>
                <td>{$data['statut_source']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.reference_biblio@}</th>
                <td>{$data['reference_biblio']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.jdd_id@}</th>
                <td>{$data['jdd_id']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.jdd_code@}</th>
                <td>{$data['jdd_code']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.identifiant_origine@}</th>
                <td>{$data['identifiant_origine']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.identifiant_permanent@}</th>
                <td>{$data['identifiant_permanent']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.ds_publique@}</th>
                <td>{$data['ds_publique']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.code_idcnp_dispositif@}</th>
                <td>{$data['code_idcnp_dispositif']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.organisme_standard@}</th>
                <td>{$data['organisme_standard']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.statut_observation@}</th>
                <td>{$data['statut_observation']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.nom_cite@}</th>
                <td>{$data['nom_cite']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.cd_nom@}</th>
                <td>{$data['cd_nom']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.cd_ref@}</th>
                <td>{$data['cd_ref']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.sensible@}</th>
                <td>{$data['code_sensible']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.denombrement_min@}</th>
                <td>{$data['denombrement_min']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.denombrement_max@}</th>
                <td>{$data['denombrement_max']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.objet_denombrement@}</th>
                <td>{$data['objet_denombrement']}</td>
            </tr>
        </table>
    </div>

    <h3 class="dock-subtitle">{@occtax~observation.title.qui@}</h3>
    <div class="dock-content">
        <table class="table table-condensed table-striped">

            <tr>
                <th>{@occtax~observation.output.identite_observateur@}</th>
                <td>{$data['identite_observateur']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.organisme_observateur@}</th>
                <td>{$data['organisme_observateur']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.organisme_gestionnaire_donnees@}</th>
                <td>{$data['organisme_gestionnaire_donnees']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.determinateur@}</th>
                <td>{$data['determinateur']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.validateur@}</th>
                <td>{$data['validateur']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.commentaire@}</th>
                <td>{$data['commentaire']}</td>
            </tr>

        </table>
    </div>

    <h3 class="dock-subtitle">{@occtax~observation.title.quand@}</h3>
    <div class="dock-content">
        <table class="table table-condensed table-striped">

            <tr>
                <th>{@occtax~observation.output.date_debut@}</th>
                <td>{$data['date_debut']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.date_fin@}</th>
                <td>{$data['date_fin']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.heure_debut@}</th>
                <td>{$data['heure_debut']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.heure_fin@}</th>
                <td>{$data['heure_fin']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.date_determination@}</th>
                <td>{$data['date_determination_obs']}</td>
            </tr>


        </table>
    </div>

    <h3 class="dock-subtitle">{@occtax~observation.title.ou@}</h3>
    <div class="dock-content">
        <table class="table table-condensed table-striped">

            <tr>
                <th>{@occtax~observation.output.altitude_min@}</th>
                <td>{$data['altitude_min']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.altitude_max@}</th>
                <td>{$data['altitude_max']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.profondeur_min@}</th>
                <td>{$data['profondeur_min']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.profondeur_max@}</th>
                <td>{$data['profondeur_max']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.code_habitat@}</th>
                <td>
                {if array_key_exists('habitat', $children)}
                {foreach $children['habitat'] as $item}
                    {$item->code_habitat}<br/>
                {/foreach}
                {/if}
                </td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.ref_habitat@}</th>
                <td>
                {if array_key_exists('habitat', $children)}
                {foreach $children['habitat'] as $item}
                    {$item->ref_habitat}<br/>
                {/foreach}
                {/if}
                </td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.precision_geometrie@}</th>
                <td>{$data['precision']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.nature_objet_geo@}</th>
                <td>{$data['nature_objet_geo']}</td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.code_commune@}</th>
                <td>
                {if array_key_exists('commune', $children)}
                {foreach $children['commune'] as $item}
                    {$item->code_commune}<br/>
                {/foreach}
                {/if}
                </td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.nom_commune@}</th>
                <td>
                {if array_key_exists('commune', $children)}
                {foreach $children['commune'] as $item}
                    {$item->nom_commune}<br/>
                {/foreach}
                {/if}
                </td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.code_en@}</th>
                <td>
                {if array_key_exists('espace_naturel', $children)}
                {foreach $children['espace_naturel'] as $item}
                    {$item->code_en} - {$item->nom_en} ({$item->type_en})<br/>
                {/foreach}
                {/if}
                </td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.code_maille@}</th>
                <td>
                {if array_key_exists('maille', $children)}
                {foreach $children['maille'] as $item}
                    {$item->code_maille}<br/>
                {/foreach}
                {/if}
                </td>
            </tr>
            <tr>
                <th>{@occtax~observation.output.code_me@}</th>
                <td>
                {if array_key_exists('masse_eau', $children)}
                {foreach $children['masse_eau'] as $item}
                    {$item->code_me}<br/>
                {/foreach}
                {/if}
                </td>
            </tr>

        </table>
    </div>

    <h3 class="dock-subtitle">{@occtax~observation.title.aa@}</h3>
    <div class="dock-content">

        {if array_key_exists('attribut_additionnel', $children)}
        <table class="table table-condensed table-striped">
            {foreach $children['attribut_additionnel'] as $item}
            <tr>
                <th>{$item->parametre}</th>
                <td>{$item->valeur}</td>
            </tr>
            {/foreach}
        </table>
        {else}
        <center>--</center>
        {/if}
        <br/><br/>
    </div>

    </div>
</div>
