{if count($filters)>0}
{assign $sep=''}
{foreach $filters as $k=>$v}
    {$sep}{@occtax~search.input.$k@} :  {$v}
    {assign $sep=', '}
{/foreach}
{$sep}
{else}
&nbsp;{@occtax~search.description.no.filters@}
{/if}

{@occtax~search.description.total.number.is@} : {$nb} {@occtax~search.description.total.number.observation@}{$s}

{ifnotacl2 "visualisation.donnees.brutes"}
    {@occtax~search.description.sensitive.data.not.shown@}
{/ifnotacl2}
