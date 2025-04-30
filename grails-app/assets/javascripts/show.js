/*
 * // require jquery
//= require jquery_i18n
//= require audiojs/audio.js
//= require charts2.js
//= require wms2.js
//= require amplify.js
//= require moment.min.js
//= require linkifyjs/linkify.js
//= require linkifyjs/linkify-jquery.js
//= require leaflet/leaflet.js
//= require leaflet-plugins/layer/tile/Google.js
//= require_self
 */
/**
 * JQuery on document ready callback
 */

function updatei18n() {
    $('.i8nupdate').each(function() {
        var key = $(this).attr('i18nkey')
        if (key !== undefined) {
            $(this).text(jQuery.i18n.prop(key));
        }
    });
}

$(document).ready(function() {
    if (typeof BC_CONF != 'undefined' && BC_CONF.hasOwnProperty('contextPath')) {
        jQuery.i18n.properties({
            name: 'messages',
            path: BC_CONF.contextPath + '/messages/i18n/',
            mode: 'map',
            async: true,
            cache: true,
            language: BC_CONF.locale // default is to use browser specified locale
        });
    }

    // jQuery.i18n.properties is required now, wait a bit
    setTimeout(function () {
        init()
    }, 50)

}); // end JQuery document ready

function init() {
    // check for i18n
    var i = 0;
    $.each(jQuery.i18n.map, function() { i++ });
    if (i < 100) {  // wait for at least 100 elements in this map
        // wait longer for i18n
        setTimeout(function () {
            init()
        }, 50)
        return
    }

    leafletI18n();

    $('#showUncheckedTests').on('click', function(e){
        $('.uncheckTestResult').toggle();
    });

    $('#showPassedPropResult').on('click', function(e){
        $('.passedPropResult').toggle();
    });

    $('#showMissingPropResult').on('click', function(e){
        $('.missingPropResult').toggle();
    });

    $('#copyRecordIdToClipboard').on('click', function(e) {
        var copyText = document.querySelector("#hidden-uuid");
        copyText.type = 'text';
        copyText.select();
        document.execCommand("copy");
        copyText.type = 'hidden';
        var $parent = $('#copyRecordIdToClipboard-parent');
        $parent.tooltip('show');
        setTimeout(function() {
            $parent.tooltip('hide');
        }, 1000);
        // alert("Copied");
    });
    var recordIdValid = false;
    function validateIssueForm() {
        var issueCode = $('#issue').val();
        var relatedRecordReason = $('#relatedRecordReason').val();
        if (issueCode == '20020') {
            return recordIdValid && relatedRecordReason;
        }
        return true;
    }
    function setIssueFormButtonState() {
        $('#issueForm input[type=submit]').prop('disabled', !validateIssueForm());
    }
    $('#issue').on('change', function(e) {
        var $this = $(this);
        var val = $this.val();
        var $submit = $('#issueForm input[type=submit]');
        var $p = $('#related-record-p, #related-record-reason-p');
        // if duplicate record
        if (val === '20020') {
            $('#relatedRecordId').val('');
            recordIdValid = false;
            $p.show();
        } else {
            $p.hide();
            $('#related-record-id-not-found').hide();
            $('#related-record-id-found').hide();
            $('#related-record-id-loading').hide();
            // hide the records table
            $('#records_comparison_table').hide();
            $('#records_comparison_heading').hide();
        }
        setIssueFormButtonState();
    });

    $('#relatedRecordReason').on('change', function(e) {
        var col_reason = $('#col_duplicate_reason');
        var relatedRecordReason = $('#relatedRecordReason').val();
        if (relatedRecordReason === '') {
            $(col_reason).text('');
        } else {
            $(col_reason).text(jQuery.i18n.prop('related.record.reason.description.' + relatedRecordReason));
        }
        setIssueFormButtonState();
    })

    $('#relatedRecordId').on('change', function(e) {
        var $this = $(this);
        var $submit = $('#issueForm input[type=submit]');
        var val = $this.val().trim();
        if (val === OCC_REC.recordUuid) {
            alert("You can't mark this record as a duplicate of itself!");
            recordIdValid = false;
        } else if (val === '') {
            $('#related-record-id-not-found').hide();
            $('#related-record-id-found').hide();
            $('#related-record-id-loading').hide();
            $('#records_comparison_table').hide();
            $('#records_comparison_heading').hide();
            $('#relatedRecordReason').val("");
            $('#col_duplicate_reason').text('');
            recordIdValid = false;
        } else {
            $('#related-record-id-loading').show();
            $.get( OCC_REC.contextPath + "/occurrence/exists/" + val).success(function(data) {
                $('#related-record-id-loading').hide();
                if (data.error) {
                    // show error
                    $('#related-record-id-not-found').text('More than 1 record found with specified id, please use a more specific id').show();
                    // hide compare table
                    $('#records_comparison_heading').hide();
                    $('#records_comparison_table').hide();
                    recordIdValid = false;
                } else {
                    // hide error
                    $('#related-record-id-not-found').hide();
                    // show compare table
                    $('#related-record-id-found').show();
                    $('#records_comparison_table').show();
                    $('#records_comparison_heading').show();
                    // populate the table
                    $('#t_scientificName').text(data.scientificName ? data.scientificName : '');
                    $('#t_stateProvince').text(data.stateProvince ? data.stateProvince : '');
                    $('#t_decimalLongitude').text(data.decimalLongitude ? data.decimalLongitude : '');
                    $('#t_decimalLatitude').text(data.decimalLatitude ? data.decimalLatitude : '');
                    $('#t_eventDate').text(data.eventDate ? data.eventDate : '');
                    recordIdValid = true;
                }
            }).error(function () {
                $('#related-record-id-not-found').text("The record id can't be found.").show();
                $('#related-record-id-found').hide();
                $('#related-record-id-loading').hide();
                $('#records_comparison_table').hide();
                $('#records_comparison_heading').hide();
                $('#relatedRecordReason').val("");
                $('#col_duplicate_reason').text('');
            }).always(function() {
                setIssueFormButtonState();
            });
        }
        setIssueFormButtonState();
    });

    refreshUserAnnotations();

    // bind to form submit for assertions
    $("form#issueForm").submit(function(e) {
        e.preventDefault();
        var comment = $("#issueComment").val();
        var code = $("#issue").val();
        var relatedRecordId = $('#relatedRecordId').val();
        var relatedRecordReason = $('#relatedRecordReason').val();
        var userDisplayName = OCC_REC.userDisplayName //'${userDisplayName}';
        var recordUuid = OCC_REC.recordUuid //'${ala:escapeJS(record.raw.rowKey)}';
        var assertionId = $('#assertionId').val();
        if(code!=""){
            $('#assertionSubmitProgress').css({'display':'block'});

            $.get( OCC_REC.contextPath + "/assertions/" + OCC_REC.recordUuid, function(data) {
                var bPreventAddingIssue = false;
                for (var i = 0; i < data.userAssertions.length; i++) {
                    if (data.userAssertions[i].code == 50000) {
                        data.userAssertions.forEach(function (element) {
                            if (element.uuid == data.userAssertions[i].relatedUuid && element.code == code) {
                                bPreventAddingIssue = true;
                            }
                        })
                    }
                }

                if (bPreventAddingIssue) {
                    alert("You cannot flag an issue with the same type that has already been verified.");
                    return;
                } else if (code == '20020' && !relatedRecordId) {
                    alert("You must provide a duplicate record id to mark this as a duplicate");
                    return;
                } else if (code == '20020' && !relatedRecordReason) {
                    alert("You must select a reason to mark this record as a duplicate");
                    return;
                } else if (code == '20020' && relatedRecordId == recordUuid) {
                    alert("You can't mark a record as a duplicate of itself");
                    return;
                } else {
                    $.post(OCC_REC.contextPath + "/occurrences/assertions/add",
                        {
                            recordUuid: recordUuid,
                            code: code,
                            comment: comment,
                            userAssertionStatus: 'Open issue',
                            userId: OCC_REC.userId,
                            userDisplayName: userDisplayName,
                            relatedRecordId: relatedRecordId,
                            relatedRecordReason: relatedRecordReason,
                            updateId: assertionId
                        },
                        function (data) {
                            // when add assertion succeeds, we update alert settings (only when myannotation is enabled)
                            if (OCC_REC.myAnnotationEnabled) {
                                var new_state = $('#notifyChangeCheckbox').prop('checked');
                                var actionpath = new_state ? "/api/subscribeMyAnnotation" : "/api/unsubscribeMyAnnotation";
                                $.post(OCC_REC.contextPath + actionpath);
                            }

                            $('#assertionSubmitProgress').css({'display': 'none'});
                            $("#submitSuccess").html("Thanks for flagging the problem!");
                            $("#issueFormSubmit").hide();
                            $("input#cancel").hide();
                            $("input#close").show();
                            //retrieve all assertions
                            $.get(OCC_REC.contextPath + '/assertions/' + OCC_REC.recordUuid, function (data) { // recordUuid=${record.raw.uuid}
                                //console.log("data", data);
                                $('#userAssertions').html(data);
                                $('#userAssertionsContainer').show("slow");
                            });
                            refreshUserAnnotations();
                            //document.location.reload(true);
                        }
                    ).error(function () {
                        $('#assertionSubmitProgress').css({'display': 'none'});
                        $("#submitSuccess").html(jQuery.i18n.prop('show.issueform.flagfail.message'));
                    });
                }

            });

        } else {
            alert("Please supply a issue type");
        }
    });

    $(".userAssertionComment").each(function(i, el) {
        var html = $(el).html();
        $(el).html(replaceURLWithHTMLLinks(html)); // convert it
    });

    $('#assertionButton').click(function (e) {
        // if myannotation enabled, to retrieve current settings
        if (OCC_REC.myAnnotationEnabled) {
            // by default off
            $("#notifyChangeCheckbox").prop('checked', false);
            var getAlerts = OCC_REC.contextPath + "/api/alerts";
            $.getJSON(getAlerts, function (data) {
                var myAnnotationEnabled =  data && data.myannotation && data.myannotation.length > 0;
                $("#notifyChangeCheckbox").prop('checked', myAnnotationEnabled);
            })
        }
    })

    // bind to form "close" button TODO
    $("input#close").on("click", function(e) {
        // close the popup
        //    $.fancybox.close();
        // reset form back to default state
        $('form#issueForm')[0].reset();
        $("#submitSuccess").html("");
        $("#issueFormSubmit").show("slow");
        $("input:reset").show("slow");
        $("input#close").hide("slow");
        $('#loginOrFlag').modal('hide');
        document.location.reload(true);
    });

    // convert camel case field names to "normal"
    $("td.dwc, span.dwc").each(function(i, el) {
        var html = $(el).html();
        $(el).html(fileCase(html)); // conver it
    });

    //    // load a JS map with sensitiveDatasets values from hubs.properties file
    //    var sensitiveDatasets = {
    //    <c:forEach var="sds" items="${sensitiveDatasets}" varStatus="s">
    //    ${sds}: '<ala:propertyLoader checkSupplied="true" bundle="hubs" property="sensitiveDatasets.${sds}"/>'<c:if test="${not s.last}">,</c:if>
    //    </c:forEach>
    //}
    var sensitiveDatasets = OCC_REC.sensitiveDatasets;

    // add links for dataGeneralizations pages in collectory
    $("span.dataGeneralizations").each(function(i, el) {
        var field = $(this);
        var text = $(this).text().match(/\[.*?\]/g);

        if (text) {
            $.each(text, function(j, el) {
                var list = el.replace(/\[.*,(.*)\]/, "$1").trim();
                var code = list.replace(/\s/g, "_").toUpperCase();

                if (sensitiveDatasets[code]) {
                    var linked = "<a href='" + sensitiveDatasets[code] + "' title='" + list
                        + " sensitive species list information page' target='collectory'>" + list + "</a>";
                    var regex = new RegExp(list, "g");
                    var html = $(field).html().replace(regex, linked);
                    $(field).html(html);
                }
            });
        }
    });

    $("#backBtn a").click(function(e) {
        e.preventDefault();
        var url = $(this).attr("href");
        if (url) {
            // referer value from request object
            window.location.href = url;
        } else if (history.length) {
            //There is history to go back to
            history.go(-1);
        } else {
            alert("Sorry it appears the history has been lost, please use the browser&apso;s back button");
        }
    });

    var sequenceTd = $("tr#nucleotides").find("td.value");
    var sequenceStr = sequenceTd.text().trim();
    if (sequenceStr.length > 10) {
        // split long DNA sequences into blocks of 10 chars
        $(sequenceTd).html("<code>"+sequenceStr.replace(/(.{10})/g,"$1 ")+"</code>");
    }

    // context sensitive help on data quality tests
    $(".dataQualityHelpLinkZZZ").click(function(e) {
        e.preventDefault();
        $("#dataQualityModal .modal-body").html(""); // clear content
        var code = $(this).data("code");
        var dataQualityItem = getDataQualityItem(code);
        var content = "Error: info not found";
        if (dataQualityItem) {
            content = "<div><b>Name: " + dataQualityItem.name + "</b></div>";
            content += "<div>" + dataQualityItem.description + "</div>";
            content += "<div><a href='https://github.com/AtlasOfLivingAustralia/ala-dataquality/wiki/" +
                dataQualityItem.name + "' target='wiki' title='More details on the wiki page'>Wiki page</a></div>";
        }

        //$("#dataQualityModal .modal-body").html(content);
        //$('#dataQualityModal').modal({show:true});
        $(this).popover({
            html : true,
            content: function() {
                return content;
            }
        });
    });

    $(".dataQualityHelpLinkZZ").popover({
        html : true,
        content: "Just a test"
    }).click('click', function(e) { e.preventDefault(); });

    // add BS tooltip to elements with class "tooltips"
    $(".tooltips").tooltip( {
        trigger: "hover",
        delay: { "show": 100, "hide": 1000 }
    });

    $(".dataQualityHelpLink").popover({
        html : true,
        trigger: "click",
        title: function() {
            var code = $(this).data("code");
            var content = "";
            var dataQualityItem = getDataQualityItem(code);
            if (dataQualityItem) {
                content = "<button type='button' class='close' onclick='$(&quot;.dataQualityHelpLink&quot;).popover(&quot;hide&quot;);'>×</button>" + dataQualityItem.name;
            }
            return content;
        },
        content: function() {
            var code = $(this).data("code");
            var dataQualityItem = getDataQualityItem(code);
            var content = "Error: info not found";
            if (dataQualityItem) {
                //content = "<div><b>" + dataQualityItem.name + "</b></div>";
                content = "<div>" + dataQualityItem.description + "</div>";
                if (dataQualityItem.wiki) {
                    content += "<div><i class='glyphicon glyphicon-share-alt'></i>&nbsp;<a href='https://github.com/AtlasOfLivingAustralia/ala-dataquality/wiki/" +
                        dataQualityItem.name + "' target='wiki' title='More details on the wiki page'>Wiki page</a></div>";
                }
            }
            return content;
        }
    }).click('click', function(e) { e.preventDefault(); });

    // Activate the "back to search results" button at top of page
    var lastSearch = amplify.store('lastSearch');
    //console.log('lastSearch', lastSearch);
    if (lastSearch) {
        var getUrl = window.location;
        var baseUrl = getUrl .protocol + "//" + getUrl.host;
        var lastSearchURL = new URL(lastSearch, baseUrl);
        lastSearchURL.searchParams.set('offset', OCC_REC.searchOffset);
        $('#backBtn > a').attr('href', lastSearchURL.toString());
        $('#backBtn').show();
    }

    // hide any DwC sections that are empty
    $('.occurrenceTable').each(function(i, el) {
        if (!$(el).find('tr').length) {
            // hide section
            $(el).parent().hide();
            // hide ToC entry
            var parentId = $(el).parent().attr('id').replace('Table','');
            $('a[href="#' + parentId + '"]').hide();
        }
    });

    // Copied from list.js TODO: consolidate into common JS code
    $('#copy-al4r').on('click', function() {
        var input = document.querySelector('#al4rcode');
        if (navigator.clipboard && window.isSecureContext) {
            // navigator clipboard api method'
            navigator.clipboard.writeText(input.value)

                .then(() => { alert(jQuery.i18n.prop('list.copylinks.tooltip.copied')) })
                .catch((error) => { alert(jQuery.i18n.prop('list.copylinks.alert.failed') + error) })
        } else {
            alert("Copying to clipboard requires a secure HTTPS connection. Value: " + input.value);
        }

    });

    $('#issueFormSubmit').click(function(event) {
        var comment = $('#issueComment').val().trim();
        if (comment === '') {
            event.preventDefault();

            $('#issueComment').css('border', '2px solid red');

            alert(jQuery.i18n.prop('show.issueform.label02.mandatory'));
        } else {
            $('#issueComment').css('border', '');
        }
    });

    $('#loginOrFlag').on('show.bs.modal', function (event) {
        var editMode = $('#editMode').val();
        if (editMode === 'true') {
            // alter form for edit mode
            $('#loginOrFlag').find('#loginOrFlagLabel').text(jQuery.i18n.prop('show.loginorflag.title.edit'));
            $('#loginOrFlag').find('#issue').prop('disabled', true);

            // the assertionId, issue code and comment are set elsewhere
        } else {
            // reset form to default state for creating a new issue, probably not required as the page does a reload
            $('#loginOrFlag').find('#loginOrFlagLabel').text(jQuery.i18n.prop('show.loginorflag.title'));
            $('#loginOrFlag').find('#issue').prop('disabled', false);

            var code = $('#loginOrFlag').find('#issue').children().first().val();
            $('#loginOrFlag').find('#issue').val(code);
            $('#loginOrFlag').find('#issueComment').val("");
            $('#loginOrFlag').find('#assertionId').val("");
        }
    });

}

