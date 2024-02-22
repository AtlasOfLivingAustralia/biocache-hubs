/*
 * Copyright (C) 2017. Atlas of Living Australia
 * All Rights Reserved.
 * The contents of this file are subject to the Mozilla Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/MPL/
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 */

package au.org.ala.biocache.hubs

import org.apache.commons.lang.StringUtils
import org.apache.commons.lang.WordUtils
import org.grails.web.json.JSONArray
import org.grails.web.json.JSONObject

import javax.servlet.http.Cookie
import javax.servlet.http.HttpServletRequest
import java.util.regex.Matcher

/**
 * Service to perform processing of data between the DAO and View layers
 */
class PostProcessingService {
    def grailsApplication, webServicesService, qualityService

    /**
     * Determine if the record contains images
     *
     * @param searchResults
     * @return Boolean
     */
    def Boolean resultsHaveImages(JSONObject searchResults) {
        Boolean hasImages = false
        searchResults?.facetResults?.each { fr ->
            if (fr.fieldName == "multimedia") {
                fr.fieldResult.each {
                    if (it.label =~ /(?i)image/) {
                        hasImages = true
                    }
                }
            }
        }
        log.debug "hasImages = ${hasImages}"
        hasImages
    }

    /**
     * Get the assertions grouped by assertion code.
     *
     * @see <a href="http://code.google.com/p/ala-hubs/source/browse/trunk/hubs-webapp/src/main/java/org/ala/hubs/util/AssertionUtils.java">
     *      http://code.google.com/p/ala-hubs/source/browse/trunk/hubs-webapp/src/main/java/org/ala/hubs/util/AssertionUtils.java
     *  </a>
     *
     * @param id
     * @param record
     * @param currentUserId
     * @return
     */
    def List getGroupedAssertions(JSONArray userAssertions, String currentUserId) {
        Map grouped = [:]

        // Closure to call for both user and query assertions
        def withEachAssertion = { qa ->
            if (!(qa.containsKey('code') || qa.containsKey('assertionType'))) {
                log.error "Assertion is missing required fields/keys: code || assertionType: ${qa}"
                return false
            }
            log.debug "assertion (qa) = ${qa}"
            def a = grouped.get(qa.code ?: qa.assertionType) // multiple assertions with same same code are added as a list to the map via its code

            if (!a) {
                a = qa
                a.name = qa.name ?: qa.assertionType
                a.users = []
                grouped.put(qa.code ?: qa.assertionType, a)
            }

            //add the extra users who have made the same assertion
            Map u = [:]
            u.email = qa.userId ?: qa.userEmail
            u.displayname = qa.userDisplayName ?: qa.userName
            a.users.add(u) // add to list of users for this assertion

            if (currentUserId && currentUserId == qa.userId) {
                a.assertionByUser = true
                a.usersAssertionUuid = qa.uuid
            }
        }

        userAssertions.each {
            withEachAssertion(it)
        }

//        queryAssertions.each {
//            withEachAssertion(it)
//        }

        List groupedValues = []
        groupedValues.addAll(grouped.values())
        // sort list by the name field
        groupedValues.sort { a, b ->
            a.name <=> b.name
        }

        //log.debug "groupedValues = ${groupedValues}"
        return groupedValues
    }

    /**
     * Associate the layers metadata with a record's layers values
     */
    private List getLayerSampleInfo(String layerType, JSONObject record, Map layersMetaData) {
        def sampleInfo = []

        if (record.processed[layerType]) {
            record.processed[layerType].each {
                String key = it.key.trim()
                String value = it.value

                if (layersMetaData.containsKey(key)) {
                    Map metaMap = layersMetaData.get(key)
                    metaMap.value = value
                    sampleInfo.add(metaMap)
                }
            }
        }

        return sampleInfo.sort { a, b -> (a.classification1 <=> b.classification1 ?: a.layerDisplayName <=> b.layerDisplayName) }
    }

