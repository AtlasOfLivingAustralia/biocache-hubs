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
<g:set var="serverName" value="${grailsApplication.config.serverName ?: grailsApplication.config.biocache.baseUrl}"/>
<g:set var="searchQuery" value="${grailsApplication.config.skin.useAlaBie.toBoolean() ? 'taxa' : 'q'}"/>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="${grailsApplication.config.skin.layout}"/>
    <meta name="section" content="search"/>
    <meta name="svn.revision" content="${meta(name: 'svn.revision')}"/>
    <meta name="breadcrumb" content="${message(code: "search.heading.list")}"/>
    <meta name="hideBreadcrumb" content=""/>
    <title><g:message code="home.index.title" default="Search for records"/> | ${hubDisplayName}</title>

    <g:if test="${grailsApplication.config.google.apikey}">
        <script src="https://maps.googleapis.com/maps/api/js?key=${grailsApplication.config.google.apikey}"
                type="text/javascript"></script>
    </g:if>
    <g:else>
        <script src="https://maps.google.com/maps/api/js" type="text/javascript"></script>
    </g:else>

    <script type="text/javascript">
        // global var for GSP tags/vars to be passed into JS functions
        var BC_CONF = {
            biocacheServiceUrl: "${alatag.getBiocacheAjaxUrl()}",
            bieWebappUrl: "${grailsApplication.config.bie.baseUrl}",
            bieWebServiceUrl: "${grailsApplication.config.bieService.baseUrl}",
            autocompleteHints: ${grailsApplication.config.bie?.autocompleteHints?.encodeAsJson() ?: '{}'},
            contextPath: "${request.contextPath}",
            locale: "${org.springframework.web.servlet.support.RequestContextUtils.getLocale(request)}",
            queryContext: "${grailsApplication.config.biocache.queryContext}"
        }
        /* Load Spring i18n messages into JS
         */
        jQuery.i18n.properties({
            name: 'messages',
            path: BC_CONF.contextPath + '/messages/i18n/',
            mode: 'map',
            language: BC_CONF.locale
        });
    </script>


