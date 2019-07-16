
/*
 * Copyright (C) 2014 Atlas of Living Australia
 * All Rights Reserved.
 *
 * The contents of this file are subject to the Mozilla Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 */

/*
 * // require jquery
//= require purl.js
//= require leaflet/leaflet.js
//= require leaflet-plugins/layer/tile/Google.js
//= require leaflet-plugins/spin/spin.min.js
//= require leaflet-plugins/spin/leaflet.spin.js
//= require leaflet-plugins/EasyButton/easy-button.js
//= require leaflet-google.js
//= require magellan.js
//= require jquery.qtip.min.js
//= require biocache-hubs.js
//= require map.common.js
//= require_self
 */


var geocoder, marker, circle, markerInfowindow, lastInfoWindow, taxon, taxonGuid, alaWmsLayer, radius;
var points = [], infoWindows = [], speciesGroup = "ALL_SPECIES";
var coordinatePrecision = 4; // roughly 11m at equator || 5 = 1.1 m at equator
var zoomForRadius = {
    1000: 14,
    5000: 12,
    10000: 11
};
var radiusForZoom = {
    11: 10,
    12: 5,
    14: 1
};

/**
 * Document onLoad event using JQuery
 */
$(document).ready(function() {

    // initialise Google Geocoder
    geocoder = new google.maps.Geocoder();

    // Catch page events...

    // Register events for the species_group column
    $('#taxa-level-0').on("mouseover mouseout", "tbody tr",  function() {
        // mouse hover on groups
        if ( event.type == "mouseover" ) {
            $(this).addClass('hoverRow');
        } else {
            $(this).removeClass('hoverRow');
        }
    }).on("click", "tbody tr", function(e) {
        // catch the link on the taxon groups table
        e.preventDefault(); // ignore the href text - used for data
        groupClicked(this);
    });

    // By default action on page load - show the all species group (simulate a click)
    //$('#taxa-level-0 tbody td:first').click();

    // register click event on "Search" button"
    $('input#locationSearch').click(
        function(e) {
            e.preventDefault(); // ignore the href text - used for data
            geocodeAddress();
        }
    );

    // Register onChange event on radius drop-down - will re-submit form
    $('select#radius').change(
        function(e) {
            MAP_VAR.radius = parseInt($(this).val());
            radius = MAP_VAR.radius * 1000;
            circle.setRadius(radius);
            MAP_VAR.zoom = zoomForRadius[radius];
            MAP_VAR.map.setZoom((MAP_VAR.zoom) ? MAP_VAR.zoom : 12);
            MAP_VAR.layerControl.removeLayer(marker); // prevent duplicate controls
            loadGroups();
        }
    );

    // QTip tooltips
    $(".tooltips").qtip({
        style: {
            classes: 'ui-tooltip-rounded ui-tooltip-shadow'
        },
        position: {
            target: 'mouse',
            adjust: { x: 6, y: 14 }
        }
    });

    // Handle back button and saved URLs

    var defaultParam = $.url().param('default'); // requires JS import: purl.js
    var encodedHash = getEncodedHash();

    if (defaultParam) {
        initialize();
    } else if ( $.url().param('lat') &&  $.url().param('lon') && $.url().param('radius')) {
        // triggered if user has clicked "return to search results" from download confirmation page
        // URL with have params: lat, lon, radius & fq
        // e.g. q=*:*&lat=-35.2509&lon=149.1638&radius=1&fq=geospatial_kosher:true&fq=species_group:Insects
        var lat = $.url().param('lat');
        var lon = $.url().param('lon');
        var radiusInMetres = $.url().param('radius') * 1000; // assume radius is in km (SOLR radius param)
        var radius = zoomForRadius[radiusInMetres];
        var species_group;
        var fqs = $.url().param('fq'); // can be array or string

        if (Array.isArray(fqs)) {
            // multiple fq params
            fqs.forEach(function(fq) {
                var parts = fq.split(":"); // e.g. speciesGroup:Insects
                if (parts[0] == "species_group") {
                    species_group = parts[1];
                }
            });
        } else if (fqs) {
            var parts = fqs.split(":");
            if (parts[0] == "species_group") {
                species_group = parts[1];
            }
        }

        // strip params from URL
        window.history.replaceState(null, null, window.location.pathname);
        // update map state for provided coordinates, etc.
        bookmarkedSearch(lat, lon, radius, species_group);
    } else if (encodedHash) {
        // update map state from URL hash
        loadStateFromHash(encodedHash);
    } else {
        //console.log("defaultParam not set, geolocating...");
        attemptGeolocation();
    }

    window.onhashchange = function() {
        // trigger state change (back button mostly - TODO check for duplicate function calls)
        loadStateFromHash(getEncodedHash());
    };

    // catch the link for "View all records"
    $('#viewAllRecords').on("click", function(e) {
        e.preventDefault();
        //var params = "q=taxon_name:*|"+$('#latitude').val()+"|"+$('#longitude').val()+"|"+$('#radius').val();
        var params = "q=*:*&lat="+$('#latitude').val()+"&lon="+$('#longitude').val()+"&radius="+$('#radius').val()+"&fq=geospatial_kosher:true";
        if (speciesGroup != "ALL_SPECIES") {
            params += "&fq=species_group:" + speciesGroup;
        }
        document.location.href = MAP_VAR.contextPath +'/occurrences/search?' + params;
    });

    // catch the link for "Download"
    // ?searchParams=${sr?.urlParameters?.encodeAsURL()}&targetUri=${(request.forwardURI)}&totalRecords=${sr.totalRecords}
    $('#downloadData').on("click", function(e) {
        e.preventDefault();
        //var params = "q=taxon_name:*|"+$('#latitude').val()+"|"+$('#longitude').val()+"|"+$('#radius').val();
        var params = "?q=*:*&lat="+$('#latitude').val()+"&lon="+$('#longitude').val()+"&radius="+$('#radius').val()+"&fq=geospatial_kosher:true";
        if (speciesGroup != "ALL_SPECIES") {
            params += "&fq=species_group:" + speciesGroup;
        }
        var searchParams = encodeURIComponent(params);
        document.location.href = MAP_VAR.contextPath +'/download?searchParams=' + searchParams + "&targetUri=" + MAP_VAR.forwardURI;
    });


    // Tooltip for matched location
    $('#addressHelp').qtip({
        content: {
            title: {
                text: "About the matched address",
                button: "Close"
            },
            text: "<img src=\"" + MAP_VAR.imagesUrlPrefix + "/spinner.gif\" alt=\"\" class=\"no-rounding\"/>",
            ajax: {
                url: MAP_VAR.contextPath + "/proxy/wordpress", // TODO fix proxy
                data: {
                    page_id: 27726,
                    "content-only": 1
                },
                type: "get"
            }
        },
        position: {
            at: "bottom right",
            my: "top left"
        },
        style: {
            width: 450,
            tip: "topLeft",
            classes: 'ui-tooltip-light ui-tooltip-rounded ui-tooltip-shadow'
        },
        show: {
            effect: function(api) { $(this).slideDown(300, function(){ $(this).dequeue(); }); }
        },
        hide: {
            fixed: true,
            effect: function(api) { $(this).slideUp(300, function(){ $(this).dequeue(); }); },
            event: "unfocus"
        }
    }).bind('click', function(event){ event.preventDefault(); return false;});

    $("#left-col a").qtip({
        style: {
            classes: 'ui-tooltip-rounded ui-tooltip-shadow'
        },
        position: {
            target: 'mouse',
            adjust: {
                x: 10,
                y: 12
            }
        }
    });

    // qtip for easy-button
    $('.easy-button-button').qtip();

    // Catch enter key press on form
    $("#searchForm").bind("keypress", function(e) {
        if (e.keyCode == 13) {
            e.preventDefault();
            geocodeAddress();
        }
    });

}); // end onLoad event

