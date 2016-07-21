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
import au.org.ala.web.CASRoles

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

    def dataResource(SpatialSearchRequestParams requestParams){
        requestParams.q = "data_resource_uid:" + params.uid
        def model = list(requestParams)
        render (view: 'list', model: model)
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

        if (!params.pageSize) {
            requestParams.pageSize = 20
        }

        if (!params.sort && !params.dir) {
            requestParams.sort = "first_loaded_date"
            requestParams.dir = "desc"
        }

        log.debug "requestParams = ${requestParams}"

        List taxaQueries = (ArrayList<String>) params.list("taxa") // will be list for even one instance
        log.debug "skin.useAlaBie = ${grailsApplication.config.skin.useAlaBie}"

        if (grailsApplication.config.skin.useAlaBie?.toBoolean() &&
                grailsApplication.config.bie.baseUrl &&
                !params.q &&
                taxaQueries &&
                taxaQueries[0]) { // check for list with empty string
            // taxa query - attempt GUID lookup via BIE
            List guidsForTaxa = webServicesService.getGuidsForTaxa(taxaQueries)
            requestParams.q = postProcessingService.createQueryWithTaxaParam(taxaQueries, guidsForTaxa)
        } else if (!params.q && taxaQueries && taxaQueries[0]) {
            // Bypass BIE lookup and pass taxa query in as text
            List emptyGuidList = taxaQueries.clone().collect { it = ""} // list of empty strings, of equal size to taxaQueries
            requestParams.q = postProcessingService.createQueryWithTaxaParam(taxaQueries, emptyGuidList)
        }

        if (!requestParams.q) {
            requestParams.q = "*:*"
        }

        try {
            //the configured grouping
            Map configuredGroupedFacets = webServicesService.getGroupedFacets()
            List listOfGroupedFacets = postProcessingService.getListFromGroupedFacets(configuredGroupedFacets)
            Map defaultFacets = postProcessingService.getAllFacets(listOfGroupedFacets)
            String[] userFacets = postProcessingService.getFacetsFromCookie(request)
            String[] filteredFacets = postProcessingService.getFilteredFacets(defaultFacets)

            List dynamicFacets = []

            String[] requestedFacets = userFacets ?: filteredFacets

            if (grailsApplication.config.facets.includeDynamicFacets?.toBoolean()) {
                // Sandbox only...
                dynamicFacets = webServicesService.getDynamicFacets(requestParams.q)
                requestedFacets = postProcessingService.mergeRequestedFacets(requestedFacets as List, dynamicFacets)
            }

            requestParams.facets = requestedFacets

            def wsStart = System.currentTimeMillis()
            JSONObject searchResults = webServicesService.fullTextSearch(requestParams)
            def wsTime = (System.currentTimeMillis() - wsStart)

            //create a facet lookup map
            Map groupedFacetsMap = postProcessingService.getMapOfFacetResults(searchResults.facetResults)

            //grouped facets
            Map groupedFacets = postProcessingService.getAllGroupedFacets(configuredGroupedFacets, searchResults.facetResults, dynamicFacets)

            //remove qc from active facet map
            if (params?.qc && searchResults?.activeFacetMap) {
                def remove = null
                searchResults?.activeFacetMap.each { k, v ->
                    if (k + ':' + v?.value == params.qc) {
                        remove = k
                    }
                }
                if (remove) searchResults?.activeFacetMap?.remove(remove)
            }

            [
                    sr: searchResults,
                    searchRequestParams: requestParams,
                    defaultFacets: defaultFacets,
                    groupedFacets: groupedFacets,
                    groupedFacetsMap: groupedFacetsMap,
                    dynamicFacets: dynamicFacets,
                    selectedDataResource: getSelectedResource(requestParams.q),
                    hasImages: postProcessingService.resultsHaveImages(searchResults),
                    showSpeciesImages: false,
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
        redirect(action: "list", params: [q:"lsid:" + id])
    }

    /**
     * POST from taxa drop-down list of raw taxon names
     *
     * @return
     */
    def taxaPost() {
        List rawTaxonGuids = params.list("raw_taxon_guid")
        def qQuery = "raw_taxon_name:\"" + rawTaxonGuids.join("\" OR raw_taxon_name:\"") + "\""
        redirect(action: "list", params: [q: qQuery])
    }

    private def getSelectedResource(query){
        if(query.contains("data_resource_uid:")){
            query.replace("data_resource_uid:","")
        } else {
            ""
        }
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

                String userEmail = authService?.getEmail()

                Boolean isCollectionAdmin = false

                Boolean userHasRoleAdmin = authService?.userInRole(CASRoles.ROLE_ADMIN)

                if (userHasRoleAdmin) {
                  isCollectionAdmin = true
                } else {
                    if (contacts != null && contacts.size() > 0) {
                        for (int i = 0; i < contacts.size(); i++) {
                            if (contacts.get(i).editor == true && userEmail.equals(contacts.get(i).contact.email)) {
                                isCollectionAdmin = true;
                            }
                        }
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
                        isCollectionAdmin: isCollectionAdmin,
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
