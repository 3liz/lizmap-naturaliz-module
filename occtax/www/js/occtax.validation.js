lizMap.events.on({
    'uicreated':function(evt){

        function runAction(params, a_callback) {
            a_callback = typeof a_callback !== 'undefined' ?  a_callback : null;
            var tokenFormId = $('#validation form').attr('id');
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

        function refreshValidationBasket() {
            var params = {
                'validation_action': 'get'
            };
            runAction(params, function(content) {
                if (content && 'data' in content && Array.isArray(content.data)) {
                    var counter = content.data.length;
                    $('span.validation_basket_counter').html(counter);
                }
            });
        }

        // Disconnect form submit
        $('#validation form').submit(function(){

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

            });

            return false;
        });

        // Activate buttons
        $(document).on('click', 'button.occtax_validation_button', function(){
            var action = $(this).val();
            var id = null;
            var get_id = action.split('@');
            if (get_id.length == 2) {
                action = get_id[0];
                id = get_id[1];
            }

            var params = {
                'validation_action': action,
                'id': id
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

    } // uicreated
});

