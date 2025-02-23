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
import com.maxmind.geoip2.record.Location
import grails.converters.JSON
import groovy.json.JsonSlurper
import groovy.util.logging.Slf4j
import org.grails.web.json.JSONArray
import org.grails.web.json.JSONElement
import org.grails.web.json.JSONObject
import org.springframework.beans.factory.annotation.Value

import javax.servlet.http.HttpServletRequest
import java.text.SimpleDateFormat

import static au.org.ala.biocache.hubs.TimingUtils.time
import static javax.servlet.http.HttpServletResponse.SC_NOT_FOUND

/**
 * Controller for occurrence searches and records
 */
@Slf4j
class OccurrenceController {
    def webServicesService, facetsCacheService, postProcessingService, authService, qualityService, userService, doiService, eventsService

    def SESSION_NAVIGATION_DTO = "SESSION_NAVIGATION_DTO"

    @Value('${dataquality.enabled}')
    boolean dataQualityEnabled

    GeoIpService geoIpService

    def ENVIRO_LAYER = "el"
    def CONTEXT_LAYER = "cl"

    def index() {
        redirect action: "search"
    }

    def dataResource(SpatialSearchRequestParams requestParams) {
        requestParams.q = "data_resource_uid:" + params.uid
        def model = list(requestParams)
        render(view: 'list', model: model)
    }