//var proj900913 = new OpenLayers.Projection("EPSG:900913");
//var proj4326 = new OpenLayers.Projection("EPSG:4326");

// pointer fn
function initialize() {
    //loadMap();
    loadLeafletMap();
    loadGroups();
}

/*
 * Initiate Leaflet map
 */
function loadLeafletMap() {
    var latLng = L.latLng($('#latitude').val(), $('#longitude').val());

    if (!MAP_VAR.map) {
        var defaultBaseLayer = L.tileLayer(MAP_VAR.mapMinimalUrl, {
            attribution: MAP_VAR.mapMinimalAttribution,
            subdomains: MAP_VAR.mapMinimalSubdomains
        });

        var baseLayers = {
            "Minimal": defaultBaseLayer,
            "Road":  new L.Google('ROADMAP'),
            //"Terrain": new L.Google('TERRAIN'),
            "Satellite": new L.Google('HYBRID')
        };

        MAP_VAR.map = L.map('mapCanvas', {
            center: latLng,
            zoom: MAP_VAR.zoom,
            scrollWheelZoom: false
            //layerControl: null
        });

        updateMarkerPosition(latLng);

        // add layer control (layerControl is not a leaflet var)
        MAP_VAR.layerControl = L.control.layers(baseLayers).addTo(MAP_VAR.map);

        // add the default base layer
        MAP_VAR.map.addLayer(defaultBaseLayer);

        // "locate me" button
        L.easyButton( '<i class="fa fa-location-arrow" data-toggle="tooltip" data-placement="right"></i>', function(e){
            attemptGeolocation();
        },"Use my location").addTo(MAP_VAR.map);

    } else {
        // map loaded already
        // reset layers/markers
        MAP_VAR.layerControl.removeLayer(marker); // prevent duplicate controls
        if (MAP_VAR.map.hasLayer(circle)) MAP_VAR.map.removeLayer(circle);
        if (MAP_VAR.map.hasLayer(marker)) MAP_VAR.map.removeLayer(marker);
        marker = null;
        circle = null;
    }

    // Fix for asset pipeline confusing Leaflet WRT to path to images
    L.Icon.Default.imagePath = MAP_VAR.mapIconUrlPath;

    // Add marker
    marker = L.marker(latLng, {
        title: 'Marker Location',
        draggable: true
    }).addTo(MAP_VAR.map);

    //MAP_VAR.layerControl.removeLayer(marker); // prevent duplicate controls
    MAP_VAR.layerControl.addOverlay(marker, 'Marker');

    markerInfowindow = marker.bindPopup('<div class="infoWindow">marker address</div>',
        {autoClose: true}
    );

    // Add a Circle overlay to the map.
    radius = parseInt($('select#radius').val()) * 1010;
    var circlProps = {
        //radius: radius, leaflet 1+ uses this syntax
        stroke: true,
        weight: 2,
        color: 'black',
        opacity: 0.2,
        fillColor: '#888', // '#2C48A6'
        fillOpacity: 0.2,
        zIndex: -10
    }

    // console.log("circlProps", circlProps, latLng, radius);
    circle = L.circle(latLng, radius, circlProps).addTo(MAP_VAR.map);

    // detect click event and trigger record info popup
    circle.on("click", function (event) {
        pointLookupClickRegister(event);
    });

    // bind circle to marker
    marker.on('dragend', function(e){
        var coords = e.target.getLatLng();
        var lat = coords.lat.toFixed(coordinatePrecision);
        var lon = coords.lng.toFixed(coordinatePrecision);
        var newLatLng = L.latLng(lat, lon);
        MAP_VAR.map.panTo({lon:lon,lat:lat})
        MAP_VAR.map.removeLayer(circle);
        circlProps.radius = radius;
        circle = L.circle([lat, lon], radius, circlProps).addTo(MAP_VAR.map);
        updateMarkerAddress('Drag ended');
        updateMarkerPosition(newLatLng);
        geocodePosition(newLatLng);
        //LoadTaxaGroupCounts();
        loadGroups();
        //loadRecordsLayer();
        // adjust map view for new location
        MAP_VAR.map.setView(latLng, MAP_VAR.zoom);
        MAP_VAR.layerControl.removeLayer(marker); // prevent duplicate controls
    });

    // adjust map view for new location
    MAP_VAR.map.setView(latLng, MAP_VAR.zoom);

    // Update current position info.
    geocodePosition(latLng);
    updateMarkerPosition(latLng);
}

