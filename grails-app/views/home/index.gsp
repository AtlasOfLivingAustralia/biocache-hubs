<%--
  Created by IntelliJ IDEA.
  User: dos009@csiro.au
  Date: 28/02/2014
  Time: 3:15 PM
  To change this template use File | Settings | File Templates.
--%>
<%@ page import="org.springframework.web.servlet.support.RequestContextUtils; au.org.ala.biocache.hubs.FacetsName; org.apache.commons.lang.StringUtils" contentType="text/html;charset=UTF-8" %>
<g:set var="hubDisplayName" value="${grailsApplication.config.skin.orgNameLong}"/>
<g:set var="biocacheServiceUrl" value="${grailsApplication.config.biocache.baseUrl}"/>
<g:set var="serverName" value="${grailsApplication.config.serverName?:grailsApplication.config.biocache.baseUrl}"/>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="${grailsApplication.config.skin.layout}"/>
    <meta name="section" content="search"/>
    <meta name="svn.revision" content="${meta(name: 'svn.revision')}"/>
    <title><g:message code="home.index.title" default="Search for records"/> | ${hubDisplayName}</title>
    <script src="http://maps.google.com/maps/api/js?v=3.5&sensor=false"></script>
    <r:require modules="jquery, leaflet, mapCommon, searchMap, bootstrapCombobox"/>
    <g:if test="${grailsApplication.config.skin.useAlaBie?.toBoolean()}">
        <r:require module="bieAutocomplete"/>
    </g:if>
    <r:script>
        // global var for GSP tags/vars to be passed into JS functions
        var BC_CONF = {
            biocacheServiceUrl: "${alatag.getBiocacheAjaxUrl()}",
            bieWebappUrl: "${grailsApplication.config.bie.baseUrl}",
            autocompleteHints: ${grailsApplication.config.bie?.autocompleteHints?.encodeAsJson()?:'{}'},
            contextPath: "${request.contextPath}",
            locale: "${org.springframework.web.servlet.support.RequestContextUtils.getLocale(request)}",
            queryContext: "${grailsApplication.config.biocache.queryContext}"
        }

        $(document).ready(function() {

            var mapInit = false;
            $('a[data-toggle="tab"]').on('shown', function(e) {
                //console.log("this", $(this).attr('id'));
                var id = $(this).attr('id');
                location.hash = 'tab_'+ $(e.target).attr('href').substr(1);

                if (id == "t5" && !mapInit) {
                    initialiseMap();
                    mapInit = true;
                }
            });
            // catch hash URIs and trigger tabs
            if (location.hash !== '') {
                $('.nav-tabs a[href="' + location.hash.replace('tab_','') + '"]').tab('show');
                //$('.nav-tabs li a[href="' + location.hash.replace('tab_','') + '"]').click();
            } else {
                $('.nav-tabs a:first').tab('show');
            }

            // Toggle show/hide sections with plus/minus icon
            $(".toggleTitle").not("#extendedOptionsLink").click(function(e) {
                e.preventDefault();
                var $this = this;
                $(this).next(".toggleSection").slideToggle('slow', function(){
                    // change plus/minus icon when transition is complete
                    $($this).toggleClass('toggleTitleActive');
                });
            });

            $(".toggleOptions").click(function(e) {
                e.preventDefault();
                var $this = this;
                var targetEl = $(this).attr("id");
                $(targetEl).slideToggle('slow', function(){
                    // change plus/minus icon when transition is complete
                    $($this).toggleClass('toggleOptionsActive');
                });
            });

            // Add WKT string to map button click
            $('#addWkt').click(function() {
                var wktString = $('#wktInput').val();

                if (wktString) {
                    drawWktObj($('#wktInput').val());
                } else {
                    alert("Please paste a valid WKT string"); // TODO i18n this
                }
            });

            /**
             * Load Spring i18n messages into JS
             */
            jQuery.i18n.properties({
                name: 'messages',
                path: '${request.contextPath}/messages/i18n/',
                mode: 'map',
                language: '${request.locale}' // default is to use browser specified locale
                //callback: function(){} //alert( "facet.conservationStatus = " + jQuery.i18n.prop('facet.conservationStatus')); }
            });

        }); // end $(document).ready()

        // extend tooltip with callback
        var tmp = $.fn.tooltip.Constructor.prototype.show;
        $.fn.tooltip.Constructor.prototype.show = function () {
            tmp.call(this);
            if (this.options.callback) {
                this.options.callback();
            }
        };

        var defaultBaseLayer = L.tileLayer("${grailsApplication.config.map.minimal.url}", {
            attribution: "${raw(grailsApplication.config.map.minimal.attr)}",
            subdomains: "${grailsApplication.config.map.minimal.subdomains}",
            mapid: "${grailsApplication.config.map.mapbox?.id?:''}",
            token: "${grailsApplication.config.map.mapbox?.token?:''}"
        });

        // Global var to store map config
        var MAP_VAR = {
            map : null,
            mappingUrl : "${mappingUrl}",
            query : "${searchString}",
            queryDisplayString : "${queryDisplayString}",
            //center: [-30.0,133.6],
            defaultLatitude : "${grailsApplication.config.map.defaultLatitude?:'-25.4'}",
            defaultLongitude : "${grailsApplication.config.map.defaultLongitude?:'133.6'}",
            defaultZoom : "${grailsApplication.config.map.defaultZoom?:'4'}",
            overlays : {
                <g:if test="${grailsApplication.config.map.overlay.url}">
                    "${grailsApplication.config.map.overlay.name?:'overlay'}" : L.tileLayer.wms("${grailsApplication.config.map.overlay.url}", {
                        layers: 'ALA:ucstodas',
                        format: 'image/png',
                        transparent: true,
                        attribution: "${grailsApplication.config.map.overlay.name?:'overlay'}"
                    })
                </g:if>
            },
            baseLayers : {
                "Minimal" : defaultBaseLayer,
                //"Night view" : L.tileLayer(cmUrl, {styleId: 999,   attribution: cmAttr}),
                "Road" :  new L.Google('ROADMAP'),
                "Terrain" : new L.Google('TERRAIN'),
                "Satellite" : new L.Google('HYBRID')
            },
            layerControl : null,
            //currentLayers : [],
            //additionalFqs : '',
            //zoomOutsideScopedRegion: ${(grailsApplication.config.map.zoomOutsideScopedRegion == false || grailsApplication.config.map.zoomOutsideScopedRegion == "false") ? false : true}
        };

        function initialiseMap() {
            //alert('starting map');
            if(MAP_VAR.map != null){
                return;
            }

            //initialise map
            MAP_VAR.map = L.map('leafletMap', {
                center: [MAP_VAR.defaultLatitude, MAP_VAR.defaultLongitude],
                zoom: MAP_VAR.defaultZoom,
                minZoom: 1,
                scrollWheelZoom: false
//                fullscreenControl: true,
//                fullscreenControlOptions: {
//                    position: 'topleft'
//                }
            });

            //add edit drawing toolbar
            // Initialise the FeatureGroup to store editable layers
            MAP_VAR.drawnItems = new L.FeatureGroup();
            MAP_VAR.map.addLayer(MAP_VAR.drawnItems);

            // Initialise the draw control and pass it the FeatureGroup of editable layers
            MAP_VAR.drawControl = new L.Control.Draw({
                edit: {
                    featureGroup: MAP_VAR.drawnItems
                },
                draw: {
                    polyline: false,
                    rectangle: {
                        shapeOptions: {
                            color: '#bada55'
                        }
                    },
                    circle: {
                        shapeOptions: {
                            color: '#bada55'
                        }
                    },
                    marker: false,
                    polygon: {
                        allowIntersection: false, // Restricts shapes to simple polygons
                        drawError: {
                            color: '#e1e100', // Color the shape will turn when intersects
                            message: '<strong>Oh snap!<strong> you can\'t draw that!' // Message that will show when intersect
                        },
                        shapeOptions: {
                            color: '#bada55'
                        }
                    }
                }
            });
            MAP_VAR.map.addControl(MAP_VAR.drawControl);

            MAP_VAR.map.on('draw:created', function(e) {
                //setup onclick event for this object
                var layer = e.layer;
                //console.log("layer",layer, layer._latlng.lat);
                generatePopup(layer, layer._latlng);
                addClickEventForVector(layer);
                MAP_VAR.drawnItems.addLayer(layer);
            });

            MAP_VAR.map.on('draw:edited', function(e) {
                //setup onclick event for this object
                var layers = e.layers;
                layers.eachLayer(function (layer) {
                    generatePopup(layer, layer._latlng);
                    addClickEventForVector(layer);
                });
            });

            //add the default base layer
            MAP_VAR.map.addLayer(defaultBaseLayer);

            L.control.coordinates({position:"bottomright", useLatLngOrder: true}).addTo(MAP_VAR.map); // coordinate plugin

            MAP_VAR.layerControl = L.control.layers(MAP_VAR.baseLayers, MAP_VAR.overlays, {collapsed:true, position:'topleft'});
            MAP_VAR.layerControl.addTo(MAP_VAR.map);

            L.Util.requestAnimFrame(MAP_VAR.map.invalidateSize, MAP_VAR.map, !1, MAP_VAR.map._container);
            L.Browser.any3d = false; // FF bug prevents selects working properly

            // Add a help tooltip to map when first loaded
            MAP_VAR.map.whenReady(function() {
                var opts = {
                    placement:'right',
                    callback: destroyHelpTooltip // hide help tooltip when mouse over the tools
                }
                $('.leaflet-draw-toolbar a').tooltip(opts);
                $('.leaflet-draw-toolbar').first().attr('title','Start by choosing a tool').tooltip({placement:'right'}).tooltip('show');
            });

            // Hide help tooltip on first click event
            var once = true;
            MAP_VAR.map.on('click', function(e) {
                if (once) {
                    $('.leaflet-draw-toolbar').tooltip('destroy');
                    once = false;
                }
            });
        }

        var once = true;
        function destroyHelpTooltip() {
            if ($('.leaflet-draw-toolbar').length && once) {
                $('.leaflet-draw-toolbar').tooltip('destroy');
                once = false;
            }
        }

    </r:script>
