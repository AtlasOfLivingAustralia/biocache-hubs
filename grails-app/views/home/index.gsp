<%--
  Created by IntelliJ IDEA.
  User: dos009@csiro.au
  Date: 28/02/2014
  Time: 3:15 PM
  To change this template use File | Settings | File Templates.
--%>
<%@ page import="org.springframework.web.servlet.support.RequestContextUtils; au.org.ala.biocache.hubs.FacetsName; org.apache.commons.lang.StringUtils; grails.util.Environment" contentType="text/html;charset=UTF-8" %>
<g:set var="hubDisplayName" value="${grailsApplication.config.getProperty('skin.orgNameLong')}"/>
<g:set var="biocacheServiceUrl" value="${grailsApplication.config.getProperty('biocache.baseUrl')}"/>
<g:set var="serverName" value="${grailsApplication.config.getProperty('serverName') ?: grailsApplication.config.getProperty('biocache.baseUrl')}"/>
<g:set var="biocacheServiceUrl" value="${alatag.getBiocacheAjaxUrl()}"/>
<g:set var="shortName" value="${grailsApplication.config.getProperty('skin.orgNameShort')}"/>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="${grailsApplication.config.getProperty('skin.layout')}"/>
    <meta name="section" content="search"/>
    <meta name="svn.revision" content="${meta(name: 'svn.revision')}"/>
    <meta name="breadcrumb" content="${message(code: "search.heading.list")}"/>
    <meta name="hideBreadcrumb" content=""/>
    <title><g:message code="home.index.title" default="Search for records"/> | ${hubDisplayName}</title>

    <g:if test="${grailsApplication.config.getProperty('google.apikey')}">
        <script src="https://maps.googleapis.com/maps/api/js?key=${grailsApplication.config.getProperty('google.apikey')}"
                type="text/javascript"></script>
    </g:if>
    <g:else>
        <script src="https://maps.google.com/maps/api/js" type="text/javascript"></script>
    </g:else>

    <asset:javascript src="jquery_i18n.js" />

    <script type="text/javascript">
        // global var for GSP tags/vars to be passed into JS functions
        var BC_CONF = {
            biocacheServiceUrl: "${alatag.getBiocacheAjaxUrl()}",
            bieWebappUrl: "${grailsApplication.config.getProperty('bie.baseUrl')}",
            bieWebServiceUrl: "${grailsApplication.config.getProperty('bieService.baseUrl')}",
            autocompleteHints: ${grailsApplication.config.getProperty('bie.autocompleteHints', Map)?.encodeAsJson() ?: '{}'},
            contextPath: "${request.contextPath}",
            locale: "${org.springframework.web.servlet.support.RequestContextUtils.getLocale(request)}",
            queryContext: "${grailsApplication.config.getProperty('biocache.queryContext')}",
            autocompleteUrl: "${grailsApplication.config.getProperty('skin.useAlaBie', Boolean) ? (grailsApplication.config.getProperty('bieService.baseUrl') + '/search/auto.json') : biocacheServiceUrl + '/autocomplete/search'}",
            autocompleteUseBie: ${grailsApplication.config.getProperty('skin.useAlaBie', Boolean, false)}
        }
        /* Load Spring i18n messages into JS
         */
        jQuery.i18n.properties({
            cache: true,
            async: true,
            name: 'messages',
            path: BC_CONF.contextPath + '/messages/i18n/',
            mode: 'map',
            language: BC_CONF.locale
        });

        $(document).ready(function() {
            // Init BS tooltip
            $('[data-toggle="tooltip"]').tooltip({ html: true, placement: 'right', container: '#content' });
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

    <asset:javascript src="autocomplete.js"/>

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

        var defaultBaseLayer = L.tileLayer("${grailsApplication.config.getProperty('map.minimal.url')}", {
            attribution: "${raw(grailsApplication.config.getProperty('map.minimal.attr'))}",
            subdomains: "${grailsApplication.config.getProperty('map.minimal.subdomains', String, '')}",
            mapid: "${grailsApplication.config.getProperty('map.mapbox.id', String, '')}",
            token: "${grailsApplication.config.getProperty('map.mapbox.token', String, '')}"
        });

        // Global var to store map config
        var MAP_VAR = {
            map : null,
            mappingUrl : "${mappingUrl}",
            query : "${searchString}",
            queryDisplayString : "${queryDisplayString}",
            //center: [-30.0,133.6],
            defaultLatitude : "${grailsApplication.config.getProperty('map.defaultLatitude', String, '-25.4')}",
            defaultLongitude : "${grailsApplication.config.getProperty('map.defaultLongitude', String, '133.6')}",
            defaultZoom : "${grailsApplication.config.getProperty('map.defaultZoom', String, '4')}",
            overlays : {
        <g:if test="${grailsApplication.config.getProperty('map.overlay.url')}">
            "${grailsApplication.config.getProperty('map.overlay.name', String, 'overlay')}" : L.tileLayer.wms("${grailsApplication.config.getProperty('map.overlay.url')}", {
                        layers: 'ALA:ucstodas',
                        format: 'image/png',
                        transparent: true,
                        attribution: "${grailsApplication.config.getProperty('map.overlay.name', String, 'overlay')}"
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
        //zoomOutsideScopedRegion: ${(grailsApplication.config.getProperty('map.zoomOutsideScopedRegion', Boolean) == false || grailsApplication.config.getProperty('map.zoomOutsideScopedRegion') == "false") ? false : true}
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
            <b><g:message code="home.index.body.alert" default="Alert:"/></b> <alatag:stripApiKey message="${flash.message}"/>
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
                    <li><a id="t6" href="#eventSearch" data-toggle="tab"><g:message code="home.index.navigator06"
                                                                                      default="Event search"/></a>
                    </li>
                    <li><a id="t5" href="#spatialSearch" data-toggle="tab"><g:message code="home.index.navigator05"
                                                                                      default="Spatial search"/></a></li>
                </ul>
            </div>

            <div class="tab-content searchPage">
                <div id="simpleSearch" class="tab-pane active">
                    <form class="form-horizontal" name="simpleSearchForm" id="simpleSearchForm" action="${request.contextPath}/simpleSearch"
                          method="GET">
                        <br/>
                        <div class="col-sm-9 input-group">
                            <input type="text" class="form-control" name="q" id="taxa"/>
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
                                <div class="form-group-off">
                                    <label for="raw_names"><g:message code="home.index.taxaupload.des01"
                                                                      default="Enter a list of taxon names/scientific names, one name per line (common names not currently supported)."/></label>
                                    <%--<p><input type="hidden" name="MAX_FILE_SIZE" value="2048" class="form-control"><input type="file" class="form-control"></p>--%>
                                    <textarea name="queries" id="raw_names" class="form-control" rows="15" cols="60"></textarea>
                                    <div class="row">
                                        <div class="col-sm-2">
                                            <div class="radio ">
                                                <g:message code="home.index.taxaupload.batchRadioPrefix" default="Search on:"/>
                                            </div>
                                        </div>
                                        <g:set var="matchedTaxonTooltip" value="${g.message(code:"advanced.taxon.tooltip.matched.param",default:"N/A", args:[shortName])}" />
                                        <g:set var="suppliedTaxonTooltip" value="${g.message(code:"advanced.taxon.tooltip.supplied",default:"N/A")}"/>
                                        <div class="col-sm-10">
                                            <div class="radio ">
                                                <label>
                                                    <input type="radio" name="field" id="batchModeMatched" value="taxa" checked>
                                                    <g:message code="home.index.taxaupload.batchMode.matched.param" default="Matched name" args="${[shortName]}" />
                                                </label>
                                                <a href="#" data-toggle="tooltip" data-placement="right" title="${matchedTaxonTooltip}"><i class="glyphicon glyphicon-question-sign"></i></a>
                                            </div>
                                            <div class="radio">
                                                <label>
                                                    <input type="radio" name="field" id="batchModeRaw" value="raw_scientificName" >
                                                    <g:message code="home.index.taxaupload.batchMode.provided" default="Supplied name"/>
                                                </label>
                                                <a href="#" data-toggle="tooltip" data-placement="right" title="${suppliedTaxonTooltip}"><i class="glyphicon glyphicon-question-sign"></i></a>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <%--<input type="submit" name="action" value="Download" class="form-control">--%>
                                <%--&nbsp;OR&nbsp;--%>
                                <input type="hidden" name="redirectBase"
                                       value="${serverName}${request.contextPath}/occurrences/search" class="form-control">
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
                <div id="eventSearch" class="tab-pane">
                    <form name="eventSearchForm" id="eventSearchForm"
                          action="${biocacheServiceUrl}/occurrences/batchSearch" method="POST">
                        <div class="row">
                            <div class="col-sm-8">
                                <div class="form-group">
                                    <label for="event_ids"><g:message code="home.index.eventsearch.general.des"
                                                                      default="Search across event ID, parent event ID, field number and dataset / survey name."/>
                                    </label>
                                    <br/>
                                    <label>
                                        <g:message code="home.index.eventsearch.general.des01" default="Enter a list of terms (one per line)."/>
                                    </label>

                                    <textarea name="queries" id="event_keywords" class="form-control" rows="5" cols="60"></textarea>
                                </div>
                                <input type="hidden" name="redirectBase"
                                       value="${serverName}${request.contextPath}/occurrences/search" class="form-control">
                                <input type="hidden" name="field" value="text_eventID, text_parentEventID, text_fieldNumber, text_datasetName" class="form-control">
                                <input type="hidden" name="action" value="Search" />
                                <input type="submit"
                                       value="${g.message(code:"button.search", default:"Search")}" class="btn btn-primary" />
                            </div>
                        </div>
                    </form>
                    <br>
                    <form name="eventIDSearchForm" id="eventIDSearchForm"
                          action="${biocacheServiceUrl}/occurrences/batchSearch" method="POST">
                        <div class="row">
                            <div class="col-sm-8">
                                <div class="form-group">
                                    <label for="event_ids"><g:message code="home.index.eventsearch.des01"
                                                                              default="Enter a list of parent event IDs (one per line)."/></label>
                                    <textarea name="queries" id="event_ids" class="form-control" rows="5" cols="60"></textarea>
                                </div>
                                <input type="hidden" name="redirectBase"
                                       value="${serverName}${request.contextPath}/occurrences/search" class="form-control">
                                <input type="hidden" name="field" value="text_eventID" class="form-control">
                                <input type="hidden" name="action" value="Search" />
                                <input type="submit"
                                       value="${g.message(code:"button.search", default:"Search")}" class="btn btn-primary" />
                            </div>
                        </div>
                    </form>
                    <br>
                    <form name="parentEventIDSearchForm" id="parentEventIDSearchForm"
                          action="${biocacheServiceUrl}/occurrences/batchSearch" method="POST">
                        <div class="row">
                            <div class="col-sm-8">
                                <div class="form-group">
                                    <label for="event_ids"><g:message code="home.index.parenteventsearch.des01"
                                                                      default="Enter a list of parent event IDs (one per line)."/></label>
                                    <textarea name="queries" id="parent_event_ids" class="form-control" rows="5" cols="60"></textarea>
                                </div>
                                <input type="hidden" name="redirectBase"
                                       value="${serverName}${request.contextPath}/occurrences/search" class="form-control">
                                <input type="hidden" name="field" value="text_parentEventID" class="form-control">
                                <input type="hidden" name="action" value="Search" />
                                <input type="submit"
                                       value="${g.message(code:"button.search", default:"Search")}" class="btn btn-primary" />
                            </div>
                        </div>
                    </form>
                    <br>
                    <form name="fieldNumberSearchForm" id="fieldNumberSearchForm"
                          action="${biocacheServiceUrl}/occurrences/batchSearch" method="POST">
                        <div class="row">
                            <div class="col-sm-8">
                                <div class="form-group">
                                    <label for="event_ids"><g:message code="home.index.fieldnumbersearch.des01"
                                                                      default="Enter a list of field numbers (one per line)."/></label>
                                    <textarea name="queries" id="field_numbers" class="form-control" rows="5" cols="60"></textarea>
                                </div>
                                <input type="hidden" name="redirectBase"
                                       value="${serverName}${request.contextPath}/occurrences/search" class="form-control">
                                <input type="hidden" name="field" value="text_fieldNumber" class="form-control">
                                <input type="hidden" name="action" value="Search" />
                                <input type="submit"
                                       value="${g.message(code:"button.search", default:"Search")}" class="btn btn-primary" />
                            </div>
                        </div>
                    </form>
                    <br>
                    <form name="datasetNameSearchForm" id="datasetNameSearchForm"
                          action="${biocacheServiceUrl}/occurrences/batchSearch" method="POST">
                        <div class="row">
                            <div class="col-sm-8">
                                <div class="form-group">
                                    <label for="event_ids"><g:message code="home.index.datasetnamesearch.des01"
                                                                      default="Enter a list of dataset / survey names (one per line)."/></label>
                                    <textarea name="queries" id="dataset_name" class="form-control" rows="5" cols="60"></textarea>
                                </div>
                                <input type="hidden" name="redirectBase"
                                       value="${serverName}${request.contextPath}/occurrences/search" class="form-control">
                                <input type="hidden" name="field" value="text_datasetName" class="form-control">
                                <input type="hidden" name="action" value="Search" />
                                <input type="submit"
                                       value="${g.message(code:"button.search", default:"Search")}" class="btn btn-primary" />
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

                                            <g:if test="${grailsApplication.config.getProperty('skin.useAlaSpatialPortal', Boolean)}">
                                                <p><g:message
                                                        code="search.map.importText.spatialportal"
                                                        args="${[ grailsApplication.config.getProperty('spatial.baseUrl') ]}"/>
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
