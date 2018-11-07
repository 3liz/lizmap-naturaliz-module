var uiprete = false;
var blocme = true;

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
                              lizMap.addMessage( data.msg.join('<br/>'), 'error', true );
                            else
                              lizMap.addMessage( 'Error', 'error', true );
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
                              lizMap.addMessage( data.msg.join('<br/>'), 'error', true );
                            else
                              lizMap.addMessage( 'Error', 'error', true );
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
                              lizMap.addMessage( data.msg.join('<br/>'), 'error', true );
                            else
                              lizMap.addMessage( 'Error', 'error', true );
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

    $('#occtax_taxon_select_toggle').click(function(){
        //console.log('affiche la recherche par taxon');
        $('#button-taxon').click();
    });

    function addTaxonToSearch( cd_nom, nom_cite ) {
        //console.log(cd_nom, nom_cite);
        $('#div_form_occtax_search_token form [name="search_token"]').val('');
        $('#occtax_taxon_select_params').html( '' ).hide();
        $('#occtax_taxon_select_list').show();
        var ctrl_cd_nom = $('#div_form_occtax_search_token form [name="cd_nom[]"]');
        var selectVals = ctrl_cd_nom.val();
        if ( selectVals == null )
            selectVals = [];
        if ( selectVals.indexOf( cd_nom ) == -1 ) {
            ctrl_cd_nom.append('<option selected value="'+cd_nom+'">'+nom_cite+'</option>');
            var li = $('<li data-value="'+cd_nom+'" style="height:20px; margin-left:2px;"><span style="display:inline-block; width:190px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">'+nom_cite+'</span><button type="button" class="close" value="'+cd_nom+'" aria-hidden="true">&times;</button></li>');
            $('#occtax_taxon_select_list').append(li);
            li.find('.close').click(function(){
                deleteTaxonToSearch( $(this).attr('value') );
                //return false;
            });
        }
    }

    function deleteTaxonToSearch( cd_nom ) {
      $('#div_form_occtax_search_token form [name="cd_nom[]"] option[value="'+cd_nom+'"]').remove();
      var li = $('#occtax_taxon_select_list li[data-value="'+cd_nom+'"]');
      li.find('.close').unbind('click');
      li.remove();
    }

    function clearTaxonFromSearch() {
        $('#div_form_occtax_search_token form [name="cd_nom[]"]').html('');
        $('#div_form_occtax_search_token form [name="search_token"]').val('');
        $('#occtax_taxon_select_list .close').unbind('click');
        $('#occtax_taxon_select_list').html('').show();
        $('#occtax_taxon_select_params').html('');
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
                var searchForm = $('#occtax_service_search_stats_form');

                // Do not run the query if no token has been found
                var mytoken = searchForm.find('input[name="token"]').val();
                if(!mytoken)
                  return false;
                $.getJSON(searchForm.attr('action'), searchForm.serialize(),
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
                                lizMap.addMessage( results.msg.join('<br/>'), 'error', true );
                              else
                                lizMap.addMessage( 'Error', 'error', true );
                          }
                          refreshOcctaxDatatableSize('#occtax_results_stats_table_div');
                          callback( tData );
                          $('#'+tableId+'').show();

                    }
                );
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
                $.getJSON(searchForm.attr('action'), searchForm.serialize(),
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
                                lizMap.addMessage( results.msg.join('<br/>'), 'error', true );
                            else
                                lizMap.addMessage( 'Error', 'error', true );
                          }
                          refreshOcctaxDatatableSize('#occtax_results_taxon_table_div');

                          callback( tData );
                          $('#'+tableId+'').show();
                    }
                );
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
              //~ console.log( cd_nom );
              var row_label = $('#'+tableId+' thead tr th.row-label').attr('data-value');
              row_label = row_label.split(',')[0];
              clearTaxonFromSearch();
              //~ console.log( cd_nom, d[row_label] );
              addTaxonToSearch( cd_nom, d[row_label] );
              $('#div_form_occtax_search_token form').submit();
              return false;
          });
        });
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
                var searchForm = $('#occtax_service_search_maille_form_' + type_maille);

                // Do not run the query if no token has been found
                var mytoken = searchForm.find('input[name="token"]').val();
                if(!mytoken)
                  return false;
                $.getJSON(searchForm.attr('action'), searchForm.serialize(),
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
                                lizMap.addMessage( results.msg.join('<br/>'), 'error', true );
                            else
                                lizMap.addMessage( 'Error', 'error', true );
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
                );
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
              $.getJSON(searchForm.attr('action'), searchForm.serialize(),
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
                        lizMap.addMessage( results.msg.join('<br/>'), 'error', true );
                    else
                        lizMap.addMessage( 'Error', 'error', true );
                  }
                  callback( tData );
                  if ( $('#occtax_results_draw_observation').hasClass('active') )
                    $('#occtax_results_draw_observation').click();

                  refreshOcctaxDatatableSize('#occtax_results_observation_table_div');
                  $('#'+tableId+'').show();
                });
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
          $('#'+tableId+' a.openObservation').click(function(){
              var tr = $($(this).parents('tr')[0]);
              var d = $('#'+tableId+'').DataTable().row( tr ).data();
              var identifiant_permanent = d['DT_RowId'];
              getObservationDetail( identifiant_permanent );
              return false;
          });
        });
    }


    function manageTaxonSubmit(aCallBack){
      var formId = $('#div_form_taxon_search_token form').attr('id');
      var self = $('#'+formId);
      aCallBack = typeof aCallBack !== 'undefined' ?  aCallBack : null;

      $.getJSON(self.attr('action'), self.serialize(),
        function(tData) {

          //(tData);
          if (tData.status == 1) {
            $('#form_taxon_service_search input[name="token"]').val(tData.token);
            $('#table_taxon_results').DataTable().ajax.reload();
            $('#div_taxon_search_description').html( tData.description );

            if(aCallBack){
              aCallBack();
            }
          }
        });
    }

    function initFormTaxon() {
      var formId = $('#div_form_taxon_search_token form').attr('id');
      $('#'+formId+'_autocomplete').autocomplete({
        minLength:2,
        autoFocus: true,
        source:function( request, response ) {
            request.limit = $('#form_taxon_service_autocomplete input[name="limit"]').val();
            $.getJSON($('#form_taxon_service_autocomplete').attr('action'),
                request, function( data, status, xhr ) {
                  //rearange data if necessary
                  response( data );
            });
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
          $(this).val( $('<a>').html(ui.item.label.split(' = ')[0]).text() );
          $('#'+formId+'_cd_ref').val( ui.item.cd_ref );
          $('#'+formId+' select').val('');
          if ( $('#'+formId+'_filter > div').is(':visible') ) {
            $('#'+formId+'_filter > legend > button').click();
          }
          $('#'+formId).submit();
          return false;
        }
      }).autocomplete( "widget" ).css("z-index","1050");

      // Manage taxon form submit
      $('#'+formId+'_autocomplete').autocomplete( "instance" )._renderItem = function( ul, item ) {
        return $( "<li>" )
        .append( $("<a>").html(  $("<a>").html( '<img src="'+ jFormsJQ.config.basePath + 'css/images/taxon/' + item.groupe + '.png" width="15" height="15"/>&nbsp;' + item.label )  ) )
        .appendTo( ul );
      };
      // Search taxon and display results
      $('#'+formId).submit(function(){
        manageTaxonSubmit();
        return false;
      });
      // Reinit search form
      $('#'+formId+'_reinit').click(function(){
          $('#'+formId+'_cd_ref').val( '' );
          $('#jforms_taxon_search input[name="autocomplete"]').val('')
          $('#jforms_taxon_search select option').prop('selected', function() {
            return this.defaultSelected;
          });
          return false;
      });
      // Go back to occtax panel (do nothing else)
      $('#'+formId+'_back').click(function(){
          $('#button-occtax').click();
          return false;
      });
      // Search taxon & display result in taxon panel
      $('#'+formId+'_submit').click(function(){
        manageTaxonSubmit();
        return false;
      });

      // Search taxon, and run the corresponding filter in occtax panel
      $('#'+formId+'_obsfilter').click(function(){

        manageTaxonSubmit(function(){
          // check if a search has been run
          var token = $('#form_taxon_service_search input[name="token"]').val();
          var cdref = $('#jforms_taxon_search input[name="cd_ref"]').val();
          if(!token && !cdref){
            msg = "Vous devez lancer une recherche sur les taxons pour pouvoir filtrer les observations.";
            lizMap.addMessage( msg, 'error', true );
            return false;
          }
          var description = $('#div_taxon_search_description').html();
          clearTaxonFromSearch();
          $('#div_form_occtax_search_token form [name="search_token"]').val( token );
          $('#occtax_taxon_select_list').hide();
          $('#occtax_taxon_select_params').html( description ).show();
          $('#button-occtax').click();
          $('#div_form_occtax_search_token form').submit();

        });
        return false;
      });


      $('#'+formId+'_filter > div').hide();
      $('#'+formId+'_filter > legend').html('<button class="btn" data-toggle="button">'+$('#'+formId+'_filter > legend').text()+'<span class="caret"></span></button>');
      $('#'+formId+'_filter > legend > button').click( function(){
        //$(this).toggle();
        $('#'+formId+'_filter > div').toggle();
        return false;
      });
    }

    function addTaxonTable() {
      var tableId = 'table_taxon_results';
      // Get fields to display
      var returnFields = $('#'+tableId+'').attr('data-value').split(',');
      var DT_RowId = $('#'+tableId+' thead tr').attr('data-value');
      var datatableColumns = getDatatableColumns( tableId );
      var DT_Columns = datatableColumns[0];
      var displayFields = datatableColumns[1];
      // Display data via datatable
      $('#'+tableId+'').DataTable( {
            "lengthChange": false,
            "searching": false,
            "dom":'ipt',
            "language": {url:jFormsJQ.config.basePath + lizUrls["dataTableLanguage"]},
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
              var searchForm = $('#form_taxon_service_search');
              searchForm.find('input[name="limit"]').val(param.length);
              searchForm.find('input[name="offset"]').val(param.start);
              searchForm.find('input[name="order"]').val(
                DT_Columns[param.order[0]['column']]['data'] + ':' + param.order[0]['dir']
              );

              // Do not run the query if no token has been found
              var mytoken = searchForm.find('input[name="token"]').val();
              if(!mytoken)
                return false;
              $.getJSON(searchForm.attr('action'), searchForm.serialize(),
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
                        lizMap.addMessage( results.msg.join('<br/>'), 'error', true );
                    else
                        lizMap.addMessage( 'Error', 'error', true );
                  }
                  $('#'+tableId+' a').unbind('click');
                  callback( tData );
                });
            }
        });
        $('#'+tableId+'').on( 'page.dt', function() {
          $('#'+tableId+' a').unbind('click');
        });
        $('#'+tableId+'').on( 'draw.dt', function() {
          $('#'+tableId+' a.addTaxon').click(function(){
              var tr = $($(this).parents('tr')[0]);
              var d = $('#'+tableId+'').DataTable().row( tr ).data();
              var cd_nom = tr.attr('id');
              var row_label = $('#'+tableId+' thead tr th.row-label').attr('data-value');
              row_label = row_label.split(',')[0];
              addTaxonToSearch( cd_nom, d[row_label] );
              $('#div_form_occtax_search_token form').submit();
              // Show observation search form
              $('#mapmenu #button-occtax').click();
              return false;
          });
        });
    }

    function getObservationDetail( id ) {
      //console.log(id);
        if(!id)
            return;
        var tokenFormId = $('#div_form_occtax_search_token form').attr('id');
        var obsUrl = $('#'+tokenFormId).attr('action').replace('initSearch', 'getObservation');
        obsUrl = obsUrl.replace('service', 'observation');
        $.get(
            obsUrl,
            {'id': id},
            function( data ) {
                // Show observation car h3 and div
                $('#occtax_search_observation_card').prev('h3.occtax_search:first').show();
                $('#occtax_search_observation_card').html( data ).show();
                // Hide description && result div
                $('#occtax_search_result').hide();
                $('#occtax_search_description').hide();


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

        //console.log('OccTax uicreated');
        $('#occtax-message').remove();
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
                            lizMap.addMessage( 'Geometrie incorrecte', 'error', true );
                            multiPoly = null;
                            break;
                        }
                        // does not store geom if not in the map
                        if ( !lizMap.map.restrictedExtent.intersectsBounds( geom.getBounds() ) ){
                            lizMap.addMessage( "La zone envoyée n'est pas dans l'emprise de la carte. La donnée doit être dans la projection de la carte :  " + lizMap.map.getProjection(), 'error', true );
                            break;
                        }
                        // sum total surface
                        totalSurf += geom.getArea();
                        // break if total surface is enough than maxAreaQuery
                        if ( totalSurf >= OccTax.config.maxAreaQuery ) {
                            lizMap.addMessage( 'La surface totale des objets est trop importante (doit être < ' +  OccTax.config.maxAreaQuery + ' )', 'error', true );
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
                        lizMap.addMessage( data.msg.join('<br/>'), 'info', true );
                    }
                } else
                    lizMap.addMessage( data.msg.join('<br/>'), 'error', true );
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
                    theLayer = OccTax.layers['queryLayer'];
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
                    if(ac == 'occtax_results_observation_table_div'){
                      getObservationDetail(evt.feature.fid);
                    }

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
        $('#occtax_search_input').show();
        $('#occtax_search_description').hide();
        $('#occtax_search_result').hide();
        $('#occtax-search-replay').toggle();
        $(this).toggle();
        //return false;
      });
      $('#occtax-search-replay').click(function(){
        $('#occtax_search_input').hide();
        $('#occtax_search_description').show();
        $('#occtax_search_result').show();
        $('#occtax-search-modify').toggle();
        $(this).toggle();
        //return false;
      });

      // Get search token corresponding to form inputs
      unblockSearchForm();
      $('#'+tokenFormId).submit(function(){
        // Bloc submit if a previous submit is in progress
        if(blocme){
          return false;
        }
        blocme = true;

        // Do nothing if token is not defined

        var self = $(this);

        // The Occtax events trigger an error on first load (when page not entirely loaded)
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
        $.getJSON(self.attr('action'), self.serialize(),
            function(tData) {
                blocme = false;
                if (tData.status == 1) {
                    // Display description div
                    var dHtml = tData.description;
                    $('#occtax_search_description_content').html(dHtml);
                    var dockHeight = $('#dock').height();
                    if(dockHeight >= 800)
                      $('#occtax_search_description').show();
                    else
                      $('#occtax_search_description').hide();
                    $('#occtax_search_description').prev('h3.occtax_search').show();
                    $('#occtax-search-modify').show();
                    $('#occtax-search-replay').hide();

                    // Change wfs export URL
                    $('a.btn-get-wfs').attr('href', tData.wfsUrl);

                    // Hide form div
                    $('#occtax_search_input').hide();

                    // Run and display searched data
                    $('#occtax_service_search_stats_form input[name="token"]').val(tData.token).change();
                    $('#occtax_results_stats_table').DataTable().ajax.reload();
                    $('#occtax_service_search_taxon_form input[name="token"]').val(tData.token).change();
                    $('#occtax_results_taxon_table').DataTable().ajax.reload();
                    $('#occtax_service_search_maille_form_m01 input[name="token"]').val(tData.token).change();
                    $('#occtax_results_maille_table_m01').DataTable().ajax.reload();
                    $('#occtax_service_search_maille_form_m02 input[name="token"]').val(tData.token).change();
                    $('#occtax_results_maille_table_m02').DataTable().ajax.reload();
                    //$('#occtax_service_search_maille_form_m05 input[name="token"]').val(tData.token).change();
                    //$('#occtax_results_maille_table_m05').DataTable().ajax.reload();
                    $('#occtax_service_search_maille_form_m10 input[name="token"]').val(tData.token).change();
                    $('#occtax_results_maille_table_m10').DataTable().ajax.reload();
                    $('#occtax_service_search_form input[name="token"]').val(tData.token).change();
                    $('#occtax_results_observation_table').DataTable().ajax.reload();

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
                  lizMap.addMessage( tData.msg.join('<br/>'), 'error', true );
                }
            }
        );
        return false;
      });


      $('#'+tokenFormId+'_where').append( $('#obs-spatial-query-buttons') );
      //~ $('#'+tokenFormId+'_where .jforms-table-group').hide();
      $('#'+tokenFormId+'_what').append( $('#occtax_taxon_select_div') );
      //~ $('#'+tokenFormId+'_what .jforms-table-group').hide();
      $('#'+tokenFormId+'_what .jforms-table-group .control-group:nth-last-child(-n+2)').hide();

      // Réinitialisation du formulaire
      // On supprime les géométries de recherche
      // On masque les résultats
      $('#'+tokenFormId+'_reinit').click(function(){
          clearTaxonFromSearch();
          clearSpatialSearch();
          OccTax.emptyDrawqueryLayer('queryLayer');
          try{
            OccTax.events.triggerEvent('mailledatareceived_' + 'm01', {'results':null});
            OccTax.events.triggerEvent('mailledatareceived_' + 'm02', {'results':null});
            //OccTax.events.triggerEvent('mailledatareceived_' + 'm05', {'results':null});
            OccTax.events.triggerEvent('mailledatareceived_' + 'm10', {'results':null});
            OccTax.events.triggerEvent('observationdatareceived', {'results':null});
          }catch(e){
            var myerror = e;
          }

          $('#occtax_search_result, #occtax_search_description, #occtax_search_observation_card')
          .hide()
          .prev('h3.occtax_search').hide()
          ;

          //return false;
      });


      addResultsStatsTable();
      addResultsTaxonTable();
      addResultsMailleTable('m01');
      addResultsMailleTable('m02');
      //addResultsMailleTable('m05');
      addResultsMailleTable('m10');
      addResultsObservationTable();

      initFormTaxon();
      addTaxonTable();

      $('#occtax_results_draw .btn').click(function() {
        var self = $(this);

        // Get layer
        var rLayer = OccTax.layers['resultLayer'];

        rLayer.destroyFeatures();
        var the_features = OccTax.getResultFeatures( self.val());

        // For mailles, add features to draw the underlying maille
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
      $('a.btn-export-search').click(function() {
        var eFormat = $(this).text();
        var exportUrl = $('#'+tokenFormId).attr('action');
        if( eFormat.toLowerCase() == 'dee' )
          exportUrl = exportUrl.replace('initSearch', 'exportDee');
        else if( eFormat.toLowerCase() == 'geojson' )
          exportUrl = exportUrl.replace('initSearch', 'exportGeoJSON');
        else
          exportUrl = exportUrl.replace('initSearch', 'exportCsv');

        exportUrl+= '?token=' + $('#occtax_service_search_stats_form input[name="token"]').val();
        exportUrl+= '&format=' + eFormat;

        window.open(exportUrl);
        return false;

      });

      // Toggle search div via h3
      $('h3.occtax_search').click(function(){
        // Toggle next div visibility
        var ndiv = $(this).next('div:first');
        ndiv.toggle();
        if(
          ndiv.attr('id') == 'occtax_search_observation_card'
          && ! ndiv.is(':visible')
        ){
          // Reopen results div id needed
          $('#occtax_search_result').show();
          $('#occtax_search_description').show();
        }
        var tid = $('#occtax_search_result div.tab-pane.active').attr('id');

        // Refresh size of datatable table (for scrolling)
        refreshOcctaxDatatableSize('#' + tid);
      });


      // Clear Taxon search with button
      $('#clearTaxonSearch').click(function(){
        clearTaxonFromSearch();
        return false;
      });

      // Hide taxon menu icon in menubar
      $('#button-taxon').parent('li.taxon').hide();
      // Hide occtax table menu icon
      //$('#mapmenu li.occtax_tables').hide();


      // Ajout du logo
      //$('#attribution-box').append('<img src="'+ jFormsJQ.config.basePath + 'css/img/logo_europe_mini.jpg" title="KaruNati est cofinancé par l’Union européenne. L’Europe s’engage en Guadeloupe avec le FEDER" />');

      // Masquer le metadata
      $('#mapmenu li.metadata').hide();

      // Déplacement des icônes Lizmap de la barre de menu de gauche
      moveLizmapMenuLi(occtaxClientConfig.menuOrder);


      // Modification du mot "Rechercher"
      $('#search-query').attr('placeholder', 'Rechercher un lieu');

      // On replie les couches
      $('#layers-fold-all').click();

      // Ajout des tooltip sur les boutons
      $('#occtax button').tooltip();

      // Refresh datatable size when bottom dock changes
    lizMap.events.on({
        bottomdocksizechanged: function(evt) {
           var mycontainer = $('#occtax_tables div.bottom-content.active');
           refreshOcctaxDatatableSize(mycontainer);
        }
    });


    }
});
