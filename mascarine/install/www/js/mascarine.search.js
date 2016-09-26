$(document).ready(function () {

    function getDatatableColumns( tableId ){
      var DT_Columns = $('#'+tableId+' thead tr th').map(
        function(){
          var dv = $(this).attr('data-value');
          var sp = dv.split(',');
          var ret = {
            'data': sp[0],
            'type': sp[1],
            'sortable': ( sp[2] == 'true' )
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
        Mascarine.deactivateAllDrawqueryControl();

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
            Mascarine.validGeometryFeature( feature );
            theLayer.drawFeature( feature );
            var geom = feature.geometry.clone().transform( Mascarine.map.projection, 'EPSG:4326' );
            $('#jforms_mascarine_search_geom').val( geom.toString() );
            $('#jforms_mascarine_search_code_commune').val('');
            $('#jforms_mascarine_search_code_maille').val('');
        } else {
            // query geom
            if (feature.geometry.CLASS_NAME === 'OpenLayers.Geometry.Point') {
                var myPoint = feature.geometry.clone().transform( Mascarine.map.projection, 'EPSG:4326' );
                //console.log( myPoint.x, myPoint.y );
                if ( activeButton.hasClass('maille') ) {
                    var form = $('#form_mascarine_service_maille');
                    $.post(form.attr('action')
                      ,{x:myPoint.x, y:myPoint.y}
                      , function( data ) {
                          if ( data.status == 1 ) {
                              var format = new OpenLayers.Format.GeoJSON();
                              var geom = format.read( data.result.geojson )[0].geometry;
                              $('#jforms_mascarine_search_geom').val( geom.toString() );
                              $('#jforms_mascarine_search_code_commune').val('');
                              $('#jforms_mascarine_search_code_maille').val( data.result.code_maille );
                              theLayer.destroyFeatures(feature);
                              geom.transform('EPSG:4326', Mascarine.map.projection);
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
                    var form = $('#form_mascarine_service_commune');
                    $.post(form.attr('action')
                      ,{x:myPoint.x, y:myPoint.y}
                      , function( data ) {
                          if ( data.status == 1 ) {
                              var format = new OpenLayers.Format.GeoJSON();
                              var geom = format.read( data.result.geojson )[0].geometry;
                              $('#jforms_mascarine_search_geom').val( '' );
                              $('#jforms_mascarine_search_code_commune').val( data.result.code_commune );
                              $('#jforms_mascarine_search_code_maille').val( '' );
                              theLayer.destroyFeatures(feature);
                              geom.transform('EPSG:4326', Mascarine.map.projection);
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
            var geom = evt.feature.geometry.clone().transform( Mascarine.map.projection, 'EPSG:4326' );
            $('#jforms_mascarine_search_geom').val( geom.toString() );
            $('#jforms_mascarine_search_code_commune').val('');
            $('#jforms_mascarine_search_code_maille').val('');
        }
    }

    function addTaxonToSearch( cd_nom, nom_cite ) {
        //~ console.log(cd_nom, nom_cite);
        var ctrl_cd_nom = $('#div_form_mascarine_search_token form [name="cd_nom[]"]');
        $('#mascarine_taxon_select_params').html( '' ).hide();
        $('#mascarine_taxon_select_list').show();
        var ctrl_cd_nom = $('#div_form_mascarine_search_token form [name="cd_nom[]"]');
        var selectVals = ctrl_cd_nom.val();
        if ( selectVals == null )
            selectVals = [];
        if ( selectVals.indexOf( cd_nom ) == -1 ) {
            ctrl_cd_nom.append('<option selected value="'+cd_nom+'">'+nom_cite+'</option>');
            var li = $('<li data-value="'+cd_nom+'" style="height:20px; margin-left:2px;"><span style="display:inline-block; width:190px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">'+nom_cite+'</span><button type="button" class="close" value="'+cd_nom+'" aria-hidden="true">&times;</button></li>');
            $('#mascarine_taxon_select_list').append(li);
            li.find('.close').click(function(){
                deleteTaxonToSearch( $(this).attr('value') );
            });
        }
    }

    function deleteTaxonToSearch( cd_nom ) {
      $('#div_form_mascarine_search_token form [name="cd_nom[]"] option[value="'+cd_nom+'"]').remove();
      var li = $('#mascarine_taxon_select_list li[data-value="'+cd_nom+'"]');
      li.find('.close').unbind('click');
      li.remove();
    }

    function clearTaxonToSearch() {
        $('#div_form_mascarine_search_token form [name="cd_nom[]"]').html('');
        $('#mascarine_taxon_select_list .close').unbind('click');
        $('#mascarine_taxon_select_list').html('');
    }

    function addResultsStatsTable() {
      var tableId = 'mascarine_results_stats_table';
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
            "pageLength":50,
            "language": {url:lizUrls["dataTableLanguage"]},
            "columns": DT_Columns,
            "ajax": function (param, callback, settings) {
                var searchForm = $('#mascarine_service_search_stats_form');

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
                          callback( tData );
                    }
                );
            }
        });
    }

    function addResultsTaxonTable() {
      var tableId = 'mascarine_results_taxon_table';
      // Get taxon fields to display
      var returnFields = $('#'+tableId+'').attr('data-value').split(',');
      var DT_RowId = $('#'+tableId+' thead tr').attr('data-value');
      var datatableColumns = getDatatableColumns( tableId );
      var DT_Columns = datatableColumns[0];
      var displayFields = datatableColumns[1];
      $('#'+tableId+'').DataTable( {
            "lengthChange": false,
            "searching": false,
            "dom":'ipt',
            "pageLength":50,
            "language": {url:lizUrls["dataTableLanguage"]},
            "columns": DT_Columns,
            "ajax": function (param, callback, settings) {
                var searchForm = $('#mascarine_service_search_taxon_form');

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
                          callback( tData );
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
              clearTaxonToSearch();
              //~ console.log( cd_nom, d[row_label] );
              addTaxonToSearch( cd_nom, d[row_label] );
              $('#div_form_mascarine_search_token form').submit();
              return false;
          });
        });
    }

    function addResultsMailleTable() {
      var tableId = 'mascarine_results_maille_table';
      // Get maille fields to display
      var returnFields = $('#'+tableId+'').attr('data-value').split(',');
      var DT_RowId = $('#'+tableId+' thead tr').attr('data-value');
      var datatableColumns = getDatatableColumns( tableId );
      var DT_Columns = datatableColumns[0];
      var displayFields = datatableColumns[1];
      $('#'+tableId+'').DataTable( {
            "lengthChange": false,
            "searching": false,
            "dom":'ipt',
            "pageLength":50,
            "language": {url:lizUrls["dataTableLanguage"]},
            "columns": DT_Columns,
            "ajax": function (param, callback, settings) {
                var searchForm = $('#mascarine_service_search_maille_form');

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
                            Mascarine.events.triggerEvent('mailledatareceived', {'results':results});

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
                          if ( $('#mascarine_results_draw_maille').hasClass('active') )
                              $('#mascarine_results_draw_maille').click();
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
              //var maille = Mascarine.getMaille( mId );
              var maille = Mascarine.layers.resultLayer.getFeatureByFid(mId);
              $('#obs-spatial-query-maille').click();
              var mailleSelect = maille.clone();
              Mascarine.layers['queryLayer'].addFeatures([mailleSelect]);
              onQueryFeatureAdded( mailleSelect, function() {
                $('#div_form_mascarine_search_token form').submit();
              });
              return false;
          });
          $('#'+tableId+' tbody tr').hover(function(){
              var tr = $(this);
              var mId = tr.attr('id');
              var maille = Mascarine.layers.resultLayer.getFeatureByFid(mId);
              Mascarine.controls['select']['highlightCtrl'].highlight( maille );
          },function(){
              var tr = $($(this).parents('tr')[0]);
              var mId = tr.attr('id');
              var maille = Mascarine.layers.resultLayer.getFeatureByFid(mId);
              Mascarine.controls['select']['highlightCtrl'].unhighlight( maille );
          });
        });
    }

    function addResultsObservationTable() {
      var tableId = 'mascarine_results_observation_table';
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
            "pageLength":50,
            "searching": false,
            "dom":'ipt',
            "language": {url:lizUrls["dataTableLanguage"]},
            "processing": true,
            "serverSide": true,
            "columns": DT_Columns,
            "ajax": function (param, callback, settings) {
              var searchForm = $('#mascarine_service_search_form');
              //console.log( param );
              searchForm.find('input[name="limit"]').val(param.length);
              searchForm.find('input[name="offset"]').val(param.start);
              searchForm.find('input[name="group"]').val('');
              searchForm.find('input[name="order"]').val(
                DT_Columns[param.order[0]['column']]['data'] + ':' + param.order[0]['dir']
              );
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
                    Mascarine.events.triggerEvent('observationdatareceived', {'results':results});

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
                  if ( $('#mascarine_results_draw_observation').hasClass('active') )
                    $('#mascarine_results_draw_observation').click();
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
              var obs = Mascarine.layers.resultLayer.getFeatureByFid(obsId);
              if( obs )
                Mascarine.controls['select']['highlightCtrl'].highlight( obs );
          },function(){
              var tr = $(this);
              var obsId = tr.attr('id');
              var obs = Mascarine.layers.resultLayer.getFeatureByFid(obsId);
              if( obs )
                Mascarine.controls['select']['highlightCtrl'].unhighlight( obs );
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

    function initFormAddTaxon() {
      var formId = $('#div_form_mascarine_taxon_search_token form').attr('id');
      $('#'+formId+'_autocomplete').autocomplete({
        minLength:2,
        autoFocus: true,
        source:function( request, response ) {
            request.limit = $('#form_mascarine_taxon_service_autocomplete input[name="limit"]').val();
            $.getJSON($('#form_mascarine_taxon_service_autocomplete').attr('action'),
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
          $(this).val( $('<a>').html(ui.item.nom_valide).text() );
          $('#'+formId+'_cd_ref').val( ui.item.cd_ref );
          $('#'+formId+' select').val('');
          if ( $('#'+formId+'_filter > div').is(':visible') ) {
            $('#'+formId+'_filter > legend > button').click();
          }
          $('#'+formId).submit();
          return false;
        }
      }).autocomplete( "widget" ).css("z-index","1060");
      $('#'+formId+'_autocomplete').autocomplete( "instance" )._renderItem = function( ul, item ) {
        console.log(jFormsJQ.config.basePath + 'css/images/taxon/' + item.groupe + '.png');
        return $( "<li>" )
        .append( $("<a>").html(  $("<a>").html( '<img src="'+ jFormsJQ.config.basePath + 'css/images/taxon/' + item.groupe + '.png" width="15" height="15"/>&nbsp;' + item.label )  ) )
        .appendTo( ul );
      };
      $('#'+formId).submit(function(){
        var self = $(this);
        $.getJSON(self.attr('action'), self.serialize(),
          function(tData) {
            //(tData);
            if (tData.status == 1) {
              $('#form_mascarine_taxon_service_search input[name="token"]').val(tData.token);
              $('#mascarine_results_add_taxon_table').DataTable().ajax.reload();
              $('#mascarine_results_add_taxon_description').html( tData.description );
            }
          });
        return false;
      });
      $('#'+formId+'_reinit').click(function(){
          $('#'+formId+'_cd_ref').val( '' );
      });
      $('#'+formId+'_filter > div').hide();
      $('#'+formId+'_filter > legend').html('<button class="btn" data-toggle="button">'+$('#'+formId+'_filter > legend').text()+'<span class="caret"></span></button>');
      $('#'+formId+'_filter > legend > button').click( function(){
        //$(this).toggle();
        $('#'+formId+'_filter > div').toggle();
        return false;
      });

      $('#mascarine_results_add_taxon_button').click(function(){
        var token = $('#form_mascarine_taxon_service_search input[name="token"]').val();
        var description = $('#mascarine_results_add_taxon_description').html();
        clearTaxonToSearch();
        $('#div_form_mascarine_search_token form [name="search_token"]').val( token );
        $('#mascarine_taxon_select_list').hide();
        $('#mascarine_taxon_select_params').html( description ).show();
        $('#div_form_mascarine_search_token form').submit();
      });
    }

    function addResultsAddTaxonTable() {
      var tableId = 'mascarine_results_add_taxon_table';
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
            "language": {url:lizUrls["dataTableLanguage"]},
            "processing": true,
            "serverSide": true,
            "columns": DT_Columns,
            "ajax": function (param, callback, settings) {
              var searchForm = $('#form_mascarine_taxon_service_search');
              searchForm.find('input[name="limit"]').val(param.length);
              searchForm.find('input[name="offset"]').val(param.start);
              searchForm.find('input[name="order"]').val(
                DT_Columns[param.order[0]['column']]['data'] + ':' + param.order[0]['dir']
              );
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
              $('#div_form_mascarine_search_token form').submit();
              return false;
          });
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
          $(this).val( $('<a>').html(ui.item.nom_valide).text() );
          $('#'+formId+'_cd_ref').val( ui.item.cd_ref );
          $('#'+formId+' select').val('');
          if ( $('#'+formId+'_filter > div').is(':visible') ) {
            $('#'+formId+'_filter > legend > button').click();
          }
          $('#'+formId).submit();
          return false;
        }
      }).autocomplete( "widget" ).css("z-index","1050");
      $('#'+formId+'_autocomplete').autocomplete( "instance" )._renderItem = function( ul, item ) {
        console.log(jFormsJQ.config.basePath + 'css/images/taxon/' + item.groupe + '.png');
        return $( "<li>" )
        .append( $("<a>").html(  $("<a>").html( '<img src="'+ jFormsJQ.config.basePath + 'css/images/taxon/' + item.groupe + '.png" width="15" height="15"/>&nbsp;' + item.label )  ) )
        .appendTo( ul );
      };
      $('#'+formId).submit(function(){
        var self = $(this);
        $.getJSON(self.attr('action'), self.serialize(),
          function(tData) {
            //(tData);
            if (tData.status == 1) {
              $('#form_taxon_service_search input[name="token"]').val(tData.token);
              $('#table_taxon_results').DataTable().ajax.reload();
            }
          });
        return false;
      });
      $('#'+formId+'_reinit').click(function(){
          $('#'+formId+'_cd_ref').val( '' );
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
            "language": {url:lizUrls["dataTableLanguage"]},
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
              $('#div_form_mascarine_search_token form').submit();
              // Show observation search form
              $('#mapmenu #button-mascarine').click();
              return false;
          });
        });
    }

    function getObservationDetail( id ) {
        if(!id)
            return;
        var tokenFormId = $('#div_form_mascarine_search_token form').attr('id');
        var obsUrl = $('#'+tokenFormId).attr('action').replace('getSearchToken', 'getObservation');
        obsUrl = obsUrl.replace('service', 'observation');
        $.get(
            obsUrl,
            {'id': id},
            function( data ) {
                var sLeft = lizMap.getDockRightPosition();
                $('#sub-dock').html( data ).css('width','auto').css('height', '100%').css( 'left', sLeft ).show();
                $('#sub-dock i.close').click(function(){
                    $('#sub-dock').hide();
                });

            }
        );
    }

Mascarine.events.on({
    'uicreated':function(evt){
        //~ console.log('Mascarine uicreated search');

        Mascarine.controls['query'] = {};
        /**
          * Ajout de la couche openlayers des requêtes cartographiques
          */
        var queryLayer = new OpenLayers.Layer.Vector("queryLayer", {styleMap:Mascarine.drawStyleMap});
        Mascarine.map.addLayers([queryLayer]);
        Mascarine.layers['queryLayer'] = queryLayer;

        /**
         * Point
         * @type @new;OpenLayers.Control.DrawFeature
         */
        var queryPointLayerCtrl = new OpenLayers.Control.DrawFeature(queryLayer,
          OpenLayers.Handler.Point, {'featureAdded': onQueryFeatureAdded}
        );
        Mascarine.map.addControl(queryPointLayerCtrl);
        Mascarine.controls['query']['queryPointLayerCtrl'] = queryPointLayerCtrl;

        /**
         * Circle
         * @type @new;OpenLayers.Control.DrawFeature
         */
        var queryCircleLayerCtrl = new OpenLayers.Control.DrawFeature(queryLayer,
            OpenLayers.Handler.RegularPolygon,
            { handlerOptions: {sides: 40}, 'featureAdded': onQueryFeatureAdded}
        );
        Mascarine.map.addControl(queryCircleLayerCtrl);
        Mascarine.controls['query']['queryCircleLayerCtrl'] = queryCircleLayerCtrl;

        /**
         * Polygon
         * @type @new;OpenLayers.Control.DrawFeature
         */
        var queryPolygonLayerCtrl = new OpenLayers.Control.DrawFeature(queryLayer,
            OpenLayers.Handler.Polygon, {'featureAdded': onQueryFeatureAdded, styleMap:Mascarine.drawStyleMap}
        );
        Mascarine.map.addControl(queryPolygonLayerCtrl);
        Mascarine.controls['query']['queryPolygonLayerCtrl'] = queryPolygonLayerCtrl;

        /**
         * Controle de modification d'un polygone
         * @type @new;OpenLayers.Control.ModifyFeature
         */
        var modifyPolygonLayerCtrl = new OpenLayers.Control.ModifyFeature(queryLayer, {styleMap:Mascarine.drawStyleMap});
        Mascarine.map.addControl(modifyPolygonLayerCtrl);
        Mascarine.controls['query']['modifyPolygonLayerCtrl'] = modifyPolygonLayerCtrl;
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
                        if ( !lizMap.map.restrictedExtent.intersectsBounds( geom.getBounds() ) )
                            continue;
                        // sum total surface
                        totalSurf += geom.getArea();
                        // break if total surface is enough than maxAreaQuery
                        if ( totalSurf >= Mascarine.config.maxAreaQuery ) {
                            lizMap.addMessage( 'Surface totale trop importante', 'error', true );
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
                        Mascarine.layers['queryLayer'].addFeatures( multiFeat );
                        onQueryFeatureAdded( multiFeat );
                        lizMap.addMessage( data.msg.join('<br/>'), 'info', true );
                    }
                } else
                    lizMap.addMessage( data.msg.join('<br/>'), 'error', true );
            }
        });

        $('#obs-spatial-query-buttons button').button().click(function(){
            var self = $(this);
            var dataValue = self.attr('data-value');

            if ( dataValue != 'modifyPolygon' ) {
              $('#obs-spatial-query-modify').hide();
              $('#obs-spatial-query-modify').removeClass('active');
            }

            if ( dataValue == 'deleteGeom' ) {
                Mascarine.emptyDrawqueryLayer('resultLayer');
                Mascarine.deactivateAllDrawqueryControl();
                $('#jforms_mascarine_search_geom').val('');
                $('#jforms_mascarine_search_code_commune').val('');
                $('#jforms_mascarine_search_code_maille').val('');
                $('#obs-spatial-query-buttons button').removeClass('active');
                return false;
            }
            if ( dataValue == 'importPolygon' ) {
                $('#obs-spatial-upload-geojson form input[type="file"]').click();
                //return false;
            }
            if ( dataValue == 'modifyPolygon' ) {
                if(Mascarine.controls['query']['modifyPolygonLayerCtrl'].active) {
                    self.removeClass('active');
                    theLayer = Mascarine.layers['queryLayer'];
                    var feature = theLayer.features[0];
                    Mascarine.validGeometryFeature( feature );
                    theLayer.drawFeature( feature );
                    var geom = feature.geometry.clone().transform( Mascarine.map.projection, 'EPSG:4326' );
                    $('#jforms_mascarine_search_geom').val( geom.toString() );
                    $('#jforms_mascarine_search_code_commune').val('');
                    $('#jforms_mascarine_search_code_maille').val('');
                    Mascarine.controls['query']['modifyPolygonLayerCtrl'].deactivate();
                    Mascarine.controls['query']['modifyPolygonLayerCtrl'].moveLayerBack();
                    return false;
                } else {
                    Mascarine.oneCtrlAtATime( dataValue, 'query', ['queryLayer','resultLayer'] );
                    Mascarine.controls['query']['modifyPolygonLayerCtrl'].activate();
                    Mascarine.controls['query']['modifyPolygonLayerCtrl'].selectFeature( Mascarine.layers['queryLayer'].features[0] );
                    self.addClass('active');
                }
            } else {
                Mascarine.oneCtrlAtATime( dataValue, 'query', 'resultLayer');//, 'resultLayer'
                //$('#map').css('cursor','pointer');
            }
        });


        Mascarine.controls['select'] = {};
        /**
          * Ajout de la couche openlayers des résultats
          */
        //console.log(Mascarine.resultLayerStyleMap);
        var resultLayer = new OpenLayers.Layer.Vector("resultLayer", {styleMap:Mascarine.resultLayerStyleMap});
        Mascarine.map.addLayers([resultLayer]);
        Mascarine.layers['resultLayer'] = resultLayer;

        var highlightCtrl = new OpenLayers.Control.SelectFeature(resultLayer, {
            hover: true,
            highlightOnly: true,
            renderIntent: "select",
            eventListeners: {
                beforefeaturehighlighted: function(evt){
                    $('#mascarine-highlight-message').remove();
                },
                featurehighlighted: function(evt){
                    lizMap.addMessage(evt.feature.attributes.message_text,'info',true).attr('id','mascarine-highlight-message');
                    var tr = $('tr#'+evt.feature.fid);
                    if (tr.length != 0 )
                        tr.addClass('info');
                },
                featureunhighlighted: function(evt){
                    $('#mascarine-highlight-message').fadeOut('slow', function(){
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
                    var tr = $('tr#'+evt.feature.fid);
                    var dockContent = $('#dock-content');
                    if ( tr.length != 0 )
                        dockContent.animate({scrollTop: tr.offset().top + dockContent.scrollTop() - dockContent.offset().top - tr.height() });
                }
            }
        });
        Mascarine.map.addControl( highlightCtrl );
        Mascarine.map.addControl( selectCtrl );
        Mascarine.controls['select']['highlightCtrl'] = highlightCtrl;
        Mascarine.controls['select']['selectCtrl'] = selectCtrl;
        Mascarine.controls['select']['highlightCtrl'].activate();
        Mascarine.controls['select']['selectCtrl'].activate();

        //activate tabs
        $('#mascarine_results_tabs a').tab();

      // Get token form id
      var tokenFormId = $('#div_form_mascarine_search_token form').attr('id');

      // Toggle pannel display
      $('#mascarine-search-modify').click(function(){
        $('#mascarine_search_input').show();
        $('#mascarine_search_description').show();
        $('#mascarine_search_result').hide();
        $('#mascarine-search-replay').toggle();
        $(this).toggle();
      });
      $('#mascarine-search-replay').click(function(){
        $('#mascarine_search_input').hide();
        $('#mascarine_search_description').show();
        $('#mascarine_search_result').show();
        $('#mascarine-search-modify').toggle();
        $(this).toggle();
      });

      // Get search token corresponding to form inputs
      $('#'+tokenFormId).submit(function(){
        var self = $(this);
        $('#mascarine_result_button_bar').hide();

        // show statistics
        $('#mascarine_results_stats_table_tab').tab('show');
        // deactivate geometry button
        $('#obs-spatial-query-buttons button.active').click();

        $.getJSON(self.attr('action'), self.serialize(),
            function(tData) {
                if (tData.status == 1) {
                    // Display description div
                    $('#mascarine_search_description_content').html(tData.description);
                    $('#mascarine_search_description').show();
                    $('#mascarine-search-modify').show();
                    $('#mascarine-search-replay').hide();

                    // Hide form div
                    $('#mascarine_search_input').hide();

                    // Run and display searched data
                    $('#mascarine_service_search_stats_form input[name="token"]').val(tData.token).change();
                    $('#mascarine_results_stats_table').DataTable().ajax.reload();
                    $('#mascarine_service_search_taxon_form input[name="token"]').val(tData.token).change();
                    $('#mascarine_results_taxon_table').DataTable().ajax.reload();
                    $('#mascarine_service_search_maille_form input[name="token"]').val(tData.token).change();
                    $('#mascarine_results_maille_table').DataTable().ajax.reload();
                    $('#mascarine_service_search_form input[name="token"]').val(tData.token).change();
                    $('#mascarine_results_observation_table').DataTable().ajax.reload();
                    // Show result div
                    $('#mascarine_search_result').show();
                    $('#mascarine_result_button_bar').show();
                }
            }
        );

        return false;
      });
      $('#'+tokenFormId+'_where').append( $('#obs-spatial-query-buttons') );
      //~ $('#'+tokenFormId+'_where .jforms-table-group').hide();
      $('#'+tokenFormId+'_what').append( $('#mascarine_taxon_select_div') );
      //~ $('#'+tokenFormId+'_what .jforms-table-group').hide();
      $('#'+tokenFormId+'_what .jforms-table-group .control-group:nth-last-child(-n+2)').hide();

      //FIXME
      $('#'+tokenFormId+'_reinit').click(function(){
          clearTaxonToSearch();
      });

      addResultsStatsTable();
      addResultsTaxonTable();
      addResultsMailleTable();
      addResultsObservationTable();

      initFormAddTaxon();
      addResultsAddTaxonTable();

      initFormTaxon();
      addTaxonTable();

      $('#mascarine_results_draw .btn').click(function() {
        var self = $(this);
        // Get layer
        var rLayer = Mascarine.layers['resultLayer'];
        rLayer.destroyFeatures();
        rLayer.addFeatures( Mascarine.getResultFeatures( self.val()) );
        rLayer.setVisibility(true);
        rLayer.refresh();
      });
      $('#mascarine_results_tabs a').on('shown', function (e) {
          if ( $(e.target).attr('id') == 'mascarine_results_observation_table_tab' )
            $('#mascarine_results_draw_observation').click();
          else if ( $(e.relatedTarget).attr('id') == 'mascarine_results_observation_table_tab' )
            $('#mascarine_results_draw_maille').click();
      });
      $('#mascarine_results_zoom').click(function() {
          var rLayer = Mascarine.layers['resultLayer'];
          Mascarine.map.zoomToExtent( rLayer.getDataExtent() );
      });
      $('#mascarine_results_export').click(function() {
        var exportUrl = $('#'+tokenFormId).attr('action').replace('getSearchToken', 'exportObservation');
        exportUrl+= '?token=' + $('#mascarine_service_search_stats_form input[name="token"]').val();
        window.open(exportUrl);
      });


      // Ajout du logo Europe
      $('#attribution-box').append('<img src="'+ jFormsJQ.config.basePath + 'css/img/logo_europe_mini.jpg" title="KaruFlore est cofinancé par l’Union européenne. L’Europe s’engage en Guadeloupe avec le FEDER" />');

    }
});

});
