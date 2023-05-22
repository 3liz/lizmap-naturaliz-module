{if count($filters)>0}
<span>
{foreach $filters as $k=>$v}
- <b>{@occtax~search.input.$k@}</b>  {$v}</br>
{/foreach}
</span>
{else}
{@occtax~search.description.no.filters@}
{/if}

<div>
    <b>{@occtax~search.description.total.number.is@}</b> : {$nb|number_format} {@occtax~search.description.total.number.observation@}{$s}

    <span class="nb_taxon" {if $nb == 0}style="display:none"{/if}> / {$nb_taxon|number_format} {@occtax~search.description.total.number.taxon@}{$s}</span>
    {assign $displayNumbers = 'no'}
    {ifacl2 "visualisation.donnees.brutes"}{assign $displayNumbers = 'yes'}{/ifacl2}
    {ifacl2 "visualisation.donnees.brutes.selon.diffusion"}{assign $displayNumbers = 'yes'}{/ifacl2}
    {if $displayNumbers == 'yes'}
    <div id="occtax-observation-diffusion-counts" {if $nb == 0}style="display:none"{/if}>
        <ul>
            <li>{$nb_precise|number_format} {@occtax~search.description.total.number.observation.nb_precise@}
            <li>{$nb_floutage|number_format} {@occtax~search.description.total.number.observation.nb_floutage@}
            <li>{$nb_vide|number_format} {@occtax~search.description.total.number.observation.nb_vide@}
        </ul>
    </div>
    {/if}
</div>

{ifnotacl2 "visualisation.donnees.brutes"}
<p>
    <i>{@occtax~search.description.sensitive.data.not.shown@}</i>
</p>
{/ifnotacl2}


{$legende}
