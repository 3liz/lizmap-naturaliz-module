<!--
FORMULAIRE DE RECHERCHE
-->

<h3 class="occtax_search">
    <span class="title">
        <span class="icon search"></span>&nbsp;<span class="text">{@occtax~search.form.title@}</span>
    </span>
</h3>

<div id="occtax_search_input">


    <!--
Onglets taxons vides,qu'on déplace dans le formulaire
et dans dans lequel on déplace les champs liés au taxon
-->
    <div id="occtax_taxon_tab_div" class="container" style="width:100%;">
        <legend>Filtrer les taxons</legend>
        <ul class="nav nav-tabs">
            <li class="active"><a href="#recherche_taxon_panier" data-toggle="tab">{@taxon~search.group.main@}</a></li>
            <li class=""><a href="#recherche_taxon_attributs" data-toggle="tab">{@taxon~search.group.filter@}</a></li>
        </ul>
        <div class="tab-content">
            <div id="recherche_taxon_panier" class="tab-pane active">
            </div>
            <div id="recherche_taxon_attributs" class="tab-pane ">
            </div>
        </div>
    </div>

    <!--
  Bloc qui contient le panier de taxon
  Déplacé par JS dans le formulaire
-->
    <div id="occtax_taxon_select_div" class="control-group">
        <ul id="occtax_taxon_select_list" style="display:none;">
        </ul>
        <button id="clearTaxonSearch" class="btn btn-mini">x</button>
    </div>
    <div id="occtax_jdd_select_div" class="control-group">
        <ul id="occtax_jdd_select_list" style="display:none;">
        </ul>
    </div>

    <!--
Bloc qui contient les boutons de recherche spatiale
Déplacé par JS dans le formulaire WHERE
-->
    <div class="control-group" id="obs-spatial-query-buttons-container">
        <label class="control-label jforms-label" for="" id=""
            title="{@occtax~search.input.recherche_spatiale.help@}">{@occtax~search.input.recherche_spatiale@}</label>
        <div id="obs-spatial-query-buttons" class="controls">
            <div class="btn-group" data-toggle="buttons-radio">
                <button type="button" id="obs-spatial-query-commune" data-value="queryPoint" class="btn commune"
                    title="Sélectionner une commune" alt="Cliquer sur la carte pour sélectionner la commune">
                </button>
                <button type="button" id="obs-spatial-query-masse_eau" data-value="queryPoint" class="btn masse_eau"
                    title="Sélectionner une masse d'eau" alt="Cliquer sur la carte pour sélectionner la masse d'eau">
                </button>

                {ifacl2 "visualisation.donnees.maille_01"}
                {if in_array('maille_01', $mailles_a_utiliser)}
                <button type="button" id="obs-spatial-query-maille-m01" data-value="queryPoint" class="btn maille m01"
                    title="Sélectionner une maille 1x1km" alt="Sélectionner une maille en cliquant sur la carte">
                </button>
                {/if}
                {/ifacl2}

                {ifacl2 "visualisation.donnees.maille_02"}
                {if in_array('maille_02', $mailles_a_utiliser)}
                <button type="button" id="obs-spatial-query-maille-m02" data-value="queryPoint" class="btn maille m02"
                    title="Sélectionner une maille 2x2km" alt="Sélectionner une maille en cliquant sur la carte">
                </button>
                {/if}
                {/ifacl2}
                <!--
                    <button type="button" id="obs-spatial-query-maille-m05" data-value="queryPoint" class="btn maille m05" title="Sélectionner une maille 5x5km" alt="Sélectionner une maille en cliquant sur la carte">
                    </button>
            -->
                {if in_array('maille_10', $mailles_a_utiliser)}
                <button type="button" id="obs-spatial-query-maille-m10" data-value="queryPoint" class="btn maille m10"
                    title="Sélectionner une maille 10x10km" alt="Sélectionner une maille 10 en cliquant sur la carte">
                </button>
                {/if}

                {ifacl2 "requete.spatiale.cercle"}
                <button type="button" id="obs-spatial-query-circle" data-value="queryCircle" class="btn circle"
                    title="Tracer un cercle"
                    alt="Cliquer sur la carte puis tirer en maintenant le bouton enfoncé pour tracer le cercle.">
                </button>
                {/ifacl2}
                {ifacl2 "requete.spatiale.polygone"}
                <button type="button" id="obs-spatial-query-polygon" data-value="queryPolygon" class="btn polygon"
                    title="Tracer un polygone"
                    alt="Tracer un polygone en cliquant pour chaque sommet du polygone. Double-cliquer pour terminer le polygone.">
                </button>
                {/ifacl2}
                {ifacl2 "requete.spatiale.import"}
                <button type="button" id="obs-spatial-query-import" data-value="importPolygon" class="btn import"
                    title="Choisissez un fichier au format GeoJSON">
                </button>
                {/ifacl2}
                <button type="button" id="obs-spatial-query-delete" data-value="deleteGeom" class="btn delete"
                    title="Supprimer la géométrie" alt="Un clic sur ce bouton supprime la géométrie">
                </button>

                {ifacl2 "requete.spatiale.polygone"}
                <button type="button" id="obs-spatial-query-modify" data-value="modifyPolygon" class="btn modify"
                    title="Modifier un polygone" alt="Modifier un polygone en déplaçant les vertices"
                    style="display:none;">
                </button>
                {/ifacl2}

            </div>

        </div>

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

    <form id="form_taxon_service_autocomplete" method="post" action="{jurl 'taxon~service:autocomplete'}">
        <input type="text" name="limit" value="50"></input>
        <input type="text" name="term"></input>
        <input type="text" name="taxons_locaux"></input>
        <input type="text" name="taxons_bdd"></input>
    </form>

    <form id="form_jdd_service_autocomplete" method="post" action="{jurl 'occtax~service:autocomplete'}">
        <input type="text" name="field" value="jdd"></input>
        <input type="text" name="limit" value="50"></input>
        <input type="text" name="term"></input>
    </form>

    <!--
  <form id="form_taxon_service_search" method="post" action="{jurl 'taxon~service:search'}">
    <input type="text" name="token"></input>
    <input type="text" name="limit"></input>
    <input type="text" name="offset"></input>
    <input type="text" name="order"></input>
  </form>