/**
 * Google geocode function
 */
function geocodePosition(pos) {
    var gLatLng = new google.maps.LatLng(pos.lat, pos.lng); // convert leaflet Latlng to Google Latlng

    geocoder.geocode({
        latLng: gLatLng
    }, function(responses) {
        if (responses && responses.length > 0) {
            // console.log("geocoded position", responses[0]);
            var address = responses[0].formatted_address;
            updateMarkerAddress(address);
            // update the info window for marker icon
            var content = '<div class="infoWindow"><b>Location:</b><br/>'+address+'</div>';
            markerInfowindow.bindPopup(content);
        } else {
            updateMarkerAddress('Cannot determine address at this location.');
        }
    });
}

/**
 * Update the "address" hidden input and display span
 */
function updateMarkerAddress(str) {
    $('#markerAddress').empty().html(str);
    $('#location').val(str);
    $('#dialog-confirm code').html(str); // download popup text
}

/**
 * Update the lat & lon hidden input elements
 */
function updateMarkerPosition(latLng) {
    // console.log("updateMarkerPosition", latLng, latLng.lat);
    var lat = latLng.lat.toFixed(coordinatePrecision);
    var lng = latLng.lng.toFixed(coordinatePrecision);
    // store values in hidden fields
    $('#latitude').val(lat);
    $('#longitude').val(lng);
    //console.log("updating hash lat", lat, $('#latitude').val());
    $('#dialog-confirm #rad').html(MAP_VAR.radius);
    MAP_VAR.query = "?q=*%3A*&lat=" + lat + "&lon=" + lng + "&radius=" + MAP_VAR.radius;
}

