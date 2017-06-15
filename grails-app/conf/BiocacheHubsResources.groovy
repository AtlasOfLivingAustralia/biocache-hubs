modules = {
    application {
        resource url:[dir:'js', file:'application.js', plugin:'biocache-hubs']
    }

    // 'bootstrap' was removed due to plugin conflict and now needs to be provided by client application

    // this is unpleasant, but is a fix for plugins referencing both 'bootstrap' and 'bootstrap2'
    bootstrap2 {
        dependsOn 'bootstrap'
    }

    jquery_i18n {
        dependsOn 'jquery_migration'
        resource url:[dir:'js', file:'jquery.i18n.properties-1.0.9.min.js', plugin:'biocache-hubs']
    }

    hubCore {
        //dependsOn 'bootstrap'
        dependsOn 'jquery_i18n'
        defaultBundle 'main-core'
        resource url: [dir:'css', file:'autocomplete.css', plugin:'biocache-hubs']
        resource url: [dir:'css', file:'base.css', plugin: 'biocache-hubs'],attrs: [ media: 'all' ]
        resource url: [dir:'css', file:'bootstrapAdditions.css', plugin: 'biocache-hubs'],attrs: [ media: 'all' ]
        resource url: [dir:'js', file:'jquery.autocomplete.js', plugin:'biocache-hubs'], disposition: 'head'
        resource url:[dir:'js', file:'biocache-hubs.js', plugin:'biocache-hubs']
        resource url: [dir:'js', file:'html5.js', plugin:'biocache-hubs'], wrapper: { s -> "<!--[if lt IE 9]>$s<![endif]-->" }, disposition: 'head'
    }

    searchCore {
        dependsOn 'jquery, purl, fontawesome, jquery_i18n'
        defaultBundle 'search-core'
        resource url:[dir:'css', file:'search.css', plugin:'biocache-hubs'], attrs: [ media: 'all' ]
        resource url:[dir:'css', file:'pagination.css', plugin:'biocache-hubs'], attrs: [ media: 'all' ]
        resource url:[dir:'js', file:'jquery.cookie.js', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'jquery.inview.min.js', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'jquery.jsonp-2.4.0.min.js', plugin:'biocache-hubs']
    }

    search {
        dependsOn 'searchCore'
        defaultBundle 'search-core'
        resource url:[dir:'css', file:'print-search.css', plugin:'biocache-hubs'], attrs: [ media: 'print' ]
        resource url:[dir:'js', file:'search.js', plugin:'biocache-hubs'], disposition: 'head'
    }

    bieAutocomplete {
        dependsOn 'jquery'
        resource url: [dir:'js', file:'bieAutocomplete.js', plugin:'biocache-hubs'], disposition: 'head'
    }

    nanoscroller {
        dependsOn 'jquery'
        defaultBundle 'main-extras'
        resource url:[dir:'css', file:'nanoscroller.css', plugin:'biocache-hubs'], attrs: [ media: 'all' ]
        resource url:[dir:'js', file:'jquery.nanoscroller.min.js', plugin:'biocache-hubs']
    }

    slider {
        defaultBundle 'main-extras'
        resource url:[dir:'css', file:'slider.css', plugin:'biocache-hubs'], attrs: [ media: 'all' ]
        resource url:[dir:'js', file:'bootstrap-slider.js', plugin:'biocache-hubs']
    }

    leaflet {
        dependsOn 'jquery_i18n'
        resource url:[dir:'js/leaflet-0.7.2', file:'leaflet.css', plugin:'biocache-hubs'], attrs: [ media: 'all' ]
        resource url:[dir:'js/leaflet-0.7.2', file:'leaflet.js', plugin:'biocache-hubs']

    }

    'leaflet-fullscreen' {
        dependsOn 'leaflet'
        defaultBundle 'leafletPlugins'
        resource url: [plugin: "biocache-hubs", dir: 'js/leaflet-plugins/fullscreen', file: 'Control.FullScreen.css']
        resource url: [plugin: "biocache-hubs", dir: 'js/leaflet-plugins/fullscreen', file: 'Control.FullScreen.js']
    }

    leafletPlugins {
        dependsOn 'leaflet','leaflet-fullscreen'
        defaultBundle 'leafletPlugins'
        resource url:[dir:'js/leaflet-plugins/layer/tile', file:'Google.js', plugin:'biocache-hubs']
        resource url:[dir:'js/leaflet-plugins/coordinates', file:'Leaflet.Coordinates-0.1.4.css', plugin:'biocache-hubs'], attrs: [ media: 'all' ]
        resource url:[dir:'js/leaflet-plugins/coordinates', file:'Leaflet.Coordinates-0.1.4.ie.css', plugin:'biocache-hubs'], attrs: [ media: 'all' ], wrapper: { s -> "<!--[if lt IE 8]>$s<![endif]-->" }
        resource url:[dir:'js/leaflet-plugins/layer/tile', file:'Google.js', plugin:'biocache-hubs']
        resource url:[dir:'js/leaflet-plugins/spin', file:'spin.min.js', plugin:'biocache-hubs']
        resource url:[dir:'js/leaflet-plugins/spin', file:'leaflet.spin.js', plugin:'biocache-hubs']
        resource url:[dir:'js/leaflet-plugins/coordinates', file:'Leaflet.Coordinates-0.1.4.min.js', plugin:'biocache-hubs']
        resource url:[dir:'js/leaflet-plugins/draw', file:'leaflet.draw.css', plugin:'biocache-hubs'], attrs: [ media: 'all' ]
        resource url:[dir:'js/leaflet-plugins/draw', file:'leaflet.draw-src.js', plugin:'biocache-hubs']
        resource url:[dir:'js/leaflet-plugins/wicket', file:'wicket.js', plugin:'biocache-hubs']
        resource url:[dir:'js/leaflet-plugins/wicket', file:'wicket-leaflet.js', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'LeafletToWKT.js', plugin:'biocache-hubs']
    }

    mapCommon {
        dependsOn 'jquery, purl'
        resource url:[dir:'js', file:'map.common.js', plugin:'biocache-hubs']
    }

    searchMap {
        resource url:[dir:'css', file:'searchMap.css', plugin:'biocache-hubs'], attrs: [ media: 'all' ]
    }

    qtip {
        dependsOn 'jquery'
        defaultBundle 'main-extras'
        resource url:[dir:'css', file:'jquery.qtip.min.css', plugin:'biocache-hubs'], attrs: [ media: 'all' ]
        resource url:[dir:'js', file:'jquery.qtip.min.js', plugin:'biocache-hubs']
    }

    amplify {
        dependsOn 'jquery'
        defaultBundle 'main-extras'
        resource url:[dir:'js', file:'amplify.js', plugin:'biocache-hubs']
    }

    colourPicker {
        dependsOn 'jquery'
        defaultBundle 'main-extras'
        resource url:[dir:'js', file:'jquery.colourPicker.js', plugin:'biocache-hubs']
        resource url:[dir:'css', file:'jquery.colourPicker.css', plugin:'biocache-hubs'], attrs: [ media: 'all' ]
    }

    purl {
        defaultBundle 'main-extras'
        resource url:[dir:'js', file:'purl.js', plugin:'biocache-hubs']
    }

    moment {
        defaultBundle 'main-extras'
        resource url:[dir:'js', file:'moment.min.js', plugin:'biocache-hubs']
    }

    fontawesome {
        resource url:[dir:'css', file:'font-awesome.css', plugin:'biocache-hubs'], attrs: [ media: 'all' ]
    }

    show {
        dependsOn 'jquery, fontawesome, jquery_i18n'
        resource url:[dir:'css', file:'record.css', plugin:'biocache-hubs'], attrs: [ media: 'all' ]
        resource url:[dir:'css', file:'print-record.css', plugin:'biocache-hubs'], attrs: [ media: 'print' ]
        resource url:[dir:'js', file:'audiojs/audio.min.js', plugin:'biocache-hubs'], disposition: 'head', exclude: '*'
        resource url: [dir:'js', file:'jquery.i18n.properties-1.0.9.js', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'show.js', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'charts2.js', plugin:'biocache-hubs'], disposition: 'head'
        resource url:[dir:'js', file:'wms2.js', plugin:'biocache-hubs'], disposition: 'head'
    }

    exploreYourArea {
        dependsOn 'jquery, purl'
        resource url:[dir:'css', file:'exploreYourArea.css', plugin:'biocache-hubs'], attrs: [ media: 'all' ]
        resource url:[dir:'css', file:'print-area.css', plugin:'biocache-hubs'], attrs: [ media: 'print' ]
        resource url:[dir:'js', file:'magellan.js', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'yourAreaMap.js', plugin:'biocache-hubs']
    }

    help {
        resource url:[dir:'css', file:'help.css', plugin:'biocache-hubs'], attrs: [ media: 'all' ]
        resource url:[dir:'js', file:'toc.js', plugin:'biocache-hubs']
    }

    bootstrapCombobox {
        dependsOn 'jquery'
        resource url:[dir:'js/bootstrap-combobox/', file:'bootstrap-combobox.css', plugin:'biocache-hubs']
        resource url:[dir:'js/bootstrap-combobox/', file:'bootstrap-combobox.js', plugin:'biocache-hubs']
    }

    jquery_migration{
        // Needed to support legacy js components that do not work with latest versions of jQuery
        dependsOn 'jquery'
        resource url:[ dir: 'js',file:'jquery-migrate-1.2.1.min.js', plugin:'biocache-hubs']
     }
}
