<div id="mascarine_search_description" style="display:none;">
    <h3><span class="title"><span class="icon description"></span>&nbsp;<span class="text">{@mascarine~search.description.title@}</span></span></h3>
    <div class="menu-content">
        <div id="mascarine_search_description_content"></div>
        <button id="mascarine-search-modify" type="button" class="btn" name="mod" value="modify">{@mascarine~search.button.modify.search@}</button>
        <button id="mascarine-search-replay" type="button" class="btn" name="mod" value="replay" style="display:none;">{@mascarine~search.button.replay.search@}</button>
    </div>
</div>

<div id="mascarine_search_input">
    <h3><span class="title"><span class="icon search"></span>&nbsp;<span class="text">{@mascarine~search.form.title@}</span></span></h3>
    <div id="mascarine_taxon_select_div" class="control-group">
      <label class="jforms-label control-label">
        <button type="button" data-toggle="modal" data-target="#div_mascarine_taxon_modal" class="btn" style="padding:2px;">Add taxons</button>
      </label>
      <div class="controls">
        <ul id="mascarine_taxon_select_list" style="width:220px; height:80px; overflow-x:auto; margin:0px;
         background-color:#FFF; border:solid #CCC 1px; border-radius:4px;">
        </ul>
        <div id="mascarine_taxon_select_params" style="display:none;"></div>
      </div>
    </div>
    <div id="obs-spatial-query-buttons" class="controls">
      <div class="btn-group" data-toggle="buttons-radio">
        <button type="button" id="obs-spatial-query-commune" data-value="queryPoint" class="btn commune" title="Sélectionner une commune" alt="Cliquer sur la carte pour sélectionner la commune">
        </button>
        {ifacl2 "requete.spatiale.maille_01"}
        <button type="button" id="obs-spatial-query-maille" data-value="queryPoint" class="btn maille" title="Sélectionner une maille" alt="Sélectionner une maille en cliquant sur la carte">
        </button>
        {/ifacl2}
        {ifnotacl2 "requete.spatiale.maille_01"}
        <button type="button" id="obs-spatial-query-maille" data-value="queryPoint" class="btn maille" title="Sélectionner une maille" alt="Sélectionner une maille en cliquant sur la carte">
        </button>
        {/ifnotacl2}
        {ifacl2 "requete.spatiale.cercle"}
        <button type="button" id="obs-spatial-query-circle" data-value="queryCircle" class="btn circle" title="Tracer un cercle" alt="Cliquer sur la carte puis tirer en maintenant le bouton enfoncé pour tracer le cercle.">
        </button>
        {/ifacl2}
        {ifacl2 "requete.spatiale.polygone"}
        <button type="button" id="obs-spatial-query-polygon" data-value="queryPolygon" class="btn polygon" title="Tracer un polygone" alt="Tracer un polygone en cliquant pour chaque sommet du polygone. Double-cliquer pour terminer le polygone.">
        </button>
        {/ifacl2}
        {ifacl2 "requete.spatiale.import"}
        <button type="button" id="obs-spatial-query-import" data-value="importPolygon" class="btn import" title="Choisissez un fichier au format GeoJSON">
        </button>
        {/ifacl2}
        <button type="button" id="obs-spatial-query-delete" data-value="deleteGeom" class="btn delete" title="Supprimer la géométrie" alt="Un clic sur ce bouton supprime la géométrie">
        </button>
      </div>

      {ifacl2 "requete.spatiale.polygone"}
      <div class="pull-right">
        <button type="button" id="obs-spatial-query-modify" data-value="modifyPolygon" class="btn modify" title="Modifier un polygone" alt="Modifier un polygone en déplaçant les vertices" style="display:none;">
        </button>
      </div>
      {/ifacl2}

      <div id="obs-spatial-upload-geojson" style="display:none;">
        {formfull $formUpload, 'occtax~service:uploadGeoJSON', array(), 'htmlbootstrap'}
      </div>

    </div>

    <div id="div_form_mascarine_search_token" class="menu-content">
        {formfull $form, 'mascarine~service:getSearchToken', array(), 'htmlbootstrap'}
    </div>