    /**
     * Build a LinkedHashMap form of the facets to display in the customise drop down div
     *
     * @param defaultFacets
     * @return LinkedHashMap facetsMap
     */
    def LinkedHashMap getAllFacets(List defaultFacets) {
        LinkedHashMap<String, Boolean> facetsMap = new LinkedHashMap<String, Boolean>()
        List orderedFacets = []
        List facetsToInclude = grailsApplication.config.getProperty('facets.include', List, [])
        List facetsToExclude = grailsApplication.config.getProperty('facets.exclude', List, [])
        List facetsToHide = grailsApplication.config.getProperty('facets.hide', List, [])
        List customOrder = grailsApplication.config.getProperty('facets.customOrder', List, [])
        List allFacets = new ArrayList(defaultFacets)
        allFacets.addAll(facetsToInclude)

        // check if custom facet order is specified
        customOrder.each {
            orderedFacets.add(it) // add to 'order' list
            allFacets.remove(it)  // remove from 'all' list
        }

        // add any remaining values not defined in facetsCustomOrder
        allFacets.each {
            orderedFacets.add(it)
        }

        orderedFacets.each {
            if (it && !facetsToExclude.contains(it)) {
                // only process facets that NOT in exclude list
                // Map value is true|false (true is to include facet in search facets list)
                facetsMap.put(it, !facetsToHide.contains(it))
            }
        }
        log.debug "facetsMap =${facetsMap}"
        return facetsMap
    }

    /**
     * Filter the Map of all facets to produce a list of only the "active" or selected
     * facets
     *
     * @param finalFacetsMap
     * @return
     */
    def String[] getFilteredFacets(LinkedHashMap<String, Boolean> finalFacetsMap) {
        List finalFacets = []

        for (String key : finalFacetsMap.keySet()) {
            // only include facets that are not "hidden" - Boolean "value" is false
            if (finalFacetsMap.get(key)) {
                finalFacets.add(key);
            }
        }

        //log.debug("FinalFacets = " + StringUtils.join(finalFacets, "|"));
        String[] filteredFacets = finalFacets.toArray(new String[finalFacets.size()]);

        return filteredFacets
    }

    /**
     * Read the request cookie to determine which facets are active
     *
     * @param request
     * @return
     */
    def String[] getFacetsFromCookie(HttpServletRequest request) {

        String userFacets = null
        String[] facets = null
        String rawCookie = getCookieValue(request.getCookies(), "user_facets", null)

        if (rawCookie) {
            try {
                userFacets = URLDecoder.decode(rawCookie, "UTF-8")
            } catch (UnsupportedEncodingException ex) {
                log.error(ex.getMessage(), ex)
            }

            if (!StringUtils.isBlank(userFacets)) {
                facets = userFacets.split(",")
            }
        }

        return facets
    }

    /**
     * Utility method for getting a named cookie value from the HttpServletRepsonse cookies array
     *
     * @param cookies
     * @param cookieName
     * @param defaultValue
     * @return
     */
    static String getCookieValue(Cookie[] cookies, String cookieName, String defaultValue) {
        String cookieValue = defaultValue // fall back

        cookies.each { cookie ->
            if (cookie.name == cookieName) {
                cookieValue = cookie.value
            }
        }

        return cookieValue
    }

    /**
     * Merge requested and custom facets
     *
     * @param filteredFacets
     * @param userFacets
     * @return
     */
    String[] mergeRequestedFacets(List requestedFacets, List customFacets) {
        List customFacetsFlat = customFacets.collect { it.name }
        requestedFacets.addAll(0, customFacetsFlat)
        requestedFacets
    }

    /**
     * Generate SOLR query from a taxa[] query
     *
     * @param taxaQueries
     * @param guidsForTaxa
     * @return
     */
    def String createQueryWithTaxaParam(List taxaQueries, List guidsForTaxa) {
        String query
        List expandedQueries = []

        if (taxaQueries.size() != guidsForTaxa.size()) {
            // Both Lists must the same size
            throw new IllegalArgumentException("Arguments (List) are not the same size: taxaQueries.size() (${taxaQueries.size()}) != guidsForTaxa.size() (${guidsForTaxa.size()})");
        }

        log.info "taxaQueries=${taxaQueries}||guidsForTaxa=${guidsForTaxa}"

        if (taxaQueries.size() > 1) {
            // multiple taxa params (array)
            guidsForTaxa.eachWithIndex { guid, i ->
                if (guid) {
                    expandedQueries.add("lsid:" + guid)
                } else {
                    expandedQueries.add("text:\"" + taxaQueries[i] + "\"")
                }
            }
            query = "(" + expandedQueries.join(" OR ") + ")"
        } else {
            // single taxa param
            log.info "taxaQueries[0] = ${taxaQueries[0]} || guidsForTaxa[0] = ${guidsForTaxa[0]}"
            if (taxaQueries[0]) {
                query = (guidsForTaxa[0]) ? "lsid:" + guidsForTaxa[0] : "text:\"" + taxaQueries[0] + "\""
            } else {
                query = (guidsForTaxa[0]) ? "lsid:" + guidsForTaxa[0] : ""
            }

        }

        log.info "query = ${query}"

        return query
    }

