
//= require leaflet/leaflet-src.js
//= require maplibre-gl.js
//= require leaflet-maplibre-gl.js
//= require leaflet-fullscreen.js
//= require leaflet-plugins/layer/tile/Google.js
//= require leaflet-plugins/spin/spin.min.js
//= require leaflet-plugins/spin/leaflet.spin.js
//= require leaflet-plugins/coordinates/Leaflet.Coordinates-0.1.4.min.js
//= require leaflet-plugins/draw/leaflet.draw-src.js
//= require leaflet-plugins/wicket/wicket.js
//= require leaflet-plugins/wicket/wicket-leaflet.js
//= require leaflet-plugins/loading/Control.Loading.js
//= require LeafletToWKT.js
//= require wicket-world-wrap-fix.js

if (typeof window !== 'undefined' && window.L) {
    window.L_mainMap = window.L;
}
