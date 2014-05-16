<%--
  Created by IntelliJ IDEA.
  User: dos009@csiro.au
  Date: 28/02/2014
  Time: 3:15 PM
  To change this template use File | Settings | File Templates.
--%>
<%@ page import="au.org.ala.biocache.hubs.FacetsName; org.apache.commons.lang.StringUtils" contentType="text/html;charset=UTF-8" %>
<g:set var="hubDisplayName" value="${grailsApplication.config.skin.orgNameLong}"/>
<g:set var="biocacheServiceUrl" value="${grailsApplication.config.biocache.baseUrl}"/>
<g:set var="serverName" value="${grailsApplication.config.serverName?:grailsApplication.config.biocache.baseUrl}"/>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="${grailsApplication.config.skin.layout}"/>
    <meta name="section" content="search"/>
    <meta name="svn.revision" content="${meta(name: 'svn.revision')}"/>
    <title>Search for records | ${hubDisplayName}</title>
    <r:require modules="jquery"/>
    <r:script>
        $(document).ready(function() {

            $('a[data-toggle="tab"]').on('shown', function(e) {
                //console.log("this", $(this).attr('id'));
                var id = $(this).attr('id');
                location.hash = 'tab_'+ $(e.target).attr('href').substr(1);
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
        });
    </r:script>
</head>

<body>
    <div id="headingBar">
        <h1 style="width:100%;" id="searchHeader"><g:message code="home.searchForRecordsIn" deafault="Search for records in"/> ${raw(hubDisplayName)}</h1>
    </div>
    <g:if test="${flash.message}">
        <div class="message alert alert-info">
            <button type="button" class="close" onclick="$(this).parent().hide()">×</button>
            <b>Alert:</b> ${raw(flash.message)}
        </div>
    </g:if>
    <div class="row-fluid" id="content">
        <div class="span12">
            <div class="tabbable">
                <ul class="nav nav-tabs" id="searchTabs">
                    <li><a id="t1" href="#simpleSearch" data-toggle="tab">Simple search</a></li>
                    <li><a id="t2" href="#advanceSearch" data-toggle="tab">Advanced search</a></li>
                    <li><a id="t3" href="#taxaUpload" data-toggle="tab">Batch taxon search</a></li>
                    <li><a id="t4" href="#catalogUpload" data-toggle="tab">Catalogue number search</a></li>
                    <li><a id="t5" href="#shapeFileUpload" data-toggle="tab">Shapefile search</a></li>
                </ul>
            </div>
            <div class="tab-content searchPage">
                <div id="simpleSearch" class="tab-pane active">
                    <form name="simpleSearchForm" id="simpleSearchForm" action="${request.contextPath}/occurrences/search" method="GET">
                        <br/>
                        <div class="controls">
                            <div class="input-append">
                                <input type="text" name="taxa" id="taxa" class="input-xxlarge">
                                <button id="locationSearch" type="submit" class="btn"><g:message code="search.simple.button.label" default="Search"/></button>
                            </div>
                        </div>
                        <div>
                            <br/>
                            <span style="font-size: 12px; color: #444;">
                                <b>Note:</b> the simple search attempts to match a known <b>species/taxon</b> - by its scientific name or common name.
                                If there are no name matches, a <b>full text</b> search will be performed on your query
                            </span>
                        </div>
                    </form>
                </div><!-- end simpleSearch div -->
                <div id="advanceSearch" class="tab-pane">
                    <g:render template="advanced" />
                </div><!-- end #advancedSearch div -->
                <div id="taxaUpload" class="tab-pane">
                    <form name="taxaUploadForm" id="taxaUploadForm" action="${biocacheServiceUrl}/occurrences/batchSearch" method="POST">
                        <p>Enter a list of taxon names/scientific names, one name per line (common names not currently supported).</p>
                        <%--<p><input type="hidden" name="MAX_FILE_SIZE" value="2048" /><input type="file" /></p>--%>
                        <p><textarea name="queries" id="raw_names" class="span6" rows="15" cols="60"></textarea></p>
                        <p>
                            <%--<input type="submit" name="action" value="Download" />--%>
                            <%--&nbsp;OR&nbsp;--%>
                            <input type="hidden" name="redirectBase" value="${serverName}${request.contextPath}/occurrences/search"/>
                            <input type="hidden" name="field" value="raw_name"/>
                            <input type="submit" name="action" value="Search" class="btn" /></p>
                    </form>
                </div><!-- end #uploadDiv div -->
                <div id="catalogUpload" class="tab-pane">
                    <form name="catalogUploadForm" id="catalogUploadForm" action="${biocacheServiceUrl}/occurrences/batchSearch" method="POST">
                        <p>Enter a list of catalogue numbers (one number per line).</p>
                        <%--<p><input type="hidden" name="MAX_FILE_SIZE" value="2048" /><input type="file" /></p>--%>
                        <p><textarea name="queries" id="catalogue_numbers" class="span6" rows="15" cols="60"></textarea></p>
                        <p>
                            <%--<input type="submit" name="action" value="Download" />--%>
                            <%--&nbsp;OR&nbsp;--%>
                            <input type="hidden" name="redirectBase" value="${serverName}${request.contextPath}/occurrences/search"/>
                            <input type="hidden" name="field" value="catalogue_number"/>
                            <input type="submit" name="action" value="Search" class="btn"/></p>
                    </form>
                </div><!-- end #catalogUploadDiv div -->
                <div id="shapeFileUpload" class="tab-pane">
                    <form name="shapeUploadForm" id="shapeUploadForm" action="${request.contextPath}/occurrences/shapeUpload" method="POST" enctype="multipart/form-data">
                        <p>Note: this feature is still experimental. If there are multiple polygons present in the shapefile,
                            only the first polygon will be used for searching.</p>
                        <p>Upload a shapefile (*.shp).</p>
                        <p><input type="file" name="file" class="" /></p>
                        <p><input type="submit" value="Search" class="btn"/></p>
                    </form>
                </div><!-- end #shapeFileUpload  -->
            </div><!-- end .tab-content -->
        </div><!-- end .span12 -->
    </div><!-- end .row-fluid -->
</body>
</html>