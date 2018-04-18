<g:if test="${isUnderCas && !isReadOnly && record.processed.attribution.provenance != 'Draft'}">
    <button class="btn btn-default" id="assertionButton" href="#loginOrFlag" role="button" data-toggle="modal" title="report a problem or suggest a correction for this record">
        <span id="loginOrFlagSpan" title="Flag an issue" class=""><i class="glyphicon glyphicon-flag"></i> <g:message code="show.button.assertionbutton.span" default="Flag an issue"/></span>
    </button>
</g:if>
<g:if test="${contacts && contacts.size()}">
    <button href="#contactCuratorView" class="btn btn-default" id="showCurator" role="button" data-toggle="modal"
            title="Contact curator for more details on a record">
        <span id="contactCuratorSpan" href="#contactCuratorView" title=""><i class="glyphicon glyphicon-envelope"></i> <g:message code="show.showcontactcurator.span" default="Contact curator"/></span>
    </button>
</g:if>
%{--<div class="nav-affix" data-spy="affix" data-offset-top="236" data-offset-bottom="1080">--}%
<div class="" >
    <ul id="navBox" class="nav nav-pills nav-stacked">
        <li><a href="#occurrenceDataset"><g:message code="recordcore.occurencedataset.title" default="Dataset"/></a></li>
        <li><a href="#occurrenceEvent"><g:message code="recordcore.occurenceevent.title" default="Event"/></a></li>
        <li><a href="#occurrenceTaxonomy"><g:message code="recordcore.occurencetaxonomy.title" default="Taxonomy"/></a></li>
        <li><a href="#occurrenceGeospatial"><g:message code="recordcore.occurencegeospatial.title" default="Geospatial"/></a></li>
        <g:if test="${record.raw.miscProperties}">
            <li><a href="#additionalProperties"><g:message code="recordcore.div.addtionalproperties.title" default="Additional properties"/></a></li>
        </g:if>
        <g:if test="${record.images}">
            <li><a href="#images"><g:message code="show.sidebar03.title" default="Images"/></a></li>
        </g:if>
        <g:if test="${record.sounds}">
            <li><a href="#soundsHeader"><g:message code="show.soundsheader.title" default="Sounds"/></a></li>
        </g:if>
        <li><a href="#userAnnotationsDiv" id="userAnnotationsNav" style="display:none;"><g:message code="show.userannotationsdiv.title" default="User flagged issues"/></a></li>
        <g:if test="${record.systemAssertions && record.processed.attribution.provenance != 'Draft'}">
            <li><a href="#dataQuality"><g:message code="show.dataquality.title" default="Data quality tests"/>
            (${record.systemAssertions.failed?.size()?:0} <i class="fa fa-times-circle tooltips" style="color:red;" title="<g:message code="assertions.failed" default="failed"/>"></i>,
            ${record.systemAssertions.warning?.size()?:0} <i class="fa fa-exclamation-circle tooltips" style="color:orange;" title="<g:message code="assertions.warnings" default="warning"/>"></i>,
            ${record.systemAssertions.passed?.size()?:0} <i class="fa fa-check-circle tooltips" style="color:green;" title="<g:message code="assertions.passed" default="passed"/>"></i>,
            ${record.systemAssertions.missing?.size()?:0} <i class="fa fa-question-circle tooltips" style="color:gray;" title="<g:message code="assertions.missing" default="missing"/>"></i>,
            ${record.systemAssertions.unchecked?.size()?:0} <i class="fa fa-ban tooltips" style="color:gray;" title="<g:message code="assertions.unchecked" default="unchecked"/>"></i>)
            </a></li>
        </g:if>
        <g:if test="${record.processed.occurrence.outlierForLayers}">
            <li><a href="#outlierInformation"><g:message code="show.outlierinformation.title" default="Outlier information"/></a></li>
        </g:if>
        <g:if test="${record.processed.occurrence.duplicationStatus}">
            <li><a href="#inferredOccurrenceDetails"><g:message code="show.inferredoccurrencedetails.title" default="Inferred associated occurrence details"/></a></li>
        </g:if>
        <g:if test="${contextualSampleInfo}">
            <li><a href="#contextualSampleInfo"><g:message code="show.outlierinformation.02.title01" default="Additional political boundaries information"/></a></li>
        </g:if>
        <g:if test="${environmentalSampleInfo}">
            <li><a href="#environmentalSampleInfo"><g:message code="show.outlierinformation.02.title02" default="Environmental sampling for this location"/></a></li>
        </g:if>
    </ul>
    <g:if test="${false && record.processed.attribution.provenance != 'Draft'}">
        <div class="sidebar">
            <div id="warnings">
                <div id="systemAssertionsContainer" <g:if test="${!record.systemAssertions}">style="display:none"</g:if>>
                    <h3><g:message code="show.systemassertioncontainer.title" default="Data quality tests"/></h3>

                    <span id="systemAssertions">
                        <li class="failedTestCount">
                            <g:message code="assertions.failed" default="failed"/>: ${record.systemAssertions.failed?.size()?:0}
                        </li>
                        <li class="warningsTestCount">
                            <g:message code="assertions.warnings" default="warnings"/>: ${record.systemAssertions.warning?.size()?:0}
                        </li>
                        <li class="passedTestCount">
                            <g:message code="assertions.passed" default="passed"/>: ${record.systemAssertions.passed?.size()?:0}
                        </li>
                        <li class="missingTestCount">
                            <g:message code="assertions.missing" default="missing"/>: ${record.systemAssertions.missing?.size()?:0}
                        </li>
                        <li class="uncheckedTestCount">
                            <g:message code="assertions.unchecked" default="unchecked"/>: ${record.systemAssertions.unchecked?.size()?:0}
                        </li>

                        <li id="dataQualityFurtherDetails">
                            <i class="icon-hand-right"></i>&nbsp;
                            <a id="dataQualityReportLink" href="#dataQualityReport">
                                <g:message code="show.dataqualityreportlink.navigator" default="View full data quality report"/>
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
                                    <g:message code="show.duplicatelink.navigator" default="Potential duplicate record - view details"/>
                                </a>
                            </li>
                        </g:if>

                        <g:if test="${hasExpertDistribution}">
                            <li><i class="icon-hand-right"></i>&nbsp;
                                <a id="expertRangeLink" href="#expertReport">
                                    <g:message code="show.expertrangelink.navigator" default="Outside expert range - view details"/>
                                </a>
                            </li>
                        </g:if>

                        <g:if test="${record.processed.occurrence.outlierForLayers}">
                            <li><i class="icon-hand-right"></i>&nbsp;
                                <a id="outlierReportLink" href="#outlierReport">
                                    <g:message code="show.outlierreportlink.navigator" default="Environmental outlier - view details"/>
                                </a>
                            </li>
                        </g:if>
                    </span>

                    <!--<p class="half-padding-bottom">Data validation tools identified the following possible issues:</p>-->
                    <g:set var="recordIsVerified" value="false"/>

                    <g:each in="${record.userAssertions}" var="userAssertion">
                        <g:if test="${userAssertion.name == 'userVerified'}"><g:set var="recordIsVerified" value="true"/></g:if>
                    </g:each>
                </div>

                <div id="userAssertionsContainer" <g:if test="${!record.userAssertions && !queryAssertions}">style="display:none"</g:if>>
                    <h3><g:message code="show.userassertionscontainer.title" default="User flagged issues"/></h3>
                    <ul id="userAssertions">
                        <!--<p class="half-padding-bottom">Users have highlighted the following possible issues:</p>-->
                        <alatag:groupedAssertions groupedAssertions="${groupedAssertions}" />
                    </ul>
                    <div id="userAssertionsDetailsLink">
                        <a id="showUserFlaggedIssues" href="#userAnnotations">
                            <g:message code="show.showuserflaggedissues.navigator" default="View issue list &amp; comments"/>
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </g:if>

    <g:if test="${record.processed.attribution.provenance && record.processed.attribution.provenance == 'Draft'}">
        <div class="sidebar">
            <p class="grey-bg" style="padding:5px; margin-top:15px; margin-bottom:10px;">
                <g:message code="show.sidebar01.p" default="This record was transcribed from the label by an online volunteer. It has not yet been validated by the owner institution"/>
                <a href="https://volunteer.ala.org.au/"><g:message code="show.sidebar01.volunteer.navigator" default="Biodiversity Volunteer Portal"/></a>.
            </p>

            <button class="btn btn-default" id="viewDraftButton" >
                <span id="viewDraftSpan" title="View Draft"><g:message code="show.button.viewdraftbutton.span" default="See draft in Biodiversity Volunteer Portal"/></span>
            </button>
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
            <asset:script type="text/javascript">
                $(document).ready(function() {
                    var latlng = new google.maps.LatLng(${latLngStr.trim()});
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
            </asset:script>
            %{--<h3><g:message code="show.occurrencemap.title" default="Location of record"/></h3>--}%
            <div id="occurrenceMap" class="google-maps"></div>
        </div>
    </g:if>
    <g:if test="${record.images}">
        <div class="sidebar">
            <h3 id="images"><g:message code="show.sidebar03.title" default="Images"/></h3>
            <div id="occurrenceImages" style="margin-top:5px;">
                <g:each in="${record.images}" var="image">
                    <div style="margin-bottom:10px;">
                        <g:if test="${grailsApplication.config.skin.useAlaImageService.toBoolean()}">
                            <a href="${grailsApplication.config.images.viewerUrl}${image.filePath}" target="_blank">
                                <img src="${image.alternativeFormats.smallImageUrl}" style="max-width: 100%;" alt="Click to view this image in a large viewer"/>
                            </a>
                        </g:if>
                        <g:else>
                            <a href="${image.alternativeFormats.largeImageUrl}" target="_blank">
                                <img src="${image.alternativeFormats.smallImageUrl}" style="max-width: 100%;"/>
                            </a>
                        </g:else>
                        <br/>
                        <g:if test="${record.raw.occurrence.photographer || image.metadata?.creator}">
                            <cite><g:message code="show.sidebar03.cite01" default="Photographer"/>: ${record.raw.occurrence.photographer ?: image.metadata?.creator}</cite><br/>
                        </g:if>
                        <g:if test="${record.raw.occurrence.rights || image.metadata?.rights}">
                            <cite><g:message code="show.sidebar03.cite02" default="Rights"/>: ${record.raw.occurrence.rights ?: image.metadata?.rights}</cite><br/>
                        </g:if>
                        <g:if test="${record.raw.occurrence.rightsholder || image.metadata?.rightsholder}">
                            <cite><g:message code="show.sidebar03.cite03" default="Rights holder"/>: ${record.raw.occurrence.rightsholder ?: image.metadata?.rightsholder}</cite><br/>
                        </g:if>
                        <g:if test="${record.raw.miscProperties.rightsHolder}">
                            <cite><g:message code="show.sidebar03.cite03" default="Rights holder"/>: ${record.raw.miscProperties.rightsHolder}</cite><br/>
                        </g:if>
                        <g:if test="${image.metadata?.license}">
                            <cite><g:message code="show.sidebar03.image.license" default="License"/>: ${image.metadata?.license}</cite><br/>
                        </g:if>
                        <g:if test="${grailsApplication.config.skin.useAlaImageService.toBoolean()}">
                            <a href="${grailsApplication.config.images.metadataUrl}${image.filePath}" target="_blank"><g:message code="show.sidebardiv.occurrenceimages.navigator01" default="View image details"/></a>
                        </g:if>
                        <g:else>
                            <a href="${image.alternativeFormats.imageUrl}" target="_blank"><g:message code="show.sidebardiv.occurrenceimages.navigator02" default="Original image"/></a>
                        </g:else>
                    </div>
                </g:each>
            </div>
        </div>
    </g:if>
    <g:if test="${record.sounds}">
        <div class="sidebar">
            <h3 id="soundsHeader" style="margin: 20px 0 0 0;"><g:message code="show.soundsheader.title" default="Sounds"/></h3>
            <div class="row">
                <div id="audioWrapper" class="col-md-12">
                    <audio src="${record.sounds.get(0)?.alternativeFormats?.'audio/mpeg'}" preload="auto" />
                    <div class="track-details">
                        ${record.raw.classification.scientificName}
                    </div>
                </div>
            </div>
            <g:if test="${record.raw.occurrence.rights}">
                <br/>
                <cite><g:message code="show.sidebar04.cite" default="Rights"/>: ${record.raw.occurrence.rights}</cite>
            </g:if>
            <p>
                <g:message code="show.sidebar04.p" default="Please press the play button to hear the sound file associated with this occurrence record."/>
            </p>
        </div>
    </g:if>
    <g:if test="${record.raw.lastModifiedTime && record.processed.lastModifiedTime}">
        <div class="sidebar">
            <g:set var="rawLastModifiedString" value="${record.raw.lastModifiedTime.substring(0,10)}"/>
            <g:set var="processedLastModifiedString" value="${record.processed.lastModifiedTime.substring(0,10)}"/>
            <p style="margin-bottom:20px;margin-top:20px;">
                <g:message code="show.sidebar05.p01" default="Date loaded"/>: ${rawLastModifiedString}<br/>
                <g:message code="show.sidebar05.p02" default="Date last processed"/>: ${processedLastModifiedString}<br/>
            </p>
        </div>
    </g:if>
</div>
<!-- BS modal flag-an-issue -->
<div id="loginOrFlag" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="loginOrFlagLabel" ><!-- BS modal div -->
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                <h3 id="loginOrFlagLabel"><g:message code="show.loginorflag.title" default="Flag an issue"/></h3>
            </div>
            <div class="modal-body">
                <g:if test="${!userId}">
                    <div style="margin: 20px 0;"><g:message code="show.loginorflag.div01.label" default="Login please:"/>
                        <a href="${grailsApplication.config.security.cas.casServerLoginUrl}?service=${serverName}${request.contextPath}/occurrences/${record.raw.rowKey}"><g:message code="show.loginorflag.div01.navigator" default="Click here"/></a>
                    </div>
                </g:if>
                <g:else>
                    <div>
                        <g:message code="show.loginorflag.div02.label" default="You are logged in as"/>  <strong>${userDisplayName} (${alatag.loggedInUserEmail()})</strong>.
                        <form id="issueForm">
                            <p style="margin-top:20px;">
                                <label for="issue"><g:message code="show.issueform.label01" default="Issue type:"/></label>
                                <select name="issue" id="issue">
                                    <g:each in="${errorCodes}" var="code">
                                        <option value="${code.code}"><g:message code="${code.name}" default="${code.name}"/></option>
                                    </g:each>
                                </select>
                            </p>
                            <p style="margin-top:30px;">
                                <label for="issueComment" style="vertical-align:top;"><g:message code="show.issueform.label02" default="Comment:"/></label>
                                <textarea name="comment" id="issueComment" style="width:380px;height:150px;" placeholder="Please add a comment here..."></textarea>
                            </p>
                            <p style="margin-top:20px;">
                                <input id="issueFormSubmit" type="submit" value="<g:message code="show.issueform.button.submit" default="Submit"/>" class="btn btn-primary" />
                                <input type="reset" value="<g:message code="show.issueform.button.cancel" default="Cancel"/>" class="btn btn-default" onClick="$('#loginOrFlag').modal('hide');"/>
                                <input type="button" id="close" value="<g:message code="show.issueform.button.close" default="Close"/>" class="btn btn-default" style="display:none;"/>
                                <span id="submitSuccess"></span>
                            </p>
                            <p id="assertionSubmitProgress" style="display:none;">
                                <asset:image src="indicator.gif" alt="indicator icon"/>
                            </p>
                        </form>
                    </div>
                </g:else>
            </div>
            <div class="hide modal-footer">
                <button class="btn btn-default btn-small" data-dismiss="modal" aria-hidden="true" style="float:right;"><g:message code="show.loginorflag.divbutton" default="Close"/></button>
            </div>
        </div>
    </div>
</div><!-- /.modal -->