    /**
     * Add layers metadata to outlier for layer record attributes
     *
     * @param record
     * @param layersMetaData
     * @return
     */
    def List getMetadataForOutlierLayers(JSONObject record, Map layersMetaData) {
        List metdataForOutlierLayers = []

        if (record.processed.occurrence.outlierForLayers) {
            record.processed.occurrence.outlierForLayers.each {
                if (layersMetaData.containsKey(it)) {
                    metdataForOutlierLayers.add(layersMetaData.get(it))
                }
            }
        }

        metdataForOutlierLayers
    }

    /**
     * Create a Map of facet fields for a "lookup" in _facets.gsp
     * Also normalises some fields (decade)
     *
     * @param facetResults
     * @return
     */
    def Map getMapOfFacetResults(JSONArray facetResults) {
        Map facetMap = [:]

        facetResults.each { fr ->
            def facet = fr.fieldName

            if (facet == "occurrence_year") {
                facet = "decade"
            }

            facetMap.put(facet, fr)
        }

        facetMap
    }

    /**
     * Add any ungrouped facets from search results to the groupedFacetsMap
     * used to construct the facets column in search results.
     *
     * @param groupedFacets
     * @param ungroupedFacetsList
     * @return
     */
    def Map getAllGroupedFacets(Map groupedFacets, def facetResults, dynamicFacets) {
        List ungroupedFacetsList = getUngroupedFacetsList(groupedFacets, getMapOfFacetResults(facetResults))
        def finalGroupedFacets = groupedFacets.clone()
        def dynamicFacetNames = dynamicFacets.collect { it.name }
        finalGroupedFacets.put("Ungrouped", [])
        ungroupedFacetsList.each { facet ->
            if (dynamicFacetNames.contains(facet)) {
                finalGroupedFacets.get("Custom").add(facet)
            } else {
                finalGroupedFacets.get("Ungrouped").add(facet)
            }
        }
        finalGroupedFacets
    }

    /**
     * Get a list of facet fields (from search results) that are
     * NOT in the grouped facets Map.
     *
     * @param groupedFacets
     * @param facetResults
     * @return
     */
    def List getUngroupedFacetsList(Map groupedFacets, def facetResults) {
        def groupedFacetsList = []
        def ungroupedFacetsList = []
        // get a flat list of facets in groupedFacets (search independent)
        groupedFacets.each { grp ->
            groupedFacetsList.addAll(grp.value)
        }

        facetResults.each {
            if (!groupedFacetsList.contains(it.key)) {
                ungroupedFacetsList.add(it.key)
            }
        }

        ungroupedFacetsList
    }

    /**
     * Extract list of facet fields from the grouped facets Map (json)
     *
     * @param groupedFacets
     * @return
     */
    List getListFromGroupedFacets(Map groupedFacets) {
        List facets = []

        groupedFacets.each { key, value ->
            facets.addAll(value)
        }

        facets
    }

    /**
     * Add markup, links, etc., to certain field values. Due to the way the record page is generated
     * in a field-agnostic way, it makes it hard to add field-specific formatting in the current output
     * taglib (formatExtraDwC).
     *
     * TODO: move record key string values into enum or config (e.g. Location & Occurrence)
     *
     * @param record
     */
    JSONObject augmentRecord(JSONObject record) {
        // take a copy so we don't modify the original
        JSONObject modifiedRecord = new JSONObject(record.toString()) // clone it
        // add link to conservation list for stateConservation
        //log.debug "record = ${record as JSON}"
        String stateProvince = ""
        String stateKey = ""
        // conservation list is state based, so first we need to know the state
        modifiedRecord.get("Location")?.each {
            if (it.name == "stateProvince") {
                stateProvince = it.processed ?: it.raw
                // converts to camel case, e.g. "new south wales" to "NewSouthWales"
                stateKey = WordUtils.capitalizeFully(stateProvince).replaceAll("\\s+", "")
            }
        }

        modifiedRecord
    }

    /**
     * Find any cl1234 or el1234 layer IDs in the q or fq params and return a list
     * of layer objects containing layer metadata
     *
     * @param searchRequestParams
     * @return list of layer objects
     */
    List getListOfLayers(SpatialSearchRequestParams searchRequestParams) {
        List layerIds = getListOfLayerIds(searchRequestParams)
        getListOfLayerObjects(layerIds)
    }

