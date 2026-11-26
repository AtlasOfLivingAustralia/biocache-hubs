package au.org.ala.biocache.hubs

class EventsService {

    def webServicesService
    def grailsApplication

    def eventsGraphqlQuery = { datasetKey, eventID ->  """query list {
          eventSearch(predicate: { type: and, predicates: [
              {type:equals, key: "datasetKey", value: "${datasetKey}"},
              {type:equals, key: "eventID",  value: "${eventID}"}
            ]}) {
            documents(size: 1) {
              results {
                eventTypeHierarchy 
              }
            }
          }
        }"""
    }

    /**
     * Get the facets values (and labels if available) for the requested facet field.
     *
     * @return
     */
    def getEventHierarchy(record) {

        if (!grailsApplication.config.events.enabled.toBoolean()){
            return null
        }

        def resp = null
        try {
            if (record.raw?.event?.eventID) {
                String query = eventsGraphqlQuery(record.processed.attribution.dataResourceUid, record.raw.event.eventID)
                resp = webServicesService.postJsonElements(grailsApplication.config.events.graphql, [query: query], false, false)
            }
        } catch (Exception e){
            log.error("Unable to access events graphql")
        }
        if (resp?.data?.eventSearch)
            resp?.data?.eventSearch.documents?.results?.eventTypeHierarchy[0]
        else
            null
    }
}
