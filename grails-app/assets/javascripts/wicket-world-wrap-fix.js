/**
 * Override wicket and wicket-leaflet to split polygons across -180 or +180
 */

L.Util.extend(Wkt.Wkt.prototype.construct, {

    multipolygon: function (config) {
        // Truncate the coordinates to remove the closing coordinate
        var coords = this.trunc(this.components),
            latlngs = this.coordsToLatLngs(coords, 2);

        //translate by x if requested
        if (config && config.translate && config.translate.x) {
            var copy = Wkt.copyLatLngs(latlngs, config.translate.x);
            return L.multiPolygon(copy, config);
        } else {
            return L.multiPolygon(latlngs, config);
        }
    },

    polygon: function (config) {
        // Truncate the coordinates to remove the closing coordinate
        var coords = this.trunc(this.components),
            latlngs = this.coordsToLatLngs(coords, 1);

        // latlngs is always a multipolygon

        // translate by x if requested
        if (config && config.translate && config.translate.x) {
            var copy = Wkt.copyLatLngs(latlngs, config.translate.x);
            return L.multiPolygon(copy, config);
        } else {
            return L.multiPolygon(latlngs, config);
        }
    },


});

Wkt.Wkt.prototype.deconstruct = function (obj) {
        var attr, coordsFromLatLngs, features, i, verts, rings, tmp;

        /**
         * Accepts an Array (arr) of LatLngs from which it extracts each one as a
         *  vertex; calls itself recursively to deal with nested Arrays.
         */
        coordsFromLatLngs = function (arr) {
            var i, coords;

            coords = [];
            for (i = 0; i < arr.length; i += 1) {
                if (Wkt.isArray(arr[i])) {
                    var multi_coords = coordsFromLatLngs(arr[i]);
                    for (var j = 0; j < multi_coords.length; j += 1) {
                        if (multi_coords.hasOwnProperty(j)) {
                            coords.push(multi_coords[j]);
                        }
                    }
                } else {
                    if (arr[i].lng) {
                        coords.push({
                            x: arr[i].lng,
                            y: arr[i].lat
                        });
                    } else {
                        coords.push({
                            x: arr[i].x,
                            y: arr[i].y
                        });
                    }
                }
            }

            return Wkt.wrap(coords);
        };

        // L.Marker ////////////////////////////////////////////////////////////////
        if (obj.constructor === L.Marker || obj.constructor === L.marker) {
            return {
                type: 'point',
                components: [{
                    x: obj.getLatLng().lng,
                    y: obj.getLatLng().lat
                }]
            };
        }

        // L.Rectangle /////////////////////////////////////////////////////////////
        if (obj.constructor === L.Rectangle || obj.constructor === L.rectangle) {
            tmp = obj.getBounds(); // L.LatLngBounds instance
            return {
                // always return a multipolygon in case bounds cross -180 or +180.
                type: 'multipolygon',
                components: Wkt.wrap([
                    [
                        { // NW corner
                            x: tmp.getSouthWest().lng,
                            y: tmp.getNorthEast().lat
                        },
                        { // SW corner
                            x: tmp.getSouthWest().lng,
                            y: tmp.getSouthWest().lat
                        },
                        { // SE corner
                            x: tmp.getNorthEast().lng,
                            y: tmp.getSouthWest().lat
                        },
                        { // NE corner
                            x: tmp.getNorthEast().lng,
                            y: tmp.getNorthEast().lat
                        },
                        { // NW corner (again, for closure)
                            x: tmp.getSouthWest().lng,
                            y: tmp.getNorthEast().lat
                        }
                    ]
                ])
            };

        }

        // L.Polyline //////////////////////////////////////////////////////////////
        if (obj.constructor === L.Polyline || obj.constructor === L.polyline) {
            verts = [];
            tmp = obj.getLatLngs();

            if (!tmp[0].equals(tmp[tmp.length - 1])) {

                for (i = 0; i < tmp.length; i += 1) {
                    verts.push({
                        x: tmp[i].lng,
                        y: tmp[i].lat
                    });
                }

                return {
                    type: 'linestring',
                    components: verts
                };

            }
        }

        // L.Polygon ///////////////////////////////////////////////////////////////

        if (obj.constructor === L.Polygon || obj.constructor === L.polygon) {
            rings = [];
            verts = [];
            tmp = obj.getLatLngs();

            // First, we deal with the boundary points
            for (i = 0; i < obj._latlngs.length; i += 1) {
                verts.push({ // Add the first coordinate again for closure
                    x: tmp[i].lng,
                    y: tmp[i].lat
                });
            }

            verts.push({ // Add the first coordinate again for closure
                x: tmp[0].lng,
                y: tmp[0].lat
            });

            var multi_coords = coordsFromLatLngs(verts);
            for (var j = 0; j < multi_coords.length; j += 1) {
                if (multi_coords.hasOwnProperty(j)) {
                    rings.push(multi_coords[j]);
                }
            }

            // Now, any holes
            if (obj._holes && obj._holes.length > 0) {
                // Reworked to support holes properly
                var multi_coords = coordsFromLatLngs(obj._holes);
                for (var j = 0; j < multi_coords.length; j += 1) {
                    if (multi_coords.hasOwnProperty(j)) {
                        var verts = multi_coords[j];
                        for (i = 0; i < verts.length; i++) {
                            verts[i].push(verts[i][0]); // Copy the beginning coords again for closure

                            //push interior ring to the appropriate exterior ring
                            for (var k = 0; k < rings.length; k++) {
                                if (rings[k].getBounds().intersects(verts[i].getBounds())) {
                                    rings[k].push(verts[i]);
                                }
                            }
                        }
                    }
                }
            }

            return {
                type: 'multipolygon',
                components: rings
            };

        }

        // L.MultiPolyline /////////////////////////////////////////////////////////
        // L.MultiPolygon //////////////////////////////////////////////////////////
        // L.LayerGroup ////////////////////////////////////////////////////////////
        // L.FeatureGroup //////////////////////////////////////////////////////////
        if (obj.constructor === L.MultiPolyline || obj.constructor === L.MultiPolygon
            || obj.constructor === L.LayerGroup || obj.constructor === L.FeatureGroup) {

            features = [];
            tmp = obj._layers;

            for (attr in tmp) {
                if (tmp.hasOwnProperty(attr)) {
                    if (tmp[attr].getLatLngs || tmp[attr].getLatLng) {
                        // Recursively deconstruct each layer
                        features.push(this.deconstruct(tmp[attr]));
                    }
                }
            }

            return {

                type: (function () {
                    switch (obj.constructor) {
                        case L.MultiPolyline:
                            return 'multilinestring';
                        case L.MultiPolygon:
                            return 'multipolygon';
                        case L.FeatureGroup:
                            return (function () {
                                var i, mpgon, mpline, mpoint;

                                // Assume that all layers are of one type (any one type)
                                mpgon = true;
                                mpline = true;
                                mpoint = true;

                                for (i in obj._layers) {
                                    if (obj._layers.hasOwnProperty(i)) {
                                        if (obj._layers[i].constructor !== L.Marker) {
                                            mpoint = false;
                                        }
                                        if (obj._layers[i].constructor !== L.Polyline) {
                                            mpline = false;
                                        }
                                        if (obj._layers[i].constructor !== L.Polygon) {
                                            mpgon = false;
                                        }
                                    }
                                }

                                if (mpoint) {
                                    return 'multipoint';
                                }
                                if (mpline) {
                                    return 'multilinestring';
                                }
                                if (mpgon) {
                                    return 'multipolygon';
                                }
                                return 'geometrycollection';

                            }());
                        default:
                            return 'geometrycollection';
                    }
                }()),

                components: (function () {
                    // Pluck the components from each Wkt
                    var i, comps;

                    comps = [];
                    for (i = 0; i < features.length; i += 1) {
                        if (features[i].components) {
                            comps.push(features[i].components);
                        }
                    }

                    return comps;
                }())

            };

        }

        // L.Circle ////////////////////////////////////////////////////////////////
        if (obj.constructor === L.Rectangle || obj.constructor === L.rectangle) {
            console.log('Deconstruction of L.Circle objects is not yet supported');

        } else {
            console.log('The passed object does not have any recognizable properties.');
        }
    };

