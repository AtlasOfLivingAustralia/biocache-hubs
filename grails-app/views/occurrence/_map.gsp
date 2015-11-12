<%@ page contentType="text/html;charset=UTF-8" %>
<style type="text/css">

#leafletMap {
    cursor: pointer;
    font-size: 12px;
    line-height: 18px;
}

#leafletMap, input {
    margin: 0px;
}

.leaflet-control-layers-base  {
    font-size: 12px;
}

.leaflet-control-layers-base label,  .leaflet-control-layers-base input, .leaflet-control-layers-base button, .leaflet-control-layers-base select, .leaflet-control-layers-base textarea {
    margin:0px;
    height:20px;
    font-size: 12px;
    line-height:18px;
    width:auto;
}

.leaflet-control-layers {
    opacity:0.8;
    filter:alpha(opacity=80);
}

.leaflet-control-layers-overlays label {
    font-size: 12px;
    line-height: 18px;
    margin-bottom: 0px;
}

.leaflet-drag-target {
    line-height:18px;
    font-size: 12px;
}

i.legendColour {
    -webkit-background-clip: border-box;
    -webkit-background-origin: padding-box;
    -webkit-background-size: auto;
    background-attachment: scroll;
    background-clip: border-box;
    background-image: none;
    background-origin: padding-box;
    background-size: auto;
    display: inline-block;
    height: 12px;
    line-height: 12px;
    width: 14px;
    margin-bottom: -5px;
    margin-left:2px;
    margin-right:2px;
    opacity:1;
    filter:alpha(opacity=100);
}

i#defaultLegendColour {
    margin-bottom: -2px;
    margin-left: 2px;
    margin-right: 5px;
}

.legendTable {
    padding: 0px;
    margin: 0px;
}

a.colour-by-legend-toggle {
    color: #000000;
    text-decoration: none;
    cursor: auto;
    display: block;
    font-family: 'Helvetica Neue', Arial, Helvetica, sans-serif;
    font-size: 14px;
    font-style: normal;
    font-variant: normal;
    font-weight: normal;
    line-height: 18px;
    text-decoration: none solid rgb(0, 120, 168);
    padding:6px 10px 6px 10px;
}

#mapLayerControls label {
    margin-bottom: 0;
}

/*#mapLayerControls input[type="checkbox"] {*/
    /*margin-top: 0;*/
/*}*/

.leaflet-bar-bg a,
.leaflet-bar-bg a:hover {
    width: 36px;
    height: 36px;
    line-height: 36px;
}

.leaflet-bar-bg .fa {
    line-height: 36px;
    opacity: 0.8;
}
#mapLayerControls {
    /*position: absolute;*/
    /*width: 80%;*/
    /*z-index: 1010;*/
    /*top: 0;*/
    /*left: 0;*/
    /*right: 0;*/
    height: 30px;
    /*margin: 10px auto;*/
    /*background: rgba(0,0,0,0.4);*/
    /* box-shadow: -2px 0 2px rgba(0,0,0,0.3); */
    /*box-shadow: 0 1px 5px rgba(0,0,0,0.4);*/
    /*-webkit-border-radius: 5px;*/
    /*-moz-border-radius: 5px;*/
    /*border-radius: 5px;*/
    color: #000;
    font-size: 13px;
}
#mapLayerControls .layerControls, #mapLayerControls #sizeslider {
    display: inline-block;
    float: none;
}
#mapLayerControls td {
    padding: 2px 5px 0px 5px;
}
#mapLayerControls label {
    padding-top: 4px;
}
#mapLayerControls .slider {
    margin-bottom: 4px;
}
#mapLayerControls select {
    color: #000;
    background: #EEEEEE;
    /*-moz-user-select: auto;*/
}
#mapLayerControls .layerControls {
    margin-top: 0;
}
#outlineDots {
    height: 20px;
}
#recordLayerControl {
    padding: 0 5px;
}

</style>

<div style="margin-bottom: 10px">
    <g:if test="${grailsApplication.config.skin.useAlaSpatialPortal?.toBoolean()}">
        <g:set var='spatialPortalLink' value="${sr.urlParameters}"/>
        <g:set var='spatialPortalUrlParams' value="${grailsApplication.config.spatial.params}"/>
        <div id="spatialPortalBtn" class="btn btn-small" style="margin-bottom: 2px;">
            <a id="spatialPortalLink" class="tooltips"
               href="${grailsApplication.config.spatial.baseUrl}${spatialPortalLink}${spatialPortalUrlParams}" title="Continue analysis in ALA Spatial Portal">
                <i class="fa fa-map-marker"></i>&nbsp&nbsp;<g:message code="map.spatialportal.btn.label" default="View in spatial portal"/></a>
        </div>
    </g:if>
    <div id="downloadMaps" class="btn btn-small" style="margin-bottom: 2px;">
        <a href="#downloadMap" role="button" data-toggle="modal" class="tooltips" title="Download image file (single colour mode)">
            <i class="fa fa-download"></i>&nbsp&nbsp;<g:message code="map.downloadmaps.btn.label" default="Download map"/></a>
    </div>
    <g:if test="${params.wkt}">
        <div id="downloadWKT" class="btn btn-small" style="margin-bottom: 2px;">
            <a href="#downloadWKT" role="button" class="tooltips" title="Download WKT file" onclick="downloadPolygon(); return false;">
                <i class="icon icon-stop"></i>&nbsp&nbsp;<g:message code="map.downloadwkt.btn.label" default="Download WKT"/></a>
        </div>
    </g:if>
    <%-- <div id="spatialSearchFromMap" class="btn btn-small">
        <a href="#" id="wktFromMapBounds" class="tooltips" title="Restrict search to current view">
            <i class="hide icon-share-alt"></i> Restrict search</a>
    </div>
    TODO - Needs hook in UI to detect a wkt param and include button/link under search query and selected facets.
    TODO - Also needs to check if wkt is already specified and remove previous wkt param from query.
    --%>
</div>

