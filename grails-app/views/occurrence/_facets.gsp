<div id="facetWell" class="well well-sm">
    <g:set var="startTime" value="${System.currentTimeMillis()}"/>
    ${alatag.logMsg(msg:"Start of facets.gsp - " + startTime)}
    <h3 class="visible-xs">
        <a href="#" id="toggleFacetDisplay"><i class="icon-chevron-down" id="facetIcon"></i>
            <alatag:message code="search.facets.heading" default="Refine results"/></a>
    </h3>
    <div class="sidebar hidden-xs">
        <h3 class="hidden-xs"><alatag:message code="search.facets.heading" default="Refine results"/></h3>
    </div>
    <div class="sidebar hidden-xs" style="clear:both;">
        <g:if test="${sr.query}">
            <g:set var="queryStr" value="${params.q ? params.q : searchRequestParams.q}"/>
            <g:set var="paramList" value=""/>
            <g:set var="queryParam" value="${sr.urlParameters.stripIndent(1)}" />
        </g:if>
        <g:if test="${sr.activeFacetObj?.values()?.any()}">
            <div id="currentFilter">
                <h4><span class="FieldName"><alatag:message code="search.filters.heading" default="Current filters"/></span></h4>
                <div class="subnavlist">
                    <ul id="refinedFacets">
                        <g:each var="items" in="${sr.activeFacetObj}">
                            <g:each var="item" in="${items.value}">
                                <li><alatag:currentFilterItem key="${items.key}" value="${item}" facetValue="${item.value}" addCheckBox="${true}"/></li>
                            </g:each>
                        </g:each>
                        <g:if test="${sr.activeFacetObj?.collect { it.value.size() }.sum() > 1 }">
                            <li><a href="${alatag.createFilterItemLink(facet: 'all')}" class="activeFilter" title="<g:message code="search.facets.clear.all.filters"/>">
                                <span class="closeX" style="margin-left:7px;">&gt;&nbsp;</span><g:message code="facets.currentfilter.link" default="Clear all"/></a>
                            </li>
                        </g:if>
                    </ul>
                </div>
            </div>
        </g:if>
        ${alatag.logMsg(msg:"Before grouped facets facets.gsp")}
        <alatag:ifDataQualityEnabled>
            <g:if test="${!searchRequestParams.disableAllQualityFilters && qualityCategories}">
                <div class="facetGroupName" id="heading_data_quality">
                    <a href="#" class="showHideFacetGroup" data-name="data_quality" id="showHideDQFilter"><span class="caret right-caret"></span> <g:message code="quality.filters.group.title" default="Quality filters"/></a>
                </div>
                <div class="facetsGroup" id="group_data_quality" style="display:none;">

                    <h4><span class="FieldName"><alatag:message code="dq.selectmultiple.categorytable.header.categories" default="Categories" /></span></h4>
                    <div class="subnavlist" style="clear:left">
                        <ul class="facets dq-categories">
                            <g:each var="qualityCategory" in="${qualityCategories}">
                                <li>
                                    <g:set var="qcDisabled" value="${searchRequestParams.disableQualityFilter.contains(qualityCategory.label)}" />
                                    <g:if test="${qcDisabled}">
                                        <alatag:linkQualityCategory enable="${true}" expand="${true}" category="${qualityCategory}" class="tooltips" title="${g.message(code: 'dq.pop.in', default: 'Re-enable this data quality filter and remove its corresponding filter queries')}">
                                            <span class="fa fa-square-o">&nbsp;</span><span class="tooltips" title="${qualityCategory.description}">${qualityCategory.name}</span>&nbsp;<span class="exclude-count-facet" data-category="${qualityCategory.label}"></span>
                                        </alatag:linkQualityCategory>
                                    </g:if>
                                    <g:else>
                                        <alatag:linkQualityCategory enable="${false}" expand="${false}" category="${qualityCategory}">
                                            <span class="fa fa-check-square-o">&nbsp;</span><span class="tooltips" title="${qualityCategory.description}">${qualityCategory.name}</span>&nbsp;<span class="exclude-count-facet" data-category="${qualityCategory.label}"></span>
                                        </alatag:linkQualityCategory>
                                    </g:else>
                                    &nbsp;
                                    <span>
                                        <a href="#DQCategoryDetails" class="DQCategoryDetailsLink" data-profilename="${activeProfile.name}" data-dqcategoryname="${qualityCategory.name}" data-categorylabel="${qualityCategory.label}" data-fq="${qualityFiltersByLabel[qualityCategory.label]}" data-description="${groovy.json.JsonOutput.toJson(qualityFilterDescriptionsByLabel[qualityCategory.label])}" data-translation="${translatedFilterMap[qualityCategory.label]}" data-disabled="${qcDisabled}" data-inverse-filter="${alatag.createInverseQualityCategoryLink(category: qualityCategory, inverseFilters: inverseFilters)}" data-filters="${groovy.json.JsonOutput.toJson(qualityCategory.qualityFilters.findAll{it.enabled}*.filter.flatten())}"  data-dqcategorydescription="${qualityCategory.description}" data-toggle="modal" role="button"><i class="fa fa-info-circle tooltips" title="<g:message code="dq.categoryinfo.button.tooltip" default="Click for more information and actions"/>"></i>
                                            &nbsp;
                                            <span class="facet-count">
                                            <i class="fa fa-circle-o-notch fa-spin exclude-loader"></i>
                                            </span>
                                        </a>

                                    </span>
                                </li>
                            </g:each>
                        </ul>
                    </div>
                    <g:if test="${qualityCategories.size() > 1}">
                        <a href="#DQManageFilters" class="multipleFiltersLink" data-toggle="modal" role="button" title="<g:message code="dq.button.filterselection.tooltip"/>"><span class="glyphicon glyphicon-hand-right" aria-hidden="true"></span>&nbsp;<alatag:message code="dq.button.filterselection.text" default="Select filters"/></a>
                    </g:if>
                </div>
            </g:if>
        </alatag:ifDataQualityEnabled>
        <g:set var="facetMax" value="${10}"/><g:set var="i" value="${1}"/>
        <g:each var="group" in="${groupedFacetsRequested}">
            <g:set var="keyCamelCase" value="${group.key.replaceAll(/\s+/,'')}"/>
            <div class="facetGroupName" id="heading_${keyCamelCase}">
                <a href="#" class="showHideFacetGroup" data-name="${keyCamelCase}"><span class="caret right-caret"></span> <g:message code="facet.group.${group.key}" default="${group.key}"/></a>
            </div>
            <div class="facetsGroup" id="group_${keyCamelCase}" style="display:none;">
                <g:set var="firstGroup" value="${false}"/>
                <g:each in="${group.value}" var="facetFromGroup">
                    <%--  Do a lookup on groupedFacetsMap for the current facet --%>
                    <g:set var="facetResult" value="${groupedFacetsMap.get(facetFromGroup)}"/>
                   <%--  Tests for when to display a facet --%>
                    <g:if test="${facetResult && ! sr.activeFacetMap?.containsKey(facetResult.fieldName ) }">
                        <g:set var="fieldDisplayName" value="${alatag.formatDynamicFacetName(fieldName:"${facetResult.fieldName}")}"/>
                        <h4><span class="FieldName">${fieldDisplayName?:facetResult.fieldName}</span></h4>
                        <div class="subnavlist" style="clear:left" id="facet_${facetResult.fieldName}">
                            <div id="spinner_${facetResult.fieldName}" class="spinner" >
                                <asset:image src="spinner.gif" id="spinner" class="spinner" alt="spinner icon"/>
                            </div>
                        </div>
                        <div class="showHide" id="more_${facetResult.fieldName}" style="display:none">
                            <a href="#multipleFacets" class="multipleFacetsLink" id="multi-${facetResult.fieldName}" role="button" data-toggle="modal" data-target="#multipleFacets" data-displayname="${fieldDisplayName}"
                               title="<g:message code="search.facets.see.more.options"/>"><span class="glyphicon glyphicon-hand-right" aria-hidden="true"></span> <g:message code="facets.facetfromgroup.link" default="choose more"/>...</a>
                        </div>
                    </g:if>
                </g:each>
            </div>
        </g:each>
        ${alatag.logMsg(msg:"After grouped facets facets.gsp")}
    </div>
