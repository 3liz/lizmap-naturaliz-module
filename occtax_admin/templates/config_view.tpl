{jmessage_bootstrap}

<h1>Configuration Occtax</h1>

{formdatafull $form}

<!-- Modify -->
{ifacl2 'lizmap.admin.services.update'}
<div class="form-actions">
    <a class="btn" href="{jurl 'occtax_admin~config:modify'}">
        {@admin~admin.configuration.button.modify.service.label@}
    </a>
</div>
{/ifacl2}
