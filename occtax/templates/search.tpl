<div id="occtax_search_description" style="display:none;">
    <h3>
        <span class="title">
            <span class="icon description"></span>&nbsp;<span class="text">{@occtax~search.description.title@}</span>
        </span>
    </h3>

    <div class="menu-content">
        <div id="occtax_search_description_content"></div>
        <button id="occtax-search-modify" type="button" class="btn" name="mod" value="modify" style="display:none;">{@occtax~search.button.modify.search@}</button>
        <button id="occtax-search-replay" type="button" class="btn" name="mod" value="replay" style="display:none;">{@occtax~search.button.replay.search@}</button>

            <span class="pull-right" id="occtax_result_button_bar" style="display:none;">
                <div class="dropup btn-group" role="group">

                    <button type="button" class="btn btn-mini dropdown-toggle"  data-toggle="dropdown" aria-expanded="false" style="background:#E6E6E6; padding:2px;" title="{@occtax~search.result.export.title@}">
                        <i class="icon-download"></i>
                    </button>

                    <ul class="dropdown-menu pull-right" role="menu">
                        <li><a href="" class="btn-export-search">CSV</a></li>
                        {ifacl2 "visualisation.donnees.brutes"}
                        <li><a href="" class="btn-get-wfs" target="_blank">WFS</a></li>
                        <li><a href="" class="btn-export-search">GeoJSON</a></li>
                        {/ifacl2}
                    </ul>
                </div>
                <div class="btn-group">
                    <button id="occtax_results_zoom" type="button" class="btn btn-mini" style="background:#E6E6E6; padding:2px;"  title="{@occtax~search.result.zoom.title@}">
                        <i class="icon-search"></i>
                    </button>
                </div>
            </span>
    </div>
</div>

<div id="occtax_search_input">
    <h3><span class="title"><span class="icon search"></span>&nbsp;<span class="text">{@occtax~search.form.title@}</span></span></h3>

    <div id="occtax_taxon_select_div" class="control-group">
      <label class="jforms-label control-label">
        <button type="button" id="occtax_taxon_select_toggle" class="btn" style="padding:2px;">{@occtax~search.button.add.taxon@}</button>
      </label>
      <div class="controls">
        <ul id="occtax_taxon_select_list" style="width:220px; height:80px; overflow-x:auto; margin:0px;
         background-color:#FFF; border:solid #CCC 1px; border-radius:4px;">
        </ul>
        <div id="occtax_taxon_select_params" style="display:none;"></div>
        <button id="clearTaxonSearch" class="btn btn-mini">x</button>
      </div>
    </div>
    <div id="obs-spatial-query-buttons" class="controls">
      <div class="btn-group" data-toggle="buttons-radio">
        <button type="button" id="obs-spatial-query-commune" data-value="queryPoint" class="btn commune" title="Sélectionner une commune" alt="Cliquer sur la carte pour sélectionner la commune">
        </button>
        <button type="button" id="obs-spatial-query-masse_eau" data-value="queryPoint" class="btn masse_eau" title="Sélectionner une masse d'eau" alt="Cliquer sur la carte pour sélectionner la masse d'eau">
        </button>
        <button type="button" id="obs-spatial-query-maille-m02" data-value="queryPoint" class="btn maille m02" title="Sélectionner une maille 2x2km" alt="Sélectionner une maille en cliquant sur la carte">
        </button>

        <button type="button" id="obs-spatial-query-maille-m10" data-value="queryPoint" class="btn maille m10" title="Sélectionner une maille 10x10km" alt="Sélectionner une maille 10 en cliquant sur la carte">
        </button>
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

    <div id="div_form_occtax_search_token" class="menu-content">
        {formfull $form, 'occtax~service:initSearch', array(), 'htmlbootstrap'}
    </div>
</div>

<div style="display:none;">
  <form id="form_occtax_service_commune" method="post" action="{jurl 'occtax~service:getCommune'}">
  </form>
  <form id="form_occtax_service_masse_eau" method="post" action="{jurl 'occtax~service:getMasseEau'}">
  </form>
  <form id="form_occtax_service_maille" method="post" action="{jurl 'occtax~service:getMaille'}">
  </form>
</div>

<div id="occtax_search_result" style="display:none;">

    <div class="btn-toolbar">
      <div id="occtax_results_draw" class="btn-group" data-toggle="buttons-radio" style="display:none;">
        <button id="occtax_results_draw_maille_m02" type="button" class="btn active" name="draw" value="m02">Maille 2x2</button>
        <button id="occtax_results_draw_maille_m10" type="button" class="btn" name="draw" value="m10">Maille 10x10</button>
        {ifacl2 "visualisation.donnees.brutes"}
        <button id="occtax_results_draw_observation" type="button" class="btn" name="draw" value="observation">Observation</button>
        {/ifacl2}
      </div>
    </div>

</div>

<script type="text/javascript" >
{literal}
  var occtaxClientConfig = {/literal}{$occtaxClientConfig}{literal};
{/literal}
</script>
