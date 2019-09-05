/*
 *  Copyright (C) 2014 Atlas of Living Australia
 *  All Rights Reserved.
 *
 *  The contents of this file are subject to the Mozilla Public
 *  License Version 1.1 (the "License"); you may not use this file
 *  except in compliance with the License. You may obtain a copy of
 *  the License at http://www.mozilla.org/MPL/
 *
 *  Software distributed under the License is distributed on an "AS
 *  IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 *  implied. See the License for the specific language governing
 *  rights and limitations under the License.
 */

/*  Common map (Leaflet) functions */

/**
 * Load Spring i18n messages into JS
 */
if (!(jQuery.i18n.properties && jQuery.i18n.properties.path) && typeof BC_CONF != 'undefined' && BC_CONF.hasOwnProperty('contextPath')) {
    //console.log("loading Query.i18n");
    jQuery.i18n.properties({
        name: 'messages',
        path: BC_CONF.contextPath + '/messages/i18n/',
        mode: 'map',
        async: true,
        cache: true,
        language: BC_CONF.locale // default is to use browser specified locale
        //callback: function(){} //alert( "facet.conservationStatus = " + jQuery.i18n.prop('facet.conservationStatus')); }
    });
}

// used to generate unique handler name for user drawn areas.
var areaCounter = 0;

function addClickEventForVector(layer) {
    var name = "drawnArea" + areaCounter;
    areaCounter++;

    MAP_VAR.map.addHandler(name, L.AreaPopupHandler.extend({layer: layer}));
    MAP_VAR.map[name].enable();
}

function removeLayer(leaflet_id) {
    if (MAP_VAR.map._layers[leaflet_id] !== undefined) {
        var layer = MAP_VAR.map._layers[leaflet_id];
        MAP_VAR.map.removeLayer(layer);
    }
}

L.AreaPopupHandler = L.Handler.extend({
    layer: null,

    addHooks: function() {
        L.DomEvent.on(this.layer, 'click', this._generatePopup, this);
    },

    removeHooks: function() {
        L.DomEvent.off(this.layer, 'click', this._generatePopup, this);
    },

    _generatePopup: function(e) {
        generatePopup(this.layer, e.latlng);
    }
});

L.PointClickHandler = L.Handler.extend({
    obj: null,

    addHooks: function() {
        L.DomEvent.on(this.obj, 'click', pointLookupClickRegister, this);
    },

    removeHooks: function() {
        L.DomEvent.off(this.obj, 'click', pointLookupClickRegister, this);
    }
});

/**
 * Fudge to allow double clicks to propagate to map while allowing single clicks to be registered
 *
 */
