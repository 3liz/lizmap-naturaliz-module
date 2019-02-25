{assign $a = implode( ',', $fields['return']) }
<div class="scroll-container">
<table id="{$tableId}" class="table table-striped table-bordered" data-value="{$a}">
    <thead>
        <tr data-value="{$fields['row_id']}">
        {foreach $fields['display'] as $field=>$config}
            <th data-value="{$field},{$config['type']},{$config['sortable']}{if array_key_exists('className',$config)},{$config['className']}{/if}" {if $field==$fields['row_label']} class="row-label"{/if}>
                {@$localeModule~search.output.$field@}
            </th>
        {/foreach}
        </tr>
    </thead>
</table>
</div>