    /**
     * Find any cl1234 or el1234 layer IDs in the q or fq params and return a list of layer IDs
     *
     * @param searchRequestParams
     * @return List
     */
    List getListOfLayerIds(SpatialSearchRequestParams searchRequestParams) {
        List layersList = [] // list of IDs
        List queries = [] // list of q and fq query strings
        queries.add(searchRequestParams.q) // q param
        queries.addAll(searchRequestParams.fq) // array of fq params

        queries.each { String q ->
            // regex for find el1234 and cl5678 IDs
            Matcher layer = q =~ /^\-*([ec]l\d+)\:.*/

            if (layer.matches()) {
                String match = layer[0][1] // grab the captured text

                if (match && match.length() > 3) {
                    layersList.add(match)
                }
            }
        }

        layersList
    }

    /**
     * For a given list of layer IDs (el1234 or cl456) do a lookup against spatial service
     * for metadata for the layer ID and return a list of layer objects.
     *
     * @param layerIdsList
     * @return List
     */
    List getListOfLayerObjects(List layerIdsList) {
        List layerObjects = [] // list of final layer objects used to load layers via LeafletJS
        Map layersMetaData = webServicesService.getLayersMetaData() // cached, so not blocking (after first run)

        layerIdsList.each { String id ->
            def layerObj = layersMetaData.get(id)
            if (layerObj) {
                layerObjects.add(layerObj)
            }
        }

        layerObjects
    }

    Map processUserFQInteraction(SpatialSearchRequestParams requestParams, activeFacetObj) {
        def interactionMap = [:]
        if (requestParams.disableAllQualityFilters) {
            return interactionMap
        }

        def disabled = requestParams.disableQualityFilter as Set

        // map from category label to filter names
        // Suppose there's a default quality filter occurrence_decade_i:[1900 TO *] and user has a filter occurrence_decade_i:[1990 TO *].
        // In this case, the exclude count of the DQ filter is 0 since user filter returns a subset of what DQ filter returns.
        // This means a user filter can interact with a DQ filter even when its exclude count == 0
        def categoryToKeyMap = [:]

        categoryToKeyMap = qualityService.getGroupedEnabledFilters(requestParams.qualityProfile).findAll { label, list ->
            !disabled.contains(label)
        }.collectEntries { label, list ->
            def keys = list*.filter.collect { getKeysFromFilter(it) }.flatten()
            keys.isEmpty() ? [:] : [(label): keys as Set]
        }

        def profile = qualityService.activeProfile(requestParams.qualityProfile)
        // label to name map
        def labelToNameMap = profile?.categories?.collectEntries { [(it.label): it.name] } ?: [:]

        // all used keys by quality filters
        def keys = categoryToKeyMap.values().flatten() as Set

        // map from keys to categories labels { field key -> label set }
        def keyToCategoryMap = keys.collectEntries { [(it): categoryToKeyMap.findAll { k, v -> v.contains(it) }.collect { it.key }] }


        // find all fqs interact with dq filters
        def interactingFq = requestParams.fq.findAll { getKeysFromFilter(it).find { keyToCategoryMap.containsKey(it) } }
        // userfq -> { key : [label, label]}
        def fqkeyToCategory = interactingFq.collectEntries { fq -> [(fq): getKeysFromFilter(fq).findAll { keyToCategoryMap.containsKey(it) }.collectEntries { [(it): keyToCategoryMap.get(it)] }] }
        def fqInteract = fqkeyToCategory.collectEntries { fq, dic ->
            [(fq), dic.collect { key, val ->
                'This filter may conflict with <b>[' + val.collect { labelToNameMap[it] }.join(', ') + ']</b> because they ' + (val.size() == 1 ? 'both' : 'all') + ' use field: <b>[' + key + ']</b>'
            }.join('<br><br>')]
        }

        // all keys in user fq
        def alluserkeys = requestParams.fq.collect { getKeysFromFilter(it) }.flatten()
        // key -> [userfq, userfq]
        def keyToUserfq = alluserkeys.collectEntries { key -> [(key): requestParams.fq.findAll { getKeysFromFilter(it).contains(key) }] }
        // filter it so it only contains dq categories interact with user fqs
        categoryToKeyMap = categoryToKeyMap.collectEntries { label, keySet -> [(label): keySet.findAll { alluserkeys.contains(it) }] }.findAll { label, keySet -> keySet.size() > 0 }
        def dqInteract = categoryToKeyMap.collectEntries { label, keySet ->
            [(label), keySet.collect { key ->
                'This category may conflict with <b>[' + keyToUserfq[key].join(', ') + ']</b> because they ' + (keyToUserfq[key].size() == 1 ? 'both' : 'all') + ' use field:<b>[' + key + ']</b>'
            }.join('<br><br>')]
        }

        // map from user fq to category labels (user fq -> label, only those do interact appear in map)
        def userFqInteractDQCategoryLabel = requestParams.fq.collectEntries { [(it): getKeysFromFilter(it).collect { key -> keyToCategoryMap.get(key) }.findAll { it != null }.flatten() as Set] }.findAll { key, val -> !val.isEmpty() }

        def colors = [
                "#C10020", //# Vivid Red
                "#007D34", //# Vivid Green
                "#FF8E00", //# Vivid Orange Yellow
                "#803E75", //# Strong Purple
                "#93AA00", //# Vivid Yellowish Green
                "#593315", //# Deep Yellowish Brown
                "#00538A", //# Strong Blue
                "#F6768E", //# Strong Purplish Pink
                "#FF7A5C", //# Strong Yellowish Pink
                "#53377A", //# Strong Violet
                "#F13A13",// # Vivid Reddish Orange
                "#B32851", //# Strong Purplish Red
                "#7F180D", //# Strong Reddish Brown
                "#232C16",// # Dark Olive Green
                "#CEA262", //# Grayish Yellow
                "#817066", //# Medium Gray
                "#FF6800", //# Vivid Orange
        ]

        def DQColors = [:]
        def UserFQColors = [:]

        userFqInteractDQCategoryLabel.eachWithIndex { it, index ->
            def color = colors[index % colors.size()]
            UserFQColors.put(it.key, color)
            it.value.each { DQColors.put(it, color) }
        }

        interactionMap.fqInteract = fqInteract
        interactionMap.dqInteract = dqInteract
        interactionMap.UserFQColors = UserFQColors
        interactionMap.DQColors = DQColors
        interactionMap
    }