-->

</div>


<!--
RESUME DE LA RECHERCHE ET DES RÉSULTATS
-->

<h3 class="occtax_search" style="display:none;"><span class="title"><span class="icon description"></span>&nbsp;<span
            class="text">{@occtax~search.description.title@}</span></span></h3>

<div id="occtax_search_description" style="display:none;">

    <div class="menu-content">
        <div id="occtax_search_description_content"></div>

        <input id="occtax_observation_records_total" type="hidden" value="0">
        <button id="occtax-search-modify" type="button" class="btn btn-primary" name="mod" value="modify"
            style="">{@occtax~search.button.modify.search@}</button>
        <button id="occtax-search-replay" type="button" class="btn btn-primary" name="mod" value="replay"
            style="display:none;">{@occtax~search.button.replay.search@}</button>

        <!-- validation -->
        {ifacl2 "validation.online.access"}
        <button id="occtax-search-to-basket" type="button" class="btn btn-primary" name="mod" value="basket"
            title="{@occtax~validation.button.add.search.to.basket.help@}">{@occtax~validation.button.add.search.to.basket@}</button>
        {/ifacl2}

        <!-- zoom -->

        <span id="occtax_results_data_extent" style="display:none;"></span>

        <span class="pull-right" id="occtax_result_button_bar" style="display:none;">
            <div class="btn-group">
                <button id="occtax_results_zoom" type="button" class="btn btn-mini"
                    style="background: #E6E6E6; padding:2px;" title="{@occtax~search.result.zoom.title@}">
                    <i class="icon-search"></i>
                </button>
            </div>
        </span>

        <!--
        Barre d'outil pour basculer l'affichage carto entre mailles 1, 2, 10km et observations
