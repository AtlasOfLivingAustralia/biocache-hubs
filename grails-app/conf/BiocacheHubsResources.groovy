modules = {
    application {
        resource url:[dir:'js', file:'application.js', plugin:'biocache-hubs']
    }

    bootstrap2 {
        dependsOn 'jquery'
        resource url:[dir:'bootstrap/js', file:'bootstrap.js', plugin:'biocache-hubs', disposition: 'head']
        resource url:[dir:'bootstrap/css', file:'bootstrap.css', plugin:'biocache-hubs'], attrs:[media:'screen, projection, print']
        resource url:[dir:'bootstrap/css', file:'bootstrap-responsive.css', plugin:'biocache-hubs'], attrs:[media:'screen', id:'responsiveCss']
    }

    core {
        dependsOn 'bootstrap2'
        defaultBundle 'main-core'
        resource url: [dir:'css', file:'autocomplete.css', plugin:'biocache-hubs']
        resource url: [dir:'css', file:'base.css', plugin: 'biocache-hubs']
        resource url: [dir:'css', file:'bootstrapAdditions.css', plugin: 'biocache-hubs']
        resource url: [dir:'js', file:'jquery.autocomplete.js', plugin:'biocache-hubs', disposition: 'head']
        resource url: [dir:'js', file:'bieAutocomplete.js', plugin:'biocache-hubs', disposition: 'head']
        resource url: [dir:'js', file:'html5.js', plugin:'biocache-hubs'], wrapper: { s -> "<!--[if lt IE 9]>$s<![endif]-->" }, disposition: 'head'
    }

//    ala {
//        dependsOn 'bootstrap'
//        resource url:[dir:'css', file:'base.css', plugin:'biocache-hubs']
//        resource url:[dir:'css', file:'bootstrapAdditions.css', plugin:'biocache-hubs']
//    }

//    avh {
//        dependsOn 'bootstrap','ala'
//        resource url:[dir:'css', file:'avh/style.css', plugin:'biocache-hubs']
//    }

    'search-core' {
        dependsOn 'jquery'
        defaultBundle 'main-core'
        resource url:[dir:'css', file:'search.css', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'purl.js', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'jquery.cookie.js', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'jquery.inview.min.js', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'jquery.jsonp-2.4.0.min.js', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'jquery.i18n.properties-1.0.9.min.js', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'charts2.js', plugin:'biocache-hubs', disposition: 'head']
    }

    search {
        dependsOn 'search-core'
        resource url:[dir:'js', file:'search.js', plugin:'biocache-hubs']
    }

    nanoscroller {
        dependsOn 'jquery'
        defaultBundle 'main-extras'
        resource url:[dir:'css', file:'nanoscroller.css', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'jquery.nanoscroller.min.js', plugin:'biocache-hubs']
    }

    slider {
        defaultBundle 'main-extras'
        resource url:[dir:'css', file:'slider.css', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'bootstrap-slider.js', plugin:'biocache-hubs']
    }

    leaflet {
        defaultBundle 'main-extras'
        resource url:[dir:'js', file:'leaflet-0.7.2/leaflet.css', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'leaflet-0.7.2/leaflet.js', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'leaflet-plugins/layer/tile/Google.js', plugin:'biocache-hubs']
    }

    qtip {
        dependsOn 'jquery'
        defaultBundle 'main-extras'
        resource url:[dir:'css', file:'jquery.qtip.min.css', plugin:'biocache-hubs']
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
        resource url:[dir:'css', file:'jquery.colourPicker.css', plugin:'biocache-hubs']
    }

    show {
        dependsOn 'jquery'
        resource url:[dir:'css', file:'record.css', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'audiojs/audio.min.js', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'moment.min.js', plugin:'biocache-hubs']
        //resource url:[dir:'js', file:'charts2.js', plugin:'biocache-hubs', disposition: 'head']
        resource url:[dir:'js', file:'show.js', plugin:'biocache-hubs']
    }

    exploreYourArea {
        dependsOn 'jquery'
        resource url:[dir:'css', file:'exploreYourArea.css', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'purl.js', plugin:'biocache-hubs']
        resource url:[dir:'js', file:'yourAreaMap.js', plugin:'biocache-hubs']
    }
}