<%--
  Created by IntelliJ IDEA.
  User: dos009@csiro.au
  Date: 11/02/14
  Time: 10:52 AM
  To change this template use File | Settings | File Templates.
--%>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ page import="org.apache.commons.lang.StringUtils" contentType="text/html;charset=UTF-8" %>
<g:set var="recordId" value="${alatag.getRecordId(record: record, skin: skin)}"/>
<g:set var="bieWebappContext" value="${grailsApplication.config.getProperty('bie.baseUrl')}"/>
<g:set var="collectionsWebappContext" value="${grailsApplication.config.getProperty('collections.baseUrl')}"/>
<g:set var="useAla" value="${grailsApplication.config.getProperty('skin.useAlaBie', Boolean, false)}"/>
<g:set var="taxaLinks" value="${grailsApplication.config.getProperty('skin.taxaLinks', Map, [:])}"/>
<g:set var="dwcExcludeFields" value="${grailsApplication.config.getProperty('dwc.exclude')}"/>
<g:set var="hubDisplayName" value="${grailsApplication.config.getProperty('skin.orgNameLong')}"/>
<g:set var="biocacheService" value="${alatag.getBiocacheAjaxUrl()}"/>
<g:set var="spatialPortalUrl" value="${grailsApplication.config.getProperty('spatial.baseUrl')}"/>
<g:set var="serverName" value="${grailsApplication.config.getProperty('serverName')}"/>
<g:set var="scientificName" value="${alatag.getScientificName(record: record)}"/>
<g:set var="sensitiveDatasetRaw" value="${grailsApplication.config.getProperty('sensitiveDataset.list', String, '')}"/>
<g:set var="sensitiveDatasets" value="${sensitiveDatasetRaw?.split(',')}"/>
<g:set var="userDisplayName" value="${alatag.loggedInUserDisplayname()}"/>
<g:set var="userId" value="${alatag.loggedInUserId()}"/>
<g:set var="isUnderAuth" value="${grailsApplication.config.getProperty('security.cas.enabled', Boolean, false) || grailsApplication.config.getProperty('security.oidc.enabled', Boolean, false)}"/>
<g:set var="showVernacularName" value="${grailsApplication.config.getProperty('vernacularName.show', Boolean, true)}"/>
<!DOCTYPE html>
<html>
<head>
    <meta name="svn.revision" content="${meta(name: 'svn.revision')}"/>
    <meta name="layout" content="${grailsApplication.config.getProperty('skin.layout')}"/>
    <meta name="section" content="search"/>
    <meta name="breadcrumbParent" content="${request.contextPath ?: '/'},${message(code: "search.heading.list")}"/>
    <meta name="breadcrumb" content="${message(code: "show.title")}: ${recordId} (${scientificName})"/>
    <title><g:message code="show.title" default="Record"/>: ${recordId} | <g:message code="show.occurrenceRecord" default="Occurrence record"/>  | ${hubDisplayName}</title>


    <g:if test="${grailsApplication.config.getProperty('google.apikey')}">
        <script src="https://maps.googleapis.com/maps/api/js?key=${grailsApplication.config.getProperty('google.apikey')}" type="text/javascript"></script>
    </g:if>
    <g:else>
        <script type="text/javascript" src="https://www.google.com/jsapi"></script>
    </g:else>

    <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">
        // Global var OCC_REC to pass GSP data to external JS file
        var OCC_REC = {
            userId: "${userId}",
            userDisplayName: "${userDisplayName}",
            contextPath: "${request.contextPath}",
            searchOffset: "${searchOffset}",
            recordUuid: "${record.raw.rowKey}",
            taxonRank: "${record.processed.classification.taxonRank}",
            taxonConceptID: "${record.processed.classification.taxonConceptID}",
            locale: "${org.springframework.web.servlet.support.RequestContextUtils.getLocale(request)}",
            sensitiveDatasets: {
                <g:each var="sds" in="${sensitiveDatasets}"
                   status="s">'${sds}': '${grailsApplication.config.getProperty('sensitiveDatasets', Map, [:])[sds]}'${s < (sensitiveDatasets.size() - 1) ? ',' : ''}
                </g:each>
            },
            hasGoogleKey: ${grailsApplication.config.getProperty('google.apikey', Boolean, false)},
            myAnnotationEnabled: ${(grailsApplication.config.getProperty("alerts.myannotation.enabled", Boolean, false))}
        }

        var BC_CONF = OCC_REC; // For compatibility with common JS components which require BC_CONF

        google.charts.load('current', {'packages':['bar', 'corechart', 'table']});

    </script>
    <g:render template="/layouts/global"/>

    <asset:javascript src="show.js" />

    <asset:stylesheet src="show.css" />
    <asset:stylesheet src="print.css" media="print" />

    <asset:script type="text/javascript">
        $(document).ready(function() {
            <g:if test="${record.processed.attribution.provenance == 'Draft'}">\
                // draft view button\
                $('#viewDraftButton').click(function(){
                    document.location.href = '${record.raw.occurrence.occurrenceID}';
                });
            </g:if>

            // Detect fields in the value class and convert to links
            $("table > tbody > tr > td.value").linkify({
                target: "_blank"
            });

        }); // end $(document).ready()

    </asset:script>

