<div class="occtax-legend-container">
    <span id="occtax-legend-title" title="{@occtax~search.legende.result.title.tooltip@}">{@occtax~search.legende.result.title@}</span>
    <button id="occtax-legend-toggle" class="btn btn-mini pull-right">{@occtax~search.legende.result.toggle@}</button>
    <div id="occtax-legend-classes-container">

        <div id="occtax-legend-maille" class="occtax-legend-classes">
        <h4>{@occtax~search.legende.mailles.title@}</h4>
        <table class="occtax-legend-table">
            {assign $nb = count($legend_classes)}
            {assign $min = 3}
            {assign $max = 9}
            {assign $inter = $max - $min}
            {if $nb > 0}
                {assign $step = $inter / $nb}
                {assign $x = 1}
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
        </div>

        <!-- {ifacl2 "visualisation.donnees.brutes"} -->
        <div id="occtax-legend-observation-menace" class="occtax-legend-classes" style="display:none;">
        <h4>{@occtax~search.legende.observation.menace.title@}</h4>
        <table class="occtax-legend-table">
        {foreach $menace_legend_classes as $code=>$valeur}
            <tr>
                <td>
                    <span class="redlist {$code}">{$code}</span>
                </td>
                <td>{$code} - {$valeur}</td>
            </tr>
        {/foreach}
        </table>
        </div>

        <div id="occtax-legend-observation-protection" class="occtax-legend-classes" style="display:none;">
        <h4>{@occtax~search.legende.observation.protection.title@}</h4>
        <table class="occtax-legend-table">
            <tr>
                <td>
                    <span class="protectionlist EPN">&nbsp;&nbsp;&nbsp;&nbsp;</span>
                </td>
                <td>Espèce protégée</td>
            </tr>
            <tr>
                <td>
                    <span style="padding:3px; background-color: #C7D6FF;width:50px;height:30px;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
                </td>
                <td>Autre espèce</td>
            </tr>
        </table>
        </div>

        <div id="occtax-legend-observation-date" class="occtax-legend-classes" style="display:none;">
        <h4>{@occtax~search.legende.observation.date.title@}</h4>
        <table class="occtax-legend-table">
            <tr>
                <td>
                    <span style="padding:3px; width:50px; height:30px; background-color: #fff5eb;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
                </td>
                <td>Avant 1950</td>
            </tr>
            <tr>
                <td>
                    <span style="padding:3px; width:50px; height:30px; background-color: #fdd2a5;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
                </td>
                <td>Entre 1950 et 2000</td>
            </tr>
            <tr>
                <td>
                    <span style="padding:3px; width:50px; height:30px; background-color: #fd9243;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
                </td>
                <td>Entre 2000 et {$annee_moins_10}</td>
            </tr>
            <tr>
                <td>
                    <span style="padding:3px; width:50px; height:30px; background-color: #df5005;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
                </td>
                <td>Entre {$annee_moins_10} et {$annee_dizaine}</td>
            </tr>
            <tr>
                <td>
                    <span style="padding:3px; width:50px; height:30px; background-color: #7f2704;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
                </td>
                <td>Après {$annee_dizaine}</td>
            </tr>
        </table>
        </div>
        <!-- {/ifacl2} -->
    </div>
</div>
