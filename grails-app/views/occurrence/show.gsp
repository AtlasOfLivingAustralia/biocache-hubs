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
<g:set var="bieWebappContext" value="${grailsApplication.config.bie.baseURL}"/>
<g:set var="collectionsWebappContext" value="${grailsApplication.config.collections.baseUrl}"/>
<g:set var="useAla" value="${grailsApplication.config.useAla}"/>
<g:set var="dwcExcludeFields" value="${grailsApplication.config.dwc.exclude}"/>
<g:set var="hubDisplayName" value="${grailsApplication.config.skin.orgNameLong}"/>
<g:set var="biocacheService" value="${grailsApplication.config.biocacheServicesUrl}"/>
<g:set var="spatialPortalUrl" value="${grailsApplication.config.spatial.baseURL}"/>
<g:set var="serverName" value="${grailsApplication.config.site.serverName?:grailsApplication.config.biocacheServicesUrl}"/>
<g:set var="scientificName" value="${alatag.getScientificName(record: record)}"/>
<g:set var="sensitiveDatasetRaw" value="${grailsApplication.config.sensitiveDataset?.list?:''}"/>
<g:set var="sensitiveDatasets" value="${sensitiveDatasetRaw?.split(',')}"/>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="${grailsApplication.config.ala.skin}"/>
    <title>Record: ${recordId} | <g:message code="show.occurrenceRecord" default="Occurrence record"/>  | ${hubDisplayName}</title>
    <script type="text/javascript" src="http://www.google.com/jsapi"></script>
    <script type="text/javascript">
        // Global var OCC_REC to pass GSP data to external JS file
        var OCC_REC = {
            userId: "${userId}",
            userDisplayName: "${userDisplayName}",
            contextPath: "${request.contextPath}",
            recordUuid: "${record.raw.uuid}",
            taxonRank: "${record.processed.classification.taxonRank}",
            taxonConceptID: "${record.processed.classification.taxonConceptID}",
            sensitiveDatasets: {
                <g:each var="sds" in="${sensitiveDatasets}"
                   status="s">'${sds}': '${grailsApplication.config.sensitiveDatasets[sds]}'${s < (sensitiveDatasets.size() - 1) ? ',' : ''}
                </g:each>
            }
        }

        // Google charts
        google.load('maps','3.3',{ other_params: "sensor=false" });
        google.load("visualization", "1", {packages:["corechart"]});
    </script>
    <script type="text/javascript" src="${r.resource(dir:'js', file:'charts2.js', plugin:'biocache-hubs')}"></script>

    <r:require modules="show, amplify"/>

    <r:script disposition="head">
        $(document).ready(function() {
            <g:if test="${record.processed.attribution.provenance == 'Draft'}">\
                // draft view button\
                $('#viewDraftButton').click(function(){
                    document.location.href = '${record.raw.occurrence.occurrenceID}';
                });
            </g:if>
            <g:if test="${isCollectionAdmin}">
                $(".confirmVerifyCheck").click(function(e) {
                    $("#verifyAsk").hide();
                    $("#verifyDone").show();
                });
                $(".cancelVerify").click(function(e) {
                    //$.fancybox.close(); // TODO fix
                });
                $(".closeVerify").click(function(e) {
                    //$.fancybox.close(); // TODO fix
                });
                $(".confirmVerify").click(function(e) {
                    $("#verifySpinner").show();
                    var code = "50000";
                    var userDisplayName = '${userDisplayName}';
                    var recordUuid = '${record.raw.rowKey.encodeAsURL()}';
                    var comment = $("#verifyComment").val();
                    if (!comment) {
                        alert("Please add a comment");
                        $("#verifyComment").focus();
                        $("#verifySpinner").hide();
                        return false;
                    }
                    // send assertion via AJAX... TODO catch errors
                    $.post("${pageContext.request.contextPath}/occurrences/assertions/add",
                            { recordUuid: recordUuid, code: code, comment: comment, userId: OCC_REC.userId, userDisplayName: userDisplayName},
                            function(data) {
                                // service simply returns status or OK or FORBIDDEN, so assume it worked...
                                $("#verifyAsk").fadeOut();
                                $("#verifyDone").fadeIn();
                            }
                    ).error(function (request, status, error) {
                                alert("Error verifying record: " + request.responseText);
                            }).complete(function() {
                                $("#verifySpinner").hide();
                            });
                });
            </g:if>
        }); // end $(document).ready()

        function renderOutlierCharts(data){
            var chartQuery = null;

            if (OCC_REC.taxonRank  == 'species') {
                chartQuery = 'species_guid:' + OCC_REC.taxonConceptID.replace(/:/,'\:');
            } else if (OCC_REC.taxonRank  == 'subspecies') {
                chartQuery = 'species_guid:' + OCC_REC.taxonConceptID.replace(/:/,'\:');
            }

            if(chartQuery != null){
                $.each(data, function() {
                    drawChart(this.layerId, chartQuery, this.layerId+'Outliers', this.outlierValues, this.recordLayerValue, false);
                    drawChart(this.layerId, chartQuery, this.layerId+'OutliersCumm', this.outlierValues, this.recordLayerValue, true);
                })
            }
        }

        function drawChart(facetName, biocacheQuery, chartName, outlierValues, valueForThisRecord, cumulative){

            var facetChartOptions = { error: "badQuery", legend: 'right'}
            facetChartOptions.query = biocacheQuery;
            facetChartOptions.charts = [chartName];
            facetChartOptions.backgroundColor = '#FFFEF7';
            facetChartOptions.width = "75%";
            facetChartOptions[facetName] = {chartType: 'scatter'};


            //additional config
            facetChartOptions.cumulative = cumulative;
            facetChartOptions.outlierValues = outlierValues;    //retrieved from WS
            facetChartOptions.highlightedValue = valueForThisRecord;           //retrieved from the record

            //console.log('Start the drawing...' + chartName);
            facetChartGroup.loadAndDrawFacetCharts(facetChartOptions);
            //console.log('Finished the drawing...' + chartName);
        }
    </r:script>

