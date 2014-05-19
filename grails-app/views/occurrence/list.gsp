<%--
  Created by IntelliJ IDEA.
  User: dos009@csiro.au
  Date: 11/02/14
  Time: 10:52 AM
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" %>
<g:set var="startPageTime" value="${System.currentTimeMillis()}"/>
<g:set var="queryDisplay" value="${sr?.queryTitle?:searchRequestParams?.displayString?:''}"/>
<!DOCTYPE html>
<html>
<head>
    <meta name="svn.revision" content="${meta(name: 'svn.revision')}"/>
    <meta name="layout" content="${grailsApplication.config.skin.layout}"/>
    <title>Search: ${sr?.queryTitle.replaceAll("<(.|\n)*?>", '')} | <alatag:message code="search.heading.list" default="Search results"/> | ${grailsApplication.config.skin.orgNameLong}</title>
    %{--<script src="http://maps.google.com/maps/api/js?v=3.2&sensor=false"></script>--}%
    <script type="text/javascript" src="http://www.google.com/jsapi"></script>
    <r:require modules="search, leaflet, slider, qtip, nanoscroller, amplify"/>
    <script type="text/javascript">
        // single global var for app conf settings
        <g:set var="fqParams" value="${(params.fq) ? "&fq=" + params.list('fq')?.join('&fq=') : ''}"/>
        <g:set var="searchString" value="${raw(sr?.urlParameters).encodeAsURL()}"/>
        var BC_CONF = {
            contextPath: "${request.contextPath}",
            serverName: "${grailsApplication.config.serverName}${request.contextPath}",
            searchString: "${searchString}", //  JSTL var can contain double quotes // .encodeAsJavaScript()
            facetQueries: "${fqParams.encodeAsURL()}",
            queryString: "${queryDisplay.encodeAsJavaScript()}",
            bieWebappUrl: "${grailsApplication.config.bie.baseUrl}",
            biocacheServiceUrl: "${alatag.getBiocacheAjaxUrl()}",
            skin: "${grailsApplication.config.skin.layout}",
            defaultListView: "${grailsApplication.config.defaultListView}",
            resourceName: "${grailsApplication.config.skin.orgNameLong}",
            facetLimit: "${grailsApplication.config.facets.limit?:50}",
            queryContext: "${grailsApplication.config.biocache.queryContext}",
            zoomOutsideScopedRegion: Boolean("${grailsApplication.config.map.zoomOutsideScopedRegion}"),
            //mapDefaultCentreCoords:"${grailsApplication.config.mapDefaultCentreCoords}",
            //mapDefaultZoom:"${grailsApplication.config.mapDefaultZoom}",
            hasMultimedia: ${hasImages?:'false'}, // will be either true or false
            chartsBgColour: "${grailsApplication.config.chartsBgColour?:'#fffef7'}"
        };

        google.load('maps','3.5',{ other_params: "sensor=false" });
        google.load("visualization", "1", {packages:["corechart"]});
    </script>
</head>

