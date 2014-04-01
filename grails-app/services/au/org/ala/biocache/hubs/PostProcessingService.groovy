package au.org.ala.biocache.hubs

import org.apache.commons.httpclient.HttpClient
import org.apache.commons.httpclient.methods.HeadMethod
import org.apache.commons.io.FileUtils
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

        if (taxaQueries.size() > 1) {
            guidsForTaxa.eachWithIndex { guid, i ->
                if (guid) {
                    expandedQueries.add("lsid:" + guid)
                } else {
                    expandedQueries.add(taxaQueries[i])
                }
            }
            query = "(" + expandedQueries.join(" OR ") + ")"
        } else {
            query = (guidsForTaxa[0]) ? "lsid:" + guidsForTaxa[0] : taxaQueries[0]
        }

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
     *
     * @param facetResults
     * @return
     */
    def Map getMapOfGroupedFacets(JSONArray facetResults) {
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
}