/**
 * Load (reload) geoJSON data into vector layer
 */
function loadRecordsLayer(retry) {
    if (!MAP_VAR.map && !retry) {
        // in case a callback calls this function before map has initialised
        setTimeout(function() {if (!points || points.length == 0) {loadRecordsLayer(true)}}, 2000);
        //console.log('retry triggered');
        return;
    } else if (!MAP_VAR.map) {
        //console.log('retry failed');
        return;
    }

    // Update URL hash for back button, etc
    location.hash = $('#latitude').val() + "|" + $('#longitude').val() + "|" + MAP_VAR.zoom + "|" + speciesGroup;

    // remove any existing records layers and controls
    if (alaWmsLayer) {
        MAP_VAR.map.removeLayer(alaWmsLayer);
        MAP_VAR.layerControl.removeLayer(alaWmsLayer);
        //MAP_VAR.layerControl.removeLayer(marker); // prevent duplicate controls
    }

    // URL for GeoJSON web service
    //var geoJsonUrl = MAP_VAR.biocacheServiceUrl + "/geojson/radius-points";
    var speciesGroupParam = "species_group:" + (speciesGroup == "ALL_SPECIES" ? "*" : speciesGroup);
    var alaParams = jQuery.param({
        q: (taxon) ? "taxon_name:\"" + taxon + "\"" : "*:*",
        lat: $('#latitude').val(),
        lon: $('#longitude').val(),
        radius: $('#radius').val(),
        fq: [ "geospatial_kosher:true",
              speciesGroupParam
        ],
        qc: MAP_VAR.queryContext
        //zoom: (map && map.getZoom()) ? map.getZoom() : 12
    }, true);

    // records popups need to know the species group
    MAP_VAR.removeFqs = "&fq=species_group:" + (speciesGroup == "ALL_SPECIES" ? "*" : speciesGroup) + "&fq=taxon_name:" + (taxon ? taxon : "*");

    // console.log("alaParams = ", alaParams, speciesGroupParam);

    var alaMapUrl = MAP_VAR.biocacheServiceUrl + "/ogc/wms/reflect?" + alaParams;
    var wmsParams = {
        layers: 'ALA:occurrences',
        format: 'image/png',
        transparent: true,
        attribution: "Atlas of Living Australia",
        bgcolor:"0x000000",
        outline:"false",
        GRIDDETAIL: 32, // 64 || 32
        ENV: "color:DF4A21;name:circle;size:4;opacity:0.7",
        //ENV: "colormode:grid;name:square;size:3;opacity:0.7",
        uppercase: true
    };

    //console.log('About to call $.get', map);
    // JQuery AJAX call
    //$.getJSON(alaMaprUrl, params, loadNewGeoJsonData);
    alaWmsLayer = L.tileLayer.wms(alaMapUrl, wmsParams).addTo(MAP_VAR.map);
    MAP_VAR.layerControl.addOverlay(alaWmsLayer, 'Records');

    alaWmsLayer.on('tileload', function(te){
        // populate points array so we can tell if data is loaded - legacy from geoJson version
        points.push(te.url);
    });
}