/**
 * Delete a user assertion
 */
function deleteAssertion(recordUuid, assertionUuid){
    $.post(OCC_REC.contextPath + '/occurrences/assertions/delete',
        { recordUuid: recordUuid, assertionUuid: assertionUuid },
        function(data) {
            refreshUserAnnotations();
        }
    );
}

/**
 * Convert camel case text to pretty version (all lower case)
 */
function fileCase(str) {
    return str.replace(/([a-z])([A-Z])/g, "$1 $2").toLowerCase().capitalize();
}

function compareModifiedDate(a,b) {
    if (moment(a.created).isBefore(b.created)) {
        return -1;
    } else if (moment(a.created).isAfter(b.created)) {
        return 1;
    } else {
        return 0;
    }
}

function getMessage(userAssertionCode) {
    return "${message(code:show.userAssertionStatus." + userAssertionCode+ ")}";
}

/**
 * Load and display the assertions for this record
 */
function refreshUserAnnotations(){

    $.get( OCC_REC.contextPath + "/assertions/" + OCC_REC.recordUuid, function(data) {
        if (data.assertionQueries.length == 0 && data.userAssertions.length == 0) {
            $('#userAnnotationsDiv').hide('slow');
            $('#userAssertionsContainer').hide("slow");
            $('#userAnnotationsNav').css("display","none");
        } else {
            $('#userAnnotationsDiv').show('slow');
            $('#userAssertionsContainer').show("slow");
            $('#userAnnotationsNav').css("display","block");
        }
        $('#userAnnotationsList').empty();

        for(var i=0; i < data.assertionQueries.length; i++){
            var $clone = $('#userAnnotationTemplate').clone();
            $clone.find('.issue').text(data.assertionQueries[i].assertionType);
            $clone.find('.user').text(data.assertionQueries[i].userName);
            if (data.assertionQueries[i].hasOwnProperty('comment')) {
                $clone.find('.comment').text('Comment: ' + data.assertionQueries[i].comment);
            }
            $clone.find('.created').text('Date created: ' + (moment(data.assertionQueries[i].createdDate).format('YYYY-MM-DD')));
            if(data.assertionQueries[i].recordCount > 1){
                $clone.find('.viewMore').css({display:'block'});
                $clone.find('.viewMoreLink').attr('href', OCC_REC.contextPath + '/occurrences/search?q=query_assertion_uuid:' + data.assertionQueries[i].uuid);
            }
            $('#userAnnotationsList').append($clone);
            $('#userAssertionsContainer').show("slow");
        }

        var verifiedAssertions = [];
        var disableDelete = [];
        var enableDelete = [];

        $.each(data.userAssertions, function( index, userAssertion ) {

            var $clone = $('#userAnnotationTemplate').clone();

            // if the code == 50000, then we have verification - so don't display here
            if (userAssertion.code != 50000) {
                $clone.prop('id', "userAnnotation_" + userAssertion.uuid);
                $clone.find('.issue').text(jQuery.i18n.prop(userAssertion.name)).attr('i18nkey', userAssertion.name);
                $clone.find('.issueCode').text(userAssertion.code);
                $clone.find('.issueComment').text(userAssertion.comment);
                $clone.find('.user').text(userAssertion.userDisplayName);
                if (userAssertion.hasOwnProperty('comment')) {
                    $clone.find('.comment').text('Comment: ' + userAssertion.comment);
                }
                $clone.find('.userRole').text(userAssertion.userRole != null ? userAssertion.userRole : '');
                $clone.find('.userEntity').text(userAssertion.userEntityName != null ? userAssertion.userEntityName : '');
                $clone.find('.created').text('Date created: ' + (moment(userAssertion.created, "YYYY-MM-DDTHH:mm:ssZ").format('YYYY-MM-DD HH:mm:ss')));
                if (userAssertion.relatedRecordId) {
                    $clone.find('.related-record').show();
                    // show related record id
                    $clone.find('.related-record-id').show();
                    $clone.find('.related-record-id-span').text(userAssertion.relatedRecordId);
                    var href = $clone.find('.related-record-link').attr('href');
                    $clone.find('.related-record-link').attr('href', href.replace('replace-me', userAssertion.relatedRecordId));
                    if (userAssertion.code === 20020) {
                        $clone.find('.related-record-span-user-duplicate').show();

                        $.get( OCC_REC.contextPath + "/occurrence/exists/" + userAssertion.relatedRecordId).success(function(data) {
                            if (!data.error) {
                                if (data.scientificName) {
                                    $clone.find('.related-record-name').show();
                                    $clone.find('.related-record-name-span').text(data.scientificName);
                                }

                                if (data.stateProvince) {
                                    $clone.find('.related-record-state').show();
                                    $clone.find('.related-record-state-span').text(data.stateProvince);
                                }

                                if (data.decimalLongitude) {
                                    $clone.find('.related-record-latitude').show();
                                    $clone.find('.related-record-latitude-span').text(data.decimalLongitude);
                                }

                                if (data.decimalLatitude) {
                                    $clone.find('.related-record-longitude').show();
                                    $clone.find('.related-record-longitude-span').text(data.decimalLatitude);
                                }

                                if (data.eventDate) {
                                    $clone.find('.related-record-eventdate').show();
                                    $clone.find('.related-record-eventdate-span').text(data.eventDate);
                                }
                            }
                        })
                    } else {
                        $clone.find('.related-record-span-default').show();
                    }
                }
                if (userAssertion.relatedRecordReason) {
                    $clone.find('.related-record-reason').show();
                    $clone.find('.related-record-reason-span').text(jQuery.i18n.prop('related.record.reason.' + userAssertion.relatedRecordReason)).attr('i18nkey', 'related.record.reason.' + userAssertion.relatedRecordReason);
                    $clone.find('.related-record-reason-explanation').text(jQuery.i18n.prop('related.record.reason.explanation.' + userAssertion.relatedRecordReason)).attr('i18nkey', 'related.record.reason.explanation.' + userAssertion.relatedRecordReason).show();
                }
                if (userAssertion.userRole != null) {
                    $clone.find('.userRole').text(', ' + userAssertion.userRole);
                }
                if (userAssertion.userEntityName != null) {
                    $clone.find('.userEntity').text(', ' + userAssertion.userEntityName);
                }

                //if the current user is the author of the annotation, they can delete and edit
                if(OCC_REC.userId == userAssertion.userId){
                    $clone.find('.deleteAnnotation').css({display:'block'});
                    $clone.find('.deleteAnnotation').attr('id', userAssertion.uuid);
                } else {
                    $clone.find('.deleteAnnotation').css({display:'none'});
                }

                //display the verification button,
                $clone.find('.verifyAnnotation').css({display:'block'});
                $clone.find('.verifyAnnotation').attr('id', "verifyAnnotations_" +userAssertion.uuid);

                $clone.find(".verifications").hide();

                $('#userAnnotationsList').append($clone);
            } else {
                //this is a verification assertion, so it needs to be embedded in existing assertion
                verifiedAssertions.push(userAssertion);
                // if an assertion has a verification, disable the delete button
                if (disableDelete.indexOf(userAssertion.relatedUuid) < 0) {
                    disableDelete.push(userAssertion.relatedUuid);
                }
            }
        });

        //display verified
        var sortedVerifiedAssertion = verifiedAssertions.sort(compareModifiedDate);
        for(var i = 0; i < sortedVerifiedAssertion.length; i++){

            var $clone = $('#userVerificationTemplate').clone();
            $clone.prop('id', "userVerificationAnnotation_" + sortedVerifiedAssertion[i].uuid);
            var qaStatusMessage = jQuery.i18n.prop("user_assertions." + sortedVerifiedAssertion[i].qaStatus);
            $clone.find('.qaStatus').text(qaStatusMessage).attr('i18nkey', "user_assertions." + sortedVerifiedAssertion[i].qaStatus);
            $clone.find('.comment').text(sortedVerifiedAssertion[i].comment);
            $clone.find('.userDisplayName').text(sortedVerifiedAssertion[i].userDisplayName);
            $clone.find('.created').text((moment(sortedVerifiedAssertion[i].created, "YYYY-MM-DDTHH:mm:ssZ").format('YYYY-MM-DD HH:mm:ss')));

            //add the verification, and show the table
            $('#userAnnotationsList').find('#userAnnotation_' + sortedVerifiedAssertion[i].relatedUuid + " table.verifications tbody").append($clone);
            $('#userAnnotationsList').find('#userAnnotation_' + sortedVerifiedAssertion[i].relatedUuid + " table.verifications").show();
            updateDeleteVerificationEvents(sortedVerifiedAssertion[i].relatedUuid)
        }

        for(var i = 0; i < disableDelete.length; i++) {
            var $cloneHeader = $('#userVerificationTemplate').clone();
            $cloneHeader.prop('id', "userVerificationAnnotationHeader_" + disableDelete[i]);
            $cloneHeader.find('.qaStatus').text("User Verification Status");
            $cloneHeader.find('.comment').text("Comment");
            $cloneHeader.find('.userDisplayName').text("Verified By");
            $cloneHeader.find('.created').text("Created");
            $cloneHeader.find('.deleteVerification').html('Delete this Verification');
            $cloneHeader.css({display: 'block'});
            ($cloneHeader).insertAfter('#userAnnotation_' + disableDelete[i] + ' .userVerificationClass .userVerificationTemplate:first')
        }

        for(var i = 0; i < data.userAssertions.length; i++){
            if ((data.userAssertions[i].code != 50000) && (disableDelete.indexOf(data.userAssertions[i].uuid) < 0)) {
                enableDelete.push (data.userAssertions[i].uuid);
            }
        }

        updateEditDeleteEvents(enableDelete, disableDelete);
    });
}