-->
        <div id="occtax_toggle_map_display" class="btn-toolbar">
            <div id="occtax_results_draw" class="btn-group dropup" data-toggle="buttons-radio" style="">
                {ifacl2 "visualisation.donnees.maille_01"}
                {if in_array('maille_01', $mailles_a_utiliser)}
                <button title="Afficher les mailles de 1 km" id="occtax_results_draw_maille_m01" type="button"
                    class="btn active" name="draw" value="m01">Mailles 1km</button>
                {/if}
                {/ifacl2}

                {ifacl2 "visualisation.donnees.maille_02"}
                {if in_array('maille_02', $mailles_a_utiliser)}
                <button title="Afficher les mailles de 2 km" id="occtax_results_draw_maille_m02" type="button"
                    class="btn active btn-primary" name="draw" value="m02">Mailles 2km</button>
                {/if}
                {/ifacl2}
                {if in_array('maille_10', $mailles_a_utiliser)}
                <button title="Afficher les mailles de 10 km " id="occtax_results_draw_maille_m10" type="button"
                    class="btn" name="draw" value="m10">Mailles 10km</button>
                {/if}

                {assign $voir_observations = false}
                {ifacl2 "visualisation.donnees.brutes.selon.diffusion"}
                    {assign $voir_observations = true}
                {/ifacl2}
                {ifacl2 "visualisation.donnees.brutes"}
                    {assign $voir_observations = true}
                {/ifacl2}
                {if $voir_observations}
                <button title="Afficher les données brutes par menace" type="button"
                    id="occtax_results_draw_observation_menace" class="occtax_results_draw_observation menace btn"
                    name="draw" value="observation">Menace</button>
                <button title="Afficher les données brutes par protection" type="button"
                    id="occtax_results_draw_observation_protection"
                    class="occtax_results_draw_observation protection btn" name="draw"
                    value="observation">Protection</button>
                <button title="Afficher les données brutes par date" type="button"
                    id="occtax_results_draw_observation_date" class="occtax_results_draw_observation date btn"
                    name="draw" value="observation">Date</button>
                {/if}
            </div>
        </div>

    </div>
</div>



<!--
RÉSULTATS DE RECHERCHE (TABLEAUX)
-->

<h3 class="occtax_search" style="display:none;"><span class="title"><span class="icon search"></span>&nbsp;<span
            class="text">{@occtax~search.result.title@}</span></span></h3>

<div id="occtax_search_result" style="display:none;">

    <!--
    <div id="occtax_search_observation_detail" style="display:none;">
        <h3><span class="title"><span class="icon search"></span>&nbsp;<span class="text">{@occtax~search.form.title@}</span></span></h3>
    </div>
-->

    <div class="tabbable menu-content" style="overflow-x: hidden;">

        <ul id="occtax_results_tabs" class="nav nav-tabs">
            <!-- Liste des statistiques par groupe taxonomique -->
            <li><a id="occtax_results_stats_table_tab" href="#occtax_results_stats_table_div" data-toggle="tab"
                    title="{@occtax~search.result.stats.help@}">{@occtax~search.result.stats@}</a></li>
            <!-- Liste des taxons distincts -->
            <li><a id="occtax_results_taxon_table_tab" href="#occtax_results_taxon_table_div" data-toggle="tab"
                    title="{@occtax~search.result.taxon@}">{@occtax~search.result.taxon@}</a></li>
            <!-- Liste des JDD -->
            <li><a id="occtax_results_jdd_table_tab" href="#occtax_results_jdd_table_div" data-toggle="tab"
                    title="{@occtax~search.result.jdd@}">{@occtax~search.result.jdd@}</a></li>

