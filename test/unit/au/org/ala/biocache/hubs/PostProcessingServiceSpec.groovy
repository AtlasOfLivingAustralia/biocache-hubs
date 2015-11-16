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
        grailsApplication.config.facets = [
                include:"dataHubUid,day,modified,left,right",
                exclude:"establishment_means,user_assertions,assertion_user_id,name_match_metric",
                hide:"taxon_name,common_name",
                customOrder:""
        ]
        service.grailsApplication = grailsApplication
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

    //@IgnoreRest
    void "test getListFromGroupedFacets"() {
        setup:
            def ds1 = [Taxon:["taxon_name", "raw_taxon_name", "subspecies_name", "species", "genus", "family", "order", "class", "phylum", "kingdom", "rank", "name_match_metric", "species_group", "common_name", "species_subgroup" ], Location:["country", "state", "cl2079", "cl2078", "cl925", "cl901", "cl958", "cl1048", "cl1049", "cl21"]]
            def ds2 = ["taxon_name", "raw_taxon_name", "subspecies_name", "species", "genus", "family", "order", "class", "phylum", "kingdom", "rank", "name_match_metric", "species_group", "common_name", "species_subgroup", "country", "state", "cl2079", "cl2078", "cl925", "cl901", "cl958", "cl1048", "cl1049", "cl21"]
            def ds3 = [foo:"bar", bash:"bam"]
        expect:
            service.getListFromGroupedFacets(ds1).getClass().name == "java.util.ArrayList"
            service.getListFromGroupedFacets(ds1).size() == 25
            service.getListFromGroupedFacets(ds1) == ds2
            service.getListFromGroupedFacets(ds3).size() == 2
            service.getListFromGroupedFacets(ds3) == ["bar","bam"]
    }

    //@IgnoreRest
    void "test getAllFacets"() {
        setup:
            def ds1 = ["taxon_name", "raw_taxon_name", "subspecies_name", "species", "genus", "family", "order", "class", "phylum", "kingdom", "rank", "name_match_metric", "species_group", "common_name", "species_subgroup", "country", "state", "cl2079", "cl2078", "cl925", "cl901", "cl958", "cl1048", "cl1049", "cl21"]
            def ds2 = [taxon_name:false, raw_taxon_name:true, subspecies_name:true, species:true, genus:true, family:true, order:true, class:true, phylum:true, kingdom:true, rank:true, species_group:true, common_name:false, species_subgroup:true, country:true, state:true, cl2079:true, cl2078:true, cl925:true, cl901:true, cl958:true, cl1048:true, cl1049:true, cl21:true, dataHubUid:true, day:true, modified:true, left:true, right:true]
        expect:
            service.getAllFacets(ds1).getClass().name == "java.util.LinkedHashMap"
            service.getAllFacets(ds1).size() == 29
            service.getAllFacets(ds1) == ds2
    }



}