<div class="hide" id="recordLayerControls">
    <table id="mapLayerControls">
        <tr>
            <td>
                <label for="colourBySelect"><g:message code="map.maplayercontrols.tr01td01.label" default="Colour by"/>:&nbsp;</label>
                <div class="layerControls">
                    <select name="colourBySelect" id="colourBySelect" onchange="changeFacetColours();return true;">
                        <option value=""><g:message code="map.maplayercontrols.tr01td01.option01" default="Points - default colour"/></option>
                        <option value="grid" ${(defaultColourBy == 'grid')?'selected=\"selected\"':''}><g:message code="map.maplayercontrols.tr01td01.option02" default="Record density grid"/></option>
                        <option value="gridVariable" ${(defaultColourBy == 'gridVariable')?'selected=\"selected\"':''}><g:message code="map.maplayercontrols.tr01td01.option03" default="Grid (variable precision)"/></option>
                        <option disabled role="separator">————————————</option>
                        <g:each var="facetResult" in="${facets}">
                            <g:set var="Defaultselected">
                                <g:if test="${defaultColourBy && facetResult.fieldName == defaultColourBy}">selected="selected"</g:if>
                            </g:set>
                            %{--<g:if test="${facetResult.fieldName == 'occurrence_year'}">${facetResult.fieldName = 'decade'}</g:if>--}%
                            <g:if test="${facetResult.fieldName == 'uncertainty'}">${facetResult.fieldName = 'coordinate_uncertainty'}</g:if>
                            <g:if test="${facetResult.fieldResult.size() > 1}">
                                <option value="${facetResult.fieldName}" ${Defaultselected}>
                                    <alatag:formatDynamicFacetName fieldName="${facetResult.fieldName}"/>
                                </option>
                            </g:if>
                        </g:each>
                    </select>
                </div>
            </td>
            <td>
                <label for="sizeslider"><g:message code="map.maplayercontrols.tr01td02.label" default="Size"/>:</label>
                <div class="layerControls">
                    <span class="slider-val" id="sizeslider-val">4</span>
                </div>
                <div id="sizeslider" style="width:75px;"></div>
            </td>
            <td>
                <label for="opacityslider"><g:message code="map.maplayercontrols.tr01td03.label" default="Opacity"/>:</label>
                <div class="layerControls">
                    <span class="slider-val" id="opacityslider-val">0.8</span>
                </div>
                <div id="opacityslider" style="width:75px;"></div>
            </td>
            <td>
                <label for="outlineDots"><g:message code="map.maplayercontrols.tr01td04.label" default="Outline"/>:</label>
                <input type="checkbox" name="outlineDots" checked="checked" value="true" class="layerControls" id="outlineDots">
            </td>
        </tr>
    </table>
</div>

<div id="leafletMap" class="span12" style="height:600px;"></div>

<div id="template" style="display:none">
    <div class="colourbyTemplate">
        <a class="colour-by-legend-toggle colour-by-control tooltips" href="#" title="Map legend - click to expand"><i class="fa fa-list-ul fa-lg"></i></a>
        <form class="leaflet-control-layers-list">
            <div class="leaflet-control-layers-overlays">
                <div style="overflow:auto; max-height:400px;">
                    <a href="#" class="hideColourControl pull-right" style="padding-left:10px;"><i class="icon-remove icon-grey"></i></a>
                    <table class="legendTable"></table>
                </div>
            </div>
        </form>
    </div>
</div>


<div id="recordPopup" style="display:none;">
    <a href="#"><g:message code="map.recordpopup" default="View records at this point"/></a>
</div>


