/* 
 *  Copyright (C) 2011 Atlas of Living Australia
 *  All Rights Reserved.
 * 
 *  The contents of this file are subject to the Mozilla Public
 *  License Version 1.1 (the "License"); you may not use this file
 *  except in compliance with the License. You may obtain a copy of
 *  the License at http://www.mozilla.org/MPL/
 * 
 *  Software distributed under the License is distributed on an "AS
 *  IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 *  implied. See the License for the specific language governing
 *  rights and limitations under the License.
 */

/**
 * JQuery on document ready callback
 */
$(document).ready(function() {
    // catch onHashChange event and trigger actions...
    $(window).hashchange( function() {
        var hash = window.location.hash.replace( /^#/, '');
        // remember advanced option hide/show on reload
        var show = (hash.indexOf("advanced") != -1) ? true : false; // boolean
        showHideAdvancedSearch(show);

//        var solrQuery = $("input#solrQuery");
//        if (hash.indexOf("/q=") != -1 && !solrQuery.val()) {
//            var query = hash.replace(/.*\/q=(.*)/, "$1");
//            //console.log("query", query);
//            solrQuery.val(query);
//        }
        
    }); // end hashchange

    // trigger it for page load...
    $(window).hashchange();

    // Custom string methods
    String.prototype.trim = function() {
        return this.replace(/^\s+|\s+$/g, "");
    };
    String.prototype.trimBools = function() {
        return this.replace(/^\s*(OR|AND|NOT)\s+|\s+(OR|AND|NOT)\s*$/g, "");
    };
    
    //  for taxon concepts
    $(".name_autocomplete").autocomplete('http://bie.ala.org.au/search/auto.json', {
        extraParams: {limit:100},
        dataType: 'jsonp',
        parse: function(data) {
            var rows = new Array();
            data = data.autoCompleteList;
            for(var i=0; i<data.length; i++){
                rows[i] = {
                    data:data[i],
                    value: data[i].guid,
                    result: data[i].matchedNames[0]
                };
            }
            return rows;
        },
        matchSubset: false,
        formatItem: function(row, i, n) {
            //console.log("row", row);
            var result = (row.scientificNameMatches.length > 0) ? row.scientificNameMatches[0] : row.commonNameMatches[0] ;
            if (row.name != result && row.rankString) {
                result = result + "<div class='autoLine2'>" + row.rankString + ": " + row.name + "</div>";
            } else if (row.rankString) {
                result = result + "<div class='autoLine2'>" + row.rankString + "</div>";
            }
            //result = "<input type='button' value='Add' style='float:right'/>" + result
            return result;
        },
        cacheLength: 10,
        minChars: 3,
        scroll: false,
        max: 10,
        selectFirst: false
    }).result(function(event, item) {
        // user has selected an autocomplete item
        //console.log("item", item);
        $('input#lsid').val(item.guid);
        //addTaxonConcept(item);
        //console.log("result",  item, this);
        var id = $(this).attr("id");
        //console.log("event", event, item);
        $(".lsidInput#" + id).val(item.guid);
    });

    // "clear" button next to each taxon row
    $("input.clear_taxon").live("click", function(e) {
        e.preventDefault();
        $(this).hide();
        var num = $(this).attr("id").replace("clear_", ""); // get the num
        var lsid = $("input#lsid_" + num).val();
        $('#sciname_' + num).html(''); // clear taxon
        $("tr#taxon_row_" + num).hide("slow"); // hide the row
        var query = $("#solrQuery").val(); // get the query text
        //console.log("1. clear() - query", query);
        // TODO: Clean this code up!
        query = query.replace(" OR lsid:" + lsid, "");  // remove potential OR'ed lsid
        query = query.replace("lsid:" + lsid + " OR ", ""); // remove potential OR'ed lsid
        query = query.replace("lsid:" + lsid, "").trimBools(); // reomve the LSID
        query = query.replace(/\(\)/g, ""); // remove left over braces ()
        query = query.replace(/(\(\s*OR\s*|\s+OR\S*\))/g, ""); // remove left over braces (OR .*)| (.* OR)
        query = query.replace(/^\($|^\)$/, ""); // remove orphaned braces
        //console.log("2. clear() - query", query);
        $("#solrQuery").val(query); // replace with new query text
    });

    // search submit
//    $("#solrSearchForm").submit(function(e) {
//        e.preventDefault();
//        var lsid = $("input#lsid").val();
//        var url;
//        if (lsid) {
//            // redirect to taxon search if lsid
//            url = contextPath + "/occurrences/taxa/" + lsid;
//        } else {
//            // normal full text search
//            url = contextPath + "/occurrences/search?q=" + $("input#solrQuery").val();
//        }
//        window.location.href = url;
//    });
    $("#advancedSearchForm").submit(function(e) {
        e.preventDefault();
        //save cookie with taxonText input values
        var taxaList = [];
        $(":input[name='taxonText']").each(function(i, el) {
            taxaList.push($(el).val()); // we want empty inputs added too!
        });
        $.cookie("taxa_inputs", taxaList, { expires: 7 }); // save cookie
        this.submit();
    });

    // Catch onChange event on all select elements (except institution)
    $("form#advancedSearchForm select").not("select#institution_collection").change(function() {
        var el = $(this);
        var fieldName = el.attr("class");
        var fieldValue = el.val();
        selectChange(fieldName, fieldValue);
    });

    // catch institution drop down list
    $("select#institution_collection").change(function() {
        var code = $(this).val();
        removeFieldFromQuery("institution_uid");
        removeFieldFromQuery("collection_uid");

        if (code.indexOf("in") != -1) {
            selectChange("institution_uid", code);
        } else if (code) {
            selectChange("collection_uid", code);
        } 
    });

    // catch date field changes
    $("input.occurrence_date").blur(function() {
        //console.log("date field on blur");
        var fieldName = "occurrence_date";
        removeFieldFromQuery(fieldName); // clear previous click
        var fieldValue = "";// = $(this).val();
        var start = $("input#startDate").val();
        var end   = $("input#endDate").val();
        if (!start && !end) {
            return; // both fields are blank
        }
        if (start) {
            fieldValue = "[" + start + "T00:00:00Z TO ";
        } else {
            fieldValue = "[* TO ";
        }
        if (end) {
            fieldValue = fieldValue + end + "T00:00:00Z]";
        } else {
            fieldValue = fieldValue + "*]";
        }
        if (fieldValue) {
            addFieldToQuery(fieldName, fieldValue)
        } else {
            removeFieldFromQuery(fieldName);
        }
    });

    //NOT IN USE
    // Autocomplete on IBRA, IMCRA and LGA inputs
//    $("input.region_autocomplete").each(function(i, el) {
//        el = $(el);
//        el.autocomplete(contextPath + '/proxy/gazetteer/search', {
//            //width: 350,
//            extraParams: {"layer": el.attr('id')}, // $(this).attr("id")
//            dataType: 'xml',
//            parse: function(data) {
//                var parsed = [];
//                $(data).find("result").each(function() {
//                    var region = $(this).find("name").text();
//                    region = region.replace(/\(.*\)/, "");
//                    parsed[parsed.length] = {
//                        data: [region],
//                        value: region,
//                        result: [region]
//                    };
//                });
//                return parsed;
//            },
//            matchSubset: true,
//            highlight: false,
//            delay: 600,
//            cacheLength: 10,
//            minChars: 1,
//            scroll: false,
//            max: 10,
//            selectFirst: false
//        }).result(function(event, item) {
//            // user selected an item -> process it and add to query
//            var fieldName = $(this).attr("name");
//            var fieldValue = $(this).val().trim();
//            removeFieldFromQuery(fieldName); // clear previous click
//            if (fieldValue && fieldValue.match(/\s+/)) {
//                // add quotes to search terms with spaces in them
//                addFieldToQuery(fieldName,  "\"" + fieldValue + "\"")
//            } else if (fieldValue) {
//                addFieldToQuery(fieldName, fieldValue)
//            } else {
//                // desected a select drop down
//                removeFieldFromQuery(fieldName);
//            }
//        }).blur(function(e) {
//            // check to see if user has cleared the field
//            var el = $(this);
//            if (!el.val()) {
//                var fieldName = $(this).attr("name");
//                //console.log("input blur", fieldName);
//                removeFieldFromQuery(fieldName);
//            }
//            return true;
//        });
//    });

    // dataset fields: catalogue_number & record number
    $("input.dataset").blur(function() {
        var el = $(this);
        var fieldName = el.attr("id");
        var fieldValue = el.val().trim();
        removeFieldFromQuery(fieldName);
        if (fieldValue) {
            if (fieldValue.match(/\s/)) {
                fieldValue = "\"" + fieldValue + "\"";
            }
            addFieldToQuery(fieldName, fieldValue);
        }
    });

    // populate advanced search options from q param on page load
    //var q = decodeURIComponent($.getQueryParam("q")[0]);
    var q = $("input#solrQuery").val();
    var terms = q.match(/(\w+:".*?"|lsid:(\S+)|\w+:\[.*?\]|\w+:\w+)/g); // magic regex!
    //console.log("terms", terms);
    for (var i in terms) {
        if (typeof terms[i] === 'string') {
            var term = terms[i].replace(/"|\(|\)/g, ''); // remove quotes
        }
        //console.log("term", i, term);
        if (term.indexOf(":") != -1) {
            // only interested in field searches, e.g. lsid:foo
            var bits = term.split(":");
            var fieldName = bits[0];
            var fieldValue = bits.slice(1).join(":"); //bits[1];
            // plain fields -  try setting selects and inputs
            $("select." + fieldName).val(fieldValue);
            $("input[name=" + fieldName + "]").val(fieldValue);
            // taxon concepts
            if (fieldName.indexOf("lsid") != -1) {
                // lsid searches
                var taxonUri = "http://bie.ala.org.au/species/" + fieldValue + ".json";
                //console.log("URL", taxonUri);
                $.ajax({
                    url: taxonUri,
                    dataType: "jsonp",
                    success: updateTaxonConcepts
                });
            } else if (fieldName.indexOf("_date") != -1) {
                // date range search
                fieldValue = fieldValue.replace(/\[|\]/g, ''); // remove [ & ]
                fieldValue = fieldValue.replace(/T00:00:00Z/g, ''); // remove time portion of ISO date
                fieldValue = fieldValue.replace(/\*/g, ''); // remove wildcard char
                var dates = fieldValue.split(" TO ");
                $("#startDate").val(dates[0].trim());
                $("#endDate").val(dates[1].trim());
            }
        }
    }

    // fill in autocomplete fields with saved values (cookie) from back button
    var taxaInputs = $.cookie("taxa_inputs"); // read cookie
    if (taxaInputs) {
        var taxaList = taxaInputs.split(",");
        $(taxaList).each(function(i, el) {
            // set input with saved value
            //console.log("Setting taxonText " + i, el);
            $(":input#taxa_" + (i + 1)).val(el);
        });
    }

    // Toggle advanced options
    $("#extendedOptionsLink").click(function(e) {
        e.preventDefault();
        var $this = this;
        $("#extendedOptions").slideToggle('slow', function(){
            // change plus/minus icon when transition is complete
            $($this).toggleClass('toggleTitleActive');
        });
    });

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


}); // end document ready

function selectChange(fieldName, fieldValue) {
    if (fieldValue && fieldValue.match(/\s+/)) {
        // add quotes to search terms with spaces in them
        addFieldToQuery(fieldName,  "\"" + fieldValue + "\"")
    } else if (fieldValue) {
        addFieldToQuery(fieldName, fieldValue)
    } else {
        // desected a select drop down
        removeFieldFromQuery(fieldName);
    }
}

/**
 * Add the selected field name:value to the solr query string
 */
function addFieldToQuery(fieldName, fieldValue) {
    var newQuery = fieldName + ":" + fieldValue;
    var queryText = $("#solrQuery").val();// + " " + newQuery;
    var regex = new RegExp(fieldName + ":"); // check for existing field in query
    if (queryText.match(regex)) {
        queryText = removeFromQuery(queryText, fieldName);
    }
    queryText = queryText + " " + newQuery;
    $("#solrQuery").val(queryText.trim());
}

/**
 * Remove the selected field name:value from the solr query string
 */
function  removeFieldFromQuery(fieldName) {
    var query = removeFromQuery($("#solrQuery").val(), fieldName);
    $("#solrQuery").val(query); // replace with new query text
}

/**
 * Remove the provided fieldName and any value from the query string
 */
function removeFromQuery(query, fieldName) {
    var fnRegEx = [];
    fnRegEx[0] = new RegExp(fieldName + ":\".*?\""); // quoted search
    fnRegEx[2] = new RegExp(fieldName + ":\\[.*?\\]"); // range search
    fnRegEx[3] = new RegExp(fieldName + ":\\w+"); // plain search
    
    for (var i in fnRegEx) {
        query = query.replace(fnRegEx[i], "");
    }

    query = query.replace(/\s{2,}/, " ").trim(); // replace 2 or more spaces with a single space
    return query;
}

/**
 * show/hide the advanced search div
 */
function showHideAdvancedSearch(doShow) {
    var advDiv = $("div#advancedSearch");
    //console.log("showHideAdvancedSearch", doShow);
    //if ($(advDiv).css("display") == "none") {
    if (doShow) {
        // advanced hash detected...
        $("#extendedOptions").slideToggle('slow', function(){
            // change plus/minus icon when transition is complete
            $(this).prev(".toggleTitle").toggleClass('toggleTitleActive');
        });
    }
}

/**
 * Add "sticky" behaviour for lsid searches
 */
function updateTaxonConcepts(data) {
    //console.log("ajax data", data);
    if (data.extendedTaxonConceptDTO) {
        var tc = data.extendedTaxonConceptDTO;
        var item = {};
        item.guid = tc.taxonConcept.guid;
        item.name = tc.taxonConcept.nameString;
        item.rankString = tc.taxonConcept.rankString;
        item.rankId = tc.taxonConcept.rankID;
        item.commonName = tc.commonNames[0].nameString;
        addTaxonConcept(item);
    }
}

/**
 * Add the selected lsid (+ data) to the next available lsid entry
 * displaying the rank, sci name and common names
 */
function addTaxonConcept(item) {
    // determine the next avail taxon row (num) to add to
    var num = 1;
    for (i=1;i<=4;i++) {
        if (!$("#sciname_" + i).html()) {
            num = i;
            break;
        }
    }

    $("input#lsid_" + num).val(item.guid); // add lsid to hidden field
    // build the name string
    var matchedName = "<b>" + item.name + "</b>";
    if (item.rankId && item.rankId >= 6000) {
        matchedName = "<i>" + matchedName + "</i>";
    }
    if (item.rankString) {
        matchedName = item.rankString + ": " + matchedName;
    }
    if (item.commonName) {
        matchedName = matchedName + " | " + item.commonName;
    }

    $("#sciname_" + num).html(matchedName); // populate the matched name
    $("#clear_" + num).show(); // show the 'clear' button
    $("tr#taxon_row_" + num).show("slow"); // show the row
    var queryText = $("#solrQuery").val();
    // add OR between lsid:foo terms
    // TODO wrap all lsid:NNN terms in braces
    if (queryText && queryText.indexOf(item.guid) != -1) {
        // guid already in query (e.g. page reload)
        return;
    } else if (queryText && queryText.indexOf("lsid") != -1) {
        queryText = "(" +queryText + " OR lsid:" + item.guid + ")";
    } else {
        queryText = queryText + " lsid:" + item.guid;
    }
    $("#solrQuery").val(queryText.trim()); // add LSID to the main query input
    $("#name_autocomplete").val(""); // clear the search test
}
