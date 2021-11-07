/*
 * Copyright (C) 2014 Atlas of Living Australia
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

import grails.converters.JSON
import grails.plugin.cache.CacheEvict
import grails.plugin.cache.Cacheable
import groovyx.net.http.ContentType
import groovyx.net.http.HTTPBuilder
import groovyx.net.http.Method
import org.apache.commons.httpclient.HttpClient
import org.apache.commons.httpclient.methods.HeadMethod
import org.apache.commons.io.FileUtils
import org.grails.web.json.JSONArray
import org.grails.web.json.JSONElement
import org.grails.web.json.JSONObject
import org.springframework.beans.factory.annotation.Value
import org.springframework.web.client.RestClientException
import org.supercsv.cellprocessor.ift.CellProcessor
import org.supercsv.io.CsvListReader
import org.supercsv.io.ICsvListReader
import org.supercsv.prefs.CsvPreference

import javax.annotation.PostConstruct

/**
 * Service to perform web service DAO operations
 */
class WebServicesService {

    public static final String ENVIRONMENTAL = "Environmental"
    public static final String CONTEXTUAL = "Contextual"
    def grailsApplication, facetsCacheServiceBean, authService
    QualityService qualityService

    @Value('${dataquality.enabled}')
    boolean dataQualityEnabled

    Map cachedGroupedFacets = [:] // keep a copy in case method throws an exception and then blats the saved version

    @PostConstruct
    def init(){
        facetsCacheServiceBean = grailsApplication.mainContext.getBean('facetsCacheService')
    }

    JSONObject fullTextSearch(SpatialSearchRequestParams requestParams) {
        populateProfile(requestParams)
        def url = "${grailsApplication.config.biocache.baseUrl}/occurrences/search?${requestParams.getEncodedParams()}"
        def result = getJsonElements(url)
        return result
    }

