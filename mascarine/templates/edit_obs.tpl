<h3>
    <button class="close" aria-hidden="true" data-dismiss="modal" type="button">×</button>
    <button type="button" class="btn btn-mini zoom" style="width: 20px; height: 30px;
    background:transparent; padding:2px; padding-top:4px;
    float: right; text-shadow: none; border: none; transition: none 0s ease 0s; border-radius:0px;"
      title="{@mascarine~search.result.zoom.title@}">
        <i class="icon-search icon-white"></i>
    </button>
    <span class="title">
        <span class="icon"></span>&nbsp;
        {if $id_obs != null}
        {if $obs}
        <span class="text">{$obs->type_obs} {$obs->date_obs} {$obs->nature_obs} {$obs->forme_obs}</span>
        {else}
        <span class="text">Erreur</span>
        {/if}
        {else}
        <span class="text">Erreur</span>
        {/if}
    </span>
</h3>
<div>
  {jmessage_bootstrap}
</div>
{if $id_obs != null}
<div id="div_mascarine_observation_forms_tabs">
<ul class="nav nav-tabs">
    {if $general_obs != null}<li class="active"><a href="#mascarine_observation_general_div" data-toggle="tab">{@mascarine~observation.form.general_obs@}</a></li>{/if}
    {if $personne_obs != null}<li><a href="#mascarine_observation_personne_div" data-toggle="tab">{@mascarine~observation.form.personne_obs@}</a></li>{/if}
    {if $localisation_obs != null}<li><a href="#mascarine_observation_localisation_div" data-toggle="tab">{@mascarine~observation.form.localisation_obs@}</a></li>{/if}
    {if $station_obs != null}<li><a href="#mascarine_observation_station_div" data-toggle="tab">{@mascarine~observation.form.station_obs@}</a></li>{/if}
    {if $flore_obs != null}<li><a href="#mascarine_observation_flore_div" data-toggle="tab">{@mascarine~observation.form.flore_obs@}</a></li>{/if}
    {if $habitat_obs != null}<li><a href="#mascarine_observation_habitat_div" data-toggle="tab">{@mascarine~observation.form.habitat_obs@}</a></li>{/if}
    {if $menace_obs != null}<li><a href="#mascarine_observation_menace_div" data-toggle="tab">{@mascarine~observation.form.menace_obs@}</a></li>{/if}
    {if $document_obs != null}<li><a href="#mascarine_observation_document_div" data-toggle="tab">{@mascarine~observation.form.document_obs@}</a></li>{/if}
