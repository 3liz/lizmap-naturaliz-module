<ul>
{foreach $filters as $k=>$v}
    <li><b>{@mascarine~search.input.$k@}</b>  {$v}</li>
{/foreach}
</ul>

<p><b>{@mascarine~search.description.total.number.is@}</b>: {$nb} {@mascarine~search.description.total.number.observation@}{$s}</p>
