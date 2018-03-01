<%-- 
    Document   : downloadDiv
    Created on : Feb 25, 2011, 4:20:32 PM
    Author     : "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
--%>
<!-- download modal form - used for old style downloads -->
<g:set var="biocacheServiceUrl" value="${alatag.getBiocacheAjaxUrl()}"/>

<div id="downloadModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="downloadModalLabel">
    <div class="modal-dialog" role="document">
        <div class="modal-content" style="padding:30px;">
            <form id="downloadForm" class="form-horizontal" role="form">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                    <h3 id="downloadsLabel"><g:message code="download.download.title" default="Downloads"/></h3>
                </div>
                <div class="modal-body">
                    <p id="termsOfUseDownload">
                        <g:message code="download.termsofusedownload.01" default="By downloading this content you are agreeing to use it in accordance with the Atlas of Living Australia"/>
                        <a href="http://www.ala.org.au/about/terms-of-use/#TOUusingcontent"><g:message code="download.termsofusedownload.02" default="Terms of Use"/></a>
                        <g:message code="download.termsofusedownload.03" default="and any Data Provider Terms associated with the data download."/>
                        <br/><br/>
                        <g:message code="download.termsofusedownload.04" default="Please provide the following details before downloading (* required)"/>:
                    </p>
                    <div class="form-group">
                        <label for="email"><g:message code="download.downloadform.label01" default="Email"/></label>
                        <input type="text" class="form-control" name="email" id="email" value="${request.remoteUser}" size="30"  />
                    </div>
                    <div class="form-group">
                        <label for="filename"><g:message code="download.downloadform.label02" default="Filename"/></label>
                        <input type="text" class="form-control" name="filename" id="filename" value="data" size="30"  />
                    </div>
                    <div class="form-group">
                        <label for="reasonTypeId"><g:message code="download.downloadform.label03" default="Download reason"/> *</label>
                        <select name="reasonTypeId" id="reasonTypeId" class="form-control">
                            <option value="">-- <g:message code="download.downloadformreasontypeid.option" default="select a reason"/> --</option>
                            <g:each var="it" in="${alatag.getLoggerReasons()}">
                                <option value="${it.id}">${it.name}</option>
                            </g:each>
                        </select>
                    </div>
                    <div class="form-group">
                        %{--<label for="filename" style="float: left;"><g:message code="download.downloadform.label04" default="Download type"/></label>--}%
                        <div class="form-check">
                            <input type="radio" class="form-check-input" name="downloadType" id="downloadTypeRecords" value="fast" class="tooltips" title="Download the occurrence records" checked="checked"/>
                            <label class="form-check-label" for="downloadTypeRecords">
                                <g:message code="download.downloadform.radio01" default="All Records"/>
                            </label>
                        </div>
                        <div class="form-check">
                            <input type="radio" class="form-check-input" name="downloadType" id="downloadTypeChecklist" value="checklist"  class="tooltips" title="Lists all species from the current search results"/>
                            <label class="form-check-label" for="downloadTypeChecklist">
                                <g:message code="download.downloadform.radio02" default="Species Checklist"/>
                            </label>
                        </div>
                    </div>

                    <div>
                        <input type="submit" value="<g:message code="download.downloadform.button.submit" default="Start Download"/>" id="downloadStart" class="row btn-default tooltips"/>
                    </div>
                    <div id="statusMsg" style="text-align: center; font-weight: bold; "></div>
                    <input type="hidden" name="searchParams" id="searchParams" value="${sr?.urlParameters}"/>
                    <g:if test="${clubView}">
                        <input type="hidden" name="url" id="downloadUrl" value="${request.contextPath}/proxy/download/download"/>
                        <input type="hidden" name="url" id="fastDownloadUrl" value="${request.contextPath}/proxy/download/index/download"/>
                    </g:if>
                    <g:else>
                        <input type="hidden" name="url" id="downloadUrl" value="${biocacheServiceUrl}/occurrences/download"/>
                        <input type="hidden" name="url" id="fastDownloadUrl" value="${biocacheServiceUrl}/occurrences/index/download"/>
                    </g:else>

                    <input type="hidden" name="url" id="downloadChecklistUrl" value="${biocacheServiceUrl}/occurrences/facets/download"/>
                    <input type="hidden" name="url" id="downloadFieldGuideUrl" value="${request.contextPath}/occurrences/fieldguide/download"/>
                    <input type="hidden" name="extra" id="extraFields" value="${grailsApplication.config.biocache.downloads.extra}"/>
                    <input type="hidden" name="sourceTypeId" id="sourceTypeId" value="${alatag.getSourceId()}"/>
                </div>
                <div class="modal-footer">
                </div>
            </form>
        </div>
    </div>
