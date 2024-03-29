package au.org.ala.biocache.hubs

import grails.converters.JSON
import grails.testing.services.ServiceUnitTest
import groovy.json.JsonSlurper
import org.grails.web.json.JSONObject
import spock.lang.Specification


class PostProcessingServiceSpec extends Specification implements ServiceUnitTest<PostProcessingService> {

    def setup() {
        grailsApplication.config.facets = [
                include:"dataHubUid,day,modified,left,right",
                exclude:"establishment_means,user_assertions,assertion_user_id,name_match_metric",
                hide:"taxon_name,common_name",
                customOrder:""
        ]
        grailsApplication.config.stateConservationListPath = [
                NewSouthWales: "/speciesListItem/list/dr650",
                AustralianCapitalTerritory: "/speciesListItem/list/dr649",
                Queensland: "/speciesListItem/list/dr652",
                Victoria: "/speciesListItem/list/dr655",
                WesternAustralia: "/speciesListItem/list/dr2201",
                SouthAustralia: "/speciesListItem/list/dr653",
                NorthernTerritory: "/speciesListItem/list/dr651",
                Tasmania: "/speciesListItem/list/dr654"
        ]
        grailsApplication.config.speciesList.baseURL = "https://lists.ala.org.au"
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

    //@IgnoreRest
    void "test augmentRecord"() {
        setup:
            def json1 = '''{"Measurement":[],"Attribution":[{"raw":"","processed":"co49","name":"collectionUid"},{"raw":"","processed":"Queensland Herbarium Records","name":"dataResourceName"},{"raw":"","processed":"in42","name":"institutionUid"},{"raw":"","processed":"[\\"dh2\\",\\"dh9\\"]","name":"dataHubUid"},{"raw":"","processed":"Queensland Herbarium","name":"collectionName"},{"raw":"","processed":"dp36","name":"dataProviderUid"},{"raw":"","processed":"Department of Science, Information Technology and Innovation","name":"institutionName"},{"raw":"","processed":"CC BY","name":"license"},{"raw":"dr2287","processed":"","name":"dataResourceUid"},{"raw":"","processed":"Australia's Virtual Herbarium","name":"dataProviderName"}],"Classification":[{"raw":"","processed":"wellformed","name":"nameParseType"},{"raw":"","processed":"Verticordia cunninghamii","name":"species"},{"raw":"","processed":"exactMatch","name":"nameMatchMetric"},{"raw":"Verticordia cunninghamii Schauer","processed":"Verticordia cunninghamii","name":"scientificName"},{"raw":"","processed":"Equisetopsida","name":"classs"},{"raw":"","processed":"http://id.biodiversity.org.au/node/apni/7910992","name":"genusID"},{"raw":"","processed":"http://id.biodiversity.org.au/node/apni/2887513","name":"taxonConceptID"},{"raw":"","processed":"http://id.biodiversity.org.au/node/apni/8807563","name":"kingdomID"},{"raw":"","processed":"498741","name":"left"},{"raw":"","processed":"Charophyta","name":"phylum"},{"raw":"","processed":"Plantae","name":"kingdom"},{"raw":"","processed":"http://id.biodiversity.org.au/node/apni/8807565","name":"classID"},{"raw":"Verticordia","processed":"Verticordia","name":"genus"},{"raw":"","processed":"http://id.biodiversity.org.au/node/apni/8807562","name":"phylumID"},{"raw":"","processed":"Myrtales","name":"order"},{"raw":"species","processed":"species","name":"taxonRank"},{"raw":"cunninghamii","processed":"","name":"specificEpithet"},{"raw":"","processed":"http://id.biodiversity.org.au/node/apni/8774852","name":"orderID"},{"raw":"","processed":"[\\"noIssue\\"]","name":"taxonomicIssue"},{"raw":"","processed":"http://id.biodiversity.org.au/node/apni/2887513","name":"speciesID"},{"raw":"","processed":"http://id.biodiversity.org.au/node/apni/8774750","name":"familyID"},{"raw":"Myrtaceae","processed":"Myrtaceae","name":"family"},{"raw":"","processed":"7000","name":"taxonRankID"},{"raw":"Schauer","processed":"","name":"scientificNameAuthorship"},{"raw":"ICBN","processed":"","name":"nomenclaturalCode"},{"raw":"","processed":"498741","name":"right"}],"Event":[],"Location":[{"raw":"AGD66","processed":"","name":"verbatimSRS"},{"raw":"1.0e-05","processed":"","name":"coordinatePrecision"},{"raw":"-17.9166666667","processed":"-17.9152833666","name":"decimalLatitude"},{"raw":"compiler","processed":"","name":"georeferencedBy"},{"raw":"","processed":"Burke (S)","name":"lga"},{"raw":"16000.00","processed":"16000.0","name":"coordinateUncertaintyInMeters"},{"raw":"Australia","processed":"Australia","name":"country"},{"raw":"Oceania","processed":"","name":"continent"},{"raw":"Burke","processed":"","name":"county"},{"raw":"unknown","processed":"","name":"georeferenceProtocol"},{"raw":"Queensland","processed":"Queensland","name":"stateProvince"},{"raw":"138.2500000000","processed":"138.2509257211","name":"decimalLongitude"},{"raw":"","processed":"Terrestrial","name":"biome"},{"raw":"NICHOLSON RIVER","processed":"","name":"locality"},{"raw":"AGD66","processed":"EPSG:4326","name":"geodeticDatum"},{"raw":"AU","processed":"","name":"countryCode"},{"raw":"decimal degrees","processed":"","name":"verbatimCoordinateSystem"},{"raw":"138.25","processed":"","name":"verbatimLongitude"},{"raw":"-17.9166666667","processed":"","name":"verbatimLatitude"}],"Identification":[{"raw":"","processed":"Not provided","name":"abcdIdentificationQualifier"},{"raw":"1988-06","processed":"","name":"dateIdentified"},{"raw":"","processed":"Not provided","name":"identificationQualifier"},{"raw":"1988-06-00","processed":"","name":"verbatimDateIdentified"},{"raw":"det.","processed":"","name":"identifierRole"},{"raw":"2651.00","processed":"","name":"identificationID"},{"raw":"George, A.S.","processed":"","name":"identifiedBy"}],"Occurrence":[{"raw":"urn:catalog:BRI:Herbrecs:AQ0045921","processed":"","name":"occurrenceID"},{"raw":"native","processed":"","name":"naturalOccurrence"},{"raw":"","processed":"Least concern wildlife,Least concern wildlife","name":"stateConservation"},{"raw":"PreservedSpecimen","processed":"PreservedSpecimen","name":"basisOfRecord"},{"raw":"Anonymous","processed":"UNKNOWN OR ANONYMOUS","name":"recordedBy"},{"raw":"2017-01-13 14:37:40","processed":"2017-01-13","name":"modified"},{"raw":"native","processed":"native","name":"establishmentMeans"},{"raw":"BRI","processed":"","name":"institutionCode"},{"raw":"Nicholson River.","processed":"","name":"occurrenceRemarks"},{"raw":"present","processed":"present","name":"occurrenceStatus"},{"raw":"flowers","processed":"","name":"reproductiveCondition"},{"raw":"not cultivated","processed":"","name":"cultivated"},{"raw":"sheet","processed":"","name":"preparations"},{"raw":"BRI AQ0045921","processed":"","name":"catalogNumber"},{"raw":"Herbrecs","processed":"","name":"collectionCode"}]}'''
            def json2 = '''{"Measurement":[],"Attribution":[{"raw":"","processed":"co12","name":"collectionUid"},{"raw":"","processed":"Australia's Virtual Herbarium","name":"dataResourceName"},{"raw":"","processed":"in5","name":"institutionUid"},{"raw":"","processed":"[\\"dh2\\",\\"dh9\\"]","name":"dataHubUid"},{"raw":"","processed":"Australian National Herbarium","name":"collectionName"},{"raw":"","processed":"dp36","name":"dataProviderUid"},{"raw":"","processed":"Centre for Australian National Biodiversity Research","name":"institutionName"},{"raw":"","processed":"CC BY","name":"license"},{"raw":"","processed":"Published dataset","name":"provenance"},{"raw":"dr376","processed":"","name":"dataResourceUid"},{"raw":"","processed":"Australia's Virtual Herbarium","name":"dataProviderName"}],"Classification":[{"raw":"","processed":"wellformed","name":"nameParseType"},{"raw":"","processed":"Pterostylis oreophila","name":"species"},{"raw":"","processed":"exactMatch","name":"nameMatchMetric"},{"raw":"Pterostylis oreophila Clemesha","processed":"Pterostylis oreophila","name":"scientificName"},{"raw":"","processed":"http://id.biodiversity.org.au/name/apni/75185","name":"taxonConceptID"},{"raw":"","processed":"http://id.biodiversity.org.au/node/apni/8807563","name":"kingdomID"},{"raw":"","processed":"587392","name":"left"},{"raw":"","processed":"Plantae","name":"kingdom"},{"raw":"Pterostylis","processed":"","name":"genus"},{"raw":"","processed":"species","name":"taxonRank"},{"raw":"oreophila","processed":"","name":"specificEpithet"},{"raw":"","processed":"[\\"noIssue\\"]","name":"taxonomicIssue"},{"raw":"","processed":"http://id.biodiversity.org.au/name/apni/75185","name":"speciesID"},{"raw":"Orchidaceae","processed":"","name":"family"},{"raw":"","processed":"7000","name":"taxonRankID"},{"raw":"Clemesha","processed":"","name":"scientificNameAuthorship"},{"raw":"ICBN","processed":"","name":"nomenclaturalCode"},{"raw":"","processed":"587392","name":"right"}],"Event":[{"raw":"1990-01-22","processed":"","name":"eventDate"},{"raw":"","processed":"1990","name":"year"},{"raw":"","processed":"01","name":"month"}],"Location":[{"raw":"-35.6","processed":"-35.6","name":"decimalLatitude"},{"raw":"","processed":"Tumut Shire (A)","name":"lga"},{"raw":"1000","processed":"11000.0","name":"coordinateUncertaintyInMeters"},{"raw":"Australia","processed":"Australia","name":"country"},{"raw":"not available","processed":"","name":"generalisedLocality"},{"raw":"Gentle slope. Black, wet, peaty soil under {Leptospermum langigerum}.","processed":"Gentle slope. Black, wet, peaty soil under {Leptospermum langigerum}.","name":"habitat"},{"raw":"unknown","processed":"","name":"georeferenceProtocol"},{"raw":"Australian Capital Territory","processed":"New South Wales","name":"stateProvince"},{"raw":"148.8","processed":"148.8","name":"decimalLongitude"},{"raw":"","processed":"Terrestrial","name":"biome"},{"raw":"","processed":"EPSG:4326","name":"geodeticDatum"},{"raw":"AU","processed":"","name":"countryCode"}],"Identification":[{"raw":"","processed":"Not provided","name":"abcdIdentificationQualifier"},{"raw":"2005-05","processed":"","name":"dateIdentified"},{"raw":"","processed":"Not provided","name":"identificationQualifier"},{"raw":"det.","processed":"","name":"identifierRole"},{"raw":"Jones, D.L.","processed":"","name":"identifiedBy"}],"Occurrence":[{"raw":"Unknown","processed":"","name":"naturalOccurrence"},{"raw":"","processed":"Critically Endangered,Critically Endangered","name":"stateConservation"},{"raw":"PreservedSpecimen","processed":"PreservedSpecimen","name":"basisOfRecord"},{"raw":"","processed":"Location in New South Wales, Australia generalised to 0.1 degrees. \\nSensitive in NSW, Name: New South Wales, Zone: STATE [NSW Category 2 Conservation Protected, NSW OEH]","name":"dataGeneralizations"},{"raw":"Jones, D.L.","processed":"Jones, D.L.","name":"recordedBy"},{"raw":"Jones, T.D.","processed":"","name":"secondaryCollectors"},{"raw":"2016-01-27 15:17:26","processed":"2016-01-27","name":"modified"},{"raw":"5630","processed":"","name":"fieldNumber"},{"raw":"5630","processed":"","name":"recordNumber"},{"raw":"","processed":"03fee6b0-38cf-4e80-bc17-2586443322b2|9eab97d3-344b-4bd2-9d6e-92c0e9f696cc","name":"associatedOccurrences"},{"raw":"Unknown","processed":"unknown","name":"establishmentMeans"},{"raw":"CANB","processed":"","name":"institutionCode"},{"raw":"Deciduous terrestrial orchid; stems smooth. Common.","processed":"","name":"occurrenceRemarks"},{"raw":"","processed":"present","name":"occurrenceStatus"},{"raw":"","processed":"R","name":"duplicationStatus"},{"raw":"sheet","processed":"","name":"preparations"},{"raw":"CBG 9004654.1","processed":"","name":"catalogNumber"},{"raw":"CBG","processed":"","name":"collectionCode"}]}'''
            def json3 = '''{"Measurement":[],"Attribution":[{"raw":"","processed":"co12","name":"collectionUid"},{"raw":"","processed":"Australia's Virtual Herbarium","name":"dataResourceName"},{"raw":"","processed":"in5","name":"institutionUid"},{"raw":"","processed":"[\\"dh2\\",\\"dh9\\"]","name":"dataHubUid"},{"raw":"","processed":"Australian National Herbarium","name":"collectionName"},{"raw":"","processed":"dp36","name":"dataProviderUid"},{"raw":"","processed":"Centre for Australian National Biodiversity Research","name":"institutionName"},{"raw":"","processed":"CC BY","name":"license"},{"raw":"","processed":"Published dataset","name":"provenance"},{"raw":"dr376","processed":"","name":"dataResourceUid"},{"raw":"","processed":"Australia's Virtual Herbarium","name":"dataProviderName"}],"Classification":[{"raw":"","processed":"wellformed","name":"nameParseType"},{"raw":"","processed":"Pterostylis oreophila","name":"species"},{"raw":"","processed":"exactMatch","name":"nameMatchMetric"},{"raw":"Pterostylis oreophila Clemesha","processed":"Pterostylis oreophila","name":"scientificName"},{"raw":"","processed":"http://id.biodiversity.org.au/name/apni/75185","name":"taxonConceptID"},{"raw":"","processed":"http://id.biodiversity.org.au/node/apni/8807563","name":"kingdomID"},{"raw":"","processed":"587392","name":"left"},{"raw":"","processed":"Plantae","name":"kingdom"},{"raw":"Pterostylis","processed":"","name":"genus"},{"raw":"","processed":"species","name":"taxonRank"},{"raw":"oreophila","processed":"","name":"specificEpithet"},{"raw":"","processed":"[\\"noIssue\\"]","name":"taxonomicIssue"},{"raw":"","processed":"http://id.biodiversity.org.au/name/apni/75185","name":"speciesID"},{"raw":"Orchidaceae","processed":"","name":"family"},{"raw":"","processed":"7000","name":"taxonRankID"},{"raw":"Clemesha","processed":"","name":"scientificNameAuthorship"},{"raw":"ICBN","processed":"","name":"nomenclaturalCode"},{"raw":"","processed":"587392","name":"right"}],"Event":[{"raw":"1990-01-22","processed":"","name":"eventDate"},{"raw":"","processed":"1990","name":"year"},{"raw":"","processed":"01","name":"month"}],"Location":[{"raw":"-35.6","processed":"-35.6","name":"decimalLatitude"},{"raw":"","processed":"Tumut Shire (A)","name":"lga"},{"raw":"1000","processed":"11000.0","name":"coordinateUncertaintyInMeters"},{"raw":"Australia","processed":"Australia","name":"country"},{"raw":"not available","processed":"","name":"generalisedLocality"},{"raw":"Gentle slope. Black, wet, peaty soil under {Leptospermum langigerum}.","processed":"Gentle slope. Black, wet, peaty soil under {Leptospermum langigerum}.","name":"habitat"},{"raw":"unknown","processed":"","name":"georeferenceProtocol"},{"raw":"Australian Capital Territory","processed":"Van Demon's Land","name":"stateProvince"},{"raw":"148.8","processed":"148.8","name":"decimalLongitude"},{"raw":"","processed":"Terrestrial","name":"biome"},{"raw":"","processed":"EPSG:4326","name":"geodeticDatum"},{"raw":"AU","processed":"","name":"countryCode"}],"Identification":[{"raw":"","processed":"Not provided","name":"abcdIdentificationQualifier"},{"raw":"2005-05","processed":"","name":"dateIdentified"},{"raw":"","processed":"Not provided","name":"identificationQualifier"},{"raw":"det.","processed":"","name":"identifierRole"},{"raw":"Jones, D.L.","processed":"","name":"identifiedBy"}],"Occurrence":[{"raw":"Unknown","processed":"","name":"naturalOccurrence"},{"raw":"","processed":"Critically Endangered,Critically Endangered","name":"stateConservation"},{"raw":"PreservedSpecimen","processed":"PreservedSpecimen","name":"basisOfRecord"},{"raw":"","processed":"Location in New South Wales, Australia generalised to 0.1 degrees. \\nSensitive in NSW, Name: New South Wales, Zone: STATE [NSW Category 2 Conservation Protected, NSW OEH]","name":"dataGeneralizations"},{"raw":"Jones, D.L.","processed":"Jones, D.L.","name":"recordedBy"},{"raw":"Jones, T.D.","processed":"","name":"secondaryCollectors"},{"raw":"2016-01-27 15:17:26","processed":"2016-01-27","name":"modified"},{"raw":"5630","processed":"","name":"fieldNumber"},{"raw":"5630","processed":"","name":"recordNumber"},{"raw":"","processed":"03fee6b0-38cf-4e80-bc17-2586443322b2|9eab97d3-344b-4bd2-9d6e-92c0e9f696cc","name":"associatedOccurrences"},{"raw":"Unknown","processed":"unknown","name":"establishmentMeans"},{"raw":"CANB","processed":"","name":"institutionCode"},{"raw":"Deciduous terrestrial orchid; stems smooth. Common.","processed":"","name":"occurrenceRemarks"},{"raw":"","processed":"present","name":"occurrenceStatus"},{"raw":"","processed":"R","name":"duplicationStatus"},{"raw":"sheet","processed":"","name":"preparations"},{"raw":"CBG 9004654.1","processed":"","name":"catalogNumber"},{"raw":"CBG","processed":"","name":"collectionCode"}]}'''
            JSONObject rec1 = JSON.parse(json1)
            JSONObject rec2 = JSON.parse(json2)
            JSONObject rec3 = JSON.parse(json3)
        expect:
            extractStateConservationValue(rec1) != extractStateConservationValue(service.augmentRecord(rec1))
            extractStateConservationValue(service.augmentRecord(rec1)) ==  '''<a href="https://lists.ala.org.au/speciesListItem/list/dr652" target="_lists">Queensland: Least concern wildlife</a>'''
            extractStateConservationValue(rec2) != extractStateConservationValue(service.augmentRecord(rec2))
            extractStateConservationValue(service.augmentRecord(rec2)) ==  '''<a href="https://lists.ala.org.au/speciesListItem/list/dr650" target="_lists">New South Wales: Critically Endangered</a>'''
            extractStateConservationValue(rec3) == extractStateConservationValue(service.augmentRecord(rec3))
    }

    String extractStateConservationValue(JSONObject rec) {
        rec.get("Occurrence").find{ it.name == "stateConservation" }.get("processed")
    }

    void "test getListOfLayerIds via data table"() {
        expect:
        service.getListOfLayerIds(new SpatialSearchRequestParams(q:q, fq:fq)) == ids

        where:
        q           | fq                    | ids
        "cl10955:*" | []                    | ["cl10955"]
        "cl10955:*" | ["el123:foo"]         | ["cl10955","el123"]
        "element"   | ["cl10955:*"]         | ["cl10955"]
        "el123a:*"  | ["el1234:*"]          | ["el1234"]
        ""          | ["dl1234:*"]          | []
        ""          | ["-cl1234:*"]         | ["cl1234"]
        "dl1234:*"  | []                    | []
        "dl1234:*"  | ["cl456:[* TO *]"]    | ["cl456"]
        "*:*"       | ["el123:*","cl456:*"] | ["el123","cl456"]
    }
}
