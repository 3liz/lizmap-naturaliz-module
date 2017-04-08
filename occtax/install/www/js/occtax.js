var OccTax = function() {
  occTaxObservationResult = null;
  occTaxMailleResult_m02 = null;
  occTaxMailleResult_m10 = null;
  // creating the OccTax object
  var obj = {
    map: null,
    layers: {},
    controls: {},
    config: {},

    /**
     *  Initialise TOUTES les couches de dessin
     * -------------------------------------------------------------------------- */
    emptyDrawqueryLayer: function( layersNotToEmpty ){
        if ( !$.isArray(layersNotToEmpty) )
          layersNotToEmpty = [layersNotToEmpty];
        theLayers = ['drawLayer', 'queryLayer', 'resultLayer', 'resultLayer1', 'resultLayer2', 'resultLayer3', 'obstemp'];
        for(key in theLayers){
          if ( layersNotToEmpty.indexOf( theLayers[key] ) == -1 ){
            var thisLayer = this.layers[ theLayers[key]];
            if(thisLayer){
              var allFeatures = thisLayer.features;
              if(allFeatures){
                if(this.layers[ theLayers[key]].features.length != 0){
                  this.layers[ theLayers[key]].destroyFeatures();
                }
              }
              thisLayer.setVisibility(false);
            }
          }
        }
    },

    /**
     * Désactivation de tous les controles de dessin actifs
     * -------------------------------------------------------------------------- */
    deactivateAllDrawqueryControl: function(controlNotToDeactivate, base ){
       var baseControl;

       if ( typeof(base) == 'undefined')
           baseControl = OccTax.controls;
       else
           baseControl = OccTax.controls[base];

       for(key in baseControl){

           if ( key == 'query' || key == 'draw' )
               OccTax.deactivateAllDrawqueryControl(controlNotToDeactivate, key);

           if ( key != controlNotToDeactivate ) {
               var thisCtrl = baseControl[key];
               if(thisCtrl && key != 'dragFeature' && key != 'mousePosition'){
                   if(thisCtrl.active){baseControl[key].deactivate();}
               }
           }
       }
    },

    /**
     * Active qu'un seul control à la fois
     */
    oneCtrlAtATime: function( type, layerRole, layersNotToEmpty ){
        layersNotToEmpty = layersNotToEmpty || "";

        OccTax.emptyDrawqueryLayer(layersNotToEmpty);
        var theLayer = OccTax.layers[ layerRole + 'Layer'];
        if( theLayer ) {
            theLayer.setVisibility(true);
            // On désactive tous les contrôles puis on active celui de la couche
            OccTax.deactivateAllDrawqueryControl();

            /**
             * ugly Hack during dev
             */
            if ( typeof(OccTax.controls[layerRole]) != 'undefined'
              && typeof(OccTax.controls[layerRole][ type + 'LayerCtrl' ]) != 'undefined') {
                OccTax.controls[layerRole][ type + 'LayerCtrl' ].activate();
            }
            else if ( typeof(OccTax.controls[ type + 'LayerCtrl' ]) != 'undefined' )
                OccTax.controls[ type + 'LayerCtrl' ].activate();
        }
    },

    /**
     * Valide et réduit la taille d'une géométrie si celle-ci dépasse maxAreaQuery
     */
    validGeometryFeature: function( feature ){
        if(OccTax.config.maxAreaQuery > 0 && feature.geometry.getArea() >= OccTax.config.maxAreaQuery) {
            //mascarineService.displayMessage( 'error', "L'aire ne peut pas dépasser "+ OccTax.config.maxAreaQuery / 1000000 +" km² !");
            // suppression de la géométrie et on réduit le cercle à la surface max
            var myRadius = Math.sqrt( OccTax.config.maxAreaQuery / Math.PI );
            var myCentroid = feature.geometry.getCentroid();
            var maxCircle = OpenLayers.Geometry.Polygon.createRegularPolygon(myCentroid, myRadius, 40, 0);
            maxCircle.id = feature.geometry.id;
            feature.geometry = maxCircle;
        }
        return feature;
    },

    /**
     * Fournis les résultats sous forme d'un tableau de features
     */
/*
    getMaille: function( rowId ){
        var results = occTaxMailleResult;
        var feature = null;

        // Get data
        var fields = results['fields'];
        if ( !fields )
          return feature;

        var rowIdField = fields['row_id'];
        var rowIdIdx = fields['return'].indexOf( rowIdField );
        var geoIdx = fields['return'].indexOf( 'geojson' );
        var format = new OpenLayers.Format.GeoJSON();

        for( var i=0, len=results.data.length; i<len; i++ ) {
            var d = results.data[i];
            if ( d[rowIdIdx] != rowId )
              continue;

            var geom = format.read( d[geoIdx] )[0].geometry;
            var attributes = {};
            for( j in fields['return']) {
                //if( $.inArray( fields['return'][j], fields['display'] ) > -1 )
                attributes[ fields['return'][j] ] = d[j];
                if( $.inArray( fields['return'][j], fields['display'] ) > -1 )
                  messageText.push( displayFieldsHead[fields['return'][j]]+' '+d[j] );
            }

            geom.transform('EPSG:4326', OccTax.map.projection);
            feature = new OpenLayers.Feature.Vector( geom, attributes);
            feature.fid = d[ fields['return'].indexOf( fields['row_id'] ) ];
            break;
        }
        return feature;
    },
*/

    /**
     * Fournis les résultats sous forme d'un tableau de features
     */
    getResultFeatures: function( type ){

        var results = [];
        if (type == 'm10')
            results = occTaxMailleResult_m10;
        else if (type == 'm02')
            results = occTaxMailleResult_m02;
        else if (type == 'observation')
            results = occTaxObservationResult;

        var format = new OpenLayers.Format.GeoJSON();
        var features = [];
        if (!results)
            return null;

        // Get data
        var fields = results['fields'];
        if ( !fields )
          return features;
        var geoIdx = fields['return'].indexOf( 'geojson' );

        var th = $('#occtax_results_observation_table th');
        if (type == 'm10')
          th = $('#occtax_results_maille_table_'+type+' th');

        var displayFieldsHead = {};
        for( var i=0, len=th.length; i<len; i++ ) {
            var h = $(th[i]);
            var k = h.attr('data-value').split(',')[0];
            displayFieldsHead[k] = h.text().trim() ;
        }

        for( var i=0, len=results.data.length; i<len; i++ ) {
            var d = results.data[i];
            var geom = null;
            if( d[geoIdx] )
                geom = format.read( d[geoIdx] )[0].geometry;
            var messageText = [];
            var attributes = {};
            for( j in fields['return']) {
                attributes[ fields['return'][j] ] = d[j];
                if( fields['return'][j] in fields['display'] )
                  messageText.push( displayFieldsHead[fields['return'][j]]+' '+d[j] );
            }
            attributes['message_text'] = messageText.join(', ');
            if( geom ) {
                geom.transform('EPSG:4326', OccTax.map.projection);
                var feat = new OpenLayers.Feature.Vector( geom, attributes);
                feat.fid = d[ fields['return'].indexOf( fields['row_id'] ) ];
                features.push( feat);
            }
            //~ console.log(feat);
        }
        return features;
    },
    /**
     * Property: events
     * {<OpenLayers.Events>} An events object that handles all
     *                       events on the lizmap
     */
    events: null,
    /**
     * Method: init
     */
    init: function() {
        // getConfigJSON
        // construct a json based on mascarine.ini.php
        // contain for exemple maxAreaQuery
        this.events.triggerEvent("uicreated", this);
    }
  };
  // initializing the OccTax events
  obj.events = new OpenLayers.Events(
      obj, null,
      ['uicreated','mailledatareceived_m02','mailledatareceived_m10','observationdatareceived'],
      true,
      {includeXY: true}
    );
  obj.events.on({
    'observationdatareceived':function(evt){
        if ('results' in evt )
          occTaxObservationResult = evt.results;
    }
   ,'mailledatareceived_m02':function(evt){
        if ('results' in evt )
          occTaxMailleResult_m02 = evt.results;
    }
   ,'mailledatareceived_m10':function(evt){
        if ('results' in evt )
          occTaxMailleResult_m10 = evt.results;
    }
  });
  return obj;
}();