function updateDeleteVerificationEvents(relatedAssertionId) {
    $('#userAnnotation_' + relatedAssertionId + ' .deleteVerificationButton').off("click");
    $('#userAnnotation_' + relatedAssertionId + ' .deleteVerificationButton').on("click", function (e) {
        e.preventDefault();
        var isConfirmed = confirm('Are you sure you want to delete this verification ?');
        if (isConfirmed === true) {
            deleteAssertion(OCC_REC.recordUuid, this.parentElement.parentElement.id.split('_').pop());
        }
    });

    $('#userAnnotation_' + relatedAssertionId + ' .editVerificationButton').off("click");
    $('#userAnnotation_' + relatedAssertionId + ' .editVerificationButton').on("click", function (e) {
        e.preventDefault();

        var element = $(this.parentElement.parentElement);

        // reset the form on open
        var assertionId = this.parentElement.parentElement.id.split('_').pop();
        var code = element.find('.qaStatus').attr('i18nkey').split('.').pop();
        var comment = element.find('.comment').text();
        $("#verifyComment").val(comment);
        $("#userAssertionStatusSelection").val(code);
        $(".verifyAsk").show();
        $(".verifyDone").hide();
        $("#verifySpinner").hide();
        updateConfirmVerificationEvents(OCC_REC.recordUuid, relatedAssertionId, OCC_REC.userDisplayName, assertionId);

        $("#userAssertionStatusSelection").attr('disabled', 'disabled')

        $('#verifyRecordModal').modal('show');
    });
}

