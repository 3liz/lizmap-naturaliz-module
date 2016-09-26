<h1>Les formulaires Mascarine</h1>
<form action="{formurl 'mascarine_admin~forms:submit'}" method="POST">
    <input type="submit" value="Valider" />
    <table class="table">
        <tr>
            <th scope="row"></th>
            {foreach $types as $type}
            <th scope="row"><input type="checkbox" name="{$type->code}" style="margin-bottom:4px;"{if $activated_types[$type->code]} checked{/if}></input>{$type->code}</th>
            {/foreach}
        </tr>
{foreach $forms as $key=>$form}
        <tr>
            <th scope="row">{$form->label}</th>
            {foreach $types as $type}
            <th scope="row">
                <select name="{$key}:{$type->code}" style="width:auto;" class="{$type->code}">
                  <option value="required"{if $form->roles[$type->code]=='required'} selected{/if}>Requis</option>
                  <option value="activate"{if $form->roles[$type->code]=='activate'} selected{/if}>Activé</option>
                  <option value="deactivate"{if $form->roles[$type->code]=='deactivate'} selected{/if}>Désactivé</option>
                </select>
            </th>
            {/foreach}
        </tr>
    {foreach $form->jform->getControls() as $ctrl}
        {if array_key_exists( $ctrl->ref, $form->controls) || $ctrl->type == 'output'}
        <tr>
            <td>{$ctrl->label}</td>
            {foreach $types as $type}
            <td>
                {if $ctrl->type != 'output'}
                <label><input type="radio" name="{$key}:{$type->code}:{$ctrl->ref}" value="required" class="{$type->code}"
                    {if $ctrl->required || $form->controls[$ctrl->ref][$type->code] == 'required'} checked{/if}></input>Requis</label>
                {if !$ctrl->required}
                <label><input type="radio" name="{$key}:{$type->code}:{$ctrl->ref}" value="activate" class="{$type->code}"
                    {if $form->controls[$ctrl->ref][$type->code] == 'activate'} checked{/if}></input>Activé</label>
                <label><input type="radio" name="{$key}:{$type->code}:{$ctrl->ref}" value="deactivate" class="{$type->code}"
                    {if $form->controls[$ctrl->ref][$type->code] == 'deactivate'} checked{/if}></input>Désactivé</label>
                {/if}
                {/if}
            </td>
            {/foreach}
        </tr>
        {/if}
    {/foreach}
{/foreach}
        <tr>
            <th scope="row"></th>
            {foreach $types as $type}
            <th scope="row">{$type->code}</th>
            {/foreach}
        </tr>
    </table>
    <input type="submit" value="Valider" />
</form>
<script type="text/javascript">
    {literal}
    $(document).ready(function(){
        $('form table th select').change(function(){
            var self = $(this);
            if ( self.val() == 'deactivate' ) {
                $('form table td input[name^="'+self.attr('name')+'"]').attr('disabled','true');
            } else {
                $('form table td input[name^="'+self.attr('name')+'"]:disabled').removeAttr('disabled');
            }
        }).change();
        $('form table th input[type="checkbox"]').change(function(){
            var self = $(this);
            if ( self.is(':checked')) {
                $('form table .'+self.attr('name')+':disabled').removeAttr('disabled');
            } else {
                $('form table .'+self.attr('name')).attr('disabled','true');
            }
        }).change();
    });
    {/literal}
</script>
