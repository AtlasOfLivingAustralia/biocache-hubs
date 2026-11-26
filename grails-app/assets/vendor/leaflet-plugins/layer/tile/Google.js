/*
 * Leaflet drop-in replacement for the legacy L.Google layer.
 *
 * Purpose:
 *   Keeps existing calls such as:
 *       new L.Google('ROADMAP')
 *       new L.Google('TERRAIN')
 *       new L.Google('HYBRID')
 *       new L.Google('SATELLITE')
 *   working, but uses OpenStreetMap-compatible raster tile services
 *   instead of the Google Maps JavaScript API.
 *
 * Important:
 *   This is not pixel-for-pixel identical to Google Maps imagery.
 *   "ROADMAP" uses OpenStreetMap, "TERRAIN" uses OpenTopoMap, and
 *   "SATELLITE"/"HYBRID" use Esri World Imagery.
 *
 * Usage:
 *   <script src="leaflet.js"></script>
 *   <script src="L.Google.OSM.js"></script>
 *
 *   var road = new L.Google('ROADMAP');
 *   map.addLayer(road);
 */

(function (L) {
	'use strict';

	if (!L) {
		throw new Error('Leaflet must be loaded before L.Google.OSM.js');
	}

	var TILE_PROVIDERS = {
		ROADMAP: {
			url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
			options: {
				maxZoom: 19,
				subdomains: 'abc',
				attribution:
					'&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
			}
		},

		TERRAIN: {
			url: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
			options: {
				maxZoom: 17,
				subdomains: 'abc',
				attribution:
					'Map data: &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, SRTM | Style: &copy; <a href="https://opentopomap.org">OpenTopoMap</a>'
			}
		},

		SATELLITE: {
			url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
			options: {
				maxZoom: 19,
				attribution: 'Tiles &copy; Esri'
			}
		},

		// Preserved for compatibility with the old Google layer API.
		// A true satellite-and-labels hybrid is not available from OSM itself;
		// Esri imagery is used here.
		HYBRID: {
			url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
			options: {
				maxZoom: 19,
				attribution: 'Tiles &copy; Esri'
			}
		}
	};

	function GoogleCompatibleLayer(type, options) {
		var normalizedType = String(type || 'SATELLITE').toUpperCase();
		var provider = TILE_PROVIDERS[normalizedType] || TILE_PROVIDERS.ROADMAP;

		var layerOptions = L.Util.extend({}, provider.options, options || {});

		var layer = L.tileLayer(provider.url, layerOptions);

		// Store the requested legacy type for debugging / feature detection.
		layer._googleType = normalizedType;

		return layer;
	}

	// Legacy-compatible constructor.
	L.Google = GoogleCompatibleLayer;

	// Some old code may call L.Google.asyncInitialize() after loading Google Maps.
	// Keep it as a no-op so legacy integration code does not fail.
	L.Google.asyncWait = [];
	L.Google.asyncInitialize = function () {
		// No asynchronous Google Maps initialization is required.
	};

})(window.L);
