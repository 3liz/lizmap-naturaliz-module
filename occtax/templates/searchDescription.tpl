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

<b>{@occtax~search.legende.mailles.title@}</b>
<table class="occtax-legend-table">
    {foreach $legend_classes as $class}
    <tr>
        <td style="background-color:{$class[3]};width:12px;">&nbsp;</td>
        <td>{$class[0]}</td>
    </tr>
    {/foreach}
</table>
