lizMap.events.on({
    'uicreated': function (evt) {

        /**
         *
         * @param {FormData} formData
         * @return {Promise}
         */
        function sendNewFeatureForm(url, formData) {
            return new Promise(function (resolve, reject) {

                var request = new XMLHttpRequest();
                request.open("POST", url);
                request.onload = function (oEvent) {
                    if (request.status == 200) {
                        resolve(request.responseText);
                    } else {
                        reject();
                    }
                };
                request.send(formData);
            });
        }

        // Handle form submit
        $('#jforms_occtax_import').submit(function () {
            $('body').css('cursor', 'wait');
            var form_id = '#jforms_occtax_import';
            var form = $(form_id);
            var form_data = new FormData(form.get(0));
            var url = form.attr('action');

            // Post data
            var sendFormPromise = sendNewFeatureForm(url, form_data);
            sendFormPromise.then(function (data) {
                $('body').css('cursor', 'auto');
                let response = JSON.parse(data);
                let status = (response.status == 0) ? 'error' : 'info';
                let type_conformites = ['not_null', 'format', 'conforme'];

                var table_header = '';
                table_header += '<tr>';
                table_header += '    <th width="70%">Libellé</th>';
                table_header += '    <th>Nombre de lignes en erreur</th>';
                table_header += '    <th>Identifiants concernés</th>';
                table_header += '</tr>';
                var empty_html = '';
                empty_html += '<tr>';
                empty_html += '<td>-</td>';
                empty_html += '<td>-</td>';
                empty_html += '<td>-</td>';
                empty_html += '</tr>';

                if (status == 'error') {
                    OccTax.addTimedMessage('import-naturaliz', response.messages.join('</br>'), status, 30000, true);
                    for (var c in type_conformites) {
                        var type_conformite = type_conformites[c];
                        $('#import_conformite_' + type_conformite).html(table_header + empty_html);
                    }
                    return false;
                }

                // No error, display green message
                if (response.data
                    && response.data.not_null.length == 0
                    && response.data.format.length == 0
                    && response.data.conforme.length == 0
                ) {
                    $('#import_message')
                    .html("✅ Aucune erreur n'a été détectée. Vos données sont valides !")
                    .css('color', 'green')
                    ;
                } else {
                    $('#import_message')
                    .html("❗Des erreurs ont été détectées dans votre jeu de données !")
                    .css('color', 'red')
                    ;
                }

                for (var c in type_conformites) {
                    var type_conformite = type_conformites[c];
                    var lines = response.data[type_conformite];
                    var nb_errors = lines.length;
                    var html = '';
                    for (var e in lines) {
                        var error_line = lines[e];
                        var intitule = (error_line.description !== null && error_line.description != '') ? error_line.description : error_line.libelle;
                        // console.log('TEST');
                        // console.log(error_line);
                        // console.log(intitule);
                        html += '<tr title="' + intitule + '">';
                        html += '<td>' + intitule + '</td>';
                        html += '<td>' + error_line['nb_lines'] + '</td>';
                        html += '<td>' + error_line['ids_text'] + '</td>';
                        html += '</tr>';
                    }
                    $('#import_conformite_' + type_conformite).html(table_header + html);
                    $('a[href="#import_conformite"]').click()
                }
            });

            return false;
        });
    }
});
