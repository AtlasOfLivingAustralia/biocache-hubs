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
<g:set var="authService" bean="authService"></g:set>
<g:set var="orgNameShort" value="${grailsApplication.config.getProperty('skin.orgNameShort')}"/>
<!DOCTYPE html>
<html>
<head>
    <meta name="svn.revision" content="${meta(name: 'svn.revision')}"/>
<meta name="layout" content="${grailsApplication.config.getProperty('skin.layout')}"/>
<meta name="section" content="search"/>
<meta name="breadcrumbParent" content="${request.contextPath ?: '/'},${message(code: "search.heading.list")}"/>
<meta name="breadcrumb" content="${message(code: "list.search.results")}"/>
<title><g:message code="list.title"
                  default="Search"/>: ${sr?.queryTitle?.replaceAll("<(.|\n)*?>", '')} | <alatag:message
        code="search.heading.list" default="Search results"/> | ${grailsApplication.config.getProperty('skin.orgNameLong')}</title>

<g:if test="${grailsApplication.config.getProperty('google.apikey')}">
    <script src="https://maps.googleapis.com/maps/api/js?key=${grailsApplication.config.getProperty('google.apikey')}"
            type="text/javascript"></script>
</g:if>

<script type="text/javascript" src="https://www.google.com/jsapi"></script>
<script type="text/javascript">
    // single global var for app conf settings
    <g:set var="fqParams" value="${(params.fq) ? "&fq=" + params.list('fq')?.join('&fq=') : ''}"/>
    <g:set var="searchString" value="${raw(sr?.urlParameters).encodeAsURL()}"/>
    <g:set var="biocacheServiceUrl" value="${alatag.getBiocacheAjaxUrl()}"/>
    var BC_CONF = {
        contextPath: "${request.contextPath}",
            serverName: "<g:createLink absolute="true" uri="" />",
            searchString: "${searchString}", //  JSTL var can contain double quotes // .encodeAsJavaScript()
            searchRequestParams: "${searchRequestParams.encodeAsURL()}",
            facetQueries: "${fqParams.encodeAsURL()}",
            facetDownloadQuery: "${searchString}",
            maxFacets: "${grailsApplication.config.getProperty('facets.max', String, '4')}",
            queryString: "${queryDisplay.encodeAsJavaScript()}",
            bieWebappUrl: "${grailsApplication.config.getProperty('bie.baseUrl')}",
            bieWebServiceUrl: "${grailsApplication.config.getProperty('bieService.baseUrl')}",
            biocacheServiceUrl: "${biocacheServiceUrl}",
            collectoryUrl: "${grailsApplication.config.getProperty('collectory.baseUrl')}",
            alertsUrl: "${grailsApplication.config.getProperty('alerts.baseUrl')}",
            skin: "${grailsApplication.config.getProperty('skin.layout')}",
            defaultListView: "${grailsApplication.config.getProperty('defaultListView')}",
            resourceName: "${grailsApplication.config.getProperty('skin.orgNameLong')}",
            facetLimit: "${grailsApplication.config.getProperty('facets.limit', Integer, 50)}",
            queryContext: "${grailsApplication.config.getProperty('biocache.queryContext')}",
            selectedDataResource: "${selectedDataResource}",
            autocompleteHints: ${grailsApplication.config.getProperty('bie.autocompleteHints', Map)?.encodeAsJson() ?: '{}'},
            zoomOutsideScopedRegion: Boolean("${grailsApplication.config.getProperty('map.zoomOutsideScopedRegion')}"),
            hasMultimedia: ${hasImages ?: 'false'}, // will be either true or false
            locale: "${org.springframework.web.servlet.support.RequestContextUtils.getLocale(request)}",
            imageServiceBaseUrl:"${grailsApplication.config.getProperty('images.baseUrl')}",
            likeUrl: "${createLink(controller: 'imageClient', action: 'likeImage')}",
            dislikeUrl: "${createLink(controller: 'imageClient', action: 'dislikeImage')}",
            userRatingUrl: "${createLink(controller: 'imageClient', action: 'userRating')}",
            disableLikeDislikeButton: ${authService.getUserId() ? false : true},
            addLikeDislikeButton: ${(grailsApplication.config.getProperty("addLikeDislikeButton", Boolean, false))},
            addPreferenceButton: <imageClient:checkAllowableEditRole/> ,
            userRatingHelpText: '<div><b>Up vote (<i class="fa fa-thumbs-o-up" aria-hidden="true"></i>) an image:</b>'+
' Image supports the identification of the species or is representative of the species.  Subject is clearly visible including identifying features.<br/><br/>'+
'<b>Down vote (<i class="fa fa-thumbs-o-down" aria-hidden="true"></i>) an image:</b>'+
' Image does not support the identification of the species, subject is unclear and identifying features are difficult to see or not visible.<br/></div>',
            savePreferredSpeciesListUrl: "${createLink(controller: 'imageClient', action: 'saveImageToSpeciesList')}",
            getPreferredSpeciesListUrl:  "${createLink(controller: 'imageClient', action: 'getPreferredSpeciesImageList')}",
            excludeCountUrl: "${createLink(controller: 'occurrence', action: 'dataQualityExcludeCounts', params: params.clone()).encodeAsJavaScript()}",
            expandProfileDetails: ${grailsApplication.config.getProperty('dataquality.enabled', Boolean, false) ? expandProfileDetails : true},
            userId: "${userId}",
            prefKey: "${(grailsApplication.config.getProperty("dataquality.prefkey", String, "dqUserProfile"))}",
            expandKey: "${(grailsApplication.config.getProperty("dataquality.expandKey", String, "dqDetailExpand"))}",
            autocompleteUrl: "${grailsApplication.config.getProperty('skin.useAlaBie', Boolean) ? (grailsApplication.config.getProperty('bieService.baseUrl') + '/search/auto.json') : biocacheServiceUrl + '/autocomplete/search'}",
            autocompleteUseBie: ${grailsApplication.config.getProperty('skin.useAlaBie', Boolean)},
            groupedFacets: ${(groupedFacets as grails.converters.JSON).toString().encodeAsRaw()},
            groupedFacetsRequested: ${(groupedFacetsRequested as grails.converters.JSON).toString().encodeAsRaw()},
            groupedFacetsMap: ${(groupedFacetsMap as grails.converters.JSON).toString().encodeAsRaw()}
        };