    JSONObject cachedFullTextSearch(SpatialSearchRequestParams requestParams) {
        fullTextSearch(requestParams)
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
                    facetLabelsMap = facetsCacheServiceBean.getFacetNamesFor(facetName) // cached
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

    def getAlerts(String userId) {
        def url = "${grailsApplication.config.alerts.baseUrl}" + "/api/alerts/user/" + userId
        return getJsonElements(url, "${grailsApplication.config.alerts.apiKey}")
    }

    def subscribeMyAnnotation(String userId) {
        String url = "${grailsApplication.config.alerts.baseUrl}" + "/api/alerts/user/" + userId + "/subscribeMyAnnotation"
        postFormData(url, [:], grailsApplication.config.alerts.apiKey as String)
    }

    def unsubscribeMyAnnotation(String userId) {
        String url = "${grailsApplication.config.alerts.baseUrl}" + "/api/alerts/user/" + userId + "/unsubscribeMyAnnotation"
        postFormData(url, [:], grailsApplication.config.alerts.apiKey as String)
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

    @Cacheable(value="longTermCache")
    def Map getGroupedFacets() {
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

            cachedGroupedFacets = deepCopy(groupedMap) // keep a deep copy

        } catch (Exception e) {
            log.warn "grouped facets failed to load: $e", e
            groupedMap = cachedGroupedFacets // fallback to saved copy
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
    Map addAssertion(String recordUuid, String code, String comment, String userId, String userDisplayName,
                         String userAssertionStatus, String assertionUuid, String relatedRecordId,
                         String relatedRecordReason) {
        Map postBody =  [
                recordUuid: recordUuid,
                code: code,
                comment: comment,
                userAssertionStatus: userAssertionStatus,
                assertionUuid: assertionUuid,
                relatedRecordId: relatedRecordId,
                relatedRecordReason: relatedRecordReason,
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
    def getImageMetadata(String imageId) {
        def url = "${grailsApplication.config.images.baseUrl}/ws/image/${imageId.encodeAsURL()}.json"
        getJsonElements(url)
    }

    @Cacheable('longTermCache')
    Map getLayersMetaData() {
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
                subset.source = it.source
                subset.units = it.environmentalvalueunits

                if (it.type == ENVIRONMENTAL) {
                    layersMetaMap.put("el" + it.id, subset)
                } else if (it.type == CONTEXTUAL) {
                    layersMetaMap.put("cl" + it.id, subset)
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
            if (guidsJson) {
                def match = guidsJson.get(key)[0]
                def guid = (match?.acceptedIdentifier) ? match?.acceptedIdentifier : match?.identifier
                guids.add(guid)
            } else {
                guids.add("")
            }
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
        def jsonObj = getJsonElements(url)
        jsonObj.findAll { !it.deprecated } // skip deprecated reason codes
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
     * @return the object we request or an JSON object containing error info in case of error
     */
    JSONElement getJsonElements(String url, String apiKey = null) {
        log.debug "(internal) getJson URL = " + url
        def conn = new URL(url).openConnection()
        try {
            conn.setConnectTimeout(10000)
            conn.setReadTimeout(50000)
            if (apiKey != null) {
                conn.setRequestProperty('apiKey', apiKey)
            }

            InputStream stream = null;
            if (conn instanceof HttpURLConnection) {
                conn.getResponseCode() // this line required to trigger parsing of response
                stream = conn.getErrorStream() ?: conn.getInputStream()
            } else { // when read local files it's a FileURLConnection which doesn't have getErrorStream
                stream = conn.getInputStream()
            }
            return JSON.parse(stream, "UTF-8")
        } catch (Exception e) {
            def error = "Failed to get json from web service (${url}). ${e.getClass()} ${e.getMessage()}, ${e}"
            log.error error
            throw new RestClientException(error, e)
        }
    }

    /**
     * Perform HTTP GET on a text-based web service
     *
     * @param url
     * @return
     */
    String getText(String url) {
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
            throw new RestClientException(error, e) // exception will result in no caching as opposed to returning null
        }
    }

    /**
     * Perform a POST with URL encoded params as POST body
     *
     * @param uri
     * @param postParams
     * @return postResponse (Map with keys: statusCode (int) and statusMsg (String)
     */
    def Map postFormData(String uri, Map postParams, String apiKey = null) {
        HTTPBuilder http = new HTTPBuilder(uri)
        log.debug "POST (form encoded) to ${http.uri}"
        Map postResponse = [:]

        http.request( Method.POST ) {

            if (apiKey != null) {
                headers.'apiKey' = apiKey
            }

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

    /**
     * Standard deep copy implementation
     *
     * Taken from http://stackoverflow.com/a/13155429/249327
     *
     * @param orig
     * @return
     */
    private def deepCopy(orig) {
        def bos = new ByteArrayOutputStream()
        def oos = new ObjectOutputStream(bos)
        oos.writeObject(orig); oos.flush()
        def bin = new ByteArrayInputStream(bos.toByteArray())
        def ois = new ObjectInputStream(bin)
        return ois.readObject()
    }

    JSONElement facetSearch(SearchRequestParams requestParams) {
        requestParams.pageSize = 0
        def url = "${grailsApplication.config.biocache.baseUrl}/occurrences/search?${requestParams.getEncodedParams()}"
        def result = getJsonElements(url)


        return result
    }

    String facetCSVDownload(SearchRequestParams requestParams) {
        def url = "${grailsApplication.config.biocache.baseUrl}/occurrences/facets/download?${requestParams.getEncodedParams()}&count=true&lookup=true"
        def result = getText(url)
        return result
    }

    def getAllOccurrenceFields() {
        def url = "${grailsApplication.config.biocache.baseUrl}/index/fields"
        return getJsonElements(url)?.collect {it.name}
    }

    @Cacheable('longTermCache')
    def getMessagesPropertiesFile() {
        def url = "${grailsApplication.config.biocache.baseUrl}/facets/i18n"

        def map = [:]
        def lineContent
        // split text to get lines
        def lines = getText(url).split("\\r?\\n")
        lines?.each {
            // if not comment
            if (!it.startsWith('#')) {
                lineContent = it.split('=')
                if (lineContent.length == 2) {
                    map[lineContent[0]] = lineContent[1]
                }
            }
        }
        return map
    }

    @Cacheable('longTermCache')
    def getAssertionCodeMap() {
        def url = "${grailsApplication.config.biocache.baseUrl}/assertions/codes" // code --> name
        def codes = getJsonElements(url)

        Map dataQualityCodes = getAllCodes() // code -> detail

        // convert to name -> detail
        return codes?.findAll{dataQualityCodes.containsKey(String.valueOf(it.code))}?.collectEntries{[(it.name): dataQualityCodes.get(String.valueOf(it.code))]}
    }

    def getAllCodes() {
        Map dataQualityCodes = [:]

        String dataQualityCsv = grailsApplication.mainContext.getBean('webServicesService').getDataQualityCsv() // cached

        ICsvListReader listReader = null

        try {
            listReader = new CsvListReader(new StringReader(dataQualityCsv), CsvPreference.STANDARD_PREFERENCE)
            listReader.getHeader(true) // skip the header (can't be used with CsvListReader)
            final CellProcessor[] processors = getProcessors()

            List<Object> dataQualityList
            while ((dataQualityList = listReader.read(processors)) != null) {
                //log.debug("row: " + StringUtils.join(dataQualityList, "|"));
                Map<String, String> dataQualityEls = new HashMap<String, String>();
                if (dataQualityList.get(1) != null) {
                    dataQualityEls.put("name", (String) dataQualityList.get(1));
                }
                if (dataQualityList.get(3) != null) {
                    dataQualityEls.put("description", (String) dataQualityList.get(3));
                }
                if (dataQualityList.get(4) != null) {
                    dataQualityEls.put("wiki", (String) dataQualityList.get(4));
                }
                if (dataQualityList.get(0) != null) {
                    dataQualityCodes.put((String) dataQualityList.get(0), dataQualityEls);
                }
            }
        } finally {
            if (listReader != null) {
                listReader.close();
            }
        }
        dataQualityCodes
    }

    /**
     * Internal used method to map from full country name to its iso code.
     * Mapping comes from userdetails.baseUrl/ws/registration/countries.json
     *
     * @return a list of String representing the names of states of that country
     */
    @Cacheable('longTermCache')
    def getCountryNameMap() {
        def countryUrl = "${grailsApplication.config.userdetails.baseUrl}/ws/registration/countries.json"
        def countries = getJsonElements(countryUrl)
        return countries?.findAll {it -> beAValidCountryOrState(it as JSONObject)}?.collectEntries { [(String)it.get("name"), (String)it.get("isoCode")] }
    }


    private static boolean beAValidCountryOrState(JSONObject obj) {
        return obj.has("isoCode") && obj.has("name") && obj.get("isoCode") != "" && obj.get("name") != "N/A"
    }

    /**
     * Method to get a list of states belong to provided country
     *
     * @param countryName
     * @return a list of String representing the names of states of that country
     */
    @Cacheable('longTermCache')
    List<String> getStates(String countryName) {
        List<String> matchingStates = []
        try {
            Map countryNameMap = grailsApplication.mainContext.getBean('webServicesService').getCountryNameMap()
            // if a known country name
            if (countryNameMap?.containsKey(countryName)) {
                def states = getJsonElements("${grailsApplication.config.userdetails.baseUrl}/ws/registration/states.json?country=" + countryNameMap.get(countryName))
                if (states) {
                    // only return valid states
                    matchingStates = states.findAll { it -> beAValidCountryOrState(it as JSONObject) }.collect { it -> (String) it.get("name") }
                }
            }
        } catch (Exception e) {
            log.error "getStates failed to get states of " + countryName + ", error = " + e.getMessage()
        }
        matchingStates
    }
    /**
     * CellProcessor method as required by SuperCSV
     *
     * @return
     */
    private static CellProcessor[] getProcessors() {
        final CellProcessor[] processors = [
                null, // col 1
                null, // col 2
                null, // col 3
                null, // col 4
                null, // col 5
                null, // col 6
                null, // col 7
                null, // col 8
                null, // col 9
                null, // col 10
                null, // col 11
                null, // col 12
                null, // col 13
                null, // col 14
                null, // col 15
        ]

        return processors
    }

    def populateProfile(requestParams) {
        // force set the profile if none provided
        if (dataQualityEnabled && !qualityService.isProfileValid(requestParams.qualityProfile) && !requestParams.disableAllQualityFilters) {
            requestParams.qualityProfile = qualityService.activeProfile()?.shortName
        }
    }
}