/**
 * Try to get a lat/long using HTML5 geolocation API
 */
function attemptGeolocation() {
    // HTML5 GeoLocation
    if (navigator && navigator.geolocation) {
        // console.log("trying to get coords with navigator.geolocation...");  
        function getMyPostion(position) {
            //alert('coords: '+position.coords.latitude+','+position.coords.longitude);
            // console.log('geolocation "navigator" request accepted');
            //$('#mapCanvas').empty();
            updateMarkerPosition(L.latLng(position.coords.latitude, position.coords.longitude));
            //LoadTaxaGroupCounts();
            initialize();
        }

        function positionWasDeclined() {
            alert('Geolocation request was declined or failed due to an error. Try searching for your address using the search box above the map.');
            // scroll window so search bar is visible
            $('html, body').animate({
                scrollTop: $("#searchForm").offset().top - 120 // banner offset 120px
            }, 1000);

            updateMarkerPosition(L.latLng($('#latitude').val(), $('#longitude').val()));
            //LoadTaxaGroupCounts();
            initialize();
        }

        // Add message to browser - FF needs this as it is not easy to see
        //var msg = 'Waiting for confirmation to use your current location (see browser message at top of window)'+
        //    '<br/><a href="#" onClick="initialize(); return false;">Click here to load map</a>';
        //$('#mapCanvas').html(msg).css('color','red').css('font-size','14px');
        //map.remove;
        //map = null;
        navigator.geolocation.getCurrentPosition(getMyPostion, positionWasDeclined);
        //console.log("line after navigator.geolocation.getCurrentPosition...");  
        // Neither functions gets called for some reason, so I've added a delay to initalize map anyway
        setTimeout(function() {if (!MAP_VAR.map) positionWasDeclined();}, 9000);
    } else if (google.loader && google.loader.ClientLocation) {
        // Google AJAX API fallback GeoLocation
        // console.log("getting coords using google geolocation", google.loader.ClientLocation);
        updateMarkerPosition(L.latLng(google.loader.ClientLocation.latitude, google.loader.ClientLocation.longitude));
        //LoadTaxaGroupCounts();
        initialize();
    } else {
        //alert("Client geolocation failed");
        //geocodeAddress();
        MAP_VAR.zoom = 12;
        initialize();
    }
}

/**
 * Reverse geocode coordinates via Google Maps API
 */
function geocodeAddress(reverseGeocode) {
    var address = $('input#address').val();
    var latLng = null;

    // Check if input contains a comma and try and parse coordinates
    if (address && address.indexOf(",") > -1 && magellan) {
        var parts = address.split(",");
        var lat = magellan(parts[0].trim()).latitude(); //.toDD();
        var lng = magellan(parts[1].trim()).longitude(); //.toDD();
        //console.log("magellan", parts, lat, lng);

        if (lat && lng) {
            latLng = L.latLng(lat.toDD(), lng.toDD());
            updateMarkerAddress("GPS coordinates: " + lat.toDD() + ", " + lng.toDD());
            updateMarkerPosition(latLng);
            // reload map pin, etc
            //console.log("geocodeAddress() calling loadRecordsLayer()");
            initialize();
            loadRecordsLayer();
        }

    }

    if (!latLng && geocoder && address) {
        //geocoder.getLocations(address, addAddressToPage);
        // console.log("geocodeAddress with address string");
        geocoder.geocode( {'address': address, region: MAP_VAR.geocodeRegion}, function(results, status) {
            if (status == google.maps.GeocoderStatus.OK) {
                // geocode was successful
                //console.log('geocodeAddress results', results);
                updateMarkerAddress(results[0].formatted_address);
                var gLatLng = results[0].geometry.location;
                // console.log("gLatLng", gLatLng.lat(), gLatLng.lng());
                var latLng = L.latLng(gLatLng.lat(), gLatLng.lng());
                updateMarkerPosition(latLng);
                // reload map pin, etc
                initialize();
                loadRecordsLayer();
                //LoadTaxaGroupCounts();
            } else {
                alert("Geocode was not successful for the following reason: " + status);
            }
        });
    } else {
        initialize();
    }
}

