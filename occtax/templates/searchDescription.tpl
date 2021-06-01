{if count($filters)>0}
<span>
{foreach $filters as $k=>$v}
- <b>{@occtax~search.input.$k@}</b>  {$v}</br>
{/foreach}
</span>
{else}
{@occtax~search.description.no.filters@}
{/if}

<p>
    <b>{@occtax~search.description.total.number.is@}</b> : {$nb|number_format} {@occtax~search.description.total.number.observation@}{$s}
    <span style="display:none">nb_taxon {@occtax~search.description.total.number.taxon@}{$s}</span>
</p>

{ifnotacl2 "visualisation.donnees.brutes"}
<p>
    <i>{@occtax~search.description.sensitive.data.not.shown@}</i>
</p>
{/ifnotacl2}


{$legende}