<!--
On choisir de cacher les tableaux de maille
On doit les conserver dans le DOM car l'affichage carto est très lié au datatable
-->
            {ifacl2 "visualisation.donnees.maille_01"}
            {if in_array('maille_01', $mailles_a_utiliser)}
            <li style="display:none;"><a id="occtax_results_maille_table_tab_m01"
                    href="#occtax_results_maille_table_div_m01" data-toggle="tab"
                    title="{@occtax~search.result.maille.m01.help@}">{@occtax~search.result.maille.m01@}</a></li>
            {/if}
            {/ifacl2}

            {ifacl2 "visualisation.donnees.maille_02"}
            {if in_array('maille_02', $mailles_a_utiliser)}
            <li style="display:none;" class="active"><a id="occtax_results_maille_table_tab_m02"
                    href="#occtax_results_maille_table_div_m02" data-toggle="tab"
                    title="{@occtax~search.result.maille.m02.help@}">{@occtax~search.result.maille.m02@}</a></li>
            {/if}
            {/ifacl2}

            {if in_array('maille_10', $mailles_a_utiliser)}
            <li style="display:none;"><a id="occtax_results_maille_table_tab_m10"
                    href="#occtax_results_maille_table_div_m10" data-toggle="tab"
                    title="{@occtax~search.result.maille.m10.help@}">{@occtax~search.result.maille.m10@}</a></li>
            {/if}

            <!-- Li de tabulation pour accéder au tableau des observations brutes -->
            {assign $voir_observations = false}
            {ifacl2 "visualisation.donnees.brutes.selon.diffusion"}
                {assign $voir_observations = true}
            {/ifacl2}
            {ifacl2 "visualisation.donnees.brutes"}
                {assign $voir_observations = true}
            {/ifacl2}
            {if $voir_observations}
            <li><a id="occtax_results_observation_table_tab" href="#occtax_results_observation_table_div"
                    data-toggle="tab"
                    title="{@occtax~search.result.observation.help@}">{@occtax~search.result.observation@}</a></li>
            {/if}

            <!-- Export -->
            <li><a id="occtax_results_export_tab" href="#occtax_results_export_div" data-toggle="tab"
                    title="{@occtax~search.result.export.title.help@}">{@occtax~search.result.export.title@}</a></li>
        </ul>


        <div class="tab-content">

            <!-- Statistiques par groupe taxonomique -->
            <div id="occtax_results_stats_table_div" class="tab-pane active bottom-content attribute-content">
                <form id="occtax_service_search_stats_form" method="post" action="{jurl 'occtax~service:searchStats'}"
                    style="display:none;">
                    <input type="text" name="token"></input>
                </form>
                {zone 'taxon~datatable',
                array('classId'=>'occtax~occtaxSearchObservationStats','tableId'=>'occtax_results_stats_table')}
            </div>

            <!-- Liste des taxons -->
            <div id="occtax_results_taxon_table_div" class="tab-pane bottom-content attribute-content">
                <form id="occtax_service_search_taxon_form" method="post"
                    action="{jurl 'occtax~service:searchGroupByTaxon'}" style="display:none;">
                    <input type="text" name="token"></input>
                    <input type="text" name="limit"></input>
                    <input type="text" name="offset"></input>
                    <input type="text" name="order"></input>
                    <input type="text" name="group"></input>
                </form>
                {zone 'taxon~datatable',
                array('classId'=>'occtax~occtaxSearchObservationTaxon','tableId'=>'occtax_results_taxon_table')}
            </div>

            <!-- Liste des JDD -->
            <div id="occtax_results_jdd_table_div" class="tab-pane active bottom-content attribute-content">
                <form id="occtax_service_search_jdd_form" method="post" action="{jurl 'occtax~service:searchGroupByJdd'}"
                    style="display:none;">
                    <input type="text" name="token"></input>
                </form>
                {zone 'taxon~datatable',
                array('classId'=>'occtax~occtaxSearchObservationJdd','tableId'=>'occtax_results_jdd_table')}
            </div>

<!--
mailles 1
-->
            {ifacl2 "visualisation.donnees.maille_01"}
            {if in_array('maille_01', $mailles_a_utiliser)}
            <div style="display:none;" id="occtax_results_maille_table_div_m01"
                class="tab-pane bottom-content attribute-content">
                <form id="occtax_service_search_maille_form_m01" method="post"
                    action="{jurl 'occtax~service:searchGroupByMaille'}" style="display:none;">
                    <input type="text" name="token"></input>
                    <input type="text" name="type_maille" value="m01"></input>
                </form>
                {zone 'taxon~datatable',
                array('classId'=>'occtax~occtaxSearchObservationMaille','tableId'=>'occtax_results_maille_table_m01')}
            </div>
            {/if}
            {/ifacl2}