function deleteAssertionPrompt(event) {
    var isConfirmed = confirm('Are you sure you want to delete this flagged issue?');
    if (isConfirmed === true) {
        $('#' + event.data.qa_uuid + ' .deleteAssertionSubmitProgress').css({'display':'inline'});
        //console.log(event.data.qa_uuid);
        deleteAssertion(event.data.rec_uuid, event.data.qa_uuid);
    }
}

function updateEditDeleteEvents(enableDelete, disableDelete){

    for(var i = 0; i < enableDelete.length; i++){
        $('#userAnnotation_' + enableDelete[i] + ' .deleteAnnotationButton').off("click");
        $('#userAnnotation_' + enableDelete[i] + ' .deleteAnnotationButton').click({rec_uuid: OCC_REC.recordUuid, qa_uuid: enableDelete[i]}, deleteAssertionPrompt);

        $('#userAnnotation_' + enableDelete[i] + ' .editAnnotationButton').off("click");
        $('#userAnnotation_' + enableDelete[i] + ' .editAnnotationButton').attr('annotationId', enableDelete[i]);
        $('#userAnnotation_' + enableDelete[i] + ' .editAnnotationButton').on("click", function(e){
            e.preventDefault();

            // update loginOrFlag modal state
            var annotationId = $(this).attr('annotationId');
            var code = $('#userAnnotation_' +annotationId + ' .issueCode').text();
            var comment = $('#userAnnotation_' + annotationId + ' .issueComment').text();
            $('#loginOrFlag').find('#issue').val(code);
            $('#loginOrFlag').find('#editMode').val('true');
            $('#loginOrFlag').find('#assertionId').val(annotationId);
            $('#loginOrFlag').find('#issueComment').val(comment);

            $('#loginOrFlag').modal('show');
        });

        updateVerificationEvents(enableDelete[i]);
    }

    for(var i = 0; i < disableDelete.length; i++){
        $('#userAnnotation_' + disableDelete[i] + ' .editAnnotationButton').attr('disabled', 'disabled');
        $('#userAnnotation_' + disableDelete[i] + ' .editAnnotationButton').attr('title', 'Unable to edit, as this assertion has a verification');
        $('#userAnnotation_' + disableDelete[i] + ' .editAnnotationButton').off("click");
        $('#userAnnotation_' + disableDelete[i] + ' .editAnnotationButton').on("click", function (e) {
            e.preventDefault();
        });

        $('#userAnnotation_' + disableDelete[i] + ' .deleteAnnotationButton').attr('disabled', 'disabled');
        $('#userAnnotation_' + disableDelete[i] + ' .deleteAnnotationButton').attr('title', 'Unable to delete, as this assertion has a verification');
        $('#userAnnotation_' + disableDelete[i] + ' .deleteAnnotationButton').off("click");
        $('#userAnnotation_' + disableDelete[i] + ' .deleteAnnotationButton').on("click", function (e) {
            e.preventDefault();
        });

        updateVerificationEvents(disableDelete[i]);
    }

}

