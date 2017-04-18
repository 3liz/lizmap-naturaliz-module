<ul>
{foreach $filters as $k=>$v}
    <li><b>{@occtax~search.input.$k@}</b>  {$v}</li>
{/foreach}
</ul>

<p><b>{@occtax~search.description.total.number.is@}</b>: {$nb} {@occtax~search.description.total.number.observation@}{$s}</p>

{ifnotacl2 "visualisation.donnees.brutes"}
<p>
    <i>{@occtax~search.description.sensitive.data.not.shown@}</i>
</p>
{/ifnotacl2}
