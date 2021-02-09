package biocache.hubs

class BootStrap {
    def messageSource
    def application

    def init = { servletContext ->
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
