var uiprete = false;
var blocme = true;
var error_connection = false;
var previous_search_token = null;
var observation_geometries_displayed = false;
var observation_geometries_extent = null;
var search_history_max_unstared = 10;
var search_history_max_stared = 20;

function unblockSearchForm() {
    uiprete = true;
    blocme = false;
    $("#div_form_occtax_search_token form input[type=submit]").prop('disabled', false);
}

function blockSearchForm() {
    // hide search form
    $("#div_form_occtax_search_token form input[type=submit]").prop('disabled', true);
    // Block search form
    var tokenFormId = $('#div_form_occtax_search_token form').attr('id');
    $('#' + tokenFormId).submit(function () {
        if (!uiprete) return false;
    })
};

$(document).ready(function () {
    blockSearchForm();
});


OccTax.events.on({
    'uicreated': function (evt) {

        function checkConnection() {
            // If the user was not connected, nothing to do
            if (!(occtaxClientConfig.is_connected)) {
                return true;
            }

            // If the user was connected, check if it is still connected
            var tokenFormId = $('#div_form_occtax_search_token form').attr('id');
            var url = $('#' + tokenFormId).attr('action').replace('initSearch', 'isConnected');
            $.getJSON(url, null, function (cdata) {
                if (!(cdata.is_connected)) {
                    var baseUrl = window.location.protocol + '//' + document.domain + lizUrls.basepath;
                    var url_return = '%2Findex.php%2Focctax%2F';
                    url_return += encodeURIComponent(window.location.search);
                    var loginurl = baseUrl + 'admin.php/auth/login/?auth_url_return=' + url_return;
                    if (!error_connection) {
                        if (!alert('Votre session a expiré ! La page va être rechargée.')) {
                            error_connection = true;
                            window.location = loginurl;
                        }
                    } else {
                        window.location = loginurl;
                    }
                    return false;
                }
            });
            return true;
        }


        // Close a Lizmap message by container id
        function closeMessage(container_id) {
            $('#' + container_id).remove();
        }

        // Display a lizMap message which will be hidden automatically after a delay in ms
        function addTimedMessage(container_id, message, type, delay, remove_previous) {
            if (remove_previous) {
                closeMessage(container_id);
            }
            lizMap.addMessage(message, type, true).attr('id', container_id);

            // Auto-remove after delay
            setTimeout(function () {
                closeMessage(container_id);
            }, delay);
        }
        // Make this function public to be called outside via OccTax.addTimedMessage
        OccTax.addTimedMessage = function (container_id, message, type, delay, remove_previous) {
            return addTimedMessage(container_id, message, type, delay, remove_previous);
        }

        function getDatatableColumns(tableId) {
            var DT_Columns = $('#' + tableId + ' thead tr th').map(
                function () {
                    var dv = $(this).attr('data-value');
                    var sp = dv.split(',');
                    var ret = {
                        'data': sp[0],
                        'type': sp[1],
                        'sortable': (sp[2] == 'true')
                    }
                    if (sp.length == 4) {
                        ret['className'] = sp[3];
                    }
                    return ret;
                }
            ).get();
            var displayFields = [];
            for (v in DT_Columns) {
                displayFields.push(DT_Columns[v]["data"]);
            }
            return [DT_Columns, displayFields];
        }

        function onQueryFeatureAdded(feature, callback) {

            checkConnection();

            /**
             * Initialisation
             */
            OccTax.emptyDrawqueryLayer('queryLayer'); // needed to be sure that the modify feature tool is ok for the first run
            OccTax.deactivateAllDrawqueryControl();

            var theLayer = feature.layer;
            var activeButton = $('#obs-spatial-query-buttons button.active');
            var activeValue = activeButton.attr('data-value');

            /**
             * @todo Ne gère que si il ya a seulement 1 géométrie
             */
            if (feature.layer) {
                if (feature.layer.features.length > 1) {
                    feature.layer.destroyFeatures(feature.layer.features.shift());
                }
            }

            /**
             * Activation du bouton pour le controle de navigation
             */
            if (activeValue == 'queryPolygon' || activeValue == 'importPolygon')
                $('#obs-spatial-query-modify').show();

            if (feature.geometry.CLASS_NAME === 'OpenLayers.Geometry.Polygon'
                || feature.geometry.CLASS_NAME === 'OpenLayers.Geometry.MultiPolygon'
            ) {
                // L'aire doit être inférieure à une certaine valeur
                // il faut donc la valider
                OccTax.validGeometryFeature(feature);
                theLayer.drawFeature(feature);
                var geom = feature.geometry.clone().transform(OccTax.map.projection, 'EPSG:4326');

                $('#jforms_occtax_search_geom').val(geom.toString());
                $('#jforms_occtax_search_code_commune').val('');
                $('#jforms_occtax_search_code_masse_eau').val('');
                $('#jforms_occtax_search_code_maille').val('');
                $('#jforms_occtax_search_type_maille').val('');
            } else {
                // query geom
                if (feature.geometry.CLASS_NAME === 'OpenLayers.Geometry.Point') {
                    var myPoint = feature.geometry.clone().transform(OccTax.map.projection, 'EPSG:4326');
                    if (activeButton.hasClass('maille')) {
                        var form = $('#form_occtax_service_maille');
                        var type_maille = 'm02';
                        if (activeButton.hasClass('m01')) {
                            type_maille = 'm01';
                        }
                        //if(activeButton.hasClass('m05')){
                        //type_maille = 'm05';
                        //}
                        if (activeButton.hasClass('m10')) {
                            type_maille = 'm10';
                        }
                        $.post(form.attr('action')
                            , { x: myPoint.x, y: myPoint.y, type_maille: type_maille }
                            , function (data) {
                                if (data.status == 1) {
                                    var format = new OpenLayers.Format.GeoJSON();
                                    var geom = format.read(data.result.geojson)[0].geometry;
                                    $('#jforms_occtax_search_geom').val(geom.toString());
                                    $('#jforms_occtax_search_code_commune').val('');
                                    $('#jforms_occtax_search_code_masse_eau').val('');
                                    $('#jforms_occtax_search_code_maille').val(data.result.code_maille);
                                    $('#jforms_occtax_search_type_maille').val(type_maille);
                                    theLayer.destroyFeatures(feature);
                                    geom.transform('EPSG:4326', OccTax.map.projection);
                                    theLayer.addFeatures([new OpenLayers.Feature.Vector(geom)]);
                                    if (callback)
                                        callback();
                                } else {
                                    theLayer.destroyFeatures();
                                    if (data.msg.length != 0)
                                        lizMap.addMessage(data.msg.join('<br/>'), 'error', true).attr('id', 'occtax-highlight-message');
                                    else
                                        lizMap.addMessage('Error', 'error', true).attr('id', 'occtax-highlight-message');
                                }
                            });
                    } else if (activeButton.hasClass('commune')) {
                        var form = $('#form_occtax_service_commune');
                        $.post(form.attr('action')
                            , { x: myPoint.x, y: myPoint.y }
                            , function (data) {
                                if (data.status == 1) {
                                    var format = new OpenLayers.Format.GeoJSON();
                                    var geom = format.read(data.result.geojson)[0].geometry;
                                    $('#jforms_occtax_search_geom').val('');
                                    $('#jforms_occtax_search_code_commune').val(data.result.code_commune);
                                    $('#jforms_occtax_search_code_masse_eau').val('');
                                    $('#jforms_occtax_search_code_maille').val('');
                                    $('#jforms_occtax_search_type_maille').val('');
                                    theLayer.destroyFeatures(feature);
                                    geom.transform('EPSG:4326', OccTax.map.projection);
                                    theLayer.addFeatures([new OpenLayers.Feature.Vector(geom)]);
                                    if (callback)
                                        callback();
                                } else {
                                    theLayer.destroyFeatures();
                                    if (data.msg.length != 0)
                                        lizMap.addMessage(data.msg.join('<br/>'), 'error', true).attr('id', 'occtax-highlight-message');
                                    else
                                        lizMap.addMessage('Error', 'error', true).attr('id', 'occtax-highlight-message');
                                }
                            });
                    } else if (activeButton.hasClass('masse_eau')) {
                        var form = $('#form_occtax_service_masse_eau');
                        $.post(form.attr('action')
                            , { x: myPoint.x, y: myPoint.y }
                            , function (data) {
                                if (data.status == 1) {
                                    var format = new OpenLayers.Format.GeoJSON();
                                    var geom = format.read(data.result.geojson)[0].geometry;
                                    $('#jforms_occtax_search_geom').val('');
                                    $('#jforms_occtax_search_code_commune').val('');
                                    $('#jforms_occtax_search_code_masse_eau').val(data.result.code_me);
                                    $('#jforms_occtax_search_code_maille').val('');
                                    $('#jforms_occtax_search_type_maille').val('');
                                    theLayer.destroyFeatures(feature);
                                    geom.transform('EPSG:4326', OccTax.map.projection);
                                    theLayer.addFeatures([new OpenLayers.Feature.Vector(geom)]);
                                    if (callback)
                                        callback();
                                } else {
                                    theLayer.destroyFeatures();
                                    if (data.msg.length != 0)
                                        lizMap.addMessage(data.msg.join('<br/>'), 'error', true).attr('id', 'occtax-highlight-message');
                                    else
                                        lizMap.addMessage('Error', 'error', true).attr('id', 'occtax-highlight-message');
                                }
                            });
                    }
                }
            }
            // On decheck le bouton de controle enfoncé
            $('#obs-spatial-query-buttons button').removeClass('active');
        }

        function onQueryFeatureModified(evt) {
            var button = $('#obs-spatial-query-modify');
            if (button.hasClass('active')) {
                var geom = evt.feature.geometry.clone().transform(OccTax.map.projection, 'EPSG:4326');
                $('#jforms_occtax_search_geom').val(geom.toString());
                $('#jforms_occtax_search_code_commune').val('');
                $('#jforms_occtax_search_code_masse_eau').val('');
                $('#jforms_occtax_search_code_maille').val('');
                $('#jforms_occtax_search_type_maille').val('');
            }
        }

        function addTaxonToSearch(cd_nom, nom_cite) {
            // todo supprimer commentaires
            // Vider le search_token
            //$('#div_form_occtax_search_token form [name="search_token"]').val('');

            // On vérifie que l'onglet actif est bien celui du panier
            // Important car le submit vérifie l'onglet actif pour supprimer les paramètres de l'autre onglet
            if ($('#recherche_taxon_attributs').hasClass('active')) {
                $('li a[href="#recherche_taxon_panier"]').click();
            }

            // Afficher la liste
            $('#occtax_taxon_select_list').show();

            // Ajout des données au champ caché cd_nom
            var ctrl_cd_nom = $('#div_form_occtax_search_token form [name="cd_nom[]"]');
            var selectVals = ctrl_cd_nom.val();
            if (selectVals == null)
                selectVals = [];

            // Ajout d'un item au panier
            if (selectVals.indexOf(cd_nom) == -1) {
                // Add cd_nom in hidden form input
                ctrl_cd_nom.append('<option selected value="' + cd_nom + '">' + nom_cite + '</option>');

                // Add card in the interface
                var licontent = '<li data-value="';
                licontent += cd_nom;
                licontent += '" style="height:20px; margin-left:2px;">';
                licontent += '<span title="Cliquer pour visualiser la fiche taxon">';
                licontent += nom_cite;
                licontent += '</span>';
                licontent += '<button type="button" class="detail" value="' + cd_nom + '" style="display:none;" >détail</button>';
                licontent += '<button type="button" class="close" value="' + cd_nom + '" aria-hidden="true" title="Supprimer de la sélection">&times;</button>';
                licontent += '</li>';
                var li = $(licontent);

                $('#occtax_taxon_select_list').append(li);
                li.find('.close').click(function () {
                    deleteTaxonToSearch($(this).attr('value'));
                    //return false;
                });
                li.find('span').click(function () {
                    var cd_nom = $(this).parent().find('button.detail').attr('value');
                    displayTaxonDetail(cd_nom);
                    //return false;
                });

            }

        }

        function getTaxonDataFromApi(cd_nom, aCallback) {

            var turl = 'https://taxref.mnhn.fr/api/taxa/';
            turl += cd_nom;

            $.getJSON(turl, null, function (tdata) {
                var keys = ['id', 'referenceId', 'scientificName', 'authority', 'frenchVernacularName'];
                var rdata = {};
                for (var k in keys) {
                    rdata[keys[k]] = tdata[keys[k]];
                }
                if ('_links' in tdata) {
                    rdata['inpnWebpage'] = tdata._links.inpnWebpage.href;
                }
                rdata['media_url'] = null;
                rdata['status_url'] = null;

                // media
                if (
                    '_links' in tdata
                    && 'media' in tdata._links
                ) {
                    var murl = tdata._links.media.href;
                    rdata['media_url'] = murl;
                }
                // status
                if (
                    '_links' in tdata
                    && 'status' in tdata._links
                ) {
                    var surl = tdata._links.status.href;
                    rdata['status_url'] = surl;
                }
                aCallback(rdata);
            });
        }

        function detailTaxonLoad(url) {
            return new Promise(function (resolve, reject) {
                var request = new XMLHttpRequest();
                request.open('GET', url);
                request.responseType = 'json';
                // When the request loads, check whether it was successful
                request.onload = function () {
                    if (request.status === 200) {
                        // If successful, resolve the promise by passing back the request response
                        resolve(request.response);
                    } else {
                        // If it fails, reject the promise with a error message
                        reject(Error('URL did not load successfully; error code:' + request.statusText));
                    }
                };
                request.onerror = function () {
                    reject(Error('There was a network error.'));
                };
                // Send the request
                request.send();
            });
        }

        function buildTaxonFicheHtml(data) {
            var html = '';
            html += '<h3><span class="title"><span class="text">Information</span>';

            // Close button
            html += '<button id="taxon-detail-close" class="btn btn-primary btn-mini pull-right" style="margin-left:10px;">Fermer</button>';

            // Taxon detail URL button
            var detail_url = data.inpnWebpage;
            var config_url = occtaxClientConfig.taxon_detail_source_url;
            if (config_url && config_url.trim() != '') {
                detail_url = config_url.replace('CD_NOM', data.referenceId);
            }
            html += '<a href="';
            html += detail_url;
            html += '" class="btn btn-primary btn-mini pull-right" target="_blank">Voir la fiche complète</a>';
            html += '</span>';
            html += '</h3>';
            html += '<div id="taxon-detail-container" class="menu-content">';
            html += '<h4><b>';
            html += data.scientificName;
            html += '</b> ';
            html += data.authority;
            html += '</h4>';
            var wait_html = '';
            wait_html += '  <div class="dataviz-waiter progress progress-striped active" style="margin:5px 5px;">';
            wait_html += '    <div class="bar" style="width: 100%;"></div>';
            wait_html += '  </div>';
            if (data.frenchVernacularName !== null) {
                html += '<p>';
                html += data.frenchVernacularName;
                html += '</p>';
            }
            // Image
            if (data.media_url !== null) {
                html += '<div id="taxon-detail-media">';
                html += wait_html;
                html += '</div>';
            }
            // Statuts de protection
            if (data.status_url !== null) {
                html += '<div id="taxon-detail-status">';
                html += wait_html;
                html += '</div>';
            }
            html += '</div>';

            return html;
        };

        function getTaxonMedia(media_url) {
            detailTaxonLoad(media_url).then(function (mdata) {
                if (
                    '_embedded' in mdata
                    && 'media' in mdata._embedded
                    && mdata._embedded.media.length > 0
                ) {
                    var media_href = mdata._embedded.media[0]._links.thumbnailFile.href;
                    var html = '';
                    html += '<img src="';
                    html += media_href;
                    html += '" width="100%">';
                    $('#taxon-detail-media div.dataviz-waiter').hide();
                    $('#taxon-detail-media').html(html);
                } else {
                    $('#taxon-detail-media div.dataviz-waiter').hide();
                    $('#sub-dock').css('min-width', '')
                }
            }, function (Error) {
                console.log(Error);
                $('#taxon-detail-media div.dataviz-waiter').hide();
            });
        }

        function getTaxonStatus(status_url) {
            detailTaxonLoad(status_url).then(function (mdata) {
                if (
                    '_embedded' in mdata
                    && 'status' in mdata._embedded
                    && mdata._embedded.status.length > 0
                ) {
                    let colonne_locale_labels = {
                        'gua': ['Guadeloupe'],
                        'fra': ['France métropolitaine', 'France'],
                        'may': ['Mayotte'],
                        'reu': ['Réunion'],
                        'mar': ['Martinique']
                    };
                    statut_localisations = occtaxClientConfig.statut_localisations;
                    var html = '<ul>';
                    for (var s in mdata._embedded.status) {
                        var status = mdata._embedded.status[s];
                        // Do not display if localisation is not in statut_localisations
                        for (var sl in statut_localisations) {
                            var names = colonne_locale_labels[statut_localisations[sl]];
                            if ((names.indexOf(status.locationName) > -1)) {
                                var st_title = ''; var st_cursor = ''
                                if (status.source) {
                                    st_title = ' title="' + status.source + '"';
                                    st_cursor = ' style="cursor:help;"';
                                }
                                html += '<li>';
                                html += '<b>' + status.statusTypeGroup + '</b>: ';
                                html += '<span ' + st_title + st_cursor + '>' + status.statusName + '</span>';
                                html += '<i> (' + status.locationName + ')</i>';
                                html += '</li>';
                                html += '';
                            }
                        }
                    }
                    html += '</ul>';
                    $('#taxon-detail-status div.dataviz-waiter').hide();
                    $('#taxon-detail-status').html(html);

                } else {
                    $('#taxon-detail-status div.dataviz-waiter').hide();
                }
            }, function (Error) {
                console.log(Error);
                $('#taxon-detail-status div.dataviz-waiter').hide();
            });
        }

        /**
         * PRIVATE function: getDockRightPosition
         * Calculate the position on the right side of the dock
         */
        function getDockRightPosition() {
            var right = $('#mapmenu').width();
            if ($('#content').hasClass('embed'))
                right += 11;
            else if ($('#dock').css('display') != 'none' && !lizMap.checkMobile())
                right += $('#dock').width() + 11;
            return right;
        }


        function displayTaxonDetail(cd_nom) {
            // Depending on the source, we must
            // API: "api" -> get data from MNHN API and display in subdock
            // URL: "https://some_url/cd_nom" -> open in a new tab after having replace cd_nom
            var dtype = occtaxClientConfig.taxon_detail_source_type;
            var durl = occtaxClientConfig.taxon_detail_source_url;
            if (dtype == 'api' || durl.trim() == '') {
                // Use the MNHN API to create and display a fact sheet about this taxon
                getTaxonDataFromApi(cd_nom, function (data) {
                    var html = buildTaxonFicheHtml(data);
                    html += '<button id="hide-sub-dock" class="btn pull-right" style="margin-top:5px;" name="close" title="' + lizDict['generic.btn.close.title'] + '">' + lizDict['generic.btn.close.title'] + '</button>';

                    // Depending on LWC version, sub-dock uses flex or not
                    $('#sub-dock').html(html);
                    if ($('#docks-wrapper').length) {
                        // LWC >= 3.4.0
                        $('#sub-dock')
                            .css('bottom', '0px')
                            .css('position', 'relative')
                            .css('height', '100%')
                            .css('min-width', '30%')
                            ;
                    } else {
                        // Older versions
                        $('#sub-dock').css('bottom', '0px');
                        if (!lizMap.checkMobile()) {
                            var leftPos = getDockRightPosition();
                            $('#sub-dock').css('left', leftPos).css('width', leftPos);
                        }
                    }

                    // Hide lizmap close button (replaced further)
                    $('#hide-sub-dock').click(function () {
                        $('#sub-dock').hide().html('');
                    });

                    // Load status
                    if (data.status_url) {
                        getTaxonStatus(data.status_url);
                    } else {
                        $('#taxon-detail-status div.dataviz-waiter').hide();
                    }

                    // Load media
                    if (data.media_url) {
                        getTaxonMedia(data.media_url);
                    } else {
                        $('#taxon-detail-media div.dataviz-waiter').hide();
                    }

                    // close windows
                    $('#taxon-detail-close').click(function () { $('#hide-sub-dock').click(); })

                    $('#sub-dock').show();

                })
            } else {
                // Directly open external URL in a new tab/window
                var url = durl.replace('CD_NOM', cd_nom);
                window.open(url, '_blank');
            }
        }

        function deleteTaxonToSearch(cd_nom) {
            $('#div_form_occtax_search_token form [name="cd_nom[]"] option[value="' + cd_nom + '"]').remove();
            var li = $('#occtax_taxon_select_list li[data-value="' + cd_nom + '"]');
            li.find('.close').unbind('click');
            li.remove();
            if ($('#occtax_taxon_select_list li').length == 0) {
                $('#occtax_taxon_select_list').hide();
            }
        }

        function clearTaxonFromSearch(removePanier, removeFilters) {
            var formId = 'jforms_occtax_search';
            // Panier de taxons
            if (removePanier) {
                // Remove content from taxon panier
                $('#div_form_occtax_search_token form [name="cd_nom[]"]').html('');
                // Remove content from taxon panier
                $('#occtax_taxon_select_list .close').unbind('click');
                $('#occtax_taxon_select_list').html('');
                $('#' + formId + ' input[name="autocomplete"]').val('');
            }
            // Critères de recherche
            if (removeFilters) {
                // Remove data from taxon inputs
                $('#' + formId + '_filter select option').prop('selected', function () {
                    return this.defaultSelected;
                });
                // sumoselect specific of taxon filter tab
                $('#' + formId + '_filter select.jforms-ctrl-listbox').each(function () {
                    if ($(this).attr('id') != 'jforms_occtax_search_cd_nom') {
                        $(this)[0].sumo.unSelectAll();
                    }
                });
            }

        }

        function addResultsStatsTable() {
            var tableId = 'occtax_results_stats_table';
            // Get statistics
            var returnFields = $('#' + tableId + '').attr('data-value').split(',');
            var DT_RowId = $('#' + tableId + ' thead tr').attr('data-value');
            var datatableColumns = getDatatableColumns(tableId);
            var DT_Columns = datatableColumns[0];
            var displayFields = datatableColumns[1];
            $('#' + tableId + '').DataTable({
                "lengthChange": false,
                "searching": false,
                "dom": 'ipt',
                //"pageLength":50,
                "paging": false,
                "deferRender": true,
                "scrollY": '100%',
                "scrollX": '95%',
                "language": { url: jFormsJQ.config.basePath + lizUrls["dataTableLanguage"] },
                "oLanguage": {
                    "sInfoEmpty": "",
                    "sEmptyTable": "Aucun résultat",
                    "sInfo": "Affichage des groupes _START_ à _END_ sur _TOTAL_ groupes taxonomiques",
                    "oPaginate": {
                        "sPrevious": "Précédent",
                        "sNext": "Suivant"
                    }
                },
                "columns": DT_Columns,
                "ajax": function (param, callback, settings) {
                    // Check user is still connected if he was
                    var ok = checkConnection();
                    if (!ok) {
                        return false;
                    }
                    var searchForm = $('#occtax_service_search_stats_form');

                    // Do not run the query if no token has been found
                    var mytoken = searchForm.find('input[name="token"]').val();
                    if (!mytoken)
                        return false;
                    $.post(searchForm.attr('action'), searchForm.serialize(),
                        function (results) {
                            var tData = {
                                "recordsTotal": 0,
                                "recordsFiltered": 0,
                                "data": []
                            };
                            if (results.status = 1) {
                                tData.recordsTotal = results.recordsTotal;
                                tData.recordsFiltered = results.recordsFiltered;

                                for (var i = 0, len = results.data.length; i < len; i++) {

                                    // Add data to table
                                    var r = {};
                                    var d = results.data[i];
                                    r['DT_RowId'] = d[returnFields.indexOf(DT_RowId)];
                                    for (var j = 0, jlen = displayFields.length; j < jlen; j++) {
                                        var f = displayFields[j];
                                        r[f] = d[returnFields.indexOf(f)];
                                    }
                                    tData.data.push(r);
                                }

                            } else {
                                if (results.msg.length != 0)
                                    lizMap.addMessage(results.msg.join('<br/>'), 'error', true).attr('id', 'occtax-highlight-message');
                                else
                                    lizMap.addMessage('Error', 'error', true).attr('id', 'occtax-highlight-message');
                            }
                            refreshOcctaxDatatableSize('#occtax_results_stats_table_div');
                            callback(tData);
                            $('#' + tableId + '').show();

                        }, 'json'
                    );
                }
            });
        }

        function addResultsTaxonTable() {
            var tableId = 'occtax_results_taxon_table';
            // Get taxon fields to display
            var returnFields = $('#' + tableId + '').attr('data-value').split(',');
            var DT_RowId = $('#' + tableId + ' thead tr').attr('data-value');
            var datatableColumns = getDatatableColumns(tableId);
            var DT_Columns = datatableColumns[0];
            var displayFields = datatableColumns[1];
            $('#' + tableId + '').DataTable({
                "lengthChange": false,
                "pageLength": 100,
                "paging": true,
                "deferRender": true,
                "scrollY": '100%',
                "scrollX": '95%',
                //"searching": true,
                "searching": false,
                "dom": 'ipft',
                "language": { url: jFormsJQ.config.basePath + lizUrls["dataTableLanguage"] },
                "oLanguage": {
                    "sInfoEmpty": "",
                    "sEmptyTable": "Aucun résultat",
                    "sInfo": "Affichage des taxons _START_ à _END_ sur _TOTAL_ taxons",
                    "oPaginate": {
                        "sPrevious": "Précédent",
                        "sNext": "Suivant"
                    }
                },
                "processing": true,
                "serverSide": true,
                "columns": DT_Columns,
                "ajax": function (param, callback, settings) {
                    // Check user is still connected if he was
                    var ok = checkConnection();
                    if (!ok) {
                        return false;
                    }
                    var searchForm = $('#occtax_service_search_taxon_form');
                    searchForm.find('input[name="limit"]').val(param.length);
                    searchForm.find('input[name="offset"]').val(param.start);
                    searchForm.find('input[name="group"]').val('');
                    //searchForm.find('input[name="search"]').val(param.search.value);
                    searchForm.find('input[name="order"]').val(
                        DT_Columns[param.order[0]['column']]['data'] + ':' + param.order[0]['dir']
                    );

                    // Do not run the query if no token has been found
                    var mytoken = searchForm.find('input[name="token"]').val();
                    if (!mytoken)
                        return false;
                    $.post(searchForm.attr('action'), searchForm.serialize(),
                        function (results) {
                            var tData = {
                                "recordsTotal": 0,
                                "recordsFiltered": 0,
                                "data": []
                            };
                            if (results.status = 1) {
                                tData.recordsTotal = results.recordsTotal;
                                tData.recordsFiltered = results.recordsFiltered;

                                for (var i = 0, len = results.data.length; i < len; i++) {

                                    // Add data to table
                                    var r = {};
                                    var d = results.data[i];
                                    r['DT_RowId'] = d[returnFields.indexOf(DT_RowId)];
                                    for (var j = 0, jlen = displayFields.length; j < jlen; j++) {
                                        var f = displayFields[j];
                                        r[f] = d[returnFields.indexOf(f)];
                                    }
                                    tData.data.push(r);
                                }

                                // Set number of taxons in description
                                var dhtml = $('#occtax_search_description_content').html();
                                $('#occtax_search_description_content').html(
                                    dhtml.replace(
                                        '<span style="display:none">nb_taxon',
                                        '<span> / ' + results.recordsTotal.toLocaleString()
                                    )
                                );

                            } else {
                                if (results.msg.length != 0)
                                    lizMap.addMessage(results.msg.join('<br/>'), 'error', true).attr('id', 'occtax-highlight-message');
                                else
                                    lizMap.addMessage('Error', 'error', true).attr('id', 'occtax-highlight-message');
                            }
                            refreshOcctaxDatatableSize('#occtax_results_taxon_table_div');

                            callback(tData);
                            $('#' + tableId + '').show();
                        }
                        , 'json');
                }
            });
            $('#' + tableId + '').on('page.dt', function () {
                $('#' + tableId + ' a').unbind('click');
            });
            $('#' + tableId + '').on('draw.dt', function () {
                $('#' + tableId + ' a.filterByTaxon').click(function () {
                    var tr = $($(this).parents('tr')[0]);
                    var d = $('#' + tableId + '').DataTable().row(tr).data();
                    var cd_nom = tr.attr('id');
                    var row_label = $('#' + tableId + ' thead tr th.row-label').attr('data-value');
                    row_label = row_label.split(',')[0];

                    // Remove previous taxon searches
                    var removePanier = true;
                    var removeFilters = true;
                    clearTaxonFromSearch(removePanier, removeFilters);

                    // Add new taxon to search
                    addTaxonToSearch(cd_nom, d[row_label]);
                    $('#div_form_occtax_search_token form').submit();
                    return false;
                });
                $('#' + tableId + ' a.getTaxonDetail').click(function () {
                    var tr = $($(this).parents('tr')[0]);
                    var d = $('#' + tableId + '').DataTable().row(tr).data();
                    var cd_nom = tr.attr('id');
                    displayTaxonDetail(cd_nom);
                    return false;
                });
                // Replace taxon nomenclature key by values
                $('#' + tableId + ' span.redlist_regionale').each(function () {
                    replaceKeyByLabelFromNomenclature($(this), 'menace_regionale');
                });
                $('#' + tableId + ' span.redlist_nationale').each(function () {
                    replaceKeyByLabelFromNomenclature($(this), 'menace_nationale');
                });
                $('#' + tableId + ' span.redlist_monde').each(function () {
                    replaceKeyByLabelFromNomenclature($(this), 'menace_monde');
                });
                $('#' + tableId + ' span.protectionlist').each(function () {
                    replaceKeyByLabelFromNomenclature($(this), 'protection');
                });
            });
        }

        function replaceKeyByLabelFromNomenclature(span, target_field) {
            for (var key in t_nomenclature) {
                var label = t_nomenclature[key];
                var champ = key.split('|')[0];
                if (champ != target_field) {
                    continue;
                }
                var val = key.split('|')[1];
                if ($(this).hasClass(val)) {
                    continue;
                }
                var title = span.attr('title');
                span.attr('title', title.replace(val, label));
            }
        }

        function addResultsMailleTable(type_maille) {
            var tableId = 'occtax_results_maille_table_' + type_maille;
            if ($('#' + tableId + '').length == 0) {
                return false;
            }
            // Get maille fields to display
            var returnFields = $('#' + tableId + '').attr('data-value').split(',');
            var DT_RowId = $('#' + tableId + ' thead tr').attr('data-value');
            var datatableColumns = getDatatableColumns(tableId);
            var DT_Columns = datatableColumns[0];
            var displayFields = datatableColumns[1];
            $('#' + tableId + '').DataTable({
                "lengthChange": false,
                "searching": false,
                "dom": 'ipft',
                //"pageLength":50,
                "paging": false,
                "deferRender": true,
                "scrollY": '100%',
                "scrollX": '95%',
                "language": { url: jFormsJQ.config.basePath + lizUrls["dataTableLanguage"] },
                "oLanguage": {
                    "sInfoEmpty": "",
                    "sEmptyTable": "Aucun résultat",
                    "sInfo": "Affichage des mailles _START_ à _END_ sur _TOTAL_ mailles",
                    "oPaginate": {
                        "sPrevious": "Précédent",
                        "sNext": "Suivant"
                    }
                },
                "columns": DT_Columns,
                "ajax": function (param, callback, settings) {
                    // Check user is still connected if he was
                    var ok = checkConnection();
                    if (!ok) {
                        return false;
                    }
                    var searchForm = $('#occtax_service_search_maille_form_' + type_maille);
                    // Do not run the query if no token has been found
                    var mytoken = searchForm.find('input[name="token"]').val();
                    if (!mytoken)
                        return false;
                    $.post(searchForm.attr('action'), searchForm.serialize(),
                        function (results) {
                            var tData = {
                                "recordsTotal": 0,
                                "recordsFiltered": 0,
                                "data": []
                            };
                            if (results.status = 1) {
                                tData.recordsTotal = results.recordsTotal;
                                tData.recordsFiltered = results.recordsFiltered;

                                // Trigger event that a new result has come
                                OccTax.events.triggerEvent('mailledatareceived_' + type_maille, { 'results': results });
                                for (var i = 0, len = results.data.length; i < len; i++) {

                                    // Add data to table
                                    var r = {};
                                    var d = results.data[i];
                                    r['DT_RowId'] = d[returnFields.indexOf(DT_RowId)];
                                    for (var j = 0, jlen = displayFields.length; j < jlen; j++) {
                                        var f = displayFields[j];
                                        r[f] = d[returnFields.indexOf(f)];
                                    }
                                    tData.data.push(r);
                                }
                            } else {
                                if (results.msg.length != 0)
                                    lizMap.addMessage(results.msg.join('<br/>'), 'error', true).attr('id', 'occtax-highlight-message');
                                else
                                    lizMap.addMessage('Error', 'error', true).attr('id', 'occtax-highlight-message');
                            }
                            $('#' + tableId + ' a').unbind('click');
                            callback(tData);
                            refreshOcctaxDatatableSize('#occtax_results_maille_table_div_' + type_maille);

                            // Refresh maille on map
                            // usefull to refresh map features
                            var mclick = false;
                            if ($('#occtax_results_draw_maille_m01.btn').length
                                && $('#occtax_results_draw_maille_m01.btn').hasClass('active')
                            ) {
                                $('#occtax_results_draw_maille_m01.btn').click();
                                mclick = true;
                            }
                            if (!mclick && $('#occtax_results_draw_maille_m02.btn').length
                                && $('#occtax_results_draw_maille_m02.btn').hasClass('active')
                            ) {
                                $('#occtax_results_draw_maille_m02.btn').click();
                                mclick = true;
                            }
                            if (!mclick && $('#occtax_results_draw_maille_m10.btn').length
                                && $('#occtax_results_draw_maille_m10.btn').hasClass('active')
                            ) {
                                $('#occtax_results_draw_maille_m10.btn').click();
                                mclick = true;
                            }

                            $('#' + tableId + '').show();


                        }, 'json'
                    );
                }
            });
        }

        function getObservationMapFeatures(acallback) {
            $('#occtax-highlight-message').remove();
            var msg = 'Recherche en cours...';
            lizMap.addMessage(msg, 'info', true).attr('id', 'occtax-highlight-message');

            // Do not run the query if no token has been found
            var searchForm = $('#occtax_service_search_form');
            var mytoken = searchForm.find('input[name="token"]').val();
            if (!mytoken) {
                $('#occtax-highlight-message').remove();
                return false;
            }
            // Set form values
            searchForm.find('input[name="offset"]').val(0);
            searchForm.find('input[name="group"]').val('');
            searchForm.find('input[name="order"]').val('');

            // Do not run if the user is not connected anymore
            // Todo: remove when precise data will be available for unlogged users
            var ok = checkConnection();
            if (!ok) {
                $('#occtax-highlight-message').remove();
                return false;
            }

            // Check if extent has changed
            var previous_extent = observation_geometries_extent;
            var extent = lizMap.map.getExtent().transform(OccTax.map.projection, 'EPSG:4326');
            observation_geometries_extent = extent;
            var bbox = extent.toBBOX();
            searchForm.find('input[name="extent"]').val(bbox);
            searchForm.find('input[name="map"]').val('on');

            // Token
            var previous_token = previous_search_token;
            previous_search_token = mytoken;

            // Do not re-run the query if extent has not changed
            // and geometries where already displayed
            if (previous_extent && previous_search_token && previous_extent.toBBOX() == extent.toBBOX() && previous_token == previous_search_token) {
                OccTax.refreshFeatures('observation');
                $('#occtax-highlight-message').remove();
                return true;
            }

            // Get data and pass it to layer through event
            var maximum_geometries = 15000;
            // First get row count and then get data only if rowcount < some value
            searchForm.find('input[name="rowcount"]').val('1');
            $.post(
                searchForm.attr('action'),
                searchForm.serialize(),
                function (count_results) {
                    var recordsTotal = parseInt(count_results.recordsTotal);
                    if (recordsTotal <= maximum_geometries) {
                        // Get the real data with geometries
                        searchForm.find('input[name="rowcount"]').val('0');
                        searchForm.find('input[name="limit"]').val(maximum_geometries);
                        $.post(
                            searchForm.attr('action'),
                            searchForm.serialize(),
                            function (results) {
                                // Remove previous features
                                var observation_layer = OccTax.layers['observationLayer'];
                                observation_layer.destroyFeatures();

                                // Event to set the features for observation
                                OccTax.events.triggerEvent('observationdatareceived', { 'results': results });
                                // Refresh map
                                OccTax.refreshFeatures('observation');
                                $('#occtax-highlight-message').remove();
                                var msg = recordsTotal.toLocaleString() + ' observations visibles sur cette emprise';
                                lizMap.addMessage(msg, 'info', true).attr('id', 'occtax-highlight-message');
                            }
                        );
                    } else {
                        var msg = naturalizLocales['map.message.too.many.geometries'];
                        msg = msg.replace('recordsTotal', recordsTotal.toLocaleString());
                        msg = msg.replace('maximum_geometries', maximum_geometries.toLocaleString());
                        $('#occtax-highlight-message').remove();
                        lizMap.addMessage(msg, 'info', true).attr('id', 'occtax-highlight-message');
                    }
                }
            );
        }

        function getObservationMapFeatureByFid(fid) {

            // Test if we can get single observation
            var layer = OccTax.layers['observationLayer'];
            var geom_id = null;
            var geom_feat = null;
            // Loop through features to find the correct feature
            for (var i = 0; i < layer.features.length; i++) {
                var feat = layer.features[i];
                if (feat.cluster) {
                    for (var f = 0; f < feat.cluster.length; f++) {
                        var cfeat = feat.cluster[f]
                        if (cfeat.fid == fid) {
                            geom_id = feat.fid;
                            geom_feat = feat;
                            break;
                        }
                    }
                } else {
                    if (feat.fid == fid) {
                        geom_id = feat.fid
                        geom_feat = feat;
                        break;
                    }
                }
            }

            return geom_feat;
        }

        function addResultsObservationTable() {
            var tableId = 'occtax_results_observation_table';
            // Get fields to display
            var table = $('#' + tableId + '');
            if (table.length == 0)
                return;
            var returnFields = table.attr('data-value').split(',');
            var DT_RowId = $('#' + tableId + ' thead tr').attr('data-value');
            var datatableColumns = getDatatableColumns(tableId);
            var DT_Columns = datatableColumns[0];
            var displayFields = datatableColumns[1];
            // Display data via datatable
            $('#' + tableId + '').DataTable({
                "lengthChange": false,
                "pageLength": 100,
                "paging": true,
                "deferRender": true,
                "scrollY": '100%',
                "scrollX": '95%',
                "searching": false,
                "dom": 'ipt',
                "language": { url: jFormsJQ.config.basePath + lizUrls["dataTableLanguage"] },
                "oLanguage": {
                    "sInfoEmpty": "",
                    "sEmptyTable": "Aucun résultat",
                    "sInfo": "Affichage des observations _START_ à _END_ sur _TOTAL_ observations",
                    "oPaginate": {
                        "sPrevious": "Précédent",
                        "sNext": "Suivant"
                    }
                },
                "processing": true,
                "serverSide": true,
                "columns": DT_Columns,
                "ajax": function (param, callback, settings) {
                    // Check user is still connected if he was
                    var ok = checkConnection();
                    if (!ok) {
                        return false;
                    }
                    var searchForm = $('#occtax_service_search_form');
                    searchForm.find('input[name="limit"]').val(param.length);
                    searchForm.find('input[name="offset"]').val(param.start);
                    searchForm.find('input[name="group"]').val('');
                    searchForm.find('input[name="extent"]').val('');
                    searchForm.find('input[name="map"]').val('');
                    searchForm.find('input[name="rowcount"]').val('');
                    searchForm.find('input[name="order"]').val(
                        DT_Columns[param.order[0]['column']]['data'] + ':' + param.order[0]['dir']
                    );

                    // Do not run the query if no token has been found
                    var mytoken = searchForm.find('input[name="token"]').val();
                    if (!mytoken)
                        return false;
                    $.post(searchForm.attr('action'), searchForm.serialize(),
                        function (results) {
                            var tData = {
                                "recordsTotal": 0,
                                "recordsFiltered": 0,
                                "data": []
                            };
                            if (results.status = 1) {
                                tData.recordsTotal = results.recordsTotal;
                                tData.recordsFiltered = results.recordsFiltered;

                                for (var i = 0, len = results.data.length; i < len; i++) {

                                    // Add data to table
                                    var r = {};
                                    var d = results.data[i];
                                    r['DT_RowId'] = d[returnFields.indexOf(DT_RowId)];
                                    for (var j = 0, jlen = displayFields.length; j < jlen; j++) {
                                        var f = displayFields[j];
                                        r[f] = d[returnFields.indexOf(f)];
                                    }
                                    r['geojson'] = d[returnFields.indexOf('geojson')];
                                    tData.data.push(r);
                                }
                            } else {
                                if (results.msg.length != 0)
                                    lizMap.addMessage(results.msg.join('<br/>'), 'error', true).attr('id', 'occtax-highlight-message');
                                else
                                    lizMap.addMessage('Error', 'error', true).attr('id', 'occtax-highlight-message');
                            }
                            refreshOcctaxDatatableSize('#occtax_results_observation_table_div');

                            callback(tData);

                            $('#' + tableId + '').show();
                        }, 'json'
                    );
                }
            });
            $('#' + tableId + '').on('page.dt', function () {
                $('#' + tableId + ' tbody tr').unbind('hover');
                $('#' + tableId + ' a').unbind('click');
            });
            $('#' + tableId + '').on('draw.dt', function () {
                // Display observation geometry
                var delay = 300, setTimeoutConst;
                $('#' + tableId + ' tbody tr').hover(function () {
                    var tr = $(this);
                    setTimeoutConst = setTimeout(function () {
                        var d = $('#' + tableId + '').DataTable().row(tr).data();
                        if (d) {
                            displayObservationGeom(d['geojson'], true);
                        }
                    }, delay);
                }, function () {
                    var tr = $(this);
                    var obsId = tr.attr('id');
                    clearTimeout(setTimeoutConst);
                });

                // Open observation detail
                $('#' + tableId + ' a.openObservation').click(function () {
                    var tr = $($(this).parents('tr')[0]);
                    var d = $('#' + tableId + '').DataTable().row(tr).data();
                    if (d) {
                        var cle_obs = d['DT_RowId'];
                        var with_nav_buttons = true;
                        getObservationDetail(cle_obs, with_nav_buttons);
                    }
                    return false;
                });

                // Zoom to observation
                $('#' + tableId + ' a.zoomToObservation').click(function () {
                    var tr = $($(this).parents('tr')[0]);
                    var d = $('#' + tableId + '').DataTable().row(tr).data();
                    if (d) {
                        zoomToObservation(d['geojson']);
                    }
                    return false;
                });

                // Add observateur tooltip
                $('#' + tableId + ' span.identite_observateur').tooltip();
                // Get taxon detail
                $('#' + tableId + ' a.getTaxonDetail').click(function () {
                    var tr = $($(this).parents('tr')[0]);
                    var d = $('#' + tableId + '').DataTable().row(tr).data();
                    if (d) {
                        var classes = $(d.lien_nom_valide).attr('class');
                        var cd_nom = classes.split(' ')[1].replace('cd_nom_', '');
                        displayTaxonDetail(cd_nom);
                        $('#occtax-highlight-message').remove();
                    }
                    return false;
                });

                // Get validity detail
                $('#' + tableId + ' span.niv_val').click(function () {
                    var tr = $($(this).parents('tr')[0]);
                    var t = $('#' + tableId + '').DataTable();
                    var r = t.row(tr);
                    var d = r.data();
                    $('span.niv_val.active').removeClass('active');
                    $(this).addClass('active');
                    if (d) {
                        var cle_obs = d['DT_RowId'];
                        showObservationValidation(cle_obs);
                    }
                    return false;
                });

                // Replace taxon nomenclature key by values
                $('#' + tableId + ' span.redlist_regionale').each(function () {
                    replaceKeyByLabelFromNomenclature($(this), 'menace_regionale');
                });
                $('#' + tableId + ' span.redlist_nationale').each(function () {
                    replaceKeyByLabelFromNomenclature($(this), 'menace_nationale');
                });
                $('#' + tableId + ' span.redlist_monde').each(function () {
                    replaceKeyByLabelFromNomenclature($(this), 'menace_monde');
                });
                $('#' + tableId + ' span.protectionlist').each(function () {
                    replaceKeyByLabelFromNomenclature($(this), 'protection');
                });

            });
        }


        function initTaxonAutocomplete() {
            var formId = $('#div_form_occtax_search_token form').attr('id');
            $('#' + formId + '_autocomplete').autocomplete({
                minLength: 2,
                autoFocus: true,
                source: function (request, response) {
                    request.limit = $('#form_taxon_service_autocomplete input[name="limit"]').val();
                    request.taxons_locaux = $('#jforms_occtax_search_taxons_locaux').prop("checked");
                    request.taxons_bdd = $('#jforms_occtax_search_taxons_bdd').prop("checked");
                    $.post($('#form_taxon_service_autocomplete').attr('action'),
                        request, function (data, status, xhr) {
                            //rearange data if necessary
                            response(data);
                        }, 'json'
                    );
                },
                open: function (e, ui) {
                },
                focus: function (e, ui) {
                    return false;
                },
                close: function (e, ui) {
                },
                change: function (e, ui) {
                    if ($(this).val().length < $(this).autocomplete('option', 'minLength'))
                        $('#' + formId + '_cd_ref').val('');
                },
                search: function (e, ui) {
                    $('#' + formId + '_cd_ref').val('');
                },
                select: function (e, ui) {

                    // Ajout du cd_ref dans le champ masqué
                    $('#' + formId + '_cd_ref').val(ui.item.cd_ref);

                    // Hide search comboboxes
                    if ($('#' + formId + '_filter > div').is(':visible')) {
                        $('#' + formId + '_filter > legend > button').click();
                    }

                    // Mise en forme du résultat
                    var label = ui.item.nom_valide;

                    // Suppression du contenu et perte du focus
                    $(this).val('').blur();

                    // Ajout du taxon au panier
                    addTaxonToSearch(ui.item.cd_ref, label);

                    return false;
                }
            }).autocomplete("widget").css("z-index", "1050");

            // Add image to the proposed items
            $('#' + formId + '_autocomplete').autocomplete("instance")._renderItem = function (ul, item) {
                return $("<li>")
                    .append($("<a>").html($("<a>").html('<img src="' + jFormsJQ.config.basePath + 'taxon/css/images/groupes/' + item.groupe + '.png" width="15" height="15"/>&nbsp;' + item.label)))
                    .appendTo(ul);
            };

        }


        // Display the precise observation geometry on the map
        function displayObservationGeom(geojson, empty_layer) {
            var ok = checkConnection();
            if (!ok) {
                return;
            }

            // Transform geojson to OL geometry
            var format = new OpenLayers.Format.GeoJSON();
            var geom = format.read(geojson)[0].geometry;

            geom.transform('EPSG:4326', OccTax.map.projection);
            var temp_layer = OccTax.layers['observationTempLayer'];
            var feat = new OpenLayers.Feature.Vector(geom);
            if (empty_layer) {
                temp_layer.destroyFeatures();
            }
            temp_layer.addFeatures([feat]);
            temp_layer.setVisibility(true);
        }

        function zoomToObservation(geojson) {
            if (!geojson)
                return;

            // current values
            var current_zoom = lizMap.map.getZoom();
            var current_center = lizMap.map.getExtent().getCenterLonLat();

            // Transform geojson to OL geometry
            var format = new OpenLayers.Format.GeoJSON();
            var geom = format.read(geojson)[0].geometry;
            geom.transform('EPSG:4326', OccTax.map.projection);

            // Get extent
            var target_extent = geom.getBounds();
            var target_zoom = lizMap.map.getZoomForExtent(target_extent);
            var target_resolution = lizMap.map.getResolutionForZoom(target_zoom);
            var target_scale = OpenLayers.Util.getScaleFromResolution(target_resolution, lizMap.map.getUnits())

            var max_scale = occtaxClientConfig.maximum_observation_scale;
            var current_scale = lizMap.map.getScale();
            if (current_scale >= max_scale && target_scale < max_scale) {
                target_scale = max_scale;
            }
            if (current_scale < max_scale && target_scale < current_scale) {
                target_scale = current_scale;
            }

            // NB: lizMap.map.zoomToScale( target_scale ) does not work -> we use zoom calculated from scale or resolution
            var zoom = null;
            if (lizMap.map.scales) {
                zoom = lizMap.map.scales.indexOf(target_scale);
            }
            if (lizMap.map.resolutions) {
                var target_resolution_final = OpenLayers.Util.getResolutionFromScale(target_scale, lizMap.map.getUnits());
                zoom = lizMap.map.resolutions.indexOf(target_resolution_final);
            }
            if (zoom && zoom != current_zoom) {
                lizMap.map.zoomTo(zoom);
            }
            var targetCenter = target_extent.getCenterLonLat();
            if (targetCenter != current_center) {
                lizMap.map.setCenter(targetCenter);
            }

        }


        function getObservationDetail(id, with_nav_buttons) {
            // Check user is still connected if he was
            var ok = checkConnection();
            if (!ok) {
                return;
            }
            if (!id)
                return;

            // Get observation data
            var tokenFormId = $('#div_form_occtax_search_token form').attr('id');
            var obsUrl = $('#' + tokenFormId).attr('action').replace('initSearch', 'getObservation');
            obsUrl = obsUrl.replace('service', 'observation');
            $('occtax_search_observation_card').addClass('not_enabled');
            $.get(
                obsUrl,
                { 'id': id },
                function (data) {
                    $('#mapmenu li.occtax:not(.active) a').click();
                    $('occtax_search_observation_card').removeClass('not_enabled');

                    // Show observation car h3 and div
                    $('#occtax_search_observation_card').prev('h3.occtax_search:first').show();
                    $('#occtax_search_observation_card').html(data).show();

                    // Hide description && result div
                    $('#occtax_search_input').hide();
                    $('#occtax_search_result').hide();
                    $('#occtax_search_description').hide();

                    // Taxon detail URL - Add event on click
                    $('#occtax_search_observation_card a.getTaxonDetail').click(function () {
                        var classes = $(this).attr('class');
                        var cd_nom = classes.split(' ')[1].replace('cd_nom_', '');
                        displayTaxonDetail(cd_nom);
                        return false;
                    });

                    if (!with_nav_buttons) {
                        $('#occtax_search_observation_card div.dock-content:first').hide();
                    } else {
                        // Add number of lines in the table and current position
                        var tableId = 'occtax_results_observation_table';
                        var current_line = $('#' + tableId).find('tr#' + id).index() + 1;
                        var total_count = $('#' + tableId + ' tr').length - 1;
                        $('#occtax_fiche_position').text(current_line + ' / ' + total_count);
                        if (current_line == 1) {
                            $('#occtax_fiche_before').addClass('disabled');
                        }
                        if (current_line == 100) {
                            $('#occtax_fiche_next').addClass('disabled');
                        }

                        // Next and previous observation button
                        $('#occtax_fiche_next, #occtax_fiche_before').click(function () {
                            // Remove previous subdock detail
                            $('#sub-dock').hide().html('');

                            // Get action based on clicked button
                            var action = 'next';
                            if ($(this).attr('id') == 'occtax_fiche_before') {
                                action = 'before';
                            }
                            // find brother
                            var tableId = 'occtax_results_observation_table';
                            var current_tr = $('#' + tableId).find('tr#' + id);

                            if (action == 'next') {
                                var brother_id = current_tr.next('tr').attr('id');
                                var m = 'à la fin';
                            } else {
                                var brother_id = current_tr.prev('tr').attr('id');
                                var m = 'au début';
                            }
                            if (!brother_id) {
                                $('#occtax-highlight-message').remove();
                                lizMap.addMessage("Vous êtes arrivés " + m + " du tableau d'observations", 'info', true).attr('id', 'occtax-highlight-message');
                                return false;
                            }

                            // Unhighligth current obs
                            OccTax.layers['observationTempLayer'].destroyFeatures();

                            // Go to the next observation
                            getObservationDetail(brother_id, with_nav_buttons);
                            return false;

                        });
                    }

                    // Activate button to zoom to observation
                    $('#occtax_fiche_zoom').click(function () {
                        var geojson = $(this).next('span').html();
                        zoomToObservation(geojson);
                    });

                    // Highlight obs
                    var geojson = $('#occtax_fiche_zoom').next('span').html();
                    displayObservationGeom(geojson, true);

                    // Zoom automatically
                    if (with_nav_buttons) {
                        zoomToObservation(geojson);
                    }

                    // Get validity detail
                    $('#occtax_search_observation_card span.niv_val').click(function () {
                        showObservationValidation(id);
                        return false;
                    });

                    // Show result
                    $('#mapmenu li.occtax:not(.active) a').click();
                }
            );
        }


        function showObservationValidation(cle_obs) {
            // Check user is still connected if he was
            var ok = checkConnection();
            if (!ok) {
                return false;
            }
            if (!cle_obs) {
                return false;
            }

            // Get observation data
            var tokenFormId = $('#occtax-validation-form-modal form').attr('id');
            var has_validation_right = true;
            var url = $('#' + tokenFormId).attr('action');
            if (!url) {
                has_validation_right = false;
                url = naturalizValidationProperties['url'];
            }

            var params = {
                'id': cle_obs,
                'validation_action': 'observation_validity'
            };

            $.post(
                url,
                params,
                function (content) {
                    if (!content) {
                        $('span.niv_val.active').removeClass('active');
                        return false;
                    }
                    if (content.status != 'success') {
                        $('span.niv_val.active').removeClass('active');
                        OccTax.addTimedMessage('occtax-message', content.message, 'error', 3000, true);
                        return false;
                    }
                    var data = content.data;
                    if (!data || !data.length) {
                        return false;
                    }
                    var oval = data[0];

                    // Add the active class to the button corresponding to the obs
                    // Could be needed
                    $('#occtax_results_observation_table tr#' + oval['cle_obs'] + ' span.niv_val').addClass('active');

                    // Compute display values
                    var typ_val = oval['typ_val'] ? oval['typ_val'] : '-';
                    var date_ctrl = oval['date_ctrl'] ? oval['date_ctrl'] : '-';
                    var niv_val = oval['niv_val'] ? oval['niv_val'] : '-';
                    var producteur = oval['producteur'] ? oval['producteur'] : '-';
                    var date_contact = oval['date_contact'] ? oval['date_contact'] : '-';
                    var comm_val = oval['comm_val'] ? oval['comm_val'] : '-';
                    var nom_retenu = oval['nom_retenu'] ? oval['nom_retenu'] : '-';
                    var validation_producteur = oval['validation_producteur'] ? oval['validation_producteur'] : '-';
                    var validation_nationale = oval['validation_nationale'] ? oval['validation_nationale'] : '-';

                    var html = '';
                    html += '<h3><span class="title"><span class="text">' + naturalizLocales['subdock.observation.validation.title'] + '</span>';

                    // Close button
                    html += '<button id="validation-detail-close" class="btn btn-primary btn-mini pull-right" style="margin-left:10px;">Fermer</button>';

                    // Taxon detail URL button
                    var detail_url = data.inpnWebpage;
                    var config_url = occtaxClientConfig.taxon_detail_source_url;
                    if (config_url && config_url.trim() != '') {
                        detail_url = config_url.replace('CD_NOM', data.referenceId);
                    }
                    var in_panier = oval['in_panier'] ? true : false;
                    var p_action = in_panier ? 'remove' : 'add';


                    html += '</span>';
                    html += '</h3>';
                    html += '<div id="validation-detail-container"  class="menu-content">';
                    html += '<table class="table table-condensed table-striped">';
                    // ID
                    html += '<tr><th>' + naturalizLocales['input.identifiant_permanent'] + '</th>';
                    html += '<td>' + oval['identifiant_permanent'] + '</td></tr>';
                    // Type de validation
                    html += '<tr><th title="' + naturalizLocales['input.typ_val.help'] + '">' + naturalizLocales['input.typ_val'] + '</th>';
                    html += '<td>' + (typ_val != '-' ? occtax_nomenclature['typ_val|' + typ_val] : '-') + '</td></tr>';
                    // Date du controle
                    html += '<tr><th title="' + naturalizLocales['input.date_ctrl.help'] + '">' + naturalizLocales['input.date_ctrl'] + '</th>';
                    html += '<td>' + date_ctrl + '</td></tr>';
                    // Niveau
                    html += '<tr><th title="' + naturalizLocales['input.niv_val.help'] + '">' + naturalizLocales['input.niv_val'] + '</th>';
                    html += '<td><span style="cursor:auto;" class="niv_val n' + niv_val + '">' + (niv_val != '-' ? occtax_nomenclature['validite_niveau|' + niv_val] : '-') + '</span></td></tr>';
                    // Producteur
                    html += '<tr><th title="' + naturalizLocales['input.producteur.help'] + '">' + naturalizLocales['input.producteur'] + '</th>';
                    html += '<td>' + producteur + '</td></tr>';
                    // Date du contact
                    html += '<tr><th title="' + naturalizLocales['input.date_contact.help'] + '">' + naturalizLocales['input.date_contact'] + '</th>';
                    html += '<td>' + date_contact + '</td></tr>';
                    // Commentaire
                    html += '<tr><th title="' + naturalizLocales['input.comm_val.help'] + '">' + naturalizLocales['input.comm_val'] + '</th>';
                    html += '<td>' + comm_val + '</td></tr>';
                    // Nom retenu
                    html += '<tr><th title="' + naturalizLocales['input.nom_retenu.help'] + '">' + naturalizLocales['input.nom_retenu'] + '</th>';
                    html += '<td>' + nom_retenu + '</td></tr>';

                    // Validation producteur et nationale
                    // Producteur
                    var niv_producteur = validation_producteur.match(/@(\d{1})@/);
                    if (niv_producteur) {
                        validation_producteur = validation_producteur.replace(
                            niv_producteur[0],
                            occtax_nomenclature['validite_niveau|' + niv_producteur[1]].trim().toLowerCase()
                        );
                    } else {
                        validation_producteur = '-';
                    }
                    html += '<tr><th title="' + naturalizLocales['input.validation_producteur.help'] + '">' + naturalizLocales['input.validation_producteur'] + '</th>';
                    html += '<td>' + validation_producteur + '</td></tr>';
                    // Nationale
                    var niv_national = validation_nationale.match(/@(\d{1})@/);
                    if (niv_national) {
                        validation_nationale = validation_nationale.replace(
                            niv_national[0],
                            occtax_nomenclature['validite_niveau|' + niv_national[1]].trim().toLowerCase()
                        );
                    } else {
                        validation_nationale = '-';
                    }
                    html += '<tr><th title="' + naturalizLocales['input.validation_nationale.help'] + '">' + naturalizLocales['input.validation_nationale'] + '</th>';
                    html += '<td>' + validation_nationale + '</td></tr>';

                    if (has_validation_right) {
                        // Validation basket action button
                        html += '<tr><th>' + naturalizLocales['validation_basket.actionbar.title'] + '</th>';
                        html += '<td>';
                        html += '<button value="' + p_action + '@' + oval['identifiant_permanent'] + '" class="occtax_validation_button btn btn-primary btn-mini"';
                        html += ' title="' + naturalizLocales['button.validation_basket.' + p_action + '.help'] + '">';
                        html += naturalizLocales['button.validation_basket.' + p_action + '.title'] + '</button>';
                        html += '</td></tr>';

                        // Open validation form
                        html += '<tr><th title="' + naturalizLocales['button.validate.observation.title.help'] + '">' + naturalizLocales['button.validate.observation.title'] + '</th>';
                        html += '<td>';
                        html += '<button value="' + oval['cle_obs'] + '" class="occtax_validation_open_form_button btn btn-primary btn-mini"';
                        html += ' title="' + naturalizLocales['button.validate.observation.title.help'] + '">';
                        html += naturalizLocales['button.validation_basket.open.form.title'] + '</button>';
                        html += '</td></tr>';
                    }

                    html += '</table>';
                    html += '</div>';


                    $('#sub-dock').html(html).css('bottom', '0px');
                    $('#occtax-highlight-message').remove();

                    if ($('#docks-wrapper').length) {
                        // LWC >= 3.4.0
                        $('#sub-dock')
                            .css('bottom', '0px')
                            .css('position', 'relative')
                            .css('height', '100%')
                            .css('min-width', '30%')
                            ;
                    } else {
                        // Older versions
                        $('#sub-dock').css('bottom', '0px');
                        if (!lizMap.checkMobile()) {
                            var leftPos = getDockRightPosition();
                            $('#sub-dock').css('left', leftPos).css('width', leftPos);
                        }
                    }

                    // Hide lizmap close button (replaced further)
                    $('#hide-sub-dock').hide();

                    // close windows
                    $('#validation-detail-close').click(function () {
                        $('#sub-dock').hide().html('');
                        $('span.niv_val.active').removeClass('active');
                    })

                    $('#sub-dock').show();
                }
            );
        }

        OccTax.showObservationValidation = function (cle_obs) {
            return showObservationValidation(cle_obs);
        }


        function clearSpatialSearch(empty_layer) {
            if (empty_layer) {
                OccTax.emptyDrawqueryLayer('observationLayer', 'mailleLayer');
                OccTax.deactivateAllDrawqueryControl();
            }
            $('#jforms_occtax_search_geom').val('');
            $('#jforms_occtax_search_code_commune').val('');
            $('#jforms_occtax_search_code_masse_eau').val('');
            $('#jforms_occtax_search_code_maille').val('');
            $('#jforms_occtax_search_type_maille').val('');
            $('#jforms_occtax_search_type_en').val('');
            $('#obs-spatial-query-buttons button').removeClass('active');
        }


        function refreshOcctaxDatatableSize(container) {
            var dtable = $(container).find('table.dataTable');
            dtable.DataTable().tables().columns.adjust();
            //$('#bottom-dock').addClass('visible');
            var h = $("#occtax").height()
            h = h - $('#occtax h3.occtax_search').height() * 3;
            h = h - $("#occtax_search_description:visible").height();
            h = h - $("#occtax_results_tabs").height();
            h = h - $("#occtax_results_observation_table_paginate:visible").height();
            h = h - 130;
            //dtable.parent('div.dataTables_scrollBody').height(h);
            dtable.parent('div.dataTables_scrollBody').css('height', h + "px");
            // Width
            w = dtable.parent('div.dataTables_scrollBody').width();
            //dtable.parent('div.dataTables_scrollBody').width(w - 50);
            dtable.parent('div.dataTables_scrollBody').css('width', w - 50 + "px");

            dtable.DataTable().scrollY = h;
            dtable.DataTable().tables().columns.adjust();
        }

        function moveLizmapMenuLi(liorder) {
            var ul = $("#mapmenu ul.nav-list");
            var li = ul.children("li");
            li.detach().sort(function (a, b) {
                var a_place = liorder[$(a).find('a:first').attr('href').replace('#', '')];
                var b_place = liorder[$(b).find('a:first').attr('href').replace('#', '')];
                return a_place > b_place
            });
            ul.append(li);
        }

        function getWhiteParams(context) {
            var white_params = [
                'taxons_bdd',
                'group', 'habitat', 'statut', 'endemicite',
                'invasibilite',
                'menace_regionale', 'menace_nationale', 'menace_monde',
                'protection',
                'cd_nom', 'cd_ref',
                'code_commune', 'code_masse_eau',
                'code_maille', 'type_maille',
                'type_en',
                'nom_valide',
                'geom',
                'jdd_id', 'validite_niveau', 'observateur',
                'type_en',
                'date_min', 'date_max',
                'panier_validation',
            ];
            return white_params;
        }

        // Take a query string, decompose the corresponding parameters, set the form fields values
        // And launch the search if needed
        function updateFormInputsFromUrl(query_string) {
            // Example URL
            // ?cd_nom%5B0%5D=79700&cd_nom%5B1%5D=447404&observateur=durand&date_min=2000-05-01&date_max=2019-01-01
            // detect parameters
            if (!query_string) {
                return false;
            }

            // Parse given query string
            var params = new URLSearchParams(query_string);
            var targets = {};
            params.forEach(function (value, key) {
                // Crop name to remove array part
                // cd_nom[0] -> cd_nom
                var skey = key.split('[')[0];
                if (!(skey in targets)) {
                    targets[skey] = [];
                }
                targets[skey].push(value)
            });

            // Get search form properties
            var tokenFormId = $('#div_form_occtax_search_token form').attr('id');
            var trigger_submit = false;
            var white_params = getWhiteParams('url');
            var geometry_already_added = false;
            var cd_nom_list = [];

            // Reinit form and interface
            reinitSearchForm();
            clearSpatialSearch(false);

            // Assign values to the inputs based on the parameters found in the query string
            for (var name in targets) {
                if ($.inArray(name, white_params) == -1) {
                    continue;
                }
                trigger_submit = true;
                var input_name = name;
                var input_value = targets[name];
                //var input_value = decodeURIComponent(entry[1]);

                if ((input_name == 'date_min' || input_name == 'date_max') && input_value[0] != '') {
                    // Dates: traitement particulier
                    $('#' + tokenFormId + ' [name="' + input_name + '[year]"]').val(input_value[0].split('-')[0]);
                    $('#' + tokenFormId + ' [name="' + input_name + '[month]"]').val(input_value[0].split('-')[1]);
                    $('#' + tokenFormId + ' [name="' + input_name + '[day]"]').val(input_value[0].split('-')[2]);
                    $('#' + tokenFormId + ' [name="' + input_name + '_hidden"]').val(input_value[0]);
                } else if (input_name == 'cd_nom' && Array.isArray(input_value) && input_value.length > 0) {
                    // cd_nom: recherche par liste de taxons
                    cd_nom_list = input_value;
                    for (var i in input_value) {
                        addTaxonToSearch(input_value[i], 'cd_nom = ' + input_value[i]);
                    }
                } else {
                    // Autres champs
                    var input_item = $('#' + tokenFormId + ' [name="' + input_name + '"]');
                    var ismulti = false;
                    if (input_item.length == 0) {
                        input_item = $('#' + tokenFormId + ' [name="' + input_name + '[]"]');
                        ismulti = true;
                    }
                    input_item.val(input_value);
                    // sumoselect too
                    if (ismulti && input_item && input_item[0]) {
                        input_item[0].sumo.unSelectAll();
                        for (var i in input_value) {
                            input_item[0].sumo.selectItem(input_value[i]);
                        }
                    }

                }

                // Bascule sur l'onglet de recherche par attribut
                var attributes_items = [
                    'group', 'habitat', 'statut', 'endemicite',
                    'invasibilite',
                    'menace_regionale', 'menace_nationale', 'menace_monde',
                    'protection'
                ]
                if ($.inArray(input_name, attributes_items) != -1 && input_value != '') {
                    $('li a[href="#recherche_taxon_attributs"]').click();
                }

                // Récupère la géométrie dessinée et l'affiche sur la carte
                if (input_name == 'geom' && input_value && input_value[0] != '') {
                    var wkt = input_value[0].trim();
                    var wkt_format = new OpenLayers.Format.WKT();
                    var geom = wkt_format.read(wkt).geometry;
                    var theLayer = OccTax.layers['queryLayer'];

                    geom.transform('EPSG:4326', OccTax.map.projection);
                    theLayer.addFeatures([new OpenLayers.Feature.Vector(geom)]);
                }

                // Récupère la géométrie d'un objet spatial
                var attributes_items = [
                    'code_commune', 'code_masse_eau',
                    'code_maille'
                ]
                if ($.inArray(input_name, attributes_items) != -1 && input_value != '') {
                    if (geometry_already_added) {
                        continue;
                    }
                    var geomform_getter = '#form_occtax_service_' + input_name.replace('code_', '');
                    var type_maille = '';
                    if (input_name == 'code_maille') {
                        type_maille = targets['type_maille'];
                    }
                    $.post(
                        $(geomform_getter).attr('action')
                        , { x: '', y: '', type_maille: type_maille, code: input_value[0] }
                        , function (data) {
                            if (data.status == 1) {
                                var format = new OpenLayers.Format.GeoJSON();
                                var geom = format.read(data.result.geojson)[0].geometry;
                                var theLayer = OccTax.layers['queryLayer'];
                                theLayer.destroyFeatures();
                                geom.transform('EPSG:4326', OccTax.map.projection);
                                theLayer.addFeatures([new OpenLayers.Feature.Vector(geom)]);
                            }
                        }, 'json'
                    );
                    geometry_already_added = true;
                }

            };

            // Submit form
            if (trigger_submit) {
                $('#' + tokenFormId).submit();
                if (cd_nom_list.length > 0) {
                    // Change name of chosen cd_nom in bucket
                    for (var i in cd_nom_list) {
                        var form_getter = '#form_occtax_service_commune';
                        $.post(
                            $(form_getter).attr('action').replace('getCommune', 'getTaxon')
                            , { cd_nom: cd_nom_list[i] }
                            , function (data) {
                                if (data.status == 1) {
                                    deleteTaxonToSearch(data.result.cd_nom);
                                    addTaxonToSearch(data.result.cd_nom, data.result.nom_valide);
                                }
                            }, 'json'
                        );
                    }
                }
            }
        }

        /**
         * Read the search form input values and create the corresponding query string.
         * For example:
         * ?cd_nom%5B0%5D=79700&cd_nom%5B1%5D=447404&observateur=durand&date_min=2000-05-01&date_max=2019-01-01
         *
         * It also dynamically modifies the browser URL
         * and returns the built query string
         *
         * @return {string} The generated query string
         */
        function updateUrlFromFormInput() {
            var tokenFormId = $('#div_form_occtax_search_token form').attr('id');
            var white_params = getWhiteParams('form');
            var form_params = '';
            for (var k in white_params) {
                var name = white_params[k];
                // Dates
                var input_value = '';
                if (name == "date_min") {
                    var input_value = $('#' + tokenFormId + ' [name="' + name + '[year]"]').val();
                    if (input_value != '') {
                        input_value += '-' + $('#' + tokenFormId + ' [name="' + name + '[month]"]').val();
                        input_value += '-' + $('#' + tokenFormId + ' [name="' + name + '[day]"]').val();
                    }
                } else if (name == "date_max") {
                    var input_value = $('#' + tokenFormId + ' [name="' + name + '[year]"]').val();
                    if (input_value != '') {
                        input_value += '-' + $('#' + tokenFormId + ' [name="' + name + '[month]"]').val();
                        input_value += '-' + $('#' + tokenFormId + ' [name="' + name + '[day]"]').val();
                    }
                } else if (name == "cd_nom") {
                    var cd_nom = $('#' + tokenFormId + ' [name="' + name + '[]"]').val();
                    var input_value = cd_nom;
                } else if (name == "panier_validation") {
                    var input_value = $('#' + tokenFormId + ' [name="' + name + '"]').prop("checked");
                    input_value = input_value ? 1 : 0;
                } else {
                    // Check if simple input can be found
                    var input_selector = '#' + tokenFormId + ' [name="' + name + '"]';
                    var input_item = $(input_selector);
                    if (input_item.length == 0) {
                        var input_selector = '#' + tokenFormId + ' [name="' + name + '[]"]';
                        var input_item = $(input_selector);
                    }
                    var input_value = input_item.val();
                }
                if (input_value && input_value != '') {
                    if (Array.isArray(input_value)) {
                        for (var v in input_value) {
                            form_params += name + '[' + v + ']=' + input_value[v] + '&';
                        }
                    } else {
                        form_params += name + '=' + input_value + '&';
                    }
                }

            }
            if (form_params != '') {
                var to_push = '?';
                to_push +=  form_params.trim('&');
                window.history.pushState('', '', to_push);
            }

            // Return the built query string
            var query_string = window.location.search;

            return query_string;
        }


        // MANAGE THE HISTORY OF URLS

        /**
         * Return a valid UUID.
         *
         * @return {string} The generated UUID.
         */
        function uuidv4() {
            return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
                var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
                return v.toString(16);
            });
        }

        /**
         * Remove bbox from query string.
         *
         * Useful when comparing query strings.
         *
         * @return {string} The cleaned query string.
         */
        function cleanQueryString(query_string) {
            return query_string.split('bbox')[0].replace(/&+$/gm, '');
        }

        /**
         * Get the stored search items from localStorage and returns an array of items.
         *
         * @return {array} The array of search history items.
         */
        function getSearchHistory() {

            // Get current storage (json representation of an array of objects)
            var current_storage_json = localStorage.getItem('naturaliz_search_history');
            var current_storage = [];
            if (current_storage_json) {
                current_storage = JSON.parse(current_storage_json);
            }

            return current_storage;
        }

        /**
         * Transform the stored search items to keep only a given maximum of stared and unstared items.
         *
         * It also save the transformed array and override the previous one.
         *
         * @param {integer} max_stared - The maximum number of stared items to keep.
         * @param {integer} max_unstared - The maximum number of unstared items to keep.
         * @return {array} The array of search history items
         */
        function cleanSearchHistory(max_stared, max_unstared) {
            var current_storage = getSearchHistory();

            // Filter the item based on the stared status
            var filtered_storage = [];
            var stared = 0;
            var unstared = 0;
            for (var s in current_storage) {
                // Get the item
                var item = current_storage[s];

                // increment the number of items
                if (item.stared) {
                    stared ++;
                } else {
                    unstared ++;
                }

                // Add to the filtered array only if under max items required
                if (item.stared && stared <= max_stared) {
                    filtered_storage.push(item);
                }
                if (!item.stared && unstared <= max_unstared) {
                    filtered_storage.push(item);
                }
            }

            // Refresh the select
            refreshHistorySelector(null);

            localStorage.setItem('naturaliz_search_history', JSON.stringify(filtered_storage));

            return filtered_storage;
        }

        /**
         * Find a search history item by query string.
         *
         * @param {string} query_string - The query string to search
         * @return {array} The found search index and history item.
         */
         function findSearchItemByQueryString(query_string) {
            var current_storage = getSearchHistory();
            var item = null;
            for (var i in current_storage) {
                let stored_query_string = cleanQueryString(current_storage[i].value);
                if(stored_query_string == query_string) {
                    item = [i, current_storage[i]];
                    break;
                }
            }

            return item;
        }


        /**
         * Get a search item by its uid
         *
         * @param {string} uid - The UUID of the item
         * @return {object} The found search item.
         */
         function findSearchItemByUid(uid) {
            var current_storage = getSearchHistory();
            var found_item = null;

            // Rename current item in naturaliz_search_history
            for (var i in current_storage) {
                if(current_storage[i].uid == uid) {
                    found_item = current_storage[i];
                    break;
                }
            }

            return found_item;
         }

        /**
         * Store the current search item in the local storage.
         *
         * The item label is auto-generated. The stared status is set to false.
         *
         * @return {object} The stored search item.
         */
        function storeCurrentSearch() {
            var query_string = window.location.search;
            if (!query_string) {
                return false;
            }
            // Remove bbox
            query_string = cleanQueryString(query_string);

            // Get all the stored items
            var current_storage = getSearchHistory();

            // Check if this query_string does not already exists
            var check_item = findSearchItemByQueryString(query_string);
            if (check_item) {
                // Get index and item content
                let existing_index = check_item[0];
                var existing_item = check_item[1];

                // Move item at the top
                current_storage.sort((x,y) => x['uid'] === existing_item.uid ? -1 : y['uid'] === existing_item.uid);

                // Replace label if name is not automatic
                if (existing_item.label.substring(0, 9) == "Recherche") {
                    const current_date = new Date().toLocaleString('fr-FR').replace(', ', ' à ');
                    current_storage[0]['label'] = 'Recherche du ' + current_date;
                }

                // Save it back to the storage
                localStorage.setItem('naturaliz_search_history', JSON.stringify(current_storage));

                refreshHistorySelector(existing_item.uid);
                return false;
            }

            // Initialize a new item with a default label
            const current_date = new Date().toLocaleString('fr-FR').replace(', ', ' à ');
            let query_description = $('#occtax_search_description_content').text().split('Résultat')[0].trim();
            var item = {
                'uid': uuidv4(),
                'label': 'Recherche du ' + current_date,
                'description': query_description,
                'value': query_string,
                'stared': false
            };

            // Prepend this new item at the beginning of the array of items
            current_storage.unshift(item);

            // Save it back to the storage
            localStorage.setItem('naturaliz_search_history', JSON.stringify(current_storage));

            // Keep only the 10 last items which are not stared
            cleanSearchHistory(search_history_max_stared, search_history_max_unstared);

            // Refresh the select
            refreshHistorySelector(item.uid);

            return item;
        }


        /**
         * Star or unstar the given search history item.
         *
         * @param {string} uid - The UUID of the item
         * @return {object} The modified search item.
         */
        function starSearchItem(uid) {
            var current_storage = getSearchHistory();
            var new_item = null;
            var star_it = $('#occtax-search-history-select option[value="'+uid+'"]').hasClass('unstared');

            // Rename current item in naturaliz_search_history
            for (var i in current_storage) {
                if(current_storage[i].uid == uid) {
                    // check actual star status
                    new_item = {
                        'uid': current_storage[i].uid,
                        'label': current_storage[i].label,
                        'description': current_storage[i].description,
                        'value': current_storage[i].value,
                        'stared': star_it
                    };

                    current_storage.splice(i, 1, new_item);
                    break;
                }
            }
            localStorage.setItem('naturaliz_search_history', JSON.stringify(current_storage));

            // Refresh the select
            refreshHistorySelector(uid);

            return new_item;
        }


        /**
         * Rename the given search history item.
         *
         * @param {string} uid - The UUID of the item
         * @param {string} label - The label to give
         * @return {object} The modified search item.
         */
         function renameSearchItem(uid, label) {
            var current_storage = getSearchHistory();
            var new_item = null;

            // Rename current item in naturaliz_search_history
            for (var i in current_storage) {
                if(current_storage[i].uid == uid) {
                    // check actual star status
                    new_item = {
                        'uid': current_storage[i].uid,
                        'label': current_storage[i].label,
                        'description': current_storage[i].description,
                        'value': current_storage[i].value,
                        'stared': current_storage[i].stared
                    };
                    new_item.label = label.trim();

                    current_storage.splice(i, 1, new_item);
                    break;
                }
            }
            localStorage.setItem('naturaliz_search_history', JSON.stringify(current_storage));

            // Refresh the select
            refreshHistorySelector(uid);

            return new_item;
        }

        /**
         * Delete a search history item by UUID.
         *
         * @param {string} uid - The UUID of the item
         * @return {object} The deleted search item.
         */
        function deleteSearchItem(uid) {
            var current_storage = getSearchHistory();
            var deleted = null;

            for (var i in current_storage) {
                if(current_storage[i].uid == uid) {
                    var confirm_msg = 'Êtes-vous sûr de vouloir supprimer cette recherche ?'
                    var confirm_action = confirm(confirm_msg);
                    if (!confirm_action) {
                        return false;
                    }
                    deleted = current_storage.splice(i, 1);
                    break;
                }
            }
            localStorage.setItem('naturaliz_search_history', JSON.stringify(current_storage));

            // Refresh the select
            if (deleted) {
                refreshHistorySelector(null);
            }

            return deleted;
        }

        /**
         * Lauch the search for a given stored item.
         *
         * @param {string} uid - The UUID of the item
         * @return {string} The query string which has been launched
         */
        function runSearchItem(uid) {
            var current_storage = getSearchHistory();
            var query_string = null;

            for (var i in current_storage) {
                if(current_storage[i].uid == uid) {
                    var query_string = cleanQueryString(current_storage[i].value);

                    // Reinit browser query string
                    window.history.pushState('', '', '?bbox=' + lizMap.map.getExtent().toBBOX());

                    // Réinit form
                    reinitSearchForm();

                    // Run search
                    updateFormInputsFromUrl(query_string);
                    break;
                }
            }

            return query_string;
        }

        /**
         * Empty the search history.
         *
         * You can choose which one to empty with the stared_status parameter.
         *
         * @param {string} stared_status - The status of the items to delete: all, stared, unstared.
         * @return {boolean} - True on success, false if canceled.
         */
        function emptySearchHistory(stared_status) {
            var confirm_msg = 'Êtes-vous sûr de vouloir vider votre historique de recherches ?'
            var confirm_action = confirm(confirm_msg);
            if (!confirm_action) {
                return false;
            }

            if (stared_status == 'unstared') {
                cleanSearchHistory(20, 0);
            } else if (stared_status == 'stared') {
                cleanSearchHistory(0, 10);
            } else {
                cleanSearchHistory(0, 0);
            }

                // Refresh the select
            refreshHistorySelector(null);
            return true;
        }

        /**
         * Refresh the html select occtax-search-history-select with the current search history items
         *
         * @param {string} uid_to_select - UUID to select in the list (optional)
         */
        function refreshHistorySelector(uid_to_select) {
            var html = '';
            var count_unstared = 0;
            var count_stared = 0;
            // Add options from the items
            var current_storage = getSearchHistory();
            for (var i in current_storage) {
                var item = current_storage[i];
                var is_stared = (item.stared ? 'stared' : 'unstared');
                html += ' <option class="'+is_stared+'"';
                html += ' value="' + item.uid + '"';
                html += ' title="' + item.label + '\n' + item.description + '"';
                html += '>';
                var icon = (item.stared ? '⭐' : '🧭');
                html += icon + '&nbsp;' + item.label;
                html += '</option>';
                if (item.stared) {
                    count_stared += 1;
                } else {
                    count_unstared += 1;
                }
            }

            // Update HTML
            $('#occtax-search-history-select').html(html);
            if (uid_to_select) {
                $('#occtax-search-history-select').val(uid_to_select);
            }

            // Update description
            var description = [];
            if (count_stared > 0) {
                description.push('⭐ ' + count_stared + '/' + search_history_max_stared);
            }
            if (count_unstared > 0) {
                description.push('🧭 ' + count_unstared + '/' + search_history_max_unstared);
            }
            var history_title = description.join('&nbsp;&nbsp;&nbsp;')
            $('#occtax-search-history-title-counter').html(history_title);

        }


        /**
         * Change some UI elements based on the selected option
         *
         * @param {string} uid - The UUID of the item
         */
         function adaptHistoryUiForSelectedOption(uid) {
            // Get item
            var item = findSearchItemByUid(uid);
            if (!item) {
                return false;
            }

            // Change the star button
            var star_button_icon = (item.stared) ? 'icon-star-empty': 'icon-star';
            var star_button_label = (item.stared) ? 'Retirer des favoris': 'Ajouter aux favoris';
            $('#occtax-search-history-star i').attr('class', star_button_icon);
            $('#occtax-search-history-star').attr('title', star_button_label);
         }

        // Adapt UI when an option is selected
        $('#occtax-search-history-select').change(function() {
            var uid = $(this).val();
            if (uid) {
                adaptHistoryUiForSelectedOption(uid);
            }
        });

        // Trigger the search when the select option is selected
        $('#occtax-search-history-play').click(function() {
            var uid = $('#occtax-search-history-select').val();
            if (uid) {
                runSearchItem(uid);
            }
        });

        // Trigger the star/unstar
        $('#occtax-search-history-star').click(function() {
            var uid = $('#occtax-search-history-select').val();
            if (uid) {
                starSearchItem(uid);
                adaptHistoryUiForSelectedOption(uid);
            }
        });

        // Trigger the rename
        $('#occtax-search-history-rename').click(function() {
            var uid = $('#occtax-search-history-select').val();
            if (uid) {
                var prompt_msg = 'Choisissez le texte pour renommer cette recherche';
                var label = prompt(prompt_msg);
                if (!label || label.trim() == '') {
                    return false;
                }
                renameSearchItem(uid, label.trim());
            }
        });

        // Trigger the deletion
        $('#occtax-search-history-delete').click(function() {
            var uid = $('#occtax-search-history-select').val();
            if (uid) {
                deleteSearchItem(uid);
            }

        });

        // Tests
        OccTax.getSearchHistory = function () {return getSearchHistory()};
        OccTax.cleanSearchHistory = function (max_stared, max_unstared) {return cleanSearchHistory(max_stared, max_unstared)};
        OccTax.storeCurrentSearch = function () {return storeCurrentSearch()};
        OccTax.starSearchItem = function (uid) {return starSearchItem(uid)};
        OccTax.deleteSearchItem = function (uid) {return deleteSearchItem(uid)};
        OccTax.runSearchItem = function (uid) {return runSearchItem(uid)};
        OccTax.emptySearchHistory = function (stared_status) {return emptySearchHistory(stared_status)};
        OccTax.refreshHistorySelector = function (uid) {return refreshHistorySelector(uid)};


        //console.log('OccTax uicreated');
        $('#occtax-message').remove();
        $('#occtax-highlight-message').remove();

        // Hide empty groups
        $('.jforms-table-group').each(function () {
            var tbContent = $(this).html().replace(/(\r\n|\n|\r)/gm, "");
            if (!tbContent) {
                $(this).parent('fieldset:first').hide();
            }
        });

        OccTax.controls['query'] = {};
        /**
          * Ajout de la couche openlayers des requêtes cartographiques
          */
        var queryLayer = new OpenLayers.Layer.Vector(
            "queryLayer", { styleMap: OccTax.drawStyleMap }
        );
        OccTax.map.addLayers([queryLayer]);
        OccTax.layers['queryLayer'] = queryLayer;

        /**
         * Point
         * @type @new;OpenLayers.Control.DrawFeature
         */
        var queryPointLayerCtrl = new OpenLayers.Control.DrawFeature(queryLayer,
            OpenLayers.Handler.Point, { 'featureAdded': onQueryFeatureAdded }
        );
        OccTax.map.addControl(queryPointLayerCtrl);
        OccTax.controls['query']['queryPointLayerCtrl'] = queryPointLayerCtrl;

        /**
         * Circle
         * @type @new;OpenLayers.Control.DrawFeature
         */
        var queryCircleLayerCtrl = new OpenLayers.Control.DrawFeature(queryLayer,
            OpenLayers.Handler.RegularPolygon,
            { handlerOptions: { sides: 40 }, 'featureAdded': onQueryFeatureAdded }
        );
        OccTax.map.addControl(queryCircleLayerCtrl);
        OccTax.controls['query']['queryCircleLayerCtrl'] = queryCircleLayerCtrl;

        /**
         * Polygon
         * @type @new;OpenLayers.Control.DrawFeature
         */
        var queryPolygonLayerCtrl = new OpenLayers.Control.DrawFeature(queryLayer,
            OpenLayers.Handler.Polygon, { 'featureAdded': onQueryFeatureAdded, styleMap: OccTax.drawStyleMap }
        );
        OccTax.map.addControl(queryPolygonLayerCtrl);
        OccTax.controls['query']['queryPolygonLayerCtrl'] = queryPolygonLayerCtrl;

        /**
         * Controle de modification d'un polygone
         * @type @new;OpenLayers.Control.ModifyFeature
         */
        var modifyPolygonLayerCtrl = new OpenLayers.Control.ModifyFeature(queryLayer, { styleMap: OccTax.drawStyleMap });
        OccTax.map.addControl(modifyPolygonLayerCtrl);
        OccTax.controls['query']['modifyPolygonLayerCtrl'] = modifyPolygonLayerCtrl;
        queryLayer.events.on({
            featuremodified: onQueryFeatureModified
        });

        $('#obs-spatial-upload-geojson form').fileupload({
            dataType: 'json',
            done: function (e, data) {
                data = data.result;
                if (data.status == 1) {
                    var format = new OpenLayers.Format.GeoJSON();
                    var features = format.read(data.result);
                    var totalSurf = 0.0;
                    var multiPoly = null;

                    for (var i = 0, len = features.length; i < len; i++) {
                        var feat = features[i];
                        var geom = feat.geometry;
                        // break if the geometry is not a polygon
                        if (geom.CLASS_NAME != 'OpenLayers.Geometry.Polygon'
                            && geom.CLASS_NAME != 'OpenLayers.Geometry.MultiPolygon') {
                            lizMap.addMessage('Geometrie incorrecte', 'error', true).attr('id', 'occtax-highlight-message');
                            multiPoly = null;
                            break;
                        }
                        // does not store geom if not in the map
                        if (!lizMap.map.restrictedExtent.intersectsBounds(geom.getBounds())) {
                            lizMap.addMessage("La zone envoyée n'est pas dans l'emprise de la carte. La donnée doit être dans la projection de la carte :  " + lizMap.map.getProjection(), 'error', true).attr('id', 'occtax-highlight-message');
                            break;
                        }
                        // sum total surface
                        totalSurf += geom.getArea();
                        // break if total surface is enough than maxAreaQuery (only if maxAreaQuery != -1
                        if (OccTax.config.maxAreaQuery > 0 && totalSurf >= OccTax.config.maxAreaQuery) {
                            lizMap.addMessage('La surface totale des objets est trop importante (doit être < ' + OccTax.config.maxAreaQuery + ' )', 'error', true).attr('id', 'occtax-highlight-message');
                            multiPoly = null;
                            break;
                        }
                        // Construct multi polygon
                        if (geom.CLASS_NAME == 'OpenLayers.Geometry.MultiPolygon') {
                            if (multiPoly == null)
                                multiPoly = geom;
                            else
                                multiPoly.addComponents(geom.components);
                        } else {
                            if (multiPoly == null)
                                multiPoly = new OpenLayers.Geometry.MultiPolygon([geom]);
                            else
                                multiPoly.addComponents([geom]);
                        }
                    }
                    if (multiPoly != null) {
                        // construct feature and add it
                        var multiFeat = new OpenLayers.Feature.Vector(multiPoly);
                        OccTax.layers['queryLayer'].addFeatures(multiFeat);
                        onQueryFeatureAdded(multiFeat);
                        lizMap.addMessage(data.msg.join('<br/>'), 'info', true).attr('id', 'occtax-highlight-message');
                    }
                } else
                    lizMap.addMessage(data.msg.join('<br/>'), 'error', true).attr('id', 'occtax-highlight-message');
            }
        });


        $('#obs-spatial-query-buttons button').button().click(function () {
            // Deactivate print if active
            $('#mapmenu li.print.active a').click();

            var self = $(this);
            var dataValue = self.attr('data-value');

            if (dataValue != 'modifyPolygon') {
                $('#obs-spatial-query-modify').hide();
                $('#obs-spatial-query-modify').removeClass('active');
            }

            if (dataValue == 'deleteGeom') {
                clearSpatialSearch(true);
                return false;
            }
            if (dataValue == 'importPolygon') {
                $('#obs-spatial-upload-geojson form input[type="file"]').click();
                //return false;
            }
            if (dataValue == 'modifyPolygon') {
                if (OccTax.controls['query']['modifyPolygonLayerCtrl'].active) {
                    self.removeClass('active');
                    var theLayer = OccTax.layers['queryLayer'];
                    var feature = theLayer.features[0];
                    OccTax.validGeometryFeature(feature);
                    theLayer.drawFeature(feature);
                    var geom = feature.geometry.clone().transform(OccTax.map.projection, 'EPSG:4326');
                    $('#jforms_occtax_search_geom').val(geom.toString());
                    $('#jforms_occtax_search_code_commune').val('');
                    $('#jforms_occtax_search_code_masse_eau').val('');
                    $('#jforms_occtax_search_code_maille').val('');
                    $('#jforms_occtax_search_type_maille').val('');
                    OccTax.controls['query']['modifyPolygonLayerCtrl'].deactivate();
                    OccTax.controls['query']['modifyPolygonLayerCtrl'].moveLayerBack();
                    return false;
                } else {
                    // we must empty mailleLayer and observationLayer to be sure the modified control works
                    // This is why we do not list them in oneCtrlAtATime
                    OccTax.oneCtrlAtATime(dataValue, 'query', ['queryLayer']);
                    OccTax.controls['query']['modifyPolygonLayerCtrl'].activate();
                    OccTax.controls['query']['modifyPolygonLayerCtrl'].selectFeature(OccTax.layers['queryLayer'].features[0]);
                    self.addClass('active');
                }
            } else {
                OccTax.oneCtrlAtATime(dataValue, 'query', ['mailleLayer', 'observationLayer']);
                //$('#map').css('cursor','pointer');
            }
            //return false;
        });


        OccTax.controls['select'] = {};
        /**
          * Ajout de la couche openlayers des résultats de mailles
          */
        var mailleLayer = new OpenLayers.Layer.Vector("mailleLayer", {
            styleMap: OccTax.mailleLayerStyleMap
        }
        );
        OccTax.map.addLayers([mailleLayer]);
        OccTax.layers['mailleLayer'] = mailleLayer;

        var highlightCtrl = new OpenLayers.Control.SelectFeature(mailleLayer, {
            hover: true,
            highlightOnly: true,
            renderIntent: "select",
            eventListeners: {
                beforefeaturehighlighted: function (e) {
                    $('#occtax-highlight-message').remove();
                },
                featurehighlighted: function (evt) {
                    lizMap.addMessage(evt.feature.attributes.message_text, 'info', true).attr('id', 'occtax-highlight-message');
                },
                featureunhighlighted: function (evt) {
                    $('#occtax-highlight-message').fadeOut('fast', function () {
                        $(this).remove();
                    });
                }
            }
        });
        OccTax.map.addControl(highlightCtrl);
        OccTax.controls['select']['highlightCtrl'] = highlightCtrl;
        OccTax.controls['select']['highlightCtrl'].activate();

        /**
          * Ajout de la couche openlayers des résultats d'observations
          */
        var cluster_strategy = new OpenLayers.Strategy.Cluster();
        var observationLayer = new OpenLayers.Layer.Vector("observationLayer", {
            styleMap: OccTax.observationLayerStyleMap
            , strategies: [
                cluster_strategy
            ]
        }
        );
        cluster_strategy.distance = 30;
        OccTax.map.addLayers([observationLayer]);
        OccTax.layers['observationLayer'] = observationLayer;
        var selectObservationCtrl = new OpenLayers.Control.SelectFeature(observationLayer, {
            clickout: true,
            eventListeners: {
                featurehighlighted: function (evt) {
                    $('#occtax-highlight-message').remove();
                    var features = evt.feature.cluster;
                    var len = features.length;

                    // Prepare message table
                    var messages = [];
                    messages.push('<b>');
                    messages.push(len + ' observation');
                    if (len > 1) {
                        messages.push('s');
                    }
                    messages.push('</b>');
                    messages.push('<div class="occtax-highlight-message-container">');

                    messages.push('<i>' + naturalizLocales['map.message.table.click.detail.info'] + '</i>');
                    messages.push('<table class="table table-condensed">');
                    messages.push('<thead>');

                    var avoided_properties = [
                        'labels', OccTax.config.taxon_detail_nom_menace, 'protection'
                        , 'geojson'
                    ];

                    // Add table header with attributes
                    var feat_zero = features[0];
                    messages.push('<tr>');
                    for (var a in feat_zero.attributes) {
                        if ($.inArray(a, avoided_properties) > -1) {
                            continue;
                        }
                        messages.push('<th>' + naturalizLocales['output.' + a] + '</th>');
                    }
                    messages.push('</tr>');
                    messages.push('</thead>');
                    messages.push('<tbody>');

                    // Add lines from cluster or single feature
                    // Only one feature
                    if (len == 1) {
                        var feature = feat_zero;
                        messages.push('<tr>');
                        for (var a in feature.attributes) {
                            if ($.inArray(a, avoided_properties) > -1) {
                                continue;
                            }
                            messages.push('<td>' + feature.attributes[a] + '</td>');
                        }
                        messages.push('</tr>');
                    }
                    // Cluster
                    else {
                        for (var f in features) {
                            var feature = features[f];
                            messages.push('<tr>');
                            for (var a in feature.attributes) {
                                if ($.inArray(a, avoided_properties) > -1) {
                                    continue;
                                }
                                messages.push('<td>' + feature.attributes[a] + '</td>');
                            }
                            messages.push('</tr>');
                        }
                    }
                    // Add Lizmap message
                    messages.push('</tbody>');
                    messages.push('</table>');
                    messages.push('</div>');
                    lizMap.addMessage(messages.join(''), 'info', true).attr('id', 'occtax-highlight-message');
                    // Transform table into a datatable table
                    var message_table = $('div.occtax-highlight-message-container table').DataTable({
                        paging: false,
                        info: false,
                        searching: false,
                        scrollY: 200,
                        scrollX: '95%',
                        scrollCollapse: true,
                        columnDefs: [
                            {
                                "targets": [0], // 0 = id
                                "visible": false
                            }
                        ]
                    });

                    // Activate click on table line: open the observation detail
                    $('div.occtax-highlight-message-container table tbody').on('click', 'tr', function () {
                        var data = message_table.row(this).data();
                        var with_nav_buttons = false;
                        getObservationDetail(data[0], with_nav_buttons);
                    });

                    // Display raw geometries if cluster is clicked
                    // or if geometry is not point
                    OccTax.layers['observationTempLayer'].destroyFeatures();
                    var display_raw = false;
                    if (len == 1) {
                        // Do not display if geometry is point
                        if (feature.geometry.CLASS_NAME != 'OpenLayers.Geometry.Point') {
                            displayObservationGeom(feat_zero.attributes.geojson, true);
                        }
                    }
                    //else {
                    //for (var f in features) {
                    //var feature = features[f];
                    //displayObservationGeom(feature.attributes.geojson, false);
                    //}
                    //}
                },
                featureunhighlighted: function (evt) {
                    $('#occtax-highlight-message').fadeOut('fast', function () {
                        $(this).remove();
                    });
                    OccTax.layers['observationTempLayer'].destroyFeatures();
                }
            }
        });
        OccTax.map.addControl(selectObservationCtrl);
        OccTax.controls['select']['selectObservationCtrl'] = selectObservationCtrl;
        OccTax.controls['select']['selectObservationCtrl'].activate();


        // Ajout de la couche pour afficher les observations uniques
        var observationTempLayer = new OpenLayers.Layer.Vector(
            "observationTempLayer", { styleMap: OccTax.tempStyleMap }
        );
        OccTax.map.addLayers([observationTempLayer]);
        OccTax.layers['observationTempLayer'] = observationTempLayer;

        //activate tabs
        $('#occtax_results_tabs a').tab();

        // Get token form id
        var tokenFormId = $('#div_form_occtax_search_token form').attr('id');

        // Toggle pannel display
        $('#occtax-search-modify').click(function () {
            $('#occtax-highlight-message').remove();
            $('#occtax-message').remove();
            $('#occtax_search_input').show();
            $('#occtax_search_observation_card').hide();
            $('#occtax_search_description').hide();
            $('#occtax_search_result').hide();
            $('#occtax-search-replay').toggle();
            $(this).toggle();
            //return false;
        });
        $('#occtax-search-replay').click(function () {
            $('#occtax_search_input').hide();
            $('#occtax_search_observation_card').hide();
            $('#occtax_search_description').show();
            $('#occtax_search_result').show();
            $('#occtax-search-modify').toggle();
            $(this).toggle();
            //return false;
        });

        // Get search token corresponding to form inputs
        unblockSearchForm();
        $('#' + tokenFormId).submit(function () {

            // Check user is still connected if he was
            var ok = checkConnection();
            if (!ok) {
                return false;
            }

            // Bloc submit if a previous submit is in progress
            if (blocme) {
                return false;
            }
            blocme = true;

            var self = $(this);

            // The Occtax events trigger an error on first load (when page not entirely loaded)
            // this causes submit to another page because JS event has not been correctly added to the form
            // we use try/catch to avoid it
            try {
                $('#occtax_result_button_bar').hide();
                // show statistics
                $('#occtax_results_stats_table_tab').tab('show');
                // deactivate geometry button
                $('#obs-spatial-query-buttons button.active').click();

                // Remove previous features : remove feature in all layers except queryLayer
                OccTax.emptyDrawqueryLayer('queryLayer');
                if ($('#occtax_results_draw_maille_m01.btn').length) {
                    OccTax.events.triggerEvent('mailledatareceived_' + 'm01', { 'results': null });
                }
                if ($('#occtax_results_draw_maille_m02.btn').length) {
                    OccTax.events.triggerEvent('mailledatareceived_' + 'm02', { 'results': null });
                }
                //OccTax.events.triggerEvent('mailledatareceived_' + 'm05', {'results':null});
                if ($('#occtax_results_draw_maille_m10.btn').length) {
                    OccTax.events.triggerEvent('mailledatareceived_' + 'm10', { 'results': null });
                }
            } catch (e) {
                var anerror = 1;
                //console.error(e);
            }

            // Remove previous messages
            $('#occtax-message').remove();
            $('#occtax-highlight-message').remove();

            // Deactivate (CSS) main div
            $('#occtax').addClass('not_enabled');
            lizMap.addMessage('Recherche en cours...', 'info', true).attr('id', 'occtax-message');

            // Remove taxon input values depending on active tab
            if ($('#occtax_taxon_tab_div > div.tab-content > div.active').length == 1) {
                var aid = $('#occtax_taxon_tab_div > div.tab-content > div.active')[0].id;

                // Panier de taxons
                if (aid == 'recherche_taxon_panier') {
                    var removePanier = false;
                    var removeFilters = true;
                }
                // Recherche par critères
                else {
                    var removePanier = true;
                    var removeFilters = false;
                }
                clearTaxonFromSearch(removePanier, removeFilters);
            }
            // Add BBOX filter
            var extent = lizMap.map.getExtent().transform(OccTax.map.projection, 'EPSG:4326');
            var bbox = extent.toBBOX();
            self.find('input[name="extent"]').val(bbox);

            // Send request and get token
            $.post(self.attr('action'), self.serialize(),
                function (tData) {
                    blocme = false;
                    if (tData.status == 1) {
                        // Add parameters in URL
                        var query_string = updateUrlFromFormInput();

                        // Add bbox in the URL (not done before to not store it in the search history)
                        if (query_string) {
                            var bbox_param = 'bbox=' + lizMap.map.getExtent().toBBOX();
                            window.history.pushState('', '', query_string.trim('&') + '&' + bbox_param);
                        }

                        // Display description div
                        var dHtml = tData.description;
                        $('#occtax_search_description_content').html(dHtml);

                        // Store the search in the history
                        // Done after the occtax_search_description_content change
                        // because this text description is stored in the history item
                        storeCurrentSearch();

                        // Show or hide depending on dock height
                        var dockHeight = $('#dock').height();
                        if (dockHeight >= 800)
                            $('#occtax_search_description').show();
                        else
                            $('#occtax_search_description').hide();

                        // Show description title
                        $('#occtax_search_description').prev('h3.occtax_search').show();
                        $('#occtax-search-modify').show();
                        $('#occtax-search-replay').hide();
                        $('#occtax_search_observation_card').hide();

                        // Move legend to map
                        // First get which legend was selected
                        var selected_legend_button_id = $('#occtax_results_draw button.active').attr('id');
                        $('#map-content div.occtax-legend-container').remove();
                        // Add number of records in
                        // Hide or display legend and map maille toglle button depending on results
                        if (tData.recordsTotal > 0) {
                            $('#dock div.occtax-legend-container')
                                .appendTo($('#map-content'))
                                .show();
                            $('#occtax_toggle_map_display').show();
                            $('#occtax_observation_records_total').val(tData.recordsTotal);
                            // Afficher/masquer la légende
                            $('#occtax-legend-title').click(function () {
                                $('#occtax-legend-classes-container').toggle();
                                $('#occtax-legend-toggle').toggle();
                            });
                            $('#occtax-legend-toggle').click(function () {
                                $('#occtax-legend-classes-container').toggle();
                                $('#occtax-legend-toggle').toggle();
                            });
                        } else {
                            $('#dock div.occtax-legend-container').remove();
                            $('#occtax_toggle_map_display').hide();
                            $('#occtax_observation_records_total').val(0);
                        }

                        // Change wfs export URL
                        $('a#btn-get-wfs').attr('href', tData.wfsUrl);

                        // Hide form div
                        $('#occtax_search_input').hide();

                        // Run and display searched data
                        $('#occtax_service_search_stats_form input[name="token"]').val(tData.token).change();
                        $('#occtax_results_stats_table').DataTable().ajax.reload();
                        $('#occtax_service_search_taxon_form input[name="token"]').val(tData.token).change();
                        $('#occtax_results_taxon_table').DataTable().ajax.reload();

                        if ($('#occtax_results_draw_maille_m01.btn').length) {
                            $('#occtax_service_search_maille_form_m01 input[name="token"]').val(tData.token).change();
                            $('#occtax_results_maille_table_m01').DataTable().ajax.reload();
                        }
                        if ($('#occtax_results_draw_maille_m02.btn').length) {
                            $('#occtax_service_search_maille_form_m02 input[name="token"]').val(tData.token).change();
                            $('#occtax_results_maille_table_m02').DataTable().ajax.reload();
                        }
                        if ($('#occtax_results_draw_maille_m10.btn').length) {
                            $('#occtax_service_search_maille_form_m10 input[name="token"]').val(tData.token).change();
                            $('#occtax_results_maille_table_m10').DataTable().ajax.reload();
                        }
                        if ($('button.occtax_results_draw_observation.btn').length) {
                            $('#occtax_service_search_form input[name="token"]').val(tData.token).change();
                            $('#occtax_results_observation_table').DataTable().ajax.reload();
                        }

                        // Show result div
                        $('#occtax_search_result').show();
                        $('#occtax_search_result').prev('h3.occtax_search').show();
                        $('#occtax_result_button_bar').show();

                        // Hide observation card div and h3
                        $('#occtax_search_observation_card').prev('h3.occtax_search').hide();
                        $('#occtax_search_observation_card').hide();

                        // Refresh size
                        var mycontainer = '#occtax_results_stats_table_div';
                        refreshOcctaxDatatableSize(mycontainer);

                        // Click on the previous selected legend button
                        $('#' + selected_legend_button_id).click();

                    } else {
                        $('#occtax-highlight-message').remove();
                        $('#occtax-message').remove();
                        lizMap.addMessage(tData.msg.join('<br/>'), 'error', true).attr('id', 'occtax-highlight-message');
                    }

                    // Enable back the left panel
                    $('#occtax').removeClass('not_enabled');
                    $("#div_form_occtax_search_token form input[type=submit]").prop('disabled', false);

                }, 'json'
            );
            return false;
        });

        // Move spatial query buttons to WHERE group
        $('#' + tokenFormId + '_where').append($('#obs-spatial-query-buttons-container'));

        // Move taxon tabs to the top
        $('#' + tokenFormId).prepend($('#occtax_taxon_tab_div'));

        // Move taxon panier to the taxon main group
        $('#' + tokenFormId + '_main').append($('#occtax_taxon_select_div'));

        // Move taxon main group to the panier tab
        $('#recherche_taxon_panier').append($('#' + tokenFormId + '_main'));

        // Move taxon advanced filter to the attributes
        $('#recherche_taxon_attributs').append($('#' + tokenFormId + '_filter'));

        // Hide cd_nom
        $('#' + tokenFormId + '_cd_nom').parent('.controls').parent('.control-group').hide();
        //$('#'+tokenFormId+'_main .jforms-table-group .control-group:nth-last-child(-n+2)').hide();

        // Réinitialisation du formulaire
        function reinitSearchForm() {
            // Reinit taxon
            var removeTaxonPanier = true;
            var removeFilters = true;
            clearTaxonFromSearch(removeTaxonPanier, removeFilters);

            // Reinit other fields
            var tokenFormId = $('#div_form_occtax_search_token form').attr('id');
            $('#' + tokenFormId).trigger("reset");
            // sumoselect
            $('select.jforms-ctrl-listbox').each(function () {
                if ($(this).attr('id') != 'jforms_occtax_search_cd_nom') {
                    $(this)[0].sumo.unSelectAll();
                }
            });

            // Remove tokens
            // Needed so that depending buttons are deactivated
            $('#occtax_service_search_form input[name="token"]').val('');

            // Reinit date picker
            $('#' + tokenFormId + ' .ui-datepicker-reset').click();
        }


        // On supprime les géométries de recherche
        // On masque les résultats
        $('#' + tokenFormId + '_reinit').click(function () {
            // Reinit form input values
            reinitSearchForm();

            // Reinit spatial button
            clearSpatialSearch(true);
            OccTax.emptyDrawqueryLayer('queryLayer');

            // Reinit count
            $('#occtax_observation_records_total').val(0);

            // Reinit tables
            try {
                OccTax.events.triggerEvent('mailledatareceived_' + 'm01', { 'results': null });
                OccTax.events.triggerEvent('mailledatareceived_' + 'm02', { 'results': null });
                OccTax.events.triggerEvent('mailledatareceived_' + 'm10', { 'results': null });
                OccTax.events.triggerEvent('observationdatareceived', { 'results': null });
            } catch (e) {
                var myerror = e;
            }

            // Hide description, result and card panels
            $('#occtax_search_result, #occtax_search_description, #occtax_search_observation_card')
                .hide()
                .prev('h3.occtax_search').hide()
                ;

            // Cacher la barre d'outil pour les boutons
            $('#occtax_toggle_map_display').hide();

            // Masquer la légende
            $('#map-content div.occtax-legend-container').remove();

            // Remove URL parameters
            window.history.pushState('', '', '?bbox=' + lizMap.map.getExtent().toBBOX());

            return false;
        });




        // Add datatable tables
        // This does not get the data, which is done in the submit
        // of the form $('#div_form_occtax_search_token form').attr('id');
        // See ligne containing: $('#'+tokenFormId).submit(function(){
        addResultsStatsTable();
        addResultsTaxonTable();
        addResultsMailleTable('m01');
        addResultsMailleTable('m02');
        addResultsMailleTable('m10');
        addResultsObservationTable();

        // Initialize autocompletion
        initTaxonAutocomplete();

        // Replace taxon group values by values coherent with vm_obsevation.categorie
        // Insectes (papillons, mouches, abeilles) -> Insectes
        $('#jforms_occtax_search_group option').each(function () {
            var v = $(this).val();
            var vv = v.split(' ')[0];
            $(this).val(vv);
        });

        // Hide taxon checkboxes labels
        $('#jforms_occtax_search_taxons_locaux_label').hide();
        $('#jforms_occtax_search_taxons_bdd_label').hide();

        // Hide validation checkbox label
        $('#jforms_occtax_search_panier_validation_label').hide();

        // Boutons de changement de données affichées sur la carte
        $('#occtax_results_draw .btn').click(function () {
            var self = $(this);

            $('#occtax_results_draw .btn').removeClass('btn-primary');
            self.addClass('btn-primary');

            // Destroy previous content
            OccTax.emptyDrawqueryLayer('queryLayer');

            // Get layer to active and fill in
            var rLayer = OccTax.layers['mailleLayer'];
            var layer_type = 'maille';
            if (self.val() == 'observation') {
                rLayer = OccTax.layers['observationLayer'];
                layer_type = 'observation';
            }
            rLayer.destroyFeatures();

            // For observation, for testing purpose, get data everytime button is clicked
            // We need to get data and process it afterward by using the callback
            if (layer_type == 'observation') {
                // OBSERVATIONS
                observation_geometries_displayed = true;
                // Change style
                var observation_style = 'menace';
                if (self.hasClass('protection')) {
                    observation_style = 'protection';
                }
                if (self.hasClass('date')) {
                    observation_style = 'date';
                }
                OccTax.observation_style = observation_style;
                getObservationMapFeatures();
            } else {
                observation_geometries_displayed = false;
                // MAILLES

                // First add point features (centroids)
                OccTax.refreshFeatures(self.val());

                // Clone the features in a new object as we will modify the features by adding attributes
                // We need to add square features to draw the underlying maille
                //var sq_features = Object.assign({}, the_features);
                var sq_features = OccTax.getResultFeatures(self.val());
                if (sq_features) {
                    var square = 2000;
                    if (self.val() == 'm10') {
                        square = 10000;
                    }
                    if (self.val() == 'm01') {
                        square = 1000;
                    }
                    if (self.val() == 'm02') {
                        square = 2000;
                    }
                    if (self.val() == 'm05') {
                        square = 5000;
                    }

                    for (var i = 0, len = sq_features.length; i < len; i++) {
                        var f = sq_features[i];
                        f.fid += 'sq';
                        f.attributes.square = square;
                        f.attributes.color = '#ffffff';
                    }
                    rLayer.addFeatures(sq_features);
                }
            }

            // Enable left panel
            $('#occtax').removeClass('not_enabled');
            $("#div_form_occtax_search_token form input[type=submit]").prop('disabled', false);
            $('#occtax-message').remove();

            // Toggle the legend depending on the clicked button
            $('#map-content div.occtax-legend-container').toggle(true);
            $('div.occtax-legend-classes').toggle(false);
            var value = self.val();
            if (value == 'm01' || value == 'm02' || value == 'm10') {
                $('#occtax-legend-maille').toggle(true);
            } else {
                if (self.hasClass('menace')) {
                    $('#occtax-legend-observation-menace').toggle(true);
                }
                if (self.hasClass('protection')) {
                    $('#occtax-legend-observation-protection').toggle(true);
                }
                if (self.hasClass('date')) {
                    $('#occtax-legend-observation-date').toggle(true);
                }
            }
        });


        // Refresh datatable display ( set height used with scrollY )
        // When one of the result tabs is selected
        $('#occtax_results_tabs a').on('shown', function (e) {
            // Refresh datatable display ( set height used with scrollY )
            var container = $(e.target).attr('href');
            refreshOcctaxDatatableSize(container);

            return false;
        });

        // Zoom to data
        $('#occtax_results_zoom').click(function () {
            var rLayer = OccTax.layers['mailleLayer'];
            if (rLayer.features.length > 0) {
                OccTax.map.zoomToExtent(rLayer.getDataExtent());
            }
            //return False;
        });

        // Export des donnees
        $('#occtax_result_export_form').submit(function () {
            if (!uiprete) return false;

            var exportUrl = '';
            var eFormat = $('#export_format').val();
            // WFS
            if (eFormat == 'WFS') {
                exportUrl = $('a#btn-get-wfs').attr('href');
                $('#input-get-wfs')
                    .val(exportUrl)
                    .show()
                    .select()
                    ;
                lizMap.addMessage('Vous pouvez copier l\'url WFS correspondant à votre requête pour l\'utiliser dans votre SIG', 'info', true).attr('id', 'occtax-highlight-message');
            }
            // CSV or GeoJSON
            else {
                exportUrl += $('#' + tokenFormId).attr('action');
                if (eFormat == 'DEE') {
                    exportUrl = exportUrl.replace('service', 'export').replace('initSearch', 'init');
                }
                else if (eFormat == 'GeoJSON') {
                    exportUrl = exportUrl.replace('service', 'export').replace('initSearch', 'init');
                }
                else {
                    exportUrl = exportUrl.replace('service', 'export').replace('initSearch', 'init');
                }
                exportUrl += '?token=' + $('#occtax_service_search_stats_form input[name="token"]').val();
                exportUrl += '&format=' + eFormat;

                // Projection
                exportUrl += '&projection=' + $('#export_projection').val();
                window.open(exportUrl);
            }

            return false;
        })

        $('#export_format').change(function () {
            var isWFS = ($(this).val() == 'WFS');
            $('#input-get-wfs')
                .val('')
                .toggle(isWFS);
            if (isWFS) {
                $('#occtax_result_export_form').submit();
                return false;
            }
        })

        // Toggle search div via h3
        $('h3.occtax_search').click(function () {
            // Toggle next div visibility
            var ndiv = $(this).next('div:first');
            ndiv.toggle();

            // Reopen results & description
            // when observation car is hidden
            if (
                ndiv.attr('id') == 'occtax_search_observation_card'
                && !(ndiv.is(':visible'))
            ) {
                $('#occtax_search_result').show();
                $('#occtax_search_description').show();
            }

            // Hide observation card when other div is displayed
            if (
                ndiv.attr('id') != 'occtax_search_observation_card'
                && (ndiv.is(':visible'))
            ) {
                $('#occtax_search_observation_card').hide();
            }

            var tid = $('#occtax_search_result div.tab-pane.active').attr('id');

            // Refresh size of datatable table (for scrolling)
            refreshOcctaxDatatableSize('#' + tid);
        });


        // Clear Taxon search with button
        $('#clearTaxonSearch').hide(); // Hide this useless button to remove them all
        $('#clearTaxonSearch').click(function () {
            var removePanier = true;
            var removeFilters = false;
            clearTaxonFromSearch(removePanier, removeFilters);
            return false;
        });

        // Hide taxon menu icon in menubar
        $('#button-taxon').parent('li.taxon').hide();

        // Masquer le metadata
        $('#mapmenu li.metadata').hide();

        // Masquer le permalien, car repris automatiquemen
        $('#mapmenu li.permaLink').hide();

        // Déplacement des icônes Lizmap de la barre de menu de gauche
        moveLizmapMenuLi(occtaxClientConfig.menuOrder);

        // Modification du mot "Rechercher"
        $('#search-query').attr('placeholder', 'Rechercher un lieu');

        // Ajout de sumoselect pour les listes déroulantes multiples
        $('#occtax select.jforms-ctrl-listbox').SumoSelect(
            {
                placeholder: 'Saisir/Choisir dans la liste',
                captionFormat: '{0} sélectionnés',
                captionFormatAllSelected: '{0} tout est sélectionné !',
                okCancelInMulti: false,
                isClickAwayOk: true,
                //selectAll: true, // disabled because of bad perf
                search: true,
                searchText: 'Recherche...',
                noMatch: 'Pas de correspondance pour "{0}"',
                locale: ['OK', 'Annuler', 'Tous']
            }
        );

        // On replie les couches
        $('#layers-fold-all').click();

        // TOOLTIPS
        // Ajout des tooltip sur les boutons
        $('#occtax button').tooltip();
        // Ajout sur les inputs de formulaire
        $('#jforms_occtax_search select, #jforms_occtax_search input, #jforms_occtax_search  checkbox, #jforms_occtax_search label').tooltip();
        // Onglets de résultat
        //$('#occtax_results_tabs > li > a').tooltip();
        //désactivé car entraîne le changement des données affichées sur la carte

        // Déplacement de la barre de modification de l'affichage
        $('#occtax_toggle_map_display')
            .appendTo($('#map-content'))
            .hide()
            ;

        // Ajout de la classe btn-primary sur les boutons du formulaire
        $('div.jforms-submit-buttons button.jforms-reset').addClass('btn').addClass('btn-primary');
        $('div.jforms-submit-buttons input.jforms-submit').addClass('btn').addClass('btn-primary');

        // Refresh bbox in URL
        lizMap.map.events.on({
            moveend: function (evt) {
                // Refresh URL
                var query_string = window.location.search;
                var params = new URLSearchParams(query_string);
                var new_bbox = lizMap.map.getExtent().toBBOX();
                params.set('bbox', new_bbox);
                window.history.replaceState({}, '', `${location.pathname}?${params}`);
                // Refresh observation geometries if displayed
                if (observation_geometries_displayed) {
                    getObservationMapFeatures();
                }
            }
        });

        // Get URL parameters, set form inputs and submit search form
        var query_string = window.location.search;
        if (query_string && query_string != '') {
            updateFormInputsFromUrl(query_string);
        }

    }
});