<r:script>

    //var mbAttr = 'Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>, imagery &copy; <a href="http://cartodb.com/attributions">CartoDB</a>';
	//var mbUrl = 'http://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
    var defaultBaseLayer = L.tileLayer("${grailsApplication.config.map.minimal.url}", {
            attribution: "${raw(grailsApplication.config.map.minimal.attr)}",
            subdomains: "${grailsApplication.config.map.minimal.subdomains}",
            mapid: "${grailsApplication.config.map.mapbox?.id?:''}",
            token: "${grailsApplication.config.map.mapbox?.token?:''}"
        });

    var MAP_VAR = {
        map : null,
        mappingUrl : "${mappingUrl}",
        query : "${searchString}",
        queryDisplayString : "${queryDisplayString}",
        center: [-23.6,133.6],
        defaultLatitude : "${grailsApplication.config.map.defaultLatitude?:'-23.6'}",
        defaultLongitude : "${grailsApplication.config.map.defaultLongitude?:'133.6'}",
        defaultZoom : "${grailsApplication.config.map.defaultZoom?:'4'}",
        overlays : {

            <g:if test="${grailsApplication.config.map.overlay.url}">
                //example WMS layer
                "${grailsApplication.config.map.overlay.name?:'overlay'}" : L.tileLayer.wms("${grailsApplication.config.map.overlay.url}", {
                    layers: 'ALA:ucstodas',
                    format: 'image/png',
                    transparent: true,
                    attribution: "${grailsApplication.config.map.overlay.name?:'overlay'}"
                })
            </g:if>

        },
        baseLayers : {
            "Minimal" : defaultBaseLayer,
            "Road" :  new L.Google('ROADMAP'),
            "Terrain" : new L.Google('TERRAIN'),
            "Satellite" : new L.Google('HYBRID')
        },
        layerControl : null,
        currentLayers : [],
        additionalFqs : '',
        zoomOutsideScopedRegion: ${(grailsApplication.config.map.zoomOutsideScopedRegion == false || grailsApplication.config.map.zoomOutsideScopedRegion == "false") ? false : true},
        removeFqs: ''
    };

    var ColourByControl = L.Control.extend({
        options: {
            position: 'topright',
            collapsed: false
        },
        onAdd: function (map) {
            // create the control container with a particular class name
            var $controlToAdd = $('.colourbyTemplate').clone();
            var container = L.DomUtil.create('div', 'leaflet-control-layers');
            var $container = $(container);
            $container.attr("id","colourByControl");
            $container.attr('aria-haspopup', true);
            $container.html($controlToAdd.html());
            return container;
        }
    });

    var RecordLayerControl = L.Control.extend({
        options: {
            position: 'topright',
            collapsed: false
        },
        onAdd: function (map) {
            // create the control container with a particular class name
            var container = L.DomUtil.create('div', 'leaflet-control-layers');
            var $container = $(container);
            $container.attr("id","recordLayerControl");
            $('#mapLayerControls').prependTo($container);
            // Fix for Firefox select bug
            var stop = L.DomEvent.stopPropagation;
            L.DomEvent
                .on(container, 'click', stop)
                .on(container, 'mousedown', stop);
            return container;
        }
    });

    function initialiseMap(){
        //console.log("initialiseMap", MAP_VAR.map);
        if(MAP_VAR.map != null){
            return;
        }

        //initialise map
        MAP_VAR.map = L.map('leafletMap', {
            center: [MAP_VAR.defaultLatitude, MAP_VAR.defaultLongitude],
            zoom: MAP_VAR.defaultZoom,
            minZoom: 1,
            scrollWheelZoom: false,
            fullscreenControl: true,
            fullscreenControlOptions: {
                position: 'topleft'
            }
        });

        //add edit drawing toolbar
        // Initialise the FeatureGroup to store editable layers
        MAP_VAR.drawnItems = new L.FeatureGroup();
        MAP_VAR.map.addLayer(MAP_VAR.drawnItems);

        // Initialise the draw control and pass it the FeatureGroup of editable layers
        MAP_VAR.drawControl = new L.Control.Draw({
            edit: {
                featureGroup: MAP_VAR.drawnItems
            },
            draw: {
                polyline: false,
                rectangle: {
                    shapeOptions: {
                        color: '#bada55'
                    }
                },
                circle: {
                    shapeOptions: {
                        color: '#bada55'
                    }
                },
                marker: false,
                polygon: {
                    allowIntersection: false, // Restricts shapes to simple polygons
                    drawError: {
                        color: '#e1e100', // Color the shape will turn when intersects
                        message: '<strong>Oh snap!<strong> you can\'t draw that!' // Message that will show when intersect
                    },
                    shapeOptions: {
                        color: '#bada55'
                    }
                }
            }
        });
        MAP_VAR.map.addControl(MAP_VAR.drawControl);

        MAP_VAR.map.on('draw:created', function(e) {
            //setup onclick event for this object
            var layer = e.layer;
            generatePopup(layer, layer._latlng);
            addClickEventForVector(layer);
            MAP_VAR.drawnItems.addLayer(layer);
        });

        //add the default base layer
        MAP_VAR.map.addLayer(defaultBaseLayer);

        L.control.coordinates({position:"bottomright", useLatLngOrder: true}).addTo(MAP_VAR.map); // coordinate plugin

        MAP_VAR.layerControl = L.control.layers(MAP_VAR.baseLayers, MAP_VAR.overlays, {collapsed:true, position:'topleft'});
        MAP_VAR.layerControl.addTo(MAP_VAR.map);

        addQueryLayer(true);

        MAP_VAR.map.addControl(new RecordLayerControl());
        MAP_VAR.map.addControl(new ColourByControl());

        L.Util.requestAnimFrame(MAP_VAR.map.invalidateSize, MAP_VAR.map, !1, MAP_VAR.map._container);
        L.Browser.any3d = false; // FF bug prevents selects working properly

        $('.colour-by-control').click(function(e){

            if($(this).parent().hasClass('leaflet-control-layers-expanded')){
                $(this).parent().removeClass('leaflet-control-layers-expanded');
                $('.colour-by-legend-toggle').show();
            } else {
                $(this).parent().addClass('leaflet-control-layers-expanded');
                $('.colour-by-legend-toggle').hide();
            }
            e.preventDefault();
            e.stopPropagation();
            return false;
        });

        $('#colourByControl,#recordLayerControl').mouseover(function(e){
            //console.log('mouseover');
            MAP_VAR.map.dragging.disable();
            MAP_VAR.map.off('click', pointLookupClickRegister);
        });

        $('#colourByControl,#recordLayerControl').mouseout(function(e){
            //console.log('mouseout');
            MAP_VAR.map.dragging.enable();
            MAP_VAR.map.on('click', pointLookupClickRegister);
        });

        $('.hideColourControl').click(function(e){
            //console.log('hideColourControl');
            $('#colourByControl').removeClass('leaflet-control-layers-expanded');
            $('.colour-by-legend-toggle').show();
            e.preventDefault();
            e.stopPropagation();
            return false;
        });

        $( "#sizeslider" ).slider({
            min:1,
            max:6,
            value: Number($('#sizeslider-val').text()),
            tooltip: 'hide'
        }).on('slideStop', function(ev){
            $('#sizeslider-val').html(ev.value);
            addQueryLayer(true);
        });

        $( "#opacityslider" ).slider({
            min: 0.1,
            max: 1.0,
            step: 0.1,
            value: Number($('#opacityslider-val').text()),
            tooltip: 'hide'
        }).on('slideStop', function(ev){
            var value = parseFloat(ev.value).toFixed(1); // prevent values like 0.30000000004 appearing
            $('#opacityslider-val').html(value);
            if (MAP_VAR.currentLayers.length == 1) {
                MAP_VAR.currentLayers[0].setOpacity(value);
            } else {
                addQueryLayer(true);
            }
        });

        $('#outlineDots').click(function(e) {
            addQueryLayer(true);
        });

        fitMapToBounds(); // zoom map if points are contained within Australia
        //drawCircleRadius(); // draw circle around lat/lon/radius searches

        // display vector from previous wkt search
        var wktFromParams = "${params.wkt}";
        if (wktFromParams) {
            var wkt = new Wkt.Wkt();
            wkt.read(wktFromParams);
            var wktObject = wkt.toObject({color: '#bada55'});
            //addClickEventForVector(wktObject); // can't click on points if this is set
            //wktObject.editing.enable();
            wktObject.on('click', pointLookupClickRegister);
            MAP_VAR.drawnItems.addLayer(wktObject);

        } else if (isSpatialRadiusSearch()) {
            // draw circle onto map
            var circle = L.circle([$.url().param('lat'), $.url().param('lon')], ($.url().param('radius') * 1000), {color: '#bada55'});
            //console.log("circle", circle);
            //addClickEventForVector(circle);  // can't click on points if this is set
            circle.on('click', pointLookupClickRegister);
            MAP_VAR.drawnItems.addLayer(circle);
        }

        MAP_VAR.map.on('draw:edited', function(e) {
            //setup onclick event for this object
            var layers = e.layers;
            layers.eachLayer(function (layer) {
                generatePopup(layer, layer._latlng);
                addClickEventForVector(layer);
            });
        });

        MAP_VAR.recordList = new Array(); // store list of records for popup

        MAP_VAR.map.on('click', pointLookupClickRegister);
    }

    var clickCount = 0;

    /**
    * Fudge to allow double clicks to propagate to map while allowing single clicks to be registered
    *
    */
    function pointLookupClickRegister(e) {
        //console.log('pointLookupClickRegister', clickCount);
        clickCount += 1;
        if (clickCount <= 1) {
            setTimeout(function() {
                if (clickCount <= 1) {
                    pointLookup(e);
                }
                clickCount = 0;
            }, 400);
        }
    }

    function changeFacetColours() {
        MAP_VAR.additionalFqs = '';
        // clear this variable every time a new colour by is chosen.
        MAP_VAR.removeFqs = ''
        //e.preventDefault();
        //e.stopPropagation();
        addQueryLayer(true);
        return true;
    }

    function showHideControls(el) {
        //console.log("el", el, this);
        var $this = this;
        if ($($this).hasClass('fa')) {
            alert("activating");
            $($this).hide();
            $($this + ' table.controls').show();
        } else {
            alert("deactivating");
            $($this).show();
            $($this + ' table.controls').hide();
        }
    }

    /**
     * A tile layer to map colouring the dots by the selected colour.
     */
    function addQueryLayer(redraw){

        $.each(MAP_VAR.currentLayers, function(index, value){
            MAP_VAR.map.removeLayer(MAP_VAR.currentLayers[index]);
            MAP_VAR.layerControl.removeLayer(MAP_VAR.currentLayers[index]);
        });

        MAP_VAR.currentLayers = [];

        var colourByFacet = $('#colourBySelect').val();
        var pointSize = $('#sizeslider-val').html();
        var opacity = $('#opacityslider-val').html();
        var outlineDots = $('#outlineDots').is(':checked');

        var envProperty = "color:${grailsApplication.config.map.pointColour};name:circle;size:"+pointSize+";opacity:"+opacity

        if(colourByFacet){
            if(colourByFacet == "gridVariable"){
                colourByFacet = "coordinate_uncertainty"
                envProperty = "colormode:coordinate_uncertainty;name:circle;size:"+pointSize+";opacity:1;cellfill:0xffccff;variablegrids:on"
            } else {
                envProperty = "colormode:" + colourByFacet + ";name:circle;size:"+pointSize+";opacity:1;"
            }
        }

        var gridSizeMap = {
            1: 256, 2:128, 3: 64, 4:32, 5:16, 6:8
        }

        var layer = L.tileLayer.wms(MAP_VAR.mappingUrl + "/mapping/wms/reflect" + MAP_VAR.query + MAP_VAR.additionalFqs, {
            layers: 'ALA:occurrences',
            format: 'image/png',
            transparent: true,
            bgcolor:"0x000000",
            outline:outlineDots,
            ENV: envProperty,
            opacity: opacity,
            GRIDDETAIL: gridSizeMap[pointSize],
            STYLE: "opacity:"+opacity // for grid data
        });

        if(redraw){
             if(!colourByFacet){
                $('.legendTable').html('');
                addDefaultLegendItem("${grailsApplication.config.map.pointColour}");
             } else if (colourByFacet == 'grid') {
                 $('.legendTable').html('');
                 addGridLegendItem();
             } else {
                //update the legend
                $('.legendTable').html('<tr><td>Loading legend....</td></tr>');
                $.ajax({
                    url: "${request.contextPath}/occurrence/legend" + MAP_VAR.query + "&cm=" + colourByFacet + "&type=application/json",
                    success: function(data) {
                        $('.legendTable').html('');

                        $.each(data, function(index, legendDef){
                            var legItemName = legendDef.name ? legendDef.name : 'Not specified';
                            addLegendItem(legItemName, legendDef.red,legendDef.green,legendDef.blue, legendDef );
                        });

                        $('.layerFacet').click(function(e){
                            var controlIdx = 0;
                            MAP_VAR.additionalFqs = '';
                            MAP_VAR.removeFqs = ''
                            $('#colourByControl').find('.layerFacet').each(function(idx, layerInput){
                                var $input = $(layerInput), fq;
                                var include =  $input.is(':checked');

                                if(!include){
                                    MAP_VAR.additionalFqs = MAP_VAR.additionalFqs + '&HQ=' + controlIdx;
                                    fq = $input.attr('fq');
                                    // logic for facets with missing value is different from those with value
                                    if(fq && fq.startsWith('-')){
                                        // to ignore unknown or missing values, minus sign must be removed
                                         fq = fq.replace('-','');
                                    } else{
                                        // for all other values minus sign has to be added
                                        fq = '-' + fq;
                                    }

                                    // add fq to ensure the query in sync with dots displayed on map
                                    MAP_VAR.removeFqs += '&fq=' + fq;
                                }
                                controlIdx = controlIdx + 1;
                                addQueryLayer(false);
                            });
                        });
                    }
                });
            }
        }
        MAP_VAR.layerControl.addOverlay(layer, 'Occurrences');
        MAP_VAR.map.addLayer(layer);
        MAP_VAR.currentLayers.push(layer);
        return true;
    }

    function addDefaultLegendItem(pointColour){
        $(".legendTable")
            .append($('<tr>')
                .append($('<td>')
                    .append($('<i>')
                        .addClass('legendColour')
                        .attr('style', "background-color:#"+ pointColour + ";")
                        .attr('id', 'defaultLegendColour')
                    )
                    .append($('<span>')
                        .addClass('legendItemName')
                        .html("All records")
                    )
                )
        );
    }

    function addGridLegendItem(){
        $(".legendTable")
            .append($('<tr>')
                .append($('<td>')
                    .append($('<img id="gridLegendImg" src="' + MAP_VAR.mappingUrl + '/density/legend' + MAP_VAR.query + '"/>'))
                )
        );
    }

    function addLegendItem(name, red, green, blue, data){
        var nameLabel = jQuery.i18n.prop(name);
        var isoDateRegEx = /^(\d{4})-\d{2}-\d{2}T.*/; // e.g. 2001-02-31T12:00:00Z with year capture
        if (name.search(isoDateRegEx) > -1) {
            // convert full ISO date to YYYY-MM-DD format
            name = name.replace(isoDateRegEx, "$1");
        }
        $(".legendTable")
            .append($('<tr>')
                .append($('<td>')
                    .append($('<input>')
                        .attr('type', 'checkbox')
                        .attr('checked', 'checked')
                        .attr('id', name)
                        .attr('fq',data.fq)
                        .addClass('layerFacet')
                        .addClass('leaflet-control-layers-selector')
                    )
                )
                .append($('<td>')
                    .append($('<i>')
                        .addClass('legendColour')
                        .attr('style', "background-color:rgb("+ red +","+ green +","+ blue + ");")
                    )
                    .append($('<span>')
                        .addClass('legendItemName')
                        .html((nameLabel.indexOf("[") == -1) ? nameLabel : name)
                    )
                )
        );
    }

    function rgbToHex(redD, greenD, blueD){
        var red = parseInt(redD);
        var green = parseInt(greenD);
        var blue = parseInt(blueD);

        var rgb = blue | (green << 8) | (red << 16);
        return rgb.toString(16);
    }

    /**
     * Event handler for point lookup.
     * @param e
     */
    function pointLookup(e) {

        MAP_VAR.popup = L.popup().setLatLng(e.latlng);
        var radius = 0;
        var size = $('sizeslider-val').html();
        var zoomLevel = MAP_VAR.map.getZoom();
        switch (zoomLevel){
            case 0:
                radius = 800;
                break;
            case 1:
                radius = 400;
                break;
            case 2:
                radius = 200;
                break;
            case 3:
                radius = 100;
                break;
            case 4:
                radius = 50;
                break;
            case 5:
                radius = 25;
                break;
            case 6:
                radius = 20;
                break;
            case 7:
                radius = 7.5;
                break;
            case 8:
                radius = 3;
                break;
            case 9:
                radius = 1.5;
                break;
            case 10:
                radius = .75;
                break;
            case 11:
                radius = .25;
                break;
            case 12:
                radius = .15;
                break;
            case 13:
                radius = .1;
                break;
            case 14:
                radius = .05;
                break;
            case 15:
                radius = .025;
                break;
            case 16:
                radius = .015;
                break;
            case 17:
                radius = 0.0075;
                break;
            case 18:
                radius = 0.004;
                break;
            case 19:
                radius = 0.002;
                break;
            case 20:
                radius = 0.001;
                break;
        }

        if (size >= 5 && size < 8){
            radius = radius * 2;
        }
        if (size >= 8){
            radius = radius * 3;
        }

        MAP_VAR.popupRadius = radius;
        var mapQuery = MAP_VAR.query.replace(/&(?:lat|lon|radius)\=[\-\.0-9]+/g, ''); // remove existing lat/lon/radius/wkt params
        MAP_VAR.map.spin(true);

        $.ajax({
            url: MAP_VAR.mappingUrl + "/occurrences/info" + mapQuery + MAP_VAR.removeFqs,
            jsonp: "callback",
            dataType: "jsonp",
            data: {
                zoom: MAP_VAR.map.getZoom(),
                lat: e.latlng.lat,
                lon: e.latlng.lng,
                radius: radius,
                format: "json"
            },
            success: function(response) {
                MAP_VAR.map.spin(false);

                if (response.occurrences && response.occurrences.length > 0) {

                    MAP_VAR.recordList = response.occurrences; // store the list of record uuids
                    MAP_VAR.popupLatlng = e.latlng; // store the coordinates of the mouse click for the popup

                    // Load the first record details into popup
                    insertRecordInfo(0);
                }
            },
            error: function() {
                MAP_VAR.map.spin(false);
            }
        });
    }

    /**
    * Populate the map popup with record details
    *
    * @param recordIndex
    */
    function insertRecordInfo(recordIndex) {
        //console.log("insertRecordInfo", recordIndex, MAP_VAR.recordList);
        var recordUuid = MAP_VAR.recordList[recordIndex];
        var $popupClone = $('.popupRecordTemplate').clone();
        MAP_VAR.map.spin(true);

        if (MAP_VAR.recordList.length > 1) {
            // populate popup header
            $popupClone.find('.multiRecordHeader').show();
            $popupClone.find('.currentRecord').html(recordIndex + 1);
            $popupClone.find('.totalrecords').html(MAP_VAR.recordList.length.toString().replace(/100/, '100+'));
            var occLookup = "&radius=" + MAP_VAR.popupRadius + "&lat=" + MAP_VAR.popupLatlng.lat + "&lon=" + MAP_VAR.popupLatlng.lng;
            $popupClone.find('a.viewAllRecords').attr('href', "${request.contextPath}/occurrences/search" + MAP_VAR.query.replace(/&(?:lat|lon|radius)\=[\-\.0-9]+/g, '') + occLookup);
            // populate popup footer
            $popupClone.find('.multiRecordFooter').show();
            if (recordIndex < MAP_VAR.recordList.length - 1) {
                $popupClone.find('.nextRecord a').attr('onClick', 'insertRecordInfo('+(recordIndex + 1)+'); return false;');
                $popupClone.find('.nextRecord a').removeClass('disabled');
            }
            if (recordIndex > 0) {
                $popupClone.find('.previousRecord a').attr('onClick', 'insertRecordInfo('+(recordIndex - 1)+'); return false;');
                $popupClone.find('.previousRecord a').removeClass('disabled');
            }
        }

        $popupClone.find('.recordLink a').attr('href', "${request.contextPath}/occurrences/" + recordUuid);

        // Get the current record details
        $.ajax({
            url: MAP_VAR.mappingUrl + "/occurrences/" + recordUuid + ".json",
            jsonp: "callback",
            dataType: "jsonp",
            success: function(record) {
                MAP_VAR.map.spin(false);

                if (record.raw) {
                    var displayHtml = "";

                    // catalogNumber
                    if(record.raw.occurrence.catalogNumber != null){
                        displayHtml += "${g.message(code:'record.catalogNumber.label', default: 'Catalogue number')}: " + record.raw.occurrence.catalogNumber + '<br />';
                    } else if(record.processed.occurrence.catalogNumber != null){
                        displayHtml += "${g.message(code:'record.catalogNumber.label', default: 'Catalogue number')}: " + record.processed.occurrence.catalogNumber + '<br />';
                    }

                    if(record.raw.classification.vernacularName!=null ){
                        displayHtml += record.raw.classification.vernacularName + '<br />';
                    } else if(record.processed.classification.vernacularName!=null){
                        displayHtml += record.processed.classification.vernacularName + '<br />';
                    }

                    if (record.processed.classification.scientificName) {
                        displayHtml += formatSciName(record.processed.classification.scientificName, record.processed.classification.taxonRankID)  + '<br />';
                    } else {
                        displayHtml += record.raw.classification.scientificName  + '<br />';
                    }

                    if(record.processed.attribution.institutionName != null){
                        displayHtml += "${g.message(code:'record.institutionName.label', default: 'Institution')}: " + record.processed.attribution.institutionName + '<br />';
                    } else if(record.processed.attribution.dataResourceName != null){
                        displayHtml += "${g.message(code:'record.dataResourceName.label', default: 'Data Resource')}: " + record.processed.attribution.dataResourceName + '<br />';
                    }

                    if(record.processed.attribution.collectionName != null){
                        displayHtml += "${g.message(code:'record.collectionName.label', default: 'Collection')}: " + record.processed.attribution.collectionName  + '<br />';
                    }

                    if(record.raw.occurrence.recordedBy != null){
                        displayHtml += "${g.message(code:'record.recordedBy.label', default: 'Collector')}: " + record.raw.occurrence.recordedBy + '<br />';
                    } else if(record.processed.occurrence.recordedBy != null){
                        displayHtml += "${g.message(code:'record.recordedBy.label', default: 'Collector')}: " + record.processed.occurrence.recordedBy + '<br />';
                    }

                    if(record.processed.event.eventDate != null){
                        //displayHtml += "<br/>";
                        var label = "${g.message(code:'record.eventDate.label', default: 'Event date')}: ";
                        displayHtml += label + record.processed.event.eventDate;
                    }

                    $popupClone.find('.recordSummary').html( displayHtml ); // insert into clone
                } else {
                    // missing record - disable "view record" button and display message
                    $popupClone.find('.recordLink a').attr('disabled', true).attr('href','javascript: void(0)');
                    $popupClone.find('.recordSummary').html( "<br><g:message code="search.recordNotFoundForId" default="Error: record not found for ID:"/>: <span style='white-space:nowrap;'>" + recordUuid + '</span><br><br>' ); // insert into clone
                }

                MAP_VAR.popup.setContent($popupClone.html()); // push HTML into popup content
                MAP_VAR.popup.openOn(MAP_VAR.map);
            },
            error: function() {
                MAP_VAR.map.spin(false);
            }
        });

    }

    function getRecordInfo(){
        // http://biocache.ala.org.au/ws/occurrences/c00c2f6a-3ae8-4e82-ade4-fc0220529032
        //console.log("MAP_VAR.query", MAP_VAR.query);
        $.ajax({
            url: "${alatag.getBiocacheAjaxUrl()}/occurrences/info" + MAP_VAR.query,
            jsonp: "callback",
            dataType: "jsonp",
            success: function(response) {
            }
        });
    }

    /**
     * Format the display of a scientific name.
     * E.g. genus and below should be italicised
     */
    function formatSciName(name, rankId) {
        var output = "";
        if (rankId && rankId >= 6000) {
            output = "<i>" + name + "</i>";
        } else {
            output = name;
        }
        return output;
    }

    /**
     * Zooms map to either spatial search or from WMS data bounds
     */
    function fitMapToBounds() {
        // Don't run for spatial searches, which have their own fitBounds() method
        if (true || !isSpatialRadiusSearch()) { // inactive if
            // all other searches (non-spatial)
            // do webservice call to get max extent of WMS data
            var jsonUrl = "${alatag.getBiocacheAjaxUrl()}/mapping/bounds.json" + MAP_VAR.query + "&callback=?";
            $.getJSON(jsonUrl, function(data) {
                if (data.length == 4) {
                    //console.log("data", data);
                    var sw = L.latLng(data[1],data[0]);
                    var ne = L.latLng(data[3],data[2]);
                    //console.log("sw", sw.toString());
                    var dataBounds = L.latLngBounds(sw, ne);
                    //var centre = dataBounds.getCenter();
                    var mapBounds = MAP_VAR.map.getBounds();

                    if (mapBounds && mapBounds.contains(sw) && mapBounds.contains(ne) && dataBounds) {
                        // data bounds is smaller than all of Aust
                        //console.log("smaller bounds",dataBounds,mapBounds)
                        MAP_VAR.map.fitBounds(dataBounds);

                        if (MAP_VAR.map.getZoom() > 15) {
                            MAP_VAR.map.setZoom(15);
                        }
                    } else if (MAP_VAR.zoomOutsideScopedRegion) {
                        // fitBounds is async so we set a one time only listener to detect change
                        MAP_VAR.map.once('zoomend', function() {
                            //console.log("zoomend", MAP_VAR.map.getZoom());
                            if (MAP_VAR.map.getZoom() < 2) {
                                MAP_VAR.map.setView(L.latLng(0, 24), 2); // zoom level 2 and centered over africa
                            }
                        });
                        MAP_VAR.map.fitBounds(dataBounds);
                    }
                    MAP_VAR.map.invalidateSize();
                }
            });
        }
    }

    /**
     * Spatial searches from Explore Your Area - draw a circle representing
     * the radius boundary for the search.
     *
     * Note: this function has a dependency on purl.js:
     * https://github.com/allmarkedup/purl
     */
    function drawCircleRadius() {
        if (isSpatialRadiusSearch()) {
            // spatial search from EYA
            var lat = $.url().param('lat');
            var lng = $.url().param('lon');
            var radius = $.url().param('radius');
            var latLng = L.latLng(lat, lng);
            var circleOpts = {
                weight: 1,
                color: 'white',
                opacity: 0.5,
                fillColor: '#222', // '#2C48A6'
                fillOpacity: 0.2
            }

            L.Icon.Default.imagePath = "${request.contextPath}/static/js/leaflet-0.7.2/images";
            var popupText = "Centre of spatial search with radius of " + radius + " km";
            var circle = L.circle(latLng, radius * 1030, circleOpts);
            circle.addTo(MAP_VAR.map);
            MAP_VAR.map.fitBounds(circle.getBounds()); // make circle the centre of the map, not the points
            L.marker(latLng, {title: popupText}).bindPopup(popupText).addTo(MAP_VAR.map);
            MAP_VAR.map.invalidateSize();
        }
    }

    /**
     * Returns true for a lat/lon/radius (params) style search
     *
     * @returns {boolean}
     */
    function isSpatialRadiusSearch() {
        var returnBool = false;
        var lat = $.url().param('lat');
        var lng = $.url().param('lon');
        var radius = $.url().param('radius');

        if (lat && lng && radius) {
            returnBool = true;
        }

        return returnBool
    }

    /**
     * http://stackoverflow.com/questions/3916191/download-data-url-file
     */
    function downloadPolygon() {
      var uri = "data:text/html,${params.wkt}",
          name = "polygon.txt";
      var link = document.createElement("a");
      link.download = name;
      link.href = uri;
      link.click();
      return false;
    }

