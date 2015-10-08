package au.org.ala.biocache.hubs

import grails.converters.JSON
import grails.plugin.cache.CacheEvict
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
    def grailsApplication, facetsCacheService

    def JSONObject fullTextSearch(SpatialSearchRequestParams requestParams) {
        def url = "${grailsApplication.config.biocache.baseUrl}/occurrences/search?${requestParams.getEncodedParams()}"
        getJsonElements(url)
    }

    def JSONObject cachedFullTextSearch(SpatialSearchRequestParams requestParams) {
        def url = "${grailsApplication.config.biocache.baseUrl}/occurrences/search?${requestParams.getEncodedParams()}"
        getJsonElements(url)
    }

    def JSONObject getRecord(String id, Boolean hasClubView) {
        def url = "${grailsApplication.config.biocache.baseUrl}/occurrence/${id.encodeAsURL()}"
        if (hasClubView) {
            url += "?apiKey=${grailsApplication.config.biocache.apiKey?:''}"
        }
        getJsonElements(url)
    }

    def JSONObject getCompareRecord(String id) {
        def url = "${grailsApplication.config.biocache.baseUrl}/occurrence/compare?uuid=${id.encodeAsURL()}"
        getJsonElements(url)
    }

    def JSONArray getMapLegend(String queryString) {
        def url = "${grailsApplication.config.biocache.baseUrl}/mapping/legend?${queryString}"
        JSONArray json = getJsonElements(url)
        def facetName
        Map facetLabelsMap = [:]

        json.each { item ->
            if (!facetName) {
                // do this once
                facetName = item.fq?.tokenize(':')?.get(0)?.replaceFirst(/^\-/,'')
                try {
                    facetLabelsMap = facetsCacheService.getFacetNamesFor(facetName) // cached
                } catch (IllegalArgumentException iae) {
                    log.info "${iae.message}"
                }
            }

            if (facetLabelsMap && facetLabelsMap.containsKey(item.name)) {
                item.name = facetLabelsMap.get(item.name)
            }
        }
        json
    }

    def JSONArray getUserAssertions(String id) {
        def url = "${grailsApplication.config.biocache.baseUrl}/occurrences/${id.encodeAsURL()}/assertions"
        getJsonElements(url)
    }

    def JSONArray getQueryAssertions(String id) {
        def url = "${grailsApplication.config.biocache.baseUrl}/occurrences/${id.encodeAsURL()}/assertionQueries"
        getJsonElements(url)
    }

    def JSONObject getDuplicateRecordDetails(JSONObject record) {
        log.debug "getDuplicateRecordDetails -> ${record?.processed?.occurrence?.associatedOccurrences}"
        if (record?.processed?.occurrence?.associatedOccurrences) {
            def status = record.processed.occurrence.duplicationStatus
            def uuid

            if (status == "R") {
                // reference record so use its UUID
                uuid = record.raw.uuid
            } else {
                // duplicate record so use the reference record UUID
                uuid = record.processed.occurrence.associatedOccurrences
            }

            def url = "${grailsApplication.config.biocache.baseUrl}/duplicates/${uuid.encodeAsURL()}"
            getJsonElements(url)
        }
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

        if (grailsApplication.config.biocache.groupedFacetsUrl) {
            // some hubs use a custom JSON url
            url = "${grailsApplication.config.biocache.groupedFacetsUrl}"
        }

        Map groupedMap = [ "Custom" : []] // LinkedHashMap by default so ordering is maintained

        try {
            JSONArray groupedArray = getJsonElements(url)

            // simplify DS into a Map with key as group name and value as list of facets
            groupedArray.each { group ->
                groupedMap.put(group.title, group.facets.collect { it.field })
            }

        } catch (Exception e) {
            log.debug "$e"
        }

        groupedMap
    }

    @CacheEvict(value='collectoryCache', allEntries=true)
    def doClearCollectoryCache() {
        "collectoryCache cache cleared\n"
    }

    @CacheEvict(value='longTermCache', allEntries=true)
    def doClearLongTermCache() {
        "longTermCache cache cleared\n"
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

    @Cacheable('collectoryCache')
    def JSONArray getCollectionContact(String id){
        def url = "${grailsApplication.config.collections.baseUrl}/ws/collection/${id.encodeAsURL()}/contact.json"
        getJsonElements(url)
    }

    @Cacheable('collectoryCache')
    def JSONArray getDataresourceContact(String id){
        def url = "${grailsApplication.config.collections.baseUrl}/ws/dataResource/${id.encodeAsURL()}/contact.json"
        getJsonElements(url)
    }

    @Cacheable('longTermCache')
    def Map getLayersMetaData() {
        Map layersMetaMap = [:]
        def url = "${grailsApplication.config.layersservice.baseUrl}/layers"

        try {
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
        } catch (RestClientException rce) {
            log.debug "Can't access layer service - ${rce.message}"
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

        def url = grailsApplication.config.bieService.baseUrl + "/guid/batch?q=" + encodedQueries.join("&q=")
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
        def url = "${grailsApplication.config.logger.baseUrl}/logger/reasons"
        getJsonElements(url)
    }

    @Cacheable('longTermCache')
    def JSONArray getLoggerSources() {
        def url = "${grailsApplication.config.logger.baseUrl}/logger/sources"
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
     * Get list of dynamic facets for a given query (Sandbox)
     *
     * @param query
     * @return
     */
    List getDynamicFacets(String query) {
        def url = "${grailsApplication.config.biocache.baseUrl}/upload/dynamicFacets?q=${query}"
        JSONArray facets = getJsonElements(url)
        def dfs = []
        facets.each {
            if (it.name && it.displayName) {
                dfs.add([name: it.name, displayName: it.displayName])
            } // reduce to List of Maps
        }
        dfs
    }

    /**
     * Use HTTP HEAD to determine the file size of a URL (image)
     *
     * @param imageURL
     * @return
     * @throws Exception
     */
    private Long getImageSizeInBytes(String imageURL) throws Exception {
        // encode the path part of the URI - taken from http://stackoverflow.com/a/8962869/249327
        Long imageFileSize = 0l
        try {
            URL url = new URL(imageURL);
            URI uri = new URI(url.getProtocol(), url.getUserInfo(), url.getHost(), url.getPort(), url.getPath(), url.getQuery(), url.getRef());
            HttpClient httpClient = new HttpClient()
            HeadMethod headMethod = new HeadMethod(uri.toString())
            httpClient.executeMethod(headMethod)
            String lengthString = headMethod.getResponseHeader("Content-Length")?.getValue()?:'0'
            imageFileSize = Long.parseLong(lengthString)
        } catch (Exception ex) {
            log.error "Error getting image url file size: ${ex}", ex
        }

        return imageFileSize
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

    def JSONElement postJsonElements(String url, String jsonBody) {
        HttpURLConnection conn = null
        def charEncoding = 'UTF-8'
        try {
            conn = new URL(url).openConnection()
            conn.setDoOutput(true)
            conn.setRequestProperty("Content-Type", "application/json;charset=${charEncoding}");
//            conn.setRequestProperty("Authorization", grailsApplication.config.api_key);
//            def user = userService.getUser()
//            if (user) {
//                conn.setRequestProperty(grailsApplication.config.app.http.header.userId, user.userId) // used by ecodata
//                conn.setRequestProperty("Cookie", "ALA-Auth="+java.net.URLEncoder.encode(user.userName, charEncoding)) // used by specieslist
//            }
            OutputStreamWriter wr = new OutputStreamWriter(conn.getOutputStream(), charEncoding)
            wr.write(jsonBody)
            wr.flush()
            def resp = conn.inputStream.text
            log.debug "fileid = ${conn.getHeaderField("fileId")}"
            //log.debug "resp = ${resp}"
            //log.debug "code = ${conn.getResponseCode()}"
            if (!resp && conn.getResponseCode() == 201) {
                // Field guide code...
                log.debug "field guide catch"
                resp = "{fileId: \"${conn.getHeaderField("fileId")}\" }"
            }
            wr.close()
            return JSON.parse(resp?:"{}")
        } catch (SocketTimeoutException e) {
            def error = "Timed out calling web service. URL= ${url}."
            throw new RestClientException(error) // exception will result in no caching as opposed to returning null
        } catch (Exception e) {
            def error = "Failed calling web service. ${e.getMessage()} URL= ${url}." +
                        "statusCode: " +conn?.responseCode?:"" +
                        "detail: " + conn?.errorStream?.text
            throw new RestClientException(error) // exception will result in no caching as opposed to returning null
        }
    }
}