</head>
<body>
    %{--<g:set var="json" value="${request.contextPath}/occurrences/${record?.raw?.uuid}.json" />--}%
    <g:if test="${record}">
        <g:if test="${record.raw}">
            <div id="headingBar" class="recordHeader">
                <h1><g:message code="show.occurrenceRecord" default="Occurrence record"/>: <span id="recordId">${recordId}</span></h1>
                <g:if test="${skin != 'avh'}">
                    <div id="jsonLink">
                        <g:if test="${isCollectionAdmin}">
                            <g:set var="admin" value=" - admin"/>
                        </g:if>
                        <g:if test="${userDisplayName}">
                            Logged in as: ${userDisplayName}
                        </g:if>
                        <g:if test="${clubView}">
                            <div id="clubView">Showing &quot;Club View&quot;</div>
                        </g:if>
                        <!-- <a href="${json}">JSON</a> -->
                    </div>
                </g:if>
                %{--<g:if test="${lastSearchUri}">--}%
                    <div id="backBtn" class="hide pull-right">
                        <a href="${lastSearchUri}" title="Return to search results" class="btn">Back to search results</a>
                    </div>
                %{--</g:if>--}%
                <g:if test="${record.raw.classification}">
                    <h2 id="headingSciName">
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
                        <g:if test="${record.processed.classification.vernacularName}">
                            | ${record.processed.classification.vernacularName}
                        </g:if>
                        <g:elseif test="${record.raw.classification.vernacularName}">
                            | ${record.raw.classification.vernacularName}
                        </g:elseif>
                    </h2>
                </g:if>
            </div>
            <div class="row-fluid">
                <div id="SidebarBoxZ" class="span4">
                <g:if test="${collectionLogo}">
                    <div class="sidebar">
                        <img src="${collectionLogo}" alt="institution logo" id="institutionLogo"/>
                    </div>
                </g:if>

                <g:if test="${record.processed.attribution.provenance != 'Draft'}">
                    <div class="sidebar">
                        <div id="warnings">

                            <div id="systemAssertionsContainer" <g:if test="${!record.systemAssertions}">style="display:none"</g:if>>
                                <h3>Data quality tests</h3>

                                <ul id="systemAssertions">
                                    <li class="failedTestCount">
                                        <g:message code="failed" default="failed"/>: ${record.systemAssertions.failed?.size()?:0}
                                    </li>
                                    <li class="warningsTestCount">
                                        <g:message code="warnings" default="warnings"/>: ${record.systemAssertions.warning?.size()?:0}
                                    </li>
                                    <li class="passedTestCount">
                                        <g:message code="passed" default="passed"/>: ${record.systemAssertions.passed?.size()?:0}
                                    </li>
                                    <li class="missingTestCount">
                                        <g:message code="missing" default="missing"/>: ${record.systemAssertions.missing?.size()?:0}
                                    </li>
                                    <li class="uncheckedTestCount">
                                        <g:message code="unchecked" default="unchecked"/>: ${record.systemAssertions.unchecked?.size()?:0}
                                    </li>

                                    <li id="dataQualityFurtherDetails">
                                        <i class="icon-hand-right"></i>&nbsp;
                                        <a id="dataQualityReportLink" href="#dataQualityReport">
                                            View full data quality report
                                        </a>
                                    </li>

                                    <g:set var="hasExpertDistribution" value="${false}"/>
                                    <g:each var="systemAssertion" in="${record.systemAssertions.failed}">
                                        <g:if test="${systemAssertion.code == 26}">
                                            <g:set var="hasExpertDistribution" value="${true}"/>
                                        </g:if>
                                    </g:each>

                                    <g:set var="isDuplicate" value="${false}"/>
                                    <g:if test="${record.processed.occurrence.duplicationStatus}">
                                        <g:set var="isDuplicate" value="${true}"/>
                                    </g:if>

                                    <g:if test="${isDuplicate}">
                                       <li><i class="icon-hand-right"></i>&nbsp;
                                        <a id="duplicateLink" href="#inferredOccurrenceDetails">
                                            Potential duplicate record - view details
                                        </a>
                                        </li>
                                    </g:if>

                                    <g:if test="${hasExpertDistribution}">
                                       <li><i class="icon-hand-right"></i>&nbsp;
                                        <a id="expertRangeLink" href="#expertReport">
                                            Outside expert range - view details
                                        </a>
                                        </li>
                                    </g:if>

                                    <g:if test="${record.processed.occurrence.outlierForLayers}">
                                       <li><i class="icon-hand-right"></i>&nbsp;
                                        <a id="outlierReportLink" href="#outlierReport">
                                            Environmental outlier - view details
                                        </a>
                                        </li>
                                    </g:if>
                                </ul>

                                <!--<p class="half-padding-bottom">Data validation tools identified the following possible issues:</p>-->
                                <g:set var="recordIsVerified" value="false"/>

                                <g:each in="${record.userAssertions}" var="userAssertion">
                                    <g:if test="${userAssertion.name == 'userVerified'}"><g:set var="recordIsVerified" value="true"/></g:if>
                                </g:each>
                            </div>

                            <div id="userAssertionsContainer" <g:if test="${!record.userAssertions && !queryAssertions}">style="display:none"</g:if>>
                                <h3>User flagged issues</h3>
                                <ul id="userAssertions">
                                    <!--<p class="half-padding-bottom">Users have highlighted the following possible issues:</p>-->
                                    <alatag:groupedAssertions groupedAssertions="${groupedAssertions}" />
                                </ul>
                                <div id="userAssertionsDetailsLink">
                                    <a id="showUserFlaggedIssues" href="#userAnnotations">
                                        View issue list & comments
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </g:if>
                <g:if test="${isCollectionAdmin && (record.systemAssertions.failed || record.userAssertions) && ! recordIsVerified}">
                    <div class="sidebar">
                        <button class="btn" id="verifyButton" href="#verifyRecord">
                            <span id="verifyRecordSpan" title="">Verify record</span>
                        </button>
                        <div style="display:none;">
                            <div id="verifyRecord">
                                <h3>Confirmation</h3>
                                <div id="verifyAsk">
                                    <g:set var="markedAssertions"/>
                                    <g:if test="!record.processed.geospatiallyKosher">
                                        <g:set var="markedAssertions">geospatially suspect</g:set>
                                    </g:if>
                                    <g:if test="!record.processed.taxonomicallyKosher">
                                        <g:set var="markedAssertions">${markedAssertions}${markedAssertions ? ", " : ""}taxonomically suspect</g:set>
                                    </g:if>
                                    <g:each var="sysAss" in="${record.systemAssertions.failed}">
                                        <g:set var="markedAssertions">${markedAssertions}${markedAssertions ? ", " : ""}<g:message code="${sysAss.name}" /></g:set>
                                    </g:each>
                                    <p>
                                        Record is marked as <b>${markedAssertions}</b>
                                    </p>
                                    <p style="margin-bottom:10px;">
                                        Click the &quot;Confirm&quot; button to verify that this record is correct and that
                                        the listed &quot;validation issues&quot; are incorrect/invalid.<br/>Please provide a
                                        short comment supporting your verification.
                                    </p>
                                    <textarea id="verifyComment" rows="3"></textarea><br/>
                                    <button class="btn confirmVerify">Confirm</button>
                                    <button class="btn cancelVerify">Cancel</button>
                                    <img src="${request.contextPath}/images/spinner.gif" id="verifySpinner" class="hide" alt="spinner icon"/>
                                </div>
                                <div id="verifyDone" style="display:none;">
                                    Record successfully verified
                                    <br/>
                                    <button class="btn closeVerify">Close</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </g:if>
                <g:if test="${record.processed.attribution.provenance && record.processed.attribution.provenance == 'Draft'}">
                    <div class="sidebar">
                        <p class="grey-bg" style="padding:5px; margin-top:15px; margin-bottom:10px;">
                            This record was transcribed from the label by an online volunteer.
                            It has not yet been validated by the owner institution
                            <a href="http://volunteer.ala.org.au/">Biodiversity Volunteer Portal</a>.
                        </p>

                        <button class="btn" id="viewDraftButton" >
                            <span id="viewDraftSpan" title="View Draft">See draft in Biodiversity Volunteer Portal</span>
                        </button>
                    </div>
                </g:if>
                <g:if test="${!isReadOnly && record.processed.attribution.provenance != 'Draft'}">
                    <div class="sidebar">
                        <button class="btn" id="assertionButton" href="#loginOrFlag" role="button" data-toggle="modal" title="report a problem or suggest a correction for this record">
                            <span id="loginOrFlagSpan" title="Flag an issue" class=""><i class="icon-flag"></i> Flag an issue</span>
                        </button>
                        <div id="loginOrFlag" class="modal hide" tabindex="-1" role="dialog" aria-labelledby="loginOrFlagLabel" aria-hidden="true"><!-- BS modal div -->
                            <div class="modal-header">
                                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                                <h3 id="loginOrFlagLabel">Flag an issue</h3>
                            </div>
                            <div class="modal-body">
                                <g:if test="${!userId}">
                                    <div style="margin: 20px 0;">Login please:
                                        <a href="https://auth.ala.org.au/cas/login?service=${serverName}${request.contextPath}/occurrences/${record.raw.uuid}">Click here</a>
                                    </div>
                                </g:if>
                                <g:else>
                                    <div>
                                        You are logged in as  <strong>${userDisplayName} (${userEmail})</strong>.
                                        <form id="issueForm">
                                            <p style="margin-top:20px;">
                                                <label for="issue">Issue type:</label>
                                                <select name="issue" id="issue">
                                                    <g:each in="${errorCodes}" var="code">
                                                        <option value="${code.code}"><g:message code="${code.name}" default="${code.name}"/></option>
                                                    </g:each>
                                                </select>
                                            </p>
                                            <p style="margin-top:30px;">
                                                <label for="issueComment" style="vertical-align:top;">Comment:</label>
                                                <textarea name="comment" id="issueComment" style="width:380px;height:150px;" placeholder="Please add a comment here..."></textarea>
                                            </p>
                                            <p style="margin-top:20px;">
                                                <input id="issueFormSubmit" type="submit" value="Submit" class="btn" />
                                                <input type="reset" value="Cancel" class="btn" onClick="$.fancybox.close();"/>
                                                <input type="button" id="close" value="Close" class="btn" style="display:none;"/>
                                                <span id="submitSuccess"></span>
                                            </p>
                                            <p id="assertionSubmitProgress" style="display:none;">
                                                <img src="${serverName}${request.contextPath}/images/indicator.gif"/>
                                            </p>

                                        </form>
                                    </div>
                                </g:else>
                            </div>
                            <div class="modal-footer">
                                <button class="btn btn-small" data-dismiss="modal" aria-hidden="true" style="float:right;">Close</button>
                            </div>
                        </div>
                    </div>
                </g:if>
                <div class="sidebar">
                    <button href="#processedVsRawView" class="btn" id="showRawProcessed" role="button" data-toggle="modal"
                            title="Table showing both original and processed record values">
                        <span id="processedVsRawViewSpan" href="#processedVsRawView" title=""><i class="icon-th"></i> Original vs Processed</span>
                    </button>
                </div>
                <g:if test="${record.images}">
                    <div class="sidebar">
                        <h3>Images</h3>
                        <div id="occurrenceImages" style="margin-top:5px;">
                            <g:each in="${record.images}" var="image">
                                <a href="${image.alternativeFormats.largeImageUrl}" target="_blank">
                                    <img src="${image.alternativeFormats.smallImageUrl}" style="max-width: 100%;"/>
                                </a>
                                <br/>
                                <g:if test="${record.raw.occurrence.photographer}">
                                    <cite>Photographer: ${record.raw.occurrence.photographer}</cite>
                                </g:if>
                                <g:if test="${record.raw.occurrence.rights}">
                                    <cite>Rights: ${record.raw.occurrence.rights}</cite>
                                </g:if>
                                <g:if test="${record.raw.occurrence.rightsholder}">
                                    <cite>Rights holder: ${record.raw.occurrence.rightsholder}</cite>
                                </g:if>
                                <a href="${image.alternativeFormats.imageUrl}" target="_blank">Original image (${formattedImageSizes?.get(image.alternativeFormats?.imageUrl)?:'file size not known'})</a>
                            </g:each>
                        </div>
                    </div>
                </g:if>
                <g:if test="${record.processed.location.decimalLatitude && record.processed.location.decimalLongitude}">
                    <g:set var="latLngStr">
                        <g:if test="${clubView && record.raw.location.decimalLatitude && record.raw.location.decimalLatitude != record.processed.location.decimalLatitude}">
                            ${record.raw.location.decimalLatitude},${record.raw.location.decimalLongitude}
                        </g:if>
                        <g:else>
                            ${record.processed.location.decimalLatitude},${record.processed.location.decimalLongitude}
                        </g:else>
                    </g:set>
                    <div class="sidebar">

                        %{--<script type="text/javascript" src="http://maps.google.com/maps/api/js?sensor=false"></script>--}%
                        <script type="text/javascript">
                            $(document).ready(function() {
                                var latlng = new google.maps.LatLng(${latLngStr});
                                var myOptions = {
                                    zoom: 5,
                                    center: latlng,
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

                                var map = new google.maps.Map(document.getElementById("occurrenceMap"), myOptions);

                                var marker = new google.maps.Marker({
                                    position: latlng,
                                    map: map,
                                    title:"Occurrence Location"
                                });

                                <g:if test="${record.processed.location.coordinateUncertaintyInMeters}">
                                var radius = parseInt('${record.processed.location.coordinateUncertaintyInMeters}');
                                if (!isNaN(radius)) {
                                    // Add a Circle overlay to the map.
                                    circle = new google.maps.Circle({
                                        map: map,
                                        radius: radius, // 3000 km
                                        strokeWeight: 1,
                                        strokeColor: 'white',
                                        strokeOpacity: 0.5,
                                        fillColor: '#2C48A6',
                                        fillOpacity: 0.2
                                    });
                                    // bind circle to marker
                                    circle.bindTo('center', marker, 'position');
                                }
                                </g:if>
                            });
                        </script>
                        <h3>Location of record</h3>
                        <div id="occurrenceMap"></div>
                    </div>
                </g:if>
                <g:if test="${record.sounds}">
                    <div class="sidebar">
                        <h3 id="soundsHeader">Sounds</h3>
                        <div class="row-fluid">
                        <div id="audioWrapper" class="span12">
                            <audio src="${record.sounds.get(0).alternativeFormats.audio/mpeg}" preload="auto" />
                            <div class="track-details">
                              ${record.raw.classification.scientificName}
                            </div>
                        </div>
                        </div>
                        <g:if test="${record.raw.occurrence.rights}">
                            <br/>
                            <cite>Rights: ${record.raw.occurrence.rights}</cite>
                        </g:if>
                        <p>
                            Please press the play button to hear the sound file
                            associated with this occurrence record.
                        </p>
                    </div>
                </g:if>
                <g:if test="${record.raw.lastModifiedTime && record.processed.lastModifiedTime}">
                    <div class="sidebar" style="margin-top: 10px;font-size: 12px; color: #555;">
                        %{--<g:catch var="parseError">--}%
                            %{--<fmt:parseDate var="rawLastModified" value="${record.raw.lastModifiedTime}" pattern="yyyy-MM-dd'T'HH:mm:ss'Z'"/>--}%
                            %{--<fmt:formatDate var="rawLastModifiedString" value="${rawLastModified}" pattern="yyyy-MM-dd"/>--}%
                            %{--<fmt:parseDate var="processedLastModified" value="${record.processed.lastModifiedTime}" pattern="yyyy-MM-dd'T'HH:mm:ss'Z'"/>--}%
                            %{--<fmt:formatDate var="processedLastModifiedString" value="${processedLastModified}" pattern="yyyy-MM-dd"/>--}%
                        %{--</g:catch>--}%
                        %{--<g:if test="${parseError}">--}%
                            %{--<g:set var="rawLastModifiedString" value="${record.raw.lastModifiedTime}"/>--}%
                            %{--<g:set var="processedLastModifiedString" value="${record.processed.lastModifiedTime}"/>--}%
                        %{--</g:if>--}%
                        <p style="margin-bottom:20px;">
                            Date loaded: ${rawLastModifiedString}<br/>
                            Date last processed: ${processedLastModifiedString}<br/>
                        </p>
                    </div>
                </g:if>
                </div><!-- end div#SidebarBox -->
                <div id="content2Z" class="span8">
                    %{--<jsp:include page="recordCoreDiv.jsp"/>--}%
                    <g:render template="recordCore" />
                </div><!-- end of div#content2 -->
            </div>

            <g:if test="${hasExpertDistribution}">
                <div id="hasExpertDistribution"  class="additionalData" style="clear:both;padding-top: 20px;">
                    <h2>Record outside of expert distribution area (shown in red) <a id="expertReport" href="#expertReport">&nbsp;</a></h2>
                    <script type="text/javascript" src="${request.contextPath}/js/wms2.js"></script>
                    <script type="text/javascript">
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
                    </script>
                    <div id="expertDistroMap" style="width:80%;height:400px;margin:20px 20px 10px 0;"></div>
                </div>
            </g:if>

                <style type="text/css">
                    #outlierFeedback #inferredOccurrenceDetails { clear:both; margin-left:20px;margin-top:30px; width:100%; }
                        /*#outlierFeedback h3 {color: #718804; }*/
                    #outlierFeedback #outlierInformation #inferredOccurrenceDetails { margin-bottom:20px; }
                </style>

            <script type="text/javascript" src="${biocacheService}/outlier/record/${uuid}.json?callback=renderOutlierCharts"></script>

            <div id="userAnnotationsDiv" class="additionalData">
                <h2>User flagged issues<a id="userAnnotations">&nbsp;</a></h2>
                <ul id="userAnnotationsList" style="list-style: none; margin:0;"></ul>
            </div>

            <div id="dataQuality" class="additionalData"><a name="dataQualityReport"></a>
                <h2>Data quality tests</h2>
                <div id="dataQualityModal" class="modal hide fade" tabindex="-1" role="dialog">
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal">×</button>
                        <h3>Data Quality Details</h3>
                    </div>
                    <div class="modal-body">
                        <p>loading...</p>
                    </div>
                    <div class="modal-footer">
                        <button class="btn" data-dismiss="modal">Close</button>
                    </div>
                </div>
                <table class="dataQualityResults table-striped table-bordered table-condensed">
                    <%--<caption>Details of tests that have been performed for this record.</caption>--%>
                    <thead>
                        <tr class="sectionName">
                            <td class="dataQualityTestName">Test name</td>
                            <td class="dataQualityTestResult">Result</td>
                            <%--<th class="dataQualityMoreInfo">More information</th>--%>
                        </tr>
                    </thead>
                    <tbody>
                        <g:set var="testSet" value="${record.systemAssertions.failed}"/>
                        <g:each in="${testSet}" var="test">
                        <tr>
                            <td><g:message code="${test.name}" default="${test.name}"/><alatag:dataQualityHelp code="${test.code}"/></td>
                            <td><i class="icon-thumbs-down icon-red"></i> Failed</td>
                            <%--<td>More info</td>--%>
                        </tr>
                        </g:each>

                        <g:set var="testSet" value="${record.systemAssertions.warning}"/>
                        <g:each in="${testSet}" var="test">
                        <tr>
                            <td><g:message code="${test.name}" default="${test.name}"/><alatag:dataQualityHelp code="${test.code}"/></td>
                            <td><i class="icon-warning-sign"></i> Warning</td>
                            <%--<td>More info</td>--%>
                        </tr>
                        </g:each>

                        <g:set var="testSet" value="${record.systemAssertions.passed}"/>
                        <g:each in="${testSet}" var="test">
                        <tr>
                            <td><g:message code="${test.name}" default="${test.name}"/><alatag:dataQualityHelp code="${test.code}"/></td>
                            <td><i class="icon-thumbs-up icon-green"></i> Passed</td>
                            <%--<td>More info</td>--%>
                        </tr>
                        </g:each>

                        <g:if test="${record.systemAssertions.missing}">
                            <tr>
                                <td colspan="2">
                                <a href="javascript:void(0)" id="showMissingPropResult">Show/Hide  ${record.systemAssertions.missing.length()} missing properties</a>
                                </td>
                            </tr>
                        </g:if>
                        <g:set var="testSet" value="${record.systemAssertions.missing}"/>
                        <g:each in="${testSet}" var="test">
                        <tr class="missingPropResult" style="display:none;">
                            <td><g:message code="${test.name}" default="${test.name}"/><alatag:dataQualityHelp code="${test.code}"/></td>
                            <td><i class=" icon-question-sign"></i> Missing</td>
                        </tr>
                        </g:each>

                        <g:if test="${record.systemAssertions.unchecked}">
                            <tr>
                                <td colspan="2">
                                <a href="javascript:void(0)" id="showUncheckedTests">Show/Hide  ${record.systemAssertions.unchecked.length()} tests that havent been ran</a>
                                </td>
                            </tr>
                        </g:if>
                        <g:set var="testSet" value="${record.systemAssertions.unchecked}"/>
                        <g:each in="${testSet}" var="test">
                        <tr class="uncheckTestResult" style="display:none;">
                            <td><g:message code="${test.name}" default="${test.name}"/><alatag:dataQualityHelp code="${test.code}"/></td>
                            <td>Unchecked (lack of data)</td>
                        </tr>
                        </g:each>

                    </tbody>
                </table>
            </div>

            <div id="outlierFeedback">
                <g:if test="${record.processed.occurrence.outlierForLayers}">
                    <div id="outlierInformation" class="additionalData">
                        <h2>Outlier information <a id="outlierReport" href="#outlierReport">&nbsp;</a></h2>
                        <p>
                            This record has been detected as an outlier using the
                            <a href="http://code.google.com/p/ala-dataquality/wiki/DETECTED_OUTLIER_JACKKNIFE">Reverse Jackknife algorithm</a>
                            for the following layers:</p>
                        <ul>
                        <g:each in="${metadataForOutlierLayers}" var="layerMetadata">
                            <li>
                                <a href="http://spatial.ala.org.au/layers/more/${layerMetadata.name}">${layerMetadata.displayname} - ${layerMetadata.source}</a><br/>
                                Notes: ${layerMetadata.notes}<br/>
                                Scale: ${layerMetadata.scale}
                            </li>
                        </g:each>
                        </ul>

                        <p style="margin-top:20px;">More information on the data quality work being undertaken by the Atlas is available here:
                            <ul>
                                <li><a href="http://code.google.com/p/ala-dataquality/wiki/DETECTED_OUTLIER_JACKKNIFE">http://code.google.com/p/ala-dataquality/wiki/DETECTED_OUTLIER_JACKKNIFE</a></li>
                                <li><a href="https://docs.google.com/open?id=0B7rqu1P0r1N0NGVhZmVhMjItZmZmOS00YmJjLWJjZGQtY2Y0ZjczZmUzZTZl">Notes on Methods for Detecting Spatial Outliers</a></li>
                            </ul>
                        </p>
                    </div>
                    <div id="charts" style="margin-top:20px;"></div>
                </g:if>

				<g:if test="${record.processed.occurrence.duplicationStatus}">
					<div id="inferredOccurrenceDetails">
              		<a href="#inferredOccurrenceDetails" name="inferredOccurrenceDetails" id="inferredOccurrenceDetails" hidden="true"></a>
              		<h2>Inferred associated occurrence details</h2>
					<p style="margin-top:5px;">
                        <g:if test="${record.processed.occurrence.duplicationStatus == 'R' }">
                            This record has been identified as the <em>representative</em> occurrence in a group of associated occurrences.
                            This mean other records have been detected that seem to relate to this record and this particular record has the most detailed
                            information on the occurrence.
                        </g:if>
                        <g:else>This record is associated with the <em>representative</em> record.
                            This mean another record has been detected to be similar to this record, and that the other
                            record (the representative record) has the most detailed information for the occurrence.
                        </g:else>
					    More information about the duplication detection methods and terminology in use is available here:
						<ul>
							<li>
							<a href="http://code.google.com/p/ala-dataquality/wiki/INFERRED_DUPLICATE_RECORD">http://code.google.com/p/ala-dataquality/wiki/INFERRED_DUPLICATE_RECORD</a>
							</li>
						</ul>
					</p>
					<g:if test="${duplicateRecordDetails}">
						<table class="duplicationTable table-striped table-bordered table-condensed" style="border-bottom:none;">
							<tr class="sectionName"><td colspan="4">Representative Record</td></tr>
							<alatag:occurrenceTableRow
                                    annotate="false"
                                    section="duplicate"
                                    fieldName="Record UUID">
                            <a href="${request.contextPath}/occurrences/${duplicateRecordDetails.uuid}">${duplicateRecordDetails.uuid}</a></alatag:occurrenceTableRow>
                            <alatag:occurrenceTableRow
        							annotate="false"
        							section="duplicate"
        							fieldName="Data Resource">
        					<g:set var="dr">${duplicateRecordDetails.rowKey.substring(0, duplicateRecordDetails.rowKey.indexOf("|"))}</g:set>
        					<a href="${collectionsWebappContext}/public/show/${dr}">${dataResourceCodes.get(dr)}</a>
				 			</alatag:occurrenceTableRow>
                            <g:if test="${duplicateRecordDetails.rawScientificName}">
			        		<alatag:occurrenceTableRow
	                				annotate="false"
	                				section="duplicate"
	                				fieldName="Raw Scientific Name">
	        					${duplicateRecordDetails.rawScientificName}</alatag:occurrenceTableRow>
		        			</g:if>
                            <alatag:occurrenceTableRow
                                    annotate="false"
                                    section="duplicate"
                                    fieldName="Coordinates">
                            ${duplicateRecordDetails.latLong}</alatag:occurrenceTableRow>
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
                            <tr class="sectionName"><td colspan="4">Related records</td></tr>
                            <g:each in="${duplicateRecordDetails.duplicates }" var="dup">
                            	<alatag:occurrenceTableRow
                                    annotate="false"
                                    section="duplicate"
                                    fieldName="Record UUID">
                            <a href="${request.contextPath}/occurrences/${dup.uuid}">${dup.uuid}</a></alatag:occurrenceTableRow>
                            <alatag:occurrenceTableRow
        							annotate="false"
        							section="duplicate"
        							fieldName="Data Resource">
        					<g:set var="dr">${dup.rowKey.substring(0, dup.rowKey.indexOf("|"))}</g:set>
        					<a href="${collectionsWebappContext}/public/show/${dr}">${dataResourceCodes.get(dr)}</a>
				 			</alatag:occurrenceTableRow>
                            <g:if test="${dup.rawScientificName}">
			        		<alatag:occurrenceTableRow
	                				annotate="false"
	                				section="duplicate"
	                				fieldName="Raw Scientific Name">
	        					${dup.rawScientificName}</alatag:occurrenceTableRow>
		        			</g:if>
                            <alatag:occurrenceTableRow
                                    annotate="false"
                                    section="duplicate"
                                    fieldName="Coordinates">
                            ${dup.latLong}</alatag:occurrenceTableRow>
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
                            		<g:message code="duplication.${dupType.id}"/>
                            		<br>
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
                    <h3>Additional political boundaries information</h3>
                    <table class="layerIntersections table-striped table-bordered table-condensed">
                        <tbody>
                        <g:each in="${contextualSampleInfo}" var="sample" status="vs">
                            <g:if test="${sample.classification1 && (vs == 0 || (sample.classification1 != contextualSampleInfo.get(vs - 1).classification1 && vs != contextualSampleInfo.size() - 1))}">
                                <tr class="sectionName"><td colspan="2">${sample.classification1}</td></tr>
                            </g:if>
                            <g:set var="fn"><a href='${spatialPortalUrl}layers/more/${sample.layerName}' title='more information about this layer'>${sample.layerDisplayName}</a></g:set>
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
                    <h3>Environmental sampling for this location</h3>
                    <table class="layerIntersections table-striped table-bordered table-condensed" >
                        <tbody>
                        <g:each in="${environmentalSampleInfo}" var="sample" status="vs">
                            <g:if test="${sample.classification1 && (vs == 0 || (sample.classification1 != environmentalSampleInfo.get(vs - 1).classification1 && vs != environmentalSampleInfo.size() - 1))}">
                                <tr class="sectionName"><td colspan="2">${sample.classification1}</td></tr>
                            </g:if>
                            <g:set var="fn"><a href='${spatialPortalUrl}layers/more/${sample.layerName}' title='More information about this layer'>${sample.layerDisplayName}</a></g:set>
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

            <div id="processedVsRawView" class="modal hide " tabindex="-1" role="dialog" aria-labelledby="processedVsRawViewLabel" aria-hidden="true"><!-- BS modal div -->
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                    <h3 id="processedVsRawViewLabel"><g:message code="show.comparisonTable.title" default="&quot;Original versus Processed&quot; Comparison Table"/></h3>
                </div>
                <div class="modal-body">
                    <table class="table table-bordered table-striped table-condensed">
                        <thead>
                        <tr>
                            <th style="width:15%;">Group</th>
                            <th style="width:15%;">Field Name</th>
                            <th style="width:35%;">Original Value</th>
                            <th style="width:35%;">Processed Value</th>
                        </tr>
                        </thead>
                        <tbody>
                            <alatag:formatRawVsProcessed map="${compareRecord}"/>
                        </tbody>
                    </table>
                </div>
                <div class="modal-footer">
                    <button class="btn btn-small" data-dismiss="modal" aria-hidden="true" style="float:right;">Close</button>
                </div>
            </div>

            %{--<div style="display:none;clear:both;">--}%
                %{--<div id="processedVsRawView">--}%
                    %{--<h2>&quot;Original versus Processed&quot; Comparison Table</h2>--}%
                    %{--<table>--}%
                        %{--<thead>--}%
                            %{--<tr>--}%
                                %{--<th style="width:15%;text-align:center;">Group</th>--}%
                                %{--<th style="width:15%;text-align:center;">Field Name</th>--}%
                                %{--<th style="width:35%;text-align:center;">Original</th>--}%
                                %{--<th style="width:35%;text-align:center;">Processed</th>--}%
                            %{--</tr>--}%
                        %{--</thead>--}%
                        %{--<tbody>--}%
                            %{--<alatag:formatRawVsProcessed map="${compareRecord}"/>--}%
                        %{--</tbody>--}%
                    %{--</table>--}%
                %{--</div>--}%
            %{--</div>--}%
        </g:if>

        <ul style="display:none;">
        <li id="userAnnotationTemplate" class="userAnnotationTemplate well">
           <h3><span class="issue"></span> - flagged by <span class="user"></span><span class="userRole"></span><span class="userEntity"></span></h3>
           <p class="comment"></p>
           <p class="hide userDisplayName"></p>
           <p class="created"></p>
           <p class="viewMore" style="display:none;">
               <a class="viewMoreLink" href="#">View more with this annotation</a>
           </p>
           <p class="deleteAnnotation" style="display:none;">
               <a class="deleteAnnotationButton btn" href="#">Delete this annotation</a>
           </p>
        </li>
        </ul>

        <g:if test="${!record.raw}">
            <div id="headingBar">
                <h1>Record Not Found</h1>
                <p>The requested record ID "${uuid}" was not found</p>
            </div>
        </g:if>
            <g:if test="${record.sounds}">
            <script>
              audiojs.events.ready(function() {
                var as = audiojs.createAll();
              });
            </script>
        </g:if>
    </g:if>
    <g:else>
        <h3>An error occurred <br/>${flash.message}</h3>
    </g:else>
</body>
</html>