<!-- Here are the leaflet plugins JS -->

    <asset:javascript src="leaflet/leaflet.js"/>
    <asset:javascript src="leafletPlugins.js"/>
    <asset:javascript src="mapCommon.js"/>
    <asset:javascript src="bootstrapCombobox.js"/>

    <!-- Here are the leaflet plugins CSS -->
    <asset:stylesheet src="leaflet/leaflet.css"/>
    <asset:stylesheet src="leafletPlugins.css"/>
    <asset:stylesheet src="searchMap.css"/>
    <asset:stylesheet src="search.css" />
    <asset:stylesheet src="print-search.css" media="print" />
    <asset:stylesheet src="bootstrapCombobox.css"/>

    <g:if test="${grailsApplication.config.skin.useAlaBie?.toBoolean()}">
        <asset:javascript src="bieAutocomplete.js"/>
    </g:if>

    <asset:script type="text/javascript">
        $(document).ready(function() {
            var mapInit = false;
            $('a[data-toggle="tab"]').on('shown.bs.tab', function(e) {
                // console.log("this", $(this).attr('id'));
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
                    try{
                        drawWktObj($('#wktInput').val());
                    } catch (e) {
                        console.log(e);
                        alert("Please paste a valid WKT string"); // TODO i18n this
                    }
                } else {
                    alert("Please paste a valid WKT string"); // TODO i18n this
                }
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
            mapid: "${grailsApplication.config.map.mapbox?.id ?: ''}",
            token: "${grailsApplication.config.map.mapbox?.token ?: ''}"
        });

        // Global var to store map config
        var MAP_VAR = {
            map : null,
            mappingUrl : "${mappingUrl}",
            query : "${searchString}",
            queryDisplayString : "${queryDisplayString}",
            //center: [-30.0,133.6],
            defaultLatitude : "${grailsApplication.config.map.defaultLatitude ?: '-25.4'}",
            defaultLongitude : "${grailsApplication.config.map.defaultLongitude ?: '133.6'}",
            defaultZoom : "${grailsApplication.config.map.defaultZoom ?: '4'}",
            overlays : {
        <g:if test="${grailsApplication.config.map.overlay.url}">
            "${grailsApplication.config.map.overlay.name ?: 'overlay'}" : L.tileLayer.wms("${grailsApplication.config.map.overlay.url}", {
                        layers: 'ALA:ucstodas',
                        format: 'image/png',
                        transparent: true,
                        attribution: "${grailsApplication.config.map.overlay.name ?: 'overlay'}"
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
            // alert('starting map');
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
                            message: '<strong>Oh snap!</strong> you can\'t draw that!' // Message that will show when intersect
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
                $('.leaflet-draw-toolbar').first().attr('title',jQuery.i18n.prop('advancedsearch.js.choosetool')).tooltip({placement:'right'}).tooltip('show');
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

    </asset:script>
</head>

<body>
    <div id="headingBar" class="heading-bar">
        <h1 style="width:100%;" id="searchHeader"><g:message code="home.index.body.title"
                                                             default="Search for records in"/> ${raw(hubDisplayName)}</h1>
    </div>
    <g:if test="${flash.message}">
        <div class="message alert alert-info alert-dismissable">
            <button type="button" class="close" onclick="$(this).parent().hide()">×</button>
            <b><g:message code="home.index.body.alert" default="Alert:"/></b> ${raw(flash.message)}
        </div>
    </g:if>
    <div class="row" id="content">
        <div class="col-sm-12 col-md-12">
            <div class="tabbable">
                <ul class="nav nav-tabs" id="searchTabs">
                    <li><a id="t1" href="#simpleSearch" data-toggle="tab"><g:message code="home.index.navigator01"
                                                                                     default="Simple search"/></a></li>
                    <li><a id="t2" href="#advanceSearch" data-toggle="tab"><g:message code="home.index.navigator02"
                                                                                      default="Advanced search"/></a></li>
                    <li><a id="t3" href="#taxaUpload" data-toggle="tab"><g:message code="home.index.navigator03"
                                                                                   default="Batch taxon search"/></a></li>
                    <li><a id="t4" href="#catalogUpload" data-toggle="tab"><g:message code="home.index.navigator04"
                                                                                      default="Catalogue number search"/></a>
                    </li>
                    <li><a id="t5" href="#spatialSearch" data-toggle="tab"><g:message code="home.index.navigator05"
                                                                                      default="Spatial search"/></a></li>
                </ul>
            </div>

            <div class="tab-content searchPage">
                <div id="simpleSearch" class="tab-pane active">
                    <form class="form-horizontal" name="simpleSearchForm" id="simpleSearchForm" action="${request.contextPath}/occurrences/search"
                          method="GET">
                        <br/>
                        <div class="col-sm-9 input-group">
                            <input type="text" class="form-control" name="${searchQuery}" id="taxa"/>
                            <span class="input-group-btn">
                                <input class="form-control btn btn-primary" id="locationSearch"  type="submit"
                                       value="${g.message(code:"home.index.simsplesearch.button", default:"Search")}"/>
                            </span>
                        </div>
                        <div>
                            <br/>
                            <span class="simpleSearchNote">
                                <b><g:message code="home.index.simsplesearch.span"
                                              default="Note: the simple search attempts to match a known species/taxon - by its scientific name or common name. If there are no name matches, a full text search will be performed on your query"/></b>
                            </span>
                        </div>
                    </form>
                </div><!-- end simpleSearch div -->
                <div id="advanceSearch" class="tab-pane">
                    <g:render template="advanced"/>
                </div><!-- end #advancedSearch div -->
                <div id="taxaUpload" class="tab-pane">
                    <form name="taxaUploadForm" id="taxaUploadForm" action="${biocacheServiceUrl}/occurrences/batchSearch"
                          method="POST">
                        <div class="row">
                            <div class="col-sm-8">
                                <div class="form-group">
                                    <label for="raw_names"><g:message code="home.index.taxaupload.des01"
                                                                      default="Enter a list of taxon names/scientific names, one name per line (common names not currently supported)."/></label>
                                    <%--<p><input type="hidden" name="MAX_FILE_SIZE" value="2048" class="form-control"><input type="file" class="form-control"></p>--%>
                                    <textarea name="queries" id="raw_names" class="form-control" rows="15" cols="60"></textarea>
                                </div>
                                <%--<input type="submit" name="action" value="Download" class="form-control">--%>
                                <%--&nbsp;OR&nbsp;--%>
                                <input type="hidden" name="redirectBase"
                                       value="${serverName}${request.contextPath}/occurrences/search" class="form-control">
                                <input type="hidden" name="field" value="raw_name" class="form-control"/>
                                <input type="hidden" name="action" value="Search" />
                                <input type="submit"
                                       value="${g.message(code:"home.index.catalogupload.button01", default:"Search")}" class="btn btn-primary" />
                            </div>
                        </div>
                    </form>
                </div><!-- end #uploadDiv div -->
                <div id="catalogUpload" class="tab-pane">
                    <form name="catalogUploadForm" id="catalogUploadForm"
                          action="${biocacheServiceUrl}/occurrences/batchSearch" method="POST">
                        <div class="row">
                                <div class="col-sm-8">
                                <div class="form-group">
                                    <label for="catalogue_numbers"><g:message code="home.index.catalogupload.des01"
                                                  default="Enter a list of catalogue numbers (one number per line)."/></label>
                                    <%--<p><input type="hidden" name="MAX_FILE_SIZE" value="2048" class="form-control"><input type="file" class="form-control"></p>--%>
                                    <textarea name="queries" id="catalogue_numbers" class="form-control" rows="15" cols="60"></textarea>
                                </div>
                                <%--<input type="submit" name="action" value="Download" class="form-control">--%>
                                <%--&nbsp;OR&nbsp;--%>
                                <input type="hidden" name="redirectBase"
                                       value="${serverName}${request.contextPath}/occurrences/search" class="form-control">
                                <input type="hidden" name="field" value="catalogue_number" class="form-control">
                                <input type="hidden" name="action" value="Search" />
                                <input type="submit"
                                       value="${g.message(code:"home.index.catalogupload.button01", default:"Search")}" class="btn btn-primary" />
                            </div>
                        </div>
                    </form>
                </div><!-- end #catalogUploadDiv div -->
                <div id="spatialSearch" class="tab-pane">
                    <div class="row">
                        <div class="col-sm-3 col-md-3">
                            <div>
                                <g:message code="search.map.helpText"
                                           default="Select one of the draw tools (polygon, rectangle, circle), draw a shape and click the search link that pops up."/>
                            </div>
                            <br>

                            <div class="panel-group panel-group-caret" id="importAreaPanel">
                                <div class="panel panel-default">
                                    <div class="panel-heading">
                                        <a class="panel-group-toggle collapsed" data-toggle="collapse"
                                           data-parent="#importAreaPanel" href="#importAreaContent">
                                            <g:message code="search.map.importToggle" default="Import WKT"/>
                                        </a>
                                    </div>

                                    <div id="importAreaContent" class="panel-collapse collapse">
                                        <div class="panel-body">
                                            <p><g:message code="search.map.importText"/></p>

                                            <g:if test="${grailsApplication.config.skin.useAlaSpatialPortal?.toBoolean()}">
                                                <p><g:message
                                                        code="search.map.importText.spatialportal"
                                                        args="${[ grailsApplication.config.spatial.baseUrl ]}"/>
                                                </p>
                                            </g:if>

                                            <p><g:message code="search.map.wktHelpText"
                                                          default="Optionally, paste a WKT string: "/></p>
                                            <textarea type="text" id="wktInput"></textarea>
                                            <br/>
                                            <button class="btn btn-primary btn-sm" id="addWkt"><g:message
                                                    code="search.map.wktButtonText" default="Add to map"/></button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="col-sm-9 col-md-9">
                            <div id="leafletMap" style="height:600px;"></div>
                        </div>
                    </div>
                </div><!-- end #spatialSearch  -->
            </div><!-- end .tab-content -->
        </div><!-- end .span12 -->
    </div><!-- end .row -->
</body>
</html>