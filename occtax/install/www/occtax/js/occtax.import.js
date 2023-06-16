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

        /**
         * Copy the inner text of a given HTML element
         *
         * @param {HTMLElement} element The element to copy content from.
         */
        function copyElementText(element) {

            // Get element inner text
            let textToCopy = element.innerText;

            // Create a fake input element
            let myTemporaryInputElement = document.createElement("input");
            myTemporaryInputElement.type = "text";
            myTemporaryInputElement.value = textToCopy;
            document.body.appendChild(myTemporaryInputElement);

            // Copy the fake element content
            myTemporaryInputElement.select();
            document.execCommand("Copy");

            // Remove the fake element
            document.body.removeChild(myTemporaryInputElement);

            // Add a success message
            OccTax.addTimedMessage(
                'import-naturaliz',
                'Les identifiants ont bien été copiés dans le presse-papier !',
                'info',
                2000,
                true
            );
        }
        OccTax.copyElementText = function (element) {
            return copyElementText(element);
        }

        // Handle form submit
        // First set the check_or_import input data depending on the clicked button
        $('#jforms_occtax_import input[type="submit"]').on('click', function () {
            let action_input = $('#jforms_occtax_import input[name="check_or_import"]');
            action_input.val(this.name);
        });
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
                let status_check = (response.status_check == 0) ? 'error' : 'info';
                let action = response.action;

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

                if (status_check == 'error') {
                    OccTax.addTimedMessage('import-naturaliz', response.messages.join('</br>'), status_check, 30000, true);
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
                        html += '<tr title="' + intitule + '">';
                        html += '  <td>' + intitule + '</td>';
                        html += '  <td>' + error_line['nb_lines'] + '</td>';
                        let ids = error_line['ids_text'].split(', ');
                        let displayedIds = ids.join(', ');
                        let maxNumber = 5;
                        if (ids.length > maxNumber) {
                            displayedIds = ids.slice(0, maxNumber).join(', ') + ' [...]';
                        }

                        html += '  <td>' + displayedIds;
                        html += '    <span style="display:none;">' + error_line['ids_text'] + '</span>';
                        html += '    <button class="copy-content btn btn-mini" onclick="OccTax.copyElementText(this.previousElementSibling);" title="Copier les identifiants concernés">copier</button>';
                        html += '  </td>';
                        html += '</tr>';
                    }
                    $('#import_conformite_' + type_conformite).html(table_header + html);
                    $('a[href="#import_conformite"]').click();
                }

                if (action == 'import') {
                    let status_import = (response.status_import == 0) ? 'error' : 'info';

                    console.log(status_import);
                    // import has been tried: open the result tab
                    $('a[href="#import_resultat"]').click();

                    if (status_import == 'error') {
                        console.log(response.data);
                        // Add data in the error table
                        if ('duplicate_ids' in response.data) {
                            $('#import_erreurs_nombre').html(response.data['duplicate_count']);
                            $('#import_erreurs_ids').html(response.data['duplicate_ids']);
                            $('#import_erreurs_nombre_all').html(response.data['duplicate_count_all']);
                            $('#import_erreurs_ids_all').html(response.data['duplicate_ids_all']);
                            $('#import_erreurs').show();
                        }

                        // Empty the data from the success table
                        $('#import_resultat_observations').html('-');
                        $('#import_resultat_organismes').html('-');
                        $('#import_resultat_personnes').html('-');
                        $('#import_resultat_observateurs').html('-');
                        $('#import_resultat_determinateurs').html('-');

                        // Display message
                        var msg = response.messages.join('</br>');
                        OccTax.addTimedMessage('import-naturaliz', msg, status_import, 30000, true);
                        $('#import_message_resultat')
                            .html("❗" + msg)
                            .css('color', 'red')
                            ;

                    } else {
                        // Empty data in the error table
                        $('#import_erreurs').hide();
                        $('#import_erreurs_nombre').html('-');
                        $('#import_erreurs_ids').html('-');
                        $('#import_erreurs_nombre_all').html('-');
                        $('#import_erreurs_ids_all').html('-');

                        // Add data in the result table
                        $('#import_resultat_observations').html(response.data['observations']['nb']);
                        $('#import_resultat_organismes').html(response.data['other']['organismes']);
                        $('#import_resultat_personnes').html(response.data['other']['personnes']);
                        $('#import_resultat_observateurs').html(response.data['other']['observateurs']);
                        $('#import_resultat_determinateurs').html(response.data['other']['determinateurs']);

                        // Display message
                        if (response.data['observations']['nb'] > 0) {
                            var msg = response.messages.join('</br>');
                        } else {
                            var msg = "Aucune observation n'a été importée.";
                            msg += ' Elles sont probablement déjà dans la base, en attente de validation';
                        }
                        OccTax.addTimedMessage('import-naturaliz', msg, status_import, 30000, true);
                        $('#import_message_resultat')
                            .html("✅ " + msg)
                            .css('color', 'green')
                            ;
                    }

                    return false;
                }

            });
            // TODO Gérer les cas où il y a une erreur (code pas 200 cf fonction sendNewFeatureForm)

            return false;
        });
    }
});
