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

    function resetDrawButtonToolbar() {
        $( "#obs-spatial-draw-buttons button" ).each(function( index ) {
            $(this).removeClass('active');
        });
        //$('#spatialDrawButtonsMsg').empty();
    };
    function updateUnvalidateObservationFeatures() {

        var rLayer = Mascarine.layers['resultLayer'];
        var features = Mascarine.getResultFeatures( 'unvalidate' );
        if ( rLayer.features.length != 0 ) {
            var newFIDs = $.map( features, function(f, i) {
                return f.fid;
            });
            var oldFIDs = $.map( rLayer.features, function(f, i) {
                return f.fid;
            });
            for ( var i=0, len=features.length; i<len; i++ ) {
                var f = features[i];
                if ( oldFIDs.indexOf( f.fid ) != -1 ) {
                    var feat = rLayer.getFeatureByFid( f.fid );
                    f.geometry.id = feat.geometry.id;
                    feat.attributes = OpenLayers.Util.extend( feat.attributes, f.attributes );
                    feat.geometry = f.geometry;
                } else
                    rLayer.addFeatures( [f] );
            }
            for( var i=0, len=oldFIDs.length; i<len; i++ ) {
                var fid  = oldFIDs[i];
                if ( newFIDs.indexOf( fid ) == -1 ) {
                    rLayer.destroyFeatures( [rLayer.getFeatureByFid( fid )] );
                }
            }
        } else
            rLayer.addFeatures( features );
        rLayer.setVisibility(true);
        rLayer.refresh();

    };
    function drawFeatureAdded( feature ) {
        //only one feature at a time
        /*
        if(feature.layer.features.length > 1){
          feature.layer.destroyFeatures(feature.layer.features.shift());
        }
        * */

        // on active le contrôle de modification
        Mascarine.oneCtrlAtATime( 'drawModify', 'draw', ['drawLayer','resultLayer'] );
        Mascarine.controls['draw']['drawModifyLayerCtrl'].selectFeature(feature);

        // on redessine
        feature.layer.redraw();

        // Curseur normal
        $('#map').css('cursor', 'default');

        // On efface le message sous les boutons
        resetDrawButtonToolbar();
        // remove disbled on split button
        $( "#obs-spatial-draw-buttons button.split" ).removeClass('disabled');

        saveTemp();
    }

    // Controle visuel de découpe
    function flashFeatures(features, index) {
        var drawLayer = Mascarine.layers['drawLayer'];
        if(!index) {
            index = 0;
        }
        var current = features[index];
        if(current && current.layer === drawLayer) {
            drawLayer.drawFeature(features[index], "select");
        }
        var prev = features[index-1];
        if(prev && prev.layer === drawLayer && prev.layer.selectedFeatures.indexOf( prev ) == -1) {
            drawLayer.drawFeature(prev, "default");
        }
        ++index;
        if(index <= features.length) {
            window.setTimeout(function() {flashFeatures(features, index);}, 100);
        }
    }

    function intersectionWithCommuneAndMaille() {
        var drawLayer = Mascarine.layers['drawLayer'];
        var feat = Mascarine.controls['draw']['drawModifyLayerCtrl'].feature;
        if ( feat ) {
            var wkt = feat.geometry.clone().transform( Mascarine.map.getProjection(), 'EPSG:4326' ).toString();
            var form = $('#form_mascarine_service_intersectGeometry');
            $.post(form.attr('action')
              ,{wkt:wkt}
              , function( data ) {
                  //console.log(data);
                  if ( data.result.length > 0 ) {
                      var format = new OpenLayers.Format.GeoJSON();
                      var features = [];
                      for ( var i = 0, len=data.result.length; i<len; i++ ) {
                          var r = data.result[i];
                          var geom = format.read( r.geojson )[0].geometry;
                          geom.transform('EPSG:4326', Mascarine.map.projection);
                          delete r.geojson;
                          features.push( new OpenLayers.Feature.Vector( geom, r ) );
                      }
                      // Désactivation du control de modification
                      Mascarine.controls['draw']['drawModifyLayerCtrl'].deactivate();
                      resetDrawButtonToolbar();
                      // Supression
                      drawLayer.destroyFeatures( [feat] );
                      // Activation du control de modification
                      drawLayer.addFeatures( features );
                      Mascarine.oneCtrlAtATime( 'drawModify', 'draw', ['drawLayer','resultLayer'] );
                      Mascarine.controls['draw']['drawModifyLayerCtrl'].selectFeature(features[0]);
                      flashFeatures(features);
                  }
              }
            );
        }
    }

    function addOrganisme( aForm ) {
        var form = $('#form_mascarine_organisme_add');
        $.get(form.attr('action'),{}
          , function( data ) {
                  $('#lizmap-modal').html(data);
                  $('#lizmap-modal form').submit(function() {
                      var self = $(this);
                      $.post( self.attr('action'), self.serialize()
                        , function( result ) {
                            if ( result.status == 1 ) {
                                // add to control
                                var opt = document.createElement('option');
                                opt.setAttribute('value', result.result.id_org);
                                opt.appendChild( document.createTextNode(result.result.nom_org) );
                                var jForm = jFormsJQ.getForm( aForm.attr('id') );
                                jForm.element.elements['id_org'].appendChild(opt);
                                $( jForm.element.elements['id_org'] ).val( result.result.id_org );
                            }
                            $('#lizmap-modal').modal('hide');
                        }
                      );
                      return false;
                  });
                  $('#lizmap-modal').modal('show');
          }
        );
    }

    function addPersonne( aForm ) {
        var form = $('#form_mascarine_personne_add');
        $.get(form.attr('action'),{'id_org':aForm.find('*[name="id_org"]').val()}
          , function( data ) {
                  $('#lizmap-modal').html(data);
                  $('#lizmap-modal form').submit(function() {
                      var self = $(this);
                      $.post( self.attr('action'), self.serialize()
                        , function( result ) {
                            if ( result.status == 1 ) {
                                // add to control
                                var opt = document.createElement('option');
                                opt.setAttribute('value', result.result.id_perso);
                                opt.appendChild( document.createTextNode(result.result.nom_perso+' '+result.result.prenom_perso) );
                                var jForm = jFormsJQ.getForm( aForm.attr('id') );
                                jForm.element.elements['id_perso'].appendChild(opt);
                                $( jForm.element.elements['id_perso'] ).val( result.result.id_perso );
                            }
                            $('#lizmap-modal').modal('hide');
                        }
                      );
                      return false;
                  });
                  $('#lizmap-modal').modal('show');
          }
          , 'html'
        );
    }

    function initAjaxControlDate( control, config ) {
        if( !(control instanceof jFormsJQControlDate) ) return;
        var disabled=false;
        if(control.multiFields){
            var eltId='#'+control.formName+'_'+control.name;
            var eltYear=jQuery(eltId+'_year').after('<input type="hidden" disabled="disabled" id="'+control.formName+'_'+control.name+'_hidden" />');
            var eltMonth=jQuery(eltId+'_month');
            var eltDay=jQuery(eltId+'_day');
            var elt=jQuery(eltId+'_hidden');
            disabled=eltYear.attr('disabled');
        }else{
            var elt=jQuery('#'+control.formName+'_'+control.name);
            disabled=elt.attr('disabled');
        }
        var params={
            changeMonth:true,
            changeYear:true,
            showButtonPanel:true,
            showOn:"button",
            buttonImageOnly:true,
            buttonImage:config.jelixWWWPath+'design/jforms/calendar.gif',
            onSelect:function(date){
                if(!control.multiFields)return;
                eltYear.val('');
                eltMonth.val('');
                eltDay.val('');
                date=date.split('-');
                eltYear.val(date[0]);
                eltMonth.val(date[1]);
                eltDay.val(date[2])
            }
        };
        var currentYear=parseInt(new Date().getFullYear(),10);
        var yearRange=[parseInt(currentYear-10,10),parseInt(currentYear+10,10)];
        if(control.minDate){
            var t=control.minDate.match(/^(\d{4})\-(\d{2})\-(\d{2}).*$/);
            if(t!==null){
                yearRange[0]=parseInt(t[1],10);
                params.minDate=new Date(parseInt(t[1],10),parseInt(t[2],10)-1,parseInt(t[3],10))
            }
        }
        if(control.maxDate){
            var t=control.maxDate.match(/^(\d{4})\-(\d{2})\-(\d{2}).*$/);
            if(t!==null){
                yearRange[1]=parseInt(t[1],10);
                params.maxDate=new Date(parseInt(t[1],10),parseInt(t[2],10)-1,parseInt(t[3],10))
            }
        }
        params.yearRange=yearRange.join(':');
        if(control.multiFields)params.beforeShow=function(){
            elt.val(eltYear.val()+'-'+eltMonth.val()+'-'+eltDay.val())
        };
        if(!control.lang)params.dateFormat='yy-mm-dd';
        elt.datepicker(params);
        jQuery("#ui-datepicker-div").css("z-index",999999);
        var triggerIcon=elt.parent().children('img.ui-datepicker-trigger').eq(0);
        if(!control.required){
            triggerIcon.after(' <img class="ui-datepicker-reset" src="'+config.jelixWWWPath+'design/jforms/cross.png" alt="'+elt.datepicker('option','resetButtonText')+'"  title="'+elt.datepicker('option','resetButtonText')+'" />');
            var cleanTriggerIcon=elt.parent().children('img').eq(1);
            cleanTriggerIcon.click(function(e){
                if(elt.datepicker('isDisabled'))return;
                if(control.multiFields){
                    eltYear.val('');
                    eltMonth.val('');
                    eltDay.val('')
                }
                elt.val('')
            })
        }
        triggerIcon.css({'vertical-align':'text-bottom','margin-left':'3px'});
        elt.bind('jFormsActivateControl',function(e,val){
            if(val){
                jQuery(this).datepicker('enable');
                if(!control.required)cleanTriggerIcon.css('opacity','1')
            }else{
                jQuery(this).datepicker('disable');
                if(!control.required)cleanTriggerIcon.css('opacity','0.5')
            }
        });
        elt.trigger('jFormsActivateControl',!disabled);
        elt.blur();
        return;
    }

    function initEditObservation() {
        $.each( $('#div_mascarine_observation_forms form'), function( index, form ) {
            form = $( form );
            var jForm = jFormsJQ.getForm( form.attr('id') );
            var jFormsConfig = jFormsJQ.config;
            $.each(jForm.controls,function(index,control){
                initAjaxControlDate( control, jFormsConfig );
            });
            form.submit( function() {
                $.post( form.attr('action'), form.serialize()
                    , function( data ) {
                        var parent = form.parent();
                        form.find('button').unbind();
                        form.unbind();
                        parent.html( data );
                    });
                return false;
            });
        });
    }

    function addDocumentObservationTable() {
      var tableId = 'mascarine_observation_document_table';
      var table = $('#'+tableId+'');
      if ( table.length == 0 )
        return;
      // Get fields to display
      var returnFields = table.attr('data-value').split(',');
      var DT_RowId = table.find('thead tr').attr('data-value');
      var datatableColumns = getDatatableColumns( tableId );
      var DT_Columns = datatableColumns[0];
      var displayFields = datatableColumns[1];

      // Display data via datatable
      table.DataTable( {
            "lengthChange": false,
            "searching": false,
            "dom":'ipt',
            "language": {url:lizUrls["dataTableLanguage"]},
            "processing": true,
            "serverSide": true,
            "columns": DT_Columns,
            "ajax": function (param, callback, settings) {
              var searchForm = $('#mascarine_observation_document_form');
              searchForm.find('input[name="limit"]').val(param.length);
              searchForm.find('input[name="offset"]').val(param.start);
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
                  table.find('a').unbind('click');
                  callback( tData );
                });
            }
        });
        table.on( 'page.dt', function() {
          table.find('a').unbind('click');
        });
        table.on( 'draw.dt', function() {
          table.find('a.remove').click(function(){
              var self = $(this);
              $.get(self.attr('href'), {}
                ,function(data) {
                    if ( data.msg.length != 0 ) {
                      if ( data.status == 0 )
                        lizMap.addMessage( data.msg.join('<br/>'), 'error', true );
                      else
                        lizMap.addMessage( data.msg.join('<br/>'), 'info', true );
                    }
                    if ( data.status == 1 ) {
                        $('#mascarine_observation_document_table').DataTable().ajax.reload();
                        if ( 'check' in data ) {
                            var tabPane = table.parents('.tab-pane');
                            var tabPaneId = tabPane.attr('id');
                            var addForm = tabPane.first().find('form').first();
                            var addFormId = addForm.attr('id');
                            addForm.find('.jforms-hiddens').after('<div id="'+addFormId+'_errors" class="alert alert-block alert-error jforms-error-list"><p>'+data.check+'</p></div>');
                            $('#div_mascarine_observation_forms .nav-tabs a[href="#'+tabPaneId+'"]').addClass('jforms-error-list');
                        }
                    }
                }
              );
              return false;
          });
        });
    }

    function addMenaceObservationTable() {
      var tableId = 'mascarine_observation_menace_table';
      var table = $('#'+tableId+'');
      if ( table.length == 0 )
        return;
      // Get fields to display
      var returnFields = table.attr('data-value').split(',');
      var DT_RowId = table.find('thead tr').attr('data-value');
      var datatableColumns = getDatatableColumns( tableId );
      var DT_Columns = datatableColumns[0];
      var displayFields = datatableColumns[1];

      // Display data via datatable
      table.DataTable( {
            "lengthChange": false,
            "searching": false,
            "dom":'ipt',
            "language": {url:lizUrls["dataTableLanguage"]},
            "processing": true,
            "serverSide": true,
            "columns": DT_Columns,
            "ajax": function (param, callback, settings) {
              var searchForm = $('#mascarine_observation_menace_form');
              searchForm.find('input[name="limit"]').val(param.length);
              searchForm.find('input[name="offset"]').val(param.start);
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
                  table.find('a').unbind('click');
                  callback( tData );
                });
            }
        });
        table.on( 'page.dt', function() {
          table.find('a').unbind('click');
        });
        table.on( 'draw.dt', function() {
          table.find('a.remove').click(function(){
              var self = $(this);
              $.get(self.attr('href'), {}
                ,function(data) {
                    if ( data.msg.length != 0 ) {
                      if ( data.status == 0 )
                        lizMap.addMessage( data.msg.join('<br/>'), 'error', true );
                      else
                        lizMap.addMessage( data.msg.join('<br/>'), 'info', true );
                    }
                    if ( data.status == 1 ) {
                        $('#mascarine_observation_menace_table').DataTable().ajax.reload();
                        if ( 'check' in data ) {
                            var tabPane = table.parents('.tab-pane');
                            var tabPaneId = tabPane.attr('id');
                            var addForm = tabPane.first().find('form').first();
                            var addFormId = addForm.attr('id');
                            addForm.find('.jforms-hiddens').after('<div id="'+addFormId+'_errors" class="alert alert-block alert-error jforms-error-list"><p>'+data.check+'</p></div>');
                            $('#div_mascarine_observation_forms .nav-tabs a[href="#'+tabPaneId+'"]').addClass('jforms-error-list');
                        }
                    }
                }
              );
              return false;
          });
        });
    }

    function addHabitatObservationTable() {
      $('#div_form_mascarine_observation_habitat form .jforms-table').hide();
      $('#div_form_mascarine_observation_habitat form .jforms-submit-buttons').hide();
      $('#div_form_mascarine_observation_habitat label a.btn').click(function() {
          var self = $(this);
          $.get(self.attr('href'), {}
            ,function(data) {
                if ( data.msg.length != 0 ) {
                  if ( data.status == 0 )
                    lizMap.addMessage( data.msg.join('<br/>'), 'error', true );
                  else
                    lizMap.addMessage( data.msg.join('<br/>'), 'info', true );
                }
                if ( data.status == 1 ) {
                    if ( $('#div_form_mascarine_observation_habitat form .jforms-error-list').length != 0 ) {
                        $('#div_form_mascarine_observation_habitat form .jforms-error-list').remove();
                        $('#div_mascarine_observation_forms .nav-tabs a[href="#mascarine_observation_habitat_div"]').removeClass('jforms-error-list');
                    }
                    $('#mascarine_observation_habitat_table').DataTable().ajax.reload();
                }
            }
          );
          return false;
      });
      var tableId = 'mascarine_observation_habitat_table';
      var table = $('#'+tableId+'');
      if ( table.length == 0 )
        return;
      // Get fields to display
      var returnFields = table.attr('data-value').split(',');
      var DT_RowId = table.find('thead tr').attr('data-value');
      var datatableColumns = getDatatableColumns( tableId );
      var DT_Columns = datatableColumns[0];
      var displayFields = datatableColumns[1];

      // Display data via datatable
      table.DataTable( {
            "lengthChange": false,
            "searching": false,
            "dom":'ipt',
            "language": {url:lizUrls["dataTableLanguage"]},
            "processing": true,
            "serverSide": true,
            "columns": DT_Columns,
            "ajax": function (param, callback, settings) {
              var searchForm = $('#mascarine_observation_habitat_form');
              searchForm.find('input[name="limit"]').val(param.length);
              searchForm.find('input[name="offset"]').val(param.start);
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
                  table.find('a').unbind('click');
                  callback( tData );
                });
            }
        });
        table.on( 'page.dt', function() {
          table.find('a').unbind('click');
        });
        table.on( 'draw.dt', function() {
          table.find('a.remove').click(function(){
              var self = $(this);
              $.get(self.attr('href'), {}
                ,function(data) {
                    if ( data.msg.length != 0 ) {
                      if ( data.status == 0 )
                        lizMap.addMessage( data.msg.join('<br/>'), 'error', true );
                      else
                        lizMap.addMessage( data.msg.join('<br/>'), 'info', true );
                    }
                    if ( data.status == 1 ) {
                        $('#mascarine_observation_habitat_table').DataTable().ajax.reload();
                        if ( 'check' in data ) {
                            var tabPane = table.parents('.tab-pane');
                            var tabPaneId = tabPane.attr('id');
                            var addForm = tabPane.first().find('form').first();
                            var addFormId = addForm.attr('id');
                            addForm.find('.jforms-hiddens').after('<div id="'+addFormId+'_errors" class="alert alert-block alert-error jforms-error-list"><p>'+data.check+'</p></div>');
                            $('#div_mascarine_observation_forms .nav-tabs a[href="#'+tabPaneId+'"]').addClass('jforms-error-list');
                        }
                    }
                }
              );
              return false;
          });
        });
    }

    function manageFloreObservationAddForm() {
        var form = $('#lizmap-modal div.form div.add form');
        var token = form.find('input[name="__JFORMS_TOKEN__"]').val();
        form.submit(function(){
            $.post( form.attr('action'), form.serialize()
                , function( data ) {
                    var content = $(data);
                    if ( content.find('div.form').length != 0 )
                      data = content.find('div.form')[0].innerHTML;
                    $('#lizmap-modal div.form').html( data );
                    if ( token != $('#lizmap-modal div.form div.add form input[name="__JFORMS_TOKEN__"]').val() )
                        $('#lizmap-modal div.table table').DataTable().ajax.reload();
                    manageFloreObservationAddForm();
                }
                ,'html'
            );
            return false;
        });
    }

    function manageFloreObservationUpdateForm() {
        var divUpdate = $('#lizmap-modal div.form div.update');
        var form = divUpdate.find('form');
        form.submit(function(){
            $.post( form.attr('action'), form.serialize()
                , function( data ) {
                    if ( data.msg.length != 0 ) {
                      if ( data.status == 0 )
                        lizMap.addMessage( data.msg.join('<br/>'), 'error', true );
                      else
                        lizMap.addMessage( data.msg.join('<br/>'), 'info', true );
                    }
                    if ( data.status == 1 ) {
                        $('#lizmap-modal div.table table').DataTable().ajax.reload();
                        form.unbind('submit');
                        divUpdate.find('input[type="checkbox"]').removeAttr('checked');
                        divUpdate.hide();
                    }
                }
                ,'json'
            );
            return false;
        });
    }

    function addPopFloreObservationTable() {
      var tableId = 'mascarine_observation_flore_pop_table';
      var table = $('#'+tableId+'');
      if ( table.length == 0 )
        return;
      // Get fields to display
      var returnFields = table.attr('data-value').split(',');
      var DT_RowId = table.find('thead tr').attr('data-value');
      var datatableColumns = getDatatableColumns( tableId );
      var DT_Columns = datatableColumns[0];
      var displayFields = datatableColumns[1];

      // Display data via datatable
      table.DataTable( {
            "lengthChange": false,
            "searching": false,
            "dom":'ipt',
            "language": {url:lizUrls["dataTableLanguage"]},
            "processing": true,
            "serverSide": true,
            "columns": DT_Columns,
            "ajax": function (param, callback, settings) {
              var searchForm = $('#mascarine_observation_flore_pop_form');
              searchForm.find('input[name="limit"]').val(param.length);
              searchForm.find('input[name="offset"]').val(param.start);
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
                  table.find('a').unbind('click');
                  callback( tData );
                });
            }
        });
        table.on( 'page.dt', function() {
          table.find('a').unbind('click');
        });
        table.on( 'draw.dt', function() {
          table.find('a.edit').click(function(){
              var self = $(this);
              $.get(self.attr('href'), {}
                ,function(data) {
                    var updateDiv = $('#lizmap-modal div.form div.update');
                    updateDiv.find('form').replaceWith( data );
                    updateDiv.show();
                    updateDiv.find('input[type="checkbox"]')[0].checked = true;
                    $('#lizmap-modal div.form div.add input[type="checkbox"]').removeAttr('checked');
                    manageFloreObservationUpdateForm();
                }
              );
              return false;
          });
          table.find('a.remove').click(function(){
              var self = $(this);
              $.get(self.attr('href'), {}
                ,function(data) {
                    if ( data.msg.length != 0 ) {
                      if ( data.status == 0 )
                        lizMap.addMessage( data.msg.join('<br/>'), 'error', true );
                      else
                        lizMap.addMessage( data.msg.join('<br/>'), 'info', true );
                    }
                    if ( data.status == 1 ) {
                        $('#mascarine_observation_flore_pop_table').DataTable().ajax.reload();
                    }
                }
              );
              return false;
          });
      });
    }

    function addPhenoFloreObservationTable() {
      var tableId = 'mascarine_observation_flore_pheno_table';
      var table = $('#'+tableId+'');
      if ( table.length == 0 )
        return;
      // Get fields to display
      var returnFields = table.attr('data-value').split(',');
      var DT_RowId = table.find('thead tr').attr('data-value');
      var datatableColumns = getDatatableColumns( tableId );
      var DT_Columns = datatableColumns[0];
      var displayFields = datatableColumns[1];

      // Display data via datatable
      table.DataTable( {
            "lengthChange": false,
            "searching": false,
            "dom":'ipt',
            "language": {url:lizUrls["dataTableLanguage"]},
            "processing": true,
            "serverSide": true,
            "columns": DT_Columns,
            "ajax": function (param, callback, settings) {
              var searchForm = $('#mascarine_observation_flore_pheno_form');
              searchForm.find('input[name="limit"]').val(param.length);
              searchForm.find('input[name="offset"]').val(param.start);
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
                  table.find('a').unbind('click');
                  callback( tData );
                });
            }
        });
        table.on( 'page.dt', function() {
          table.find('a').unbind('click');
        });
        table.on( 'draw.dt', function() {
          table.find('a.edit').click(function(){
              var self = $(this);
              $.get(self.attr('href'), {}
                ,function(data) {
                    var updateDiv = $('#lizmap-modal div.form div.update');
                    updateDiv.find('form').replaceWith( data );
                    updateDiv.show();
                    updateDiv.find('input[type="checkbox"]')[0].checked = true;
                    $('#lizmap-modal div.form div.add input[type="checkbox"]').removeAttr('checked');
                    manageFloreObservationUpdateForm();
                }
              );
              return false;
          });
          table.find('a.remove').click(function(){
              var self = $(this);
              $.get(self.attr('href'), {}
                ,function(data) {
                    if ( data.msg.length != 0 ) {
                      if ( data.status == 0 )
                        lizMap.addMessage( data.msg.join('<br/>'), 'error', true );
                      else
                        lizMap.addMessage( data.msg.join('<br/>'), 'info', true );
                    }
                    if ( data.status == 1 ) {
                        $('#mascarine_observation_flore_pheno_table').DataTable().ajax.reload();
                    }
                }
              );
              return false;
          });
      });
    }

    function addTaxonObservationTable() {
      var tableId = 'mascarine_observation_taxon_table';
      var table = $('#'+tableId+'');
      if ( table.length == 0 )
        return;
      // Get fields to display
      var returnFields = table.attr('data-value').split(',');
      var DT_RowId = table.find('thead tr').attr('data-value');
      var datatableColumns = getDatatableColumns( tableId );
      var DT_Columns = datatableColumns[0];
      var displayFields = datatableColumns[1];

      // Display data via datatable
      table.DataTable( {
            "lengthChange": false,
            "searching": false,
            "dom":'ipt',
            "language": {url:lizUrls["dataTableLanguage"]},
            "processing": true,
            "serverSide": true,
            "columns": DT_Columns,
            "ajax": function (param, callback, settings) {
              var searchForm = $('#mascarine_observation_taxon_form');
              searchForm.find('input[name="limit"]').val(param.length);
              searchForm.find('input[name="offset"]').val(param.start);
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
                  table.find('a').unbind('click');
                  callback( tData );
                });
            }
        });
        table.on( 'page.dt', function() {
          table.find('a').unbind('click');
        });
        table.on( 'draw.dt', function() {
          table.find('a.remove').click(function(){
              var self = $(this);
              $.get(self.attr('href'), {}
                ,function(data) {/*
                    if ( data.msg.length != 0 ) {
                      if ( data.status == 0 )
                        lizMap.addMessage( data.msg.join('<br/>'), 'error', true );
                      else
                        lizMap.addMessage( data.msg.join('<br/>'), 'info', true );
                    }
                    if ( data.status == 1 ) {
                        $('#mascarine_observation_taxon_table').DataTable().ajax.reload();
                        if ( 'check' in data ) {
                            var tabPane = table.parents('.tab-pane');
                            var tabPaneId = tabPane.attr('id');
                            var addForm = tabPane.first().find('form').first();
                            var addFormId = addForm.attr('id');
                            addForm.find('.jforms-hiddens').after('<div id="'+addFormId+'_errors" class="alert alert-block alert-error jforms-error-list"><p>'+data.check+'</p></div>');
                            $('#div_mascarine_observation_forms .nav-tabs a[href="#'+tabPaneId+'"]').addClass('jforms-error-list');
                        }
                    }*/
                    var addForm = $('#div_form_mascarine_observation_flore form');
                    addForm.unbind();
                    addForm.replaceWith( data );
                    initObservationForm( $('#div_form_mascarine_observation_flore form') );
                    $('#mascarine_observation_taxon_table').DataTable().ajax.reload();
                }
              );
              return false;
          });
          table.find('a.detail').click(function(){
              var self = $(this);
              $.get(self.attr('href'), {}
                ,function(data) {
                  $('#lizmap-modal').html(data);
                  var form = $('#lizmap-modal form');
                  var formId = form.attr('id');
                  $('#'+formId+'_cd_nom_phorophyte_autocomplete').autocomplete({
                    minLength:2,
                    autoFocus: true,
                    source:function( request, response ) {
                        request.limit = $('#form_mascarine_observation_flore_taxon_service_autocomplete input[name="limit"]').val();
                        $.getJSON($('#form_mascarine_observation_flore_taxon_service_autocomplete').attr('action'),
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
                        $('#'+formId+'_cd_nom_phorophyte').val( '' );
                    },
                    search: function( e, ui ) {
                      $('#'+formId+'_cd_nom_phorophyte').val( '' );
                    },
                    select: function( e, ui ) {
                      $(this).val( $('<a>').html(ui.item.nom_valide).text() );
                      $('#'+formId+'_cd_nom_phorophyte').val( ui.item.cd_ref );
                      return false;
                    }
                  }).autocomplete( "widget" ).css("z-index","1060");
                  $('#'+formId+'_cd_nom_phorophyte_autocomplete').autocomplete( "instance" )._renderItem = function( ul, item ) {
                    return $( "<li>" )
                    .append( $("<a>").html( item.label ) )
                    .appendTo( ul );
                  };
                  form.submit(function() {
                      $.post( form.attr('action'), form.serialize()
                        , function( result ) {
                            if ( result.status == 0 )
                              lizMap.addMessage( result.msg.join('<br/>'), 'error', true );
                            else
                              lizMap.addMessage( result.msg.join('<br/>'), 'info', true );
                            $('#lizmap-modal').modal('hide');
                        }
                      );
                      return false;
                  });
                  $('#lizmap-modal').modal('show');
                  $('#lizmap-modal').on('hide',function(){
                        var checkForm = $('#mascarine_observation_taxon_check_form');
                        $.get(checkForm.attr('action'), checkForm.serialize(), function(checkData ) {
                            var addForm = $('#div_form_mascarine_observation_flore form');
                            addForm.unbind();
                            addForm.replaceWith( checkData );
                            initObservationForm( $('#div_form_mascarine_observation_flore form') );
                        });
                        $('#lizmap-modal').unbind('hide');
                  });
                }
              );
              return false;
          });
          table.find('a.pheno').click(function(){
              var self = $(this);
              $.get(self.attr('href'), {}
                ,function(data) {
                  $('#lizmap-modal').html(data);
                  manageFloreObservationAddForm();
                  addPhenoFloreObservationTable();
                  $('#lizmap-modal').modal('show');
                  $('#lizmap-modal').on('hide',function(){
                        var checkForm = $('#mascarine_observation_taxon_check_form');
                        $.get(checkForm.attr('action'), checkForm.serialize(), function(checkData ) {
                            var addForm = $('#div_form_mascarine_observation_flore form');
                            addForm.unbind();
                            addForm.replaceWith( checkData );
                            initObservationForm( $('#div_form_mascarine_observation_flore form') );
                        });
                        $('#lizmap-modal').unbind('hide');
                  });
                }
              );
              return false;
          });
          table.find('a.pop').click(function(){
              var self = $(this);
              $.get(self.attr('href'), {}
                ,function(data) {
                  $('#lizmap-modal').html(data);
                  manageFloreObservationAddForm();
                  addPopFloreObservationTable();
                  $('#lizmap-modal').modal('show');
                  $('#lizmap-modal').on('hide',function(){
                        var checkForm = $('#mascarine_observation_taxon_check_form');
                        $.get(checkForm.attr('action'), checkForm.serialize(), function(checkData ) {
                            var addForm = $('#div_form_mascarine_observation_flore form');
                            addForm.unbind();
                            addForm.replaceWith( checkData );
                            initObservationForm( $('#div_form_mascarine_observation_flore form') );
                        });
                        $('#lizmap-modal').unbind('hide');
                  });
                }
              );
              return false;
          });
          table.find('a').click(function(){
              return false;
          });
        });
    }

    function addPersonneObservationTable() {
      var tableId = 'mascarine_observation_personne_table';
      var table = $('#'+tableId+'');
      if ( table.length == 0 )
        return;
      // Get fields to display
      var returnFields = table.attr('data-value').split(',');
      var DT_RowId = table.find('thead tr').attr('data-value');
      var datatableColumns = getDatatableColumns( tableId );
      var DT_Columns = datatableColumns[0];
      var displayFields = datatableColumns[1];

      // Display data via datatable
      table.DataTable( {
            "lengthChange": false,
            "searching": false,
            "dom":'ipt',
            "language": {url:lizUrls["dataTableLanguage"]},
            "processing": true,
            "serverSide": true,
            "columns": DT_Columns,
            "ajax": function (param, callback, settings) {
              var searchForm = $('#mascarine_observation_personne_form');
              searchForm.find('input[name="limit"]').val(param.length);
              searchForm.find('input[name="offset"]').val(param.start);
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
                  table.find('a').unbind('click');
                  callback( tData );
                });
            }
        });
        table.on( 'page.dt', function() {
          table.find('a').unbind('click');
        });
        table.on( 'draw.dt', function() {
          table.find('a.remove').click(function(){
              var self = $(this);
              $.get(self.attr('href'), {}
                ,function(data) {
                    if ( data.msg.length != 0 ) {
                      if ( data.status == 0 )
                        lizMap.addMessage( data.msg.join('<br/>'), 'error', true );
                      else
                        lizMap.addMessage( data.msg.join('<br/>'), 'info', true );
                    }
                    if ( data.status == 1 ) {
                        table.DataTable().ajax.reload();
                        if ( 'check' in data ) {
                            var tabPane = table.parents('.tab-pane');
                            var tabPaneId = tabPane.attr('id');
                            var addForm = tabPane.first().find('form').first();
                            var addFormId = addForm.attr('id');
                            addForm.find('.jforms-hiddens').after('<div id="'+addFormId+'_errors" class="alert alert-block alert-error jforms-error-list"><p>'+data.check+'</p></div>');
                            $('#div_mascarine_observation_forms .nav-tabs a[href="#'+tabPaneId+'"]').addClass('jforms-error-list');
                        }
                    }
                }
              );
              return false;
          });
        });
    }

    function addUnvalidateObservationTable() {
      var tableId = 'mascarine_observation_unvalid_table';
      var table = $('#'+tableId+'');
      if ( table.length == 0 )
        return;
      // Get fields to display
      var returnFields = table.attr('data-value').split(',');
      var DT_RowId = table.find('thead tr').attr('data-value');
      var datatableColumns = getDatatableColumns( tableId );
      var DT_Columns = datatableColumns[0];
      var displayFields = datatableColumns[1];

      // Display data via datatable
      table.DataTable( {
            "lengthChange": false,
            "searching": false,
            "dom":'ipt',
            "language": {url:lizUrls["dataTableLanguage"]},
            "processing": true,
            "serverSide": true,
            "columns": DT_Columns,
            "ajax": function (param, callback, settings) {
              var searchForm = $('#mascarine_observation_unvalid_form');
              searchForm.find('input[name="limit"]').val(param.length);
              searchForm.find('input[name="offset"]').val(param.start);
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
                    Mascarine.events.triggerEvent('observationunvalidatereceived', {'results':results});

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
                  table.find('a').unbind('click');
                  callback( tData );
                });
            }
        });
        table.on( 'page.dt', function() {
          table.find('a').unbind('click');
        });
        table.on( 'draw.dt', function() {
          // Update features on map when table changes
          updateUnvalidateObservationFeatures();

          table.find('a.editObs').click(function(){
              var self = $(this);
              $.get(self.attr('href'), {}
                ,function(data) {
                    $('#div_mascarine_observation_forms').html( data );
                    var forms = $('#div_mascarine_observation_forms form');
                    Mascarine.deactivateAllDrawqueryControl();
                    $('#mascarine_observation_add').hide();
                    $('#mascarine_observation_unvalid').hide();
                    Mascarine.layers['obstemp'].destroyFeatures();
                    Mascarine.layers['obstemp'].setVisibility(true);
                    Mascarine.controls['select']['highlightCtrl'].deactivate();
                    $.each( forms, function( index, form ) {
                        initObservationForm( form );
                    });
                    initObservationTabs();
                    $('#div_mascarine_observation_forms button.close').click(function() {
                        closeObservation();
                    });
                    $('#div_mascarine_observation_forms button.zoom').click(function() {
                        Mascarine.map.zoomToExtent( Mascarine.layers['obstemp'].getDataExtent() );
                        return false;
                    });
                }
              );
              return false;
          });
          table.find('a.removeObs').click(function(){
              var self = $(this);
              $.get(self.attr('href'), {}
                ,function(data) {
                    if ( data.msg.length != 0 ) {
                      if ( data.status == 0 )
                        lizMap.addMessage( data.msg.join('<br/>'), 'error', true );
                      else
                        lizMap.addMessage( data.msg.join('<br/>'), 'info', true );
                    }
                    if ( data.status == 1 )
                        table.DataTable().ajax.reload(function() {
                            updateUnvalidateObservationFeatures();
                        });
                }
              );
              return false;
          });
        });
    }

    function setObservationTabsHeight() {
        var tabsHeight = parseInt( $('#dock-content').css('max-height') ) - $('#mascarine_personne_user').outerHeight() - $('#div_mascarine_observation_forms > h3').first().outerHeight();
        $('#div_mascarine_observation_forms_tabs').height( tabsHeight+'px' );
    }

    function initObservationTabs() {
        addPersonneObservationTable();
        addTaxonObservationTable();
        addHabitatObservationTable();
        addMenaceObservationTable();
        addDocumentObservationTable();

        $(window).resize( setObservationTabsHeight );
        setObservationTabsHeight();
        $('#div_mascarine_observation_forms_tabs > ul.nav-tabs a[data-toggle="tab"]').unbind('click');
        $('#div_mascarine_observation_forms_tabs > ul.nav-tabs a[data-toggle="tab"]').click(function(){
            $(this).blur();
            return false;
        });
        $('#div_mascarine_observation_forms_tabs > ul.nav-tabs a[data-toggle="tab"]').on('shown', function (e) {
            /*
            var oldActiveTab = $(e.relatedTarget).attr('href');
            if ( oldActiveTab == '#mascarine_observation_general_div'
              || oldActiveTab == '#mascarine_observation_localisation_div'
              || oldActiveTab == '#mascarine_observation_station_div' )
                $(oldActiveTab+' form').submit();
                */
          //console.log( 'new active tab' + $(e.target).attr('href') ); // activated tab
          //console.log( 'old active tab' + $(e.relatedTarget).attr('href') ); // previous tab
          if( $('#div_mascarine_observation_forms_tabs > ul.nav-tabs > li.active').prev().length == 0 )
            $('#div_mascarine_observation_forms_tabs > .pager > .previous').addClass('disabled');
          else
            $('#div_mascarine_observation_forms_tabs > .pager > .previous').removeClass('disabled');
          if( $('#div_mascarine_observation_forms_tabs > ul.nav-tabs > li.active').next().length == 0 )
            $('#div_mascarine_observation_forms_tabs > .pager > .next a').html('Enregistrer').addClass('save');
          else
            $('#div_mascarine_observation_forms_tabs > .pager > .next a').html('Suivant &rarr;').removeClass('save');
        });
        $('#div_mascarine_observation_forms_tabs > .pager > .previous').click(function() {
            var activeTab = $('#div_mascarine_observation_forms_tabs > ul.nav-tabs > li.active');
            var activeTabLink = activeTab.find('a').attr('href');
            var prev = activeTab.prev();
            if ( activeTabLink == '#mascarine_observation_general_div'
              || activeTabLink == '#mascarine_observation_localisation_div'
              || activeTabLink == '#mascarine_observation_station_div' )
                submitObservationForm( $(activeTabLink+' form'), function() {
                    if ( prev.length != 0 )//&& $(activeTabLink+' form .jforms-error-list').length == 0 )
                        prev.find('a').tab('show');
                });
            else if ( prev.length != 0 )//&& $(activeTabLink+' form .jforms-error-list').length == 0 )
                prev.find('a').tab('show');
            return false;
        });
        $('#div_mascarine_observation_forms_tabs > .pager > .next').click(function() {
            var activeTab = $('#div_mascarine_observation_forms_tabs > ul.nav-tabs > li.active');
            var activeTabLink = activeTab.find('a').attr('href');
            var next = activeTab.next();


            // Display next tab
            if ( activeTabLink == '#mascarine_observation_general_div'
              || activeTabLink == '#mascarine_observation_localisation_div'
              || activeTabLink == '#mascarine_observation_station_div' ){
                submitObservationForm( $(activeTabLink+' form'), function() {
                    // Show next tab if it exists
                    if ( $(activeTabLink+' form .jforms-error-list').length == 0 ){
                        if( next.length != 0 ){
                            next.find('a').tab('show');
                        }
                        // else
                        // Add the status "Enregistré" and close the form
                        else {
                            var hForm = $('#mascarine_observation_hidden_form');
                            $.post( hForm.attr('action'), hForm.serialize(), function( data ) {
                                if ( data.status == 1 ) {
                                    lizMap.addMessage( data.msg[0], 'info', true );
                                    $('#mascarine_observation_unvalid_table').DataTable().ajax.reload(function() {
                                        updateUnvalidateObservationFeatures();
                                        closeObservation();
                                    });

                                } else {
                                  lizMap.addMessage( data.msg[0], 'error', true );
                                }
                            });
                        }
                    }
                });
            }
            else if ( $(activeTabLink+' form .jforms-error-list').length == 0 ){
                // Show next tab
                if( next.length != 0 ){
                    next.find('a').tab('show');
                }
                // else
                // Add the status "Enregistré" and close the form
                else {
                    var hForm = $('#mascarine_observation_hidden_form');
                    $.post( hForm.attr('action'), hForm.serialize(), function( data ) {
                        if ( data.status == 1 ) {
                            lizMap.addMessage( data.msg[0], 'info', true );
                            $('#mascarine_observation_unvalid_table').DataTable().ajax.reload(function() {
                                updateUnvalidateObservationFeatures();
                                closeObservation();
                            });
                        } else {
                          lizMap.addMessage( data.msg[0], 'error', true );
                        }
                    });
                }
            }
            return false;

        });
        if( $('#div_mascarine_observation_forms_tabs > ul.nav-tabs > li.active').prev().length == 0 )
            $('#div_mascarine_observation_forms_tabs > .pager > .previous').addClass('disabled');
        else
            $('#div_mascarine_observation_forms_tabs > .pager > .previous').removeClass('disabled');
        if( $('#div_mascarine_observation_forms_tabs > ul.nav-tabs > li.active').next().length == 0 )
            $('#div_mascarine_observation_forms_tabs > .pager > .next').addClass('disabled');
        else
            $('#div_mascarine_observation_forms_tabs > .pager > .next').removeClass('disabled');
    }

    function submitObservationForm( aForm, aCallback ) {
        aForm = $(aForm);
        var formId = aForm.attr('id');
        var parent = aForm.parent();
        var parentId = parent.attr('id');
        var tabPane = parent.parents('.tab-pane').first();
        var tabPaneId = tabPane.attr('id');
        var jForm = jFormsJQ.getForm( aForm.attr('id') );

        $.post( aForm.attr('action'), aForm.serialize()
            , function( data ) {
                aForm.find('button').unbind();
                aForm.unbind();
                $('#div_mascarine_observation_forms .nav-tabs a[href="#'+tabPaneId+'"]').removeClass('jforms-error-list');
                var forms = [];
                if ( parentId == 'div_form_mascarine_add_obs' ) {
                    $('#mascarine_observation_unvalid_table').DataTable().ajax.reload(function() {
                        updateUnvalidateObservationFeatures();
                    });
                    $('#div_mascarine_observation_forms').html( data );
                    forms = $('#div_mascarine_observation_forms form');
                } else {
                    if ( parentId == 'div_form_mascarine_observation_general' )
                        $('#mascarine_observation_unvalid_table').DataTable().ajax.reload(function() {
                            updateUnvalidateObservationFeatures();
                        });
                    else if ( parentId == 'div_form_mascarine_observation_personne' ) {
                        $('#mascarine_observation_personne_table').DataTable().ajax.reload();
                    } else if ( parentId == 'div_form_mascarine_observation_flore' )
                        $('#mascarine_observation_taxon_table').DataTable().ajax.reload();
                    else if ( parentId == 'div_form_mascarine_observation_menace' )
                        $('#mascarine_observation_menace_table').DataTable().ajax.reload();
                  parent.html( data );
                  forms = parent.find('form');
                }
                $.each( forms, function( index, form ) {
                    initObservationForm( form );
                });
                if ( parentId == 'div_form_mascarine_add_obs' ) {
                    initObservationTabs();
                    $('#div_mascarine_observation_forms button.close').click(function() {
                        closeObservation();
                        return false;
                    });
                    $('#div_mascarine_observation_forms button.zoom').click(function() {
                        Mascarine.map.zoomToExtent( Mascarine.layers['obstemp'].getDataExtent() );
                        return false;
                    });
                } else if ( forms.length == 0 ) {
                    $('#div_mascarine_observation_forms button.close').click();
                    $('#mascarine_observation_unvalid_div_table').before(data);
                    $('#mascarine_observation_unvalid_table').DataTable().ajax.reload(function() {
                        updateUnvalidateObservationFeatures();
                    });
                }
                if ( aCallback )
                    aCallback()
            });
    }

    function initObservationForm( aForm ) {
        aForm = $(aForm);
        var formId = aForm.attr('id');
        var parent = aForm.parent();
        var parentId = parent.attr('id');
        var tabPane = parent.parents('.tab-pane').first();
        var tabPaneId = tabPane.attr('id');
        var jForm = jFormsJQ.getForm( aForm.attr('id') );

        if ( parentId == 'div_form_mascarine_add_obs'
          || parentId == 'div_form_mascarine_observation_personne' ) {
          aForm.find('button[name="add_org"]').click(function() {
            addOrganisme( aForm );
            return false;
          });
          aForm.find('button[name="add_perso"]').click(function() {
            addPersonne( aForm );
            return false;
          });
        }
        if ( parentId == 'div_form_mascarine_add_obs' ) {
          jForm.getControl('first_obs').addControl({
              name: 'add_org',
              label: 'add_org',
              required: false,
              errInvalid: '',
              errRequired: '',
              readOnly: false,
          },'0');
          jForm.getControl('first_obs').addControl({
              name: 'add_perso',
              label: 'add_perso',
              required: false,
              errInvalid: '',
              errRequired: '',
              readOnly: false,
          },'0');
          jForm.getControl('first_obs').activate('1');
        }
        if ( parentId == 'div_form_mascarine_add_obs'
          || parentId == 'div_form_mascarine_observation_general' ) {
          $.each(jForm.controls,function(index,control){
              initAjaxControlDate( control, jFormsJQ.config );
          });
          aForm.find('button[name="valider_obs"]').click(function() {
              if ( confirm('Êtes-vous sûr de vouloir valider cette observation ?') )
                aForm.find('.jforms-hiddens').hide().append('<input type="checkbox" name="validee_obs" checked="true"></input>');
              else
                return false;
          });
        }
        if ( parentId == 'div_form_mascarine_add_obs'
          || parentId == 'div_form_mascarine_observation_localisation' ) {
              var wkt = new OpenLayers.Format.WKT();
              var feat = wkt.read($('#'+formId+'_geo_wkt').val());
              feat.geometry.transform( 'EPSG:4326', Mascarine.map.getProjection() );
              Mascarine.layers['obstemp'].addFeatures( [ feat ] );
        }
        if ( parentId == 'div_form_mascarine_observation_flore' ) {
            $('#'+formId+'_cd_nom_autocomplete').autocomplete({
            minLength:2,
            autoFocus: true,
            source:function( request, response ) {
                request.limit = $('#form_mascarine_observation_flore_taxon_service_autocomplete input[name="limit"]').val();
                $.getJSON($('#form_mascarine_observation_flore_taxon_service_autocomplete').attr('action'),
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
                $('#'+formId+'_cd_nom').val( '' );
            },
            search: function( e, ui ) {
              $('#'+formId+'_cd_nom').val( '' );
            },
            select: function( e, ui ) {
              $(this).val( $('<a>').html(ui.item.nom_valide).text() );
              $('#'+formId+'_cd_nom').val( ui.item.cd_ref );
              //~ console.log( 'cd_ref: '+ui.item.cd_ref );
              //~ console.log( 'cd_nom: '+$('#'+formId+'_cd_nom').val() );
              return false;
            }
          }).autocomplete( "widget" ).css("z-index","1060");
          $('#'+formId+'_cd_nom_autocomplete').autocomplete( "instance" )._renderItem = function( ul, item ) {
            return $( "<li>" )
            .append( $("<a>").html( item.label ) )
            .appendTo( ul );
          };
        }
        if ( parentId == 'div_form_mascarine_observation_document' ) {
            var input = aForm.find('input[type="file"]');
            var span = $('<span class="btn fileinput-button"><i class="icon-plus"></i><span>Select</span></span>');
            span.appendTo( input.parent() );
            input.appendTo( span );
            var progressBar = $('<div id="progress"><div class="bar" style="height: 18px; background: green; width: 0%;"></div></div>');
            progressBar.appendTo( aForm.find('.jforms-submit-buttons') );
            $( input ).fileupload({
                dataType: 'text',
                add: function (e, data) {
                    data.context = $('<button class="btn"/>').text('Upload')
                        .appendTo(aForm.find('.jforms-submit-buttons'))
                        .click(function () {
                            data.context = $('<p/>').text('Uploading...').replaceAll($(this));
                            data.submit();
                        });
                    progressBar.find('.bar').css(
                        'width',
                        '0.0%'
                    );
                },
                done: function (e, data) {
                    data.context.text('Upload finished.');
                    $('#mascarine_observation_document_table').DataTable().ajax.reload();
                    $('#'+parentId).html( data.result );
                    var forms = parent.find('form');
                    $.each( forms, function( index, form ) {
                        initObservationForm( form );
                    });
                },
                progressall: function (e, data) {
                    var progress = parseInt(data.loaded / data.total * 100, 10);
                    progressBar.find('.bar').css(
                        'width',
                        progress + '%'
                    );
                }
            });
        }
        if ( parentId && parentId != 'div_form_mascarine_add_obs' ) {
            if ( aForm.find('.jforms-error-list').length > 0 ) {
                $('#div_mascarine_observation_forms .nav-tabs a[href="#'+tabPaneId+'"]').addClass('jforms-error-list');
            }
        }

        aForm.submit( function() {
            submitObservationForm( aForm );
            return false;
        });
    }

    function closeObservation() {
        Mascarine.layers['obstemp'].destroyFeatures();
        Mascarine.layers['obstemp'].setVisibility(false);
        $('#div_mascarine_observation_forms form button').unbind();
        $('#div_mascarine_observation_forms form').unbind();
        $('#div_mascarine_observation_forms').html('');
        $('#mascarine_observation_add').show();
        $('#mascarine_observation_unvalid').show();
        Mascarine.oneCtrlAtATime( 'drawModify', 'draw', ['drawLayer','resultLayer'] );
        var feat = Mascarine.layers['drawLayer'].getFeatureById( $('#form_mascarine_add_obs input[name="ol_feat_id"]').val() );
        if ( feat != null )
            Mascarine.controls['draw']['drawModifyLayerCtrl'].selectFeature( feat );
    }

    function addObservation() {
        var form = $('#form_mascarine_add_obs');
        $.post(form.attr('action'), form.serialize()
          , function( data ) {
              $('#div_mascarine_observation_forms').html( data );
              Mascarine.deactivateAllDrawqueryControl();
              $('#mascarine_observation_add').hide();
              $('#mascarine_observation_unvalid').hide();
              Mascarine.layers['obstemp'].destroyFeatures();
              Mascarine.layers['obstemp'].setVisibility(true);
              var forms = $('#div_mascarine_observation_forms form');
              if ( forms.length > 0 )
                initObservationForm( forms[0] );
              $('#div_mascarine_observation_forms button.close').click(function() {
                  closeObservation();
              });
              $('#div_mascarine_observation_forms button.zoom').click(function() {
                  Mascarine.map.zoomToExtent( Mascarine.layers['obstemp'].getDataExtent() );
                  return false;
              });
        });
    }

    function testGeometry() {
        var feat = Mascarine.controls['draw']['drawModifyLayerCtrl'].feature;
        if ( feat ) {
            var wkt = feat.geometry.clone().transform( Mascarine.map.getProjection(), 'EPSG:4326' ).toString();
            var form = $('#form_mascarine_service_testGeometry');
            $.post(form.attr('action')
              ,{wkt:wkt}
              , function( data ) {
                  if ( data.status == 1 ) {
                    var result = data.result[0];
                    $('#form_mascarine_add_obs input[name="code_commune"]').val(result.code_commune);
                    $('#form_mascarine_add_obs input[name="code_maille"]').val(result.code_maille);
                    var format = new OpenLayers.Format.GeoJSON();
                    $('#form_mascarine_add_obs input[name="geo_wkt"]').val( format.read(result.geojson)[0].geometry.toString() );
                    $('#form_mascarine_add_obs input[name="ol_feat_id"]').val( feat.id );
                    addObservation();
                  } else {
                    lizMap.addMessage( data.msg[0], 'error', true );
                  }
                  resetDrawButtonToolbar();
              }
            );
        }
    }

    function saveTemp() {
      var format = new OpenLayers.Format.GeoJSON();
      var geojson = format.write( Mascarine.layers['drawLayer'].features );
      var form = $('#form_mascarine_service_saveTemp');
      $.post(form.attr('action')
        ,{geojson:geojson}
        , function( data ) {
            console.log( data );
        }
      );
    }

Mascarine.events.on({
    'uicreated':function(evt){
        //~ console.log('Mascarine uicreated edit');

        $('#form_mascarine_personne_user').submit( function() {
            var form = $(this);
            $.get(form.attr('action'),{}
              , function( data ) {
                  $('#lizmap-modal').html(data);
                  var form = $('#lizmap-modal form')
                  var formId = form.attr('id');
                  form.submit(function() {
                      var self = $(this);
                      $.post( self.attr('action'), self.serialize()
                        , function( result ) {
                            $('#lizmap-modal').modal('hide');
                            if ( result.status == 1 ) {
                              lizMap.addMessage( result.msg.join('<br/>'), 'info', true );
                            } else {
                              window.setTimeout( function(){$('#form_mascarine_personne_user').submit()}, 1000 );
                            }
                        }
                      );
                      return false;
                  });
                  form.find('input[name="select_org"][value="0"]').change(function() {
                      //~ console.log('input[name="select_org"][value="0"]' +$(this).is(':checked') );
                      if ( $(this).is(':checked') )
                        form.find('input[name="select_perso"][value="0"]').click();
                  });
                  $('#lizmap-modal').modal('show');
              }
              , 'html'
            );
            return false;
        });

        Mascarine.controls['draw'] = {};

        var drawLayer = new OpenLayers.Layer.Vector("drawLayer", {styleMap:Mascarine.drawStyleMap});
        Mascarine.map.addLayers([drawLayer]);
        Mascarine.layers['drawLayer'] = drawLayer;

        // Dessin de point
        var drawPointLayerCtrl = new OpenLayers.Control.DrawFeature(drawLayer,
            OpenLayers.Handler.Point, {'featureAdded': drawFeatureAdded}
        );
        Mascarine.map.addControl(drawPointLayerCtrl);
        Mascarine.controls['draw']['drawPointLayerCtrl'] = drawPointLayerCtrl;

        // Dessin de ligne
        var drawLineLayerCtrl = new OpenLayers.Control.DrawFeature(drawLayer,
            OpenLayers.Handler.Path, {'featureAdded': drawFeatureAdded}
        );
        Mascarine.map.addControl(drawLineLayerCtrl);
        Mascarine.controls['draw']['drawLineLayerCtrl'] = drawLineLayerCtrl;

        // Dessin de polygone
        var drawPolygonLayerCtrl = new OpenLayers.Control.DrawFeature(drawLayer,
            OpenLayers.Handler.Polygon, {'featureAdded': drawFeatureAdded, styleMap:Mascarine.drawStyleMap}
        );
        Mascarine.map.addControl(drawPolygonLayerCtrl);
        Mascarine.controls['draw']['drawPolygonLayerCtrl'] = drawPolygonLayerCtrl;

        // controle de modification
        var drawModifyLayerCtrl = new OpenLayers.Control.ModifyFeature(drawLayer,
         {'onModificationStart':function(){
              $( "#obs-spatial-draw-buttons button.manage:not(.split)" ).removeClass('disabled');
          },'onModificationEnd':function(){
              $( "#obs-spatial-draw-buttons button.manage:not(.split)" ).addClass('disabled');
          },vertexRenderIntent:'temporary'
        }
        );
        Mascarine.map.addControl(drawModifyLayerCtrl);
        //drawModifyLayerCtrl.virtualStyle = Mascarine.drawStyleTemp;
        Mascarine.controls['draw']['drawModifyLayerCtrl'] = drawModifyLayerCtrl;
        /*
        drawLayer.events.on({
            "featureselected": function(e) {
                console.log("featureselected");
            },
            "featureunselected": function(e) {
                console.log("featureunselected");
            },
            "beforefeaturemodified": function(e) {
                console.log("beforefeaturemodified");
            },
            "afterfeaturemodified": function(e) {
                console.log("afterfeaturemodified "+Mascarine.controls['draw']['drawModifyLayerCtrl'].feature);
                if ( Mascarine.controls['draw']['drawModifyLayerCtrl'].feature != null )
                    $( "#obs-spatial-draw-buttons button.manage:not(.split)" ).addClass('disabled');
            }
        });
        * */

        var splitLayerCtrl = new OpenLayers.Control.Split({
            layer: drawLayer,
            eventListeners: {
                aftersplit: function(event) {
                    flashFeatures(event.features);
                    Mascarine.oneCtrlAtATime( 'drawModify', 'draw', ['drawLayer','resultLayer'] );
                    Mascarine.controls['draw']['drawModifyLayerCtrl'].selectFeature(event.features[0]);

                    resetDrawButtonToolbar();
                }
            }
        });
        Mascarine.map.addControl(splitLayerCtrl);
        Mascarine.controls['draw']['splitLayerCtrl'] = splitLayerCtrl;

        // Géométries temporaires pour affichage d'une observation temporaire
        // ----------------------------------------------------------------------
        var obstemp = new OpenLayers.Layer.Vector( 'obstemp',
            {isBaseLayer: false,visibility: true,styleMap: Mascarine.drawStyleMap}
        );
        Mascarine.map.addLayer(obstemp);
        Mascarine.layers['obstemp'] = obstemp;

        // contrôle de modification des géométries temporaires
        var drawModifyObstempCtrl = new OpenLayers.Control.ModifyFeature(obstemp, {styleMap:Mascarine.drawStyleMap});
        Mascarine.map.addControl(drawModifyObstempCtrl);
        Mascarine.controls['drawModifyObstempCtrl'] = drawModifyObstempCtrl;
        drawModifyObstempCtrl.deactivate();
        obstemp.setVisibility( false );

        $('#div_form_mascarine_draw_write form').submit(function(){
            var pt = new OpenLayers.Geometry.Point( parseFloat( $(this.coord_x).val() ), parseFloat( $(this.coord_y).val() ) );
            var projSrc = $(this.proj).val();
            lizMap.loadProjDefinition( projSrc, function() {
                lizMap.loadProjDefinition( Mascarine.map.getProjection(), function() {
                    pt.transform( projSrc, Mascarine.map.getProjection() );
                    if ( Mascarine.map.maxExtent.contains( pt.x, pt.y ) ) {
                        var feat = new OpenLayers.Feature.Vector( pt );
                        drawLayer.addFeatures( [ feat ] );
                        $('#obs-spatial-draw-buttons button.write').click();
                        drawFeatureAdded( feat );
                    } else {
                        lizMap.addMessage( 'Pas dans la carte', 'error', true );
                    }
                });
            });
            return false;
        });

        $('#div_form_mascarine_service_upload_gpx form').fileupload({
            dataType: 'xml',
            done: function (e, data) {
                var format = new OpenLayers.Format.GPX();
                var features = format.read( data.result );
                if ( features.length > 0 ) {
                    var maxExtent = Mascarine.map.maxExtent.clone();
                    maxExtent.transform( Mascarine.map.getProjection(), 'EPSG:4326' );
                    var tFeatures = [];
                    var outFeatures = 0;
                    while ( features.length > 0 ) {
                        var feat = features.pop();
                        if ( maxExtent.intersectsBounds( feat.geometry.getBounds() ) ) {
                            feat.geometry.transform( 'EPSG:4326', Mascarine.map.getProjection() );
                            tFeatures.push( feat );
                        } else {
                            outFeatures += 1;
                        }
                    }
                    if ( outFeatures > 0 ) {
                        lizMap.addMessage( outFeatures.length +' features out of the map', 'info', true );
                    }
                    if ( tFeatures.length > 0 ) {
                        lizMap.addMessage( tFeatures.length +' features added', 'info', true );
                        drawLayer.addFeatures( tFeatures );
                        Mascarine.oneCtrlAtATime( 'drawModify', 'draw', ['drawLayer','resultLayer'] );
                        Mascarine.controls['draw']['drawModifyLayerCtrl'].selectFeature(tFeatures[0]);
                        flashFeatures(tFeatures);
                    }
                } else {
                    lizMap.addMessage( 'No data read', 'error', true );
                }
                $('#obs-spatial-draw-buttons button.gpx').removeClass('active');
            }
        });

        $('#obs-spatial-draw-buttons button').button().click(function(){
            var self = $(this);
            if ( self.hasClass( 'disabled' ) )
              return false;

            var dataValue = self.attr('data-value');

            if ( self.hasClass('confirm') && !confirm( self.attr('alt') ) )
              return false;

            switch( dataValue ) {
                case 'drawCancel':
                    // Désactivation de tous les controles de dessins
                    Mascarine.deactivateAllDrawqueryControl();

                    // On vide la couche de dessin
                    Mascarine.emptyDrawqueryLayer(['queryLayer', 'resultLayer', 'resultLayer1', 'resultLayer2', 'resultLayer3', 'obstemp']);

                    // Curseur souris par défaut
                    $('#map').css('cursor','default');
                    $('#obs-spatial-draw-buttons button').removeClass('active');
                    return false;

                case 'drawPoint':
                case 'drawLine':
                case 'drawPolygon':
                    if ( self.hasClass( 'active' ) ) {
                        Mascarine.deactivateAllDrawqueryControl();
                        $('#map').css('cursor','default');
                        self.removeClass( 'active' );
                        return false;
                    } else {
                        $('#map').css('cursor','crosshair');
                        Mascarine.oneCtrlAtATime( dataValue, 'draw', ['drawLayer','resultLayer'] );
                    }
                    break;

                case 'splitGeometry':
                    if ( Mascarine.controls.draw.splitLayerCtrl.active )
                        Mascarine.deactivateAllDrawqueryControl();
                    else
                        Mascarine.oneCtrlAtATime( 'split', 'draw', ['drawLayer','resultLayer'] );
                    break;

                case 'intersectGeometry':
                    intersectionWithCommuneAndMaille();
                    break;

                case "deleteGeometry":
                  var feat = Mascarine.controls['draw']['drawModifyLayerCtrl'].feature;
                  if ( feat ) {
                      Mascarine.layers['drawLayer'].destroyFeatures( [feat] );
                      $('#obs-spatial-draw-buttons button').removeClass('active');
                      Mascarine.oneCtrlAtATime( 'drawModify', 'draw', ['drawLayer','resultLayer'] );
                      return false;
                  }
                  break;

                case 'addGeometry':
                    testGeometry();
                    break;

                case 'writePoint':
                    if ( self.hasClass( 'active' ) ) {
                        $('#div_form_mascarine_draw_write').hide();
                        self.removeClass( 'active' );
                        return false;
                    } else {
                        $('#div_form_mascarine_draw_write').show();
                    }
                    break;

                case 'gpx':
                    $('#div_form_mascarine_service_upload_gpx form input[type="file"]').click();
                    break;
            }
        });

        $('#mascarine_observation_add > h3 span.title button.zoom').click(function() {
            Mascarine.map.zoomToExtent( Mascarine.layers['drawLayer'].getDataExtent() );
        });
        addUnvalidateObservationTable();
        $('#mascarine_observation_unvalid > h3 span.title button.zoom').click(function() {
            Mascarine.map.zoomToExtent( Mascarine.layers['resultLayer'].getDataExtent() );
        });
        lizMap.events.on({
            dockopened: function(e) {
                if ( e.id == 'mascarine_edit' ) {
                    // Get layer
                    var rLayer = Mascarine.layers['resultLayer'];
                    rLayer.destroyFeatures();
                    updateUnvalidateObservationFeatures();
                    //rLayer.addFeatures( Mascarine.getResultFeatures( 'unvalidate' ) );
                    Mascarine.oneCtrlAtATime( 'drawModify', 'draw', ['drawLayer','resultLayer','obstemp'] );
                    rLayer.setVisibility(true);
                    rLayer.refresh();
                }
            }
        });
        Mascarine.map.events.on({
            zoomend : function() {
                if ( $('#button-mascarine_edit').parent().hasClass('active') )
                    Mascarine.oneCtrlAtATime( 'drawModify', 'draw', ['drawLayer','resultLayer','obstemp'] );
            }
        });
    }
});

});