/**
 * Geocode location via Google Maps API
 */
function addAddressToPage(response) {
    //map.clearOverlays();
    if (!response || response.Status.code != 200) {
        alert("Sorry, we were unable to geocode that address");
    } else {
        var location = response.Placemark[0];
        var lat = location.Point.coordinates[1]
        var lon = location.Point.coordinates[0];
        var locationStr = response.Placemark[0].address;
        updateMarkerAddress(locationStr);
        updateMarkerPosition(L.latLng(lat, lon));
    }
}

/**
 * Species group was clicked
 */
function groupClicked(el) {
    // Change the global var speciesGroup
    speciesGroup = $(el).find('a.taxonBrowse').attr('id');
    taxon = null; // clear any species click
    taxonGuid = null;
    //taxa = []; // array of taxa
    //taxa = (taxon.indexOf("|") > 0) ? taxon.split("|") : taxon;
    $('#taxa-level-0 tr').removeClass("activeRow");
    $(el).addClass("activeRow");
    $('#taxa-level-1 tbody tr').addClass("activeRow");
    // update records page link text
    if (speciesGroup == "ALL_SPECIES") {
        $("#recordsGroupText").text("all");
    } else {
        $("#recordsGroupText").text("selected");
    }
    // load records layer on map
    //console.log('about to run: loadRecordsLayer()');
    // update links to downloads and records list
    //console.log("groupClicked() calling loadRecordsLayer()");
    if (MAP_VAR.map) loadRecordsLayer();
    // AJAX...
    var uri = MAP_VAR.biocacheServiceUrl + "/explore/group/"+speciesGroup+".json";
    var params = {
        lat: $('#latitude').val(),
        lon: $('#longitude').val(),
        radius: $('#radius').val(),
        fq: "geospatial_kosher:true",
        qc: MAP_VAR.queryContext,
        pageSize: 50
    };
    //var params = "?latitude=${latitude}&longitude=${longitude}&radius=${radius}&taxa="+taxa+"&rank="+rank;
    $('#taxaDiv').html('[loading...]');
    $.getJSON(uri, params, function(data) {
        // process JSON data from request
        if (data) processSpeciesJsonData(data);
    });
}

/**
 * Process the JSON data from an Species list AJAX request (species in area)
 */
