package au.org.ala.biocache.hubs

import org.apache.commons.lang.StringUtils
import org.codehaus.groovy.grails.web.json.JSONArray
import org.codehaus.groovy.grails.web.json.JSONObject

import javax.servlet.http.Cookie
import javax.servlet.http.HttpServletRequest

/**
 * Service to perform processing of data between the DAO and View layers
 */
class PostProcessingService {
    def grailsApplication

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
     *  @see <a href="http://code.google.com/p/ala-hubs/source/browse/trunk/hubs-webapp/src/main/java/org/ala/hubs/util/AssertionUtils.java">
     *      http://code.google.com/p/ala-hubs/source/browse/trunk/hubs-webapp/src/main/java/org/ala/hubs/util/AssertionUtils.java
     *  </a>
     *
     * @param id
     * @param record
     * @param currentUserId
     * @return
     */
    def List getGroupedAssertions(JSONArray userAssertions, JSONArray queryAssertions, String currentUserId) {
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

        queryAssertions.each {
            withEachAssertion(it)
        }

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
                String value = it.value.trim()

                if (layersMetaData.containsKey(key)) {
                    Map metaMap = layersMetaData.get(key)
                    metaMap.value = value
                    sampleInfo.add(metaMap)
                }
            }
        }

        return sampleInfo.sort{a,b -> (a.classification1 <=> b.classification1 ?: a.layerDisplayName <=> b.layerDisplayName)}
    }

   /**
     * Build a LinkedHashMap form of the facets to display in the cutomise drop down div
     *
     * @param defaultFacets
     * @return LinkedHashMap facetsMap
     */
   def LinkedHashMap getAllFacets(JSONArray defaultFacets) {
        LinkedHashMap<String, Boolean> facetsMap = new LinkedHashMap<String, Boolean>()
        List orderedFacets = []
        List facetsToInclude = grailsApplication.config.facets?.include?.split(',') ?: []
        List facetsToExclude = grailsApplication.config.facets?.exclude?.split(',') ?: []
        List facetsToHide = grailsApplication.config.facets?.hide?.split(',') ?: []
        List customOrder = grailsApplication.config.facets?.customOrder?.split(',') ?: []
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
    private static String getCookieValue(Cookie[] cookies, String cookieName, String defaultValue) {
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
        log.debug "customFacetsFlat = ${customFacetsFlat}"
        requestedFacets.addAll(customFacetsFlat)
        return requestedFacets
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
                    expandedQueries.add("text:" + taxaQueries[i])
                }
            }
            query = "(" + expandedQueries.join(" OR ") + ")"
        } else {
            // single taxa param
            log.info "taxaQueries[0] = ${taxaQueries[0]}"
            if (taxaQueries[0]) {
                query = (guidsForTaxa[0]) ? "lsid:" + guidsForTaxa[0] : "text:" + taxaQueries[0]
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
                metdataForOutlierLayers.add(layersMetaData.get(it))
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
    def Map getAllGroupedFacets(Map groupedFacets, def facetResults) {
        List ungroupedFacetsList = getUngroupedFacetsList(groupedFacets, getMapOfFacetResults(facetResults))
        def finalGroupedFacets = groupedFacets.clone()
        finalGroupedFacets.put("Ungrouped", ungroupedFacetsList)
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
}
