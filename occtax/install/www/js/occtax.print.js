var lizAttributeTable = function() {

    lizMap.events.on({
        'uicreated':function(evt){

            var printCapabilities = lizMap.getPrintCapabilities();
            var dragCtrl = lizMap.controls['printDrag'];
            var map = lizMap.map;
            var config = lizMap.config;
            var externalBaselayersReplacement = lizMap.getExternalBaselayersReplacement();

            $('#print-launch').unbind('click').click(function() {

                var pTemplate = dragCtrl.layout.template;
                var extent = dragCtrl.layer.features[0].geometry.getBounds();
                var url = OpenLayers.Util.urlAppend(lizUrls.wms
                    ,OpenLayers.Util.getParameterString(lizUrls.params)
                );
                url += '&SERVICE=WMS';
                //url += '&VERSION='+capabilities.version+'&REQUEST=GetPrint';
                url += '&VERSION=1.3&REQUEST=GetPrint';
                url += '&FORMAT=pdf&EXCEPTIONS=application/vnd.ogc.se_inimage&TRANSPARENT=true';
                url += '&SRS='+map.projection;
                url += '&DPI='+$('#print-dpi').val();
                url += '&TEMPLATE='+pTemplate.title;
                url += '&'+dragCtrl.layout.mapId+':extent='+extent;
                //url += '&'+dragCtrl.layout.mapId+':rotation=0';
                var scale = $('#print-scale').val();
                url += '&'+dragCtrl.layout.mapId+':scale='+scale;
                var gridInterval = lizMap.getPrintGridInterval( dragCtrl.layout, parseFloat(scale), printCapabilities.scales );
                url += '&'+dragCtrl.layout.mapId+':grid_interval_x='+gridInterval;
                url += '&'+dragCtrl.layout.mapId+':grid_interval_y='+gridInterval;
                var printLayers = [];
                var styleLayers = [];
                $.each(map.layers, function(i, l) {
                  if (l.getVisibility()
                    && (
                      l.CLASS_NAME == "OpenLayers.Layer.WMS"
                      || ( l.CLASS_NAME == "OpenLayers.Layer.WMTS" && !(l.name.lastIndexOf('ign', 0) === 0 ) )
                    )
                  ){
                    // Add layer to the list of printed layers
                    printLayers.push(l.params['LAYERS']);
                    // Optionnaly add layer style if needed (same order as layers )
                    var lst = 'default';
                    if( 'STYLES' in l.params && l.params['STYLES'].length > 0 )
                      lst = l.params['STYLES'];
                    styleLayers.push( lst );
                  }
                });

                printLayers.reverse();
                styleLayers.reverse();

                // Get active baselayer, and add the corresponding QGIS layer if needed
                var activeBaseLayerName = map.baseLayer.name;
                if ( activeBaseLayerName in externalBaselayersReplacement ) {
                    printLayers.push(externalBaselayersReplacement[activeBaseLayerName]);
                }

                url += '&'+dragCtrl.layout.mapId+':LAYERS='+printLayers.join(',');
                url += '&'+dragCtrl.layout.mapId+':STYLES='+styleLayers.join(',');
                if ( dragCtrl.layout.overviewId != null
                  && config.options.hasOverview ) {
                    var bbox = config.options.bbox;
                    var oExtent = new OpenLayers.Bounds(Number(bbox[0]),Number(bbox[1]),Number(bbox[2]),Number(bbox[3]));
                    url += '&'+dragCtrl.layout.overviewId+':extent='+oExtent;
                    url += '&'+dragCtrl.layout.overviewId+':LAYERS=Overview';
                    printLayers.unshift('Overview');
                    styleLayers.unshift('Overview');
                }
                url += '&LAYERS='+printLayers.join(',');
                url += '&STYLES='+styleLayers.join(',');
                var labels = $('#print-menu .print-labels').find('input, textarea').serialize();
                if ( labels != "" )
                    url += '&'+labels;

                // Occtax specific parameters
                var searchForm = $('#occtax_service_search_maille_form');
                var datatype = 'm';
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

                window.open(url);
                return false;
            });


      } // uicreated
    });


}();
