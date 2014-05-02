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
import org.codehaus.groovy.grails.web.json.JSONObject

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
        if (!params.pageSize) {
            requestParams.pageSize = 20
        }

        if (!params.sort && !params.dir) {
            requestParams.sort = "first_loaded_date"
            requestParams.dir = "desc"
        }

        List taxaQueries = (ArrayList<String>) params.list("taxa") // will be list for even one instance

        if (!params.q && taxaQueries) {
            // taxa query
            List guidsForTaxa = webServicesService.getGuidsForTaxa(taxaQueries)
            requestParams.q = postProcessingService.createQueryWithTaxaParam(taxaQueries, guidsForTaxa)
        }

        if (!requestParams.q) {
            requestParams.q= "*:*"
        }

        try {
            Map defaultFacets = postProcessingService.getAllFacets(webServicesService.getDefaultFacets())
            String[] userFacets = postProcessingService.getFacetsFromCookie(request)
            String[] filteredFacets = postProcessingService.getFilteredFacets(defaultFacets)
            requestParams.facets = userFacets ?: filteredFacets
            def wsStart = System.currentTimeMillis()
            JSONObject searchResults = webServicesService.fullTextSearch(requestParams)
            def wsTime = (System.currentTimeMillis() - wsStart)
            // postProcessingService.modifyQueryTitle(searchResults, taxaQueries)
            // log.info "searchResults = ${searchResults.toString(2)}"
            session['hit'] = 0
            //log.debug "userid = ${authService.getUserId()} - ${session['hit']++}"

            [
                    sr: searchResults,
                    searchRequestParams: requestParams,
                    defaultFacets: defaultFacets,
                    groupedFacets: webServicesService.getGroupedFacets(), // cached
                    groupedFacetsMap: postProcessingService.getMapOfGroupedFacets(searchResults.facetResults),
                    dynamicFacets: null, // TODO
                    hasImages: postProcessingService.resultsHaveImages(searchResults),
                    showSpeciesImages: false, // TODO
                    sort: requestParams.sort,
                    dir: requestParams.dir,
                    userId: authService?.getUserId(),
                    userEmail: authService?.getEmail(),
                    processingTime: (System.currentTimeMillis() - start),
                    wsTime: wsTime
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
            Boolean hasClubView = request.isUserInRole(grailsApplication.config.clubRoleForHub)
            JSONObject record = webServicesService.getRecord(id, hasClubView)

            if (record) {
                JSONObject compareRecord = webServicesService.getCompareRecord(id)
                JSONObject collectionInfo = null

                if (record.processed.attribution.collectionUid) {
                    collectionInfo = webServicesService.getCollectionInfo(record.processed.attribution.collectionUid)
                }

                List groupedAssertions = postProcessingService.getGroupedAssertions(webServicesService.getUserAssertions(id), webServicesService.getQueryAssertions(id), userId)
                Map layersMetaData = webServicesService.getLayersMetaData()

                [
                        record: record,
                        uuid: id,
                        compareRecord: compareRecord,
                        groupedAssertions: groupedAssertions,
                        formattedImageSizes: webServicesService.getImageFileSizeInMb(record.images),
                        collectionName: collectionInfo?.name,
                        collectionLogo: collectionInfo?.institutionLogoUrl,
                        collectionInstitution: collectionInfo?.institution,
                        isCollectionAdmin: false, // TODO implement this
                        queryAssertions: null, // TODO implement this
                        duplicateRecordDetails: null, // TODO implement
                        dataResourceCodes: facetsCacheService.getFacetNamesFor(FacetsName.DATA_RESOURCE), // TODO test
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
                speciesPageUrl: grailsApplication.config.bie.baseUrl + "species/"
        ]
    }

    /**
     * AJAX webservice for legend data from SP
     *
     * @return
     */
    def legend(){
       def legend = webServicesService.getText(grailsApplication.config.biocache.baseUrl + "/webportal/legend?" + request.queryString)
       response.setContentType("application/json")
       render legend
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
