<%--
  Created by IntelliJ IDEA.
  User: dos009@csiro.au
  Date: 11/02/14
  Time: 10:52 AM
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" %>
<g:set var="startPageTime" value="${System.currentTimeMillis()}"/>
<g:set var="queryDisplay" value="${sr?.queryTitle ?: searchRequestParams?.displayString ?: ''}"/>
<g:set var="searchQuery" value="${grailsApplication.config.skin?.useAlaBie?.toBoolean() ? 'taxa' : 'q'}"/>
<g:set var="authService" bean="authService"></g:set>
<!DOCTYPE html>
<html>
<head>
    <meta name="svn.revision" content="${meta(name: 'svn.revision')}"/>
<meta name="layout" content="${grailsApplication.config.skin.layout}"/>
<meta name="section" content="search"/>
<meta name="breadcrumbParent" content="${request.contextPath ?: '/'},${message(code: "search.heading.list")}"/>
<meta name="breadcrumb" content="${message(code: "list.search.results")}"/>
<title><g:message code="list.title"
                  default="Search"/>: ${sr?.queryTitle?.replaceAll("<(.|\n)*?>", '')} | <alatag:message
        code="search.heading.list" default="Search results"/> | ${grailsApplication.config.skin.orgNameLong}</title>

<g:if test="${grailsApplication.config.google.apikey}">
    <script src="https://maps.googleapis.com/maps/api/js?key=${grailsApplication.config.google.apikey}"
            type="text/javascript"></script>
</g:if>

<script type="text/javascript" src="https://www.google.com/jsapi"></script>
<script type="text/javascript">
    // single global var for app conf settings
    <g:set var="fqParams" value="${(params.fq) ? "&fq=" + params.list('fq')?.join('&fq=') : ''}"/>
    <g:set var="searchString" value="${raw(sr?.urlParameters).encodeAsURL()}"/>
    var BC_CONF = {
        contextPath: "${request.contextPath}",
            serverName: "${grailsApplication.config.serverName}${request.contextPath}",
            searchString: "${searchString}", //  JSTL var can contain double quotes // .encodeAsJavaScript()
            facetQueries: "${fqParams.encodeAsURL()}",
            facetDownloadQuery: "${searchString}",
            maxFacets: "${grailsApplication.config.facets?.max ?: '4'}",
            queryString: "${queryDisplay.encodeAsJavaScript()}",
            bieWebappUrl: "${grailsApplication.config.bie.baseUrl}",
            bieWebServiceUrl: "${grailsApplication.config.bieService.baseUrl}",
            biocacheServiceUrl: "${alatag.getBiocacheAjaxUrl()}",
            collectoryUrl: "${grailsApplication.config.collectory.baseUrl}",
            alertsUrl: "${grailsApplication.config.alerts.baseUrl}",
            skin: "${grailsApplication.config.skin.layout}",
            defaultListView: "${grailsApplication.config.defaultListView}",
            resourceName: "${grailsApplication.config.skin.orgNameLong}",
            facetLimit: "${grailsApplication.config.facets.limit ?: 50}",
            queryContext: "${grailsApplication.config.biocache.queryContext}",
            selectedDataResource: "${selectedDataResource}",
            autocompleteHints: ${grailsApplication.config.bie?.autocompleteHints?.encodeAsJson() ?: '{}'},
            zoomOutsideScopedRegion: Boolean("${grailsApplication.config.map.zoomOutsideScopedRegion}"),
            hasMultimedia: ${hasImages ?: 'false'}, // will be either true or false
            locale: "${org.springframework.web.servlet.support.RequestContextUtils.getLocale(request)}",
            imageServiceBaseUrl:"${grailsApplication.config.images.baseUrl}",
            likeUrl: "${createLink(controller: 'imageClient', action: 'likeImage')}",
            dislikeUrl: "${createLink(controller: 'imageClient', action: 'dislikeImage')}",
            userRatingUrl: "${createLink(controller: 'imageClient', action: 'userRating')}",
            disableLikeDislikeButton: ${authService.getUserId() ? false : true},
            addLikeDislikeButton: ${(grailsApplication.config.addLikeDislikeButton == false) ? false : true},
            addPreferenceButton: <imageClient:checkAllowableEditRole/> ,
            userRatingHelpText: '<div><b>Up vote (<i class="fa fa-thumbs-o-up" aria-hidden="true"></i>) an image:</b>'+
' Image supports the identification of the species or is representative of the species.  Subject is clearly visible including identifying features.<br/><br/>'+
'<b>Down vote (<i class="fa fa-thumbs-o-down" aria-hidden="true"></i>) an image:</b>'+
' Image does not support the identification of the species, subject is unclear and identifying features are difficult to see or not visible.<br/></div>',
            savePreferredSpeciesListUrl: "${createLink(controller: 'imageClient', action: 'saveImageToSpeciesList')}",
            getPreferredSpeciesListUrl:  "${createLink(controller: 'imageClient', action: 'getPreferredSpeciesImageList')}"
        };
