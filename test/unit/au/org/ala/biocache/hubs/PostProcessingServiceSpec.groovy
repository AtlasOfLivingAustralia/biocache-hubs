package au.org.ala.biocache.hubs

import grails.test.mixin.TestFor
import groovy.json.JsonSlurper
import org.codehaus.groovy.grails.web.json.JSONObject
import spock.lang.IgnoreRest
import spock.lang.Specification

/**
 * See the API for {@link grails.test.mixin.services.ServiceUnitTestMixin} for usage instructions
 */
@TestFor(PostProcessingService)
class PostProcessingServiceSpec extends Specification {

    def setup() {
    }

    def cleanup() {
    }

    //@IgnoreRest
    void "test resultsHaveImages"() {
        setup:
            def json1 = '''{"query":"?q=lsid%3Aurn%3Alsid%3Abiodiversity.org.au%3Aafd.taxon%3A682e1228-5b3c-45ff-833b-550efd40c399&fq=multimedia%3A%22None%22","status":"OK","sort":"score","pageSize":0,"dir":"asc","occurrences":[],"totalRecords":779882,"facetResults":[{"fieldName":"multimedia","fieldResult":[{"count":779882,"label":"None"}]}],"startIndex":0,"urlParameters":"?q=lsid%3Aurn%3Alsid%3Abiodiversity.org.au%3Aafd.taxon%3A682e1228-5b3c-45ff-833b-550efd40c399&fq=multimedia%3A%22None%22","queryTitle":"<span class='lsid' id='urn:lsid:biodiversity.org.au:afd.taxon:682e1228-5b3c-45ff-833b-550efd40c399'>CLASS: REPTILIA</span>","activeFacetMap":{"multimedia":{"name":"multimedia","value":"\\"None\\"","displayName":"Multimedia:None"}}}'''
            def json2 = '''{"query":"?q=lsid%3Aurn%3Alsid%3Abiodiversity.org.au%3Aafd.taxon%3A682e1228-5b3c-45ff-833b-550efd40c399&fq=multimedia%3A%22Image%22","status":"OK","sort":"score","pageSize":0,"dir":"asc","occurrences":[],"totalRecords":1719,"facetResults":[{"fieldName":"multimedia","fieldResult":[{"count":1719,"label":"Image"}]}],"startIndex":0,"urlParameters":"?q=lsid%3Aurn%3Alsid%3Abiodiversity.org.au%3Aafd.taxon%3A682e1228-5b3c-45ff-833b-550efd40c399&fq=multimedia%3A%22Image%22","queryTitle":"<span class='lsid' id='urn:lsid:biodiversity.org.au:afd.taxon:682e1228-5b3c-45ff-833b-550efd40c399'>CLASS: REPTILIA</span>","activeFacetMap":{"multimedia":{"name":"multimedia","value":"\\"Image\\"","displayName":"Multimedia:Image"}}}'''
            JSONObject sr1 = new JsonSlurper().parseText(json1)
            JSONObject sr2 = new JsonSlurper().parseText(json2)

        expect:
            service.resultsHaveImages(sr1) == false
            service.resultsHaveImages(sr2) == true
    }

}
