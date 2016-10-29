<div id="facetWell" class="well well-small">
    <g:set var="startTime" value="${System.currentTimeMillis()}"/>
    ${alatag.logMsg(msg:"Start of facets.gsp - " + startTime)}
    <h3 class="visible-phone">
        <a href="#" id="toggleFacetDisplay"><i class="icon-chevron-down" id="facetIcon"></i>
            <alatag:message code="search.facets.heading" default="Refine results"/></a>
    </h3>
    <div class="sidebar hidden-phone">
        <h3 class="hidden-phone"><alatag:message code="search.facets.heading" default="Refine results"/></h3>
    </div>
    <div class="sidebar hidden-phone" style="clear:both;">
        <g:if test="${sr.query}">
            <g:set var="queryStr" value="${params.q ? params.q : searchRequestParams.q}"/>
            <g:set var="paramList" value=""/>
            <g:set var="queryParam" value="${sr.urlParameters.stripIndent(1)}" />
        </g:if>
        <g:if test="${sr.activeFacetMap}">
            <div id="currentFilter">
                <h4><span class="FieldName"><alatag:message code="search.filters.heading" default="Current filters"/></span></h4>
                <div class="subnavlist">
                    <ul id="refinedFacets">
                        <g:each var="item" in="${sr.activeFacetMap}">
                            <li><alatag:currentFilterItem item="${item}" addCheckBox="${true}"/></li>
                        </g:each>
                        <g:if test="${sr.activeFacetMap?.size() > 1}">
                            <li><a href="#" class="activeFilter" data-facet="all" title="${alatag.message(code:"facets.currentfilter.clearall",default:"Click to clear all filters")}">
                                <span class="closeX" style="margin-left:7px;">&gt;&nbsp;</span><g:message code="facets.currentfilter.link" default="Clear all"/></a>
                            </li>
                        </g:if>
                    </ul>
                </div>
            </div>
        </g:if>
        ${alatag.logMsg(msg:"Before grouped facets facets.gsp")}
        <g:set var="facetMax" value="${10}"/><g:set var="i" value="${1}"/>
        <g:each var="group" in="${groupedFacets}">
            <g:set var="keyCamelCase" value="${group.key.replaceAll(/\s+/,'')}"/>
            <div class="facetGroupName" id="heading_${keyCamelCase}">
                <a href="#" class="showHideFacetGroup" data-name="${keyCamelCase}"><span class="caret right-caret"></span> <g:message code="facet.group.${group.key}" default="facet.group.${group.key}"/></a>
            </div>
            <div class="facetsGroup hide" id="group_${keyCamelCase}">
                <g:set var="firstGroup" value="${false}"/>
                <g:each in="${group.value}" var="facetFromGroup">
                    <%--  Do a lookup on groupedFacetsMap for the current facet --%>
                    <g:set var="facetResult" value="${groupedFacetsMap.get(facetFromGroup)}"/>
                   <%--  Tests for when to display a facet --%>
                    <g:if test="${facetResult && facetResult.fieldResult.length() >= 1 && facetResult.fieldResult[0].count != sr.totalRecords && ! sr.activeFacetMap?.containsKey(facetResult.fieldName ) }">
                        <g:set var="fieldDisplayName" value="${alatag.formatDynamicFacetName(fieldName:"${facetResult.fieldName}")}"/>
                        <h4><span class="FieldName">${fieldDisplayName?:facetResult.fieldName}</span></h4>
                        <div class="subnavlist nano" style="clear:left">
                            <alatag:facetLinkList facetResult="${facetResult}" queryParam="${queryParam}"/>
                        </div>
                        %{--<div class="fadeout"></div>--}%
                        <g:if test="${facetResult.fieldResult.length() > 0}">
                            <div class="showHide">
                                <a href="#multipleFacets" class="multipleFacetsLink" id="multi-${facetResult.fieldName}" role="button" data-toggle="modal" data-displayname="${fieldDisplayName}"
                                   title="${g.message(code:"facets.groupdynamicfacets.link.title",default:"See more options or refine with multiple values")}"><i class="icon-hand-right"></i> <g:message code="facets.facetfromgroup.link" default="choose more"/>...</a>
                            </div>
                        </g:if>
                    </g:if>
                </g:each>
            </div>
        </g:each>
        ${alatag.logMsg(msg:"After grouped facets facets.gsp")}
    </div>
</div><!--end facets-->
<!-- modal popup for "choose more" link -->
<div id="multipleFacets" class="modal hide " tabindex="-1" role="dialog" aria-labelledby="multipleFacetsLabel" aria-hidden="true"><!-- BS modal div -->
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
                            <th style="border-right-style: none;text-align: right;"><a href="#count" class="fsort" data-sort="count" data-foffset="0" title="${g.message(code:"facets.multiplefacets.count.title",default:"Sort by record count")}"><g:message code="facets.multiplefacets.tableth01" default="Count"/></a></th>
                        </tr>
                    </thead>
                    <tbody class="scrollContent">
                        <tr class="hide">
                            <td><input type="checkbox" name="fqs" class="fqs" value=""></td>
                            <td><a href=""></a></td>
                            <td style="text-align: right; border-right-style: none;"></td>
                        </tr>
                        <tr id="spinnerRow">
                            <td colspan="3" style="text-align: center;"><g:message code="facets.multiplefacets.tabletr01td01" default="loading data"/>... <g:img plugin="biocache-hubs" dir="images" file="spinner.gif" id="spinner2" class="spinner" alt="spinner icon"/></td>
                        </tr>
                    </tbody>
                </table>
            </form>
        </div>
    </div>
    <div id='submitFacets' class="modal-footer" style="text-align: left;">
        <div class="btn-group">
            <button type='submit' class='submit btn btn-small' id="include"><g:message code="facets.includeSelected.button" default="INCLUDE selected items"/></button>
            <button class="btn btn-small dropdown-toggle" data-toggle="dropdown">
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
            <button type='submit' class='submit btn btn-small' id="exclude" ><g:message code="facets.excludeSelected.button" default="EXCLUDE selected items"/></button>
            <button class="btn btn-small dropdown-toggle" data-toggle="dropdown">
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
        <a href="#" id="downloadFacet" class="btn btn-small" title="${g.message(code:'facets.downloadfacets.button', default:'Download this list')}"><i class="icon icon-download-alt" title="${g.message(code:'facets.downloadfacets.button', default:'Download this list')}"></i> <span class="hide"><g:message code="facets.downloadfacets.button" default="Download"/></span></a>
        <button class="btn btn-small" data-dismiss="modal" aria-hidden="true" style="float:right;"><g:message code="facets.submitfacets.button" default="Close"/></button>
    </div>
</div>
<script type="text/javascript">
    var dynamicFacets = new Array();
    <g:each in="${dynamicFacets}" var="dynamicFacet">
        dynamicFacets.push('${dynamicFacet.name}');
    </g:each>
</script>
<g:if test="${params.benchmarks}">
    <g:set var="endTime" value="${System.currentTimeMillis()}"/>
    ${alatag.logMsg(msg:"End of facets.gsp - " + endTime + " => " + (endTime - startTime))}
    <div style="color:#ddd;">
        <g:message code="facets.endtime.l" default="facets render time"/> = ${(endTime - startTime)} <g:message code="facets.endtime.r" default="ms"/>
    </div>
</g:if>
