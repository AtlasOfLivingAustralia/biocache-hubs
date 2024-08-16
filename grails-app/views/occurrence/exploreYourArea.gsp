<%--
  - Copyright (C) 2014 Atlas of Living Australia
  - All Rights Reserved.
  -
  - The contents of this file are subject to the Mozilla Public
  - License Version 1.1 (the "License"); you may not use this file
  - except in compliance with the License. You may obtain a copy of
  - the License at http://www.mozilla.org/MPL/
  -
  - Software distributed under the License is distributed on an "AS
  - IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
  - implied. See the License for the specific language governing
  - rights and limitations under the License.
--%>
<%--
  Created by IntelliJ IDEA.
  User: dos009@csiro.au
  Date: 4/03/2014
  Time: 4:39 PM
--%>
<%@ page contentType="text/html;charset=UTF-8" %>
<g:set var="biocacheServiceUrl" value="${grailsApplication.config.getProperty('biocache.baseUrl')}"/>
<g:set var="queryContext" value="${grailsApplication.config.getProperty('biocache.queryContext')}"/>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="${grailsApplication.config.getProperty('skin.layout')}"/>
    <meta name="section" content="yourArea"/>
    <meta name="breadcrumbParent" content="${grailsApplication.config.getProperty('skin.exploreUrl')},${message(code:"eya.parent.title")}"/>
    <meta name="breadcrumb" content="Explore your area"/>
    <title><g:message code="eya.title01" default="Explore Your Area"/> | ${grailsApplication.config.getProperty('skin.orgNameLong')} </title>

    <g:if test="${grailsApplication.config.getProperty('google.apikey')}">
        <script src="https://maps.googleapis.com/maps/api/js?key=${grailsApplication.config.getProperty('google.apikey')}" type="text/javascript"></script>
    </g:if>
    <g:else>
        <script src="https://maps.google.com/maps/api/js"></script>
    </g:else>

    <g:render template="/layouts/global"/>
    <asset:javascript src="exploreYourArea.js" asset-defer="true"/>
    <asset:stylesheet src="exploreYourArea.css" />
    <asset:stylesheet src="print-area.css" media="print" />

    <asset:script type="text/javascript">
        // Global variables for yourAreaMap.js
        var MAP_VAR = {
            contextPath: "${request.contextPath}",
            biocacheServiceUrl: "${biocacheServiceUrl.encodeAsHTML()?:''}",
            mappingUrl: "${biocacheServiceUrl.encodeAsHTML()?:''}", // duplicate var for map.commom.js
            forwardURI: "${request.forwardURI}",
            imagesUrlPrefix: "${request.contextPath}/assets/eya-images",
            zoom: Number(${zoom}),
            radius: Number(${radius}),
            speciesPageUrl: "${speciesPageUrl}",
            queryContext: "${queryContext}",
            mapMinimalUrl: "${grailsApplication.config.getProperty('map.minimal.url')}",
            mapMinimalAttribution: "${raw(grailsApplication.config.getProperty('map.minimal.attr'))}",
            mapMinimalSubdomains: "${grailsApplication.config.getProperty('map.minimal.subdomains')}",
            locale: "${org.springframework.web.servlet.support.RequestContextUtils.getLocale(request)}",
            geocodeRegion: "${grailsApplication.config.getProperty('geocode.region')}",
            hasGoogleKey: ${grailsApplication.config.getProperty('google.apikey') as Boolean},
            removeFqs: '',
            mapIconUrlPath: "${assetPath(src:'/leaflet/images')}"
        }

        //make the taxa and rank global variable so that they can be used in the download
        var taxa = ["*"], rank = "*";
    </asset:script>
</head>
<body class="nav-locations explore-your-area">
<div id="header" class="heading-bar">
    <g:if test="${grailsApplication.config.getProperty('skin.layout') == 'ala'}">
        <div id="breadcrumb">
            <ol class="breadcrumb">
                <li><a href="${grailsApplication.config.getProperty('organisation.baseUrl')}"><g:message code="eya.breadcrumb.navigator01" default="Home"/></a> <span class=" icon icon-arrow-right"></span></li>
                <li><a href="${grailsApplication.config.getProperty('organisation.baseUrl')}/species-by-location/"><g:message code="eya.breadcrumb.navigator02" default="Locations"/></a> <span class=" icon icon-arrow-right"></span></li>
                <li class="active"><g:message code="eya.breadcrumb.navigator03" default="Your Area"/></li>
            </ol>
        </div>
    </g:if>
    <h1><g:message code="eya.header.title" default="Explore Your Area"/></h1>
