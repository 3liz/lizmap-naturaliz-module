<ul>
{foreach $filters as $k=>$v}
    <li><b>{@occtax~search.input.$k@}</b>  {$v}</li>
{/foreach}
</ul>

<p><b>{@occtax~search.description.total.number.is@}</b>: {$nb} {@occtax~search.description.total.number.observation@}{$s}</p>