<body>
    <div id="listHeader" class="row-fluid">
        <div class="span5">
            <h1><alatag:message code="search.heading.list" default="Search results"/><a name="resultsTop">&nbsp;</a></h1>
        </div>
        <div id="searchBoxZ" class="span7 text-right">
            <form action="${g.createLink(controller: 'occurrence', action: 'search')}" id="solrSearchForm" class="">
                <div id="advancedSearchLink"><a href="${g.createLink(uri: '/search')}#tab_advanceSearch">Advanced search</a></div>
                <div class="input-append">
                    <input type="text" id="taxaQuery" name="taxa" class="input-xlarge" value="${params.list('taxa').join(' OR ')}">
                    <button type="submit" id="solrSubmit" class="btn">Quick search</button>
                </div>
            </form>
        </div>
        <input type="hidden" id="userId" value="${userId}">
        <input type="hidden" id="userEmail" value="${userEmail}">
        <input type="hidden" id="lsid" value="${params.lsid}"/>
    </div>
    <g:if test="${errors}">
        <div class="searchInfo searchError">
            <h2 style="padding-left: 10px;">Error</h2>
            <h4>${errors}</h4>
        </div>
    </g:if>
    <g:elseif test="${!sr || sr.totalRecords == 0}">
        <div class="searchInfo searchError">
            <p>No records found for <span class="queryDisplay">${raw(queryDisplay)?:params.q}</span></p>
        </div>
    </g:elseif>
    <g:else>
        <!--  first row (#searchInfoRow), contains customise facets button and number of results for query, etc.  -->
        <div class="row-fluid clearfix" id="searchInfoRow">
            <!-- facet column -->
            <div class="span3">
                <div id="customiseFacetsButton" class="btn-group">
                    <a class="btn btn-small dropdown-toggle tooltips" data-toggle="dropdown" href="#" title="Customise the contents of this column">
                        <i class="icon-cog"></i> <g:message code="search.filter.customise"/>
                        <span class="caret"></span>
                    </a>
                    <div class="dropdown-menu" role="menu"> <%--facetOptions--%>
                        <h4>Select the filter categories that you want to appear in the &quot;Refine results&quot; column</h4>
                        <%-- <form:checkboxes path="facets" items="${defaultFacets}" itemValue="key" itemLabel="value" /> --%>
                        <div id="facetCheckboxes">
                            Select: <a href="#" id="selectAll">All</a> | <a href="#" id="selectNone">None</a>
                            &nbsp;&nbsp;
                            <button  id="updateFacetOptions" class="btn btn-primary btn-small">Update</button>
                            &nbsp;&nbsp;
                            <g:set var="resetTitle" value="Restore default settings"/>
                            <button id="resetFacetOptions" class="btn btn-small" title="${resetTitle}">Reset to defaults</button>
                            <br/>
                            %{--<div class="facetsColumn">--}%
                            <%-- iterate over the groupedFacets, checking the defaultFacets for each entry --%>
                            <g:set var="count" value="${0}"/>
                            <g:each var="group" in="${groupedFacets}">
                                <div class="facetsColumn">
                                    <div class="facetGroupName">${group.key}</div>
                                    <g:each in="${group.value}" var="facetFromGroup">
                                        %{--<g:set var="facet" value="${defaultFacets.get(facetFromGroup)}"/>--}%
                                        <g:if test="${defaultFacets.containsKey(facetFromGroup)}">
                                            <g:set var="count" value="${count+1}"/>
                                            <input type="checkbox" name="facets" class="facetOpts" value="${facetFromGroup}"
                                                ${(defaultFacets.get(facetFromGroup)) ? 'checked=checked' : ''}>&nbsp;<alatag:message code="facet.${facetFromGroup}"/><br>
                                        </g:if>
                                    </g:each>
                                </div>
                            </g:each>
                            %{--</div>--}%
                            <g:if test="${false && dynamicFacets}"><!-- INACTIVE - user not able to toggle display of custom fields for now -->
                                <div class="facetsColumn">
                                    <h4>Custom facets</h4>
                                    <g:each var="facet" in="${dynamicFacets}">
                                        <input type="checkbox" name="facets" class="facetOpts" value="${facet.name}"
                                            ${(facet.name) ? 'checked="checked"' : ''}>&nbsp;${facet.displayName}<%--<alatag:formatDynamicFacetName fieldName="${facet.name}"/>--%><br>
                                    </g:each>
                                </div>
                            </g:if>
                        </div>
                        %{--<div class="clearfix"></div>--}%
                    </div>
                </div>
            </div><!-- /.span3 -->
            <div class="span9">
                <a name="map" class="jumpTo"></a><a name="list" class="jumpTo"></a>
                <g:if test="${flash.message}">
                    <div class="alert alert-info" style="margin-left: -30px;">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        ${flash.message}
                    </div>
                </g:if>
                <div id="resultsReturned">
                    %{--<div class="alert alert-info ">--}%
                        <span id="returnedText"><strong><g:formatNumber number="${sr.totalRecords}" format="#,###,###"/></strong> results for</span>
                        <span class="queryDisplay"><strong>${raw(queryDisplay)}</strong></span>&nbsp;&nbsp;
                    %{--</div>--}%
                    %{--<g:set var="hasFq" value="${false}"/>--}%
                    <g:if test="${sr.activeFacetMap?.size() > 0}">
                        <div class="activeFilters">
                            <b><alatag:message code="search.filters.heading" default="Current filters"/></b>:&nbsp;
                            <g:each var="fq" in="${sr.activeFacetMap}">
                                <g:if test="${fq.key}">
                                    <g:set var="hasFq" value="${true}"/>
                                    <alatag:currentFilterItem item="${fq}" cssClass="btn btn-mini" addCloseBtn="${true}"/>
                                </g:if>
                            </g:each>
                            <g:if test="${sr.activeFacetMap?.size() > 1}">
                                <button class="btn btn-primary btn-mini activeFilter" data-facet="all"
                                        title="Click to clear all filters"><span
                                        class="closeX">&gt;&nbsp;</span>Clear all</button>
                            </g:if>
                        </div>
                    </g:if>
                    <%-- jQuery template used for taxon drop-downs --%>
                    <div class="btn-group hide" id="template">
                        <a class="btn btn-small" href="" id="taxa_" title="view species page" target="BIE">placeholder</a>
                        <button class="btn btn-small dropdown-toggle" data-toggle="dropdown" title="click for more info on this query">
                            <span class="caret"></span>
                        </button>
                        <div class="dropdown-menu" aria-labelledby="taxa_">
                            <div class="taxaMenuContent">
                                The search results include records for synonyms and child taxa of
                                <b class="nameString">placeholder</b> (<span class="speciesPageLink">link placeholder</span>).

                                <form name="raw_taxon_search" class="rawTaxonSearch" action="${request.contextPath}/occurrences/search/taxa" method="POST">
                                    <div class="refineTaxaSearch">
                                        The result set contains records provided under the following names:
                                        <input type="submit" class="btn btn-small rawTaxonSumbit"
                                               value="Refine search" title="Restrict results to the selected names">
                                        <div class="rawTaxaList">placeholder taxa list</div>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>
            </div><!-- /.span9 -->
        </div><!-- /#searchInfoRow -->
        <!--  Second row - facet column and results column -->
        <div class="row-fluid" id="content">
            <div class="span3">
                <g:render template="facets" />
            </div>
            <g:set var="postFacets" value="${System.currentTimeMillis()}"/>
            <div id="content2" class="span9">
                <g:if test="${grailsApplication.config.skin.useAlaSpatialPortal?.toBoolean()}">
                    <div id="alert" class="modal hide" tabindex="-1" role="dialog" aria-labelledby="alertLabel" aria-hidden="true">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                            <h3 id="myModalLabel">Email alerts</h3>
                        </div>
                        <div class="modal-body">
                            <div class="">
                                <a href="#alertNewRecords" id="alertNewRecords" class="btn tooltips" data-method="createBiocacheNewRecordsAlert"
                                   title="Notify me when new records come online for this search">Get
                                email alerts for new <u>records</u> </a>
                            </div>
                            <br/>
                            <div class="">
                                <a href="#alertNewAnnotations" id="alertNewAnnotations" data-method="createBiocacheNewAnnotationsAlert"
                                   class="btn tooltips" title="Notify me when new annotations (corrections, comments, etc) come online for this search">Get
                                email alerts for new <u>annotations</u></a>
                            </div>
                            <p>&nbsp;</p>
                            <p><a href="http://alerts.ala.org.au/notification/myAlerts">View your current alerts</a></p>
                        </div>
                        <div class="modal-footer">
                            <button class="btn" data-dismiss="modal" aria-hidden="true">Close</button>
                            %{--<button class="btn btn-primary">Save changes</button>--}%
                        </div>
                    </div><!-- /#alerts -->
                </g:if>

                <g:render template="download"/>
                <div style="display:none">

                </div>
                <div class="tabbable">
                    <ul class="nav nav-tabs" data-tabs="tabs">
                        <li class="active"><a id="t1" href="#recordsView" data-toggle="tab">Records</a></li>
                        <li><a id="t2" href="#mapView" data-toggle="tab">Map</a></li>
                        <li><a id="t3" href="#chartsView" data-toggle="tab">Charts</a></li>
                        <g:if test="${showSpeciesImages}">
                            <li><a id="t4" href="#speciesImages" data-toggle="tab">Species images</a></li>
                        </g:if>
                        <g:if test="${hasImages}">
                            <li><a id="t5" href="#recordImages" data-toggle="tab">Record images</a></li>
                        </g:if>
                    </ul>
                </div>
                <div class="tab-content clearfix">
                    <div class="tab-pane solrResults active" id="recordsView">
                        <div id="searchControls" class="row-fluid">
                            <div class="span4">
                                <div id="downloads" class="btn btn-small">
                                    <a href="#download" role="button" data-toggle="modal" class="tooltips" title="Download all ${g.formatNumber(number:sr.totalRecords, format:"#,###,###")} records OR species checklist"><i class="icon-download"></i> Downloads</a>
                                </div>
                                <g:if test="${grailsApplication.config.skin.useAlaSpatialPortal?.toBoolean()}">
                                    <div id="alerts" class="btn btn-small">
                                        <a href="#alert" role="button" data-toggle="modal" class="tooltips" title="Get email alerts for this search"><i class="icon-bell"></i> Alerts</a>
                                    </div>
                                </g:if>
                            </div>

                            <div id="sortWidgets" class="span8">
                                <span class="hidden-phone">per </span>page:
                                <select id="per-page" name="per-page" class="input-small">
                                    <g:set var="pageSizeVar" value="${params.pageSize?:params.max?:"20"}"/>
                                    <option value="10" <g:if test="${pageSizeVar == "10"}">selected</g:if>>10</option>
                                    <option value="20" <g:if test="${pageSizeVar == "20"}">selected</g:if>>20</option>
                                    <option value="50" <g:if test="${pageSizeVar == "50"}">selected</g:if>>50</option>
                                    <option value="100" <g:if test="${pageSizeVar == "100"}">selected</g:if>>100</option>
                                </select>&nbsp;
                                <g:set var="useDefault" value="${(!params.sort && !params.dir) ? true : false }"/>
                                sort:
                                <select id="sort" name="sort" class="input-small">
                                    <option value="score" <g:if test="${params.sort == 'score'}">selected</g:if>>Best match</option>
                                    <option value="taxon_name" <g:if test="${params.sort == 'taxon_name'}">selected</g:if>>Taxon name</option>
                                    <option value="common_name" <g:if test="${params.sort == 'common_name'}">selected</g:if>>Common name</option>
                                    <option value="occurrence_date" <g:if test="${params.sort == 'occurrence_date'}">selected</g:if>>${skin == 'avh' ? 'Collecting date' : 'Record date'}</option>
                                    <g:if test="${skin != 'avh'}">
                                        <option value="record_type" <g:if test="${params.sort == 'record_type'}">selected</g:if>>Record type</option>
                                    </g:if>
                                    <option value="first_loaded_date" <g:if test="${useDefault || params.sort == 'first_loaded_date'}">selected</g:if>>Date added</option>
                                    <option value="last_assertion_date" <g:if test="${params.sort == 'last_assertion_date'}">selected</g:if>>Last annotated</option>
                                </select>&nbsp;
                                order:
                                <select id="dir" name="dir" class="input-small">
                                    <option value="asc" <g:if test="${params.dir == 'asc'}">selected</g:if>>Ascending</option>
                                    <option value="desc" <g:if test="${useDefault || params.dir == 'desc'}">selected</g:if>>Descending</option>
                                </select>
                            </div><!-- sortWidget -->
                        </div><!-- searchControls -->
                        <div id="results">
                            <g:set var="startList" value="${System.currentTimeMillis()}"/>
                            <g:each var="occurrence" in="${sr.occurrences}">
                                <alatag:formatListRecordRow occurrence="${occurrence}" />
                            </g:each>
                        </div><!--close results-->
                        <g:if test="${params.benchmarks}">
                            <div style="color:#ddd;">
                                list render time = ${(System.currentTimeMillis() - startList)} ms<br>
                            </div>
                        </g:if>
                        <div id="searchNavBar" class="pagination">
                            <g:paginate total="${sr.totalRecords}" max="${sr.pageSize}" offset="${sr.startIndex}" params="${[taxa:params.taxa, q:params.q, fq:params.fq]}"/>
                        </div>
                    </div><!--end solrResults-->
                    <div id="mapView" class="tab-pane">
                        <g:render template="map"
                                  model="[mappingUrl:alatag.getBiocacheAjaxUrl(),
                                          searchString: searchString,
                                          queryDisplayString:queryDisplay,
                                          facets:sr.facetResults,
                                          defaultColourBy:grailsApplication.config.map.defaultFacetMapColourBy
                                  ]"
                        />
                        <div id='envLegend'></div>
                    </div><!-- end #mapwrapper -->
                    <div id="chartsView" class="tab-pane">
                        <style type="text/css">
                           #charts div { display: inline-flex; padding-left:20px; }
                        </style>
                        <div id="charts" class="row-fluid"></div>
                    </div><!-- end #chartsWrapper -->
                    <g:if test="${showSpeciesImages}">
                        <div id="speciesImages" class="tab-pane">
                            <h3>Representative images of species</h3>
                            <div id="speciesGalleryControls">
                                Filter by group
                                <select id="speciesGroup">
                                    <option>no species groups loaded</option>
                                </select>
                                &nbsp;
                                Sort by
                                <select id="speciesGallerySort">
                                    <option value="common">Common name</option>
                                    <option value="taxa">Scientific name</option>
                                    <option value="count">Record count</option>
                                </select>
                            </div>
                            <div id="speciesGallery">[image gallery should appear here]</div>
                            <div id="loadMoreSpecies" style="display:none;">
                                <button class="btn">Show more images</button>
                                <img style="display:none;" src="${request.contextPath}/images/indicator.gif"/>
                            </div>
                        </div><!-- end #speciesWrapper -->
                    </g:if>
                    <g:if test="${hasImages}">
                        <div id="recordImages" class="tab-pane">
                            <h3>Images from occurrence records</h3>
                            <%--<p>(see also <a href="#tab_speciesImages">representative species images</a>)</p>--%>
                            <div id="imagesGrid">
                                loading images...
                            </div>
                            <div id="loadMoreImages" style="display:none;">
                                <button class="btn">Show more images</button>
                            </div>
                        </div><!-- end #imagesWrapper -->
                    </g:if>
                </div><!-- end .css-panes -->
                <form name="raw_taxon_search" class="rawTaxonSearch" id="rawTaxonSearchForm" action="${request.contextPath}/occurrences/search/taxa" method="POST">
                        <%-- taxon concept search drop-down div are put in here via Jquery --%>
                    <div style="display:none;" >
                    </div>
                </form>
            </div>
        </div>
    </g:else>
<g:if test="${params.benchmarks}">
    <g:set var="endPageTime" value="${System.currentTimeMillis()}"/>
    <div style="color:#ddd;">
        post-facets time = ${(endPageTime - postFacets)} ms<br>
        page render time = ${(endPageTime - startPageTime)} ms<br>
        biocache-service GET time = ${wsTime} ms<br>
        controller processing time = ${processingTime} ms<br>
        total processing time = ${(endPageTime - startPageTime) + processingTime} ms
    </div>
</g:if>
</body>
</html>