package biocache.hubs

class BootStrap {
    def messageSource
    def application
    def grailsApplication
    def grailsUrlMappingsHolder

    def init = { servletContext ->

        // if my annotation feature turned on, add url mapping to handle add/remove my annotation alert requests
        if (grailsApplication.config.getProperty('alerts.myannotation.enabled', Boolean, false)) {
            grailsUrlMappingsHolder.addMappings({
                "/api/alerts"(controller: 'webservice', action: [GET: 'getAlerts'])
                "/api/subscribeMyAnnotation"(controller: 'webservice', action: [POST: 'subscribeMyAnnotation'])
                "/api/unsubscribeMyAnnotation"(controller: 'webservice', action: [POST: 'unsubscribeMyAnnotation'])
            })
        }

        messageSource.setBasenames(
                "file:///var/opt/atlas/i18n/downloads-plugin/messages",
                "file:///opt/atlas/i18n/downloads-plugin/messages",
                "file:///var/opt/atlas/i18n/biocache-hubs/messages",
                "file:///opt/atlas/i18n/biocache-hubs/messages",
                "WEB-INF/grails-app/i18n/messages",
                "classpath:messages",
                "${application.config.biocache.baseUrl}/facets/i18n"
        )
        messageSource.setCacheSeconds(60 * 60 * 6) // 6 hours
        messageSource.setUseCodeAsDefaultMessage(false)
        messageSource.setDefaultEncoding("UTF-8")
    }
    def destroy = {
    }
}