</head>

<body>
    <div id="headingBar" class="heading-bar">
        <h1 style="width:100%;" id="searchHeader"><g:message code="home.index.body.title" default="Search for records in"/> ${raw(hubDisplayName)}</h1>
    </div>
    <g:if test="${flash.message}">
        <div class="message alert alert-info">
            <button type="button" class="close" onclick="$(this).parent().hide()">×</button>
            <b><g:message code="home.index.body.alert" default="Alert:"/></b> ${raw(flash.message)}
        </div>
    </g:if>
    <div class="row-fluid" id="content">
        <div class="span12">
            <div class="tabbable">
                <ul class="nav nav-tabs" id="searchTabs">
                    <li><a id="t1" href="#simpleSearch" data-toggle="tab"><g:message code="home.index.navigator01" default="Simple search"/></a></li>
                    <li><a id="t2" href="#advanceSearch" data-toggle="tab"><g:message code="home.index.navigator02" default="Advanced search"/></a></li>
                    <li><a id="t3" href="#taxaUpload" data-toggle="tab"><g:message code="home.index.navigator03" default="Batch taxon search"/></a></li>
                    <li><a id="t4" href="#catalogUpload" data-toggle="tab"><g:message code="home.index.navigator04" default="Catalogue number search"/></a></li>
                    <li><a id="t5" href="#spatialSearch" data-toggle="tab"><g:message code="home.index.navigator05" default="Spatial search"/></a></li>
                </ul>
            </div>
            <div class="tab-content searchPage">
                <div id="simpleSearch" class="tab-pane active">
                    <form name="simpleSearchForm" id="simpleSearchForm" action="${request.contextPath}/occurrences/search" method="GET">
                        <br/>
                        <div class="controls">
                            <div class="input-append">
                                <input type="text" name="taxa" id="taxa" class="input-xxlarge">
                                <button id="locationSearch" type="submit" class="btn"><g:message code="home.index.simsplesearch.button" default="Search"/></button>
                            </div>
                        </div>
                        <div>
                            <br/>
                            <span style="font-size: 12px; color: #444;">
                                <b><g:message code="home.index.simsplesearch.span" default="Note: the simple search attempts to match a known species/taxon - by its scientific name or common name. If there are no name matches, a full text search will be performed on your query"/>
                            </span>
                        </div>
                    </form>
                </div><!-- end simpleSearch div -->
                <div id="advanceSearch" class="tab-pane">
                    <g:render template="advanced" />
                </div><!-- end #advancedSearch div -->
                <div id="taxaUpload" class="tab-pane">
                    <form name="taxaUploadForm" id="taxaUploadForm" action="${biocacheServiceUrl}/occurrences/batchSearch" method="POST">
                        <p><g:message code="home.index.taxaupload.des01" default="Enter a list of taxon names/scientific names, one name per line (common names not currently supported)."/></p>
                        <%--<p><input type="hidden" name="MAX_FILE_SIZE" value="2048" /><input type="file" /></p>--%>
                        <p><textarea name="queries" id="raw_names" class="span6" rows="15" cols="60"></textarea></p>
                        <p>
                            <%--<input type="submit" name="action" value="Download" />--%>
                            <%--&nbsp;OR&nbsp;--%>
                            <input type="hidden" name="redirectBase" value="${serverName}${request.contextPath}/occurrences/search"/>
                            <input type="hidden" name="field" value="raw_name"/>
                            <input type="submit" name="action" value=<g:message code="home.index.taxaupload.button01" default="Search"/> class="btn" /></p>
                    </form>
                </div><!-- end #uploadDiv div -->
                <div id="catalogUpload" class="tab-pane">
                    <form name="catalogUploadForm" id="catalogUploadForm" action="${biocacheServiceUrl}/occurrences/batchSearch" method="POST">
                        <p><g:message code="home.index.catalogupload.des01" default="Enter a list of catalogue numbers (one number per line)."/></p>
                        <%--<p><input type="hidden" name="MAX_FILE_SIZE" value="2048" /><input type="file" /></p>--%>
                        <p><textarea name="queries" id="catalogue_numbers" class="span6" rows="15" cols="60"></textarea></p>
                        <p>
                            <%--<input type="submit" name="action" value="Download" />--%>
                            <%--&nbsp;OR&nbsp;--%>
                            <input type="hidden" name="redirectBase" value="${serverName}${request.contextPath}/occurrences/search"/>
                            <input type="hidden" name="field" value="catalogue_number"/>
                            <input type="submit" name="action" value=<g:message code="home.index.catalogupload.button01" default="Search"/> class="btn"/></p>
                    </form>
                </div><!-- end #catalogUploadDiv div -->
                <div id="spatialSearch" class="tab-pane">
                    <div class="row-fluid">
                        <div class="span3">
                            <div>
                                <g:message code="search.map.helpText" default="Select one of the draw tools (polygon, rectangle, circle), draw a shape and click the search link that pops up."/>
                            </div>
                            <br>
                            <div class="accordion accordion-caret" id="accordion2">
                                <div class="accordion-group">
                                    <div class="accordion-heading">
                                        <a class="accordion-toggle collapsed" data-toggle="collapse" data-parent="#accordion2" href="#collapseOne">
                                            <g:message code="search.map.importToggle" default="Import WKT"/>
                                        </a>
                                    </div>
                                    <div id="collapseOne" class="accordion-body collapse">
                                        <div class="accordion-inner">
                                            <p><g:message code="search.map.importText"/></p>
                                            <p><g:message code="search.map.wktHelpText" default="Optionally, paste a WKT string: "/></p>
                                            <textarea type="text" id="wktInput"></textarea>
                                            <br>
                                            <button class="btn btn-small" id="addWkt"><g:message code="search.map.wktButtonText" default="Add to map"/></button>
                                        </div>
                                    </div>
                                </div>
                            </div>

                        </div>
                        <div class="span9">
                            <div id="leafletMap" style="height:600px;"></div>
                        </div>
                    </div>
                </div><!-- end #spatialSearch  -->
            </div><!-- end .tab-content -->
        </div><!-- end .span12 -->
    </div><!-- end .row-fluid -->
</body>
</html>