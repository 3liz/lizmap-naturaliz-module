
<div id="metadata-jdd-container"  class="menu-content">
{if !empty($jdds)}
{foreach $jdds as $jdd}
    <table class="table table-condensed table-striped">
        <tr>
            <th>{@metadata.input.jdd.id.title@}</th>
            <td>{$jdd->jdd_id}</td>
        </tr>
        <tr>
            <th>{@metadata.input.jdd.metadonnee_dee_id.title@}</th>
            <td>{$jdd->jdd_metadonnee_dee_id}</td>
        </tr>
        <tr>
            <th>{@metadata.input.jdd.libelle.title@}</th>
            <td>{$jdd->jdd_libelle}</td>
        </tr>
        <tr>
            <th>{@metadata.input.jdd.code.title@}</th>
            <td>{$jdd->jdd_code}</td>
        </tr>
        <tr>
            <th>{@metadata.input.jdd.description.title@}</th>
            <td>{$jdd->jdd_description}</td>
        </tr>

    </table>
{/foreach}
{else}
{@metadata.error.jdd.not.found@}
{/if}
</div>
