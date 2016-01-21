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

// Note there are some global variables that are set by the calling page (which has access to
// the ${pageContet} object, which are required by this file.:
//
//var EYA_CONF = {
//    contextPath: "${pageContext.request.contextPath}",
//    biocacheServiceUrl: "${biocacheServiceUrl}",
//    zoom: ${zoom},
//    radius: ${radius},
//    speciesPageUrl: "${speciesPageUrl}",
//    queryContext: ""
//}

var geocoder, map, marker, circle, markerInfowindow, lastInfoWindow, taxon, taxonGuid;
var points = [], infoWindows = [], speciesGroup = "ALL_SPECIES";
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

// Load Google maps via AJAX API
google.load("maps", "3.3", {other_params:"sensor=false"});

/**
 * Document onLoad event using JQuery
 */
$(document).ready(function() {
    // initialise Google Geocoder
    geocoder = new google.maps.Geocoder();

    // Catch page events...
    
    // Register events for the species_group column
    $('#taxa-level-0 tbody tr').live("mouseover mouseout", function() {
        // mouse hover on groups
        if ( event.type == "mouseover" ) {
            $(this).addClass('hoverRow');
        } else {
            $(this).removeClass('hoverRow');
        }
    }).live("click", function(e) {
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
            EYA_CONF.radius = parseInt($(this).val());
            var radiusInMetres = EYA_CONF.radius * 1000;
            circle.setRadius(radiusInMetres);
            EYA_CONF.zoom = zoomForRadius[radiusInMetres];
            map.setZoom((EYA_CONF.zoom)?EYA_CONF.zoom:12);
            updateMarkerPosition(marker.getPosition()); // so bookmarks is updated
            //loadRecordsLayer();
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
    // hash coding: #lat|lng|zoom
    var hash = window.location.hash.replace( /^#/, '');
    var hash2;
    var defaultParam = $.url().param('default'); // requires JS import: purl.js
    //console.log("defaultParam", defaultParam);

    if (hash.indexOf("%7C") != -1) {
        // already escaped
        hash2 = hash;
    } else {
        // escape used to prevent injection attacks
        hash2 = encodeURIComponent(hash);
    }

    if (defaultParam) {
        initialize();
    } else if (hash2) {
        //console.log("url hash", hash2);
        var hashParts = hash2.split("%7C"); // note escaped version of |
        if (hashParts.length == 3) {
            bookmarkedSearch(hashParts[0], hashParts[1], hashParts[2], null);
        } else if (hashParts.length == 4) {
            bookmarkedSearch(hashParts[0], hashParts[1], hashParts[2], hashParts[3]);
        } else {
            attemptGeolocation();
        }
    } else {
        //console.log("url not set, geolocating...");
        attemptGeolocation();
    }


    // catch the link for "View all records"
    $('#viewAllRecords').live("click", function(e) {
        e.preventDefault();
        //var params = "q=taxon_name:*|"+$('#latitude').val()+"|"+$('#longitude').val()+"|"+$('#radius').val();
        var params = "q=*:*&lat="+$('#latitude').val()+"&lon="+$('#longitude').val()+"&radius="+$('#radius').val();
        if (speciesGroup != "ALL_SPECIES") {
            params += "&fq=species_group:" + speciesGroup;
        }
        document.location.href = EYA_CONF.contextPath +'/occurrences/search?' + params;
    });

    // Tooltip for matched location
    $('#addressHelp').qtip({
        content: {
            title: {
                text: "About the matched address",
                button: "Close"
            },
            text: "<img src=\"" + EYA_CONF.imagesUrlPrefix + "/spinner.gif\" alt=\"\" class=\"no-rounding\"/>",
            ajax: {
                url: EYA_CONF.contextPath + "/proxy/wordpress", // TODO fix proxy
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
    loadMap();
    loadGroups();
}
/**
 * Google map API v3
 */
function loadMap() {
    var latLng = new google.maps.LatLng($('#latitude').val(), $('#longitude').val());
    map = new google.maps.Map(document.getElementById('mapCanvas'), {
        zoom: EYA_CONF.zoom,
        center: latLng,
        scrollwheel: false,
        streetViewControl: true,
        mapTypeControl: true,
        mapTypeControlOptions: {
            style: google.maps.MapTypeControlStyle.DROPDOWN_MENU
        },
        navigationControl: true,
        navigationControlOptions: {
            style: google.maps.NavigationControlStyle.SMALL // DEFAULT
        },
        mapTypeId: google.maps.MapTypeId.HYBRID
    });
    marker = new google.maps.Marker({
        position: latLng,
        title: 'Marker Location',
        map: map,
        draggable: true
    });

    markerInfowindow = new google.maps.InfoWindow({
        content: '<div class="infoWindow">marker address</div>' // gets updated by geocodePosition()
    });
    
    google.maps.event.addListener(marker, 'click', function(event) {
        if (lastInfoWindow) lastInfoWindow.close();
        markerInfowindow.setPosition(event.latLng);
        markerInfowindow.open(map, marker);
        lastInfoWindow = markerInfowindow;
    });

    // Add a Circle overlay to the map.
    var radius = parseInt($('select#radius').val()) * 1010;
    circle = new google.maps.Circle({
        map: map,
        radius: radius,
        strokeWeight: 1,
        strokeColor: 'white',
        strokeOpacity: 0.5,
        fillColor: '#222', // '#2C48A6'
        fillOpacity: 0.2,
        zIndex: -10
    });
    // bind circle to marker
    circle.bindTo('center', marker, 'position');

    // Update current position info.
    //updateMarkerPosition(latLng);
    geocodePosition(latLng);

    // Add dragging event listeners.
    google.maps.event.addListener(marker, 'dragstart', function() {
        updateMarkerAddress('Dragging...');
    });

    google.maps.event.addListener(marker, 'drag', function() {
        updateMarkerAddress('Dragging...');
        //updateMarkerPosition(marker.getPosition());
    });

    google.maps.event.addListener(marker, 'dragend', function() {
        updateMarkerAddress('Drag ended');
        updateMarkerPosition(marker.getPosition());
        geocodePosition(marker.getPosition());
        //LoadTaxaGroupCounts();
        loadGroups();
        map.panTo(marker.getPosition());
    });
    
    google.maps.event.addListener(map, 'zoom_changed', function() {
        loadRecordsLayer();
    });
    
    if (!points || points.length == 0) {
        //$('#taxa-level-0 tbody td:first').click(); // click on "all species" group
        loadRecordsLayer();
    }
}

/**
 * Google geocode function
 */
function geocodePosition(pos) {
    geocoder.geocode({
        latLng: pos
    }, function(responses) {
        if (responses && responses.length > 0) {
            //console.log("geocoded position", responses[0]);
            var address = responses[0].formatted_address;
            updateMarkerAddress(address);
            // update the info window for marker icon
            var content = '<div class="infoWindow"><b>Your Location:</b><br/>'+address+'</div>';
            markerInfowindow.setContent(content);
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
    $('#latitude').val(latLng.lat());
    $('#longitude').val(latLng.lng());
    // Update URL hash for back button, etc
    location.hash = latLng.lat() + "|" + latLng.lng() + "|" + EYA_CONF.zoom + "|" + speciesGroup;
    $('#dialog-confirm #rad').html(EYA_CONF.radius);
}

/**
 * Load (reload) geoJSON data into vector layer
 */
function loadRecordsLayer(retry) {
    if (!map && !retry) {
        // in case AJAX calls this function before map has initialised
        setTimeout(function() {if (!points || points.length == 0) {loadRecordsLayer(true)}}, 2000);
        //console.log('retry triggered');
        return;
    } else if (!map) {
        //console.log('retry failed');
        return;
    }

    // URL for GeoJSON web service
    var geoJsonUrl = EYA_CONF.biocacheServiceUrl + "/geojson/radius-points.jsonp?callback=?";
    var zoom = (map && map.getZoom()) ? map.getZoom() : 12;
    // request params for ajax geojson call
    var params = {
        lat: $('#latitude').val(),
        lon: $('#longitude').val(),
        radius: $('#radius').val(),
        fq: "geospatial_kosher:true",
        qc: EYA_CONF.queryContext,
        zoom: zoom
    };
    if (taxon) {
        params.q = "taxon_name:\"" + taxon + "\"";
    } else {
        params.group = speciesGroup;
    }
    //console.log('About to call $.get', map);
    // JQuery AJAX call
    $.getJSON(geoJsonUrl, params, loadNewGeoJsonData);
}

/**
 * Callback for geoJSON ajax call
 */
function loadNewGeoJsonData(data) {
    // clear vector featers and popups
    if (points && points.length > 0) {
        $.each(points, function (i, p) {
            p.setMap(null); // remove from map
        });
        points = [];
    } else {
        points = [];
    }

    if (infoWindows && infoWindows.length > 0) {
        $.each(infoWindows, function (i, n) {
            n.close(); // close any open popups
        });
        infoWindows = [];
    } else {
        infoWindows = [];
    }
    
    $.each(data.features, function (i, n) {
        var latLng1 = new google.maps.LatLng(n.geometry.coordinates[1], n.geometry.coordinates[0]);
        var iconUrl = EYA_CONF.imagesUrlPrefix+"/circle-"+n.properties.color.replace('#','')+".png";
        var markerImage = new google.maps.MarkerImage(iconUrl,
            new google.maps.Size(9, 9),
            new google.maps.Point(0,0),
            new google.maps.Point(4, 5)
        );
        points[i] = new google.maps.Marker({
            map: map,
            position: latLng1,
            title: n.properties.count+" occurrences",
            icon: markerImage
        });

        var solrQuery;
        if ($.inArray("|", taxa) > 0) {
            var parts = taxa.split("|");
            var newParts = [];
            for (j in parts) {
                newParts.push(rank+":"+parts[j]);
            }
            solrQuery = newParts.join(" OR ");
        } else {
            solrQuery = "*:*"; //rank+':'+taxa;
        }
        var fqParam = "";
        if (taxonGuid) {
            fqParam = "&fq=species_guid:" + taxonGuid;
        } else if (speciesGroup != "ALL_SPECIES") {
            fqParam = "&fq=species_group:" + speciesGroup;
        }
        
        var content = '<div class="infoWindow">Number of records: '+n.properties.count+'<br/>'+
                '<a href="'+ EYA_CONF.contextPath +'/occurrences/search?q='+solrQuery+fqParam+
                '&lat='+n.geometry.coordinates[1]+'&lon='+n.geometry.coordinates[0]+'&radius=0.05">View list of records</a></div>';
        infoWindows[i] = new google.maps.InfoWindow({
            content: content,
            maxWidth: 200,
            disableAutoPan: false
        });
        google.maps.event.addListener(points[i], 'click', function(event) {
            if (lastInfoWindow) lastInfoWindow.close(); // close any previously opened infoWindow
            infoWindows[i].setPosition(event.latLng);
            infoWindows[i].open(map, points[i]);
            lastInfoWindow = infoWindows[i]; // keep reference to current infoWindow
        });
    });
    
}

/**
 * Try to get a lat/long using HTML5 geoloation API
 */
function attemptGeolocation() {
    // HTML5 GeoLocation
    if (navigator && navigator.geolocation) {
        //console.log("trying to get coords with navigator.geolocation...");  
        function getMyPostion(position) {  
            //alert('coords: '+position.coords.latitude+','+position.coords.longitude);
            //console.log('geolocation request accepted');
            $('#mapCanvas').empty();
            updateMarkerPosition(new google.maps.LatLng(position.coords.latitude, position.coords.longitude));
            //LoadTaxaGroupCounts();
            initialize();
        }
        
        function positionWasDeclined() {
            //console.log('geolocation request declined or errored');
            $('#mapCanvas').empty();
            //zoom = 12;
            //alert('latitude = '+$('#latitude').val());
            updateMarkerPosition(new google.maps.LatLng($('#latitude').val(), $('#longitude').val()));
            //LoadTaxaGroupCounts();
            initialize();
        }
        // Add message to browser - FF needs this as it is not easy to see
        var msg = 'Waiting for confirmation to use your current location (see browser message at top of window)'+
            '<br/><a href="#" onClick="loadMap(); return false;">Click here to load map</a>';
        $('#mapCanvas').html(msg).css('color','red').css('font-size','14px');
        navigator.geolocation.getCurrentPosition(getMyPostion, positionWasDeclined);
        //console.log("line after navigator.geolocation.getCurrentPosition...");  
        // Neither functions gets called for some reason, so I've added a delay to initalize map anyway
        setTimeout(function() {if (!map) positionWasDeclined();}, 9000);
    } else if (google.loader && google.loader.ClientLocation) {
        // Google AJAX API fallback GeoLocation
        //alert("getting coords using google geolocation");
        updateMarkerPosition(new google.maps.LatLng(google.loader.ClientLocation.latitude, google.loader.ClientLocation.longitude));
        //LoadTaxaGroupCounts();
        initialize();
    } else {
        //alert("Client geolocation failed");
        //geocodeAddress();
        EYA_CONF.zoom = 12;
        initialize();
    }
}

/**
 * Reverse geocode coordinates via Google Maps API
 */
function geocodeAddress(reverseGeocode) {
    var address = $('input#address').val();
    var latLng = null;

    // Check if input contains a comma and try and patch coordinates
    if (address && address.indexOf(",") > -1 && magellan) {
        var parts = address.split(",");
        var lat = magellan(parts[0].trim()).latitude(); //.toDD();
        var lng = magellan(parts[1].trim()).longitude(); //.toDD();
        //console.log("magellan", parts, lat, lng);

        if (lat && lng) {
            latLng = new google.maps.LatLng(lat.toDD(), lng.toDD());
            updateMarkerAddress("GPS corrdinates: " + lat.toDD() + ", " + lng.toDD());
            updateMarkerPosition(latLng);
            // reload map pin, etc
            initialize();
            loadRecordsLayer();
        }

    }

    if (!latLng && geocoder && address) {
        //geocoder.getLocations(address, addAddressToPage);
        geocoder.geocode( {'address': address, region: 'AU'}, function(results, status) {
            if (status == google.maps.GeocoderStatus.OK) {
                // geocode was successful
                //console.log('geocodeAddress results', results);
                updateMarkerAddress(results[0].formatted_address);
                updateMarkerPosition(results[0].geometry.location);
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
        updateMarkerPosition(new google.maps.LatLng(lat, lon));
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

    if (map) loadRecordsLayer();
    // AJAX...
    var uri = EYA_CONF.biocacheServiceUrl + "/explore/group/"+speciesGroup+".json?callback=?";
    var params = {
        lat: $('#latitude').val(),
        lon: $('#longitude').val(),
        radius: $('#radius').val(),
        fq: "geospatial_kosher:true",
        qc: EYA_CONF.queryContext,
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
                tr = tr + ' : '+data[i].commonName+'';
            }
            // add links to species page and ocurrence search (inside hidden div)
            var speciesInfo = '<div class="speciesInfo">';
            if (data[i].guid) {
                speciesInfo = speciesInfo + '<a title="'+infoTitle+'" href="'+EYA_CONF.speciesPageUrl + data[i].guid+
                    '"><img src="'+ EYA_CONF.imagesUrlPrefix + '/page_white_go.png" alt="species page icon" style="margin-bottom:-3px;" class="no-rounding"/>'+
                    ' species profile</a> | ';
            }
            speciesInfo = speciesInfo + '<a href="'+ EYA_CONF.contextPath +'/occurrences/search?q=taxon_name:%22'+data[i].name+
                    '%22&lat='+$('input#latitude').val()+'&lon='+$('input#longitude').val()+'&radius='+$('select#radius').val()+'" title="'+
                    recsTitle+'"><img src="'+ EYA_CONF.imagesUrlPrefix + '/database_go.png" '+
                    'alt="search list icon" style="margin-bottom:-3px;" class="no-rounding"/> list of records</a></div>';
            tr = tr + speciesInfo;
            // add number of records
            tr = tr + '</td><td class="rightCounts">'+data[i].count+' </td></tr>';
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
            var uri = EYA_CONF.biocacheServiceUrl + "/explore/group/"+speciesGroup+".json?callback=?";
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
                qc: EYA_CONF.queryContext
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
 * Perform normal spatial searcj for spceies groups and species counts
 */
function loadGroups() {
    var url = EYA_CONF.biocacheServiceUrl +"/explore/groups.json?callback=?";
    var params = {
        //"group": $(this).attr('title'),
        lat: $('#latitude').val(),
        lon: $('#longitude').val(),
        radius: $('#radius').val(),
        fq: "geospatial_kosher:true",
        facets: "species_group",
        qc: EYA_CONF.queryContext
    }
    
    $.getJSON(url, params, function(data) {
        if (data) {
            populateSpeciesGroups(data);
        }
    });
}

/*
 * Populate the spceies group column (via callback from AJAX)
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
        if (group == "ALL_SPECIES") label = "All Species";
        var rc = (group == speciesGroup) ? " class='activeRow'" : ""; // highlight active group
        var h = "<tr"+rc+" title='click to view group on map'><td class='indent"+indent+"'><a href='#' id='"+group+"' class='taxonBrowse' title='click to view group on map'>"+label+"</a></td><td>"+count+"</td></tr>";
        $("#taxa-level-0 tbody").append(h);
    }
}

function bookmarkedSearch(lat, lng, zoom1, group) {
    EYA_CONF.radius = radiusForZoom[zoom1];  // set global var
    EYA_CONF.zoom = parseInt(zoom1);
    $('select#radius').val(EYA_CONF.radius); // update drop-down widget
    if (group) speciesGroup = group;
    updateMarkerPosition(new google.maps.LatLng(lat, lng));
    // load map and groups
    initialize();
}