</ul>
<div class="tab-content">
    <form id="mascarine_observation_hidden_form" method="post" action="{jurl 'mascarine~edit_obs:enregistrer'}" style="display:none;">
        <input type="hidden" name="id_obs" value="{$id_obs}"></input>
    </form>
    <!-- Autre formulaires -->
    {if $general_obs != null}
    <div id="mascarine_observation_general_div" class="tab-pane active">
        <h3>
            <span class="title">
                <span class="icon"></span>&nbsp;
                <span class="text">{@mascarine~observation.form.general_obs@}</span>
            </span>
        </h3>
        <div>
            <div id="div_form_mascarine_observation_general" class="menu-content">
                {formfull $general_obs, 'mascarine~edit_obs:general', array('id_obs'=>$id_obs), 'htmlbootstrap'}
            </div>
        </div>
    </div>
    {/if}
    {if $personne_obs != null}
    <div id="mascarine_observation_personne_div" class="tab-pane">
        <h3>
            <span class="title">
                <span class="icon"></span>&nbsp;
                <span class="text">{@mascarine~observation.form.personne_obs@}</span>
            </span>
        </h3>
        <div>
            <div id="div_form_mascarine_observation_personne" class="menu-content">
                {formfull $personne_obs, 'mascarine~edit_obs:addPersonne', array('id_obs'=>$id_obs), 'htmlbootstrap'}
            </div>
            <div class="menu-content">
                <form id="mascarine_observation_personne_form" method="post" action="{jurl 'mascarine~observation:personnes'}" style="display:none;">
                    <input type="hidden" name="id_obs" value="{$id_obs}"></input>
                    <input type="hidden" name="limit"></input>
                    <input type="hidden" name="offset"></input>
                </form>
                {zone 'taxon~datatable', array('classId'=>'mascarine~personneObservationSearch','tableId'=>'mascarine_observation_personne_table','objectId'=>$id_obs)}
            </div>
        </div>
    </div>
    {/if}
    {if $localisation_obs != null}
    <div id="mascarine_observation_localisation_div" class="tab-pane">
        <h3>
            <span class="title">
                <span class="icon"></span>&nbsp;
                <span class="text">{@mascarine~observation.form.localisation_obs@}</span>
            </span>
        </h3>
        <div>
            <div id="div_form_mascarine_observation_localisation" class="menu-content">
                {formfull $localisation_obs, 'mascarine~edit_obs:localisation', array('id_obs'=>$id_obs), 'htmlbootstrap'}
            </div>
        </div>
    </div>
    {/if}
    {if $station_obs != null}
    <div id="mascarine_observation_station_div" class="tab-pane">
        <h3>
            <span class="title">
                <span class="icon"></span>&nbsp;
                <span class="text">{@mascarine~observation.form.station_obs@}</span>
           </span>
        </h3>
        <div>
            <div id="div_form_mascarine_observation_station" class="menu-content">
                {formfull $station_obs, 'mascarine~edit_obs:station', array('id_obs'=>$id_obs), 'htmlbootstrap'}
            </div>
        </div>
    </div>
    {/if}
    {if $flore_obs != null}
    <div id="mascarine_observation_flore_div" class="tab-pane">
        <h3>
            <span class="title">
                <span class="icon"></span>&nbsp;
                <span class="text">{@mascarine~observation.form.flore_obs@}</span>
            </span>
        </h3>
        <div>
            <div id="div_form_mascarine_observation_flore" class="menu-content">
                {formfull $flore_obs, 'mascarine~edit_obs:addTaxon', array('id_obs'=>$id_obs), 'htmlbootstrap'}
            </div>
            <div class="menu-content">
                <form id="form_mascarine_observation_flore_taxon_service_autocomplete" method="post" action="{jurl 'mascarine~taxon:autocomplete'}" style="display:none;">
                    <input type="text" name="limit" value="10"></input>
                    <input type="text" name="term"></input>
                </form>
                <form id="mascarine_observation_taxon_form" method="post" action="{jurl 'mascarine~observation:taxons'}" style="display:none;">
                    <input type="hidden" name="id_obs" value="{$id_obs}"></input>
                    <input type="hidden" name="limit"></input>
                    <input type="hidden" name="offset"></input>
                </form>
                <form id="mascarine_observation_taxon_check_form" method="post" action="{jurl 'mascarine~edit_obs:checkTaxon'}" style="display:none;">
                    <input type="hidden" name="id_obs" value="{$id_obs}"></input>
                </form>
                {zone 'taxon~datatable', array('classId'=>'mascarine~taxonObservationSearch','tableId'=>'mascarine_observation_taxon_table','objectId'=>$id_obs)}
            </div>
        </div>
    </div>
    {/if}
    {if $habitat_obs != null}
    <div id="mascarine_observation_habitat_div" class="tab-pane">
        <h3>
            <span class="title">
                <span class="icon"></span>&nbsp;
                <span class="text">{@mascarine~observation.form.habitat_obs@}</span>
           </span>
        </h3>
        <div>
            <div id="div_form_mascarine_observation_habitat" class="menu-content">
                {formfull $habitat_obs, 'mascarine~edit_obs:habitat', array('id_obs'=>$id_obs), 'htmlbootstrap'}
                <ul>
                {foreach $ref_habitats as $h}
                    <li>{if count( $h->children ) > 0 }
                        <input type="checkbox" id="{$h->ref_habitat}"/>
                        {/if}
                        <label for="{$h->ref_habitat}">
                        {if count( $h->children ) > 0 }
                        <i class="icon-chevron-right"></i>
                        <i class="icon-chevron-down"></i>
                        {/if}
                        {$h->libelle_habitat}
                        </label>
                        {zone 'mascarine~habitat_children', array('id_obs'=>$id_obs,'children'=>$h->children,'habitats'=>$habitats)}
                    </li>
                {/foreach}
                </ul>
            </div>
            <div class="menu-content">
                <form id="mascarine_observation_habitat_form" method="post" action="{jurl 'mascarine~observation:habitats'}" style="display:none;">
                    <input type="hidden" name="id_obs" value="{$id_obs}"></input>
                    <input type="hidden" name="limit"></input>
                    <input type="hidden" name="offset"></input>
                </form>
                {zone 'taxon~datatable', array('classId'=>'mascarine~habitatObservationSearch','tableId'=>'mascarine_observation_habitat_table','objectId'=>$id_obs)}
            </div>
        </div>
    </div>
    {/if}
    {if $menace_obs != null}
    <div id="mascarine_observation_menace_div" class="tab-pane">
        <h3>
            <span class="title">
                <span class="icon"></span>&nbsp;
                <span class="text">{@mascarine~observation.form.menace_obs@}</span>
            </span>
        </h3>
        <div>
            <div id="div_form_mascarine_observation_menace" class="menu-content">
                {formfull $menace_obs, 'mascarine~edit_obs:addMenace', array('id_obs'=>$id_obs), 'htmlbootstrap'}
            </div>
            <div class="menu-content">
                <form id="mascarine_observation_menace_form" method="post" action="{jurl 'mascarine~observation:menaces'}" style="display:none;">
                    <input type="hidden" name="id_obs" value="{$id_obs}"></input>
                    <input type="hidden" name="limit"></input>
                    <input type="hidden" name="offset"></input>
                </form>
                {zone 'taxon~datatable', array('classId'=>'mascarine~menaceObservationSearch','tableId'=>'mascarine_observation_menace_table','objectId'=>$id_obs)}
            </div>
        </div>
    </div>
    {/if}
    {if $document_obs != null}
    <div id="mascarine_observation_document_div" class="tab-pane">
        <h3>
            <span class="title">
                <span class="icon"></span>&nbsp;
                <span class="text">{@mascarine~observation.form.document_obs@}</span>
            </span>
        </h3>
        <div>
            <div id="div_form_mascarine_observation_document" class="menu-content">
                {formfull $document_obs, 'mascarine~edit_obs:addDocument', array('id_obs'=>$id_obs), 'htmlbootstrap'}
            </div>
            <div class="menu-content">
                <form id="mascarine_observation_document_form" method="post" action="{jurl 'mascarine~observation:documents'}" style="display:none;">
                    <input type="hidden" name="id_obs" value="{$id_obs}"></input>
                    <input type="hidden" name="limit"></input>
                    <input type="hidden" name="offset"></input>
                </form>
                {zone 'taxon~datatable', array('classId'=>'mascarine~documentObservationSearch','tableId'=>'mascarine_observation_document_table','objectId'=>$id_obs)}
            </div>
        </div>
    </div>
    {/if}
</div>
<ul class="pager">
    <li class="previous">
        <a href="#">&larr; Précédent</a>
    </li>
    <li class="next">
        <a href="#">Suivant &rarr;</a>
    </li>
</ul>
</div>
{/if}
