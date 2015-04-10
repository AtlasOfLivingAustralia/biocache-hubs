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
jQuery(document).ready(function() {
    // Autocomplete
    var bieBaseUrl = BC_CONF.bieWebappUrl;
    var bieParams = { limit: 100 };
    var autoHints = BC_CONF.autocompleteHints; // expects { fq: "kingdom:Plantae" }
    $.extend( bieParams, autoHints ); // merge autoHints into bieParams
    jQuery(":input#taxaQuery, :input#solrQuery, :input#taxa, :input.name_autocomplete").autocomplete(bieBaseUrl + '/search/auto.json', {
        extraParams: bieParams,
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
            return row.matchedNames[0];
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
    });

    // search submit
    jQuery("#solrSearchFormOFF").submit(function(e) {
        e.preventDefault();
        var lsid = $("input#lsid").val();
        var query = $("input#solrQuery").val();
        // add q param to current URL hash for back button support
        var hash = window.location.hash;
        window.location.hash = hash + "/q=" + query;
        var url;
        if (lsid) {
            // redirect to taxon search if lsid
            url = contextPath + "/occurrences/taxa/" + lsid;
        } else {
            // normal full text search
            url = contextPath + "/occurrences/search?q=" + query;
        }
        window.location.href = url;
    });
});