</head>
<body class="occurrence-record">
    <g:if test="${record}">
        <g:if test="${record.raw}">
            <div class="recordHeader clearfix" id="headingBar">
                <div class="side left">
                    <g:if test="${collectionLogo}">
                        <div class="sidebar">
                            <img src="${collectionLogo}" alt="institution logo" id="institutionLogo"/>
                        </div>
                    </g:if>
                </div>
                <div class="side right">
                    <div id="jsonLinkZ">
                        <g:if test="${isCollectionAdmin}">
                            <g:set var="admin" value=" - admin"/>
                        </g:if>
                        <g:if test="${false && alatag.loggedInUserDisplayname()}">
                            <g:message code="show.jsonlink.login" default="Logged in as:"/> ${alatag.loggedInUserDisplayname()}
                        </g:if>
                        <g:if test="${clubView}">
                            <div id="clubView"><span class="label label-danger"><i class="glyphicon glyphicon-lock"></i><g:message code="show.clubview.message" default="Club View"/></span></div>
                        </g:if>
                    </div>
                <div class="pull-rightZ">
                    <g:if test="${displayNavigationButtons}">
                    <span id="previousBtn">
                        <a href="${request.contextPath}/occurrences/previous" title="<g:message code="show.previousbtn.navigator.title"/>" class="btn btn-default <g:if test="${isFirstOccurrence}">disabled</g:if>">
                            <span><i class="glyphicon glyphicon-arrow-left" style="margin-bottom: 5px;"></i><g:message code="show.previousbtn.navigator" default="Previous"/></span></a>
                    </span>
                    <span id="nextBtn">
                        <a href="${request.contextPath}/occurrences/next" title="<g:message code="show.nextbtn.navigator.title"/>" class="btn btn-default <g:if test="${isLastOccurrence}">disabled</g:if>">
                            <span><i class="glyphicon glyphicon-arrow-right" style="margin-bottom: 5px;"></i><g:message code="show.nextbtn.navigator" default="Next"/></span></a>
                        </a>
                    </span>
                    <span id="backBtn">
                        <a href="#" title="<g:message code="show.backbtn.navigator.title"/>" class="btn btn-default"><g:message code="show.backbtn.navigator" default="Back to search results"/></a>
                    </span>
                    </g:if>
                    </div>
                </div>
                <div class="centre">
                    <h1>
                        <g:message code="show.headingbar01.title" default="Occurrence record"/>
                        <span id="recordId">${recordId}</span>
                    </h1>
                    <g:if test="${record.raw.classification}">
                        <div id="recordHeadingLine2">
                            <g:message code="basisOfRecord.${record.processed.occurrence?.basisOfRecord}" default="${record.processed.occurrence?.basisOfRecord}"/>
                            <g:message code="show.heading.of" default="of"/>
                            <g:if test="${record.processed.classification.scientificName}">
                                <alatag:formatSciName rankId="${record.processed.classification.taxonRankID}" name="${record.processed.classification.scientificName}"/>
                                ${record.processed.classification.scientificNameAuthorship}
                            </g:if>
                            <g:elseif test="${record.raw.classification.scientificName}">
                                <alatag:formatSciName rankId="${record.raw.classification.taxonRankID}" name="${record.raw.classification.scientificName}"/>
                                ${record.raw.classification.scientificNameAuthorship}
                            </g:elseif>
                            <g:else>
                                <i>${record.raw.classification.genus} ${record.raw.classification.specificEpithet}</i>
                                ${record.raw.classification.scientificNameAuthorship}
                            </g:else>
                            <g:if test="${showVernacularName && record.processed.classification.vernacularName}">
                                | ${record.processed.classification.vernacularName}
                            </g:if>
                            <g:elseif test="${showVernacularName && record.raw.classification.vernacularName}">
                                | ${record.raw.classification.vernacularName}
                            </g:elseif>
                            <g:if test="${record.processed.event?.eventDate || record.raw.event?.eventDate}">
                                <g:message code="show.heading.recordedOn" default="recorded on"/> ${record.processed.event?.eventDate ?: record.raw.event?.eventDate}
                            </g:if>
                        </div>
                    </g:if>
                </div>
            </div>
            <div class="row">
                <div id="record-sidebar" class="col-md-4 scrollspy">
                    <g:render template="recordSidebar" />
                </div><!-- end div#SidebarBox -->
                <div id="" class="col-md-8">
                    <div class="text-right">
                        <alatag:linkViewOriginal url="${record.raw.occurrence.occurrenceID}" class="btn btn-default" role="button" title="Click to view the original record" target="_blank"><g:message code="show.sidebar02.viewOriginal" default="View original record"/></alatag:linkViewOriginal>
                        <button href="#processedVsRawView" class="btn btn-default" id="showRawProcessed" role="button" data-toggle="modal"
                                title="Table showing both original and processed record values">
                            <span id="processedVsRawViewSpan" href="#processedVsRawView" title=""><i class="glyphicon glyphicon-transfer"></i>
                                <g:message code="show.sidebar02.showrawprocessed.span" default="View original vs processed values"/></span>
                        </button>
                        <input id="hidden-uuid" type="hidden" value="${uuid}">
                        <span id="copyRecordIdToClipboard-parent" data-toggle="tooltip" data-trigger="manual" data-title="${uuid} copied!">
                            <button class="btn btn-default" id="copyRecordIdToClipboard" role="button" title="Copy this record's id to the clipboard"><g:message code="show.sidebar02.copyrecordid" default="Copy record id" /></button>
                        </span>
                        <a href="#CopyLink" data-toggle="modal" role="button" class="tooltips btn btn-default copyLink"
                            data-placement="bottom" title="${g.message(code:"show.copylinks.dlg.copybutton.title")}"><i class="fa fa-file-code-o" aria-hidden="true"></i>&nbsp;&nbsp;
                            <g:message code="list.copylinks" default="API"/></a>
                        <div id="CopyLink" class="modal fade" role="dialog" tabindex="-1">
                            <div class="modal-dialog" role="document">
                                <div class="modal-content">
                                    <div class="modal-header text-left">
                                        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                                        <h3><g:message code="list.copylinks.dlg.title" default="JSON web service API"/></h3>
                                    </div>
                                    <div class="modal-body">
                                        <div>&nbsp;</div>
                                        <div>&nbsp;</div>
                                        <div class="col-sm-12 input-group">
                                            <g:set var="jsonurl" value="${alatag.getBiocacheAjaxUrl()}/occurrences/${uuid}"/>
                                            <input type="text" class="form-control" value=${jsonurl} id="al4rcode" readonly/>
                                            <span class="input-group-btn">
                                                <button class="form-control btn btn-default tooltips" id="copy-al4r" data-toggle="tooltip" data-placement="bottom" title="${g.message(code:'list.copylinks.tooltip.copytoclipboard')}">
                                                    <alatag:message code="list.copylinks.dlg.copybutton.text" default="Copy URL"/>
                                                </button>
                                            </span>
                                        </div>
                                        <div>&nbsp;</div>
                                        <div>&nbsp;</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <g:render template="recordCore" />
                </div><!-- end of div#content2 -->
            </div>

            <g:if test="${hasExpertDistribution}">
                <div id="hasExpertDistribution"  class="additionalData" style="clear:both;padding-top: 20px;">
                    <h3><g:message code="show.hasexpertdistribution.title" default="Record outside of expert distribution area (shown in red)"/> <a id="expertReport" href="#expertReport">&nbsp;</a></h3>
                    <asset:javascript src="wms2.js" />
                    <asset:script type="text/javascript">
                        $(document).ready(function() {
                            var latlng1 = new google.maps.LatLng(${latLngStr});
                            var mapOptions = {
                                zoom: 4,
                                center: latlng1,
                                scrollwheel: false,
                                scaleControl: true,
                                streetViewControl: false,
                                mapTypeControl: true,
                                mapTypeControlOptions: {
                                    style: google.maps.MapTypeControlStyle.DROPDOWN_MENU,
                                    mapTypeIds: [google.maps.MapTypeId.ROADMAP, google.maps.MapTypeId.HYBRID, google.maps.MapTypeId.TERRAIN ]
                                },
                                mapTypeId: google.maps.MapTypeId.ROADMAP
                            };

                            var distroMap = new google.maps.Map(document.getElementById("expertDistroMap"), mapOptions);

                            var marker1 = new google.maps.Marker({
                                position: latlng1,
                                map: distroMap,
                                title:"Occurrence Location"
                            });

                            // Attempt to display expert distribution layer on map
                            var SpatialUrl = "${spatialPortalUrl}ws/distribution/lsid/${record.processed.classification.taxonConceptID}?callback=?";
                            $.getJSON(SpatialUrl, function(data) {

                                if (data.wmsurl) {
                                    var urlParts = data.wmsurl.split("?");

                                    if (urlParts.length == 2) {
                                        var baseUrl = urlParts[0] + "?";
                                        var paramParts = urlParts[1].split("&");
                                        loadWMS(distroMap, baseUrl, paramParts);
                                        // adjust bounds for both Aust (centre) and marker
                                        var AusCentre = new google.maps.LatLng(-27, 133);
                                        var dataBounds = new google.maps.LatLngBounds();
                                        dataBounds.extend(AusCentre);
                                        dataBounds.extend(latlng1);
                                        distroMap.fitBounds(dataBounds);
                                    }

                                }
                            });

                            <g:if test="${record.processed.location.coordinateUncertaintyInMeters}">
                                var radius1 = parseInt('${record.processed.location.coordinateUncertaintyInMeters}');

                                if (!isNaN(radius1)) {
                                    // Add a Circle overlay to the map.
                                    circle1 = new google.maps.Circle({
                                        map: distroMap,
                                        radius: radius1, // 3000 km
                                        strokeWeight: 1,
                                        strokeColor: 'white',
                                        strokeOpacity: 0.5,
                                        fillColor: '#2C48A6',
                                        fillOpacity: 0.2
                                    });
                                    // bind circle to marker
                                    circle1.bindTo('center', marker1, 'position');
                                }
                            </g:if>
                        });
                    </asset:script>
                    <div id="expertDistroMap" style="width:80%;height:400px;margin:20px 20px 10px 0;"></div>
                </div>
            </g:if>
            <div class="row">
                <div class="col-md-8 col-md-offset-4">
                    <div id="userAnnotationsDiv" class="additionalData">
                        <h3><g:message code="show.userannotationsdiv.title" default="User flagged issues"/><a id="userAnnotations">&nbsp;</a></h3>
                        <ul id="userAnnotationsList"></ul>
                    </div>

                    <g:if test="${referencedPublications}">
                    <div id="referencedPublications" class="additionalData">
                        <h3>Referenced in publications</h3>
                        <g:each in="${referencedPublications}" var="publication">
                            <div class="well well-sm">
                                <h4>Publication: <g:link url="${collectionsWebappContext}/public/show/${publication.annotation['dataResourceUid']}"> ${publication.name}</g:link></h4>
                                <p class="samp"><span class="badge">DOI</span> ${publication['@id']}</p>
                                <p>${publication.description}</p>
                                <h5 style="margin-top:25px;">Version of the data used in the publication</h5>
                                <table class="table">
                                    <g:if test="${publication.annotation['scientificName']}"><tr><td>Scientific name</td><td>${publication.annotation['scientificName']}</td></tr></g:if>
                                    <g:if test="${publication.annotation['decimalLatitude']}"><tr><td>Decimal latitude</td><td>${publication.annotation['decimalLatitude']}</td></tr></g:if>
                                    <g:if test="${publication.annotation['decimalLongitude']}"><tr><td>Decimal longitude</td><td>${publication.annotation['decimalLongitude']}</td></tr></g:if>
                                    <g:if test="${publication.annotation['year']}"><tr><td>Year</td><td>${publication.annotation['year']}</td></tr></g:if>
                                    <g:if test="${publication.annotation['month']}"><tr><td>Month</td><td>${publication.annotation['month']}</td></tr></g:if>
                                    <g:if test="${publication.annotation['occurrenceRemarks']}"><tr><td>Occurrence remarks</td><td>${publication.annotation['occurrenceRemarks']}</td></tr></g:if>
                                </table>
                               <g:if test="${publication.annotation['dataResourceUid']}">
                                <p class="samp pull right">
                                    <g:link controller="occurrence" action="search" params="${['q': 'annotationsUid:' + publication.annotation['dataResourceUid']]}">View all data referenced by this publication</g:link>
                                </p>
                               </g:if>
                            </div>
                        </g:each>
                    </div>
                    </g:if>

                    <div id="dataQuality" class="additionalData"><a name="dataQualityReport"></a>
                        <h3><g:message code="show.dataquality.title" default="Data quality tests"/></h3>
                        <div id="dataQualityModal" class="modal hide fade" tabindex="-1" role="dialog">
                            <div class="modal-header">
                                <button type="button" class="close" data-dismiss="modal">×</button>
                                <h3><g:message code="show.dataqualitymodal.title" default="Data Quality Details"/></h3>
                            </div>
                            <div class="modal-body">
                                <p><g:message code="show.dataqualitymodal.body" default="loading"/>...</p>
                            </div>
                            <div class="modal-footer">
                                <button class="btn btn-default" data-dismiss="modal"><g:message code="show.dataqualitymodal.button" default="Close"/></button>
                            </div>
                        </div>
                        <table class="dataQualityResults table table-striped table-bordered table-condensed">
                            <%--<caption>Details of tests that have been performed for this record.</caption>--%>
                            <thead>
                            <tr class="sectionName">
                                <td class="dataQualityTestName"><g:message code="show.tabledataqualityresultscol01.title" default="Test name"/></td>
                                <td class="dataQualityTestResult"><g:message code="show.tabledataqualityresultscol02.title" default="Result"/></td>
                                <%--<th class="dataQualityMoreInfo">More information</th>--%>
                            </tr>
                            </thead>
                            <tbody>
                            <g:set var="testSet" value="${record.systemAssertions.failed}"/>
                            <g:each in="${testSet}" var="test">
                                <tr>
                                    <td><g:message code="${test.name}" default="${test.name}"/><alatag:dataQualityHelp code="${test.code}"/></td>
                                    <td><i class="fa fa-times-circle" style="color:red;"></i> <g:message code="show.tabledataqualityresults.tr01td02" default="Failed"/></td>
                                    <%--<td>More info</td>--%>
                                </tr>
                            </g:each>

                            <g:set var="testSet" value="${record.systemAssertions.warning}"/>
                            <g:each in="${testSet}" var="test">
                                <tr>
                                    <td><g:message code="${test.name}" default="${test.name}"/><alatag:dataQualityHelp code="${test.code}"/></td>
                                    <td><i class="fa fa-exclamation-circle" style="color:orange;"></i> <g:message code="show.tabledataqualityresults.tr02td02" default="Warning"/></td>
                                    <%--<td>More info</td>--%>
                                </tr>
                            </g:each>

                            <g:if test="${record.systemAssertions.passed}">
                                <tr>
                                    <td colspan="2">
                                        <a href="javascript:void(0)" id="showPassedPropResult"><g:message code="show.tabledataqualityresults.tr04td02" default="Show/Hide"/>  ${record.systemAssertions.passed.length()} passed properties</a>
                                    </td>
                                </tr>
                            </g:if>
                            <g:set var="testSet" value="${record.systemAssertions.passed}"/>
                            <g:each in="${testSet}" var="test">
                                <tr class="passedPropResult" style="display:none;">
                                    <td><g:message code="${test.name}" default="${test.name}"/><alatag:dataQualityHelp code="${test.code}"/></td>
                                    <td><i class="fa fa-check-circle" style="color:green;"></i> <g:message code="show.tabledataqualityresults.tr03td02" default="Passed"/></td>
                                    <%--<td>More info</td>--%>
                                </tr>
                            </g:each>

                            <g:if test="${record.systemAssertions.missing}">
                                <tr>
                                    <td colspan="2">
                                        <a href="javascript:void(0)" id="showMissingPropResult"><g:message code="show.tabledataqualityresults.tr04td02" default="Show/Hide"/>  ${record.systemAssertions.missing.length()} missing properties</a>
                                    </td>
                                </tr>
                            </g:if>
                            <g:set var="testSet" value="${record.systemAssertions.missing}"/>
                            <g:each in="${testSet}" var="test">
                                <tr class="missingPropResult" style="display:none;">
                                    <td><g:message code="${test.name}" default="${test.name}"/><alatag:dataQualityHelp code="${test.code}"/></td>
                                    <td><i class="fa fa-question-circle"></i> <g:message code="show.tabledataqualityresults.tr05td02" default="Missing"/></td>
                                </tr>
                            </g:each>

                            <g:if test="${record.systemAssertions.unchecked}">
                                <tr>
                                    <td colspan="2">
                                        <a href="javascript:void(0)" id="showUncheckedTests"><g:message code="show.tabledataqualityresults.tr06td02" default="Show/Hide"/>  ${record.systemAssertions.unchecked.length()} tests that have not been run</a>
                                    </td>
                                </tr>
                            </g:if>
                            <g:set var="testSet" value="${record.systemAssertions.unchecked}"/>
                            <g:each in="${testSet}" var="test">
                                <tr class="uncheckTestResult" style="display:none;">
                                    <td><g:message code="${test.name}" default="${test.name}"/><alatag:dataQualityHelp code="${test.code}"/></td>
                                    <td><i class="fa fa-ban"></i> <g:message code="show.tabledataqualityresults.tr07td02" default="Unchecked (lack of data)"/></td>
                                </tr>
                            </g:each>

                            </tbody>
                        </table>
                    </div>

                    <div id="outlierFeedback">
                        <g:if test="${record.processed.occurrence.outlierForLayers}">
                            <div id="outlierInformation" class="additionalData">
                                <h3><g:message code="show.outlierinformation.title" default="Outlier information"/> <a id="outlierReport" href="#outlierReport">&nbsp;</a></h3>
                                <p>
                                    <g:message code="show.outlierinformation.p01" default="This record has been detected as an outlier using the"/>
                                    <a href="https://github.com/AtlasOfLivingAustralia/ala-dataquality/wiki/DETECTED_OUTLIER_JACKKNIFE"><g:message code="show.outlierinformation.p.vavigator" default="Reverse Jackknife algorithm"/></a>
                                    <g:message code="show.outlierinformation.p02" default="for the following layers"/>:</p>
                                <ul>
                                    <g:each in="${metadataForOutlierLayers}" var="layerMetadata">
                                        <li>
                                            <a href="${grailsApplication.config.getProperty('layersservice.baseUrl')}/layers/view/more/${layerMetadata.name}">${layerMetadata.displayname} - ${layerMetadata.source}</a><br/>
                                            <g:message code="show.outlierinformation.each.label01" default="Notes"/>: ${layerMetadata.notes}<br/>
                                            <g:message code="show.outlierinformation.each.label02" default="Scale"/>: ${layerMetadata.scale}
                                        </li>
                                    </g:each>
                                </ul>

                                <p style="margin-top:20px;"><g:message code="show.outlierinformation.p.label" default="More information on the data quality work being undertaken by the Atlas is available here"/>:
                                <ul>
                                    <li><a href="https://github.com/AtlasOfLivingAustralia/ala-dataquality/wiki/DETECTED_OUTLIER_JACKKNIFE">https://github.com/AtlasOfLivingAustralia/ala-dataquality/wiki/DETECTED_OUTLIER_JACKKNIFE</a></li>
                                    <li><a href="https://docs.google.com/open?id=0B7rqu1P0r1N0NGVhZmVhMjItZmZmOS00YmJjLWJjZGQtY2Y0ZjczZmUzZTZl"><g:message code="show.outlierinformation.p.li02" default="Notes on Methods for Detecting Spatial Outliers"/></a></li>
                                </ul>
                                </p>
                            </div>
                            <div id="charts" style="margin-top:20px;"></div>
                            <script type="text/javascript" >
                                function renderOutlierCharts(data){
                                    var chartQuery = null;

                                    if (OCC_REC.taxonRank  == 'species') {
                                        chartQuery = 'species_guid:' + OCC_REC.taxonConceptID.replace(/:/,'\:');
                                    } else if (OCC_REC.taxonRank  == 'subspecies') {
                                        chartQuery = 'species_guid:' + OCC_REC.taxonConceptID.replace(/:/,'\:');
                                    }

                                    if(chartQuery != null){
                                        $.each(data, function() {
                                            drawChart(this.layerId, chartQuery, this.layerId, this.outlierValues, this.recordLayerValue, false);
                                            drawChart(this.layerId, chartQuery, this.layerId, this.outlierValues, this.recordLayerValue, true);
                                        })
                                    }
                                }

                                function drawChart(facetName, biocacheQuery, chartName, outlierValues, valueForThisRecord, cumulative){

                                    var facetChartOptions = { error: "badQuery", legend: 'right'}
                                    facetChartOptions.query = biocacheQuery;
                                    facetChartOptions.charts = [chartName];
                                    facetChartOptions.width = "65%";
                                    facetChartOptions.chartsDiv = "charts";
                                    facetChartOptions[facetName] = {chartType: 'scatter'};
                                    facetChartOptions.biocacheServicesUrl = "${alatag.getBiocacheAjaxUrl()}";
                                    facetChartOptions.displayRecordsUrl = "${grailsApplication.config.getProperty('grails.serverURL')}";

                                    //additional config
                                    facetChartOptions.cumulative = cumulative;
                                    facetChartOptions.outlierValues = outlierValues;    //retrieved from WS
                                    facetChartOptions.highlightedValue = valueForThisRecord;           //retrieved from the record

                                    //console.log('Start the drawing...' + chartName;
                                    facetChartGroup.loadAndDrawFacetCharts(facetChartOptions);
                                    //console.log('Finished the drawing...' + chartName);
                                }

                                function handleOutlierError(jqXHR, textStatus) {
                                    var message = "[ <g:message code="show.outlierChart.errorMessage" default="Outlier charts cannot be displayed"/> -- " + textStatus + " (<g:message code="show.outlierChart.errorCode" default="status code"/>: " + jqXHR.status + ") ]";
                                    $('#charts').html(message);
                                }

                                $.getJSON("${biocacheService}/outlier/record/${uuid}.json", renderOutlierCharts).fail(handleOutlierError);

                            </script>
                        </g:if>

                        <g:if test="${record.processed.occurrence.duplicationStatus}">
                            <div id="inferredOccurrenceDetails">
                                <a href="#inferredOccurrenceDetails" name="inferredOccurrenceDetails" id="inferredOccurrenceDetails" hidden="true"></a>
                                <h3><g:message code="show.inferredoccurrencedetails.title" default="Inferred associated occurrence details"/></h3>
                            <p style="margin-top:5px;">
                                <g:if test="${record.processed.occurrence.duplicationStatus == 'R' }">
                                    <g:message code="show.inferredoccurrencedetails.p01" default="This record has been identified as the representative occurrence in a group of associated occurrences."/>
                                </g:if>
                                <g:else><g:message code="show.inferredoccurrencedetails.p02" default="This record is associated with the representative record."/>
                                </g:else>
                                <g:message code="show.inferredoccurrencedetails.p03" default="More information about the duplication detection methods and terminology in use is available here"/>:
                                <ul>
                                    <li>
                                        <a href="https://github.com/AtlasOfLivingAustralia/ala-dataquality/wiki/INFERRED_DUPLICATE_RECORD">https://github.com/AtlasOfLivingAustralia/ala-dataquality/wiki/INFERRED_DUPLICATE_RECORD</a>
                                    </li>
                                </ul>
                            </p>
                            <g:if test="${duplicateRecordDetails && duplicateRecordDetails.duplicates?.size() > 0}">
                                <table class="duplicationTable table table-striped table-bordered table-condensed" style="border-bottom:none;">
                                    <tr class="sectionName"><td colspan="4"><g:message code="show.table01.title" default="Representative Record"/></td></tr>
                                    <g:if test="${duplicateRecordDetails.uuid}">
                                        <alatag:occurrenceTableRow
                                                annotate="false"
                                                section="duplicate"
                                                fieldName="Record UUID">
                                            <a href="${request.contextPath}/occurrences/${duplicateRecordDetails.uuid}">${duplicateRecordDetails.uuid}</a></alatag:occurrenceTableRow>

                                        <alatag:occurrenceTableRow
                                                annotate="false"
                                                section="duplicate"
                                                fieldName="Data Resource">
                                            <g:set var="dr"><alatag:getDruid uuid="${duplicateRecordDetails.uuid}"/></g:set>
                                            <a href="${collectionsWebappContext}/public/show/${dr}">${dataResourceCodes?.get(dr)}</a>
                                        </alatag:occurrenceTableRow>
                                    </g:if>
                                    <g:if test="${duplicateRecordDetails.rawScientificName}">
                                        <alatag:occurrenceTableRow
                                                annotate="false"
                                                section="duplicate"
                                                fieldName="Raw Scientific Name">
                                            ${duplicateRecordDetails.rawScientificName}</alatag:occurrenceTableRow>
                                    </g:if>
                                    <g:if test="${duplicateRecordDetails.latLong}">
                                        <alatag:occurrenceTableRow
                                                annotate="false"
                                                section="duplicate"
                                                fieldName="Coordinates">
                                            ${duplicateRecordDetails.latLong}</alatag:occurrenceTableRow>
                                    </g:if>
                                    <g:if test="${duplicateRecordDetails.collector }">
                                        <alatag:occurrenceTableRow
                                                annotate="false"
                                                section="duplicate"
                                                fieldName="Collector">
                                            ${duplicateRecordDetails.collector}</alatag:occurrenceTableRow>
                                    </g:if>
                                    <g:if test="${duplicateRecordDetails.year }">
                                        <alatag:occurrenceTableRow
                                                annotate="false"
                                                section="duplicate"
                                                fieldName="Year">
                                            ${duplicateRecordDetails.year}</alatag:occurrenceTableRow>
                                    </g:if>
                                    <g:if test="${duplicateRecordDetails.month }">
                                        <alatag:occurrenceTableRow
                                                annotate="false"
                                                section="duplicate"
                                                fieldName="Month">
                                            ${duplicateRecordDetails.month}</alatag:occurrenceTableRow>
                                    </g:if>
                                    <g:if test="${duplicateRecordDetails.day }">
                                        <alatag:occurrenceTableRow
                                                annotate="false"
                                                section="duplicate"
                                                fieldName="Day">
                                            ${duplicateRecordDetails.day}</alatag:occurrenceTableRow>
                                    </g:if>
                                <!-- Loop through all the duplicate records -->
                                    <tr class="sectionName"><td colspan="4"><g:message code="show.table02.title" default="Related records"/></td></tr>
                                    <g:each in="${duplicateRecordDetails.duplicates }" var="dup">
                                        <g:if test="${dup.uuid}">
                                            <alatag:occurrenceTableRow
                                                    annotate="false"
                                                    section="duplicate"
                                                    fieldName="Record UUID">
                                                <a href="${request.contextPath}/occurrences/${dup.uuid}">${dup.uuid}</a></alatag:occurrenceTableRow>

                                            <alatag:occurrenceTableRow
                                                    annotate="false"
                                                    section="duplicate"
                                                    fieldName="Data Resource">
                                                <g:set var="dr"><alatag:getDruid uuid="${dup.uuid}"/></g:set>
                                                <a href="${collectionsWebappContext}/public/show/${dr}">${dataResourceCodes?.get(dr)}</a>
                                            </alatag:occurrenceTableRow>
                                        </g:if>
                                        <g:if test="${dup.rawScientificName}">
                                            <alatag:occurrenceTableRow
                                                    annotate="false"
                                                    section="duplicate"
                                                    fieldName="Raw Scientific Name">
                                                ${dup.rawScientificName}</alatag:occurrenceTableRow>
                                        </g:if>
                                        <g:if test="${dup.latLong}">
                                            <alatag:occurrenceTableRow
                                                    annotate="false"
                                                    section="duplicate"
                                                    fieldName="Coordinates">
                                                ${dup.latLong}</alatag:occurrenceTableRow>
                                        </g:if>
                                        <g:if test="${dup.collector }">
                                            <alatag:occurrenceTableRow
                                                    annotate="false"
                                                    section="duplicate"
                                                    fieldName="Collector">
                                                ${dup.collector}</alatag:occurrenceTableRow>
                                        </g:if>
                                        <g:if test="${dup.year }">
                                            <alatag:occurrenceTableRow
                                                    annotate="false"
                                                    section="duplicate"
                                                    fieldName="Year">
                                                ${dup.year}</alatag:occurrenceTableRow>
                                        </g:if>
                                        <g:if test="${dup.month }">
                                            <alatag:occurrenceTableRow
                                                    annotate="false"
                                                    section="duplicate"
                                                    fieldName="Month">
                                                ${dup.month}</alatag:occurrenceTableRow>
                                        </g:if>
                                        <g:if test="${dup.day }">
                                            <alatag:occurrenceTableRow
                                                    annotate="false"
                                                    section="duplicate"
                                                    fieldName="Day">
                                                ${dup.day}</alatag:occurrenceTableRow>
                                        </g:if>
                                        <g:if test="${dup.dupTypes }">
                                            <alatag:occurrenceTableRow
                                                    annotate="false"
                                                    section="duplicate"
                                                    fieldName="Comments">
                                                <g:each in="${dup.dupTypes }" var="dupType">
                                                    <g:if test="${dupType.id }">
                                                        <g:message code="duplication.${dupType.id}"/>
                                                        <br>
                                                    </g:if>
                                                </g:each>
                                            </alatag:occurrenceTableRow>
                                            <tr class="sectionName"><td colspan="4"></td></tr>
                                        </g:if>
                                    </g:each>
                                </table>
                            </g:if>
                            </p>
                        </g:if>
                    </div>

                        <div id="outlierInformation" class="additionalData">
                            <g:if test="${contextualSampleInfo}">
                                <h3 id="contextualSampleInfo"><g:message code="show.outlierinformation.02.title01" default="Additional geographic & environmental information"/></h3>
                                <table class="layerIntersections table table-striped table-bordered table-condensed">
                                    <tbody>
                                    <g:each in="${contextualSampleInfo}" var="sample" status="vs">
                                        <g:if test="${sample.classification1 && (vs == 0 || (sample.classification1 != contextualSampleInfo.get(vs - 1).classification1 && vs != contextualSampleInfo.size() - 1))}">
                                            <tr class="sectionName"><td colspan="2">${sample.classification1}</td></tr>
                                        </g:if>
                                        <g:set var="fn"><a href='${grailsApplication.config.getProperty('layersservice.baseUrl')}/layers/view/more/${sample.layerName}' title='more information about this layer'>${sample.layerDisplayName}</a></g:set>
                                        <alatag:occurrenceTableRow
                                                annotate="false"
                                                section="contextual"
                                                fieldCode="${sample.layerName}"
                                                fieldName="${fn}">
                                            ${sample.value}</alatag:occurrenceTableRow>
                                    </g:each>
                                    </tbody>
                                </table>
                            </g:if>

                            <g:if test="${environmentalSampleInfo}">
                                <h3 id="environmentalSampleInfo"><g:message code="show.outlierinformation.02.title02" default="Environmental sampling for this location"/></h3>
                                <table class="layerIntersections table table-striped table-bordered table-condensed" >
                                    <tbody>
                                    <g:each in="${environmentalSampleInfo}" var="sample" status="vs">
                                        <g:if test="${sample.classification1 && (vs == 0 || (sample.classification1 != environmentalSampleInfo.get(vs - 1).classification1 && vs != environmentalSampleInfo.size() - 1))}">
                                            <tr class="sectionName"><td colspan="2">${sample.classification1}</td></tr>
                                        </g:if>
                                        <g:set var="fn"><a href='${grailsApplication.config.getProperty('layersservice.url')}/layers/view/more/${sample.layerName}' title='More information about this layer'>${sample.layerDisplayName}</a></g:set>
                                        <alatag:occurrenceTableRow
                                                annotate="false"
                                                section="contextual"
                                                fieldCode="${sample.layerName}"
                                                fieldName="${fn}">
                                            ${sample.value} ${(sample.units && !StringUtils.containsIgnoreCase(sample.units,'dimensionless')) ? sample.units : ''}
                                        </alatag:occurrenceTableRow>
                                    </g:each>
                                    </tbody>
                                </table>
                            </g:if>
                        </div>
                    </div>
                </div><!-- /.col-md-8 .col-md-offset-4 -->
            </div><!-- /.row -->


            <!-- BS modal div -->
            <div id="processedVsRawView" class="modal fade " tabindex="-1" role="dialog" aria-labelledby="processedVsRawViewLabel">
                <div class="modal-dialog modal-lg" role="document">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                            <h3 id="processedVsRawViewLabel"><g:message code="show.processedvsrawview.title" default="&quot;Original versus Processed&quot; Comparison Table"/></h3>
                        </div>
                        <div class="modal-body">
                            <table class="table table-bordered table-striped table-condensed">
                                <thead>
                                <tr>
                                    <th style="width:15%;"><g:message code="show.processedvsrawview.table.th01" default="Group"/></th>
                                    <th style="width:15%;"><g:message code="show.processedvsrawview.table.th02" default="Field Name"/></th>
                                    <th style="width:35%;"><g:message code="show.processedvsrawview.table.th03" default="Original Value"/></th>
                                    <th style="width:35%;"><g:message code="show.processedvsrawview.table.th04" default="Processed Value"/></th>
                                </tr>
                                </thead>
                            </table>
                            <table class="table table-bordered table-striped table-condensed"
                                   style="max-height: calc(100vh - 300px);overflow: auto;display: block;">
                                <thead style="visibility: collapse;">
                                <tr>
                                    <th style="width:15%; padding: 0px;"></th>
                                    <th style="width:15%; padding: 0px;"></th>
                                    <th style="width:35%; padding: 0px;"></th>
                                    <th style="width:35%; padding: 0px;"></th>
                                </tr>
                                </thead>
                                <tbody >
                                    <alatag:formatRawVsProcessed map="${compareRecord}"/>
                                </tbody>
                            </table>
                        </div>
                        <div class="modal-footer">
                            <button class="btn btn-default btn-small" data-dismiss="modal" aria-hidden="true"><g:message code="show.processedvsrawview.button.close" default="Close"/></button>
                        </div>
                    </div>
                </div>
            </div>
        </g:if>

        <g:if test="${contacts}">
            <!-- BS modal div -->
            <div id="contactCuratorView" class="modal fade " tabindex="-1" role="dialog" aria-labelledby="contactCuratorViewLabel">
                <div class="modal-dialog" role="document">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                            <h3 id="contactCuratorViewLabel"><g:message code="show.contactcuratorview.title" default="Contact curator"/></h3>
                        </div>
                        <div class="modal-body">
                            <p><g:message code="show.contactcuratorview.message" default="For more details and to report issues about this record, please contact a person mentioned below."></g:message> </p>
                            <g:each in="${contacts}" var="c">
                                <address>
                                    <strong>${c.contact.firstName} ${c.contact.lastName} <g:if test="${c.primaryContact}"><span class="primaryContact">*</span></g:if> </strong>
                                    <g:if test="${c.role}"><br>${c.role}<br></g:if>
                                    <g:if test="${c.contact.phone}"><abbr title="Phone">P:</abbr> ${c.contact.phone} <br></g:if>
                                    <g:if test="${c.contact.email}"><abbr title="Email">E:</abbr> <alatag:emailLink email="${c.contact.email}"><g:message code="show.contactcuratorview.emailtext" default="email this contact"></g:message> </alatag:emailLink> <br></g:if>
                                </address>
                            </g:each>
                            <p><span class="primaryContact"><b>*</b></span> <g:message code="show.contactcuratorview.primarycontact" default="Primary Contact"></g:message> </p>
                        </div>
                        <div class="modal-footer">
                            <button class="btn btn-default btn-small" data-dismiss="modal" aria-hidden="true" style="float:right;"><g:message code="show.processedvsrawview.button.close" default="Close"/></button>
                        </div>
                    </div>
                </div>
            </div>
        </g:if>

        <ul style="display:none;">
            <li id="userAnnotationTemplate" class="userAnnotationTemplate well well-sm">
                <h4><span class="issue i8nupdate"></span> - <g:message code="show.userannotationtemplate.title" default="flagged by"/> <span class="user"></span><span class="userRole"></span><span class="userEntity"></span></h4>
                <p class="related-record-reason" style="display:none;"><g:message code="show.userannotationtemplate.relatedrecord.reason.label" default="Reason:"/> <span class="related-record-reason-span i8nupdate"></span></p>
                <p class="related-record" style="display:none;">
                    <p class="related-record-reason-explanation i8nupdate" style="display:none;"></p>
                    <p class="related-record-id" style="display:none;">&nbsp;&nbsp;&nbsp;&nbsp;<g:message code="related.record.id.label" default="record ID"/>: <span class="related-record-id-span"></span></p>
                    <p class="related-record-name" style="display:none;">&nbsp;&nbsp;&nbsp;&nbsp;<g:message code="related.record.name.label" default="scientific name"/>: <span class="related-record-name-span"></span></p>
                    <p class="related-record-state" style="display:none;">&nbsp;&nbsp;&nbsp;&nbsp;<g:message code="related.record.state.label" default="state"/>: <span class="related-record-state-span"></span></p>
                    <p class="related-record-latitude" style="display:none;">&nbsp;&nbsp;&nbsp;&nbsp;<g:message code="related.record.latitude.label" default="latitude"/>: <span class="related-record-latitude-span"></span></p>
                    <p class="related-record-longitude" style="display:none;">&nbsp;&nbsp;&nbsp;&nbsp;<g:message code="related.record.longitude.label" default="longitude"/>: <span class="related-record-longitude-span"></span></p>
                    <p class="related-record-eventdate" style="display:none;">&nbsp;&nbsp;&nbsp;&nbsp;<g:message code="related.record.eventdate.label" default="eventDate"/>: <span class="related-record-eventdate-span"></span></p>
                    <g:link class="related-record-link" controller="occurrence" action="show" id="replace-me" target="_blank">
                        <span class="related-record-span-user-duplicate" style="display:none;">
                            <g:message code="show.userannotationtemplate.relatedrecord.userduplicate.a" default="View duplicated record"/>
                        </span>
                        <span class="related-record-span-default" style="display:none;">
                            <g:message code="show.userannotationtemplate.relatedrecord.default.a" default="View related record"/>
                        </span>
                    </g:link>
                </p>
                <p class="comment"></p>
                <p class="hide issueCode"></p>
                <p class="hide issueComment"></p>
                <p class="hide userDisplayName"></p>
                <p class="created small"></p>
                <p class="viewMore" style="display:none;">
                   <a class="viewMoreLink" href="#"><g:message code="show.userannotationtemplate.p01.navigator" default="View more with this annotation"/></a>
                </p>
                <p class="deleteAnnotation" style="display:block;">
                    <a class="editAnnotationButton btn btn-danger" href="#">
                        <g:message code="show.userannotationtemplate.p05.navigator" default="Edit"/>
                        <span class="editAssertionSubmitProgress" style="display:none;">
                            <asset:image src="indicator.gif" alt="indicator icon"/>
                        </span>
                    </a>
                    <a class="deleteAnnotationButton btn btn-danger" href="#">
                        <g:message code="show.userannotationtemplate.p02.navigator" default="Delete this annotation"/>
                        <span class="deleteAssertionSubmitProgress" style="display:none;">
                            <asset:image src="indicator.gif" alt="indicator icon"/>
                        </span>
                    </a>
                </p>
                <g:if test="${isCollectionAdmin}">
                    <p class="verifyAnnotation" style="display:none;">
                        <a class="verifyAnnotationButton btn btn-default"  href="#verifyRecordModal" data-toggle="modal">
                            <i class="glyphicon glyphicon-thumbs-up"> </i> &nbsp;
                            <g:message code="show.userannotationtemplate.p03.navigator" default="Verify this annotation"/></a>
                    </p>
                </g:if>

                <!-- verifications for this annotation -->
                <table class="table verifications">
                    <thead>
                        <tr>
                            <th>Verification status</th>
                            <th>Comment</th>
                            <th>Verified&nbsp;by</th>
                            <th>Created</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
                    </tbody>
                </table>
            </li>
        </ul>

        <!-- template to add a row -->
        <table class="hide">
            <tr id="userVerificationTemplate" class="userVerificationTemplate">
                <td class="qaStatus i8nupdate"></td>
                <td class="comment"></td>
                <td class="userDisplayName"></td>
                <td class="created"></td>
                <td class="deleteVerification">
                    <g:if test="${isCollectionAdmin}">
                        <a class="editVerificationButton btn btn-danger" style="text-align: right" href="#">
                            <g:message code="show.userannotationtemplate.p06.navigator" default="Edit"/>
                        </a>
                        <a class="deleteVerificationButton btn btn-danger" style="text-align: right" href="#">
                            <g:message code="show.userannotationtemplate.p04.navigator" default="Delete this verification"/>
                        </a>
                    </g:if>
                </td>
            </tr>
        </table>

        <div id="verifyRecordModal" class="modal fade in" data-keyboard="false"  role="dialog" aria-labelledby="verifyRecordLabel" aria-hidden="true">
            <div class="modal-dialog modal-lg" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h3><g:message code="show.verifyrecord.title" default="Confirmation"/></h3>
                    </div>
                    <div class="modal-body">
                        <div class="verifyAsk">
                            <g:set var="markedAssertions"/>
                            <g:if test="!record.processed.geospatiallyKosher">
                                <g:set var="markedAssertions"><g:message code="show.verifyask.set01" default="geospatially suspect"/></g:set>
                            </g:if>
                            <g:if test="!record.processed.taxonomicallyKosher">
                                <g:set var="markedAssertions">${markedAssertions}${markedAssertions ? ", " : ""}<g:message code="show.verifyask.set02" default="taxonomically suspect"/></g:set>
                            </g:if>
                            <g:each var="sysAss" in="${record.systemAssertions.failed}">
                                <g:set var="markedAssertions">${markedAssertions}${markedAssertions ? ", " : ""}<g:message code="${sysAss.name}" /></g:set>
                            </g:each>
                            <p>
                                <g:message code="show.verifyrecord.p01" default="Record is marked as"/> <b>${markedAssertions}</b>
                            </p>
                            <p style="margin-bottom:10px;">
                                <g:message code="show.verifyrecord.p02" default="Click the &quot;Confirm&quot; button to verify that this record is correct and that the listed &quot;validation issues&quot; are incorrect/invalid."/>
                            </p>
                            <p style="margin-top:20px;">
                                <label for="userAssertionStatusSelection"><g:message code="show.verifyrecord.p03" default="User Assertion Status:"/></label>
                                <select name="userAssertionStatusSelection" id="userAssertionStatusSelection">
                                    <option value="50001"><alatag:message code="user_assertions.50001" default="Open issue"/></option>
                                    <option value="50002"><alatag:message code="user_assertions.50002" default="Verified"/></option>
                                    <option value="50003"><alatag:message code="user_assertions.50003" default="Corrected"/></option>
                                </select>
                            </p>
                            <p><textarea id="verifyComment" rows="3" style="width: 90%"></textarea></p><br>
                        </div>
                        <div class="verifyDone" style="display:none;">
                            <g:message code="show.verifydone.message" default="Record successfully verified"/>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <div class="verifyAsk">
                            <button id="confirmVerify" class="btn btn-primary confirmVerify"><g:message code="show.verifyrecord.btn.confirmverify" default="Confirm"/></button>
                            <button class="btn btn-default cancelVerify"  data-dismiss="modal"><g:message code="show.verifyrecord.btn.cancel" default="Cancel"/></button>
                            <img src="${assetPath(src: 'spinner.gif')}" id="verifySpinner" class="verifySpinner hide" alt="spinner icon"/>
                        </div>
                        <div class="verifyDone" style="display:none;">
                            <button class="btn btn-default closeVerify" data-dismiss="modal"><g:message code="show.verifydone.btn.closeverify" default="Close"/></button>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <g:if test="${!record.raw}">
            <div id="headingBar">
                <h1><g:message code="show.headingbar02.title" default="Record Not Found"/></h1>
                <p><g:message code="show.headingbar02.p01" default="The requested record ID"/> "${uuid}" <g:message code="show.headingbar02.p02" default="was not found"/></p>
            </div>
        </g:if>
        <g:if test="${record.sounds}">
            <asset:script type="text/javascript">
              audiojs.events.ready(function() {
                var as = audiojs.createAll();
              });
            </asset:script>
        </g:if>
    </g:if>
    <g:else>
        <h3><g:message code="show.body.error.title" default="An error occurred"/> <br/><alatag:stripApiKey message="${flash.message}"/></h3>
    </g:else>
</body>
</html>
