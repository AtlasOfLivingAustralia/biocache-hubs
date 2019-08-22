/*
 * // require jquery
//= require jquery_i18n
//= require audiojs/audio.js
//= require jquery.i18n.properties.js
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
$(document).ready(function() {

    $('#showUncheckedTests').on('click', function(e){
        $('.uncheckTestResult').toggle();
    });

    $('#showMissingPropResult').on('click', function(e){
        $('.missingPropResult').toggle();
    });

    jQuery.i18n.properties({
        name: 'messages',
        path: OCC_REC.contextPath + '/messages/i18n/',
        mode: 'map',
        async: true,
        cache: true,
        language: OCC_REC.locale // default is to use browser specified locale
        //callback: function(){} //alert( "facet.conservationStatus = " + jQuery.i18n.prop('facet.conservationStatus')); }
    });

    refreshUserAnnotations();

    // bind to form submit for assertions
    $("form#issueForm").submit(function(e) {
        e.preventDefault();
        var comment = $("#issueComment").val();
        var code = $("#issue").val();
        var userDisplayName = OCC_REC.userDisplayName //'${userDisplayName}';
        var recordUuid = OCC_REC.recordUuid //'${ala:escapeJS(record.raw.rowKey)}';
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
                } else {

                    $.post(OCC_REC.contextPath + "/occurrences/assertions/add",
                        {
                            recordUuid: recordUuid,
                            code: code,
                            comment: comment,
                            userAssertionStatus: 'Open issue',
                            userId: OCC_REC.userId,
                            userDisplayName: userDisplayName
                        },
                        function (data) {
                            $('#assertionSubmitProgress').css({'display': 'none'});
                            $("#submitSuccess").html("Thanks for flagging the problem!");
                            $("#issueFormSubmit").hide();
                            $("input:reset").hide();
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
                        $("#submitSuccess").html("There was problem flagging the issue. Please try again later.");
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
    $(".tooltips").tooltip();

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
        $('#backBtn > a').attr('href', lastSearch);
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

}); // end JQuery document ready

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

        var userAssertionStatus = jQuery.i18n.prop("user_assertions." + data.userAssertionStatus);
        $("#userAssertionStatus").text(userAssertionStatus);

        for(var i=0; i < data.assertionQueries.length; i++){
            var $clone = $('#userAnnotationTemplate').clone();
            $clone.find('.issue').text(data.assertionQueries[i].assertionType);
            $clone.find('.user').text(data.assertionQueries[i].userName);
            $clone.find('.comment').text('Comment: ' + data.assertionQueries[i].comment);
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
                $clone.find('.issue').text(jQuery.i18n.prop(userAssertion.name));
                $clone.find('.user').text(userAssertion.userDisplayName);
                $clone.find('.comment').text('Comment: ' + userAssertion.comment);
                $clone.find('.userRole').text(userAssertion.userRole != null ? userAssertion.userRole : '');
                $clone.find('.userEntity').text(userAssertion.userEntityName != null ? userAssertion.userEntityName : '');
                $clone.find('.created').text('Date created: ' + (moment(userAssertion.created, "YYYY-MM-DDTHH:mm:ssZ").format('YYYY-MM-DD HH:mm:ss')));
                if (userAssertion.userRole != null) {
                    $clone.find('.userRole').text(', ' + userAssertion.userRole);
                }
                if (userAssertion.userEntityName != null) {
                    $clone.find('.userEntity').text(', ' + userAssertion.userEntityName);
                }

                //if the current user is the author of the annotation, they can delete
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
            $clone.find('.qaStatus').text(qaStatusMessage);
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

        updateDeleteEvents(enableDelete, disableDelete);
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
}

function deleteAssertionPrompt(event) {
    var isConfirmed = confirm('Are you sure you want to delete this flagged issue?');
    if (isConfirmed === true) {
        $('#' + event.data.qa_uuid + ' .deleteAssertionSubmitProgress').css({'display':'inline'});
        console.log(event.data.qa_uuid);
        deleteAssertion(event.data.rec_uuid, event.data.qa_uuid);
    }
}

function updateDeleteEvents(enableDelete, disableDelete){

    for(var i = 0; i < enableDelete.length; i++){
        $('#userAnnotation_' + enableDelete[i] + ' .deleteAnnotation').off("click");
        $('#userAnnotation_' + enableDelete[i] + ' .deleteAnnotation').click({rec_uuid: OCC_REC.recordUuid, qa_uuid: enableDelete[i]}, deleteAssertionPrompt);
        updateVerificationEvents(enableDelete[i]);
    }

    for(var i = 0; i < disableDelete.length; i++){
        $('#userAnnotation_' + disableDelete[i] + ' .deleteAnnotationButton').attr('disabled', 'disabled');
        $('#userAnnotation_' + disableDelete[i] + ' .deleteAnnotationButton').attr('title', 'Unable to delete, as this assertion has a verification');


        $('#userAnnotation_' + disableDelete[i] + ' .deleteAnnotation').off("click");
        $('#userAnnotation_' + disableDelete[i] + ' .deleteAnnotation').on("click", function (e) {
            e.preventDefault();
        });
        updateVerificationEvents(disableDelete[i]);
    }

}

function updateVerificationEvents(assertionId) {
    $('#userAnnotation_' + assertionId + ' .verifyAnnotation').off("click");
    $('#userAnnotation_' + assertionId + ' .verifyAnnotation').on("click", function(e){
        e.preventDefault();
        $("#verifySpinner").hide();
        updateConfirmVerificationEvents(OCC_REC.recordUuid, assertionId, OCC_REC.userDisplayName);
    });
}

function updateConfirmVerificationEvents(occUuid, assertionUuid, userDisplayName){

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

        console.log("Submitting an assertion with userAssertionStatus: " + userAssertionStatus)

        $.post(OCC_REC.contextPath + "/occurrences/assertions/add",
            { recordUuid: occUuid,
                code: code,
                comment: comment,
                userAssertionStatus: userAssertionStatus,
                assertionUuid: assertionUuid,
                userId: OCC_REC.userId,
                userDisplayName: userDisplayName},
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
                if (data && data[1]) {
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
