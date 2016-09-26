<button class="close" aria-hidden="true" data-dismiss="modal" type="button">×</button>
<h3>
  <span class="title">
    <span class="icon"></span>&nbsp;<span class="text">{@mascarine~observation.form.add_obs@}</span>
  </span>
</h3>
<div id="div_form_mascarine_add_obs" class="menu-content">
    {jmessage_bootstrap}
{if $form != null}
    {formfull $form, 'mascarine~add_obs:submit', array(), 'htmlbootstrap'}
{/if}
</div>