var clickCount = 0;
function pointLookupClickRegister(e) {
    // console.log('pointLookupClickRegister', clickCount);
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

function generatePopup(layer, latlng) {
    var params = "";
    if (jQuery.isFunction(layer.getRadius)) {
        // circle
        params = getParamsForCircle(layer);
    } else {
        var wkt = new Wkt.Wkt();
        wkt.fromObject(layer);
        params = getParamsforWKT(wkt.write());
    }

    if (latlng == null) {
        latlng = layer.getBounds().getCenter();
    }

    L.popup()
        .setLatLng([latlng.lat, latlng.lng])
        .setContent("species count: <b id='speciesCountDiv'>calculating...</b><br>" +
            "occurrence count: <b id='occurrenceCountDiv'>calculating...</b><br>" +
            "<a id='showOnlyTheseRecords' href='" + BC_CONF.contextPath + "/occurrences/search" +
            params + "'>" + jQuery.i18n.prop("search.map.popup.linkText") + "</a><br>" +
            "<a id='removeArea' href='javascript:void(0)' " +
            "onclick='removeLayer(\"" + layer._leaflet_id + "\");MAP_VAR.map.closePopup()'>" +
            jQuery.i18n.prop("search.map.popup.removeText") + "</a>")
        .openOn(MAP_VAR.map);

    getSpeciesCountInArea(params);
    getOccurrenceCountInArea(params);
}

function getSpeciesCountInArea(params) {
    speciesCount = -1;
    $.getJSON(BC_CONF.biocacheServiceUrl + "/occurrence/facets.json" + params + "&facets=taxon_name&callback=?",
        function( data ) {
            if (data && data.length > 0 && data[0].count !== undefined) {
                var speciesCount = data[0].count;
                document.getElementById("speciesCountDiv").innerHTML = speciesCount;
            } else {
                document.getElementById("speciesCountDiv").innerHTML = 0;
            }
        });
}

function getOccurrenceCountInArea(params) {
    occurrenceCount = -1;
    $.getJSON(BC_CONF.biocacheServiceUrl + "/occurrences/search.json" + params + "&pageSize=0&facet=off&callback=?",
        function( data ) {
            if (data && data.totalRecords !== undefined) {
                var occurrenceCount = data.totalRecords;
                document.getElementById("occurrenceCountDiv").innerHTML = occurrenceCount;

                if (occurrenceCount == "0") {
                    $("#showOnlyTheseRecords").hide()
                }
            } else {
                document.getElementById("occurrenceCountDiv").innerHTML = 0;
            }
        });
}

function getParamsforWKT(wkt) {
    return "?" + getExistingParams() + "&wkt=" + encodeURI(wkt.replace(" ", "+"));
}

function getParamsForCircle(circle) {
    var latlng = circle.getLatLng();
    var radius = Math.round((circle.getRadius() / 1000) * 10) / 10; // convert to km (from m) and round to 1 decmial place
    return "?" + getExistingParams() + "&radius=" + radius + "&lat=" + latlng.lat + "&lon=" + latlng.lng;
}

function getExistingParams() {
    var paramsObj = $.url(MAP_VAR.query).param();
    if (!paramsObj.q) {
        paramsObj.q = "*:*";
    }
    delete paramsObj.wkt;
    delete paramsObj.lat;
    delete paramsObj.lon;
    delete paramsObj.radius;
    var decoder = document.createElement("textarea");
    decoder.innerHTML = decodeURI(BC_CONF.queryContext);
    paramsObj.qc = decoder.value;
    //otherwise get context like "Isle of Man" as %26quot%3BIsle of Man%26quot%3B (encoded html entities), which never matches any records
    return $.param(paramsObj);
}

function drawWktObj(wktString) {
    var wkt = new Wkt.Wkt();
    wkt.read(wktString);
    var wktObject = wkt.toObject({color: '#bada55'});
    generatePopup(wktObject.getLayers()[0], null);
    addClickEventForVector(wktObject);
    MAP_VAR.drawnItems.addLayer(wktObject);

    if (wktObject.getBounds !== undefined && typeof wktObject.getBounds === 'function') {
        // For objects that have defined bounds or a way to get them
        MAP_VAR.map.fitBounds(wktObject.getBounds());
    } else {
        if (focus && wktObject.getLatLng !== undefined && typeof wktObject.getLatLng === 'function') {
            MAP_VAR.map.panTo(wktObject.getLatLng());
        }
    }
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
        timeout: 30000,
        data: {
            zoom: MAP_VAR.map.getZoom(),
            lat: e.latlng.wrap().lat,
            lon: e.latlng.wrap().lng,
            radius: radius,
            format: "json"
        },
        success: function(response) {
            MAP_VAR.map.spin(false);

            if (response.occurrences && response.occurrences.length > 0) {

                MAP_VAR.recordList = response.occurrences; // store the list of record uuids
                MAP_VAR.popupLatlng = e.latlng.wrap(); // store the coordinates of the mouse click for the popup

                // Load the first record details into popup
                insertRecordInfo(0);
            }
        },
        error: function(x, t, m) {
            MAP_VAR.map.spin(false);
        },

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
        $popupClone.find('.multiRecordHeader').removeClass('collapse');
        $popupClone.find('.currentRecord').html(recordIndex + 1);
        $popupClone.find('.totalrecords').html(MAP_VAR.recordList.length.toString().replace(/100/, '100+'));
        var occLookup = "&radius=" + MAP_VAR.popupRadius + "&lat=" + MAP_VAR.popupLatlng.lat + "&lon=" + MAP_VAR.popupLatlng.lng;
        $popupClone.find('a.viewAllRecords').attr('href', BC_CONF.contextPath + "/occurrences/search" + MAP_VAR.query.replace(/&(?:lat|lon|radius)\=[\-\.0-9]+/g, '') + MAP_VAR.removeFqs + occLookup);
        // populate popup footer
        $popupClone.find('.multiRecordFooter').removeClass('collapse');
        if (recordIndex < MAP_VAR.recordList.length - 1) {
            $popupClone.find('.nextRecord a').attr('onClick', 'insertRecordInfo('+(recordIndex + 1)+'); return false;');
            $popupClone.find('.nextRecord a').removeClass('disabled');
        }
        if (recordIndex > 0) {
            $popupClone.find('.previousRecord a').attr('onClick', 'insertRecordInfo('+(recordIndex - 1)+'); return false;');
            $popupClone.find('.previousRecord a').removeClass('disabled');
        }
    }

    $popupClone.find('.recordLink a').attr('href', BC_CONF.contextPath + "/occurrences/" + recordUuid);
    // Get the current record details
    $.ajax({
        url: MAP_VAR.mappingUrl + "/occurrences/" + recordUuid + ".json",
        success: function(record) {
            MAP_VAR.map.spin(false);

            if (record.raw) {
                var displayHtml = formatPopupHtml(record);
                $popupClone.find('.recordSummary').html( displayHtml ); // insert into clone
            } else {
                // missing record - disable "view record" button and display message
                $popupClone.find('.recordLink a').attr('disabled', true).attr('href','javascript: void(0)');
                $popupClone.find('.recordSummary').html( "<br>" + jQuery.i18n.prop("search.recordNotFoundForId") + ": <span style='white-space:nowrap;'>" + recordUuid + '</span><br><br>' ); // insert into clone
            }

            MAP_VAR.popup.setContent($popupClone.html()); // push HTML into popup content
            MAP_VAR.popup.openOn(MAP_VAR.map);
        },
        error: function() {
            MAP_VAR.map.spin(false);
        }
    });

}

