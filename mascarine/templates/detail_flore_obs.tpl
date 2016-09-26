<div class="modal-header">
  <h3>Détail observation flore</h3>
</div>
{jmessage_bootstrap}
{if $form != null }
{formfull $form, 'mascarine~flore_obs:submitDetail', array('id_flore_obs'=>$id_flore_obs,'id_obs'=>$id_obs,'cd_nom'=>$cd_nom,'strate_flore'=>$strate_flore), 'htmlbootstrap', array("modal"=>True,"cancel"=>True,"cancelLocale"=>"view~edition.form.cancel.label","errorDecorator"=>"bootstrapErrorDecoratorHtml")}
{else}
<div class="modal-footer">
    <button class="btn" data-dismiss="modal" aria-hidden="true">Annuler</button>
</div>
{/if}