<!--
mailles 2
-->
            {ifacl2 "visualisation.donnees.maille_02"}
            {if in_array('maille_02', $mailles_a_utiliser)}
            <div style="display:none;" id="occtax_results_maille_table_div_m02"
                class="tab-pane bottom-content attribute-content">
                <form id="occtax_service_search_maille_form_m02" method="post"
                    action="{jurl 'occtax~service:searchGroupByMaille'}" style="display:none;">
                    <input type="text" name="token"></input>
                    <input type="text" name="type_maille" value="m02"></input>
                </form>
                {zone 'taxon~datatable',
                array('classId'=>'occtax~occtaxSearchObservationMaille','tableId'=>'occtax_results_maille_table_m02')}
            </div>
            {/if}
            {/ifacl2}

<!--
mailles 10
-->
            {if in_array('maille_10', $mailles_a_utiliser)}
            <div style="display:none;" id="occtax_results_maille_table_div_m10"
                class="tab-pane bottom-content attribute-content">
                <form id="occtax_service_search_maille_form_m10" method="post"
                    action="{jurl 'occtax~service:searchGroupByMaille'}" style="display:none;">
                    <input type="text" name="token"></input>
                    <input type="text" name="type_maille" value="m10"></input>
                </form>
                {zone 'taxon~datatable',
                array('classId'=>'occtax~occtaxSearchObservationMaille','tableId'=>'occtax_results_maille_table_m10')}
            </div>
            {/if}

<!--
donnees brutes
-->
            {assign $voir_observations = false}
            {ifacl2 "visualisation.donnees.brutes.selon.diffusion"}
            {assign $voir_observations = true}
            {/ifacl2}
            {ifacl2 "visualisation.donnees.brutes"}
            {assign $voir_observations = true}
            {/ifacl2}
            {if $voir_observations}
            <div id="occtax_results_observation_table_div" class="tab-pane bottom-content attribute-content">
                <form id="occtax_service_search_form" method="post" action="{jurl 'occtax~service:search'}"
                    style="display:none;">
                    <input type="text" name="token"></input>
                    <input type="text" name="limit"></input>
                    <input type="text" name="offset"></input>
                    <input type="text" name="order"></input>
                    <input type="text" name="group"></input>
                    <input type="text" name="extent"></input>
                    <input type="text" name="map"></input>
                    <input type="text" name="rowcount"></input>
                </form>
                {zone 'taxon~datatable',
                array('classId'=>'occtax~occtaxSearchObservation','tableId'=>'occtax_results_observation_table')}
            </div>
            {/if}

<!--
export
-->
            <div id="occtax_results_export_div" class="tab-pane bottom-content attribute-content">

                <form class="form-horizontal" method="post" id="occtax_result_export_form">
                    <legend>{@occtax~search.result.export.legend@}</legend>
                    <div class="control-group">
                        <label class="control-label" for="export_projection">Projection</label>
                        <div class="controls">
                            <select id="export_projection">
                                <option value="locale">{$libelle_srid} (EPSG:{$srid})</option>
                                <option value="4326">Longitude/Latitude (EPSG:4326)</option>
                            </select>
                        </div>
                    </div>

                    <div class="control-group">
                        <label class="control-label" for="export_format">Format</label>
                        <div class="controls">
                            <select id="export_format">
                                <option value="CSV">CSV</option>
                                {ifacl2 "visualisation.donnees.brutes"}
                                <option value="GeoJSON">GeoJSON</option>
                                <option value="WFS">WFS</option>
                                {/ifacl2}
                            </select>
                        </div>
                        {ifacl2 "visualisation.donnees.brutes"}
                        <a id="btn-get-wfs" href="" style="display:none;"></a>
                        <div class="controls">
                            <input type="text" id="input-get-wfs" value="" style="display:none;">
                        </div>
                        {/ifacl2}
                    </div>

                    <div class="control-group">
                        <div class="controls">
                            <button type="submit" class="btn btn-primary">{@occtax~search.result.export.title@}</button>
                        </div>
                    </div>
                </form>
            </div>
        </div>




    </div>

</div>


<!--
FICHE OBSERVATION
-->

<h3 class="occtax_search" style="display:none;"><span class="title"><span class="icon description"></span>&nbsp;<span
            class="text">{@occtax~observation.fiche.title@}</span></span></h3>

<div id="occtax_search_observation_card" style="display:none;">

</div>



<script type="text/javascript">
    {literal}
    var occtaxClientConfig = {/literal}{$occtaxClientConfig} {literal};
    {/literal}
</script>
