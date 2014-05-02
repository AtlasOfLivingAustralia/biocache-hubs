package au.org.ala.biocache.hubs

import grails.converters.JSON
import grails.plugin.cache.Cacheable

import groovyx.net.http.ContentType
import groovyx.net.http.HTTPBuilder
import groovyx.net.http.Method
import org.apache.commons.httpclient.HttpClient
import org.apache.commons.httpclient.methods.HeadMethod
import org.apache.commons.io.FileUtils
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
        def url = "${grailsApplication.config.biocache.baseUrl}/occurrences/search?${requestParams.getEncodedParams()}"
        getJsonElements(url)
    }

    @Cacheable('longTermCache')
    def JSONObject cachedFullTextSearch(SpatialSearchRequestParams requestParams) {
        def url = "${grailsApplication.config.biocache.baseUrl}/occurrences/search?${requestParams.getEncodedParams()}"
        getJsonElements(url)
    }

    @Cacheable('biocacheCache')
    def JSONObject getRecord(String id, Boolean hasClubView) {
        def url = "${grailsApplication.config.biocache.baseUrl}/occurrence/${id.encodeAsURL()}"
        if (hasClubView) {
            url += "?apiKey=${grailsApplication.config.biocache.apiKey?:''}"
        }
        getJsonElements(url)
    }

    @Cacheable('biocacheCache')
    def JSONObject getCompareRecord(String id) {
        def url = "${grailsApplication.config.biocache.baseUrl}/occurrence/compare?uuid=${id.encodeAsURL()}"
        getJsonElements(url)
    }

    //@Cacheable('biocacheCache')
    def JSONArray getUserAssertions(String id) {
        def url = "${grailsApplication.config.biocache.baseUrl}/occurrences/${id.encodeAsURL()}/assertions"
        getJsonElements(url)
    }

    //@Cacheable('biocacheCache')
    def JSONArray getQueryAssertions(String id) {
        def url = "${grailsApplication.config.biocache.baseUrl}/occurrences/${id.encodeAsURL()}/assertionQueries"
        getJsonElements(url)
    }

    @Cacheable('longTermCache')
    def JSONArray getDefaultFacets() {
        def url = "${grailsApplication.config.biocache.baseUrl}/search/facets"
        getJsonElements(url)
    }

    @Cacheable('longTermCache')
    def JSONArray getErrorCodes() {
        def url = "${grailsApplication.config.biocache.baseUrl}/assertions/user/codes"
        getJsonElements(url)
    }

    @Cacheable('longTermCache')
    def Map getGroupedFacets() {
        log.info "Getting grouped facets"
        def url = "${grailsApplication.config.biocache.baseUrl}/search/grouped/facets"
        JSONArray groupedArray = getJsonElements(url)
        Map groupedMap = [:] // LinkedHashMap by default so ordering is maintained

        // simplify DS into a Map with key as group name and value as list of facets
        groupedArray.each { group ->
            groupedMap.put(group.title, group.facets.collect { it.field })
        }

        groupedMap
    }

    /**
     * Perform POST for new assertion to biocache-service
     *
     * @param recordUuid
     * @param code
     * @param comment
     * @param userId
     * @param userDisplayName
     * @return Map postResponse
     */
    def Map addAssertion(String recordUuid, String code, String comment, String userId, String userDisplayName) {
        Map postBody =  [
                recordUuid: recordUuid,
                code: code,
                comment: comment,
                userId: userId,
                userDisplayName: userDisplayName,
                apiKey: grailsApplication.config.biocache.apiKey
        ]

        postFormData(grailsApplication.config.biocache.baseUrl + "/occurrences/assertions/add", postBody)
    }

    /**
     * Perform POST to delete an assertion on biocache-service
     *
     * @param recordUuid
     * @param assertionUuid
     * @return
     */
    def Map deleteAssertion(String recordUuid, String assertionUuid) {
        Map postBody =  [
                recordUuid: recordUuid,
                assertionUuid: assertionUuid,
                apiKey: grailsApplication.config.biocache.apiKey
        ]

        postFormData(grailsApplication.config.biocache.baseUrl + "/occurrences/assertions/delete", postBody)
    }

    @Cacheable('collectoryCache')
    def JSONObject getCollectionInfo(String id) {
        def url = "${grailsApplication.config.collections.baseUrl}/lookup/summary/${id.encodeAsURL()}"
        getJsonElements(url)
    }

    @Cacheable('longTermCache')
    def Map getLayersMetaData() {
        Map layersMetaMap = [:]
        def url = "${grailsApplication.config.spatial.baseUrl}/layers.json"
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
            String taxaQ = taxaQueries[0]?:'*:*' // empty taxa search returns all records
            taxaQueries.addAll(taxaQ.split(" OR ") as List)
            taxaQueries.remove(0) // remove first entry
        }

        List encodedQueries = taxaQueries.collect { it.encodeAsURL() } // URL encode params

        def url = grailsApplication.config.bie.baseUrl + "/ws/guid/batch?q=" + encodedQueries.join("&q=")
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
     * Generate a Map of image url (key) with image file size (like ls -h) (value)
     *
     * @param images
     * @return
     */
    def Map getImageFileSizeInMb(JSONArray images) {
        Map imageSizes = [:]

        images.each { image ->
            //log.debug "image = ${image}"
            String originalImageUrl = image.alternativeFormats?.imageUrl
            if (originalImageUrl) {
                Long imageSizeInBytes = getImageSizeInBytes(originalImageUrl)
                String formattedImageSize = FileUtils.byteCountToDisplaySize(imageSizeInBytes) // human readable value
                imageSizes.put(originalImageUrl, formattedImageSize)
            }
        }

        imageSizes
    }

    /**
     * Use HTTP HEAD to determine the file size of a URL (image)
     *
     * @param imageURL
     * @return
     * @throws Exception
     */
    @Cacheable('longTermCache')
    private Long getImageSizeInBytes(String imageURL) throws Exception {
        HttpClient httpClient = new HttpClient()
        HeadMethod headMethod = new HeadMethod(imageURL)
        httpClient.executeMethod(headMethod)
        String lengthString = headMethod.getResponseHeader("Content-Length").getValue()
        return Long.parseLong(lengthString)
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

    /**
     * Perform a POST with URL encoded params as POST body
     *
     * @param uri
     * @param postParams
     * @return postResponse (Map with keys: statusCode (int) and statusMsg (String)
     */
    def Map postFormData(String uri, Map postParams) {
        HTTPBuilder http = new HTTPBuilder(uri)
        log.debug "POST (form encoded) to ${http.uri}"
        Map postResponse = [:]

        http.request( Method.POST ) {

            send ContentType.URLENC, postParams

            response.success = { resp ->
                log.debug "POST - response status: ${resp.statusLine}"
                postResponse.statusCode = resp.statusLine.statusCode
                postResponse.statusMsg = resp.statusLine.reasonPhrase
                //assert resp.statusLine.statusCode == 201
            }

            response.failure = { resp ->
                //def error = [error: "Unexpected error: ${resp.statusLine.statusCode} : ${resp.statusLine.reasonPhrase}"]
                postResponse.statusCode = resp.statusLine.statusCode
                postResponse.statusMsg = resp.statusLine.reasonPhrase
                log.error "POST - Unexpected error: ${postResponse.statusCode} : ${postResponse.statusMsg}"
            }
        }

        postResponse
    }
}
