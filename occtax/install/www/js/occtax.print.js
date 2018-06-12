
lizMap.events.on({
'uicreated':function(evt){

    var printCapabilities = lizMap.getPrintCapabilities();
    var dragCtrl = lizMap.controls['printDrag'];
    var map = lizMap.map;
    var config = lizMap.config;
    var externalBaselayersReplacement = lizMap.getExternalBaselayersReplacement();

    $('#print-launch').unbind('click').click(function() {
      var pTemplate = dragCtrl.layout.template;
      var pTableVectorLayers = [];
      if( 'tables' in pTemplate )
          pTableVectorLayers = $.map( pTemplate.tables, function( t ){
              if( t.composerMap == -1 || ('map'+t.composerMap) == dragCtrl.layout.mapId )
                return t.vectorLayer;
          });
      // Print Extent
      var extent = dragCtrl.layer.features[0].geometry.getBounds();
      // Projection code and reverseAxisOrder
      var projCode = map.projection.getCode();
      var reverseAxisOrder = (OpenLayers.Projection.defaults[projCode] && OpenLayers.Projection.defaults[projCode].yx);

      // Build URL
      var url = OpenLayers.Util.urlAppend(lizUrls.wms
          ,OpenLayers.Util.getParameterString(lizUrls.params)
          );
      url += '&SERVICE=WMS';
      //url += '&VERSION='+capabilities.version+'&REQUEST=GetPrint';
      url += '&VERSION=1.3.0&REQUEST=GetPrint';
      url += '&FORMAT='+$('#print-format').val();
      url += '&EXCEPTIONS=application/vnd.ogc.se_inimage&TRANSPARENT=true';
      url += '&SRS='+projCode;
      url += '&DPI='+$('#print-dpi').val();
      url += '&TEMPLATE='+pTemplate.title;
      url += '&'+dragCtrl.layout.mapId+':extent='+extent.toBBOX(null, reverseAxisOrder);
      //url += '&'+dragCtrl.layout.mapId+':rotation=0';
      var scale = $('#print-scale').val();
      url += '&'+dragCtrl.layout.mapId+':scale='+scale;
      if ( 'grid' in pTemplate && pTemplate.grid == 'True' ) {
          var gridInterval = getPrintGridInterval( dragCtrl.layout, parseFloat(scale), printCapabilities.scales );
          url += '&'+dragCtrl.layout.mapId+':grid_interval_x='+gridInterval;
          url += '&'+dragCtrl.layout.mapId+':grid_interval_y='+gridInterval;
      }
      var printLayers = [];
      var styleLayers = [];
      var opacityLayers = [];
      $.each(map.layers, function(i, l) {
        if (
            l instanceof OpenLayers.Layer.WMS
            || ( l instanceof OpenLayers.Layer.WMTS && !(l.name.lastIndexOf('ign', 0) === 0 ) )
        ){
            if( l.getVisibility() ) {
              // Add layer to the list of printed layers
              printLayers.push(l.params['LAYERS']);
              // Optionnaly add layer style if needed (same order as layers )
              var lst = 'default';
              if( 'STYLES' in l.params && l.params['STYLES'].length > 0 )
                lst = l.params['STYLES'];
              styleLayers.push( lst );
              opacityLayers.push(parseInt(255*l.opacity));
            /*} else {
                var qgisName = null;
                if ( layer.name in cleanNameMap )
                    qgisName = getLayerNameByCleanName(name);
                var configLayer = null;
                if ( qgisName )
                    configLayer = config.layers[qgisName];
                if ( !configLayer )
                    configLayer = config.layers[layer.params['LAYERS']];
                if ( !configLayer )
                    configLayer = config.layers[layer.name];
                if ( configLayer && pTableVectorLayers.indexOf( configLayer.layerId ) != -1 ) {
                  // Add layer to the list of printed layers
                  printLayers.push(l.params['LAYERS']);
                  // Optionnaly add layer style if needed (same order as layers )
                  var lst = 'default';
                  if( 'STYLES' in l.params && l.params['STYLES'].length > 0 )
                    lst = l.params['STYLES'];
                  styleLayers.push( lst );
                  opacityLayers.push(parseInt(255*l.opacity));
                }*/
            }
        }
      });

      printLayers.reverse();
      styleLayers.reverse();
      opacityLayers.reverse();

      // Get active baselayer, and add the corresponding QGIS layer if needed
      var activeBaseLayerName = map.baseLayer.name;
      if ( activeBaseLayerName in externalBaselayersReplacement ) {
        var exbl = externalBaselayersReplacement[activeBaseLayerName];
        if( exbl in config.layers ) {
            var activeBaseLayerConfig = config.layers[exbl];
            if ( 'id' in activeBaseLayerConfig && 'useLayerIDs' in config.options && config.options.useLayerIDs == 'True' ){
                printLayers.push(activeBaseLayerConfig.id);
            }
            else{
                printLayers.push(exbl);
            }
            styleLayers.push('default');
            opacityLayers.push(255);
        }
      }

      // Add table vector layer without geom
      if( pTableVectorLayers.length > 0 ) {
          $.each( pTableVectorLayers, function( i, layerId ){
              var aConfig = lizMap.getLayerConfigById( layerId );
              if( aConfig ) {
                  var layerName = aConfig[0];
                  var layerConfig = aConfig[1];
                  if( ( layerConfig.geometryType == "none" || layerConfig.geometryType == "unknown" || layerConfig.geometryType == "" ) ) {
                      if ( 'shortname' in layerConfig && layerConfig.shortname != '' )
                          printLayers.push(layerConfig.shortname);
                      else
                          printLayers.push(layerConfig.name);
                      styleLayers.push('default');
                      opacityLayers.push(255);
                  }
              }
          });
      }

      if ( 'qgisServerVersion' in config.options && config.options.qgisServerVersion != '2.14' ) {
        printLayers.reverse();
        styleLayers.reverse();
        opacityLayers.reverse();
      }

      url += '&'+dragCtrl.layout.mapId+':LAYERS='+printLayers.join(',');
      url += '&'+dragCtrl.layout.mapId+':STYLES='+styleLayers.join(',');

      if ( dragCtrl.layout.overviewId != null
          && config.options.hasOverview ) {
        var bbox = config.options.bbox;
        var oExtent = new OpenLayers.Bounds(Number(bbox[0]),Number(bbox[1]),Number(bbox[2]),Number(bbox[3]));
        url += '&'+dragCtrl.layout.overviewId+':extent='+oExtent;
        url += '&'+dragCtrl.layout.overviewId+':LAYERS=Overview';
        if ( 'qgisServerVersion' in config.options && config.options.qgisServerVersion != '2.14' ) {
            printLayers.push('Overview');
            styleLayers.push('default');
            opacityLayers.push(255);
        } else {
        printLayers.unshift('Overview');
        styleLayers.unshift('default');
        opacityLayers.unshift(255);
      }
      }
      url += '&LAYERS='+printLayers.join(',');
      url += '&STYLES='+styleLayers.join(',');
      url += '&OPACITIES='+opacityLayers.join(',');
      var labels = $('#print .print-labels').find('input.print-label, textarea.print-label').serialize();
      if ( labels != "" )
        url += '&'+labels;
      var filter = [];
      var selection = [];
      for ( var  lName in config.layers ) {
          var lConfig = config.layers[lName];
          if ( !('request_params' in lConfig)
            || lConfig['request_params'] == null )
              continue;
          var requestParams = lConfig['request_params'];
          if ( ('filter' in lConfig['request_params'])
            && lConfig['request_params']['filter'] != null
            && lConfig['request_params']['filter'] != "" ) {
              filter.push( lConfig['request_params']['filter'] );
          }
          if ( ('selection' in lConfig['request_params'])
            && lConfig['request_params']['selection'] != null
            && lConfig['request_params']['selection'] != "" ) {
              selection.push( lConfig['request_params']['selection'] );
          }
      }
      if ( filter.length !=0 )
        url += '&FILTER='+ filter.join(';');
      if ( selection.length !=0 )
        url += '&SELECTION='+ selection.join(';');

      // occtax
      url = getOcctaxPrintUrlParams(url);

      window.open(url);
      return false;
    });


    function getOcctaxPrintUrlParams(url){
        // Occtax specific parameters
        var searchForm = $('#occtax_service_search_maille_form_m02');
        var datatype = 'm02';
        if( $('#occtax_results_maille_table_div_m01.active').length > 0 ){
            var searchForm = $('#occtax_service_search_maille_form_m01');
            var datatype = 'm01';
        }
        //if( $('#occtax_results_maille_table_div_m05.active').length > 0 ){
            //var searchForm = $('#occtax_service_search_maille_form_m05');
            //var datatype = 'm05';
        //}
        if( $('#occtax_results_maille_table_div_m10.active').length > 0 ){
            var searchForm = $('#occtax_service_search_maille_form_m10');
            var datatype = 'm10';
        }
        if( $('#occtax_results_observation_table_div.active').length > 0 ){
            searchForm = $('#occtax_service_search_form');
            datatype = 'b';
        }
        if( searchForm ) {

            var token = searchForm.find('input[name="token"]').val();
            var limit = searchForm.find('input[name="limit"]').val();
            var offset = searchForm.find('input[name="offset"]').val();

            if( token ){
                url = url.replace('/lizmap/service/', '/occtax/lizmapService/');
                url += '&token=' + token;
                url += '&datatype=' + datatype;
                if( datatype == 'b' )
                    url += '&limit=' + limit + '&offset=' + offset;
            }
        }
        return url;
    }

  } // uicreated
});