lizMap.events.on({
    'uicreated':function(evt){
          //console.log('uicreated');
        OccTax.map = lizMap.map;
        // Style des couches
        // ----------------------------------------------------------------------
        OccTax.resultLayerContext = {
            getPointRadius:function(feat) {
                var res = OccTax.map.getResolution();

                if(feat.attributes.rayon > 0){
                    //~ return feat.attributes.rayon; //
                    return Math.round(feat.attributes.rayon / res); //pour rayon en mètre
                }else{
                    return (OccTax.map.getZoom() + 1) * 1.5;
                }
            },
            getPointColor:function(feat) {
                if (!feat.attributes.color)
                  feat.attributes.color = '#'+Math.floor(Math.random()*16777215).toString(16);
                return feat.attributes.color;
            },
            getStrokeWidth:function(feat) {
                mySw = (OccTax.map.getZoom() + 1) * 1.5;
                if(mySw < 3){mySw = 3;}
                return mySw;
            },
            getPointRadiusSelect:function(feat) {
                var res = OccTax.map.getResolution();

                if(feat.attributes.rayon > 0){
                    //~ return feat.attributes.rayon; //
                    return Math.round(feat.attributes.rayon / res) * 1.5; //pour rayon en mètre
                }else{
                    return (OccTax.map.getZoom() + 1) * 1.5 * 1.5;
                }
            },
            getStrokeWidthSelect:function(feat) {
                mySw = (OccTax.map.getZoom() + 1) * 1.5 * 2;
                if(mySw < 3){mySw = 3 * 2;}
                return mySw;
            },
            getGraphicName:function(feat) {
                var graphic = 'circle';
                if(
                    feat.attributes.source_objet &&
                    feat.attributes.source_objet.indexOf('maille') == 0 // starts with maille -> square
                )
                    graphic = 'square';
                return graphic;

            }
        };

        var resultLayerTemplateDefault = {
            pointRadius: "${getPointRadius}",
            fillColor: "${getPointColor}",
            fillOpacity: 1,
            strokeColor: "${getPointColor}",
            strokeOpacity: 1,
            strokeDashstyle: "solid",
            strokeWidth: "${getStrokeWidth}",
            graphicName: "${getGraphicName}"
        };
        OccTax.resultLayerStyleDefault = new OpenLayers.Style(
            resultLayerTemplateDefault, {context: OccTax.resultLayerContext}
        );

        var resultLayerTemplateSelect = {
            pointRadius: "${getPointRadius}",
            fillColor: "${getPointColor}",
            fillOpacity: 1,
            strokeColor: "blue",
            strokeOpacity: 1,
            strokeDashstyle: "solid",
            strokeWidth: "${getStrokeWidthSelect}",
            graphicName: "${getGraphicName}"
        };
        OccTax.resultLayerStyleSelect = new OpenLayers.Style(
            resultLayerTemplateSelect, {context: OccTax.resultLayerContext}
        );

        OccTax.resultLayerStyleMap = new OpenLayers.StyleMap({
            "default": OccTax.resultLayerStyleDefault,
            "select" : OccTax.resultLayerStyleSelect
        });

        // Style des outils de dessin et sélection
        // -------------------------------------------------------------------------
        OccTax.drawStyle = new OpenLayers.Style({
            pointRadius:7,
            fillColor: "#94EF05",
            fillOpacity: 0.3,
            strokeColor: "yellow",
            strokeOpacity: 1,
            strokeWidth: 3
        });

        OccTax.drawStyleTemp = new OpenLayers.Style({
            pointRadius:7,
            fillColor: "orange",
            fillOpacity: 0.3,
            strokeColor: "blue",
            strokeOpacity: 1,
            strokeWidth: 3
        });

        OccTax.drawStyleSelect = new OpenLayers.Style({
            pointRadius:7,
            fillColor: "blue",
            fillOpacity: 0.3,
            strokeColor: "blue",
            strokeOpacity: 1,
            strokeWidth: 3
        });

        OccTax.drawStyleMap = new OpenLayers.StyleMap({
            "default":   OccTax.drawStyle,
            "temporary": OccTax.drawStyleTemp,
            "select" :   OccTax.drawStyleSelect
        });

        OccTax.config = occtaxClientConfig;

        OccTax.init();

        // Hide home button
        $('#mapmenu li.home').hide();

        // Show observation search
        $('#button-occtax').click();
        $('#button-taxon').parent('li.taxon').hide();


    },

    // Adapt dock size to display metadata
    dockopened: function(e) {
        if ( e.id == 'metadata' ) {
            //$('#dock')
            //.css('max-width', 'none')
            //.css('width', '50%')
            //;

            // Replace metadata content
            if( $('#occtax-metadata').length ){
                var ohtml = $('#occtax-metadata').html();
                $('#metadata').html(ohtml);
            }
        }
    }
    //,

    //dockclosed: function(e) {
        //if ( e.id == 'metadata' ) {
            //$('#dock')
            //.css('max-width', '30%')
            //.css('width', 'none')
            //;
        //}
    //}

});
