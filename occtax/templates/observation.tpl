<div style="height:100%;overflow:auto;">

<div class="dock-content" style="padding: 2px;">
    <center>
        <span id="occtax_fiche_navigation">
            <button class="btn btn-mini btn-primary" id="occtax_fiche_before">Précédent</button>
            <span style="font-weight: bold;" id="occtax_fiche_position" class=""></span>
            <button class="btn btn-mini btn-primary" id="occtax_fiche_next">Suivant</button>
            <button class="btn btn-mini btn-primary pull-right" id="occtax_fiche_zoom">Zoom</button>
            <span style="display:none;">{if array_key_exists('geojson', $data)}{$data['geojson']}{/if}</span>
        </span>
        {if $in_basket}
        <button value="remove@{$data['identifiant_permanent']}" class="occtax_validation_button btn btn-mini pull-right" tooltip="{@validation.button.validation_basket.remove.help@}">{@validation.button.validation_basket.remove.title@}</button>
        {else}
        <button value="add@{$data['identifiant_permanent']}" class="occtax_validation_button btn btn-mini pull-right" tooltip="{@validation.button.validation_basket.add.help@}">{@validation.button.validation_basket.add.title@}</button>
        {/if}

    </center>
</div>

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
            <td>
                {assign $a = 'statut_observation'}
                {if array_key_exists($a . '|' . $data[$a], $nomenclature) }
                {assign $k = $a . '|' . $data[$a]}
                {$nomenclature[$k]}
                {else}
                {$data[$a]}
                {/if}
            </td>
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
            <td><a href="#" class="getTaxonDetail cd_nom_{$data['cd_nom']}">{$data['nom_cite']}</a></td>
        </tr>
        {/if}

        {if array_key_exists('lb_nom_valide', $data)}
        <tr>
            <th>{@occtax~observation.output.lb_nom_valide@}</th>
            <td><a href="#" class="getTaxonDetail cd_nom_{$data['cd_nom']}">{$data['lb_nom_valide']}</a></td>
        </tr>
        {/if}

        {if array_key_exists('nom_vern', $data)}
        <tr>
            <th>{@occtax~observation.output.nom_vern@}</th>
            <td>{$data['nom_vern']}</td>
        </tr>
        {/if}

        {if array_key_exists('nom_vern_valide', $data)}
        <tr>
            <th>{@occtax~observation.output.nom_vern_valide@}</th>
            <td>{$data['nom_vern']}</td>
        </tr>
        {/if}

        {if array_key_exists('group2_inpn', $data)}
        <tr>
            <th>{@occtax~observation.output.group2_inpn@}</th>
            <td>{$data['group2_inpn']}</td>
        </tr>
        {/if}

        {if array_key_exists('famille', $data)}
        <tr>
            <th>{@occtax~observation.output.famille@}</th>
            <td>{$data['famille']}</td>
        </tr>
        {/if}

        {if array_key_exists('loc', $data)}
        <tr>
            <th>{@occtax~observation.output.loc@}</th>
            <td>
                {assign $a = 'loc'}
                {if array_key_exists('statut_taxref' . '|' . $data[$a], $nomenclature) }
                {assign $k = 'statut_taxref' . '|' . $data[$a]}
                {$nomenclature[$k]}
                {else}
                {$data[$a]}
                {/if}
            </td>
        </tr>
        {/if}

        {if array_key_exists('statut_biogeographique', $data)}
        <tr>
            <th>{@occtax~observation.output.statut_biogeographique@}</th>
            <td>
                {assign $a = 'statut_biogeographique'}
                {if array_key_exists($a . '|' . $data[$a], $nomenclature) }
                {assign $k = $a . '|' . $data[$a]}
                {$nomenclature[$k]}
                {else}
                {$data[$a]}
                {/if}
            </td>
        </tr>
        {/if}

        {if array_key_exists('menace_regionale', $data)}
        <tr>
            <th>{@occtax~observation.output.menace_regionale@}</th>
            <td>
                {assign $a = 'menace_regionale'}
                {if array_key_exists('menace' . '|' . $data[$a], $nomenclature) }
                {assign $k = 'menace' . '|' . $data[$a]}
                {$nomenclature[$k]}
                {else}
                {$data[$a]}
                {/if}
            </td>
        </tr>
        {/if}

        {if array_key_exists('menace_nationale', $data)}
        <tr>
            <th>{@occtax~observation.output.menace_nationale@}</th>
            <td>
                {assign $a = 'menace_nationale'}
                {if array_key_exists('menace' . '|' . $data[$a], $nomenclature) }
                {assign $k = 'menace' . '|' . $data[$a]}
                {$nomenclature[$k]}
                {else}
                {$data[$a]}
                {/if}
            </td>
        </tr>
        {/if}

        {if array_key_exists('menace_monde', $data)}
        <tr>
            <th>{@occtax~observation.output.menace_monde@}</th>
            <td>
                {assign $a = 'menace_monde'}
                {if array_key_exists('menace' . '|' . $data[$a], $nomenclature) }
                {assign $k = 'menace' . '|' . $data[$a]}
                {$nomenclature[$k]}
                {else}
                {$data[$a]}
                {/if}
            </td>
        </tr>
        {/if}

        {if array_key_exists('protection', $data)}
        <tr>
            <th>{@occtax~observation.output.protection@}</th>
            <td>
                {assign $a = 'protection'}
                {if array_key_exists($a . '|' . $data[$a], $nomenclature) }
                {assign $k = $a . '|' . $data[$a]}
                {$nomenclature[$k]}
                {else}
                {$data[$a]}
                {/if}
            </td>
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
            <td>
                {if array_key_exists('objet_denombrement' . '|' . $data['objet_denombrement'], $nomenclature) }
                {assign $k = 'objet_denombrement' . '|' . $data['objet_denombrement']}
                {$nomenclature[$k]}
                {else}
                {$data['objet_denombrement']}
                {/if}
            </td>
        </tr>
        {/if}

        {if array_key_exists('type_denombrement', $data)}
        <tr>
            <th>{@occtax~observation.output.type_denombrement@}</th>
            <td>
                {if array_key_exists('type_denombrement' . '|' . $data['type_denombrement'], $nomenclature) }
                {assign $k = 'type_denombrement' . '|' . $data['type_denombrement']}
                {$nomenclature[$k]}
                {else}
                {$data['type_denombrement']}
                {/if}
            </td>
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



