var OccTax = function() {
  occTaxObservationResult = null;
  occTaxMailleResult_m01 = null;
  occTaxMailleResult_m02 = null;
  occTaxMailleResult_m05 = null;
  occTaxMailleResult_m10 = null;

  // creating the OccTax object
  var obj = {
    map: null,
    layers: {},
    controls: {},
    config: {},
    //observation_style: 'menace',
    observation_style: 'protection',

    annee_dizaine: Math.round(parseInt(new Date().getFullYear()) / 10) * 10,

    /**
     *  Initialise TOUTES les couches de dessin
     * -------------------------------------------------------------------------- */
    emptyDrawqueryLayer: function( layersNotToEmpty ){
        if ( !$.isArray(layersNotToEmpty) )
          layersNotToEmpty = [layersNotToEmpty];
        theLayers = ['drawLayer', 'queryLayer', 'mailleLayer', 'observationLayer', 'observationTempLayer'];
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
            // suppression de la géométrie et on réduit le cercle à la surface max
            var myRadius = Math.sqrt( OccTax.config.maxAreaQuery / Math.PI );
            var myCentroid = feature.geometry.getCentroid();
            var maxCircle = OpenLayers.Geometry.Polygon.createRegularPolygon(myCentroid, myRadius, 40, 0);
            maxCircle.id = feature.geometry.id;
            feature.geometry = maxCircle;
        }
        return feature;
    },


    // Remplace les features d'une couche par les nouvelles données
    refreshFeatures: function(type) {
        // Choose layer
        var rLayer = OccTax.layers['mailleLayer'];
        if (type == 'observation') {
          rLayer = OccTax.layers['observationLayer'];
        }

        // Destroy previous features
        rLayer.destroyFeatures();

        // Parse the features comming from the backend into data usable by OpenLayers
        var the_features = OccTax.getResultFeatures(type);

        // Add raw features
        rLayer.addFeatures(the_features);

        // Show
        rLayer.setVisibility(true);
        //rLayer.refresh();
    },

    /**
     * Fournis les résultats sous forme d'un tableau de features
     */
    getResultFeatures: function( type ){

        var results = [];
        if (type == 'm10')
            results = occTaxMailleResult_m10;
        //else if (type == 'm05')
            //results = occTaxMailleResult_m05;
        else if (type == 'm02')
            results = occTaxMailleResult_m02;
        else if (type == 'm01')
            results = occTaxMailleResult_m01;
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
        if (type == 'm01')
          th = $('#occtax_results_maille_table_'+type+' th');
        if (type == 'm02')
          th = $('#occtax_results_maille_table_'+type+' th');
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
            if( d[geoIdx] ) {
                geom = format.read( d[geoIdx] )[0].geometry;
            }
            // messageText is the text representation of the feature
            // used to display detail in Lizmap message bar
            var messageText = [];
            var attributes = {};
            var avoided_properties = [ 'filter', 'detail'];
            for (j in fields['return']) {

                // Do not add property text in tooltip for some properties
                if ($.inArray(fields['return'][j], avoided_properties) > -1) {
                    continue;
                }

                // Add field data in attributes
                attributes[ fields['return'][j] ] = d[j];

                // For mailles, build message_text content
                // Display property label (same as in table) and value. "Maille XXX - Nb Obs. 34 - Nb taxons 37"
                // For observation, not done here but only on feature selected
                // Build message text representation
                if (type != 'observation') {
                    if (fields['return'][j] in fields['display']) {
                        messageText.push( displayFieldsHead[fields['return'][j]]+' : '+d[j] );
                    }
                }
            }
            if (type != 'observation') {
                // Add simple message
                attributes['message_text'] = messageText.join(' - ');
            }
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
      [
        'uicreated',
        'mailledatareceived_m01',
        'mailledatareceived_m02',
        //'mailledatareceived_m05',
        'mailledatareceived_m10',
        'observationdatareceived'
      ],
      true,
      {includeXY: true}
    );
  obj.events.on({
    'observationdatareceived':function(evt){
        if ('results' in evt )
          occTaxObservationResult = evt.results;
    }
   ,'mailledatareceived_m01':function(evt){
        if ('results' in evt )
          occTaxMailleResult_m01 = evt.results;
    }
   ,'mailledatareceived_m02':function(evt){
        if ('results' in evt )
          occTaxMailleResult_m02 = evt.results;
    }
   //,'mailledatareceived_m05':function(evt){
        //if ('results' in evt )
          //occTaxMailleResult_m05 = evt.results;
    //}
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

        // mailleLayer
        OccTax.mailleLayerContext = {
            getPointRadius:function(feat) {
                var res = OccTax.map.getResolution();
                // Draw square underneath maille features
                // NB: in mailleLayer, mailles are duplicated: one for point with radius, one for square
                if('square' in feat.attributes){
                    var rad = Math.round((feat.attributes.square / 2) / res);
                } else {
                    var rad = Math.round(feat.attributes.rayon / res); //pour rayon en mètre
                }
                return rad;
            },
            getPointColor:function(feat) {
                return feat.attributes.color;
            },
            getStrokeWidth:function(feat) {
                mySw = (OccTax.map.getZoom() + 1);
                if(mySw < 3){mySw = 3;}
                // Draw square underneath maille features
                if('square' in feat.attributes){
                    mySw = 0.5;
                }
                return mySw;
            },
            getStrokeWidthSelect:function(feat) {
                mySw = (OccTax.map.getZoom() + 1);
                if(mySw < 3){mySw = 3;}
                // Hide square underneath maille features on select
                if('square' in feat.attributes){
                    mySw = 0;
                }
                return mySw;
            },
            getGraphicName:function(feat) {
                var graphic = 'circle';
                if(
                    feat.attributes.source_objet &&
                    feat.attributes.source_objet.indexOf('maille') == 0 // starts with maille -> square
                ){
                    graphic = 'square';
                }
                // Draw square underneath maille features
                if('square' in feat.attributes){
                    graphic = 'square';
                }
                return graphic;
            },
            getFillOpacity:function(feat) {
                var fo = 1;
                // Draw square underneath maille features
                if('square' in feat.attributes){
                    fo = 0.2;
                }
                return fo;
            },
            getDefaultStrokeColor:function(feat) {
                var sc = 'white';
                if( 'strokeColor' in OccTax.config )
                    sc = OccTax.config.strokeColor;
                return sc;
            }
        };

        var mailleLayerTemplateDefault = {
            pointRadius: "${getPointRadius}",
            fillColor: "${getPointColor}",
            fillOpacity: "${getFillOpacity}",
            strokeColor: "${getDefaultStrokeColor}",
            strokeOpacity: 1,
            strokeDashstyle: "solid",
            strokeWidth:1,
//            strokeWidth: "${getStrokeWidth}",
            graphicName: "${getGraphicName}",
            cursor: "pointer"
        };
        OccTax.mailleLayerStyleDefault = new OpenLayers.Style(
            mailleLayerTemplateDefault, {context: OccTax.mailleLayerContext}
        );

        var mailleLayerTemplateSelect = {
            pointRadius: "${getPointRadius}",
            fillColor: "${getPointColor}",
            fillOpacity: "${getFillOpacity}",
            strokeColor: "blue",
            strokeOpacity: 1,
            strokeDashstyle: "solid",
            strokeWidth: "${getStrokeWidthSelect}",
            graphicName: "${getGraphicName}",
            cursor: "pointer"
        };
        OccTax.mailleLayerStyleSelect = new OpenLayers.Style(
            mailleLayerTemplateSelect, {context: OccTax.mailleLayerContext}
        );

        OccTax.mailleLayerStyleMap = new OpenLayers.StyleMap({
            "default": OccTax.mailleLayerStyleDefault,
            "select" : OccTax.mailleLayerStyleSelect
        });

        var redlist_colors = {
            'CR': '#D3001B',
            'DD': '#D3D4D5',
            'EN': '#FBBF00',
            'EW': '#3D1951',
            'EX': '#000000',
            'LC': '#78B74A',
            'NA': '#919294',
            'NE': '#E9EAEB',
            'NT': '#FBF2CA',
            'RE': '#5A1A63',
            'VU': '#FFED00'
        };

        var protection_colors = {
            'EPN': '#7499ff',
            'EPC': '#7fa8ff',
            'EPI': '#a4c1ff',
            'EPA': '#c4d7ff'
        };

// Todo: essayer de récupérer
//var elem,
    //style;
//elem = document.querySelector('.test');
//style = getComputedStyle(elem);
//style.marginTop; //`20px`

        // Function to choose color depending on feature attributes
        function getPointColorByAttributes(afeat) {
            var color = '#FFFFFF80';
            if (afeat.attributes.color) {
                color = afeat.attributes.color;
            } else {
                // Style feature based on property
                if (OccTax.observation_style == 'menace') {
                    var menace = OccTax.config.taxon_detail_nom_menace;
                    color = '#E9EAEB';
                    if (menace in afeat.attributes && afeat.attributes[menace] in redlist_colors ) {
                        color = redlist_colors[afeat.attributes[menace]];
                    }
                } else if (OccTax.observation_style == 'protection') {
                    color = '#C7D6FF';
                    if ('protection' in afeat.attributes && afeat.attributes['protection'] in protection_colors ) {
                        color = protection_colors[afeat.attributes['protection']];
                    }
                } else if (OccTax.observation_style == 'date') {
                    color = '#FFFFFF80';
                    if ('date_debut' in afeat.attributes && afeat.attributes['date_debut'] ) {
                        var obs_annee = parseInt(afeat.attributes['date_debut'].substring(0,4));
                        if (obs_annee < 1950) {
                            color = '#fff5eb';
                        }
                        else if (obs_annee >= 1950 && obs_annee < 2000) {
                            color = '#fdd2a5';
                        }
                        else if (obs_annee >= 2000 && obs_annee < (OccTax.annee_dizaine - 10)) {
                            color = '#fd9243';
                        }
                        else if (obs_annee >= (OccTax.annee_dizaine - 10) && obs_annee < OccTax.annee_dizaine) {
                            color = '#df5005';
                        }
                        else if (obs_annee >= OccTax.annee_dizaine) {
                            color = '#7f2704';
                        }
                    }
                } else {
                    // Random colors
                    //color = '#'+Math.floor(Math.random()*16777215).toString(16);
                    color = '#FFFFFF80';
                }
            }
            return color;
        }

        function getLabelByAttribute(afeat) {
            var label = '';
            if (OccTax.observation_style == 'menace') {
                var menace_label = afeat.attributes[OccTax.config.taxon_detail_nom_menace];
                if (menace_label) {
                    return menace_label;
                }
            }
            return label;
        }

        // ObservationLayer
        OccTax.observationLayerContext = {
            getPointRadius:function(feat) {
                var len = 1;
                if (feat.cluster) {
                    len = feat.cluster.length;
                }
                var rad = (OccTax.map.getZoom() + 3);
                if(len > 1) {
                    rad = Math.max(rad + feat.attributes.count/10, rad + 4);
                }
                return rad;
            },
            getPointColor:function(feat) {
                var color = '#FFFFFF80';
                var len = 1;
                if (feat.cluster) {
                    len = feat.cluster.length
                };
                if(len > 1) {
                    // Cluster color
                    color = '#FFFFFF80';
                } else {
                    if(feat.cluster) {
                        var afeat = feat.cluster[0];
                    } else {
                        var afeat = feat;
                    }
                    color = getPointColorByAttributes(afeat);
                }
                return color;
            },
            getStrokeWidth:function(feat) {
                mySw = (OccTax.map.getZoom() + 1);
                if(mySw < 3){mySw = 3;}
                return mySw;
            },
            getGraphicName:function(feat) {
                var graphic = 'square';
                if (feat.cluster && feat.cluster.length > 1) {
                    graphic = 'circle';
                }
                return graphic;
            },
            getFillOpacity:function(feat) {
                var fo = 1;
                return fo;
            },
            getLabel: function(feat) {
                var label = '';
                if (feat.cluster) {
                    if (feat.cluster.length > 1) {
                        return feat.cluster.length;
                    } else {
                        return getLabelByAttribute(feat.cluster[0])
                    }
                }
                return getLabelByAttribute(feat);
            },
            getLabelFontSize: function(feat) {
                if (feat.cluster) {
                    if (feat.cluster.length > 1) {
                        return 15;
                    } else {
                        return 10;
                    }
                }
                return 10;
            }
            //,
            //getExternalGraphic: function(feat) {
                //var tpl = 'http://naturaliz-reunion.localhost/taxon/css/images/groupes/REPLACE.png'
                //if (feat.cluster) {
                    //if (feat.cluster.length > 1) {
                        //return '';
                    //}
                    //return tpl.replace('REPLACE', 'reptiles');
                //}
                //return '';
            //}
        };

        var observationLayerTemplateDefault = {
            pointRadius: "${getPointRadius}",
            fillColor: "${getPointColor}",
            fillOpacity: "${getFillOpacity}",
            strokeColor: "#040404",
            strokeOpacity: 1,
            strokeDashstyle: "solid",
            strokeWidth:1,
            //strokeWidth: "${getStrokeWidth}",
            graphicName: "${getGraphicName}",
            //externalGraphic: "${getExternalGraphic}",
            cursor: "pointer",
            label: "${getLabel}",
            fontSize: "${getLabelFontSize}",
            fontColor: '#040404'
        };
        OccTax.observationLayerStyleDefault = new OpenLayers.Style(
            observationLayerTemplateDefault, {context: OccTax.observationLayerContext}
        );

        var observationLayerTemplateSelect = {
            pointRadius: "${getPointRadius}",
            fillColor: "${getPointColor}",
            fillOpacity: "${getFillOpacity}",
            strokeColor: "blue",
            strokeOpacity: 1,
            strokeDashstyle: "solid",
            //strokeWidth: "${getStrokeWidth}",
            strokeWidth: 2,
            graphicName: "${getGraphicName}",
            cursor: "pointer"
        };
        OccTax.observationLayerStyleSelect = new OpenLayers.Style(
            observationLayerTemplateSelect, {context: OccTax.observationLayerContext}
        );

        OccTax.observationLayerStyleMap = new OpenLayers.StyleMap({
            "default": OccTax.observationLayerStyleDefault,
            "select" : OccTax.observationLayerStyleSelect
        });


        // Style de la couche temporaire pour afficher une ou deux observations
        // -------------------------------------------------------------------------
        OccTax.tempStyle = new OpenLayers.Style({
            //pointRadius: "${getPointRadius}",
            pointRadius: 15,
            fillColor: "lightblue",
            fillOpacity: 0.3,
            //strokeColor: "${getPointColor}",
            strokeColor: "blue",
            strokeOpacity: 1,
            strokeWidth: 3,
            graphicName: 'square'
        }, {context: OccTax.observationLayerContext});

        OccTax.tempStyleMap = new OpenLayers.StyleMap({
            "default":   OccTax.tempStyle,
            "temporary": OccTax.tempStyle,
            "select" :   OccTax.tempStyle
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

        // Add config
        OccTax.config = occtaxClientConfig;

        // Initialize object
        OccTax.init();

        // Hide home button
        $('#mapmenu li.home').hide();

        // Show observation search
        $('#button-occtax').click();
        $('#button-taxon').parent('li.taxon').hide();

        // Change deconnect URL
        var deconnectUrl = $('a[href$="=/index.php/view/"]');
        if( deconnectUrl.length == 1 ){
            var duVal = deconnectUrl.attr('href');
            deconnectUrl.attr('href', duVal.replace('view', 'occtax'));
        }


    },

    // Adapt docks
    dockopened: function(e) {
    }
    ,
    dockclosed: function(e) {
        if ( e.id == 'occtax' ) {
            // Hide subdock with obs detail
            $('#sub-dock').hide();
        }
    }
    ,
    minidockopened: function(e) {
        if ( e.id == 'print' || e.id == 'tooltip' ) {
            // Deactivate Occtax layers controls
            // Needed because they prevent print drag control from working
            OccTax.controls.select.selectCtrl.deactivate();
            OccTax.controls.select.highlightCtrl.deactivate()
            OccTax.controls.select.selectObservationCtrl.deactivate()
        }
    },
    dockclosed: function(e) {
        if ( e.id == 'print' || e.id == 'tooltip' ) {
            // Activate Occtax controls
            OccTax.controls.select.selectCtrl.activate();
            OccTax.controls.select.highlightCtrl.activate()
            //OccTax.controls.select.selectObservationCtrl.activate();
        }
    }

});