function processSpeciesJsonData(data, appendResults) {
    // clear right list unless we're paging
    if (!appendResults) {
        //$('#loadMoreSpecies').detach();
        $('#rightList tbody').empty();
    }
    // process JSON data
    if (data.length > 0) {
        var lastRow = $('#rightList tbody tr').length;
        var linkTitle = "display on map";
        var infoTitle = "view species page";
        var recsTitle = "view list of records";
        // iterate over list of species from search
        for (i=0;i<data.length;i++) {
            // create new table row
            var count = i + lastRow;
            // add count
            var tr = '<tr><td class="speciesIndex">'+(count+1)+'.</td>';
            // add scientific name
            tr = tr + '<td class="sciName"><a id="' + data[i].guid + '" class="taxonBrowse2" title="'+linkTitle+'" href="'+ // id=taxon_name
                data[i].name+'"><i>'+data[i].name+'</i></a>';
            // add common name
            if (data[i].commonName) {
                tr = tr + ' : ' + data[i].commonName+'';
            }
            // add links to species page and occurrence search (inside hidden div)
            if(MAP_VAR.speciesPageUrl) {

                var speciesInfo = '<div class="speciesInfo">';
                if (data[i].guid) {
                    speciesInfo = speciesInfo + '<a class="speciesPageLink" title="' + infoTitle + '" href="' + MAP_VAR.speciesPageUrl + data[i].guid +
                        '"><img src="' + MAP_VAR.imagesUrlPrefix + '/page_white_go.png" alt="species page icon" style="margin-bottom:-3px;" class="no-rounding"/>' +
                        ' species profile</a> | ';
                }
                speciesInfo = speciesInfo + '<a href="' + MAP_VAR.contextPath + '/occurrences/search?q=taxon_name:%22' + data[i].name +
                    '%22&lat=' + $('input#latitude').val() + '&lon=' + $('input#longitude').val() + '&radius=' + $('select#radius').val() + '" title="' +
                    recsTitle + '"><img src="' + MAP_VAR.imagesUrlPrefix + '/database_go.png" ' +
                    'alt="search list icon" style="margin-bottom:-3px;" class="no-rounding"/> list of records</a></div>';
                tr = tr + speciesInfo;
            }
            // add number of records
            tr = tr + '</td><td class="rightCounts">' + data[i].count + ' </td></tr>';
            // write list item to page
            $('#rightList tbody').append(tr);
            //if (console) console.log("tr = "+tr);
        }

        if (data.length == 50) {
            // add load more link
            var newStart = $('#rightList tbody tr').length;
            var sortOrder = $("div#rightList").data("sort") ? $("div#rightList").data("sort") : "index";
            $('#rightList tbody').append('<tr id="loadMoreSpecies"><td>&nbsp;</td><td colspan="2"><a href="'+newStart+
                '" data-sort="'+sortOrder+'">Show more species</a></td></tr>');
        }

    } else if (appendResults) {
        // do nothing
    } else {
        // no spceies were found (either via paging or clicking on taxon group
        var text = '<tr><td></td><td colspan="2">[no species found]</td></tr>';
        $('#rightList tbody').append(text);
    }

    // Register clicks for the list of species links so that map changes
    $('#rightList tbody tr').click(function(e) {
        e.preventDefault(); // ignore the href text - used for data
        //var thisTaxon = $(this).find('a.taxonBrowse2').attr('href'); // absolute URI in IE!
        var thisTaxonA = $(this).find('a.taxonBrowse2').attr('href').split('/');
        var thisTaxon = thisTaxonA[thisTaxonA.length-1].replace(/%20/g, ' ');
        var guid = $(this).find('a.taxonBrowse2').attr('id');
        taxonGuid = guid;
        taxon = thisTaxon; // global var so map can show just this taxon
        //rank = $(this).find('a.taxonBrowse2').attr('id');
        //taxa = []; // array of taxa
        //taxa = (taxon.indexOf("|") > 0) ? taxon.split("|") : taxon;
        //$(this).unbind('click'); // activate links inside this row
        $('#rightList tbody tr').removeClass("activeRow2"); // un-highlight previous current taxon
        // remove previous species info row
        $('#rightList tbody tr#info').detach();
        var info = $(this).find('.speciesInfo').html();
        // copy contents of species into a new (tmp) row
        if (info) {
            $(this).after('<tr id="info"><td><td>'+info+'<td></td></tr>');
        }
        // hide previous selected spceies info box
        $(this).addClass("activeRow2"); // highloght current taxon
        // show the links for current selected species
        //console.log('species link -> loadRecordsLayer()');
        loadRecordsLayer();
    });

    // Register onClick for "load more species" link & sort headers
    $('#loadMoreSpecies a, thead.fixedHeader a').click(function(e) {
            e.preventDefault(); // ignore the href text - used for data
            var thisTaxon = $('#taxa-level-0 tr.activeRow').find('a.taxonBrowse').attr('id');
            //rank = $('#taxa-level-0 tr.activeRow').find('a.taxonBrowse').attr('id');
            taxa = []; // array of taxa
            taxa = (thisTaxon.indexOf("|") > 0) ? thisTaxon.split("|") : thisTaxon;
            var start = $(this).attr('href');
            var sortOrder = $(this).data("sort") ? $(this).data("sort") : "index";
            var sortParam = sortOrder;
            var commonName = false;
            if (sortOrder == "common") {
                commonName = true;
                sortParam = "index";
                //$("a#commonSort").insertBefore("a#speciesSort");
            } else if (sortOrder == "index") {
                //$("a#speciesSort").insertBefore("a#commonSort");
            }
            var append = true;
            if (start == 0) {
                append = false;
                $(".scrollContent").scrollTop(0); // return scroll bar to top of tbody
            }
            $("div#rightList").data("sort", sortOrder); // save it to the DOM
            // AJAX...
            var uri = MAP_VAR.biocacheServiceUrl + "/explore/group/"+speciesGroup+".json";
            //var params = "&lat="+$('#latitude').val()+"&lon="+$('#longitude').val()+"&radius="+$('#radius').val()+"&group="+speciesGroup;
            var params = {
                lat: $('#latitude').val(),
                lon: $('#longitude').val(),
                radius: $('#radius').val(),
                fq: "geospatial_kosher:true",
                start: start,
                common: commonName,
                sort: sortParam,
                pageSize: 50,
                qc: MAP_VAR.queryContext
            };
            //console.log("explore params", params, append);
            //$('#taxaDiv').html('[loading...]');
            $('#loadMoreSpecies').detach(); // delete it
            $.getJSON(uri, params, function(data) {
                // process JSON data from request
                processSpeciesJsonData(data, append);
            });
        }
    );

    // add hover effect to table cell with scientific names
    $('#rightList tbody tr').hover(
        function() {
            $(this).addClass('hoverCell');
        },
        function() {
            $(this).removeClass('hoverCell');
        }
    );
}

