    <div class="tabbable">

      <ul id="occtax_results_tabs" class="nav nav-tabs">
        <li><a id="occtax_results_stats_table_tab" href="#occtax_results_stats_table_div" data-toggle="tab">{@occtax~search.result.stats@}</a></li>
        <li><a id="occtax_results_taxon_table_tab" href="#occtax_results_taxon_table_div" data-toggle="tab">{@occtax~search.result.taxon@}</a></li>
        <li class="active"><a id="occtax_results_maille_table_tab_m02" href="#occtax_results_maille_table_div_m02" data-toggle="tab">{@occtax~search.result.maille.m02@}</a></li>
        <li><a id="occtax_results_maille_table_tab_m10" href="#occtax_results_maille_table_div_m10" data-toggle="tab">{@occtax~search.result.maille.m10@}</a></li>
        {ifacl2 "visualisation.donnees.brutes"}
        <li><a id="occtax_results_observation_table_tab" href="#occtax_results_observation_table_div" data-toggle="tab">{@occtax~search.result.observation@}</a></li>
        {/ifacl2}
      </ul>


      <div class="tab-content">

        <div id="occtax_results_stats_table_div" class="tab-pane active bottom-content attribute-content">
          <form id="occtax_service_search_stats_form" method="post" action="{jurl 'occtax~service:searchStats'}" style="display:none;">
            <input type="text" name="token"></input>
          </form>
          {zone 'taxon~datatable', array('classId'=>'occtax~occtaxSearchObservationStats','tableId'=>'occtax_results_stats_table')}
        </div>

        <div id="occtax_results_taxon_table_div" class="tab-pane bottom-content attribute-content">
          <form id="occtax_service_search_taxon_form" method="post" action="{jurl 'occtax~service:searchGroupByTaxon'}" style="display:none;">
            <input type="text" name="token"></input>
          </form>
          {zone 'taxon~datatable', array('classId'=>'occtax~occtaxSearchObservationTaxon','tableId'=>'occtax_results_taxon_table')}
        </div>

<!--
        mailles 2
-->
        <div id="occtax_results_maille_table_div_m02" class="tab-pane bottom-content attribute-content">
          <form id="occtax_service_search_maille_form_m02" method="post" action="{jurl 'occtax~service:searchGroupByMaille'}" style="display:none;">
            <input type="text" name="token"></input>
            <input type="text" name="type_maille" value="m02"></input>
          </form>
          {zone 'taxon~datatable', array('classId'=>'occtax~occtaxSearchObservationMaille','tableId'=>'occtax_results_maille_table_m02')}
        </div>


<!--
        mailles 10
-->
        <div id="occtax_results_maille_table_div_m10" class="tab-pane bottom-content attribute-content">
          <form id="occtax_service_search_maille_form_m10" method="post" action="{jurl 'occtax~service:searchGroupByMaille'}" style="display:none;">
            <input type="text" name="token"></input>
            <input type="text" name="type_maille" value="m10"></input>
          </form>
          {zone 'taxon~datatable', array('classId'=>'occtax~occtaxSearchObservationMaille','tableId'=>'occtax_results_maille_table_m10')}
        </div>


<!--
        donnees brutes
-->
        {ifacl2 "visualisation.donnees.brutes"}
        <div id="occtax_results_observation_table_div" class="tab-pane bottom-content attribute-content">
          <form id="occtax_service_search_form" method="post" action="{jurl 'occtax~service:search'}" style="display:none;">
            <input type="text" name="token"></input>
            <input type="text" name="limit"></input>
            <input type="text" name="offset"></input>
            <input type="text" name="order"></input>
            <input type="text" name="group"></input>
          </form>


<!--
          <div id="occtax-bottom-main">
-->
            {zone 'taxon~datatable', array('classId'=>'occtax~occtaxSearchObservation','tableId'=>'occtax_results_observation_table')}
<!--
          </div>

          <div id="occtax-bottom-detail">
          </div>
-->
        </div>
        {/ifacl2}
      </div>
    </div>