</div>
<form name="searchForm" id="searchForm" class="" action="" method="GET">
    <input type="hidden" name="latitude" id="latitude" value="${latitude}"/>
    <input type="hidden" name="longitude" id="longitude" value="${longitude}"/>
    <input type="hidden" name="location" id="location" value="${location}"/>
    <div class="control-group">
        <label class="control-label" for="address"><h4><g:message code="eya.searchform.label01" default="Enter your location or address"/>:</h4></label>
        <div class="controls row">
            <div class="col-md-5">
                <div class="input-group">
                    <input type="text" name="address" id="address" class="form-control">
                    <span class="input-group-btn">
                        <input id="locationSearch" type="submit" class="btn btn-default" value="<g:message code="eya.searchform.btn01" default="Search"/>"/>
                    </span>
                </div><!-- /input-group -->
            </div><!-- /.col-md-5 -->
            <div class="col-md-7 help-inline"><g:message code="eya.searchform.des01" default="E.g. a street address, place name, postcode or GPS coordinates (as lat, long)"/></div>
        </div><!-- /.row -->
    </div>
    <div id="locationInfo" class="col-md-12 row ">
        <g:if test="${true || location}">
            <div id="resultsInfo">
                <g:message code="eya.searchform.label02" default="Showing records for"/>: <span id="markerAddress">${location}</span>&nbsp;&nbsp<a href="#" id="addressHelp" style="text-decoration: none"><span class="help-container">&nbsp;</span></a>
            </div>
        </g:if>
        <div class="row">
            <div class="col-md-12">
                <span class="pad">
                    <g:message code="eya.searchformradius.label01" default="Display records in a"/>
                    <select id="radius" name="radius" class="" style="height:24px;width:auto;line-height:18px;margin-bottom:0;">
                        <option value="1" <g:if test="${radius == 1}">selected</g:if>>1</option>
                        <option value="5" <g:if test="${radius == 5}">selected</g:if>>5</option>
                        <option value="10" <g:if test="${radius == 10}">selected</g:if>>10</option>
                    </select> <g:message code="eya.searchformradius.label02" default="km radius"/>
                </span>
                <span class="pad">
                    <a href="#" id="viewAllRecords" class="btn btn-sm btn-default"><i class="glyphicon glyphicon-list"></i>&nbsp;&nbsp;<g:message code="eya.searchform.a.viewallrecords.01" default="View"/>
                        <span id="recordsGroupText"><g:message code="eya.searchform.a.viewallrecords.02" default="all"/></span>  <g:message code="eya.searchform.a.viewallrecords.03" default="records"/></a>
                </span>
                <span class="pad">
                    <g:if test="${grailsApplication.config.getProperty('useDownloadPlugin', Boolean)}">
                        <a href="#" id="downloadData" class="btn btn-sm btn-default tooltips" title="Download records, check lists or field guides">
                            <i class="glyphicon glyphicon-download-alt"></i>&nbsp;&nbsp;
                            <g:message code="list.downloads.navigator" default="Download"/></a>
                    </g:if>
                    <g:else>
                        <a href="#downloadModal"
                           role="button"
                           data-toggle="modal"
                           class="btn btn-sm btn-default tooltips"
                           title="Download all records OR species checklist">
                            <i class="glyphicon glyphicon-download-alt"></i> <g:message code="eya.searchform.a.downloads" default="Downloads"/></a>
                    </g:else>
                </span>
            </div>
        </div>
        <div id="dialog-confirm" title="Continue with download?" style="display: none">
            <p><span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0;"></span><g:message code="eya.dialogconfirm01" default="You are about to download a list of species found within a"/> <span id="rad"></span> <g:message code="eya.dialogconfirm02" default="km radius of"/> <code>${location}</code>.<br/>
                <g:message code="eya.dialogconfirm03" default="Format: tab-delimited text file (called data.xls)"/></p>
        </div>
    </div>
</form>
<div class="row">
    <div class="col-md-7 col-xs-12">
        <div id="taxaBox">
            <div id="leftList">
                <table id="taxa-level-0">
                    <thead>
                    <tr>
                        <th><g:message code="eya.table.01.th01" default="Group"/></th>
                        <th><g:message code="eya.table.01.th02" default="Species"/></th>
                    </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            </div>
            <div id="rightList" class="tableContainer">
                <div id="spinnerRow" style="position:absolute;margin-top:40px;margin-left:40px">
                    <span style="text-align: center;"><g:message code="facets.multiplefacets.tabletr01td01" default="loading data"/>... <asset:image src="spinner.gif" id="spinner2" class="spinner" alt="spinner icon"/></span>
                </div>
                <table>
                    <thead class="fixedHeader">
                    <tr>
                        <th class="speciesIndex">&nbsp;&nbsp;</th>
                        <th class="sciName"><a href="0" id="commonSort" data-sort="common" title="sort by common name"><g:message code="eya.table.02.th01.a" default="Common Name"/></a></th>
                        <th class="sciName"><a href="0" id="speciesSort" data-sort="taxa" title="sort by scientific name"><g:message code="eya.table.02.th01" default="Scientific Name"/></a></th>
                        <th class="rightCounts"><a href="0" data-sort="count" title="sort by record count"><g:message code="eya.table.02.th02" default="Records"/></a></th>
                    </tr>
                    </thead>
                    <tbody class="scrollContent">
                    </tbody>
                </table>
            </div>
        </div>
    </div><!-- .col-md-7 -->
    <div class="col-md-5 col-xs-12">
        <div id="mapCanvas" style="width: 100%; height: 490px;"></div>
        <div style="font-size:11px;width:100%;color:black;height:20px;" class="show-80 collapse">
            <table id="cellCountsLegend">
                <tr>
                    <td style="background-color:#000; color:white; text-align:right;"><g:message code="eya.table.03.td" default="Records"/>:&nbsp;</td>
                    <td style="background-color:#ffff00;">1&ndash;9</td>
                    <td style="background-color:#ffcc00;">10&ndash;49</td>
                    <td style="background-color:#ff9900;">50&ndash;99</td>
                    <td style="background-color:#ff6600;">100&ndash;249</td>
                    <td style="background-color:#ff3300;">250&ndash;499</td>
                    <td style="background-color:#cc0000;">500+</td>
                </tr>
            </table>
        </div>
        <div id="mapTips">
            <b><g:message code="eya.maptips.01" default="Tip"/></b>: <g:message code="eya.maptips.02" default="you can fine-tune the location of the area by dragging the blue marker icon"/>
        </div>
    </div><!-- .col-md-5 -->
</div><!-- .row -->

<g:render template="mapPopup"/>
<g:if test="${!grailsApplication.config.getProperty('useDownloadPlugin', Boolean)}">
    <g:render template="download"/>
</g:if>
</body>
</html>
