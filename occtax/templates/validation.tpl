<div style="height:100%;overflow:auto;">
    <h3 class="occtax_search"><span class="title"><span class="icon search"></span>&nbsp;<span class="text">{@validation.dock.title@}</span></span></h3>
    <div class="menu-content">
        Contenu du panier
        <table>
            <tr>
                <th>Nombre d'observations</th>
                <td><span class="validation_basket_counter">{$counter}</span></td>
            </tr>
        </table>
        <form id="validation_form" method="post" action="{jurl 'occtax~validation:index'}">
            <button value="empty" class="occtax_validation_button btn btn-mini" title="{@validation.button.validation_basket.empty.help@}">{@validation.button.validation_basket.empty.title@}</button>
        </form>

    </div>
</div>
