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
import grails.converters.JSON
import org.codehaus.groovy.grails.web.json.JSONArray
import org.codehaus.groovy.grails.web.json.JSONElement
import org.codehaus.groovy.grails.web.json.JSONObject

import java.text.SimpleDateFormat
/**
 * Controller for occurrence searches and records
 */
class OccurrenceController {

    def webServicesService, facetsCacheService, postProcessingService, authService
    def ENVIRO_LAYER = "el"
    def CONTEXT_LAYER = "cl"

    def index() {
        redirect action: "search"
    }

    /**
     * Perform a full text search
     *
     * @param requestParams
     * @return
     */
    def list(SpatialSearchRequestParams requestParams) {
        def start = System.currentTimeMillis()
        requestParams.fq = params.list("fq") as String[] // override Grails binding which splits on internal commas in value
        Long alaId = Long.parseLong(authService?.getUserId()?:0);
        Boolean showHistory = grailsApplication.config.myHistory as Boolean

        if (!params.pageSize) {
            requestParams.pageSize = 20
        }

        if (!params.sort && !params.dir) {
            requestParams.sort = "first_loaded_date"
            requestParams.dir = "desc"
        }

        List taxaQueries = (ArrayList<String>) params.list("taxa") // will be list for even one instance
        log.debug "skin.useAlaBie = ${grailsApplication.config.skin.useAlaBie}"

        if (grailsApplication.config.skin.useAlaBie?.toBoolean() && grailsApplication.config.bie.baseUrl && !params.q && taxaQueries && taxaQueries[0]) { // check for list with empty string
            // taxa query - attempt GUID lookup via BIE
            List guidsForTaxa = webServicesService.getGuidsForTaxa(taxaQueries)
            requestParams.q = postProcessingService.createQueryWithTaxaParam(taxaQueries, guidsForTaxa)
        } else if (!params.q && taxaQueries && taxaQueries[0]) {
            // Bypass BIE lookup and pass taxa query in as text
            List emptyGuidList = taxaQueries.clone().collect { it = ""} // list of empty strings, of equal size to taxaQueries
            requestParams.q = postProcessingService.createQueryWithTaxaParam(taxaQueries, emptyGuidList)
        }

        if (!requestParams.q) {
            requestParams.q= "*:*"
        }

        try {
            Map defaultFacets = postProcessingService.getAllFacets(webServicesService.getDefaultFacets())
            String[] userFacets = postProcessingService.getFacetsFromCookie(request)
            String[] filteredFacets = postProcessingService.getFilteredFacets(defaultFacets)
            List dynamicFacets = []
            String[] requestedFacets = userFacets ?: filteredFacets
            List searchHistory = [];

            log.debug(postProcessingService.constructRequestURL(request));

            if (grailsApplication.config.facets.includeDynamicFacets?.toBoolean()) {
                // Sandbox only...
                dynamicFacets = webServicesService.getDynamicFacets(requestParams.q)
                requestedFacets = postProcessingService.mergeRequestedFacets(requestedFacets as List, dynamicFacets)
            }
            requestParams.facets = requestedFacets
            def wsStart = System.currentTimeMillis()
            JSONObject searchResults = webServicesService.fullTextSearch(requestParams)
            def wsTime = (System.currentTimeMillis() - wsStart)
            Map groupedFacets = webServicesService.getGroupedFacets() // cached
            Map facetResultsMap = postProcessingService.getMapOfFacetResults(searchResults.facetResults)

            // check if the hub wants to show my history, only then get history
            if(showHistory && alaId){
                Map newSearch = [url: postProcessingService.constructRequestURL(request),
                                 name: searchResults?.queryTitle?.replaceAll("<(.|\n)*?>", '')]
                searchHistory = postProcessingService.getSearchHistory(alaId)?:[]
                postProcessingService.updateSearchHistory(alaId,  newSearch, searchHistory.clone())
                showHistory = showHistory && (searchHistory.size() >= 1);
            }

            [
                    sr: searchResults,
                    searchRequestParams: requestParams,
                    defaultFacets: defaultFacets,
                    groupedFacets: postProcessingService.getAllGroupedFacets(groupedFacets, searchResults.facetResults),
                    groupedFacetsMap: facetResultsMap,
                    dynamicFacets: dynamicFacets,
                    hasImages: postProcessingService.resultsHaveImages(searchResults),
                    showSpeciesImages: false, // TODO
                    sort: requestParams.sort,
                    dir: requestParams.dir,
                    userId: authService?.getUserId(),
                    userEmail: authService?.getEmail(),
                    processingTime: (System.currentTimeMillis() - start),
                    wsTime: wsTime,
                    searchHistory: searchHistory.reverse(),
                    showHistory: showHistory
            ]
        } catch (Exception ex) {
            log.warn "Error getting search results: $ex.message", ex
            flash.message = "${ex.message}"
            render view:'../error'
        }
    }