</div>

<div style="display:none;">
  <form id="form_mascarine_service_commune" method="post" action="{jurl 'mascarine~service:getCommune'}">
  </form>
  <form id="form_mascarine_service_maille" method="post" action="{jurl 'mascarine~service:getMaille'}">
  </form>
</div>

<div id="mascarine_search_result" style="display:none;">
    <h3>
        <span class="title">
            <span class="icon result"></span>&nbsp;<span class="text">{@mascarine~search.result.title@}</span>
            <span class="pull-right" id="mascarine_result_button_bar" style="display:none;">
                <div class="btn-group">
                    <button id="mascarine_results_export" type="button" class="btn btn-mini" style="background:#E6E6E6; padding:2px;"  title="{@mascarine~search.result.export.title@}">
                        <i class="icon-download"></i>
                    </button>
                </div>
                <div class="btn-group">
                    <button id="mascarine_results_zoom" type="button" class="btn btn-mini" style="background:#E6E6E6; padding:2px;"  title="{@mascarine~search.result.zoom.title@}">
                        <i class="icon-search"></i>
                    </button>
                </div>
            </span>
        </span>
        </h3>

    <div class="btn-toolbar">
      <div id="mascarine_results_draw" class="btn-group" data-toggle="buttons-radio" style="display:none;">
        <button id="mascarine_results_draw_maille" type="button" class="btn active" name="draw" value="maille">Maille</button>
        {ifacl2 "visualisation.donnees.brutes"}
        <button id="mascarine_results_draw_observation" type="button" class="btn" name="draw" value="observation">Observation</button>
        {/ifacl2}
      </div>
    </div>

    <div class="menu-content tabbable">
      <ul id="mascarine_results_tabs" class="nav nav-tabs">
        <li><a id="mascarine_results_stats_table_tab" href="#mascarine_results_stats_table_div" data-toggle="tab">{@mascarine~search.result.stats@}</a></li>
        <li><a id="mascarine_results_taxon_table_tab" href="#mascarine_results_taxon_table_div" data-toggle="tab">{@mascarine~search.result.taxon@}</a></li>
        <li class="active"><a id="mascarine_results_maille_table_tab" href="#mascarine_results_maille_table_div" data-toggle="tab">{@mascarine~search.result.maille@}</a></li>
        {ifacl2 "visualisation.donnees.brutes"}
        <li><a id="mascarine_results_observation_table_tab" href="#mascarine_results_observation_table_div" data-toggle="tab">{@mascarine~search.result.observation@}</a></li>
        {/ifacl2}
      </ul>
      <div class="tab-content">

        <div id="mascarine_results_stats_table_div" class="tab-pane">
          <form id="mascarine_service_search_stats_form" method="post" action="{jurl 'mascarine~service:searchStats'}" style="display:none;">
            <input type="text" name="token"></input>
          </form>
          {zone 'taxon~datatable', array('classId'=>'mascarine~mascarineSearchObservationStats','tableId'=>'mascarine_results_stats_table')}
        </div>

        <div id="mascarine_results_taxon_table_div" class="tab-pane">
          <form id="mascarine_service_search_taxon_form" method="post" action="{jurl 'mascarine~service:searchGroupByTaxon'}" style="display:none;">
            <input type="text" name="token"></input>
          </form>
          {zone 'taxon~datatable', array('classId'=>'mascarine~mascarineSearchObservationTaxon','tableId'=>'mascarine_results_taxon_table')}
        </div>

        <div id="mascarine_results_maille_table_div" class="tab-pane active">
          <b>{@mascarine~search.legende.mailles.title@}</b>
          <dl class="dl-horizontal">
            <dt><img src="{$j_basepath}css/img/legend/a.png"/></dt>
            <dd>{@mascarine~search.legende.mailles.a@}</dd>
            <dt><img src="{$j_basepath}css/img/legend/b.png"/></dt>
            <dd>{@mascarine~search.legende.mailles.b@}</dd>
            <dt><img src="{$j_basepath}css/img/legend/c.png"/></dt>
            <dd>{@mascarine~search.legende.mailles.c@}</dd>
            <dt><img src="{$j_basepath}css/img/legend/d.png"/></dt>
            <dd>{@mascarine~search.legende.mailles.d@}</dd>
          </dl>

          <form id="mascarine_service_search_maille_form" method="post" action="{jurl 'mascarine~service:searchGroupByMaille'}" style="display:none;">
            <input type="text" name="token"></input>
          </form>
          {zone 'taxon~datatable', array('classId'=>'mascarine~mascarineSearchObservationMaille','tableId'=>'mascarine_results_maille_table')}
        </div>

        {ifacl2 "visualisation.donnees.brutes"}
        <div id="mascarine_results_observation_table_div" class="tab-pane">
          <form id="mascarine_service_search_form" method="post" action="{jurl 'mascarine~service:search'}" style="display:none;">
            <input type="text" name="token"></input>
            <input type="text" name="limit"></input>
            <input type="text" name="offset"></input>
            <input type="text" name="group"></input>
            <input type="text" name="order"></input>
          </form>
          {zone 'taxon~datatable', array('classId'=>'mascarine~mascarineSearchObservationObs','tableId'=>'mascarine_results_observation_table')}
        </div>
        {/ifacl2}
      </div>
    </div>
