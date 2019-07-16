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
 *
 * // require jquery
//= require_self
 */

/**
 * JQuery on document ready callback
 */
jQuery(document).ready(function() {
    // Autocomplete
    var bieBaseUrl = BC_CONF.bieWebServiceUrl;
    var bieParams = { limit: 20 };
    var autoHints = BC_CONF.autocompleteHints; // expects { fq: "kingdom:Plantae" }
    $.extend( bieParams, autoHints ); // merge autoHints into bieParams

    function getMatchingName(item) {
        if (item.commonNameMatches && item.commonNameMatches.length) {
            return item.commonName;
        } else {
            return item.name;
        }
    };

    function formatAutocompleteList(list) {
        var results = [];
        if (list && list.length){
            list.forEach(function (item) {
                var name = getMatchingName(item);
                results.push({label: name, value: name});
            })
        }

        return results;
    };

    $.ui.autocomplete({
        source: function (request, response) {
            bieParams.q = request.term;
            $.ajax( {
                url: bieBaseUrl + '/search/auto.json',
                dataType: "json",
                data: bieParams,
                success: function( data ) {
                    response( formatAutocompleteList(data.autoCompleteList) );
                }
            } );
        }
    }, $(":input#taxaQuery, :input#solrQuery, :input#taxa, :input.name_autocomplete"));

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