L.Util.extend(Wkt, {
    // deep copy latlngs nested arrays
    copyLatLngs: function (obj, x, y) {
        if (obj instanceof L.LatLng) {
            if (!y) y = 0;
            if (!x) x = 0;
            return new L.LatLng(obj.lat + y, obj.lng + x)
        } else {
            var copy = [];
            for (var i = 0; i < obj.length; i++) {
                copy.push(this.copyLatLngs(obj[i], x, y));
            }
            return copy;
        }
    },
    _addSplitPoint: function (rings, edge, last_pt, pt, last_region, region, slope, y) {
        if (edge.x <= Math.max(last_pt.x, pt.x) && edge.x >= Math.min(last_pt.x, pt.x)) {
            var ym = slope * edge.x + y;
            var latlng = MAP_VAR.map.containerPointToLatLng(new L.Point(edge.x, ym));

            var lastRing = rings[last_region + 1][rings[last_region + 1].length - 1];
            lastRing.push({x: latlng.lng, y: latlng.lat});

            // add new ring when the current ring is finished.
            if (lastRing[0].x == latlng.lng) {
                rings[last_region + 1].push([])
            }

            var nextRing = rings[region + 1][rings[region + 1].length - 1];
            nextRing.push({x: latlng.lng, y: latlng.lat});

        }
    },

    _isOutOfRange: function (coords) {
        var below = false;
        var above = false;
        for (var i = coords.length - 1; i >= 0; i--) {
            var ring = coords[i];
            for (j in ring) {
                if (ring.hasOwnProperty(j)) {
                    if (ring[j].x < -180) {
                        below = true;
                    }
                    if (ring[j].x > 180) {
                        above = true;
                    }
                }
            }
        }

        return below || above;
    },

    _buildMultiPolygonFromWrapRings: function (rings) {
        var multipolygon = [];
        for (var r = 0; r < rings.length; r++) {
            var groups = rings[r];
            for (var g = 0; g < groups.length; g++) {
                var coords = groups[g];
                var ring = [];
                for (var i = 0; i < coords.length; i++) {
                    while (coords[i].x < -180) {
                        coords[i].x += 360;
                    }
                    while (coords[i].x > 180) {
                        coords[i].x -= 360;
                    }
                    //correct lower bound of > +180 ring
                    if (r == 2 && coords[i].x == 180) {
                        coords[i].x = -180;
                    }
                    //correct upper bound of < -180 ring
                    if (r == 0 && coords[i].x == -180) {
                        coords[i].x = 180;
                    }
                    ring.push(coords[i])
                }

                if (ring.length > 0) {
                    //close open rings
                    if (ring[0].x != ring[ring.length - 1].x || ring[0].y != ring[ring.length - 1].y) {
                        ring.push(ring[0]);
                    }
                    multipolygon.push([ring]);
                }
            }
        }

        return multipolygon;
    },

    _addWrapPointToRings: function (current, last_pt, pt, last_region, region, rings) {
        // if the region has changed, split the ring along -180 and +180
        if (last_region != -2 && last_region != region) {
            var slope = (pt.y - last_pt.y) / (pt.x - last_pt.x);
            var y = pt.y - pt.x * slope;

            this._addSplitPoint(rings, this.wrap_minus, last_pt, pt, last_region, region, slope, y);
            this._addSplitPoint(rings, this.wrap_plus, last_pt, pt, last_region, region, slope, y);
        }

        rings[region + 1][rings[region + 1].length - 1].push(current);
    },

    /**
     * Split polygons that cross longitude -180 or +180 into multipolygons.
     *
     * @param obj
     */
    wrap: function (coords) {

        if (!(coords[0] instanceof Array)) {
            coords = [coords];
        }

        // only need to split when there is a point < -180 or > 180
        if (this._isOutOfRange(coords)) {
            this.wrap_minus = MAP_VAR.map.latLngToContainerPoint(new L.LatLng(-90, -180));
            this.wrap_plus = MAP_VAR.map.latLngToContainerPoint(new L.LatLng(90, 180));

            var rings = [[[]], [[]], [[]]];

            var region = 0;
            var last_region = -2;
            var last_pt = {};
            for (i in coords) {
                if (coords.hasOwnProperty(i)) {
                    var ring = coords[i];
                    for (j in ring) {
                        if (ring.hasOwnProperty(j)) {
                            //convert to pixel for intersection test
                            var pt = MAP_VAR.map.latLngToContainerPoint(new L.LatLng(ring[j].y, ring[j].x));

                            if (pt.x < this.wrap_minus.x) region = -1;
                            else if (pt.x > this.wrap_plus.x) region = 1;
                            else region = 0;

                            this._addWrapPointToRings(ring[j], last_pt, pt, last_region, region, rings);

                            last_region = region;
                            last_pt = pt;
                        }
                    }
                }
            }

            return this._buildMultiPolygonFromWrapRings(rings);
        } else {
            return [coords];
        }
    }
});