    def taxa(String id) {
        log.debug "taxa search for ${id}"
        redirect(action: "search", params: [q:"lsid:" + id])
    }

    /**
     * Display an occurrence record
     *
     * @param id
     * @return
     */
    def show(String id) {

        try {
            String userId = authService?.getUserId()
            Boolean hasClubView = request.isUserInRole("${grailsApplication.config.clubRoleForHub}")
            JSONObject record = webServicesService.getRecord(id, hasClubView)
            log.debug "hasClubView = ${hasClubView} || ${grailsApplication.config.clubRoleForHub}"

            if (record) {
                JSONObject compareRecord = webServicesService.getCompareRecord(id)
                JSONObject collectionInfo = null
                JSONArray contacts = null

                if (record.processed.attribution.collectionUid) {
                    collectionInfo = webServicesService.getCollectionInfo(record.processed.attribution.collectionUid)
                    contacts = webServicesService.getCollectionContact(record.processed.attribution.collectionUid)
                }

                if(record.raw.attribution.dataResourceUid && (contacts == null)){
                    try {
                        contacts = webServicesService.getDataresourceContact(record.raw.attribution.dataResourceUid)
                    } catch(Exception e){
                        log.warn("Problem retrieving contact details for ${record.raw.attribution.dataResourceUid} - " + e.getMessage())
                    }
                }

                List groupedAssertions = postProcessingService.getGroupedAssertions(
                        webServicesService.getUserAssertions(id),
                        webServicesService.getQueryAssertions(id),
                        userId)

                Map layersMetaData = webServicesService.getLayersMetaData()

                [
                        record: record,
                        uuid: id,
                        compareRecord: compareRecord,
                        groupedAssertions: groupedAssertions,
                        collectionName: collectionInfo?.name,
                        collectionLogo: collectionInfo?.institutionLogoUrl,
                        collectionInstitution: collectionInfo?.institution,
                        isCollectionAdmin: false, // TODO implement this
                        contacts: contacts,
                        queryAssertions: null, // TODO implement this
                        duplicateRecordDetails: webServicesService.getDuplicateRecordDetails(record),
                        dataResourceCodes: facetsCacheService.getFacetNamesFor("data_resource_uid"), // TODO move string value to config file
                        clubView: hasClubView,
                        errorCodes: webServicesService.getErrorCodes(),
                        metadataForOutlierLayers: postProcessingService.getMetadataForOutlierLayers(record, layersMetaData),
                        environmentalSampleInfo: postProcessingService.getLayerSampleInfo(ENVIRO_LAYER, record, layersMetaData),
                        contextualSampleInfo: postProcessingService.getLayerSampleInfo(CONTEXT_LAYER, record, layersMetaData),
                        skin: grailsApplication.config.skin.layout
                ]
            } else {
                flash.message = "No record found with id: ${id}"
                render view:'../error'
            }
        } catch (Exception ex) {
            log.warn "Error getting record details: $ex.message", ex
            flash.message = "${ex.message}"
            render view:'../error'
        }
    }