</script>

<asset:javascript src="biocache-hubs.js"/>
<asset:javascript src="ala/images-client.js"/>
<asset:javascript src="leafletPlugins.js"/>
<asset:javascript src="listThirdParty.js"/>
<asset:javascript src="search.js"/>
<asset:javascript src="mapCommon.js"/>
<asset:javascript src="ala/ala-charts.js"/>

<asset:stylesheet src="print.css" media="print" />
<asset:stylesheet src="searchMap.css"/>
<asset:stylesheet src="search.css"/>
<asset:stylesheet src="print-search.css" media="print" />
<asset:stylesheet src="ala/images-client.css"/>
<asset:stylesheet src="leafletPlugins.css"/>
<asset:stylesheet src="listThirdParty.css"/>
<asset:stylesheet src="ala/ala-charts.css"/>


<g:if test="${grailsApplication.config.skin.useAlaBie?.toString()?.toBoolean()}">
    <asset:javascript src="bieAutocomplete.js"/>
</g:if>
<asset:script type="text/javascript">
    <g:if test="${!grailsApplication.config.google.apikey}">
        google.load('maps','3.5',{ other_params: "sensor=false" });
    </g:if>
</asset:script>
</head>

<body class="occurrence-search-">
    <div id="listHeader" class="heading-bar row">
        <div class="col-sm-5 col-md-5">
            <h1><alatag:message code="search.heading.list" default="Search results"></alatag:message><a
        name="resultsTop">&nbsp;</a></h1>
        </div>

        <div id="searchBoxZ" class="text-right col-sm-7 col-md-7">
            <form action="${g.createLink(controller: 'occurrences', action: 'search')}" id="solrSearchForm" class="form-horizontal">
                <div id="advancedSearchLink">
                    <a href="${g.createLink(uri: '/search')}#tab_advanceSearch" class="tooltips" title="<g:message code="list.advancedsearchlink.tooltip" default="Go to advanced search form"></g:message>">
                        <i class="fa fa-cogs"></i>
                        <g:message code="list.advancedsearchlink.navigator" default="Advanced search"></g:message>
                    </a>
                </div>
                <div class="input-group pull-right col-sm-7 col-md-7">
                    <input type="text" id="taxaQuery" name="${searchQuery}" class="form-control"
                           value="${params.list(searchQuery).join(' OR ')}"/>
                    <span class="input-group-btn">
                        <input class="form-control btn btn-default" type="submit" id="solrSubmit" value="${g.message(code:"list.advancedsearchlink.button.label", default:"Quick search")}"/>
                    </span>
                </div>
            </form>
        </div>
        <input type="hidden" id="userId" value="${userId}" class="form-control">
        <input type="hidden" id="userEmail" value="${userEmail}" class="form-control">
        <input type="hidden" id="lsid" value="${params.lsid}" class="form-control">
    </div>
    <g:if test="${flash.message}">
        <div id="errorAlert" class="alert alert-danger alert-dismissible alert-dismissable" role="alert">
            <button type="button" class="close" onclick="$(this).parent().hide()" aria-label="Close"><span
                    aria-hidden="true">&times;</span></button>
            <h4>${flash.message}</h4>

            <p>Please contact <a
                    href="mailto:${grailsApplication.config.supportEmail ?: 'support@ala.org.au'}?subject=biocache error"
                    style="text-decoration: underline;">support</a> if this error continues</p>
        </div>
    </g:if>
    <g:if test="${errors}">
        <div class="searchInfo searchError">
            <h2 style="padding-left: 10px;"><g:message code="list.01.error" default="Error"/></h2>
            <h4>${errors}</h4>
            Please contact <a
                href="mailto:${grailsApplication.config.supportEmail ?: 'support@ala.org.au'}?subject=biocache error">support</a> if this error continues
        </div>
    </g:if>
    <g:elseif test="${!sr || sr.totalRecords == 0}">
        <div class="searchInfo searchError">
            <g:if test="${queryDisplay =~ /lsid/ && params.taxa}"><!-- ${raw(queryDisplay)} -->
                <g:if test="${queryDisplay =~ /span/}">
                    <p><g:message code="list.02.p01" default="No records found for"/> <span
                            class="queryDisplay">${raw(queryDisplay.replaceAll('null:', ''))}</span></p>
                </g:if>
                <g:else>
                    <p><g:message code="list.02.p02" default="No records found for"/> <span
                            class="queryDisplay">${params.taxa}</span></p>
                </g:else>
                <p><g:message code="list.02.p03.01" default="Trying search for"/> <a
                        href="?q=text:${params.taxa}"><g:message code="list.02.p03.02"
                                                                 default="text"/>:${params.taxa}</a>
                </p>
            </g:if>
            <g:elseif test="${queryDisplay =~ /^text:/ && queryDisplay =~ /\s+/ && !(queryDisplay =~ /\bOR\b/)}">
                <p><g:message code="list.03.p01" default="No records found for"/> <span
                        class="queryDisplay">${raw(queryDisplay)}</span></p>
                <g:set var="queryTerms" value="${queryDisplay.split(" ")}"/>
                <g:set var="newQueryStr" value="${queryTerms.join(" OR ").replaceAll("\"","").replaceAll("text:","")}"/>
                <p><g:message code="list.03.p02" default="Trying search for"/> <a
                        href="?q=${newQueryStr}">${newQueryStr}</a></p>
            </g:elseif>
            <g:else>
                <p><g:message code="list.03.p03" default="No records found for"/> <span
                        class="queryDisplay">${raw(queryDisplay) ?: params.q ?: params.taxa}</span></p>
            </g:else>
        </div>
    </g:elseif>
    <g:else>
        <!--  first row (#searchInfoRow), contains customise facets button and number of results for query, etc.  -->
        <div class="clearfix row" id="searchInfoRow">
            <!-- facet column -->
            <div class="col-md-3 col-sm-3">
                <!-- Trigger the modal with a button -->
                <a class="btn tooltips btn-default btn-sm" data-toggle="modal" data-target="#facetConfigDialog" href="#"
                   title="Customise the contents of this column">
                    <i class="fa fa-cog"></i>&nbsp;&nbsp;<g:message code="search.filter.customise"/>
                </a>

                <!-- Modal -->
                <div id="facetConfigDialog" class="modal fade" role="dialog" aria-labelledby="customiseFacetsLabel">
                    <div class="modal-dialog modal-lg">
                        <!-- Modal content-->
                        <div class="modal-content">
                            <div class="modal-header">
                                <button type="button" class="close" data-dismiss="modal">&times;</button>
                                <h4 class="modal-title" id="customiseFacetsLabel">
                                    <g:message code="list.customisefacetsbutton.div01.title" default="Customise filter options"/>
                                    <span id="customiseFacetsHint"><g:message code="list.customisefacetsbutton.title.hint" default="Scroll to see full list"/></span>
                                </h4>
                            </div>
                            <div class="modal-body">
                                <div id="facetCheckboxes">
                                    <div class="row padding-left-1">
                                        <%-- iterate over the groupedFacets, checking the default facets for each entry --%>
                                        <g:set var="count" value="0"></g:set>
                                        <g:each var="group" in="${groupedFacets}">
                                            <g:if test="${defaultFacets.find { key, value -> group.value.any { it == key } }}">
                                                <div class="facetsColumn">
                                                    <div class="facetGroupName"><g:message code="facet.group.${group.key}" default="${group.key}"/></div>
                                                    <g:each in="${group.value}" var="facetFromGroup">
                                                        <g:if test="${defaultFacets.containsKey(facetFromGroup)}">
                                                            <g:set var="count" value="${count + 1}"/>
                                                            <input type="checkbox" name="facets" class="facetOpts" value="${facetFromGroup}"
                                                                ${(defaultFacets.get(facetFromGroup)) ? 'checked=checked' : ''}>&nbsp;<alatag:message
                                                                code="facet.${facetFromGroup}" default="${facetFromGroup}"/><br/>
                                                        </g:if>
                                                    </g:each>
                                                </div>
                                            </g:if>
                                        </g:each>
                                    </div>
                                </div>
                            </div>
                            <div class="modal-footer">
                                <span id="facetConfigErrors" class="collapse bg-danger pull-left"></span>
                                <button id="resetFacetOptions" class="btn btn-default btn-sm margin-left-5" title="${resetTitle}"><g:message
                                        code="list.facetcheckboxes.button.resetfacetoptions"
                                        default="Reset to defaults"/></button>
                                <button class="btn btn-default btn-sm" data-dismiss="modal"><g:message
                                        code="list.facetcheckboxes.button.closeFacetoptions" default="Close"/></button>
                                <button id="updateFacetOptions" class="btn btn-primary btn-sm"><g:message
                                        code="list.facetcheckboxes.button.updatefacetoptions" default="Update"/></button>
                            </div>
                        </div>
                    </div>
                </div>
            </div><!-- /.col-md-3 -->
            <!-- Results column -->
            <div class="col-sm-9 col-md-9">
                <a name="map" class="jumpTo"></a><a name="list" class="jumpTo"></a>
                <g:if test="${false && flash.message}"><%-- OFF for now --%>
                    <div class="alert alert-info alert-dismissable" style="margin-left: -30px;">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        ${flash.message}
                    </div>
                </g:if>
                <g:if test="${grailsApplication.config.useDownloadPlugin?.toBoolean()}">
                    <div id="downloads" class="btn btn-primary pull-right">
                        <a href="${g.createLink(uri: '/download')}?searchParams=${sr?.urlParameters?.encodeAsURL()}&targetUri=${(request.forwardURI)}&totalRecords=${sr.totalRecords}"
                           class="tooltips newDownload"
                           title="Download all ${g.formatNumber(number: sr.totalRecords, format: "#,###,###")} records"><i
                                class="fa fa-download"></i>
                            &nbsp;&nbsp;<g:message code="list.downloads.navigator" default="Download"/></a>
                    </div>
                </g:if>
                <div id="resultsReturned">
                    <g:render template="sandboxUploadSourceLinks" model="[dataResourceUid: selectedDataResource]"/>
                    <span id="returnedText"><strong><g:formatNumber number="${sr.totalRecords}"
                                                                    format="#,###,###"/></strong> <g:message
                            code="list.resultsretuened.span.returnedtext" default="results for"/></span>
                    <span class="queryDisplay"><strong>${raw(queryDisplay)}</strong></span>&nbsp;&nbsp;
                    <g:if test="${params.taxa && queryDisplay.startsWith("text:")}">
                        %{--Fallback taxa search to "text:", so provide feedback to user about this--}%
                        (<g:message code="list.taxa.notfound" args="${[params.taxa]}" default="(Note: no matched taxon name found for {0})"/>)
                    </g:if>
                    %{--<g:set var="hasFq" value="${false}"/>--}%
                    <g:if test="${sr.activeFacetMap?.size() > 0 || params.wkt || params.radius}">
                        <div class="activeFilters">
                            <b><alatag:message code="search.filters.heading" default="Current filters"/></b>:&nbsp;
                            <g:each var="fq" in="${sr.activeFacetMap}">
                                <g:if test="${fq.key}">
                                    <g:set var="hasFq" value="${true}"/>
                                    <alatag:currentFilterItem item="${fq}" cssClass="btn btn-default btn-xs" addCloseBtn="${true}"/>
                                </g:if>
                            </g:each>
                            <g:if test="${params.wkt}"><%-- WKT spatial filter   --%>
                                <g:set var="spatialType" value="${params.wkt =~ /^\w+/}"/>
                                <a href="${alatag.getQueryStringForWktRemove()}" class="btn tooltips btn-default btn-xs"
                                   title="Click to remove this filter">Spatial filter: ${spatialType[0]}
                                    <span class="closeX">&times;</span>
                                </a>
                            </g:if>
                            <g:elseif test="${params.radius && params.lat && params.lon}">
                                <a href="${alatag.getQueryStringForRadiusRemove()}" class="btn tooltips btn-default btn-xs"
                                   title="Click to remove this filter">Spatial filter: CIRCLE
                                    <span class="closeX">&times;</span>
                                </a>
                            </g:elseif>
                            <g:if test="${sr.activeFacetMap?.size() > 1}">
                                <button class="btn btn-primary activeFilter btn-xs" data-facet="all"
                                        title="Click to clear all filters"><span
                                        class="closeX">&gt;&nbsp;</span><g:message code="list.resultsretuened.button01"
                                                                                   default="Clear all"/></button>
                            </g:if>
                        </div>
                    </g:if>
                <%-- jQuery template used for taxon drop-downs --%>
                    <div class="btn-group hide" id="template">
                        <a class="btn btn-default btn-sm" href="" id="taxa_" title="view species page" target="BIE"><g:message
                                code="list.resultsretuened.navigator01" default="placeholder"/></a>
                        <button class="btn dropdown-toggle btn-default btn-sm" data-toggle="dropdown"
                                title="click for more info on this query">
                            <span class="caret"></span>
                        </button>

                        <div class="dropdown-menu" aria-labelledby="taxa_">
                            <div class="taxaMenuContent">
                                <g:message code="list.resultsretuened.div01.des01"
                                           default="The search results include records for synonyms and child taxa of"/>
                                <b class="nameString"><g:message code="list.resultsretuened.div01.des02"
                                                                 default="placeholder"/></b> (<span
                                    class="speciesPageLink"><g:message code="list.resultsretuened.div01.des03"
                                                                       default="link placeholder"/></span>).

                                <form name="raw_taxon_search" class="rawTaxonSearch"
                                      action="${request.contextPath}/occurrences/search/taxa" method="POST">
                                    <div class="refineTaxaSearch">
                                        <g:message code="list.resultsretuened.form.des01"
                                                   default="The result set contains records provided under the following names"/>:
                                        <input type="submit" class="btn  btn-default btn-sm rawTaxonSumbit"
                                               value="<g:message code="list.resultsretuened.form.button01"
                                                                 default="Refine search"/>"
                                               title="Restrict results to the selected names">

                                        <div class="rawTaxaList"><g:message code="list.resultsretuened.form.div01"
                                                                            default="placeholder taxa list"/></div>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>
            </div><!-- /.col-md-9 -->
        </div><!-- /#searchInfoRow -->
        <!--  Second row - facet column and results column -->
        <div class="row" id="content">
            <div class="col-sm-3 col-md-3">
                <g:render template="facets"></g:render>
            </div>
            <g:set var="postFacets" value="${System.currentTimeMillis()}"/>
            <div id="content2" class="col-sm-9 col-md-9">
                <g:if test="${grailsApplication.config.alerts.baseUrl}">
                    <div id="alert" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="alertLabel"
                         aria-hidden="true">
                        <div class="modal-dialog" role="document">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>

                                    <h3 id="myModalLabel"><g:message code="list.alert.title" default="Email alerts"/></h3>
                                </div>

                                <div class="modal-body">
                                    <div class="">
                                        <a href="#alertNewRecords" id="alertNewRecords" class="btn tooltips btn-default"
                                           data-method="createBiocacheNewRecordsAlert"
                                           title="Notify me when new records come online for this search"><g:message
                                                code="list.alert.navigator01" default="Get email alerts for new records"/></a>
                                    </div>
                                    <br/>

                                    <div class="">
                                        <a href="#alertNewAnnotations" id="alertNewAnnotations"
                                           data-method="createBiocacheNewAnnotationsAlert"
                                           class="btn tooltips btn-default"
                                           title="Notify me when new annotations (corrections, comments, etc) come online for this search"><g:message
                                                code="list.alert.navigator02" default="Get email alerts for new annotations"/></a>
                                    </div>
                                    <p>&nbsp;</p>
                                    <p><a href="${grailsApplication.config.alerts.baseUrl}/notification/myAlerts"><g:message
                                            code="list.alert.navigator03" default="View your current alerts"/></a></p>
                                </div>
                                <div class="modal-footer">
                                    <button class="btn btn-default" data-dismiss="modal" aria-hidden="true"><g:message
                                            code="list.alert.button01" default="Close"/></button>
                                </div>
                            </div><!-- /.modal-content -->
                        </div><!-- /.modal-dialog -->
                    </div><!-- /#alerts -->
                </g:if>

                <g:if test="${!grailsApplication.config.useDownloadPlugin?.toBoolean()}">
                    <g:render template="download"/>
                    <div style="display:none"></div>
                </g:if>

                <div class="tabbable">
                    <ul class="nav nav-tabs" data-tabs="tabs">
                        <li class="active"><a id="t1" href="#recordsView" data-toggle="tab"><g:message code="list.link.t1"
                                                                                                       default="Records"/></a>
                        </li>
                        <li><a id="t2" href="#mapView" data-toggle="tab"><g:message code="list.link.t2" default="Map"/></a>
                        </li>
                        <plugin:isAvailable name="alaChartsPlugin">
                            <li><a id="t3" href="#chartsView" data-toggle="tab"><g:message code="list.link.t3"
                                                                                           default="Charts"/></a></li>
                            <g:if test="${grailsApplication.config.userCharts && grailsApplication.config.userCharts.toBoolean()}">
                                <li><a id="t6" href="#userChartsView" data-toggle="tab"><g:message code="list.link.t6"
                                                                                                   default="Custom Charts"/></a>
                                </li>
                            </g:if>
                        </plugin:isAvailable>
                        <g:if test="${showSpeciesImages}">
                            <li><a id="t4" href="#speciesImages" data-toggle="tab"><g:message code="list.link.t4"
                                                                                              default="Species images"/></a>
                            </li>
                        </g:if>
                        <g:if test="${hasImages}">
                            <li><a id="t5" href="#recordImages" data-toggle="tab"><g:message code="list.link.t5"
                                                                                             default="Record images"/></a>
                            </li>
                        </g:if>
                    </ul>
                </div>

                <div class="tab-content clearfix">
                    <div class="tab-pane solrResults active" id="recordsView">
                        <div id="searchControls" class="row">
                            <div class="col-sm-4 col-md-4">
                                <g:if test="${!grailsApplication.config.useDownloadPlugin?.toBoolean()}">
                                    <div id="downloads" class="btn btn-default btn-sm">
                                        <a href="#downloadModal"
                                           role="button"
                                           data-toggle="modal"
                                           class="tooltips"
                                           title="Download all ${g.formatNumber(number: sr.totalRecords, format: "#,###,###")} records OR species checklist">
                                            <i class="fa fa-download"></i>&nbsp;&nbsp;<g:message
                                                code="list.downloads.navigator" default="Downloads"/></a>
                                    </div>
                                </g:if>
                                <g:if test="${grailsApplication.config.alerts.baseUrl}">
                                    <div id="alerts" class="btn btn-default btn-sm ">
                                        <a href="#alert" role="button" data-toggle="modal" class="tooltips"
                                           title="Get email alerts for this search"><i
                                                class="fa fa-bell"></i>&nbsp;&nbsp;<g:message code="list.alerts.navigator" default="Alerts"/></a>
                                    </div>
                                </g:if>
                            </div>

                            <div id="sortWidgets" class="col-sm-8 col-md-8">
                                <span class="hidden-sm"><g:message code="list.sortwidgets.span01"
                                                                      default="per"/></span><g:message
                                    code="list.sortwidgets.span02" default="page"/>:
                                <select id="per-page" name="per-page" class="input-small">
                                    <g:set var="pageSizeVar" value="${params.pageSize ?: params.max ?: "20"}"/>
                                    <option value="10" <g:if test="${pageSizeVar == "10"}">selected</g:if>>10</option>
                                    <option value="20" <g:if test="${pageSizeVar == "20"}">selected</g:if>>20</option>
                                    <option value="50" <g:if test="${pageSizeVar == "50"}">selected</g:if>>50</option>
                                    <option value="100" <g:if test="${pageSizeVar == "100"}">selected</g:if>>100</option>
                                </select>&nbsp;
                            <g:set var="useDefault" value="${(!params.sort && !params.dir) ? true : false}"/>
                            <g:message code="list.sortwidgets.sort.label" default="sort"/>:
                                <select id="sort" name="sort" class="input-small">
                                    <option value="score" <g:if test="${params.sort == 'score'}">selected</g:if>><g:message
                                            code="list.sortwidgets.sort.option01" default="Best match"/></option>
                                    <option value="taxon_name"
                                            <g:if test="${params.sort == 'taxon_name'}">selected</g:if>><g:message
                                            code="list.sortwidgets.sort.option02" default="Taxon name"/></option>
                                    <option value="common_name"
                                            <g:if test="${params.sort == 'common_name'}">selected</g:if>><g:message
                                            code="list.sortwidgets.sort.option03" default="Common name"/></option>
                                    <option value="occurrence_date"
                                            <g:if test="${params.sort == 'occurrence_date'}">selected</g:if>>${skin == 'avh' ? g.message(code: "list.sortwidgets.sort.option0401", default: "Collecting date") : g.message(code: "list.sortwidgets.sort.option0402", default: "Record date")}</option>
                                    <g:if test="${skin != 'avh'}">
                                        <option value="record_type"
                                                <g:if test="${params.sort == 'record_type'}">selected</g:if>><g:message
                                                code="list.sortwidgets.sort.option05" default="Record type"/></option>
                                    </g:if>
                                    <option value="first_loaded_date"
                                            <g:if test="${useDefault || params.sort == 'first_loaded_date'}">selected</g:if>><g:message
                                            code="list.sortwidgets.sort.option06" default="Date added"/></option>
                                    <option value="last_assertion_date"
                                            <g:if test="${params.sort == 'last_assertion_date'}">selected</g:if>><g:message
                                            code="list.sortwidgets.sort.option07" default="Last annotated"/></option>
                                </select>&nbsp;
                            <g:message code="list.sortwidgets.dir.label" default="order"/>:
                                <select id="dir" name="dir" class="input-small">
                                    <option value="asc" <g:if test="${params.dir == 'asc'}">selected</g:if>><g:message
                                            code="list.sortwidgets.dir.option01" default="Ascending"/></option>
                                    <option value="desc"
                                            <g:if test="${useDefault || params.dir == 'desc'}">selected</g:if>><g:message
                                            code="list.sortwidgets.dir.option02" default="Descending"/></option>
                                </select>
                            </div><!-- sortWidget -->
                        </div><!-- searchControls -->
                        <div id="results">
                            <g:set var="startList" value="${System.currentTimeMillis()}"/>
                            <g:each var="occurrence" in="${sr.occurrences}">
                                <alatag:formatListRecordRow occurrence="${occurrence}"/>
                            </g:each>
                        </div><!--close results-->
                        <g:if test="${params.benchmarks}">
                            <div style="color:#ddd;">
                                <g:message code="list.recordsview.benchmarks.01"
                                           default="list render time"/> = ${(System.currentTimeMillis() - startList)} <g:message
                                    code="list.recordsview.benchmarks.02" default="ms"/><br/>
                            </div>
                        </g:if>
                        <div id="searchNavBar" class="pagination">
                            <g:paginate total="${sr.totalRecords}" max="${sr.pageSize}" offset="${sr.startIndex}"
                                        omitLast="true"
                                        params="${[taxa: params.taxa, q: params.q, fq: params.fq, wkt: params.wkt, lat: params.lat, lon: params.lon, radius: params.radius]}"/>
                        </div>
                    </div><!--end solrResults-->
                    <div id="mapView" class="tab-pane">
                        <g:render template="map"
                                  model="[mappingUrl        : alatag.getBiocacheAjaxUrl(),
                                          searchString      : searchString,
                                          queryDisplayString: queryDisplay,
                                          facets            : sr.facetResults,
                                          defaultColourBy   : grailsApplication.config.map.defaultFacetMapColourBy
                                  ]"/>
                        <div id='envLegend'></div>
                    </div><!-- end #mapwrapper -->
                    <plugin:isAvailable name="alaChartsPlugin">
                        <div id="chartsView" class="tab-pane">
                            <g:render template="charts"
                                      model="[searchString: searchString]"/>
                        </div><!-- end #chartsWrapper -->
                        <g:if test="${grailsApplication.config.userCharts && grailsApplication.config.userCharts?.toBoolean()}">
                            <div id="userChartsView" class="tab-pane">
                                <g:render template="userCharts"
                                          model="[searchString: searchString]"/>
                            </div><!-- end #chartsWrapper -->
                        </g:if>
                    </plugin:isAvailable>
                    <g:if test="${showSpeciesImages}">
                        <div id="speciesImages" class="tab-pane">
                            <h3><g:message code="list.speciesimages.title" default="Representative images of species"/></h3>

                            <div id="speciesGalleryControls">
                                <g:message code="list.speciesgallerycontrols.label01" default="Filter by group"/>
                                <select id="speciesGroup">
                                    <option><g:message code="list.speciesgallerycontrols.speciesgroup.option01"
                                                       default="no species groups loaded"/></option>
                                </select>
                                &nbsp;
                                <g:message code="list.speciesgallerycontrols.label02" default="Sort by"/>
                                <select id="speciesGallerySort">
                                    <option value="common"><g:message
                                            code="list.speciesgallerycontrols.speciesgallerysort.option01"
                                            default="Common name"/></option>
                                    <option value="taxa"><g:message
                                            code="list.speciesgallerycontrols.speciesgallerysort.option02"
                                            default="Scientific name"/></option>
                                    <option value="count"><g:message
                                            code="list.speciesgallerycontrols.speciesgallerysort.option03"
                                            default="Record count"/></option>
                                </select>
                            </div>

                            <div id="speciesGallery">[<g:message code="list.speciesgallerycontrols.speciesgallery"
                                                                 default="image gallery should appear here"/>]</div>

                            <div id="loadMoreSpecies" style="display:none;">
                                <button class="btn btn-default"><g:message code="list.speciesgallerycontrols.loadmorespecies.button"
                                                               default="Show more images"/></button>
                                <asset:image src="indicator.gif" style="display:none;" alt="indicator icon"/>
                            </div>
                        </div><!-- end #speciesWrapper -->
                    </g:if>
                    <g:if test="${hasImages}">
                        <div id="recordImages" class="tab-pane">
                            <h3><g:message code="list.speciesgallerycontrols.recordimages.title"
                                           default="Images from occurrence records"/></h3>
                            <%--<p>(see also <a href="#tab_speciesImages">representative species images</a>)</p>--%>
                            <div id="imagesGrid">
                                <g:message code="list.speciesgallerycontrols.imagesgrid" default="loading images"/>...
                            </div>

                            <div id="loadMoreImages" style="display:none;">
                                <button class="btn btn-default"><g:message code="list.speciesgallerycontrols.loadmoreimages.button"
                                                               default="Show more images"/>
                                <asset:image src="indicator.gif" style="display:none;" alt="indicator icon"/>
                                </button>
                            </div>
                            <%-- HTML template used by AJAX code --%>
                            <div class="imgConTmpl hide">
                                <div class="imgCon">
                                    <a class="cbLink" rel="thumbs" href="" id="thumb">
                                        <img src="" alt="${tc?.taxonConcept?.nameString} image thumbnail"/>

                                        <div class="meta brief"></div>

                                        <div class="meta detail hide"></div>
                                    </a>
                                </div>
                            </div>
                        </div><!-- end #imagesWrapper -->
                    </g:if>
                </div><!-- end .css-panes -->
                <form name="raw_taxon_search" class="rawTaxonSearch" id="rawTaxonSearchForm"
                      action="${request.contextPath}/occurrences/search/taxa" method="POST">
                    <%-- taxon concept search drop-down div are put in here via Jquery --%>
                    <div style="display:none;">
                    </div>
                </form>
            </div>
        </div>
    </g:else>
    <div id="imageDialog" class="modal fade" tabindex="-1" role="dialog">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-body">
                    <div id="viewerContainerId">

                    </div>
                </div>
            </div><!-- /.modal-content -->
        </div><!-- /.modal-dialog -->
    </div>
    <g:if test="${params.benchmarks}">
        <g:set var="endPageTime" value="${System.currentTimeMillis()}"/>
        <div style="color:#ddd;">
            <g:message code="list.endpagetime01" default="post-facets time"/> = ${(endPageTime - postFacets)} ms<br>
            <g:message code="list.endpagetime02" default="page render time"/> = ${(endPageTime - startPageTime)} ms<br>
            <g:message code="list.endpagetime03" default="biocache-service GET time"/> = ${wsTime} ms<br>
            <g:message code="list.endpagetime04" default="controller processing time"/> = ${processingTime} ms<br>
            <g:message code="list.endpagetime05"
                       default="total processing time"/> = ${(endPageTime - startPageTime) + processingTime} ms
        </div>
    </g:if>
</body>
</html>