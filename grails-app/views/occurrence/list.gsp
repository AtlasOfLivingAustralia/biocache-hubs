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
            serverName: "<g:createLink absolute="true" uri="" />",
            searchString: "${searchString}", //  JSTL var can contain double quotes // .encodeAsJavaScript()
            searchRequestParams: "${searchRequestParams.encodeAsURL()}",
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
            addLikeDislikeButton: ${(grailsApplication.config.getProperty("addLikeDislikeButton", Boolean, false))},
            addPreferenceButton: <imageClient:checkAllowableEditRole/> ,
            userRatingHelpText: '<div><b>Up vote (<i class="fa fa-thumbs-o-up" aria-hidden="true"></i>) an image:</b>'+
' Image supports the identification of the species or is representative of the species.  Subject is clearly visible including identifying features.<br/><br/>'+
'<b>Down vote (<i class="fa fa-thumbs-o-down" aria-hidden="true"></i>) an image:</b>'+
' Image does not support the identification of the species, subject is unclear and identifying features are difficult to see or not visible.<br/></div>',
            savePreferredSpeciesListUrl: "${createLink(controller: 'imageClient', action: 'saveImageToSpeciesList')}",
            getPreferredSpeciesListUrl:  "${createLink(controller: 'imageClient', action: 'getPreferredSpeciesImageList')}",
            excludeCountUrl: "${createLink(controller: 'occurrence', action: 'dataQualityExcludeCounts', params: params.clone()).encodeAsJavaScript()}"
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
    <g:set var="dqEnabled" value="${grailsApplication.config.getProperty('dataquality.enabled', Boolean)}" />
    <g:set var="recordsExcluded" value="${dqEnabled && (qualityTotalCount != sr.totalRecords)}"/>


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
                   title="<g:message code="search.filter.customise.title"/>">
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
                        <alatag:download searchResults="${sr}" searchRequestParams="${searchRequestParams}" class="tooltips newDownload" title="${g.message(code:"list.downloads.navigator.title", args:[g.formatNumber(number: sr.totalRecords, format: "#,###,###")])}">
                            <i class="fa fa-download"></i>
                            &nbsp;&nbsp;<g:message code="list.downloads.navigator" default="Download"/>
                        </alatag:download>
                    </div>
                </g:if>
                <div id="resultsReturned">
                    <g:render template="sandboxUploadSourceLinks" model="[dataResourceUid: selectedDataResource]"/>
                    <span id="returnedText">
                        <strong><g:formatNumber number="${sr.totalRecords}" format="#,###,###"/></strong>
                        <g:message code="list.resultsretuened.span.returnedtotal" default="records returned of"/></span>
                        <strong><g:formatNumber number="${qualityTotalCount}" format="#,###,###"/></strong>
                        <g:message code="list.resultsretuened.span.returnedtext" default="for"/>
                    </span>
                    <span class="queryDisplay"><strong>
                        <g:set var="queryToShow"><alatag:sanitizeContent>${raw(queryDisplay)}</alatag:sanitizeContent></g:set>
                        ${raw(queryToShow) ?: params.taxa ?: params.q}
                    </strong></span>&nbsp;&nbsp;
                    <g:if test="${params.taxa && queryDisplay.startsWith("text:")}">
                        %{--Fallback taxa search to "text:", so provide feedback to user about this--}%
                        (<g:message code="list.taxa.notfound" args="${[params.taxa]}" default="(Note: no matched taxon name found for {0})"/>)
                    </g:if>

                    <alatag:ifDataQualityEnabled>
                        <div class="activeFilters col-sm-12">
                            <div>
                            <a role="button" data-toggle="collapse" href="#dq-filters-collapse" aria-expanded="true" aria-controls="dq-filters-collapse" class="dq-filters-collapse" style="vertical-align: middle;"><i class="fa fa-caret-down" style="width: 8px;color: black"></i>&nbsp;<b><alatag:message code="quality.filters.group.title" default="Data Profile"/></b>:</a>
                            <g:if test="${qualityProfiles.size() >= 1}">
                                <span class="dropdown">
                                    <button id="profile-dropdown" type="button" class="btn btn-default btn-xs" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Click to switch profiles">
                                        ${searchRequestParams.disableAllQualityFilters ? 'Disabled' : activeProfile.name}
                                        <span class="caret"></span>
                                    </button>
                                    <ul class="dropdown-menu" aria-labelledby="profile-dropdown">
                                        <g:each in="${qualityProfiles}" var="profile">
                                            <li><g:link action="${actionName}" params="${params.clone().with { if (profile.isDefault) it.remove('qualityProfile') else it.qualityProfile = profile.shortName ; it.remove('disableAllQualityFilters'); it } }" title="Click to enable the ${profile.name} quality filters">${profile.name}<g:if test="${profile.isDefault}"> (Default)</g:if></g:link></li>
                                        </g:each>
                                        <li><g:link action="${actionName}" params="${params.clone().with { it.disableAllQualityFilters = true; it } }" title="Click to disable all data profiles"><alatag:message code="dq.buttontext.disableall" default="Disable data profiles"/></g:link></li>
                                    </ul>
                                </span>
                            </g:if>
                            <g:else>
                                <alatag:linkToggeleDQFilters class="btn btn-default btn-xs"/>
                            </g:else>
                            <g:if test="${!searchRequestParams.disableAllQualityFilters}">
                                <span style="vertical-align: middle;">
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
                                                        <table class="table table-bordered table-condensed table-striped scrollTable cat-table" data-translation="${translatedFilterMap[category.label]}">
                                                            <tr>
                                                                <th><alatag:message code="dq.profiledetail.filtertable.header.description" default="Filter description"/></th>
                                                                <th><alatag:message code="dq.profiledetail.filtertable.header.value" default="Filter value"/></th>
                                                                <th><alatag:message code="dq.profiledetail.filtertable.header.wiki" default="Wiki"/></th>
                                                            </tr>
                                                            <g:each var="filter" in="${category.qualityFilters}">
                                                                <g:if test="${filter.enabled}">
                                                                    <tr>
                                                                        <td class='filter-description' style="word-break: break-word;">${filter.description}</td>
                                                                        <td class='filter-value' style="word-break: keep-all"><span style="white-space: nowrap;">${filter.filter}</span></td>
                                                                        <td class="filter-wiki"></td>
                                                                    </tr>
                                                                </g:if>
                                                            </g:each>
                                                        </table>
                                                    </g:if>
                                                </g:each>
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
                                                    <form name="filterRefineForm" id="filterRefineForm">
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
                                                                            <button class='btn btn-link btn-sm expand' data-category="${qualityCategory.label}" style="vertical-align: middle; margin: 0; padding: 0; text-decoration: none; font-size: 14px"
                                                                                    title="<g:message code="dq.pop.out" default="Convert this data quality filter into separate filter queries you can include/exclude individually"></g:message>">
                                                                            <g:message code="dq.selectmultiple.buttontext.expandfilters" default="Expand and edit filters"/></button>
                                                                            <span class="expanded" data-category="${qualityCategory.label}" style="vertical-align: middle; margin: 0; font-style: italic; color:#c44d34"><g:message code="dq.selectmultiple.text.expanded" default="Expanded"/></span>
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
                                <span style="vertical-align: middle;">
                                    <alatag:linkResetSearch filters="${qualityCategories.collect{it.qualityFilters.findAll{it.enabled}*.filter}.flatten()}">
                                        <i class="fas fa-undo fa-xs tooltips" title="<g:message code="quality.filters.resetsearch.tooltip" default="Reset filters"></g:message>"></i>
                                    </alatag:linkResetSearch>
                                </span>&nbsp;
                            </g:if>

                            <g:if test="${!searchRequestParams.disableAllQualityFilters && qualityCategories.size() > 1}">
                                <span style="vertical-align: middle;"><a href="#DQManageFilters" class="multipleFiltersLink tooltips" data-toggle="modal" role="button" title="<g:message code="dq.button.filterselection.tooltip"/>"><span class="glyphicon glyphicon-hand-right" aria-hidden="true"></span>&nbsp;<alatag:message code="dq.button.filterselection.text" default="filter selection"/></a></span>
                            </g:if>

                            <span style="vertical-align: middle;">
                                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href=""><g:message code="dq.link.whatsdataprofile.title" default="What are Data Profiles"></g:message>?</a>
                            </span>
                            </div>

                            <g:if test="${searchRequestParams.disableAllQualityFilters}">
                                <div class="alert alert-warning alert-sm">
                                    <alatag:message code="quality.filters.disabled" default="Data Quality filters have been disabled for this search"/>
                                </div>
                            </g:if>
                            <g:else>
                                <div class="collapse in" id="dq-filters-collapse">
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

                                                <a href="#DQFilterDetails" class="DQFilterDetailsLink" data-profilename="${activeProfile.name}" data-dqcategoryname="${qualityCategory.name}" data-dqcategorydescription="${qualityCategory.description}" data-categorylabel="${qualityCategory.label}" data-fq="${qualityFiltersByLabel[qualityCategory.label]}" data-description="${qualityFilterDescriptionsByLabel[qualityCategory.label]}" data-translation="${translatedFilterMap[qualityCategory.label]}" data-disabled="${qcDisabled}" data-inverse-filter="${alatag.createInverseQualityCategoryLink(category: qualityCategory, inverseFilters: inverseFilters)}" data-toggle="modal" role="button"><i class="fa fa-info-circle tooltips" title="<g:message code="dq.categoryinfo.button.tooltip" default="Click for more information and actions"></g:message>"></i></a>
                                                <alatag:invertQualityCategory category="${qualityCategory}" inverseFilters="${inverseFilters}" target="_blank" class="tooltips" title="${g.message(code: 'dq.inverse.button', default: 'Show excluded records')}">
                                                    (<i class="fa fa-circle-o-notch fa-spin exclude-loader"></i><span style="display: none;" class="exclude-count-label" data-category="${qualityCategory.label}" data-enabled="${!searchRequestParams.disableQualityFilter.contains(qualityCategory.label)}"></span>
                                                    <alatag:message code="quality.filters.excludeCount" default="records excluded" />)
                                                </alatag:invertQualityCategory>
                                            </span>
                                        </div>
                                    </g:each>
                                    <div id="DQFilterDetails" class="modal fade " role="dialog" tabindex="-1">
                                        <div class="modal-dialog" role="document" id="DQDetailsModal">
                                            <div class="modal-content">
                                                <div class="modal-header">
                                                    <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                                                    <h3 id="fqdetail-heading-name"></h3>
                                                    <p id="fqdetail-heading-description" style="font-style: italic"></p>
                                                </div>

                                                <div class="modal-body" id="modal-body">
                                                    <p id="excluded" style="margin-bottom: 0"><i class="fa fa-circle-o-notch fa-spin exclude-loader"></i><span class="exclude-count-label"></span> <g:message code="dq.excluded.count" default="records are excluded by this category"/></p>
                                                    <a id="view-excluded" class="btn btn-link" href="#view-excluded" target="_blank" style="text-decoration: none; padding: 0"><g:message code="dq.view.excluded" default="View excluded records"/></a>
                                                    <p id="filter-value" style="margin-bottom: 0"></p>
                                                    <button id='expandfilters' class="btn btn-link tooltips" data-dismiss="modal" title="<g:message code="dq.pop.out" default="Convert this data quality filter into separate filter queries you can include/exclude individually"></g:message>" style="text-decoration: none; padding: 0"><g:message code="dq.categoryinfo.dlg.expandbutton.text" default="Expand and edit filters"/></button>

                                                    <table class="table table-bordered table-condensed table-striped scrollTable" id="DQDetailsTable" style="margin-top: 20px">
                                                        <thead class="fixedHeader">
                                                        <tr>
                                                            <th><alatag:message code="dq.categoryinfo.dlg.fieldtable.heading.name" default="Field name"/></th>
                                                            <th><alatag:message code="dq.categoryinfo.dlg.fieldtable.heading.description" default="Description"/></th>
                                                            <th><alatag:message code="dq.categoryinfo.dlg.fieldtable.heading.wiki" default="Wiki"/></th>
                                                        </tr>

                                                        <tr class="spinnerRow">
                                                            <td colspan="3" style="text-align: center;"><g:message code="facets.multiplefacets.tabletr01td01" default="loading data"/>... <asset:image src="spinner.gif" id="spinner2" class="spinner" alt="spinner icon"/></td>
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
                                                            <th><alatag:message code="dq.categoryinfo.dlg.valuetable.heading.wiki" default="Wiki"/></th>
                                                        </tr>

                                                        <tr class="spinnerRow">
                                                            <td colspan="3" style="text-align: center;"><g:message code="facets.multiplefacets.tabletr01td01" default="loading data"/>... <asset:image src="spinner.gif" id="spinner2" class="spinner" alt="spinner icon"/></td>
                                                        </tr>
                                                        </thead>

                                                        <tbody>
                                                        </tbody>
                                                    </table>
                                                </div>
                                                <div class="modal-footer">
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
                        <div class="activeFilters col-sm-12">
                            <b><alatag:message code="search.filters.heading" default="User selected filters"/></b>:&nbsp;
                            <g:each var="items" in="${sr.activeFacetObj}">
                                <g:if test="${items.key}">
                                    <g:each var="item" in="${items.value}">
                                        <g:set var="hasFq" value="${true}"/>
                                        <alatag:currentFilterItem key="${items.key}" value="${item}" facetValue="${item.value}" cssClass="btn btn-default btn-xs" cssColor="${UserFQColors[item.value]}" title="${fqInteract[item.value]}" addCloseBtn="${true}"/>
                                    </g:each>
                                </g:if>
                            </g:each>
                            <g:if test="${params.wkt}"><%-- WKT spatial filter   --%>
                                <g:set var="spatialType" value="${params.wkt =~ /^\w+/}"/>
                                <a href="${alatag.getQueryStringForWktRemove()}" class="btn tooltips btn-default btn-xs"
                                   title="<g:message code="list.resultsretuened.click.to.remove.filters"/>"><g:message code="list.resultsretuened.spatial.filter"/>: ${spatialType[0]}
                                    <span class="closeX">&times;</span>
                                </a>
                            </g:if>
                            <g:elseif test="${params.radius && params.lat && params.lon}">
                                <a href="${alatag.getQueryStringForRadiusRemove()}" class="btn tooltips btn-default btn-xs"
                                   title="<g:message code="list.resultsretuened.click.to.remove.filters"/>"><g:message code="list.resultsretuened.spatial.filter"/>: <g:message code="list.resultsretuened.circle"/>
                                    <span class="closeX">&times;</span>
                                </a>
                            </g:elseif>
                            <g:if test="${sr.activeFacetObj?.collect { it.value.size() }.sum() > 1 }">
                                <a href="${alatag.createFilterItemLink(facet: 'all')}" class="btn btn-primary activeFilter btn-xs"
                                   title="<g:message code="list.resultsretuened.button01.title"/>"><span
                                        class="closeX">&gt;&nbsp;</span><g:message code="list.resultsretuened.button01"
                                                                                   default="Clear all"/></a>
                            </g:if>
                        </div>
                    </g:if>
                <%-- jQuery template used for taxon drop-downs --%>
                    <div class="btn-group hide" id="template">
                        <a class="btn btn-default btn-sm" href="" id="taxa_" title="<g:message code="list.resultsretuened.navigator01.title"/>" target="BIE"><g:message
                                code="list.resultsretuened.navigator01" default="placeholder"/></a>
                        <button class="btn dropdown-toggle btn-default btn-sm" data-toggle="dropdown"
                                title="<g:message code="list.resultsretuened.click.more.info"/>">
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
                                               title="<g:message code="list.resultsretuened.restrict.results"/>">

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
                                           title="<g:message code="list.downloads.navigator.title2" args="${[g.formatNumber(number: sr.totalRecords, format: "#,###,###")]}"/>">
                                            <i class="fa fa-download"></i>&nbsp;&nbsp;<g:message
                                                code="list.downloads.navigator" default="Downloads"/></a>
                                    </div>
                                </g:if>
                                <g:if test="${grailsApplication.config.alerts.baseUrl}">
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
                                        params="${params.clone().with { it.remove('max'); it.remove('offset'); it } }"
                            />
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
