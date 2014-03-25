<div id="facetWell" class="well well-small">
    ${alatag.logMsg(msg:"Start of facets.gsp")}
    <h3 class="visible-phone">
        <a href="#" id="toggleFacetDisplay"><i class="icon-chevron-down" id="facetIcon"></i>
            Refine results</a>
    </h3>
    <div class="sidebar hidden-phone">
        <h3 class="hidden-phone"><g:message code="search.facets.heading" default="Refine results"/></h3>
    </div>
    <div class="sidebar hidden-phone" style="clear:both;">
        <g:if test="${sr.query}">
            <g:set var="queryStr" value="${params.q ? params.q : searchRequestParams.q}"/>
            <g:set var="paramList" value=""/>
            <g:set var="queryParam" value="${sr.urlParameters.stripIndent(1)}" />
        </g:if>
        <g:if test="${sr.activeFacetMap}">
            <div id="currentFilter">
                <h4><span class="FieldName"><g:message code="search.filters.heading" default="Current filters"/></span></h4>
                <div class="subnavlist">
                    <ul id="refinedFacets">
                        <g:each var="item" in="${sr.activeFacetMap}">
                            <li><alatag:currentFilterItem item="${item}" addCheckBox="${true}"/></li>
                        </g:each>
                        <g:if test="${sr.activeFacetMap?.size() > 1}">
                            <li><a href="#" class="activeFilter" data-facet="all" title="Click to clear all filters">
                                <span class="closeX" style="margin-left:7px;">&gt;&nbsp;</span>Clear all</a>
                            </li>
                        </g:if>
                    </ul>
                </div>
            </div>
        </g:if>
        ${alatag.logMsg(msg:"Before grouped facets facets.gsp")}
        <g:set var="facetMax" value="${20}"/><g:set var="i" value="${1}"/>
        <g:each var="group" in="${groupedFacets}">
            <g:set var="keyCamelCase" value="${group.key.replaceAll(/\s+/,'')}"/>
            <div class="facetGroupName" id="heading_${keyCamelCase}">
                <a href="#" class="showHideFacetGroup" data-name="${keyCamelCase}"><span class="caret right-caret"></span> ${group.key}</a>
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
                        <g:if test="${facetResult.fieldResult.length() > 1}">
                            <div class="showHide">
                                <a href="#multipleFacets" class="multipleFacetsLink" id="multi-${facetResult.fieldName}" role="button" data-toggle="modal" data-displayname="${fieldDisplayName}"
                                   title="See more options or refine with multiple values"><i class="icon-hand-right"></i> choose more...</a>
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
        <h3 id="multipleFacetsLabel">Refine your search</h3>
    </div>
    <div class="modal-body">
        <div id="dynamic" class="tableContainer">
            <form name="facetRefineForm" id="facetRefineForm" method="GET" action="/occurrences/search/facets">
                <table class="table table-bordered table-condensed table-striped scrollTable" id="fullFacets">
                    <thead class="fixedHeader">
                        <tr class="tableHead">
                            <th>&nbsp;</th>
                            <th id="indexCol" width="80%"><a href="#index" class="fsort" data-sort="index" data-foffset="0"></a></th>
                            <th style="border-right-style: none;text-align: right;"><a href="#count" class="fsort" data-sort="count" data-foffset="0" title="Sort by record count">Count</a></th>
                        </tr>
                    </thead>
                    <tbody class="scrollContent">
                        <tr class="hide">
                            <td><input type="checkbox" name="fqs" class="fqs" value=""></td>
                            <td><a href=""></a></td>
                            <td style="text-align: right; border-right-style: none;"></td>
                        </tr>
                        <tr id="spinnerRow">
                            <td colspan="3" style="text-align: center;">loading data... <g:img dir="images" file="spinner.gif" id="spinner2" class="spinner" alt="spinner icon"/></td>
                        </tr>
                    </tbody>
                </table>
            </form>
        </div>
    </div>
    <div id='submitFacets' class="modal-footer" style="text-align: left;">
        <input type='submit' class='submit btn btn-small' id="include" value="INCLUDE selected items"/>
        &nbsp;
        <input type='submit' class='submit btn btn-small' id="exclude" value="EXCLUDE selected items"/>
        &nbsp;
        <button class="btn btn-small" data-dismiss="modal" aria-hidden="true" style="float:right;">Close</button>
    </div>
</div>
${alatag.logMsg(msg:"End of facets.gsp")}