</script>

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


<asset:javascript src="autocomplete.js"/>
<asset:script type="text/javascript">
    <g:if test="${!grailsApplication.config.getProperty('google.apikey')}">
        google.load('maps','3.5');
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
            <form action="${g.createLink(controller: 'home', action: 'simpleSearch')}" id="solrSearchForm" class="form-horizontal">
                <div id="advancedSearchLink">
                    <a href="${g.createLink(uri: '/search')}#tab_advanceSearch" class="tooltips" title="<g:message code="list.advancedsearchlink.tooltip" default="Go to advanced search form"></g:message>">
                        <i class="fa fa-cogs"></i>
                        <g:message code="list.advancedsearchlink.navigator" default="Advanced search"></g:message>
                    </a>
                </div>
                <div class="input-group pull-right col-sm-7 col-md-7">
                    <input type="text" id="taxaQuery" name="q" class="form-control"
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
    <g:set var="dqEnabled" value="${grailsApplication.config.getProperty('dataquality.enabled', Boolean)}" />
    <g:set var="recordsExcluded" value="${dqEnabled && (qualityTotalCount != sr.totalRecords)}"/>


    <g:if test="${flash.message}">
        <div id="errorAlert" class="alert alert-danger alert-dismissible alert-dismissable" role="alert">
            <button type="button" class="close" onclick="$(this).parent().hide()" aria-label="Close"><span
                    aria-hidden="true">&times;</span></button>
            <h4><alatag:stripApiKey message="${flash.message}"/></h4>

            <p>Please contact <a
                    href="mailto:${grailsApplication.config.getProperty('supportEmail', String, 'support@ala.org.au')}?subject=biocache error"
                    style="text-decoration: underline;">support</a> if this error continues</p>
        </div>
    </g:if>
    <g:if test="${errors || sr?.status == "ERROR"}">
        <g:set var="errorMessage" value="${errors ?: sr?.errorMessage}"/>
        <div class="searchInfo searchError">
            <h2 style="padding-left: 10px;"><g:message code="list.01.error" default="Error"/></h2>
            <div class="alert alert-info" role="alert">
                <b>${alatag.stripApiKey(message: errorMessage)}</b>
            </div>
            Please contact <a
                href="mailto:${grailsApplication.config.getProperty('supportEmail', String, 'support@ala.org.au')}?subject=biocache error">support</a> if this error continues
        </div>
    </g:if>
    <g:elseif test="${!sr || (sr.totalRecords == 0 && !recordsExcluded)}">
        <div class="searchInfo searchError">
            %{-- search query was interpreted as matching a taxon - thus has a span with `lsid` attribute --}%
            <g:if test="${queryDisplay =~ /lsid/}">
                <p><g:message code="list.02.p02" default="No records found for"/>
                    <span class="queryDisplay"><alatag:sanitizeContent>${raw(queryDisplay.replaceAll('null:', ''))}</alatag:sanitizeContent></span>
                </p>
                %{-- Provide a sensible alternative query that may return results --}%
                <p><g:message code="list.02.p03.01" default="Trying search for"/>
                   <a href="?q=text:${params.taxa?:params.q}"><g:message code="list.02.p03.02"
                          default="text"/>:${params.taxa?:params.q}</a>
                </p>
            </g:if>
            %{-- queryDisplay starts with "text:" and contains multiple terms (and no OR operator) --}%
            <g:elseif test="${queryDisplay =~ /^text:/ && queryDisplay =~ /\s+/ && !(queryDisplay =~ /\bOR\b/)}">${queryDisplay}
                <p><g:message code="list.03.p01" default="No records found for"/> <span
                        class="queryDisplay">${queryDisplay}</span></p>
                <p><g:message code="list.03.p02" default="Trying search for"/>:<br/>
                    %{-- Suggest alternative queries with terms ANDed and ORed --}%
                    <g:each var="boolOp" in="${["AND","OR"]}">
                        <g:set var="queryTerms" value="${queryDisplay.split(" ")}"/>
                        <g:set var="newQueryStr" value="${queryTerms.join(" ${boolOp} ").replaceAll("\"","").replaceAll("text:","")}"/>
                        <a href="?q=${newQueryStr}">${newQueryStr}</a><br/>
                    </g:each>
                </p>
            </g:elseif>
            %{-- fall-back for remaining searches --}%
            <g:else>
                <p><g:message code="list.03.p03" default="No records found for"/>
                    <span class="queryDisplay"> ${queryDisplay ?: params.q ?: params.taxa}</span>
                    <g:if test="${params.fq}">
                        <g:message code="list.03.p04" default="with filters: "/>
                        <g:each var="fq" in="${params.list('fq')}" status="i">
                            <g:set var="fqPairList" value="${fq.split(':')}"/>
                            <g:set var="fieldName" value="${fqPairList[0]}"/>
                            <g:if test="${fqPairList[0].startsWith('-')}">
                                <g:set var="fieldName"><g:message code="list.03.p05" default="(exclude)"/> ${fqPairList[0].substring(1)}</g:set>
                            </g:if>
                            <span class="queryDisplay">
                                ${fieldName}:${fqPairList[1]}
                            </span>
                            <g:if test="${(i + 1) < params.list('fq').size()}"> AND </g:if>
                        </g:each>
                    </g:if>
                </p>
            </g:else>
        </div>
        <g:if test="${grailsApplication.config.getProperty('alerts.baseUrl')}">
            <div id="alertsNorecords" class="btn btn-default btn-sm">
                <a href="#alert" role="button" data-toggle="modal" class="tooltips"
                   title="<g:message code="list.alerts.navigator.title.norecords"/>"><i
                        class="fa fa-bell"></i>&nbsp;&nbsp;<g:message code="list.alerts.navigator" default="Alerts"/></a>
            </div> <g:message code="list.alerts.navigator.title.norecords.text" default='Receive "Alert" emails when new records appear for this search'/>
        </g:if>
    </g:elseif>
    <g:else>
        <!--  first row (#searchInfoRow), contains customise facets button and number of results for query, etc.  -->
        <div class="clearfix row" id="searchInfoRow">
            <!-- facet column -->
            <div class="col-md-3 col-sm-3">
                <!-- Trigger the modal with a button -->
                <div style="margin-bottom: 10px;">
                <a class="btn tooltips btn-default btn-sm" data-toggle="modal" data-target="#facetConfigDialog" href="#"
                   title="<g:message code="search.filter.customise.title"/>">
                    <i class="fa fa-cog"></i>&nbsp;&nbsp;<g:message code="search.filter.customise"/>
                </a>
                </div>

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

                <!-- Facet list -->
                <g:render template="facets"></g:render>
            </div><!-- /.col-md-3 -->
            <!-- Results column -->
            <div class="col-sm-9 col-md-9">
                <a name="map" class="jumpTo"></a><a name="list" class="jumpTo"></a>
                <g:if test="${false && flash.message}"><%-- OFF for now --%>
                    <div class="alert alert-info alert-dismissable" style="margin-left: -30px;">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <alatag:stripApiKey message="${flash.message}"/>
                    </div>
                </g:if>
                <g:if test="${grailsApplication.config.getProperty('useDownloadPlugin', Boolean)}">
                    <div id="download-button-area" class="pull-right" >
                        <div id="downloads" class="btn btn-primary">
                            <alatag:download searchResults="${sr}" searchRequestParams="${searchRequestParams}" class="tooltips newDownload" title="${g.message(code:"list.downloads.navigator.title", args:[g.formatNumber(number: sr.totalRecords, format: "#,###,###")])}">
                                <i class="fa fa-download"></i>
                                &nbsp;&nbsp;<g:message code="list.downloads.navigator" default="Download"/>
                            </alatag:download>
                        </div>
                        <a href="#CopyLink" data-toggle="modal" role="button" class="tooltips btn copyLink" title="${g.message(code:"list.copylinks.dlg.copybutton.title")}"><i class="fa fa-file-code-o" aria-hidden="true"></i>&nbsp;&nbsp;<g:message code="list.copylinks" default="API"/></a>
                        <div id="CopyLink" class="modal fade" role="dialog" tabindex="-1">
                            <div class="modal-dialog" role="document">
                                <div class="modal-content">
                                    <div class="modal-header">
                                        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                                        <h3><g:message code="list.copylinks.dlg.title" default="Copy the JSON web service URL"/></h3>
                                    </div>
                                    <div class="modal-body">
                                        <div class="col-sm-12 input-group">
                                            <g:set var="jsonurl" value="${biocacheServiceUrl}/occurrences/search${searchString}"/>
                                            <input type="text" class="form-control" value=${jsonurl} id="al4rcode" readonly/>
                                            <span class="input-group-btn">
                                                <button class="form-control btn" id="copy-al4r">
                                                    <alatag:message code="list.copylinks.dlg.copybutton.text" default="{JSON}"/>
                                                </button>
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </g:if>
                <div id="resultsReturned">
                    <g:render template="sandboxUploadSourceLinks" model="[dataResourceUid: selectedDataResource]"/>
                    <alatag:resultCount totalRecords="${sr.totalRecords}" qualityTotalCount="${qualityTotalCount}" />
                    <span class="queryDisplay"><strong>
                        <g:set var="queryToShow"><alatag:sanitizeContent>${raw(queryDisplay)}</alatag:sanitizeContent></g:set>
                        ${raw(queryToShow) ?: params.taxa ?: params.q}
                    </strong></span>&nbsp;&nbsp;
                    <g:if test="${params.taxa && queryDisplay.startsWith("text:")}">
                        %{--Fallback taxa search to "text:", so provide feedback to user about this--}%
                        (<g:message code="list.taxa.notfound" args="${[params.taxa]}" default="(Note: no matched taxon name found for {0})"/>)
                    </g:if>
                    <alatag:ifDataQualityEnabled>
                        <g:if test="${grailsApplication.config.getProperty('dataquality.warningOn', Boolean, false) && !cookie(name:'dq_warn_off')}">
                            <div class="modal fade" id="modal-dismiss-dq" tabindex="-1" role="dialog" aria-labelledby="dq-applied-warning">
                                <div class="modal-dialog" role="document">
                                    <div class="modal-content">
                                        <div class="modal-header">
                                            <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                                            <h4 class="modal-title text-center"><alatag:message code="dq.warning.dataprofile.title" default="Results filtering with data profiles"></alatag:message></h4>
                                        </div>
                                        <div class="modal-body">
                                            <p>
                                                <g:message code="dq.warning.dataprofile.content.line1.param" args="${[orgNameShort]}" default="Search results are now filtered by default to exclude lower quality records according to the {0} General data profile. Data profiles may be disabled or other data profiles are available via the data profile drop down."></g:message>
                                            </p>
                                            <p>
                                                <alatag:message code="dq.warning.dataprofile.content.line2"></alatag:message>
                                            </p>
                                        </div>
                                        <div class="modal-footer">
                                            <a href="${grailsApplication.config.getProperty('dataquality.learnmore_link')}" target="_blank" type="button" class="btn btn-link pull-left"><alatag:message code="dq.warning.dataprofile.buttonleft.text" default="Learn More"></alatag:message></a>
                                            <button id="hide-dq-warning" type="button" class="btn btn-primary pull-right" data-dismiss="modal"><alatag:message code="dq.warning.dataprofile.buttonright.text" default="Got it"></alatag:message></button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </g:if>
                    </alatag:ifDataQualityEnabled>
                    <alatag:ifDataQualityEnabled>
                        <div class="activeFilters col-sm-12" style="margin-top:6px; margin-bottom:5px;">
                            <div><span class="valign-middle">
                                <a role="button" data-toggle="collapse" href="#dq-filters-collapse" aria-expanded="true" aria-controls="dq-filters-collapse" class="dq-filters-collapse"><i id='dq-collapse-caret' class="fa fa-caret-right"></i>&nbsp;<b><alatag:message code="quality.filters.group.title" default="Data Profile"/></b>:</a>
                            </span>
                            <g:if test="${qualityProfiles.size() >= 1}">
                                <span class="dropdown">
                                    <button id="profile-dropdown" type="button" class="btn btn-default btn-xs" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="${message(code:"dq.click.to.switch.profiles")}">
                                        <span id="active-profile-name">${searchRequestParams.disableAllQualityFilters ? g.message(code: 'dq.disabled', default: 'Disabled') : activeProfile.name}</span>
                                        <span class="caret"></span>
                                    </button>
                                    <ul class="dropdown-menu" id="profiles-selection" aria-labelledby="profile-dropdown">
                                        <g:each in="${qualityProfiles}" var="profile">
                                            <li><g:link action="${actionName}" params="${params.clone().with { if (profile.isDefault) it.remove('qualityProfile') else it.qualityProfile = profile.shortName ; it.remove('disableAllQualityFilters'); it } }" title="${g.message(code: "dq.click.to.enable.the.profile.quality.filter", default: "Click to enable the {0} quality filters", args: [profile.name])} ">${profile.name}<g:if test="${profile.isDefault}"> (Default)</g:if></g:link></li>
                                        </g:each>
                                        <li><g:link action="${actionName}" params="${params.clone().with { it.disableAllQualityFilters = true; it } }" title="${message(code:"dq.click.to.disable.data.profiles")}"><alatag:message code="dq.buttontext.disableall" default="Disable data profiles"/></g:link></li>
                                    </ul>
                                </span>
                            </g:if>
                            <g:else>
                                <alatag:linkToggeleDQFilters class="btn btn-default btn-xs"/>
                            </g:else>
                            <g:if test="${!searchRequestParams.disableAllQualityFilters}">
                                <span class="valign-middle">
                                    <a href="#DQProfileDetails" class="DQProfileDetailsLink" data-toggle="modal" role="button"><i class="fa fa-info-circle tooltips" title="<g:message code="dq.profileinfo.button.tooltip" default="Click to view the profile description"></g:message>"></i></a>
                                </span>&nbsp;
                                <div id="DQProfileDetails" class="modal fade" role="dialog" tabindex="-1">
                                    <div class="modal-dialog" role="document" id="DQProfileDetailsModal">
                                        <div class="modal-content">
                                            <div class="modal-header">
                                                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                                            </div>
                                            <div class="modal-body">
                                                <h4><alatag:message code="dq.profiledetail.title" default="Data quality profile description"/></h4>
                                                <table class="table table-bordered table-condensed table-striped scrollTable">
                                                    <tr><td><alatag:message code="dq.profiledetail.profiletable.header.profilename" default="Profile name"/></td><td>${activeProfile.name}</td></tr>
                                                    <tr><td><alatag:message code="dq.profiledetail.profiletable.header.profileshortname" default="Profile short name"/></td><td>${activeProfile.shortName}</td></tr>
                                                    <tr><td><alatag:message code="dq.profiledetail.profiletable.header.profiledescription" default="Profile description"/></td><td>${activeProfile.description}</td></tr>
                                                    <tr><td><alatag:message code="dq.profiledetail.profiletable.header.owner" default="Owner"/></td><td>${activeProfile.contactName}</td></tr>
                                                    <tr><td><alatag:message code="dq.profiledetail.profiletable.header.contact" default="Contact"/></td><td><a target="_blank" href = "mailto: ${activeProfile.contactEmail}">${activeProfile.contactEmail}</a></td></tr>
                                                </table>

                                                <h4><alatag:message code="dq.profiledetail.categorylabel" default="Filter categories"/>:</h4>
                                                <g:each var="category" in="${activeProfile.categories}">
                                                    %{-- only when the category is enabled and have enabled filters--}%
                                                    <g:if test = "${category.enabled && category.qualityFilters.findAll{it.enabled}.size() > 0}">
                                                        <div>
                                                            <b>${category.name}</b><br>
                                                            ${category.description}
                                                        </div>
                                                        <table class="table cat-table table-bordered table-condensed table-striped scrollTable" data-translation="${translatedFilterMap[category.label]}" data-filters="${groovy.json.JsonOutput.toJson(category.qualityFilters.findAll{it.enabled}*.filter.flatten())}">
                                                            <tr>
                                                                <th><alatag:message code="dq.profiledetail.filtertable.header.description" default="Filter description"/></th>
                                                                <th><alatag:message code="dq.profiledetail.filtertable.header.value" default="Filter value"/></th>
                                                                <th><alatag:message code="dq.profiledetail.filtertable.header.furtherInfo" default="Further information"/></th>
                                                            </tr>
                                                            <g:each var="filter" in="${category.qualityFilters}">
                                                                <g:if test="${filter.enabled}">
                                                                    <tr>
                                                                        <td class='filter-description' data-val="${filter.description}"></td>
                                                                        <td class='filter-value'><span>${filter.filter}</span></td>
                                                                        <td class="filter-wiki"></td>
                                                                    </tr>
                                                                </g:if>
                                                            </g:each>
                                                        </table>
                                                    </g:if>
                                                </g:each>
                                            </div>
                                            <div class="modal-footer">
                                                <a href="${grailsApplication.config.getProperty('dataquality.learnmore_link')}" target="_blank" type="button" class="btn btn-link pull-left"><alatag:message code="dq.warning.dataprofile.buttonleft.text" default="Learn More"></alatag:message></a>
                                                <button class="btn btn-default" data-dismiss="modal" ><alatag:message code="dq.categoryinfo.dlg.closebutton.text" default="Close"/></button>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div id="DQManageFilters" class="modal fade" role="dialog" tabindex="-1">
                                    <div class="modal-dialog" role="document">
                                        <div class="modal-content">
                                            <div class="modal-header">
                                                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                                                <h4><alatag:message code="dq.selectmultiple.header.description" default="Filter selection"/></h4>
                                            </div>
                                            <div class="modal-body">
                                                <div id="dynamic" class="tableContainer">
                                                    <form name="filterRefineForm" id="filterRefineForm" data-profile="${params.qualityProfile}">
                                                        <table class="table table-bordered table-condensed table-striped scrollTable">
                                                            <thead class="fixedHeader">
                                                            <tr class="tableHead">
                                                                <th width="65%"><alatag:message code="dq.selectmultiple.categorytable.header.categories" default="Categories"/></th>
                                                                <th><input type="checkbox" name="filters" class="checkall" value=""></th>
                                                            </tr>
                                                            </thead>
                                                            <tbody class="scrollContent">
                                                                <g:each var="qualityCategory" in="${qualityCategories}">
                                                                    <g:set var="qcDisabled" value="${searchRequestParams.disableQualityFilter.contains(qualityCategory.label)}" />
                                                                    <tr>
                                                                        <td class="filternames" data-filters="${qualityCategory.qualityFilters.findAll { it.enabled }*.filter}" data-category="${qualityCategory.label}">${qualityCategory.name}</td>
                                                                        <td>
                                                                            <input type="checkbox" name="filters" class="filters" data-category="${qualityCategory.label}" data-enabled="${!qcDisabled}" value="" style="vertical-align: middle; margin: 0">&nbsp;
                                                                            <button class='btn btn-link btn-sm expand' data-category="${qualityCategory.label}"
                                                                                    title="<g:message code="dq.pop.out" default="Convert this data quality filter into separate filter queries you can include/exclude individually"></g:message>">
                                                                            <a><g:message code="dq.selectmultiple.buttontext.expandfilters" default="Expand and edit filters"/></a></button>
                                                                            <span class="expanded" data-category="${qualityCategory.label}" ><g:message code="dq.selectmultiple.text.expanded" default="Expanded"/></span>
                                                                        </td>
                                                                    </tr>
                                                                </g:each>
                                                            </tbody>
                                                        </table>
                                                    </form>
                                                </div>
                                            </div>

                                            <div id="submitFilters" class="modal-footer">
                                                <div class="pull-right">
                                                    <button class="btn btn-default" data-dismiss="modal" ><alatag:message code="dq.selectmultiple.form.cancel" default="Cancel"/></button>
                                                    <button type='submit' class="submit btn btn-primary" data-dismiss="modal" ><alatag:message code="dq.selectmultiple.form.submit" default="Apply"/></button>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <span class="valign-middle">
                                    <alatag:linkResetSearch filters="${qualityCategories.collect{it.qualityFilters.findAll{it.enabled}*.filter}.flatten()}">
                                        <i class="fa fa-undo fa-xs tooltips" title="<g:message code="quality.filters.resetsearch.tooltip" default="Reset filters"></g:message>"></i>
                                    </alatag:linkResetSearch>
                                </span>&nbsp;
                            </g:if>

                            <g:if test="${!searchRequestParams.disableAllQualityFilters && qualityCategories.size() > 1}">
                                <span class="valign-middle"><a href="#DQManageFilters" class="multipleFiltersLink tooltips" data-toggle="modal" role="button" title="<g:message code="dq.button.filterselection.tooltip"/>"><span class="glyphicon glyphicon-hand-right" aria-hidden="true"></span>&nbsp;<alatag:message code="dq.button.filterselection.text" default="Select filters"/></a></span>
                            </g:if>
                                <a href="#DQPrefSettings" class="DQPrefSettingsLink" data-toggle="modal" role="button"><span id='usersettings' title="<g:message code="dq.profilesettings.button.tooltip" default="Data profile settings"/>"><span><g:message code="dq.profilesettings.button.label" default="Settings"/>&nbsp;</span><i class="fa fa-cog"></i></span></a>
                                <div id="DQPrefSettings" class="modal fade" role="dialog" tabindex="-1" data-defaultprofilename="${defaultProfileName}" data-userpref="${userPref}" data-userpref-json="${groovy.json.JsonOutput.toJson(userPref)}" data-profiles="${groovy.json.JsonOutput.toJson(qualityProfiles.collect {it.shortName})}" data-filters="${groovy.json.JsonOutput.toJson(qualityCategories.collect{it.qualityFilters.findAll{it.enabled}*.filter}.flatten())}">
                                    <div class="modal-dialog" role="document">
                                        <div class="modal-content">
                                            <div class="modal-header">
                                                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                                                <h3><g:message code="dq.prefsettings.dlg.title" default="Data profile user settings"/></h3>
                                            </div>
                                            <div class="modal-body">
                                                <div class="col-md-12" id="userPrefBody">
                                                    <form>
                                                        <div class="form-group row">
                                                            <label for="prefer_profile" class="col-sm-12 col-form-label text-info"><g:message code="dq.profilesettings.warning.appliedtosearch" default="Your default profile is applied to searches unless you select another profile from the data profiles drop down"/></label>
                                                        </div>
                                                        <div class="form-group row">
                                                            <label for="prefer_profile" class="col-sm-4 col-form-label"><g:message code="dq.profilesettings.label.defaultprofile" default="Default profile"/></label>
                                                            <div class="col-sm-8">
                                                                <select id='prefer_profile' class="form-control col-md-6">
                                                                    <g:each in="${qualityProfiles}" var="profile">
                                                                        <option value="${profile.shortName}">${profile.name}</option>
                                                                    </g:each>
                                                                    <option value="disableall-option"><alatag:message code="dq.buttontext.disableall" default="Disable data profiles"/></option>
                                                                </select>
                                                            </div>
                                                        </div>
                                                        <div class="form-group row">
                                                            <label for="profile_expand" class="col-sm-4 col-form-label"><g:message code="dq.profilesettings.label.showexpend" default="Show data profile details"/></label>
                                                            <div class="col-sm-8">
                                                                <select id='profile_expand' class="form-control col-md-6">
                                                                    <option value="collapsed"><g:message code="dq.profilesettings.select.option.collapsed" default="Collapsed" /></option>
                                                                    <option value="expanded"><g:message code="dq.profilesettings.select.option.expanded" default="Expanded" /></option>
                                                                </select>
                                                            </div>
                                                        </div>
                                                        <g:each in="${qualityProfiles}" var="profile">
                                                            <div id="items_${profile.shortName}"
                                                                 <g:if test="${defaultProfileName != profile.shortName}">
                                                                     style="display:none;"
                                                                 </g:if>
                                                                 class="profile_items">
                                                                <g:each in="${profile.categories}" var="category">
                                                                    <div class="form-group row">
                                                                        <label class="col-sm-6 col-form-label">${category.name}</label>
                                                                        <input class="col-sm-1" type="checkbox" name="items_${profile.shortName}" value="${category.label}" checked="checked" />
                                                                    </div>
                                                                </g:each>
                                                            </div>
                                                        </g:each>
                                                    </form>
                                                </div>
                                            </div>
                                            <div id="submitPref" class="modal-footer">
                                                <button class="btn btn-default" data-dismiss="modal"><alatag:message code="dq.profilesettings.button.cancel" default="Cancel"/></button>
                                                <button type='submit' class="submit btn btn-primary"><alatag:message code="dq.profilesettings.button.save" default="Save"/></button>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <g:if test="${searchRequestParams.disableAllQualityFilters}">
                                <div class="collapse" id="dq-filters-collapse">
                                    <div class="alert alert-warning alert-sm">
                                        <alatag:message code="dq.data.profiles.disabled" default="Data profiles have been disabled for this search"/>
                                    </div>
                                </div>
                            </g:if>
                            <g:else>
                                <div class="collapse" id="dq-filters-collapse">
                                    <g:each var="qualityCategory" in="${qualityCategories}">
                                        <g:set var="qcDisabled" value="${searchRequestParams.disableQualityFilter.contains(qualityCategory.label)}" />
                                        <div class="col-sm-6 dq-active-filter-item">
                                            <g:if test="${qcDisabled}">
                                                <alatag:linkQualityCategory class="tooltips" expand="${true}" enable="${true}" category="${qualityCategory}" title="${g.message(code: 'dq.pop.in', default: 'Re-enable this data quality filter and remove its corresponding filter queries')}">
                                                    <i class="fa fa-square-o"></i>
                                                </alatag:linkQualityCategory>
                                            </g:if>
                                            <g:else>
                                                <alatag:linkQualityCategory class="tooltips" expand="${false}" enable="${false}" category="${qualityCategory}">
                                                    <i class="fa fa-check-square-o"></i>
                                                </alatag:linkQualityCategory>
                                            </g:else>
                                            <span>
                                                <span class="tooltips cursor-pointer" title="${qualityCategory.description + (dqInteract.containsKey(qualityCategory.label) ? "<br><br>" + dqInteract[qualityCategory.label] : "")}" style="color:${DQColors[qualityCategory.label]}">${qualityCategory.name}</span>

                                                <a href="#DQCategoryDetails" class="DQCategoryDetailsLink" data-profilename="${activeProfile.name}" data-dqcategoryname="${qualityCategory.name}" data-dqcategorydescription="${qualityCategory.description}" data-categorylabel="${qualityCategory.label}" data-filters="${groovy.json.JsonOutput.toJson(qualityCategory.qualityFilters.findAll{it.enabled}*.filter.flatten())}" data-fq="${qualityFiltersByLabel[qualityCategory.label]}" data-description="${groovy.json.JsonOutput.toJson(qualityFilterDescriptionsByLabel[qualityCategory.label])}" data-translation="${translatedFilterMap[qualityCategory.label]}" data-disabled="${qcDisabled}" data-inverse-filter="${alatag.createInverseQualityCategoryLink(category: qualityCategory, inverseFilters: inverseFilters)}" data-toggle="modal" role="button"><i class="fa fa-info-circle tooltips" title="<g:message code="dq.categoryinfo.button.tooltip" default="Click for more information and actions"></g:message>"></i></a>
                                                <alatag:invertQualityCategory category="${qualityCategory}" inverseFilters="${inverseFilters}" target="_blank" class="tooltips" title="${g.message(code: 'dq.inverse.button', default: 'Show excluded records')}">
                                                    (<i class="fa fa-circle-o-notch fa-spin exclude-loader"></i><span style="display: none;" class="exclude-count-label" data-category="${qualityCategory.label}" data-enabled="${!searchRequestParams.disableQualityFilter.contains(qualityCategory.label)}"></span>
                                                    <alatag:message code="quality.filters.excludeCount" default="records excluded" />)
                                                </alatag:invertQualityCategory>
                                            </span>
                                        </div>
                                    </g:each>
                                    <div id="DQCategoryDetails" class="modal fade " role="dialog" tabindex="-1">
                                        <div class="modal-dialog" role="document" id="DQDetailsModal">
                                            <div class="modal-content">
                                                <div class="modal-header">
                                                    <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                                                    <h3 id="fqdetail-heading-name"></h3>
                                                    <p id="fqdetail-heading-description"></p>
                                                </div>

                                                <div class="modal-body" id="modal-body">
                                                    <p id="excluded"><i class="fa fa-circle-o-notch fa-spin exclude-loader"></i><span class="exclude-count-label"></span> <g:message code="dq.excluded.count" default="records are excluded by this category"/></p>
                                                    <a id="view-excluded" class="btn btn-link" href="#view-excluded" target="_blank"><g:message code="dq.view.excluded" default="View excluded records"/></a>
                                                    <p id="filter-value"></p>
                                                    <button id='expandfilters' class="btn btn-link tooltips" data-dismiss="modal" data-profile=${params.qualityProfile} title="<g:message code="dq.pop.out" default="Convert this data quality filter into separate filter queries you can include/exclude individually"></g:message>"><g:message code="dq.categoryinfo.dlg.expandbutton.text" default="Expand and edit filters"/></button>

                                                    <table class="table table-bordered table-condensed table-striped scrollTable" id="DQDetailsTable">
                                                        <thead class="fixedHeader">
                                                        <tr>
                                                            <th><alatag:message code="dq.categoryinfo.dlg.fieldtable.heading.name" default="Field name"/></th>
                                                            <th><alatag:message code="dq.categoryinfo.dlg.fieldtable.heading.description" default="Description"/></th>
                                                            <th><alatag:message code="dq.categoryinfo.dlg.fieldtable.heading.furtherInfo" default="Further information"/></th>
                                                        </tr>

                                                        <tr class="spinnerRow">
                                                            <td colspan="3" class="text-center"><g:message code="facets.multiplefacets.tabletr01td01" default="loading data"/>... <asset:image src="spinner.gif" id="spinner2" class="spinner" alt="spinner icon"/></td>
                                                        </tr>
                                                        </thead>

                                                        <tbody>
                                                        </tbody>
                                                    </table>

                                                    <table class="table table-bordered table-condensed table-striped scrollTable" id="DQFiltersTable">
                                                        <thead class="fixedHeader">
                                                        <tr>
                                                            <th><alatag:message code="dq.categoryinfo.dlg.valuetable.heading.description" default="Filter description"/></th>
                                                            <th><alatag:message code="dq.categoryinfo.dlg.valuetable.heading.value" default="Filter value"/></th>
                                                            <th><alatag:message code="dq.categoryinfo.dlg.valuetable.heading.furtherInfo" default="Further information"/></th>
                                                        </tr>

                                                        <tr class="spinnerRow">
                                                            <td colspan="3" class="text-center"><g:message code="facets.multiplefacets.tabletr01td01" default="loading data"/>... <asset:image src="spinner.gif" id="spinner2" class="spinner" alt="spinner icon"/></td>
                                                        </tr>
                                                        </thead>

                                                        <tbody>
                                                        </tbody>
                                                    </table>
                                                </div>
                                                <div class="modal-footer">
                                                    <a href="${grailsApplication.config.getProperty('dataquality.learnmore_link')}" target="_blank" type="button" class="btn btn-link pull-left"><alatag:message code="dq.warning.dataprofile.buttonleft.text" default="Learn More"></alatag:message></a>
                                                    <button class="btn btn-default" data-dismiss="modal" ><alatag:message code="dq.categoryinfo.dlg.closebutton.text" default="Close"/></button>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                </div>
                            </g:else>
                        </div>
                    </alatag:ifDataQualityEnabled>
                    %{--<g:set var="hasFq" value="${false}"/>--}%
                    <g:if test="${sr.activeFacetObj?.values()?.any() || params.wkt || params.radius}">
                        <div class="activeFilters col-sm-12" style="margin-bottom: 10px;">
                            <b><alatag:message code="search.filters.heading" default="User selected filters"/></b>:&nbsp;
                            <g:each var="items" in="${sr.activeFacetObj}">
                                <g:if test="${items.key}">
                                    <g:each var="item" in="${items.value}">
                                        <g:set var="hasFq" value="${true}"/>
                                        <alatag:currentFilterItem key="${items.key}" value="${item}" facetValue="${item.value}" cssClass="btn btn-default btn-xs" cssColor="${UserFQColors != null ? UserFQColors[item.value] : null}" title="${fqInteract != null ? fqInteract[item.value] : null}" addCloseBtn="${true}"/>
                                    </g:each>
                                </g:if>
                            </g:each>
                            <g:if test="${params.wkt}"><%-- WKT spatial filter   --%>
                                <g:set var="spatialType" value="${params.wkt =~ /^\w+/}"/>
                                <a href="${alatag.getQueryStringForWktRemove()}" class="btn tooltips btn-default btn-xs"
                                   title="<g:message code="list.resultsreturned.click.to.remove.filters"/>"><g:message code="list.resultsreturned.spatial.filter"/>: ${spatialType[0]}
                                    <span class="closeX">&times;</span>
                                </a>
                            </g:if>
                            <g:elseif test="${params.radius && params.lat && params.lon}">
                                <a href="${alatag.getQueryStringForRadiusRemove()}" class="btn tooltips btn-default btn-xs"
                                   title="<g:message code="list.resultsreturned.click.to.remove.filters"/>"><g:message code="list.resultsreturned.spatial.filter"/>: <g:message code="list.resultsreturned.circle"/>
                                    <span class="closeX">&times;</span>
                                </a>
                            </g:elseif>
                            <g:if test="${sr.activeFacetObj?.collect { it.value.size() }.sum() > 1 }">
                                <a href="${alatag.createFilterItemLink(facet: 'all')}" class="btn btn-primary activeFilter btn-xs"
                                   title="<g:message code="list.resultsreturned.button01.title"/>"><span
                                        class="closeX">&gt;&nbsp;</span><g:message code="list.resultsreturned.button01"
                                                                                   default="Clear all"/></a>
                            </g:if>
                        </div>
                    </g:if>
                <%-- jQuery template used for taxon drop-downs --%>
                    <div class="btn-group hide" id="template">
                        <a class="btn btn-default btn-sm" href="" id="taxa_" title="<g:message code="list.resultsreturned.navigator01.title"/>" target="BIE"><g:message
                                code="list.resultsreturned.navigator01" default="placeholder"/></a>
                        <button class="btn dropdown-toggle btn-default btn-sm" data-toggle="dropdown"
                                title="<g:message code="list.resultsreturned.click.more.info"/>">
                            <span class="caret"></span>
                        </button>

                        <div class="dropdown-menu" aria-labelledby="taxa_">
                            <div class="taxaMenuContent">
                                <g:message code="list.resultsreturned.div01.des01"
                                           default="The search results include records for synonyms and child taxa of"/>
                                <b class="nameString"><g:message code="list.resultsreturned.div01.des02"
                                                                 default="placeholder"/></b> (<span
                                    class="speciesPageLink"><g:message code="list.resultsreturned.div01.des03"
                                                                       default="link placeholder"/></span>).

                                <form name="raw_taxon_search" class="rawTaxonSearch"
                                      action="${request.contextPath}/occurrences/search/taxa" method="POST">
                                    <div class="refineTaxaSearch">
                                        <g:message code="list.resultsreturned.form.des01"
                                                   default="The result set contains records provided under the following names"/>:
                                        <input type="submit" class="btn  btn-default btn-sm rawTaxonSumbit"
                                               value="<g:message code="list.resultsreturned.form.button01"
                                                                 default="Refine search"/>"
                                               title="<g:message code="list.resultsreturned.restrict.results"/>">

                                        <div class="rawTaxaList"><g:message code="list.resultsreturned.form.div01"
                                                                            default="placeholder taxa list"/></div>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>
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
                            <g:if test="${grailsApplication.config.getProperty('userCharts') && grailsApplication.config.getProperty('userCharts', Boolean)}">
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
                                <g:if test="${!grailsApplication.config.getProperty('useDownloadPlugin', Boolean, false)}">
                                    <div id="downloads" class="btn btn-default btn-sm">
                                        <a href="#downloadModal"
                                           role="button"
                                           data-toggle="modal"
                                           class="tooltips"
                                           title="<g:message code="list.downloads.navigator.title2" args="${[g.formatNumber(number: sr.totalRecords, format: "#,###,###")]}"/>">
                                            <i class="fa fa-download"></i>&nbsp;&nbsp;<g:message
                                                code="list.downloads.navigator" default="Downloads"/></a>
                                    </div>
                                </g:if>
                                <g:if test="${grailsApplication.config.getProperty('alerts.baseUrl')}">
                                    <div id="alerts" class="btn btn-default btn-sm ">
                                        <a href="#alert" role="button" data-toggle="modal" class="tooltips"
                                           title="<g:message code="list.alerts.navigator.title"/>"><i
                                                class="fa fa-bell"></i>&nbsp;&nbsp;<g:message code="list.alerts.navigator" default="Alerts"/></a>
                                    </div>
                                </g:if>
                            </div>

                            <div id="sortWidgets" class="col-sm-8 col-md-8">
                                <span class="hidden-sm"><g:message code="list.sortwidgets.span01"
                                                                      default="per"/></span>&nbsp;<g:message
                                    code="list.sortwidgets.span02" default="page"/>:
                                <select id="per-page" name="per-page" class="input-small">
                                    <g:set var="pageSizeVar" value="${params.pageSize ?: params.max ?: "20"}"/>
                                    <option value="10" <g:if test="${pageSizeVar == "10"}">selected</g:if>>10</option>
                                    <option value="20" <g:if test="${pageSizeVar == "20"}">selected</g:if>>20</option>
                                    <option value="50" <g:if test="${pageSizeVar == "50"}">selected</g:if>>50</option>
                                    <option value="100" <g:if test="${pageSizeVar == "100"}">selected</g:if>>100</option>
                                </select>&nbsp;
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
                                            <g:if test="${(!params.sort) || params.sort == 'first_loaded_date'}">selected</g:if>><g:message
                                            code="list.sortwidgets.sort.option06" default="Date added"/></option>
                                    <option value="last_assertion_date"
                                            <g:if test="${params.sort == 'last_assertion_date'}">selected</g:if>><g:message
                                            code="list.sortwidgets.sort.option07" default="Last annotated"/></option>
                                </select>&nbsp;
                            <g:message code="list.sortwidgets.dir.label" default="order"/>:
                                <select id="dir" name="dir" class="input-small">
                                    <g:set var="sortOrder" value="${params.dir ?: params.order}"/>
                                    <option value="asc" <g:if test="${sortOrder == 'asc'}">selected</g:if>><g:message
                                            code="list.sortwidgets.dir.option01" default="Ascending"/></option>
                                    <option value="desc"
                                            <g:if test="${!sortOrder || sortOrder == 'desc'}">selected</g:if>><g:message
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
                        <div class="content">
                            <div id="searchNavBar" class="pagination">
                            <g:paginate total="${sr.totalRecords}" max="${sr.pageSize}" offset="${sr.startIndex}"
                                        next="${message(code: "show.nextbtn.navigator", default:"Next")}"
                                        prev="${message(code: "show.previousbtn.navigator", default:"Previous")}"
                                        omitLast="true"
                                        params="${params.clone().with { it.remove('max'); it.remove('offset'); it } }"
                            />
                        </div>
                        </div>
                    </div><!--end solrResults-->
                    <div id="mapView" class="tab-pane">
                        <g:render template="map"
                                  model="[mappingUrl        : alatag.getBiocacheAjaxUrl(),
                                          searchString      : searchString,
                                          queryDisplayString: queryDisplay,
                                          facets            : sr.facetResults,
                                          defaultColourBy   : grailsApplication.config.getProperty('map.defaultFacetMapColourBy')
                                  ]"/>
                        <div id='envLegend'></div>
                    </div><!-- end #mapwrapper -->
                    <plugin:isAvailable name="alaChartsPlugin">
                        <div id="chartsView" class="tab-pane">
                            <g:render template="charts"
                                      model="[searchString: searchString]"/>
                        </div><!-- end #chartsWrapper -->
                        <g:if test="${grailsApplication.config.userCharts && grailsApplication.config.getProperty('userCharts', Boolean)}">
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

    <g:if test="${grailsApplication.config.getProperty('alerts.baseUrl')}">
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
                               title="<g:message code="list.alert.navigator01.title"/>"><g:message
                                    code="list.alert.navigator01" default="Get email alerts for new records"/></a>
                        </div>
                        <br/>

                        <div class="">
                            <a href="#alertNewAnnotations" id="alertNewAnnotations"
                               data-method="createBiocacheNewAnnotationsAlert"
                               class="btn tooltips btn-default"
                               title="<g:message code="list.alert.navigator02.title"/>"><g:message
                                    code="list.alert.navigator02" default="Get email alerts for new annotations"/></a>
                        </div>
                        <p>&nbsp;</p>
                        <p><a href="${grailsApplication.config.getProperty('alerts.baseUrl')}/notification/myAlerts"><g:message
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