/*
 * Perform normal spatial search for species groups and species counts
 */
function loadGroups() {
    var url = MAP_VAR.biocacheServiceUrl +"/explore/groups.json";
    var params = {
        //"group": $(this).attr('title'),
        lat: $('#latitude').val(),
        lon: $('#longitude').val(),
        radius: $('#radius').val(),
        fq: "geospatial_kosher:true",
        facets: "species_group",
        qc: MAP_VAR.queryContext
    }

    $.getJSON(url, params, function(data) {
        if (data) {
            populateSpeciesGroups(data);
        }
    });
}

/*
 * Populate the species group column (via callback from AJAX)
 */
function populateSpeciesGroups(data) {
    if (data.length > 0) {
        $("#taxa-level-0 tbody").empty(); // clear existing values
        $.each(data, function (i, n) {
            addGroupRow(n.name, n.speciesCount, n.level)
        });

        // Dynamically set height of #taxaDiv (to match containing div height)
        var tableHeight = $('#taxa-level-0').height();
        $('.tableContainer').height(tableHeight+2);
        var tbodyHeight = $('#taxa-level-0 tbody').height();
        $('#rightList tbody').height(tbodyHeight);
        $('#taxa-level-0 tbody tr.activeRow').click();
    }

    function addGroupRow(group, count, indent) {
        var label = group;
        if (group == "ALL_SPECIES") label = "all.species";
        var rc = (group == speciesGroup) ? " class='activeRow'" : ""; // highlight active group
        var i18nLabel = jQuery.i18n.prop(label);
        // console.log("i18n check", label, i18nLabel);
        var h = "<tr"+rc+" title='click to view group on map'><td class='indent"+indent+"'><a href='#' id='"+group+"' class='taxonBrowse' title='click to view group on map'>"+i18nLabel+"</a></td><td>"+count+"</td></tr>";
        $("#taxa-level-0 tbody").append(h);
    }
}

function bookmarkedSearch(lat, lng, zoom1, group) {
    // console.log("bookmarkedSearch", lat, lng, zoom1, group);
    MAP_VAR.radius = radiusForZoom[zoom1];  // set global var
    MAP_VAR.zoom = parseInt(zoom1);
    $('select#radius').val(MAP_VAR.radius); // update drop-down widget
    if (group) speciesGroup = group;
    updateMarkerPosition(L.latLng(lat, lng));
    // load map and groups
    initialize();
}

//
function loadStateFromHash(encodedHash) {
    // update map state from URL hash
    // e.g. #-35.2512|149.1630|12|ALL_SPECIES
    var hashParts = encodedHash.split("%7C"); // note escaped version of |
    if (hashParts.length == 3) {
        bookmarkedSearch(hashParts[0], hashParts[1], hashParts[2], null);
    } else if (hashParts.length == 4) {
        bookmarkedSearch(hashParts[0], hashParts[1], hashParts[2], hashParts[3]);
    } else {
        attemptGeolocation();
    }
}

function getEncodedHash() {
    // hash coding: #lat|lng|zoom
    var hash = window.location.hash.replace( /^#/, '');
    var encodedHash;

    if (hash.indexOf("%7C") != -1) {
        // already escaped
        encodedHash = hash;
    } else {
        // escape used to prevent injection attacks
        encodedHash = encodeURIComponent(hash);
    }

    return encodedHash;
}