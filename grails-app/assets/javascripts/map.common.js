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
    paramsObj.qc = BC_CONF.queryContext;
    return $.param(paramsObj);
}

function drawWktObj(wktString) {
    var wkt = new Wkt.Wkt();
    wkt.read(wktString);
    var wktObject = wkt.toObject({color: '#bada55'});
    generatePopup(wktObject,null);
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