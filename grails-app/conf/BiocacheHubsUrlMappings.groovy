class BiocacheHubsUrlMappings {

	static mappings = {
        "/occurrences/search"(controller: 'occurrence', action: 'list')
        "/occurrence/search"(controller: 'occurrence', action: 'list')
        "/occurrences/taxa/$id"(controller: 'occurrence', action: 'taxa')
        "/occurrence/index"(controller: 'occurrence', action: 'index')
        "/occurrence/legend"(controller: 'occurrence', action: 'legend')
        "/occurrences/$id"(controller: 'occurrence', action: 'show')
        "/occurrence/$id"(controller: 'occurrence', action: 'show')
        "/assertions/$id"(controller: 'occurrence', action: 'assertions')
        "/explore/your-area"(controller: 'occurrence', action: 'exploreYourArea')
        "/$action?"(controller:"home")
        "/$controller/$action?/$id?"{
            constraints {
                // apply constraints here
            }
        }
	}
}
