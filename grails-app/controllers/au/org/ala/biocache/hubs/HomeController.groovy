/*
 * Copyright (C) 2014 Atlas of Living Australia
 * All Rights Reserved.
 *
 * The contents of this file are subject to the Mozilla Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 */

package au.org.ala.biocache.hubs

class HomeController {

    def facetsCacheService

    def index() throws Exception {
        log.debug "Home controller index page"
        addCommonModel()
    }

    def advancedSearch(AdvancedSearchParams requestParams) {
        log.debug "Home controller advancedSearch page"
        //flash.message = "Advanced search for: ${requestParams.toString()}"
        redirect(controller: "occurrences", action:"search", params: requestParams.toParamMap())
    }
    
    private Map addCommonModel() {
        def model = [:]

        facetsCacheService.facetsList.each { fn ->
            model.put(fn, facetsCacheService.getFacetNamesFor(fn))
        }

        model
    }
}
