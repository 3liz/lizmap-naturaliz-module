<div id="metadata-cadre-container"  class="menu-content">
    {if !empty($cadre)}
    <table class="table table-condensed table-striped">

        <tr>
            <th>{@metadata.input.cadre.id.title@}</th>
            <td>{$cadre->cadre_id}</td>
        </tr>
        <tr>
            <th>{@metadata.input.cadre.uuid.title@}</th>
            <td>{$cadre->cadre_uuid}</td>
        </tr>
        <tr>
            <th>{@metadata.input.cadre.libelle.title@}</th>
            <td>{$cadre->libelle}</td>
        </tr>
        <tr>
            <th>{@metadata.input.cadre.description.title@}</th>
            <td>{$cadre->description}</td>
        </tr>

    </table>
    {else}
    {@metadata.error.cadre.not.found@}
    {/if}
</div>