</div><!--end facets-->
<!-- modal popup for "choose more" link -->
<div id="multipleFacets" class="modal fade " tabindex="-1" role="dialog" aria-labelledby="multipleFacetsLabel"><!-- BS modal div -->
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                <h3 id="multipleFacetsLabel"><g:message code="facets.multiplefacets.title" default="Refine your search"/></h3>
            </div>
            <div class="modal-body">
                <div id="dynamic" class="tableContainer">
                    <form name="facetRefineForm" id="facetRefineForm" method="GET" action="/occurrences/search/facets">
                        <table class="table table-bordered table-condensed table-striped scrollTable" id="fullFacets">
                            <thead class="fixedHeader">
                                <tr class="tableHead">
                                    <th>&nbsp;</th>
                                    <th id="indexCol" width="80%"><a href="#index" class="fsort" data-sort="index" data-foffset="0"></a></th>
                                    <th style="border-right-style: none;text-align: right;"><a href="#count" class="fsort" data-sort="count" data-foffset="0" title="<g:message code="facets.multiplefacets.tableth01.title"/>"><g:message code="facets.multiplefacets.tableth01" default="Count"/></a></th>
                                </tr>
                            </thead>
                            <tbody class="scrollContent">
                                <tr class="hide">
                                    <td><input type="checkbox" name="fqs" class="fqs" value=""></td>
                                    <td><a href=""></a></td>
                                    <td style="text-align: right; border-right-style: none;"></td>
                                </tr>
                            </tbody>
                        </table>
                        <div id="spinnerRow">
                            <span style="text-align: center;"><g:message code="facets.multiplefacets.tabletr01td01" default="loading data"/>... <asset:image src="spinner.gif" id="spinner2" class="spinner" alt="spinner icon"/></span>
                        </div>
                    </form>
                </div>
            </div>
            <div id='submitFacets' class="modal-footer" style="text-align: left;">
                <div class="btn-group">
                    <button type='submit' class='submit btn btn-default btn-small' id="include"><g:message code="facets.includeSelected.button" default="INCLUDE selected items"/></button>
                    <button class="btn btn-default btn-small dropdown-toggle" data-toggle="dropdown">
                        <span class="caret"></span>
                    </button>
                    <ul class="dropdown-menu">
                        <!-- dropdown menu links -->
                        <li>
                            <a href="#" class="wildcard" id="includeAll"><g:message code="facets.submitfacets.li01" default="INCLUDE all values (wildcard include)"/></a>
                        </li>
                    </ul>
                </div>
                &nbsp;
                <div class="btn-group">
                    <button type='submit' class='submit btn btn-default btn-small' id="exclude" ><g:message code="facets.excludeSelected.button" default="EXCLUDE selected items"/></button>
                    <button class="btn btn-default btn-small dropdown-toggle" data-toggle="dropdown">
                        <span class="caret"></span>
                    </button>
                    <ul class="dropdown-menu">
                        <!-- dropdown menu links -->
                        <li>
                            <a href="#" class="wildcard" id="excludeAll"><g:message code="facets.submitfacets.li02" default="EXCLUDE all values (wildcard exclude)"/></a>
                        </li>
                    </ul>
                </div>
                &nbsp;
                <a href="#" id="downloadFacet" class="btn btn-default btn-small" title="${g.message(code:'facets.downloadfacets.button', default:'Download this list')}"><i class="fa fa-download" title="${g.message(code:'facets.downloadfacets.button', default:'Download this list')}"></i> <span class="hide"><g:message code="facets.downloadfacets.button" default="Download"/></span></a>
                <button class="btn btn-default btn-small" data-dismiss="modal" aria-hidden="true" style="float:right;"><g:message code="facets.submitfacets.button" default="Close"/></button>
            </div>
        </div>
    </div>
</div>
<g:if test="${params.benchmarks}">
    <g:set var="endTime" value="${System.currentTimeMillis()}"/>
    ${alatag.logMsg(msg:"End of facets.gsp - " + endTime + " => " + (endTime - startTime))}
    <div style="color:#ddd;">
        <g:message code="facets.endtime.l" default="facets render time"/> = ${(endTime - startTime)} <g:message code="facets.endtime.r" default="ms"/>
    </div>
</g:if>
