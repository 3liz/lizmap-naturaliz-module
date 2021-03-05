lizMap.events.on({
    'uicreated':function(evt){

        function runAction(params) {
            var tokenFormId = $('#validation form').attr('id');
            var url = $('#'+tokenFormId).attr('action');
            $.getJSON(
                url,
                params,
                function(data){
                    console.log(data);
                }
            );
        }

        // Disconnect form submit
        $('#validation form').submit(function(){
            console.log('Submit canceled');

            return false;
        });
        // Activate buttons
        $('#validation button.occtax_validation_button').click(function(){
            var id = '0d6ff02f-9970-4bd7-b6f6-60bcd2fa959a';
            var params = {
                'validation_action': $(this).val(),
                'id': id
            };
            runAction(params);
            return false;
        });

    } // uicreated
});

