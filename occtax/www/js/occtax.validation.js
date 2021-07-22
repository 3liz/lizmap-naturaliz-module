lizMap.events.on({
    'uicreated':function(evt){

        // Move form into body so that modal behaves correctly
        $('#occtax-validation-form-modal').appendTo('body');

        // Use Validation API entrypoint to send data
        // And get response
        function runAction(params, a_callback) {
            a_callback = typeof a_callback !== 'undefined' ?  a_callback : null;
            var tokenFormId = $('#occtax-validation-form-modal form').attr('id');
            var url = $('#'+tokenFormId).attr('action');
            $.getJSON(
                url,
                params,
                function(data){
                    if (a_callback) {
                        a_callback(data);
                    }

                    // Open the mini-dock if not visible
                    $('#mapmenu li.validation:not(.active) a').click();

                    // Add message if everything is ok
                    var action = params['validation_action'];
                    if (action == 'add' || action == 'remove') {
                        var msg = data.message;
                        var msg_type = 'info';
                        if (data.status == 'error') msg_type = 'error';
                        $('#occtax-message').remove();
                        lizMap.addMessage( msg, msg_type, true ).attr('id','occtax-message');
                    }
                }
            );
        }

        // Refresh the counter of validation basket observations
        function refreshValidationBasket(refresh_observation_table) {
            var params = {
                'validation_action': 'get'
            };
            runAction(params, function(content) {
                if (content && 'data' in content && Array.isArray(content.data)) {
                    var nb = content.data[0]['nb'];
                    var counter_text = ' observation';
                    if (nb > 1) counter_text += 's';
                    $('span#validation_basket_counter').html(nb);
                    $('span#validation_basket_counter_text').html(counter_text);
                }
                if (refresh_observation_table) {
                    // Reload observation table
                    $('#occtax_results_observation_table').DataTable().ajax.reload(null, false);
                }
            });
        }

        // Activate open form button
        $(document).on('click', 'button.occtax_validation_open_form_button', function(){
            var id = $(this).val();
            var vparams = [
                'niv_val', 'producteur', 'date_contact', 'comm_val', 'nom_retenu',
                'identifiant_permanent'
            ];

            // Reset previous form content
            var tokenFormId = $('#occtax-validation-form-modal form').attr('id');
            reinitValidationForm();

            // If ID is given, we need to open the form and fill it with the chosen observation data
            if (id) {
                var params = {
                    'validation_action': 'observation_validity',
                    'id': id
                };
                // Get the data from the database
                runAction(params, function(content) {
                    $('#occtax-message').remove();
                    if (content.status == 'error') {
                        lizMap.addMessage( content.message, 'error', true ).attr('id','occtax-message');
                        return false;
                    }
                    if (content && 'data' in content && Array.isArray(content.data)) {
                        var obs = content.data[0];
                        var tokenFormId = $('#occtax-validation-form-modal form').attr('id');

                        // main fields
                        for (var v in vparams) {
                            var key = vparams[v];
                            $('#' + tokenFormId + ' [name="'+key+'"]').val(obs[key]);
                        }

                        // Datepicker
                        var date_ctrl = 'date_contact';
                        var date_value = obs[date_ctrl]
                        if (date_value) {
                            $('#' + tokenFormId + ' [name="'+date_ctrl+'[year]"]').val(date_value.split('-')[0]);
                            $('#' + tokenFormId + ' [name="'+date_ctrl+'[month]"]').val(date_value.split('-')[1]);
                            $('#' + tokenFormId + ' [name="'+date_ctrl+'[day]"]').val(date_value.split('-')[2]);
                            $('#' + tokenFormId + ' [name="'+date_ctrl+'_hidden"]').val(date_value);
                        }

                        // Rename modal and submit button
                        $('#occtax-validation-form-modal div.modal-header h3').html(
                            naturalizLocales['button.validate.observation.confirm.title']
                        );
                        $('#' + tokenFormId + ' [name="submit"]').val(
                            naturalizLocales['button.validate.observation.title']
                        );

                        // Show form
                        $('#occtax-validation-form-modal').modal('show');
                    }

                });
            } else {
                // Simply show the form: all observations in the basket will be modified
                // Rename modal
                $('#occtax-validation-form-modal div.modal-header h3').html(
                    naturalizLocales['button.validation_basket.validate.confirm.title']
                );
                $('#' + tokenFormId + ' [name="submit"]').val(
                    naturalizLocales['input.submit']
                );

                // Show
                $('#occtax-validation-form-modal').modal('show');

                // Close subdock
                $('#sub-dock').hide().html('');
            }

            return false;
        });

        // Reinitialise validation form
        function reinitValidationForm() {
            var tokenFormId = $('#occtax-validation-form-modal form').attr('id');

            // Reinit main fields
            $('#'+tokenFormId).trigger("reset");

            // Reinit date picker
            $('#'+tokenFormId+' .ui-datepicker-reset').click();


            var vparams = [
                'niv_val', 'producteur', 'date_contact', 'comm_val', 'nom_retenu',
                'identifiant_permanent'
            ];
            for (var v in vparams) {
                var key = vparams[v];
                $('#' + tokenFormId + ' [name="'+key+'"]').val('');
            }

        };

        // Handle form submit
        $('#occtax-validation-form-modal form').submit(function(){

            // On vérifie si pas d'erreur jForms côté client
            var error_div = $('#jforms_occtax_validation_errors');
            if (error_div.length) {
                var has_client_error = $('#jforms_occtax_validation_errors').html().length;
                if (has_client_error) return false;
            }

            // On récupère les valeurs du formulaire
            var form_params = $(this).serializeArray();
            var params = {
                'validation_action': 'validate'
            };
            for (var i in form_params){
                var param = form_params[i];
                params[param.name] = param.value;
            }

            // On demande confirmation avant de lancer la validation
            // Le message dépend du contexte (validation d'une obervation ou du panier)
            var nl = "\r\n";
            // Message pour le panier
            var confirm_msg = naturalizLocales['button.validation_basket.validate.confirm.title'].toUpperCase();
            var nb = $('span#validation_basket_counter').html();
            confirm_msg += nl + nl + naturalizLocales['button.validation_basket.validate.confirm'].replace('%s', nb)
            // Message pour une observation
            var ident = params['identifiant_permanent'];
            if (ident) {
                confirm_msg = naturalizLocales['button.validate.observation.confirm.title'].toUpperCase();
                confirm_msg += nl + nl + naturalizLocales['button.validate.observation.confirm'];
            }
            var confirm_action = confirm(confirm_msg);
            if (!confirm_action) {
                return false;
            }

            // Run the Ajax query to validate the given observation of the observations in basket
            runAction(params, function(content) {

                $('#occtax-message').remove();
                if (content.status == 'error') {
                    lizMap.addMessage( content.message, 'error', true ).attr('id','occtax-message');
                    return false;
                }
                lizMap.addMessage( content.message, 'info', true ).attr('id','occtax-message');

                // Reload observation table
                $('#occtax_results_observation_table').DataTable().ajax.reload(null, false);

                // Reload observation validation panel
                // only for single observation
                if (content.data && content.data.length == 1
                    && 'cle_obs' in content.data[0]
                    && content.message == naturalizLocales['button.validate.observation.success']
                ) {
                    OccTax.showObservationValidation(content.data[0]['cle_obs']);
                } else {
                    // Close subdock
                    $('#sub-dock').hide().html('');
                }

                // Close Form
                reinitValidationForm();
                $('#occtax-validation-form-modal').modal('hide');

                return false;

            });

            return false;
        });

        // Activate API validation buttons
        $(document).on('click', '.occtax_validation_button', function(){
            var action_val = $(this).val();
            var is_button = true;
            var in_observation_table = $(this).hasClass('datatable')

            // For a instead of button, get href instead
            if (!action_val && in_observation_table) {
                action_val = $(this).attr('href').replace('#', '')
                is_button = false;
            }
            if (!action_val) {
                return false;
            }

            var uid = null;
            var action = action_val;
            var get_id = action_val.split('@');
            if (get_id.length == 2) {
                action = get_id[0];
                uid = get_id[1];
            }
            if (!action) {
                return false;
            }

            var params = {
                'validation_action': action,
                'identifiant_permanent': uid
            };

            // Ask confirmation for delete or empty
            if (action == 'remove' || action == 'empty') {
                var nl = "\r\n";
                var confirm_msg = naturalizLocales['button.validation_basket.'+action+'.confirm.title'].toUpperCase();
                confirm_msg += nl + nl + naturalizLocales['button.validation_basket.'+action+'.confirm'];
                var confirm_action = confirm(confirm_msg);
                if (!confirm_action) {
                    return false;
                }
            }

            // Change button interface
            if (action == 'remove' || action == 'add') {
                // Flip action after change: add -> delete and vise et versa
                var new_action = 'remove';
                var star_class = 'icon-star';
                if (action == 'remove') {
                    new_action = 'add';
                    star_class = 'icon-star-empty';
                }
                var new_val = action_val.replace(action, new_action);
                if (is_button) {
                    $(this).attr('value', new_val);
                    $(this).html(naturalizLocales['button.validation_basket.'+new_action+'.title']);
                } else {
                    $(this).attr('href', '#' + new_val)
                    $(this).find('i').attr('class', star_class);
                    $(this).parent().focus()
                }
                $(this).attr('tooltip', naturalizLocales['button.validation_basket.'+new_action+'.help']);
                $(this).attr('title', naturalizLocales['button.validation_basket.'+new_action+'.help']);

                // Close subdock
                $('#sub-dock').hide().html('');

            }

            // Run action
            if (in_observation_table) {
                // If the clicked item is a a inside the observation table
                // Do not refresh the datatable table
                runAction(params, function(){
                    refreshValidationBasket(false);
                });
            } else {
                runAction(params, function(){
                    refreshValidationBasket(true);
                });
            }


            return false;
        });

        // Show only observation from the basket
        $('#validation button.occtax_validation_filter_button').click(function() {
            // Run reinit
            var tokenFormId = $('#div_form_occtax_search_token form').attr('id');
            $('#'+tokenFormId+'_reinit').click();

            // Check the adequate form checkbox
            $('#' + tokenFormId + ' [name="panier_validation"]').prop("checked", true);

            // Re submit form
            $('#'+tokenFormId).submit();

        });


        // Add search result to basket
        $('#occtax-search-to-basket').click(function() {
            $('#occtax-message').remove();
            var search_token = $('#occtax_service_search_form input[name="token"]').val();
            if (!search_token) {
                var msg = naturalizLocales['button.add.search.to.basket.error.token'];
                lizMap.addMessage( msg, 'error', true ).attr('id','occtax-message');
                return false;
            }
            var params = {
                'validation_action': 'add_search_to_basket',
                'token': search_token
            };
            var nb = $('#occtax_observation_records_total').val();
            var nl = "\r\n";
            var confirm_msg = naturalizLocales['button.add.search.to.basket.confirm.title'].toUpperCase();
            confirm_msg += nl + nl + naturalizLocales['button.add.search.to.basket.confirm'].replace('%s', nb)
            var confirm_action = confirm(confirm_msg);
            if (!confirm_action) {
                return false;
            }
            runAction(params, function(content) {
                if (content && 'data' in content && Array.isArray(content.data)) {
                    var data = content.data;
                    var count = data[0]['count'];
                    var localized_msg = 'button.add.search.to.basket.result.count';
                    if (count == 1) {
                        localized_msg+= '.singulier';
                    }
                    var msg = count + ' ' + naturalizLocales[localized_msg]
                    lizMap.addMessage( msg, 'info', true ).attr('id','occtax-message');

                    // Refresh validation basket counter
                    refreshValidationBasket(true);
                }
            });
        });

    } // uicreated
});