    /**
     * Parse a fq string to get a list of filter names
     *
     * @return filter names in the fq as Set
     */
    private def getKeysFromFilter(String fq) {
        int pos = 0
        int start = 0
        List keys = []
        while ((pos = fq.indexOf(':', pos)) != -1) {
            // ':' at pos
            start = fq.lastIndexOf(' ', pos)
            if (start == -1) {
                keys.add(fq.substring(0, pos))
            } else {
                keys.add(fq.substring(start + 1, pos))
            }
            pos++
        }

        // the values in the keys can now be "-(xxx", "-xxx", "(xxx"
        // need to remove '-' and '('
        keys = keys.collect {
            it = it.replace("(", "")
            if (it?.startsWith("-")) it = it.substring(1)
            it
        }

        keys as Set
    }

    def translateValues(qualityFiltersByLabel, propertyMap, assertionMap) {
        def translatedFilterMap = [:]
        qualityFiltersByLabel.each { label, filters ->
            def translatedFilters = [:]
            filters.each { filter ->
                def rslt = parseSimpleFq(filter.filter, propertyMap, assertionMap)
                if (rslt != null) {
                    translatedFilters[rslt[0]] = rslt[1]
                }
            }

            if (!translatedFilters.isEmpty()) {
                // need a json object here so that it can be passed to html element as data-* attribute
                translatedFilterMap[label] = new JSONObject(translatedFilters)
            }
        }
        translatedFilterMap
    }

    /**
     * To lookup translation of a filter value
     *
     * @return null if no translation found. [value, translation] otherwise
     */

    private def parseSimpleFq(String fq, propertyMap, assertionMap) {
        def idx = fq.indexOf(':')
        if (idx == -1) return null

        // to extract field and value (with leading " and surrounding '()' '""' removed)
        // then look up translation
        String key = fq.substring(0, idx)
        String value = fq.substring(idx + 1)
        if (key.length() > 0 && key[0] == '-') key = key.substring(1)
        if ((key.length() > 0 && key[0] == '(') && (value.length() > 0 && value[value.length() - 1] == ')')) {
            key = key.substring(1)
            value = value.substring(0, value.length() - 1)
        }

        if (value.length() >= 2 && value[0] == '"' && value[value.length() - 1] == '"') value = value.substring(1, value.length() - 1)

        def retVal = null
        // if it's an assertion, find it in assertion map first
        if (key.equals('assertions')) {
            // need a json object here so that it can be passed to html as an object instead of a String
            retVal = assertionMap?.get(value) ? new JSONObject(assertionMap?.get(value)) : null
        }

        if (retVal == null) {
            def lookup = key + '.' + value

            retVal = propertyMap.get(lookup)
            if (retVal == null) {
                retVal = propertyMap.get(value)
            }
        }
        return retVal != null ? [value, retVal] : null
    }
}
