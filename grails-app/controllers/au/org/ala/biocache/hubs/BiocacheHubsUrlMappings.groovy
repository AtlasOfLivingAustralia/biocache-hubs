package au.org.ala.biocache.hubs

class BiocacheHubsUrlMappings {

	static mappings = {

        "/dataResource/$uid"(controller: 'occurrence', action: 'dataResource')
        "/occurrences"(redirect: [controller: 'occurrences', action: 'search'])
        "/occurrences/searchByArea"(redirect: [controller: 'occurrences', action: 'search'])
        "/occurrences/search"(controller: 'occurrence', action: 'list')
        "/occurrence/search"(controller: 'occurrence', action: 'list')
        "/occurrences/search/taxa"(controller: 'occurrence', action: 'taxaPost')
        "/occurrences/taxa/$id**"(controller: 'occurrence', action: 'taxa')
        "/occurrences/assertions/add"(controller: 'assertions', action: 'addAssertion')
        "/occurrences/assertions/delete"(controller: 'assertions', action: 'deleteAssertion')
        "/occurrences/index"(controller: 'occurrence', action: 'index')
        "/occurrence/index"(controller: 'occurrence', action: 'index')
        "/occurrences/legend"(controller: 'occurrence', action: 'legend')
        "/occurrence/legend"(controller: 'occurrence', action: 'legend')
        "/occurrences/fieldguide/download"(controller: 'occurrence', action: 'fieldGuideDownload')
        "/occurrences/facets"(controller: 'occurrence', action: 'facets')
        "/occurrences/getExcluded"(controller: 'occurrence', action: 'getExcluded')
        "/occurrences/facets/download"(controller: 'occurrence', action: 'facetsDownload')
        "/occurrences/next"(controller: 'occurrence', action: 'next')
        "/occurrences/previous"(controller: 'occurrence', action: 'previous')
        "/occurrences/dataQualityExcludeCounts"(controller: 'occurrence', action: 'dataQualityExcludeCounts')
        "/occurrences/alerts"(controller: 'occurrence', action: [GET: 'getAlerts'])
        "/occurrences/addAlert"(controller: 'occurrence', action: [POST: 'addAlert'])
        "/occurrences/deleteAlert"(controller: 'occurrence', action: [POST: 'deleteAlert'])
        "/occurrences/$id"(controller: 'occurrence', action: 'show')
        "/occurrence/$id"(controller: 'occurrence', action: 'show')
        "/assertions/$id"(controller: 'assertions', action: 'assertions')
        "/explore/your-area"(controller: 'occurrence', action: 'exploreYourArea')
        "/search"(controller: 'home')
        "/advancedSearch"(controller: 'home', action: 'advancedSearch')
        "/proxy/$path**" (controller: 'proxy'){
            action = [POST:'doPost']
        }
        "/proxy/$path**" (controller: 'proxy'){
            action = [GET:'doGet']
        }
        "/user/$type" (controller: 'user'){
            action = [POST:'set', GET:'get']
        }
        "/"(redirect: [uri:"/search"])
        "/$controller/$action?/$id?"{
            constraints {
                // apply constraints here
            }
        }
	}
}
