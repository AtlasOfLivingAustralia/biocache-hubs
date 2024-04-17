<g:if test="${isUnderAuth}">
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
<div class="">
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
        <g:if test="${record.referencedPublications}">
            <li><a href="#referencedPublications"><g:message code="show.referencedPublications.title" default="Referenced in publications"/> (${record.referencedPublications.size()})</a></li>
        </g:if>
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

    <g:if test="${record.processed.attribution.provenance && record.processed.attribution.provenance == 'Draft'}">
        <div class="sidebar">
            <p class="grey-bg" style="padding:5px; margin-top:15px; margin-bottom:10px;">
                <g:message code="show.sidebar01.p" default="This record was transcribed from the label by an online volunteer. It has not yet been validated by the owner institution"/>
                <a href="https://volunteer.ala.org.au/"><g:message code="show.sidebar01.volunteer.navigator" default="Biodiversity Volunteer Portal"/></a>.
            </p>
        </div>
    </g:if>
    <g:if test="${record.processed.location.decimalLatitude && record.processed.location.decimalLongitude}">
        <g:set var="latLngStr">
            <g:if test="${clubView && record.sensitive && record.raw.location.decimalLatitude && record.raw.location.decimalLongitude}">
                ${record.raw.location.decimalLatitude}, ${record.raw.location.decimalLongitude}
            </g:if>
            <g:else>
                ${record.processed.location.decimalLatitude}, ${record.processed.location.decimalLongitude}
            </g:else>
        </g:set>
        <div class="sidebar">
            <asset:script type="text/javascript">
                $(document).ready(function() {
                    // Leaflet map
                    var defaultBaseLayer = L.tileLayer("${grailsApplication.config.getProperty('map.minimal.url')}", {
                        attribution: "${raw(grailsApplication.config.getProperty('map.minimal.attr'))}",
                        subdomains: "${grailsApplication.config.getProperty('map.minimal.subdomains')}"
                    });

                    var baseLayers = {
                        "Minimal": defaultBaseLayer,
                        "Road":  new L.Google('ROADMAP'),
                        //"Terrain": new L.Google('TERRAIN'),
                        "Satellite": new L.Google('HYBRID')
                    };

                    var latLng = L.latLng(${latLngStr.trim()});
                    var map = L.map('occurrenceMap', {
                        center: latLng,
                        zoom: 5,
                        scrollWheelZoom: false
                    });

                    L.control.layers(baseLayers).addTo(map);

                    map.on('baselayerchange', function(event) {
                        $.cookie('map.baseLayer', event.name, { path: '/' })
                    });

                    // select the user's preferred base layer
                    var userBaseLayer = $.cookie('map.baseLayer')
                    var baseLayer = baseLayers[userBaseLayer]
                    if (baseLayer !== undefined) {
                        //add the default base layer
                        map.addLayer(baseLayer);
                    } else {
                        map.addLayer(defaultBaseLayer);
                    }

                    // Fix for asset pipeline confusing Leaflet WRT to path to images
                    L.Icon.Default.imagePath = "${assetPath(src:'/leaflet/images')}";

                    // Add marker
                    L.marker(latLng, {
                        title: 'Occurrence location',
                        draggable: false
                    }).addTo(map);

                    <g:if test="${record.processed.location.coordinateUncertaintyInMeters}">
                        var radius = parseInt('${record.processed.location.coordinateUncertaintyInMeters}');
                        if (!isNaN(radius)) {
                            // Add a Circle overlay to the map.
                            var circlProps = {
                                stroke: true,
                                weight: 2,
                                color: 'black',
                                opacity: 0.2,
                                fillColor: '#888', // '#2C48A6'
                                fillOpacity: 0.2,
                                zIndex: -10
                            };
                            // console.log("circlProps", circlProps, latLng, radius);
                            L.circle(latLng, radius, circlProps).addTo(map);
                        }
                    </g:if>

                });
            </asset:script>
            %{--<h3><g:message code="show.occurrencemap.title" default="Location of record"/></h3>--}%
            <div id="occurrenceMap" class="google-maps"></div>
        </div>
    </g:if>

    <g:if test="${eventHierarchy}">
        <div id="eventDetailsSideBar" class="well well-sm" style="margin-top: 20px;">
            <h4><g:message code="record.eventdetails.label"/></h4>
            <p>
                <g:message code="record.eventdetails.desc1"/>
                <div>
                    <alatag:renderTree hierarchy="${eventHierarchy}"/>
                </div>
                <g:message code="record.eventdetails.desc2"/>
                <br/>
                <a class="btn-small btn btn-default"
                   style="margin-top:10px;"
                   href="${grailsApplication.config.events.eventUrl}${record.raw.event.eventID}">
                    <g:message code="record.eventdetails.link"/>
                </a>
            </p>
        </div>
    </g:if>

    <g:if test="${record.images}">
        <div class="sidebar">
            <h3 id="images"><g:message code="show.sidebar03.title" default="Images"/></h3>
            <div id="occurrenceImages" style="margin-top:5px;">
                <g:each in="${record.images}" var="image">
                    <div style="margin-bottom:10px;">
                        <g:if test="${grailsApplication.config.getProperty('skin.useAlaImageService', Boolean)}">
                            <a href="${grailsApplication.config.getProperty('images.viewerUrl')}${image.filePath}" target="_blank">
                                <img src="${image.alternativeFormats.smallImageUrl}" style="max-width: 100%;" alt="Click to view this image in a large viewer"/>
                            </a>
                        </g:if>
                        <g:else>
                            <a href="${image.alternativeFormats.largeImageUrl}" target="_blank">
                                <img src="${image.alternativeFormats.smallImageUrl}" style="max-width: 100%;"/>
                            </a>
                        </g:else>
                        <br/>
                        <g:if test="${record.raw.miscProperties?.TITLE}">
                            <cite><b><g:message code="show.sidebar03.image.title" default="Title"/>:</b> <alatag:sanitizeContent>${raw(record.raw.miscProperties.TITLE)}</alatag:sanitizeContent></cite><br/>
                        </g:if>
                        <g:if test="${record.raw.occurrence.photographer || image.metadata?.creator}">
                            <cite><b><g:message code="show.sidebar03.cite01" default="Photographer"/>:</b> ${image.metadata?.creator ?: record.raw.occurrence.photographer}</cite><br/>
                        </g:if>
                        <g:if test="${record.raw.occurrence.rights || image.metadata?.rights}">
                            <cite><b><g:message code="show.sidebar03.cite02" default="Rights"/>:</b> ${image.metadata?.rights ?: record.raw.occurrence.rights}</cite><br/>
                        </g:if>
                        <g:if test="${record.raw.occurrence.rightsholder || image.metadata?.rightsHolder}">
                            <cite><b><g:message code="show.sidebar03.cite03" default="Rights holder"/>:</b> ${image.metadata?.rightsHolder ?: record.raw.occurrence.rightsholder}</cite><br/>
                        </g:if>
                        <g:if test="${record.raw.miscProperties.rightsHolder}">
                            <cite><b><g:message code="show.sidebar03.cite03" default="Rights holder"/>:</b> ${record.raw.miscProperties.rightsHolder}</cite><br/>
                        </g:if>
                        <g:if test="${image.metadata?.license}">
                            <cite><b><g:message code="show.sidebar03.image.license" default="License"/>:</b> ${image.metadata?.license}</cite><br/>
                        </g:if>
                        <g:if test="${record.raw.miscProperties?.DESCRIPTION}">
                                <cite><b><g:message code="show.sidebar03.caption" default="Caption"/>:</b> <alatag:sanitizeContent>${raw(record.raw.miscProperties.DESCRIPTION)}</alatag:sanitizeContent></cite><br/>
                        </g:if>
                        <g:if test="${grailsApplication.config.getProperty('skin.useAlaImageService', Boolean)}">
                            <a href="${grailsApplication.config.getProperty('images.metadataUrl')}${image.filePath}" target="_blank"><g:message code="show.sidebardiv.occurrenceimages.navigator01" default="View image details"/></a>
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
            <div id="occurrenceSounds" style="margin-top:5px;">
                <g:each in="${record.sounds}" var="sound">
                    <div class="row">
                        <div id="audioWrapper" class="col-md-12">
                            <audio src="${sound?.alternativeFormats?.'audio/mpeg'}" preload="auto" />
                            <div class="track-details">
                                ${record.raw.classification.scientificName}
                            </div>
                        </div>
                    </div>
                    <p>
                        <g:message code="show.sidebar04.p" default="Please press the play button to hear the sound file associated with this occurrence record."/>
                    </p>

                    <g:if test="${sound?.metadata?.rights || record.raw.occurrence.rights}">
                        <cite><b><g:message code="show.sidebar04.cite" default="Rights"/>:</b> ${sound?.metadata?.rights ?: record.raw.occurrence.rights}</cite><br/>
                    </g:if>
                    <g:if test="${sound?.metadata?.rightsHolder || record.raw.occurrence.rightsholder}">
                        <cite><b><g:message code="show.sidebar03.cite03" default="Rights holder"/>:</b> ${sound?.metadata?.rightsHolder ?: record.raw.occurrence.rightsholder}</cite><br/>
                    </g:if>

                    <g:if test="${sound?.metadata?.license}">
                        <cite><b><g:message code="show.sidebar03.sound.license" default="License"/>:</b> ${sound?.metadata?.license}</cite><br/>
                    </g:if>

                    <g:if test="${grailsApplication.config.getProperty('skin.useAlaImageService', Boolean) && sound?.alternativeFormats?.detailLink}">
                        <a href="${sound?.alternativeFormats?.detailLink}" target="_blank"><g:message code="show.sidebardiv.occurrencesounds.navigator01" default="View sound details"/></a><br/>
                    </g:if>
                    <br/>
                </g:each>
            </div>
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
                <h3 id="loginOrFlagLabel"><g:message code="show.loginorflag.title" default="Flag an issue"/>
                    <a href="${grailsApplication.config.getProperty('help.flagIssueUrl')}" target="_blank" style="font-size: 14px;margin-left: 10px;">
                        <i class="glyphicon glyphicon-question-sign"></i>
                    </a>
                </h3>
            </div>
            <div class="modal-body">
                <g:if test="${!userId}">
                    <div style="margin: 20px 0;"><g:message code="show.loginorflag.div01.label" default="Login please:"/>
                        <a href="${request.contextPath}/login?path=/occurrences/${record.raw.rowKey}"><g:message code="show.loginorflag.div01.navigator" default="Click here"/></a>
                    </div>
                </g:if>
                 <g:else>
                    <div>
                        <g:message code="show.loginorflag.div02.label" default="You are logged in as"/>  <strong>${userDisplayName} (${alatag.loggedInUserEmail()})</strong>.
                        <form id="issueForm">
                            <p style="margin-top:20px;">
                                <label for="issue"><g:message code="show.issueform.label01" default="Issue type:"/></label>
                                <select name="issue" id="issue" autocomplete="off">
                                    <g:each in="${errorCodes}" var="code">
                                        <option value="${code.code}"><g:message code="${code.name}" default="${code.name}"/></option>
                                    </g:each>
                                </select>
                            </p>
                            <div id="related-record-p" style="display: none; margin-top:30px;">
                                <label for="relatedRecordId" style="vertical-align:top;"><g:message code="show.issueform.label03" default="Duplicate Record ID:"/><span style="color: red;">*</span></label>
                                <input type="text" name="relatedRecordId" id="relatedRecordId" placeholder="Paste the duplicate record id here" style="width:380px;"/>
                                <div class="help-block">
                                    <span style="display: none; color:red;" id="related-record-id-not-found">The record id can't be found.</span>
                                    <span style="display: none;" id="related-record-id-loading"><i class="fa fa-gear fa-spin"></i></span>
                                    <div style="display: none;" id="related-record-id-found">
                                        <span style="display: none;" id="records_comparison_heading"><g:message code="record.compare_table.heading" default="You are indicating that"/>:</span>
                                        <table style="display: none;" id='records_comparison_table' class="table table-bordered table-condensed table-striped scrollTable">
                                            <tr>
                                                <th width="35%"><g:message code="record.compare_table.source_record.heading" default="This record"/></th>
                                                <th rowspan="6" id="col_duplicate_reason"></th>
                                                <th width="35%"><g:message code="record.compare_table.target_record.heading" default="This record ID provided"/></th>
                                            </tr>
                                            <tr>
                                                <td>${record?.processed?.classification?.scientificName ?: record?.raw?.classification?.scientificName ?: ''}</td>
                                                <td id="t_scientificName"></td>
                                            </tr>
                                            <tr>
                                                <td>${record?.processed?.location?.stateProvince ?: record?.raw?.location?.stateProvince ?: ''}</td>
                                                <td id="t_stateProvince"></td>
                                            </tr>
                                            <tr>
                                                <td>${record?.processed?.location?.decimalLongitude ?: record?.raw?.location?.decimalLongitude ?: ''}</td>
                                                <td id="t_decimalLongitude"></td>
                                            </tr>
                                            <tr>
                                                <td>${record?.processed?.location?.decimalLatitude ?: record?.raw?.location?.decimalLatitude ?: ''}</td>
                                                <td id="t_decimalLatitude"></td>
                                            </tr>
                                            <tr>
                                                <td>${record?.processed?.event?.eventDate ?: record?.raw?.event?.eventDate ?: ''}</td>
                                                <td id="t_eventDate"></td>
                                            </tr>
                                        </table>
                                    </div>
                                </div>
                            </div>
                            <p id="related-record-reason-p" style="display: none; margin-top:30px;">
                                <label for="relatedRecordReason" style="vertical-align:top;"><g:message code="show.issueform.label04" default="Duplicate Reason:"/><span style="color: red;">*</span></label>
                                <select name="relatedRecordReason" id="relatedRecordReason" autocomplete="off">
                                    <option value=""><g:message code="related.record.reason.select" default="-- Select a reason --" /></option>
                                    <option value="sameoccurrence"><g:message code="related.record.reason.sameoccurrence" default="Duplicate occurrence"/></option>
                                    <option value="tissuesample"><g:message code="related.record.reason.tissuesample" default="Tissue sample"/></option>
                                    <option value="splitspecimen"><g:message code="related.record.reason.splitspecimen" default="Split specimen"/></option>
                                </select>
                            </p>
                            <p style="margin-top:30px;">
                                <label for="issueComment" style="vertical-align:top;"><g:message code="show.issueform.label02" default="Comment:"/></label>
                                <textarea name="comment" id="issueComment" style="width:380px;height:150px;" placeholder="Please add a comment here..."></textarea>
                            </p>

                            <g:if test="${grailsApplication.config.getProperty('alerts.myannotation.enabled', Boolean)}">
                                <p style="margin-top:30px;">
                                    <label style="width:100%" id="notifyChange"><input type="checkbox" id="notifyChangeCheckbox" name="notifyChange" value="" checked>&nbsp;<g:message code="show.issueform.notifyme" default="Notify me when records I have annotated are updated"/></label>
                                </p>
                            </g:if>

                            <p style="margin-top:20px;">
                                <input id="issueFormSubmit" type="submit" value="<g:message code="show.issueform.button.submit" default="Submit"/>" class="btn btn-primary" />
                                <input type="button" id="cancel" value="<g:message code="show.issueform.button.cancel" default="Cancel"/>" class="btn btn-default" onClick="$('#loginOrFlag').modal('hide');"/>
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
