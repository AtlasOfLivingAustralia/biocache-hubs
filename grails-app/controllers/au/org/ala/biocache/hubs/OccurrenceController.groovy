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

import au.org.ala.dataquality.model.QualityProfile
import au.org.ala.web.CASRoles
import com.maxmind.geoip2.record.Location
import grails.converters.JSON
import groovy.util.logging.Slf4j
import org.grails.web.json.JSONArray
import org.grails.web.json.JSONElement
import org.grails.web.json.JSONObject

import javax.servlet.http.HttpServletResponse
import java.text.SimpleDateFormat

import static au.org.ala.biocache.hubs.TimingUtils.time
import static javax.servlet.http.HttpServletResponse.SC_NOT_FOUND
import static javax.servlet.http.HttpServletResponse.SC_NO_CONTENT

/**
 * Controller for occurrence searches and records
 */
@Slf4j
class OccurrenceController {
    def webServicesService, facetsCacheService, postProcessingService, authService

    def SESSION_NAVIGATION_DTO = "SESSION_NAVIGATION_DTO"

    GeoIpService geoIpService
    QualityService qualityService

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

        def activeProfile = time("active profile") { qualityService.activeProfile(requestParams.qualityProfile) }

        normaliseRequestParams(requestParams)

        try {
            //the configured grouping
            Map configuredGroupedFacets
            List listOfGroupedFacets
            Map defaultFacets
            String[] userFacets
            String[] filteredFacets
            time("all facets") {
                configuredGroupedFacets = webServicesService.getGroupedFacets()
                listOfGroupedFacets = postProcessingService.getListFromGroupedFacets(configuredGroupedFacets)
                defaultFacets = postProcessingService.getAllFacets(listOfGroupedFacets)
                userFacets = postProcessingService.getFacetsFromCookie(request)
                filteredFacets = postProcessingService.getFilteredFacets(defaultFacets)
            }

            final facetsDefaultSelectedConfig = grailsApplication.config.facets.defaultSelected
            if (!userFacets && facetsDefaultSelectedConfig) {
                userFacets = facetsDefaultSelectedConfig.trim().split(",")
                log.debug "facetsDefaultSelectedConfig = ${facetsDefaultSelectedConfig}"
                log.debug "userFacets = ${userFacets}"
                def facetKeys = defaultFacets.keySet()
                facetKeys.each {
                    defaultFacets.put(it, false)
                }
                userFacets.each {
                    defaultFacets.put(it, true)
                }
            }

            List dynamicFacets = []

            String[] requestedFacets = userFacets ?: filteredFacets

            if (grailsApplication.config.facets.includeDynamicFacets?.toString()?.toBoolean()) {
                // Sandbox only...
                time("sandbox only facets") {
                    dynamicFacets = webServicesService.getDynamicFacets(requestParams.q)
                    requestedFacets = postProcessingService.mergeRequestedFacets(requestedFacets as List, dynamicFacets)
                }
            }

            requestParams.facets = requestedFacets

            def wsStart = System.currentTimeMillis()
            JSONObject searchResults = time("full text search") { webServicesService.fullTextSearch(requestParams) }
            def wsTime = (System.currentTimeMillis() - wsStart)

            // If there's an error, treat it as an exception so error page can be shown
            if (searchResults.status == 'ERROR') {
                throw new Exception(searchResults.errorMessage)
            }

            //create a facet lookup map
            Map groupedFacetsMap = postProcessingService.getMapOfFacetResults(searchResults.facetResults)

            //grouped facets
            Map groupedFacets = postProcessingService.getAllGroupedFacets(configuredGroupedFacets, searchResults.facetResults, dynamicFacets)

            //remove qc from active facet map
            if (params?.qc) {
                def qc = params.qc
                if (searchResults?.activeFacetMap) {
                    def remove = null
                    searchResults?.activeFacetMap.each { k, v ->
                        if (k + ':' + v?.value == qc) {
                            remove = k
                        }
                    }
                    if (remove) searchResults?.activeFacetMap?.remove(remove)
                }

                if (searchResults?.activeFacetObj) {
                    def removeKey = null
                    def removeIdx = null
                    searchResults?.activeFacetObj.each { k, v ->
                        def idx = v.findIndexOf { it.value == qc }
                        if (idx > -1) {
                            removeKey = k
                            removeIdx = idx
                        }
                    }
                    if (removeKey && removeIdx != null) {
                        searchResults.activeFacetObj[removeKey].remove(removeIdx)
                    }
                }

            }

            def hasImages = postProcessingService.resultsHaveImages(searchResults)
            if(grailsApplication.config.alwaysshow.imagetab?.toString()?.toBoolean()){
                hasImages = true
            }

            def qualityCategories = time("quality categories") { qualityService.findAllEnabledCategories(requestParams.qualityProfile) }
            def qualityFiltersByLabel = time("quality filters by label") { qualityService.getEnabledFiltersByLabel(requestParams.qualityProfile) }
            def qualityTotalCount = time("quality total count") { qualityService.countTotalRecords(requestParams) }
            def groupedEnabledFilters = time("get grouped enabled filters") { qualityService.getGroupedEnabledFilters(requestParams.qualityProfile) }
            def qualityFilterDescriptionsByLabel = groupedEnabledFilters.collectEntries {[(it.key) : it.value*.description.join(' and ')] }

            def (fqInteract, dqInteract, UserFQColors, DQColors) = time("process user fq interactions") { postProcessingService.processUserFQInteraction(requestParams) }

            def messagePropertiesFile = time("message properties file") { webServicesService.getMessagesPropertiesFile() }
            def assertionCodeMap = time("assertionCodeMap") { webServicesService.getAssertionCodeMap() }
            def translatedFilterMap = postProcessingService.translateValues(groupedEnabledFilters, messagePropertiesFile, assertionCodeMap)

            log.debug "defaultFacets = ${defaultFacets}"

            OccurrenceNavigationDTO navigationDTO = new OccurrenceNavigationDTO();
            List<String> uuids = new ArrayList<String>();
            searchResults.occurrences.each { occ ->
                uuids.add(occ.uuid);
            }
            navigationDTO.setCurrentPageUUIDs(uuids);
            navigationDTO.setSearchRequestParams(requestParams);
            navigationDTO.setSearchRequestResultSize(searchResults.totalRecords);
            request.getSession().setAttribute(SESSION_NAVIGATION_DTO, navigationDTO);

            def inverseFilters = time("inverseFilters") { qualityService.getAllInverseCategoryFiltersForProfile(activeProfile) }

            def processingTime = (System.currentTimeMillis() - start)
            log.info ("Timing - list processing time: {} ms", processingTime)
            [
                    sr: searchResults,
                    searchRequestParams: requestParams,
                    defaultFacets: defaultFacets,
                    groupedFacets: groupedFacets,
                    groupedFacetsMap: groupedFacetsMap,
                    dynamicFacets: dynamicFacets,
                    translatedFilterMap: translatedFilterMap,
                    selectedDataResource: getSelectedResource(requestParams.q),
                    hasImages: hasImages,
                    showSpeciesImages: false,
                    overlayList: postProcessingService.getListOfLayers(requestParams),
                    sort: requestParams.sort,
                    dir: requestParams.dir,
                    userId: authService?.getUserId(),
                    userEmail: authService?.getEmail(),
                    processingTime: (System.currentTimeMillis() - start),
                    wsTime: wsTime,
                    qualityCategories: qualityCategories,
                    qualityFiltersByLabel: qualityFiltersByLabel,
                    qualityTotalCount: qualityTotalCount,
                    fqInteract: fqInteract,
                    qualityFilterDescriptionsByLabel: qualityFilterDescriptionsByLabel,
                    dqInteract: dqInteract,
                    UserFQColors: UserFQColors,
                    DQColors: DQColors,
                    activeProfile: activeProfile,
                    qualityProfiles: time("findAllEnabledProfiles") { qualityService.findAllEnabledProfiles(true) },
                    inverseFilters: inverseFilters
            ]

        } catch (Exception ex) {
            log.warn "Error getting search results: $ex.message", ex
            flash.message = "${ex.message}"
            render view:'../error'
        }
    }

    /**
     * Massage the request params with defaults and processing additional query params
     * @param requestParams The request params to normalise
     */
    private void normaliseRequestParams(SpatialSearchRequestParams requestParams) {
        requestParams.fq = params.list("fq") as String[] // override Grails binding which splits on internal commas in value

        log.debug "requestParams = ${requestParams}"


        List taxaQueries = (ArrayList<String>) params.list("taxa") // will be list for even one instance
        log.debug "skin.useAlaBie = ${grailsApplication.config.skin.useAlaBie}"
        log.debug "taxaQueries = ${taxaQueries} || q = ${requestParams.q}"

        if (grailsApplication.config.skin.useAlaBie?.toString()?.toBoolean() &&
                grailsApplication.config.bie.baseUrl && taxaQueries && taxaQueries[0]) {
            // check for list with empty string
            // taxa query - attempt GUID lookup
            List guidsForTaxa = webServicesService.getGuidsForTaxa(taxaQueries)
            def additionalQ = (params.q) ? " AND " + params.q : "" // advanced search form can provide both taxa and q params
            requestParams.q = postProcessingService.createQueryWithTaxaParam(taxaQueries, guidsForTaxa) + additionalQ
        } else if (!params.q && taxaQueries && taxaQueries[0]) {
            // Bypass BIE lookup and pass taxa query in as text
            List emptyGuidList = taxaQueries.clone().collect { it = ""} // list of empty strings, of equal size to taxaQueries
            requestParams.q = postProcessingService.createQueryWithTaxaParam(taxaQueries, emptyGuidList)
        }

        if (!requestParams.q) {
            requestParams.q = "*:*"
        }
    }

    def dataQualityExcludeCounts(SpatialSearchRequestParams requestParams) {
        normaliseRequestParams(requestParams)
        // assign profile here. Since WebServiceService.fullTextSearch always attach a profile before searching (so if profile in req is null it changes to 'Default' after search)
        // if incoming request has a null profile and we don't assign Default to it. it will never hit the cache
        webServicesService.populateProfile(requestParams)

        def qualityCategories = time("quality categories") { qualityService.findAllEnabledCategories(requestParams.qualityProfile) }
        def qualityExcludeCount = time("quality exclude count") { qualityService.getExcludeCount(qualityCategories, requestParams) }
        def result = qualityExcludeCount
        render result as JSON
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
                    if (userEmail && contacts != null && contacts.size() > 0) {
                        for (int i = 0; i < contacts.size(); i++) {
                            if (contacts.get(i).editor == true && userEmail.equalsIgnoreCase(contacts.get(i).contact.email)) {
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
                compareRecord = postProcessingService.augmentRecord(compareRecord) // adds some links to certain fields, etc

                // Retrieve Navigation DTO from session (if available)
                // to add the Previous/Next/Back to results buttons
                int searchOffset = 0;
                boolean displayNavigationButtons = false;
                boolean isFirstOccurrence = false;
                boolean isLastOccurrence = false;
                OccurrenceNavigationDTO navigationDTO = (OccurrenceNavigationDTO) request.getSession().getAttribute(SESSION_NAVIGATION_DTO);
                // Check if the Navigation DTO in session is consistent (ex: if we navigate in several tabs)
                if (navigationDTO && navigationDTO.getCurrentPageUUIDs() && navigationDTO.getCurrentPageUUIDs().contains(id)) {
                    displayNavigationButtons = true;
                    navigationDTO.setCurrentUUID(id);
                    searchOffset = (navigationDTO.getSearchRequestParams() && navigationDTO.getSearchRequestParams().offset) ? navigationDTO.getSearchRequestParams().offset : 0;
                    request.getSession().setAttribute(SESSION_NAVIGATION_DTO, navigationDTO);

                    // is first occurrence?
                    int indexInPage = navigationDTO.getCurrentPageUUIDs().indexOf(id);
                    isFirstOccurrence = (searchOffset == 0) && (indexInPage == 0);

                    // is last occurrence?
                    int indexInResults = searchOffset + indexInPage;
                    isLastOccurrence = (indexInResults == (navigationDTO.getSearchRequestResultSize()-1));
                }

                render(view: 'show', model:
                [
                        record: record,
                        uuid: id,
                        searchOffset: searchOffset,
                        displayNavigationButtons: displayNavigationButtons,
                        isFirstOccurrence: isFirstOccurrence,
                        isLastOccurrence: isLastOccurrence,
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
                ])
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
     * Go to the next occurrences of the search results
     * Use the Navigation DTO from session (if available)
     */
    def next() {
        moveCursorAndShow(1);
    }

    /**
     * Go to the previous occurrences of the search results
     * Use the Navigation DTO from session (if available)
     */
    def previous() {
        moveCursorAndShow(-1);
    }

    def moveCursorAndShow(int direction) {
        OccurrenceNavigationDTO navigationDTO = (OccurrenceNavigationDTO) request.getSession().getAttribute(SESSION_NAVIGATION_DTO);
        if (navigationDTO && navigationDTO.getCurrentPageUUIDs() && navigationDTO.getCurrentUUID()) {
            int currentIndex = navigationDTO.getCurrentPageUUIDs().indexOf(navigationDTO.getCurrentUUID())
            if (currentIndex != -1) {
                int newIndex = currentIndex + direction;
                if (newIndex >= 0 && newIndex < navigationDTO.getCurrentPageUUIDs().size()) {
                    // New occurrence is in current page
                    redirect (controller:'occurrence', action:'show', id:navigationDTO.getCurrentPageUUIDs().get(newIndex));
                    return;
                }
                else {
                    // New occurrence is in another page
                    SpatialSearchRequestParams requestParams = navigationDTO.getSearchRequestParams();
                    if (requestParams && requestParams.offset && requestParams.pageSize) {
                        Integer newOffset = requestParams.offset + direction * requestParams.pageSize;
                        requestParams.offset = newOffset;
                        // Execute new SolR query to get the other page (next or previous)
                        JSONObject searchResults = webServicesService.fullTextSearch(requestParams);
                        if (searchResults && searchResults.occurrences && searchResults.occurrences.size() > 0) {
                            List<String> uuids = new ArrayList<String>();
                            searchResults.occurrences.each { occ ->
                                uuids.add(occ.uuid);
                            }
                            String newUUID = (direction > 0) ? uuids.first() : uuids.last();
                            navigationDTO.setCurrentPageUUIDs(uuids);
                            navigationDTO.setSearchRequestParams(requestParams);
                            navigationDTO.setCurrentUUID(newUUID);
                            request.getSession().setAttribute(SESSION_NAVIGATION_DTO, navigationDTO);
                            // Redirect to the new occurrence
                            redirect (controller:'occurrence', action:'show', id:newUUID);
                            return;
                        }
                    }
                }
            }
        }
        // Redirect to the default list of occurrences in case of error
        // ex: if we call /next or /previous directly, without Navigation DTO in session
        redirect (controller:'occurrence', action:'list');
        return;
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
     * Uses http://dev.maxmind.com/geoip/geoip2/geolite2/
     *
     * @return
     */
    def exploreYourArea() {
        def radius = params.radius?:5
        Map radiusToZoomLevelMap = grailsApplication.config.exploreYourArea.zoomLevels // zoom levels for the various radius sizes

        def lat = params.latitude
        def lng = params.longitude

        if (!(lat && lng)) {
            // try to determine lat/lng from IP address via lookup with MaxMind GeoLite2 City
            Location location = geoIpService.getLocation(request)

            if (location) {
                log.debug "location = ${location}"
                lat = location.latitude
                lng = location.longitude
            } else {
                lat = grailsApplication.config.exploreYourArea.lat
                lng = grailsApplication.config.exploreYourArea.lng
            }
        }

        [
                latitude: lat,
                longitude: lng,
                radius: radius,
                zoom: radiusToZoomLevelMap.get(radius?.toString()),
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
                fg.guids = fr.fieldResult?.label
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
        String contextPath = request.contextPath
        fg.link = serverName + contextPath + "/occurrences/search?" + request.getQueryString()
        //log.info "FG json = " + fg.getJson()

        try {
            JSONElement fgPostObj = webServicesService.postJsonElements(grailsApplication.config.fieldguide.url + "/generate", fg.getJson())
            //log.info "fgFileId = ${fgFileId}"

            if (fgPostObj.fileId) {
                response.sendRedirect(grailsApplication.config.fieldguide.url + "/guide/"+fgPostObj.fileId)
            } else {
                flash.message = "No field guide found for requested taxa."
                render view:'../error'
            }
        } catch (Exception ex) {
            flash.message = "Error generating field guide PDF. ${ex}"
            log.error ex.message, ex
            render view:'../error'
        }
    }

    def facets(SpatialSearchRequestParams requestParams) {
        requestParams.fq = params.list("fq") as String[] // override Grails binding which splits on internal commas in value
        render webServicesService.facetSearch(requestParams) as JSON
    }

    def facetsDownload(SpatialSearchRequestParams requestParams) {
        requestParams.fq = params.list("fq") as String[] // override Grails binding which splits on internal commas in value
        response.setHeader('Content-Disposition', 'attachment; filename="data.csv"')
        render webServicesService.facetCSVDownload(requestParams), contentType: 'text/csv', fileName: 'data.csv'
    }

    def exists(String id) {
        def record = webServicesService.getRecord(id, false)
        if (record.keySet()) {
            log.trace("{}", record)
            def result = "${record?.processed?.classification?.scientificName ?: record?.raw?.classification?.scientificName ?: ''}, ${record?.processed?.location?.stateProvince ?: record?.raw?.location?.stateProvince ?: ''}, ${record?.processed?.location?.decimalLongitude ?: record?.raw?.location?.decimalLongitude ?: ''}, ${record?.processed?.location?.decimalLatitude ?: record?.raw?.location?.decimalLatitude ?: ''}, ${record?.processed?.event?.eventDate ?: record?.raw?.event?.eventDate ?: ''}"
            render text: result
        } else {
            render status: SC_NOT_FOUND, text: ''
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

    def getExcluded(SpatialSearchRequestParams requestParams) {
        def data = [:]
        QualityProfile profile = qualityService.activeProfile(requestParams.qualityProfile)
        data.count = qualityService.getExcludeCount(params.categoryLabel, profile.getCategories(), requestParams)
        render data as JSON
    }

    def getAlerts() {
        String userId = authService?.getUserId()
        if (userId == null) {
            response.status = 404
            render ([error: 'userId must be supplied to get alerts'] as JSON)
        } else {
            render webServicesService.getAlerts(userId) as JSON
        }
    }

    def addAlert() {
        String userId = authService?.getUserId()
        if (userId == null) {
            response.status = 404
            render ([error: 'userId must be supplied to add alert'] as JSON)
        } else {
            render webServicesService.addAlert(userId, params.queryId) as JSON
        }
    }

    def deleteAlert() {
        String userId = authService?.getUserId()
        if (userId == null) {
            response.status = 404
            render ([error: 'userId must be supplied to delete alert'] as JSON)
        } else {
            render webServicesService.deleteAlert(userId, params.queryId) as JSON
        }
    }
}