    /**
     * Display just the "core" section of an occurrence record.
     * I.e. the basic DwC values in a table
     *
     * @param id
     * @return
     */
    def showCore(String id) {
        try {
            JSONObject record = webServicesService.getRecord(id)
            JSONObject compareRecord = webServicesService.getCompareRecord(id)

            if (record) {
                [       record: record,
                        uuid: id,
                        compareRecord: compareRecord
                ]
            } else {
                flash.message = "No record found for id: ${id}"
                render view:'../error'
            }
        } catch (Exception ex) {
            flash.message = "${ex.message}"
            render view:'../error'
        }
    }

    /**
     * Explore your area page
     *
     * @return
     */
    def exploreYourArea() {
        def radius = params.radius?:5
        Map radiusToZoomLevelMap = [ 1: 14, 5: 12, 10: 11, 50: 9 ] // zoom levels for the various radius sizes

        [
                latitude:  params.latitude?:grailsApplication.config.exploreYourArea.lat,
                longitude: params.longitude?:grailsApplication.config.exploreYourArea.lng,
                radius: radius,
                zoom: radiusToZoomLevelMap.get(radius),
                location: grailsApplication.config.exploreYourArea.location,
                speciesPageUrl: grailsApplication.config.bie.baseUrl + "/species/"
        ]
    }

    /**
     * AJAX webservice for legend data from SP
     *
     * @return
     */
    def legend() {
        def legend = webServicesService.getMapLegend(request.queryString)
        render legend as JSON
    }

    /**
     * Field guide download
     *
     * @param requestParams
     * @return
     */
    def fieldGuideDownload(SpatialSearchRequestParams requestParams) {
        requestParams.pageSize = 0 // we just want the facet results
        requestParams.flimit = params.maxSpecies ?: 150
        FieldGuideDTO fg = new FieldGuideDTO()
        JSONObject searchResults = webServicesService.fullTextSearch(requestParams)

        searchResults?.facetResults?.each { fr ->
            if (fr.fieldName == 'species_guid') {
                fg.guids = fr.fieldResult?.label // groovy does an implicit collect
            }
        }

        if (fg.guids.isEmpty()) {
            flash.message = "Error: No species were found for the requested search (${requestParams.toString()})."
            render view:'../error'
            return
        }

        SimpleDateFormat sdf = new SimpleDateFormat("dd MMMMM yyyy")
        //set the properties of the query
        fg.title = "This document was generated on "+ sdf.format(new Date())
        String serverName = grailsApplication.config.serverName ?: grailsApplication.config.security.cas.appServerName
        String contextPath = grailsApplication.config.contextPath ?: grailsApplication.config.security.cas.contextPath ?: ""
        fg.link = serverName + contextPath + "/occurrences/search?" + request.getQueryString()
        //log.info "FG json = " + fg.getJson()

        try {
            JSONElement fgPostObj = webServicesService.postJsonElements("http://fieldguide.ala.org.au/generate", fg.getJson())
            //log.info "fgFileId = ${fgFileId}"

            if (fgPostObj.fileId) {
                response.sendRedirect("http://fieldguide.ala.org.au/guide/"+fgPostObj.fileId)
            } else {
                flash.message = "No field guide found for requested taxa."
                render view:'../error'
            }
        } catch (Exception ex) {
            flash.message = "Error generating field guide PDF. ${ex}"
            log.error ex, ex
            render view:'../error'
        }
    }

    /**
     * JSON webservices for debugging/testing
     */
    def searchJson (SpatialSearchRequestParams requestParams) {
        render webServicesService.fullTextSearch(requestParams) as JSON
    }

    /**
     * JSON webservices for debugging/testing
     */
    def showJson (String id) {
        def combined = [:]
        combined.record = webServicesService.getRecord(id)
        combined.compareRecord = webServicesService.getCompareRecord(id)
        render combined as JSON
    }
}