function formatPopupHtml(record) {
    var displayHtml = "";

    // catalogNumber
    if (record.raw.occurrence.catalogNumber != null) {
        displayHtml += jQuery.i18n.prop('record.catalogNumber.label') + ": " + record.raw.occurrence.catalogNumber + '<br />';
    } else if (record.processed.occurrence.catalogNumber != null) {
        displayHtml += jQuery.i18n.prop('record.catalogNumber.label') + ": " + record.processed.occurrence.catalogNumber + '<br />';
    }

    // record or field number
    if (record.raw.occurrence.recordNumber != null) {
        displayHtml += jQuery.i18n.prop('record.recordNumber.label') + ": " + record.raw.occurrence.recordNumber + '<br />';
    } else if (record.raw.occurrence.fieldNumber != null) {
        displayHtml += jQuery.i18n.prop('record.fieldNumber.label') + ": " + record.raw.occurrence.fieldNumber + '<br />';
    }

    // institution or dataset name
    if (record.processed.attribution.institutionName != null) {
        displayHtml += jQuery.i18n.prop('record.institutionName.label') + ": " + record.processed.attribution.institutionName + '<br />';
    } else if (record.processed.attribution.dataResourceName != null) {
        displayHtml += jQuery.i18n.prop('record.dataResourceName.label') + ": " + record.processed.attribution.dataResourceName + '<br />';
    }

    // collection name
    if (record.processed.attribution.collectionName != null) {
        displayHtml += jQuery.i18n.prop('record.collectionName.label') + ": " + record.processed.attribution.collectionName + '<br />';
    }

    // common name
    if (record.raw.classification.vernacularName != null) {
        displayHtml += record.raw.classification.vernacularName + '<br />';
    } else if (record.processed.classification.vernacularName != null) {
        displayHtml += record.processed.classification.vernacularName + '<br />';
    }

    // scientific name
    if (record.processed.classification.scientificName) {
        displayHtml += formatSciName(record.processed.classification.scientificName, record.processed.classification.taxonRankID) + '<br />';
    } else {
        displayHtml += record.raw.classification.scientificName + '<br />';
    }

    if (record.raw.occurrence.recordedBy != null) {
        displayHtml += jQuery.i18n.prop('record.recordedBy.label') + ": " + record.raw.occurrence.recordedBy + '<br />';
    } else if (record.processed.occurrence.recordedBy != null) {
        displayHtml += jQuery.i18n.prop('record.recordedBy.label') + ": " + record.processed.occurrence.recordedBy + '<br />';
    }

    if (record.processed.event.eventDate != null) {
        //displayHtml += "<br/>";
        var label = jQuery.i18n.prop('record.eventDate.label') + ": ";
        displayHtml += label + record.processed.event.eventDate;
    }

    return displayHtml;
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
