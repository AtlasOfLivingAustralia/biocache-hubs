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
    padding:5px 10px 5px 10px;
}

</style>

<table id="mapLayerControls">
<tr>
    <td>
        <label for="colourBySelect">Colour by:&nbsp;</label>

        <div class="layerControls">
            <select name="colourFacets" id="colourBySelect">
                <option value="">None</option>
                <g:each var="facetResult" in="${facets}">
                    <g:set var="Defaultselected">
                        <g:if test="${defaultColourBy && facetResult.fieldName == defaultColourBy}">selected="selected"</g:if>
                    </g:set>
                    <g:if test="${facetResult.fieldResult.size() > 1}">
                        <option value="${facetResult.fieldName}" ${Defaultselected}>
                            <alatag:formatDynamicFacetName fieldName="${facetResult.fieldName}"/>
                        </option>
                    </g:if>
                </g:each>
            </select>
        </div>
    </td>
    <g:if test="${skin == 'avh'}">
        <td>
            <label for="envLyrList">Environmental layer:&nbsp;</label>

            <div class="layerControls">
                <select id="envLyrList">
                    <option value="">None</option>
                </select>
            </div>
        </td>
        </tr>
        <tr>
    </g:if>
    <td>
        <label for="sizeslider">Size:</label>
        <div class="layerControls">
            <span id="sizeslider-val">4</span>
        </div>
        <div id="sizeslider" style="width:100px;"></div>
    </td>
    <td class="pull-right">
        <g:set var='spatialPortalLink' value="${sr.urlParameters}"/>
        <g:set var='spatialPortalUrlParams' value="${grailsApplication.config.spatial.params}"/>
        <div id="downloadMaps" class="btn btn-small">
            <a id="spatialPortalLink"
               href="${grailsApplication.config.spatial.baseUrl}${spatialPortalLink}${spatialPortalUrlParams}">View in spatial portal</a>
        </div>
        <div id="downloadMaps" class="btn btn-small">
            <a href="#downloadMap" id="downloadMapLink" title="Download a publication quality map">
                <i class="icon-download"></i> Download map</a>
        </div>
    </td>
</tr>
</table>

<div id="leafletMap" class="span12" style="height:600px;"></div>

<div id="template" style="display:none">
    <div class="colourbyTemplate">
        <a class="colour-by-legend-toggle colour-by-control" href="#" title="Map legend">Legend</a>
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
    <a href="#">View records at this point</a>
</div>