</r:script>
<div class="hide">
    <div class="popupRecordTemplate">
        <div class="multiRecordHeader hide">
            <g:message code="search.map.viewing" default="Viewing"/> <span class="currentRecord"></span> <g:message code="search.map.of" default="of"/>
            <span class="totalrecords"></span> <g:message code="search.map.occurrences" default="occurrence records"/>
            &nbsp;&nbsp;<i class="icon-share-alt"></i> <a href="#" class="btn+btn-mini viewAllRecords"><g:message code="search.map.viewAllRecords" default="view all records"/></a>
        </div>
        <div class="recordSummary">

        </div>
        <div class="hide multiRecordFooter">
            <span class="previousRecord "><a href="#" class="btn btn-mini disabled" onClick="return false;"><g:message code="search.map.popup.prev" default="&lt; Prev"/></a></span>
            <span class="nextRecord "><a href="#" class="btn btn-mini disabled" onClick="return false;"><g:message code="search.map.popup.next" default="Next &gt;"/></a></span>
        </div>
        <div class="recordLink">
            <a href="#" class="btn btn-mini"><g:message code="search.map.popup.viewRecord" default="View record"/></a>
        </div>
    </div>
</div>

<div id="downloadMap" class="modal hide" tabindex="-1" role="dialog" aria-labelledby="downloadsMapLabel" aria-hidden="true">

    <form id="downloadMapForm">
        <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
            <h3 id="downloadsMapLabel"><g:message code="map.downloadmap.title" default="Download publication map"/></h3>
        </div>
        <div class="modal-body">
            <input id="mapDownloadUrl" type="hidden" value="${alatag.getBiocacheAjaxUrl()}/webportal/wms/image"/>
            <fieldset>
                <p><label for="format"><g:message code="map.downloadmap.field01.label" default="Format"/></label>
                    <select name="format" id="format">
                        <option value="jpg"><g:message code="map.downloadmap.field01.option01" default="JPEG"/></option>
                        <option value="png"><g:message code="map.downloadmap.field01.option02" default="PNG"/></option>
                    </select>
                </p>
                <p>
                    <label for="dpi"><g:message code="map.downloadmap.field02.label" default="Quality (DPI)"/></label>
                    <select name="dpi" id="dpi">
                        <option value="100">100</option>
                        <option value="300" selected="true">300</option>
                        <option value="600">600</option>
                    </select>
                </p>
                <p>
                    <label for="pradiusmm"><g:message code="map.downloadmap.field03.label" default="Point radius (mm)"/></label>
                    <select name="pradiusmm" id="pradiusmm">
                        <option>0.1</option>
                        <option>0.2</option>
                        <option>0.3</option>
                        <option>0.4</option>
                        <option>0.5</option>
                        <option>0.6</option>
                        <option selected="true">0.7</option>
                        <option>0.8</option>
                        <option>0.9</option>
                        <option>1</option>
                        <option>2</option>
                        <option>3</option>
                        <option>4</option>
                        <option>5</option>
                        <option>6</option>
                        <option>7</option>
                        <option>8</option>
                        <option>9</option>
                        <option>10</option>
                    </select>
                </p>
                <p>
                    <label for="popacity"><g:message code="map.downloadmap.field04.label" default="Opacity"/></label>
                    <select name="popacity" id="popacity">
                        <option>1</option>
                        <option>0.9</option>
                        <option>0.8</option>
                        <option selected="true">0.7</option>
                        <option>0.6</option>
                        <option>0.5</option>
                        <option>0.4</option>
                        <option>0.3</option>
                        <option>0.2</option>
                        <option>0.1</option>
                    </select>
                </p>
                <p id="colourPickerWrapper">
                    <label for="pcolour"><g:message code="map.downloadmap.field05.label" default="Color"/></label>
                    <select name="pcolour" id="pcolour">
                        <option value="ffffff">#ffffff</option>
                        <option value="ffccc9">#ffccc9</option>
                        <option value="ffce93">#ffce93</option>
                        <option value="fffc9e">#fffc9e</option>
                        <option value="ffffc7">#ffffc7</option>
                        <option value="9aff99">#9aff99</option>
                        <option value="96fffb">#96fffb</option>
                        <option value="cdffff">#cdffff</option>
                        <option value="cbcefb">#cbcefb</option>
                        <option value="cfcfcf">#cfcfcf</option>
                        <option value="fd6864">#fd6864</option>
                        <option value="fe996b">#fe996b</option>
                        <option value="fffe65">#fffe65</option>
                        <option value="fcff2f">#fcff2f</option>
                        <option value="67fd9a">#67fd9a</option>
                        <option value="38fff8">#38fff8</option>
                        <option value="68fdff">#68fdff</option>
                        <option value="9698ed">#9698ed</option>
                        <option value="c0c0c0">#c0c0c0</option>
                        <option value="fe0000">#fe0000</option>
                        <option value="f8a102">#f8a102</option>
                        <option value="ffcc67">#ffcc67</option>
                        <option value="f8ff00">#f8ff00</option>
                        <option value="34ff34">#34ff34</option>
                        <option value="68cbd0">#68cbd0</option>
                        <option value="34cdf9">#34cdf9</option>
                        <option value="6665cd">#6665cd</option>
                        <option value="9b9b9b">#9b9b9b</option>
                        <option value="cb0000">#cb0000</option>
                        <option value="f56b00">#f56b00</option>
                        <option value="ffcb2f">#ffcb2f</option>
                        <option value="ffc702">#ffc702</option>
                        <option value="32cb00">#32cb00</option>
                        <option value="00d2cb">#00d2cb</option>
                        <option value="3166ff">#3166ff</option>
                        <option value="6434fc">#6434fc</option>
                        <option value="656565">#656565</option>
                        <option value="9a0000">#9a0000</option>
                        <option value="ce6301">#ce6301</option>
                        <option value="cd9934">#cd9934</option>
                        <option value="999903">#999903</option>
                        <option value="009901">#009901</option>
                        <option value="329a9d">#329a9d</option>
                        <option value="3531ff" selected="selected">#3531ff</option>
                        <option value="6200c9">#6200c9</option>
                        <option value="343434">#343434</option>
                        <option value="680100">#680100</option>
                        <option value="963400">#963400</option>
                        <option value="986536">#986536</option>
                        <option value="646809">#646809</option>
                        <option value="036400">#036400</option>
                        <option value="34696d">#34696d</option>
                        <option value="00009b">#00009b</option>
                        <option value="303498">#303498</option>
                        <option value="000000">#000000</option>
                        <option value="330001">#330001</option>
                        <option value="643403">#643403</option>
                        <option value="663234">#663234</option>
                        <option value="343300">#343300</option>
                        <option value="013300">#013300</option>
                        <option value="003532">#003532</option>
                        <option value="010066">#010066</option>
                        <option value="340096">#340096</option>
                    </select>
                </p>
                <p>
                    <label for="widthmm"><g:message code="map.downloadmap.field06.label" default="Width (mm)"/></label>
                    <input type="text" name="widthmm" id="widthmm" value="150" />
                </p>
                <p>
                    <label for="scale_on"><g:message code="map.downloadmap.field07.label" default="Include scale"/></label>
                    <input type="radio" name="scale" value="on" id="scale_on" checked="checked"/> <g:message code="map.downloadmap.field07.option01" default="Yes"/> &nbsp;
                    <input type="radio" name="scale" value="off" /> <g:message code="map.downloadmap.field07.option02" default="No"/>
                </p>
                <p>
                    <label for="outline"><g:message code="map.downloadmap.field08.label" default="Outline points"/></label>
                    <input type="radio" name="outline" value="true" id="outline" checked="checked"/> <g:message code="map.downloadmap.field08.option01" default="Yes"/> &nbsp;
                    <input type="radio" name="outline" value="false" /> <g:message code="map.downloadmap.field08.option02" default="No"/>
                </p>
                <p>
                    <label for="baselayer"><g:message code="map.downloadmap.field09.label" default="Base layer"/></label>
                    <select name="baselayer" id="baselayer">
                        <option value="world"><g:message code="map.downloadmap.field09.option01" default="World outline"/></option>
                        <option value="aus1" selected="true"><g:message code="map.downloadmap.field09.option02" default="States & Territories"/></option>
                        <option value="aus2"><g:message code="map.downloadmap.field09.option03" default="Local government areas"/></option>
                        <option value="ibra_merged"><g:message code="map.downloadmap.field09.option04" default="IBRA"/></option>
                        <option value="ibra_sub_merged"><g:message code="map.downloadmap.field09.option05" default="IBRA sub regions"/></option>
                        <option value="imcra4_pb"><g:message code="map.downloadmap.field09.option06" default="IMCRA"/></option>
                    </select>
                </p>
                <p>
                    <label for="fileName"><g:message code="map.downloadmap.field10.label" default="File name (without extension)"/></label>
                    <input type="text" name="fileName" id="fileName" value="MyMap"/>
                </p>
            </fieldset>

        </div>
        <div class="modal-footer">
            <button id="submitDownloadMap" class="btn" style="float:left;"><g:message code="map.downloadmap.button01.label" default="Download map"/></button>
            <button class="btn" data-dismiss="modal" aria-hidden="true"><g:message code="map.downloadmap.button02.label" default="Close"/></button>
        </div>
    </form>
