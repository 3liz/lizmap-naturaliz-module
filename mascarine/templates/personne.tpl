<div class="modal-header">
  {if $id != null}
  <h3>Mise à jour d'un perso</h3>
  {else}
  <h3>Ajout d'un perso</h3>
  {/if}
</div>
  {if $id != null}
    {formfull $form, 'mascarine~personne:update', array('id'=>$id), 'htmlbootstrap', array("modal"=>True,"cancel"=>True,"cancelLocale"=>"view~edition.form.cancel.label","errorDecorator"=>"bootstrapErrorDecoratorHtml")}
  {else}
    {formfull $form, 'mascarine~personne:create', array(), 'htmlbootstrap', array("modal"=>True,"cancel"=>True,"cancelLocale"=>"view~edition.form.cancel.label","errorDecorator"=>"bootstrapErrorDecoratorHtml")}
  {/if}
