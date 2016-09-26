{if count( $children ) > 0 }
<ul>
{foreach $children as $chCode}
    {assign $ch = $habitats[$chCode]}
    <li>{if count( $ch->children ) > 0 }
        <input type="checkbox" id="{$ch->code_habitat}"/>
        {/if}
        <label for="{$ch->code_habitat}">
        {if count( $ch->children ) > 0 }
        <i class="icon-chevron-right"></i>
        <i class="icon-chevron-down"></i>
        {else}
        <i class="icon-minus"></i>
        {/if}
        <a class="pull-right btn btn-mini" href="{jurl 'mascarine~edit_obs:addHabitat',array('id_obs'=>$id_obs,'code_habitat'=>$ch->code_habitat,'ref_habitat'=>$ch->ref_habitat)}"><i class="icon-plus"></i></a>
        {$ch->libelle_habitat}
        </label>
        {if count( $ch->children ) > 0 }{zone 'mascarine~habitat_children', array('id_obs'=>$id_obs,'children'=>$ch->children,'habitats'=>$habitats)}{/if}
    </li>
{/foreach}
</ul>
{/if}
