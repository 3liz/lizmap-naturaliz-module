lizAdaptEditingCreateChildCombobox = function () {
    // Text displayed before the new buttons
    var create_child_help_msg = 'Vous pouvez ajouter des éléments liés à l\'objet en cours d\'édition';

    // If we should display a confirm message
    // before opening the child feature
    var create_child_display_confirm_msg = true;

    // Content of the confirm messages
    // @child_layer@ will be replaced by the name of the layer
    var create_child_confirm_msg = '';
    create_child_confirm_msg += 'Vous aller ajouter un nouvel élément fils "@child_layer@"';
    create_child_confirm_msg += ' pour l\'objet parent actuellement en cours d\'édition.\n';
    create_child_confirm_msg += ' Veillez à bien avoir enregistré avant les modifications de l\'objet parent.\n\n';
    create_child_confirm_msg += ' Souhaitez-vous continuer ?';

    // List of layers for which to reopen the form
    // when a new feature has been created
    // This will ease the addition of child features
    // Use a list of layers names
    var reopen_form_after_creation_for_layers = [
        'acteur',
        'organisme',
        'adherent'
    ]

    function adaptFormCreateChildrenInterface() {
        // Hide "Create child" button group
        $('#edition-children-container div.btn-group').hide();

        var html_buttons = '';

        // Add help message
        if (create_child_help_msg) {
            html_buttons += '<p>' + create_child_help_msg + '</p>';
        }

        // Loop for each original create child links and create a dedicated button
        $('#edition-children-container div.btn-group a.btn-createFeature-attributeTable').each(function () {

            var cleanName = $(this).attr('href').replace('#', '');
            //var aName = attributeLayersDic[cleanName];
            var aName = cleanName;
            var childLayerConfig = lizMap.config.layers[aName];

            // Add a new button
            html_buttons += '<button class="btn btn-mini btn-createChild" value="' + cleanName + '">';
            html_buttons += '➕ ' + childLayerConfig['title'];
            html_buttons += '</button>';
        })

        // Add the new buttons container if missing
        if ($('#edition-children-add-buttons').length == 0) {
            $('#edition-children-container').prepend('<div id="edition-children-add-buttons"></div>')
        }

        // Add the buttons in the container
        $('#edition-children-add-buttons').html(html_buttons);

        // Activate the buttons
        activateNewAddChildButtons();
    }

    function activateNewAddChildButtons() {
        $('#edition-children-add-buttons button.btn-createChild').click(function () {
            var childCleanName = $(this).val();
            //var aName = attributeLayersDic[cleanName];
            var aName = childCleanName;
            var childLayerConfig = lizMap.config.layers[aName];
            if (create_child_display_confirm_msg) {
                var confirm_msg = create_child_confirm_msg.replace('@child_layer@', childLayerConfig['title']);
                var has_confirmed = confirm(confirm_msg);
                if (!has_confirmed) {
                    return false;
                }
            }

            // Click on the hidden original link
            $('#edition-children-container div.btn-group a.btn-createFeature-attributeTable[href="#' + childCleanName + '"]').click();
        });
    }

    function moveChildrenTablesInsideForm() {
        // Find child layers
        var has_child_tables = false;
        $('#edition-children-container div.edition-children-content div.attribute-layer-child-content').each(function () {
            has_child_tables = true;

            // Get parent layer
            var parent_layer = $(this).find('input.attribute-table-hidden-parent-layer').val();

            // Get child layer table
            var child_layer = $(this).find('input.attribute-table-hidden-layer').val();

            // Get child attribute table id
            var parent_and_child = parent_layer + '-' + child_layer;
            var child_table_id = 'edition-child-tab-' + parent_and_child;

            // Move the child attribute table to the group corresponding to the child table
            // TODO : find a better way (improve LWC code)
            // var last_tab_id = $('#jforms_view_edition-tab-content').find('div.tab-pane:last').attr('id');
            var target_group_legend = $('#jforms_view_edition legend').filter(function() {
                return ($(this).text() === parent_and_child)
            });

            var target_group_div = target_group_legend.next('div.jforms-table-group');
            $('#' + child_table_id).appendTo(target_group_div);

            // Replace legend code by the child layer name
            var child_layer_name = lizMap.getLayerNameByCleanName(child_layer);
            target_group_legend.text(child_layer_name);
        })

        // Hide child attribute tables container (the one under the form
        if (has_child_tables) {
            $('div.edition-children-content').hide();
        }
    }

    lizMap.events.on({

        'lizmapeditionformdisplayed': function(evt) {
            // Get parent editing layer config
            var getLayerConfig = lizMap.getLayerConfigById(evt['layerId']);
            if (!getLayerConfig) { return true; }
            var layerConfig = getLayerConfig[1];
            // var featureType = getLayerConfig[0];

            // Check if it is a new feature or a modification
            let featureId = evt['featureId'];
            var isCreation = true;
            if (/^(0|[1-9]\d*)$/.test(featureId)) {
                isCreation = false;
            }

            // Reopen the form once the new observation has been created
            // to allow to add child features
            if (isCreation && reopen_form_after_creation_for_layers.indexOf(layerConfig['name']) > -1) {
                // Reopen the form once the observation is created
                $('#jforms_view_edition_liz_future_action').val('edit');
            }else {
                $('#jforms_view_edition_liz_future_action').val('close');
            }


            // Replace the combobox with child layers
            // by several buttons, one per child layer
            if (!isCreation) {
                setTimeout(function () {
                    adaptFormCreateChildrenInterface();
                }, 500);
            }

            // Move children tables inside the form
            setTimeout(function () {
                moveChildrenTablesInsideForm();
            }, 500);

        }
    });

    return true;
}();