<r:script>

    var cmAttr = 'Map data &copy; 2011 OpenStreetMap contributors, Imagery &copy; 2011 CloudMade',
            cmUrl = 'http://{s}.tile.cloudmade.com/${grailsApplication.config.map.cloudmade.key}/{styleId}/256/{z}/{x}/{y}.png';

    var minimal = L.tileLayer(cmUrl, {styleId: 22677, attribution: cmAttr});

    var MAP_VAR = {
        map : null,
        mappingUrl : "${mappingUrl}",
        query : "${searchString}",
        queryDisplayString : "${queryDisplayString}",
        overlays : {},
        baseLayers : {
            "Minimal" : minimal,
            "Night view" : L.tileLayer(cmUrl, {styleId: 999,   attribution: cmAttr}),
            "Road" : new L.Google('ROADMAP'),
            "Terrain" : new L.Google('TERRAIN'),
            "Satellite" : new L.Google('HYBRID')
        },
        layerControl : null,
        currentLayers : [],
        additionalFqs : ''
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

    function initialiseMap(){
        //console.log("initialiseMap", MAP_VAR.map );
        if(MAP_VAR.map != null){
            return;
        }

        //initialise map
        MAP_VAR.map = L.map('leafletMap', {
            center: [-23.6,133.6],
            zoom: 4,
            scrollWheelZoom: false
        });

        //add the default base layer
        MAP_VAR.map.addLayer(minimal);

        MAP_VAR.layerControl = L.control.layers(MAP_VAR.baseLayers, MAP_VAR.overlays, {collapsed:true, position:'topleft'});
        MAP_VAR.layerControl.addTo(MAP_VAR.map);

        addQueryLayer(true);

        MAP_VAR.map.addControl(new ColourByControl());

        L.Util.requestAnimFrame(MAP_VAR.map.invalidateSize, MAP_VAR.map, !1, MAP_VAR.map._container);

        $('#colourBySelect').change(function(e) {
            MAP_VAR.additionalFqs = '';
            addQueryLayer(true);
        });

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

        $('#colourByControl').mouseover(function(e){
            MAP_VAR.map.dragging.disable();
            MAP_VAR.map.off('click', pointLookup);
        });

        $('#colourByControl').mouseout(function(e){
            MAP_VAR.map.dragging.enable();
            MAP_VAR.map.on('click', pointLookup);
        });

        $('.hideColourControl').click(function(e){
            $('#colourByControl').removeClass('leaflet-control-layers-expanded');
            $('.colour-by-legend-toggle').show();
            e.preventDefault();
            e.stopPropagation();
            return false;
        });

        $( "#sizeslider" ).slider({
            min:2,
            max:10,
            tooltip: 'hide'
        }).on('slideStop', function(ev){
            $('#sizeslider-val').html(ev.value);
            addQueryLayer(true);
        });

        fitMapToBounds(); // zoom map if points are contained within Australia
        drawCircleRadius(); // draw circle around lat/lon/radius searches

        //enable the point lookup - but still allow double clicks to propagate
        var clickCount = 0;
        MAP_VAR.map.on('click', function(e) {
            clickCount += 1;
            if (clickCount <= 1) {
                setTimeout(function() {
                    if (clickCount <= 1) {
                        pointLookup(e);
                    }
                    clickCount = 0;
                }, 400);
            }
        });
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

        var envProperty = "color:${grailsApplication.config.map.pointColour};name:circle;size:"+pointSize+";opacity:1"

        if(colourByFacet){
            envProperty = "colormode:" + colourByFacet +";name:circle;size:"+pointSize+";opacity:1"
        }

        var layer = L.tileLayer.wms(MAP_VAR.mappingUrl + "/webportal/wms/reflect" + MAP_VAR.query + MAP_VAR.additionalFqs, {
            layers: 'ALA:occurrences',
            format: 'image/png',
            transparent: true,
            attribution: "${grailsApplication.config.skin.orgNameLong}",
            bgcolor:"0x000000",
            outline:"true",
            ENV: envProperty
        });

        if(redraw){
             if(!colourByFacet){
                $('.legendTable').html('');
                addDefaultLegendItem("${grailsApplication.config.map.pointColour}");
             } else {
                //update the legend
                $('.legendTable').html('<tr><td>Loading legend....</td></tr>');
                $.ajax({
                    url: "${grailsApplication.config.security.cas.contextPath}/occurrence/legend" + MAP_VAR.query + "&cm=" + colourByFacet + "&type=application/json",
                    success: function(data) {
                        $('.legendTable').html('');

                        $.each(data, function(index, legendDef){
                            var legItemName = legendDef.name ? legendDef.name : 'Not specified';
                            addLegendItem(legItemName, legendDef.red,legendDef.green,legendDef.blue );
                        });

                        $('.layerFacet').click(function(e){
                            var controlIdx = 0;
                            MAP_VAR.additionalFqs = '';
                            $('#colourByControl').find('.layerFacet').each(function(idx, layerInput){
                                var include =  $(layerInput).is(':checked');

                                if(!include){
                                    MAP_VAR.additionalFqs = MAP_VAR.additionalFqs + '&HQ=' + controlIdx;
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

    function addLegendItem(name, red, green, blue){
        $(".legendTable")
            .append($('<tr>')
                .append($('<td>')
                    .append($('<input>')
                        .attr('type', 'checkbox')
                        .attr('checked', 'checked')
                        .attr('id', name)
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
                        .html(name)
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

        var popup = L.popup().setLatLng(e.latlng);
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

        $.ajax({
            url: MAP_VAR.mappingUrl + "/occurrences/info",
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

                console.log(response);

                var $popupClone = null;

                var occLookup = "&radius=" + radius + "&lat=" + e.latlng.lat + "&lon=" + e.latlng.lng;

                if(response.count == 1){
                    var popupClone = $('.popupSingleRecordTemplate').clone();
                    $popupClone = $(popupClone);
                    $popupClone.find('.viewRecord').attr('href', "${grailsApplication.config.biocache.baseURL }/occurrences/" + response.occurrences[0]);
                    popup.setContent($popupClone.html());
                    popup.openOn(MAP_VAR.map);
                }
                if(response.count > 1){
                    var popupClone = $('.popupMultiRecordTemplate').clone();
                    $popupClone = $(popupClone);
                    $popupClone.find('.viewRecord').attr('href', "${grailsApplication.config.biocache.baseURL }/occurrences/" + response.occurrences[0]);
                    $popupClone.find('.viewAllRecords').attr('href', "${grailsApplication.config.biocache.baseURL }/occurrences/search" + MAP_VAR.query + occLookup);
                    $popupClone.find('.recordCount').html(response.count);
                    popup.setContent($popupClone.html());
                    popup.openOn(MAP_VAR.map);
                }
            }
        });
    }

    function getRecordInfo(){
        http://biocache.ala.org.au/ws/occurrences/c00c2f6a-3ae8-4e82-ade4-fc0220529032
        $.ajax({
            url: "${grailsApplication.config.biocacheServicesUrl}/occurrences/info" + MAP_VAR.query,
            jsonp: "callback",
            dataType: "jsonp",
            success: function(response) {

            }
        });
    }

    /**
     * Zooms map to either spatial search or from WMS data bounds
     */
    function fitMapToBounds() {
        // Don't run for spatial searches, which have their own fitBounds() method
        if (!isSpatialRadiusSearch()) {
            // all other searches (non-spatial)
            // do webservice call to get max extent of WMS data
            var jsonUrl = "${grailsApplication.config.biocacheServicesUrl}/webportal/bounds.json" + MAP_VAR.query + "&callback=?";
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
                    } else if (BC_CONF.zoomOutsideAustralia) {
                        //map.fitBounds(dataBounds);
                        //console.log("zoom", map.getZoom())
                        MAP_VAR.map.fitBounds(dataBounds);

                        if (MAP_VAR.map.getZoom() == 0) {
                            //MAP_VAR.map.setCenter(centre);
                            MAP_VAR.map.setZoom(2);
                        }
                    }
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

            var popupText = "Centre of spatial search with radius of " + radius + " km";
            var circle = L.circle(latLng, radius * 1030, circleOpts);
            circle.addTo(MAP_VAR.map);
            MAP_VAR.map.fitBounds(circle.getBounds()); // make circle the centre of the map, not the points
            L.marker(latLng, {title: popupText}).bindPopup(popupText).addTo(MAP_VAR.map);
            //L.circleMarker(latLng, {radius: 6, opacity: 0.8, fillOpacity: 1.0}).bindPopup(popupText).addTo(MAP_VAR.map);
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

</r:script>

<div style="display:none;">

<div class="popupSingleRecordTemplate">
    <span class="dataResource">Dummy resource</span><br/>
    <span class="institution">Dummy institution</span><br/>
    <span class="collection">Dummy collection</span><br/>
    <span class="catalogueNumber">Dummy catalogue number</span><br/>
    <a href="" class="viewRecord">View this record</a>
</div>

<div class="popupMultiRecordTemplate">
    <span>Records: </span><a href="" class="viewAllRecords"><span class="recordCount">1,321</span></a><br/>
    <span class="dataResource">Dummy resource</span><br/>
    <span class="institution">Dummy institution</span><br/>
    <span class="collection">Dummy collection</span><br/>
    <span class="catalogueNumber">Dummy catalogue number</span><br/>
    <a href="" class="viewRecord" >View this record</a><br/>
    <a href="" class="viewAllRecords">View <span class="recordCount">1,321</span> records at this point</a>
</div>

</div>