    /**
     * Perform a full text search
     *
     * @param requestParams
     * @return
     */
    def list(SpatialSearchRequestParams requestParams) {
        def start = System.currentTimeMillis()

        // get the user preference settings
        def userPref = userService.getUserPref(authService?.getUserId(), request)
        // apply the user preference settings
        normaliseRequestParams(requestParams, userPref)

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

            final facetsDefaultSelectedConfig = grailsApplication.config.getProperty('facets.defaultSelected')
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

            String[] requestedFacets = userFacets ?: filteredFacets

            // Disable the biocache-service request for facets. They are new retrieved dynamically by the client
            requestParams.facets = null

            def wsStart = System.currentTimeMillis()
            JSONObject searchResults = time("full text search") { webServicesService.fullTextSearch(requestParams) }
            def wsTime = (System.currentTimeMillis() - wsStart)

            // If there's an error, treat it as an exception so error page can be shown
            if (searchResults.errorType) {
                throw new Exception(searchResults.message)
            }

            //create a facet lookup map
            Map groupedFacetsMap = postProcessingService.getMapOfFacetResults(requestedFacets)

            //grouped facets
            Map groupedFacets = postProcessingService.getAllGroupedFacets(configuredGroupedFacets, groupedFacetsMap)

            //grouped facets, but only those requested and not in the activeFacetMap
            Map groupedFacetsRequested = postProcessingService.getRequestedGroupedFacets(configuredGroupedFacets, groupedFacetsMap, requestedFacets, searchResults?.activeFacetMap)

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
            if (grailsApplication.config.getProperty('alwaysshow.imagetab', Boolean, false)) {
                hasImages = true
            }

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

            def resultData =
                    [
                            sr                  : searchResults,
                            searchRequestParams : requestParams,
                            defaultFacets       : defaultFacets,
                            groupedFacets       : groupedFacets,
                            groupedFacetsRequested: groupedFacetsRequested,
                            groupedFacetsMap    : groupedFacetsMap,
                            selectedDataResource: getSelectedResource(requestParams.q),
                            hasImages           : hasImages,
                            showSpeciesImages   : false,
                            overlayList         : postProcessingService.getListOfLayers(requestParams),
                            sort                : requestParams.sort,
                            dir                 : requestParams.dir,
                            userId              : authService?.getUserId(),
                            userEmail           : authService?.getEmail(),
                            processingTime      : (System.currentTimeMillis() - start),
                            wsTime              : wsTime
                    ]

            if (dataQualityEnabled) {
                def qualityCategories = time("quality categories") { qualityService.findAllEnabledCategories(requestParams.qualityProfile) }
                def qualityFiltersByLabel = [:]
                def groupedEnabledFilters = [:]
                def qualityFilterDescriptionsByLabel = [:]
                def translatedFilterMap = [:]
                def interactionMap = [:]
                // if disable all quality filters, we don't need to retrieve them, it saves time
                if (!requestParams.disableAllQualityFilters) {
                    qualityFiltersByLabel = time("quality filters by label") { qualityService.getEnabledFiltersByLabel(requestParams.qualityProfile) }
                    groupedEnabledFilters = time("get grouped enabled filters") { qualityService.getGroupedEnabledFilters(requestParams.qualityProfile) }
                    qualityFilterDescriptionsByLabel = groupedEnabledFilters.collectEntries { [(it.key): it.value*.description] }
                    interactionMap = time("process user fq interactions") { postProcessingService.processUserFQInteraction(requestParams, searchResults?.activeFacetObj) }

                    def messagePropertiesFile = time("message properties file") { webServicesService.getMessagesPropertiesFile() }
                    def assertionCodeMap = time("assertionCodeMap") { webServicesService.getAssertionCodeMap() }
                    translatedFilterMap = postProcessingService.translateValues(groupedEnabledFilters, messagePropertiesFile, assertionCodeMap)
                }
                def qualityTotalCount = time("quality total count") { qualityService.countTotalRecords(requestParams) }

                def activeProfile = time("active profile") { qualityService.activeProfile(requestParams.qualityProfile) }
                def inverseFilters = time("inverseFilters") { qualityService.getAllInverseCategoryFiltersForProfile(activeProfile) }

                // params.qualityProfile is used to construct exclude count link, we need to set with the actual profile being used
                params.qualityProfile = activeProfile?.shortName
                resultData.translatedFilterMap = translatedFilterMap
                resultData.qualityCategories = qualityCategories
                resultData.qualityFiltersByLabel = qualityFiltersByLabel
                resultData.qualityTotalCount = qualityTotalCount
                resultData.fqInteract = interactionMap.fqInteract ?: [:]
                resultData.qualityFilterDescriptionsByLabel = qualityFilterDescriptionsByLabel
                resultData.dqInteract = interactionMap.dqInteract ?: [:]
                resultData.UserFQColors = interactionMap.UserFQColors ?: [:]
                resultData.DQColors = interactionMap.DQColors ?: [:]
                resultData.activeProfile = activeProfile
                resultData.defaultProfileName = qualityService.activeProfile()?.shortName
                resultData.expandProfileDetails = getProfileDetailExpandState(userPref, request)
                resultData.userPref = userPref
                resultData.qualityProfiles = time("findAllEnabledProfiles") { qualityService.findAllEnabledProfiles(true) }
                resultData.inverseFilters = inverseFilters
            }

            def processingTime = (System.currentTimeMillis() - start)
            log.info("Timing - list processing time: {} ms", processingTime)

            resultData
        } catch (Exception ex) {
            log.warn "Error getting search results: $ex.message", ex
            flash.message = "${ex.message}"
            render view: '../error'
        }
    }

    /**
     * Massage the request params with defaults and processing additional query params
     * @param requestParams The request params to normalise
     */
    private void normaliseRequestParams(SpatialSearchRequestParams requestParams, userPref = null) {
        requestParams.fq = params.list("fq") as String[] // override Grails binding which splits on internal commas in value

        log.debug "requestParams = ${requestParams}"


        List taxaQueries = (ArrayList<String>) params.list("taxa") // will be list for even one instance
        log.debug "skin.useAlaBie = ${grailsApplication.config.getProperty('skin.useAlaBie')}"
        log.debug "taxaQueries = ${taxaQueries} || q = ${requestParams.q}"

        if (grailsApplication.config.getProperty('skin.useAlaBie', Boolean, false) &&
                grailsApplication.config.getProperty('bieService.baseUrl') && taxaQueries && taxaQueries[0]) {
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


        if (!requestParams.disableAllQualityFilters && userPref?.size() > 0) {
            // find all enabled profiles, this list will be used for both requested profile and user default profile
            def enabledProfiles = qualityService.findAllEnabledProfiles(true)
            def requestProfileValid = requestParams.qualityProfile && enabledProfiles?.any { it.shortName == requestParams.qualityProfile }

            // if no valid profile setting, see if we can get any preference settings
            if (!requestProfileValid) {
                // if user disables all
                if (userPref.disableAll == true) {
                    requestParams.disableAllQualityFilters = true
                } else {
                    // apply user preferred profile then system default
                    def profileToUse = ''
                    def profileToUseFullName = ''

                    def userPrefProfileValid = userPref.dataProfile && enabledProfiles?.any { it.shortName == userPref.dataProfile }
                    if (userPrefProfileValid) {
                        profileToUse = userPref.dataProfile
                        profileToUseFullName = enabledProfiles?.find { it.shortName == userPref.dataProfile }?.name
                    } else {
                        def systemDefaultProfile = qualityService.activeProfile()
                        profileToUse = systemDefaultProfile?.shortName
                        profileToUseFullName = systemDefaultProfile.name
                    }

                    if (userPref.disabledItems) {
                        requestParams.disableQualityFilter.addAll(userPref.disabledItems)
                    }

                    // profile not null then it's disabled or not-exist
                    if (requestParams.qualityProfile) {
                        // to display full name of the profile being used
                        flash.message = "The selected profile ${requestParams.qualityProfile} is not available, ${profileToUseFullName} is currently applied.".toString()
                    }
                    requestParams.qualityProfile = profileToUse
                }
            }
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
        redirect(action: "list", params: [q: "lsid:" + id])
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

    private def getSelectedResource(query) {
        if (query.contains("data_resource_uid:")) {
            query.replace("data_resource_uid:", "")
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
            Boolean hasClubView = request.isUserInRole("${grailsApplication.config.getProperty('clubRoleForHub')}")
            JSONObject record = webServicesService.getRecord(id, hasClubView)
            log.debug "hasClubView = ${hasClubView} || ${grailsApplication.config.getProperty('clubRoleForHub')}"

            // if backend can't find the record, a JSON error with a field 'message' will be returned
            // TODO: backend can refine the response to put like errorType into returned JSON
            if (record && record.size() > 1) {
                JSONObject compareRecord = webServicesService.getCompareRecord(id)
                JSONObject collectionInfo = null
                JSONArray contacts = null

                if (record.processed.attribution.collectionUid) {
                    collectionInfo = webServicesService.getCollectionInfo(record.processed.attribution.collectionUid)
                    contacts = webServicesService.getCollectionContact(record.processed.attribution.collectionUid)
                }

                if (record.raw.attribution.dataResourceUid && (contacts == null)) {
                    try {
                        contacts = webServicesService.getDataresourceContact(record.raw.attribution.dataResourceUid)
                    } catch (Exception e) {
                        log.warn("Problem retrieving contact details for ${record.raw.attribution.dataResourceUid} - " + e.getMessage())
                    }
                }

                populateSound(record)

                String userEmail = authService?.getEmail()
                Boolean isCollectionAdmin = false
                Boolean userHasRoleAdmin = false

                // Check (optionally comma-separated) list of authorise.roles - if we get `true` then stop checking
                grailsApplication.config.getProperty('authorise.roles', String, "").tokenize(',').each {
                    !userHasRoleAdmin ? userHasRoleAdmin = authService?.userInRole( it ) : null
                }

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
                    isLastOccurrence = (indexInResults == (navigationDTO.getSearchRequestResultSize() - 1));
                }

                render(view: 'show', model:
                        [
                                record                  : record,
                                uuid                    : id,
                                searchOffset            : searchOffset,
                                displayNavigationButtons: displayNavigationButtons,
                                isFirstOccurrence       : isFirstOccurrence,
                                isLastOccurrence        : isLastOccurrence,
                                compareRecord           : compareRecord,
                                groupedAssertions       : groupedAssertions,
                                collectionName          : collectionInfo?.name,
                                collectionLogo          : collectionInfo?.institutionLogoUrl,
                                collectionInstitution   : collectionInfo?.institution,
                                isCollectionAdmin       : isCollectionAdmin,
                                contacts                : contacts,
                                queryAssertions         : null, // TODO implement this
                                referencedPublications  : doiService.getDoiInfo(record),
                                eventHierarchy          : eventsService.getEventHierarchy(record),
                                duplicateRecordDetails  : webServicesService.getDuplicateRecordDetails(record),
                                dataResourceCodes       : facetsCacheService.getFacetNamesFor("data_resource_uid"), // TODO move string value to config file
                                clubView                : hasClubView,
                                errorCodes              : webServicesService.getErrorCodes(),
                                metadataForOutlierLayers: postProcessingService.getMetadataForOutlierLayers(record, layersMetaData),
                                environmentalSampleInfo : postProcessingService.getLayerSampleInfo(ENVIRO_LAYER, record, layersMetaData),
                                contextualSampleInfo    : postProcessingService.getLayerSampleInfo(CONTEXT_LAYER, record, layersMetaData),
                                skin                    : grailsApplication.config.getProperty('skin.layout')
                        ])
            } else {
                if (record?.message == 'Unrecognised UID') {
                    flash.message = "No record found with id: ${id}"
                }
                render view: '../error'
            }
        } catch (Exception ex) {
            log.warn "Error getting record details: $ex.message", ex
            flash.message = "${ex.message}"

            if (ex.getMessage() && ex.getMessage().contains("HTTP 404")) {
                render view: '../occurrenceNotFound'
            } else {
                render view: '../error'
            }
        }
    }

    /**
     * Retrieve sound detail link and sound file metadata
     */
    private def populateSound(JSONObject record) {
        if (record?.sounds) {
            // record.sounds is a list of mediaDTO
            for (JSONObject mediaDTO in record.sounds) {
                String soundUrl = mediaDTO?.alternativeFormats?.'audio/mpeg'
                if (soundUrl) {
                    String[] parts = soundUrl.split("imageId=")
                    if (parts.length >= 2) {
                        log.debug("image id = " + parts[1])
                        mediaDTO.alternativeFormats.'detailLink' = "${grailsApplication.config.getProperty('images.baseUrl')}/image/${parts[1].encodeAsURL()}"
                        mediaDTO.metadata = webServicesService.getImageMetadata(parts[1])
                    }
                }
            }
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
                    redirect(controller: 'occurrence', action: 'show', id: navigationDTO.getCurrentPageUUIDs().get(newIndex));
                    return;
                } else {
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
                            redirect(controller: 'occurrence', action: 'show', id: newUUID);
                            return;
                        }
                    }
                }
            }
        }
        // Redirect to the default list of occurrences in case of error
        // ex: if we call /next or /previous directly, without Navigation DTO in session
        redirect(controller: 'occurrence', action: 'list');
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
                [record       : record,
                 uuid         : id,
                 compareRecord: compareRecord
                ]
            } else {
                flash.message = "No record found for id: ${id}"
                render view: '../error'
            }
        } catch (Exception ex) {
            flash.message = "${ex.message}"
            render view: '../error'
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
        Map radiusToZoomLevelMap = grailsApplication.config.getProperty('exploreYourArea.zoomLevels', Map) // zoom levels for the various radius sizes

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
                lat = grailsApplication.config.getProperty('exploreYourArea.lat')
                lng = grailsApplication.config.getProperty('exploreYourArea.lng')
            }
        }

        [
                latitude      : lat,
                longitude     : lng,
                radius        : radius,
                zoom          : radiusToZoomLevelMap.get(radius?.toString()),
                location      : grailsApplication.config.getProperty('exploreYourArea.location'),
                speciesPageUrl: grailsApplication.config.getProperty('bie.baseUrl') + "/species/"
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
            render view: '../error'
            return
        }

        SimpleDateFormat sdf = new SimpleDateFormat("dd MMMMM yyyy")
        //set the properties of the query
        fg.title = "This document was generated on " + sdf.format(new Date())
        String serverName = grailsApplication.config.getProperty('serverName') ?: grailsApplication.config.getProperty('security.cas.appServerName')
        String contextPath = request.contextPath
        fg.link = serverName + contextPath + "/occurrences/search?" + request.getQueryString()
        //log.info "FG json = " + fg.getJson()

        try {
            JSONElement fgPostObj = webServicesService.postJsonElements(grailsApplication.config.getProperty('fieldguide.url') + "/generate", fg.getMap())
            //log.info "fgFileId = ${fgFileId}"

            if (fgPostObj.fileId) {
                response.sendRedirect(grailsApplication.config.getProperty('fieldguide.url') + "/guide/" + fgPostObj.fileId)
            } else {
                flash.message = "No field guide found for requested taxa."
                render view: '../error'
            }
        } catch (Exception ex) {
            flash.message = "Error generating field guide PDF. ${ex}"
            log.error ex.message, ex
            render view: '../error'
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
        // getRecord can return either 1 record or a list of records
        // if a list returned, asking user to be more specific
        def record = webServicesService.getRecord(id, false)
        if (record?.occurrences) {
            render([error: 'id not unique'] as JSON)
        } else if (record?.keySet() && record?.processed) {
            def rslt = [:]
            rslt.scientificName = record?.processed?.classification?.scientificName ?: (record?.raw?.classification?.scientificName ?: '')
            rslt.stateProvince = record?.processed?.location?.stateProvince ?: (record?.raw?.location?.stateProvince ?: '')
            rslt.decimalLongitude = record?.processed?.location?.decimalLongitude ?: (record?.raw?.location?.decimalLongitude ?: '')
            rslt.decimalLatitude = record?.processed?.location?.decimalLatitude ?: (record?.raw?.location?.decimalLatitude ?: '')
            rslt.eventDate = record?.processed?.event?.eventDate ?: (record?.raw?.event?.eventDate ?: '')
            render rslt as JSON
        } else {
            render status: SC_NOT_FOUND, text: ''
        }
    }

    /**
     * JSON webservices for debugging/testing
     */
    def searchJson(SpatialSearchRequestParams requestParams) {
        render webServicesService.fullTextSearch(requestParams) as JSON
    }

    /**
     * JSON webservices for debugging/testing
     */
    def showJson(String id) {
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

    // profile details expand/collapse will be kept for whole session
    private def getProfileDetailExpandState(userPref, HttpServletRequest request) {
        def expandKey = "${grailsApplication.config.getProperty('dataquality.expandKey')}"
        def rawCookie = PostProcessingService.getCookieValue(request.getCookies(), expandKey, null)

        // if already have expand/collapse settings, use it to overwrite user preference
        if (rawCookie != null) {
            try {
                // apply session settings
                def val = new JsonSlurper().parseText(URLDecoder.decode(rawCookie, "UTF-8"))
                return val.expand
            } catch (UnsupportedEncodingException ex) {
                log.error(ex.getMessage(), ex)
            }
        }
        // rawCookie == null means the start of session so use default user settings

        return userPref.expand
    }
}
