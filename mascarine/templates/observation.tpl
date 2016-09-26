<div class="" style="min-width:250px;">
    <h3>
        <span class="title">
            <span class="text">{@occtax~observation.fiche.title@}</span>
                <i class="pull-right close icon-remove icon-white"></i>
            </span>
    </h3>

    <div style="height:100%;overflow:auto;">

    <h3 class="dock-subtitle">{@mascarine~observation.form.general_obs@}</h3>
    <div class="dock-content">
        <table class="table table-condensed table-striped">

            <tr>
                <th>{@mascarine~observation.input.date_obs@}</th>
                <td>{$data['date_obs']}</td>
            </tr>

            <tr>
                <th>{@mascarine~observation.input.type_obs@}</th>
                <td>{$data['type_obs']}</td>
            </tr>

            <tr>
                <th>{@mascarine~observation.input.nature_obs@}</th>
                <td>{$data['nature_obs']}</td>
            </tr>

            <tr>
                <th>{@mascarine~observation.input.forme_obs@}</th>
                <td>{$data['forme_obs']}</td>
            </tr>

            <tr>
                <th>{@mascarine~observation.input.num_manuscrit@}</th>
                <td>{$data['num_manuscrit']}</td>
            </tr>

            <tr>
                <th>{@mascarine~observation.input.remarques_obs@}</th>
                <td>{$data['remarques_obs']}</td>
            </tr>
        </table>
    </div>

    <h3 class="dock-subtitle">{@mascarine~observation.form.personne_obs@}</h3>
    <div class="dock-content">
        <table class="table table-condensed table-striped">

            <tr>
                <th>{@mascarine~observation.input.id_perso@}s</th>
                <td>{$data['personnes']}</td>
            </tr>

        </table>
    </div>

    <h3 class="dock-subtitle">{@mascarine~observation.form.localisation_obs@}</h3>
    <div class="dock-content">
        <table class="table table-condensed table-striped">

            <tr>
                <th>{@mascarine~observation.input.code_commune@}s</th>
                <td>{$data['nom_commune']} ({$data['code_commune']})</td>
            </tr>

            <tr>
                <th>{@mascarine~observation.input.code_maille@}s</th>
                <td>{$data['code_maille']}</td>
            </tr>

        </table>
    </div>

    <h3 class="dock-subtitle">{@mascarine~observation.form.flore_obs@}</h3>
    <div class="dock-content">
        <table class="table table-condensed table-striped">

            <tr>
                <th>{@mascarine~observation.input.cd_nom@}s</th>
                <td>{$data['nom_valide']} ({$data['cd_nom']})</td>
            </tr>

        </table>
    </div>



    <h3 class="dock-subtitle">{@mascarine~observation.form.station_obs@}</h3>
    <div class="dock-content">
        <table class="table table-condensed table-striped">

            <tr>
                <th>{@mascarine~observation.input.alt_min_station@}</th>
                <td>{$data['alt_min_station']}</td>
            </tr>

            <tr>
                <th>{@mascarine~observation.input.alt_moy_station@}</th>
                <td>{$data['alt_moy_station']}</td>
            </tr>

            <tr>
                <th>{@mascarine~observation.input.alt_max_station@}</th>
                <td>{$data['alt_max_station']}</td>
            </tr>

        </table>
    </div>


    <h3 class="dock-subtitle">{@mascarine~observation.form.habitat_obs@}</h3>
    <div class="dock-content">
        <table class="table table-condensed table-striped">

            <tr>
                <th>{@mascarine~observation.form.habitat_obs@}</th>
                <td>
                {if array_key_exists('habitat', $children)}
                {foreach $children['habitat'] as $item}
                    {$item->code_habitat} - {$item->libelle_habitat}<br/>
                {/foreach}
                {/if}
                </td>
            </tr>


        </table>
    </div>


    <h3 class="dock-subtitle">{@mascarine~observation.form.menace_obs@}</h3>
    <div class="dock-content">
        <table class="table table-condensed table-striped">

            <tr>
                <th>{@mascarine~observation.form.menace_obs@}</th>
                <td>
                {if array_key_exists('menace', $children)}
                {foreach $children['menace'] as $item}
                    {$item->type_menace} - {$item->valeur_menace} - {$item->statut_menace}<br/>
                {/foreach}
                {/if}
                </td>
            </tr>


        </table>
    </div>

    </div>
</div>
