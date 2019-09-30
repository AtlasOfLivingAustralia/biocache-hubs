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

import org.apache.commons.lang.StringUtils
import org.grails.web.json.JSONObject
import org.springframework.web.client.RestClientException

import javax.annotation.PostConstruct

/**
 * Service to cache the facet values available from a given data hub.
 * Used to populate the values in select drop-down lists in advanced search page.
 */
class FacetsCacheService {
    def webServicesService, grailsApplication
    Map facetsMap = [:]  // generated via SOLR lookup
    List facetsList = [] // set via config (facets.cached) in init()

    /**
     * Init method - load facetsList from config file
     *
     * @return
     */
    @PostConstruct
    void init() {
        // Note config.getProperties will coerce a comma-separated String into a List automagically
        facetsList = grailsApplication.config.getProperty("facets.cached", List, [])
    }

    /**
     * Get the facets values (and labels if available) for the requested facet field.
     *
     * @param facet
     * @return
     */
    Map getFacetNamesFor(String facet) {
        if (!facetsMap) {
            loadSearchResults()
        }

        return facetsMap?.get(facet)
    }

    /**
     * Can be triggered from the admin page. Note: the longTermCache needs to be
     * cleared as well (admin function does this).
     */
    void clearCache() {
        facetsMap = [:]
        init() //  reload config values
    }

    /**
     * Do a search for all records and store facet values for the requested facet fields
     */
    private void loadSearchResults() {
        if (!facetsList) {
            init()
        }

        SpatialSearchRequestParams requestParams = new SpatialSearchRequestParams()
        requestParams.setQ("*:*")
        requestParams.setPageSize(0)
        requestParams.setFlimit(999)
        requestParams.setFacets(facetsList as String[])

        try {
            JSONObject sr = webServicesService.cachedFullTextSearch(requestParams)

            if (sr.has("facetResults") && sr.facetResults.size() > 0) {
                sr.facetResults.each { fq ->
                    log.debug "facetResults = ${fq}"
                    def fieldName = fq.fieldName
                    def fields = [:]
                    fq.fieldResult.each {
                        if (it.fq) {
                            def values = it.fq.tokenize(":")
                            def value = StringUtils.remove(values[1], '"') // some values have surrounding quotes
                            fields.put(value, it.label) // it.label is the display label that can be different from the Solr field value
                        } else {
                            fields.put(it.label, it.label)
                        }
                    }

                    if (fields.size() > 0) {
                        facetsMap.put(fieldName, fields)
                    } else {
                        log.warn "No facet values found for ${fieldName}"
                    }
                }
            }
        } catch (RestClientException rce) {
            log.warn "Cached facets call failed - ${rce.message}", rce
        }
    }

}