</div>

<asset:script type="text/javascript">
    $(document).ready(function() {
        // catch download submit button
        // Note the unbind().bind() syntax - due to Jquery ready being inside <body> tag.

        // start download button
        $(":input#downloadStart").unbind("click").bind("click",function(e) {
            e.preventDefault();
            var downloadType = $('input:radio[name=downloadType]:checked').val();

            if (validateForm()) {
                if (downloadType == "fast") {
                    var downloadUrl = generateDownloadPrefix($(":input#fastDownloadUrl").val())+"&email="+$("#email").val()+"&sourceTypeId="+$("#sourceTypeId").val()+"&reasonTypeId="+
                            $("#reasonTypeId").val()+"&file="+$("#filename").val()+"&extra="+$(":input#extraFields").val();
                    //alert("downloadUrl = " + downloadUrl);
                    window.location.href = downloadUrl;
                    notifyDownloadStarted();
                } else if (downloadType == "detailed") {
                    var downloadUrl = generateDownloadPrefix($(":input#downloadUrl").val())+"&email="+$("#email").val()+"&sourceTypeId="+$("#sourceTypeId").val()+"&reasonTypeId="+
                            $("#reasonTypeId").val()+"&file="+$("#filename").val()+"&extra="+$(":input#extraFields").val();
                    //alert("downloadUrl = " + downloadUrl);
                    window.location.href = downloadUrl;
                    notifyDownloadStarted();
                } else if (downloadType == "checklist") {
                    var downloadUrl = generateDownloadPrefix($("input#downloadChecklistUrl").val())+"&facets=species_guid&lookup=true&file="+
                            $("#filename").val()+"&sourceTypeId="+$("#sourceTypeId").val()+"&reasonTypeId="+$("#reasonTypeId").val();
                    //alert("downloadUrl = " + downloadUrl);
                    window.location.href = downloadUrl;
                    notifyDownloadStarted();
                } else if (downloadType == "fieldGuide") {
                    var downloadUrl = generateDownloadPrefix($("input#downloadFieldGuideUrl").val())+"&facets=species_guid"+"&sourceTypeId="+
                            $("#sourceTypeId").val()+"&reasonTypeId="+$("#reasonTypeId").val();
                    window.open(downloadUrl);
                    notifyDownloadStarted();
                } else {
                    alert("download type not recognised");
                }
            }
        });
    });

    function generateDownloadPrefix(downloadUrlPrefix) {
        downloadUrlPrefix = downloadUrlPrefix.replace(/\\ /g, " ");
        var searchParams = $(":input#searchParams").val();
        if (searchParams) {
            downloadUrlPrefix += searchParams;
        } else {
            // EYA page is JS driven
            downloadUrlPrefix += "?q=*:*&lat="+$('#latitude').val()+"&lon="+$('#longitude').val()+"&radius="+$('#radius').val();
            if (speciesGroup && speciesGroup != "ALL_SPECIES") {
                downloadUrlPrefix += "&fq=species_group:" + speciesGroup;
            }
        }
        return downloadUrlPrefix;
    }

    function notifyDownloadStarted() {
        $("#statusMsg").html("Download has commenced");
        window.setTimeout(function() {
            $("#statusMsg").html("");
            $('#download').modal('hide');
        }, 2000);
    }

    function validateForm() {
        var isValid = false;
        var reasonId = $("#reasonTypeId option:selected").val();

        if (reasonId) {
            isValid = true;
        } else {
            $("#reasonTypeId").focus();
            $("label[for='reasonTypeId']").css("color","red");
            alert("Please select a \"download reason\" from the drop-down list");
        }

        return isValid;
    }
</asset:script>