function updateVerificationEvents(assertionId) {
    $('#userAnnotation_' + assertionId + ' .verifyAnnotation').off("click");
    $('#userAnnotation_' + assertionId + ' .verifyAnnotation').on("click", function(e){
        e.preventDefault();

        // reset the form on open
        $("#verifyComment").val("");
        $("#userAssertionStatusSelection").val("50001");
        $(".verifyAsk").show();
        $(".verifyDone").hide();
        $("#verifySpinner").hide();
        updateConfirmVerificationEvents(OCC_REC.recordUuid, assertionId, OCC_REC.userDisplayName);
    });
}

// provide assertionId when editing a verification, do not provide when creating a verification
function updateConfirmVerificationEvents(occUuid, assertionUuid, userDisplayName, updateId){

    $('.closeVerify').on("click", function(e){
        e.preventDefault();
        $(".verifyAsk").fadeIn();
        $(".verifyDone").fadeOut();
    });

    $('.confirmVerify').off("click");
    $('.confirmVerify').on("click", function(e){
        e.preventDefault();
        $("#verifySpinner").show();
        var code = "50000";
        var comment = $("#verifyComment").val();
        var userAssertionStatus = $("#userAssertionStatusSelection").val();
        if (!comment) {
            alert("Please add a comment");
            $("#verifyComment").focus();
            $("#verifySpinner").hide();
            return false;
        }

        //console.log("Submitting an assertion with userAssertionStatus: " + userAssertionStatus)
        $.post(OCC_REC.contextPath + "/occurrences/assertions/add",
            { recordUuid: occUuid,
                code: code,
                comment: comment,
                userAssertionStatus: userAssertionStatus,
                assertionUuid: assertionUuid,
                userId: OCC_REC.userId,
                userDisplayName: userDisplayName,
                updateId: updateId },
            function(data) {
                // service simply returns status or OK or FORBIDDEN, so assume it worked...
                $(".verifyAsk").fadeOut();
                $(".verifyDone").fadeIn();
                refreshUserAnnotations();
            }
        ).error(function (request, status, error) {
            alert("Error verifying record: " + request.responseText);
        }).complete(function() {
            $("#verifySpinner").hide();
        });
    });
}

