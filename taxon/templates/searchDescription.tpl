<ul>
{foreach $filters as $k=>$v}
    <li><b>{@taxon~search.input.$k@}</b>  {$v}</li>
{/foreach}
</ul>
