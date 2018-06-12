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

<p>
    <i>{@occtax~search.description.sensitive.data.not.shown@}</i>
</p>



{assign $nb = count($legend_classes)}

<b>{@occtax~search.legende.mailles.title@}</b>
<table class="occtax-legend-table">

    {assign $min = 3}
    {assign $max = 9}
    {assign $inter = $max - $min}
    {if $nb > 0}
        {assign $step = $inter / $nb}
        {foreach $legend_classes as $class}
        <tr>
            <td>
                <svg height="20" width="20">
                    <circle cx="10" cy="10" r="{=$min + $x * $step}" stroke="gray" stroke-width="1" fill="{$class[3]}" />
                </svg>
            </td>
            <td>{$class[0]}</td>
        </tr>
        {assign $x = $x +1}
        {/foreach}
    {else}
        {assign $step = 1}
        <tr>
            <td>
                <svg height="20" width="20">
                    <circle cx="10" cy="10" r="{=$min + $x * $step}" stroke="gray" stroke-width="1" fill="orange" />
                </svg>
            </td>
            <td>Observations</td>
        </tr>
    {/if}
    {assign $x = 0}

</table>