/**
 * Capitalise first letter of string only
 * @return {String}
 */
String.prototype.capitalize = function() {
    return this.charAt(0).toUpperCase() + this.slice(1);
}

var dataQualityDataIsLoaded = false;
var dataQualityItems = {};

function getDataQualityItem(code) {

    if (!dataQualityDataIsLoaded) {
        var url = OCC_REC.contextPath + "/dataQuality/allCodes";
        $.ajax({
            type: 'GET',
            url: url,
            dataType: 'json',
            success: function(data) {
                if (data) {
                    $.each(data, function(key, val) {
                        //console.log("data", key, val);
                        dataQualityItems[key] = val;
                    });
                }
            },
            complete: function() {
                dataQualityDataIsLoaded = true;
            },
            async: false
        });
    }
    //console.log("dataQualityItems",dataQualityItems);
    if (dataQualityItems[code]) {
        return dataQualityItems[code];
    }
}

/*
 * IE doesn't support String.trim(), so add it in manually
 */
if(typeof String.prototype.trim !== 'function') {
    String.prototype.trim = function() {
        return this.replace(/^\s+|\s+$/g, '');
    }
}

function replaceURLWithHTMLLinks(text) {
    var exp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/i;
    return text.replace(exp,"<a href='$1'>$1</a>");
}

/************************************************************\
 *
 \************************************************************/
// opens email window for slightly obfuscated email addy
var strEncodedAtSign = "(SPAM_MAIL@ALA.ORG.AU)";
function sendEmail(strEncoded) {
    var strAddress;
    strAddress = strEncoded.split(strEncodedAtSign);
    strAddress = strAddress.join("@");
    window.location.href = 'mailto:' + strAddress
    if (event) {
        event.cancelBubble = true;
    }
    return false;
}