<h3 class="dock-subtitle">{@occtax~observation.title.descriptif.sujet@}</h3>
<div class="dock-content">
{if array_key_exists('descriptif_sujet', $data) and !empty($data['descriptif_sujet'])}
    {assign $descriptif_sujet = json_decode($data['descriptif_sujet'])}

    <ul class="nav nav-tabs">
    {assign $i = 1}
    {foreach $descriptif_sujet as $ds}
      <li><a data-toggle="tab" href="#descriptif_sujet_{$i}">{@occtax~observation.output.descriptif_sujet@} {$i}</a></li>
    {assign $i = $i + 1}
    {/foreach}
    </ul>

    <div class="tab-content">
    {assign $i = 1}
    {foreach $descriptif_sujet as $ds}
      <div id="descriptif_sujet_{$i}" class="tab-pane">
        <table class="table table-condensed table-striped">
            {foreach $ds as $key => $val}
            {if in_array($key, $observation_card_fields)}
            <tr>
                <th>{@occtax~observation.output.$key@}</th>
                <td>
                    {if array_key_exists($key . '|' . $val, $nomenclature) }
                    {assign $k = $key . '|' . $val}
                    {$nomenclature[$k]}
                    {else}
                    {$val}
                    {/if}
                </td>
            </tr>
            {/if}
            {/foreach}
        </table>
      </div>
    {assign $i = $i + 1}
    {/foreach}
    </div>

    <script>
    {literal}
    $('a[href="#descriptif_sujet_1"]').click();
    {/literal}
    </script>
{else}
Pas d'individu décrit
{/if}
</div>



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
            <td>{$data['date_debut']|jdatetime:'db_date'}</td>
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
            <td>{$data['date_fin']|jdatetime:'db_date'}</td>
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
            <td>{$data['date_determination']|jdatetime:'db_date'}</td>
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
            <td>
                {if array_key_exists('nature_objet_geo' . '|' . $data['nature_objet_geo'], $nomenclature) }
                {assign $k = 'nature_objet_geo' . '|' . $data['nature_objet_geo']}
                {$nomenclature[$k]}
                {else}
                {$data['nature_objet_geo']}
                {/if}
            </td>
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
                {$item->code_me} (version {$item->version_me}, {$item->date_me|jdatetime:'db_date'})<br/>
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
            <td>{$data['dee_date_derniere_modification']|jdatetime:'db_date'}</td>
        </tr>
        {/if}

        {if array_key_exists('dee_date_transformation', $data)}
        <tr>
            <th>{@occtax~observation.output.dee_date_transformation@}</th>
            <td>{$data['dee_date_transformation']|jdatetime:'db_date'}</td>
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
            <td>
                {if array_key_exists('diffusion_niveau_precision' . '|' . $data['diffusion_niveau_precision'], $nomenclature) }
                {assign $k = 'diffusion_niveau_precision' . '|' . $data['diffusion_niveau_precision']}
                {$nomenclature[$k]}
                {else}
                {$data['diffusion_niveau_precision']}
                {/if}
            </td>
        </tr>
        {/if}

        {if array_key_exists('ds_publique', $data)}
        <tr>
            <th>{@occtax~observation.output.ds_publique@}</th>
            <td>
                {if array_key_exists('ds_publique' . '|' . $data['ds_publique'], $nomenclature) }
                {assign $k = 'ds_publique' . '|' . $data['ds_publique']}
                {$nomenclature[$k]}
                {else}
                {$data['ds_publique']}
                {/if}
            </td>
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

        {if array_key_exists('organisme_standard', $data)}
        <tr>
            <th>{@occtax~observation.output.organisme_standard@}</th>
            <td>{$data['organisme_standard']}</td>
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
            <td>
                {if array_key_exists('statut_source' . '|' . $data['statut_source'], $nomenclature) }
                {assign $k = 'statut_source' . '|' . $data['statut_source']}
                {$nomenclature[$k]}
                {else}
                {$data['statut_source']}
                {/if}
            </td>
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
            <td>
                {if array_key_exists('sensible' . '|' . $data['sensible'], $nomenclature) }
                {assign $k = 'sensible' . '|' . $data['sensible']}
                {$nomenclature[$k]}
                {else}
                {$data['sensible']}
                {/if}
            </td>
        </tr>
        {/if}

        {if array_key_exists('sensi_date_attribution', $data)}
        <tr>
            <th>{@occtax~observation.output.sensi_date_attribution@}</th>
            <td>{$data['sensi_date_attribution']|jdatetime:'db_date'}</td>
        </tr>
        {/if}

        {if array_key_exists('sensi_niveau', $data)}
        <tr>
            <th>{@occtax~observation.output.sensi_niveau@}</th>
            <td>
                {if array_key_exists('sensi_niveau' . '|' . $data['sensi_niveau'], $nomenclature) }
                {assign $k = 'sensi_niveau' . '|' . $data['sensi_niveau']}
                {$nomenclature[$k]}
                {else}
                {$data['sensi_niveau']}
                {/if}
            </td>
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
            <td>
                {if array_key_exists('validite_niveau' . '|' . $data['validite_niveau'], $nomenclature) }
                {assign $k = 'validite_niveau' . '|' . $data['validite_niveau']}
                <span class="niv_val n{$data['validite_niveau']}">{$nomenclature[$k]}</span>
                {else}
                <span class="niv_val n{$data['validite_niveau']}">{$data['validite_niveau']}</span>
                {/if}
            </td>
        </tr>
        {/if}

        {if array_key_exists('validite_date_validation', $data)}
        <tr>
            <th>{@occtax~observation.output.validite_date_validation@}</th>
            <td>{$data['validite_date_validation']|jdatetime:'db_date'}</td>
        </tr>
        {/if}
    </table>
</div>


</div>
