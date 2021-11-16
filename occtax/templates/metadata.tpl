<h3>
    <span class="title"><span class="text">{@metadata.dock.title@}</span>
        <button id="metadata-close" class="btn btn-primary btn-mini pull-right" style="margin-left:10px;">Fermer</button>
        {if !empty($url)}
        <a href="{$url}" class="btn btn-primary btn-mini pull-right" target="_blank">{@metadata.button.detail@}</a>
        {/if}
    </span>
</h3>

{if $type == 'jdd'}
    <h3>{@metadata.jdd.title@}</h3>
    {include 'occtax~metadata_jdd'}
{/if}

<h3>{@metadata.cadre.title@}</h3>
{include 'occtax~metadata_cadre'}

{if $type == 'cadre' && !empty($cadre)}
<h3>{@metadata.jdds.title@}</h3>
    {include 'occtax~metadata_jdd'}
{/if}
