<div class="modal-header">
  <h3>{@mascarine~observation.form.pheno_flore_obs@}</h3>
</div>
<div class="modal-body">
    {jmessage_bootstrap}
    <div class="form">
    {if $form != null }
      <div class="add">
        <input type="checkbox" id="mascarine_observation_flore_pheno_checkbox" checked=""></input>
        <label for="mascarine_observation_flore_pheno_checkbox">Ajouter</label>
        {formfull $form, 'mascarine~flore_obs:addPheno', array(), 'htmlbootstrap'}
      </div>
    {/if}
      <div class="update" style="display:none;">
        <input type="checkbox" id="mascarine_observation_flore_pheno_update_checkbox" checked=""></input>
        <label for="mascarine_observation_flore_pheno_update_checkbox">Modifier</label>
        <form></form>
      </div>
    </div>
    <div class="table">
        <form id="mascarine_observation_flore_pheno_form" method="post" action="{jurl 'mascarine~flore_obs:phenos'}" style="display:none;">
            <input type="hidden" name="id_flore_obs" value="{$id_flore_obs}"></input>
            <input type="hidden" name="id_obs" value="{$id_obs}"></input>
            <input type="hidden" name="cd_nom" value="{$cd_nom}"></input>
            <input type="hidden" name="strate_flore" value="{$strate_flore}"></input>
            <input type="hidden" name="limit"></input>
            <input type="hidden" name="offset"></input>
        </form>
        {zone 'taxon~datatable', array('classId'=>'mascarine~phenoFloreObservationSearch','tableId'=>'mascarine_observation_flore_pheno_table','objectId'=>array('id_flore_obs'=>$id_flore_obs, 'id_obs'=>$id_obs, 'cd_nom'=>$cd_nom, 'strate_flore'=>$strate_flore))}
    </div>
</div>
<div class="modal-footer">
    <button class="btn" data-dismiss="modal" aria-hidden="true">Fermer</button>
</div>
