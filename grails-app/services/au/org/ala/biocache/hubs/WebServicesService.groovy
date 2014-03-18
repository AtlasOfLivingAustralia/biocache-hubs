package au.org.ala.biocache.hubs

import grails.converters.JSON
import grails.plugin.cache.Cacheable
import org.codehaus.groovy.grails.web.json.JSONArray
import org.codehaus.groovy.grails.web.json.JSONElement
import org.codehaus.groovy.grails.web.json.JSONObject
import org.springframework.web.client.RestClientException

/**
 * Service to perform web service DAO operations
 */
class WebServicesService {

    public static final String ENVIRONMENTAL = "Environmental"
    public static final String CONTEXTUAL = "Contextual"
    def grailsApplication

    @Cacheable('biocacheCache')
    def JSONObject fullTextSearch(SpatialSearchRequestParams requestParams) {
        def url = "${grailsApplication.config.biocacheServicesUrl}/occurrences/search?${requestParams.getEncodedParams()}"
        getJsonElements(url)
    }

    @Cacheable('longTermCache')
    def JSONObject cachedFullTextSearch(SpatialSearchRequestParams requestParams) {
        def url = "${grailsApplication.config.biocacheServicesUrl}/occurrences/search?${requestParams.getEncodedParams()}"
        getJsonElements(url)
    }

    @Cacheable('biocacheCache')
    def JSONObject getRecord(String id, Boolean hasClubView) {
        def url = "${grailsApplication.config.biocacheServicesUrl}/occurrence/${id.encodeAsURL()}"
        if (hasClubView) {
            url += "?apiKey=${grailsApplication.config.apiKey?:''}"
        }
        getJsonElements(url)
    }

    @Cacheable('biocacheCache')
    def JSONObject getCompareRecord(String id) {
        def url = "${grailsApplication.config.biocacheServicesUrl}/occurrence/compare?uuid=${id.encodeAsURL()}"
        getJsonElements(url)
    }

    @Cacheable('biocacheCache')
    def JSONArray getUserAssertions(String id) {
        def url = "${grailsApplication.config.biocacheServicesUrl}/occurrences/${id.encodeAsURL()}/assertions"
        getJsonElements(url)
    }

    @Cacheable('biocacheCache')
    def JSONArray getQueryAssertions(String id) {
        def url = "${grailsApplication.config.biocacheServicesUrl}/occurrences/${id.encodeAsURL()}/assertionQueries"
        getJsonElements(url)
    }

    @Cacheable('longTermCache')
    def JSONArray getDefaultFacets() {
        def url = "${grailsApplication.config.biocacheServicesUrl}/search/facets"
        getJsonElements(url)
    }

    @Cacheable('longTermCache')
    def JSONArray getErrorCodes() {
        def url = "${grailsApplication.config.biocacheServicesUrl}/assertions/user/codes"
        getJsonElements(url)
    }

    @Cacheable('longTermCache')
    def Map getGroupedFacets() {
        def url = "${grailsApplication.config.biocacheServicesUrl}/search/grouped/facets"
        JSONArray groupedArray = getJsonElements(url)
        Map groupedMap = [:] // LinkedHashMap by default so ordering is maintained

        // simplify DS into a Map with key as group name and value as list of facets
        groupedArray.each { group ->
            groupedMap.put(group.title, group.facets.collect { it.field })
        }

        groupedMap
    }

    @Cacheable('collectoryCache')
    def JSONObject getCollectionInfo(String id) {
        def url = "${grailsApplication.config.collections.baseUrl}/lookup/summary/${id.encodeAsURL()}"
        getJsonElements(url)
    }

    @Cacheable('longTermCache')
    def Map getLayersMetaData() {
        Map layersMetaMap = [:]
        def url = "${grailsApplication.config.spatial.baseURL}/layers.json"
        def jsonArray = getJsonElements(url)

        jsonArray.each {
            Map subset = [:]
            subset << it // clone the original Map
            subset.layerID = it.uid
            subset.layerName = it.name
            subset.layerDisplayName = it.displayname
            subset.value = null
            subset.classification1 = it.classification1
            subset.units = it.environmentalvalueunits

            if (it.type == ENVIRONMENTAL) {
                layersMetaMap.put("el" + it.uid.trim(), subset)
            } else if (it.type == CONTEXTUAL) {
                layersMetaMap.put("cl" + it.uid.trim(), subset)
            }
        }

        return layersMetaMap
    }

    /**
     * Query the BIE for GUIDs for a given list of names
     *
     * @param taxaQueries
     * @return
     */
    @Cacheable('longTermCache')
    def List<String> getGuidsForTaxa(List taxaQueries) {
        List guids = []

        if (taxaQueries.size() == 1) {
            String taxaQ = taxaQueries[0]
            taxaQueries.addAll(taxaQ.split(" OR ") as List)
            taxaQueries.remove(0) // remove first entry
        }

        List encodedQueries = taxaQueries.collect { it.encodeAsURL() } // URL encode params

        def url = grailsApplication.config.bie.baseURL + "/ws/guid/batch?q=" + encodedQueries.join("&q=")
        JSONObject guidsJson = getJsonElements(url)

        taxaQueries.each { key ->
            def match = guidsJson.get(key)[0]
            def guid = match?.acceptedIdentifier
            guids.add(guid)
        }

        return guids
    }

    /**
     * Get the CSV for ALA data quality checks meta data
     *
     * @return
     */
    @Cacheable('longTermCache')
    def String getDataQualityCsv() {
        String url = grailsApplication.config.dataQualityChecksUrl ?: "https://docs.google.com/spreadsheet/pub?key=0AjNtzhUIIHeNdHJOYk1SYWE4dU1BMWZmb2hiTjlYQlE&single=true&gid=0&output=csv"
        getText(url)
    }

    @Cacheable('longTermCache')
    def JSONArray getLoggerReasons() {
        def url = "http://logger.ala.org.au/service/logger/reasons"
        getJsonElements(url)
    }

    @Cacheable('longTermCache')
    def JSONArray getLoggerSources() {
        def url = "http://logger.ala.org.au/service/logger/sources"
        try {
            getJsonElements(url)
        } catch (Exception ex) {
            log.error "Error calling logger service: ${ex.message}", ex
        }
    }

    /**
     * Perform HTTP GET on a JSON web service
     *
     * @param url
     * @return
     */
    def JSONElement getJsonElements(String url) {
        log.debug "(internal) getJson URL = " + url
        def conn = new URL(url).openConnection()
        //JSONObject.NULL.metaClass.asBoolean = {-> false}

        try {
            conn.setConnectTimeout(10000)
            conn.setReadTimeout(50000)
            def json = conn.content.text
            return JSON.parse(json)
        } catch (Exception e) {
            def error = "Failed to get json from web service (${url}). ${e.getClass()} ${e.getMessage()}, ${e}"
            log.error error
            throw new RestClientException(error)
        }

    }

    /**
     * Perform HTTP GET on a text-based web service
     *
     * @param url
     * @return
     */
    def String getText(String url) {
        log.debug "(internal text) getText URL = " + url
        def conn = new URL(url).openConnection()

        try {
            conn.setConnectTimeout(10000)
            conn.setReadTimeout(50000)
            def text = conn.content.text
            return text
        } catch (Exception e) {
            def error = "Failed to get text from web service (${url}). ${e.getClass()} ${e.getMessage()}, ${e}"
            log.error error
            //return null
            throw new RestClientException(error) // exception will result in no caching as opposed to returning null
        }
    }
}
