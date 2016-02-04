class BiocacheHubsUrlMappings {

	static mappings = {

        "/dataResource/$uid"(controller: 'occurrence', action: 'dataResource')
        "/occurrences"(redirect: [controller: 'occurrences', action: 'search'])
        "/occurrences/searchByArea"(redirect: [controller: 'occurrences', action: 'search'])
        "/occurrences/search"(controller: 'occurrence', action: 'list')
        "/occurrence/search"(controller: 'occurrence', action: 'list')
        "/occurrences/search/taxa"(controller: 'occurrence', action: 'taxaPost')
        "/occurrences/taxa/$id"(controller: 'occurrence', action: 'taxa')
        "/occurrences/assertions/add"(controller: 'assertions', action: 'addAssertion')
        "/occurrences/assertions/delete"(controller: 'assertions', action: 'deleteAssertion')
        "/occurrences/index"(controller: 'occurrence', action: 'index')
        "/occurrence/index"(controller: 'occurrence', action: 'index')
        "/occurrences/legend"(controller: 'occurrence', action: 'legend')
        "/occurrence/legend"(controller: 'occurrence', action: 'legend')
        "/occurrences/fieldguide/download"(controller: 'occurrence', action: 'fieldGuideDownload')
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
        "/"(redirect: [uri:"/search"])
        "/$controller/$action?/$id?"{
            constraints {
                // apply constraints here
            }
        }
	}
}