</div>


<div id="div_mascarine_taxon_modal" class="modal hide fade">
    <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
        <h3>Filtrer les taxons</h3>
    </div>
    <div class="modal-body">

        <div style="display:none;">
          <form id="form_mascarine_taxon_service_autocomplete" method="post" action="{jurl 'mascarine~taxon:autocomplete'}">
            <input type="text" name="limit" value="10"></input>
            <input type="text" name="term"></input>
          </form>
        </div>
        <h3><span class="title"><span class="icon search"></span>&nbsp;<span class="text">{@taxon~search.form.title@}</span></span></h3>
        <div id="div_form_mascarine_taxon_search_token" class="menu-content">
            {formfull $formTax, 'mascarine~taxon:getSearchToken', array(), 'htmlbootstrap'}
        </div>
        <h3>
            <span class="title">
                <span class="icon result"></span>&nbsp;<span class="text">{@taxon~search.result.title@}</span>
                <span class="pull-right">
                    <div class="btn-group">
                        <button id="mascarine_results_add_taxon_button"
                                type="button" class="btn btn-mini" style="background:#E6E6E6; paddding:2px; width:20px; height:20px;"
                                title="Ajouter la recherche">
                            <i class="icon-plus-sign"></i>
                        </button>
                    </div>
                </span>
            </span>
        </h3>
        <div id="mascarine_results_add_taxon_table_div" class="menu-content">
            <form id="form_mascarine_taxon_service_search" method="post" action="{jurl 'mascarine~taxon:search'}" style="display:none;">
                <input type="text" name="token"></input>
                <input type="text" name="limit"></input>
                <input type="text" name="offset"></input>
                <input type="text" name="order"></input>
            </form>
            <div id="mascarine_results_add_taxon_description" style="display:none;"></div>
            {zone 'taxon~datatable', array('classId'=>'mascarine~taxonSearchMascarine','tableId'=>'mascarine_results_add_taxon_table', 'localeModule'=>'taxon')}
        </div>
    </div>
    <div class="modal-footer">
        <button class="btn" data-dismiss="modal" aria-hidden="true">Close</button>
    </div>
</div>

<script>
{literal}
$(document).ready(function() {
  $('body').append($('#div_mascarine_taxon_modal'));
});
{/literal}
</script>

