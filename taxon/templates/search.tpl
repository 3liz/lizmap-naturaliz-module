<div style="display:none;">
  <form id="form_taxon_service_autocomplete" method="post" action="{jurl 'taxon~service:autocomplete'}">
    <input type="text" name="limit" value="50"></input>
    <input type="text" name="term"></input>
  </form>
  <form id="form_taxon_service_search" method="post" action="{jurl 'taxon~service:search'}">
    <input type="text" name="token"></input>
    <input type="text" name="limit"></input>
    <input type="text" name="offset"></input>
    <input type="text" name="order"></input>
  </form>
</div>
<h3><span class="title"><span class="icon search"></span>&nbsp;<span class="text">{@taxon~search.form.title@}</span></span></h3>
<div id="div_form_taxon_search_token" class="menu-content">
{formfull $form, 'taxon~service:initSearch', array(), 'htmlbootstrap'}
</div>

<div id="div_taxon_search_description" style="display:none;"></div>

<h3><span class="title"><span class="icon result"></span>&nbsp;<span class="text">{@taxon~search.result.title@}</span></span></h3>
<div id="div_table_taxon_results" class="menu-content">
    {zone 'taxon~datatable', array('classId'=>'taxon~taxonSearch','tableId'=>'table_taxon_results')}
</div>
