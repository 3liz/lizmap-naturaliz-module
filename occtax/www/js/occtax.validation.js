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
                }
            );
        }

        // Refresh the counter of validation basket observations
        function refreshValidationBasket() {
            var params = {
                'validation_action': 'get'
            };
            runAction(params, function(content) {
                if (content && 'data' in content && Array.isArray(content.data)) {
                    var nb = content.data[0]['nb'];
                    $('span.validation_basket_counter').html(nb);
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
            // Close subdock
            $('#sub-dock').hide().html('');

            // Reset previous form content
            var tokenFormId = $('#occtax-validation-form-modal form').attr('id');
            for (var v in vparams) {
                var key = vparams[v];
                $('#' + tokenFormId + ' [name="'+key+'"]').val('');
            }
            if (id) {
                var params = {
                    'validation_action': 'observation_validity',
                    'id': id
                };
                runAction(params, function(content) {
                    $('#occtax-message').remove();
                    if (content.status == 'error') {
                        lizMap.addMessage( content.message, 'error', true ).attr('id','occtax-message');
                        return false;
                    }
                    if (content && 'data' in content && Array.isArray(content.data)) {
                        var obs = content.data[0];
                        var tokenFormId = $('#occtax-validation-form-modal form').attr('id');
                        for (var v in vparams) {
                            var key = vparams[v];
                            $('#' + tokenFormId + ' [name="'+key+'"]').val(obs[key]);
                        }
                        // Show form
                        $('#occtax-validation-form-modal').modal('show');
                    }

                });
            } else {
                // Simply show the form: all observations in the basket will be modified
                $('#occtax-validation-form-modal').modal('show');
            }

            return false;
        });

        // Handle form submit
        $('#occtax-validation-form-modal form').submit(function(){

            // On demande confirmation avant de lancer la validation
            // En précisant que la recherche a été lancée pour lui montrer seulement les données du panier
            // On lance la recherche après réinitialisation du formulaire et case du panier cochée
            // L'utilisateur peut alors vérifier
            var confirm_action = confirm(naturalizLocales['button.validation_basket.validate.confirm']);
            if (!confirm_action) {
                return false;
            }
            var form_params = $(this).serializeArray();
            var params = {
                'validation_action': 'validate'
            };
            for (var i in form_params){
                var param = form_params[i];
                params[param.name] = param.value;
            }

            // Add single observation ID if coming from
            runAction(params, function(content) {

                $('#occtax-message').remove();
                if (content.status == 'error') {
                    lizMap.addMessage( content.message, 'error', true ).attr('id','occtax-message');
                    return false;
                }
                lizMap.addMessage( content.message, 'info', true ).attr('id','occtax-message');

                //var tokenFormId = $('#div_form_occtax_search_token form').attr('id');
                //$('#' + tokenFormId + ' [name="'+name+'"]').prop("checked", true);
                //$('#'+tokenFormId).submit();

                // Reload observation table
                $('#occtax_results_observation_table').DataTable().ajax.reload(null, false);

                return false;

            });

            return false;
        });

        // Activate API validation buttons
        $(document).on('click', 'button.occtax_validation_button', function(){
            var action = $(this).val();
            var uid = null;
            var get_id = action.split('@');
            if (get_id.length == 2) {
                action = get_id[0];
                uid = get_id[1];
            }

            var params = {
                'validation_action': action,
                'identifiant_permanent': uid
            };

            // Ask confirmation for delete
            if (action == 'remove' || action == 'empty') {
                var confirm_action = confirm(naturalizLocales['button.validation_basket.'+action+'.confirm']);
                if (!confirm_action) {
                    return false;
                }
            }
            runAction(params, refreshValidationBasket);

            // Change button interface
            if (action == 'remove' || action == 'add') {
                // Flip action after change: add -> delete and vise et versa
                var new_action = 'remove';
                if (action == 'remove') {
                    var new_action = 'add';
                }
                var new_val = $(this).val().replace(action, new_action);
                $(this).attr('value', new_val)
                $(this).attr('tooltip', naturalizLocales['button.validation_basket.'+new_action+'.help']);
                $(this).attr('title', naturalizLocales['button.validation_basket.'+new_action+'.help']);
                $(this).html(naturalizLocales['button.validation_basket.'+new_action+'.title']);

                // Close subdock
                $('#sub-dock').hide().html('');

                // Reload observation table
                $('#occtax_results_observation_table').DataTable().ajax.reload(null, false);
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
            var confirm_action = confirm(naturalizLocales['button.add.search.to.basket.confirm']);
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
                    refreshValidationBasket();

                    // Reload observation table
                    $('#occtax_results_observation_table').DataTable().ajax.reload(null, false);
                }
            });
        });

    } // uicreated
});