</div>

<r:require module="colourPicker"/>
<script type="text/javascript">

    $(document).ready(function(){
        $('#pcolour').colourPicker({
            ico:    '${r.resource(dir:'images',file:'jquery.colourPicker.gif', plugin:'biocache-hubs')}',
            title:    false
        });

        // restrict search to current map bounds/view
        $('#wktFromMapBounds').click(function(e) {
            e.preventDefault();
            var b = MAP_VAR.map.getBounds();
            var wkt = "POLYGON ((" + b.getWest() + " " + b.getNorth() + ", " +
                    b.getEast()  + " " + b.getNorth() + ", " +
                    b.getEast()  + " " + b.getSouth() + ", " +
                    b.getWest()  + " " + b.getSouth() + ", " +
                    b.getWest() + " " + b.getNorth() + "))";
            //console.log('wkt', wkt);
            var url = "${g.createLink(uri:'/occurrences/search')}" + MAP_VAR.query + "&wkt=" + encodeURIComponent(wkt);
            //console.log('new url', url);
            window.location.href = url;
        });
    });

    $('#submitDownloadMap').click(function(e){
        e.preventDefault();
        downloadMapNow();
    });

    function downloadMapNow(){

        var bounds = MAP_VAR.map.getBounds();
        var ne =  bounds.getNorthEast();
        var sw =  bounds.getSouthWest();
        var extents = sw.lng + ',' + sw.lat + ',' + ne.lng + ','+ ne.lat;

        var downloadUrl =  $('#mapDownloadUrl').val() +
                '${raw(sr.urlParameters)}' +
            //'&extents=' + '142,-45,151,-38' +  //need to retrieve the
                '&extents=' + extents +  //need to retrieve the
                '&format=' + $('#format').val() +
                '&dpi=' + $('#dpi').val() +
                '&pradiusmm=' + $('#pradiusmm').val() +
                '&popacity=' + $('#popacity').val() +
                '&pcolour=' + $(':input[name=pcolour]').val().toUpperCase() +
                '&widthmm=' + $('#widthmm').val() +
                '&scale=' + $(':input[name=scale]:checked').val() +
                '&outline=' + $(':input[name=outline]:checked').val() +
                '&outlineColour=0x000000' +
                '&baselayer=' + $('#baselayer').val()+
                '&fileName=' + $('#fileName').val()+'.'+$('#format').val().toLowerCase();

        //console.log('downloadUrl', downloadUrl);
        $('#downloadMap').modal('hide');
        document.location.href = downloadUrl;
    }
</script>