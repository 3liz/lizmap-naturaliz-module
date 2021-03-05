<div style="height:100%;overflow:auto;">
    <h3 class="occtax_search"><span class="title"><span class="icon search"></span>&nbsp;<span class="text">{@validation.dock.title@}</span></span></h3>
    <div class="menu-content">
        Contenu du panier
        <table>
            <tr>
                <th>Nombre d'observations</th>
                <td>{$counter}</td>
            </tr>
        </table>
        <form id="validation_form" method="post" action="{jurl 'occtax~validation:index'}">
            <button value="get" class="occtax_validation_button btn btn-mini" tooltip="{@validation.button.empty_validation_basket.tooltip@}">Get</button>
            <button value="add" class="occtax_validation_button btn btn-mini" tooltip="{@validation.button.empty_validation_basket.tooltip@}">Add</button>
            <button value="remove" class="occtax_validation_button btn btn-mini" tooltip="{@validation.button.empty_validation_basket.tooltip@}">Del</button>
            <button value="empty" class="occtax_validation_button btn btn-mini" tooltip="{@validation.button.empty_validation_basket.tooltip@}">{@validation.button.empty_validation_basket.title@}</button>
        </form>

    </div>
</div>
