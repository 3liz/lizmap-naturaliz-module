var uiprete = false;
var blocme = true;
var error_connection = false;

function unblockSearchForm(){
    uiprete = true;
    blocme = false;
    $("#div_form_occtax_search_token form input[type=submit]").prop('disabled', false);
}

function blockSearchForm(){
    // hide search form
    $("#div_form_occtax_search_token form input[type=submit]").prop('disabled', true);
    // Block search form
    var tokenFormId = $('#div_form_occtax_search_token form').attr('id');
    $('#'+tokenFormId).submit(function(){
        if(!uiprete) return false;
    })
};

$( document ).ready(function() {
  blockSearchForm();
});


OccTax.events.on({
    'uicreated':function(evt){

    function checkConnection(){
        // If the user was not connected, no souci
        if (!(occtaxClientConfig.is_connected)) {
            return true;
        }

        // If the user was connected, check if it is still connected
        var tokenFormId = $('#div_form_occtax_search_token form').attr('id');
        var url = $('#'+tokenFormId).attr('action').replace('initSearch', 'isConnected');
        $.getJSON(url, null, function( cdata ) {
            if ( !(cdata.is_connected) ) {
                var baseUrl = window.location.protocol + '//' + document.domain + lizUrls.basepath;
                var url_return = '%2Findex.php%2Focctax%2F';
                url_return+= encodeURIComponent(window.location.search);
                var loginurl = baseUrl + 'admin.php/auth/login/?auth_url_return=' + url_return;
                if( !error_connection ) {
                    if(!alert('Votre session a expiré ! La page va être rechargée.')){
                        error_connection = true;
                        window.location = loginurl;
                    }
                }else{
                    window.location = loginurl;
                }
                return false;
            }
        });
        return true;
    }

    function getDatatableColumns( tableId ){
      var DT_Columns = $('#'+tableId+' thead tr th').map(
        function(){
          var dv = $(this).attr('data-value');
          var sp = dv.split(',');
          var ret = {
            'data': sp[0],
            'type': sp[1],
            'sortable': (sp[2] == 'true')
          }
          if(sp.length == 4){
            ret['className'] = sp[3];
          }
          return ret;
        }
      ).get();
      var displayFields = [];
      for(v in DT_Columns) {
        displayFields.push( DT_Columns[v]["data"] );
      }
      return [DT_Columns, displayFields];
    }

    function onQueryFeatureAdded( feature, callback ) {

        checkConnection();

        /**
         * Initialisation
         */
        //mascarineService.emptyMessage();
        OccTax.emptyDrawqueryLayer('queryLayer'); // needed to be sure that the modify feature tool is ok for the first run
        OccTax.deactivateAllDrawqueryControl();

        var theLayer = feature.layer;
        var activeButton = $('#obs-spatial-query-buttons button.active');
        var activeValue = activeButton.attr('data-value');

        /**
         * @todo Ne gère que si il ya a seulement 1 géométrie
         */
        if( feature.layer ) {
            if(feature.layer.features.length > 1) {
                feature.layer.destroyFeatures( feature.layer.features.shift() );
            }
        }

       /**
        * Activation du bouton pour le controle de navigation
        */
        if ( activeValue == 'queryPolygon' || activeValue == 'importPolygon' )
              $('#obs-spatial-query-modify').show();

        if (feature.geometry.CLASS_NAME === 'OpenLayers.Geometry.Polygon'
          || feature.geometry.CLASS_NAME === 'OpenLayers.Geometry.MultiPolygon'
        ) {
            // L'aire doit être inférieure à une certaine valeur
            // il faut donc la valider
            OccTax.validGeometryFeature( feature );
            theLayer.drawFeature( feature );
            var geom = feature.geometry.clone().transform( OccTax.map.projection, 'EPSG:4326' );

            $('#jforms_occtax_search_geom').val( geom.toString() );
            $('#jforms_occtax_search_code_commune').val('');
            $('#jforms_occtax_search_code_masse_eau').val('');
            $('#jforms_occtax_search_code_maille').val('');
            $('#jforms_occtax_search_type_maille').val('');
        } else {
            // query geom
            if (feature.geometry.CLASS_NAME === 'OpenLayers.Geometry.Point') {
                var myPoint = feature.geometry.clone().transform( OccTax.map.projection, 'EPSG:4326' );
                //console.log( myPoint.x, myPoint.y );
                if ( activeButton.hasClass('maille') ) {
                    var form = $('#form_occtax_service_maille');
                    var type_maille = 'm02';
                    if(activeButton.hasClass('m01')){
                      type_maille = 'm01';
                    }
                    //if(activeButton.hasClass('m05')){
                      //type_maille = 'm05';
                    //}
                    if(activeButton.hasClass('m10')){
                      type_maille = 'm10';
                    }
                    $.post(form.attr('action')
                      ,{x:myPoint.x, y:myPoint.y, type_maille: type_maille}
                      , function( data ) {
                          if ( data.status == 1 ) {
                              var format = new OpenLayers.Format.GeoJSON();
                              var geom = format.read( data.result.geojson )[0].geometry;
                              $('#jforms_occtax_search_geom').val( geom.toString() );
                              $('#jforms_occtax_search_code_commune').val('');
                              $('#jforms_occtax_search_code_masse_eau').val('');
                              $('#jforms_occtax_search_code_maille').val( data.result.code_maille );
                              $('#jforms_occtax_search_type_maille').val( type_maille );
                              theLayer.destroyFeatures(feature);
                              geom.transform('EPSG:4326', OccTax.map.projection);
                              theLayer.addFeatures( [new OpenLayers.Feature.Vector( geom)] );
                              if ( callback )
                                callback();
                          } else {
                            theLayer.destroyFeatures();
                            if ( data.msg.length != 0 )
                              lizMap.addMessage( data.msg.join('<br/>'), 'error', true ).attr('id','occtax-highlight-message');
                            else
                              lizMap.addMessage( 'Error', 'error', true ).attr('id','occtax-highlight-message');
                            //~ console.log(data);
                          }
                      });
                } else if ( activeButton.hasClass('commune') ) {
                    var form = $('#form_occtax_service_commune');
                    $.post(form.attr('action')
                      ,{x:myPoint.x, y:myPoint.y}
                      , function( data ) {
                          if ( data.status == 1 ) {
                              var format = new OpenLayers.Format.GeoJSON();
                              var geom = format.read( data.result.geojson )[0].geometry;
                              $('#jforms_occtax_search_geom').val( '' );
                              $('#jforms_occtax_search_code_commune').val( data.result.code_commune );
                              $('#jforms_occtax_search_code_masse_eau').val('');
                              $('#jforms_occtax_search_code_maille').val( '' );
                              $('#jforms_occtax_search_type_maille').val( '' );
                              theLayer.destroyFeatures(feature);
                              geom.transform('EPSG:4326', OccTax.map.projection);
                              theLayer.addFeatures( [new OpenLayers.Feature.Vector( geom)] );
                              if ( callback )
                                callback();
                          } else {
                            theLayer.destroyFeatures();
                            if ( data.msg.length != 0 )
                              lizMap.addMessage( data.msg.join('<br/>'), 'error', true ).attr('id','occtax-highlight-message');
                            else
                              lizMap.addMessage( 'Error', 'error', true ).attr('id','occtax-highlight-message');
                            //~ console.log(data);
                          }
                      });
                } else if ( activeButton.hasClass('masse_eau') ) {
                    var form = $('#form_occtax_service_masse_eau');
                    $.post(form.attr('action')
                      ,{x:myPoint.x, y:myPoint.y}
                      , function( data ) {
                          if ( data.status == 1 ) {
                              var format = new OpenLayers.Format.GeoJSON();
                              var geom = format.read( data.result.geojson )[0].geometry;
                              $('#jforms_occtax_search_geom').val( '' );
                              $('#jforms_occtax_search_code_commune').val( '' );
                              $('#jforms_occtax_search_code_masse_eau').val( data.result.code_me );
                              $('#jforms_occtax_search_code_maille').val( '' );
                              $('#jforms_occtax_search_type_maille').val( '' );
                              theLayer.destroyFeatures(feature);
                              geom.transform('EPSG:4326', OccTax.map.projection);
                              theLayer.addFeatures( [new OpenLayers.Feature.Vector( geom)] );
                              if ( callback )
                                callback();
                          } else {
                            theLayer.destroyFeatures();
                            if ( data.msg.length != 0 )
                              lizMap.addMessage( data.msg.join('<br/>'), 'error', true ).attr('id','occtax-highlight-message');
                            else
                              lizMap.addMessage( 'Error', 'error', true ).attr('id','occtax-highlight-message');
                            //~ console.log(data);
                          }
                      });
                }
            }
        }
        // On decheck le bouton de controle enfoncé
        $('#obs-spatial-query-buttons button').removeClass('active');
    }

    function onQueryFeatureModified( evt ) {
        var button = $('#obs-spatial-query-modify');
        if ( button.hasClass('active') ) {
            var geom = evt.feature.geometry.clone().transform( OccTax.map.projection, 'EPSG:4326' );
            $('#jforms_occtax_search_geom').val( geom.toString() );
            $('#jforms_occtax_search_code_commune').val('');
            $('#jforms_occtax_search_code_masse_eau').val('');
            $('#jforms_occtax_search_code_maille').val('');
            $('#jforms_occtax_search_type_maille').val('');
        }
    }

    function addTaxonToSearch( cd_nom, nom_cite ) {
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
        if ( selectVals == null )
            selectVals = [];

        // Ajout d'un item au panier
        if ( selectVals.indexOf( cd_nom ) == -1 ) {
            // Add cd_nom in hidden form input
            ctrl_cd_nom.append('<option selected value="'+cd_nom+'">'+nom_cite+'</option>');

            // Add card in the interface
            var licontent = '<li data-value="';
            licontent+= cd_nom;
            licontent+= '" style="height:20px; margin-left:2px;">';
            licontent+= '<span title="Cliquer pour visualiser la fiche taxon">';
            licontent+= nom_cite;
            licontent+= '</span>';
            licontent+= '<button type="button" class="detail" value="'+cd_nom+'" style="display:none;" >détail</button>';
            licontent+= '<button type="button" class="close" value="'+cd_nom+'" aria-hidden="true" title="Supprimer de la sélection">&times;</button>';
            licontent+= '</li>';
            var li = $(licontent);

            $('#occtax_taxon_select_list').append(li);
            li.find('.close').click(function(){
                deleteTaxonToSearch( $(this).attr('value') );
                //return false;
            });
            li.find('span').click(function(){
                var cd_nom = $(this).parent().find('button.detail').attr('value');
                displayTaxonDetail(cd_nom);
                //return false;
            });

        }

    }

    function getTaxonDataFromApi(cd_nom, aCallback){

      var turl = 'https://taxref.mnhn.fr/api/taxa/';
      turl+= cd_nom;

      $.getJSON(turl, null, function( tdata ) {
        var keys = ['id', 'referenceId', 'scientificName', 'authority', 'frenchVernacularName'];
        var rdata = {};
        for(var k in keys){
          rdata[keys[k]] = tdata[keys[k]];
        }
        if('_links' in tdata){
          rdata['inpnWebpage'] = tdata._links.inpnWebpage.href;
        }
        rdata['media_url'] = null;
        rdata['status_url'] = null;

        // media
        if(
          '_links' in tdata
          && 'media' in tdata._links
        ){
          var murl = tdata._links.media.href;
          rdata['media_url'] = murl;
        }
        // status
        if(
          '_links' in tdata
          && 'status' in tdata._links
        ){
          var surl = tdata._links.status.href;
          rdata['status_url'] = surl;
        }
        aCallback(rdata);
      });
    }

    function detailTaxonLoad(url) {
      return new Promise(function(resolve, reject) {
        var request = new XMLHttpRequest();
        request.open('GET', url);
        request.responseType = 'json';
        // When the request loads, check whether it was successful
        request.onload = function() {
          if (request.status === 200) {
          // If successful, resolve the promise by passing back the request response
            resolve(request.response);
          } else {
          // If it fails, reject the promise with a error message
            reject(Error('URL did not load successfully; error code:' + request.statusText));
          }
        };
        request.onerror = function() {
            reject(Error('There was a network error.'));
        };
        // Send the request
        request.send();
      });
    }

    function buildTaxonFicheHtml(data){
        var html = '';
        html+= '<h3><span class="title"><span class="text">Information</span>';

        // Close button
        html+= '<button id="taxon-detail-close" class="btn btn-primary btn-mini pull-right" style="margin-left:10px;">Fermer</button>';

        // Taxon detail URL button
        var detail_url = data.inpnWebpage;
        var config_url = occtaxClientConfig.taxon_detail_source_url;
        if (config_url && config_url.trim() != '') {
            detail_url = config_url.replace('CD_NOM', data.referenceId);
        }
        html+= '<a href="';
        html+= detail_url;
        html+= '" class="btn btn-primary btn-mini pull-right" target="_blank">Voir la fiche complète</a>';
        html+= '</span>';
        html+= '</h3>';
        html+= '<div id="taxon-detail-container" class="menu-content">';
        html+= '<h4><b>';
        html+= data.scientificName;
        html+= '</b> ';
        html+= data.authority;
        html+= '</h4>';
        var wait_html = '';
        wait_html+= '  <div class="dataviz-waiter progress progress-striped active" style="margin:5px 5px;">';
        wait_html+= '    <div class="bar" style="width: 100%;"></div>';
        wait_html+= '  </div>';
        if (data.frenchVernacularName !== null) {
            html+= '<p>';
            html+= data.frenchVernacularName;
            html+= '</p>';
        }
        // Image
        if (data.media_url !== null) {
            html+= '<div id="taxon-detail-media">';
            html+= wait_html;
            html+= '</div>';
        }
        // Statuts de protection
        if (data.status_url !== null) {
            html+= '<div id="taxon-detail-status">';
            html+= wait_html;
            html+= '</div>';
        }
        html+= '</div>';

        return html;
    };

    function getTaxonMedia(media_url) {
      detailTaxonLoad(media_url).then(function(mdata) {
        if (
          '_embedded' in mdata
          && 'media' in mdata._embedded
          && mdata._embedded.media.length > 0
        ){
          var media_href = mdata._embedded.media[0]._links.thumbnailFile.href;
          var html = '';
          html+= '<img src="';
          html+= media_href;
          html+= '" width="100%">';
          $('#taxon-detail-media div.dataviz-waiter').hide();
          $('#taxon-detail-media').html(html);
        } else {
          $('#taxon-detail-media div.dataviz-waiter').hide();
        }
      }, function(Error) {
        console.log(Error);
        $('#taxon-detail-media div.dataviz-waiter').hide();
      });
    }

    function getTaxonStatus(status_url) {
      detailTaxonLoad(status_url).then(function(mdata) {
        if(
          '_embedded' in mdata
          && 'status' in mdata._embedded
          && mdata._embedded.status.length > 0
        ){
          let colonne_locale_labels = {
            'gua': ['Guadeloupe'],
            'fra': ['France métropolitaine','France'],
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
                html+= '<li>';
                html+= '<b>'+status.statusTypeGroup + '</b>: ';
                html+= '<span ' + st_title + st_cursor + '>' + status.statusName + '</span>';
                html+= '<i> (' + status.locationName +')</i>';
                html+= '</li>';
                html+= '';
              }
            }
          }
          html+= '</ul>';
          $('#taxon-detail-status div.dataviz-waiter').hide();
          $('#taxon-detail-status').html(html);

        } else {
          $('#taxon-detail-status div.dataviz-waiter').hide();
        }
      }, function(Error) {
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
      if( $('#content').hasClass('embed') )
          right+= 11;
      else if( $('#dock').css('display') != 'none' && !lizMap.checkMobile() )
          right+= $('#dock').width() + 11;
      return right;
    }


    function displayTaxonDetail(cd_nom){
        // Depending on the source, we must
        // API: "api" -> get data from MNHN API and display in subdock
        // URL: "https://some_url/cd_nom" -> open in a new tab after having replace cd_nom
        var dtype = occtaxClientConfig.taxon_detail_source_type;
        var durl = occtaxClientConfig.taxon_detail_source_url;
        if (dtype == 'api' || durl.trim() == '') {
          // Use the MNHN API to create and display a fact sheet about this taxon
          getTaxonDataFromApi(cd_nom, function(data){
              var html = buildTaxonFicheHtml(data);
              html+=  '<button id="hide-sub-dock" class="btn pull-right" style="margin-top:5px;" name="close" title="'+lizDict['generic.btn.close.title']+'">'+lizDict['generic.btn.close.title']+'</button>';
              $('#sub-dock').html(html)
              .css('bottom', '0px');
              if( !lizMap.checkMobile() ){
                  var leftPos = getDockRightPosition();
                  $('#sub-dock').css('left', leftPos).css('width', leftPos);
              }
              // Hide lizmap close button (replaced further)
              $('#hide-sub-dock').click(function(){
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
              $('#taxon-detail-close').click(function(){$('#hide-sub-dock').click();})

              $('#sub-dock').show();

          })
        } else {
          // Directly open external URL in a new tab/window
          var url = durl.replace('CD_NOM', cd_nom);
          window.open(url, '_blank');
        }
    }

    function deleteTaxonToSearch( cd_nom ) {
      $('#div_form_occtax_search_token form [name="cd_nom[]"] option[value="'+cd_nom+'"]').remove();
      var li = $('#occtax_taxon_select_list li[data-value="'+cd_nom+'"]');
      li.find('.close').unbind('click');
      li.remove();
      if($('#occtax_taxon_select_list li').length == 0){
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
        $('#'+formId+' input[name="autocomplete"]').val('');
      }
      // Critères de recherche
      if (removeFilters) {
        // Remove data from taxon inputs
        $('#'+formId+'_filter select option').prop('selected', function() {
          return this.defaultSelected;
        });
        // sumoselect specific of taxon filter tab
        $('#'+formId+'_filter select.jforms-ctrl-listbox').each(function(){
            if ($(this).attr('id') != 'jforms_occtax_search_cd_nom') {
                $(this)[0].sumo.unSelectAll();
            }
        });
      }

    }

    function addResultsStatsTable() {
      var tableId = 'occtax_results_stats_table';
      // Get statistics
      var returnFields = $('#'+tableId+'').attr('data-value').split(',');
      var DT_RowId = $('#'+tableId+' thead tr').attr('data-value');
      var datatableColumns = getDatatableColumns( tableId );
      var DT_Columns = datatableColumns[0];
      var displayFields = datatableColumns[1];
      $('#'+tableId+'').DataTable( {
            "lengthChange": false,
            "searching": false,
            "dom":'ipt',
            //"pageLength":50,
            "paging": false,
            "deferRender": true,
            "scrollY": '100%',
            "scrollX": '95%',
            "language": {url: jFormsJQ.config.basePath + lizUrls["dataTableLanguage"]},
            "oLanguage": {
              "sInfoEmpty": "",
              "sEmptyTable": "Aucun résultat",
              "sInfo": "Affichage des groupes _START_ à _END_ sur _TOTAL_ groupes taxonomiques",
              "oPaginate" : {
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
                if(!mytoken)
                  return false;
                $.post(searchForm.attr('action'), searchForm.serialize(),
                    function( results ) {
                          var tData = {
                            "recordsTotal": 0,
                            "recordsFiltered": 0,
                            "data": []
                          };
                          if ( results.status = 1 ) {
                            tData.recordsTotal = results.recordsTotal;
                            tData.recordsFiltered = results.recordsFiltered;

                            for( var i=0, len=results.data.length; i<len; i++ ) {

                              // Add data to table
                              var r = {};
                              var d = results.data[i];
                              r['DT_RowId'] = d[ returnFields.indexOf( DT_RowId ) ];
                              for( var j=0, jlen = displayFields.length; j < jlen; j++ ) {
                                var f = displayFields[j];
                                r[ f ] = d[ returnFields.indexOf( f ) ];
                              }
                              tData.data.push( r );
                            }

                          } else {
                              if ( results.msg.length != 0 )
                                lizMap.addMessage( results.msg.join('<br/>'), 'error', true ).attr('id','occtax-highlight-message');
                              else
                                lizMap.addMessage( 'Error', 'error', true ).attr('id','occtax-highlight-message');
                          }
                          refreshOcctaxDatatableSize('#occtax_results_stats_table_div');
                          callback( tData );
                          $('#'+tableId+'').show();

                    }
                , 'json');
            }
        });
    }

    function addResultsTaxonTable() {
      var tableId = 'occtax_results_taxon_table';
      // Get taxon fields to display
      var returnFields = $('#'+tableId+'').attr('data-value').split(',');
      var DT_RowId = $('#'+tableId+' thead tr').attr('data-value');
      var datatableColumns = getDatatableColumns( tableId );
      var DT_Columns = datatableColumns[0];
      var displayFields = datatableColumns[1];
      $('#'+tableId+'').DataTable( {
            "lengthChange": false,
            "pageLength":100,
            "paging": true,
            "deferRender": true,
            "scrollY": '100%',
            "scrollX": '95%',
            //"searching": true,
            "searching": false,
            "dom":'ipft',
            "language": {url: jFormsJQ.config.basePath +  lizUrls["dataTableLanguage"]},
            "oLanguage": {
              "sInfoEmpty": "",
              "sEmptyTable": "Aucun résultat",
              "sInfo": "Affichage des taxons _START_ à _END_ sur _TOTAL_ taxons",
              "oPaginate" : {
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
                if(!mytoken)
                  return false;
                $.post(searchForm.attr('action'), searchForm.serialize(),
                    function( results ) {
                          var tData = {
                            "recordsTotal": 0,
                            "recordsFiltered": 0,
                            "data": []
                          };
                          if ( results.status = 1 ) {
                            tData.recordsTotal = results.recordsTotal;
                            tData.recordsFiltered = results.recordsFiltered;

                            for( var i=0, len=results.data.length; i<len; i++ ) {

                              // Add data to table
                              var r = {};
                              var d = results.data[i];
                              r['DT_RowId'] = d[ returnFields.indexOf( DT_RowId ) ];
                              for( var j=0, jlen = displayFields.length; j < jlen; j++ ) {
                                var f = displayFields[j];
                                r[ f ] = d[ returnFields.indexOf( f ) ];
                              }
                              tData.data.push( r );
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
                            if ( results.msg.length != 0 )
                                lizMap.addMessage( results.msg.join('<br/>'), 'error', true ).attr('id','occtax-highlight-message');
                            else
                                lizMap.addMessage( 'Error', 'error', true ).attr('id','occtax-highlight-message');
                          }
                          refreshOcctaxDatatableSize('#occtax_results_taxon_table_div');

                          callback( tData );
                          $('#'+tableId+'').show();
                    }
                , 'json');
            }
        });
        $('#'+tableId+'').on( 'page.dt', function() {
          $('#'+tableId+' a').unbind('click');
        });
        $('#'+tableId+'').on( 'draw.dt', function() {
          $('#'+tableId+' a.filterByTaxon').click(function(){
              var tr = $($(this).parents('tr')[0]);
              var d = $('#'+tableId+'').DataTable().row( tr ).data();
              var cd_nom = tr.attr('id');
              //console.log( cd_nom );
              var row_label = $('#'+tableId+' thead tr th.row-label').attr('data-value');
              row_label = row_label.split(',')[0];

              // Remove previous taxon searches
              var removePanier = true;
              var removeFilters = true;
              clearTaxonFromSearch(removePanier, removeFilters);
              // console.log( cd_nom, d[row_label] );

              // Add new taxon to search
              addTaxonToSearch( cd_nom, d[row_label] );
              $('#div_form_occtax_search_token form').submit();
              return false;
          });
          $('#'+tableId+' a.getTaxonDetail').click(function(){
              var tr = $($(this).parents('tr')[0]);
              var d = $('#'+tableId+'').DataTable().row( tr ).data();
              var cd_nom = tr.attr('id');
              displayTaxonDetail(cd_nom);
              return false;
          });
          // Replace taxon nomenclature key by values
          $('#'+tableId+' span.redlist_regionale').each(function(){
            replaceKeyByLabelFromNomenclature($(this), 'menace_regionale');
          });
          $('#'+tableId+' span.redlist_nationale').each(function(){
            replaceKeyByLabelFromNomenclature($(this), 'menace_nationale');
          });
          $('#'+tableId+' span.redlist_monde').each(function(){
            replaceKeyByLabelFromNomenclature($(this), 'menace_monde');
          });
          $('#'+tableId+' span.protectionlist').each(function(){
            replaceKeyByLabelFromNomenclature($(this), 'protection');
          });
        });
    }

    function replaceKeyByLabelFromNomenclature(span, target_field) {
        for(var key in t_nomenclature) {
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
      if($('#'+tableId+'').length == 0){
        return false;
      }
      // Get maille fields to display
      var returnFields = $('#'+tableId+'').attr('data-value').split(',');
      var DT_RowId = $('#'+tableId+' thead tr').attr('data-value');
      var datatableColumns = getDatatableColumns( tableId );
      var DT_Columns = datatableColumns[0];
      var displayFields = datatableColumns[1];
      $('#'+tableId+'').DataTable( {
            "lengthChange": false,
            "searching": false,
            "dom":'ipft',
            //"pageLength":50,
            "paging": false,
            "deferRender": true,
            "scrollY": '100%',
            "scrollX": '95%',
            "language": {url: jFormsJQ.config.basePath +  lizUrls["dataTableLanguage"]},
            "oLanguage": {
              "sInfoEmpty": "",
              "sEmptyTable": "Aucun résultat",
              "sInfo": "Affichage des mailles _START_ à _END_ sur _TOTAL_ mailles",
              "oPaginate" : {
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
                if(!mytoken)
                  return false;
                $.post(searchForm.attr('action'), searchForm.serialize(),
                    function( results ) {
                          var tData = {
                            "recordsTotal": 0,
                            "recordsFiltered": 0,
                            "data": []
                          };
                          if ( results.status = 1 ) {
                            tData.recordsTotal = results.recordsTotal;
                            tData.recordsFiltered = results.recordsFiltered;

                            // Trigger event that a new result has come
                            OccTax.events.triggerEvent('mailledatareceived_'+type_maille, {'results':results});
                            for( var i=0, len=results.data.length; i<len; i++ ) {

                              // Add data to table
                              var r = {};
                              var d = results.data[i];
                              r['DT_RowId'] = d[ returnFields.indexOf( DT_RowId ) ];
                              for( var j=0, jlen = displayFields.length; j < jlen; j++ ) {
                                var f = displayFields[j];
                                r[ f ] = d[ returnFields.indexOf( f ) ];
                              }
                              tData.data.push( r );
                            }
                          } else {
                            if ( results.msg.length != 0 )
                                lizMap.addMessage( results.msg.join('<br/>'), 'error', true ).attr('id','occtax-highlight-message');
                            else
                                lizMap.addMessage( 'Error', 'error', true ).attr('id','occtax-highlight-message');
                          }
                          $('#'+tableId+' a').unbind('click');
                          callback( tData );
                          refreshOcctaxDatatableSize('#occtax_results_maille_table_div_'+type_maille);

                          // Refresh maille on map
                          // usefull to refresh map features
                          var mclick = false;
                          if($('#occtax_results_draw_maille_m01.btn').length){
                            $('#occtax_results_draw_maille_m01.btn').click();
                            mclick = true;
                          }
                          if(!mclick && $('#occtax_results_draw_maille_m02.btn').length){
                            $('#occtax_results_draw_maille_m02.btn').click();
                            mclick = true;
                          }

                          $('#'+tableId+'').show();


                    }
                , 'json');
            }
        });
        $('#'+tableId+'').on( 'page.dt', function() {
          $('#'+tableId+' a').unbind('click');
          $('#'+tableId+' tbody tr').unbind('hover');
        });
        $('#'+tableId+'').on( 'draw.dt', function() {
          $('#'+tableId+' a.filterByMaille').click(function(){
              var tr = $($(this).parents('tr')[0]);
              var d = $('#'+tableId+'').DataTable().row( tr ).data();
              var mId = tr.attr('id');
              //var maille = OccTax.getMaille( mId );
              var maille = OccTax.layers.resultLayer.getFeatureByFid(mId);
              $('#obs-spatial-query-maille-' + type_maille).click();
              var mailleSelect = maille.clone();
              OccTax.layers['queryLayer'].addFeatures([mailleSelect]);
              onQueryFeatureAdded( mailleSelect, function() {
                $('#div_form_occtax_search_token form').submit();
              });
              //return false;
          });
          $('#'+tableId+' tbody tr').hover(function(){
              var tr = $(this);
              var mId = tr.attr('id');
              var maille = OccTax.layers.resultLayer.getFeatureByFid(mId);
              OccTax.controls['select']['highlightCtrl'].highlight( maille  );
          },function(){
              var tr = $(this);
              var mId = tr.attr('id');
              var maille = OccTax.layers.resultLayer.getFeatureByFid(mId);
              OccTax.controls['select']['highlightCtrl'].unhighlight( maille );
          });

        });
    }

    function addResultsObservationTable() {
      var tableId = 'occtax_results_observation_table';
      // Get fields to display
      var table = $('#'+tableId+'');
      if( table.length == 0 )
        return;
      var returnFields = table.attr('data-value').split(',');
      var DT_RowId = $('#'+tableId+' thead tr').attr('data-value');
      var datatableColumns = getDatatableColumns( tableId );
      var DT_Columns = datatableColumns[0];
      var displayFields = datatableColumns[1];
      // Display data via datatable
      $('#'+tableId+'').DataTable( {
            "lengthChange": false,
            "pageLength":100,
            "paging": true,
            "deferRender": true,
            "scrollY": '100%',
            "scrollX": '95%',
            "searching": false,
            "dom":'ipt',
            "language": {url:jFormsJQ.config.basePath + lizUrls["dataTableLanguage"]},
            "oLanguage": {
              "sInfoEmpty": "",
              "sEmptyTable": "Aucun résultat",
              "sInfo": "Affichage des observations _START_ à _END_ sur _TOTAL_ observations",
              "oPaginate" : {
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
              //console.log( param );
              searchForm.find('input[name="limit"]').val(param.length);
              searchForm.find('input[name="offset"]').val(param.start);
              searchForm.find('input[name="group"]').val('');
              searchForm.find('input[name="order"]').val(
                DT_Columns[param.order[0]['column']]['data'] + ':' + param.order[0]['dir']
              );

              // Do not run the query if no token has been found
              var mytoken = searchForm.find('input[name="token"]').val();
              if(!mytoken)
                return false;
              $.post(searchForm.attr('action'), searchForm.serialize(),
                function( results ) {
                  //console.log( results );
                  var tData = {
                    "recordsTotal": 0,
                    "recordsFiltered": 0,
                    "data": []
                  };
                  if ( results.status = 1 ) {
                    tData.recordsTotal = results.recordsTotal;
                    tData.recordsFiltered = results.recordsFiltered;

                    // Trigger event that a new result has come
                    OccTax.events.triggerEvent('observationdatareceived', {'results':results});

                    for( var i=0, len=results.data.length; i<len; i++ ) {

                      // Add data to table
                      var r = {};
                      var d = results.data[i];
                      r['DT_RowId'] = d[ returnFields.indexOf( DT_RowId ) ];
                      for( var j=0, jlen = displayFields.length; j < jlen; j++ ) {
                        var f = displayFields[j];
                        r[ f ] = d[ returnFields.indexOf( f ) ];
                      }
                      tData.data.push( r );
                    }
                  } else {
                    if ( results.msg.length != 0 )
                        lizMap.addMessage( results.msg.join('<br/>'), 'error', true ).attr('id','occtax-highlight-message');
                    else
                        lizMap.addMessage( 'Error', 'error', true ).attr('id','occtax-highlight-message');
                  }
                  callback( tData );
                  if ( $('#occtax_results_draw_observation').hasClass('active') )
                    $('#occtax_results_draw_observation').click();

                  refreshOcctaxDatatableSize('#occtax_results_observation_table_div');
                  $('#'+tableId+'').show();
                }, 'json');
            }
        });
        $('#'+tableId+'').on( 'page.dt', function() {
          $('#'+tableId+' tbody tr').unbind('hover');
          $('#'+tableId+' a').unbind('click');
        });
        $('#'+tableId+'').on( 'draw.dt', function() {
          $('#'+tableId+' tbody tr').hover(function(){
              var tr = $(this);
              var obsId = tr.attr('id');
              var obs = OccTax.layers.resultLayer.getFeatureByFid(obsId);
              if( obs )
                OccTax.controls['select']['highlightCtrl'].highlight( obs );
          },function(){
              var tr = $(this);
              var obsId = tr.attr('id');
              var obs = OccTax.layers.resultLayer.getFeatureByFid(obsId);
              if( obs )
                OccTax.controls['select']['highlightCtrl'].unhighlight( obs );
          });
          // Open observation detail
          $('#'+tableId+' a.openObservation').click(function(){
              var tr = $($(this).parents('tr')[0]);
              var d = $('#'+tableId+'').DataTable().row( tr ).data();
              var identifiant_permanent = d['DT_RowId'];
              getObservationDetail( identifiant_permanent );
              return false;
          });
          // Zoom to observation
          $('#'+tableId+' a.zoomToObservation').click(function(){
              var tr = $($(this).parents('tr')[0]);
              var d = $('#'+tableId+'').DataTable().row( tr ).data();
              var identifiant_permanent = d['DT_RowId'];
              zoomToObservation( identifiant_permanent );
              return false;
          });
          $('#'+tableId+' span.identite_observateur').tooltip();
          $('#'+tableId+' a.getTaxonDetail').click(function(){
              var tr = $($(this).parents('tr')[0]);
              var d = $('#'+tableId+'').DataTable().row( tr ).data();
              var classes = $(d.lien_nom_valide).attr('class');
              var cd_nom = classes.split(' ')[1].replace('cd_nom_', '');
              displayTaxonDetail(cd_nom);
              $('#occtax-highlight-message').remove();
              return false;
          });
          // Replace taxon nomenclature key by values
          $('#'+tableId+' span.redlist_regionale').each(function(){
            replaceKeyByLabelFromNomenclature($(this), 'menace_regionale');
          });
          $('#'+tableId+' span.redlist_nationale').each(function(){
            replaceKeyByLabelFromNomenclature($(this), 'menace_nationale');
          });
          $('#'+tableId+' span.redlist_monde').each(function(){
            replaceKeyByLabelFromNomenclature($(this), 'menace_monde');
          });
          $('#'+tableId+' span.protectionlist').each(function(){
            replaceKeyByLabelFromNomenclature($(this), 'protection');
          });

        });
    }


    function initTaxonAutocomplete() {
      var formId = $('#div_form_occtax_search_token form').attr('id');
      $('#'+formId+'_autocomplete').autocomplete({
        minLength:2,
        autoFocus: true,
        source:function( request, response ) {
            request.limit = $('#form_taxon_service_autocomplete input[name="limit"]').val();
            request.taxons_locaux = $('#jforms_occtax_search_taxons_locaux').prop( "checked");
            request.taxons_bdd = $('#jforms_occtax_search_taxons_bdd').prop( "checked");
            $.post($('#form_taxon_service_autocomplete').attr('action'),
                request, function( data, status, xhr ) {
                  //rearange data if necessary
                  response( data );
            }, 'json');
        },
        open: function( e, ui ) {
        },
        focus: function( e, ui ) {
          return false;
        },
        close: function( e, ui ) {
        },
        change: function( e, ui ) {
          if ( $(this).val().length < $(this).autocomplete('option','minLength') )
            $('#'+formId+'_cd_ref').val( '' );
        },
        search: function( e, ui ) {
          $('#'+formId+'_cd_ref').val( '' );
        },
        select: function( e, ui ) {

          // Ajout du cd_ref dans le champ masqué
          $('#'+formId+'_cd_ref').val( ui.item.cd_ref );

          // Hide search comboboxes
          if ( $('#'+formId+'_filter > div').is(':visible') ) {
            $('#'+formId+'_filter > legend > button').click();
          }

          // Mise en forme du résultat
          var label = ui.item.nom_valide;

          // Suppression du contenu et perte du focus
          $(this).val( '' ).blur();

          // Ajout du taxon au panier
          addTaxonToSearch( ui.item.cd_ref, label );

          return false;
        }
      }).autocomplete( "widget" ).css("z-index","1050");

      // Add image to the proposed items
      $('#'+formId+'_autocomplete').autocomplete( "instance" )._renderItem = function( ul, item ) {
        return $( "<li>" )
        .append( $("<a>").html(  $("<a>").html( '<img src="'+ jFormsJQ.config.basePath + 'taxon/css/images/groupes/' + item.groupe + '.png" width="15" height="15"/>&nbsp;' + item.label )  ) )
        .appendTo( ul );
      };

    }

    function zoomToObservation( id ) {
        var ok = checkConnection();
        if (!ok) {
            return;
        }
        if(!id)
            return;
        var obsId = id;
        var obs = OccTax.layers.resultLayer.getFeatureByFid(obsId);
        if (!obs)
            return;

        var target_extent = obs.geometry.bounds;
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

        // Bug: lizMap.map.zoomToScale( target_scale ) -> we use zoom
        var zoom = lizMap.map.scales.indexOf(target_scale);
        lizMap.map.zoomTo(zoom);
        var targetCenter = target_extent.getCenterLonLat();
        lizMap.map.setCenter( targetCenter );

    }


    function getObservationDetail( id ) {
        // Check user is still connected if he was
        var ok = checkConnection();
        if (!ok) {
            return;
        }
        if(!id)
            return;

        // Zoom to observation
        zoomToObservation(id);

        // Get observation data
        var tokenFormId = $('#div_form_occtax_search_token form').attr('id');
        var obsUrl = $('#'+tokenFormId).attr('action').replace('initSearch', 'getObservation');
        obsUrl = obsUrl.replace('service', 'observation');
        $('occtax_search_observation_card').addClass('not_enabled');
        $.get(
            obsUrl,
            {'id': id},
            function( data ) {
                $('occtax_search_observation_card').removeClass('not_enabled');

                // Show observation car h3 and div
                $('#occtax_search_observation_card').prev('h3.occtax_search:first').show();
                $('#occtax_search_observation_card').html( data ).show();

                // Hide description && result div
                $('#occtax_search_input').hide();
                $('#occtax_search_result').hide();
                $('#occtax_search_description').hide();

                // Taxon detail URL - Add event on click
                $('#occtax_search_observation_card a.getTaxonDetail').click(function(){
                    var classes = $(this).attr('class');
                    var cd_nom = classes.split(' ')[1].replace('cd_nom_', '');
                    displayTaxonDetail(cd_nom);
                    return false;
                });

                // Add number of lines in the table and current position
                var tableId = 'occtax_results_observation_table';
                var current_line = $('#'+tableId).find('tr#' + id).index() + 1;
                var total_count = $('#'+tableId+' tr').length - 1;
                $('#occtax_fiche_position').text(current_line + ' / '+total_count);
                if (current_line == 1){
                    $('#occtax_fiche_before').addClass('disabled');
                }
                if (current_line == 100){
                    $('#occtax_fiche_next').addClass('disabled');
                }

                // Next and previous observation button
                $('#occtax_fiche_next, #occtax_fiche_before').click(function(){
                    // Remove taxon detail
                    $('#sub-dock').hide().html('');

                    // Get action based on clicked button
                    var action = 'next';
                    if ($(this).attr('id') == 'occtax_fiche_before') {
                        action = 'before';
                    }
                    // find brother
                    var tableId = 'occtax_results_observation_table';
                    var current_tr = $('#'+tableId).find('tr#' + id);
                    //console.log(current_tr);
                    if (action == 'next') {
                        var brother_id = current_tr.next('tr').attr('id');
                        var m = 'à la fin';
                    } else {
                        var brother_id = current_tr.prev('tr').attr('id');
                        var m = 'au début';
                    }
                    if (!brother_id){
                        $('#occtax-highlight-message').remove();
                        lizMap.addMessage( "Vous êtes arrivés " + m + " du tableau d'observations", 'info', true ).attr('id','occtax-highlight-message');
                        return false;
                    }

                    // Unhighligth current obs
                    var current_obs = OccTax.layers.resultLayer.getFeatureByFid(id);
                    OccTax.controls['select']['highlightCtrl'].unhighlight( current_obs );

                    // Go to the next observation
                    getObservationDetail(brother_id);
                    return false;

                });

                $('#occtax_fiche_zoom').click(function(){
                    zoomToObservation(id);
                });

                // Highlight obs
                var obs = OccTax.layers.resultLayer.getFeatureByFid(id);
                if (obs) {
                    OccTax.controls['select']['highlightCtrl'].highlight( obs );
                }


            }
        );
    }

    function clearSpatialSearch(){
        OccTax.emptyDrawqueryLayer('resultLayer');
        OccTax.deactivateAllDrawqueryControl();
        $('#jforms_occtax_search_geom').val('');
        $('#jforms_occtax_search_code_commune').val('');
        $('#jforms_occtax_search_code_masse_eau').val('');
        $('#jforms_occtax_search_code_maille').val('');
        $('#jforms_occtax_search_type_maille').val('');
        $('#jforms_occtax_search_type_en').val('');
        $('#obs-spatial-query-buttons button').removeClass('active');
    }


    function refreshOcctaxDatatableSize(container){
      var dtable = $(container).find('table.dataTable');
      dtable.DataTable().tables().columns.adjust();
      //$('#bottom-dock').addClass('visible');
      var h = $("#occtax").height()
      h = h - $('#occtax h3.occtax_search').height() * 3;
      h = h - $("#occtax_search_description:visible").height();
      h = h - $("#occtax_results_tabs").height();
      h = h - $("#occtax_results_observation_table_paginate:visible").height();
      h = h - 130;
      dtable.parent('div.dataTables_scrollBody').height(h);
      // Width
      w = dtable.parent('div.dataTables_scrollBody').width();
      dtable.parent('div.dataTables_scrollBody').width(w - 50);
      dtable.DataTable().tables().columns.adjust();
    }

    function moveLizmapMenuLi( liorder ){
      var ul = $("#mapmenu ul.nav-list");
      var li = ul.children("li");
      li.detach().sort(function(a, b) {
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
            'date_min', 'date_max'
        ];
        return white_params;
    }

    function updateFormInputsFromUrl() {
        // Example URL
        // ?cd_nom%5B0%5D=79700&cd_nom%5B1%5D=447404&observateur=durand&date_min=2000-05-01&date_max=2019-01-01
        // detect parameters
        var queryString = window.location.search;
        if (queryString && queryString != '') {
            var params = new URLSearchParams(queryString);
            var targets = {};
            params.forEach(function(value, key) {
                // Crop name to remove array part
                // cd_nom[0] -> cd_nom
                var skey = key.split('[')[0];
                if (!(skey in targets)) {
                    targets[skey] = [];
                }
                targets[skey].push(value)
            });

            var tokenFormId = $('#div_form_occtax_search_token form').attr('id');
            var trigger_submit = false;
            var white_params = getWhiteParams('url');
            var geometry_already_added = false;
            var cd_nom_list = [];

            for (var name in targets) {
                if ($.inArray(name, white_params) == -1) {
                    continue;
                }
                trigger_submit = true;
                var input_name = name;
                var input_value = targets[name];
                //var input_value = decodeURIComponent(entry[1]);

                if (( input_name == 'date_min' || input_name == 'date_max') && input_value[0] != '') {
                    $('#' + tokenFormId + ' [name="'+input_name+'[year]"]').val(input_value[0].split('-')[0]);
                    $('#' + tokenFormId + ' [name="'+input_name+'[month]"]').val(input_value[0].split('-')[1]);
                    $('#' + tokenFormId + ' [name="'+input_name+'[day]"]').val(input_value[0].split('-')[2]);
                    $('#' + tokenFormId + ' [name="'+input_name+'_hidden"]').val(input_value[0]);
                }else if (input_name == 'cd_nom' && Array.isArray(input_value) && input_value.length > 0) {
                    cd_nom_list = input_value;
                    for (var i in input_value) {
                        //console.log("Récupère le nom des taxon et les mets dans le panier");
                        addTaxonToSearch( input_value[i], 'cd_nom = ' + input_value[i] );
                    }
                } else {
                    var input_item = $('#' + tokenFormId + ' [name="'+input_name+'"]');
                    var ismulti = false;
                    if (input_item.length == 0) {
                        input_item = $('#' + tokenFormId + ' [name="'+input_name+'[]"]');
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
                    var format = new OpenLayers.Format.WKT();
                    var geom = format.read( wkt ).geometry;
                    var theLayer = OccTax.layers['queryLayer'];
                    theLayer.destroyFeatures();
                    geom.transform('EPSG:4326', OccTax.map.projection);
                    theLayer.addFeatures( [new OpenLayers.Feature.Vector( geom)] );
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
                        ,{x:'', y:'', type_maille: type_maille, code: input_value[0]}
                        , function( data ) {
                        if ( data.status == 1 ) {
                              var format = new OpenLayers.Format.GeoJSON();
                              var geom = format.read( data.result.geojson )[0].geometry;
                              var theLayer = OccTax.layers['queryLayer'];
                              theLayer.destroyFeatures();
                              geom.transform('EPSG:4326', OccTax.map.projection);
                              theLayer.addFeatures( [new OpenLayers.Feature.Vector( geom)] );
                        }
                    }, 'json');
                    geometry_already_added = true;
                }

            };

            // Submit form
            if (trigger_submit) {
                $('#'+tokenFormId).submit();
                if (cd_nom_list.length > 0) {
                    // Change name of chosen cd_nom in bucket
                    for (var i in cd_nom_list) {
                        var form_getter = '#form_occtax_service_commune';
                        $.post(
                            $(form_getter).attr('action').replace('getCommune', 'getTaxon')
                            ,{cd_nom: cd_nom_list[i]}
                            , function( data ) {
                            if ( data.status == 1 ) {
                                deleteTaxonToSearch( data.result.cd_nom );
                                addTaxonToSearch( data.result.cd_nom, data.result.nom_valide );
                            }
                        }, 'json');
                    }
                }
            }
        }
    }

    function updateUrlFromFormInput() {
        var queryString = window.location.search;
        var tokenFormId = $('#div_form_occtax_search_token form').attr('id');
        var white_params = getWhiteParams('form');
        var form_params = '';
        for (var k in white_params) {
            var name = white_params[k];

            // Dates
            var input_value = '';
            if (name == "date_min") {
                var input_value = $('#' + tokenFormId + ' [name="'+name+'[year]"]').val();
                if (input_value != '') {
                    input_value+= '-' + $('#' + tokenFormId + ' [name="'+name+'[month]"]').val();
                    input_value+= '-' + $('#' + tokenFormId + ' [name="'+name+'[day]"]').val();
                }
            } else if (name == "date_max") {
                var input_value = $('#' + tokenFormId + ' [name="'+name+'[year]"]').val();
                if (input_value != '') {
                    input_value+= '-' + $('#' + tokenFormId + ' [name="'+name+'[month]"]').val();
                    input_value+= '-' + $('#' + tokenFormId + ' [name="'+name+'[day]"]').val();
                }
            } else if (name == "cd_nom") {
                var cd_nom = $('#' + tokenFormId + ' [name="'+name+'[]"]').val();
                var input_value = cd_nom;
            } else {
                // Check if simple input can be found
                var input_selector = '#' + tokenFormId + ' [name="'+name+'"]';
                var input_item = $(input_selector);
                if (input_item.length == 0) {
                    var input_selector = '#' + tokenFormId + ' [name="'+name+'[]"]';
                    var input_item = $(input_selector);
                }
                var input_value = input_item.val();
            }
            if (input_value && input_value != '') {
                if (Array.isArray(input_value)) {
                    for (var v in input_value) {
                        form_params+= name+'['+v+']='+input_value[v]+'&';
                    }
                } else {
                    form_params+= name+'='+input_value+'&';
                }
            }
        }
        if (form_params != '') {
            window.history.pushState('', '', '?bbox=' + lizMap.map.getExtent().toBBOX() + '&' + form_params.trim('&'));
        }
    }

        //console.log('OccTax uicreated');
        $('#occtax-message').remove();
        $('#occtax-highlight-message').remove();
        // Hide empty groups
        $('.jforms-table-group').each(function(){
            var tbContent = $(this).html().replace(/(\r\n|\n|\r)/gm,"");
            if( !tbContent ) {
                $(this).parent('fieldset:first').hide();
            }
        });

        OccTax.controls['query'] = {};
        /**
          * Ajout de la couche openlayers des requêtes cartographiques
          */
        var queryLayer = new OpenLayers.Layer.Vector("queryLayer", {styleMap:OccTax.drawStyleMap});
        OccTax.map.addLayers([queryLayer]);
        OccTax.layers['queryLayer'] = queryLayer;

        /**
         * Point
         * @type @new;OpenLayers.Control.DrawFeature
         */
        var queryPointLayerCtrl = new OpenLayers.Control.DrawFeature(queryLayer,
          OpenLayers.Handler.Point, {'featureAdded': onQueryFeatureAdded}
        );
        OccTax.map.addControl(queryPointLayerCtrl);
        OccTax.controls['query']['queryPointLayerCtrl'] = queryPointLayerCtrl;

        /**
         * Circle
         * @type @new;OpenLayers.Control.DrawFeature
         */
        var queryCircleLayerCtrl = new OpenLayers.Control.DrawFeature(queryLayer,
            OpenLayers.Handler.RegularPolygon,
            { handlerOptions: {sides: 40}, 'featureAdded': onQueryFeatureAdded}
        );
        OccTax.map.addControl(queryCircleLayerCtrl);
        OccTax.controls['query']['queryCircleLayerCtrl'] = queryCircleLayerCtrl;

        /**
         * Polygon
         * @type @new;OpenLayers.Control.DrawFeature
         */
        var queryPolygonLayerCtrl = new OpenLayers.Control.DrawFeature(queryLayer,
            OpenLayers.Handler.Polygon, {'featureAdded': onQueryFeatureAdded, styleMap:OccTax.drawStyleMap}
        );
        OccTax.map.addControl(queryPolygonLayerCtrl);
        OccTax.controls['query']['queryPolygonLayerCtrl'] = queryPolygonLayerCtrl;

        /**
         * Controle de modification d'un polygone
         * @type @new;OpenLayers.Control.ModifyFeature
         */
        var modifyPolygonLayerCtrl = new OpenLayers.Control.ModifyFeature(queryLayer, {styleMap:OccTax.drawStyleMap});
        OccTax.map.addControl(modifyPolygonLayerCtrl);
        OccTax.controls['query']['modifyPolygonLayerCtrl'] = modifyPolygonLayerCtrl;
        queryLayer.events.on({
            featuremodified: onQueryFeatureModified
        });

        $('#obs-spatial-upload-geojson form').fileupload({
            dataType: 'json',
            done: function (e, data) {
                data = data.result;
                if( data.status == 1 ) {
                    var format = new OpenLayers.Format.GeoJSON();
                    var features = format.read( data.result );
                    var totalSurf = 0.0;
                    var multiPoly = null;

                    for ( var i=0, len = features.length; i<len; i++ ) {
                        var feat = features[i];
                        var geom = feat.geometry;
                        // break if the geometry is not a polygon
                        if ( geom.CLASS_NAME != 'OpenLayers.Geometry.Polygon'
                          && geom.CLASS_NAME != 'OpenLayers.Geometry.MultiPolygon' ) {
                            lizMap.addMessage( 'Geometrie incorrecte', 'error', true ).attr('id','occtax-highlight-message');
                            multiPoly = null;
                            break;
                        }
                        // does not store geom if not in the map
                        if ( !lizMap.map.restrictedExtent.intersectsBounds( geom.getBounds() ) ){
                            lizMap.addMessage( "La zone envoyée n'est pas dans l'emprise de la carte. La donnée doit être dans la projection de la carte :  " + lizMap.map.getProjection(), 'error', true ).attr('id','occtax-highlight-message');
                            break;
                        }
                        // sum total surface
                        totalSurf += geom.getArea();
                        // break if total surface is enough than maxAreaQuery (only if maxAreaQuery != -1
                        if ( OccTax.config.maxAreaQuery > 0 && totalSurf >= OccTax.config.maxAreaQuery ) {
                            lizMap.addMessage( 'La surface totale des objets est trop importante (doit être < ' +  OccTax.config.maxAreaQuery + ' )', 'error', true ).attr('id','occtax-highlight-message');
                            multiPoly = null;
                            break;
                        }
                        // Construct multi polygon
                        if ( geom.CLASS_NAME == 'OpenLayers.Geometry.MultiPolygon' ){
                            if ( multiPoly == null )
                                multiPoly = geom;
                            else
                                multiPoly.addComponents( geom.components );
                        } else {
                            if ( multiPoly == null )
                                multiPoly = new OpenLayers.Geometry.MultiPolygon([ geom ]);
                            else
                                multiPoly.addComponents([ geom ]);
                        }
                    }
                    if ( multiPoly != null ) {
                        // construct feature and add it
                        var multiFeat = new OpenLayers.Feature.Vector( multiPoly );
                        OccTax.layers['queryLayer'].addFeatures( multiFeat );
                        onQueryFeatureAdded( multiFeat );
                        lizMap.addMessage( data.msg.join('<br/>'), 'info', true ).attr('id','occtax-highlight-message');
                    }
                } else
                    lizMap.addMessage( data.msg.join('<br/>'), 'error', true ).attr('id','occtax-highlight-message');
            }
        });


        $('#obs-spatial-query-buttons button').button().click(function(){
            // Deactivate print if active
            $('#mapmenu li.print.active a').click();

            var self = $(this);
            var dataValue = self.attr('data-value');

            if ( dataValue != 'modifyPolygon' ) {
              $('#obs-spatial-query-modify').hide();
              $('#obs-spatial-query-modify').removeClass('active');
            }

            if ( dataValue == 'deleteGeom' ) {
                clearSpatialSearch();
                return false;
            }
            if ( dataValue == 'importPolygon' ) {
                $('#obs-spatial-upload-geojson form input[type="file"]').click();
                //return false;
            }
            if ( dataValue == 'modifyPolygon' ) {
                if(OccTax.controls['query']['modifyPolygonLayerCtrl'].active) {
                    self.removeClass('active');
                    var theLayer = OccTax.layers['queryLayer'];
                    var feature = theLayer.features[0];
                    OccTax.validGeometryFeature( feature );
                    theLayer.drawFeature( feature );
                    var geom = feature.geometry.clone().transform( OccTax.map.projection, 'EPSG:4326' );
                    $('#jforms_occtax_search_geom').val( geom.toString() );
                    $('#jforms_occtax_search_code_commune').val('');
                    $('#jforms_occtax_search_code_masse_eau').val('');
                    $('#jforms_occtax_search_code_maille').val('');
                    $('#jforms_occtax_search_type_maille').val('');
                    OccTax.controls['query']['modifyPolygonLayerCtrl'].deactivate();
                    OccTax.controls['query']['modifyPolygonLayerCtrl'].moveLayerBack();
                    return false;
                } else {
                    // we must empty resultLayer to be sure the modified control works
                    //OccTax.oneCtrlAtATime( dataValue, 'query', ['queryLayer','resultLayer'] );
                    OccTax.oneCtrlAtATime( dataValue, 'query', ['queryLayer'] );
                    OccTax.controls['query']['modifyPolygonLayerCtrl'].activate();
                    OccTax.controls['query']['modifyPolygonLayerCtrl'].selectFeature( OccTax.layers['queryLayer'].features[0] );
                    self.addClass('active');
                }
            } else {
                OccTax.oneCtrlAtATime( dataValue, 'query', 'resultLayer');//, 'resultLayer'
                //$('#map').css('cursor','pointer');
            }
            //return false;
        });


        OccTax.controls['select'] = {};
        /**
          * Ajout de la couche openlayers des résultats
          */
        //console.log(OccTax.resultLayerStyleMap);
        var resultLayer = new OpenLayers.Layer.Vector("resultLayer", {styleMap:OccTax.resultLayerStyleMap});
        OccTax.map.addLayers([resultLayer]);
        OccTax.layers['resultLayer'] = resultLayer;

        var highlightCtrl = new OpenLayers.Control.SelectFeature(resultLayer, {
            hover: true,
            highlightOnly: true,
            renderIntent: "select",
            eventListeners: {
                beforefeaturehighlighted: function(e){
                    $('#occtax-highlight-message').remove();
                },
                featurehighlighted: function(evt){
                  //console.log(evt);
                    lizMap.addMessage(evt.feature.attributes.message_text,'info',true).attr('id','occtax-highlight-message');
                    var tr = $('tr#'+evt.feature.fid);
                    if (tr.length != 0 ){
                        tr.addClass('info');
                    }

                },
                featureunhighlighted: function(evt){
                    $('#occtax-highlight-message').fadeOut('slow', function(){
                        $(this).remove();
                    });
                    var tr = $('tr#'+evt.feature.fid+'.info');
                    if (tr.length != 0 )
                        tr.removeClass('info');
                }
            }
        });
        var selectCtrl = new OpenLayers.Control.SelectFeature(resultLayer, {
            clickout: true,
            eventListeners: {
                featureselected: function(evt) {
                  console.log(evt);
                },
                featurehighlighted: function(evt) {
                  //console.log(evt);
                  var tr = $('tr#'+evt.feature.fid);
                  if (tr.length != 0 ){
                    // on masque le message du haut
                    $('#occtax-highlight-message').remove();

                    // on affiche la fiche de détail de l'observation
                    var ac = $('#occtax_search_result div.tab-pane.active').attr('id');
                    //if(ac == 'occtax_results_observation_table_div'){
                      getObservationDetail(evt.feature.fid);
                    //}

                    // on scroll dans le tableau : Le scroll ne fonctionne pas !
                    //var pos = tr.offset().top;
                    //my.animate({
                      //scrollTop: pos
                    //}, 300);
                  }
                },
                featureunhighlighted: function(evt){
                  // on réaffiche le panneau des résultats
                  var ac = $('#occtax_search_result div.tab-pane.active').attr('id');
                  if(ac == 'occtax_results_observation_table_div'){
                    $('#occtax_search_observation_card').prev('h3.occtax_search').click();
                  }
                }

            }
        });
        OccTax.map.addControl( highlightCtrl );
        OccTax.map.addControl( selectCtrl );
        OccTax.controls['select']['highlightCtrl'] = highlightCtrl;
        OccTax.controls['select']['selectCtrl'] = selectCtrl;
        OccTax.controls['select']['highlightCtrl'].activate();
        OccTax.controls['select']['selectCtrl'].activate();

        //activate tabs
        $('#occtax_results_tabs a').tab();

      // Get token form id
      var tokenFormId = $('#div_form_occtax_search_token form').attr('id');

      // Toggle pannel display
      $('#occtax-search-modify').click(function(){
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
      $('#occtax-search-replay').click(function(){
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
      $('#'+tokenFormId).submit(function(){

        // Check user is still connected if he was
        var ok = checkConnection();
        if (!ok) {
            return false;
        }

        // Bloc submit if a previous submit is in progress
        if(blocme){
          return false;
        }
        blocme = true;

        var self = $(this);

        // The Occtax events trigger an error on first load (when page not entirely loaded)
        // this causes submit to another page because JS event has not been correctly added to the form
        // we use try/catch to avoid it
        try{
          $('#occtax_result_button_bar').hide();
          // show statistics
          $('#occtax_results_stats_table_tab').tab('show');
          // deactivate geometry button
          $('#obs-spatial-query-buttons button.active').click();

          // Remove previous features : remove feature in all layers except queryLayer
          OccTax.emptyDrawqueryLayer('queryLayer');
          if($('#occtax_results_draw_maille_m01.btn').length){
            OccTax.events.triggerEvent('mailledatareceived_' + 'm01', {'results':null});
          }
          if($('#occtax_results_draw_maille_m02.btn').length){
            OccTax.events.triggerEvent('mailledatareceived_' + 'm02', {'results':null});
          }
          //OccTax.events.triggerEvent('mailledatareceived_' + 'm05', {'results':null});
          if($('#occtax_results_draw_maille_m10.btn').length){
            OccTax.events.triggerEvent('mailledatareceived_' + 'm10', {'results':null});
          }
        }catch(e){
           var anerror = 1;
           //console.error(e);
        }

        // Remove previous messages
        $('#occtax-message').remove();
        $('#occtax-highlight-message').remove();

        // Deactivate (CSS) main div
        $('#occtax').addClass('not_enabled');
        lizMap.addMessage( 'Recherche en cours...', 'info', true ).attr('id','occtax-message');

        // Remove taxon input values depending on active tab
        if( $('#occtax_taxon_tab_div > div.tab-content > div.active').length == 1 ) {
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

        // Add parameters in URL
        updateUrlFromFormInput();

        // Send request and get token
        $.post(self.attr('action'), self.serialize(),
            function(tData) {
                blocme = false;
                if (tData.status == 1) {

                    // Display description div
                    var dHtml = tData.description;
                    $('#occtax_search_description_content').html(dHtml);

                    // Show or hide depending on dock height
                    var dockHeight = $('#dock').height();
                    if(dockHeight >= 800)
                      $('#occtax_search_description').show();
                    else
                      $('#occtax_search_description').hide();

                    // Show description title
                    $('#occtax_search_description').prev('h3.occtax_search').show();
                    $('#occtax-search-modify').show();
                    $('#occtax-search-replay').hide();
                    $('#occtax_search_observation_card').hide();

                    // Move legend to map
                    $('#map-content div.occtax-legend-container').remove();
                    // Add number of records in
                    // Hide or display legend and map maille toglle button depending on results
                    if(tData.recordsTotal > 0){
                        $('#dock div.occtax-legend-container')
                        .appendTo($('#map-content'))
                        .show();
                        $('#occtax_toggle_map_display').show();
                        $('#occtax_observation_records_total').val(tData.recordsTotal);
                    }else{
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

                    if($('#occtax_results_draw_maille_m01.btn').length){
                        $('#occtax_service_search_maille_form_m01 input[name="token"]').val(tData.token).change();
                        $('#occtax_results_maille_table_m01').DataTable().ajax.reload();
                    }
                    if($('#occtax_results_draw_maille_m02.btn').length){
                        $('#occtax_service_search_maille_form_m02 input[name="token"]').val(tData.token).change();
                        $('#occtax_results_maille_table_m02').DataTable().ajax.reload();
                    }
                    if($('#occtax_results_draw_maille_m10.btn').length){
                        $('#occtax_service_search_maille_form_m10 input[name="token"]').val(tData.token).change();
                        $('#occtax_results_maille_table_m10').DataTable().ajax.reload();
                    }
                    if($('#occtax_results_draw_observation.btn').length){
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

                }else{
                  lizMap.addMessage( tData.msg.join('<br/>'), 'error', true ).attr('id','occtax-highlight-message');
                }

            }
        ,'json');
        return false;
      });

      // Move spatial query buttons to WHERE group
      $('#'+tokenFormId+'_where').append( $('#obs-spatial-query-buttons-container') );

      // Move taxon tabs to the top
      $('#'+tokenFormId).prepend($('#occtax_taxon_tab_div'));

      // Move taxon panier to the taxon main group
      $('#'+tokenFormId+'_main').append( $('#occtax_taxon_select_div'));

      // Move taxon main group to the panier tab
      $('#recherche_taxon_panier').append($('#'+tokenFormId+'_main'));

      // Move taxon advanced filter to the attributes
      $('#recherche_taxon_attributs').append($('#'+tokenFormId+'_filter'));

      // Hide cd_nom
      $('#'+tokenFormId+'_cd_nom').parent('.controls').parent('.control-group').hide();
      //$('#'+tokenFormId+'_main .jforms-table-group .control-group:nth-last-child(-n+2)').hide();

      // Réinitialisation du formulaire
      // On supprime les géométries de recherche
      // On masque les résultats
      $('#'+tokenFormId+'_reinit').click(function(){
          // Reinit taxon
          var removePanier = true;
          var removeFilters = true;
          clearTaxonFromSearch(removePanier, removeFilters);

          // Reinit other fields
          $('#'+tokenFormId).trigger("reset");
          // sumoselect
          $('select.jforms-ctrl-listbox').each(function(){
              if ($(this).attr('id') != 'jforms_occtax_search_cd_nom') {
                  $(this)[0].sumo.unSelectAll();
              }
          });

          // Reinit date picker
          $('#'+tokenFormId+' .ui-datepicker-reset').click();

          // Reinit spatial button
          clearSpatialSearch();
          OccTax.emptyDrawqueryLayer('queryLayer');

          // Reinit count
          $('#occtax_observation_records_total').val(0);

          // Reinit tables
          try{
            OccTax.events.triggerEvent('mailledatareceived_' + 'm01', {'results':null});
            OccTax.events.triggerEvent('mailledatareceived_' + 'm02', {'results':null});
            OccTax.events.triggerEvent('mailledatareceived_' + 'm10', {'results':null});
            OccTax.events.triggerEvent('observationdatareceived', {'results':null});
          }catch(e){
            var myerror = e;
          }

          // Hide description, result and card panels
          $('#occtax_search_result, #occtax_search_description, #occtax_search_observation_card')
          .hide()
          .prev('h3.occtax_search').hide()
          ;

          // Cacher la barre d'outil pour les boutons
          $('#occtax_toggle_map_display').hide();

          // Masquer la légende des mailles
          $('#map-content div.occtax-legend-container').remove();

          // Remove URL parameters
          window.history.pushState('', '', '?bbox=' + lizMap.map.getExtent().toBBOX());

          return false;
      });




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
      $('#jforms_occtax_search_group option').each(function(){
        var v = $(this).val();
        var vv = v.split(' ')[0];
        $(this).val(vv);
      });

      // Toggle taxon checkbox depending on active taxon tab
      //$('#occtax_taxon_tab_div > ul > li > a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
        //var target = $(e.target).attr("href") // activated tab
        //var showTaxonInBdd = false;
        //if(target == '#recherche_taxon_panier'){
          //showTaxonInBdd = true;
        //}
        //$('#jforms_occtax_search_taxons_bdd_label').toggle(showTaxonInBdd);
      //});

      // Hide taxon checkboxes labels
      $('#jforms_occtax_search_taxons_locaux_label').hide();
      $('#jforms_occtax_search_taxons_bdd_label').hide();

      $('#occtax_results_draw .btn').click(function() {
        var self = $(this);

        $('#occtax_results_draw .btn').removeClass('btn-primary');
        self.addClass('btn-primary');

        // Get layer
        var rLayer = OccTax.layers['resultLayer'];
        rLayer.destroyFeatures();
        var the_features = OccTax.getResultFeatures( self.val());

        // For mailles,
        // We need to add features to draw the underlying maille
        if( self.val() == 'm01' || self.val() == 'm02' || self.val() == 'm05' || self.val() == 'm10' ){
          var sq_features = OccTax.getResultFeatures( self.val());
          if(sq_features){
            var square = 2000;
            if(self.val() == 'm10'){
              square = 10000;
            }
            if(self.val() == 'm01'){
              square = 1000;
            }
            if(self.val() == 'm02'){
              square = 2000;
            }
            if(self.val() == 'm05'){
              square = 5000;
            }

            for(var i=0, len=sq_features.length; i<len; i++){
              var f = sq_features[i];
              f.fid += 'sq';
              f.attributes.square = square;
              f.attributes.color = '#ffffff';
            }
            rLayer.addFeatures( sq_features );
          }
        }
        // Add raw features (circles for mailles)
        rLayer.addFeatures( the_features );

        rLayer.setVisibility(true);
        rLayer.refresh();

        // Enable left panel
        $('#occtax').removeClass('not_enabled');
        $('#occtax-message').remove();

        // Toggle the legend depending on the clicked button
        var displayLegend = (self.val() != 'observation');
        $('#map-content div.occtax-legend-container').toggle(displayLegend);
        //return false;
      });


      // Click on hidden draw buttons when changing displayed tab
      $('#occtax_results_tabs a').on('shown', function (e) {

          var tid = $(e.target).attr('id');

          // Refresh datatable display ( set height used with scrollY )
          var container = $(e.target).attr('href');
          refreshOcctaxDatatableSize(container);

          // Draw geometries corresponding to displayed tab
          var drawButton = 'occtax_results_draw_maille_m02';
          if(tid == 'occtax_results_maille_table_tab_m01'){
            drawButton = 'occtax_results_draw_maille_m01';
          }
          if(tid == 'occtax_results_maille_table_tab_m02'){
            drawButton = 'occtax_results_draw_maille_m02';
          }
          //if(tid == 'occtax_results_maille_table_tab_m05'){
            //drawButton = 'occtax_results_draw_maille_m05';
          //}
          if(tid == 'occtax_results_maille_table_tab_m10'){
            drawButton = 'occtax_results_draw_maille_m10';
          }
          if(tid == 'occtax_results_observation_table_tab'){
            drawButton = 'occtax_results_draw_observation';
          }
          $('#' + drawButton).click();

      });
      $('#occtax_results_zoom').click(function() {
          var rLayer = OccTax.layers['resultLayer'];
          if( rLayer.features.length > 0 ){
            OccTax.map.zoomToExtent( rLayer.getDataExtent() );
          }
          //return False;
      });

      // Export des donnees
      $('#occtax_result_export_form').submit(function(){
        if(!uiprete) return false;

        var exportUrl = '';
        var eFormat = $('#export_format').val();
        // WFS
        if( eFormat == 'WFS' ){
          exportUrl = $('a#btn-get-wfs').attr('href');
          $('#input-get-wfs')
          .val(exportUrl)
          .show()
          .select()
          ;
          lizMap.addMessage( 'Vous pouvez copier l\'url WFS correspondant à votre requête pour l\'utiliser dans votre SIG', 'info', true ).attr('id','occtax-highlight-message');
        }
        // CSV or GeoJSON
        else{
          exportUrl+= $('#'+tokenFormId).attr('action');
          if( eFormat == 'DEE' ) {
            exportUrl = exportUrl.replace('service', 'export').replace('initSearch', 'init');
          }
          else if( eFormat == 'GeoJSON' ) {
            exportUrl = exportUrl.replace('service', 'export').replace('initSearch', 'init');
          }
          else {
            exportUrl = exportUrl.replace('service', 'export').replace('initSearch', 'init');
          }
          exportUrl+= '?token=' + $('#occtax_service_search_stats_form input[name="token"]').val();
          exportUrl+= '&format=' + eFormat;

          // Projection
          exportUrl+= '&projection=' + $('#export_projection').val();
          window.open(exportUrl);
        }

        return false;
      })

      $('#export_format').change(function(){
        var isWFS = ($(this).val() == 'WFS');
        $('#input-get-wfs')
        .val('')
        .toggle(isWFS);
        if(isWFS){
          $('#occtax_result_export_form').submit();
          return false;
        }
      })

      // Toggle search div via h3
      $('h3.occtax_search').click(function(){
        // Toggle next div visibility
        var ndiv = $(this).next('div:first');
        ndiv.toggle();

        // Reopen results & description
        // when observation car is hidden
        if(
          ndiv.attr('id') == 'occtax_search_observation_card'
          && !(ndiv.is(':visible'))
        ){
          $('#occtax_search_result').show();
          $('#occtax_search_description').show();
        }

        // Hide observation card when other div is displayed
        if(
          ndiv.attr('id') != 'occtax_search_observation_card'
          && (ndiv.is(':visible'))
        ){
          $('#occtax_search_observation_card').hide();
        }

        var tid = $('#occtax_search_result div.tab-pane.active').attr('id');

        // Refresh size of datatable table (for scrolling)
        refreshOcctaxDatatableSize('#' + tid);
      });


      // Clear Taxon search with button
      $('#clearTaxonSearch').hide(); // Hide this useless button to remove them all
      $('#clearTaxonSearch').click(function(){
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
      $('select.jforms-ctrl-listbox').SumoSelect(
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

      // Refresh datatable size when bottom dock changes
      // commented because tables are not in the bottom dock anymore
        //lizMap.events.on({
            //bottomdocksizechanged: function(evt) {
               //var mycontainer = $('#occtax_tables div.bottom-content.active');
               //refreshOcctaxDatatableSize(mycontainer);
            //}
        //});

        // Refresh bbox in URL
        lizMap.map.events.on({
            moveend: function(evt) {
                var queryString = window.location.search;
                var params = new URLSearchParams(queryString);
                var new_bbox = lizMap.map.getExtent().toBBOX();
                params.set('bbox', new_bbox);
                window.history.replaceState({}, '', `${location.pathname}?${params}`);
            }
        });

        // Get URL parameters, set form inputs and submit search form
        updateFormInputsFromUrl();


    }
});
