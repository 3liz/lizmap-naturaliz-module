<div style="height:100%;overflow:auto;">
    <h3 class="occtax_search"><span class="title"><span class="icon search"></span>&nbsp;<span class="text">{@validation.validation.dock.title@}</span></span></h3>
    <div class="menu-content">
        {@validation.validation.dock.subtitle@} :</br>
        <b><span id="validation_basket_counter">{$counter}</span></b> observation{if $counter > 1}s{/if}

        <div id="validation_basket_button_bar">
            <button value="empty" class="occtax_validation_button btn btn-mini btn-primary" title="{@validation.button.validation_basket.empty.help@}">{@validation.button.validation_basket.empty.title@}</button>
            <button value="" class="occtax_validation_open_form_button btn btn-mini btn-primary" title="{@validation.button.validation_basket.open.form.help@}">{@validation.button.validation_basket.open.form.title@}</button>
            <button value="" class="occtax_validation_filter_button btn btn-mini btn-primary" title="{@validation.button.validation_basket.filter.observations.help@}">{@validation.button.validation_basket.filter.observations.title@}</button>
        </div>

    </div>
</div>

<!--
        Validation form
-->
<div id="occtax-validation-form-modal" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true" data-show="false" data-keyboard="false" data-backdrop="static">
    <div class="modal-header" style="background-color:rgba(0, 0, 0, 0.7);"><a class="close" data-dismiss="modal">X</a>
        <h3 style="color:white;">{@validation.input.submit@}</h3></div>
        <div class="modal-body">
            <div class="occtax_validation_form">
                {formfull $form, 'occtax~validation:index', array(), 'htmlbootstrap'}
            </div>
        </div>
        <div class="modal-footer" style="background-color:rgba(0, 0, 0, 0.7);">
            <button type="button" class="btn btn-default" data-dismiss="modal">{@validation.button.validation_basket.close.form.title@}</button>
        </div>
    </div>
</div>
